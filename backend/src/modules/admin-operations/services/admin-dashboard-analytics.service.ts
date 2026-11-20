import { Injectable, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../core/database/prisma.service';
import { RedisService } from '../../../core/redis/redis.service';
import { MetricsService } from '../../../core/metrics/metrics.service';
import { EmailService } from '../../email/email.service';
import { AnalyticsQueryDto } from '../dto/admin-operations.dto';

function sanitizeCsvCell(val: unknown): string {
  const str = val === null || val === undefined ? '' : String(val);
  const safe = /^[=+\-@\t\r]/.test(str) ? `'${str}` : str;
  return `"${safe.replace(/"/g, '""')}"`;
}

@Injectable()
export class AdminDashboardAnalyticsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    @Optional() private readonly redis?: RedisService,
    @Optional() private readonly metricsService?: MetricsService,
    @Optional() private readonly emailService?: EmailService,
  ) {}

  async getOverview() {
    const now = new Date();
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const [
      totalUsers,
      newUsers7d,
      newUsers30d,
      activeUsers,
      suspendedUsers,
      bannedUsers,
      totalAccounts,
      verifiedAccounts,
      totalListings,
      publishedListings,
      pendingListings,
      rejectedListings,
      hiddenListings,
      expiredListings,
      openReports,
      pendingVerifications,
      totalConversations,
      recentAuditLogs,
      dbUp,
      cacheUp,
      queueUp,
    ] = await Promise.all([
      this.prisma.user.count({ where: { deletedAt: null } }),
      this.prisma.user.count({
        where: { deletedAt: null, createdAt: { gte: sevenDaysAgo } },
      }),
      this.prisma.user.count({
        where: { deletedAt: null, createdAt: { gte: thirtyDaysAgo } },
      }),
      this.prisma.user.count({
        where: {
          deletedAt: null,
          isActive: true,
          sessions: {
            some: {
              isRevoked: false,
              lastUsedAt: { gte: thirtyDaysAgo },
            },
          },
        },
      }),
      this.prisma.user.count({
        where: { deletedAt: null, moderationStatus: 'suspended' },
      }),
      this.prisma.user.count({
        where: { deletedAt: null, moderationStatus: 'banned' },
      }),
      this.prisma.account.count({ where: { deletedAt: null } }),
      this.prisma.account.count({
        where: { deletedAt: null, verificationStatus: 'approved' },
      }),
      this.prisma.listing.count({ where: { deletedAt: null } }),
      this.prisma.listing.count({
        where: {
          deletedAt: null,
          moderationStatus: 'approved',
          publicationStatus: 'published',
        },
      }),
      this.prisma.listing.count({
        where: { deletedAt: null, moderationStatus: 'pending' },
      }),
      this.prisma.listing.count({
        where: { deletedAt: null, moderationStatus: 'rejected' },
      }),
      this.prisma.listing.count({
        where: { deletedAt: null, publicationStatus: 'hidden' },
      }),
      this.prisma.listing.count({
        where: { deletedAt: null, publicationStatus: 'expired' },
      }),
      this.prisma.report.count({ where: { status: 'open' } }),
      this.prisma.accountVerification.count({ where: { status: 'pending' } }),
      this.prisma.conversation.count(),
      this.prisma.auditLog.findMany({
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
      this.prisma.ping().catch(() => false),
      this.redis ? this.redis.pingCache().catch(() => false) : Promise.resolve(false),
      this.redis ? this.redis.pingQueue().catch(() => false) : Promise.resolve(false),
    ]);

    return {
      kpis: {
        users: {
          total: totalUsers,
          new7d: newUsers7d,
          new30d: newUsers30d,
          active30d: activeUsers,
          suspended: suspendedUsers,
          banned: bannedUsers,
        },
        accounts: {
          total: totalAccounts,
          verified: verifiedAccounts,
        },
        listings: {
          total: totalListings,
          published: publishedListings,
          pending: pendingListings,
          rejected: rejectedListings,
          hidden: hiddenListings,
          expired: expiredListings,
        },
        moderation: {
          openReports,
          pendingVerifications,
          totalConversations,
        },
      },
      platformHealth: {
        status: dbUp && cacheUp ? 'healthy' : 'degraded',
        database: dbUp ? 'up' : 'down',
        redisCache: cacheUp ? 'up' : 'down',
        redisQueue: queueUp ? 'up' : 'down',
      },
      recentActivities: recentAuditLogs,
      generatedAt: now.toISOString(),
    };
  }

  async getCharts(days = 30) {
    const safeDays = Math.min(Math.max(days, 7), 90);
    const since = new Date(Date.now() - safeDays * 24 * 60 * 60 * 1000);

    const [userSeries, listingSeries, categoryGroups, reportReasonGroups] =
      await Promise.all([
        this.prisma.$queryRaw<Array<{ day: string; count: number }>>`
          SELECT to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS day,
                 COUNT(*)::int AS count
          FROM users
          WHERE deleted_at IS NULL AND created_at >= ${since}
          GROUP BY 1
          ORDER BY 1 ASC
        `,
        this.prisma.$queryRaw<Array<{ day: string; count: number }>>`
          SELECT to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS day,
                 COUNT(*)::int AS count
          FROM listings
          WHERE deleted_at IS NULL AND created_at >= ${since}
          GROUP BY 1
          ORDER BY 1 ASC
        `,
        this.prisma.$queryRaw<
          Array<{
            categoryId: string;
            nameEn: string;
            nameAr: string;
            count: number;
          }>
        >`
          SELECT c.id AS "categoryId",
                 c.name_en AS "nameEn",
                 c.name_ar AS "nameAr",
                 COUNT(l.id)::int AS count
          FROM categories c
          LEFT JOIN listings l ON l.category_id = c.id AND l.deleted_at IS NULL
          GROUP BY c.id, c.name_en, c.name_ar
          ORDER BY count DESC
          LIMIT 10
        `,
        this.prisma.report.groupBy({
          by: ['reason'],
          _count: { _all: true },
        }),
      ]);

    const dayMap = new Map<
      string,
      { date: string; users: number; listings: number }
    >();
    for (let i = safeDays - 1; i >= 0; i--) {
      const d = new Date(Date.now() - i * 24 * 60 * 60 * 1000)
        .toISOString()
        .slice(0, 10);
      dayMap.set(d, { date: d, users: 0, listings: 0 });
    }
    for (const row of userSeries) {
      const entry = dayMap.get(row.day);
      if (entry) entry.users = Number(row.count);
    }
    for (const row of listingSeries) {
      const entry = dayMap.get(row.day);
      if (entry) entry.listings = Number(row.count);
    }

    return {
      activitySeries: Array.from(dayMap.values()),
      categoryStats: categoryGroups,
      reportReasons: reportReasonGroups.map((r) => ({
        reason: r.reason,
        count: r._count._all,
      })),
    };
  }

  async getAnalyticsSummary(query: AnalyticsQueryDto) {
    const toDate = query.to ? new Date(query.to) : new Date();
    const fromDate = query.from
      ? new Date(query.from)
      : new Date(toDate.getTime() - 30 * 24 * 60 * 60 * 1000);

    const dateRange = { gte: fromDate, lte: toDate };

    const [
      usersCreated,
      activeUsers,
      suspendedUsers,
      bannedUsers,
      listingsByModeration,
      listingsByPublication,
      reportsByStatus,
      reportsByReason,
      verificationsByStatus,
      campaignsStats,
      charts,
    ] = await Promise.all([
      this.prisma.user.count({
        where: { deletedAt: null, createdAt: dateRange },
      }),
      this.prisma.user.count({
        where: { deletedAt: null, isActive: true },
      }),
      this.prisma.user.count({
        where: { deletedAt: null, moderationStatus: 'suspended' },
      }),
      this.prisma.user.count({
        where: { deletedAt: null, moderationStatus: 'banned' },
      }),
      this.prisma.listing.groupBy({
        by: ['moderationStatus'],
        where: { deletedAt: null, createdAt: dateRange },
        _count: { _all: true },
      }),
      this.prisma.listing.groupBy({
        by: ['publicationStatus'],
        where: { deletedAt: null, createdAt: dateRange },
        _count: { _all: true },
      }),
      this.prisma.report.groupBy({
        by: ['status'],
        where: { createdAt: dateRange },
        _count: { _all: true },
      }),
      this.prisma.report.groupBy({
        by: ['reason'],
        where: { createdAt: dateRange },
        _count: { _all: true },
      }),
      this.prisma.accountVerification.groupBy({
        by: ['status'],
        where: { createdAt: dateRange },
        _count: { _all: true },
      }),
      this.prisma.notificationCampaign.aggregate({
        where: { createdAt: dateRange },
        _count: { _all: true },
        _sum: {
          sentCount: true,
          deliveredCount: true,
          failedCount: true,
        },
      }),
      this.getCharts(
        Math.max(
          7,
          Math.ceil(
            (toDate.getTime() - fromDate.getTime()) / (24 * 60 * 60 * 1000),
          ),
        ),
      ),
    ]);

    return {
      period: {
        from: fromDate.toISOString(),
        to: toDate.toISOString(),
      },
      scopeNote:
        'V1 Marketplace Scope: Metrics reflect real operational entities only (no fabricated revenue or order transactions).',
      users: {
        newRegistrations: usersCreated,
        totalActive: activeUsers,
        suspended: suspendedUsers,
        banned: bannedUsers,
      },
      listings: {
        byModerationStatus: listingsByModeration.map((x) => ({
          status: x.moderationStatus,
          count: x._count._all,
        })),
        byPublicationStatus: listingsByPublication.map((x) => ({
          status: x.publicationStatus,
          count: x._count._all,
        })),
      },
      moderation: {
        reportsByStatus: reportsByStatus.map((x) => ({
          status: x.status,
          count: x._count._all,
        })),
        reportsByReason: reportsByReason.map((x) => ({
          reason: x.reason,
          count: x._count._all,
        })),
      },
      verifications: {
        byStatus: verificationsByStatus.map((x) => ({
          status: x.status,
          count: x._count._all,
        })),
      },
      notifications: {
        campaignsCount: campaignsStats._count._all,
        sentCount: campaignsStats._sum.sentCount ?? 0,
        deliveredCount: campaignsStats._sum.deliveredCount ?? 0,
        failedCount: campaignsStats._sum.failedCount ?? 0,
      },
      categoryStats: charts.categoryStats,
      activitySeries: charts.activitySeries,
    };
  }

  async exportAnalytics(actorId: string, query: AnalyticsQueryDto) {
    const summary = await this.getAnalyticsSummary(query);

    await this.prisma.auditLog.create({
      data: {
        actorType: 'staff',
        actorId,
        action: 'ANALYTICS_EXPORTED',
        targetEntity: 'analytics',
        diffPayload: {
          from: summary.period.from,
          to: summary.period.to,
          format: query.format || 'csv',
        },
      },
    });

    if (query.format === 'json') {
      return summary;
    }

    const lines: string[] = [
      'section,metric,value',
      ['users', 'newRegistrations', summary.users.newRegistrations]
        .map(sanitizeCsvCell)
        .join(','),
      ['users', 'totalActive', summary.users.totalActive]
        .map(sanitizeCsvCell)
        .join(','),
      ['users', 'suspended', summary.users.suspended]
        .map(sanitizeCsvCell)
        .join(','),
      ['users', 'banned', summary.users.banned]
        .map(sanitizeCsvCell)
        .join(','),
    ];

    for (const item of summary.listings.byModerationStatus) {
      lines.push(
        ['listings_moderation', item.status, item.count]
          .map(sanitizeCsvCell)
          .join(','),
      );
    }
    for (const item of summary.moderation.reportsByStatus) {
      lines.push(
        ['reports_status', item.status, item.count]
          .map(sanitizeCsvCell)
          .join(','),
      );
    }
    for (const item of summary.verifications.byStatus) {
      lines.push(
        ['verifications_status', item.status, item.count]
          .map(sanitizeCsvCell)
          .join(','),
      );
    }
    for (const cat of summary.categoryStats) {
      lines.push(
        ['category_listings', cat.nameEn, cat.count]
          .map(sanitizeCsvCell)
          .join(','),
      );
    }

    return {
      format: 'csv',
      period: summary.period,
      csv: lines.join('\n'),
    };
  }

  async getSystemHealth() {
    const dbStart = performance.now();
    const dbUp = await this.prisma.ping().catch(() => false);
    const dbLatencyMs = Math.round((performance.now() - dbStart) * 100) / 100;

    const postgis = await this.prisma
      .checkPostgisSupport()
      .catch(() => ({ supported: false, version: undefined }));

    const cacheStart = performance.now();
    const cacheUp = this.redis
      ? await this.redis.pingCache().catch(() => false)
      : false;
    const cacheLatencyMs =
      Math.round((performance.now() - cacheStart) * 100) / 100;

    const queueUp = this.redis
      ? await this.redis.pingQueue().catch(() => false)
      : false;

    const outboxStats = await this.prisma.outboxEvent.groupBy({
      by: ['status'],
      _count: { _all: true },
    });

    const outboxMap: Record<string, number> = {
      PENDING: 0,
      PROCESSING: 0,
      PUBLISHED: 0,
      FAILED: 0,
    };
    for (const row of outboxStats) {
      outboxMap[row.status] = row._count._all;
    }

    const r2Key = this.configService.get<string>('R2_ACCESS_KEY_ID', '');
    const storageConfigured =
      Boolean(r2Key) && !r2Key.toLowerCase().includes('placeholder');

    const fcmEmail = this.configService.get<string>(
      'FIREBASE_CLIENT_EMAIL',
      '',
    );
    const fcmConfigured =
      Boolean(fcmEmail) && !fcmEmail.toLowerCase().includes('placeholder');

    const mem = process.memoryUsage();
    const prometheusSample = this.metricsService?.renderPrometheus() || '';
    const totalHttpRequests = prometheusSample
      .split('\n')
      .filter((l) => l.startsWith('http_requests_total{'))
      .reduce((sum, line) => {
        const val = Number(line.split(' ').pop() || 0);
        return sum + (Number.isFinite(val) ? val : 0);
      }, 0);
    const serverErrors5xx = prometheusSample
      .split('\n')
      .filter(
        (l) => l.startsWith('http_requests_total{') && l.includes('status_code="5'),
      )
      .reduce((sum, line) => {
        const val = Number(line.split(' ').pop() || 0);
        return sum + (Number.isFinite(val) ? val : 0);
      }, 0);

    return {
      overallStatus: dbUp && cacheUp ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      runtime: {
        nodeEnv: this.configService.get<string>('NODE_ENV', 'development'),
        uptimeSeconds: Math.floor(process.uptime()),
        memoryRssMb: Math.round(mem.rss / 1024 / 1024),
        heapUsedMb: Math.round(mem.heapUsed / 1024 / 1024),
      },
      database: {
        status: dbUp ? 'up' : 'down',
        latencyMs: dbLatencyMs,
        postgisSupported: postgis.supported,
        postgisVersion: postgis.version ?? null,
      },
      redis: {
        cacheStatus: cacheUp ? 'up' : 'down',
        cacheLatencyMs,
        queueStatus: queueUp ? 'up' : 'down',
      },
      integrations: {
        objectStorage: storageConfigured ? 'configured' : 'unconfigured',
        emailResend: this.emailService
          ? this.emailService.getReadinessStatus()
          : 'unconfigured',
        pushFcm: fcmConfigured ? 'configured' : 'mock_or_unconfigured',
      },
      queuesAndOutbox: {
        outbox: outboxMap,
      },
      apiPerformance: {
        totalHttpRequests,
        serverErrors5xx,
        errorRatePercent:
          totalHttpRequests > 0
            ? Math.round((serverErrors5xx / totalHttpRequests) * 10000) / 100
            : 0,
      },
    };
  }
}
