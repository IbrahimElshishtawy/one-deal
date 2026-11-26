import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/seller_verification/application/notifiers/seller_verification_notifiers.dart';
import 'package:market_space/features/seller_verification/application/notifiers/seller_verification_wizard_notifier.dart';
import 'package:market_space/features/seller_verification/data/datasources/seller_verification_remote_datasource.dart';
import 'package:market_space/features/seller_verification/data/repositories/seller_verification_repository_impl.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/repositories/seller_verification_repository.dart';
import 'package:market_space/features/seller_verification/services/document_picker/document_picker_service.dart';
import 'package:market_space/features/seller_verification/services/document_upload/document_upload_service.dart';

/// Centralized remote datasource reusing the existing app-wide [apiClientProvider].
final sellerVerificationRemoteDataSourceProvider =
    Provider<SellerVerificationRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SellerVerificationRemoteDataSource(apiClient: apiClient);
});

/// Repository provider with hybrid cache for non-sensitive requirements.
final sellerVerificationRepositoryProvider =
    Provider<SellerVerificationRepository>((ref) {
  final remote = ref.watch(sellerVerificationRemoteDataSourceProvider);
  final cache = ref.watch(hybridCacheManagerProvider);
  return SellerVerificationRepositoryImpl(
    remoteDataSource: remote,
    cache: cache,
  );
});

/// Document picker service (camera / gallery / file).
final documentPickerServiceProvider = Provider<DocumentPickerService>((ref) {
  return const PlatformDocumentPickerService();
});

/// 3-step private document upload orchestrator.
final documentUploadServiceProvider = Provider<DocumentUploadService>((ref) {
  final repository = ref.watch(sellerVerificationRepositoryProvider);
  return DocumentUploadService(repository: repository);
});

// ============================================================================
// FEATURE STATE NOTIFIER PROVIDERS
// ============================================================================

final sellerOnboardingProvider =
    StateNotifierProvider<SellerOnboardingNotifier, SellerOnboardingState>(
  (ref) {
    final repository = ref.watch(sellerVerificationRepositoryProvider);
    return SellerOnboardingNotifier(repository: repository);
  },
);

final sellerTypeSelectionProvider = StateNotifierProvider<
    SellerTypeSelectionNotifier, SellerTypeSelectionState>(
  (ref) => SellerTypeSelectionNotifier(),
);

final sellerInformationProvider =
    StateNotifierProvider<SellerInformationNotifier, SellerInformationState>(
  (ref) {
    final repository = ref.watch(sellerVerificationRepositoryProvider);
    return SellerInformationNotifier(repository: repository);
  },
);

final verificationRequirementsProvider = StateNotifierProvider<
    VerificationRequirementsNotifier, VerificationRequirementsState>(
  (ref) {
    final repository = ref.watch(sellerVerificationRepositoryProvider);
    return VerificationRequirementsNotifier(repository: repository);
  },
);

final documentUploadProvider =
    StateNotifierProvider<DocumentUploadNotifier, DocumentUploadState>(
  (ref) {
    final picker = ref.watch(documentPickerServiceProvider);
    final upload = ref.watch(documentUploadServiceProvider);
    final repository = ref.watch(sellerVerificationRepositoryProvider);
    return DocumentUploadNotifier(
      pickerService: picker,
      uploadService: upload,
      repository: repository,
    );
  },
);

final verificationSubmissionProvider = StateNotifierProvider<
    VerificationSubmissionNotifier, VerificationSubmissionState>(
  (ref) {
    final repository = ref.watch(sellerVerificationRepositoryProvider);
    return VerificationSubmissionNotifier(repository: repository);
  },
);

final verificationTrackingProvider = StateNotifierProvider<
    VerificationTrackingNotifier, VerificationTrackingState>(
  (ref) {
    final repository = ref.watch(sellerVerificationRepositoryProvider);
    return VerificationTrackingNotifier(repository: repository);
  },
);

final businessUpgradeProvider =
    StateNotifierProvider<BusinessUpgradeNotifier, BusinessUpgradeState>(
  (ref) {
    final repository = ref.watch(sellerVerificationRepositoryProvider);
    return BusinessUpgradeNotifier(repository: repository);
  },
);

/// Authoritative live Seller Verification Badge provider for the authenticated user.
/// Always reflects server-side `verificationStatus`, `verificationTier`, and `verificationBadge`.
final sellerVerificationBadgeProvider =
    FutureProvider.autoDispose<VerificationStatusSnapshot?>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isAuthenticated) return null;
  final repository = ref.watch(sellerVerificationRepositoryProvider);
  return repository.getMyVerificationStatus(forceRefresh: true);
});

/// Provider powering the modular 3-step Seller Conversion & Verification Wizard.
final sellerVerificationWizardProvider = StateNotifierProvider.autoDispose<
    SellerVerificationWizardNotifier, SellerVerificationWizardState>(
  (ref) {
    final repository = ref.watch(sellerVerificationRepositoryProvider);
    final picker = ref.watch(documentPickerServiceProvider);
    final upload = ref.watch(documentUploadServiceProvider);
    return SellerVerificationWizardNotifier(
      repository: repository,
      pickerService: picker,
      uploadService: upload,
    );
  },
);
