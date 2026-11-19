import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/auth_l10n_extension.dart';
import '../../theme/auth_design_tokens.dart';

/// Interactive support contact bottom sheet accessible from OTP troubleshooting.
class SupportContactSheet extends StatelessWidget {
  const SupportContactSheet({super.key});

  static const String supportEmail = 'support@dealone.eg';
  static const String supportHotline = '+20 100 000 0000';

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AuthDesignTokens.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SupportContactSheet(),
    );
  }

  Future<void> _copyValue(
    BuildContext context,
    String value,
    String label,
  ) async {
    final l10n = context.authL10n;
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.copiedItem(label))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.authL10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AuthDesignTokens.borderOf(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.supportTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.supportSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AuthDesignTokens.bodyOf(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _SupportTile(
            icon: Icons.email_outlined,
            title: l10n.supportEmailTitle,
            value: supportEmail,
            copyTooltip: l10n.copy,
            onCopy: () =>
                _copyValue(context, supportEmail, l10n.supportEmailTitle),
          ),
          const SizedBox(height: 10),
          _SupportTile(
            icon: Icons.support_agent_rounded,
            title: l10n.supportHotlineTitle,
            value: supportHotline,
            copyTooltip: l10n.copy,
            onCopy: () =>
                _copyValue(context, supportHotline, l10n.supportHotlineTitle),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String copyTooltip;
  final VoidCallback onCopy;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.copyTooltip,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuthDesignTokens.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthDesignTokens.borderOf(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AuthDesignTokens.linkOf(context), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AuthDesignTokens.mutedOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AuthDesignTokens.headingOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 19),
            tooltip: copyTooltip,
          ),
        ],
      ),
    );
  }
}
