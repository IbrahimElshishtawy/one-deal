# 02 — Seller Types & Verification Requirements Engine

## Supported Seller Types

The system supports three configurable seller types (`SellerType` enum) while maintaining backward compatibility with `AccountType` (`individual`, `company`, `factory`, `office`, `store`):

1. **`INDIVIDUAL`**
   - Required profile fields: `businessName`, `nationalIdNumber` (encrypted at rest).
   - Optional/contextual fields: `contactPhone`, `contactEmail`, `cityId`, `address`.
   - Baseline documents: `national_id_front` (required), `national_id_back` (required), `proof_of_address` (optional globally, required for `real-estate`).

2. **`BUSINESS`**
   - Required profile fields: `businessName`, `commercialRegisterNumber`.
   - Optional/contextual fields: `taxIdNumber` (encrypted), `authorizedRepresentativeName`, `authorizedRepresentativeId` (encrypted), `address`.
   - Baseline documents: `national_id_front` (authorized representative, required), `commercial_register` (required), `tax_card` (required), `legal_representation_proof` (optional).

3. **`SERVICE_PROVIDER`**
   - Required profile fields: `businessName`, `nationalIdNumber` (encrypted), `serviceCategory`.
   - Optional/contextual fields: `yearsOfExperience`, `qualifications`, `professionalLicenseNumber`, `portfolioUrl`.
   - Baseline documents: `national_id_front` (required), `national_id_back` (required), `qualification_certificate` (required), `portfolio_document` (optional).

## Marketplace Sections (Deal One Categories)

Requirements are configurable per Deal One root category (`MarketplaceSection` enum):

| Section Slug | Category Name | Default Section-Specific Rules |
| --- | --- | --- |
| `real-estate` | Real Estate | `BUSINESS`: `business_license` (required, expiration); `INDIVIDUAL`: `proof_of_address` (required) |
| `building-materials` | Building Materials & Electricity | `BUSINESS`: `proof_of_address` (warehouse/storefront, required) |
| `services` | Home & Engineering Services | `SERVICE_PROVIDER`: `professional_license` (required, expiration) |
| `home-appliances` | Appliances & Home Décor | `BUSINESS`: `business_license` (optional) |
| `cars` | Cars | `BUSINESS`: `business_license` (dealership license, required, expiration) |
| `fashion` | Clothes & Accessories | `BUSINESS`: `portfolio_document` (optional, images only, max 5 MB) |

## Requirements Resolution Algorithm

`SellerVerificationRequirementsService.getApplicableRequirements(sellerType, marketplaceSections)`:
1. Queries all active, non-deleted `SellerVerificationRequirement` rows matching `sellerType IN [requested, 'ALL']` and `marketplaceSection IS NULL OR marketplaceSection IN sections`.
2. Deduplicates by `documentType` so that a section-specific rule overrides a global rule for the same document type.
3. If multiple selected sections define the same `documentType`, `isRequired = true` takes precedence.
4. Returns sorted requirements with `acceptedMimeTypes`, `maxFileSizeBytes`, `requiresExpiration`, `verificationRules`, and `version`.

## Admin Configurability & Versioning

Admins with `verification.requirements.manage` (or `settings.update`) can create, update, and soft-delete requirements via `/api/v1/admin/seller-applications/requirements`. Every update automatically increments `version` and records an audit event (`VERIFICATION_REQUIREMENT_CREATED`, `VERIFICATION_REQUIREMENT_UPDATED`, `VERIFICATION_REQUIREMENT_DEACTIVATED`).
