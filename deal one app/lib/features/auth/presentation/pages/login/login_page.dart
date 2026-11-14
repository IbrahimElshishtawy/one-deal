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
import '../../widgets/login/login_form_card.dart';

/// Deal One Login page (Design Screen 10).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

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
    final pending = await ref.read(loginControllerProvider.notifier).submit();
    if (!mounted || pending == null) return;
    ref.read(loginControllerProvider.notifier).consumePendingContext();
    context.push(RouteNames.otpVerification, extra: pending);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return AuthScaffoldShell(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              )
            : null,
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
            title: 'مرحباً بعودتك',
            subtitle:
                'سجل دخولك برقم الهاتف لإدارة إعلاناتك ومتابعة عروضك المفضلة',
          ),
          const SizedBox(height: 30),
          LoginFormCard(
            phoneController: _phoneController,
            phoneError: state.phoneError,
            submitError: state.submitError,
            isSubmitting: state.isSubmitting,
            onPhoneChanged: controller.updatePhone,
            onSubmit: _handleSubmit,
          ),
          const SizedBox(height: 26),
          AuthSocialSection(
            onProviderSelected: (provider) {
              UnavailableProviderDialog.show(context, provider: provider);
            },
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ليس لديك حساب؟',
                style: TextStyle(
                  fontSize: 14,
                  color: AuthDesignTokens.bodyOf(context),
                ),
              ),
              TextButton(
                key: const Key('login_to_signup_button'),
                onPressed: () => context.go(RouteNames.signUp),
                child: const Text(
                  'إنشاء حساب جديد',
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
