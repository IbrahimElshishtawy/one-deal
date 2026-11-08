# DEAL ONE — Flutter Mobile Re-Foundation & API Integration
## Master AI Execution Prompt / Engineering Specification

**Document type:** Executable implementation brief  
**Project:** Deal One Flutter Mobile Application  
**Workspace (verify before use):** `/home/ibrahim-elshishtawy/flutter project/market_space`  
**Production API base:** `https://one-deal-cjjt-production.up.railway.app/api/v1`  
**State management:** Riverpod 2 only  
**Architecture:** Feature-First + Clean Architecture + Repository Pattern  
**Networking:** Dio through one centrally configured API client  
**Caching:** Hybrid — memory + persistent disk + server as source of truth  
**Backend modification policy:** STRICT READ-ONLY / NO BACKEND CHANGES  
**Execution mode:** Phased, evidence-driven, test-gated; no skipping phases

---

# PART A — MASTER INSTRUCTIONS TO THE AI AGENT

You are acting as a coordinated senior engineering team consisting of:

1. Principal Flutter Architect.
2. Senior Dart/Flutter Engineer.
3. API Integration Engineer.
4. Application Security Engineer.
5. Performance and Scalability Engineer.
6. QA / Test Automation Engineer.
7. Technical Documentation Engineer.
8. Independent Reviewer who challenges the implementation and verifies evidence.

Your task is to re-establish the Deal One Flutter mobile application from its current actual state. The previous mobile screens and selected foundation folders have been deleted by the project owner. Do not assume the old source tree still exists. Do not recreate an obsolete architecture merely because old documentation describes it.

The owner has explicitly approved these decisions:

- **Riverpod 2** is the only state-management and dependency-injection solution.
- Integrate **all applicable V1 backend API modules**, not only authentication or one sample feature.
- Use **hybrid caching**: in-memory cache, persistent disk cache where justified, and server revalidation.
- Build and verify the mobile foundation before implementing the product screens.
- The backend is deployed and must be treated as an external, read-only system.
- The initial product ambition is approximately **2 million listings/products and 100,000 customers in year one**. This is a client-side design target, not proof that the backend or hosting can currently sustain that load.

## A1. Absolute scope boundaries

### Allowed
- Inspect the entire repository, Git history, Flutter project, backend source, backend docs, OpenAPI/Swagger, deployment docs, tests, and public production API responses.
- Run safe read-only HTTP requests against documented public/health endpoints.
- Generate mobile-only source files, tests, assets, and mobile documentation.
- Change Flutter dependencies and Flutter platform configuration when justified and verified.
- Create local mock fixtures strictly for tests and explicitly marked development fallback.
- Add API contract tests and integration tests without changing the server.
- Create reports documenting backend gaps and request owner decisions.

### Forbidden
**Do not edit, generate, migrate, seed, format, refactor, or deploy anything in the backend.**
Do not change:
- `backend/**` source files.
- Prisma schema or migrations.
- SQL files or database data.
- Backend environment variables or secrets.
- Railway settings, deployment configuration, domains, services, or variables.
- Redis, PostgreSQL, queues, workers, Cloudflare, R2, WAF, DNS, or server-side feature flags.
- Backend OpenAPI source files.
- Backend tests or backend documentation, unless the owner separately authorizes it.

Do not run backend write commands such as database migrations, seeds, schema pushes, deployment commands, or scripts that mutate remote state. Do not use production POST/PUT/PATCH/DELETE requests during discovery. A documented read-only GET is not permission to probe arbitrary resources.

If a backend defect blocks mobile integration:
1. Record the exact endpoint, request, response/status, timestamp, and impact.
2. Do not silently work around a security defect.
3. Do not alter the backend.
4. Use a safe, explicitly approved client behavior only if it does not weaken security or misrepresent server state.
5. Mark the affected feature BLOCKED or PARTIAL and report the required backend action separately.

### Critical security stop condition
If production public feeds expose personal phone numbers or other private PII, the mobile app must not display, log, cache, analytics-track, or otherwise expose those values. Do not treat a client-side mask as a complete security fix. The API must be verified to return appropriately redacted data. If it does not, report a release blocker and do not build a UI that displays the exposed field. The mobile client cannot repair a server-side data-leak vulnerability.

## A2. Non-negotiable engineering rules

1. Inspect before implementing. Never guess the repository root, Flutter app root, package name, SDK version, route paths, response JSON, or auth flow.
2. Existing docs are evidence to compare with source, not unquestionable truth. Newer source and verified runtime behavior take precedence; discrepancies must be documented.
3. Never invent API endpoints, fields, enum values, token names, pagination keys, status codes, or request bodies.
4. Do not write a fake implementation and call it integrated.
5. No hardcoded secrets, tokens, credentials, private keys, production test accounts, or sensitive personal data.
6. No tokens in logs, crash reports, analytics, URLs, screenshots, test snapshots, or plain preferences.
7. No broad catch-and-ignore. Errors must remain observable and typed.
8. No `dynamic` across application boundaries unless the JSON decoder requires it temporarily and the value is validated immediately.
9. No business logic in widgets.
10. No direct Dio calls from screens or widgets.
11. No feature may instantiate its own independent Dio client.
12. No global mutable singleton state outside controlled dependency registration.
13. No unbounded in-memory collections, unbounded request concurrency, or eager loading of the full catalog.
14. No automatic retries for non-idempotent operations unless the backend contract explicitly supports idempotency.
15. No offline mutation queue unless the backend supports safe idempotency/conflict semantics and the design is documented.
16. No `setState` for app-wide/server state. Local ephemeral widget state is allowed.
17. No mixing Riverpod with Provider, GetX, Bloc/Cubit, Redux, or another state-management framework.
18. Keep domain entities independent from Flutter, Dio, JSON, storage, and Riverpod.
19. Every phase must finish with evidence, tests, a report, and an explicit gate decision.
20. Do not proceed past a failed or blocked gate. Do not claim completion based only on generated files.

---

# PART B — PROJECT DISCOVERY AND BASELINE

## PHASE 00 — Repository, Flutter App and Backend Read-Only Audit

### Objective
Establish the exact current state of the repository and distinguish the Flutter app from the backend and documentation. The owner has deleted old mobile folders/screens, but the exact remaining structure must be discovered.

### Required inspection

#### 00.1 Repository identity and Git safety
- Confirm current working directory.
- Find the Git root.
- Inspect `git status --short --branch`.
- Inspect recent commits and current branch.
- Inspect `.gitignore`.
- Identify uncommitted user changes.
- Do not reset, clean, stash, checkout, rebase, or overwrite user work.
- Identify nested Flutter/backend directories.
- Confirm which directory is the actual Flutter package root by locating `pubspec.yaml`.

#### 00.2 Flutter project inventory
Inspect:
- `pubspec.yaml` and `pubspec.lock`.
- `lib/`, `test/`, `integration_test/`, `assets/`.
- `android/`, `ios/`, `web/` if present, and other supported platform folders.
- `analysis_options.yaml`.
- `l10n.yaml` and localization resources if present.
- app icons, fonts, native permissions, flavors, build configuration.
- existing generated files and code-generation setup.
- CI/CD configuration.
- existing tests and test fixtures.
- dependency versions and dependency constraints.
- Flutter and Dart versions actually installed in the environment.

Record:
- Flutter version.
- Dart version.
- package name.
- app display name.
- application identifiers per platform.
- minimum Android/iOS deployment targets.
- current build/analyze/test status.
- current dependency health.
- exact folders/files deleted or absent, based on current filesystem and Git evidence.

Do not upgrade Flutter or major dependencies merely because newer versions exist. Keep the project's compatible SDK and dependency constraints unless a verified incompatibility requires a change.

#### 00.3 Product and business-domain audit
Read the project's actual product documentation, especially:
- `mock_data/` Markdown documentation.
- `backend_blueprint/` and ADRs.
- root project status and changelog documents.
- any `docs/mobile-system-design/` documents that still exist.
- V1 scope and exclusions.
- category and dynamic-attribute definitions.
- account, team, branch, moderation, listing, search, favorites, media, location and quota behavior.
- current navigation and user journeys if documented.

Preserve the agreed Deal One V1 direction:
- Hybrid marketplace: listings/advertisements now; commerce/booking capabilities later where approved.
- V1 does not implement checkout/orders/online payments unless an explicit newer approved decision says otherwise.
- Main verticals include real estate, building materials/electricity, home and engineering services, home appliances and décor, cars, clothes and accessories.
- Trust, listing quality, account verification, chat, location, moderation and secure contact reveal are important product concerns.
- Do not infer that `account.verified` means a particular verification workflow; verify the actual contract and document its meaning.

#### 00.4 Backend read-only audit
Inspect the backend source and docs without editing them:
- `BACKEND_PROJECT_STATUS.md`.
- Backend implementation changelog/status reports.
- `backend_blueprint/` architecture and ADRs.
- backend `package.json` and module registration.
- controllers, route decorators, DTOs, serializers, guards, interceptors and response envelopes.
- Prisma schema only for understanding public domain/API shapes; never modify.
- backend tests and OpenAPI/Swagger generation.
- deployment guide and Railway configuration docs.
- security audit reports and known unresolved findings.

Compare docs against source and deployed behavior. Mark every finding as:
- VERIFIED IN SOURCE.
- VERIFIED IN PRODUCTION.
- DOCUMENTED BUT NOT VERIFIED.
- MISMATCH.
- NOT IMPLEMENTED.
- BLOCKED / INACCESSIBLE.

Do not assume that an earlier report still describes the latest deployed build.

#### 00.5 Existing mobile design docs
If the old `docs/mobile-system-design/` files or copies are available, inspect all relevant documents, especially:
- Mobile System Overview.
- Flutter Project Structure.
- Application Modules.
- Navigation and User Flows.
- State Management and Data Flow.
- API Integration Design.
- Local Data and Caching.
- UI/UX Design System.
- Authentication and Security.
- Mobile Architecture Audit.
- Consolidated Mobile System Design.

Important: previous documentation may describe a former `ValueNotifier` / custom dependency-scope implementation. The new approved decision is Riverpod 2. Do not carry over the old state-management architecture. Extract reusable product rules and verified API facts only.

### Deliverables
Create mobile-only documentation under a clear path such as `docs/mobile-rebuild/`:
1. `00_REPOSITORY_AND_BASELINE_AUDIT.md`
2. `01_PRODUCT_AND_V1_SCOPE.md`
3. `02_BACKEND_API_DISCOVERY.md`
4. `03_EXISTING_DOCUMENTATION_RECONCILIATION.md`
5. `BLOCKERS_AND_OWNER_DECISIONS.md`

### Gate 00 — PASS criteria
- Actual Flutter root is identified.
- Git changes are preserved.
- Flutter baseline commands have been run and results recorded.
- Product scope and V1 exclusions are documented.
- Backend source and deployed API are distinguished.
- API discovery limitations are explicit.
- Known security blockers are listed.
- No backend file or remote state was changed.

If the API cannot be inspected, do not invent contracts. Continue only with backend-independent foundation tasks and mark API-dependent work BLOCKED.

---

# PART C — API CONTRACT DISCOVERY

## PHASE 01 — Production API and OpenAPI Contract Verification

### Objective
Build a complete, evidence-backed inventory of every applicable V1 API operation before implementing repositories.

### 01.1 Discover API documentation safely
Start from repository configuration and backend docs. Determine the actual Swagger/OpenAPI route from source/configuration; do not guess that `/api/docs`, `/docs`, `/openapi.json`, or the API base path is correct.

Check:
- documented OpenAPI JSON/YAML file.
- Swagger UI route, if enabled.
- API global prefix.
- version prefix.
- health/liveness/readiness endpoints.
- authentication requirements for docs.
- environment-specific base URL behavior.

The production base URL supplied by the owner is:
`https://one-deal-cjjt-production.up.railway.app/api/v1`

The root of this base URL may legitimately return 404 if no root controller exists. That alone does not establish API failure. Discover valid routes from the source/OpenAPI contract and verify safe read-only routes.

### 01.2 Endpoint inventory
For every API operation record:

| Field | Required evidence |
|---|---|
| Module | Backend module/controller |
| Operation ID | OpenAPI or source |
| Method | Exact HTTP method |
| Path | Exact path including version prefix |
| Authentication | Public / access token / role / permission |
| Request | Query/path/header/body schema |
| Response | Exact status and schema |
| Error responses | Exact documented envelope/status |
| Pagination | Offset/cursor/none and exact fields |
| Filtering | Exact supported filters |
| Sorting | Exact supported sort keys |
| Rate limit | Documented/verified/unknown |
| Idempotency | Required/optional/not supported/unknown |
| Upload behavior | If applicable |
| Production verification | Verified / not verified / blocked |
| Mobile priority | V1 required / optional / excluded |

Do not use a generic `Map<String, dynamic>` response as a substitute for a missing contract.

### 01.3 Required module discovery
Discover all applicable V1 modules from actual backend source and OpenAPI, including where implemented:

- Health / readiness (diagnostics only; no sensitive data).
- Authentication and phone OTP.
- Access token / refresh / logout / session endpoints.
- Accounts and profile.
- Account verification status and onboarding.
- Team members, roles, permissions and invitations.
- Branches / account locations if applicable.
- Categories and category fields / dynamic attributes.
- Listings: create, read, update, delete, publish/unpublish, status and ownership operations as supported.
- Search and listing feeds.
- Locations / cities / districts / map/radius filters.
- Favorites.
- Media upload initiation, upload confirmation, attachment, deletion or other supported lifecycle.
- Contact reveal and daily quota endpoints.
- Notifications if actually implemented.
- Chat if actually implemented and in V1.
- Reporting / moderation if user-facing and authorized.
- Any other V1 module discovered in source and docs.

Do not assume every module in this list exists. Mark absent endpoints as NOT IMPLEMENTED and do not fabricate a mobile service for them.

### 01.4 API behavior verification
For each safe public GET:
- Verify production status code.
- Verify content type.
- Verify response envelope.
- Verify schema shape.
- Verify empty-state behavior.
- Verify pagination metadata.
- Verify cache headers / ETag / Last-Modified if present.
- Verify rate-limit headers if present.
- Verify error envelope using safe invalid read-only query/path only where it cannot mutate data.
- Verify that private fields are not exposed in public results.

Never send OTP, create accounts, upload files, reveal contact details, create/update/delete listings, change favorites, invite members, or trigger any mutation in production during discovery unless the owner separately authorizes a controlled test account and test plan.

### 01.5 Contract registry
Create a machine-readable registry where useful, but do not duplicate the entire OpenAPI spec blindly. Each implemented operation must trace back to a source contract.

Deliver:
- `04_API_ENDPOINT_INVENTORY.md`
- `05_API_CONTRACT_GAPS.md`
- `api_contracts/` with versioned mobile contract snapshots or schemas where appropriate.
- `api_contracts/README.md` explaining source, date, version and regeneration procedure.

### Gate 01 — PASS criteria
- All backend V1 modules have been reviewed.
- All applicable API operations have inventory entries.
- Exact request/response/error schemas are known for operations to be implemented.
- Production verification state is clearly marked.
- Unknowns are not disguised as facts.
- No mutating production request was made.
- All security blockers have a release impact assessment.

---

# PART D — TARGET MOBILE ARCHITECTURE

## PHASE 02 — Architecture Design and Dependency Decisions

### Objective
Design a small, understandable, testable architecture that scales by feature without creating unnecessary abstractions.

### 02.1 Architecture principles
Use:
- Feature-First modular organization.
- Clean Architecture where it provides real boundaries.
- Repository Pattern.
- Dependency inversion.
- Riverpod 2 for state management and dependency injection.
- Dio for HTTP.
- Typed DTOs and explicit mappers.
- Domain entities independent of Flutter and infrastructure.
- Centralized configuration, errors, security and networking.
- Explicit data ownership and cache policies.

Avoid:
- One giant `core` folder containing business features.
- A use case class for every trivial getter if it adds no value.
- Generic base repositories with dozens of type parameters.
- Service locator plus Riverpod duplication.
- Global mutable state.
- Deep inheritance trees.
- Over-engineered event buses.
- Unnecessary micro-packages inside a single app.

### 02.2 Proposed directory structure
Adapt this after Phase 00; do not create folders blindly.

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/
│   ├── providers/
│   └── lifecycle/
│
├── bootstrap/
│   ├── bootstrap.dart
│   ├── app_environment.dart
│   └── app_initializer.dart
│
├── core/
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   │   ├── client/
│   │   ├── interceptors/
│   │   ├── endpoints/
│   │   ├── transformers/
│   │   └── connectivity/
│   ├── security/
│   │   ├── token_storage/
│   │   ├── token_manager/
│   │   └── session/
│   ├── storage/
│   ├── cache/
│   ├── pagination/
│   ├── performance/
│   ├── logging/
│   └── utils/
│
├── shared/
│   ├── widgets/
│   ├── theme/
│   ├── localization/
│   └── extensions/
│
└── features/
    ├── auth/
    ├── account/
    ├── home/
    ├── categories/
    ├── listings/
    ├── search/
    ├── locations/
    ├── favorites/
    ├── media/
    ├── contact_reveal/
    ├── notifications/   # only if API exists
    ├── chat/            # only if API exists and is V1
    ├── real_estate/
    ├── building_materials/
    ├── home_services/
    ├── home_appliances/
    ├── cars/
    └── fashion/
```

A feature may use:

```text
feature_name/
├── data/
│   ├── datasources/
│   ├── dto/
│   ├── mappers/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers/
    ├── controllers/
    ├── pages/
    └── widgets/
```

Use this full split for complex business modules. For simple infrastructure-adjacent features, a lighter structure is acceptable if responsibilities remain explicit.

### 02.3 Dependency direction
Allowed:
- Presentation → Domain.
- Data → Domain.
- Composition root / Riverpod providers → concrete implementations.
- Core infrastructure may be injected into data sources.

Forbidden:
- Domain → Flutter, Dio, JSON serialization, storage, Riverpod.
- Domain entities importing DTOs.
- Widgets importing Dio or token storage.
- One feature reaching into another feature's private data implementation.
- Core importing feature-specific business rules.

### 02.4 Feature boundaries
Keep generic listings infrastructure reusable, but category-specific rules remain in the relevant feature/domain configuration. Avoid six duplicated listing engines. Avoid one universal screen with dozens of category-specific booleans.

### Deliverables
- `06_MOBILE_ARCHITECTURE_DECISIONS.md`
- `07_DEPENDENCY_GRAPH.md`
- `08_TARGET_FOLDER_STRUCTURE.md`
- `09_RIVERPOD_CONVENTIONS.md`
- `10_NAMING_AND_CODE_STYLE.md`

### Gate 02
Architecture reviewed against real API contracts, V1 scope, performance and security. No implementation starts until the dependency direction and module boundaries are clear.

---

# PART E — FOUNDATION IMPLEMENTATION

## PHASE 03 — Flutter App Foundation and Bootstrap

### Objective
Create the minimal app skeleton and deterministic startup sequence.

### Tasks
1. Preserve package identity, signing setup, platform identifiers and user-owned native configuration.
2. Reconcile `pubspec.yaml` with the actual installed Flutter/Dart SDK.
3. Add only justified dependencies.
4. Configure lint rules and formatting.
5. Set up environment configuration for development, staging and production without committing secrets.
6. Define base URL selection by build flavor/configuration.
7. Ensure production base URL is HTTPS.
8. Configure app initialization order.
9. Initialize Flutter bindings and required plugins safely.
10. Initialize secure storage, cache stores and logging only as needed.
11. Initialize ProviderScope and Riverpod overrides for tests/flavors.
12. Configure app lifecycle hooks for session/cache behavior.
13. Ensure startup errors are surfaced safely.
14. Add an app-level error boundary / FlutterError and PlatformDispatcher handlers with privacy-safe reporting.
15. Keep startup work minimal; defer noncritical work.
16. Ensure initialization can be tested and does not create hidden network requests.

### Required startup behavior
- A failure in a noncritical analytics/cache warm-up must not prevent app launch.
- A missing or invalid production configuration must fail safely, not silently point to localhost.
- No secret is embedded in the binary as if it were confidential. Mobile app API keys are public identifiers, not secrets.
- No API call should run before its dependencies and environment are ready.
- No token refresh should be triggered by startup probes unnecessarily.

### Tests
- Bootstrap order test.
- Environment selection tests.
- Missing/invalid base URL tests.
- Startup failure handling.
- ProviderScope setup test.
- App smoke test.

### Gate 03
`flutter analyze`, `flutter test`, and a debug build pass. No backend changes.

---

## PHASE 04 — Riverpod 2 State Management and Dependency Injection

### Objective
Adopt Riverpod 2 consistently and make state ownership predictable.

### Rules
- Use `flutter_riverpod` and the Riverpod 2 API compatible with the project's SDK.
- Use `Provider` for immutable dependencies.
- Use `Notifier` for synchronous mutable state.
- Use `AsyncNotifier` for asynchronous state with lifecycle and loading/error/data semantics.
- Use `FutureProvider` / `StreamProvider` only when they express the use case clearly.
- Use `family` for parameterized state such as listing details, category fields, or search filters.
- Use `autoDispose` where lifecycle should be bounded; do not apply it blindly to session/global caches.
- Use `select` to reduce unnecessary rebuilds.
- Use `ref.watch` for declarative dependencies and `ref.read` for event actions.
- Use `ref.listen` for one-off side effects and navigation/snackbar effects, not for deriving ordinary UI state.
- Do not keep `Ref` in long-lived domain objects.
- Do not expose mutable internal collections.
- Do not create provider cycles.
- Avoid reading providers from global variables or outside ProviderScope.

### State modeling
Every asynchronous feature state must distinguish:
- Initial / not requested.
- Loading.
- Data (including legitimate empty data).
- Error (typed and recoverable where possible).
- Refreshing / loading-more where relevant.
- Pagination exhausted.
- Offline/stale data where relevant.

Do not encode every state as nullable data plus booleans that can contradict each other.

### Provider organization
- Keep providers close to their owning feature or in a clearly defined composition file.
- Centralize infrastructure providers in `core` only when shared.
- Inject repository interfaces into controllers/providers.
- Use ProviderScope overrides for deterministic unit tests.
- Keep navigation side effects out of repositories.

### Tests
- Provider unit tests.
- AsyncNotifier loading/data/error tests.
- Family isolation tests.
- Disposal/lifecycle tests.
- Dependency override tests.
- No unexpected network access in unit tests.

### Gate 04
No competing state-management framework; provider ownership and lifetimes documented; test suite passes.

---

## PHASE 05 — Core Networking and Dio API Client

### Objective
Create one robust, centrally configured HTTP stack that all feature repositories use.

### 05.1 Dio configuration
Configure:
- Base URL from validated environment config.
- Connect timeout.
- Send timeout.
- Receive timeout.
- Response type and content-type handling.
- JSON transformer behavior.
- Redirect policy where justified.
- Connection reuse through Dio's adapter.
- User-Agent/app version headers where appropriate.
- Request ID / correlation ID if contract supports it.
- Locale header only if backend supports it.
- Safe default headers.
- Per-request cancellation.
- Typed request options.

Do not select arbitrary timeout/retry numbers without documenting the trade-off. Use reasonable defaults and make them centrally configurable.

### 05.2 Interceptor responsibilities
Implement separate, ordered interceptors as needed:
1. Request metadata / correlation.
2. Authentication.
3. Safe logging (development only, redacted).
4. Error normalization only if not better handled at repository boundary.

Interceptor order must be documented and tested.

### 05.3 Authentication concurrency
The auth interceptor must:
- Attach a valid access token only to the correct API origin.
- Never send tokens to arbitrary absolute URLs or third-party upload hosts.
- Detect the exact backend unauthorized response semantics.
- Exclude auth/refresh endpoints from recursive refresh.
- Coordinate concurrent 401 responses through a single refresh operation.
- Queue or await other failed requests safely.
- Retry each eligible original request at most once after successful refresh.
- Avoid replaying unsafe non-idempotent requests unless server idempotency semantics explicitly allow it.
- Clear session and emit a signed-out state if refresh is invalid/revoked/expired.
- Avoid refresh storms and infinite loops.
- Handle app termination during refresh safely.
- Avoid exposing token values in exceptions or logs.

If refresh token rotation exists, persist the new token pair atomically enough to avoid using a stale refresh token after a partial write. Document storage limitations and recovery behavior.

### 05.4 Request cancellation and concurrency
- Support CancelToken or the current Dio cancellation mechanism.
- Search query changes cancel obsolete requests.
- Disposed screens should not continue expensive work unnecessarily.
- Avoid duplicate identical in-flight GETs where safe.
- Bound concurrent image/media/network operations.
- Do not cancel a shared request while another consumer still depends on it unless request coalescing tracks subscribers.

### 05.5 Retry policy
Retry only transient failures and only when safe:
- connection errors/timeouts for idempotent requests.
- selected 5xx responses if policy and contract permit.
- 429 only respecting `Retry-After` / server guidance.
- exponential backoff with jitter and maximum attempts.
- no retry loops.
- no retry on validation, auth, permission, or not-found errors.
- no automatic replay of OTP, listing creation, upload confirmation, favorites mutation, contact reveal or other non-idempotent actions unless explicit idempotency support is verified.

### 05.6 Error normalization
Create typed failures such as:
- NetworkUnavailable.
- ConnectionTimeout.
- SendTimeout.
- ReceiveTimeout.
- Unauthorized.
- Forbidden.
- NotFound.
- ValidationFailure with field-level errors.
- RateLimited with retry metadata.
- Conflict.
- ServerFailure.
- ParsingFailure.
- Cancelled.
- UnknownFailure.

Map exact backend error envelope to typed failures. Preserve a safe diagnostic code and request ID where available. Never expose stack traces, SQL errors, internal server messages, secrets or raw response bodies to end users.

### 05.7 Logging
- Debug logging must be disabled or tightly restricted in release.
- Redact Authorization, cookies, OTP, phone, email, address, tokens, upload signatures and personal data.
- Never log full request/response bodies by default.
- Do not log signed upload URLs.
- Use a central logger with severity and safe metadata.
- Avoid leaking sensitive values in Crashlytics/analytics breadcrumbs.

### Tests
- Base URL and headers.
- Interceptor ordering.
- Token attach only to trusted host.
- Redaction tests.
- 401 refresh single-flight test with concurrent requests.
- Refresh failure and session clearing.
- Retry eligibility and retry limit.
- Cancellation.
- 429 handling.
- Parsing/error mapping.
- No recursive refresh.
- No unsafe mutation replay.

### Gate 05
All feature networking goes through the same configured client; critical interceptor and auth concurrency tests pass.

---

# PART F — SECURITY AND SESSION

## PHASE 06 — Secure Storage, Authentication and Session Lifecycle

### Objective
Implement authentication only from verified backend contracts.

### 06.1 Token storage
- Use platform-backed secure storage (Android Keystore / iOS Keychain via a maintained package).
- Store only the tokens and minimal session metadata required.
- Never store tokens in SharedPreferences, Hive, SQLite, plain files or cache.
- Do not store passwords or OTP values.
- Do not store secrets in source, assets or build-time public defines.
- Handle secure storage read/write errors.
- Define logout cleanup and token rotation behavior.
- Do not claim secure deletion guarantees beyond platform APIs.

### 06.2 OTP flow
Only implement exact backend-supported steps:
- request OTP.
- resend OTP if supported.
- verify OTP.
- onboarding/account completion if required.
- token/session response.
- rate-limit and cooldown behavior.
- generic user-facing errors that do not reveal whether an account/phone exists, if backend policy requires it.

Never invent OTP length, expiry, retry limits, cooldowns, phone format or request payload. Derive them from verified backend contracts.

### 06.3 Session state
Model:
- Unknown / checking.
- Unauthenticated.
- Authenticated.
- Expired / revoked.
- Logging out if useful.

Do not treat a locally stored token as proof that the server session remains valid. Restore locally, then rely on protected API behavior or a documented session endpoint. Avoid unnecessary blocking startup calls.

### 06.4 Logout
- Clear local tokens and user-specific sensitive caches.
- Cancel authenticated in-flight requests where practical.
- Reset user-scoped providers.
- Clear private cached data.
- Call backend logout/revocation only if documented and safe.
- Ensure logout still clears local state if server is unavailable.
- Avoid clearing public cache unnecessarily.

### 06.5 Account authorization
- Client-side role/permission checks are for UX only.
- Backend remains authoritative.
- Never rely on hidden buttons or client checks as security.
- Handle 403 distinctly from 401.
- Verify ownership and team role behavior from API responses.
- Do not infer verification meaning from a boolean name alone.

### 06.6 Privacy and sensitive data
- Mask phone/email/address in UI where product rules require.
- Public listing responses must not be assumed safe until verified.
- Contact reveal must call the exact authorized endpoint and obey server quota.
- Do not cache revealed contact data beyond the minimum needed; prefer no persistent cache.
- Do not put PII in route URLs, logs, analytics or crash breadcrumbs.
- Apply data minimization to local persistence.

### 06.7 Platform security
Review Android/iOS:
- cleartext traffic disabled for production.
- network security config.
- backup behavior for sensitive app data.
- screenshot/app-switcher privacy for sensitive screens where justified.
- biometric support only if explicitly in product scope; do not add it as a substitute for server authentication.
- permissions requested only when the feature needs them.
- deep links validated against allowlisted schemes/hosts and route parameters.
- clipboard behavior and OTP autofill permissions.
- app transport security and minimum platform settings.

Do not implement certificate pinning casually. If considered, document rotation/failure risks, operational ownership and a recovery strategy. Do not ship pinning without a reliable certificate rotation process.

### Tests
- secure storage abstraction tests.
- token persistence/rotation.
- logout cleanup.
- 401 vs 403.
- expired/revoked session.
- no PII/token logging.
- contact reveal privacy.
- deep-link validation.
- platform manifest/config review.

### Gate 06
Auth behavior matches verified backend contract; no secrets or PII leakage in tests/logs; known backend privacy blockers remain explicit.

---

# PART G — DATA LAYER AND ALL V1 API MODULES

## PHASE 07 — Typed Contracts, DTOs, Mappers and Repositories

### Objective
Implement every applicable V1 module discovered in Phase 01, not every imagined module.

### 07.1 DTO policy
- DTOs represent exact wire contracts.
- Use generated serialization only if generation is reliable and fits the project.
- Use explicit nullable/required semantics.
- Handle unknown enum values safely without crashing.
- Parse dates, numeric values and IDs explicitly.
- Do not silently coerce invalid values to zero/empty strings.
- Do not assume backend returns the same shape for list and detail.
- Support optional dynamic category attributes with validation.
- Add contract fixtures based on verified responses (sanitize PII).
- Keep backward compatibility strategy documented.

### 07.2 Domain entities
Entities must express business concepts, not API implementation details. Avoid carrying raw JSON maps into domain/UI. Model dynamic attributes safely using a typed value representation or validated value object.

### 07.3 Mappers
- Map DTO to entity in one explicit location.
- Handle unknown fields safely.
- Keep mapping deterministic and unit-tested.
- Do not put mapping logic inside widgets/providers.
- Record incompatible contract changes clearly.

### 07.4 Repository contract
Each repository:
- exposes domain-level methods.
- hides Dio and storage.
- returns typed result/failure.
- handles remote/local coordination.
- applies cache policy explicitly.
- supports cancellation/pagination where needed.
- does not swallow errors.
- is testable with fake data sources.

### 07.5 Module-by-module implementation
Build an endpoint-to-code traceability matrix for every V1 module. At minimum evaluate:

**Identity & Auth**
- OTP request/verify/resend if supported.
- session refresh/logout.
- profile/current account.

**Accounts**
- profile/account details.
- onboarding/verification status.
- team members, invitation, removal, role/permission display.
- branches and account context if supported.

**Categories**
- category tree/list.
- category details.
- dynamic category fields.
- category slug/ID behavior.
- caching and invalidation.

**Listings**
- feeds/listing query.
- listing detail.
- create/update/delete if V1 permits.
- publication/moderation/availability state as exposed.
- ownership and edit permissions.
- media association.
- dynamic attributes.
- category-specific presentation mapping.

**Search**
- query.
- filters.
- sorting.
- pagination.
- location/radius if supported.
- Arabic normalization behavior (server-side contract must be respected).
- cancellation and debounce.

**Locations**
- city/district/location metadata.
- coordinates and radius semantics.
- permissions and privacy.
- do not request device location until the user invokes a feature that needs it.

**Favorites**
- list.
- add/remove.
- server synchronization.
- optimistic UI only if rollback and conflict behavior are defined.

**Media**
- upload intent/presigned URL if supported.
- direct upload to storage host if required.
- upload confirmation.
- attachment to listing.
- deletion if supported.
- file type/size limits from backend contract.
- signed URL handling and expiry.
- progress and cancellation.
- do not send backend bearer token to a third-party storage host unless the contract explicitly requires it.

**Contact reveal / quotas**
- reveal endpoint.
- quota state.
- cooldown/limit behavior.
- no contact value in logs/cache.
- never assume client-side quota counters are authoritative.

**Notifications / chat / moderation / reports**
- integrate only when the API exists, V1 scope includes it, and auth/permissions are clear.
- document unsupported capabilities rather than faking them.

### 07.6 V1 vs V2 exclusion
Do not build payment checkout, order fulfillment, commerce transactions, booking payments, or Cloudflare Stream/video publishing just because related backend code or draft docs exist. Confirm approved V1 scope. Read-only listing media/image upload may be supported; video upload/streaming is not automatically in scope.

### Gate 07
Every implemented repository method traces to a verified API operation and has DTO, mapper, repository, error and tests. Unsupported endpoints are clearly marked and not simulated as production functionality.

---

# PART H — HYBRID CACHING AND PERFORMANCE

## PHASE 08 — Cache Architecture

### Objective
Improve responsiveness without displaying stale/private data incorrectly or exhausting memory/storage.

### 08.1 Cache layers
**Memory cache**
- short-lived in-memory objects for frequently revisited data.
- bounded size and eviction policy.
- avoid duplicate copies of large lists.
- cache keys include relevant filters, sort, category, locale and account scope where applicable.

**Disk cache**
- persist only data with a justified offline/fast-reopen benefit.
- use a maintained local storage/database package selected after audit.
- define schema/version/migration strategy for the local cache.
- encrypt sensitive persisted data when required; do not persist tokens here.
- keep cache storage separate from secure token storage.
- bound disk usage and evict by policy.
- clear user-scoped cache on logout/account switch.

**Server**
- authoritative for account permissions, listing state, quotas, favorites synchronization, moderation and contact reveal.
- respect server cache headers if present.
- never assume local cached authorization is current.

### 08.2 Cache policy matrix
Create a table for each data type:
- public category metadata.
- public listing feed.
- listing detail.
- search result.
- location metadata.
- user profile.
- favorites.
- quota.
- contact reveal.
- team/branch data.
- media metadata.

Specify:
- memory TTL.
- disk TTL.
- stale-while-revalidate allowed?
- offline fallback allowed?
- invalidation events.
- user-scoped or public.
- sensitive data classification.

Do not invent TTLs. Propose defaults, explain trade-offs, and configure centrally. Short-lived authorization-sensitive data should be revalidated.

### 08.3 Cache correctness
- Cache keys must include all query-affecting values.
- Do not mix user A and user B cache entries.
- Invalidate after listing create/update/delete/moderation changes.
- Invalidate favorites after mutation.
- Invalidate account/team cache after role changes.
- Clear private cache on logout.
- Handle account switching.
- Avoid cache stampedes with in-flight request coalescing.
- Use ETag/If-None-Match only if server supports it.
- Handle clock skew and expired data safely.

### 08.4 Offline behavior
- Read-only cached content may be shown with a clear stale/offline indication.
- Do not pretend an offline write succeeded.
- Do not queue writes unless backend idempotency and conflict handling are verified.
- Explain retry behavior to the user.
- Never use cached data to authorize an action.

### 08.5 Images and media
- Use a maintained image cache solution with bounded disk/memory cache.
- Use thumbnails/resized variants if backend/CDN provides them.
- Avoid downloading original multi-megabyte images for small cards.
- Define placeholders, errors and retry behavior.
- Avoid decoding many full-resolution images simultaneously.
- Use appropriate image dimensions/cacheWidth/cacheHeight.
- Avoid excessive prefetching.
- Do not cache expiring signed URLs as permanent media identity.
- Keep image loading separate from listing JSON fetch state.

### Tests
- cache key correctness.
- TTL expiry.
- eviction.
- invalidation.
- logout/account switch.
- stale-while-revalidate.
- offline read.
- no offline mutation false success.
- signed URL expiry.
- bounded cache behavior.

### Gate 08
Cache policy is documented and bounded; private data is isolated; cache invalidation tests pass.

---

## PHASE 09 — Pagination, Search, Large Catalog and Memory Discipline

### Objective
Make the mobile client efficient for a catalog that may grow to millions of records.

### 09.1 Pagination
- Use the exact backend pagination contract.
- Prefer cursor pagination when the API provides stable cursors.
- If only offset pagination exists, document limitations and avoid large offsets where possible.
- Never request the entire catalog.
- Start with a conservative page size supported by backend limits.
- Do not assume page size can be increased without server approval.
- Handle duplicate items between pages.
- Handle deleted/reordered records and expired cursors.
- Ensure refresh resets cursor correctly.
- Prevent concurrent duplicate load-more requests.
- Keep only a bounded number of pages in memory where appropriate.
- Preserve scroll position where UX requires it.

### 09.2 Search
- Debounce user input.
- Cancel superseded requests.
- Avoid firing on every keystroke without debounce.
- Normalize query only as backend contract specifies.
- Keep filters and sort in an immutable query object.
- Make query cache key deterministic.
- Do not mix results from different filter states.
- Handle empty query and empty results distinctly.
- Handle rate limiting.
- Restore search state only when appropriate.

### 09.3 Rendering
- Use lazy builders (`ListView.builder`, `SliverList`, grids) for long collections.
- Use stable keys.
- Avoid expensive work in `build`.
- Avoid nested unbounded scrollables.
- Use const widgets where meaningful.
- Keep provider watch scope narrow.
- Use `select` for small state slices.
- Avoid rebuilding full pages when one favorite changes.
- Do not create large eagerly computed derived collections on every frame.
- Use isolates/compute only for measured CPU-heavy work; don't add isolate complexity to ordinary JSON parsing without profiling evidence.

### 09.4 Network and memory bounds
- Define maximum in-flight requests by workload.
- Cancel requests on obsolete query/disposal.
- Avoid unbounded prefetch.
- Avoid keeping every visited listing in a global provider forever.
- Evict image and object caches.
- Avoid repeated JSON serialization/copying of large lists.
- Avoid retaining BuildContext, Ref or widget state in long-lived services.

### 09.5 Performance budgets and measurement
Set measurable budgets after recording a baseline device/environment. At minimum measure:
- cold startup.
- warm startup.
- first contentful listing feed.
- search response-to-render.
- scroll frame stability.
- memory after extended feed scrolling.
- image cache growth.
- request count for common flows.
- rebuild count for feed/favorite/search interactions.

Use Flutter DevTools, profile mode and reproducible datasets. Do not claim “no lag” without measurements. Define target thresholds with device class and test conditions.

### Gate 09
Large-list tests demonstrate bounded memory and no eager full-catalog fetch; pagination/search cancellation tests pass; profile measurements are recorded.

---

# PART I — SHARED APP CAPABILITIES

## PHASE 10 — Error UX, Connectivity and Resilience

### Tasks
- Build a consistent error-to-UI presentation policy.
- Distinguish empty, loading, stale, offline, unauthorized, forbidden, rate-limited and server failure states.
- Provide retry only when meaningful.
- Avoid showing raw backend error text.
- Handle app background/foreground transitions.
- Restore safe state after process recreation.
- Avoid duplicate snackbars/dialogs from repeated provider emissions.
- Ensure retry does not duplicate mutations.
- Connectivity state is advisory; actual request result remains authoritative.
- Avoid blocking UI based only on connectivity plugin state.

### Deliverables
- Shared async state conventions.
- Error presentation guidelines.
- Connectivity abstraction if needed.
- Tests for offline and recovery states.

### Gate 10
No silent failures or generic “something went wrong” for all cases; error behavior is consistent and testable.

## PHASE 11 — Routing, Deep Links and Localization Foundation

### Tasks
- Inspect current router and dependencies; select/retain a declarative router only after compatibility review.
- Centralize route names/paths.
- Use typed route arguments where supported.
- Validate listing IDs and all route parameters.
- Support auth redirects without redirect loops.
- Handle expired sessions during navigation.
- Deep links must validate allowed scheme/host and destination.
- Do not place tokens or PII in links.
- Preserve back-stack behavior.
- Support Arabic RTL and English LTR.
- Use generated localization resources where suitable.
- Avoid hardcoded UI strings in new features.
- Format currency, dates, numbers and phone numbers according to locale and product rules.
- Ensure backend enum values are mapped to localized labels rather than shown raw.
- Add accessibility labels and semantics.
- Do not implement all screens in this phase; establish infrastructure only.

### Gate 11
Route/auth transitions, invalid deep links, RTL/LTR and localization smoke tests pass.

## PHASE 12 — Design System and UI Foundation (No Full Feature Screens Yet)

### Tasks
- Inspect existing brand assets and product design docs.
- Preserve approved brand identity; do not invent a new brand.
- Establish color tokens, typography, spacing, radii, elevation, icon and semantic status tokens.
- Light and dark themes.
- Contrast verification, aiming for WCAG 2.2 AA where applicable.
- RTL/LTR layout behavior.
- Reusable buttons, inputs, cards, chips, loading skeletons, empty states, error states, dialogs and sheets.
- Consistent focus, disabled, pressed, loading and validation states.
- Responsive layout for supported mobile form factors.
- Avoid global design components that accept dozens of unrelated parameters.
- Add golden tests for foundational components if practical.

### Gate 12
Theme, typography, RTL/LTR, core components and accessibility checks are verified. Do not begin full screens until approved.

---

# PART J — FEATURE INTEGRATION AND V1 READINESS

## PHASE 13 — Feature-by-Feature API Integration

### Objective
Connect all applicable V1 modules through the established architecture. Build one vertical slice at a time and keep each independently testable.

### Required vertical-slice order
Adjust order only when dependencies require it; document why.

1. Auth/session and account bootstrap.
2. Categories and dynamic category fields.
3. Shared listings domain/data layer.
4. Home/feed.
5. Search/filter/sort/pagination.
6. Listing details.
7. Favorites.
8. Locations and map filters where supported.
9. Media upload and listing attachment.
10. Contact reveal and quotas.
11. Account profile, teams and branches.
12. Category-specific vertical configuration:
   - Real estate.
   - Building materials/electricity.
   - Home/engineering services.
   - Home appliances/décor.
   - Cars.
   - Clothes/accessories.
13. Notifications/chat only if API exists and V1 scope approves.

### For every vertical slice
1. Read exact API contract.
2. Write sanitized request/response fixtures.
3. Implement DTOs.
4. Implement mapper tests.
5. Implement domain entities and repository contract.
6. Implement remote/local data sources.
7. Implement repository and cache policy.
8. Implement Riverpod providers/controllers.
9. Implement loading/error/empty/data/stale states.
10. Add integration tests with mocked HTTP.
11. Verify actual production GET behavior when safe.
12. Add documentation and traceability.
13. Pass review before moving on.

### Important product rules
- No checkout/orders/payment in V1 unless owner explicitly changes scope.
- Do not fake chat or notifications if backend does not support them.
- Do not treat a local mock as live API data.
- Mock mode must be explicit and impossible to enable accidentally in production.
- No user-facing phone number unless the verified contact-reveal flow authorizes it.
- Backend is authoritative for moderation, listing state, quotas and access control.
- Category dynamic fields must be driven by verified category-field contracts; do not hardcode assumptions that conflict with backend configuration.

### Gate 13
Every in-scope module has an integration status: PASS / PARTIAL / BLOCKED / OUT OF SCOPE. All PASS items have tests and API traceability.

---

# PART K — TESTING, SECURITY REVIEW AND RELEASE

## PHASE 14 — Automated Test Strategy

### Test pyramid
**Unit tests**
- entities/value objects.
- DTO serialization/deserialization.
- mappers.
- validators.
- query/cache keys.
- pagination state.
- repository behavior.
- error mapping.
- retry policy.
- token manager.

**Provider tests**
- Notifier/AsyncNotifier lifecycle.
- loading/data/error transitions.
- family isolation.
- cancellation.
- invalidation.
- cache refresh.
- optimistic mutation rollback if used.

**API contract tests**
- exact paths/methods.
- query and body serialization.
- headers.
- response parsing.
- status/error mapping.
- unknown enum handling.
- pagination.
- upload host/token isolation.

**Widget tests**
- loading/empty/error/data.
- RTL/LTR.
- light/dark.
- accessibility semantics.
- interaction and navigation.

**Integration tests**
- bootstrap.
- login flow against controlled test environment.
- session restoration.
- expired session.
- listing feed and pagination.
- search and cancellation.
- favorite mutation.
- upload flow in non-production/test environment.
- logout and private-cache clearing.

Never run destructive integration tests against production.

### Quality commands
Run the commands supported by the actual Flutter project and record exact output:
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- relevant integration test command.
- debug build for supported target.
- release/profile build when environment permits.

Do not claim a command passed if it was not executed. Do not hide skipped tests.

### Gate 14
All required tests pass; failures are fixed or documented as blockers; no known critical security regression.

## PHASE 15 — Independent Security and Privacy Audit

A second agent/reviewer must inspect the implementation independently.

Checklist:
- secrets and credentials scan.
- token storage and leakage.
- interceptor origin restrictions.
- refresh concurrency and replay behavior.
- TLS/cleartext config.
- PII exposure and logs.
- contact reveal and quota enforcement.
- user cache isolation.
- logout cleanup.
- deep link validation.
- file upload type/size validation.
- signed URL handling.
- permission minimization.
- dependency vulnerabilities and outdated critical packages.
- insecure random IDs or local authorization.
- production mock-mode prevention.
- debug endpoints/logging disabled in release.

Classify findings:
- Critical.
- High.
- Medium.
- Low.
- Informational.

No Critical or High issue may be marked accepted without explicit owner approval and a documented mitigation. Client-side mitigations cannot close server-side security findings.

### Gate 15
Independent reviewer signs off or release remains blocked.

## PHASE 16 — Performance and Scale Validation

### Objective
Verify client behavior with realistic large-catalog patterns, without claiming the mobile app proves backend capacity.

### Test scenarios
- feed with many pages.
- rapid search typing.
- filter/sort changes while requests are in flight.
- rapid scroll and image loading.
- open/close multiple listing details.
- favorite toggles on multiple cards.
- account switch/logout after cached data exists.
- weak network / high latency.
- offline and reconnect.
- 429 and transient 5xx.
- expired signed media URL.
- memory pressure / app background and resume.

### Measurements
Record:
- device/emulator model and OS.
- Flutter/Dart version.
- build mode.
- dataset size and fixture source.
- number of pages fetched.
- memory before/after.
- frame timing/jank.
- network request count.
- cache hit/miss behavior.
- image memory/disk usage.
- startup and first-content timing.

Use profile mode for performance conclusions. Avoid using debug-mode timings as release performance proof.

### Gate 16
Performance report contains reproducible measurements, bounded memory/cache evidence, and unresolved bottlenecks. Backend load capacity is explicitly outside the mobile-only sign-off.

## PHASE 17 — Final Documentation, Handover and Release Readiness

Create/update mobile-only documents:
- `MOBILE_PROJECT_STATUS.md`
- `MOBILE_ARCHITECTURE.md`
- `MOBILE_API_INTEGRATION_MATRIX.md`
- `MOBILE_SECURITY_AUDIT.md`
- `MOBILE_CACHE_AND_PERFORMANCE.md`
- `MOBILE_TEST_REPORT.md`
- `MOBILE_KNOWN_LIMITATIONS.md`
- `MOBILE_RELEASE_CHECKLIST.md`
- `MOBILE_CHANGELOG.md`

Final report must state:
- what was implemented.
- what was not implemented.
- exact API endpoints integrated.
- API operations blocked/unavailable.
- test counts and results.
- build/analyze results.
- security findings.
- performance measurements.
- cache policies.
- known limitations.
- files changed.
- confirmation that backend files were untouched.
- Git diff summary.
- recommended next step.

### Final mobile foundation sign-off
Only mark the mobile foundation complete when:
- all required gates passed.
- all V1 API integrations are accounted for.
- no unverified endpoint is presented as working.
- security audit has no unresolved Critical/High issue.
- tests and build pass.
- performance report exists.
- backend diff is empty.
- owner-facing handover is complete.

---

# PART L — AGENT COORDINATION AND EXECUTION CONTROL

## L1. Agent roles

Use separate agents only when the environment supports reliable parallel work and each agent has a strictly isolated scope.

**Agent A — Repository & Product Auditor**
- Read-only repository, docs and product audit.
- Produces Phase 00 reports.
- No code changes.

**Agent B — Backend/API Contract Auditor**
- Read-only backend/OpenAPI/production API audit.
- Produces endpoint inventory and gap report.
- No mutation requests and no backend changes.

**Agent C — Flutter Architect**
- Designs target architecture and Riverpod conventions.
- Does not start feature screens.

**Agent D — Flutter Foundation Engineer**
- Implements approved foundation phases only.
- Mobile directory scope only.

**Agent E — API Integration Engineer**
- Implements verified DTOs, repositories and integrations after foundation approval.
- No invented contracts.

**Agent F — QA/Performance Engineer**
- Tests, profiles, audits and verifies evidence.
- Must be independent of implementation claims.

Parallel agents must not edit the same files simultaneously. One lead agent owns integration and final Git state.

## L2. Phase execution protocol

At the start of each phase:
1. Read this specification.
2. Read prior phase reports.
3. Check current Git status.
4. Confirm phase prerequisites.
5. State exact files/directories in scope.
6. Confirm forbidden paths.

At the end of each phase:
1. Run phase tests.
2. Run analyzer/formatter as appropriate.
3. Inspect Git diff.
4. Search for secrets/PII.
5. Confirm no backend modifications.
6. Update the phase report.
7. Produce PASS / FAIL / BLOCKED.
8. List evidence and exact commands.
9. Stop if not PASS.

Do not combine all phases into one giant unreviewable change. Work in small, coherent commits if Git workflow is approved. Never commit automatically if the owner has not authorized commits; leave changes inspectable and report them.

## L3. Progress report template

For every phase report:

```text
PHASE:
STATUS: PASS / FAIL / BLOCKED

OBJECTIVE:
FILES CREATED:
FILES MODIFIED:
FILES DELETED:
API OPERATIONS VERIFIED:
TESTS EXECUTED:
TEST RESULTS:
ANALYZE / FORMAT:
BUILD:
SECURITY CHECKS:
PERFORMANCE EVIDENCE:
BACKEND FILES MODIFIED: NO (must remain NO)
GIT DIFF SUMMARY:
KNOWN LIMITATIONS:
BLOCKERS:
NEXT PHASE PREREQUISITES:
```

## L4. Stop conditions

Stop and request owner input when:
- Flutter project root is ambiguous.
- package identity or signing configuration could be overwritten.
- a required API contract is missing or contradictory.
- production auth flow cannot be safely verified.
- API returns private PII in public data.
- token refresh behavior is unclear and cannot be safely implemented.
- an endpoint requires a production mutation to test.
- backend and OpenAPI disagree on a security-sensitive field.
- a requested V1 feature depends on a missing backend operation.
- a dependency requires a breaking SDK upgrade.
- a cache strategy risks stale authorization or cross-account leakage.
- any action would modify backend or production state.
- a phase gate fails.

Do not ask the owner questions whose answers can be established safely by repository inspection. Ask only for decisions that genuinely require product/owner authority.

---

# PART M — INITIAL EXECUTION INSTRUCTION

Start now with **PHASE 00 only**.

Do not start creating screens.
Do not implement the API client yet.
Do not edit backend files.
Do not change production data.
Do not delete or overwrite existing user files.

First:
1. Confirm repository and Flutter app roots.
2. Inspect Git status and protect all current changes.
3. Inventory the current Flutter project after the owner's deletion.
4. Inspect all relevant Deal One product and backend documentation.
5. Inspect backend source/OpenAPI read-only.
6. Identify the actual deployed API documentation and safe read-only routes.
7. Record known backend security/API gaps.
8. Run baseline Flutter analyze/test/build where feasible.
9. Produce Phase 00 audit documents.
10. Report PASS / FAIL / BLOCKED and wait for approval before Phase 01.

After the owner approves Phase 00, proceed one phase at a time under the same gate policy. Do not interpret this master prompt as permission to bypass gates or to modify the backend.

**The quality standard is verified engineering, not the volume of generated code.**
