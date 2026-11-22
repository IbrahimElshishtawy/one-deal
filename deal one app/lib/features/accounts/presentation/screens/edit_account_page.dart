import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/accounts/domain/entities/user_profile_entity.dart';
import 'package:market_space/features/accounts/presentation/providers/user_profile_providers.dart';
import 'package:market_space/features/accounts/presentation/widgets/edit_account_avatar_section.dart';
import 'package:market_space/features/accounts/presentation/widgets/edit_account_form_card.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';

/// Edit Account Details Screen matching `Edit account details.png`.
/// Connected to `GET /users/me`, `PUT /users/me`, and `GET /locations/governorates`.
class EditAccountPage extends ConsumerStatefulWidget {
  const EditAccountPage({super.key});

  @override
  ConsumerState<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends ConsumerState<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _initialized = false;
  String? _avatarUrl;
  GovernorateEntity? _selectedGovernorate;
  CityEntity? _selectedCity;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _hydrateFromProfile(UserProfileEntity profile) {
    if (_initialized) return;
    _initialized = true;
    _fullNameController.text = profile.fullName;
    _emailController.text = profile.email ?? '';
    _avatarUrl = profile.avatarUrl;
    _selectedGovernorate = ref.read(selectedGovernorateProvider);
    _selectedCity = ref.read(selectedCityProvider);
  }

  Future<void> _showAvatarUrlDialog() async {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final urlCtrl = TextEditingController(text: _avatarUrl ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'تحديث الصورة الشخصية' : 'Update Profile Photo'),
        content: TextField(
          controller: urlCtrl,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'https://...',
            labelText: isArabic ? 'رابط الصورة (JPG / PNG)' : 'Image URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DealOneTokens.navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(urlCtrl.text.trim()),
            child: Text(isArabic ? 'تطبيق' : 'Apply'),
          ),
        ],
      ),
    );
    urlCtrl.dispose();
    if (result != null && mounted) {
      setState(() => _avatarUrl = result.isEmpty ? null : result);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final langCode = Localizations.localeOf(context).languageCode;

    final ok = await ref.read(editProfileControllerProvider.notifier).submit(
          UpdateUserProfileInput(
            fullName: _fullNameController.text.trim(),
            avatarUrl: _avatarUrl,
            preferredLanguage: langCode,
            governorateId: _selectedGovernorate?.id,
            cityId: _selectedCity?.id,
          ),
        );

    if (!mounted) return;

    if (ok) {
      ref.read(selectedGovernorateProvider.notifier).state =
          _selectedGovernorate;
      ref.read(selectedCityProvider.notifier).state = _selectedCity;

      final isArabic = Directionality.of(context) == TextDirection.rtl;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم حفظ التعديلات بنجاح'
                : 'Account details updated successfully',
          ),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final profileAsync = ref.watch(userProfileProvider);
    final governoratesAsync = ref.watch(governoratesProvider);
    final editState = ref.watch(editProfileControllerProvider);

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            DealOneSubPageHeader(
              title: isArabic ? 'تعديل بيانات الحساب' : 'Edit Account Details',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: profileAsync.when(
                loading: () => const DealOneLoadingList(
                  itemCount: 3,
                  itemHeight: 120,
                ),
                error: (err, _) => DealOneErrorStateView(
                  error: err,
                  onRetry: () => ref.invalidate(userProfileProvider),
                ),
                data: (profile) {
                  _hydrateFromProfile(profile);
                  final governorates = governoratesAsync.valueOrNull ?? const [];

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      AppSpacing.sm,
                      hPad,
                      AppSpacing.xxl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              EditAccountAvatarSection(
                                fullName: _fullNameController.text.isNotEmpty
                                    ? _fullNameController.text
                                    : profile.fullName,
                                avatarUrl: _avatarUrl,
                                onChangeAvatarTap: _showAvatarUrlDialog,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              EditAccountFormCard(
                                fullNameController: _fullNameController,
                                emailController: _emailController,
                                phoneNumber: profile.phone,
                                isPhoneVerified: profile.isPhoneVerified,
                                governorates: governorates,
                                selectedGovernorate: _selectedGovernorate,
                                selectedCity: _selectedCity,
                                fieldErrors: editState.fieldErrors,
                                onGovernorateChanged: (gov) {
                                  setState(() {
                                    _selectedGovernorate = gov;
                                    _selectedCity =
                                        (gov != null && gov.cities.isNotEmpty)
                                            ? gov.cities.first
                                            : null;
                                  });
                                },
                                onCityChanged: (city) {
                                  setState(() => _selectedCity = city);
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Encryption notice card matching PNG
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: DealOneTokens.softTileBgOf(context),
                                  borderRadius: AppRadii.lg,
                                  border: Border.all(
                                    color: DealOneTokens.cardBorderOf(context),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: DealOneTokens.cardSurfaceOf(
                                          context,
                                        ),
                                        borderRadius: AppRadii.md,
                                      ),
                                      child: Icon(
                                        Icons.shield_outlined,
                                        size: 20,
                                        color: DealOneTokens.textPrimaryOf(
                                          context,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isArabic
                                                ? 'بياناتك الشخصية مشفرة'
                                                : 'Your personal data is encrypted',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  DealOneTokens.textPrimaryOf(
                                                context,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            isArabic
                                                ? 'جميع معلومات الاتصال محمية تماماً وتخضع لسياسة الخصوصية وأمان المعاملات الخاصة بـ Deal One.'
                                                : 'All contact details are protected under Deal One privacy and security standards.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.45,
                                              color:
                                                  DealOneTokens.textSecondaryOf(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (editState.generalError != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: DealOneTokens.dangerSoftBg,
                                    borderRadius: AppRadii.md,
                                  ),
                                  child: Text(
                                    editState.generalError!,
                                    style: const TextStyle(
                                      color: DealOneTokens.dangerRed,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: AppSpacing.xl),

                              // Primary Save Button
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: DealOneTokens.buttonMinHeight,
                                ),
                                child: ElevatedButton.icon(
                                  key: const Key('edit_account_save_button'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: DealOneTokens.navy,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: AppRadii.md,
                                    ),
                                  ),
                                  onPressed: editState.isSubmitting
                                      ? null
                                      : _saveChanges,
                                  icon: editState.isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined, size: 20),
                                  label: Text(
                                    isArabic
                                        ? 'حفظ التعديلات'
                                        : 'Save Changes',
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // Cancel Text Button
                              TextButton(
                                onPressed: editState.isSubmitting
                                    ? null
                                    : () => Navigator.of(context).maybePop(),
                                child: Text(
                                  isArabic ? 'إلغاء والتراجع' : 'Cancel',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: DealOneTokens.textPrimaryOf(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
