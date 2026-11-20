import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { PrismaService } from '../../../core/database/prisma.service';
import { RedisService } from '../../../core/redis/redis.service';
import { NotificationsService } from '../../notifications/notifications.service';
import {
  AudiencePreviewDto,
  CreateCmsItemDto,
  CreateFeatureFlagDto,
  CreateNotificationCampaignDto,
  UpdateCmsItemDto,
  UpdateFeatureFlagDto,
} from '../dto/admin-operations.dto';

@Injectable()
export class AdminGrowthPlatformService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    @Optional() private readonly redis?: RedisService,
  ) {}

  // =========================================================================
  // NOTIFICATIONS CAMPAIGNS MANAGEMENT
  // =========================================================================

  async listCampaigns(page = 1, limit = 20, status?: string) {
    const safePage = Math.max(Number(page) || 1, 1);
    const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
    const skip = (safePage - 1) * safeLimit;
    const where: any = status && status !== 'all' ? { status } : {};

    const [total, items] = await Promise.all([
      this.prisma.notificationCampaign.count({ where }),
      this.prisma.notificationCampaign.findMany({
        where,
        skip,
        take: safeLimit,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    return {
      items,
      meta: {
        total,
        page: safePage,
        limit: safeLimit,
        totalPages: Math.ceil(total / safeLimit),
      },
    };
  }

  async previewAudience(dto: AudiencePreviewDto) {
    const where = this.buildAudienceWhere(dto.audienceType, dto.audienceFilter);
    const count = await this.prisma.user.count({ where });
    return {
      audienceType: dto.audienceType,
      estimatedRecipients: count,
    };
  }

  async createCampaign(dto: CreateNotificationCampaignDto, actorId: string) {
    const where = this.buildAudienceWhere(dto.audienceType, dto.audienceFilter);
    const estimatedRecipients = await this.prisma.user.count({ where });

    const initialStatus = dto.submitForApproval
      ? 'pending_approval'
      : dto.scheduledAt
        ? 'scheduled'
        : 'draft';

    return this.prisma.$transaction(async (tx) => {
      const campaign = await tx.notificationCampaign.create({
        data: {
          id: crypto.randomUUID(),
          titleAr: dto.titleAr.trim(),
          titleEn: dto.titleEn.trim(),
          bodyAr: dto.bodyAr.trim(),
          bodyEn: dto.bodyEn.trim(),
          audienceType: dto.audienceType,
          audienceFilter: (dto.audienceFilter as any) ?? {},
          status: initialStatus,
          scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : null,
          estimatedRecipients,
          createdByStaffId: actorId,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'NOTIFICATION_CAMPAIGN_CREATED',
          targetEntity: 'notification_campaign',
          targetId: campaign.id,
          diffPayload: {
            audienceType: campaign.audienceType,
            estimatedRecipients,
            status: campaign.status,
          },
        },
      });

      return campaign;
    });
  }

  async approveCampaign(campaignId: string, actorId: string) {
    const existing = await this.prisma.notificationCampaign.findUnique({
      where: { id: campaignId },
    });
    if (!existing) throw new NotFoundException('Campaign not found');

    if (!['draft', 'pending_approval', 'scheduled'].includes(existing.status)) {
      throw new BadRequestException(
        `Campaign in status '${existing.status}' cannot be approved.`,
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.notificationCampaign.update({
        where: { id: campaignId },
        data: {
          status: 'approved',
          approvedByStaffId: actorId,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'NOTIFICATION_CAMPAIGN_APPROVED',
          targetEntity: 'notification_campaign',
          targetId: campaignId,
          diffPayload: { previousStatus: existing.status, newStatus: 'approved' },
        },
      });
      return updated;
    });
  }

  async sendCampaign(campaignId: string, actorId: string) {
    const campaign = await this.prisma.notificationCampaign.findUnique({
      where: { id: campaignId },
    });
    if (!campaign) throw new NotFoundException('Campaign not found');

    if (campaign.status !== 'approved') {
      throw new BadRequestException(
        'Campaign must be approved before sending.',
      );
    }

    const where = this.buildAudienceWhere(
      campaign.audienceType as any,
      campaign.audienceFilter as any,
    );
    const recipients = await this.prisma.user.findMany({
      where,
      select: { id: true, preferredLanguage: true },
      take: 5000,
    });

    let sentCount = 0;
    let deliveredCount = 0;
    let failedCount = 0;

    for (const user of recipients) {
      const isAr = user.preferredLanguage !== 'en';
      const title = isAr ? campaign.titleAr : campaign.titleEn;
      const body = isAr ? campaign.bodyAr : campaign.bodyEn;
      sentCount++;
      try {
        await this.notificationsService.sendPushNotification(
          user.id,
          title,
          body,
          {
            type: 'CAMPAIGN',
            campaignId: campaign.id,
          },
        );
        deliveredCount++;
      } catch {
        failedCount++;
      }
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.notificationCampaign.update({
        where: { id: campaignId },
        data: {
          status: 'sent',
          sentAt: new Date(),
          sentCount,
          deliveredCount,
          failedCount,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'NOTIFICATION_CAMPAIGN_SENT',
          targetEntity: 'notification_campaign',
          targetId: campaignId,
          diffPayload: { sentCount, deliveredCount, failedCount },
        },
      });

      return updated;
    });
  }

  async cancelCampaign(campaignId: string, actorId: string) {
    const campaign = await this.prisma.notificationCampaign.findUnique({
      where: { id: campaignId },
    });
    if (!campaign) throw new NotFoundException('Campaign not found');
    if (campaign.status === 'sent') {
      throw new BadRequestException('Cannot cancel a campaign already sent.');
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.notificationCampaign.update({
        where: { id: campaignId },
        data: { status: 'cancelled' },
      });
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'NOTIFICATION_CAMPAIGN_CANCELLED',
          targetEntity: 'notification_campaign',
          targetId: campaignId,
        },
      });
      return updated;
    });
  }

  private buildAudienceWhere(
    audienceType: 'all' | 'verified' | 'new_users' | 'category',
    filter?: Record<string, unknown>,
  ) {
    const base: any = { deletedAt: null, isActive: true };
    if (audienceType === 'verified') {
      base.ownedAccounts = { some: { verificationStatus: 'approved' } };
    } else if (audienceType === 'new_users') {
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      base.createdAt = { gte: sevenDaysAgo };
    } else if (audienceType === 'category' && filter?.categoryId) {
      base.ownedAccounts = {
        some: {
          listings: {
            some: { categoryId: String(filter.categoryId), deletedAt: null },
          },
        },
      };
    }
    return base;
  }

  // =========================================================================
  // CMS MANAGEMENT + PUBLIC FLUTTER ENDPOINTS
  // =========================================================================

  async listCmsItems(type?: string, status?: string, q?: string) {
    const where: any = {
      ...(type && type !== 'all' ? { type } : {}),
      ...(status && status !== 'all' ? { status } : {}),
      ...(q
        ? {
            OR: [
              { titleEn: { contains: q.trim(), mode: 'insensitive' } },
              { titleAr: { contains: q.trim(), mode: 'insensitive' } },
              { slug: { contains: q.trim(), mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    return this.prisma.cmsItem.findMany({
      where,
      orderBy: [{ sortOrder: 'asc' }, { updatedAt: 'desc' }],
    });
  }

  async getCmsItem(id: string) {
    const item = await this.prisma.cmsItem.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('CMS item not found');
    return item;
  }

  async createCmsItem(dto: CreateCmsItemDto, actorId: string) {
    const slug = dto.slug.trim().toLowerCase();
    const existing = await this.prisma.cmsItem.findUnique({ where: { slug } });
    if (existing) {
      throw new ConflictException(`CMS item with slug '${slug}' already exists`);
    }

    const created = await this.prisma.$transaction(async (tx) => {
      const item = await tx.cmsItem.create({
        data: {
          id: crypto.randomUUID(),
          type: dto.type,
          slug,
          titleAr: dto.titleAr.trim(),
          titleEn: dto.titleEn.trim(),
          bodyAr: dto.bodyAr ?? null,
          bodyEn: dto.bodyEn ?? null,
          imageUrl: dto.imageUrl ?? null,
          targetUrl: dto.targetUrl ?? null,
          placement: dto.placement ?? null,
          sortOrder: dto.sortOrder ?? 0,
          status: dto.status ?? 'draft',
          isActive: dto.isActive ?? true,
          startsAt: dto.startsAt ? new Date(dto.startsAt) : null,
          endsAt: dto.endsAt ? new Date(dto.endsAt) : null,
          revisions: [],
          updatedByStaffId: actorId,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'CMS_ITEM_CREATED',
          targetEntity: 'cms_item',
          targetId: item.id,
          diffPayload: { slug: item.slug, type: item.type, status: item.status },
        },
      });

      return item;
    });

    await this.redis?.del('cms:public:all').catch(() => undefined);
    return created;
  }

  async updateCmsItem(id: string, dto: UpdateCmsItemDto, actorId: string) {
    const existing = await this.prisma.cmsItem.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('CMS item not found');

    const prevRevisions = Array.isArray(existing.revisions)
      ? (existing.revisions as Array<Record<string, unknown>>)
      : [];

    const snapshot = {
      version: prevRevisions.length + 1,
      savedAt: new Date().toISOString(),
      savedBy: actorId,
      titleAr: existing.titleAr,
      titleEn: existing.titleEn,
      bodyAr: existing.bodyAr,
      bodyEn: existing.bodyEn,
      status: existing.status,
    };

    const updated = await this.prisma.$transaction(async (tx) => {
      const item = await tx.cmsItem.update({
        where: { id },
        data: {
          ...(dto.titleAr !== undefined ? { titleAr: dto.titleAr.trim() } : {}),
          ...(dto.titleEn !== undefined ? { titleEn: dto.titleEn.trim() } : {}),
          ...(dto.bodyAr !== undefined ? { bodyAr: dto.bodyAr } : {}),
          ...(dto.bodyEn !== undefined ? { bodyEn: dto.bodyEn } : {}),
          ...(dto.imageUrl !== undefined ? { imageUrl: dto.imageUrl } : {}),
          ...(dto.targetUrl !== undefined ? { targetUrl: dto.targetUrl } : {}),
          ...(dto.placement !== undefined ? { placement: dto.placement } : {}),
          ...(dto.sortOrder !== undefined ? { sortOrder: dto.sortOrder } : {}),
          ...(dto.status !== undefined ? { status: dto.status } : {}),
          ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
          ...(dto.startsAt !== undefined
            ? { startsAt: dto.startsAt ? new Date(dto.startsAt) : null }
            : {}),
          ...(dto.endsAt !== undefined
            ? { endsAt: dto.endsAt ? new Date(dto.endsAt) : null }
            : {}),
          revisions: [snapshot, ...prevRevisions].slice(0, 20) as any,
          updatedByStaffId: actorId,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'CMS_ITEM_UPDATED',
          targetEntity: 'cms_item',
          targetId: id,
          diffPayload: {
            slug: existing.slug,
            previousStatus: existing.status,
            newStatus: item.status,
          },
        },
      });

      return item;
    });

    await this.redis?.del('cms:public:all').catch(() => undefined);
    return updated;
  }

  async changeCmsStatus(
    id: string,
    status: 'published' | 'draft' | 'archived',
    actorId: string,
  ) {
    const existing = await this.prisma.cmsItem.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('CMS item not found');

    const updated = await this.prisma.$transaction(async (tx) => {
      const item = await tx.cmsItem.update({
        where: { id },
        data: {
          status,
          isActive: status === 'published',
          updatedByStaffId: actorId,
        },
      });
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: `CMS_ITEM_${status.toUpperCase()}`,
          targetEntity: 'cms_item',
          targetId: id,
          diffPayload: { slug: existing.slug, previousStatus: existing.status, status },
        },
      });
      return item;
    });

    await this.redis?.del('cms:public:all').catch(() => undefined);
    return updated;
  }

  async deleteCmsItem(id: string, actorId: string) {
    const existing = await this.prisma.cmsItem.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('CMS item not found');

    await this.prisma.$transaction(async (tx) => {
      await tx.cmsItem.delete({ where: { id } });
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'CMS_ITEM_DELETED',
          targetEntity: 'cms_item',
          targetId: id,
          diffPayload: { slug: existing.slug },
        },
      });
    });

    await this.redis?.del('cms:public:all').catch(() => undefined);
    return { success: true };
  }

  async getPublicCmsItems(type?: string) {
    const now = new Date();
    const items = await this.prisma.cmsItem.findMany({
      where: {
        isActive: true,
        ...(type ? { type } : {}),
        OR: [
          { status: 'published' },
          { status: 'scheduled', startsAt: { lte: now } },
        ],
      },
      orderBy: [{ sortOrder: 'asc' }, { updatedAt: 'desc' }],
      select: {
        id: true,
        type: true,
        slug: true,
        titleAr: true,
        titleEn: true,
        bodyAr: true,
        bodyEn: true,
        imageUrl: true,
        targetUrl: true,
        placement: true,
        sortOrder: true,
        startsAt: true,
        endsAt: true,
        updatedAt: true,
      },
    });

    return items.filter((item) => !item.endsAt || item.endsAt >= now);
  }

  async getPublicCmsBySlug(slug: string) {
    const now = new Date();
    const item = await this.prisma.cmsItem.findUnique({
      where: { slug },
      select: {
        id: true,
        type: true,
        slug: true,
        titleAr: true,
        titleEn: true,
        bodyAr: true,
        bodyEn: true,
        imageUrl: true,
        targetUrl: true,
        placement: true,
        status: true,
        isActive: true,
        startsAt: true,
        endsAt: true,
        updatedAt: true,
      },
    });
    if (
      !item ||
      !item.isActive ||
      !(
        item.status === 'published' ||
        (item.status === 'scheduled' && item.startsAt && item.startsAt <= now)
      ) ||
      (item.endsAt && item.endsAt < now)
    ) {
      throw new NotFoundException(`Published CMS content '${slug}' not found`);
    }
    return item;
  }

  // =========================================================================
  // FEATURE FLAGS MANAGEMENT
  // =========================================================================

  async listFeatureFlags() {
    return this.prisma.featureFlag.findMany({ orderBy: { key: 'asc' } });
  }

  async createFeatureFlag(dto: CreateFeatureFlagDto, actorId: string) {
    const key = dto.key.trim().toLowerCase();
    const existing = await this.prisma.featureFlag.findUnique({
      where: { key },
    });
    if (existing) {
      throw new ConflictException(`Feature flag '${key}' already exists`);
    }

    const created = await this.prisma.$transaction(async (tx) => {
      const flag = await tx.featureFlag.create({
        data: {
          key,
          name: dto.name.trim(),
          description: dto.description ?? null,
          isEnabled: dto.isEnabled ?? false,
          environment: dto.environment ?? 'all',
          rolloutPercentage: dto.rolloutPercentage ?? 100,
          rules: {
            history: [
              {
                changedAt: new Date().toISOString(),
                changedBy: actorId,
                isEnabled: dto.isEnabled ?? false,
                environment: dto.environment ?? 'all',
              },
            ],
          },
          isSystem: false,
          updatedByStaffId: actorId,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'FEATURE_FLAG_CREATED',
          targetEntity: 'feature_flag',
          diffPayload: { key, isEnabled: flag.isEnabled, environment: flag.environment },
        },
      });

      return flag;
    });

    await this.redis?.del('feature_flags:all').catch(() => undefined);
    return created;
  }

  async updateFeatureFlag(
    key: string,
    dto: UpdateFeatureFlagDto,
    actorId: string,
  ) {
    const existing = await this.prisma.featureFlag.findUnique({
      where: { key },
    });
    if (!existing) throw new NotFoundException(`Feature flag '${key}' not found`);

    const existingRules =
      (existing.rules as { history?: Array<Record<string, unknown>> }) || {};
    const prevHistory = Array.isArray(existingRules.history)
      ? existingRules.history
      : [];

    const nextHistory = [
      {
        changedAt: new Date().toISOString(),
        changedBy: actorId,
        previousIsEnabled: existing.isEnabled,
        newIsEnabled: dto.isEnabled ?? existing.isEnabled,
        environment: dto.environment ?? existing.environment,
        rolloutPercentage: dto.rolloutPercentage ?? existing.rolloutPercentage,
      },
      ...prevHistory,
    ].slice(0, 30);

    const updated = await this.prisma.$transaction(async (tx) => {
      const flag = await tx.featureFlag.update({
        where: { key },
        data: {
          ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
          ...(dto.description !== undefined
            ? { description: dto.description }
            : {}),
          ...(dto.isEnabled !== undefined ? { isEnabled: dto.isEnabled } : {}),
          ...(dto.environment !== undefined
            ? { environment: dto.environment }
            : {}),
          ...(dto.rolloutPercentage !== undefined
            ? { rolloutPercentage: dto.rolloutPercentage }
            : {}),
          rules: { ...existingRules, history: nextHistory } as any,
          updatedByStaffId: actorId,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'FEATURE_FLAG_UPDATED',
          targetEntity: 'feature_flag',
          diffPayload: {
            key,
            previousIsEnabled: existing.isEnabled,
            newIsEnabled: flag.isEnabled,
            environment: flag.environment,
            rolloutPercentage: flag.rolloutPercentage,
          },
        },
      });

      return flag;
    });

    await this.redis?.del('feature_flags:all').catch(() => undefined);
    return updated;
  }

  async deleteFeatureFlag(key: string, actorId: string) {
    const existing = await this.prisma.featureFlag.findUnique({
      where: { key },
    });
    if (!existing) throw new NotFoundException(`Feature flag '${key}' not found`);
    if (existing.isSystem) {
      throw new ForbiddenException('System feature flags cannot be deleted.');
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.featureFlag.delete({ where: { key } });
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'FEATURE_FLAG_DELETED',
          targetEntity: 'feature_flag',
          diffPayload: { key },
        },
      });
    });

    await this.redis?.del('feature_flags:all').catch(() => undefined);
    return { success: true };
  }
}
