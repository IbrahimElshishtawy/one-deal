# Deal One — Profile & Real Estate UI Implementation Report

## 1. الشاشات التي تم تنفيذها

| # | الشاشة | المسار / الملف الرئيسي | الحالة |
|---|---|---|---|
| 1 | **Profile** | `lib/features/accounts/presentation/screens/profile_screen.dart` | مكتمل ومتصل بالـ Backend |
| 2 | **Edit Account Details** | `lib/features/accounts/presentation/screens/edit_account_page.dart` | مكتمل ومتصل بالـ Backend |
| 3 | **Conversations (+ Chat Thread)** | `lib/features/conversations/presentation/pages/conversations_page.dart` + `conversation_chat_page.dart` | مكتمل ومتصل بالـ Backend |
| 4 | **Notification** | `lib/features/notifications/presentation/pages/notifications_page.dart` | مكتمل ومتصل بالـ Backend |
| 5 | **Non Notification (Empty State)** | `lib/features/notifications/presentation/widgets/non_notification_empty_state.dart` | مكتمل وقابل لإعادة الاستخدام |
| 6 | **Map View** | `lib/features/real_estate/presentation/pages/real_estate_map_page.dart` | مكتمل باستخدام `flutter_map` |
| 7 | **Photo Gallery (+ Fullscreen Zoom)** | `lib/features/real_estate/presentation/pages/photo_gallery_page.dart` | مكتمل مع Hero + `InteractiveViewer` |
| 8 | **Real Estate Details** | `lib/features/real_estate/presentation/pages/real_estate_details_page.dart` | مكتمل ومتصل بالـ Backend |
| 9 | **Real Estate Reels Viewer** | `lib/features/real_estate/presentation/pages/real_estate_reels_page.dart` | مكتمل مع Pagination + Lifecycle Pause |

---

## 2. الصور المرجعية التي تم تطبيقها

تم فحص وتطبيق الصور التسعة كاملة من:
`ui/"Design For "DealOna/All Home pages/All Pages for Home - Real Estate and Land/`

1. `Profile.png`
2. `Edit account details.png`
3. `Conversations.png`
4. `Notification.png`
5. `Non Notification.png`
6. `Map View.png`
7. `Photo Gallery.png`
8. `Real Estate Details.png`
9. `Real Estate Reels Viewer.png`

---

## 3. Widgets والملفات التي تم إنشاؤها

### Core Design System & Shared States
- `lib/core/design_system/deal_one_design_tokens.dart` — Design Tokens موحدة (Colors, Surfaces, Shadows, Card Decorations, Button/Icon sizes).
- `lib/core/design_system/deal_one_ui_states.dart` — `DealOneSubPageHeader`, `DealOneAvatar`, `DealOneEmptyStateView`, `DealOneErrorStateView`, `DealOneLoadingList`, `DealOnePrivacyFooter`.

### Profile & Edit Account (`features/accounts`)
- `lib/features/accounts/domain/entities/user_profile_entity.dart`
- `lib/features/accounts/domain/repositories/user_profile_repository.dart`
- `lib/features/accounts/data/repositories/user_profile_repository_impl.dart`
- `lib/features/accounts/presentation/providers/user_profile_providers.dart`
- `lib/features/accounts/presentation/widgets/profile_user_card.dart`
- `lib/features/accounts/presentation/widgets/profile_quick_stats_row.dart`
- `lib/features/accounts/presentation/widgets/profile_business_banner.dart`
- `lib/features/accounts/presentation/widgets/profile_menu_card.dart`
- `lib/features/accounts/presentation/widgets/profile_bottom_nav.dart`
- `lib/features/accounts/presentation/widgets/profile_settings_sheet.dart`
- `lib/features/accounts/presentation/widgets/edit_account_avatar_section.dart`
- `lib/features/accounts/presentation/widgets/edit_account_form_card.dart`
- `lib/features/accounts/presentation/screens/edit_account_page.dart`

### Conversations (`features/conversations`)
- `lib/features/conversations/domain/entities/conversation_entity.dart`
- `lib/features/conversations/domain/repositories/conversations_repository.dart`
- `lib/features/conversations/data/repositories/conversations_repository_impl.dart`
- `lib/features/conversations/presentation/providers/conversations_providers.dart`
- `lib/features/conversations/presentation/widgets/conversation_filter_header.dart`
- `lib/features/conversations/presentation/widgets/conversation_card.dart`
- `lib/features/conversations/presentation/pages/conversations_page.dart`
- `lib/features/conversations/presentation/pages/conversation_chat_page.dart`

### Notifications (`features/notifications`)
- `lib/features/notifications/domain/entities/user_notification_entity.dart`
- `lib/features/notifications/domain/repositories/user_notifications_repository.dart`
- `lib/features/notifications/data/repositories/user_notifications_repository_impl.dart`
- `lib/features/notifications/presentation/providers/user_notifications_providers.dart`
- `lib/features/notifications/presentation/widgets/notification_filter_bar.dart`
- `lib/features/notifications/presentation/widgets/notification_item_card.dart`
- `lib/features/notifications/presentation/widgets/non_notification_empty_state.dart`
- `lib/features/notifications/presentation/pages/notifications_page.dart`

### Real Estate Map, Gallery, Details & Reels (`features/real_estate`)
- `lib/features/real_estate/domain/entities/reel_item_entity.dart`
- `lib/features/real_estate/data/repositories/reels_repository.dart`
- `lib/features/real_estate/presentation/providers/reels_providers.dart`
- `lib/features/real_estate/presentation/widgets/map_property_preview_card.dart`
- `lib/features/real_estate/presentation/widgets/map_floating_controls.dart`
- `lib/features/real_estate/presentation/pages/real_estate_map_page.dart`
- `lib/features/real_estate/presentation/widgets/gallery_hero_viewer.dart`
- `lib/features/real_estate/presentation/widgets/gallery_thumbnail_grid.dart`
- `lib/features/real_estate/presentation/pages/photo_gallery_page.dart`
- `lib/features/real_estate/presentation/widgets/real_estate_details_hero.dart`
- `lib/features/real_estate/presentation/widgets/real_estate_specs_grid.dart`
- `lib/features/real_estate/presentation/widgets/real_estate_description_card.dart`
- `lib/features/real_estate/presentation/widgets/real_estate_location_preview.dart`
- `lib/features/real_estate/presentation/pages/real_estate_details_page.dart`
- `lib/features/real_estate/presentation/widgets/reel_overlay_controls.dart`
- `lib/features/real_estate/presentation/pages/real_estate_reels_page.dart`

### Tests
- `test/features/profile_and_real_estate_ui_test.dart`

---

## 4. الملفات التي تم تعديلها

- `lib/core/network/api_endpoints.dart` — إضافة `videoFeed`, `videoUploadToken`, `conversationsStream`.
- `lib/core/routing/route_names.dart` — إضافة مسارات `editAccount`, `conversations`, `conversationChat`, `realEstateMap`, `realEstateGallery`, `realEstateReels`.
- `lib/app/app_router.dart` — ربط جميع المسارات الجديدة مع انتقالات مخصصة (`glide`, `verticalLift`, `reveal`).
- `lib/features/listings/domain/entities/listing_entity.dart`, `lib/features/listings/data/dto/listing_dto.dart`, `lib/features/listings/data/mappers/listing_mapper.dart` — دعم `latitude`, `longitude`, `sellerAvatarUrl` بشكل متوافق مع الإصدارات السابقة.
- `lib/features/listings/presentation/screens/listing_detail_screen.dart` — توجيه إعلانات العقارات تلقائياً إلى `RealEstateDetailsPage`.
- `lib/features/accounts/presentation/screens/profile_screen.dart` — إعادة بناء شاشة الملف الشخصي وفق `Profile.png` مع الحفاظ على التوافق الكامل مع Guest Mode والإعدادات.
- `lib/core/design_system/deal_one_section_chrome.dart` — ربط شريط `معاينات حية` للانتقال مباشرة إلى `RealEstateReelsPage`.
- `lib/features/real_estate/presentation/pages/real_estate_home_page.dart` — إضافة زر مختصر لفتح `Map View`.

---

## 5. API Endpoints التي تم ربطها

- `GET /users/me` — جلب بيانات المستخدم الحقيقية لشاشتي Profile و Edit Account.
- `PUT /users/me` — تحديث الاسم الكامل والصورة واللغة المفضلة.
- `GET /accounts/my-accounts` و `POST /accounts` — عرض وإنشاء الحساب التجاري.
- `GET /locations/governorates` — قائمة المحافظات والمدن في Edit Account.
- `GET /conversations` — جلب قائمة المحادثات المرتبة حسب آخر رسالة.
- `POST /conversations` — بدء أو استرجاع محادثة لعقار من Real Estate Details / Map View / Reels.
- `GET /conversations/:id/messages` و `POST /conversations/:id/messages` — عرض وإرسال الرسائل داخل المحادثة.
- `GET /notifications` — جلب الإشعارات المرقّمة (`page`, `limit`, `unread`) وعدد غير المقروء.
- `PATCH /notifications/:id/read` و `PATCH /notifications/read-all` — تحديد إشعار واحد أو الكل كمقروء.
- `GET /listings/:id` — جلب تفاصيل العقار والصور والمواصفات.
- `POST /listings/:id/contact` — كشف رقم المعلن ضمن حصة القاهرة اليومية.
- `GET /video-feed?cursor=...&limit=10` — جلب معاينات الفيديو العقارية مع Cursor Pagination.
- `GET /favorites`, `POST /favorites/:id`, `DELETE /favorites/:id` — المفضلة في Profile و Details و Gallery و Reels.

---

## 6. الـ Endpoints والبيانات الناقصة في الـ Backend (تم توثيقها دون اختراع سلوك وهمي)

1. **`PUT /users/me` (Edit Account Details):**
   - `UsersService.updateProfile` يقوم حالياً بتحديث `fullName`, `avatarUrl`, `preferredLanguage` فقط ولا يحفظ `governorateId`, `cityId`, `email` في قاعدة البيانات (رغم وجود `governorateId` و `cityId` في `UpdateProfileDto`). تم إرسالها في الـ request وحفظ اختيار المحافظة والمدينة محلياً في `selectedGovernorateProvider` / `selectedCityProvider` حتى يتم تفعيل حفظها في الـ Backend.
2. **`GET /conversations` (Conversations):**
   - الاستجابة لا تتضمن حالياً `unreadCount` لكل محادثة ولا `verificationStatus` في `sellerAccount`. التطبيق يقرأها تلقائياً إذا أضيفت مستقبلاً، ولا يعرض أرقاماً وهمية في غيابها.
3. **`GET /listings` & `GET /listings/:id` (Map View):**
   - حقول PostGIS (`physicalLocation` / `displayLocation`) من نوع `Unsupported("geometry(Point, 4326)")` في Prisma ولا تُرسل حالياً كـ `latitude` / `longitude` في JSON. تم تجهيز الـ DTO لقراءتها فوراً بمجرد تسلسلها من الـ Backend، مع عرض تنبيه واضح وشفاف على الخريطة عند عدم وجود إحداثيات GPS دقيقة.
4. **Native Video Playback & Gallery Picker:**
   - لم يتم إضافة حزم خارجية جديدة (`video_player`, `image_picker`, `geolocator`) التزاماً بتقليل Dependencies غير الضرورية؛ تم بناء مشغل Reels مرتبط بدورة حياة الشاشة (`WidgetsBindingObserver`) مع Poster/Progress/Pause/Mute، ويمكن ربط `video_player` ببث Cloudflare Stream HLS (`videoHlsUrl`) فور اعتماد الحزمة.

---

## 7. Navigation Routes والأنيميشن

| المسار | الانتقال | الملاحظات |
|---|---|---|
| `/profile` → `/profile/edit` | `CinematicTransitionStyle.glide` | انتقال جانبي RTL-aware |
| `/profile` → `/conversations` → `/conversations/:id` | `CinematicTransitionStyle.glide` | انتقال سلس مع تمرير `ConversationEntity` |
| `/profile` → `/notifications` | `CinematicTransitionStyle.verticalLift` | فتح صندوق الإشعارات مع الحفاظ على Back Stack |
| `/listings/:id` → `/real-estate/gallery/:id` | `CinematicTransitionStyle.reveal` + `Hero` | Hero Animation على صور العقار |
| `/listings/:id` → `/real-estate/map` | `CinematicTransitionStyle.verticalLift` + `AnimatedSwitcher` | Bottom Preview Card متحركة |
| `/real-estate` (Live Previews) → `/real-estate/reels` | `CinematicTransitionStyle.reveal` | عرض رأسي كامل للشاشة |

---

## 8. Responsive Testing Results

- تم اختبار التخطيطات على أحجام صغيرة (`320×640`)، متوسطة (`360×780`)، وأحجام أكبر بدون أي `RenderFlex overflow`.
- تم استخدام `LayoutBuilder` و `ResponsiveContext` (`horizontalScreenPadding`, `isSmallPhone`, `isCompactPhone`, `effectiveTextScale`, `productGridColumnsForWidth`) مع تفادي الأبعاد الثابتة العشوائية، وتكديس الأزرار تلقائياً عند تكبير خط النظام (`effectiveTextScale >= 1.5`).

---

## 9. RTL / LTR Testing Results

- جميع الشاشات تستخدم `EdgeInsetsDirectional` و `PositionedDirectional` و `AlignmentDirectional` وتدعم العربية (`ar` RTL) والإنجليزية (`en` LTR) بالكامل.
- تم اختبار `ProfileScreen` باللغتين `ar` و `en` بدون أخطاء تخطيط.

---

## 10. Performance Notes

- استخدام `ListView.builder` / `SliverList.separated` / `GridView.builder` و `PageView.builder` لجميع القوائم والمعارض والـ Reels.
- استخدام `AppNetworkImage` مع `cacheWidth` / `cacheHeight` و Shimmer placeholder و Error fallback.
- فصل Providers لكل Feature باستخدام `autoDispose` حيثما يلزم، وإيقاف `AnimationController` و `PageController` و `WidgetsBindingObserver` عند التخلص من الشاشات لمنع Memory Leaks.

---

## 11. Test Results

- `flutter analyze`: **0 issues** (No errors, no warnings, no lints).
- `flutter test` على حزمة الاختبارات الجديدة والاختبارات المرجعية: **28/28 passed (All tests passed!)**:
  - `test/features/profile_and_real_estate_ui_test.dart` (9 اختبارات تغطي الشاشات التسعة)
  - `test/features/seven_homes_widget_test.dart`
  - `test/core/routing/app_page_transitions_test.dart`
  - `test/core/notifications/notification_repository_test.dart`
  - `test/features/accounts/accounts_repository_test.dart`
  - `test/features/listings/listings_repository_test.dart`

---

## 12. المشاكل المتبقية

- لا توجد أخطاء تحليل أو اختبارات فاشلة.
- النقاط الموثقة في القسم (6) هي فجوات Backend أو حزم Native اختيارية (GPS / Video HLS / Image Picker) تنتظر قرارك قبل إضافتها أو تعديل الـ Backend.

---

## 13. قرارات مطلوبة منك

1. هل ترغب في تعديل الـ Backend لإرجاع `latitude`/`longitude` في `GET /listings` و `unreadCount` في `GET /conversations` وحفظ `governorateId`/`cityId` في `PUT /users/me`؟
2. هل توافق على إضافة حزم `video_player` (لتشغيل بث Cloudflare Stream HLS في Reels)، و `image_picker` (لاختيار صورة الحساب من المعرض)، و `geolocator` (لتحديد موقع المستخدم الحي على الخريطة) إلى `pubspec.yaml`؟
