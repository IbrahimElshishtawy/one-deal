#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const { PrismaClient } = require('@prisma/client');

const MIGRATION_LOCK_ID = 84920173;

/**
 * Redacts credentials from any PostgreSQL connection string before logging.
 * @param {unknown} value
 * @returns {string}
 */
function sanitizeMessage(value) {
  const text = value instanceof Error ? value.message : String(value ?? '');
  return text.replace(
    /(postgres(?:ql)?:\/\/)([^:@\s]+):([^@\s]+)@/gi,
    '$1***:***@',
  );
}

/**
 * Validates DATABASE_URL and enforces connection_limit=1 so session-level
 * PostgreSQL advisory locks remain bound to a single backend connection.
 * @param {string | undefined} rawUrl
 * @returns {string}
 */
function buildSingleConnectionUrl(rawUrl) {
  if (!rawUrl || !rawUrl.trim()) {
    throw new Error(
      'DATABASE_URL environment variable is missing or empty. Aborting migration.',
    );
  }

  let parsed;
  try {
    parsed = new URL(rawUrl.trim());
  } catch {
    throw new Error('DATABASE_URL is not a valid URL. Aborting migration.');
  }

  if (parsed.protocol !== 'postgresql:' && parsed.protocol !== 'postgres:') {
    throw new Error(
      `Unsupported DATABASE_URL protocol "${parsed.protocol}". Expected postgresql:// or postgres://.`,
    );
  }

  parsed.searchParams.set('connection_limit', '1');
  return parsed.toString();
}

/**
 * Lists local migration directory names containing migration.sql.
 * @param {string} migrationsDir
 * @returns {string[]}
 */
function listLocalMigrations(migrationsDir) {
  if (!fs.existsSync(migrationsDir)) {
    throw new Error(`Migrations directory not found at ${migrationsDir}`);
  }

  const entries = fs.readdirSync(migrationsDir, { withFileTypes: true });
  return entries
    .filter((entry) => {
      if (!entry.isDirectory()) return false;
      return fs.existsSync(path.join(migrationsDir, entry.name, 'migration.sql'));
    })
    .map((entry) => entry.name)
    .sort();
}

/**
 * Resolves the local Prisma CLI entrypoint without invoking npx.
 * @param {string} appRoot
 * @returns {string}
 */
function resolvePrismaCliPath(appRoot) {
  const cliPath = path.join(
    appRoot,
    'node_modules',
    'prisma',
    'build',
    'index.js',
  );
  if (!fs.existsSync(cliPath)) {
    throw new Error(
      `Local Prisma CLI not found at ${cliPath}. Ensure prisma and @prisma/engines are installed in the runtime image.`,
    );
  }
  return cliPath;
}

async function run() {
  const appRoot = path.resolve(__dirname, '..');
  const prismaDir = path.join(appRoot, 'prisma');
  const schemaPath = path.join(prismaDir, 'schema.prisma');
  const migrationsDir = path.join(prismaDir, 'migrations');

  if (!fs.existsSync(schemaPath)) {
    throw new Error(`Prisma schema not found at ${schemaPath}`);
  }

  const localMigrations = listLocalMigrations(migrationsDir);
  if (localMigrations.length === 0) {
    throw new Error(`No migration.sql files found under ${migrationsDir}`);
  }

  const prismaCliPath = resolvePrismaCliPath(appRoot);
  const singleConnUrl = buildSingleConnectionUrl(process.env.DATABASE_URL);

  const prisma = new PrismaClient({
    datasources: { db: { url: singleConnUrl } },
    log: ['error'],
  });

  let lockHeld = false;

  try {
    console.log(
      `[migrate-deploy] Found ${localMigrations.length} local Prisma migration(s).`,
    );
    console.log('[migrate-deploy] Verifying database connectivity...');
    await prisma.$connect();
    await prisma.$queryRawUnsafe('SELECT 1 AS ok');

    const versionRows = await prisma.$queryRawUnsafe(
      'SELECT version() AS version',
    );
    console.log(
      `[migrate-deploy] Connected to: ${versionRows[0]?.version ?? 'PostgreSQL'}`,
    );

    const postgisRows = await prisma.$queryRawUnsafe(
      "SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'postgis'",
    );
    if (!postgisRows || postgisRows.length === 0) {
      throw new Error(
        'PostGIS extension is not available on this PostgreSQL server. Aborting safely.',
      );
    }
    const postgisInfo = postgisRows[0];
    if (postgisInfo.installed_version) {
      console.log(
        `[migrate-deploy] PostGIS extension already installed (v${postgisInfo.installed_version}).`,
      );
    } else {
      console.log(
        `[migrate-deploy] PostGIS extension available (v${postgisInfo.default_version}); will be enabled during initial migration.`,
      );
    }

    console.log(
      `[migrate-deploy] Acquiring PostgreSQL advisory lock (${MIGRATION_LOCK_ID})...`,
    );
    const tryLockRows = await prisma.$queryRawUnsafe(
      `SELECT pg_try_advisory_lock(${MIGRATION_LOCK_ID}) AS acquired`,
    );
    if (!tryLockRows[0]?.acquired) {
      console.log(
        '[migrate-deploy] Another migration process holds the lock; waiting...',
      );
      await prisma.$executeRawUnsafe(
        `SELECT pg_advisory_lock(${MIGRATION_LOCK_ID})`,
      );
    }
    lockHeld = true;
    console.log('[migrate-deploy] Advisory lock acquired.');

    const historyExistsRows = await prisma.$queryRawUnsafe(
      "SELECT to_regclass('public._prisma_migrations') IS NOT NULL AS exists",
    );
    const historyExists = Boolean(historyExistsRows[0]?.exists);

    if (historyExists) {
      const historyRows = await prisma.$queryRawUnsafe(
        'SELECT migration_name, finished_at, rolled_back_at FROM "_prisma_migrations" ORDER BY started_at ASC',
      );
      const failedRows = historyRows.filter(
        (row) => row.finished_at === null && row.rolled_back_at === null,
      );
      if (failedRows.length > 0) {
        const names = failedRows.map((row) => row.migration_name).join(', ');
        throw new Error(
          `Partially applied or failed migration(s) detected in _prisma_migrations: [${names}]. Stopping to preserve production data; resolve manually before retrying.`,
        );
      }

      const appliedCount = historyRows.filter(
        (row) => row.finished_at !== null && row.rolled_back_at === null,
      ).length;
      console.log(
        `[migrate-deploy] Existing migration history healthy (${appliedCount} applied).`,
      );
    } else {
      const existingTables = await prisma.$queryRawUnsafe(
        "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename NOT IN ('spatial_ref_sys') ORDER BY tablename ASC",
      );
      if (existingTables.length > 0) {
        const tableList = existingTables.map((row) => row.tablename).join(', ');
        throw new Error(
          `Database schema is non-empty without _prisma_migrations (found: ${tableList}). Stopping to protect existing data; baseline manually before running prisma migrate deploy.`,
        );
      }
      console.log(
        '[migrate-deploy] Fresh database detected (no _prisma_migrations yet). Ready to apply baseline migrations.',
      );
    }

    console.log('[migrate-deploy] Executing local prisma migrate deploy...');
    execFileSync(
      process.execPath,
      [prismaCliPath, 'migrate', 'deploy', '--schema', schemaPath],
      {
        cwd: appRoot,
        stdio: 'inherit',
        env: process.env,
      },
    );

    const listingsCheck = await prisma.$queryRawUnsafe(
      "SELECT to_regclass('public.listings') IS NOT NULL AS exists",
    );
    if (!listingsCheck[0]?.exists) {
      throw new Error(
        'Post-migration check failed: table public.listings does not exist after migrate deploy.',
      );
    }

    const postgisVersionRows = await prisma.$queryRawUnsafe(
      'SELECT PostGIS_Version() AS postgis_version',
    );
    console.log(
      `[migrate-deploy] Verified public.listings exists and PostGIS active: ${postgisVersionRows[0]?.postgis_version ?? 'ok'}`,
    );

    const postHistoryRows = await prisma.$queryRawUnsafe(
      'SELECT migration_name, finished_at, rolled_back_at FROM "_prisma_migrations" ORDER BY started_at ASC',
    );
    const postFailed = postHistoryRows.filter(
      (row) => row.finished_at === null && row.rolled_back_at === null,
    );
    const postApplied = postHistoryRows.filter(
      (row) => row.finished_at !== null && row.rolled_back_at === null,
    );
    if (postFailed.length > 0 || postApplied.length < localMigrations.length) {
      throw new Error(
        `Post-migration verification failed: applied=${postApplied.length}, expected>=${localMigrations.length}, failed=${postFailed.length}`,
      );
    }

    console.log(
      `[migrate-deploy] All ${postApplied.length} migration(s) verified successfully.`,
    );
  } finally {
    if (lockHeld) {
      try {
        await prisma.$executeRawUnsafe(
          `SELECT pg_advisory_unlock(${MIGRATION_LOCK_ID})`,
        );
        console.log('[migrate-deploy] Advisory lock released.');
      } catch (unlockError) {
        console.error(
          `[migrate-deploy] Warning: failed to release advisory lock cleanly: ${sanitizeMessage(unlockError)}`,
        );
      }
    }
    await prisma.$disconnect().catch(() => {});
  }
}

if (require.main === module) {
  run().catch((error) => {
    console.error(`[migrate-deploy] FAILED: ${sanitizeMessage(error)}`);
    process.exit(1);
  });
}

module.exports = {
  MIGRATION_LOCK_ID,
  sanitizeMessage,
  buildSingleConnectionUrl,
  listLocalMigrations,
  resolvePrismaCliPath,
  run,
};
