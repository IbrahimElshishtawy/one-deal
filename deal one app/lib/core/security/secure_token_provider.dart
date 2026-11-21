import 'package:market_space/core/storage/secure_storage_service.dart';
import 'package:market_space/core/storage/storage_keys.dart';
import 'package:market_space/core/security/token_provider.dart';

class SecureTokenProvider implements TokenProvider {
  final SecureStorageService secureStorageService;

  SecureTokenProvider({required this.secureStorageService});

  @override
  Future<String?> getAccessToken() async {
    return secureStorageService.read(StorageKeys.accessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return secureStorageService.read(StorageKeys.refreshToken);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await secureStorageService.write(StorageKeys.accessToken, accessToken);
    await secureStorageService.write(StorageKeys.refreshToken, refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await secureStorageService.delete(StorageKeys.accessToken);
    await secureStorageService.delete(StorageKeys.refreshToken);
  }

  @override
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
