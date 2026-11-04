/**
 * Verdicts for two seating invariants, kept pure so each one can be watched failing.
 *
 * WHY THESE LIVE IN CI RATHER THAN IN THE MIGRATIONS THAT NEEDED THEM.
 *
 *   CC_0338 ends without a `DO $$ ... $$` gate at all, and its own header explains that the
 *   `DROP FUNCTION IF EXISTS ... (7 args)` is load-bearing: a signature that does not match
 *   fails SILENTLY, `CREATE OR REPLACE` then leaves an OVERLOAD beside the old function, and
 *   every existing 4-argument call site fails "is not unique" at runtime.
 *
 *   CC_0341 has a gate, but both of its assertions are tautologies of the view definition —
 *   "a DISTINCT ON (office_id) view returns one row per office" and "a view filtered on
 *   term_start > CURRENT_DATE holds no past rows". Neither can ever fire. By this repo's own
 *   standard a gate that cannot be watched failing is not a gate.
 *
 * 🔴 AND NEITHER MIGRATION CAN BE AMENDED. Both are applied. Migrations here run once, by hand,
 * and are never replayed, so editing an applied file desyncs it from what actually ran and the
 * edit would never execute anywhere. A daily check is also strictly stronger than a one-shot
 * gate: it catches drift that happens AFTER the migration, which is the only kind that can
 * happen here — terms start and end on their own dates, with no commit involved.
 */

/** The argument list CC_0338 left behind. */
const REELECTION_PARAM = 'p_allow_reelection';

/**
 * @param {{args: string}[]} rows one per `essentials.seat_officeholder` in pg_proc
 */
export function seatHelperVerdict(rows) {
  if (rows.length === 0) {
    return { ok: false, message: 'essentials.seat_officeholder does not exist. Every seeding and seating path is broken.' };
  }

  if (rows.length > 1) {
    return {
      ok: false,
      message:
        `${rows.length} essentials.seat_officeholder functions exist, so every 4-argument call ` +
        `site fails "function is not unique". CC_0338's DROP did not match an overload. ` +
        `Signatures: ${rows.map((r) => `(${r.args})`).join(' | ')}`,
    };
  }

  if (!rows[0].args.includes(REELECTION_PARAM)) {
    return {
      ok: false,
      message:
        `essentials.seat_officeholder has no ${REELECTION_PARAM} parameter, so seating a ` +
        `re-elected incumbent is a SILENT NO-OP again — 1,088 of 2,078 races (81% of federal). ` +
        `Something replaced the function with a pre-CC_0338 definition. Got: (${rows[0].args})`,
    };
  }

  return { ok: true, message: `essentials.seat_officeholder: 1 function, carries ${REELECTION_PARAM}` };
}

/**
 * Compare `essentials.office_next_term` against the base table it summarises.
 *
 * @param {{expected: {office_id: string, term_start: string}[], actual: {office_id: string, term_start: string}[]}} sets
 */
export function nextTermVerdict({ expected, actual }) {
  const want = new Map(expected.map((r) => [r.office_id, String(r.term_start).slice(0, 10)]));
  const got = new Map(actual.map((r) => [r.office_id, String(r.term_start).slice(0, 10)]));

  const missing = [...want.keys()].filter((id) => !got.has(id));
  if (missing.length) {
    return {
      ok: false,
      message:
        `${missing.length} office(s) have a pending term but are MISSING from ` +
        `essentials.office_next_term, so no read path can say the seat is changing hands: ` +
        `${missing.slice(0, 5).join(', ')}`,
    };
  }

  const unexpected = [...got.keys()].filter((id) => !want.has(id));
  if (unexpected.length) {
    return {
      ok: false,
      message:
        `${unexpected.length} office(s) appear in essentials.office_next_term with no pending ` +
        `term behind them: ${unexpected.slice(0, 5).join(', ')}`,
    };
  }

  const wrong = [...want.entries()].filter(([id, date]) => got.get(id) !== date);
  if (wrong.length) {
    const [id, date] = wrong[0];
    return {
      ok: false,
      message:
        `${wrong.length} office(s) show the wrong handover date. Office ${id} should show ` +
        `${date} (its earliest pending term) but shows ${got.get(id)}.`,
    };
  }

  // ⚠ Say what was compared. A bare OK over an empty set is the shape of a detector that has
  // quietly stopped reading anything.
  return { ok: true, message: `essentials.office_next_term agrees with office_terms on ${want.size} office(s) with a pending handover` };
}
