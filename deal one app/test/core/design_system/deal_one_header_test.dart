import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/design_system/deal_one_header.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/security/session_state.dart';
import 'package:market_space/features/accounts/domain/entities/user_profile_entity.dart';
import 'package:market_space/features/accounts/domain/repositories/user_profile_repository.dart';
import 'package:market_space/features/accounts/presentation/providers/user_profile_providers.dart';

class _FakeSessionNotifier extends SessionNotifier {
  final SessionState initial;

  _FakeSessionNotifier(this.initial);

  @override
  SessionState build() => initial;
}

class _FakeUserProfileRepository implements UserProfileRepository {
  Future<UserProfileEntity> Function() onGetMyProfile;

  _FakeUserProfileRepository(this.onGetMyProfile);

  @override
  Future<UserProfileEntity> getMyProfile() => onGetMyProfile();

  @override
  Future<UserProfileEntity> updateMyProfile(UpdateUserProfileInput input) {
    throw UnimplementedError();
  }

  @override
  Future<void> createBusinessAccount({
    required String displayName,
    required String accountType,
    String? bio,
  }) {
    throw UnimplementedError();
  }
}

Widget _wrapHeader({
  required List<Override> overrides,
  TextDirection textDirection = TextDirection.rtl,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Directionality(
        textDirection: textDirection,
        child: const Scaffold(
          body: SafeArea(
            child: DealOneHomeHeader(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('DealOneHomeHeader user verification & loading', () {
    testWidgets('shows loading indicator while verifying user, then displays verified name', (
      tester,
    ) async {
      final completer = Completer<UserProfileEntity>();
      final fakeRepo = _FakeUserProfileRepository(() => completer.future);

      await tester.pumpWidget(
        _wrapHeader(
          overrides: [
            sessionProvider.overrideWith(
              () => _FakeSessionNotifier(
                const SessionState.authenticated(userId: 'user-1'),
              ),
            ),
            userProfileRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );

      // While GET /users/me is in-flight, the top bar shows the loading state.
      await tester.pump();
      expect(find.byKey(const Key('header_user_name_loading')), findsOneWidget);
      expect(find.byKey(const Key('header_user_name_text')), findsNothing);

      // Complete verification with the real logged-in user profile.
      completer.complete(
        const UserProfileEntity(
          id: 'user-1',
          phone: '+201012345678',
          fullName: 'إبراهيم الششتاوي',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('header_user_name_loading')), findsNothing);
      expect(find.byKey(const Key('header_user_name_text')), findsOneWidget);
      expect(find.text('إبراهيم الششتاوي'), findsOneWidget);
    });

    testWidgets('shows retry control when verification fails and reloads on tap', (
      tester,
    ) async {
      var attempt = 0;
      final fakeRepo = _FakeUserProfileRepository(() async {
        attempt++;
        if (attempt == 1) {
          throw Exception('Network error');
        }
        return const UserProfileEntity(
          id: 'user-2',
          phone: '+201099999999',
          fullName: 'أحمد محمود',
        );
      });

      await tester.pumpWidget(
        _wrapHeader(
          overrides: [
            sessionProvider.overrideWith(
              () => _FakeSessionNotifier(
                const SessionState.authenticated(userId: 'user-2'),
              ),
            ),
            userProfileRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('header_user_name_retry')), findsOneWidget);

      await tester.tap(find.byKey(const Key('header_user_name_retry')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('header_user_name_retry')), findsNothing);
      expect(find.text('أحمد محمود'), findsOneWidget);
      expect(attempt, 2);
    });

    testWidgets('shows guest greeting when unauthenticated and ignores stale cached name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapHeader(
          overrides: [
            sessionProvider.overrideWith(
              () => _FakeSessionNotifier(const SessionState.unauthenticated()),
            ),
            activeUserDisplayNameProvider.overrideWith((ref) => 'اسم قديم'),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('header_user_name_loading')), findsNothing);
      expect(find.text('مرحباً بك'), findsOneWidget);
      expect(find.text('اسم قديم'), findsNothing);
    });
  });
}
