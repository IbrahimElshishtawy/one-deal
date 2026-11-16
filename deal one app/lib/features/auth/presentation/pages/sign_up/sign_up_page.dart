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
import '../../widgets/sign_up/sign_up_form_card.dart';

/// Deal One Sign Up page matching `ui/انشاء حساب.png`.
class SignUpPage extends ConsumerStatefulWidget {
  final String? redirectTo;

  const SignUpPage({super.key, this.redirectTo});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final notifier = ref.read(signUpControllerProvider.notifier);
    final pending = await notifier.submit(redirectTo: widget.redirectTo);
    if (!mounted) return;
    if (pending != null) {
      notifier.consumePendingContext();
      context.push(RouteNames.otpVerification, extra: pending);
      return;
    }

    final state = ref.read(signUpControllerProvider);
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
    final state = ref.watch(signUpControllerProvider);
    final controller = ref.read(signUpControllerProvider.notifier);

    return AuthScaffoldShell(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'لديك حساب بالفعل؟ ',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AuthDesignTokens.mutedOf(context),
                ),
              ),
              GestureDetector(
                key: const Key('signup_to_login_button'),
                onTap: () => context.go(
                  widget.redirectTo != null
                      ? '${RouteNames.login}?redirect=${Uri.encodeComponent(widget.redirectTo!)}'
                      : RouteNames.login,
                ),
                child: Text(
                  'تسجيل الدخول',
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
            title: 'أنشئ حسابك في Deal One',
            subtitle: 'ابحث عن عقارك، سيارتك، وصفقاتك في\nمكان واحد.',
          ),
          const SizedBox(height: AuthDesignTokens.headerToFormGap),
          SignUpFormCard(
            fullNameController: _fullNameController,
            phoneController: _phoneController,
            fullNameError: state.fullNameError,
            phoneError: state.phoneError,
            submitError: state.submitError,
            isSubmitting: state.isSubmitting,
            onFullNameChanged: controller.updateFullName,
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
