import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/accounts/presentation/providers/user_profile_providers.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/badges/verification_badges.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/onboarding/onboarding_widgets.dart';

/// SCREEN 09 — Verified Seller Profile
class VerifiedSellerProfilePage extends ConsumerWidget {
  const VerifiedSellerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SellerVerificationStrings.of(context);
    final statusAsync = ref.watch(sellerVerificationBadgeProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      appBar: VerificationAppBar(title: s.verifiedProfileTitle),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(sellerVerificationBadgeProvider);
            ref.invalidate(userProfileProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: statusAsync.when(
                  loading: () => const VerificationLoadingSkeleton(cardCount: 2),
                  error: (err, _) => DealOneErrorStateView(
                    error: err,
                    onRetry: () =>
                        ref.invalidate(sellerVerificationBadgeProvider),
                  ),
                  data: (snapshot) {
                    if (snapshot == null) {
                      return StartSellingButton(
                        onPressed: () =>
                            context.push(RouteNames.sellerVerification),
                      );
                    }
                    final displayName =
                        snapshot.application?.businessName ??
                            profileAsync.valueOrNull?.fullName ??
                            'Deal One Seller';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VerifiedSellerHeader(
                          displayName: displayName,
                          sellerType:
                              snapshot.sellerType ?? SellerType.individual,
                          verificationStatus: snapshot.sellerStatus,
                          verificationTier: snapshot.verificationTier,
                          badge: snapshot.activeBadge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SellerVerificationSummary(
                          snapshot: snapshot,
                          onTrackTap: () => context
                              .push(RouteNames.sellerVerificationTracking),
                          onUpgradeTap: snapshot
                                  .capabilities.canUpgradeToBusiness
                              ? () => context
                                  .push(RouteNames.sellerVerificationUpgrade)
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const VerificationSecurityNotice(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
