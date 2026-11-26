import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/review/review_and_success_widgets.dart';

/// SCREEN 07 — Submission Success
class SubmissionSuccessPage extends ConsumerWidget {
  const SubmissionSuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SellerVerificationStrings.of(context);
    final submitted =
        ref.watch(verificationSubmissionProvider).submittedApplication;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      appBar: VerificationAppBar(title: s.onboardingTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  const VerificationSuccessIcon(),
                  const SizedBox(height: AppSpacing.lg),
                  const VerificationSuccessHeader(),
                  const SizedBox(height: AppSpacing.md),
                  const PendingStatusBadge(),
                  const SizedBox(height: AppSpacing.xl),
                  if (submitted != null && submitted.id.isNotEmpty) ...[
                    ApplicationReferenceCard(referenceId: submitted.id),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  SubmissionDateCard(
                    submittedAt: submitted?.submittedAt ?? DateTime.now(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TrackApplicationButton(
                    onPressed: () =>
                        context.go(RouteNames.sellerVerificationTracking),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ReturnHomeButton(
                    onPressed: () => context.go(RouteNames.root),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
