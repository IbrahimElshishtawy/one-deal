# Deal One Backend — Production Readiness Initial Audit

**Audit Date:** 2026-11-19  
**Repository:** `backend/` (NestJS 10 + Fastify + Prisma 5 + PostgreSQL/PostGIS + Dual Redis + BullMQ)  
**Production URL:** `https://one-deal-cjjt-production.up.railway.app/api/v1`  
**Baseline Git Commit:** `6c65615` (`main`)  
**Baseline Unit Tests:** 32 suites passed, 178 tests passed (`npm test`)

---

## Executive Summary

A full source-code audit of the Deal One backend identified **3 Critical**, **6 High**, and **3 Medium** production-readiness and security findings. Every finding below was verified directly against the current source code.

| ID | Severity | Title | Primary Location |
|---|---|---|---|
| F-01 | **Critical** | Hardcoded JWT default secrets & fail-open env validation | `src/core/config/env.config.ts:55-62,136-151` |
| F-02 | **Critical** | Unprotected auth endpoints (login, refresh, OTP verify) & account-status enumeration | `src/modules/auth/auth.controller.ts:117-146,246-279` |
| F-03 | **Critical** | Publicly exposed `/metrics` Prometheus endpoint without auth | `src/core/metrics/metrics.controller.ts:7-16` |
| F-04 | **High** | Spoofable `X-Forwarded-For` header & missing Fastify `trustProxy` | `src/main.ts:23-26`, `src/core/guards/rate-limit.guard.ts:72-76` |
| F-05 | **High** | Permissive production CORS (`CORS_ORIGIN='*'`) reflected with `credentials: true` | `src/main.ts:31,38-41`, `src/core/config/env.config.ts:16` |
| F-06 | **High** | Non-atomic Redis `INCR` + `EXPIRE` in `checkRateLimit` & broken Redis-down behavior | `src/core/redis/redis.service.ts:383-398` |
| F-07 | **High** | Weak media ownership check (`storageKey.includes`) & path traversal risk | `src/modules/media/media.service.ts:177-184` |
| F-08 | **High** | Video webhook missing timestamp replay window & event idempotency | `src/modules/video/video.service.ts:108-169` |
| F-09 | **High** | Access tokens remain valid after logout/revocation (no Redis denylist) | `src/modules/auth/strategies/jwt.strategy.ts:34-64`, `src/modules/auth/services/session.service.ts:282-401` |
| F-10 | **Medium** | Audit queue worker swallows DB errors (disabling BullMQ retries) | `src/core/security/security-audit.service.ts:67-73,153-179` |
| F-11 | **Medium** | Redundant `items` array in `ListingsService.getListingsFeed` doubles Redis cache payload | `src/modules/listings/listings.service.ts:536-548` |
| F-12 | **Medium** | Missing `Retry-After` header on 429 & verbose PostGIS version in `/health/ready` | `src/core/guards/rate-limit.guard.ts:87-103`, `src/core/health/health.controller.ts:75` |

---

## Detailed Findings

### F-01 — Hardcoded JWT Default Secrets & Fail-Open Environment Validation
- **Severity:** Critical
- **Actual File & Lines:**
  - `src/core/config/env.config.ts:55-62` (hardcoded default secrets)
  - `src/core/config/env.config.ts:136-151` (`validateEnv` catches validation failures and silently falls back to `envSchema.parse({})` in non-test environments)
  - `src/modules/auth/services/otp.service.ts:44-47` (`'deal_one_fallback_pepper'`)
  - `docker-compose.yml:73-74,103-104` (identical placeholder defaults for both access and refresh secrets)
- **Root Cause:** `envSchema` defines default string values for `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET`. Worse, `validateEnv()` does not throw in `NODE_ENV=production` when validation fails — it logs a warning and returns `envSchema.parse({})`, booting production with publicly known secrets committed to Git. There is also no validation that `JWT_ACCESS_SECRET !== JWT_REFRESH_SECRET`, no minimum 32-char / entropy check in production, and no denylist for known placeholders.
- **Exploitation Scenario:** If Railway environment variables are misconfigured, empty, or temporarily missing during a deployment, the API silently boots using `dealone_default_access_secret_key_32chars_min_production!`. Any attacker who reads the repository can forge valid HS256 JWTs for any user or admin role (`ADMIN`/`SUPER_ADMIN`).
- **Recommended Remediation:**
  - Remove hardcoded default secrets from production mode and require explicit `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` in `NODE_ENV=production`.
  - Enforce minimum length (≥32 chars in production), entropy/character diversity, non-equality (`JWT_ACCESS_SECRET !== JWT_REFRESH_SECRET`), and rejection of known default/placeholder values.
  - Fail fast (throw error and crash startup) in production on any invalid configuration.
  - Remove `'deal_one_fallback_pepper'` fallback in `OtpService` when in production.
- **Related Tests:** `src/core/config/env.config.spec.ts`

---

### F-02 — Unprotected Authentication Endpoints & Account Status Enumeration
- **Severity:** Critical
- **Actual File & Lines:**
  - `src/modules/auth/auth.controller.ts:117-146` (`POST /auth/login`, `POST /auth/password/login` — no rate limit)
  - `src/modules/auth/auth.controller.ts:246-279` (`POST /auth/refresh`, `POST /auth/token/refresh` — no rate limit)
  - `src/modules/auth/auth.controller.ts:88-115` (`POST /auth/otp/verify` — no IP/account rate limit guard)
  - `src/modules/auth/auth.controller.ts:42-86` (`POST /auth/otp/send`, `POST /auth/otp/resend` — no guard-level rate limit or `Retry-After`)
  - `src/modules/auth/auth.service.ts:251-266` (`loginWithPassword` returns `'Account suspended or deactivated.'` before verifying password, allowing account existence/status enumeration)
- **Root Cause:** Only `password/forgot` and `password/reset` have `@UseGuards(RateLimitGuard)`. Login, refresh, and OTP verify have no HTTP-layer rate limiting, and `loginWithPassword` has no per-account throttling.
- **Exploitation Scenario:** An attacker can perform high-speed credential stuffing or password brute-force against `POST /auth/login`, hammer `POST /auth/refresh` to cause DB load or probe refresh token hashes, or enumerate suspended/active phone numbers via `loginWithPassword`.
- **Recommended Remediation:**
  - Apply distributed Redis-backed `RateLimitGuard` with configurable limits and `Retry-After` headers to `login`, `password/login`, `refresh`, `token/refresh`, `otp/verify`, `otp/send`, and `otp/resend`.
  - Add account-based throttling (by normalized phone) in `AuthService.loginWithPassword` and `OtpService.verifyOtp`.
  - Equalize authentication errors in `loginWithPassword` (verify password / dummy argon2 before rejecting, return consistent `Invalid phone number or password.` error to avoid enumeration).
- **Related Tests:** `src/modules/auth/auth.service.spec.ts`, `src/core/guards/rate-limit.guard.spec.ts`, `test/auth.e2e-spec.ts`

---

### F-03 — Publicly Exposed `/metrics` Endpoint
- **Severity:** Critical
- **Actual File & Lines:**
  - `src/core/metrics/metrics.controller.ts:7-16`
  - `src/main.ts:61-69`
- **Root Cause:** `GET /metrics` is excluded from the `api/v1` prefix and has no authentication guard or IP/network restriction.
- **Exploitation Scenario:** Any unauthenticated internet user can scrape `https://one-deal-cjjt-production.up.railway.app/metrics` to enumerate all active API routes, traffic volumes, error rates, latency histograms, memory usage, and uptime.
- **Recommended Remediation:**
  - Protect `GET /metrics` with a dedicated `MetricsAuthGuard` supporting bearer token (`METRICS_AUTH_TOKEN`) and/or Basic Auth for Prometheus scraping, plus optional internal-network allowlisting in production. Fail closed in production if `METRICS_AUTH_TOKEN` is not configured (or restrict strictly to private/loopback IPs when token is unset, documented clearly).
  - Update `infra/prometheus/prometheus.yml` documentation/example with bearer token config.
- **Related Tests:** `src/core/metrics/metrics.service.spec.ts` (add `metrics.controller.spec.ts`)

---

### F-04 — Spoofable `X-Forwarded-For` Header & Missing Fastify `trustProxy`
- **Severity:** High
- **Actual File & Lines:**
  - `src/main.ts:23-26` (`new FastifyAdapter({ logger: false, maxParamLength: 200 })` — `trustProxy` omitted)
  - `src/core/guards/rate-limit.guard.ts:72-76` (directly reads `request.headers['x-forwarded-for'].split(',')[0]`)
- **Root Cause:** Without `trustProxy`, Fastify sets `request.ip` to the immediate TCP peer (Railway's internal edge proxy). Meanwhile, `RateLimitGuard` manually parses the leftmost `X-Forwarded-For` value, which is attacker-controlled.
- **Exploitation Scenario:** An attacker sends `X-Forwarded-For: 1.2.3.<random>` on every request to bypass all IP-based rate limits in `RateLimitGuard`. Conversely, in `OtpService` (which uses `req.ip`), all legitimate users behind Railway's proxy share a single proxy IP and hit the 10-req/15-min IP limit together.
- **Recommended Remediation:**
  - Configure Fastify `trustProxy` via a validated `TRUST_PROXY` env var (narrowest valid config: e.g., `1` hop for Railway's single edge proxy, or explicit CIDR/loopback list; never blindly `true` unless explicitly configured and documented).
  - Update `RateLimitGuard` to use `request.ip` (resolved by Fastify's trusted proxy boundary) instead of manually parsing raw `X-Forwarded-For`.
- **Related Tests:** `src/core/guards/rate-limit.guard.spec.ts`

---

### F-05 — Permissive Production CORS (`CORS_ORIGIN='*'`) with `credentials: true`
- **Severity:** High
- **Actual File & Lines:**
  - `src/core/config/env.config.ts:16` (`CORS_ORIGIN: z.string().default('*')`)
  - `src/main.ts:31,38-41` (`origin: corsOrigin === '*' ? true : corsOrigin.split(','), credentials: true`)
  - `src/main.ts:34-36` (`helmet` disables CSP globally even when Swagger is off)
- **Root Cause:** In production, `CORS_ORIGIN` defaults to `'*'`, which `main.ts` converts to `origin: true` alongside `credentials: true`. Fastify CORS then reflects any requesting origin into `Access-Control-Allow-Origin` with `Access-Control-Allow-Credentials: true`.
- **Exploitation Scenario:** Any malicious website can make credentialed cross-origin requests from a victim's browser to the Deal One API and read responses.
- **Recommended Remediation:**
  - Require explicit, non-wildcard `CORS_ORIGIN` in `NODE_ENV=production` (fail startup if missing or `'*'`).
  - Parse, trim, and validate origin URLs; reject unauthorized origins cleanly while allowing requests with no `Origin` header (native Flutter mobile apps / server-to-server).
  - Never combine wildcard/arbitrary reflection with `credentials: true`.
  - Enable Helmet security headers appropriately (enable CSP when Swagger UI is disabled).
- **Related Tests:** New CORS & HTTP security unit/integration tests.

---

### F-06 — Non-Atomic Redis `INCR` + `EXPIRE` in `checkRateLimit`
- **Severity:** High
- **Actual File & Lines:**
  - `src/core/redis/redis.service.ts:383-398`
- **Root Cause:** `checkRateLimit` executes `INCR` and `EXPIRE` as two separate network round-trips. If the app crashes or Redis disconnects between calls, the key persists forever without a TTL. Furthermore, in-memory fallback `incr()` calls `set(key, next)` without a TTL, and when Redis is down in production, `get()`/`set()` no-op so `incr()` always returns `1`, silently disabling rate limiting.
- **Exploitation Scenario:** A process crash between `INCR` and `EXPIRE` permanently locks out a legitimate user or IP. Conversely, if Redis Cache drops in production, all rate limits silently fail open without tracking or warning.
- **Recommended Remediation:**
  - Replace `INCR` + `EXPIRE` with an atomic Redis Lua script that increments the counter, initializes TTL only when `current == 1` (or repairs TTL if `ttl == -1`), and returns `{current, ttl}` so `Retry-After` is accurate.
  - Handle Redis errors safely with bounded in-memory fallback (with TTL) or configurable fail mode, and auto-recover when Redis reconnects.
- **Related Tests:** `src/core/redis/redis.service.spec.ts`

---

### F-07 — Weak Media Ownership Validation & Path Traversal Risk
- **Severity:** High
- **Actual File & Lines:**
  - `src/modules/media/media.service.ts:177-184`
- **Root Cause:** `confirmUpload` validates ownership using `!dto.storageKey.includes(\`/${userId}/\`)`.
- **Exploitation Scenario:** An attacker supplies `storageKey: "uploads/images/2026-11/<attackerId>/../<victimId>/secret.jpg"` or `"arbitrary/<attackerId>/../../other"` which passes `.includes('/<attackerId>/')` and lets the attacker attach unauthorized or traversed storage keys to listings.
- **Recommended Remediation:**
  - Enforce strict regex/segment validation matching the exact canonical key structure generated by `generateImageUploadUrls`: `^uploads/images/\d{4}-\d{2}/<userId>/[a-zA-Z0-9._-]+\.(jpg|jpeg|png|webp)$`.
  - Reject any `..`, backslashes, leading slashes, query strings, fragments, null bytes, or mismatched owner/resource segments.
- **Related Tests:** `src/modules/media/media-video-notifications.spec.ts`, `test/security-integration.e2e-spec.ts`

---

### F-08 — Video Webhook Replay Attack & Duplicate Processing
- **Severity:** High
- **Actual File & Lines:**
  - `src/modules/video/video.service.ts:108-169`
  - `src/modules/video/video.controller.ts:42-51`
- **Root Cause:** Cloudflare Stream signs `Webhook-Signature: time=<unix_ts>,sig1=<hmac_sha256>` over `<time>.<raw_body>`. Current implementation:
  1. Never checks that `time` is within a fresh tolerance window (e.g., 300s) → vulnerable to indefinite replay.
  2. Never records processed webhook signatures/event IDs → vulnerable to duplicate delivery / replay.
  3. Uses `JSON.stringify(payload)` instead of raw request body when available.
  4. Does not validate strict hex format of `sig1` before `Buffer.from(sig1, 'hex')`.
  5. Uses `storageKey: { contains: uid }` without validating `uid` format/length.
- **Exploitation Scenario:** An attacker who intercepts a valid webhook (e.g., `readyToStream: false`) can replay it indefinitely to flip a ready video back to `failed`.
- **Recommended Remediation:**
  - Validate `time` is a valid integer within ±300 seconds (configurable) of server time.
  - Validate `sig1` is a 64-char hex string and verify via `crypto.timingSafeEqual` against raw body (with `JSON.stringify` fallback for unit tests).
  - Enforce idempotency / replay prevention using Redis `SET NX EX` keyed by webhook event fingerprint (signature or `uid + time + status`).
  - Validate `uid` format before querying/updating `listingMedia`.
- **Related Tests:** `src/modules/media/media-video-notifications.spec.ts`

---

### F-09 — Access Tokens Not Revoked on Logout / Password Reset / Session Termination
- **Severity:** High
- **Actual File & Lines:**
  - `src/modules/auth/strategies/jwt.strategy.ts:34-64`
  - `src/modules/auth/services/session.service.ts:83-96,282-401`
  - `src/modules/auth/auth.controller.ts:281-292`
- **Root Cause:** `logout`, `terminateAllSessions`, `changePassword`, and `resetPassword` revoke `UserSession` rows in PostgreSQL, but `JwtStrategy.validate` never checks if the token's `sid` (or `jti`) or user's revocation timestamp is denylisted in Redis. Additionally, `POST /auth/logout` has no JWT extraction, so it cannot immediately denylist the caller's access token.
- **Exploitation Scenario:** After a user logs out or resets a compromised password, an attacker holding a stolen access token continues to have full API access for up to 15 minutes.
- **Recommended Remediation:**
  - Add a `jti` claim to minted access tokens (keeping existing claims intact for full compatibility).
  - Use Redis-backed revocation keys with TTL matching the access token lifetime (15 min):
    - `auth:revoked:sid:<sessionId>` on single-session logout / refresh rotation reuse detection.
    - `auth:revoked:user_before:<userId>` (Unix timestamp) on `terminateAllSessions` and `resetPassword` (revokes all access tokens issued before that timestamp without needing to track every individual JTI).
    - `auth:revoked:sid:<id>` for each revoked session in `revokeOtherUserSessions` (preserving the current session).
  - Check Redis revocation in `JwtStrategy.validate` before authorizing requests, preserving multi-device sessions and avoiding extra DB queries for session lookups.
  - Extract Bearer token (if present) on `POST /auth/logout` to immediately denylist its `sid`/`jti` while keeping `POST /auth/logout` backward-compatible with `{ refreshToken }`.
- **Related Tests:** `src/modules/auth/services/session.service.spec.ts`, `src/modules/auth/auth.service.spec.ts`

---

### F-10 — Audit Queue Swallows Errors (Preventing BullMQ Retries)
- **Severity:** Medium
- **Actual File & Lines:**
  - `src/core/security/security-audit.service.ts:67-73,153-179`
- **Root Cause:** `persistAuditRecord` catches all exceptions and logs them without rethrowing. When invoked inside the BullMQ `Worker` callback, failed DB writes appear successful to BullMQ, completely defeating the configured `attempts: 3` + exponential backoff retry policy. Also lacks worker `failed`/`error` listeners and substring-based sensitive key redaction (e.g., `apiKey`, `privateKey`).
- **Recommended Remediation:**
  - Separate `persistAuditRecord` (throws on failure so BullMQ retries) from direct-fallback error handling in `logEvent`.
  - Add BullMQ worker `failed` and `error` listeners for observability.
  - Expand `sanitizeMetadata` to redact partial-match sensitive keys (`secret`, `token`, `password`, `apikey`, `privatekey`, `authorization`, `cookie`, `otp`).
  - Ensure graceful shutdown drains worker and closes queue cleanly.
- **Related Tests:** `src/core/security/security-audit.service.spec.ts`

---

### F-11 — Redundant `items` Property in `ListingsService.getListingsFeed`
- **Severity:** Medium
- **Actual File & Lines:**
  - `src/modules/listings/listings.service.ts:536-548`
- **Root Cause:** `getListingsFeed` returns `{ data: mappedData, meta: {...}, items: mappedData, nextCursor }` and caches the entire object in Redis. However, `TransformInterceptor` (`src/core/interceptors/transform.interceptor.ts:38-49`) transforms `{ data, meta }` into `{ success: true, data, meta }`, stripping `items` and `nextCursor` from HTTP responses anyway. Flutter (`deal one app/lib/features/listings/data/dto/listing_dto.dart:126`) reads `json['data']` first.
- **Recommended Remediation:**
  - Verify all unit tests and Flutter consumers before removing redundant `items` from the Redis cache payload (keeping HTTP API contract 100% identical).
- **Related Tests:** `src/modules/listings/listings.service.spec.ts`

---

### F-12 — Missing `Retry-After` Header on 429 & Verbose PostGIS Version in `/health/ready`
- **Severity:** Medium
- **Actual File & Lines:**
  - `src/core/guards/rate-limit.guard.ts:87-103`
  - `src/core/health/health.controller.ts:75`
- **Root Cause:** `RateLimitGuard` does not set the standard `Retry-After` HTTP header on 429 responses. `/health/ready` returns the full `PostGIS_Version()` string publicly, disclosing exact database/extension build versions.
- **Recommended Remediation:**
  - Emit `Retry-After` (in seconds, based on actual remaining Redis TTL) in `RateLimitGuard` when a request is throttled.
  - Redact detailed PostGIS version string in `/health/ready` when `NODE_ENV=production` (return `'up'` instead of `'up (3.4 ...)'`).
- **Related Tests:** `src/core/guards/rate-limit.guard.spec.ts`, `src/core/health/health.controller.spec.ts`
