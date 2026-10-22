import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import {
  DeadEndSchema, InstrumentSchema, JurisdictionSchema, PersonSourcesSchema, appendDeadEnd, storePaths, upsertInstrument, upsertPerson, validateStore,
  type Instrument, type Vote,
} from './sourceStore.js';

const PID = '3f2b8c1e-5d4a-4e6b-9a7c-1b2d3e4f5a6b';
let root: string;
beforeEach(() => { root = mkdtempSync(join(tmpdir(), 'source-store-')); });
afterEach(() => { rmSync(root, { recursive: true, force: true }); });

const prov = (at: string) => ({ fetched_by: 'tester', fetched_at: at, method: 'webfetch' as const });
const vote = (motion: string, yes = 5): Vote => ({
  date: '2021-04-01', body: 'Senate', motion, kind: 'roll-call', yes, no: 1, members: [],
});
const inst = (over: Partial<Instrument> = {}): Instrument => ({
  id: 'WA-ESSB-5044-2021', scope: 'state:wa', title: 'Police training', urls: ['https://example.org/a'],
  version: 'enrolled', single_subject: [], votes: [vote('final passage')], provenance: prov('2026-10-01T00:00:00Z'), ...over,
});

describe('schemas', () => {
  it('accepts method "unrecorded" and a vote note', () => {
    expect(InstrumentSchema.safeParse(inst({ provenance: { ...prov('2026-10-01T00:00:00Z'), method: 'unrecorded' } })).success).toBe(true);
    expect(InstrumentSchema.safeParse(inst({ provenance: { ...prov('2026-10-01T00:00:00Z'), method: 'guess' as never } })).success).toBe(false);
    expect(InstrumentSchema.safeParse(inst({ votes: [{ ...vote('m'), note: 'nay count not printed; inferred 0' }] })).success).toBe(true);
  });
  it('rejects an instrument without provenance', () => {
    const { provenance: _p, ...rest } = inst();
    expect(InstrumentSchema.safeParse(rest).success).toBe(false);
  });
  it('rejects a bad scope', () => {
    for (const s of ['WA', 'state:WA']) expect(InstrumentSchema.safeParse(inst({ scope: s })).success).toBe(false);
    for (const s of ['state:wa', 'county:53033', 'place:5363000', 'school:5103840', 'federal']) {
      expect(InstrumentSchema.safeParse(inst({ scope: s })).success).toBe(true);
    }
    for (const s of ['school:510384', 'school:51038400', 'school:va']) expect(InstrumentSchema.safeParse(inst({ scope: s })).success).toBe(false);
  });
  it('accepts recused as a member vote', () => {
    const vote = { date: '2026-01-01', body: 'b', motion: 'm', kind: 'action-item', yes: 4, no: 0,
      members: [{ name: 'A', vote: 'recused' }, { name: 'B', vote: 'yea' }] };
    expect(InstrumentSchema.safeParse(inst({ votes: [vote] as any })).success).toBe(true);
    expect(InstrumentSchema.safeParse(inst({ votes: [{ ...vote, members: [{ name: 'A', vote: 'present' }] }] as any })).success).toBe(false);
  });
  it('checks instrument id format', () => {
    expect(InstrumentSchema.safeParse(inst({ id: 'WA-ESSB-5044-2021' })).success).toBe(true);
    expect(InstrumentSchema.safeParse(inst({ id: '5044' })).success).toBe(false);
  });
});

describe('provenance and ids', () => {
  it('rejects a portal without provenance', () => {
    const portal = { name: 'p', url: 'https://x', status: 'works', checked_at: '2026-10-01' };
    const j = { scope: 'state:wa', portals: [portal], rosters: [], higher_law_duties: [] };
    expect(JurisdictionSchema.safeParse(j).success).toBe(false);
    expect(JurisdictionSchema.safeParse({ ...j, portals: [{ ...portal, provenance: prov('2026-10-01T00:00:00Z') }] }).success).toBe(true);
  });
  it('rejects a politician_id that is not a uuid', () => {
    expect(PersonSourcesSchema.safeParse({ politician_id: '../x', sources: [], terms: [] }).success).toBe(false);
    expect(PersonSourcesSchema.safeParse({ politician_id: PID, sources: [], terms: [] }).success).toBe(true);
  });
});

describe('paths', () => {
  it('maps scope to a directory', () => {
    const p = storePaths(root);
    expect(p.instrument('state:wa', 'WA-ESSB-5044-2021')).toBe(join(root, 'instruments', 'state-wa', 'WA-ESSB-5044-2021.json'));
    expect(p.instrument('federal', 'US-HR-1-2021')).toContain(join('instruments', 'federal'));
    expect(p.instrument('school:5103840', 'VA-VBCPS-0408-12-2025')).toBe(join(root, 'instruments', 'school-5103840', 'VA-VBCPS-0408-12-2025.json'));
    expect(p.jurisdiction('school:1800630')).toBe(join(root, 'jurisdictions', 'school-1800630.json'));
  });
});

describe('upsertInstrument', () => {
  it('creates then merges votes and keeps the newer provenance fields', () => {
    expect(upsertInstrument(root, inst())).toBe('created');
    const second = inst({
      title: 'Police training (revised)',
      votes: [vote('final passage', 99), vote('concur')],
      provenance: prov('2026-10-10T00:00:00Z'),
    });
    expect(upsertInstrument(root, second)).toBe('merged');
    const saved = JSON.parse(readFileSync(storePaths(root).instrument('state:wa', 'WA-ESSB-5044-2021'), 'utf8'));
    expect(saved.votes).toHaveLength(2);
    expect(saved.title).toBe('Police training (revised)');
    expect(saved.provenance.fetched_at).toBe('2026-10-10T00:00:00Z');
  });
  it('keeps the existing value when the incoming object is older', () => {
    upsertInstrument(root, inst({ title: 'New' }));
    upsertInstrument(root, inst({ title: 'Stale', provenance: prov('2026-01-01T00:00:00Z') }));
    const saved = JSON.parse(readFileSync(storePaths(root).instrument('state:wa', 'WA-ESSB-5044-2021'), 'utf8'));
    expect(saved.title).toBe('New');
  });
  it('writes keys in schema order with a trailing newline', () => {
    upsertInstrument(root, inst());
    const text = readFileSync(storePaths(root).instrument('state:wa', 'WA-ESSB-5044-2021'), 'utf8');
    expect(text.endsWith('}\n')).toBe(true);
    expect(Object.keys(JSON.parse(text)).slice(0, 3)).toEqual(['id', 'scope', 'title']);
  });
});

describe('upsertPerson', () => {
  it('unions sources by url and terms by office+start', () => {
    const src = (url: string, at: string) => ({ url, kind: 'record' as const, topic_keys: [], useful: true, provenance: prov(at) });
    const term = { office: 'Senator', start: '2019', precision: 'year' as const, source: 's' };
    upsertPerson(root, { politician_id: PID, sources: [src('u1', '2026-01-01T00:00:00Z')], terms: [term] });
    expect(upsertPerson(root, {
      politician_id: PID, sources: [src('u1', '2026-02-01T00:00:00Z'), src('u2', '2026-02-01T00:00:00Z')], terms: [term],
    })).toBe('merged');
    const saved = JSON.parse(readFileSync(storePaths(root).person(PID), 'utf8'));
    expect(saved.sources).toHaveLength(2);
    expect(saved.sources[0].provenance.fetched_at).toBe('2026-02-01T00:00:00Z');
    expect(saved.terms).toHaveLength(1);
  });
});

describe('appendDeadEnd', () => {
  it('appends one JSON line per call', () => {
    const d = { at: '2026-10-20', query_or_url: 'https://x', result: 'blocked' as const, by: 'tester' };
    appendDeadEnd(root, d);
    appendDeadEnd(root, { ...d, result: 'nothing' });
    const lines = readFileSync(storePaths(root).deadEnds, 'utf8').trim().split('\n');
    expect(lines).toHaveLength(2);
    for (const l of lines) expect(DeadEndSchema.safeParse(JSON.parse(l)).success).toBe(true);
  });
  it('refuses an object stringified into query_or_url', () => {
    const d = { at: '2026-10-20', query_or_url: String({ target: 'x', reason: 'y' }), result: 'blocked' as const, by: 'tester' };
    expect(() => appendDeadEnd(root, d)).toThrow(/object Object/);
    expect(() => appendDeadEnd(root, { ...d, query_or_url: '' })).toThrow();
  });
});

describe('validateStore', () => {
  it('reports a dead end whose query_or_url is [object Object]', () => {
    mkdirSync(root, { recursive: true });
    writeFileSync(storePaths(root).deadEnds, JSON.stringify({ at: '2026-10-21', query_or_url: '[object Object]', result: 'blocked', by: 'tester' }) + '\n');
    const problems = validateStore(root);
    expect(problems).toHaveLength(1);
    expect(problems[0].file).toBe('dead-ends.jsonl:1');
    expect(problems[0].error).toMatch(/object Object/);
  });
  it('reports a dead end stored twice, ignoring the timestamp', () => {
    mkdirSync(root, { recursive: true });
    const d = { at: '2026-10-21T01:47:30Z', topic_key: 'voting-rights', query_or_url: 'legiscan.com (403)', result: 'blocked', by: 'tester' };
    writeFileSync(storePaths(root).deadEnds, [
      d,
      { ...d, query_or_url: 'congress.gov (403)' },
      { by: d.by, result: d.result, query_or_url: d.query_or_url, topic_key: d.topic_key, at: '2026-10-21T01:52:20Z' },
    ].map((x) => JSON.stringify(x)).join('\n') + '\n');
    const problems = validateStore(root);
    expect(problems).toHaveLength(1);
    expect(problems[0].file).toBe('dead-ends.jsonl:3');
    expect(problems[0].error).toMatch(/duplicate of line 1/);
  });
  it('is clean for an empty or missing store', () => {
    expect(validateStore(root)).toEqual([]);
    expect(validateStore(join(root, 'nope'))).toEqual([]);
  });
  it('reports file and reason', () => {
    upsertInstrument(root, inst());
    const bad = join(root, 'instruments', 'state-wa', 'WA-BAD-1-2020.json');
    mkdirSync(join(root, 'instruments', 'state-wa'), { recursive: true });
    writeFileSync(bad, JSON.stringify({ id: 'WA-BAD-1-2020' }));
    const problems = validateStore(root);
    expect(problems).toHaveLength(1);
    expect(problems[0].file).toContain('WA-BAD-1-2020.json');
    expect(problems[0].error.length).toBeGreaterThan(0);
  });
});
