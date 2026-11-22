/**
 * The pure half of the seating-wave derivation: the selection digest a wave's P1 pre-check
 * refuses to proceed without, and the classification that names what is blocking a body.
 *
 * 🔴 THE DIGEST EXISTS TO PIN A SELECTION THAT THE MIGRATION DERIVES RATHER THAN TRANSCRIBES.
 * CC_0453 says why: a literal list in the file would agree with itself however wrong it was, so
 * the rows are selected by query — and the risk that creates is the opposite one, the data moving
 * under the file between writing and applying. The digest is what stops that silently.
 *
 * So this function has exactly one job: produce, in JS, the string Postgres produces for the same
 * rows. Every test below is a way the two can disagree, and each one was reachable:
 *
 *   · 71 state offices carry MORE THAN ONE WINNER, so office_id alone is not a unique sort key
 *     and string_agg's order among ties is unspecified — the same rows could digest two ways.
 *   · 211 winner rows have NO politician record, and in Postgres `a || NULL || b` is NULL while
 *     string_agg SKIPS a NULL element. A bare render disagrees exactly when that happens.
 *   · A boolean is 'true'/'false' in Postgres, never 1/0.
 *
 * Pure: no database. The JS-against-SQL agreement is a control run against production, not a
 * test — a test cannot prove two engines agree.
 */
import { describe, it, expect } from 'vitest';
import { createHash } from 'node:crypto';
import { selectionDigest, classifyWave } from './seating-wave.mjs';

const md5 = (s: string) => createHash('md5').update(s).digest('hex');

/** A winner row as WAVE_SELECTION_SQL returns it, with everything unremarkable. */
function row(over: Record<string, unknown> = {}) {
  return {
    office_id: '0561b24d-9c8a-40b1-81a9-8b676e0d56fa',
    politician_id: '72dd5219-490f-48bb-986e-183a6098d602',
    is_reelection: false,
    winner_count: 1,
    swearing_in_date: '2027-01-04',
    basis: 'statute',
    next_term_start: null,
    is_vacant: false,
    certainty: 'called',
    label: 'State House District 1',
    ...over,
  };
}

describe('selectionDigest', () => {
  it('renders the re-election flag the way Postgres renders a boolean', () => {
    expect(selectionDigest([{ office_id: 'a', politician_id: 'p', is_reelection: true }])).toBe(
      md5('a:p:true'),
    );
    expect(selectionDigest([{ office_id: 'a', politician_id: 'p', is_reelection: false }])).toBe(
      md5('a:p:false'),
    );
  });

  it('separates rows with a pipe and fields within a row with a colon', () => {
    const digest = selectionDigest([
      { office_id: 'a', politician_id: 'p', is_reelection: false },
      { office_id: 'b', politician_id: 'q', is_reelection: true },
    ]);
    expect(digest).toBe(md5('a:p:false|b:q:true'));
  });

  // 🔴 CC_0453 sorted on office_id alone because its P3 guaranteed one winner per office. 71
  // state offices carry two or three, so office_id ties — and string_agg's order among tied sort
  // keys is unspecified. Without the second key the same selection can digest two different ways
  // on two runs, and P1 would report "the data moved under this file" when nothing had.
  it('is stable for a multi-winner office, whichever order its rows arrive in', () => {
    const forwards = [
      { office_id: 'a', politician_id: 'q', is_reelection: false },
      { office_id: 'a', politician_id: 'p', is_reelection: true },
    ];
    const backwards = [forwards[1], forwards[0]];
    expect(selectionDigest(forwards)).toBe(selectionDigest(backwards));
    expect(selectionDigest(forwards)).toBe(md5('a:p:true|a:q:false'));
  });

  // 🔴 In Postgres, concatenating NULL yields NULL and string_agg SKIPS that element entirely —
  // so a bare render of a missing winner produces a string Postgres would never produce, exactly
  // on the 211 rows where it matters. COALESCE to '-' is CC_0453's own idiom (holders_md5).
  it('renders a winner with no politician record as a dash, not as null', () => {
    const digest = selectionDigest([{ office_id: 'a', politician_id: null, is_reelection: false }]);
    expect(digest).toBe(md5('a:-:false'));
    expect(digest).not.toBe(md5('a:null:false'));
    expect(digest).not.toBe(md5('a:undefined:false'));
  });

  it('sorts a missing winner after a present one on the same office', () => {
    expect(
      selectionDigest([
        { office_id: 'a', politician_id: null, is_reelection: false },
        { office_id: 'a', politician_id: 'p', is_reelection: false },
      ]),
    ).toBe(md5('a:p:false|a:-:false'));
  });

  // The tamper. If this passes, the digest is not reading the flag and P1 cannot tell a
  // re-election from a handover — which is the one thing p_allow_reelection depends on.
  it('changes when one row\'s re-election flag changes', () => {
    const before = selectionDigest([{ office_id: 'a', politician_id: 'p', is_reelection: false }]);
    const after = selectionDigest([{ office_id: 'a', politician_id: 'p', is_reelection: true }]);
    expect(after).not.toBe(before);
  });
});

describe('classifyWave counts', () => {
  it('splits the rows into re-elections and new holders, and they sum to the total', () => {
    const got = classifyWave([
      row({ is_reelection: true }),
      row({ office_id: 'b', is_reelection: false }),
      row({ office_id: 'c', is_reelection: false }),
    ]);
    expect(got.rows).toBe(3);
    expect(got.reelections).toBe(1);
    expect(got.newHolders).toBe(2);
    expect(got.reelections + got.newHolders).toBe(got.rows);
  });

  it('reports the term start when every row agrees on it', () => {
    expect(classifyWave([row(), row({ office_id: 'b' })]).termStart).toBe('2027-01-04');
  });

  // Ruling B: a wave records how exposed it was to a reversed canvass, so the split is counted
  // here rather than eyeballed per migration.
  it('counts the called and certified rows separately', () => {
    const got = classifyWave([row(), row({ office_id: 'b', certainty: 'certified' })]);
    expect(got.called).toBe(1);
    expect(got.certified).toBe(1);
  });
});

describe('classifyWave blockers', () => {
  const kinds = (rows: ReturnType<typeof row>[]) => classifyWave(rows).blockers.map((b) => b.kind);

  it('finds nothing wrong with a clean wave', () => {
    expect(classifyWave([row(), row({ office_id: 'b' })]).blockers).toEqual([]);
  });

  it('flags an office carrying more than one winner', () => {
    expect(kinds([row({ winner_count: 2 })])).toContain('multi_winner');
  });

  it('flags a winner with no politician record', () => {
    expect(kinds([row({ politician_id: null })])).toContain('winner_no_record');
  });

  it('flags an office with no swearing-in date', () => {
    expect(kinds([row({ swearing_in_date: null })])).toContain('no_date');
  });

  // 🔴 The table's CHECK permits basis = 'estimated'. This plan does not let one seat anybody:
  // an estimated date is a guess, and a term start is a legal fact.
  it('flags an estimated date', () => {
    expect(kinds([row({ basis: 'estimated' })])).toContain('date_estimated');
  });

  it('flags an office already carrying a future term', () => {
    expect(kinds([row({ next_term_start: '2027-01-04' })])).toContain('already_scheduled');
  });

  it('flags an office flagged vacant', () => {
    expect(kinds([row({ is_vacant: true })])).toContain('flagged_vacant');
  });

  // Two dates in one wave is not a wave. It is two bodies that were asked for together, and a
  // migration pinned to one date would silently seat half its rows at the wrong one.
  it('flags disagreeing dates and refuses to name a term start', () => {
    const got = classifyWave([row(), row({ office_id: 'b', swearing_in_date: '2027-01-11' })]);
    expect(got.blockers.map((b) => b.kind)).toContain('date_disagrees');
    expect(got.termStart).toBeNull();
  });

  // 🔴 This script REPORTS. A migration refuses; a report that refused would hide the other
  // blockers behind the first one, which is how a body gets fixed one round trip at a time.
  it('still returns its counts when a wave is blocked', () => {
    const got = classifyWave([row({ politician_id: null, is_vacant: true })]);
    expect(got.rows).toBe(1);
    expect(got.blockers.length).toBe(2);
  });

  it('names the office on every blocker it reports', () => {
    const got = classifyWave([row({ office_id: 'b', winner_count: 2 })]);
    expect(got.blockers[0].office_id).toBe('b');
    expect(got.blockers[0].detail).toBeTruthy();
  });
});
