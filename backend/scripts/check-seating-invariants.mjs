#!/usr/bin/env node
/**
 * Fail if the two seating invariants CC_0338 and CC_0341 depend on have drifted.
 *
 *   node scripts/check-seating-invariants.mjs [--verbose]
 *
 * Verdicts: scripts/lib/seating-invariants.mjs (pure, tested, each one watched failing)
 * Control:  scripts/control-seating-invariants.mjs (breaks prod's state inside a rolled-back
 *           transaction and asserts this check goes red)
 *
 * ── WHAT IT GUARDS, AND WHY IT IS A CHECK AND NOT A MIGRATION GATE ───────────────────────────
 *
 * 1. essentials.seat_officeholder is EXACTLY ONE function and still carries p_allow_reelection.
 *
 *    CC_0338 drops the old 7-argument form before recreating it with an eighth parameter.
 *    `DROP ... IF EXISTS` with a signature that does not match fails SILENTLY, and
 *    `CREATE OR REPLACE` then leaves an OVERLOAD beside the original — at which point every
 *    existing 4-argument call site fails "function is not unique", all of them, at runtime.
 *    The migration's header calls that drop load-bearing and then does not check it.
 *    The other half: if something restores a pre-CC_0338 definition, seating a RE-ELECTED
 *    INCUMBENT silently writes nothing again, and that is 81% of the federal tier.
 *
 * 2. essentials.office_next_term agrees with essentials.office_terms.
 *
 *    CC_0341 has a gate whose two assertions are tautologies of the view's own definition:
 *    a `DISTINCT ON (office_id)` view cannot return two rows per office, and a view filtered on
 *    `term_start > CURRENT_DATE` cannot hold a past row. Neither can ever fire. This compares
 *    the view against the BASE TABLE instead: every office with a pending, occupied term must
 *    appear, exactly once, showing its EARLIEST pending date.
 *
 * 🔴 NEITHER MIGRATION CAN BE AMENDED TO CARRY THIS. Both are applied, migrations here run once
 * by hand and are never replayed, so editing an applied file desyncs it from what ran and the
 * new gate would execute nowhere. A daily check is also strictly stronger: the drift that
 * matters here happens AFTER the migration, because terms start and end on their own dates with
 * no commit involved.
 *
 * ── FAILURE BEHAVIOUR ────────────────────────────────────────────────────────────────────────
 *
 * 🔴 NO DATABASE_URL -> SKIP, exit 0, and SAY SO. Forks get no secrets, and a red wall on every
 *    outside PR is worse than the drift. A check that skips without printing why is the shape of
 *    a detector that has quietly stopped working.
 */
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import pg from 'pg';
import dotenv from 'dotenv';
import { seatHelperVerdict, nextTermVerdict } from './lib/seating-invariants.mjs';

dotenv.config({ path: path.join(path.dirname(fileURLToPath(import.meta.url)), '..', '.env') });
dotenv.config();

const SEAT_HELPER_SQL = `
  SELECT pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'essentials' AND p.proname = 'seat_officeholder'
   ORDER BY 1`;

// The base table, summarised the way the view claims to summarise it.
const EXPECTED_SQL = `
  SELECT t.office_id, min(t.term_start)::text AS term_start
    FROM essentials.office_terms t
   WHERE t.term_start > CURRENT_DATE AND t.politician_id IS NOT NULL
   GROUP BY t.office_id`;

const ACTUAL_SQL = `
  SELECT office_id, term_start::text AS term_start FROM essentials.office_next_term`;

/** Run both verdicts against an open client. Exported so the control can drive it. */
export async function runChecks(client) {
  const [helper, expected, actual] = await Promise.all([
    client.query(SEAT_HELPER_SQL),
    client.query(EXPECTED_SQL),
    client.query(ACTUAL_SQL),
  ]);
  return [
    seatHelperVerdict(helper.rows),
    nextTermVerdict({ expected: expected.rows, actual: actual.rows }),
  ];
}

// 🔴 RESOLVED URLS, NOT A FILENAME SUFFIX. A suffix is not an identity: the sibling script was
// importable only by files whose name did not happen to end with its own, which is not a
// property anyone can rely on. `control-seating-invariants.mjs` ends with this file's name.
const invokedDirectly = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;

if (invokedDirectly) {
  if (!process.env.DATABASE_URL) {
    console.log(
      'SKIPPED: DATABASE_URL is not set, so the seating invariants could not be checked against ' +
        'the live schema. Forks get no secrets; this is a deliberate green skip, not a pass.',
    );
    process.exit(0);
  }

  const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
  let failed = false;
  try {
    await client.connect();
    for (const v of await runChecks(client)) {
      console.log(`${v.ok ? 'OK  ' : 'FAIL'}  ${v.message}`);
      if (!v.ok) failed = true;
    }
  } finally {
    await client.end();
  }

  if (failed) {
    console.error(
      '\nSeating invariant drift. Neither of these can be fixed by re-running a migration: ' +
        'CC_0338 and CC_0341 are already applied. Work out what changed the schema first.',
    );
    process.exit(1);
  }
  console.log('\nSeating invariants hold.');
}
