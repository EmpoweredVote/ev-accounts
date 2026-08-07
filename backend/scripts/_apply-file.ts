import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

/**
 * Apply a .sql migration file by hand. There is no migration runner in this repo.
 *
 * ── WHICH ROLE THIS CONNECTS AS, AND WHY IT MATTERS ────────────────────────────────────────────
 * Prefers MIGRATION_DATABASE_URL (role `ev_migrator`) and falls back to DATABASE_URL (role
 * `ev_api`). They are not interchangeable:
 *
 *   ev_api      the LIVE API's role. Has USAGE on `essentials` and full SELECT/INSERT/UPDATE/DELETE,
 *               but NO CREATE on the schema. Any migration containing CREATE TABLE -- which is every
 *               migration that archives rows before deleting them -- fails against it with the
 *               genuinely misleading "permission denied for schema essentials". The schema is not
 *               the problem; CREATE is. It also holds BYPASSRLS, so it is not a role to widen.
 *   ev_migrator added 2026-08-07 for exactly this job. Same DML, plus CREATE on `essentials` and
 *               `inform`. No SUPERUSER, no CREATEDB, no CREATEROLE, no BYPASSRLS, and no membership
 *               in `postgres`.
 *
 * ⚠ ev_migrator's CEILING: CREATE INDEX and ALTER TABLE on an EXISTING table require table
 * OWNERSHIP, which no schema-level grant can confer. Every table in `essentials` is owned by
 * `postgres`. So migrations that add a column or build an index (e.g. 1574, 1586, 1589) still cannot
 * run through this script under any grant short of making ev_migrator a table owner -- run those as
 * `postgres`. Data migrations and archive-table migrations (e.g. 1588, 1590-1592) work fine here.
 *
 * Historical note: the "applied by hand via scripts/_apply-file.ts" line in migration headers before
 * 1593 was boilerplate and was NOT true of the DDL ones. All four archive tables (the
 * _fabricated_NNNN_removed and _retired_NNNN_x ones) are owned by `postgres`, not ev_api, so they
 * were applied over a `postgres` connection.
 */

const MIGRATION_URL = process.env['MIGRATION_DATABASE_URL'];
const FALLBACK_URL = process.env['DATABASE_URL'];
const connectionString = MIGRATION_URL ?? FALLBACK_URL;

const file = process.argv[2];
if (!file) {
  console.error('usage: tsx _apply-file.ts <path-to-sql>');
  process.exit(2);
}
if (!connectionString) {
  console.error('Neither MIGRATION_DATABASE_URL nor DATABASE_URL is set.');
  process.exit(2);
}

/** Describe the target without ever printing the password. */
function describe(url: string): string {
  try {
    const u = new URL(url);
    return `${u.username.split('.')[0]}@${u.hostname}/${u.pathname.replace(/^\//, '')}`;
  } catch {
    return '(unparseable connection string)';
  }
}

const pool = new Pool({ connectionString, ssl: { rejectUnauthorized: false } });

async function main() {
  const sql = readFileSync(path.resolve(process.cwd(), file), 'utf8');
  const which = MIGRATION_URL ? 'MIGRATION_DATABASE_URL' : 'DATABASE_URL';
  console.log(`Applying ${file}`);
  console.log(`  via ${which} -> ${describe(connectionString!)}`);
  if (!MIGRATION_URL) {
    console.warn(
      '  ⚠ MIGRATION_DATABASE_URL is not set, falling back to the API role (ev_api). DML will\n' +
      '    work; anything with CREATE TABLE will fail. See the header of this file.',
    );
  }

  const client = await pool.connect();
  try {
    const { rows } = await client.query<{ role: string; can_create: boolean }>(
      `SELECT current_user AS role,
              has_schema_privilege(current_user, 'essentials', 'CREATE') AS can_create`,
    );
    const { role, can_create } = rows[0]!;
    console.log(`  connected as ${role} (CREATE on essentials: ${can_create ? 'yes' : 'NO'})`);

    await client.query(sql);
    console.log(`Applied ${file} OK`);
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((e: unknown) => {
  const err = e as { message?: string; code?: string };
  console.error('APPLY FAILED:', err.message);

  // 42501 = insufficient_privilege. Say which privilege and which role, because the raw Postgres
  // message names the schema and thereby sends you looking in the wrong place.
  if (err.code === '42501') {
    console.error('\nThis is a PRIVILEGE error (SQLSTATE 42501), not a missing schema.');
    if (!MIGRATION_URL) {
      console.error(
        'You are on DATABASE_URL (ev_api), which has no CREATE on `essentials`.\n' +
        'Set MIGRATION_DATABASE_URL in backend/.env to the ev_migrator connection string and retry.',
      );
    } else {
      console.error(
        'You are already on MIGRATION_DATABASE_URL (ev_migrator). If this migration does\n' +
        'CREATE INDEX or ALTER TABLE on an existing table, that needs table OWNERSHIP and no grant\n' +
        'will fix it -- apply this one as `postgres`. See the header of this file.',
      );
    }
  }
  process.exit(1);
});
