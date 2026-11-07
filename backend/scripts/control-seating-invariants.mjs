/**
 * Control for check-seating-invariants.mjs.
 *
 * It drives the REAL `runChecks` — the same SQL constants, the same verdict functions, the same
 * wiring the CI job runs — through a stub client that returns the row shapes a broken schema
 * would produce. What it proves is that a FAIL in the verdict layer actually reaches the exit
 * code, which the unit tests on their own cannot say.
 *
 * ── THE DDL TAMPERS, AND WHY THEY ARE NOT IN THIS FILE ───────────────────────────────────────
 *
 * Both invariants can only be falsified by a SCHEMA change: the view is derived from the table,
 * so no amount of data movement can make them disagree. Breaking them needs CREATE/REPLACE,
 * which `ev_api` cannot do (it is not the owner), so this script cannot perform them.
 *
 * They were performed against production on 2026-11-04 through the privileged connection, each
 * inside `BEGIN ... ROLLBACK`, and each was confirmed to produce exactly the input this control
 * replays:
 *
 *   TAMPER 1 — recreate the pre-CC_0338 7-argument function beside the current one, which is
 *   what a non-matching DROP leaves behind. The check's own SQL returned TWO rows:
 *     (… p_how_ended_prev text)
 *     (… p_how_ended_prev text, p_allow_reelection boolean)
 *   → seatHelperVerdict: "2 essentials.seat_officeholder functions exist …"
 *
 *   TAMPER 2 — redefine essentials.office_next_term with `AND false`, so it silently stops
 *   covering a pending handover. Base table said 1 office pending, the view returned 0.
 *   → nextTermVerdict: "1 office(s) have a pending term but are MISSING …"
 *
 * Re-running the check against production after both rollbacks returned OK on both lines, so
 * the tampers were real and were reverted. ▶ Repeat them the same way if this check is ever
 * changed; a verdict nobody has watched fail is not a gate.
 */
import { runChecks } from './check-seating-invariants.mjs';
import { seatHelperVerdict, nextTermVerdict } from './lib/seating-invariants.mjs';

const GOOD_HELPER = {
  args: 'p_office_id uuid, p_politician_id uuid, p_term_start date, p_source text, ' +
        'p_how_started text, p_start_precision text, p_how_ended_prev text, p_allow_reelection boolean',
};
const OLD_HELPER = {
  args: 'p_office_id uuid, p_politician_id uuid, p_term_start date, p_source text, ' +
        'p_how_started text, p_start_precision text, p_how_ended_prev text',
};

/** A client that answers each of runChecks' three queries from a fixture. */
const stub = ({ helper, expected, actual }) => ({
  query: (sql) => {
    if (sql.includes('pg_proc')) return Promise.resolve({ rows: helper });
    if (sql.includes('office_next_term')) return Promise.resolve({ rows: actual });
    return Promise.resolve({ rows: expected });
  },
});

const PENDING = [{ office_id: 'office-a', term_start: '2027-01-05' }];

const CASES = [
  {
    name: 'healthy schema passes',
    fixture: { helper: [GOOD_HELPER], expected: PENDING, actual: PENDING },
    expectFail: false,
  },
  {
    name: 'TAMPER 1 — a surviving overload is caught',
    fixture: { helper: [OLD_HELPER, GOOD_HELPER], expected: PENDING, actual: PENDING },
    expectFail: true,
  },
  {
    name: 'TAMPER 1b — a pre-CC_0338 definition restores the silent no-op',
    fixture: { helper: [OLD_HELPER], expected: PENDING, actual: PENDING },
    expectFail: true,
  },
  {
    name: 'TAMPER 2 — the view stops covering a pending handover',
    fixture: { helper: [GOOD_HELPER], expected: PENDING, actual: [] },
    expectFail: true,
  },
  {
    name: 'TAMPER 2b — the view shows a later handover than the earliest pending one',
    fixture: {
      helper: [GOOD_HELPER], expected: PENDING,
      actual: [{ office_id: 'office-a', term_start: '2031-01-05' }],
    },
    expectFail: true,
  },
];

let failed = false;
for (const c of CASES) {
  const verdicts = await runChecks(stub(c.fixture));
  const red = verdicts.some((v) => !v.ok);
  if (red !== c.expectFail) {
    console.error(`  ✗ ${c.name}: expected ${c.expectFail ? 'FAIL' : 'PASS'}, got ${red ? 'FAIL' : 'PASS'}`);
    failed = true;
  } else {
    const why = verdicts.find((v) => !v.ok)?.message ?? verdicts.map((v) => v.message).join(' · ');
    console.log(`  ✓ ${c.name}\n      ${why}`);
  }
}

// A control that only ever passes proves nothing, so assert the fixtures really do differ.
if (seatHelperVerdict([GOOD_HELPER]).ok === seatHelperVerdict([OLD_HELPER, GOOD_HELPER]).ok) {
  console.error('  ✗ the two helper fixtures produce the same verdict — this control tests nothing');
  failed = true;
}
if (nextTermVerdict({ expected: PENDING, actual: PENDING }).ok === nextTermVerdict({ expected: PENDING, actual: [] }).ok) {
  console.error('  ✗ the two view fixtures produce the same verdict — this control tests nothing');
  failed = true;
}

console.log(failed ? '\nCONTROL FAILED' : '\nCONTROL PASSED — every tamper reaches a FAIL verdict');
process.exit(failed ? 1 : 0);
