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
import 'package:market_space/features/seller_verification/presentation/widgets/tracking/tracking_and_upgrade_widgets.dart';

/// SCREEN 08 — Verification Tracking Center
class VerificationTrackingPage extends ConsumerStatefulWidget {
  const VerificationTrackingPage({super.key});

  @override
  ConsumerState<VerificationTrackingPage> createState() =>
      _VerificationTrackingPageState();
}

class _VerificationTrackingPageState
    extends ConsumerState<VerificationTrackingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(verificationTrackingProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final state = ref.watch(verificationTrackingProvider);
    final snapshot = state.snapshot;
    final app = snapshot?.application;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      appBar: VerificationAppBar(
        title: s.trackingTitle,
        actions: [
          IconButton(
            tooltip: s.refreshLabel,
            icon: Icon(
              Icons.refresh_rounded,
              color: DealOneTokens.textPrimaryOf(context),
            ),
            onPressed: () {
              ref.read(verificationTrackingProvider.notifier).refresh();
              ref.invalidate(sellerVerificationBadgeProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(verificationTrackingProvider.notifier).refresh();
            ref.invalidate(sellerVerificationBadgeProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const VerificationTrackingHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.isLoading && snapshot == null)
                      const VerificationLoadingSkeleton(cardCount: 3)
                    else if (state.failure != null && snapshot == null)
                      DealOneErrorStateView(
                        error: state.failure!,
                        onRetry: () => ref
                            .read(verificationTrackingProvider.notifier)
                            .refresh(),
                      )
                    else if (snapshot == null ||
                        snapshot.sellerStatus ==
                            VerificationStatus.notSubmitted) ...[
                      VerificationStatusCard(
                        status: VerificationStatus.notSubmitted,
                        verificationTier: VerificationTier.none,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      StartSellingButton(
                        onPressed: () =>
                            context.push(RouteNames.sellerVerificationType),
                      ),
                    ] else ...[
                      VerificationStatusCard(
                        status: snapshot.sellerStatus,
                        sellerType: snapshot.sellerType ?? app?.sellerType,
                        verificationTier: snapshot.verificationTier,
                        badge: snapshot.activeBadge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (app != null) ...[
                        VerificationSubmittedInfo(application: app),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (snapshot.sellerStatus == VerificationStatus.rejected &&
                          app?.rejectionReason != null) ...[
                        VerificationRejectionReasonCard(
                          reason: app!.rejectionReason!,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        VerificationResubmitButton(
                          onPressed: () => _openEditForResubmission(app),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (snapshot.sellerStatus ==
                              VerificationStatus.needsChanges &&
                          app != null) ...[
                        VerificationCorrectionNotice(
                          reason: app.correctionReason ??
                              s.correctionNoticeTitle,
                          affectedFields: app.correctionFields,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        VerificationResubmitButton(
                          onPressed: () => _openEditForResubmission(app),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (snapshot.sellerStatus ==
                          VerificationStatus.approved) ...[
                        VerificationApprovedCard(
                          snapshot: snapshot,
                          onUpgradeTap: snapshot
                                  .capabilities.canUpgradeToBusiness
                              ? () => context
                                  .push(RouteNames.sellerVerificationUpgrade)
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (snapshot.sellerStatus ==
                          VerificationStatus.suspended) ...[
                        VerificationSuspendedCard(
                          reason: snapshot.sellerSuspensionReason ??
                              app?.suspensionReason,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (snapshot.sellerStatus == VerificationStatus.draft &&
                          app != null) ...[
                        ContinueButton(
                          label: s.continueLabel,
                          onPressed: () => _openEditForResubmission(app),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (state.history.isNotEmpty) ...[
                        VerificationTimeline(items: state.history),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      ContactSupportButton(
                        onPressed: () => context.push(RouteNames.terms),
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

  void _openEditForResubmission(dynamic app) {
    ref.read(sellerTypeSelectionProvider.notifier).hydrateFromApplication(app);
    ref.read(sellerInformationProvider.notifier).hydrateFromApplication(app);
    ref
        .read(documentUploadProvider.notifier)
        .hydrateExistingDocuments(app.documents);
    ref.read(verificationRequirementsProvider.notifier).load(
          sellerType: app.sellerType,
          marketplaceSections: app.marketplaceSections,
          forceRefresh: true,
        );
    context.push(RouteNames.sellerVerificationUpload);
  }
}
