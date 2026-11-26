import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/features/seller_verification/application/notifiers/seller_verification_notifiers.dart';
import 'package:market_space/features/seller_verification/data/models/seller_verification_models.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/domain/validators/seller_verification_validators.dart';

void main() {
  group('SellerTypeSelectionNotifier', () {
    test('defaults to individual and switches cleanly to business and back', () {
      final notifier = SellerTypeSelectionNotifier();
      expect(notifier.state.selectedType, SellerType.individual);
      expect(notifier.state.selectedBusinessType, BusinessAccountType.individual);

      notifier.selectSellerType(SellerType.business);
      expect(notifier.state.selectedType, SellerType.business);
      expect(notifier.state.selectedBusinessType, BusinessAccountType.company);

      notifier.selectBusinessType(BusinessAccountType.office);
      expect(notifier.state.selectedBusinessType, BusinessAccountType.office);

      notifier.selectSellerType(SellerType.serviceProvider);
      expect(notifier.state.selectedType, SellerType.serviceProvider);
    });
  });

  group('SellerVerificationRequirementModel & Validators', () {
    final nationalIdFrontReq = SellerVerificationRequirementModel.fromJson({
      'id': 'req-1',
      'sellerType': 'INDIVIDUAL',
      'documentType': 'national_id_front',
      'displayName': 'National ID (Front)',
      'displayNameAr': 'البطاقة الشخصية (الوجه الأمامي)',
      'isRequired': true,
      'acceptedMimeTypes': ['image/jpeg', 'image/png', 'application/pdf'],
      'maxFileSizeBytes': 5 * 1024 * 1024,
    });

    final optionalProofReq = SellerVerificationRequirementModel.fromJson({
      'id': 'req-2',
      'sellerType': 'INDIVIDUAL',
      'documentType': 'proof_of_address',
      'displayName': 'Proof of Address',
      'isRequired': false,
    });

    test('maps localized requirement names correctly for AR and EN', () {
      expect(
        nationalIdFrontReq.localizedName(isArabic: true),
        'البطاقة الشخصية (الوجه الأمامي)',
      );
      expect(
        nationalIdFrontReq.localizedName(isArabic: false),
        'National ID (Front)',
      );
    });

    test('validates file MIME, extension match, and max size', () {
      final validJpg = PickedDocumentFile(
        fileName: 'id-front.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]),
      );
      expect(
        SellerVerificationValidators.validateDocumentFile(
          validJpg,
          requirement: nationalIdFrontReq,
          isArabic: false,
        ),
        isNull,
      );

      final badExt = PickedDocumentFile(
        fileName: 'payload.exe',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      expect(
        SellerVerificationValidators.validateDocumentFile(
          badExt,
          requirement: nationalIdFrontReq,
          isArabic: false,
        ),
        isNotNull,
      );

      final oversized = PickedDocumentFile(
        fileName: 'huge.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List(6 * 1024 * 1024),
      );
      expect(
        SellerVerificationValidators.validateDocumentFile(
          oversized,
          requirement: nationalIdFrontReq,
          isArabic: false,
        ),
        isNotNull,
      );
    });

    test('optional documents never block completeness', () {
      final uploaded = [
        const SellerDocumentEntity(
          id: 'doc-1',
          applicationId: 'app-1',
          documentType: 'national_id_front',
          originalFileName: 'front.jpg',
          mimeType: 'image/jpeg',
          fileSizeBytes: 1024,
          status: SellerDocumentStatus.uploaded,
        ),
      ];

      final missing = SellerVerificationValidators.findMissingRequiredDocuments(
        requirements: [nationalIdFrontReq, optionalProofReq],
        uploadedDocuments: uploaded,
      );
      expect(missing, isEmpty);
    });
  });

  group('VerificationStatusModel, Badge Rules & BusinessUpgradeModel', () {
    test('exposes activeBadge ONLY when status is APPROVED and tier is verified', () {
      final approvedSnap = VerificationStatusModel.fromJson({
        'userId': 'u-1',
        'sellerStatus': 'APPROVED',
        'sellerType': 'INDIVIDUAL',
        'verificationTier': 'IDENTITY_VERIFIED',
        'verificationBadge': {
          'code': 'IDENTITY_VERIFIED',
          'label': 'هوية موثقة',
        },
        'capabilities': {
          'canUpgradeToBusiness': true,
          'canCreateListing': true,
        },
      });
      expect(approvedSnap.activeBadge?.code, VerificationTier.identityVerified);
      expect(approvedSnap.activeBadge?.label, 'هوية موثقة');
      expect(approvedSnap.capabilities.canUpgradeToBusiness, isTrue);

      for (final status in ['PENDING', 'REJECTED', 'SUSPENDED', 'NEEDS_CORRECTION']) {
        final nonApproved = VerificationStatusModel.fromJson({
          'userId': 'u-2',
          'sellerStatus': status,
          'verificationTier': 'BUSINESS_VERIFIED',
          'verificationBadge': {
            'code': 'BUSINESS_VERIFIED',
            'label': 'شركة / مكتب موثق',
          },
        });
        expect(nonApproved.activeBadge, isNull);
      }
    });

    test('parses BusinessUpgradeSnapshot eligibility and requirements', () {
      final upgrade = BusinessUpgradeModel.fromJson({
        'accountId': 'acc-1',
        'currentSellerType': 'INDIVIDUAL',
        'currentVerificationTier': 'IDENTITY_VERIFIED',
        'currentVerificationBadge': {
          'code': 'IDENTITY_VERIFIED',
          'label': 'هوية موثقة',
        },
        'eligibleForUpgrade': true,
        'businessRequirements': [
          {
            'id': 'r-cr',
            'sellerType': 'BUSINESS',
            'documentType': 'commercial_register',
            'displayName': 'Commercial Register',
            'displayNameAr': 'السجل التجاري',
            'isRequired': true,
          },
          {
            'id': 'r-tax',
            'sellerType': 'BUSINESS',
            'documentType': 'tax_card',
            'displayName': 'Tax Card',
            'displayNameAr': 'البطاقة الضريبية',
            'isRequired': true,
          },
        ],
      });

      expect(upgrade.eligibleForUpgrade, isTrue);
      expect(upgrade.accountId, 'acc-1');
      expect(upgrade.businessRequirements.length, 2);
      expect(upgrade.currentVerificationTier, VerificationTier.identityVerified);
    });
  });
}
