# 05 — Flutter Seller Verification API Alignment (Workstream E)

## Implemented Changes (`MOB-001`)

| Layer | File | Changes |
| :--- | :--- | :--- |
| **Domain Enums** | `deal one app/lib/features/seller_verification/domain/enums/seller_verification_enums.dart` | Added `VerificationStatus.withdrawn('WITHDRAWN')`, `isWithdrawable`, `isRenewable`, `SellerApplicationType.renewal`, `SellerDocumentStatus.purged`. |
| **API Endpoints** | `deal one app/lib/core/network/api_endpoints.dart` | Added `sellerApplicationMeWithdraw = '/seller-applications/me/withdraw'` and `sellerApplicationMeRenew = '/seller-applications/me/renew'`. |
| **Data & Repo** | `seller_verification_remote_datasource.dart`, `seller_verification_repository.dart`, `seller_verification_repository_impl.dart` | Added typed `withdrawApplication()` and `startVerificationRenewal()` methods using backend responses as sole source of truth. |
| **State Management** | `seller_verification_notifiers.dart` | Added `VerificationTrackingNotifier.withdrawApplication()` and `startRenewal()` with eligibility guards, loading/error states, and full Riverpod snapshot refresh. |
| **Presentation & L10n** | `verification_tracking_page.dart`, `tracking_and_upgrade_widgets.dart`, `verification_step3_status_view.dart`, `seller_verification_strings.dart` | Added AR/EN labels for `WITHDRAWN`, wired **Withdraw Application** (when `isWithdrawable`) and **Renew Verification** (when `isRenewable`) actions in `VerificationTrackingPage`. |
| **Tests** | `deal one app/test/features/seller_verification/seller_verification_phase2_test.dart` | Verified `WITHDRAWN`/`EXPIRED` parsing, `isWithdrawable`/`isRenewable` rules, and endpoint paths. |
