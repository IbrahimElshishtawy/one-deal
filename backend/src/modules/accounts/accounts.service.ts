import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
import {
  AccountMemberRole,
  VerificationTier,
} from '../../core/enums/domain.enums';
import {
  buildVerificationBadge,
  formatPublicSellerVerification,
  resolveAccountSellerType,
  resolveEffectiveVerificationTier,
} from './verification-tier.helper';
import { CreateAccountDto } from './dto/create-account.dto';
import { CreateBranchDto } from './dto/create-branch.dto';
import { InviteMemberDto } from './dto/invite-member.dto';
import { UpdateBranchDto } from './dto/update-branch.dto';
import { UpsertServiceAreaDto } from './dto/upsert-service-area.dto';
import { SubmitVerificationDto } from './dto/submit-verification.dto';

@Injectable()
export class AccountsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Creates a new merchant or seller account and assigns the user as owner.
   */
  async createAccount(userId: string, dto: CreateAccountDto) {
    let slug = dto.slug;
    if (!slug) {
      const sanitized = dto.displayName
        .toLowerCase()
        .trim()
        .replace(/[^\w\s-]/g, '')
        .replace(/[\s_-]+/g, '-')
        .replace(/^-+|-+$/g, '')
        .substring(0, 50);
      const randomSuffix = Math.random().toString(36).substring(2, 7);
      slug = sanitized ? `${sanitized}-${randomSuffix}` : `acc-${randomSuffix}`;
    }

    const existing = await this.prisma.account.findUnique({
      where: { slug },
    });
    if (existing) {
      slug = `${slug}-${Math.random().toString(36).substring(2, 6)}`;
    }

    return this.prisma.$transaction(async (tx) => {
      const account = await tx.account.create({
        data: {
          ownerUserId: userId,
          displayName: dto.displayName,
          accountType: dto.accountType,
          sellerType: resolveAccountSellerType(null, dto.accountType),
          slug,
          bio: dto.bio,
          logoUrl: dto.logoUrl,
          bannerUrl: dto.bannerUrl,
          verificationStatus: 'pending',
          verificationTier: VerificationTier.NONE,
          isActive: true,
        },
      });

      await tx.accountMember.create({
        data: {
          accountId: account.id,
          userId,
          role: 'owner',
        },
      });

      return account;
    });
  }

  /**
   * Creates a commercial store branch for an account.
   */
  async createBranch(accountId: string, userId: string, dto: CreateBranchDto) {
    await this.assertAccountRole(accountId, userId, [
      AccountMemberRole.OWNER,
      AccountMemberRole.MANAGER,
    ]);

    return this.prisma.branch.create({
      data: {
        accountId,
        name: dto.name,
        areaId: dto.areaId,
        address: dto.address,
        phone: dto.phone,
        isMain: dto.isMain ?? false,
      },
      include: {
        area: {
          include: {
            city: {
              include: { governorate: true },
            },
          },
        },
      },
    });
  }

  /**
   * Retrieves all active accounts where the specified user is an owner or member.
   * Powers the mobile Account Switcher drawer (Decision 01 / Pattern A).
   */
  async getMyAccounts(userId: string) {
    const memberships = await this.prisma.accountMember.findMany({
      where: {
        userId,
        account: {
          isActive: true,
          deletedAt: null,
        },
      },
      include: {
        account: {
          select: {
            id: true,
            accountType: true,
            sellerType: true,
            displayName: true,
            slug: true,
            bio: true,
            logoUrl: true,
            verificationStatus: true,
            verificationTier: true,
            isActive: true,
            createdAt: true,
          },
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    return memberships.map((m) => {
      const effectiveTier = resolveEffectiveVerificationTier(
        m.account.verificationStatus,
        m.account.verificationTier,
        m.account.isActive,
      );
      return {
        ...m.account,
        sellerType: resolveAccountSellerType(
          m.account.sellerType,
          m.account.accountType,
        ),
        verificationTier: effectiveTier,
        verificationBadge: buildVerificationBadge(
          m.account.verificationStatus,
          effectiveTier,
          m.account.isActive,
        ),
        role: m.role,
        joinedAt: m.createdAt,
      };
    });
  }

  /**
   * Retrieves public seller account profile.
   */
  async getAccountById(id: string) {
    const account = await this.prisma.account.findUnique({
      where: { id },
      include: {
        branches: {
          take: 5,
          include: {
            area: { include: { city: { include: { governorate: true } } } },
          },
        },
        _count: {
          select: {
            listings: {
              where: { publicationStatus: 'published', deletedAt: null },
            },
            branches: true,
          },
        },
      },
    });

    if (!account || !account.isActive || account.deletedAt) {
      throw new NotFoundException('Seller account not found');
    }

    const seller = formatPublicSellerVerification(account);

    return {
      id: account.id,
      displayName: account.displayName,
      slug: account.slug,
      accountType: account.accountType,
      sellerType: seller.sellerType,
      bio: account.bio,
      logoUrl: account.logoUrl,
      bannerUrl: account.bannerUrl,
      verificationStatus: account.verificationStatus,
      verificationTier: seller.verificationTier,
      verificationBadge: seller.verificationBadge,
      seller,
      branchesCount: account._count.branches,
      activeListingsCount: account._count.listings,
      branches: account.branches,
      createdAt: account.createdAt,
    };
  }

  /**
   * Retrieves all branches for a given account.
   */
  async getAccountBranches(accountId: string) {
    return this.prisma.branch.findMany({
      where: { accountId },
      include: {
        area: {
          include: {
            city: {
              include: { governorate: true },
            },
          },
        },
      },
      orderBy: [{ isMain: 'desc' }, { createdAt: 'asc' }],
    });
  }

  private async assertAccountRole(
    accountId: string,
    userId: string,
    allowedRoles: AccountMemberRole[],
  ) {
    const member = await this.prisma.accountMember.findUnique({
      where: {
        uq_account_user: {
          accountId,
          userId,
        },
      },
    });

    if (!member || !allowedRoles.includes(member.role as AccountMemberRole)) {
      throw new ForbiddenException(
        'You do not have administrative permission for this account',
      );
    }
    return member;
  }

  /**
   * Retrieves all members belonging to the specified seller account.
   */
  async getAccountMembers(accountId: string, callerUserId: string) {
    const callerMember = await this.prisma.accountMember.findUnique({
      where: {
        uq_account_user: {
          accountId,
          userId: callerUserId,
        },
      },
    });

    if (!callerMember) {
      throw new ForbiddenException('You are not a member of this account');
    }

    return this.prisma.accountMember.findMany({
      where: { accountId },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            phone: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  /**
   * Invites / adds a member to the account with specified RBAC role.
   */
  async inviteMember(
    accountId: string,
    callerUserId: string,
    dto: InviteMemberDto,
  ) {
    await this.assertAccountRole(accountId, callerUserId, [
      AccountMemberRole.OWNER,
      AccountMemberRole.MANAGER,
    ]);

    const cleanDigits = dto.phone.replace(/[^0-9]/g, '');
    let normalizedPhone = dto.phone;
    if (cleanDigits.startsWith('20') && cleanDigits.length === 12) {
      normalizedPhone = `+${cleanDigits}`;
    } else if (cleanDigits.startsWith('0') && cleanDigits.length === 11) {
      normalizedPhone = `+20${cleanDigits.slice(1)}`;
    } else if (cleanDigits.length === 10) {
      normalizedPhone = `+20${cleanDigits}`;
    }

    let targetUser = await this.prisma.user.findUnique({
      where: { phone: normalizedPhone },
    });

    if (!targetUser) {
      targetUser = await this.prisma.user.create({
        data: {
          phone: normalizedPhone,
          fullName: `عضو فريق ${normalizedPhone.slice(-4)}`,
          isPhoneVerified: false,
          isActive: true,
        },
      });
    }

    const existingMember = await this.prisma.accountMember.findUnique({
      where: {
        uq_account_user: {
          accountId,
          userId: targetUser.id,
        },
      },
    });

    if (existingMember) {
      throw new BadRequestException('User is already a member of this account');
    }

    return this.prisma.accountMember.create({
      data: {
        accountId,
        userId: targetUser.id,
        role: dto.role,
      },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            phone: true,
            avatarUrl: true,
          },
        },
      },
    });
  }

  /**
   * Removes a member from the seller account.
   */
  async removeMember(
    accountId: string,
    callerUserId: string,
    targetUserId: string,
  ) {
    const caller = await this.assertAccountRole(accountId, callerUserId, [
      AccountMemberRole.OWNER,
      AccountMemberRole.MANAGER,
    ]);

    const target = await this.prisma.accountMember.findUnique({
      where: {
        uq_account_user: {
          accountId,
          userId: targetUserId,
        },
      },
    });

    if (!target) {
      throw new NotFoundException('Team member not found');
    }

    if (target.role === AccountMemberRole.OWNER) {
      throw new ForbiddenException('Cannot remove an account owner');
    }

    if (
      caller.role === AccountMemberRole.MANAGER &&
      target.role === AccountMemberRole.MANAGER
    ) {
      throw new ForbiddenException('Managers cannot remove other managers');
    }

    await this.prisma.accountMember.delete({
      where: {
        uq_account_user: {
          accountId,
          userId: targetUserId,
        },
      },
    });

    return { success: true };
  }

  /**
   * Updates branch details.
   */
  async updateBranch(
    accountId: string,
    branchId: string,
    callerUserId: string,
    dto: UpdateBranchDto,
  ) {
    await this.assertAccountRole(accountId, callerUserId, [
      AccountMemberRole.OWNER,
      AccountMemberRole.MANAGER,
    ]);

    const branch = await this.prisma.branch.findFirst({
      where: { id: branchId, accountId },
    });

    if (!branch) {
      throw new NotFoundException('Branch not found');
    }

    if (dto.isMain) {
      await this.prisma.branch.updateMany({
        where: { accountId },
        data: { isMain: false },
      });
    }

    const updateData: any = {};
    if (dto.name !== undefined) updateData.name = dto.name;
    if (dto.address !== undefined) updateData.address = dto.address;
    if (dto.phone !== undefined) updateData.phone = dto.phone;
    if (dto.areaId !== undefined) updateData.areaId = dto.areaId;
    if (dto.isMain !== undefined) updateData.isMain = dto.isMain;

    return this.prisma.branch.update({
      where: { id: branchId },
      data: updateData,
    });
  }

  /**
   * Deletes a branch from the seller account.
   */
  async deleteBranch(
    accountId: string,
    branchId: string,
    callerUserId: string,
  ) {
    await this.assertAccountRole(accountId, callerUserId, [
      AccountMemberRole.OWNER,
      AccountMemberRole.MANAGER,
    ]);

    const branch = await this.prisma.branch.findFirst({
      where: { id: branchId, accountId },
    });

    if (!branch) {
      throw new NotFoundException('Branch not found');
    }

    await this.prisma.branch.delete({
      where: { id: branchId },
    });

    return { success: true };
  }

  /**
   * Lists configured service areas for an active account.
   */
  async getServiceAreas(accountId: string) {
    const account = await this.prisma.account.findUnique({
      where: { id: accountId },
      select: { id: true, isActive: true, deletedAt: true },
    });

    if (!account || !account.isActive || account.deletedAt) {
      throw new NotFoundException('Account not found');
    }

    return this.prisma.serviceArea.findMany({
      where: { accountId },
      include: {
        area: {
          include: {
            city: {
              include: { governorate: true },
            },
          },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  /**
   * Adds or updates a geographic service area coverage radius for an account.
   */
  async upsertServiceArea(
    accountId: string,
    userId: string,
    dto: UpsertServiceAreaDto,
  ) {
    await this.assertAccountRole(accountId, userId, [
      AccountMemberRole.OWNER,
      AccountMemberRole.MANAGER,
    ]);

    const area = await this.prisma.area.findUnique({
      where: { id: dto.areaId },
      select: { id: true, isActive: true },
    });
    if (!area || !area.isActive) {
      throw new NotFoundException('Geographic area not found or inactive');
    }

    return this.prisma.serviceArea.upsert({
      where: {
        uq_service_area: {
          accountId,
          areaId: dto.areaId,
        },
      },
      update: {
        radiusKm: dto.radiusKm ?? 10,
      },
      create: {
        accountId,
        areaId: dto.areaId,
        radiusKm: dto.radiusKm ?? 10,
      },
      include: {
        area: {
          include: {
            city: {
              include: { governorate: true },
            },
          },
        },
      },
    });
  }

  /**
   * Removes a configured service area from the account.
   */
  async removeServiceArea(
    accountId: string,
    serviceAreaId: string,
    userId: string,
  ) {
    await this.assertAccountRole(accountId, userId, [
      AccountMemberRole.OWNER,
      AccountMemberRole.MANAGER,
    ]);

    const existing = await this.prisma.serviceArea.findFirst({
      where: { id: serviceAreaId, accountId },
    });

    if (!existing) {
      throw new NotFoundException('Service area not found');
    }

    await this.prisma.serviceArea.delete({
      where: { id: serviceAreaId },
    });

    return { success: true };
  }

  /**
   * Lists verification document submissions for an account (owner/manager only).
   */
  async getAccountVerifications(accountId: string, userId: string) {
    await this.assertAccountRole(accountId, userId, [
      AccountMemberRole.OWNER,
      AccountMemberRole.MANAGER,
    ]);

    return this.prisma.accountVerification.findMany({
      where: { accountId },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Submits a verification document for account trust review.
   */
  async submitVerification(
    accountId: string,
    userId: string,
    dto: SubmitVerificationDto,
  ) {
    await this.assertAccountRole(accountId, userId, [
      AccountMemberRole.OWNER,
      AccountMemberRole.MANAGER,
    ]);

    const account = await this.prisma.account.findUnique({
      where: { id: accountId },
      select: { id: true, isActive: true, deletedAt: true },
    });

    if (!account || !account.isActive || account.deletedAt) {
      throw new NotFoundException('Account not found');
    }

    return this.prisma.$transaction(async (tx) => {
      const verification = await tx.accountVerification.create({
        data: {
          accountId,
          documentType: dto.documentType,
          documentNumber: dto.documentNumber ?? null,
          fileUrl: dto.fileUrl,
          status: 'pending',
        },
      });

      await tx.account.update({
        where: { id: accountId },
        data: { verificationStatus: 'pending' },
      });

      return verification;
    });
  }
}
