import * as path from 'node:path';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const migrateDeploy = require('../../../scripts/migrate-deploy');

describe('migrate-deploy script helpers', () => {
  const backendRoot = path.resolve(__dirname, '..', '..', '..');

  it('redacts PostgreSQL credentials from error messages', () => {
    const raw =
      'P1001: Can not reach database at postgresql://postgres:SuperSecret123@db.internal:5432/railway';
    const sanitized = migrateDeploy.sanitizeMessage(raw);
    expect(sanitized).not.toContain('SuperSecret123');
    expect(sanitized).toContain(
      'postgresql://***:***@db.internal:5432/railway',
    );
  });

  it('rejects missing or invalid DATABASE_URL values', () => {
    expect(() => migrateDeploy.buildSingleConnectionUrl(undefined)).toThrow(
      /missing or empty/i,
    );
    expect(() => migrateDeploy.buildSingleConnectionUrl('not-a-url')).toThrow(
      /not a valid URL/i,
    );
    expect(() =>
      migrateDeploy.buildSingleConnectionUrl('mysql://user:pass@host/db'),
    ).toThrow(/Unsupported DATABASE_URL protocol/i);
  });

  it('enforces connection_limit=1 on valid PostgreSQL URLs', () => {
    const url = migrateDeploy.buildSingleConnectionUrl(
      'postgresql://user:pass@localhost:5432/marketspace?schema=public&connection_limit=10',
    );
    const parsed = new URL(url);
    expect(parsed.searchParams.get('connection_limit')).toBe('1');
    expect(parsed.searchParams.get('schema')).toBe('public');
  });

  it('discovers all existing Prisma migrations in backend/prisma/migrations', () => {
    const migrations = migrateDeploy.listLocalMigrations(
      path.join(backendRoot, 'prisma', 'migrations'),
    );
    expect(migrations).toHaveLength(17);
    expect(migrations[0]).toBe('20261102232252_init_database_foundation');
    expect(migrations[5]).toBe('20261104230259_add_demo_marker_and_indexes');
    expect(migrations[6]).toBe(
      '20261117000001_add_payments_and_listing_promotion_search',
    );
    expect(migrations[7]).toBe(
      '20261117000002_add_trgm_jsonb_indexes_and_pg_stat_statements',
    );
    expect(migrations[8]).toBe('20261120000001_add_enterprise_admin_platform');
    expect(migrations[9]).toBe('20261121213256_add_activity_hub_domains');
    expect(migrations[10]).toBe(
      '20261122000001_stabilize_activity_hub_constraints_and_outbox',
    );
    expect(migrations[11]).toBe(
      '20261124000001_add_seller_verification_system',
    );
    expect(migrations[12]).toBe(
      '20261126000001_enhance_seller_verification_identity_review',
    );
    expect(migrations[13]).toBe(
      '20261126000002_add_verification_tiers_and_business_upgrade',
    );
    expect(migrations[14]).toBe(
      '20261127000001_harden_seller_verification_lifecycle',
    );
    expect(migrations[15]).toBe(
      '20261127000002_add_message_idempotency_and_suspended_uniqueness',
    );
    expect(migrations[16]).toBe('20261127000003_add_seller_deals_crm');
  });

  it('redacts Redis credentials from error messages', () => {
    const raw =
      'Connection failed to redis://:RedisPass123@redis.internal:6379 and rediss://default:TlsPass456@upstash.io:6379';
    const sanitized = migrateDeploy.sanitizeMessage(raw);
    expect(sanitized).not.toContain('RedisPass123');
    expect(sanitized).not.toContain('TlsPass456');
    expect(sanitized).toContain('redis://***:***@redis.internal:6379');
    expect(sanitized).toContain('rediss://***:***@upstash.io:6379');
  });

  it('resolves the local Prisma CLI binary without npx', () => {
    const cliPath = migrateDeploy.resolvePrismaCliPath(backendRoot);
    expect(cliPath).toMatch(/node_modules[\\/]prisma[\\/]build[\\/]index\.js$/);
  });

  it('resolves the compiled seed script path and throws when missing', () => {
    const seedPath = migrateDeploy.resolveCompiledSeedPath(backendRoot);
    expect(seedPath).toMatch(/dist[\\/]prisma[\\/]seeds[\\/]seed\.js$/);
    expect(() =>
      migrateDeploy.resolveCompiledSeedPath(
        path.join(backendRoot, 'nonexistent-dir'),
      ),
    ).toThrow(/Compiled seed script not found/i);
  });

  it('returns false safely from invalidateCatalogRedisCache when no Redis URL is configured', async () => {
    await expect(migrateDeploy.invalidateCatalogRedisCache({})).resolves.toBe(
      false,
    );
  });

  it('prefers DIRECT_DATABASE_URL and rejects PgBouncer transaction-pooled URLs', () => {
    const resolved = migrateDeploy.resolveMigrationDatabaseUrl({
      DATABASE_URL:
        'postgresql://user:pass@pgbouncer:6432/marketspace?schema=public&pgbouncer=true',
      DIRECT_DATABASE_URL:
        'postgresql://user:pass@postgres:5432/marketspace?schema=public',
    });
    const parsed = new URL(resolved);
    expect(parsed.hostname).toBe('postgres');
    expect(parsed.port).toBe('5432');
    expect(parsed.searchParams.get('connection_limit')).toBe('1');

    expect(() =>
      migrateDeploy.resolveMigrationDatabaseUrl({
        DATABASE_URL:
          'postgresql://user:pass@pgbouncer:6432/marketspace?schema=public&pgbouncer=true',
      }),
    ).toThrow(/PgBouncer transaction pooling/i);
  });
});
