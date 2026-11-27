# 12 — Security & Sensitive Data Flow Diagram

## Overview

This diagram maps the end-to-end handling of all sensitive identifiers, KYC verification documents, and authentication tokens verified in `SensitiveDataCryptoService`, `PrivateDocumentStorageService`, `SellerApplicationService`, `SessionService`, and `AdminAuthService`.

> **Security Policy:** Zero secrets, real tokens, or real PII appear in this document.

## Sensitive Data Flow Diagram

```mermaid
flowchart TB
    subgraph Entry["1. Client Input (TLS / HTTPS Only)"]
        PIIIn["Sensitive Seller Identifiers:\nNational ID | Tax ID\nCommercial Register Number\nAuthorized Representative ID"]
        DocIn["KYC / Commercial Documents:\nPDF, JPG, PNG, WEBP (<=10MB)"]
        CredIn["Auth Credentials:\nPhone OTP | Password | Admin TOTP MFA"]
    end

    subgraph Validation["2. Validation & Guard Boundary (Fastify + NestJS)"]
        Pipe["Global ValidationPipe\n(whitelist + forbidNonWhitelisted)\nBlocks verificationTier injection"]
        DocVal["PrivateDocumentStorageService:\nMIME + Extension + Size + Magic Bytes\n+ Strict Path Traversal Regex"]
        Malware["Malware Scanner Boundary\n(scanDocumentBoundary)\nStatus: SCANNER_NOT_CONFIGURED"]
    end

    subgraph Crypto["3. Cryptographic Protection"]
        KeyRing["AES-256-GCM Versioned Key Ring\nSELLER_PII_ENCRYPTION_KEYS (v1, v2...)\nSELLER_PII_ENCRYPTION_KEY_VERSION\nRandom 96-bit IV + 128-bit Auth Tag\nFormat: enc:<ver>:<iv>:<tag>:<ct>"]
        TokenHash["JWT Signing (15m Access)\n+ SHA-256 Refresh Token Hash\n+ bcrypt Password Hash\n+ AES-256-GCM Admin TOTP Secret"]
    end

    subgraph Storage["4. Encrypted / Isolated Storage"]
        PG[("PostgreSQL\nSellerApplication (TEXT encrypted cols)\nUserSession / StaffSession (hashed RT)\nAuditLog (zero PII metadata)")]
        R2Priv[("Cloudflare R2 Private Bucket\nR2_PRIVATE_BUCKET_NAME\nKey: private/seller-verification/<uid>/<appId>/<uuid>.<ext>\nNEVER served on R2_PUBLIC_DOMAIN")]
    end

    subgraph Access["5. Output Serialization & Access Control"]
        PublicOut["Public APIs (/listings, /search, /accounts)\nONLY: sellerType, verificationStatus,\nverificationTier, verificationBadge\nZERO PII | ZERO Documents"]
        OwnerOut["Seller Own API (/seller-applications/me)\nMasked IDs (**********4567)\nShort-Lived Signed GET (5m, Owner Only)"]
        AdminOut["Admin APIs (/admin/seller-applications/*)\nList/Detail: Masked IDs ONLY\nDocument Access: verification.documents.read\n+ Audited Signed GET (5m) + AuditLog"]
    end

    PIIIn --> Pipe --> KeyRing --> PG
    DocIn --> DocVal --> Malware
    DocVal -->|"SigV4 Presigned PUT (15m) + HEAD Verify"| R2Priv
    CredIn --> Pipe --> TokenHash --> PG

    PG --> PublicOut
    PG -->|"SensitiveDataCryptoService.mask()"| OwnerOut
    PG -->|"SensitiveDataCryptoService.mask()"| AdminOut
    R2Priv -->|"SigV4 Presigned GET (5m)"| OwnerOut
    R2Priv -->|"Audited SigV4 Presigned GET (5m)"| AdminOut
```

## Key Rotation & Privacy Controls

| Control | Implementation | Source File |
| :--- | :--- | :--- |
| **AES-256-GCM Key Rotation** | Comma-separated versioned keys (`SELLER_PII_ENCRYPTION_KEYS="v1:...,v2:..."`); new writes use active version while `v1` and legacy plaintext remain readable; `needsReencryption()` + `reencrypt()` support idempotent migration. | `sensitive-data-crypto.service.ts` |
| **Tamper Detection** | GCM auth tag failure or unknown key version returns `ok: false` without throwing or logging plaintext/ciphertext; `mask()` returns `'********'`. | `sensitive-data-crypto.service.ts` |
| **Admin Masking** | `nationalIdNumber`, `taxIdNumber`, `commercialRegisterNumber`, and `authorizedRepresentativeId` are masked in user responses, admin list responses, and admin detail responses. | `seller-application.service.ts` |
| **Refresh Token Reuse Detection** | Replaying a revoked refresh token revokes the entire `familyId` session tree and logs a high-severity security alert. | `session.service.ts` |
| **Malware Scanner Status** | **Not active yet.** `scanDocumentBoundary()` returns `SCANNER_NOT_CONFIGURED`; MIME, extension, size, magic-byte, and R2 `HEAD` checks are active. | `private-document-storage.service.ts` |
