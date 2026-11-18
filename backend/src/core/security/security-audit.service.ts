import {
  Injectable,
  Logger,
  Optional,
  OnModuleInit,
  OnModuleDestroy,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Queue, Worker } from 'bullmq';
import { PrismaService } from '../database/prisma.service';
import { RedisService } from '../redis/redis.service';

export interface AuditEventPayload {
  action: string;
  actorType?: 'user' | 'staff' | 'system' | 'anonymous';
  actorId?: string;
  targetEntity: string;
  targetId?: string;
  ipAddress?: string;
  userAgent?: string;
  correlationId?: string;
  metadata?: Record<string, unknown>;
}

interface NormalizedAuditRecord {
  actorType: string;
  actorId: string | null;
  action: string;
  targetEntity: string;
  targetId: string | null;
  ipAddress: string | null;
  userAgent: string | null;
  diffPayload: Record<string, unknown>;
}

/**
 * Structured Security Audit Service.
 * Writes immutable, non-sensitive audit records to PostgreSQL audit_log table.
 * Supports non-blocking async BullMQ queuing when AUDIT_QUEUE_ENABLED=true and Redis Queue is healthy,
 * with automatic direct DB write fallback.
 */
@Injectable()
export class SecurityAuditService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(SecurityAuditService.name);
  private readonly uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  private auditQueue: Queue | null = null;
  private auditWorker: Worker | null = null;

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly redis?: RedisService,
    @Optional() private readonly configService?: ConfigService,
  ) {}

  onModuleInit() {
    const queueEnabled =
      this.configService?.get<boolean>('AUDIT_QUEUE_ENABLED', false) ?? false;
    const workersEnabled =
      this.configService?.get<boolean>('ENABLE_WORKERS', true) ?? true;

    if (queueEnabled && this.redis?.isQueueClientConnected()) {
      const connection = this.redis.getQueueConnectionOptions();
      this.auditQueue = new Queue('audit-logs', { connection });

      if (workersEnabled) {
        this.auditWorker = new Worker(
          'audit-logs',
          async (job) => {
            await this.persistAuditRecord(
              job.data as NormalizedAuditRecord,
              true,
            );
          },
          { connection, concurrency: 5 },
        );
        this.auditWorker.on('failed', (job, err) => {
          this.logger.error(
            `🚨 Audit queue job [${job?.id}] failed (attempt ${job?.attemptsMade}/${job?.opts?.attempts ?? 1}): ${err.message}`,
          );
        });
        this.auditWorker.on('error', (err) => {
          this.logger.error(`🚨 Audit queue worker error: ${err.message}`);
        });
      }
    }
  }

  async onModuleDestroy() {
    await this.auditWorker?.close().catch(() => undefined);
    await this.auditQueue?.close().catch(() => undefined);
  }

  async logEvent(event: AuditEventPayload): Promise<void> {
    const record = this.normalizeEvent(event);

    if (this.auditQueue && this.redis?.isQueueClientConnected()) {
      try {
        await this.auditQueue.add('persist-audit', record, {
          removeOnComplete: 1000,
          removeOnFail: 5000,
          attempts: 5,
          backoff: { type: 'exponential', delay: 1000 },
        });
        return;
      } catch (err: any) {
        this.logger.warn(
          `Audit queue enqueue failed, falling back to direct DB write: ${err.message}`,
        );
      }
    }

    await this.persistAuditRecord(record);
  }

  private normalizeEvent(event: AuditEventPayload): NormalizedAuditRecord {
    const {
      action,
      actorType = event.actorId ? 'user' : 'system',
      actorId,
      targetEntity,
      targetId,
      ipAddress,
      userAgent,
      correlationId,
      metadata = {},
    } = event;

    const sanitizedMetadata = this.sanitizeMetadata(metadata);
    if (correlationId) {
      sanitizedMetadata.correlationId = correlationId;
    }

    let validActorId: string | null = null;
    if (actorId) {
      if (this.uuidRegex.test(actorId)) {
        validActorId = actorId;
      } else {
        sanitizedMetadata.rawActorId = actorId;
      }
    }

    let validTargetId: string | null = null;
    if (targetId) {
      if (this.uuidRegex.test(targetId)) {
        validTargetId = targetId;
      } else {
        sanitizedMetadata.rawTargetId = targetId;
      }
    }

    return {
      actorType,
      actorId: validActorId,
      action,
      targetEntity,
      targetId: validTargetId,
      ipAddress: ipAddress ? ipAddress.substring(0, 50) : null,
      userAgent: userAgent ? userAgent.substring(0, 500) : null,
      diffPayload: sanitizedMetadata,
    };
  }

  async persistAuditRecord(
    record: NormalizedAuditRecord,
    rethrow = false,
  ): Promise<void> {
    try {
      await this.prisma.auditLog.create({
        data: {
          actorType: record.actorType,
          actorId: record.actorId,
          action: record.action,
          targetEntity: record.targetEntity,
          targetId: record.targetId,
          ipAddress: record.ipAddress,
          userAgent: record.userAgent,
          diffPayload: record.diffPayload as any,
        },
      });

      this.logger.log(
        `🛡️ [SECURITY AUDIT] Action: ${record.action} | Entity: ${record.targetEntity}:${record.targetId || 'N/A'} | Actor: [${record.actorType}] ${record.actorId || 'Anonymous'}`,
      );
    } catch (err: any) {
      this.logger.error(
        `🚨 FAILED to record security audit log for action [${record.action}]: ${err.message}`,
        err.stack,
      );
      if (rethrow) {
        throw err;
      }
    }
  }

  private sanitizeMetadata(
    obj: Record<string, unknown>,
  ): Record<string, unknown> {
    const sensitiveExact = new Set(['code', 'otp', 'jwt', 'cookie']);
    const sensitiveSubstrings = [
      'password',
      'secret',
      'token',
      'authorization',
      'apikey',
      'api_key',
      'privatekey',
      'private_key',
    ];

    const isSensitiveKey = (key: string): boolean => {
      const lowerKey = key.toLowerCase();
      if (sensitiveExact.has(lowerKey)) return true;
      return sensitiveSubstrings.some((part) => lowerKey.includes(part));
    };

    const sanitized: Record<string, unknown> = {};

    for (const [key, value] of Object.entries(obj)) {
      if (isSensitiveKey(key)) {
        sanitized[key] = '[REDACTED]';
      } else if (
        value &&
        typeof value === 'object' &&
        !Array.isArray(value) &&
        !(value instanceof Date)
      ) {
        sanitized[key] = this.sanitizeMetadata(
          value as Record<string, unknown>,
        );
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }
}
