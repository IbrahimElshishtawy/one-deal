import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/app_localization.dart';
import '../../../../../core/routing/route_names.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../utils/auth_error_localizer.dart';
import '../../widgets/bottom_sheets/email_fallback_sheet.dart';
import '../../widgets/bottom_sheets/support_contact_sheet.dart';
import '../../widgets/bottom_sheets/whatsapp_delivery_failure_sheet.dart';
import '../../widgets/common/auth_legal_footer.dart';
import '../../widgets/common/auth_logo_header.dart';
import '../../widgets/common/auth_scaffold_shell.dart';
import '../../widgets/common/auth_social_button.dart';
import '../../widgets/dialogs/unavailable_provider_dialog.dart';
import '../../widgets/sign_up/sign_up_form_card.dart';

/// Deal One Sign Up page matching `Sign-Up.png`.
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
      final localizedReason = AuthErrorLocalizer.resolveMessage(
        context,
        rawMessage: state.submitError,
        errorKind: state.errorKind,
      );
      _showDeliveryFailureSheet(
        displayPhone: state.deliveryFailurePhone!,
        failureReason: localizedReason,
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
    final l10n = AppLocalization.of(context);

    final localizedNameError = AuthErrorLocalizer.resolveMessage(
      context,
      rawMessage: state.fullNameError,
    );
    final localizedPhoneError = AuthErrorLocalizer.resolveMessage(
      context,
      rawMessage: state.phoneError,
    );
    final localizedSubmitError = AuthErrorLocalizer.resolveMessage(
      context,
      rawMessage: state.submitError,
      errorKind: state.errorKind,
    );

    return AuthScaffoldShell(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.signUpHaveAccountPrompt,
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
                  l10n.signUpLoginLink,
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
                l10n.authBrowseAsGuest,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AuthDesignTokens.mutedOf(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceMd),
          AuthLogoHeader(
            title: l10n.signUpTitle,
            subtitle: l10n.signUpSubtitle,
          ),
          const SizedBox(height: AuthDesignTokens.headerToFormGap),
          SignUpFormCard(
            fullNameController: _fullNameController,
            phoneController: _phoneController,
            fullNameError: localizedNameError,
            phoneError: localizedPhoneError,
            submitError: localizedSubmitError,
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
