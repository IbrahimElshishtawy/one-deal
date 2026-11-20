import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/errors/error_presenter.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعلانات المفضلة')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(favoritesProvider.notifier).loadFavorites();
        },
        child: favoritesState.when(
          data: (favorites) {
            if (favorites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: AppColors.textMutedOf(context),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'لا توجد إعلانات مفضلة بعد',
                      style: TextStyle(fontSize: 16),
                    ),
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
                    child:
                        item.primaryImageUrl != null &&
                            item.primaryImageUrl!.isNotEmpty
                        ? Image.network(
                            item.primaryImageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.surfaceSecondaryOf(context),
                                  child: Icon(
                                    Icons.broken_image,
                                    color: AppColors.textMutedOf(context),
                                  ),
                                ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: AppColors.surfaceSecondaryOf(context),
                            child: Icon(
                              Icons.photo,
                              color: AppColors.textMutedOf(context),
                            ),
                          ),
                  ),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${item.price.toStringAsFixed(0)} ${item.currency}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOf(context),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: AppColors.errorOf(context),
                    ),
                    onPressed: () {
                      ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(item.id);
                    },
                  ),
                );
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (err, _) {
            final isArabic = Directionality.of(context) == TextDirection.rtl;
            final presented = ErrorPresenter.present(err, isArabic: isArabic);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.errorOf(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      presented.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      presented.message,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(favoritesProvider.notifier).loadFavorites(),
                      child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
