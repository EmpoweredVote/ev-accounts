/**
 * Verdicts for the two seating invariants that CC_0338 and CC_0341 should have gated and did
 * not. Both migrations are already applied, and amending an applied file desyncs it from what
 * actually ran — so the gate lives here, where it also catches drift neither migration could
 * see, because it runs every day rather than once.
 *
 * Pure: no database, so every verdict is testable and each one is watched failing below.
 */
import { describe, it, expect } from 'vitest';
import { seatHelperVerdict, nextTermVerdict } from './seating-invariants.mjs';

const GOOD_ARGS =
  'p_office_id uuid, p_politician_id uuid, p_term_start date, p_source text, ' +
  'p_how_started text, p_start_precision text, p_how_ended_prev text, p_allow_reelection boolean';

describe('seatHelperVerdict', () => {
  it('passes with exactly one function carrying p_allow_reelection', () => {
    expect(seatHelperVerdict([{ args: GOOD_ARGS }])).toMatchObject({ ok: true });
  });

  it('FAILS when the drop did not match and an overload survives', () => {
    // 🔴 This is the failure CC_0338's header calls load-bearing. `DROP ... IF EXISTS` with a
    // signature that does not match fails SILENTLY, `CREATE OR REPLACE` then adds a second
    // function, and every existing 4-argument call site breaks with "is not unique" — all of
    // them at once, at runtime, with nothing in the migration output to say so.
    const v = seatHelperVerdict([
      { args: 'p_office_id uuid, p_politician_id uuid, p_term_start date, p_source text, p_how_started text, p_start_precision text, p_how_ended_prev text' },
      { args: GOOD_ARGS },
    ]);
    expect(v.ok).toBe(false);
    expect(v.message).toMatch(/2 /);
    expect(v.message).toMatch(/not unique|overload/i);
  });

  it('FAILS when the re-election parameter has gone', () => {
    // A later CREATE OR REPLACE that dropped the parameter restores the SILENT NO-OP: seating a
    // re-elected incumbent would write nothing again, and that is 81% of the federal tier.
    const v = seatHelperVerdict([
      { args: 'p_office_id uuid, p_politician_id uuid, p_term_start date, p_source text, p_how_started text, p_start_precision text, p_how_ended_prev text' },
    ]);
    expect(v.ok).toBe(false);
    expect(v.message).toMatch(/p_allow_reelection/);
  });

  it('FAILS when the function is missing entirely', () => {
    expect(seatHelperVerdict([])).toMatchObject({ ok: false });
  });
});

describe('nextTermVerdict', () => {
  // 🔴 CC_0341's own gate asserted that a view defined DISTINCT ON (office_id) returns one row
  // per office, and that a view filtered on `term_start > CURRENT_DATE` holds no past rows.
  // Both are tautologies of the view's definition and can never fire. A gate with teeth
  // compares the view against the BASE TABLE, which is what these do.
  it('passes when the view shows every office that has a future term, at its earliest date', () => {
    expect(nextTermVerdict({
      expected: [{ office_id: 'o1', term_start: '2027-01-03' }],
      actual: [{ office_id: 'o1', term_start: '2027-01-03' }],
    })).toMatchObject({ ok: true });
  });

  it('FAILS when an office with a future term is missing from the view', () => {
    // The real consequence: a seat changes hands and no read path can say so, which is the
    // whole defect piece 8 exists to prevent.
    const v = nextTermVerdict({
      expected: [{ office_id: 'o1', term_start: '2027-01-03' }],
      actual: [],
    });
    expect(v.ok).toBe(false);
    expect(v.message).toMatch(/missing/i);
  });

  it('FAILS when the view shows a later term than the earliest one pending', () => {
    // An office can carry a successor AND a successor's successor. Showing the wrong one tells
    // a voter the handover is further away than it is.
    const v = nextTermVerdict({
      expected: [{ office_id: 'o1', term_start: '2027-01-03' }],
      actual: [{ office_id: 'o1', term_start: '2029-01-03' }],
    });
    expect(v.ok).toBe(false);
    expect(v.message).toMatch(/2027-01-03/);
  });

  it('FAILS when the view shows an office that has no pending term at all', () => {
    const v = nextTermVerdict({
      expected: [],
      actual: [{ office_id: 'ghost', term_start: '2027-01-03' }],
    });
    expect(v.ok).toBe(false);
    expect(v.message).toMatch(/ghost|unexpected/i);
  });

  it('passes on an empty database rather than claiming success it cannot have', () => {
    const v = nextTermVerdict({ expected: [], actual: [] });
    expect(v.ok).toBe(true);
    // ⚠ A uniform answer is a broken detector until a control passes, so the verdict must SAY
    // it compared nothing instead of printing a bare OK.
    expect(v.message).toMatch(/0 office/);
  });
});
