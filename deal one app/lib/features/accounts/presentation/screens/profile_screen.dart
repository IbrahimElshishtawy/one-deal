import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';
import 'package:market_space/features/quotas/presentation/providers/quotas_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final quotaAsync = ref.watch(myQuotaUsageProvider);
    final accountsAsync = ref.watch(myAccountsProvider);

    if (!session.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('حسابي')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle_outlined, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 16),
                const Text(
                  'سجّل الدخول للوصول إلى إعلاناتك والتواصل',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('تسجيل الدخول برقم الهاتف', style: TextStyle(fontSize: 16)),
                    onPressed: () => context.push(RouteNames.login),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي والملف الشخصي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User header card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, size: 36, color: Colors.blueAccent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المستخدم المسجل',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.userId ?? 'المعرف متوفر',
                          style: const TextStyle(color: Colors.grey),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'حصة التواصل اليومية (توقيت القاهرة)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  quotaAsync.when(
                    data: (quota) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: quota.limit > 0 ? (quota.used / quota.limit) : 0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            quota.isLimitReached ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'المتبقي اليوم: ${quota.remaining} من أصل ${quota.limit} كشوفات أرقام',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'تتجدد الحصة تلقائياً عند منتصف ليل كل يوم بتوقيت القاهرة.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const Text('تعذر تحميل معلومات الحصة اليومية'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Accounts / Organizations
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حسابات البيع والمعارض التابعة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  accountsAsync.when(
                    data: (accounts) {
                      if (accounts.isEmpty) {
                        return const Text('لا توجد حسابات معارض إضافية', style: TextStyle(color: Colors.grey));
                      }
                      return Column(
                        children: accounts.map((acc) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.store),
                            title: Text(acc.displayName),
                            subtitle: Text('الصفة: ${acc.role} • ${acc.isVerified ? "موثق" : "قيد المراجعة"}'),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                    error: (_, _) => const Text('تعذر تحميل الحسابات'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 16)),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.read(sessionProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}
