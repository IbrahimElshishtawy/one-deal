import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';

void main() {
  group('Phase 2 Mobile Seller Verification Alignment (MOB-001)', () {
    test('VerificationStatus parses WITHDRAWN and EXPIRED accurately', () {
      expect(
        VerificationStatus.fromApi('WITHDRAWN'),
        VerificationStatus.withdrawn,
      );
      expect(
        VerificationStatus.fromApi('EXPIRED'),
        VerificationStatus.expired,
      );
      expect(VerificationStatus.withdrawn.apiValue, 'WITHDRAWN');
      expect(VerificationStatus.expired.apiValue, 'EXPIRED');
    });

    test('isWithdrawable and isRenewable enforce backend state rules', () {
      expect(VerificationStatus.draft.isWithdrawable, isTrue);
      expect(VerificationStatus.pending.isWithdrawable, isTrue);
      expect(VerificationStatus.needsChanges.isWithdrawable, isTrue);
      expect(VerificationStatus.approved.isWithdrawable, isFalse);
      expect(VerificationStatus.underReview.isWithdrawable, isFalse);
      expect(VerificationStatus.suspended.isWithdrawable, isFalse);

      expect(VerificationStatus.expired.isRenewable, isTrue);
      expect(VerificationStatus.approved.isRenewable, isFalse);
      expect(VerificationStatus.withdrawn.isRenewable, isFalse);
    });

    test('ApiEndpoints exposes withdraw and renew paths', () {
      expect(
        ApiEndpoints.sellerApplicationMeWithdraw,
        '/seller-applications/me/withdraw',
      );
      expect(
        ApiEndpoints.sellerApplicationMeRenew,
        '/seller-applications/me/renew',
      );
    });
  });
}
