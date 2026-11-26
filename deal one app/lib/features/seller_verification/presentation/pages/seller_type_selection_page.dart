import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/type_selection/seller_type_widgets.dart';

/// SCREEN 02 — Seller Type Selection
class SellerTypeSelectionPage extends ConsumerWidget {
  const SellerTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SellerVerificationStrings.of(context);
    final selection = ref.watch(sellerTypeSelectionProvider);
    final notifier = ref.read(sellerTypeSelectionProvider.notifier);

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      appBar: VerificationAppBar(title: s.selectTypeTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VerificationStepProgress(currentStep: 1, totalSteps: 5),
                  const SizedBox(height: AppSpacing.lg),
                  const SellerTypeSelectionHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  IndividualSellerCard(
                    isSelected:
                        selection.selectedType == SellerType.individual,
                    onTap: () =>
                        notifier.selectSellerType(SellerType.individual),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BusinessSellerCard(
                    isSelected: selection.selectedType == SellerType.business,
                    onTap: () => notifier.selectSellerType(SellerType.business),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SellerTypeCard(
                    key: const Key('seller_type_card_service_provider'),
                    sellerType: SellerType.serviceProvider,
                    icon: Icons.handyman_outlined,
                    title: s.serviceProviderTitle,
                    description: s.serviceProviderDesc,
                    badgePreview: s.identityVerifiedBadge,
                    isSelected:
                        selection.selectedType == SellerType.serviceProvider,
                    onTap: () =>
                        notifier.selectSellerType(SellerType.serviceProvider),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ContinueButton(
                    label: s.continueLabel,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      // Pre-fetch dynamic requirements for the chosen sellerType
                      ref.read(verificationRequirementsProvider.notifier).load(
                            sellerType: selection.selectedType,
                          );
                      context.push(RouteNames.sellerVerificationInfo);
                    },
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
