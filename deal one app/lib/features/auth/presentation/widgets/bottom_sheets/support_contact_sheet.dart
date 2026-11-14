import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('تم نسخ $label')));
  }

  @override
  Widget build(BuildContext context) {
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
            'الدعم الفني - ديل ون',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'إذا واجهت صعوبة متكررة في استلام رمز التحقق، يمكنك التواصل مع فريق الدعم أو نسخ بيانات التواصل أدناه:',
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
            title: 'البريد الإلكتروني للدعم',
            value: supportEmail,
            onCopy: () =>
                _copyValue(context, supportEmail, 'البريد الإلكتروني'),
          ),
          const SizedBox(height: 10),
          _SupportTile(
            icon: Icons.support_agent_rounded,
            title: 'خدمة العملاء',
            value: supportHotline,
            onCopy: () =>
                _copyValue(context, supportHotline, 'رقم خدمة العملاء'),
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
  final VoidCallback onCopy;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.value,
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
          Icon(icon, color: AuthDesignTokens.actionBlue, size: 22),
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
            tooltip: 'نسخ',
          ),
        ],
      ),
    );
  }
}
