import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

/**
 * Apply a .sql migration file by hand. There is no migration runner in this repo.
 *
 * ── ▶ APPLY MIGRATIONS AS `postgres`, OVER THE SUPABASE MCP ────────────────────────────────────
 * That is the working path, and the one that has always actually been used. This script is a
 * convenience for when you have a `postgres`-grade connection string in MIGRATION_DATABASE_URL; it is
 * NOT usable with the API's credentials.
 *
 * TWO REASONS A LESSER ROLE CANNOT DO THIS JOB — both measured on 2026-08-07, not assumed:
 *
 *   1. RLS. Every table in `essentials` has RLS ENABLED with no permissive policy, so a role WITHOUT
 *      BYPASSRLS sees ZERO rows. `ev_api` works only because it HOLDS BYPASSRLS. Without it, SELECT
 *      returns nothing and UPDATE/DELETE match nothing WHILE STILL REPORTING SUCCESS — hence the
 *      blind-write guard below, which is the load-bearing safety feature of this file.
 *   2. Ownership. CREATE INDEX and ALTER TABLE on an existing table need table OWNERSHIP, which no
 *      schema-level grant confers, and `postgres` owns everything in `essentials`.
 *
 * Neither is fixable by granting: BYPASSRLS requires SUPERUSER and `postgres` is not one on Supabase.
 * A dedicated `ev_migrator` role was tried for exactly this (migration 1593) and dropped a day later
 * (migration 1595) once RLS made it inert. Don't rebuild it without reading both.
 *
 * DO NOT WIDEN `ev_api` to make this script work. It serves accounts-api.empowered.vote and already
 * holds BYPASSRLS; granting it CREATE would hand the internet-facing web role DDL on the election
 * corpus. Its lack of CREATE is why a CREATE TABLE migration fails against DATABASE_URL with the
 * genuinely misleading "permission denied for schema essentials" — the schema is fine, CREATE is what
 * is missing.
 *
 * Historical note: the "applied by hand via scripts/_apply-file.ts" line in migration headers before
 * 1593 was boilerplate and was NOT true of the DDL ones. All four archive tables (the
 * _fabricated_NNNN_removed and _retired_NNNN_x ones) are owned by `postgres`, not ev_api, so they
 * were applied over a `postgres` connection.
 */

/**
 * Treat blank as unset. `??` alone does NOT: `MIGRATION_DATABASE_URL=` in .env yields '', which is not
 * nullish, so it wins the fallback and the script then reports "neither is set" while DATABASE_URL sits
 * right there. Blanking a line is the obvious way to disable it, so it has to work.
 */
const env = (k: string): string | undefined => {
  const v = process.env[k];
  return v && v.trim() !== '' ? v : undefined;
};

const MIGRATION_URL = env('MIGRATION_DATABASE_URL');
const FALLBACK_URL = env('DATABASE_URL');
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
      '  ⚠ MIGRATION_DATABASE_URL is not set, falling back to the API role (ev_api). It has no CREATE\n' +
      '    on `essentials`, so any CREATE TABLE will fail. Prefer applying as `postgres` over the\n' +
      '    supabase MCP -- see the header of this file.',
    );
  }

  const client = await pool.connect();
  try {
    const { rows } = await client.query<{ role: string; can_create: boolean; visible: number }>(
      `SELECT current_user AS role,
              has_schema_privilege(current_user, 'essentials', 'CREATE') AS can_create,
              (SELECT count(*)::int FROM essentials.race_candidates) AS visible`,
    );
    const { role, can_create, visible } = rows[0]!;
    console.log(`  connected as ${role} (CREATE on essentials: ${can_create ? 'yes' : 'NO'})`);

    // ── THE RLS BLIND-WRITE GUARD ──────────────────────────────────────────────────────────────
    // Every table in `essentials` has RLS ENABLED with no permissive policy, so a role without
    // BYPASSRLS sees ZERO rows -- and an UPDATE matching zero rows SUCCEEDS. Without this check the
    // script prints "Applied OK" having changed nothing, which is worse than failing: it produces a
    // false record that a migration was applied. Caught 2026-08-07, after exactly that happened.
    if (visible === 0) {
      throw new Error(
        `role "${role}" can see 0 rows in essentials.race_candidates -- refusing to apply.\n\n` +
        'The table is not empty; RLS is hiding it. This role lacks BYPASSRLS, so SELECTs return\n' +
        'nothing and UPDATE/DELETE match nothing while still reporting success. Applying this file\n' +
        'would silently do nothing and claim it worked.\n\n' +
        'Use a role with BYPASSRLS (ev_api has it; `postgres` owns the tables). `postgres` CANNOT\n' +
        'grant BYPASSRLS -- it is not a superuser on Supabase -- so this cannot be fixed by granting.\n' +
        'See migration 1593.',
      );
    }

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

  // Supavisor reports a role that does not exist as "(EAUTHQUERY) user not found in the database",
  // with NO SQLSTATE, so it matches none of the branches below. A dropped role yields this OR 28P01
  // depending on whether the pooler's credential cache has caught up, so both paths must name it.
  if (/EAUTHQUERY|user not found in the database/i.test(err.message ?? '')) {
    console.error(
      '\nThe ROLE DOES NOT EXIST (the pooler says "user not found"), so this is not a password problem.\n' +
      '`ev_migrator` was dropped in migration 1595 — if backend/.env still sets MIGRATION_DATABASE_URL\n' +
      'to it, DELETE that line. With it gone the script falls back to DATABASE_URL (ev_api), which can\n' +
      'apply DML migrations but not CREATE TABLE; for those use `postgres` over the supabase MCP.',
    );
    process.exit(1);
  }

  // 28P01 = invalid_password. DO NOT immediately conclude the password is wrong: Supabase's pooler
  // (Supavisor) caches credentials, so for ~30-60s after `ALTER ROLE ... PASSWORD`, a CORRECT password
  // is still rejected here. Observed 2026-08-07 -- a rotation was diagnosed as a mismatch and rotated
  // a second time, when the only thing that actually fixed it was waiting. RETRY BEFORE RE-ROTATING.
  if (err.code === '28P01') {
    console.error('\nThis is an AUTH failure (SQLSTATE 28P01), which does NOT prove the password is wrong.');
    console.error(
      'Three causes, in the order worth checking:\n' +
      '  1. THE ROLE NO LONGER EXISTS. A dropped role gives this identical error. `ev_migrator` was\n' +
      '     dropped in migration 1595 -- if backend/.env still names it, delete that line.\n' +
      '  2. POOLER CACHE. Supabase\'s pooler serves the OLD credential for ~30-60s after ALTER ROLE, so\n' +
      '     a CORRECT new password is rejected. Wait and retry BEFORE re-rotating.\n' +
      '  3. Genuinely wrong password. Note a bare `new URL()` check will happily report a well-formed\n' +
      '     line that still holds the wrong string -- compare the value, not its shape.',
    );
  }

  // 42501 = insufficient_privilege. Say which privilege and which role, because the raw Postgres
  // message names the schema and thereby sends you looking in the wrong place.
  if (err.code === '42501') {
    console.error('\nThis is a PRIVILEGE error (SQLSTATE 42501), not a missing schema.');
    console.error(
      'Three different causes wear this same code, and the raw message misdirects on the first:\n' +
      '  "permission denied for schema essentials"        -> the role lacks CREATE (the schema is fine)\n' +
      '  "must be owner of table X"                       -> CREATE INDEX / ALTER TABLE need OWNERSHIP,\n' +
      '                                                      which no grant confers\n' +
      '  "new row violates row-level security policy"     -> the role lacks BYPASSRLS\n' +
      'All three are answered the same way: apply this migration as `postgres` over the supabase MCP.\n' +
      'BYPASSRLS cannot be granted (it needs SUPERUSER, and `postgres` is not one), and do NOT widen\n' +
      'ev_api to get around it. See the header of this file and migrations 1593/1595.',
    );
  }
  process.exit(1);
});
