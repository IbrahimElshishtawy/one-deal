import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/categories/domain/entities/category_entity.dart';
import 'package:market_space/features/categories/presentation/providers/categories_providers.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/presentation/providers/listings_providers.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryTreeProvider);
    final feedAsync = ref.watch(listingsFeedProvider);
    final currentFilter = ref.watch(currentFeedFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_offer, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              'صفقة ون - Deal One',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(RouteNames.search),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.push(RouteNames.favorites),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(listingsFeedProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Horizontal categories bar
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (categories) => _CategorySelector(
                  categories: categories,
                  selectedSlug: currentFilter.categorySlug,
                  onSelect: (slug) {
                    ref.read(currentFeedFilterProvider.notifier).state =
                        FilterListingsDto(
                      categorySlug: slug == currentFilter.categorySlug ? null : slug,
                    );
                  },
                ),
                loading: () => const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

            // Feed items
            feedAsync.when(
              data: (feed) {
                if (feed.items.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('لا توجد إعلانات مطابقة حالياً', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = feed.items[index];
                        return _ListingCard(item: item);
                      },
                      childCount: feed.items.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('تعذر تحميل الإعلانات: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        onPressed: () => ref.invalidate(listingsFeedProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<CategoryItem> categories;
  final String? selectedSlug;
  final ValueChanged<String> onSelect;

  const _CategorySelector({
    required this.categories,
    required this.selectedSlug,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.slug == selectedSlug;
          return FilterChip(
            label: Text(cat.nameAr),
            selected: isSelected,
            onSelected: (_) => onSelect(cat.slug),
          );
        },
      ),
    );
  }
}

class _ListingCard extends ConsumerWidget {
  final ListingItem item;

  const _ListingCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesNotifier = ref.watch(favoritesProvider.notifier);
    final isFav = favoritesNotifier.isFavorited(item.id);

    return InkWell(
      onTap: () {
        context.push('/listings/${item.id}');
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image & Favorite button
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.primaryImageUrl != null && item.primaryImageUrl!.isNotEmpty
                      ? Image.network(
                          item.primaryImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.photo_outlined, size: 40, color: Colors.grey),
                        ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white70,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.black87,
                        ),
                        onPressed: () {
                          favoritesNotifier.toggleFavorite(item.id);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.price.toStringAsFixed(0)} ${item.currency}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          item.localizedLocation('ar'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
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
