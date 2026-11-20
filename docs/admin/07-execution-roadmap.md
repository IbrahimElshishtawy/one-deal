# 07 — Execution Roadmap (Phases 00–11)

> **Status:** `PHASE 00 COMPLETE` — Ready for Phase 01 & Phase 02 after user review.

---

## Execution Sequence & Dependencies

| Phase | Name | Scope & Primary Deliverables | Exit Criteria / Verification Gate |
| :--- | :--- | :--- | :--- |
| **00** | **Backend Discovery** *(Done)* | Full inspection of NestJS backend, Prisma schema, auth, security, and API gaps; `docs/admin/00..08` + `EXECUTION_PROGRESS.md` | All 10 docs created and verified against codebase |
| **06-A / 02** | **Database Foundation & Admin Auth** | Extend `StaffRole`, `StaffUser`, `Report`, `User`; add `StaffSession`, `StaffLoginAttempt`, `StaffPasswordResetToken`; install `@fastify/cookie`; build `AdminAuthModule` (`AdminJwtStrategy`, `StaffSessionService`, MFA TOTP, login attempts, password recovery); fix `CORS` allowed headers (`X-CSRF-Token`, `X-Requested-With`) | Prisma migrate succeeds cleanly without data loss; unit + E2E tests verify login, MFA, cookie refresh rotation, reuse detection, logout, and isolation from mobile JWTs |
| **03** | **Granular RBAC & 9 Roles Seed** | Define canonical permission catalog (`38` permissions); implement `PermissionsGuard` + `@Permissions()`; seed 9 initial roles (`Super Admin` .. `Security Auditor`); enforce last-Super-Admin & anti-privilege-escalation checks | RBAC matrix test suite validates every role against allowed & forbidden endpoints (`403` on unauthorized, `200/201` on authorized) |
| **05 / 06-B** | **Backend Admin Modules & Migrations** | Implement/extend all 16 `/api/v1/admin/*` modules (`AdminDashboard`, `AdminUsers`, `AdminListings`, `AdminCategories`, `AdminModeration` fixes, `AdminNotifications`, `AdminCms`, `AdminChatOversight`, `AdminAnalytics`, `AdminStaff`, `AdminAuditLogs`, `AdminSystemHealth`, `AdminFeatureFlags`, `PlatformSettings` fixes) | `npm run build`, `eslint`, unit tests, E2E tests, AND existing mobile Flutter API E2E suites all pass 100% |
| **01** | **React Admin Web App Foundation** | Scaffold independent React + TypeScript + Vite/React Router (or Next.js App Router if chosen, keeping React modular structure) + Tailwind + shadcn/ui + TanStack Query + TanStack Table + RHF + Zod + i18next (AR RTL / EN LTR) + Theme (Dark/Light) + centralized `apiClient` | Typecheck, lint, Vitest smoke tests, auth silent refresh & RTL/LTR layout verified |
| **04 / 07** | **16 Admin Modules UI & Enterprise UX** | Build all 16 React feature modules with loading/empty/error states, permission gates, confirmation dialogs, global search, breadcrumbs, charts (Recharts), and real backend integration | Zero mock data; every visible button executes real backend call; Vitest integration tests pass |
| **08** | **Performance & Scale Hardening** | Composite DB indexes (`audit_log`, `listings`, `reports`, `users`), Redis caching for dashboard KPIs & feature flags with mutation invalidation, BullMQ bulk jobs, load testing (`k6`) | P95 latency targets verified under pagination & large-dataset load tests |
| **09** | **Security Audit & Pen-Test Checks** | Verify CSRF, XSS (CSP/DOMPurify if rich text), SQLi (parameterized Prisma), rate limiting, cookie flags, privilege escalation, CSV formula injection protection on exports, audit log completeness | Security test suite & checklist pass with 0 critical/high findings |
| **10** | **Full QA & Regression Testing** | TypeScript, ESLint, Vitest unit/integration, Playwright E2E (all roles, RTL/LTR, responsive), NestJS unit & E2E, Flutter mobile backward-compatibility verification | 100% executed & passing tests (no skipped assertions) |
| **11** | **Production Readiness & Deployment** | Verify Railway env vars (`CORS_ORIGIN`, `TRUST_PROXY`, `JWT_*`, `RESEND_API_KEY`), HTTPS/HSTS, `Secure` cookies, health/metrics monitoring, DB backup & rollback runbook | Formal `GO` sign-off in `EXECUTION_PROGRESS.md` |

---

## Sequencing Recommendation for Backend + React Workflow

Because you are building the frontend in **React**:
1. **Execute Backend Phases (06 Schema -> 02 Admin Auth -> 03 RBAC -> 05 Admin Endpoints)** first (or module-by-module alongside React), so Swagger (`/api/docs`) and the real `/api/v1/admin/*` endpoints are live and contract-tested before React features consume them.
2. **Never break mobile:** After every backend migration or module edit, run the existing `backend/test/*.e2e-spec.ts` suites (`auth.e2e-spec.ts`, `data-flow.e2e-spec.ts`, `all-modules-audit.e2e-spec.ts`, `security-integration.e2e-spec.ts`) to guarantee Flutter compatibility.
