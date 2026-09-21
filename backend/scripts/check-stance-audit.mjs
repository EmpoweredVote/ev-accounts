#!/usr/bin/env node
/**
 * check-stance-audit — the guard for ADR 0007 §5.
 *
 * 🔴 WHY THIS EXISTS. The stance-read audit is one line of configuration
 * (CC_0116: `ALTER ROLE postgres SET log_statement = 'all'`). A setting nobody
 * checks is not a control — it can be reset by anyone who can set it, and a
 * platform maintenance event resetting rolconfig would be silent. The floor in
 * ADR 0007 §4 is only as good as this staying true.
 *
 * Design: docs/superpowers/specs/2026-09-15-stance-read-audit-design.md (Stage 4).
 * Built alongside Stage 1 deliberately: the spec argues the guard must not lag the
 * mechanism, because the failure it catches is the mechanism silently going away.
 *
 * THREE ASSERTIONS
 *
 *  1. `postgres` still has log_statement=all. This is the audit itself.
 *
 *  2. `cli_login_postgres` is still expired (or gone). It is a member of `postgres`
 *     and would inherit read access, but rolconfig does NOT inherit — so a renewed
 *     cli_login_postgres is an unlogged path to every stance. Its password expired
 *     2026-08-17. Renewal must be a deliberate, visible act, not a quiet one.
 *
 *  3. The set of roles with effective SELECT on inform.compass_responses has not
 *     changed. `has_table_privilege` is used rather than a grants query ON PURPOSE:
 *     an earlier version of this design checked information_schema.role_table_grants
 *     alone and would have reported a clean result while supabase_read_only_user and
 *     supabase_etl_admin read every stance through pg_read_all_data. Direct grants
 *     are not the access path; effective privilege is.
 *
 * ON THE BASELINE. Three of the nine are Supabase's own platform roles, and their
 * access is NOT auditable from inside this database (ADR 0007 §5 scopes the floor to
 * EV's conduct for exactly this reason). They are in the baseline because they are
 * present and expected — not because they are covered.
 *
 * If this fails, do NOT just update the constant. A new reader of the stance table
 * is the thing the floor exists to notice.
 *
 * Live-DB check, so it runs on the daily schedule (and workflow_dispatch), NOT on
 * push/PR — a commit of ours cannot change role configuration — and it SKIPS itself
 * green when DATABASE_URL is absent (forks / manual runs with no secret).
 *
 * Exit 0 = all three hold (or skipped). Exit 1 = an assertion failed. Exit 2 = error.
 *
 * Usage:
 *   node scripts/check-stance-audit.mjs
 */
import 'dotenv/config';
import { Pool } from 'pg';

/** The role the audit logs. See CC_0116 for why this one and only this one. */
const AUDITED_ROLE = 'postgres';

/**
 * Every role holding effective SELECT on inform.compass_responses, confirmed live
 * against production `kxsdzaojfaibhuzmclfq` on 2026-09-17.
 *
 * Bump this ONLY for a deliberate, reviewed grant, in the same PR that causes it,
 * and say so in the message. Anything else appearing here is an incident.
 */
const EXPECTED_READERS = [
  'anon',                    // RLS-constrained; owner-only policy applies
  'authenticated',           // RLS-constrained; owner-only policy applies
  'ev_api',                  // the application
  'pg_read_all_data',        // the group, not a login role
  'postgres',                // human/dashboard — logged by CC_0116
  'service_role',            // the application, assumed via SET ROLE from authenticator
  'supabase_admin',          // Supabase's; not auditable by us
  'supabase_etl_admin',      // Supabase's; not auditable by us
  'supabase_read_only_user', // Supabase's; not auditable by us
];

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const fail = [];

(async () => {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    process.exit(0);
  }

  // 1 — the audit is on.
  const { rows: cfg } = await pool.query(
    `SELECT COALESCE(rolconfig, '{}') AS rolconfig
       FROM pg_roles WHERE rolname = $1`,
    [AUDITED_ROLE],
  );
  if (!cfg.length) {
    fail.push(`Role ${AUDITED_ROLE} does not exist. The audit cannot be on.`);
  } else if (!cfg[0].rolconfig.includes('log_statement=all')) {
    fail.push(
      `${AUDITED_ROLE} has lost log_statement=all (rolconfig = ${cfg[0].rolconfig.join(', ') || '(none)'}).\n` +
      '  The stance-read audit is OFF. Re-apply CC_0116:\n' +
      "    ALTER ROLE postgres SET log_statement = 'all';\n" +
      '  If a platform event reset it, say so in the PR — that is a known-unverified risk\n' +
      '  the spec records, and this check existing is how we would find out.',
    );
  }

  // 2 — the inherited path stays shut.
  const { rows: cli } = await pool.query(
    `SELECT rolvaliduntil, (rolvaliduntil IS NOT NULL AND rolvaliduntil < now()) AS expired
       FROM pg_roles WHERE rolname = 'cli_login_postgres'`,
  );
  if (cli.length && !cli[0].expired) {
    fail.push(
      'cli_login_postgres can authenticate again ' +
      `(rolvaliduntil = ${cli[0].rolvaliduntil ?? 'never'}).\n` +
      '  It is a member of postgres, so it reaches every stance — but rolconfig does NOT\n' +
      '  inherit, so it is NOT covered by CC_0116. Either expire it again, or give it its\n' +
      "  own ALTER ROLE ... SET log_statement = 'all' and update this check in the same PR.",
    );
  }

  // 3 — no new reader of the stance table.
  const { rows: readers } = await pool.query(
    `SELECT rolname FROM pg_roles
      WHERE has_table_privilege(rolname, 'inform.compass_responses', 'SELECT')
      ORDER BY rolname`,
  );
  const actual = readers.map((r) => r.rolname);
  const added = actual.filter((r) => !EXPECTED_READERS.includes(r));
  const removed = EXPECTED_READERS.filter((r) => !actual.includes(r));

  if (added.length) {
    fail.push(
      `New role(s) can read inform.compass_responses: ${added.join(', ')}.\n` +
      '  This is ADR 0007 §4 territory. Do NOT just add them to EXPECTED_READERS —\n' +
      '  establish why the grant exists, whether the read path carries the visibility\n' +
      '  filter, and whether the role is loggable, before deciding it is expected.',
    );
  }
  if (removed.length) {
    fail.push(
      `Expected reader(s) gone: ${removed.join(', ')}.\n` +
      '  Not a privacy regression, but the baseline is stale — update EXPECTED_READERS\n' +
      '  in the PR that removed them.',
    );
  }

  await pool.end();

  if (fail.length) {
    console.error(`FAIL: stance-read audit guard — ${fail.length} assertion(s) failed.\n`);
    for (const f of fail) console.error(`· ${f}\n`);
    process.exit(1);
  }

  console.log(
    `stance-read audit — ${AUDITED_ROLE} logs statements; cli_login_postgres cannot ` +
    `authenticate; ${actual.length} roles can read inform.compass_responses, as expected. ` +
    'ADR 0007 §5 holds.',
  );
  process.exit(0);
})().catch(async (err) => {
  console.error(`ERROR: stance-read audit guard could not run — ${err.message}`);
  try { await pool.end(); } catch { /* already closed */ }
  process.exit(2);
});
