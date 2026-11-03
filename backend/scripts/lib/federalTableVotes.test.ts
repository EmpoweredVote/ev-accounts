import { describe, it, expect } from 'vitest';
import { instrumentBill, groupRollCalls, matchRollCall, tableAct, type TableRollCall, type TableVoteRow } from './federalTableVotes.js';

const roll = (over: Partial<TableRollCall>): TableRollCall => ({
  external_vote_id: 'house-252', bill_number: 'HJRES 44', congress: '118', date: '2023-06-13',
  question: 'On Passage RC# 252', rc: 252, yes: 219, no: 210, positions: new Map(), ...over,
});

const hj44 = { congress: '118', bill_number: 'HJRES 44' };
const rolls: TableRollCall[] = [
  roll({}),
  roll({ external_vote_id: 'house-253', question: 'Passage, Objections of the President To The Contrary Notwithstanding RC# 253', rc: 253, yes: 233, no: 197 }),
];
const twinOf252 = roll({ external_vote_id: 'house-252-twin', question: 'On Passage RC# 999', rc: 999, yes: 218, no: 211 });
const withSenate = [...rolls, roll({ external_vote_id: 'senate-99', question: 'On Passage RC# 99', rc: 99, yes: 49, no: 48 })];

const houseRowFor = (politician_id: string): TableVoteRow => ({
  politician_id, external_vote_id: 'house-252', bill_number: 'HJRES 44', congress: '118', vote_date: '2023-06-13',
  vote_question: 'On Passage RC# 252', position: 'yea', yea_count: 219, nay_count: 210,
});

describe('federalTableVotes', () => {
  it('derives Congress and bill from an instrument id', () => {
    expect(instrumentBill('US-HJRES-44-2023')).toEqual({ congress: '118', bill_number: 'HJRES 44' });
    expect(instrumentBill('US-HR-1-2025')).toEqual({ congress: '119', bill_number: 'HR 1' });
    expect(instrumentBill('IN-SB-10-2025')).toBeNull();
  });
  it('matches the one roll call with the same bill, date and totals within one', () => {
    expect(matchRollCall({ date: '2023-06-13', yes: 219, no: 210 }, hj44, rolls)).toMatchObject({ kind: 'one', roll: { rc: 252 } });
    expect(matchRollCall({ date: '2023-06-13', yes: 220, no: 210 }, hj44, rolls)).toMatchObject({ kind: 'one' });
  });
  it('does not match a different bill or Congress', () => {
    expect(matchRollCall({ date: '2023-06-13', yes: 219, no: 210 }, { congress: '118', bill_number: 'HR 44' }, rolls).kind).toBe('none');
    expect(matchRollCall({ date: '2023-06-13', yes: 219, no: 210 }, { congress: '117', bill_number: 'HJRES 44' }, rolls).kind).toBe('none');
  });
  it('refuses a census vote with no table roll call', () => {
    expect(matchRollCall({ date: '2023-06-14', yes: 219, no: 210 }, hj44, rolls).kind).toBe('none');
    expect(matchRollCall({ date: '2023-06-13', yes: 222, no: 210 }, hj44, rolls).kind).toBe('none');
  });
  it('refuses, never picks, when two roll calls fit', () => {
    expect(matchRollCall({ date: '2023-06-13', yes: 219, no: 210 }, hj44, [...rolls, twinOf252])).toEqual({
      kind: 'many', candidates: ['house-252', 'house-252-twin'],
    });
  });
  it('tells a House roll call from a Senate one on the same bill and day by totals', () => {
    expect(matchRollCall({ date: '2023-06-13', yes: 49, no: 48 }, hj44, withSenate)).toMatchObject({ kind: 'one', roll: { yes: 49 } });
  });
  it("groups rows by roll call whoever voted, so a senator's earlier House vote is found", () => {
    const g = groupRollCalls([houseRowFor('sen-now-1'), houseRowFor('rep-1')]);
    expect(g).toHaveLength(1);
    expect(g[0].positions.get('sen-now-1')).toBe('yea');
    expect(g[0]).toMatchObject({ rc: 252, yes: 219, no: 210 });
  });
  it('parses the RC number, and leaves it null when the question has none', () => {
    const g = groupRollCalls([
      { ...houseRowFor('a'), external_vote_id: 'x', vote_question: 'Passage, Objections of the President To The Contrary Notwithstanding RC# 253' },
      { ...houseRowFor('a'), external_vote_id: 'y', vote_question: 'On Motion to Recommit' },
    ]);
    expect(g.map((r) => r.rc)).toEqual([253, null]);
  });
  it('maps table positions to acts; not_voting is no act', () => {
    expect([tableAct('yea'), tableAct('nay'), tableAct('present'), tableAct('not_voting')]).toEqual(['yea', 'nay', 'abstain', null]);
  });
});
