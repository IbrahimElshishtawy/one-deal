import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../domain/entities/auth_session.dart';
import '../../../domain/validators/auth_validators.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../widgets/common/auth_primary_button.dart';
import '../../widgets/common/auth_scaffold_shell.dart';

/// Deal One Verification Success screen (Design Screen 9).
class VerificationSuccessPage extends ConsumerWidget {
  final AuthSession? session;

  const VerificationSuccessPage({
    super.key,
    this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUser = session?.user ?? ref.watch(authControllerProvider).valueOrNull;
    final displayName = (activeUser?.fullName.trim().isNotEmpty == true)
        ? activeUser!.fullName
        : 'عميل ديل ون';
    final displayPhone = (activeUser?.phone.trim().isNotEmpty == true)
        ? EgyptianPhoneValidator.formatForDisplay(activeUser!.phone)
        : null;

    return AuthScaffoldShell(
      centerVertically: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    color: AuthDesignTokens.successTintOf(context),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 102,
                  height: 102,
                  decoration: BoxDecoration(
                    color: AuthDesignTokens.successGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            AuthDesignTokens.successGreen.withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'تم التحقق من حسابك بنجاح!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'أهلاً بك، $displayName\nأصبح حسابك في ديل ون جاهزاً للتصفح وإضافة الإعلانات والتواصل مع البائعين.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: AuthDesignTokens.bodyOf(context),
              height: 1.65,
            ),
          ),
          if (displayPhone != null) ...[
            const SizedBox(height: 18),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AuthDesignTokens.surfaceOf(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AuthDesignTokens.borderOf(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: AuthDesignTokens.successGreen,
                    ),
                    const SizedBox(width: 8),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        displayPhone,
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
            ),
          ],
          const SizedBox(height: 36),
          AuthPrimaryButton(
            key: const Key('verification_success_continue_button'),
            label: 'المتابعة إلى ديل ون',
            onPressed: () => context.go(RouteNames.root),
          ),
        ],
      ),
    );
  }
}
