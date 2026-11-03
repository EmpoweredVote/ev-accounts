import { describe, it, expect } from 'vitest';
import { prefillFindings, parseGatesTsv, type GateRow } from './stage5Prefill.js';
import { PersonFindingsSchema, type Instrument } from './sourceStore.js';
import type { RosterRow } from './stage5Roster.js';
import type { TableRollCall } from './federalTableVotes.js';

const P1 = '11111111-1111-4111-8111-111111111111';
const P2 = '22222222-2222-4222-8222-222222222222';
const GONE = '99999999-9999-4999-8999-999999999999';

const roster: RosterRow[] = [
  { politician_id: P1, full_name: 'A One', office_id: 'o1', level: 'state', state: 'IN', scope: 'sitting', leaving: 'no', race_ids: [] },
  { politician_id: P2, full_name: 'B Two', office_id: 'o2', level: 'state', state: 'IN', scope: 'sitting', leaving: 'no', race_ids: [] },
];

const inst = (id: string, members: Instrument['votes'][number]['members'], motion = 'final passage'): Instrument => ({
  id, scope: 'state:in', title: 'Photo ID to vote', urls: [`https://iga.in.gov/${id}`], version: 'enrolled', single_subject: [],
  votes: [
    { date: '2011-04-12', body: 'Indiana Senate', motion, kind: 'roll-call', yes: 30, no: 20, members },
    { date: '2011-03-01', body: 'Indiana Senate', motion: 'second reading', kind: 'roll-call', yes: 30, no: 20, members },
  ],
  provenance: { fetched_by: 'collector', fetched_at: '2026-10-20T00:00:00Z', method: 'webfetch' },
});

const gate = (instrument_id: string, g = ''): GateRow => ({ instrument_id, vote_date: '2011-04-12', body: 'Indiana Senate', motion: 'final passage', gate: g });
const subjects = { 'IN-SB-483-2011': ['voter ID at the polls'], 'IN-SB-1-2012': ['voter ID at the polls'] };

describe('prefillFindings', () => {
  it('turns a counted vote by a roster person into one record finding, with the gate in the note', () => {
    const { findings } = prefillFindings(
      [inst('IN-SB-483-2011', [{ name: 'One', politician_id: P1, vote: 'yea' }])],
      [gate('IN-SB-483-2011', 'near-unanimous')], roster, 'voting-rights', subjects,
    );
    expect(findings).toHaveLength(1);
    const pf = PersonFindingsSchema.parse(findings[0]);
    expect(pf.politician_id).toBe(P1);
    expect(pf.searches).toEqual([]); // pre-fill is not the own-words search
    expect(pf.findings).toHaveLength(1);
    expect(pf.findings[0]).toMatchObject({
      kind: 'record', act: 'yea', instrument_id: 'IN-SB-483-2011', date: '2011-04-12', motion: 'final passage',
      url: 'https://iga.in.gov/IN-SB-483-2011', subjects: ['voter ID at the polls'], topic_keys: ['voting-rights'],
    });
    expect(pf.findings[0].note).toMatch(/gate: near-unanimous/);
    expect(pf.findings[0].gate_by_topic).toEqual({ 'voting-rights': 'near-unanimous' });
  });

  it('ignores a vote the census did not count (an earlier reading)', () => {
    const { findings } = prefillFindings(
      [inst('IN-SB-483-2011', [{ name: 'One', politician_id: P1, vote: 'nay' }])],
      [gate('IN-SB-483-2011')], roster, 'voting-rights', subjects,
    );
    expect(findings[0].findings.map((f) => f.motion)).toEqual(['final passage']);
  });

  it('picks the counted vote by motion when one body voted twice that day', () => {
    const i = inst('IN-SB-483-2011', [{ name: 'One', politician_id: P1, vote: 'yea' }]);
    i.votes.push({ date: '2011-04-12', body: 'Indiana Senate', motion: 'amendment 3', kind: 'roll-call', yes: 10, no: 40, members: [{ name: 'One', politician_id: P1, vote: 'nay' }] });
    const { findings } = prefillFindings([i], [gate('IN-SB-483-2011')], roster, 'voting-rights', subjects);
    expect(findings[0].findings.map((f) => [f.motion, f.act])).toEqual([['final passage', 'yea']]);
  });

  it('falls back to the one vote that body took that day when the motion text differs', () => {
    const { findings, skipped } = prefillFindings(
      [inst('IN-SB-483-2011', [{ name: 'One', politician_id: P1, vote: 'yea' }], 'third reading and final passage')],
      [gate('IN-SB-483-2011')], roster, 'voting-rights', subjects,
    );
    expect(findings[0].findings).toHaveLength(1);
    expect(skipped).toEqual([]);
  });

  it('reports a census vote it cannot find in the store', () => {
    const { skipped } = prefillFindings(
      [inst('IN-SB-483-2011', [])], [{ ...gate('IN-SB-483-2011'), vote_date: '', motion: 'something else' }], roster, 'voting-rights', subjects,
    );
    expect(skipped).toEqual([expect.objectContaining({ instrument_id: 'IN-SB-483-2011' })]);
  });

  it('turns a roster sponsor into a sponsor finding, and lists an unmatched sponsor', () => {
    const i = inst('IN-SB-483-2011', []);
    i.sponsors = [{ name: 'A One', politician_id: P1, role: 'prime' }, { name: 'Z Nobody', role: 'co' }];
    const { findings, unmatched } = prefillFindings([i], [gate('IN-SB-483-2011')], roster, 'voting-rights', subjects);
    expect(findings).toHaveLength(1);
    expect(findings[0].findings[0]).toMatchObject({ kind: 'record', act: 'sponsor', instrument_id: 'IN-SB-483-2011', date: '2011', date_precision: 'year' });
    expect(unmatched).toEqual([expect.objectContaining({ name: 'Z Nobody', vote: 'co' })]);
  });

  it('writes one finding when two census rows resolve to the same vote', () => {
    const { findings } = prefillFindings(
      [inst('IN-SB-483-2011', [{ name: 'One', politician_id: P1, vote: 'yea' }])],
      [gate('IN-SB-483-2011'), { ...gate('IN-SB-483-2011'), motion: 'final passage (as printed)' }], roster, 'voting-rights', subjects,
    );
    expect(findings[0].findings).toHaveLength(1);
  });

  it('lists a member with no politician id as unmatched, for the identity check', () => {
    const { findings, unmatched } = prefillFindings(
      [inst('IN-SB-483-2011', [{ name: 'Smith', vote: 'yea' }])], [gate('IN-SB-483-2011')], roster, 'voting-rights', subjects,
    );
    expect(findings).toEqual([]);
    expect(unmatched).toEqual([{ instrument_id: 'IN-SB-483-2011', date: '2011-04-12', body: 'Indiana Senate', motion: 'final passage', name: 'Smith', vote: 'yea' }]);
  });

  it('skips a matched member who is not on the roster (left office)', () => {
    const { findings, unmatched } = prefillFindings(
      [inst('IN-SB-483-2011', [{ name: 'Gone', politician_id: GONE, vote: 'yea' }])], [gate('IN-SB-483-2011')], roster, 'voting-rights', subjects,
    );
    expect(findings).toEqual([]);
    expect(unmatched).toEqual([]);
  });

  it('records no act for an absent or recused member', () => {
    const { findings } = prefillFindings(
      [inst('IN-SB-483-2011', [{ name: 'One', politician_id: P1, vote: 'absent' }, { name: 'Two', politician_id: P2, vote: 'recused' }])],
      [gate('IN-SB-483-2011')], roster, 'voting-rights', subjects,
    );
    expect(findings).toEqual([]);
  });

  it('ignores an instrument the census did not accept', () => {
    const { findings } = prefillFindings(
      [inst('IN-SB-1-2012', [{ name: 'One', politician_id: P1, vote: 'yea' }])], [gate('IN-SB-483-2011')], roster, 'voting-rights', subjects,
    );
    expect(findings).toEqual([]);
  });

  it('refuses an accepted instrument with no subjects, naming it', () => {
    expect(() => prefillFindings(
      [inst('IN-SB-483-2011', [{ name: 'One', politician_id: P1, vote: 'yea' }])], [gate('IN-SB-483-2011')], roster, 'voting-rights', {},
    )).toThrow(/IN-SB-483-2011.*subjects/);
  });

  it('gives the same finding the same id on a second run', () => {
    const run = () => prefillFindings(
      [inst('IN-SB-483-2011', [{ name: 'One', politician_id: P1, vote: 'yea' }])], [gate('IN-SB-483-2011')], roster, 'voting-rights', subjects,
    ).findings[0].findings[0].id;
    expect(run()).toBe(run());
  });
});

const stateInst = inst; // `inst` is the federal instrument inside the next block

describe('prefillFindings with the federal votes table', () => {
  const fedRoster: RosterRow[] = ['pid-a', 'pid-b', 'pid-unmatched-by-name'].map((politician_id) => ({
    politician_id, full_name: politician_id, office_id: `o-${politician_id}`, level: 'federal', state: 'CA', scope: 'sitting', leaving: 'no', race_ids: [],
  }));
  const ID = 'US-HJRES-44-2023';
  const federal = (members: Instrument['votes'][number]['members'], id = ID, kind: Instrument['votes'][number]['kind'] = 'roll-call'): Instrument => ({
    id, scope: 'federal', title: 'Disapproving the ATF pistol brace rule', urls: [`https://www.congress.gov/${id}`], version: 'enrolled', single_subject: [],
    votes: [{ date: '2023-06-13', body: 'US House', motion: 'final passage (On Passage)', kind, yes: 219, no: 210, members }],
    provenance: { fetched_by: 'collector', fetched_at: '2026-10-20T00:00:00Z', method: 'webfetch' },
  });
  // The hand list: pid-a and pid-b matched by the identity step, one member it could not place.
  const inst = federal([
    { name: 'Aye', politician_id: 'pid-a', vote: 'nay' },
    { name: 'Bee', politician_id: 'pid-b', vote: 'nay' },
    { name: 'Unplaced', vote: 'nay' },
  ]);
  const instWithWrongHandVote = federal([
    { name: 'Aye', politician_id: 'pid-a', vote: 'yea' },
    { name: 'Bee', politician_id: 'pid-b', vote: 'nay' },
  ]);
  const gates: GateRow[] = [{ instrument_id: ID, vote_date: '2023-06-13', body: 'US House', motion: 'final passage (On Passage)', gate: '' }];
  const subjects = { [ID]: ['pistol stabilizing braces'], 'US-S-649-SAMDT-711-2013': ['background checks'] };
  const roll = (external_vote_id: string, positions: Record<string, string>, yes = 219, no = 210): TableRollCall => ({
    external_vote_id, bill_number: 'HJRES 44', congress: '118', date: '2023-06-13', question: 'On Passage RC# 252',
    rc: 252, yes, no, positions: new Map(Object.entries(positions)),
  });
  const roll252 = roll('h252-118.2023', { 'pid-a': 'nay', 'pid-b': 'nay', 'pid-unmatched-by-name': 'nay', 'pid-left-office': 'yea' });
  const rollWithANotVoting = roll('h252-118.2023', { 'pid-a': 'not_voting', 'pid-b': 'nay', 'pid-unmatched-by-name': 'nay' });
  const rollWithoutPidB = roll('h252-118.2023', { 'pid-a': 'nay', 'pid-unmatched-by-name': 'nay' });

  it('takes positions from the matched table roll call, by politician id, with no name match', () => {
    const r = prefillFindings([inst], gates, fedRoster, 'gun-policy', subjects, [roll252]);
    expect(r.findings.find((p) => p.politician_id === 'pid-unmatched-by-name')?.findings[0].act).toBe('nay');
    expect(r.crosscheck.tableOnly).toBe(1);
  });
  it('still lists a hand member with no politician id on a matched roll call, for the identity check', () => {
    // The table cannot say which hand name it holds; a member it does not hold must keep today's path.
    const r = prefillFindings([inst], gates, fedRoster, 'gun-policy', subjects, [roll252]);
    expect(r.unmatched).toEqual([{ instrument_id: ID, date: '2023-06-13', body: 'US House', motion: 'final passage (On Passage)', name: 'Unplaced', vote: 'nay' }]);
  });
  it('does not list a hand member with no politician id whose vote is not an act', () => {
    const absent = federal([{ name: 'Aye', politician_id: 'pid-a', vote: 'nay' }, { name: 'Away', vote: 'absent' }]);
    expect(prefillFindings([absent], gates, fedRoster, 'gun-policy', subjects, [roll252]).unmatched).toEqual([]);
  });
  it('reports a hand-list vote the table contradicts', () => {
    const r = prefillFindings([instWithWrongHandVote], gates, fedRoster, 'gun-policy', subjects, [roll252]);
    expect(r.crosscheck.disagree).toEqual([expect.objectContaining({ politician_id: 'pid-a', hand: 'yea', table: 'nay' })]);
  });
  it('treats a table not_voting against a hand yea as a disagreement', () => {
    // The hand list has pid-a voting yea; the table holds pid-a as not voting.
    const r = prefillFindings([instWithWrongHandVote], gates, fedRoster, 'gun-policy', subjects, [rollWithANotVoting]);
    expect(r.crosscheck.disagree).toEqual([expect.objectContaining({ politician_id: 'pid-a', hand: 'yea', table: null })]);
  });
  it('keeps the hand finding of a roster member the table does not hold, and lists it', () => {
    const r = prefillFindings([inst], gates, fedRoster, 'gun-policy', subjects, [rollWithoutPidB]);
    expect(r.findings.some((p) => p.politician_id === 'pid-b')).toBe(true);
    expect(r.crosscheck.handOnly).toEqual([expect.objectContaining({ politician_id: 'pid-b' })]);
  });
  it('falls back to the hand list, and says why, when no table roll call matches', () => {
    const r = prefillFindings([inst], gates, fedRoster, 'gun-policy', subjects, []);
    expect(r.crosscheck.unmatchedRollCalls[0].reason).toBe('table: no roll call');
    expect(r.findings.length).toBeGreaterThan(0);
  });

  it('writes the table finding in the hand finding\'s shape, naming the table roll call in the note', () => {
    const r = prefillFindings([inst], gates, fedRoster, 'gun-policy', subjects, [roll252]);
    const a = r.findings.find((p) => p.politician_id === 'pid-a')!;
    const hand = prefillFindings([inst], gates, fedRoster, 'gun-policy', subjects).findings.find((p) => p.politician_id === 'pid-a')!;
    expect(a.findings).toHaveLength(1);
    expect(a.findings[0]).toEqual({ ...hand.findings[0], note: `${hand.findings[0].note} positions from essentials.legislative_votes (h252-118.2023).` });
    expect(r.crosscheck).toMatchObject({ matched: 1, disagree: [], handOnly: [], unmatchedRollCalls: [] });
  });
  it('writes no finding for a member the table holds as not voting', () => {
    const r = prefillFindings([instWithWrongHandVote], gates, fedRoster, 'gun-policy', subjects, [rollWithANotVoting]);
    expect(r.findings.some((p) => p.politician_id === 'pid-a')).toBe(false);
  });
  it('records present as an abstention', () => {
    const r = prefillFindings([inst], gates, fedRoster, 'gun-policy', subjects, [roll('h252-118.2023', { 'pid-unmatched-by-name': 'present', 'pid-a': 'nay', 'pid-b': 'nay' })]);
    expect(r.findings.find((p) => p.politician_id === 'pid-unmatched-by-name')?.findings[0].act).toBe('abstain');
  });
  it('refuses, and falls back to the hand list, when two table roll calls fit', () => {
    const r = prefillFindings([inst], gates, fedRoster, 'gun-policy', subjects, [roll252, { ...roll252, external_vote_id: 'h253-118.2023' }]);
    expect(r.crosscheck.unmatchedRollCalls).toEqual([expect.objectContaining({ instrument_id: ID, reason: 'table: 2 roll calls fit' })]);
    expect(r.crosscheck.matched).toBe(0);
    expect(r.unmatched).toEqual([expect.objectContaining({ name: 'Unplaced' })]);
    expect(r.findings.map((p) => p.politician_id).sort()).toEqual(['pid-a', 'pid-b']);
  });
  it('keeps the hand path for a federal instrument with no bill id, and lists it', () => {
    const amdt = federal([{ name: 'Aye', politician_id: 'pid-a', vote: 'yea' }], 'US-S-649-SAMDT-711-2013');
    const r = prefillFindings([amdt], [{ ...gates[0], instrument_id: amdt.id }], fedRoster, 'gun-policy', subjects, [roll252]);
    expect(r.crosscheck.unmatchedRollCalls).toEqual([expect.objectContaining({ instrument_id: amdt.id, reason: 'table: not a bill id' })]);
    expect(r.findings[0].findings[0].note).not.toMatch(/legislative_votes/);
  });
  it('uses the table only for a roll-call vote on a US instrument, and does not list the rest', () => {
    const voice = federal([{ name: 'Aye', politician_id: 'pid-a', vote: 'yea' }], ID, 'consent');
    const r = prefillFindings([voice], gates, fedRoster, 'gun-policy', subjects, [roll252]);
    expect(r.crosscheck).toEqual({ disagree: [], handOnly: [], tableOnly: 0, matched: 0, unmatchedRollCalls: [] });
    expect(r.findings.map((p) => [p.politician_id, p.findings[0].act])).toEqual([['pid-a', 'yea']]);
    const state = prefillFindings([stateInst('IN-SB-483-2011', [{ name: 'One', politician_id: P1, vote: 'yea' }])], [gate('IN-SB-483-2011')], roster, 'voting-rights',
      { 'IN-SB-483-2011': ['voter ID at the polls'] }, [roll252]);
    expect(state.crosscheck.unmatchedRollCalls).toEqual([]);
  });
  it('without the table, returns today\'s output and an empty cross-check', () => {
    const r = prefillFindings([inst], gates, fedRoster, 'gun-policy', subjects);
    expect(r.crosscheck).toEqual({ disagree: [], handOnly: [], tableOnly: 0, matched: 0, unmatchedRollCalls: [] });
    expect(r.unmatched).toEqual([expect.objectContaining({ name: 'Unplaced' })]);
  });
  it('counts a roll call once when two census rows resolve to it', () => {
    const r = prefillFindings([instWithWrongHandVote], [gates[0], { ...gates[0], motion: 'final passage' }], fedRoster, 'gun-policy', subjects, [roll252]);
    expect(r.crosscheck.matched).toBe(1);
    expect(r.crosscheck.disagree).toHaveLength(1);
    expect(r.crosscheck.tableOnly).toBe(1);
  });
});

describe('parseGatesTsv', () => {
  it('reads the census gates file', () => {
    const text = 'instrument_id\tvote_date\tbody\tmotion\tkind\tyes\tno\tabsent\tbody_size\town_motion\thigher_law_duty\tmulti_subject\tgate\tnote\n'
      + 'US-HR-22-2025\t2025-04-10\tUS House\tfinal passage (On Passage)\troll-call\t220\t208\t5\t435\ttrue\tfalse\tfalse\t\t\n';
    expect(parseGatesTsv(text)).toEqual([{ instrument_id: 'US-HR-22-2025', vote_date: '2025-04-10', body: 'US House', motion: 'final passage (On Passage)', gate: '' }]);
  });
});
