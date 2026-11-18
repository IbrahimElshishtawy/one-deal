# Deal One Backend — Staging Git & Change Review

**Review Date:** 2026-11-19  
**Active Validation Branch:** `staging-validation` (branched cleanly from `main` at `8d444da`)  
**Previous Remediation Commit:** `8d444da` (`feat(security): add production security verification report and implement metrics authentication guard`, 36 files changed, +2863/-206)  
**Pre-Remediation Baseline:** `6c65615` (`fix/review-findings`)

---

## 1. Git Integrity & Secret Exposure Audit

- **Branch isolation:** Work on staging validation is isolated on `staging-validation` with zero destructive git operations, no auto-commit, and no auto-push.
- **Staged/unstaged changes on `staging-validation` (new fixes caught during live E2E & staging validation):**
  1. `src/main.ts` — Fixed critical Fastify startup crash (`FastifyError: Content type parser 'application/json' already present`) by switching to NestJS native `{ rawBody: true }` instead of duplicate `addContentTypeParser('application/json')`.
  2. `src/modules/video/video.controller.ts` — Converted `Buffer | string` `req.rawBody` cleanly for Cloudflare Stream HMAC verification.
  3. `src/modules/auth/services/session.service.ts` & `src/modules/auth/strategies/jwt.strategy.ts` — Fixed real same-second race condition caught by `test/new-features.e2e-spec.ts` where `resetPassword` followed by immediate re-login within the same Unix second rejected the new token (`iat <= revokedBefore`). Now denylists every active `sid` + uses millisecond-precision `iatMs` cutoff.
  4. `load-tests/k6-5000-online.js` — Fixed hardcoded `http://localhost:3000/health/ready` on line 69 to derive from `BASE_URL`.
  5. `load-tests/k6-staging-validation.js` (new) — Gradual-ramp staging k6 validation script.
  6. `test/staging-validation.e2e-spec.ts` (new) — Real PostgreSQL/PostGIS + Real Redis E2E validation suite.
  7. `.env.staging.example` (new) — Sanitized staging environment template (no real credentials).
- **Migrations check:** Zero Prisma migrations were modified or deleted (`prisma/migrations/` untouched; all 8 migrations verified intact via `scripts/migrate-deploy.js`).
- **Production config check:** No production Railway environment variables, domains, or databases were modified.
- **Accidental secrets check:** Verified `.env` is gitignored (`../.gitignore`) and zero real credentials exist in tracked/untracked files. Note: historical commit `de78088` previously committed hardcoded default JWT strings (addressed in `docs/JWT_PRODUCTION_SECRET_ROTATION.md`).
