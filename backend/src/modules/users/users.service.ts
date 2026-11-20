import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
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
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User profile not found');
    }

    return {
      ...user,
      role: 'USER',
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
