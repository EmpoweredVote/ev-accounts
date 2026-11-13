/**
 * The transition tracker's seat-state ladder, as tests.
 *
 * Every race in the 2026-11-03 general sits at exactly one of five states, and the tracker's
 * whole value is that a seat cannot be quietly skipped. Two of these cases exist because the
 * obvious implementation gets them wrong:
 *
 *  - an UNDECIDED race must read as state 1, not throw and not read as "done". On the day
 *    after an election most races are undecided, and recounts run for weeks.
 *  - state 4 vs state 5 is decided by comparing the winner's term start to TODAY, never by a
 *    stored flag. The whole transition model turns on the calendar doing the work, so the
 *    ladder has to read the calendar too.
 */
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import {
  seatState, levelOf, isStillStanding, sqlNotStandingList, STATE_KEY, STATE_LABEL,
} from './election-transition-status.mjs';

describe('the state labels', () => {
  // 🔴 THIS IS A CORRECTNESS TEST, NOT A STYLE ONE. seatState() compares a term start to the
  // calendar. It cannot observe an oath, so no state it returns may claim one. State 5 read
  // "Sworn in" until 2026-11-12, when it called Indiana House 62 sworn in eight days after the
  // term began under Ind. Const. art. 4 §3 and well before Organization Day, where the oath is
  // actually taken. The repo's cited oath dates live in essentials.office_swearing_in, which
  // held no row for that seat at the time.
  it('never claims an oath, in any state', () => {
    for (const [state, label] of Object.entries(STATE_LABEL)) {
      expect(label, `state ${state}`).not.toMatch(/sworn|swearing|oath|inaugurat/i);
    }
    for (const [state, key] of Object.entries(STATE_KEY)) {
      expect(key, `state ${state}`).not.toMatch(/sworn|swearing|oath|inaugurat/i);
    }
  });

  // The control: the matcher above must be able to fail. A pattern that matches nothing passes
  // every label, including the one this test exists to reject.
  it('would reject the label it replaced', () => {
    expect(() => expect('Sworn in').not.toMatch(/sworn|swearing|oath|inaugurat/i)).toThrow();
  });

  it('labels and counter keys cover exactly the five states seatState can return', () => {
    expect(Object.keys(STATE_LABEL)).toEqual(['1', '2', '3', '4', '5']);
    expect(Object.keys(STATE_KEY)).toEqual(['1', '2', '3', '4', '5']);
  });
});

describe('seatState', () => {
  it('returns 1 when no result is recorded', () => {
    expect(seatState({ result: null })).toBe(1);
  });

  it('returns 2 for a called win', () => {
    expect(seatState({ result: 'won', resultCertainty: 'called' })).toBe(2);
  });

  it('returns 3 for a certified win', () => {
    expect(seatState({ result: 'won', resultCertainty: 'certified' })).toBe(3);
  });

  it('returns 4 when a future-dated term exists for the winner', () => {
    expect(
      seatState({
        result: 'won',
        resultCertainty: 'certified',
        winnerTermStart: '2027-01-03',
        today: '2026-11-04',
      }),
    ).toBe(4);
  });

  it('returns 5 once that term has started', () => {
    expect(
      seatState({
        result: 'won',
        resultCertainty: 'certified',
        winnerTermStart: '2027-01-03',
        today: '2027-01-03',
      }),
    ).toBe(5);
  });

  it('stays at 1 for an undecided race rather than throwing', () => {
    expect(seatState({ result: null, liveCandidates: 4 })).toBe(1);
  });

  it('is still 4 the day before the term starts, not 5', () => {
    expect(
      seatState({
        result: 'won',
        resultCertainty: 'called',
        winnerTermStart: '2027-01-03',
        today: '2027-01-02',
      }),
    ).toBe(4);
  });
});

describe('levelOf', () => {
  it('maps both national district types to federal', () => {
    expect(levelOf('NATIONAL_UPPER')).toBe('federal');
    expect(levelOf('NATIONAL_LOWER')).toBe('federal');
  });

  it('maps every STATE_ prefix to state', () => {
    expect(levelOf('STATE_LOWER')).toBe('state');
    expect(levelOf('STATE_EXEC')).toBe('state');
    expect(levelOf('STATE_BOARD_EDUCATION')).toBe('state');
  });

  it('maps school, county and municipal types to local', () => {
    expect(levelOf('SCHOOL')).toBe('local');
    expect(levelOf('COUNTY')).toBe('local');
    expect(levelOf('LOCAL_EXEC')).toBe('local');
  });

  it('maps a race with no district to unknown rather than guessing', () => {
    expect(levelOf(null)).toBe('unknown');
  });
});

describe('isStillStanding', () => {
  // 🔴 This is deliberately NOT essentials.is_live_candidate, which returns TRUE for `won`
  // AND `lost` alike (migration 1582 says so in capitals). Using that one would mean
  // recording losers never shrinks the headshot and stance gap counts to the winners.
  it('counts a candidate with no result yet', () => {
    expect(isStillStanding({ result: null })).toBe(true);
  });

  it('counts a winner', () => {
    expect(isStillStanding({ result: 'won' })).toBe(true);
  });

  it('excludes a loser, unlike essentials.is_live_candidate', () => {
    expect(isStillStanding({ result: 'lost' })).toBe(false);
  });

  it('excludes not_nominated and withdrew', () => {
    expect(isStillStanding({ result: 'not_nominated' })).toBe(false);
    expect(isStillStanding({ result: 'withdrew' })).toBe(false);
  });
});

describe('the SQL and the JS cannot drift apart', () => {
  // 🔴 levelOf and isStillStanding were exported, documented and TESTED — and never called,
  // because buildStatus inlined both as SQL. Eight of the tests above were asserting the
  // behaviour of dead duplicates: edit one copy and the other diverges with the suite green.
  // Now there is one definition of each and the SQL is built from it.
  const src = readFileSync(new URL('./election-transition-status.mjs', import.meta.url), 'utf8');

  it('builds the "still standing" SQL list from the same constant isStillStanding uses', () => {
    expect(src).toMatch(/NOT_STANDING/);
    // The list may appear EXACTLY ONCE — its definition. A second copy is the drift this
    // guards: the SQL interpolates `sqlNotStandingList()` rather than repeating the values.
    const copies = src.match(/'lost'\s*,\s*'not_nominated'\s*,\s*'withdrew'/g) ?? [];
    expect(copies).toHaveLength(1);
    expect(src).toMatch(/NOT IN \(\$\{sqlNotStandingList\(\)\}\)/);
  });

  it('has no second, SQL-side copy of the level mapping', () => {
    expect(src).not.toMatch(/LEVEL_SQL/);
  });

  // 🔴 The same drift, one file over. build-transition-dataset.mjs held its own STATE_LABEL and
  // its own positional array of counter keys, so renaming a state here changed nothing a reader
  // sees, and renaming it there changed the CSV column without changing the label. That is how
  // "Sworn in" outlived the state it described. There is one definition now; this asserts the
  // builder still reads it rather than keeping a copy.
  const builder = readFileSync(new URL('./build-transition-dataset.mjs', import.meta.url), 'utf8');

  it('the dataset builder imports the labels instead of redefining them', () => {
    expect(builder).toMatch(/import \{[^}]*\bSTATE_LABEL\b[^}]*\} from '\.\/election-transition-status\.mjs'/s);
    expect(builder).toMatch(/import \{[^}]*\bSTATE_KEY\b[^}]*\} from '\.\/election-transition-status\.mjs'/s);
    expect(builder).not.toMatch(/const STATE_LABEL\s*=/);
    expect(builder).not.toMatch(/const STATE_KEY\s*=/);
  });

  it('the dataset builder keeps no positional copy of the counter keys', () => {
    expect(builder).not.toMatch(/\[''\s*,\s*'not_looked_at'/);
  });

  it('every value isStillStanding rejects appears in the SQL list it generates', () => {
    for (const r of ['lost', 'not_nominated', 'withdrew']) {
      expect(isStillStanding({ result: r })).toBe(false);
      expect(sqlNotStandingList()).toContain(`'${r}'`);
    }
  });
});
