import { describe, it, expect } from 'vitest';
import { prefillFindings, parseGatesTsv, type GateRow } from './stage5Prefill.js';
import { PersonFindingsSchema, type Instrument } from './sourceStore.js';
import type { RosterRow } from './stage5Roster.js';

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

describe('parseGatesTsv', () => {
  it('reads the census gates file', () => {
    const text = 'instrument_id\tvote_date\tbody\tmotion\tkind\tyes\tno\tabsent\tbody_size\town_motion\thigher_law_duty\tmulti_subject\tgate\tnote\n'
      + 'US-HR-22-2025\t2025-04-10\tUS House\tfinal passage (On Passage)\troll-call\t220\t208\t5\t435\ttrue\tfalse\tfalse\t\t\n';
    expect(parseGatesTsv(text)).toEqual([{ instrument_id: 'US-HR-22-2025', vote_date: '2025-04-10', body: 'US House', motion: 'final passage (On Passage)', gate: '' }]);
  });
});
