import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/app/app_router.dart';
import 'package:market_space/core/config/app_config.dart';
import 'package:market_space/core/config/environment.dart';
import 'package:market_space/core/logging/app_logger.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/network_info.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_guards.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/security/secure_token_provider.dart';
import 'package:market_space/core/security/session_state.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/secure_storage_service.dart';
import 'package:market_space/core/storage/storage_keys.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';

class _AlwaysConnectedNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream<bool>.empty();
}

typedef _StubResponder = ResponseBody Function(
  RequestOptions options,
  Map<String, dynamic>? jsonBody,
);

class _FakeHttpAdapter implements HttpClientAdapter {
  final Map<String, _StubResponder> handlers = {};
  final List<String> requestLog = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestLog.add('${options.method} ${options.path}');
    Map<String, dynamic>? jsonBody;
    if (options.data is Map) {
      jsonBody = Map<String, dynamic>.from(options.data as Map);
    }
    final key = '${options.method.toUpperCase()} ${options.path}';
    final handler = handlers[key];
    if (handler == null) {
      return _jsonResponse(404, {
        'success': false,
        'error': {'code': 'NOT_FOUND', 'message': 'No stub for $key'},
      });
    }
    return handler(options, jsonBody);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return ResponseBody.fromBytes(
    Uint8List.fromList(utf8.encode(jsonEncode(body))),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    },
  );
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void trigger() => notifyListeners();
}

void main() {
  late InMemoryPreferencesService prefs;
  late InMemorySecureStorageService secureStorage;
  late SecureTokenProvider tokens;
  late _FakeHttpAdapter httpAdapter;
  late AppConfig config;

  ProviderContainer makeIntegrationContainer({
    void Function()? onSessionExpired,
  }) {
    late ProviderContainer container;
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        networkInfoProvider.overrideWithValue(_AlwaysConnectedNetworkInfo()),
        preferencesServiceProvider.overrideWithValue(prefs),
        secureStorageServiceProvider.overrideWithValue(secureStorage),
        tokenProvider.overrideWithValue(tokens),
        otpAutoTimerEnabledProvider.overrideWithValue(false),
        apiClientProvider.overrideWith((ref) {
          final client = DioApiClient.create(
            appConfig: config,
            networkInfo: ref.read(networkInfoProvider),
            tokenProvider: tokens,
            logger: AppLoggerImpl(isLoggingEnabled: false),
            onSessionExpired: () {
              onSessionExpired?.call();
              ref.read(sessionProvider.notifier).logout();
            },
          );
          client.dio.httpClientAdapter = httpAdapter;
          return client;
        }),
        sessionValidatorProvider.overrideWith((ref) {
          final client = ref.watch(apiClientProvider);
          return () => validateSessionViaBackend(client);
        }),
      ],
    );
    return container;
  }

  setUp(() {
    prefs = InMemoryPreferencesService();
    secureStorage = InMemorySecureStorageService();
    tokens = SecureTokenProvider(secureStorageService: secureStorage);
    httpAdapter = _FakeHttpAdapter();
    config = const AppConfig(
      environment: AppEnvironment.staging,
      apiBaseUrl: 'https://one-deal-cjjt-production.up.railway.app/api/v1',
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 5),
      enableLogging: false,
      enableMockMode: false,
    );
  });

  group('Auth End-to-End Integration', () {
    test('Single-flight token refresh rotates tokens once across concurrent 401 calls and restores session', () async {
      await tokens.saveTokens(
        accessToken: 'expired_access',
        refreshToken: 'valid_refresh_1',
      );
      await secureStorage.write(StorageKeys.userId, 'usr_42');

      var refreshCalls = 0;
      httpAdapter.handlers['GET /users/me'] = (options, _) {
        final auth = options.headers['Authorization']?.toString() ?? '';
        if (auth == 'Bearer fresh_access_2') {
          return _jsonResponse(200, {
            'success': true,
            'data': {
              'id': 'usr_42',
              'phone': '+201012345678',
              'fullName': 'عمر حسن',
              'isPhoneVerified': true,
            },
          });
        }
        return _jsonResponse(401, {
          'success': false,
          'error': {'code': 'UNAUTHORIZED', 'message': 'Token expired'},
        });
      };

      httpAdapter.handlers['POST /auth/refresh'] = (_, body) {
        refreshCalls++;
        expect(body?['refreshToken'], 'valid_refresh_1');
        return _jsonResponse(200, {
          'success': true,
          'data': {
            'accessToken': 'fresh_access_2',
            'refreshToken': 'fresh_refresh_2',
            'expiresIn': 900,
            'tokenType': 'Bearer',
            'sessionId': 'sess_2',
          },
        });
      };

      final container = makeIntegrationContainer();
      addTearDown(container.dispose);

      final apiClient = container.read(apiClientProvider);

      final results = await Future.wait([
        apiClient.get('/users/me'),
        apiClient.get('/users/me'),
      ]);

      expect(results.length, 2);
      expect(refreshCalls, 1);
      expect(await tokens.getAccessToken(), 'fresh_access_2');
      expect(await tokens.getRefreshToken(), 'fresh_refresh_2');

      await container.read(sessionProvider.notifier).restoreSession();
      expect(
        container.read(sessionProvider).status,
        SessionStatus.authenticated,
      );
      expect(container.read(sessionProvider).userId, 'usr_42');
    });

    test('Invalid or reused refresh token clears secure storage and logs out session', () async {
      await tokens.saveTokens(
        accessToken: 'expired_access',
        refreshToken: 'reused_refresh',
      );
      await secureStorage.write(StorageKeys.userId, 'usr_42');

      httpAdapter.handlers['GET /users/me'] = (_, _) => _jsonResponse(401, {
        'success': false,
        'error': {'code': 'UNAUTHORIZED', 'message': 'Expired'},
      });
      httpAdapter.handlers['POST /auth/refresh'] = (_, _) =>
          _jsonResponse(401, {
            'success': false,
            'error': {
              'code': 'UNAUTHORIZED',
              'message': 'Security violation: Refresh token reuse detected.',
            },
          });

      final container = makeIntegrationContainer();
      addTearDown(container.dispose);

      await container.read(sessionProvider.notifier).restoreSession();

      expect(
        container.read(sessionProvider).status,
        SessionStatus.unauthenticated,
      );
      expect(await tokens.getAccessToken(), isNull);
      expect(await tokens.getRefreshToken(), isNull);
      expect(await secureStorage.read(StorageKeys.userId), isNull);
    });

    testWidgets(
      'Protected route guard redirects unauthenticated user to login, completes sign up + OTP + profile update, and unlocks guarded route',
      (tester) async {
        httpAdapter.handlers['POST /auth/otp/send'] = (_, body) {
          expectSync(body?['phone'], '+201099887766');
          return _jsonResponse(200, {
            'success': true,
            'data': {
              'success': true,
              'message':
                  'OTP verification code dispatched successfully via SMS.',
              'cooldownSeconds': 60,
            },
          });
        };

        httpAdapter.handlers['POST /auth/otp/verify'] = (_, body) {
          if (body?['code'] == '999999') {
            return _jsonResponse(400, {
              'success': false,
              'error': {
                'code': 'BAD_REQUEST',
                'message': 'Incorrect OTP code.',
              },
            });
          }
          expectSync(body?['code'], '123456');
          return _jsonResponse(200, {
            'success': true,
            'data': {
              'user': {
                'id': 'usr_new_1',
                'phone': '+201099887766',
                'fullName': 'مستخدم 7766',
                'role': 'USER',
                'isPhoneVerified': true,
              },
              'activeAccount': {
                'id': 'acc_new_1',
                'accountType': 'individual',
                'displayName': 'مستخدم 7766',
                'role': 'owner',
              },
              'tokens': {
                'accessToken': 'jwt_access_new',
                'refreshToken': 'opaque_refresh_new',
                'expiresIn': 900,
                'tokenType': 'Bearer',
                'sessionId': 'sess_new_1',
              },
            },
          });
        };

        httpAdapter.handlers['PUT /users/me'] = (options, body) {
          expectSync(options.headers['Authorization'], 'Bearer jwt_access_new');
          expectSync(body?['fullName'], 'كريم سامي');
          return _jsonResponse(200, {
            'success': true,
            'data': {
              'id': 'usr_new_1',
              'phone': '+201099887766',
              'fullName': 'كريم سامي',
              'isPhoneVerified': true,
            },
          });
        };

        httpAdapter.handlers['GET /users/me'] = (_, _) => _jsonResponse(200, {
          'success': true,
          'data': {
            'id': 'usr_new_1',
            'phone': '+201099887766',
            'fullName': 'كريم سامي',
            'isPhoneVerified': true,
          },
        });

        httpAdapter.handlers['POST /auth/logout'] = (_, body) {
          expectSync(body?['refreshToken'], 'opaque_refresh_new');
          return _jsonResponse(200, {
            'success': true,
            'data': {'success': true},
          });
        };

        final container = makeIntegrationContainer();
        addTearDown(container.dispose);

        final refreshNotifier = _RouterRefreshNotifier();
        addTearDown(refreshNotifier.dispose);

        container.listen(sessionProvider, (_, _) => refreshNotifier.trigger());

        final guard = SessionRouteGuard(
          tokenProvider: tokens,
          isAuthenticatedProvider: () =>
              container.read(sessionProvider).isAuthenticated,
        );

        final router = GoRouter(
          initialLocation: RouteNames.favorites,
          refreshListenable: refreshNotifier,
          redirect: (context, state) =>
              guard.evaluateRedirect(context, state.uri.toString()),
          routes: [
            GoRoute(
              path: RouteNames.root,
              builder: (_, _) => const Scaffold(body: Text('HOME_PAGE')),
            ),
            GoRoute(
              path: RouteNames.favorites,
              builder: (_, _) => Scaffold(
                body: Column(
                  children: [
                    const Text('FAVORITES_PAGE'),
                    Consumer(
                      builder: (_, ref, _) => ElevatedButton(
                        key: const Key('test_logout_button'),
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).logout(),
                        child: const Text('LOGOUT'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...AppRouter.createRouter().configuration.routes
                .whereType<GoRoute>()
                .where(
                  (r) =>
                      r.path == RouteNames.login ||
                      r.path == RouteNames.signUp ||
                      r.path == RouteNames.otpVerification ||
                      r.path == RouteNames.verificationSuccess ||
                      r.path == RouteNames.terms ||
                      r.path == RouteNames.privacy,
                ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              locale: const Locale('ar'),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('أهلاً بك مجدداً'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const Key('login_to_signup_button')),
        );
        await tester.tap(find.byKey(const Key('login_to_signup_button')));
        await tester.pumpAndSettle();
        expect(find.text('أنشئ حسابك في Deal One'), findsOneWidget);

        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('signup_fullname_field')),
            matching: find.byType(TextField),
          ),
          'كريم سامي',
        );
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('signup_phone_field')),
            matching: find.byType(TextField),
          ),
          '01099887766',
        );
        await tester.tap(find.byKey(const Key('signup_submit_button')));
        await tester.pumpAndSettle();

        expect(find.text('أدخل رمز التحقق'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('otp_hidden_input')),
          '999999',
        );
        await tester.pumpAndSettle();
        expect(
          find.text('رمز التحقق غير صحيح، يرجى التأكد وإعادة المحاولة'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('otp_retry_button')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('otp_hidden_input')),
          '123456',
        );
        await tester.pumpAndSettle();

        expect(find.text('تم التحقق بنجاح!'), findsOneWidget);
        expect(find.textContaining('كريم سامي'), findsOneWidget);
        expect(await tokens.getAccessToken(), 'jwt_access_new');
        expect(await tokens.getRefreshToken(), 'opaque_refresh_new');

        await tester.tap(
          find.byKey(const Key('verification_success_continue_button')),
        );
        await tester.pumpAndSettle();
        expect(find.text('FAVORITES_PAGE'), findsOneWidget);

        await tester.tap(find.byKey(const Key('test_logout_button')));
        await tester.pumpAndSettle();

        expect(await tokens.getAccessToken(), isNull);
        expect(
          container.read(sessionProvider).status,
          SessionStatus.unauthenticated,
        );
        expect(find.text('أهلاً بك مجدداً'), findsOneWidget);
      },
    );
  });
}
