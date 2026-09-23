#!/usr/bin/env node
/**
 * check-rls-coverage — a live tripwire for the drift the 2026-09-10 RLS audit
 * (CTO decision 0015) was supposed to end: a base table that `anon` or
 * `authenticated` can SELECT with row-level security OFF. That is the property
 * behind Supabase's `rls_disabled_in_public` advisor, and it keeps re-opening —
 * treasury tables (2026-09-16..18), essentials.source_hubs (1869), and
 * essentials._fabricated_ca0156_removed (CA_0156, a `CREATE TABLE ... AS` backup)
 * all landed RLS-off AFTER the sweep. This is the automated form of the weekly
 * advisor read that caught each of them.
 *
 * 🔴 WHY A LIVE CHECK, NOT A STATIC ONE. The treasury-tracker sibling
 * (scripts/lib/exposedTableRls.mjs) scans migration TEXT because that repo keeps
 * no DB credential in CI. ev-accounts CI has DATABASE_URL, and a live read is
 * strictly better here: tables arrive in prod off-commit (migrations are applied
 * by hand, ad hoc — there is no schema_migrations runner), and some are made by
 * `CREATE TABLE ... AS` or by scripts, which no text scan of migrations can see.
 * The live catalog is the only faithful source.
 *
 * WHAT IT FLAGS. Every base table (relkind='r') with relrowsecurity = false that
 * anon or authenticated holds SELECT on, in any application schema. A table with
 * RLS ON keeps its grant but denies rows, so it passes; a table anon cannot SELECT
 * at all is not a read exposure, so it is not flagged. Supabase-internal schemas
 * (auth, storage, realtime, vault, cron, …) are excluded — we do not own them.
 * Verified 2026-09-23 against prod kxsdzaojfaibhuzmclfq: this query returns exactly
 * the ALLOWLIST, matching the advisor's rls_disabled_in_public = 1.
 *
 * 🔴 POSITIVE CONTROL (the project's rule: run one on any detector that reports
 * "nothing found"). A query typo that silently matched zero rows would report a
 * clean database while checking nothing. So the scan must still SEE every
 * ALLOWLIST member as a live RLS-off table; if it does not, the scan has gone
 * blind and the check ERRORS (exit 2) instead of passing. spatial_ref_sys is
 * permanently RLS-off and anon-readable here (ev-cto decision 0006), so it is a
 * reliable control that is always present.
 *
 * Live-DB check, so like check-spatial-ref-baseline it runs on the daily schedule
 * (and workflow_dispatch), NOT on push/PR — a commit here does not apply a
 * migration to prod, so a per-push run would only re-read unchanged prod state and
 * flag drift the push did not cause. It SKIPS itself green when DATABASE_URL is
 * absent (forks / manual runs with no secret).
 *
 * Exit 0 = only allowlisted tables are RLS-off (or skipped). Exit 1 = an
 * unallowlisted table is RLS-off and anon-readable. Exit 2 = error, incl. a blind
 * scan.
 *
 * Usage:
 *   node scripts/check-rls-coverage.mjs
 */
import 'dotenv/config';
import { Pool } from 'pg';

/**
 * Tables deliberately left RLS-off, each with a reason. A base table anon can read
 * with RLS off is a finding UNLESS it is here. Keep this list tiny; every entry is
 * a standing exception someone must be able to justify.
 */
const ALLOWLIST = new Map([
  ['public.spatial_ref_sys',
    'PostGIS EPSG reference table, owned by supabase_admin — EV\'s postgres role cannot ALTER it, ' +
    'so RLS cannot be enabled. Accepted by ev-cto decision 0006; tampering is watched separately by ' +
    'check-spatial-ref-baseline.mjs.'],
]);

// Supabase-internal / system schemas we do not own or govern.
const SYSTEM_SCHEMAS = [
  'pg_catalog', 'information_schema', 'pg_toast', 'extensions', 'graphql', 'graphql_public',
  'realtime', '_realtime', 'storage', 'vault', 'auth', 'supabase_functions', 'supabase_migrations',
  'cron', 'net', 'pgsodium', 'pgsodium_masks', '_analytics', 'pgbouncer',
];

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

(async () => {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    process.exit(0);
  }

  // The raw set: every base table anon/authenticated can SELECT with RLS off.
  const { rows } = await pool.query(
    `SELECT n.nspname AS schema, c.relname AS name,
            has_table_privilege('anon', c.oid, 'SELECT')          AS anon_select,
            has_table_privilege('authenticated', c.oid, 'SELECT') AS auth_select
       FROM pg_class c
       JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relkind = 'r'
        AND NOT c.relrowsecurity
        AND n.nspname <> ALL ($1::text[])
        AND (has_table_privilege('anon', c.oid, 'SELECT')
             OR has_table_privilege('authenticated', c.oid, 'SELECT'))
      ORDER BY 1, 2`,
    [SYSTEM_SCHEMAS],
  );

  const rawSet = new Set(rows.map((r) => `${r.schema}.${r.name}`));

  // ── Positive control: the scan must still see every allowlist member as a live
  // RLS-off table. If it sees none of them, it has gone blind — refuse to pass.
  const controlsSeen = [...ALLOWLIST.keys()].filter((t) => rawSet.has(t));
  if (controlsSeen.length === 0) {
    console.error(
      'FAIL (blind scan): the RLS-off scan matched none of its positive controls\n' +
      `  (${[...ALLOWLIST.keys()].join(', ')}).\n` +
      'These are permanently RLS-off and anon-readable, so an empty match means the query is\n' +
      'broken, not that the database is clean. Fix the scan before trusting a green result.',
    );
    await pool.end();
    process.exit(2);
  }

  const offenders = rows.filter((r) => !ALLOWLIST.has(`${r.schema}.${r.name}`));

  if (offenders.length === 0) {
    console.log(
      `RLS coverage OK — ${rawSet.size} anon-readable RLS-off table(s), all ${ALLOWLIST.size} allowlisted ` +
      `(control(s) seen: ${controlsSeen.join(', ')}). Matches rls_disabled_in_public floor.`,
    );
    await pool.end();
    process.exit(0);
  }

  const lines = offenders.map(
    (r) => `  ${r.schema}.${r.name}  (anon SELECT=${r.anon_select}, authenticated SELECT=${r.auth_select})`,
  );
  console.error(
    `FAIL: ${offenders.length} base table(s) are readable by anon/authenticated with row-level ` +
    `security OFF:\n${lines.join('\n')}\n\n` +
    'Each is internet-reachable through the schema-default SELECT grant. Fix by enabling default-deny ' +
    'RLS in a forward migration:\n' +
    '  ALTER TABLE <schema>.<table> ENABLE ROW LEVEL SECURITY;   -- RLS on, no policy\n' +
    '(add a permissive SELECT policy instead only if the table is public on purpose), mirroring ' +
    '1891_source_hubs_rls_default_deny.sql / CA_0186_fabricated_ca0156_removed_rls.sql. If a table ' +
    'is genuinely un-fixable like public.spatial_ref_sys, add it to ALLOWLIST with a reason.',
  );
  await pool.end();
  process.exit(1);
})().catch(async (err) => {
  console.error('FAIL: check-rls-coverage errored:', err.message);
  try { await pool.end(); } catch { /* already closed */ }
  process.exit(2);
});
