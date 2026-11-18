# Deal One Backend — `TRUST_PROXY` Verification Report (F-04)

**Verification Date:** 2026-11-19  
**Code Status:** **VERIFIED IN LOCAL STAGING E2E & UNIT TESTS**  
**Live Railway Staging Observation:** **BLOCKED** (Railway project `airy-creativity` currently has only a `production` environment; creating a paid staging environment requires owner authorization)

---

## 1. Infrastructure Topology Discovery (Read-Only Railway Inspection)

Read-only inspection of Railway project `airy-creativity` (`036ef563-b1f9-4d6e-b901-802946a28e0a`), service `one-deal-cJjt`:
- **Configured domains:** `https://one-deal-cjjt-production.up.railway.app` (Railway-generated service domain, port `8080`).
- **Custom/Cloudflare domains:** None attached.
- **Implied proxy topology:** Single reverse-proxy hop (Railway edge proxy → NestJS/Fastify container), which corresponds to **`TRUST_PROXY=1`**.
- **Guardrail in code (`src/core/config/env.config.ts:147-182`):** `parseTrustProxy()` explicitly **rejects `TRUST_PROXY=true`** at startup to prevent trusting arbitrary `X-Forwarded-For` chains, accepting only `false`, exact hop count (`1`..`10`), `loopback`, or explicit IP/CIDR lists.

---

## 2. Automated Verification Matrix (Real Fastify + Real Redis)

Executed in `src/core/config/env.config.spec.ts`, `src/core/guards/rate-limit.guard.spec.ts`, and `test/staging-validation.e2e-spec.ts` (`trustProxy: 1` + real Redis):

| # | Test Scenario | Observed Result | Status |
|---|---|---|---|
| 1 | Direct request with forged `X-Forwarded-For` when `trustProxy: false` | `RateLimitGuard` ignores `X-Forwarded-For` and keys on `request.ip` (`198.51.100.10`) | **PASS** |
| 2 | Request through trusted 1-hop proxy (`X-Forwarded-For: 198.51.100.42`) | Fastify resolves `request.ip = 198.51.100.42` | **PASS** |
| 3 | Multi-hop forged chain (`X-Forwarded-For: 203.0.113.<n>, 198.51.100.41`) under `trustProxy: 1` | Fastify extracts rightmost hop `198.51.100.41`; rotating leftmost forged IPs cannot bypass rate limit → HTTP `429` + `Retry-After` | **PASS** |
| 4 | Request without forwarded headers | Falls back cleanly to socket `remoteAddress` (`127.0.0.1`) | **PASS** |
| 5 | Repeated failed login requests from same client (`198.51.100.41`) | Throttled with HTTP `429` and positive `Retry-After` header | **PASS** |
| 6 | Request from separate client (`198.51.100.42`) while `198.51.100.41` is throttled | Receives HTTP `401` (not `429`), confirming per-client IP isolation | **PASS** |

---

## 3. Remaining Live Infrastructure Action

When the project owner provisions a Railway Staging environment:
1. Set `TRUST_PROXY=1`.
2. Send a request with a forged header `curl -H "X-Forwarded-For: 1.2.3.4" https://<staging-host>/api/v1/listings?limit=1` and inspect the structured JSON `req.ip` in Railway logs.
3. Confirm `req.ip` equals the caller's real public IP (not `1.2.3.4` and not Railway's internal `100.64.x.x` proxy IP). If Cloudflare is added later in front of Railway, update to `TRUST_PROXY=2`.
