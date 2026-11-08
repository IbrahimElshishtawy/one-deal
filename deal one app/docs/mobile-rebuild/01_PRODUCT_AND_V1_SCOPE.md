# 01 — Product and V1 Scope Specification

**Project:** Deal One (صفقة ون) Mobile Application  
**Target Market:** Egypt (Egyptian Classifieds Marketplace)  
**Date:** November 8, 2026  
**Status:** DEFINED & ALIGNED

---

## 1. Product Identity and Strategic Positioning

Deal One (صفقة ون) is a modern, high-performance, mobile-first classifieds marketplace engineered specifically for the Egyptian market. It bridges buyers and sellers across key consumer and industrial categories with localized features (Egyptian mobile number OTP, governorates and districts hierarchy, Arabic dialect and transliteration search, and EGP currency formatting).

### Scalability Ambition (Design Target)
- **Catalog Design Target:** Capable of indexing and browsing ~2,000,000 active listings smoothly.
- **User Base Target:** 100,000 active registered customers in Year 1.
- *Architectural Implication:* Bounded memory pagination, efficient local caching, lazy widget building, query debouncing, and defensive network resource management.

---

## 2. In-Scope Product Verticals (V1)

The V1 marketplace serves six primary Egyptian economic sectors:
1. **Real Estate (عقارات):** Apartments, villas, commercial spaces, land (sale and rent).
2. **Cars & Vehicles (سيارات ومركبات):** Used and new cars, motorcycles, auto parts.
3. **Building Materials & Electricity (مواد بناء وتأسيس):** Cement, steel, electrical supplies, plumbing.
4. **Home & Engineering Services (خدمات منزلية وهندسية):** Contractors, technicians, maintenance.
5. **Home Appliances & Décor (أجهزة منزلية وديكور):** Refrigerator, TV, furniture, kitchenware.
6. **Fashion & Accessories (أزياء وإكسسوارات):** Clothes, shoes, watches, personal care.

---

## 3. Core V1 Mobile Capabilities & Feature Matrix

| Domain | In V1 Scope | Implementation Specification |
|---|:---:|---|
| **Authentication** | **YES** | Egyptian Phone (`+20...`) + SMS OTP (`/api/v1/auth/otp/*`). JWT access + refresh rotation. Password login fallback. |
| **User Profile & Accounts** | **YES** | Multi-tenant account switching, individual profile, seller account onboarding (`/api/v1/accounts`). |
| **Categories & Dynamic Taxonomy** | **YES** | Root category hierarchy (`GET /api/v1/categories`), subcategory dynamic fields (`GET /api/v1/categories/:slug/fields`). |
| **Listings Lifecycle** | **YES** | Browse feed, filter by category/location/price, listing detail, seller listings management (`GET/POST/PUT/DELETE /api/v1/listings`). |
| **Availability Management** | **YES** | Seller toggles availability (`PATCH /api/v1/listings/:id/availability`: `available`, `reserved`, `sold`). |
| **Search & Discovery** | **YES** | Trigram text search (`GET /api/v1/search`), Egyptian governorates/cities (`GET /api/v1/locations/governorates`), distance radius. |
| **Favorites** | **YES** | Server-synced favorites list (`GET /api/v1/favorites`), add/remove (`POST /api/v1/favorites/:id`, `DELETE`). |
| **Media Handling** | **YES** | Presigned S3/R2 direct image upload (up to 10 photos per listing) via `/api/v1/media/presigned` & `/api/v1/media/confirm`. |
| **Contact Reveal & Anti-Scraping** | **YES** | Seller contact info is hidden by default. Reveal endpoint (`POST /api/v1/quotas/contact-reveals/reveal/:listingId`) enforces daily quotas. Direct WhatsApp and dialer deep linking. |
| **Abuse Reporting** | **YES** | User reporting of fraudulent/inappropriate listings (`POST /api/v1/moderation/reports`). |

---

## 4. Explicit V1 Exclusions (Out of Scope for Initial Mobile Release)

To prevent architectural bloat and maintain alignment with verified backend capabilities:
1. **NO E-Commerce Cart or Checkout:** The mobile app is a peer-to-peer and merchant classifieds platform, NOT a retail store. The old mock cart and checkout flows for building materials and appliances were unauthorized and are completely excluded from V1.
2. **NO In-App Payment Escrow:** No direct credit card checkouts for purchasing goods. (Paymob payment for classified listing promotions/featured bumps is reserved for subsequent monetization phases).
3. **NO Video Upload / Cloudflare Stream in Initial Foundation Slice:** While OpenAPI mentions `videoStreamUid`, video uploading and reels are deferred until image-based listing workflows are rock solid.
4. **NO Delivery Logistics / Courier Booking:** Shipping calculators and staged shipments are excluded.
5. **NO Unverified WebSocket Real-Time Chat:** Initial buyer-seller interaction is mediated through the audited Contact Reveal workflow and WhatsApp linking.

---

## 5. Security & Privacy Non-Negotiables

1. **Zero Phone Leaks in Public Feeds:** Public listing JSON must never contain unmasked seller phone numbers.
2. **Enforce Contact Reveal Quota:** Calling seller phone numbers MUST go through the server contact reveal endpoint to respect user daily limits and track lead metrics.
3. **Strict Client-Side Redaction:** Logs, analytics, and crash breadcrumbs must strip Egyptian phone numbers, JWT tokens, and OTP codes.
