# Deal One — Railway `TRUST_PROXY` Verification Report (Phase Three)

**Date:** 2026-11-19  
**Local Code & Fastify/Redis Verification:** **PASS**  
**Live Railway Staging Header Observation:** **BLOCKED** (Dedicated Railway `staging` environment not yet provisioned; testing against `production` is prohibited and `one-deal-cJjt` is currently `[CRASHED]`)

---

## 1. Observed Railway Network Topology (Read-Only Inspection)

From `describe-service` on `one-deal-cJjt` (`054c6588-efa8-4203-b1b6-6515cc8cabc6`) and Railway Edge Networking documentation:

| Topology Attribute | Observed Value | Source |
|---|---|---|
| **Public Domain** | `one-deal-cjjt-production.up.railway.app` (Railway-managed domain, target port `8080`) | `describe-service` |
| **Custom Domain / Cloudflare Proxy** | None attached | `describe-service` |
| **TLS Termination** | Terminated at Railway Edge (`X-Railway-Edge: iad1`) | Railway Edge Networking docs |
| **Forwarding Headers Sent by Railway** | `X-Forwarded-For`, `X-Forwarded-Proto`, `X-Railway-Edge` | Railway Specs & Edge Networking docs |
| **Expected Proxy Hop Count** | `1` hop (Railway Edge → Fastify container) | Inferred from topology; **must be empirically confirmed on live staging before production sign-off** |

> **Important:** Per security policy, `TRUST_PROXY` is **not** marked verified from domain inspection alone. It remains **BLOCKED** until live HTTP requests through Railway Staging are observed and verified.

---

## 2. Application Proxy & Rate-Limit Implementation Review

1. **Startup Guardrail (`src/core/config/env.config.ts:155-196`):**
   - `parseTrustProxy()` rejects `TRUST_PROXY=true` at startup to prevent trusting attacker-controlled `X-Forwarded-For` prefixes.
   - Accepts only `false`, integer hop count `1..10`, `loopback`/`linklocal`/`uniquelocal`, or explicit IP/CIDR list.
2. **Fastify Wiring (`src/main.ts:27-33`):**
   - Passes `trustProxy: parseTrustProxy(process.env.TRUST_PROXY)` directly to `new FastifyAdapter({ trustProxy })`.
3. **Rate-Limit Key Extraction (`src/core/guards/rate-limit.guard.ts:97-111`):**
   - Authenticated routes key on `ratelimit:user:${userId}:${route}`.
   - Anonymous routes key strictly on `request.ip || request.socket?.remoteAddress || '127.0.0.1'` — **never** manually parsing `req.headers['x-forwarded-for']`.

---

## 3. Local Fastify + Real Redis Verification Evidence (`trustProxy: 1`)

Verified via `src/core/config/env.config.spec.ts`, `src/core/guards/rate-limit.guard.spec.ts`, and `test/staging-validation.e2e-spec.ts` (43/43 E2E passed on 2026-11-19):

| # | Scenario | Result | Status |
|---|---|---|---|
| 1 | Direct request with forged `X-Forwarded-For` under `trustProxy: false` | Ignored; keyed on socket IP (`198.51.100.10`) | **PASS (Local)** |
| 2 | Single-hop proxy (`X-Forwarded-For: 198.51.100.42`) under `trustProxy: 1` | Fastify resolves `request.ip = 198.51.100.42` | **PASS (Local)** |
| 3 | Spoofed leftmost XFF (`X-Forwarded-For: 203.0.113.<n>, 198.51.100.41`) under `trustProxy: 1` | Fastify resolves rightmost hop `198.51.100.41`; rotating forged IPs cannot bypass login rate limit → HTTP `429` + `Retry-After` | **PASS (Local)** |
| 4 | Request without `X-Forwarded-For` header | Falls back cleanly to socket `remoteAddress` (`127.0.0.1`) | **PASS (Local)** |
| 5 | Repeated failed logins from one client (`198.51.100.41`) | Throttled with HTTP `429` + `Retry-After` | **PASS (Local)** |
| 6 | Request from separate client (`198.51.100.42`) while client A is throttled | Receives HTTP `401` (not `429`), confirming client isolation | **PASS (Local)** |

---

## 4. Live Railway Staging Verification Procedure (Execute Immediately After Staging Provisioning)

No temporary public diagnostic endpoint is required because `LoggingInterceptor` (`src/core/interceptors/logging.interceptor.ts`) already emits structured JSON logs containing `req.ip` without logging `Authorization` headers or cookies.

Once `staging-api` is deployed on Railway with `TRUST_PROXY=1`:

1. **Test 1 — Normal Request Through Railway:**
   ```bash
   MY_IP=$(curl -s https://api.ipify.org)
   curl -s -o /dev/null -w "%{http_code}\n" "https://<staging-host>/api/v1/listings?limit=1"
   ```
   Inspect Railway deploy logs (`get-logs`) and verify `req.ip == $MY_IP` (and NOT Railway internal `100.64.x.x` or `127.0.0.1`).
2. **Test 2 — Forged `X-Forwarded-For` Header:**
   ```bash
   curl -s -H "X-Forwarded-For: 203.0.113.99" "https://<staging-host>/api/v1/listings?limit=1" > /dev/null
   ```
   Verify `req.ip == $MY_IP` (NOT `203.0.113.99`).
3. **Test 3 — Multi-Hop Forged `X-Forwarded-For` Chain:**
   ```bash
   curl -s -H "X-Forwarded-For: 198.51.100.1, 203.0.113.99" "https://<staging-host>/api/v1/listings?limit=1" > /dev/null
   ```
   Verify `req.ip == $MY_IP`.
4. **Test 4 — Repeated Failed Login Attempts with Rotating Forged XFF:**
   Send 6 `POST /api/v1/auth/login` requests with different forged `X-Forwarded-For: 203.0.113.<i>` headers from the same real client IP. Confirm attempts 1–5 return `401` and attempt 6 returns `429` with `Retry-After`.
5. **Test 5 — Legitimate Client Isolation:**
   From a second distinct public IP (e.g., mobile tether), send `POST /api/v1/auth/login` while Client 1 is throttled. Confirm Client 2 receives `401` (not `429`).
6. **Test 6 — Cloudflare Fronting Check (If Cloudflare Proxy Is Added Later):**
   If orange-cloud Cloudflare proxy is placed in front of Railway, Railway receives `X-Forwarded-For: <client_ip>, <cf_edge_ip>` and appends its own hop. In that topology, verify with Tests 1–5 and update `TRUST_PROXY=2` (or restrict to Railway + Cloudflare CIDRs).

---

## 5. Final Verified Configuration Status

- **Candidate Narrowest Configuration:** `TRUST_PROXY=1` (for direct `*.up.railway.app` without Cloudflare).
- **Current Gate Status:** **BLOCKED** — Awaiting live Railway Staging header observation and sanitized log evidence.
