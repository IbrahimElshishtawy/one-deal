import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/media/data/repositories/media_repository_impl.dart';
import 'package:market_space/features/media/domain/repositories/media_repository.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MediaRepositoryImpl(apiClient: apiClient);
});
