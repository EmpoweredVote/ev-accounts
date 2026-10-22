import { describe, it, expect } from 'vitest';
import { loadRoster, formatRosterTsv, parseRosterTsv, rosterCounts, type RosterGap, type RosterRow } from './stage5Roster.js';

// One fake database. Each query in loadRoster starts with a `-- stage5:<name>` tag, so the fake answers
// by tag rather than by matching SQL text.
type Rows = Record<string, any[]>;
function fakeQuery(rows: Rows) {
  const seen: { tag: string; params: unknown[] }[] = [];
  const q = async (sql: string, params: unknown[] = []) => {
    const tag = /--\s*stage5:([a-z-]+)/.exec(sql)?.[1] ?? '?';
    seen.push({ tag, params });
    return { rows: rows[tag] ?? [] };
  };
  return { q, seen };
}

const state = (o: string, chamber = 'c-house') => ({ office_id: o, chamber_id: chamber, district_type: 'STATE_LOWER', is_judicial: false, district_label: 'HD 1', office_labels: ['Representative', 'House'], state: 'IN' });
const federal = (o: string) => ({ office_id: o, chamber_id: 'c-us-house', district_type: 'NATIONAL_LOWER', is_judicial: false, district_label: 'IN-1', office_labels: ['Representative', 'US House'], state: 'IN' });
const local = (o: string) => ({ office_id: o, chamber_id: 'c-council', district_type: 'LOCAL', is_judicial: false, district_label: 'Ward 1', office_labels: ['Council Member', 'City Council'], state: 'IN' });

const base: Rows = { roles: [{ role_scope: 'federal' }, { role_scope: 'state' }] };

async function run(rows: Rows) {
  const gaps: RosterGap[] = [];
  const { q, seen } = fakeQuery({ ...base, ...rows });
  const roster = await loadRoster(q, 'voting-rights', (g) => gaps.push(g), { asOf: '2026-10-22' });
  return { roster, gaps, seen };
}

describe('loadRoster', () => {
  it('gives a person with two offices one row, at the higher level', async () => {
    const { roster } = await run({ sitting: [
      { politician_id: 'p1', full_name: 'A One', ...state('o-state') },
      { politician_id: 'p1', full_name: 'A One', ...federal('o-fed') },
    ] });
    expect(roster).toHaveLength(1);
    expect(roster[0]).toMatchObject({ politician_id: 'p1', level: 'federal', office_id: 'o-fed', scope: 'sitting' });
  });

  it('marks a sitting official who is an active candidate for their seat as both, not leaving', async () => {
    const { roster } = await run({
      sitting: [{ politician_id: 'p1', full_name: 'A One', ...state('o1') }],
      candidates: [{ candidate_id: 'rc1', politician_id: 'p1', full_name: 'A One', race_id: 'r1', ...state('o1') }],
      upcoming: [{ office_id: 'o1', chamber_id: 'c-house' }],
    });
    expect(roster).toHaveLength(1);
    expect(roster[0]).toMatchObject({ scope: 'both', leaving: 'no', race_ids: ['r1'] });
  });

  it('marks a sitting official whose seat is up and who is on no ballot as leaving', async () => {
    const { roster } = await run({
      sitting: [{ politician_id: 'p1', full_name: 'A One', ...state('o1') }],
      upcoming: [{ office_id: 'o1', chamber_id: 'c-house' }],
    });
    expect(roster[0].leaving).toBe('yes');
  });

  it('marks a seat not up, in a chamber that has races, as not leaving', async () => {
    const { roster } = await run({
      sitting: [{ politician_id: 'p1', full_name: 'A One', ...state('o1') }],
      upcoming: [{ office_id: 'o2', chamber_id: 'c-house' }],
    });
    expect(roster[0].leaving).toBe('no');
  });

  it('says unknown when the chamber has no upcoming races on file', async () => {
    const { roster } = await run({ sitting: [{ politician_id: 'p1', full_name: 'A One', ...state('o1') }] });
    expect(roster[0].leaving).toBe('unknown');
  });

  it('reports an active candidate with no politician record as a gap, with no row', async () => {
    const { roster, gaps } = await run({
      candidates: [{ candidate_id: 'rc9', politician_id: null, full_name: 'B Nine', race_id: 'r9', ...state('o9') }],
    });
    expect(roster).toHaveLength(0);
    expect(gaps).toEqual([expect.objectContaining({ kind: 'candidate-no-politician', id: 'rc9' })]);
  });

  it('drops a level the topic is not asked at, as a gap', async () => {
    const { roster, gaps } = await run({ sitting: [{ politician_id: 'p5', full_name: 'C Five', ...local('o5') }] });
    expect(roster).toHaveLength(0);
    expect(gaps).toEqual([expect.objectContaining({ kind: 'level-out-of-scope', id: 'p5' })]);
  });

  it('reports an office whose level is unknown as a gap', async () => {
    const { roster, gaps } = await run({ sitting: [{ politician_id: 'p6', full_name: 'D Six', ...state('o6'), district_type: 'WEIRD' }] });
    expect(roster).toHaveLength(0);
    expect(gaps).toEqual([expect.objectContaining({ kind: 'no-level', id: 'p6' })]);
  });

  it('adds a challenger as a candidate-only row', async () => {
    const { roster } = await run({
      candidates: [{ candidate_id: 'rc2', politician_id: 'p2', full_name: 'E Two', race_id: 'r2', ...federal('o-fed') }],
    });
    expect(roster).toEqual([expect.objectContaining({ politician_id: 'p2', scope: 'candidate', level: 'federal', leaving: 'no', race_ids: ['r2'] })]);
  });

  it('treats an empty district state as no state', async () => {
    const { roster } = await run({ sitting: [{ politician_id: 'p7', full_name: 'F Seven', ...federal('o7'), state: '' }] });
    expect(roster[0].state).toBeNull();
  });

  it('passes the topic key and the as-of date to the database', async () => {
    const { seen } = await run({});
    expect(seen.find((s) => s.tag === 'roles')?.params).toEqual(['voting-rights']);
    expect(seen.find((s) => s.tag === 'candidates')?.params).toEqual(['2026-10-22']);
    expect(seen.find((s) => s.tag === 'upcoming')?.params).toEqual(['2026-10-22']);
  });
});

describe('roster tsv', () => {
  const rows: RosterRow[] = [
    { politician_id: 'p1', full_name: 'A One', office_id: 'o1', level: 'state', state: 'IN', scope: 'both', leaving: 'no', race_ids: ['r1', 'r2'] },
    { politician_id: 'p2', full_name: 'E Two', office_id: null, level: 'federal', state: null, scope: 'candidate', leaving: 'no', race_ids: [] },
  ];

  it('round-trips', () => {
    const text = formatRosterTsv(rows);
    expect(text.split('\n')[0]).toBe('politician_id\tfull_name\toffice_id\tlevel\tstate\tscope\tleaving\trace_ids');
    expect(parseRosterTsv(text)).toEqual(rows);
  });

  it('counts by level, state, scope and leaving', () => {
    const c = rosterCounts(rows);
    expect(c.byLevel).toMatchObject({ state: 1, federal: 1 });
    expect(c.byState).toEqual({ IN: 1, '(none)': 1 });
    expect(c.byScope).toEqual({ sitting: 0, candidate: 1, both: 1 });
    expect(c.leaving).toEqual({ yes: 0, no: 2, unknown: 0 });
  });
});
