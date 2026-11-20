# 05 — API Integration Matrix (Backend ↔ React Admin Dashboard)

> **Namespace Convention:** All admin operations are served under `/api/v1/admin/*` to preserve 100% backward compatibility with Flutter mobile routes under `/api/v1/*`.  
> **Strategy:** **REUSE** existing endpoints where sufficient, **EXTEND** existing admin endpoints safely, and **ADD** only missing admin capabilities.

---

## 1. Authentication, Sessions & Self-Profile (`/api/v1/admin/auth`)

| Action | Method & Path | Strategy | Required Permission / Guard | Notes for React Client |
| :--- | :--- | :--- | :--- | :--- |
| Admin Login | `POST /api/v1/admin/auth/login` | **ADD** | Public + `RateLimitGuard` | Accepts `{ email, password }`; returns `{ requiresMfa: true, mfaChallengeToken }` OR `{ admin, accessToken, expiresIn }` + sets `HttpOnly` refresh cookie |
| Verify MFA Challenge | `POST /api/v1/admin/auth/mfa/verify` | **ADD** | Public + `RateLimitGuard` | Exchanges `{ mfaChallengeToken, code }` (TOTP or recovery code) for `{ admin, accessToken }` + `HttpOnly` cookie |
| Silent Token Refresh | `POST /api/v1/admin/auth/refresh` | **ADD** | Cookie + CSRF Header + `RateLimitGuard` | Reads `dealone_admin_rt` `HttpOnly` cookie; rotates `StaffSession` & cookie; returns new in-memory `accessToken` |
| Admin Logout | `POST /api/v1/admin/auth/logout` | **ADD** | `AdminJwtAuthGuard` (or Cookie) | Revokes `StaffSession`, denylists access token JTI/SID in Redis, clears `HttpOnly` cookie |
| Current Admin Identity | `GET /api/v1/admin/auth/me` | **ADD** | `AdminJwtAuthGuard` | Returns `{ id, email, fullName, mfaEnabled, role: { id, name }, permissions: string[] }` |
| Active Admin Sessions | `GET /api/v1/admin/auth/sessions` | **ADD** | `AdminJwtAuthGuard` | Lists active `StaffSession` records for current admin |
| Revoke Own Session | `DELETE /api/v1/admin/auth/sessions/:sessionId` | **ADD** | `AdminJwtAuthGuard` | Revokes specific session + Redis denylist |
| Setup MFA (QR/Secret) | `POST /api/v1/admin/auth/mfa/setup` | **ADD** | `AdminJwtAuthGuard` | Generates encrypted TOTP secret & `otpauth://` URI |
| Enable MFA | `POST /api/v1/admin/auth/mfa/enable` | **ADD** | `AdminJwtAuthGuard` | Verifies TOTP code, enables MFA, returns one-time recovery codes |
| Disable MFA | `POST /api/v1/admin/auth/mfa/disable` | **ADD** | `AdminJwtAuthGuard` | Requires current password + valid TOTP code |
| Change Password | `POST /api/v1/admin/auth/password/change` | **ADD** | `AdminJwtAuthGuard` | Verifies current password, updates hash, revokes other sessions |
| Forgot Password | `POST /api/v1/admin/auth/password/forgot` | **ADD** | Public + `RateLimitGuard` | Sends single-use reset link via `EmailService` (always 200 OK) |
| Reset Password | `POST /api/v1/admin/auth/password/reset` | **ADD** | Public + `RateLimitGuard` | Consumes reset token, updates hash, revokes all `StaffSession`s |

---

## 2. Module-by-Module Integration Matrix

### Module 1: Overview Dashboard
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/dashboard/overview` | **ADD** | `analytics.read` (or any authenticated admin with scoped cards) | KPI counts (users, sellers, listings by status, pending moderation, open reports, pending verifications, 24h activity) |
| `GET /api/v1/admin/dashboard/charts` | **ADD** | `analytics.read` | Time-series data (7d/30d/90d listings & user registrations, category breakdown) |

### Module 2: Users & Seller Accounts Management
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/users` | **ADD** | `users.read` | Paginated search/filter (`q`, `status`, `isActive`, `isDemo`, `verified`, `sortBy`, `sortOrder`) |
| `GET /api/v1/admin/users/:id` | **ADD** | `users.read` | User details + owned accounts + active session count + recent reports/listings summary |
| `PATCH /api/v1/admin/users/:id` | **ADD** | `users.update` | Update editable admin metadata (`fullName`, `preferredLanguage`, `isActive`) with audit diff |
| `POST /api/v1/admin/users/:id/suspend` | **ADD** | `users.suspend` | Temporarily suspend user (`reason`, `suspendedUntil?`), sets `isActive: false` + revokes all `UserSession`s |
| `POST /api/v1/admin/users/:id/ban` | **ADD** | `users.ban` | Permanently ban user (`reason`), sets `isActive: false` + revokes all `UserSession`s + hides active listings |
| `POST /api/v1/admin/users/:id/activate` | **ADD** | `users.suspend` or `users.update` | Restore active status & clear suspension/ban flags |
| `POST /api/v1/admin/users/:id/revoke-sessions` | **ADD** | `users.suspend` | Force-logout all mobile sessions for user |
| `GET /api/v1/admin/accounts` | **ADD** | `users.read` | Paginated list of seller business/individual accounts (`accountType`, `verificationStatus`, `isActive`) |
| `PATCH /api/v1/admin/accounts/:id/status` | **ADD** | `users.update` | Activate/deactivate seller account |

### Module 3: Listings Management
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/listings` | **ADD** | `listings.read` | Full paginated/sorted/filtered list across ALL moderation, publication & availability states |
| `GET /api/v1/admin/listings/:id` | **ADD** | `listings.read` | Full listing detail including hidden/rejected/pending + moderation history + media |
| `GET /api/v1/admin/moderation/listings` | **EXTEND** | `listings.read` | Keep backward compatible; support `AdminJwtAuthGuard` + `PermissionsGuard` |
| `POST /api/v1/admin/moderation/listings/:id/decision` | **EXTEND** | `listings.approve` / `listings.reject` | Fix `staffId`, `approvedAt`, `publicationStatus: 'unpublished'` on reject; support `listings.approve` & `listings.reject` |
| `PATCH /api/v1/admin/listings/:id/hide` | **ADD** | `listings.hide` | Set `publicationStatus: 'hidden'` + audit log |
| `PATCH /api/v1/admin/listings/:id/publish` | **ADD** | `listings.hide` / `listings.approve` | Restore hidden approved listing to `published` |
| `DELETE /api/v1/admin/listings/:id` | **ADD** | `listings.delete` | Soft-delete (`deletedAt = now()`, `publicationStatus = 'archived'`) + audit log |
| `POST /api/v1/admin/listings/bulk-decision` | **ADD** | `listings.approve` / `listings.reject` | Transactional bulk approve/reject/hide with bounded batch size (max 100 IDs) |

### Module 4: Categories Management
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/categories` | **REUSE** | Public / Authenticated | Public active tree (also used for reference) |
| `GET /api/v1/admin/categories` | **ADD** | `categories.read` | Full hierarchy including `isActive: false` categories & listing counts |
| `POST /api/v1/admin/categories` | **EXTEND** | `categories.create` | Switch guard to `PermissionsGuard`; add audit log |
| `PATCH /api/v1/admin/categories/:id` | **ADD** | `categories.update` | Update names, slug, icon, parent, `sortOrder`, `isActive` + invalidate all category caches |
| `DELETE /api/v1/admin/categories/:id` | **ADD** | `categories.delete` | Delete if 0 listings & 0 children; otherwise reject or soft-deactivate |
| `GET /api/v1/admin/categories/:id/fields` | **ADD** | `categories.read` | List all dynamic fields (including inactive) |
| `POST /api/v1/admin/categories/:id/fields` | **EXTEND** | `categories.update` | Switch guard to `PermissionsGuard`; add audit log; fix slug/UUID cache key invalidation |
| `PATCH /api/v1/admin/categories/:id/fields/:fieldId` | **ADD** | `categories.update` | Update or toggle `isActive` on a dynamic field |
| `DELETE /api/v1/admin/categories/:id/fields/:fieldId` | **ADD** | `categories.delete` | Remove/deactivate dynamic field |

### Module 5: Reports & Moderation
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/moderation/queue` | **EXTEND** | `reports.read` | Add filters (`status`: `all\|open\|resolved\|dismissed`, `reason`, `assignedToStaffId`, `q`) + pagination |
| `POST /api/v1/admin/moderation/reports/:id/assign` | **ADD** | `reports.assign` | Assign report to a `StaffUser` (`assignedToStaffId`) + audit log |
| `PATCH /api/v1/admin/moderation/reports/:id` | **EXTEND** | `reports.resolve` | **Fix bug:** persist `dto.status` (`resolved` \| `dismissed` \| `open`) instead of hardcoded `'resolved'`, set `resolvedByStaffId` |
| `GET /api/v1/admin/moderation/logs` | **ADD** | `reports.read` | Paginated history from `moderation_log` with staff details |

### Module 6: Verification Management
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/moderation/verifications` | **EXTEND** | `verification.read` | Add filters (`status`: `pending\|approved\|rejected\|all`, `documentType`, `q`) |
| `GET /api/v1/admin/moderation/verifications/:id` | **ADD** | `verification.read` | Full submission details, document URL, seller account, reviewer metadata |
| `POST /api/v1/admin/moderation/verifications/:id/decision` | **EXTEND** | `verification.approve` / `verification.reject` | Fix `reviewedByStaffId` and `ModerationLog.staffId` attribution |

### Module 7: Notifications Management
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/notifications` | **ADD** | `notifications.read` | List recent admin notification dispatches/logs |
| `POST /api/v1/admin/notifications/send` | **ADD** | `notifications.send` | Send targeted user push+in-app notification or segmented broadcast (via BullMQ background worker) |

### Module 8: CMS Management
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/cms` | **ADD** | `cms.read` | List banners, announcements, static pages (`type`, `isActive`, pagination) |
| `POST /api/v1/admin/cms` | **ADD** | `cms.manage` | Create CMS item (AR/EN title & body, image, link, schedule) |
| `PATCH /api/v1/admin/cms/:id` | **ADD** | `cms.manage` | Update or publish/unpublish CMS item |
| `DELETE /api/v1/admin/cms/:id` | **ADD** | `cms.manage` | Delete CMS item |
| `GET /api/v1/cms/public` *(optional)* | **ADD** | Public | Read-only active banners/announcements for mobile/web |

### Module 9: Chat Oversight
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/chat/conversations` | **ADD** | `chat.oversight.read` | Search/filter conversations (e.g. flagged/reported listings or participants) |
| `GET /api/v1/admin/chat/conversations/:id/messages` | **ADD** | `chat.oversight.read` | Read-only message history; **writes mandatory `CHAT_OVERSIGHT_VIEWED` entry to `AuditLog`** |
| `PATCH /api/v1/admin/chat/conversations/:id/status` | **ADD** | `chat.oversight.read` + `reports.resolve` | Close/freeze abusive conversation |

### Module 10: Analytics & Reports
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/analytics/overview` | **ADD** | `analytics.read` | Period-over-period growth metrics (`from`, `to`, `granularity`) |
| `GET /api/v1/admin/analytics/listings` | **ADD** | `analytics.read` | Breakdown by category, governorate, listing kind, moderation SLA |
| `GET /api/v1/admin/analytics/revenue` | **ADD** | `analytics.read` | Promotion packages & payments aggregations (even when `ENABLE_V2_PAYMENTS=false`, queries `payments` safely) |
| `GET /api/v1/admin/analytics/export` | **ADD** | `analytics.read` | Audited CSV/JSON export with row limit |

### Module 11: Admin Management (`StaffUser`)
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/staff` | **EXTEND** | `admins.read` | Add pagination, search (`q`), `roleId`, `isActive` filters |
| `GET /api/v1/admin/staff/:id` | **ADD** | `admins.read` | Admin details + active session count + recent audit actions |
| `POST /api/v1/admin/staff` | **EXTEND** | `admins.create` | Prevent assigning role with permissions caller lacks; send welcome/setup email |
| `PATCH /api/v1/admin/staff/:id` | **EXTEND** | `admins.update` | Prevent deactivating/demoting last Super Admin or self-deactivation; revoke `StaffSession`s on deactivate/role change |
| `POST /api/v1/admin/staff/:id/revoke-sessions` | **ADD** | `admins.update` | Force-logout target admin across all sessions |
| `POST /api/v1/admin/staff/:id/reset-mfa` | **ADD** | `admins.update` | Reset MFA for locked-out admin (with Super Admin confirmation + audit log) |

### Module 12: Roles & Permissions (`StaffRole`)
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/staff/permissions` | **ADD** | `roles.read` | Authoritative permission catalog grouped by module (AR/EN labels) |
| `GET /api/v1/admin/staff/roles` | **EXTEND** | `roles.read` | Include staff user count per role & `isSystem` flag |
| `POST /api/v1/admin/staff/roles` | **EXTEND** | `roles.create` | Validate permission strings against catalog; reject escalation |
| `PATCH /api/v1/admin/staff/roles/:id` | **ADD** | `roles.update` | Update role name/description/permissions; protect `super_admin` permissions from truncation |
| `DELETE /api/v1/admin/staff/roles/:id` | **ADD** | `roles.delete` | Reject if `isSystem=true` or if `staffUsers` are assigned |

### Module 13: Audit Logs
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/audit-logs` | **EXTEND** | `audit_logs.read` | Add filters (`actorType`, `actorId`, `action`, `targetEntity`, `targetId`, `ipAddress`, `from`, `to`, `q`), sorting, pagination |
| `GET /api/v1/admin/audit-logs/:id` | **ADD** | `audit_logs.read` | Inspect full `diffPayload` & metadata |
| `GET /api/v1/admin/audit-logs/export` | **ADD** | `audit_logs.read` | Audited CSV/JSON export (`AUDIT_LOGS_EXPORTED` logged) |

### Module 14: System Health
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /health/ready` | **REUSE** | Public | Infrastructure probe |
| `GET /api/v1/admin/system/health` | **ADD** | `system_health.read` | Rich JSON: DB latency, PostGIS, Redis Cache & Queue memory/ping, BullMQ queue counts, Outbox pending/failed count, Email/FCM/R2 config status |

### Module 15: Feature Flags
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/feature-flags` | **ADD** | `feature_flags.read` | List all feature flags |
| `POST /api/v1/admin/feature-flags` | **ADD** | `feature_flags.manage` | Create flag (`key`, `name`, `isEnabled`, `rolloutPercentage`, `rules`) |
| `PATCH /api/v1/admin/feature-flags/:key` | **ADD** | `feature_flags.manage` | Toggle/update flag + invalidate Redis cache + audit log |
| `DELETE /api/v1/admin/feature-flags/:key` | **ADD** | `feature_flags.manage` | Delete non-system flag |

### Module 16: Platform Settings
| Endpoint | Strategy | Permission | Purpose |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/admin/settings` | **REUSE / EXTEND** | `settings.read` | Switch guard to `@Permissions('settings.read')` |
| `GET /api/v1/admin/settings/:key` | **REUSE / EXTEND** | `settings.read` | Switch guard to `@Permissions('settings.read')` |
| `PUT /api/v1/admin/settings/:key` | **EXTEND** | `settings.update` | Switch guard to `@Permissions('settings.update')`; populate `updatedByStaffId` |
