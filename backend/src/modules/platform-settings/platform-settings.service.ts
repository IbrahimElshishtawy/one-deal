import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../core/database/prisma.service';
import { UpsertPlatformSettingDto } from './dto/upsert-platform-setting.dto';
import { assertValidSettingKey } from './pipes/setting-key.pipe';

@Injectable()
export class PlatformSettingsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Lists all platform configuration settings ordered by key.
   */
  async listSettings() {
    return this.prisma.platformSetting.findMany({
      orderBy: { key: 'asc' },
    });
  }

  /**
   * Retrieves a single platform setting by key.
   */
  async getSetting(key: string) {
    assertValidSettingKey(key);
    const setting = await this.prisma.platformSetting.findUnique({
      where: { key },
    });
    if (!setting) {
      throw new NotFoundException(`Platform setting '${key}' not found`);
    }
    return setting;
  }

  /**
   * Creates or updates a platform setting and records an immutable audit log entry.
   */
  async upsertSetting(
    key: string,
    actorId: string,
    dto: UpsertPlatformSettingDto,
    ipAddress?: string,
    userAgent?: string,
  ) {
    assertValidSettingKey(key);
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.platformSetting.findUnique({
        where: { key },
      });

      const setting = await tx.platformSetting.upsert({
        where: { key },
        update: {
          value: dto.value as Prisma.InputJsonValue,
          ...(dto.description !== undefined
            ? { description: dto.description }
            : {}),
        },
        create: {
          key,
          value: dto.value as Prisma.InputJsonValue,
          description: dto.description ?? null,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: existing
            ? 'PLATFORM_SETTING_UPDATED'
            : 'PLATFORM_SETTING_CREATED',
          targetEntity: 'platform_setting',
          ipAddress: ipAddress?.slice(0, 50),
          userAgent: userAgent?.slice(0, 500),
          diffPayload: {
            key,
            previousValue: existing?.value ?? null,
            newValue: dto.value as Prisma.InputJsonValue,
          },
        },
      });

      return setting;
    });
  }
}
