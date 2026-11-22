import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';

/// Account details form card matching `Edit account details.png`:
/// Full name, verified phone display, optional email, and governorate/city dropdowns.
class EditAccountFormCard extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final String phoneNumber;
  final bool isPhoneVerified;
  final List<GovernorateEntity> governorates;
  final GovernorateEntity? selectedGovernorate;
  final CityEntity? selectedCity;
  final ValueChanged<GovernorateEntity?> onGovernorateChanged;
  final ValueChanged<CityEntity?> onCityChanged;
  final Map<String, String> fieldErrors;

  const EditAccountFormCard({
    super.key,
    required this.fullNameController,
    required this.emailController,
    required this.phoneNumber,
    required this.isPhoneVerified,
    required this.governorates,
    required this.selectedGovernorate,
    required this.selectedCity,
    required this.onGovernorateChanged,
    required this.onCityChanged,
    this.fieldErrors = const {},
  });

  String _formatLocalPhone(String raw) {
    final cleaned = raw.trim();
    if (cleaned.startsWith('+20')) {
      return cleaned.substring(3).trim();
    }
    if (cleaned.startsWith('20') && cleaned.length > 10) {
      return cleaned.substring(2).trim();
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final langCode = isArabic ? 'ar' : 'en';
    final cities = selectedGovernorate?.cities ?? const <CityEntity>[];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: DealOneTokens.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Full Name
          _FieldLabel(
            label: isArabic ? 'الاسم الكامل' : 'Full Name',
            requiredField: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: const Key('edit_account_fullname_field'),
            controller: fullNameController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              context,
              hint: isArabic ? 'أدخل اسمك الكامل' : 'Enter your full name',
              prefixIcon: Icons.manage_accounts_outlined,
              errorText: fieldErrors['fullName'],
            ),
            validator: (val) {
              final trimmed = val?.trim() ?? '';
              if (trimmed.isEmpty) {
                return isArabic
                    ? 'الاسم الكامل مطلوب'
                    : 'Full name is required';
              }
              if (trimmed.length < 2) {
                return isArabic
                    ? 'الاسم يجب أن يكون حرفين على الأقل'
                    : 'Name must be at least 2 characters';
              }
              if (trimmed.length > 120) {
                return isArabic
                    ? 'الاسم طويل جداً (الحد الأقصى 120 حرف)'
                    : 'Name cannot exceed 120 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Phone Number (Verified / Read-only)
          _FieldLabel(
            label: isArabic ? 'رقم الجوال' : 'Phone Number',
            requiredField: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: DealOneTokens.inputFillOf(context),
              borderRadius: AppRadii.md,
              border: Border.all(color: DealOneTokens.cardBorderOf(context)),
            ),
            child: Row(
              children: [
                Text(
                  '🇪🇬 +20',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      phoneNumber.isNotEmpty
                          ? _formatLocalPhone(phoneNumber)
                          : '---',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ),
                if (isPhoneVerified) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: DealOneTokens.softTileBgOf(context),
                      borderRadius: AppRadii.full,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: DealOneTokens.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isArabic ? 'تم التحقق' : 'Verified',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Email (Optional)
          _FieldLabel(
            label: isArabic ? 'البريد الإلكتروني' : 'Email Address',
            optionalTag: isArabic ? '(اختياري)' : '(Optional)',
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: const Key('edit_account_email_field'),
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration(
              context,
              hint: isArabic ? 'أدخل بريدك الإلكتروني' : 'Enter your email',
              prefixIcon: Icons.mark_email_read_outlined,
              errorText: fieldErrors['email'],
            ),
            validator: (val) {
              final trimmed = val?.trim() ?? '';
              if (trimmed.isEmpty) return null;
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(trimmed)) {
                return isArabic
                    ? 'صيغة البريد الإلكتروني غير صحيحة'
                    : 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // 4. Geographic Location Section
          Text(
            isArabic ? 'الموقع الجغرافي والإقامة' : 'Location & Residence',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'يساعدنا تحديد موقعك في تقديم ترشيحات عقارية ومواعيد معاينة أكثر دقة.'
                : 'Setting your location helps us recommend nearby properties and viewing slots.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LayoutBuilder(
            builder: (context, constraints) {
              final stackLocation = constraints.maxWidth < 300 ||
                  context.effectiveTextScale >= 1.5;

              final govDropdown = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(label: isArabic ? 'المحافظة' : 'Governorate'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: selectedGovernorate?.id,
                    isExpanded: true,
                    decoration: _dropdownDecoration(
                      context,
                      prefixIcon: Icons.location_on_rounded,
                    ),
                    hint: Text(isArabic ? 'اختر المحافظة' : 'Governorate'),
                    items: governorates
                        .map(
                          (g) => DropdownMenuItem<int>(
                            value: g.id,
                            child: Text(
                              g.localizedName(langCode),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) {
                        onGovernorateChanged(null);
                        return;
                      }
                      final found = governorates.firstWhere((g) => g.id == id);
                      onGovernorateChanged(found);
                    },
                  ),
                ],
              );

              final cityDropdown = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(
                    label: isArabic ? 'المدينة / المنطقة' : 'City / Area',
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue:
                        cities.any((c) => c.id == selectedCity?.id)
                            ? selectedCity?.id
                            : null,
                    isExpanded: true,
                    decoration: _dropdownDecoration(
                      context,
                      prefixIcon: Icons.near_me_outlined,
                    ),
                    hint: Text(isArabic ? 'اختر المدينة' : 'City'),
                    items: cities
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(
                              c.localizedName(langCode),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: cities.isEmpty
                        ? null
                        : (id) {
                            if (id == null) {
                              onCityChanged(null);
                              return;
                            }
                            final found = cities.firstWhere((c) => c.id == id);
                            onCityChanged(found);
                          },
                  ),
                ],
              );

              if (stackLocation) {
                return Column(
                  children: [
                    govDropdown,
                    const SizedBox(height: AppSpacing.md),
                    cityDropdown,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: govDropdown),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cityDropdown),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData prefixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: DealOneTokens.inputFillOf(context),
      prefixIcon: Icon(
        prefixIcon,
        size: 20,
        color: DealOneTokens.textPrimaryOf(context),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadii.md,
        borderSide: BorderSide(color: DealOneTokens.cardBorderOf(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.md,
        borderSide: BorderSide(color: DealOneTokens.cardBorderOf(context)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadii.md,
        borderSide: BorderSide(color: DealOneTokens.navy, width: 1.5),
      ),
    );
  }

  InputDecoration _dropdownDecoration(
    BuildContext context, {
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: DealOneTokens.inputFillOf(context),
      prefixIcon: Icon(
        prefixIcon,
        size: 18,
        color: DealOneTokens.textPrimaryOf(context),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: AppRadii.md,
        borderSide: BorderSide(color: DealOneTokens.cardBorderOf(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.md,
        borderSide: BorderSide(color: DealOneTokens.cardBorderOf(context)),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool requiredField;
  final String? optionalTag;

  const _FieldLabel({
    required this.label,
    this.requiredField = false,
    this.optionalTag,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
        ),
        if (requiredField)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: DealOneTokens.amber,
            ),
          ),
        if (optionalTag != null) ...[
          const SizedBox(width: 4),
          Text(
            optionalTag!,
            style: TextStyle(
              fontSize: 12,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
        ],
      ],
    );
  }
}
