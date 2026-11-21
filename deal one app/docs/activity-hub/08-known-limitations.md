# 08 — Known Limitations & Implementation Status Matrix

## Status Classification

| Capability | Status | Notes |
|---|---|---|
| Activity & Commerce Hub Shell (`/activity-hub`) | **Fully Implemented & Tested** | Header, summary bar, 4-tab bar, search, RTL/LTR, Light/Dark |
| Shopping Cart (Local Persistent) | **Fully Implemented & Tested** | Add, variant picker (size/color), qty validation, subtotal/total, save-for-later, remove confirmation |
| Favorites (6-Sector Filter & Search) | **Fully Implemented & Tested** | Uses live `/api/v1/favorites` repository, 6-sector filter, search, section navigation |
| 6 Marketplace Integrations | **Fully Implemented** | Header basket -> Hub; Appliances/Materials/Fashion -> Cart; Services/Real Estate/Cars -> Booking sheet; Materials -> RFQ sheet |
| Checkout / In-App Payment | **Not Implemented (V1 Excluded)** | V1 is free listings without payment; checkout CTA routes to direct seller contact |
| Bookings & Appointments Sync | **Implemented, Awaiting Backend Support** | Full UI, DTOs, status mapping, and validation; backend `/bookings` endpoints do not exist yet |
| Technician Live Tracking | **Not Implemented (Backend-Dependent)** | Hidden until backend provides real tracking data |
| RFQ Submission & Quotations | **Implemented, Awaiting Backend Support** | Full UI, DTOs, status mapping, and form validation; backend `/rfqs` endpoints do not exist yet |
