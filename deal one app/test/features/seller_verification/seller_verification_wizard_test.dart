import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/algorithms/seller_verification_algorithms.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/domain/repositories/seller_verification_repository.dart';
import 'package:market_space/features/seller_verification/presentation/pages/seller_verification_wizard_page.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/verification_loading_shimmer.dart';
import 'package:market_space/features/seller_verification/services/document_picker/document_picker_service.dart';

class _MockWizardRepository implements SellerVerificationRepository {
  VerificationStatus status = VerificationStatus.notSubmitted;
  SellerApplicationEntity? savedApp;
  final List<SellerDocumentEntity> uploadedDocs = [];

  @override
  Future<List<SellerVerificationRequirementEntity>> getRequirements({
    required SellerType sellerType,
    List<String> marketplaceSections = const [],
    bool forceRefresh = false,
  }) async =>
      const [];

  @override
  Future<VerificationStatusSnapshot> getMyVerificationStatus({
    bool forceRefresh = false,
  }) async {
    return VerificationStatusSnapshot(
      userId: 'user-1',
      sellerStatus: status,
      application: savedApp,
    );
  }

  @override
  Future<SellerApplicationEntity> createApplication(
    Map<String, dynamic> payload,
  ) async {
    status = VerificationStatus.draft;
    savedApp = SellerApplicationEntity(
      id: 'app-wizard-001',
      userId: 'user-1',
      status: VerificationStatus.draft,
      sellerType: SellerType.fromApi(payload['sellerType']?.toString()),
      businessType:
          BusinessAccountType.fromApi(payload['businessType']?.toString()),
      businessName: payload['businessName']?.toString(),
      businessDescription: payload['businessDescription']?.toString(),
      serviceCategory: payload['serviceCategory']?.toString(),
      contactPhone: payload['contactPhone']?.toString(),
      cityId: payload['cityId'] as int?,
    );
    return savedApp!;
  }

  @override
  Future<SellerApplicationEntity> updateDraft(
    Map<String, dynamic> payload,
  ) async {
    return createApplication(payload);
  }

  @override
  Future<PrivateUploadTargetEntity> requestDocumentUploadUrl({
    required String documentType,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    return PrivateUploadTargetEntity(
      applicationId: savedApp?.id ?? 'app-wizard-001',
      documentType: documentType,
      storageKey: 'private/seller-verification/user-1/app/$documentType.jpg',
      uploadUrl: 'https://private-storage.deal-one.local/upload',
      expiresInSeconds: 600,
      contentType: mimeType,
      maxSizeBytes: 10 * 1024 * 1024,
    );
  }

  @override
  Future<void> uploadDocumentBinary({
    required String uploadUrl,
    required PickedDocumentFile file,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    onSendProgress?.call(file.sizeBytes, file.sizeBytes);
  }

  @override
  Future<SellerDocumentEntity> confirmDocument({
    required String documentType,
    required String storageKey,
    required String originalFileName,
    required String mimeType,
    required int fileSizeBytes,
    String? fileHeaderBase64,
    String? expiresAt,
    String? requirementId,
  }) async {
    final doc = SellerDocumentEntity(
      id: 'doc-${uploadedDocs.length + 1}',
      applicationId: savedApp?.id ?? 'app-wizard-001',
      documentType: documentType,
      originalFileName: originalFileName,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
      status: SellerDocumentStatus.uploaded,
    );
    uploadedDocs.removeWhere((d) => d.documentType == documentType);
    uploadedDocs.add(doc);
    return doc;
  }

  @override
  Future<SellerDocumentEntity> replaceDocument({
    required String documentId,
    required String storageKey,
    required String originalFileName,
    required String mimeType,
    required int fileSizeBytes,
    String? fileHeaderBase64,
    String? expiresAt,
  }) async {
    final existing = uploadedDocs.firstWhere((d) => d.id == documentId);
    return confirmDocument(
      documentType: existing.documentType,
      storageKey: storageKey,
      originalFileName: originalFileName,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
    );
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    uploadedDocs.removeWhere((d) => d.id == documentId);
  }

  @override
  Future<SellerApplicationEntity> submitApplication() async {
    status = VerificationStatus.pending;
    savedApp = SellerApplicationEntity(
      id: savedApp!.id,
      userId: savedApp!.userId,
      status: VerificationStatus.pending,
      sellerType: savedApp!.sellerType,
      businessType: savedApp!.businessType,
      businessName: savedApp!.businessName,
      documents: List.unmodifiable(uploadedDocs),
      submittedAt: DateTime.now(),
    );
    return savedApp!;
  }

  @override
  Future<SellerApplicationEntity> resubmitApplication(
    Map<String, dynamic> payload,
  ) =>
      submitApplication();

  @override
  Future<List<VerificationHistoryItemEntity>> getMyHistory() async => const [];

  @override
  Future<BusinessUpgradeSnapshot> getBusinessUpgradeStatus({
    bool forceRefresh = false,
  }) async =>
      const BusinessUpgradeSnapshot();

  @override
  Future<SellerApplicationEntity> createBusinessUpgrade(
    Map<String, dynamic> payload,
  ) =>
      createApplication(payload);

  @override
  Future<SellerApplicationEntity> submitBusinessUpgrade() =>
      submitApplication();

  @override
  Future<SellerApplicationEntity> resubmitBusinessUpgrade(
    Map<String, dynamic> payload,
  ) =>
      submitApplication();
}

class _MockWizardPicker implements DocumentPickerService {
  // 1x1 valid PNG bytes
  static final Uint8List _validPng = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  @override
  Future<PickedDocumentFile?> pickDocument(DocumentPickSource source) async {
    return PickedDocumentFile(
      fileName: 'verification_doc.png',
      mimeType: 'image/png',
      bytes: _validPng,
    );
  }

  @override
  Future<PickedDocumentFile> readFromFilePath(String path) async {
    return (await pickDocument(DocumentPickSource.file))!;
  }
}

Widget _buildWizardApp({
  required SellerVerificationRepository repo,
  required DocumentPickerService picker,
  ThemeMode themeMode = ThemeMode.light,
}) {
  const govs = [
    GovernorateEntity(
      id: 1,
      nameAr: 'القاهرة',
      nameEn: 'Cairo',
      slug: 'cairo',
      cities: [
        CityEntity(
          id: 10,
          governorateId: 1,
          nameAr: 'مدينة نصر',
          nameEn: 'Nasr City',
          slug: 'nasr-city',
        ),
      ],
    ),
  ];

  return ProviderScope(
    overrides: [
      sellerVerificationRepositoryProvider.overrideWithValue(repo),
      documentPickerServiceProvider.overrideWithValue(picker),
      governoratesProvider.overrideWith((ref) async => govs),
    ],
    child: MaterialApp(
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      themeMode: themeMode,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: SellerVerificationWizardPage(),
      ),
    ),
  );
}

void main() {
  group('SellerVerificationAlgorithms Unit Tests', () {
    test('analyzeNationalId accepts valid 14-digit & Arabic-Indic numerals', () {
      final resAscii = SellerVerificationAlgorithms.analyzeNationalId(
        '29504150101234',
        isArabic: true,
      );
      expect(resAscii.isValid, isTrue);
      expect(resAscii.governorateNameAr, 'القاهرة');
      expect(resAscii.birthDate, DateTime(1995, 4, 15));

      final resArabicDigits = SellerVerificationAlgorithms.analyzeNationalId(
        '٢٩٥٠٤١٥٠١٠١٢٣٤',
        isArabic: true,
      );
      expect(resArabicDigits.isValid, isTrue);
      expect(resArabicDigits.normalizedDigits, '29504150101234');
    });

    test('analyzeNationalId rejects invalid length, invalid date, bad gov code', () {
      expect(
        SellerVerificationAlgorithms.analyzeNationalId(
          '2950415010',
          isArabic: false,
        ).isValid,
        isFalse,
      );
      expect(
        SellerVerificationAlgorithms.analyzeNationalId(
          '29502310101234',
          isArabic: false,
        ).isValid,
        isFalse,
      );
      expect(
        SellerVerificationAlgorithms.analyzeNationalId(
          '29504159901234',
          isArabic: false,
        ).isValid,
        isFalse,
      );
    });

    test('analyzeEgyptianPhone validates local, Arabic numerals, and +20 formats', () {
      final r1 = SellerVerificationAlgorithms.analyzeEgyptianPhone(
        '01012345678',
        isArabic: true,
      );
      expect(r1.isValid, isTrue);
      expect(r1.normalizedE164, '+201012345678');

      final r2 = SellerVerificationAlgorithms.analyzeEgyptianPhone(
        '٠١٢١٢٣٤٥٦٧٨',
        isArabic: true,
      );
      expect(r2.isValid, isTrue);
      expect(r2.normalizedE164, '+201212345678');

      final bad = SellerVerificationAlgorithms.analyzeEgyptianPhone(
        '01912345678',
        isArabic: false,
      );
      expect(bad.isValid, isFalse);
    });

    test('computeReadinessProgress advances proportionally across wizard steps', () {
      final low = SellerVerificationAlgorithms.computeReadinessProgress(
        currentStep: 1,
        officeName: '',
        activityCode: null,
        cityId: null,
        contactPhone: '',
        identityMode: SellerType.individual,
        nationalIdNumber: '',
        commercialRegisterNumber: '',
        hasPrimaryDoc1: false,
        hasPrimaryDoc2: false,
        applicationStatus: VerificationStatus.notSubmitted,
      );
      final high = SellerVerificationAlgorithms.computeReadinessProgress(
        currentStep: 2,
        officeName: 'القمة',
        activityCode: 'real_estate_marketing',
        cityId: 10,
        contactPhone: '01012345678',
        identityMode: SellerType.individual,
        nationalIdNumber: '29504150101234',
        commercialRegisterNumber: '',
        hasPrimaryDoc1: true,
        hasPrimaryDoc2: true,
        applicationStatus: VerificationStatus.draft,
      );
      expect(high, greaterThan(low));
      expect(high, 1.0);
    });
  });

  group('SellerVerificationWizardPage Widget Tests (Light, Dark & Full Flow)', () {
    testWidgets('Full 3-step Light Mode wizard flow validates, uploads, and submits', (tester) async {
      final repo = _MockWizardRepository();
      final picker = _MockWizardPicker();

      await tester.pumpWidget(_buildWizardApp(repo: repo, picker: picker));
      await tester.pumpAndSettle();

      // Step 1 matches Screenshot 1 design elements
      expect(find.text('خطوة 1 من 3'), findsOneWidget);
      expect(find.text('حساب شركاء الأعمال'), findsOneWidget);
      expect(find.text('بيع العقارات يبدأ من هنا'), findsOneWidget);
      expect(find.text('هذا الرقم متاح للتواصل عبر واتساب'), findsOneWidget);
      expect(find.text('ضمان توثيق الحسابات'), findsOneWidget);

      // Tapping continue without filling fails validation cleanly
      await tester.ensureVisible(find.byKey(const Key('wizard_step1_continue_btn')));
      await tester.tap(find.byKey(const Key('wizard_step1_continue_btn')));
      await tester.pumpAndSettle();
      expect(find.text('خطوة 1 من 3'), findsOneWidget);
      expect(find.text('يرجى إدخال اسم المكتب أو الشركة العقارية'), findsOneWidget);

      // Fill Step 1 form
      await tester.enterText(
        find.byKey(const Key('wizard_office_name_input')),
        'القمة للاستثمار العقاري',
      );
      await tester.tap(find.byKey(const Key('wizard_activity_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('activity_option_real_estate_marketing')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('wizard_governorate_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gov_option_1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('wizard_city_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('city_option_10')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('wizard_contact_phone_input')),
        '01012345678',
      );
      await tester.tap(find.byKey(const Key('wizard_whatsapp_checkbox')));
      await tester.pump();

      // Continue to Step 2
      await tester.ensureVisible(find.byKey(const Key('wizard_step1_continue_btn')));
      await tester.tap(find.byKey(const Key('wizard_step1_continue_btn')));
      await tester.pumpAndSettle();

      // Step 2 matches Screenshot 2 design elements
      expect(find.text('خطوة 2 من 3'), findsOneWidget);
      expect(find.text('توثيق الهوية والبيانات'), findsOneWidget);
      expect(find.text('فرد / مسوق مستقل'), findsOneWidget);
      expect(find.text('شركة / مكتب عقاري'), findsOneWidget);
      expect(find.text('صورة البروفايل أو الشعار'), findsOneWidget);
      expect(find.text('وجه البطاقة'), findsOneWidget);
      expect(find.text('ظهر البطاقة'), findsOneWidget);
      expect(find.text('حماية وضمان الصفقة الأولى'), findsOneWidget);

      // Switch to Business mode and back to Individual mode
      await tester.tap(find.byKey(const Key('identity_mode_business')));
      await tester.pumpAndSettle();
      expect(find.text('السجل التجاري'), findsOneWidget);
      expect(find.text('البطاقة الضريبية'), findsOneWidget);

      await tester.tap(find.byKey(const Key('identity_mode_individual')));
      await tester.pumpAndSettle();
      expect(find.text('وجه البطاقة'), findsOneWidget);

      // Fill National ID & pick Front + Back documents
      await tester.enterText(
        find.byKey(const Key('wizard_national_id_input')),
        '29504150101234',
      );
      await tester.pump();
      expect(find.text('القاهرة'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('wizard_doc_tile_front')));
      await tester.tap(find.byKey(const Key('wizard_doc_tile_front')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('picker_source_gallery')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('wizard_doc_tile_back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('picker_source_gallery')));
      await tester.pumpAndSettle();

      expect(find.text('جاهز للإرسال'), findsNWidgets(2));

      // Submit for review -> completes 4-stage pipeline and lands on Step 3
      await tester.ensureVisible(find.byKey(const Key('wizard_step2_submit_btn')));
      await tester.tap(find.byKey(const Key('wizard_step2_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('خطوة 3 من 3'), findsOneWidget);
      expect(
        find.byKey(const Key('wizard_step3_headline')),
        findsOneWidget,
      );
      expect(repo.status, VerificationStatus.pending);
      expect(repo.uploadedDocs.length, 2);
    });

    testWidgets('Renders cleanly in Dark Mode and displays shimmer on loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: VerificationLoadingShimmer()),
          ),
        ),
      );
      expect(find.byType(VerificationLoadingShimmer), findsOneWidget);

      final repo = _MockWizardRepository();
      final picker = _MockWizardPicker();
      await tester.pumpWidget(
        _buildWizardApp(
          repo: repo,
          picker: picker,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('بيع العقارات يبدأ من هنا'), findsOneWidget);
    });
  });
}
