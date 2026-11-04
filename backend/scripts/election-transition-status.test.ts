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
import { seatState, levelOf, isStillStanding } from './election-transition-status.mjs';

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
