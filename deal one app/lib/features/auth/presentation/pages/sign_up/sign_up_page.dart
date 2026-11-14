import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../widgets/common/auth_logo_header.dart';
import '../../widgets/common/auth_scaffold_shell.dart';
import '../../widgets/common/auth_social_button.dart';
import '../../widgets/dialogs/unavailable_provider_dialog.dart';
import '../../widgets/sign_up/sign_up_form_card.dart';

/// Deal One Sign Up page (Design Screen 4).
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

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
    final pending = await ref.read(signUpControllerProvider.notifier).submit();
    if (!mounted || pending == null) return;
    ref.read(signUpControllerProvider.notifier).consumePendingContext();
    context.push(RouteNames.otpVerification, extra: pending);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpControllerProvider);
    final controller = ref.read(signUpControllerProvider.notifier);

    return AuthScaffoldShell(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => context.go(RouteNames.root),
            child: Text(
              'تصفح كزائر',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AuthDesignTokens.mutedOf(context),
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthLogoHeader(
            title: 'إنشاء حساب جديد',
            subtitle:
                'أنشئ حسابك خلال ثوانٍ واستمتع بأفضل العروض في مصر عبر ديل ون',
          ),
          const SizedBox(height: 28),
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
            onTermsTap: () => context.push(RouteNames.terms),
            onPrivacyTap: () => context.push(RouteNames.privacy),
          ),
          const SizedBox(height: 24),
          AuthSocialSection(
            onProviderSelected: (provider) {
              UnavailableProviderDialog.show(context, provider: provider);
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'لديك حساب بالفعل؟',
                style: TextStyle(
                  fontSize: 14,
                  color: AuthDesignTokens.bodyOf(context),
                ),
              ),
              TextButton(
                key: const Key('signup_to_login_button'),
                onPressed: () => context.go(RouteNames.login),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AuthDesignTokens.actionBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
