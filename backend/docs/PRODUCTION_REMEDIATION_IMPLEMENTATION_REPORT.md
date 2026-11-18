# Deal One Backend — Production Remediation Implementation Report

**Date:** 2026-11-19  
**Base Commit:** `6c65615` (`main`)  
**Scope:** Phases 01–13 Production Readiness Security, Reliability, and Contract Remediation

---

## 1. Remediations Implemented

### F-01: JWT Secret Management & Fail-Fast Production Config
- **Original Vulnerability:** Hardcoded default JWT secrets in `env.config.ts` and `docker-compose.yml`, fallback pepper in `otp.service.ts`, and fail-open `validateEnv()` returning default secrets on parse failure in production.
- **Root Cause:** `envSchema` provided default strings for `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` and swallowed validation errors when `NODE_ENV !== 'test'`.
- **Files Modified:**
  - `src/core/config/env.config.ts`
  - `src/modules/auth/services/otp.service.ts`
  - `docker-compose.yml`
  - `.env.example`
- **Fix Implemented:**
  - Removed hardcoded production defaults; required explicit `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `DATABASE_URL`, and `CORS_ORIGIN` in `NODE_ENV=production`.
  - Added `validateProductionSecret()` enforcing ≥32 chars, ≥10 unique chars, Shannon entropy ≥3.0 bits/char, rejection of known defaults/placeholders, and `JWT_ACCESS_SECRET !== JWT_REFRESH_SECRET`.
  - Enforced fail-fast startup (throws error without ever printing secret values) in production.
  - Removed `'deal_one_fallback_pepper'` fallback in `OtpService` for production.
- **Tests Added:** `src/core/config/env.config.spec.ts` (16 tests covering missing secrets, weak/low-entropy secrets, identical secrets, default/placeholder secrets, valid prod config, CORS & TRUST_PROXY validation).
- **Remaining Risks:** Operator must provision distinct, high-entropy 64-char hex secrets in Railway before deploying.

---

### F-02: Authentication Rate Limiting & Enumeration Prevention
- **Original Vulnerability:** `POST /auth/login`, `POST /auth/password/login`, `POST /auth/refresh`, `POST /auth/token/refresh`, and `POST /auth/otp/verify` lacked HTTP-layer distributed rate limiting; `loginWithPassword` leaked suspended/inactive account status before password verification.
- **Root Cause:** Only `password/forgot` and `password/reset` applied `@UseGuards(RateLimitGuard)`; no per-account login throttling existed.
- **Files Modified:**
  - `src/modules/auth/auth.controller.ts`
  - `src/modules/auth/auth.service.ts`
  - `src/core/guards/rate-limit.guard.ts`
- **Fix Implemented:**
  - Applied Redis-backed `RateLimitGuard` with configurable env limits (`RATE_LIMIT_LOGIN_*`, `RATE_LIMIT_REFRESH_*`, `RATE_LIMIT_OTP_VERIFY_*`), shared bucket keys across route aliases, and `Retry-After` / `X-RateLimit-Reset` headers.
  - Added per-account (normalized phone) distributed login throttling in `AuthService.loginWithPassword`, cleared upon valid login.
  - Equalized `loginWithPassword` error message (`Invalid phone number or password.`) and timing (dummy Argon2 work) to prevent account existence/status enumeration.
- **Tests Added:** `src/core/guards/rate-limit.guard.spec.ts`, `src/modules/auth/auth.service.spec.ts`.
- **Remaining Risks:** Multi-instance distributed enforcement relies on shared Redis Cache (`REDIS_URL` / `REDIS_CACHE_URL`) being reachable in Railway.

---

### F-03: `/metrics` Endpoint Protection
- **Original Vulnerability:** `GET /metrics` was publicly accessible without authentication.
- **Root Cause:** `MetricsController` had no auth guard and was excluded from the global prefix.
- **Files Modified:**
  - `src/core/metrics/metrics-auth.guard.ts` (new)
  - `src/core/metrics/metrics.controller.ts`
  - `src/core/metrics/metrics.module.ts`
- **Fix Implemented:**
  - Created `MetricsAuthGuard` supporting constant-time Bearer token (`Authorization: Bearer <METRICS_AUTH_TOKEN>`) and `X-Metrics-Token` header validation.
  - Fails closed in production for external traffic if `METRICS_AUTH_TOKEN` is unset (loopback-only fallback); permits private/loopback scraping in dev/test.
- **Tests Added:** `src/core/metrics/metrics-auth.guard.spec.ts` (4 tests).
- **Remaining Risks:** Prometheus scraper configuration must be updated with `METRICS_AUTH_TOKEN` in production.

---

### F-04: Trusted Proxy Configuration & Anti-Spoofing
- **Original Vulnerability:** Fastify `trustProxy` was unset while `RateLimitGuard` blindly trusted the leftmost `X-Forwarded-For` header.
- **Root Cause:** Manual header parsing in `RateLimitGuard` bypassed Fastify's proxy trust model.
- **Files Modified:**
  - `src/core/config/env.config.ts` (`parseTrustProxy`)
  - `src/main.ts` (`FastifyAdapter({ trustProxy })`)
  - `src/core/guards/rate-limit.guard.ts` (uses verified `request.ip`)
- **Fix Implemented:**
  - Added `TRUST_PROXY` env var parsed via `parseTrustProxy()`, explicitly rejecting blanket `TRUST_PROXY=true` and supporting exact hop counts (e.g., `1` for Railway), `loopback`, or explicit IP/CIDR lists.
  - Removed raw `X-Forwarded-For` parsing from `RateLimitGuard` so rate limiting relies exclusively on Fastify's verified `request.ip`.
- **Tests Added:** `src/core/config/env.config.spec.ts`, `src/core/guards/rate-limit.guard.spec.ts`.
- **Remaining Risks:** Exact Railway/Cloudflare hop count (`TRUST_PROXY=1` vs `2` if Cloudflare proxy sits in front of Railway) must be confirmed in staging/production before claiming full end-to-end proxy verification.

---

### F-05: CORS Hardening & HTTP Security Headers
- **Original Vulnerability:** `CORS_ORIGIN` defaulted to `'*'` and reflected arbitrary origins with `credentials: true` in production; Helmet CSP was disabled globally.
- **Root Cause:** `main.ts` mapped `'*'` to `origin: true` alongside `credentials: true`.
- **Files Modified:**
  - `src/core/security/http-security.config.ts` (new)
  - `src/main.ts`
- **Fix Implemented:**
  - Production requires explicit, validated `http://` / `https://` origin allowlist in `CORS_ORIGIN` (wildcards rejected at startup).
  - Non-browser / native Flutter mobile requests (no `Origin` header) remain permitted.
  - Unauthorized browser origins receive no `Access-Control-Allow-Origin` header; preflight `OPTIONS` validated.
  - Enabled strict API Helmet CSP (`default-src 'none'`, `frame-ancestors 'none'`), HSTS, `X-Frame-Options: DENY`, and `Referrer-Policy: no-referrer` when Swagger UI is disabled.
- **Tests Added:** `src/core/security/http-security.config.spec.ts` (9 tests including live Fastify injection).
- **Remaining Risks:** None in code; production `CORS_ORIGIN` must list any Flutter Web / Admin domains.

---

### F-06: Atomic Redis Rate Limiting
- **Original Vulnerability:** `RedisService.checkRateLimit` executed `INCR` and `EXPIRE` as two separate non-atomic commands, risking permanent keys (TTL=-1) and broken Redis-down behavior.
- **Root Cause:** Lack of Lua atomicity and missing TTL handling in fallback map.
- **Files Modified:**
  - `src/core/redis/redis.service.ts`
- **Fix Implemented:**
  - Replaced separate `INCR` + `EXPIRE` with a single atomic Redis Lua script that increments, initializes TTL on `current == 1`, repairs `ttl == -1` keys, preserves existing TTL on subsequent hits, and returns `{ current, ttl }`.
  - Added bounded in-memory rate-limit fallback (max 10,000 keys) with fixed-window TTL when Redis is temporarily unavailable, auto-recovering when Redis reconnects.
  - Added `setIfNotExists(key, value, ttlSeconds)` (`SET NX EX`) for idempotency guards.
- **Tests Added:** `src/core/redis/redis.service.spec.ts` (9 tests including concurrency, TTL preservation, error fallback, and recovery).

---

### F-07: Strict Media Ownership Validation
- **Original Vulnerability:** `MediaService.confirmUpload` used `storageKey.includes(\`/${userId}/\`)`, vulnerable to path traversal (`../`) and query-string spoofing.
- **Root Cause:** Substring match instead of strict canonical path validation.
- **Files Modified:**
  - `src/modules/media/media.service.ts`
- **Fix Implemented:**
  - Added `validateStorageKeyOwnership()` enforcing exact 5-segment canonical structure `uploads/images/YYYY-MM/<userId>/<filename>.<jpg|jpeg|png|webp>` and rejecting `..`, backslashes, leading slashes, query strings, fragments, null bytes, and URL-encoded traversal sequences.
- **Tests Added:** `src/modules/media/media-video-notifications.spec.ts` (positive + 8 negative attack vectors).

---

### F-08: Video Webhook Replay & Idempotency Protection
- **Original Vulnerability:** Cloudflare Stream webhook verified HMAC but lacked timestamp freshness window, raw body verification, strict hex validation, payload validation, and duplicate/replay idempotency.
- **Root Cause:** `verifyWebhookSignature` ignored the `time` age and `handleWebhook` did not track processed events.
- **Files Modified:**
  - `src/modules/video/video.service.ts`
  - `src/modules/video/video.controller.ts`
  - `src/main.ts` (raw JSON body capture)
- **Fix Implemented:**
  - Preserved raw JSON body on Fastify requests for exact HMAC verification.
  - Validated `time` freshness within `±VIDEO_WEBHOOK_TOLERANCE_SEC` (default 300s) and strict 64-char hex `sig1` with `crypto.timingSafeEqual`.
  - Validated payload structure (`uid` regex, boolean `readyToStream`).
  - Added Redis `SET NX EX` idempotency guard (`video:webhook:seen:<sha256>`) to ignore replays and duplicate deliveries safely.
  - Tightened `listingMedia.updateMany` filter to `mediaType: 'video'` with exact/suffix `uid` match.
- **Tests Added:** `src/modules/media/media-video-notifications.spec.ts` (valid, invalid sig, expired timestamp, replay/duplicate, malformed payload).

---

### F-09: JWT Access Token Revocation on Logout & Session Termination
- **Original Vulnerability:** Access tokens remained valid for up to 15 minutes after logout, `terminate-all`, password change, or password reset.
- **Root Cause:** `JwtStrategy.validate` did not check Redis revocation state; `POST /auth/logout` did not extract/denylist the caller's Bearer token.
- **Files Modified:**
  - `src/modules/auth/services/session.service.ts`
  - `src/modules/auth/strategies/jwt.strategy.ts`
  - `src/modules/auth/auth.service.ts`
  - `src/modules/auth/auth.controller.ts`
- **Fix Implemented:**
  - Added `jti` claim to access tokens.
  - Implemented Redis denylist keys with TTL matching access-token expiration (`auth:revoked:sid:<id>`, `auth:revoked:jti:<jti>`, `auth:revoked:user_before:<userId>`).
  - Wired denylisting into `logout`, `terminateAllSessions`, `revokeOtherUserSessions` (preserving current device), and refresh token reuse detection.
  - Checked Redis denylist in `JwtStrategy.validate` without adding any extra DB queries.
- **Tests Added:** `src/modules/auth/strategies/jwt.strategy.spec.ts` (4 tests covering single-device logout, multi-device isolation, terminate-all, and revoke-other-sessions).

---

### F-10, F-11, F-12: Audit Queue Retries, Feed Cache Deduplication & Health Redaction
- **Files Modified:**
  - `src/core/security/security-audit.service.ts` — Rethrows DB errors in BullMQ worker mode (`rethrow=true`) so 5x exponential backoff retries execute; added worker `failed`/`error` listeners; expanded sensitive metadata redaction.
  - `src/modules/listings/listings.service.ts` — Removed redundant `items` and top-level `nextCursor` from Redis-cached `feedResponse` (HTTP response via `TransformInterceptor` remains 100% identical for Flutter).
  - `src/core/health/health.controller.ts` — Redacted exact PostGIS build version string in `NODE_ENV=production`.
- **Tests Added:** `src/core/security/security-audit.service.spec.ts`, `src/core/interceptors/transform.interceptor.spec.ts`.

---

## 2. Verification Commands & Results

| Command | Result |
|---|---|
| `npm run build` | **PASSED** (0 errors) |
| `npx tsc --noEmit` | **PASSED** (0 errors) |
| `npx eslint ...` (all modified files) | **PASSED** (0 errors, 3 unused-var `_` warnings in test destructuring) |
| `npm test` | **PASSED** — **35 test suites passed, 222 tests passed** (up from 32 suites / 178 tests) |
| `npm run test:e2e` | **NOT RUN (BLOCKED)** — No local PostgreSQL/PostGIS/Redis containers running in workspace |
| `k6 run load-tests/k6-5000-online.js` | **BLOCKED** — No dedicated staging environment URL available; production load testing prohibited |
