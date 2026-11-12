import { describe, expect, it } from 'vitest';
import { compactBatch, filterRulings, roundTripProblems, type RosterRow } from './stage5CoderInputs.js';
import type { PersonFindings } from './sourceStore.js';

const prov = { fetched_by: 'PROVENANCE-MARKER', fetched_at: '2026-11-01T00:00:00Z', method: 'api' as const };
const vote = (id: string, pid: string, subjects = ['state silencer ban repealed']) => ({
  id: id.repeat(64), kind: 'record' as const, url: 'https://legis.example/hb1324', date: '2026-03-06', date_precision: 'day' as const,
  instrument_id: 'GA-HB-1324-2025', act: 'yea' as const, motion: `Passage ${pid}`, gate_by_topic: { 'gun-policy': 'none', 'voting-rights': 'x' },
  note: 'GA House passage: yea.', subjects, topic_keys: ['gun-policy'], provenance: prov,
});
const search = { topic_key: 'gun-policy', season: 3, subjects: ['carry', 'checks'], places: ['web search'], found: 1, at: '2026-11-01', by: 'agent' };
const A = '11111111-1111-4111-8111-111111111111';
const B = '22222222-2222-4222-8222-222222222222';
const pfA: PersonFindings = {
  politician_id: A,
  findings: [vote('a', A), { ...vote('d', A), topic_keys: ['voting-rights'] },
    { id: 'b'.repeat(64), kind: 'own-words', url: 'https://x.example', date: '2026', date_precision: 'year', passage: 'Words.', note: 'n', subjects: ['carry'], topic_keys: ['gun-policy'], provenance: prov }],
  searches: [search, { ...search, season: 2 }, { ...search, topic_key: 'voting-rights' }],
};
const pfB: PersonFindings = { politician_id: B, findings: [vote('c', B, ['a different reading'])], searches: [{ ...search, subjects: ['other'] }] };
const row = (pid: string, name: string): RosterRow => ({ politician_id: pid, full_name: name, level: 'state', state: 'ga', scope: 'sitting' });
const people = [{ row: row(A, 'Ann'), pf: pfA }, { row: row(B, 'Bo'), pf: pfB }, { row: row('33333333-3333-4333-8333-333333333333', 'Cy'), pf: undefined }];

describe('compactBatch', () => {
  const c = compactBatch(people, 'gun-policy', 3, (id) => `instruments/state-ga/${id}.json`);
  it('keeps this topic and season only, and drops source tracking', () => {
    const s = JSON.stringify(c);
    expect(s).not.toContain('PROVENANCE-MARKER');
    expect(s).not.toContain('d'.repeat(64));
    expect(s).not.toContain('voting-rights');
    expect(c.people[0].searches).toHaveLength(1);
    expect(c.people[0].findings[0].gate).toBe('none');
  });
  it('states a bill\'s subjects once, keeps a finding\'s own when they differ', () => {
    expect(c.bills['GA-HB-1324-2025']).toEqual({ subjects: ['state silencer ban repealed'], file: 'instruments/state-ga/GA-HB-1324-2025.json' });
    expect(c.people[0].findings[0].subjects).toBeUndefined();
    expect(c.people[1].findings[0].subjects).toEqual(['a different reading']);
    expect(c.people[0].searches[0].subjects).toBeUndefined();
    expect(c.people[1].searches[0].subjects).toEqual(['other']);
  });
  it('rebuilds to exactly what the store holds', () => {
    expect(roundTripProblems(people, c, 'gun-policy', 3)).toEqual([]);
  });
  it('reports a lost finding or a changed field', () => {
    const lost = JSON.parse(JSON.stringify(c));
    lost.people[0].findings.pop();
    expect(roundTripProblems(people, lost, 'gun-policy', 3).join()).toContain('lost');
    const edited = JSON.parse(JSON.stringify(c));
    edited.people[0].findings[0].note = 'changed';
    expect(roundTripProblems(people, edited, 'gun-policy', 3).join()).toContain('differ');
    const subj = JSON.parse(JSON.stringify(c));
    subj.bills['GA-HB-1324-2025'].subjects = ['wrong'];
    expect(roundTripProblems(people, subj, 'gun-policy', 3).join()).toContain('differ');
  });
});

describe('filterRulings', () => {
  const md = [
    'Runner rulings, applied, not re-argued:',
    '- Police-carry bills (US-HR-354-2024) are out of scope.',
    '- {state:in} IN-HB-1365-2023 is no rung act.',
    '',
    '## Massachusetts rulings {state:ma}',
    '- MA-H-2092-2019 is a rung 3 act.',
    '- {all} A docket with its text in the store is a bill for coding.',
    '  It can seat.',
    '',
    '## Georgia notes {state:ga,mo}',
    'Store facts, not rulings:',
    '- GA-SB-204-2025 is multi-subject.',
    '',
    '## Federal {federal}',
    '- US-HR-2189 is not rung 5.',
  ].join('\n');
  it('keeps every-state rulings and this state\'s, and lists what it drops', () => {
    const r = filterRulings(md, 'state:ga');
    expect(r.text).toContain('Police-carry');
    expect(r.text).toContain('A docket with its text in the store is a bill for coding.\n  It can seat.');
    expect(r.text).toContain('## Massachusetts rulings\n');
    expect(r.text).toContain('Store facts, not rulings:');
    expect(r.text).toContain('GA-SB-204-2025');
    expect(r.text).not.toContain('MA-H-2092');
    expect(r.text).not.toContain('IN-HB-1365');
    expect(r.text).not.toContain('US-HR-2189');
    expect(r.text).not.toContain('{');
    expect(r.kept).toBe(3);
    expect(r.dropped).toHaveLength(3);
  });
  it('drops a whole section with no bullet kept, and serves a second listed state and federal', () => {
    expect(filterRulings(md, 'state:in').text).not.toContain('Georgia notes');
    expect(filterRulings(md, 'state:mo').text).toContain('GA-SB-204-2025');
    expect(filterRulings(md, 'federal').text).toContain('US-HR-2189');
  });
  it('refuses a malformed scope', () => {
    expect(() => filterRulings('## X {state:georgia}\n- a', 'state:ga')).toThrow(/bad ruling scope/);
  });
});
