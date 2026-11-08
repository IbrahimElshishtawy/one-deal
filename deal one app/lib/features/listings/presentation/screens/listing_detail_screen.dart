import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/presentation/providers/listings_providers.dart';
import 'package:market_space/features/moderation/data/dto/report_dto.dart';
import 'package:market_space/features/moderation/data/repositories/reports_repository_impl.dart';
import 'package:market_space/core/providers/core_providers.dart';

class ListingDetailScreen extends ConsumerWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(listingDetailsFamily(listingId));

    return detailAsync.when(
      data: (item) => _DetailView(item: item),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الإعلان')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('تعذر تحميل تفاصيل الإعلان: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(listingDetailsFamily(listingId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailView extends ConsumerWidget {
  final ListingItem item;

  const _DetailView({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revealState = ref.watch(contactRevealProvider(item.id));
    final favoritesNotifier = ref.watch(favoritesProvider.notifier);
    final isFav = favoritesNotifier.isFavorited(item.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : null,
            ),
            onPressed: () => favoritesNotifier.toggleFavorite(item.id),
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'إبلاغ عن الإعلان',
            onPressed: () => _showReportDialog(context, ref, item.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Carousel
            if (item.media.isNotEmpty)
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: item.media.length,
                  itemBuilder: (context, index) {
                    final media = item.media[index];
                    return Image.network(
                      media.publicUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.photo, size: 60, color: Colors.grey)),
              ),

            // Main Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.price.toStringAsFixed(0)} ${item.currency}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      Chip(
                        label: Text(item.condition == 'NEW' ? 'جديد' : 'مستعمل'),
                        backgroundColor: Colors.blue.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(item.localizedLocation('ar'), style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      const Icon(Icons.visibility_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${item.viewsCount} مشاهدة', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 32),

                  // Description
                  const Text(
                    'الوصف',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const Divider(height: 32),

                  // Dynamic Attributes / Specs
                  if (item.attributes.isNotEmpty) ...[
                    const Text(
                      'المواصفات والخصائص',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.attributes.entries.map((entry) {
                        return Chip(
                          label: Text('${entry.key}: ${entry.value}'),
                          backgroundColor: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                    const Divider(height: 32),
                  ],

                  // Seller Profile
                  const Text(
                    'المعلن',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(item.sellerName.isNotEmpty ? item.sellerName[0] : 'S'),
                    ),
                    title: Text(item.sellerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.isVerified ? 'معلن موثق ✓' : 'حساب أفراد'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -3)),
            ],
          ),
          child: revealState.when(
            data: (contactResult) {
              if (contactResult != null) {
                // Contact is revealed
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.phone),
                        label: Text(contactResult.phone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () {},
                      ),
                    ),
                    if (contactResult.whatsappUrl != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                        icon: const Icon(Icons.chat),
                        onPressed: () {},
                      ),
                    ],
                  ],
                );
              }

              // Contact is protected / not revealed yet
              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.lock_open),
                label: const Text('إظهار رقم الهاتف والتواصل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ref.read(contactRevealProvider(item.id).notifier).reveal(item.id);
                },
              );
            },
            loading: () => const Center(
              heightFactor: 1.5,
              child: CircularProgressIndicator.adaptive(),
            ),
            error: (err, _) => Row(
              children: [
                Expanded(
                  child: Text(
                    'الحصة اليومية: $err',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(contactRevealProvider(item.id).notifier).reveal(item.id),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref, String listingId) {
    String selectedReason = 'scam';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('إبلاغ عن هذا الإعلان'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedReason,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'scam', child: Text('احتيال أو إعلان مضلل')),
                      DropdownMenuItem(value: 'inappropriate', child: Text('محتوى غير لائق')),
                      DropdownMenuItem(value: 'false_info', child: Text('معلومات غير صحيحة')),
                      DropdownMenuItem(value: 'duplicate', child: Text('إعلان مكرر')),
                      DropdownMenuItem(value: 'prohibited', child: Text('سلعة محظورة')),
                      DropdownMenuItem(value: 'other', child: Text('أسباب أخرى')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedReason = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'ملاحظات إضافية (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final apiClient = ref.read(apiClientProvider);
                    final repo = ReportsRepositoryImpl(apiClient: apiClient);
                    await repo.fileReport(CreateReportDto(
                      listingId: listingId,
                      reason: selectedReason,
                      notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                    ));
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم استلام البلاغ وسيقوم فريق المراجعة بفحصه')),
                      );
                    }
                  },
                  child: const Text('إرسال البلاغ'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
