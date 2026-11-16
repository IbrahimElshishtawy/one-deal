import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../domain/entities/auth_session.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../widgets/common/auth_primary_button.dart';
import '../../widgets/common/auth_scaffold_shell.dart';

/// Navigation payload for [VerificationSuccessPage].
class VerificationSuccessArgs {
  final AuthSession session;
  final String? redirectTo;

  const VerificationSuccessArgs({required this.session, this.redirectTo});
}

/// Deal One Verification Success screen matching `ui/لو العملية التحقق نجحت.png`.
class VerificationSuccessPage extends ConsumerWidget {
  final AuthSession? session;
  final String? redirectTo;

  const VerificationSuccessPage({super.key, this.session, this.redirectTo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUser =
        session?.user ?? ref.watch(authControllerProvider).valueOrNull;
    final hasCustomName =
        activeUser != null &&
        activeUser.fullName.trim().isNotEmpty &&
        !activeUser.fullName.trim().startsWith('مستخدم ');

    final targetRoute =
        (redirectTo != null &&
            redirectTo!.startsWith('/') &&
            redirectTo != RouteNames.login &&
            redirectTo != RouteNames.signUp)
        ? redirectTo!
        : RouteNames.root;

    return AuthScaffoldShell(
      centerVertically: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Text(
                'ديل ون',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AuthDesignTokens.headingOf(context),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AuthDesignTokens.spaceXs),
              Text(
                'DEAL ONE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AuthDesignTokens.headingOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AuthDesignTokens.space3xl),
          Center(
            child: SizedBox(
              width: 224,
              height: 224,
              child: CustomPaint(
                painter: _ConcentricDashedRingsPainter(
                  ringColor: AuthDesignTokens.borderOf(context),
                ),
                child: Center(
                  child: Container(
                    width: 144,
                    height: 144,
                    decoration: BoxDecoration(
                      color: AuthDesignTokens.surfaceOf(context),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AuthDesignTokens.navyPrimary.withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 28,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 12,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AuthDesignTokens.navyPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AuthDesignTokens.successTealDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AuthDesignTokens.primaryActionOf(context),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceXl),
          Text(
            'تم التحقق بنجاح!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceSm),
          Text(
            hasCustomName
                ? 'أهلاً بك، ${activeUser.fullName}\nأصبح حسابك جاهزاً الآن للاستخدام والبحث عن عقارك ومشاريعك.'
                : 'أصبح حسابك جاهزاً الآن للاستخدام والبحث عن\nعقارك ومشاريعك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AuthDesignTokens.mutedOf(context),
              height: 1.65,
            ),
          ),
          const SizedBox(height: AuthDesignTokens.space2xl),
          AuthPrimaryButton(
            key: const Key('verification_success_continue_button'),
            label: 'المتابعة لتسجيل الدخول',
            onPressed: () => context.go(targetRoute),
          ),
        ],
      ),
    );
  }
}

class _ConcentricDashedRingsPainter extends CustomPainter {
  final Color ringColor;

  const _ConcentricDashedRingsPainter({required this.ringColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    _drawDashedCircle(canvas, center, size.width * 0.48, paint, dashCount: 44);
    _drawDashedCircle(canvas, center, size.width * 0.39, paint, dashCount: 36);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    required int dashCount,
  }) {
    final step = (2 * math.pi) / dashCount;
    final sweep = step * 0.45;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * step, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricDashedRingsPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor;
}
