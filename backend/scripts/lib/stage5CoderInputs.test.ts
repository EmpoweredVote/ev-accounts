import { describe, expect, it } from 'vitest';
import { batchLine, collapseBatch, collapsedRoundTripProblems, compactBatch, expandCollapsed, filterRulings, roundTripProblems, shownIds, type RosterRow } from './stage5CoderInputs.js';
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
  it('keeps records only in the record-first pass, and still rebuilds', () => {
    const r = compactBatch(people, 'gun-policy', 3, () => undefined, new Set(['record'] as const));
    expect(r.people[0].findings.map((f) => f.kind)).toEqual(['record']);
    expect(roundTripProblems(people, r, 'gun-policy', 3, new Set(['record'] as const))).toEqual([]);
    expect(roundTripProblems(people, r, 'gun-policy', 3).join()).toContain('lost');
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

describe('batchLine', () => {
  it('names the office, so a coder knows what the seat can act on', () => {
    expect(batchLine({ politician_id: 'p1', full_name: 'Scott Fitzpatrick', level: 'state', state: 'mo', scope: 'sitting', office: 'State Auditor' }))
      .toBe('- p1 — Scott Fitzpatrick, State Auditor, state, MO, sitting');
  });
  it('leaves the office out when the roster has none', () => {
    expect(batchLine({ politician_id: 'p1', full_name: 'A', level: 'state', state: 'MO', scope: 'both' })).toBe('- p1 — A, state, MO, both');
  });
});

describe('collapseBatch', () => {
  const pre = (id: string, bill: string, act: 'yea' | 'nay', date: string, body: string, tally: string, gate: string) => ({
    id: id.repeat(64), kind: 'record' as const, url: `https://legis.example/${bill}`, date, date_precision: 'day' as const, instrument_id: bill, act,
    motion: `${bill} Third Reading`, gate_by_topic: { 'gun-policy': gate }, note: `${body}, ${bill} Third Reading, ${date}: ${act} (tally ${tally}); census gate: ${gate}.`,
    subjects: ['s'], topic_keys: ['gun-policy'], provenance: prov,
  });
  const spon = (id: string, bill: string, role: string) => ({
    id: id.repeat(64), kind: 'record' as const, url: `https://legis.example/${bill}`, date: '2025', date_precision: 'year' as const, instrument_id: bill, act: 'sponsor' as const,
    motion: `${role} sponsor, sponsor list`, note: `${role} sponsor of ${bill} (sponsor list): a title.`, subjects: ['s'], topic_keys: ['gun-policy'], provenance: prov,
  });
  const doubt = { ...pre('7', 'XX-HB-2-2025', 'yea', '2025-06-01', 'XX House', '60–30', 'none'), note: 'XX House, XX-HB-2-2025 Third Reading, 2025-06-01: yea (tally 60–30); census gate: none. Identity unverified: two members share this surname.' };
  const own = { id: '8'.repeat(64), kind: 'own-words' as const, url: 'https://x.example', date: '2026', date_precision: 'year' as const, passage: 'Words.', note: 'n', subjects: ['carry'], topic_keys: ['gun-policy'], provenance: prov };
  const P = '44444444-4444-4444-8444-444444444444'; const Q = '55555555-5555-4555-8555-555555555555';
  const ppl = [
    { row: row(P, 'Pat'), pf: { politician_id: P, searches: [search], findings: [pre('1', 'XX-HB-1-2025', 'yea', '2025-05-01', 'XX House', '70–20', 'none'), pre('2', 'XX-HB-1-2025', 'yea', '2025-06-01', 'XX House', '71–19', 'none'), spon('3', 'XX-HB-1-2025', 'prime'), doubt, own] } as PersonFindings },
    { row: row(Q, 'Quin'), pf: { politician_id: Q, searches: [], findings: [pre('4', 'XX-HB-1-2025', 'nay', '2025-05-01', 'XX House', '70–20', 'none'), spon('5', 'XX-HB-1-2025', 'co'), pre('6', 'XX-HB-9-2025', 'yea', '2025-05-02', 'XX House', '90–0', 'near-unanimous')] } as PersonFindings },
  ];
  const table = { 'XX-HB-1-2025': { rung: 4, deciding_words: 'may carry', why: 'Carry made easier.' }, 'XX-HB-2-2025': { rung: null, why: 'A dealer rule.' } };
  const c = collapseBatch(ppl, 'gun-policy', 3, (id) => `state-xx/${id}.json`, table);

  it('writes one line per bill and act, with the bill table\'s rung, and states the reading once per bill', () => {
    expect(c.people[0].record).toEqual([
      { bill: 'XX-HB-1-2025', act: 'yea', rung: 4, on: [['1'.repeat(64), '2025-05-01', 'XX House', '70–20', 'none'], ['2'.repeat(64), '2025-06-01', 'XX House', '71–19', 'none']] },
      { bill: 'XX-HB-1-2025', act: 'sponsor', rung: 4, on: [['3'.repeat(64), '2025', 'prime']] },
    ]);
    expect(c.bills['XX-HB-1-2025']).toMatchObject({ rung: 4, deciding_words: 'may carry', why: 'Carry made easier.' });
    expect(c.bills['XX-HB-9-2025'].rung).toBeUndefined();
    expect(c.people[1].record.find((l) => l.bill === 'XX-HB-9-2025')!.rung).toBeUndefined();
  });
  it('never collapses a note that says more than the plain facts: it stays word for word', () => {
    expect(c.people[0].findings.map((f) => f.id)).toEqual(['7'.repeat(64), '8'.repeat(64)]);
    expect(c.people[0].findings[0].note).toBe(doubt.note);
    expect(JSON.stringify(c.people[0].record)).not.toContain('7'.repeat(64));
  });
  it('rebuilds every finding exactly, and lists every id it shows', () => {
    expect(collapsedRoundTripProblems(ppl, c, 'gun-policy', 3)).toEqual([]);
    expect(shownIds(c).get(P)!.sort()).toEqual(['1', '2', '3', '7', '8'].map((x) => x.repeat(64)));
    const back = expandCollapsed(c).get(Q)!.findings;
    expect(back.find((f) => f.id === '5'.repeat(64))).toMatchObject({ note: 'co sponsor of XX-HB-1-2025 (sponsor list): a title.', motion: 'co sponsor, sponsor list' });
  });
  it('reports a lost id, a changed tally and a changed doubt note', () => {
    const lost = JSON.parse(JSON.stringify(c)); lost.people[0].record[0].on.pop();
    expect(collapsedRoundTripProblems(ppl, lost, 'gun-policy', 3).join()).toContain('lost');
    const tally = JSON.parse(JSON.stringify(c)); tally.people[0].record[0].on[0][3] = '70–21';
    expect(collapsedRoundTripProblems(ppl, tally, 'gun-policy', 3).join()).toContain('its note');
    const note = JSON.parse(JSON.stringify(c)); note.people[0].findings[0].note = 'XX House: yea.';
    expect(collapsedRoundTripProblems(ppl, note, 'gun-policy', 3).join()).toContain('its note');
    const twice = JSON.parse(JSON.stringify(c)); twice.people[0].record[0].on.push(twice.people[0].record[0].on[0]);
    expect(collapsedRoundTripProblems(ppl, twice, 'gun-policy', 3).join()).toContain('twice');
  });
});
