import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

/**
 * Builds a pooled DATABASE_URL with explicit connection_limit and pgbouncer=true
 * (when PGBOUNCER_ENABLED=true) so horizontal API replicas do not exhaust Postgres max_connections.
 */
export function buildDatabaseDatasourceUrl(
  rawUrl = process.env.DATABASE_URL,
  connectionLimit = process.env.DATABASE_CONNECTION_LIMIT,
  pgBouncerEnabled = process.env.PGBOUNCER_ENABLED === 'true',
): string | undefined {
  if (!rawUrl) return undefined;
  try {
    const parsed = new URL(rawUrl);
    if (connectionLimit && !parsed.searchParams.has('connection_limit')) {
      const limitNum = Number(connectionLimit);
      if (Number.isFinite(limitNum) && limitNum > 0) {
        parsed.searchParams.set(
          'connection_limit',
          String(Math.floor(limitNum)),
        );
      }
    }
    if (pgBouncerEnabled && !parsed.searchParams.has('pgbouncer')) {
      parsed.searchParams.set('pgbouncer', 'true');
    }
    return parsed.toString();
  } catch {
    return rawUrl;
  }
}

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);
  private isConnected = false;

  constructor() {
    const datasourceUrl = buildDatabaseDatasourceUrl();
    super({
      ...(datasourceUrl ? { datasources: { db: { url: datasourceUrl } } } : {}),
      log:
        process.env.NODE_ENV === 'development' ? ['warn', 'error'] : ['error'],
    });
  }

  async onModuleInit() {
    try {
      await this.$connect();
      this.isConnected = true;
      this.logger.log('✅ PostgreSQL connection successfully established.');

      const postgisCheck = await this.checkPostgisSupport();
      if (postgisCheck.supported) {
        this.logger.log(
          `🗺️ PostGIS extension verified: ${postgisCheck.version}`,
        );
      } else {
        this.logger.warn('⚠️ PostGIS extension not detected in PostgreSQL!');
      }
    } catch (error) {
      this.isConnected = false;
      this.logger.error('❌ Failed to connect to PostgreSQL database:', error);
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
    this.isConnected = false;
    this.logger.log('PostgreSQL connection closed.');
  }

  /**
   * Performs real DB connection verification.
   */
  async ping(): Promise<boolean> {
    try {
      await this.$queryRaw`SELECT 1`;
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Verifies PostGIS extension availability and returns version string.
   */
  async checkPostgisSupport(): Promise<{
    supported: boolean;
    version?: string;
  }> {
    try {
      const result = await this.$queryRaw<Array<{ postgis_version: string }>>`
        SELECT PostGIS_Version() as postgis_version;
      `;
      if (result && result.length > 0) {
        return { supported: true, version: result[0].postgis_version };
      }
      return { supported: false };
    } catch {
      return { supported: false };
    }
  }

  getIsConnected(): boolean {
    return this.isConnected;
  }
}
