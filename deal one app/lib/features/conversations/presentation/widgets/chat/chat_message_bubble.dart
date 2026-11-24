import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';

/// Telegram-style chat message bubble supporting custom font size, corner radius,
/// color theme gradients, compact density, inline reply quotes, search highlight,
/// timestamps, and read receipt ticks.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMine;
  final ChatSettingsEntity settings;
  final String searchQuery;
  final bool isHighlightedMatch;
  final VoidCallback? onLongPress;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.settings,
    this.searchQuery = '',
    this.isHighlightedMatch = false,
    this.onLongPress,
  });

  ({String? replyHeader, String bodyText}) _splitReplyQuote(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('↪ ')) {
      return (replyHeader: null, bodyText: raw);
    }
    final newlineIndex = trimmed.indexOf('\n');
    if (newlineIndex <= 2 || newlineIndex >= trimmed.length - 1) {
      return (replyHeader: null, bodyText: raw);
    }
    final header = trimmed.substring(2, newlineIndex).trim();
    final body = trimmed.substring(newlineIndex + 1).trim();
    return (replyHeader: header, bodyText: body);
  }

  List<TextSpan> _buildHighlightedSpans(
    String text,
    TextStyle baseStyle,
    Color highlightBg,
  ) {
    final query = searchQuery.trim();
    if (query.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        }
        break;
      }
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: baseStyle.copyWith(
            backgroundColor: highlightBg,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      start = index + query.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final radius = settings.bubbleRadius;
    final tailRadius = (radius * 0.28).clamp(3.0, 8.0);
    final parsed = _splitReplyQuote(message.body);
    final isRead = message.status.toLowerCase() == 'read';
    final isDelivered = message.status.toLowerCase() == 'delivered' || isRead;
    final timeStr = DateFormat('HH:mm').format(message.sentAt.toLocal());

    final borderRadius = isMine
        ? BorderRadiusDirectional.only(
            topStart: Radius.circular(radius),
            topEnd: Radius.circular(radius),
            bottomStart: Radius.circular(radius),
            bottomEnd: Radius.circular(tailRadius),
          )
        : BorderRadiusDirectional.only(
            topStart: Radius.circular(radius),
            topEnd: Radius.circular(radius),
            bottomStart: Radius.circular(tailRadius),
            bottomEnd: Radius.circular(radius),
          );

    final textColor = isMine
        ? Colors.white
        : DealOneTokens.textPrimaryOf(context);
    final metaColor = isMine
        ? Colors.white.withValues(alpha: 0.78)
        : DealOneTokens.textSecondaryOf(context);

    final textStyle = TextStyle(
      fontSize: settings.fontSize,
      height: settings.compactMode ? 1.32 : 1.44,
      color: textColor,
    );

    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            minWidth: 72,
          ),
          margin: EdgeInsets.only(
            bottom: settings.compactMode ? 4 : AppSpacing.sm,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: settings.compactMode ? 11 : 14,
            vertical: settings.compactMode ? 7 : 10,
          ),
          decoration: BoxDecoration(
            gradient: isMine
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      settings.colorTheme.outgoingStart(isDark),
                      settings.colorTheme.outgoingEnd(isDark),
                    ],
                  )
                : null,
            color: isMine ? null : DealOneTokens.cardSurfaceOf(context),
            borderRadius: borderRadius,
            border: isHighlightedMatch
                ? Border.all(color: DealOneTokens.amber, width: 2)
                : (isMine
                      ? null
                      : Border.all(
                          color: DealOneTokens.cardBorderOf(context),
                        )),
            boxShadow: isMine
                ? [
                    BoxShadow(
                      color: settings.colorTheme
                          .outgoingStart(isDark)
                          .withValues(alpha: isDark ? 0.25 : 0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : DealOneTokens.softShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (parsed.replyHeader != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 8, 5),
                  decoration: BoxDecoration(
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.14)
                        : settings.colorTheme
                              .accent(isDark)
                              .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: BorderDirectional(
                      start: BorderSide(
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.85)
                            : settings.colorTheme.accent(isDark),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    parsed.replyHeader!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: (settings.fontSize - 2.5).clamp(10.5, 16.0),
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.9)
                          : DealOneTokens.textSecondaryOf(context),
                    ),
                  ),
                ),
              ],
              Text.rich(
                TextSpan(
                  children: _buildHighlightedSpans(
                    parsed.bodyText,
                    textStyle,
                    DealOneTokens.amber.withValues(alpha: 0.45),
                  ),
                ),
              ),
              if (settings.showTimestamps ||
                  (isMine && settings.showReadReceipts)) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (settings.showTimestamps)
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: metaColor,
                        ),
                      ),
                    if (isMine && settings.showReadReceipts) ...[
                      if (settings.showTimestamps) const SizedBox(width: 4),
                      Icon(
                        isDelivered
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 14,
                        color: isRead
                            ? const Color(0xFF7DD3FC)
                            : metaColor,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
