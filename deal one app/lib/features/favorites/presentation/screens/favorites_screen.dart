import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعلانات المفضلة'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(favoritesProvider.notifier).loadFavorites();
        },
        child: favoritesState.when(
          data: (favorites) {
            if (favorites.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('لا توجد إعلانات مفضلة بعد', style: TextStyle(fontSize: 16)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: favorites.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final fav = favorites[index];
                final item = fav.listing;
                return ListTile(
                  onTap: () => context.push('/listings/${item.id}'),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.primaryImageUrl != null && item.primaryImageUrl!.isNotEmpty
                        ? Image.network(
                            item.primaryImageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.photo),
                          ),
                  ),
                  title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${item.price.toStringAsFixed(0)} ${item.currency}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      ref.read(favoritesProvider.notifier).toggleFavorite(item.id);
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('تعذر تحميل المفضلة: $err'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.read(favoritesProvider.notifier).loadFavorites(),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
