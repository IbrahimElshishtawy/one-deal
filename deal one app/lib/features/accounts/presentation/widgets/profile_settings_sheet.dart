import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/providers/app_settings_providers.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/accounts/presentation/providers/user_profile_providers.dart';
import 'package:market_space/features/auth/presentation/l10n/auth_l10n_extension.dart';

/// Settings bottom sheet (Language, Theme, Notifications) preserving the
/// `profile_language_selector` key for accessibility and automated tests.
Future<void> showProfileSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DealOneTokens.cardSurfaceOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _ProfileSettingsSheetBody(),
  );
}

class _ProfileSettingsSheetBody extends ConsumerWidget {
  const _ProfileSettingsSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.authL10n;
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final currentMode = ref.watch(appThemeModeProvider);
    final currentLocale = ref.watch(appLocaleProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DealOneTokens.cardBorderOf(context),
                  borderRadius: AppRadii.full,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isArabic ? 'الإعدادات' : 'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.settingsThemeTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                selected: {currentMode},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    ref
                        .read(appThemeModeProvider.notifier)
                        .setThemeMode(selection.first);
                  }
                },
                segments: [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: const Icon(
                      Icons.settings_brightness_outlined,
                      size: 18,
                    ),
                    label: Text(l10n.settingsThemeSystem),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined, size: 18),
                    label: Text(l10n.settingsThemeLight),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined, size: 18),
                    label: Text(l10n.settingsThemeDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.settingsLanguageTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                key: const Key('profile_language_selector'),
                selected: {currentLocale.languageCode},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    ref
                        .read(appLocaleProvider.notifier)
                        .setLocale(Locale(selection.first));
                  }
                },
                segments: [
                  ButtonSegment<String>(
                    value: 'ar',
                    label: Text(l10n.settingsLanguageArabic),
                  ),
                  ButtonSegment<String>(
                    value: 'en',
                    label: Text(l10n.settingsLanguageEnglish),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to create a real Business / Seller account via `POST /accounts`.
Future<void> showCreateBusinessAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DealOneTokens.cardSurfaceOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _CreateBusinessAccountSheetBody(),
  );
}

class _CreateBusinessAccountSheetBody extends ConsumerStatefulWidget {
  const _CreateBusinessAccountSheetBody();

  @override
  ConsumerState<_CreateBusinessAccountSheetBody> createState() =>
      _CreateBusinessAccountSheetBodyState();
}

class _CreateBusinessAccountSheetBodyState
    extends ConsumerState<_CreateBusinessAccountSheetBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String _accountType = 'company';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(userProfileRepositoryProvider).createBusinessAccount(
            displayName: _nameCtrl.text,
            accountType: _accountType,
            bio: _bioCtrl.text,
          );
      ref.invalidate(myAccountsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        final isArabic = Directionality.of(context) == TextDirection.rtl;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم إنشاء الحساب التجاري بنجاح'
                  : 'Business account created successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DealOneTokens.cardBorderOf(context),
                    borderRadius: AppRadii.full,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isArabic ? 'إنشاء حساب تجاري' : 'Create Business Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText:
                      isArabic ? 'اسم النشاط أو الشركة' : 'Business Name',
                  filled: true,
                  fillColor: DealOneTokens.inputFillOf(context),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.md,
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => (val == null || val.trim().length < 2)
                    ? (isArabic ? 'يرجى إدخال اسم النشاط' : 'Enter a valid name')
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _accountType,
                decoration: InputDecoration(
                  labelText: isArabic ? 'نوع النشاط' : 'Account Type',
                  filled: true,
                  fillColor: DealOneTokens.inputFillOf(context),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.md,
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'company',
                    child: Text(isArabic ? 'شركة عقارية / مقاولات' : 'Company'),
                  ),
                  DropdownMenuItem(
                    value: 'office',
                    child: Text(isArabic ? 'مكتب عقاري / هندسي' : 'Office'),
                  ),
                  DropdownMenuItem(
                    value: 'store',
                    child: Text(isArabic ? 'متجر' : 'Store'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _accountType = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isArabic ? 'نبذة عن النشاط (اختياري)' : 'Bio',
                  filled: true,
                  fillColor: DealOneTokens.inputFillOf(context),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.md,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: DealOneTokens.dangerRed,
                    fontSize: 12.5,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealOneTokens.navy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isArabic ? 'إنشاء الحساب' : 'Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
