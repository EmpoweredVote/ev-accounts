/**
 * The incumbency reconciler.
 *
 * `politicians.is_incumbent` is a CACHED FLAG and nothing recomputes it. It defaulted to true
 * until CA_0188, which created 1,817 active "incumbents" holding no seat. The truth is
 * `essentials.office_current_holder`: a person is an incumbent exactly while they resolve as the
 * current holder of at least one office TODAY.
 *
 * 🔴 THE RECONCILER ALONE IS NOT ENOUGH, AND THE OBVIOUS CONTROL HIDES IT. `stagingService`'s
 * promotion used to force `is_incumbent = true` on every ON CONFLICT update, so a scheduled
 * reconciler would be undone by the next promotion — while a control that plants drift, runs the
 * reconciler and watches it get fixed would still pass, because it never exercises the writer
 * that reverts it. The last test here guards that writer by its SQL text, which is the only
 * thing a mocked test can see.
 */
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { findDrift } from './reconcile-incumbency.mjs';

const holder = (id: string) => ({ politician_id: id });

describe('findDrift', () => {
  it('flags a politician marked incumbent who holds no current seat', () => {
    const drift = findDrift({
      politicians: [{ id: 'p1', is_incumbent: true, office_id: null }],
      currentHolders: [],
      raceCandidates: [],
    });
    expect(drift).toEqual([
      { politicianId: 'p1', column: 'politicians.is_incumbent', current: true, expected: false },
    ]);
  });

  it('flags a current holder marked is_incumbent = false', () => {
    const drift = findDrift({
      politicians: [{ id: 'p2', is_incumbent: false, office_id: null }],
      currentHolders: [holder('p2')],
      raceCandidates: [],
    });
    expect(drift).toEqual([
      { politicianId: 'p2', column: 'politicians.is_incumbent', current: false, expected: true },
    ]);
  });

  it('returns nothing when every cached value agrees', () => {
    const drift = findDrift({
      politicians: [
        { id: 'p1', is_incumbent: true, office_id: 'o1' },
        { id: 'p2', is_incumbent: false, office_id: null },
      ],
      currentHolders: [holder('p1')],
      raceCandidates: [],
    });
    expect(drift).toEqual([]);
  });

  it('counts a person who holds two seats once, not twice', () => {
    // 27 active people hold two or more current seats. A politician-rooted read fans out.
    const drift = findDrift({
      politicians: [{ id: 'p3', is_incumbent: false, office_id: null }],
      currentHolders: [holder('p3'), holder('p3')],
      raceCandidates: [],
    });
    expect(drift).toHaveLength(1);
  });

  // 🔴 The next two pin rules this script used to have and MUST NOT get back. Both were applied
  // to a first measurement that reported 429 drift rows; reading real rows showed only 9 were
  // drift. CC_0342 has the full account.
  it('never reports race_candidates.is_incumbent — the column is seat-scoped and ambiguous', () => {
    // A state senator running for the U.S. House is correctly NOT the incumbent of that race.
    // The global rule called 297 rows drift; 234 of them were cross-office candidates stored
    // `true` and others of the same shape were stored `false`, so the data holds BOTH
    // conventions and nobody has ruled on which is meant.
    const drift = findDrift({
      politicians: [{ id: 'p4', is_incumbent: true }],
      currentHolders: [holder('p4')],
      raceCandidates: [{ id: 'rc1', politician_id: 'p4', is_incumbent: false }],
    });
    expect(drift).toEqual([]);
  });

  it('never reports politicians.office_id — it is a point-in-time snapshot, not a current fact', () => {
    // It was never supposed to equal the current holder; that is why the view replaced it.
    // Nulling the 101 rows the old rule caught would have destroyed values held nowhere else.
    const drift = findDrift({
      politicians: [{ id: 'p5', is_incumbent: false, office_id: 'o-stale' }],
      currentHolders: [],
      raceCandidates: [],
    });
    expect(drift).toEqual([]);
  });
});

describe('the truth predicate must exclude candidate placeholder offices', () => {
  // 🔴 A TEXT GUARD on this module's own SQL. Without the clause, 22 Senate CANDIDATES holding
  // only a 'Candidate for U.S. Senate — X' office (migration 196) are reported as missing
  // incumbents, and applying that publishes Roy Cooper and Sherrod Brown as sitting senators.
  const src = readFileSync(new URL('./reconcile-incumbency.mjs', import.meta.url), 'utf8');

  it("filters 'Candidate for%' out of the current-holder set", () => {
    expect(src).toMatch(/NOT ILIKE 'Candidate for%'/);
  });

  it('reads the holder set from office_current_holder joined to offices', () => {
    // Positive control on the assertion above: the clause only means anything if the query
    // actually joins offices, since the title lives there.
    expect(src).toMatch(/office_current_holder och[\s\S]{0,200}JOIN essentials\.offices o/);
  });
});

describe('the staging promotion must not force is_incumbent back on', () => {
  // 🔴 A TEXT GUARD, because a mocked test cannot see the SQL. Without this, piece 5 of the
  // transition programme is undone by the next staging promotion and nothing reports it.
  const src = readFileSync(new URL('../src/lib/stagingService.ts', import.meta.url), 'utf8');

  it('does not set is_incumbent in the ON CONFLICT update', () => {
    const conflictBlock = src.slice(src.indexOf('ON CONFLICT (external_id) DO UPDATE SET'));
    const setList = conflictBlock.slice(0, conflictBlock.indexOf('`'));
    expect(setList).not.toMatch(/is_incumbent\s*=\s*true/);
  });

  it('still sets is_active in that update, so the guard is reading the right block', () => {
    // A positive control on the assertion above: if this fails, the slice is wrong and the
    // first test is passing vacuously rather than because the line is gone.
    const conflictBlock = src.slice(src.indexOf('ON CONFLICT (external_id) DO UPDATE SET'));
    const setList = conflictBlock.slice(0, conflictBlock.indexOf('`'));
    expect(setList).toMatch(/is_active\s*=\s*true/);
  });
});
