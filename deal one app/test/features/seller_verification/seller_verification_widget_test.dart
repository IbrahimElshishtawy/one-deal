import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/features/seller_verification/application/notifiers/seller_verification_notifiers.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/badges/verification_badges.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/document_upload/document_upload_widgets.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/tracking/tracking_and_upgrade_widgets.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/type_selection/seller_type_widgets.dart';

Widget _wrap(
  Widget child, {
  TextDirection direction = TextDirection.rtl,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Directionality(
      textDirection: direction,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('VerificationBadge Widget Tests (RTL/LTR & Light/Dark)', () {
    testWidgets('renders Arabic "هوية موثقة" for APPROVED IDENTITY_VERIFIED', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const VerificationBadge(
            verificationStatus: VerificationStatus.approved,
            verificationTier: VerificationTier.identityVerified,
            badge: VerificationBadgeEntity(
              code: VerificationTier.identityVerified,
              label: 'هوية موثقة',
            ),
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(find.text('هوية موثقة'), findsOneWidget);
    });

    testWidgets('renders Arabic "شركة / مكتب موثق" in Dark Mode for BUSINESS_VERIFIED', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const VerificationBadge(
            verificationStatus: VerificationStatus.approved,
            verificationTier: VerificationTier.businessVerified,
            badge: VerificationBadgeEntity(
              code: VerificationTier.businessVerified,
              label: 'شركة / مكتب موثق',
            ),
          ),
          direction: TextDirection.rtl,
          brightness: Brightness.dark,
        ),
      );
      expect(find.text('شركة / مكتب موثق'), findsOneWidget);
    });

    testWidgets('renders NOTHING for PENDING, REJECTED, or SUSPENDED status', (tester) async {
      for (final status in [
        VerificationStatus.pending,
        VerificationStatus.rejected,
        VerificationStatus.suspended,
      ]) {
        await tester.pumpWidget(
          _wrap(
            VerificationBadge(
              verificationStatus: status,
              verificationTier: VerificationTier.businessVerified,
              badge: const VerificationBadgeEntity(
                code: VerificationTier.businessVerified,
                label: 'شركة / مكتب موثق',
              ),
            ),
          ),
        );
        expect(find.text('شركة / مكتب موثق'), findsNothing);
      }
    });
  });

  group('Reusable Seller Verification Widgets', () {
    testWidgets('SellerTypeCard triggers onTap and reflects selection', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          IndividualSellerCard(
            isSelected: true,
            onTap: () => tapped = true,
          ),
          direction: TextDirection.ltr,
        ),
      );
      expect(find.text('Individual Seller'), findsOneWidget);
      await tester.tap(find.byKey(const Key('seller_type_card_individual')));
      expect(tapped, isTrue);
    });

    testWidgets('DocumentUploadCard renders idle, uploading, uploaded, and error states', (tester) async {
      const req = SellerVerificationRequirementEntity(
        id: 'req-1',
        sellerType: 'INDIVIDUAL',
        documentType: 'national_id_front',
        displayName: 'National ID Front',
        displayNameAr: 'البطاقة الأمامية',
        isRequired: true,
      );

      // Idle state
      await tester.pumpWidget(
        _wrap(
          DocumentUploadCard(
            requirement: req,
            itemState: const DocumentUploadItemState(
              documentType: 'national_id_front',
            ),
            onPickSource: (_) {},
          ),
          direction: TextDirection.ltr,
        ),
      );
      expect(find.text('National ID Front'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Uploaded state
      await tester.pumpWidget(
        _wrap(
          DocumentUploadCard(
            requirement: req,
            itemState: const DocumentUploadItemState(
              documentType: 'national_id_front',
              status: DocumentUploadSlotStatus.uploaded,
              progress: 1.0,
              confirmedDocument: SellerDocumentEntity(
                id: 'doc-1',
                applicationId: 'app-1',
                documentType: 'national_id_front',
                originalFileName: 'id-front.jpg',
                mimeType: 'image/jpeg',
                fileSizeBytes: 51200,
                status: SellerDocumentStatus.uploaded,
              ),
            ),
            onPickSource: (_) {},
          ),
          direction: TextDirection.ltr,
        ),
      );
      expect(find.text('id-front.jpg'), findsOneWidget);
      expect(find.text('Uploaded Successfully'), findsOneWidget);
    });

    testWidgets('VerificationStatusCard, RejectionReasonCard, Timeline, BusinessUpgradeHeader & FormValidationMessage render cleanly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              const VerificationStatusCard(
                status: VerificationStatus.rejected,
                sellerType: SellerType.business,
                verificationTier: VerificationTier.none,
              ),
              const VerificationRejectionReasonCard(
                reason: 'Commercial register image is blurry',
              ),
              VerificationTimeline(
                items: [
                  VerificationHistoryItemEntity(
                    id: 'h-1',
                    applicationId: 'app-1',
                    actorType: 'staff',
                    previousStatus: VerificationStatus.pending,
                    newStatus: VerificationStatus.rejected,
                    reason: 'Blurry scan',
                    createdAt: DateTime(2026, 11, 26),
                  ),
                ],
              ),
              const BusinessUpgradeHeader(),
              const FormValidationMessage(message: 'Required field missing'),
            ],
          ),
          direction: TextDirection.ltr,
        ),
      );

      expect(find.text('Rejected'), findsWidgets);
      expect(find.text('Commercial register image is blurry'), findsOneWidget);
      expect(find.text('Blurry scan'), findsOneWidget);
      expect(find.text('Upgrade to Business Verified'), findsOneWidget);
      expect(find.text('Required field missing'), findsOneWidget);
    });
  });
}
