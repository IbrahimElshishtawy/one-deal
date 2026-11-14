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
    expect(sanitized).toContain('postgresql://***:***@db.internal:5432/railway');
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

  it('discovers all 6 existing Prisma migrations in backend/prisma/migrations', () => {
    const migrations = migrateDeploy.listLocalMigrations(
      path.join(backendRoot, 'prisma', 'migrations'),
    );
    expect(migrations).toHaveLength(6);
    expect(migrations[0]).toBe('20261102232252_init_database_foundation');
    expect(migrations[5]).toBe('20261104230259_add_demo_marker_and_indexes');
  });

  it('resolves the local Prisma CLI binary without npx', () => {
    const cliPath = migrateDeploy.resolvePrismaCliPath(backendRoot);
    expect(cliPath).toMatch(/node_modules[\\/]prisma[\\/]build[\\/]index\.js$/);
  });
});

