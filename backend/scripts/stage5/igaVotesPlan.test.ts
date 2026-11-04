import { describe, it, expect } from 'vitest';
import { isCommitteeVote, pickRollCall, tallyOf, type ApiRollCall } from './igaVotesPlan.js';

// Shaped like the MyIGA API's `all_rollcalls` for HB 1071 (2017), read 2026-11-04.
const rc = (n: string, chamber: string, yea: number, nay: number, type: string): ApiRollCall => ({
  rollcall_number: n, chamber: { name: chamber }, results: { yea, nay }, type,
});
const HB1071 = [
  rc('517', 'House', 74, 26, 'CONFERENCE COMMITTEE REPORT'),
  rc('506', 'Senate', 38, 12, 'CONFERENCE COMMITTEE REPORT'),
  rc('397', 'Senate', 42, 5, 'BILL'),
  rc('168', 'House', 72, 26, 'BILL'),
];

describe('isCommitteeVote', () => {
  it('reads a committee vote as one', () => {
    expect(isCommitteeVote('Committee on Public Policy, do pass')).toBe(true);
    expect(isCommitteeVote('Senate Committee on Judiciary')).toBe(true);
  });
  it('reads a floor vote on a conference committee report as a floor vote', () => {
    expect(isCommitteeVote('House - Rules Suspended. Conference Committee Report 1')).toBe(false);
    expect(isCommitteeVote('Senate - Conference Committee Report 2')).toBe(false);
  });
  it('reads a plain floor vote as a floor vote', () => {
    expect(isCommitteeVote('House - Third reading')).toBe(false);
    expect(isCommitteeVote('')).toBe(false);
  });
});

describe('tallyOf', () => {
  it('reads the tally a finding note prints, with either dash', () => {
    expect(tallyOf('IN House, Conference Committee Report 1, 2017-04-21: nay (tally 74–26)')).toEqual({ yea: 74, nay: 26 });
    expect(tallyOf('tally 66-26')).toEqual({ yea: 66, nay: 26 });
    expect(tallyOf('no tally here')).toBeNull();
  });
});

describe('pickRollCall', () => {
  it('picks the one roll call of that chamber and tally', () => {
    expect(pickRollCall(HB1071, 'H', { yea: 74, nay: 26 }, true)).toBe('517');
    expect(pickRollCall(HB1071, 'H', { yea: 72, nay: 26 }, false)).toBe('168');
  });
  it('never crosses chambers', () => {
    expect(pickRollCall(HB1071, 'S', { yea: 74, nay: 26 }, true)).toBeNull();
  });
  it('requires a conference-report roll call when the finding names one', () => {
    expect(pickRollCall(HB1071, 'H', { yea: 72, nay: 26 }, true)).toBeNull();
  });
  it('refuses when two roll calls fit, rather than guess', () => {
    const twice = [...HB1071, rc('518', 'House', 74, 26, 'CONFERENCE COMMITTEE REPORT')];
    expect(pickRollCall(twice, 'H', { yea: 74, nay: 26 }, true)).toBeNull();
  });
  it('reads counts the API gives as text', () => {
    const list = [{ ...rc('578', 'House', 72, 0, 'CONFERENCE COMMITTEE REPORT'), results: { yea: 72, nay: '0' as unknown as number } }];
    expect(pickRollCall(list, 'H', { yea: 72, nay: 0 }, true)).toBe('578');
  });
  it('accepts a tally off by one on each count only when no exact match exists (LegiScan vs official)', () => {
    // IN HB 1296 (2022): the finding (LegiScan) says 68-30, the official roll call 382 says 69-30.
    const hb1296 = [rc('382', 'House', 69, 30, 'CONFERENCE COMMITTEE REPORT'), rc('145', 'House', 91, 0, 'BILL')];
    expect(pickRollCall(hb1296, 'H', { yea: 68, nay: 30 }, true)).toBe('382');
    // An exact match wins over a near one.
    expect(pickRollCall([...HB1071, rc('600', 'House', 73, 26, 'CONFERENCE COMMITTEE REPORT')], 'H', { yea: 74, nay: 26 }, true)).toBe('517');
    // Two near matches: refuse.
    expect(pickRollCall([rc('1', 'House', 70, 24, 'BILL'), rc('2', 'House', 72, 22, 'BILL')], 'H', { yea: 71, nay: 23 }, false)).toBeNull();
    // Off by two: refuse.
    expect(pickRollCall(hb1296, 'H', { yea: 67, nay: 30 }, true)).toBeNull();
  });
  it('refuses when nothing fits', () => {
    expect(pickRollCall(HB1071, 'H', { yea: 1, nay: 99 }, false)).toBeNull();
    expect(pickRollCall([], 'H', { yea: 74, nay: 26 }, false)).toBeNull();
  });
});
