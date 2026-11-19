import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';

Future<void> showLocationSelectorSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _LocationSelectorSheet(),
  );
}

class _LocationSelectorSheet extends ConsumerWidget {
  const _LocationSelectorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final govsAsync = ref.watch(governoratesProvider);
    final selectedGov = ref.watch(selectedGovernorateProvider);
    final selectedCity = ref.watch(selectedCityProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderOf(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'اختر الموقع' : 'Select Location',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedGov != null)
                    TextButton(
                      onPressed: () {
                        ref.read(selectedGovernorateProvider.notifier).state =
                            null;
                        ref.read(selectedCityProvider.notifier).state = null;
                        Navigator.of(context).pop();
                      },
                      child: Text(isArabic ? 'كل مصر' : 'All Egypt'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: govsAsync.when(
                  data: (governorates) {
                    if (governorates.isEmpty) {
                      return Center(
                        child: Text(
                          isArabic
                              ? 'لا توجد محافظات متاحة حالياً'
                              : 'No locations available',
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: governorates.length,
                      itemBuilder: (context, index) {
                        final GovernorateEntity gov = governorates[index];
                        final isGovSelected = selectedGov?.id == gov.id;
                        final govName = isArabic ? gov.nameAr : gov.nameEn;

                        return ExpansionTile(
                          initiallyExpanded: isGovSelected,
                          leading: Icon(
                            Icons.location_city_rounded,
                            color: isGovSelected
                                ? DealOneDesignColors.navy
                                : AppColors.textMutedOf(context),
                          ),
                          title: Text(
                            govName,
                            style: TextStyle(
                              fontWeight: isGovSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                          children: [
                            ListTile(
                              dense: true,
                              title: Text(
                                isArabic ? 'كل $govName' : 'All $govName',
                              ),
                              trailing: isGovSelected && selectedCity == null
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: DealOneDesignColors.navy,
                                    )
                                  : null,
                              onTap: () {
                                ref
                                    .read(selectedGovernorateProvider.notifier)
                                    .state = gov;
                                ref.read(selectedCityProvider.notifier).state =
                                    null;
                                Navigator.of(context).pop();
                              },
                            ),
                            for (final city in gov.cities)
                              ListTile(
                                dense: true,
                                title: Text(
                                  isArabic ? city.nameAr : city.nameEn,
                                ),
                                trailing: selectedCity?.id == city.id
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: DealOneDesignColors.navy,
                                      )
                                    : null,
                                onTap: () {
                                  ref
                                      .read(
                                        selectedGovernorateProvider.notifier,
                                      )
                                      .state = gov;
                                  ref
                                      .read(selectedCityProvider.notifier)
                                      .state = city;
                                  Navigator.of(context).pop();
                                },
                              ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic
                              ? 'تعذر تحميل المحافظات'
                              : 'Failed to load locations',
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(governoratesProvider),
                          child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
