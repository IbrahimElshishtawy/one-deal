# 02 — Backend API Discovery & Contract Verification

**Target API:** Deal One Production Monolith Backend  
**Base URL:** `https://one-deal-cjjt-production.up.railway.app/api/v1`  
**Audit Date:** November 8, 2026  
**Auditor:** API Integration Engineer & Independent Reviewer  
**Status:** VERIFIED & DOCUMENTED

---

## 1. Network Topology & Infrastructure Probing

### 1.1 Health & Readiness Probes
Direct probes executed against live production:
- **`GET /health/live`:**
  - *Status:* `200 OK`
  - *Response:* `{"success":true,"data":{"status":"ok","uptimeSeconds":1199,"memoryRssMb":87,"timestamp":"2026-11-07T23:06:34.235Z"}}`
- **`GET /health/ready`:**
  - *Status:* `200 OK`
  - *Response:* `{"success":true,"data":{"status":"healthy","checks":{"database":"up","postgis":"up (3.4 USE_GEOS=1 USE_PROJ=1 USE_STATS=1)","redis_cache":"up","redis_queue":"up","workers":"active"},"timestamp":"2026-11-07T23:06:58.391Z"}}`
- **`GET /api/docs`:**
  - *Status:* `200 OK` (Swagger UI HTML)
- **`GET /api/docs-json`:**
  - *Status:* `200 OK` (Full OpenAPI 3.0.0 specification JSON)

---

## 2. API Wire Contract Envelopes

From backend source inspection (`transform.interceptor.ts` and `http-exception.filter.ts`):

### 2.1 Standard Success Envelope
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "total": 340,
    "page": 1,
    "limit": 20,
    "totalPages": 17
  }
}
```

### 2.2 Standard Error Envelope
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Validation failed for one or more fields",
    "details": [
      { "issue": "phone must be a valid Egyptian mobile number" }
    ],
    "trace_id": "e11730ea-dff7-4035-ab55-e3a2067abf9d"
  }
}
```
*Response Headers:* Every response guarantees `x-trace-id` and `x-request-id`.

---

## 3. Discovered V1 Endpoint Inventory

| Module | Method | Exact Path | Auth | Wire Status | Notes |
|---|---|---|:---:|:---:|---|
| **Health** | `GET` | `/health/live` | Public | **VERIFIED 200** | Liveness probe |
| **Health** | `GET` | `/health/ready` | Public | **VERIFIED 200** | DB & Redis deep health probe |
| **Auth** | `POST` | `/api/v1/auth/otp/send` | Public | Documented | Phone OTP dispatch (`SendOtpDto`) |
| **Auth** | `POST` | `/api/v1/auth/otp/resend` | Public | Documented | OTP resend with cooldown check |
| **Auth** | `POST` | `/api/v1/auth/otp/verify` | Public | Documented | Verifies OTP, returns `{ tokens, user, account }` |
| **Auth** | `POST` | `/api/v1/auth/login` | Public | Documented | Password fallback login |
| **Auth** | `POST` | `/api/v1/auth/refresh` | Public | Documented | Refresh token rotation (`RefreshTokenDto`) |
| **Auth** | `POST` | `/api/v1/auth/logout` | Bearer | Documented | Revokes active session family |
| **Users** | `GET` | `/api/v1/users/me` | Bearer | Documented | Returns current user profile |
| **Users** | `PATCH` | `/api/v1/users/me` | Bearer | Documented | Updates profile info |
| **Accounts** | `POST` | `/api/v1/accounts` | Bearer | Documented | Onboard business/merchant account |
| **Accounts** | `GET` | `/api/v1/accounts/my-accounts` | Bearer | Documented | Lists accounts accessible to user |
| **Accounts** | `GET` | `/api/v1/accounts/:id` | Bearer | Documented | Account details and verification status |
| **Accounts** | `GET` | `/api/v1/accounts/:id/branches` | Bearer | Documented | Account branch locations |
| **Categories** | `GET` | `/api/v1/categories` | Public | **500 on prod** | Root and subcategories tree |
| **Categories** | `GET` | `/api/v1/categories/:slug` | Public | **500 on prod** | Category details |
| **Categories** | `GET` | `/api/v1/categories/:slug/fields` | Public | **500 on prod** | Dynamic attribute schema for subcategory |
| **Listings** | `GET` | `/api/v1/listings` | Public | **500 on prod** | Feed of active listings with filters |
| **Listings** | `GET` | `/api/v1/listings/:id` | Public | **500 on prod** | Detailed listing data |
| **Listings** | `POST` | `/api/v1/listings` | Bearer | Documented | Create listing |
| **Listings** | `PUT` | `/api/v1/listings/:id` | Bearer | Documented | Update listing |
| **Listings** | `DELETE` | `/api/v1/listings/:id` | Bearer | Documented | Delete listing |
| **Listings** | `PATCH` | `/api/v1/listings/:id/availability` | Bearer | Documented | Set status: `available`, `reserved`, `sold` |
| **Listings** | `PATCH` | `/api/v1/listings/:id/status` | Bearer | Documented | Set status: `published`, `hidden`, `archived` |
| **Search** | `GET` | `/api/v1/search` | Public | **500 on prod** | Trigram text + governorate/city + radius |
| **Locations** | `GET` | `/api/v1/locations/governorates` | Public | **500 on prod** | List all 27 Egyptian governorates |
| **Locations** | `GET` | `/api/v1/locations/governorates/:id/cities` | Public | **500 on prod** | Cities under governorate |
| **Favorites** | `GET` | `/api/v1/favorites` | Bearer | Documented | User saved listings |
| **Favorites** | `POST` | `/api/v1/favorites/:listingId` | Bearer | Documented | Save listing |
| **Favorites** | `DELETE` | `/api/v1/favorites/:listingId` | Bearer | Documented | Unsave listing |
| **Media** | `POST` | `/api/v1/media/presigned` | Bearer | Documented | Obtain presigned S3/R2 direct upload URLs |
| **Media** | `POST` | `/api/v1/media/confirm` | Bearer | Documented | Confirm upload and link to listing |
| **Quotas** | `GET` | `/api/v1/quotas/contact-reveals/today` | Bearer | Documented | Remaining reveals today |
| **Quotas** | `POST` | `/api/v1/quotas/contact-reveals/reveal/:listingId` | Bearer | Documented | Reveals seller phone number |
| **Reports** | `POST` | `/api/v1/moderation/reports` | Bearer | Documented | Report listing for scam/abuse |
| **Notifications** | `POST` | `/api/v1/notifications/device-token` | Bearer | Documented | Register FCM token |
| **Chat** | `POST` | `/api/v1/chat/conversations` | Bearer | Documented | Start conversation for listing |
| **Chat** | `GET` | `/api/v1/chat/conversations` | Bearer | Documented | List conversations |

---

## 4. Production API Discrepancy & Root Cause Analysis

### 4.1 Finding
Safe, read-only GET requests to table-querying endpoints (`GET /api/v1/categories`, `GET /api/v1/listings`, `GET /api/v1/locations/governorates`) fail with:
- **HTTP Status:** `500 Internal Server Error`
- **Error Code:** `INTERNAL_SERVER_ERROR`
- **Error Message:** `"An unexpected server error occurred."`

Meanwhile, `GET /health/live`, `GET /health/ready`, and `GET /api/docs-json` return HTTP `200 OK`.

### 4.2 Technical Diagnosis
In `PrismaService.ping()`, the health check runs `SELECT 1`, which succeeds against Railway PostgreSQL. However, table queries fail because Prisma migrations have not been applied to the remote Railway database instance (or table schema drift exists). In `railway.json`, the deployment start command is `node dist/src/main.js` without running `npx prisma migrate deploy`.

### 4.3 Action Under Non-Negotiable Rules
As dictated by **Rule A1 (STRICT READ-ONLY / NO BACKEND CHANGES)**:
- We do NOT modify backend files, Dockerfile, or Railway configuration.
- We report this finding as an external operational blocker for live staging data verification.
- Mobile development will construct typed DTOs and contract tests based on the verified OpenAPI 3.0 specification (`/api/docs-json`), with sanitized fixtures until the backend migration is executed by DevOps.
