# 04 — API Endpoint Inventory & V1 Contract Matrix

**Project:** Deal One (صفقة ون) Mobile Integration  
**Base URL:** `https://one-deal-cjjt-production.up.railway.app/api/v1`  
**OpenAPI Specification Version:** `3.0.0` (Title: `Deal One API (صفقة ون)`, Version: `1.0.0`)  
**Audit Date:** November 8, 2026  
**Auditor:** API Integration Engineer & Independent Reviewer  
**Total Documented Endpoints:** 61 Operations  

---

## 1. Classification Methodology & Definitions

Every API endpoint discovered in the production OpenAPI specification (`/api/docs-json`) and verified against backend source code (`backend/src/modules/**`) is classified into one of four mutually exclusive statuses:

- **`VERIFIED`:** Contract documented AND live production response verified through safe, non-mutating HTTP requests (e.g. Health checks, Swagger endpoints, 400 validation pipe checks, 401 auth guard checks).
- **`CONTRACT_ONLY`:** Wire contract is fully documented and matched with backend Controllers/DTOs, but live production response cannot be verified without performing prohibited mutations (POST/PUT/DELETE) or using user credentials.
- **`BLOCKED`:** A verified defect on the live production server prevents normal operation (specifically, database table queries returning HTTP 500).
- **`OUT_OF_SCOPE`:** Functionality explicitly excluded from V1 mobile scope (Admin-only operations, V2 Payments, V2 Cloudflare Stream video).

---

## 2. Complete V1 API Operations Matrix (61 Endpoints)

### 2.1 Health & Infrastructure (Diagnostic Probes)
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `HealthController_getLiveness` | `GET` | `/health/live` | Public | None | `200`: `{ success: true, data: { status: 'ok', uptimeSeconds, memoryRssMb, timestamp } }` | **VERIFIED** | Live probe returns 200 OK |
| `HealthController_getLiveness` | `GET` | `/health/liveness` | Public | None | `200`: Same as `/health/live` | **VERIFIED** | Alias for Kubernetes/Railway |
| `HealthController_getReadiness` | `GET` | `/health/ready` | Public | None | `200`: `{ success: true, data: { status: 'healthy', checks: { database, postgis, redis_cache, redis_queue, workers } } }` | **VERIFIED** | Live probe returns 200 OK; PostGIS 3.4 & DB connected |
| `HealthController_getReadiness` | `GET` | `/health/readiness` | Public | None | `200`: Same as `/health/ready` | **VERIFIED** | Alias for readiness probe |

---

### 2.2 Authentication & Identity
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `AuthController_sendOtp` | `POST` | `/api/v1/auth/otp/send` | Public | Header: `x-trace-id` (opt)<br>Body: `SendOtpDto` (`{ phone: string }`) | `200`: `{ success: true, data: { cooldownSeconds, timeoutMinutes } }`<br>`400`: Validation failed<br>`429`: Cooldown/Rate limit | **VERIFIED (Validation)**<br>**CONTRACT_ONLY (Live)** | Verified: `phone: '123'` returns HTTP 400 with Egyptian phone validation issue |
| `AuthController_resendOtp` | `POST` | `/api/v1/auth/otp/resend` | Public | Header: `x-trace-id`<br>Body: `ResendOtpDto` (`{ phone: string }`) | `200`: `{ success: true, data: { cooldownSeconds } }`<br>`429`: Cooldown active | **CONTRACT_ONLY** | Triggers SMS OTP dispatch (mutation) |
| `AuthController_verifyOtp` | `POST` | `/api/v1/auth/otp/verify` | Public | Header: `x-trace-id`<br>Body: `VerifyOtpDto` (`{ phone, code: string }`) | `200`: `{ success: true, data: { accessToken, refreshToken, user, account } }`<br>`400`: Invalid/Expired code | **CONTRACT_ONLY** | Requires valid SMS OTP code |
| `AuthController_loginWithPassword` | `POST` | `/api/v1/auth/login` | Public | Header: `x-trace-id`<br>Body: `LoginPasswordDto` (`{ phone, password }`) | `200`: `{ success: true, data: { accessToken, refreshToken, user, account } }`<br>`401`: Invalid credentials | **CONTRACT_ONLY** | Password fallback login |
| `AuthController_loginPasswordAlias` | `POST` | `/api/v1/auth/password/login` | Public | Body: `LoginPasswordDto` | `200`: Same as `/api/v1/auth/login` | **CONTRACT_ONLY** | Alias |
| `AuthController_refreshToken` | `POST` | `/api/v1/auth/refresh` | Public | Header: `x-trace-id`<br>Body: `RefreshTokenDto` (`{ refreshToken / refresh_token }`) | `200`: `{ success: true, data: { accessToken, refreshToken } }`<br>`401`: Revoked / Token reuse detected | **CONTRACT_ONLY** | Token family rotation |
| `AuthController_refreshTokenAlias` | `POST` | `/api/v1/auth/token/refresh` | Public | Body: `RefreshTokenDto` | `200`: Same as `/api/v1/auth/refresh` | **CONTRACT_ONLY** | OpenAPI compatibility alias |
| `AuthController_logout` | `POST` | `/api/v1/auth/logout` | Public/Bearer | Body: `RefreshTokenDto` | `200`: `{ success: true, data: { message } }` | **CONTRACT_ONLY** | Revokes active session family in DB |
| `AuthController_getActiveSessions` | `GET` | `/api/v1/auth/sessions` | Bearer | None | `200`: `{ success: true, data: ActiveSessionResponseDto[] }`<br>`401`: Unauthorized | **VERIFIED (Guard)**<br>**CONTRACT_ONLY (Data)** | Verified: probe without token returns HTTP 401 UNAUTHORIZED |
| `AuthController_terminateAllSessions` | `POST` | `/api/v1/auth/sessions/terminate-all` | Bearer | None | `200`: `{ success: true, data: { message } }`<br>`401`: Unauthorized | **CONTRACT_ONLY** | Revokes all active sessions |
| `AuthController_getCurrentIdentity` | `GET` | `/api/v1/auth/me` | Bearer | None | `200`: `{ success: true, data: { id, phone, fullName, role, status } }` | **CONTRACT_ONLY** | Reads directly from JWT claims |

---

### 2.3 Users Profile
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `UsersController_getMyProfile` | `GET` | `/api/v1/users/me` | Bearer | None | `200`: `{ success: true, data: UserProfile }`<br>`401`: Unauthorized | **CONTRACT_ONLY** | Full user profile from DB |
| `UsersController_updateMyProfile` | `PUT` | `/api/v1/users/me` | Bearer | Body: `UpdateProfileDto` (`{ fullName, avatarUrl, preferredLanguage, governorateId, cityId }`) | `200`: `{ success: true, data: UpdatedUser }` | **CONTRACT_ONLY** | Updates profile fields |
| `UsersController_deleteMyAccount` | `DELETE` | `/api/v1/users/me` | Bearer | None | `200`: `{ success: true, data: { message } }` | **CONTRACT_ONLY** | Soft-deletes user account |

---

### 2.4 Multi-Tenant Accounts & Branches
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `AccountsController_createAccount` | `POST` | `/api/v1/accounts` | Bearer | Body: `CreateAccountDto` (`{ displayName, accountType, slug?, bio?, logoUrl?, bannerUrl? }`) | `201`: `{ success: true, data: Account }` | **CONTRACT_ONLY** | Onboard business/merchant account |
| `AccountsController_getMyAccounts` | `GET` | `/api/v1/accounts/my-accounts` | Bearer | None | `200`: `{ success: true, data: Account[] }` | **CONTRACT_ONLY** | Accessible user accounts |
| `AccountsController_getAccountById` | `GET` | `/api/v1/accounts/{id}` | Public | Path: `id: string` (UUID/slug) | `200`: `{ success: true, data: AccountPublicProfile }`<br>`404`: Not found | **BLOCKED** | Public seller profile query fails (DB table error) |
| `AccountsController_createBranch` | `POST` | `/api/v1/accounts/{id}/branches` | Bearer | Body: `CreateBranchDto` (`{ name, areaId, address, phone?, isMain? }`) | `201`: `{ success: true, data: Branch }` | **CONTRACT_ONLY** | Add branch to account |
| `AccountsController_getAccountBranches` | `GET` | `/api/v1/accounts/{id}/branches` | Public | Path: `id: string` | `200`: `{ success: true, data: Branch[] }` | **BLOCKED** | Public branch query fails (DB table error) |
| `AccountsController_updateBranch` | `PUT` | `/api/v1/accounts/{id}/branches/{branchId}` | Bearer | Body: `UpdateBranchDto` | `200`: `{ success: true, data: Branch }` | **CONTRACT_ONLY** | Update branch details |
| `AccountsController_deleteBranch` | `DELETE` | `/api/v1/accounts/{id}/branches/{branchId}` | Bearer | Path: `id`, `branchId` | `200`: `{ success: true, data: { message } }` | **CONTRACT_ONLY** | Delete branch |
| `AccountsController_getAccountMembers` | `GET` | `/api/v1/accounts/{id}/members` | Bearer | Path: `id: string` | `200`: `{ success: true, data: AccountMember[] }` | **CONTRACT_ONLY** | Team members list |
| `AccountsController_inviteMember` | `POST` | `/api/v1/accounts/{id}/members/invite` | Bearer | Body: `InviteMemberDto` (`{ phone, role }`) | `201`: `{ success: true, data: AccountMember }` | **CONTRACT_ONLY** | Invite team member |
| `AccountsController_removeMember` | `DELETE` | `/api/v1/accounts/{id}/members/{userId}` | Bearer | Path: `id`, `userId` | `200`: `{ success: true, data: { message } }` | **CONTRACT_ONLY** | Remove team member |

---

### 2.5 Categories & Dynamic Attributes
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `CategoriesController_getCategoryTree` | `GET` | `/api/v1/categories` | Public | None | `200`: `{ success: true, data: CategoryTreeNode[] }` | **BLOCKED** | **Live production probe returns HTTP 500** (`INTERNAL_SERVER_ERROR`) |
| `CategoriesController_getCategoryBySlug` | `GET` | `/api/v1/categories/{slug}` | Public | Path: `slug: string` | `200`: `{ success: true, data: CategoryDetail }`<br>`404`: Not found | **BLOCKED** | Live probe returns HTTP 500 |
| `CategoriesController_getCategoryFields` | `GET` | `/api/v1/categories/{slug}/fields` | Public | Path: `slug: string` | `200`: `{ success: true, data: CategoryFieldSchema[] }` | **BLOCKED** | Live probe returns HTTP 500 |

---

### 2.6 Geographic Locations
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `LocationsController_getGovernorates` | `GET` | `/api/v1/locations/governorates` | Public | None | `200`: `{ success: true, data: GovernorateWithCities[] }` | **BLOCKED** | **Live production probe returns HTTP 500** (`INTERNAL_SERVER_ERROR`) |
| `LocationsController_getAreasByCity` | `GET` | `/api/v1/locations/cities/{cityId}/areas` | Public | Path: `cityId: number` | `200`: `{ success: true, data: Area[] }`<br>`404`: Not found | **BLOCKED** | Live probe returns HTTP 500 |

---

### 2.7 Listings & Marketplace Operations
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `ListingsController_getFeed` | `GET` | `/api/v1/listings` | Public | Query: `FilterListingsDto` (`categoryId, q, sort, minPrice, maxPrice, cursor, limit, ...`) | `200`: `{ success: true, data: ListingSummary[], meta: { nextCursor, limit, hasMore } }` | **BLOCKED** | **Live production probe returns HTTP 500** (`INTERNAL_SERVER_ERROR`) |
| `ListingsController_getById` | `GET` | `/api/v1/listings/{id}` | Public | Path: `id: string` (UUID) | `200`: `{ success: true, data: ListingDetail }`<br>`404`: Not found | **BLOCKED** | Live probe returns HTTP 500 |
| `ListingsController_createListing` | `POST` | `/api/v1/listings` | Bearer | Body: `CreateListingDto` (`categoryId, cityId, title, description, price, mediaKeys, attributes`) | `201`: `{ success: true, data: ListingDetail }` | **CONTRACT_ONLY** | Creates new classified ad |
| `ListingsController_updateListing` | `PUT` | `/api/v1/listings/{id}` | Bearer | Body: `UpdateListingDto` | `200`: `{ success: true, data: ListingDetail }` | **CONTRACT_ONLY** | Updates listing fields |
| `ListingsController_deleteListing` | `DELETE` | `/api/v1/listings/{id}` | Bearer | Path: `id: string` | `200`: `{ success: true, data: { message } }` | **CONTRACT_ONLY** | Soft-deletes listing |
| `ListingsController_updateAvailability` | `PATCH` | `/api/v1/listings/{id}/availability` | Bearer | Body: `UpdateAvailabilityDto` (`availabilityStatus: 'available' \| 'reserved' \| 'sold'`) | `200`: `{ success: true, data: { id, availabilityStatus } }` | **CONTRACT_ONLY** | Updates operational availability |
| `ListingsController_updateStatus` | `PATCH` | `/api/v1/listings/{id}/status` | Bearer | Body: `UpdateListingStatusDto` (`status: 'hidden' \| 'published' \| 'archived'`) | `200`: `{ success: true, data: { id, publicationStatus } }` | **CONTRACT_ONLY** | Publication state machine |
| `ListingsController_submitForModeration` | `POST` | `/api/v1/listings/{id}/submit` | Bearer | Path: `id: string` | `200`: `{ success: true, data: { id, moderationStatus } }` | **CONTRACT_ONLY** | Submits draft for review |
| `ListingsController_contactSeller` | `POST` | `/api/v1/listings/{id}/contact` | Bearer | Path: `id: string` | `200`: `{ success: true, data: { phone, sellerName, whatsapp, remainingDailyQuota, dailyLimit } }`<br>`403`: Daily quota exceeded | **CONTRACT_ONLY** | **Core contact reveal flow with quota enforcement** |
| `ListingsController_revealContactAlias` | `POST` | `/api/v1/listings/{id}/reveal-contact` | Bearer | Path: `id: string` | `200`: Same as `:id/contact` | **CONTRACT_ONLY** | Alias for mobile client |

---

### 2.8 Search & Dynamic Discovery
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `SearchController_search` | `GET` | `/api/v1/search` | Public | Query: `SearchQueryDto` (`q, query, categorySlug, sort, minPrice, maxPrice, lat, lng, radiusKm, ...`) | `200`: `{ success: true, data: SearchResultItem[], meta: { total, nextCursor } }` | **BLOCKED** | **Live production probe returns HTTP 500** (`INTERNAL_SERVER_ERROR`) |

---

### 2.9 Favorites & Saved Listings
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `FavoritesController_getMyFavorites` | `GET` | `/api/v1/favorites` | Bearer | None | `200`: `{ success: true, data: FavoriteListingItem[] }` | **CONTRACT_ONLY** | Saved listings |
| `FavoritesController_addFavorite` | `POST` | `/api/v1/favorites/{listingId}` | Bearer | Path: `listingId: string` | `200`: `{ success: true, data: { favorited: true } }` | **CONTRACT_ONLY** | Add favorite |
| `FavoritesController_removeFavorite` | `DELETE` | `/api/v1/favorites/{listingId}` | Bearer | Path: `listingId: string` | `200`: `{ success: true, data: { favorited: false } }` | **CONTRACT_ONLY** | Remove favorite |
| `FavoritesController_getMyFavoritesAlias` | `GET` | `/api/v1/listings/favorites` | Bearer | None | `200`: Same as `/api/v1/favorites` | **CONTRACT_ONLY** | Alias |
| `FavoritesController_toggleFavoriteAlias` | `POST` | `/api/v1/listings/{listingId}/favorite` | Bearer | Path: `listingId: string` | `200`: `{ success: true, data: { favorited: boolean } }` | **CONTRACT_ONLY** | Toggle favorite alias |

---

### 2.10 Media Engine (Image Direct Upload)
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `MediaController_requestImageUploadUrls` | `POST` | `/api/v1/media/images/upload-url` | Bearer | Body: `PresignedUploadDto` (`contentTypes: ['image/jpeg', 'image/png', 'image/webp']`) | `200`: `{ success: true, data: { urls: Array<{ uploadUrl, storageKey, publicUrl, contentType }> } }` | **CONTRACT_ONLY** | Generates presigned R2/S3 URLs |
| `MediaController_requestUploadUrlsAlias` | `POST` | `/api/v1/media/upload-urls` | Bearer | Body: `PresignedUploadDto` | `200`: Same as above | **CONTRACT_ONLY** | Alias |
| `MediaController_requestPresignedUrlAlias` | `POST` | `/api/v1/media/presigned-url` | Bearer | Body: `PresignedUploadDto` | `200`: Same as above | **CONTRACT_ONLY** | Alias |
| `MediaController_confirmUpload` | `POST` | `/api/v1/media/confirm-upload` | Bearer | Body: `ConfirmUploadDto` (`storageKey, listingId?, sortOrder?, isPrimary?`) | `200`: `{ success: true, data: { confirmed: true, mediaId } }`<br>`403`: Forbidden (key mismatch) | **CONTRACT_ONLY** | Confirms direct upload |
| `MediaController_confirmUploadAlias` | `POST` | `/api/v1/media/confirm` | Bearer | Body: `ConfirmUploadDto` | `200`: Same as above | **CONTRACT_ONLY** | Alias |

---

### 2.11 Quotas & Usage Tracking
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `QuotasController_getMyQuotaUsage` | `GET` | `/api/v1/quotas/my-usage` | Bearer | None | `200`: `{ success: true, data: { dailyContactReveals: { used, limit, remaining, resetsAt } } }` | **CONTRACT_ONLY** | Africa/Cairo daily quota |

---

### 2.12 Reporting (Trust & Safety)
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `ModerationController_fileReport` | `POST` | `/api/v1/reports` | Bearer | Body: `CreateReportDto` (`reason, listingId?, reportedAccountId?, reportedUserId?, notes?, details?`) | `201`: `{ success: true, data: { reportId, status: 'pending' } }` | **CONTRACT_ONLY** | User filing abuse report |

---

### 2.13 Chat & Messages (P2P Messaging)
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `ChatController_getMyConversations` | `GET` | `/api/v1/conversations` | Bearer | None | `200`: `{ success: true, data: ConversationSummary[] }` | **CONTRACT_ONLY** | User active conversations |
| `ChatController_startConversation` | `POST` | `/api/v1/conversations` | Bearer | Body: `StartConversationDto` (`{ listingId: string }`) | `201`: `{ success: true, data: ConversationDetail }` | **CONTRACT_ONLY** | Start/retrieve conversation |
| `ChatController_getMessages` | `GET` | `/api/v1/conversations/{id}/messages` | Bearer | Query: `page, limit`<br>Path: `id` | `200`: `{ success: true, data: ChatMessage[] }`<br>`403`: Forbidden | **CONTRACT_ONLY** | Paginated chat history |
| `ChatController_sendMessage` | `POST` | `/api/v1/conversations/{id}/messages` | Bearer | Body: `SendMessageDto` (`{ text: string }`) | `201`: `{ success: true, data: ChatMessage }`<br>`403`: Forbidden | **CONTRACT_ONLY** | Sends text message |

---

### 2.14 Push Notifications
| Operation ID | Method | Path | Auth | Request Schema | Response Status & Schema | Status | Evidence / Notes |
|---|---|---|:---:|---|---|:---:|---|
| `NotificationsController_registerToken` | `POST` | `/api/v1/notifications/device-token` | Bearer | Body: `{ token: string, platform: 'ios' \| 'android' }` | `200`: `{ success: true, data: { registered: true } }` | **CONTRACT_ONLY** | Registers FCM token |

---

### 2.15 Explicit Out-of-Scope Operations (Excluded from V1 Mobile Client)
| Operation ID | Method | Path | Tag | Scope Rationale | Status |
|---|---|---|---|---|:---:|
| `AdminCategoriesController_createCategory` | `POST` | `/api/v1/admin/categories` | Admin | Internal back-office administration only | **OUT_OF_SCOPE** |
| `AdminCategoriesController_upsertField` | `POST` | `/api/v1/admin/categories/{id}/fields` | Admin | Internal back-office administration only | **OUT_OF_SCOPE** |
| `ModerationController_getPendingListings` | `GET` | `/api/v1/admin/moderation/listings` | Admin | Moderator review queue | **OUT_OF_SCOPE** |
| `ModerationController_adjudicateListing` | `POST` | `/api/v1/admin/moderation/listings/{id}/decision` | Admin | Moderator adjudication action | **OUT_OF_SCOPE** |
| `ModerationController_getQueue` | `GET` | `/api/v1/admin/moderation/queue` | Admin | Internal moderation queue | **OUT_OF_SCOPE** |
| `ModerationController_adjudicate` | `PATCH` | `/api/v1/admin/moderation/reports/{id}` | Admin | Moderator report resolution | **OUT_OF_SCOPE** |
| `ModerationController_getAuditLogs` | `GET` | `/api/v1/admin/audit-logs` | Admin | Security audit trail | **OUT_OF_SCOPE** |
| `VideoController_getUploadToken` | `POST` | `/api/v1/media/video/upload-token` | Video | Cloudflare Stream video token (V2 feature) | **OUT_OF_SCOPE** |
| `VideoController_handleWebhook` | `POST` | `/api/v1/media/video/webhook` | Video | Cloudflare Stream server-to-server webhook | **OUT_OF_SCOPE** |
| `VideoController_getVideoFeed` | `GET` | `/api/v1/video-feed` | Video | Vertical video swipe feed (V2 feature) | **OUT_OF_SCOPE** |

---

## 3. Inventory Summary Statistics

- **Total Documented OpenAPI Endpoints:** 61
- **V1 In-Scope Endpoints:** 51
- **V1 Out-of-Scope Endpoints (Admin & Video):** 10
- **VERIFIED Endpoints (Probed & Verified on Live Production):** 6 (Health probes, Swagger, Auth validation & guard behavior)
- **CONTRACT_ONLY Endpoints (Documented & Matched with Source Code):** 36
- **BLOCKED Endpoints (Failing with HTTP 500 on Production):** 9 (`/categories`, `/categories/:slug`, `/categories/:slug/fields`, `/locations/governorates`, `/locations/cities/:cityId/areas`, `/listings`, `/listings/:id`, `/search`, `/accounts/:id`, `/accounts/:id/branches`)
