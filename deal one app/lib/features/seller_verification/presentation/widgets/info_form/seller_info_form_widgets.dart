import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';

class SellerInformationHeader extends StatelessWidget {
  final SellerType sellerType;

  const SellerInformationHeader({super.key, required this.sellerType});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.sellerInfoTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${s.sellerTypeLabel(sellerType)} — ${s.sellerInfoSubtitle}',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: DealOneTokens.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }
}

class _VerificationTextField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final String? errorText;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _VerificationTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.initialValue,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14.5,
        color: DealOneTokens.textPrimaryOf(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: DealOneTokens.inputFillOf(context),
        border: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: BorderSide(color: DealOneTokens.cardBorderOf(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: BorderSide(color: DealOneTokens.cardBorderOf(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: BorderSide(
            color: AppColors.isDark(context)
                ? DealOneTokens.amberWarm
                : DealOneTokens.navy,
            width: 1.6,
          ),
        ),
      ),
    );
  }
}

class SellerNameField extends StatelessWidget {
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const SellerNameField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return _VerificationTextField(
      key: const Key('field_seller_full_name'),
      label: s.fullNameLabel,
      initialValue: value,
      errorText: errorText,
      icon: Icons.person_outline_rounded,
      onChanged: onChanged,
    );
  }
}

class BusinessNameField extends StatelessWidget {
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const BusinessNameField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return _VerificationTextField(
      key: const Key('field_business_name'),
      label: s.businessNameLabel,
      initialValue: value,
      errorText: errorText,
      icon: Icons.business_outlined,
      onChanged: onChanged,
    );
  }
}

class NationalIdField extends StatelessWidget {
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const NationalIdField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return _VerificationTextField(
      key: const Key('field_national_id'),
      label: s.nationalIdLabel,
      initialValue: value,
      errorText: errorText,
      icon: Icons.badge_outlined,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }
}

class CommercialRegisterField extends StatelessWidget {
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const CommercialRegisterField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return _VerificationTextField(
      key: const Key('field_commercial_register'),
      label: s.commercialRegisterLabel,
      initialValue: value,
      errorText: errorText,
      icon: Icons.description_outlined,
      onChanged: onChanged,
    );
  }
}

class TaxIdField extends StatelessWidget {
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const TaxIdField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return _VerificationTextField(
      key: const Key('field_tax_id'),
      label: s.taxIdLabel,
      initialValue: value,
      errorText: errorText,
      icon: Icons.receipt_long_outlined,
      onChanged: onChanged,
    );
  }
}

class ContactPersonField extends StatelessWidget {
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const ContactPersonField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return _VerificationTextField(
      key: const Key('field_contact_person'),
      label: s.contactPersonLabel,
      initialValue: value,
      errorText: errorText,
      icon: Icons.supervisor_account_outlined,
      onChanged: onChanged,
    );
  }
}

class SellerPhoneField extends StatelessWidget {
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const SellerPhoneField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return _VerificationTextField(
      key: const Key('field_seller_phone'),
      label: s.phoneLabel,
      initialValue: value,
      errorText: errorText,
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      onChanged: onChanged,
    );
  }
}

class SellerEmailField extends StatelessWidget {
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const SellerEmailField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return _VerificationTextField(
      key: const Key('field_seller_email'),
      label: s.emailLabel,
      initialValue: value,
      errorText: errorText,
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      onChanged: onChanged,
    );
  }
}

class SellerAddressField extends StatelessWidget {
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const SellerAddressField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return _VerificationTextField(
      key: const Key('field_seller_address'),
      label: s.addressLabel,
      initialValue: value,
      errorText: errorText,
      icon: Icons.location_on_outlined,
      maxLines: 2,
      onChanged: onChanged,
    );
  }
}

class GovernorateSelector extends StatelessWidget {
  final List<GovernorateEntity> governorates;
  final int? selectedGovernorateId;
  final ValueChanged<int?> onChanged;

  const GovernorateSelector({
    super.key,
    required this.governorates,
    required this.selectedGovernorateId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final validSelection = governorates.any((g) => g.id == selectedGovernorateId)
        ? selectedGovernorateId
        : null;

    return DropdownButtonFormField<int>(
      initialValue: validSelection,
      decoration: InputDecoration(
        labelText: s.governorateLabel,
        prefixIcon: const Icon(Icons.map_outlined, size: 20),
        filled: true,
        fillColor: DealOneTokens.inputFillOf(context),
        border: OutlineInputBorder(borderRadius: AppRadii.md),
      ),
      items: governorates
          .map(
            (g) => DropdownMenuItem<int>(
              value: g.id,
              child: Text(s.isArabic ? g.nameAr : g.nameEn),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class CitySelector extends StatelessWidget {
  final List<CityEntity> cities;
  final int? selectedCityId;
  final ValueChanged<int?> onChanged;

  const CitySelector({
    super.key,
    required this.cities,
    required this.selectedCityId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final validSelection =
        cities.any((c) => c.id == selectedCityId) ? selectedCityId : null;

    return DropdownButtonFormField<int>(
      initialValue: validSelection,
      decoration: InputDecoration(
        labelText: s.cityLabel,
        prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
        filled: true,
        fillColor: DealOneTokens.inputFillOf(context),
        border: OutlineInputBorder(borderRadius: AppRadii.md),
      ),
      items: cities
          .map(
            (c) => DropdownMenuItem<int>(
              value: c.id,
              child: Text(s.isArabic ? c.nameAr : c.nameEn),
            ),
          )
          .toList(growable: false),
      onChanged: cities.isEmpty ? null : onChanged,
    );
  }
}

class BusinessActivitySelector extends StatelessWidget {
  final List<String> selectedSections;
  final ValueChanged<String> onToggle;

  const BusinessActivitySelector({
    super.key,
    required this.selectedSections,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final activeBg = AppColors.isDark(context)
        ? DealOneTokens.amberWarm
        : DealOneTokens.navy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.activityLabel,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: MarketplaceSectionSlug.values.map((section) {
            final isSelected = selectedSections.contains(section.apiValue);
            return FilterChip(
              label: Text(
                s.sectionLabel(section),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? (AppColors.isDark(context)
                          ? AppColors.darkOnPrimary
                          : Colors.white)
                      : DealOneTokens.textPrimaryOf(context),
                ),
              ),
              selected: isSelected,
              selectedColor: activeBg,
              backgroundColor: DealOneTokens.softTileBgOf(context),
              checkmarkColor: AppColors.isDark(context)
                  ? AppColors.darkOnPrimary
                  : Colors.white,
              onSelected: (_) => onToggle(section.apiValue),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}
