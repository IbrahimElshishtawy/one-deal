import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/providers/app_settings_providers.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/auth/presentation/l10n/auth_l10n_extension.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';
import 'package:market_space/features/quotas/presentation/providers/quotas_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.authL10n;
    final session = ref.watch(sessionProvider);
    final quotaAsync = ref.watch(myQuotaUsageProvider);
    final accountsAsync = ref.watch(myAccountsProvider);

    if (!session.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitleGuest)),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 80,
                  color: AppColors.primaryOf(context),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.profileGuestHeadline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.login),
                    label: Text(
                      l10n.profileLoginWithPhone,
                      style: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () => context.push(RouteNames.login),
                  ),
                ),
                const SizedBox(height: 24),
                const _ThemeModeCard(),
                const SizedBox(height: 12),
                const _LanguageSelectorCard(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitleAuth)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User header card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.surfaceSecondaryOf(context),
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: AppColors.primaryOf(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileRegisteredUser,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.userId ?? l10n.profileIdAvailable,
                          style: TextStyle(
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Daily Quota Card (Cairo Timezone)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.successOf(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.profileDailyQuotaTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  quotaAsync.when(
                    data: (quota) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: quota.limit > 0
                              ? (quota.used / quota.limit)
                              : 0,
                          backgroundColor: AppColors.surfaceSecondaryOf(
                            context,
                          ),
                          valueColor: AlwaysStoppedAnimation(
                            quota.isLimitReached
                                ? AppColors.errorOf(context)
                                : AppColors.successOf(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.profileDailyQuotaRemaining(
                            quota.remaining,
                            quota.limit,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.profileDailyQuotaNote,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => Text(l10n.profileDailyQuotaError),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Accounts / Organizations
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileAccountsTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  accountsAsync.when(
                    data: (accounts) {
                      if (accounts.isEmpty) {
                        return Text(
                          l10n.profileAccountsEmpty,
                          style: TextStyle(
                            color: AppColors.textMutedOf(context),
                          ),
                        );
                      }
                      return Column(
                        children: accounts.map((acc) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.store),
                            title: Text(acc.displayName),
                            subtitle: Text(
                              l10n.profileRoleLabel(
                                acc.role,
                                acc.isVerified
                                    ? l10n.profileVerified
                                    : l10n.profileUnderReview,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                    error: (_, _) => Text(l10n.profileAccountsError),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const _ThemeModeCard(),
          const SizedBox(height: 12),
          const _LanguageSelectorCard(),
          const SizedBox(height: 24),

          // Logout Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorOf(context),
              side: BorderSide(color: AppColors.errorOf(context)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout),
            label: Text(
              l10n.profileLogout,
              style: const TextStyle(fontSize: 16),
            ),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeModeCard extends ConsumerWidget {
  const _ThemeModeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.authL10n;
    final currentMode = ref.watch(appThemeModeProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.brightness_6_outlined,
                  size: 20,
                  color: AppColors.primaryOf(context),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.settingsThemeTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
}

class _LanguageSelectorCard extends ConsumerWidget {
  const _LanguageSelectorCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.authL10n;
    final currentLocale = ref.watch(appLocaleProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 20,
                  color: AppColors.primaryOf(context),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.settingsLanguageTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
