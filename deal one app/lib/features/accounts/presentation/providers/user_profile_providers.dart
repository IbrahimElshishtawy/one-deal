import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/errors/app_exception.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/accounts/data/repositories/user_profile_repository_impl.dart';
import 'package:market_space/features/accounts/domain/entities/user_profile_entity.dart';
import 'package:market_space/features/accounts/domain/repositories/user_profile_repository.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserProfileRepositoryImpl(apiClient: apiClient);
});

final userProfileProvider = FutureProvider<UserProfileEntity>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isAuthenticated) {
    throw const UnauthorizedException(message: 'Not authenticated');
  }
  final repository = ref.watch(userProfileRepositoryProvider);
  final profile = await repository.getMyProfile();
  if (profile.fullName.isNotEmpty) {
    Future.microtask(() {
      ref.read(activeUserDisplayNameProvider.notifier).state = profile.fullName;
    });
  }
  return profile;
});

class EditProfileState {
  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final String? generalError;
  final bool isSuccess;

  const EditProfileState({
    this.isSubmitting = false,
    this.fieldErrors = const {},
    this.generalError,
    this.isSuccess = false,
  });

  EditProfileState copyWith({
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
    String? generalError,
    bool clearGeneralError = false,
    bool? isSuccess,
  }) {
    return EditProfileState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      generalError:
          clearGeneralError ? null : (generalError ?? this.generalError),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class EditProfileController extends StateNotifier<EditProfileState> {
  final Ref _ref;

  EditProfileController(this._ref) : super(const EditProfileState());

  Future<bool> submit(UpdateUserProfileInput input) async {
    state = state.copyWith(
      isSubmitting: true,
      fieldErrors: const {},
      clearGeneralError: true,
      isSuccess: false,
    );
    try {
      final repo = _ref.read(userProfileRepositoryProvider);
      final updated = await repo.updateMyProfile(input);
      if (updated.fullName.isNotEmpty) {
        _ref.read(activeUserDisplayNameProvider.notifier).state =
            updated.fullName;
      }
      _ref.invalidate(userProfileProvider);
      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } on ValidationException catch (e) {
      final parsed = <String, String>{};
      final rawDetails = e.details;
      if (rawDetails is Map) {
        final rawFields = rawDetails['fieldErrors'] is Map
            ? rawDetails['fieldErrors'] as Map
            : rawDetails;
        for (final entry in rawFields.entries) {
          final val = entry.value;
          if (val is List && val.isNotEmpty) {
            parsed[entry.key.toString()] = val.first.toString();
          } else if (val != null) {
            parsed[entry.key.toString()] = val.toString();
          }
        }
      }
      state = state.copyWith(
        isSubmitting: false,
        fieldErrors: parsed,
        generalError: parsed.isEmpty ? e.message : null,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        generalError: e.toString(),
      );
      return false;
    }
  }
}

final editProfileControllerProvider =
    StateNotifierProvider.autoDispose<EditProfileController, EditProfileState>(
  (ref) => EditProfileController(ref),
);
