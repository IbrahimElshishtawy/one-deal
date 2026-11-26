import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/onboarding/onboarding_widgets.dart';

/// SCREEN 01 — Seller Onboarding Entry
class SellerOnboardingEntryPage extends ConsumerStatefulWidget {
  const SellerOnboardingEntryPage({super.key});

  @override
  ConsumerState<SellerOnboardingEntryPage> createState() =>
      _SellerOnboardingEntryPageState();
}

class _SellerOnboardingEntryPageState
    extends ConsumerState<SellerOnboardingEntryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sellerOnboardingProvider.notifier).load(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final state = ref.watch(sellerOnboardingProvider);
    final snapshot = state.snapshot;

    final hasExistingApp = snapshot != null &&
        snapshot.sellerStatus != VerificationStatus.notSubmitted;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      appBar: VerificationAppBar(title: s.onboardingTitle),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(sellerOnboardingProvider.notifier).load(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SellerOnboardingHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.isLoading && snapshot == null)
                      const VerificationLoadingSkeleton(cardCount: 3)
                    else if (state.failure != null && snapshot == null)
                      DealOneErrorStateView(
                        error: state.failure!,
                        onRetry: () => ref
                            .read(sellerOnboardingProvider.notifier)
                            .load(forceRefresh: true),
                      )
                    else ...[
                      if (hasExistingApp) ...[
                        ExistingApplicationStatusCard(
                          snapshot: snapshot,
                          onTrackTap: () =>
                              context.push(RouteNames.sellerVerificationTracking),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      const SellerBenefitsSection(),
                      const SizedBox(height: AppSpacing.lg),
                      const VerificationSecurityNotice(),
                      const SizedBox(height: AppSpacing.xl),
                      if (!hasExistingApp ||
                          snapshot.sellerStatus == VerificationStatus.draft)
                        StartSellingButton(
                          isLoading: state.isLoading,
                          onPressed: () {
                            if (snapshot?.application != null) {
                              ref
                                  .read(sellerTypeSelectionProvider.notifier)
                                  .hydrateFromApplication(snapshot!.application);
                              ref
                                  .read(sellerInformationProvider.notifier)
                                  .hydrateFromApplication(snapshot.application);
                            }
                            context.push(RouteNames.sellerVerificationType);
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
