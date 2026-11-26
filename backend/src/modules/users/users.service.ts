import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
import { VerificationTier } from '../../core/enums/domain.enums';
import {
  buildVerificationBadge,
  resolveAccountSellerType,
  resolveEffectiveVerificationTier,
} from '../accounts/verification-tier.helper';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        phone: true,
        fullName: true,
        email: true,
        avatarUrl: true,
        isPhoneVerified: true,
        isEmailVerified: true,
        isActive: true,
        preferredLanguage: true,
        sellerStatus: true,
        sellerApprovedAt: true,
        sellerSuspendedAt: true,
        sellerSuspensionReason: true,
        createdAt: true,
        updatedAt: true,
        ownedAccounts: {
          where: { deletedAt: null },
          orderBy: { createdAt: 'asc' },
          take: 1,
          select: {
            id: true,
            accountType: true,
            sellerType: true,
            verificationStatus: true,
            verificationTier: true,
            isActive: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User profile not found');
    }

    const sellerStatus = user.sellerStatus ?? 'NOT_REQUESTED';
    const isApprovedSeller = sellerStatus === 'APPROVED';
    const primaryAccount = user.ownedAccounts?.[0] ?? null;
    const verificationTier = primaryAccount
      ? resolveEffectiveVerificationTier(
          primaryAccount.verificationStatus,
          primaryAccount.verificationTier,
          primaryAccount.isActive,
        )
      : VerificationTier.NONE;
    const verificationBadge = primaryAccount
      ? buildVerificationBadge(
          primaryAccount.verificationStatus,
          verificationTier,
          primaryAccount.isActive,
        )
      : null;

    const { ownedAccounts: _ignored, ...safeUser } = user;

    return {
      ...safeUser,
      role: 'USER',
      roles: isApprovedSeller ? ['BUYER', 'SELLER'] : ['BUYER'],
      sellerStatus,
      sellerType: primaryAccount
        ? resolveAccountSellerType(
            primaryAccount.sellerType,
            primaryAccount.accountType,
          )
        : null,
      verificationTier,
      verificationBadge,
      canSell: isApprovedSeller,
      status: user.isActive ? 'ACTIVE' : 'SUSPENDED',
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        fullName: dto.fullName,
        avatarUrl: dto.avatarUrl,
        preferredLanguage: dto.preferredLanguage,
      },
      select: {
        id: true,
        phone: true,
        fullName: true,
        avatarUrl: true,
        preferredLanguage: true,
        updatedAt: true,
      },
    });
  }

  async softDeleteAccount(userId: string) {
    return this.prisma.$transaction(async (tx) => {
      await tx.userSession.updateMany({
        where: { userId, isRevoked: false },
        data: { isRevoked: true },
      });

      return tx.user.update({
        where: { id: userId },
        data: {
          isActive: false,
          deletedAt: new Date(),
          fullName: 'Deleted Account',
          avatarUrl: null,
        },
        select: {
          id: true,
          isActive: true,
          deletedAt: true,
        },
      });
    });
  }
}
