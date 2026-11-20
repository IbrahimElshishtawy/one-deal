# Deal One Enterprise Admin Dashboard — Deployment & Operations Guide

## 1. Prerequisites

- Node.js `>= 20.x` & npm
- PostgreSQL `16+` with PostGIS & `pg_trgm`
- Redis Cache instance + Redis Queue instance (BullMQ)

---

## 2. Backend Environment Configuration (`backend/.env`)

Reference `backend/.env.example` and configure the following **mandatory** variables in production:

### Core & CORS / Cookie Security
```env
NODE_ENV=production
PORT=3000
API_BASE_URL=https://one-deal-cjjt-production.up.railway.app/api/v1
# Explicit origin allowlist including the deployed Admin SPA domain (no wildcard '*')
CORS_ORIGIN=https://admin.dealone.eg,https://one-deal-cjjt-production.up.railway.app
TRUST_PROXY=1
ENABLE_SWAGGER=false
ENABLE_WORKERS=true
```

### JWT, Admin Sessions, MFA & Cookies
```env
JWT_ACCESS_SECRET=<64-hex-char-mobile-access-secret>
JWT_REFRESH_SECRET=<64-hex-char-distinct-mobile-refresh-secret>

# Separate Admin signing & encryption keys (strongly recommended distinct secrets)
ADMIN_JWT_ACCESS_SECRET=<64-hex-char-admin-access-secret>
ADMIN_JWT_ACCESS_EXPIRES_IN=15m
ADMIN_REFRESH_EXPIRES_DAYS=7
ADMIN_MFA_ENCRYPTION_KEY=<64-hex-char-32-byte-encryption-key>

ADMIN_COOKIE_NAME=dealone_admin_rt
# Leave ADMIN_COOKIE_DOMAIN blank unless sharing across parent domains; set 'none' if SPA and API live on different origins (requires HTTPS)
ADMIN_COOKIE_DOMAIN=
ADMIN_COOKIE_SAMESITE=none
ADMIN_PUBLIC_URL=https://admin.dealone.eg
```

### Bootstrap Super Admin (Production Initial Seed)
```env
BOOTSTRAP_SUPER_ADMIN_EMAIL=superadmin@yourdomain.com
BOOTSTRAP_SUPER_ADMIN_PASSWORD=<strong-unique-password>
```
> **Note:** In `NODE_ENV=production`, `seed-admin-rbac.ts` **never** seeds default dev staff passwords (`AdminStaff!2026`). Only the 9 roles, baseline feature flags/settings/CMS, and the explicitly configured `BOOTSTRAP_SUPER_ADMIN_*` account are created.

---

## 3. Frontend Environment Configuration (`admin-web/.env`)

Reference `admin-web/.env.example`:
```env
VITE_API_BASE_URL=https://one-deal-cjjt-production.up.railway.app/api/v1
VITE_APP_NAME=Deal One Admin
```

---

## 4. Deployment Runbook

### Step 1: Apply Additive Database Migration & Generate Client
```bash
cd backend
npm ci
npx prisma generate
npx prisma migrate deploy
```

### Step 2: Seed 9 Enterprise Roles & Super Admin
```bash
cd backend
npm run prisma:seed:admin
```

### Step 3: Build & Start Backend (Railway)
```bash
cd backend
npm run build
npm run start:prod
```
Verify readiness: `curl -fsS https://one-deal-cjjt-production.up.railway.app/health/ready`.

### Step 4: Build & Deploy React Admin SPA (`admin-web/`)
```bash
cd admin-web
npm ci
npm run build
```
Serve `admin-web/dist/` behind any TLS-terminated static host/CDN (Cloudflare Pages, Vercel, Nginx, or S3+CloudFront) configured with SPA history fallback (`/* -> /index.html` with `200`).

---

## 5. Cross-Origin Cookie Checklist (When Admin UI & API Use Different Domains)
1. Ensure `CORS_ORIGIN` includes exact HTTPS origin of the Admin SPA (e.g. `https://admin.dealone.eg`).
2. Set `ADMIN_COOKIE_SAMESITE=none` in backend environment (cookie flag `Secure: true` is automatically enabled when `SameSite=none` or `NODE_ENV=production`).
3. Keep `X-Requested-With: dealone-admin-web` header on `/admin/auth/refresh` and `/admin/auth/logout` (automatically sent by `admin-web/src/core/api/client.ts`) and ensure CDN/WAF does not strip `X-Requested-With` or `Set-Cookie`.

---

## 6. Post-Deploy Smoke Verification & Rollback
1. Sign in with `BOOTSTRAP_SUPER_ADMIN_EMAIL`, enroll TOTP MFA in **Security Profile**, and verify session rotation on browser reload.
2. Check `/admin/system/health` shows PostgreSQL, PostGIS, Redis Cache, Redis Queue, and Outbox healthy.
3. **Zero-Downtime Rollback:** All DB changes in `20261120000001_add_enterprise_admin_platform` are strictly additive. Previous backend releases continue reading all pre-existing marketplace columns uninterrupted while the admin SPA is taken offline if needed.
