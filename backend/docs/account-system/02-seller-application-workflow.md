# 02 — Seller Application Workflow

## End-to-End Buyer-to-Seller Conversion Flow

Implemented in `SellerApplicationService` (`src/modules/accounts/services/seller-application.service.ts`) and `SellerApplicationController` (`src/modules/accounts/controllers/seller-application.controller.ts`).

### Step 1: Request Seller Conversion (`NOT_REQUESTED -> DRAFT`)
- **Endpoint**: `POST /api/v1/seller-applications`
- **Guards**: `JwtAuthGuard`, `SellerAuthorizationGuard(CAN_SUBMIT_SELLER_APPLICATION)`, `RateLimitGuard(10/hour)`
- **Behavior**:
  - Rejects if user is already `APPROVED` (`403`/`409`) or `SUSPENDED` (`403`).
  - Rejects duplicate active applications (`DRAFT`, `PENDING`, `UNDER_REVIEW`, `APPROVED`) with `409 Conflict` (`DUPLICATE_SELLER_APPLICATION`), backed by PostgreSQL partial unique index `uq_seller_applications_active_user`.
  - If user has a `REJECTED` application, directs them to `POST /api/v1/seller-applications/me/resubmit` (`409 RESUBMISSION_REQUIRED`).
  - Creates `SellerApplication` in `DRAFT`, sets `User.sellerStatus = "DRAFT"`, records `SellerApplicationHistory`, and logs `SELLER_APPLICATION_CREATED`.

### Step 2: Update Draft (`DRAFT`)
- **Endpoint**: `PATCH /api/v1/seller-applications/me`
- **Behavior**: Allows updating `businessType`, `businessName`, `businessDescription`, `nationalIdNumber`, `taxIdNumber`, `commercialRegisterNumber`, `contactPhone`, `contactEmail`, `cityId`, `address` while in `DRAFT`.

### Step 3: Upload Private Verification Documents (`DRAFT` or `REJECTED`)
1. **Request Presigned Private Upload URL**: `POST /api/v1/seller-applications/me/documents/upload-url`
   - Validates `mimeType` (`application/pdf`, `image/jpeg`, `image/png`, `image/webp`) and `fileSizeBytes` (`1 .. 10,485,760` bytes / 10 MB).
   - Generates canonical private storage key: `private/seller-verification/<userId>/<applicationId>/<uuid>.<ext>` in dedicated private bucket (`R2_PRIVATE_BUCKET_NAME`, never public CDN).
2. **Confirm Uploaded Document**: `POST /api/v1/seller-applications/me/documents`
   - Strictly validates storage key ownership (`ownerSegment === userId` and `appSegment === applicationId`) and blocks public paths or path traversal.
   - Replaces any prior document of the same `documentType` on the editable application.
   - Logs `SELLER_DOCUMENT_UPLOADED`.
3. **Required Documents by Business Type** (`getRequiredDocumentTypes`):
   - `individual`: `national_id_front`, `national_id_back` + `nationalIdNumber` + `businessName`.
   - `company | factory | office | store`: `national_id_front`, `commercial_register`, `tax_card` + `commercialRegisterNumber` + `businessName`.

### Step 4: Submit Application (`DRAFT -> PENDING`)
- **Endpoint**: `POST /api/v1/seller-applications/me/submit`
- **Behavior**:
  - Runs `evaluateApplicationCompleteness()`; rejects with `400 INCOMPLETE_SELLER_APPLICATION` listing `missingFields` and `missingDocuments` if incomplete.
  - Atomically updates `SellerApplication.status = "PENDING"`, `submittedAt = NOW()`, `User.sellerStatus = "PENDING"`, writes `SellerApplicationHistory`, and logs `SELLER_APPLICATION_SUBMITTED`.

### Step 5: Check Status & History
- `GET /api/v1/seller-applications/me`: Returns `sellerStatus`, `roles`, `capabilities`, completeness checklist, and sanitized document metadata (never raw `storageKey` or storage credentials).
- `GET /api/v1/seller-applications/me/history`: Returns chronological transition history.

### Step 6: Resubmission Policy (`REJECTED -> DRAFT | PENDING`)
- **Endpoint**: `POST /api/v1/seller-applications/me/resubmit`
- Allowed only when status is `REJECTED`. Increments `resubmissionCount`.
- If `submitImmediately: true`, validates completeness and transitions directly to `PENDING`; otherwise reopens in `DRAFT` so the applicant can update fields or upload clearer documents.
