import { BadRequestException } from '@nestjs/common';
import {
  AccountType,
  SellerApplicationStatus,
  SellerDocumentStatus,
  SellerDocumentType,
} from '../../core/enums/domain.enums';
import {
  assertValidSellerStatusTransition,
  evaluateApplicationCompleteness,
  getRequiredDocumentTypes,
  isValidSellerStatusTransition,
} from './seller-application-state-machine';

describe('SellerApplicationStateMachine', () => {
  describe('valid lifecycle transitions', () => {
    const validPairs: Array<[SellerApplicationStatus, SellerApplicationStatus]> =
      [
        [SellerApplicationStatus.NOT_REQUESTED, SellerApplicationStatus.DRAFT],
        [SellerApplicationStatus.DRAFT, SellerApplicationStatus.PENDING],
        [SellerApplicationStatus.PENDING, SellerApplicationStatus.UNDER_REVIEW],
        [SellerApplicationStatus.PENDING, SellerApplicationStatus.APPROVED],
        [SellerApplicationStatus.PENDING, SellerApplicationStatus.REJECTED],
        [SellerApplicationStatus.UNDER_REVIEW, SellerApplicationStatus.APPROVED],
        [SellerApplicationStatus.UNDER_REVIEW, SellerApplicationStatus.REJECTED],
        [SellerApplicationStatus.REJECTED, SellerApplicationStatus.DRAFT],
        [SellerApplicationStatus.REJECTED, SellerApplicationStatus.PENDING],
        [SellerApplicationStatus.APPROVED, SellerApplicationStatus.SUSPENDED],
        [SellerApplicationStatus.SUSPENDED, SellerApplicationStatus.APPROVED],
      ];

    it.each(validPairs)('allows %s -> %s', (from, to) => {
      expect(isValidSellerStatusTransition(from, to)).toBe(true);
      expect(() => assertValidSellerStatusTransition(from, to)).not.toThrow();
    });
  });

  describe('invalid lifecycle transitions', () => {
    const invalidPairs: Array<
      [SellerApplicationStatus, SellerApplicationStatus]
    > = [
      [SellerApplicationStatus.NOT_REQUESTED, SellerApplicationStatus.PENDING],
      [SellerApplicationStatus.NOT_REQUESTED, SellerApplicationStatus.APPROVED],
      [SellerApplicationStatus.DRAFT, SellerApplicationStatus.APPROVED],
      [SellerApplicationStatus.DRAFT, SellerApplicationStatus.REJECTED],
      [SellerApplicationStatus.DRAFT, SellerApplicationStatus.SUSPENDED],
      [SellerApplicationStatus.REJECTED, SellerApplicationStatus.APPROVED],
      [SellerApplicationStatus.REJECTED, SellerApplicationStatus.SUSPENDED],
      [SellerApplicationStatus.APPROVED, SellerApplicationStatus.DRAFT],
      [SellerApplicationStatus.APPROVED, SellerApplicationStatus.PENDING],
      [SellerApplicationStatus.APPROVED, SellerApplicationStatus.REJECTED],
      [SellerApplicationStatus.APPROVED, SellerApplicationStatus.APPROVED],
      [SellerApplicationStatus.SUSPENDED, SellerApplicationStatus.PENDING],
      [SellerApplicationStatus.SUSPENDED, SellerApplicationStatus.DRAFT],
    ];

    it.each(invalidPairs)('rejects %s -> %s', (from, to) => {
      expect(isValidSellerStatusTransition(from, to)).toBe(false);
      expect(() => assertValidSellerStatusTransition(from, to)).toThrow(
        BadRequestException,
      );
    });
  });

  describe('completeness validation', () => {
    it('requires national ID front & back for individual sellers', () => {
      expect(getRequiredDocumentTypes(AccountType.INDIVIDUAL)).toEqual([
        SellerDocumentType.NATIONAL_ID_FRONT,
        SellerDocumentType.NATIONAL_ID_BACK,
      ]);

      const incomplete = evaluateApplicationCompleteness({
        businessType: AccountType.INDIVIDUAL,
        businessName: 'Ahmed Store',
        nationalIdNumber: '29501011234567',
        documents: [
          {
            documentType: SellerDocumentType.NATIONAL_ID_FRONT,
            status: SellerDocumentStatus.UPLOADED,
          },
        ],
      });
      expect(incomplete.isComplete).toBe(false);
      expect(incomplete.missingDocuments).toEqual([
        SellerDocumentType.NATIONAL_ID_BACK,
      ]);

      const complete = evaluateApplicationCompleteness({
        businessType: AccountType.INDIVIDUAL,
        businessName: 'Ahmed Store',
        nationalIdNumber: '29501011234567',
        documents: [
          {
            documentType: SellerDocumentType.NATIONAL_ID_FRONT,
            status: SellerDocumentStatus.UPLOADED,
          },
          {
            documentType: SellerDocumentType.NATIONAL_ID_BACK,
            status: SellerDocumentStatus.UPLOADED,
          },
        ],
      });
      expect(complete.isComplete).toBe(true);
      expect(complete.missingFields).toEqual([]);
      expect(complete.missingDocuments).toEqual([]);
    });

    it('requires commercial register, tax card, and national ID front for company sellers', () => {
      expect(getRequiredDocumentTypes(AccountType.COMPANY)).toEqual([
        SellerDocumentType.NATIONAL_ID_FRONT,
        SellerDocumentType.COMMERCIAL_REGISTER,
        SellerDocumentType.TAX_CARD,
      ]);

      const incomplete = evaluateApplicationCompleteness({
        businessType: AccountType.COMPANY,
        businessName: 'Cairo Corp',
        commercialRegisterNumber: '',
        documents: [],
      });
      expect(incomplete.isComplete).toBe(false);
      expect(incomplete.missingFields).toContain('commercialRegisterNumber');
      expect(incomplete.missingDocuments).toHaveLength(3);
    });
  });
});
