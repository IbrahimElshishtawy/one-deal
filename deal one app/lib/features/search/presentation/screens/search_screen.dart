import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/features/search/presentation/providers/search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchResultsProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'ابحث عن سيارات، عقارات، أجهزة...',
            border: InputBorder.none,
            suffixIcon: currentQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            ref.read(searchQueryProvider.notifier).state = val;
          },
        ),
      ),
      body: currentQuery.trim().isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('اكتب كلمة البحث للبدء', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : searchAsync.when(
              data: (result) {
                if (result.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('لا توجد نتائج لـ "${result.query}"', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: result.items.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = result.items[index];
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
                        '${item.price.toStringAsFixed(0)} ${item.currency} • ${item.localizedLocation('ar')}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.chevron_left),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator.adaptive()),
              error: (err, _) => Center(
                child: Text('خطأ في البحث: $err'),
              ),
            ),
    );
  }
}
