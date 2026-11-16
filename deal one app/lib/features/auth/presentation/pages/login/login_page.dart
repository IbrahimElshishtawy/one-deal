import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../widgets/bottom_sheets/email_fallback_sheet.dart';
import '../../widgets/bottom_sheets/support_contact_sheet.dart';
import '../../widgets/bottom_sheets/whatsapp_delivery_failure_sheet.dart';
import '../../widgets/common/auth_legal_footer.dart';
import '../../widgets/common/auth_logo_header.dart';
import '../../widgets/common/auth_scaffold_shell.dart';
import '../../widgets/common/auth_social_button.dart';
import '../../widgets/dialogs/unavailable_provider_dialog.dart';
import '../../widgets/login/login_form_card.dart';

/// Deal One Login page matching `ui/login.png`.
class LoginPage extends ConsumerStatefulWidget {
  final String? redirectTo;

  const LoginPage({super.key, this.redirectTo});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final notifier = ref.read(loginControllerProvider.notifier);
    final pending = await notifier.submit(redirectTo: widget.redirectTo);
    if (!mounted) return;
    if (pending != null) {
      notifier.consumePendingContext();
      context.push(RouteNames.otpVerification, extra: pending);
      return;
    }

    final state = ref.read(loginControllerProvider);
    if (state.hasDeliveryFailure) {
      _showDeliveryFailureSheet(
        displayPhone: state.deliveryFailurePhone!,
        failureReason: state.submitError,
      );
      notifier.clearDeliveryFailure();
    }
  }

  void _showDeliveryFailureSheet({
    required String displayPhone,
    String? failureReason,
  }) {
    WhatsAppDeliveryFailureSheet.show(
      context,
      displayPhone: displayPhone,
      subtitle: failureReason,
      onEditPhone: () {},
      onSendViaSms: _handleSubmit,
      onTryEmail: () => EmailFallbackSheet.show(context),
      onContactSupport: () => SupportContactSheet.show(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return AuthScaffoldShell(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ليس لديك حساب؟ ',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AuthDesignTokens.mutedOf(context),
                ),
              ),
              GestureDetector(
                key: const Key('login_to_signup_button'),
                onTap: () => context.go(
                  widget.redirectTo != null
                      ? '${RouteNames.signUp}?redirect=${Uri.encodeComponent(widget.redirectTo!)}'
                      : RouteNames.signUp,
                ),
                child: Text(
                  'إنشاء حساب الآن',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AuthDesignTokens.headingOf(context),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AuthDesignTokens.spaceMd),
          AuthLegalFooter(
            onTermsTap: () => context.push(RouteNames.terms),
            onPrivacyTap: () => context.push(RouteNames.privacy),
          ),
          const SizedBox(height: AuthDesignTokens.spaceSm),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTopBar(
            onBack: context.canPop() ? () => context.pop() : null,
            trailing: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuthDesignTokens.spaceSm,
                ),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => context.go(RouteNames.root),
              child: Text(
                'تصفح كزائر',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AuthDesignTokens.mutedOf(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceMd),
          const AuthLogoHeader(
            title: 'أهلاً بك مجدداً',
            subtitle: 'أدخل رقم الواتساب للمتابعة واستكشاف\nالعقارات والمشاريع',
          ),
          const SizedBox(height: AuthDesignTokens.headerToFormGap),
          LoginFormCard(
            phoneController: _phoneController,
            phoneError: state.phoneError,
            submitError: state.submitError,
            isSubmitting: state.isSubmitting,
            onPhoneChanged: controller.updatePhone,
            onSubmit: _handleSubmit,
          ),
          const SizedBox(height: AuthDesignTokens.sectionGap),
          AuthSocialSection(
            onProviderSelected: (provider) {
              UnavailableProviderDialog.show(context, provider: provider);
            },
          ),
        ],
      ),
    );
  }
}
