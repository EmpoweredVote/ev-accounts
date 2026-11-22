import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import type { Finding } from '../lib/sourceStore.js';
import { assemble } from './summary-assemble.js';

const TOPIC = 'gun-policy';
const pid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const fid = (n: number) => `f${n}`.padEnd(64, '0');

function finding(n: number): Finding {
  return {
    id: fid(n), kind: 'record', url: `https://example.gov/bill/${n}`, date: '2024-01-05', date_precision: 'day', act: 'yea',
    instrument_id: `PA-HB-${n}-2024`, motion: 'final passage', note: `Voted yea on HB ${n}.`, subjects: ['erpo'], topic_keys: [TOPIC],
    provenance: { fetched_by: 't', fetched_at: '2026-01-01T00:00:00Z', method: 'webfetch' },
  } as Finding;
}

const draft = (n: number, texts = ['Voted for a bill on risk orders.', 'Voted for a second bill.'], cites = [[fid(1)], [fid(2)]]) => ({
  politician_id: pid(n), topic_key: TOPIC, sentences: texts.map((text, i) => ({ text, cites: cites[i] })),
});

function world(draftFiles: Record<string, unknown>) {
  const dir = mkdtempSync(join(tmpdir(), 'summary-assemble-'));
  const stage5 = join(dir, 'stage5'); const store = join(dir, 'store');
  const batchDir = join(stage5, 'summaries', 'b1');
  mkdirSync(join(batchDir, 'drafts'), { recursive: true });
  mkdirSync(join(stage5, 'codes'), { recursive: true });
  mkdirSync(join(store, 'findings'), { recursive: true });
  const people = [1, 2].map((n) => {
    writeFileSync(join(stage5, 'codes', `${pid(n)}.json`), JSON.stringify({
      politician_id: pid(n), topic_key: TOPIC, season: 3, season_id: 's', revision_id: 'r', outcome: 'seated', value: 3,
      reasoning: 'x', tags: [], finding_ids: [fid(1)], codebook: '0.6', coded_by: 'c', coded_at: '2026-10-31T00:00:00Z',
    }));
    writeFileSync(join(store, 'findings', `${pid(n)}.json`), JSON.stringify({ politician_id: pid(n), findings: [finding(1), finding(2)], searches: [] }));
    return { politician_id: pid(n), name: `Person ${n}`, outcome: 'seated', value: 3, finding_ids: [fid(1), fid(2)], left_out: 0 };
  });
  writeFileSync(join(batchDir, 'people.json'), JSON.stringify(people));
  for (const [name, body] of Object.entries(draftFiles)) writeFileSync(join(batchDir, 'drafts', name), typeof body === 'string' ? body : JSON.stringify(body));
  const profile = { topic_key: TOPIC, topic_name: 'Gun policy', stage5, sides: '1,2,3/4,5' };
  return { batchDir, run: () => assemble({ profile, batch: 'b1', store }) };
}
const lines = (p: string) => (existsSync(p) ? readFileSync(p, 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l)) : []);

describe('assemble', () => {
  it('a clean draft gets a summary and a checker file; a linted-out draft gets neither', () => {
    const bad = draft(2, ['Voted for a bill.', 'Voted with the Republican caucus.'], [[fid(1)], [fid(2)]]);
    const { batchDir, run } = world({ '1.json': [draft(1), bad] });
    const r = run();
    expect(r).toMatchObject({ drafted: 2, lintedOut: 1, toCheck: 1 });
    const s = lines(join(batchDir, 'summaries.jsonl'));
    expect(s).toHaveLength(1);
    expect(s[0]).toMatchObject({ politician_id: pid(1), topic_key: TOPIC, cites: [[fid(1)], [fid(2)]] });
    expect(s[0].text).toContain('[1]');
    expect(s[0].sources).toEqual(['https://example.gov/bill/1', 'https://example.gov/bill/2']);
    const refused = lines(join(batchDir, 'lint-refused.jsonl'));
    expect(refused).toHaveLength(1);
    expect(refused[0].politician_id).toBe(pid(2));
    expect(refused[0].problems.join(' ')).toMatch(/party/);
    const checkers = readdirSync(join(batchDir, 'checker'));
    expect(checkers).toEqual([`${pid(1)}.md`]);
    expect(readFileSync(join(batchDir, 'checker', `${pid(1)}.md`), 'utf8')).toContain(s[0].sha256);
  });

  it('each checker file names the absolute path its Claude checker writes to', () => {
    const { batchDir, run } = world({ '1.json': [draft(1)] });
    run();
    const md = readFileSync(join(batchDir, 'checker', `${pid(1)}.md`), 'utf8');
    expect(md).toContain(join(resolve(batchDir), 'claude-checks', `${pid(1)}.json`));
    expect(md).not.toMatch(/\{\{/);
  });

  it('refuses an unknown person and invalid JSON without crashing, and accepts a single-object file', () => {
    const stranger = { ...draft(1), politician_id: pid(99) };
    const { batchDir, run } = world({ '1.json': draft(1), '2.json': stranger, '3.json': '{not json', '4.json': { nope: true } });
    const r = run();
    expect(r).toMatchObject({ drafted: 4, lintedOut: 3, toCheck: 1 });
    const reasons = lines(join(batchDir, 'lint-refused.jsonl')).map((x) => x.problems.join(' '));
    expect(reasons.some((x) => /not in people\.json/.test(x))).toBe(true);
    expect(reasons.some((x) => /JSON/.test(x))).toBe(true);
    expect(reasons.some((x) => /schema/i.test(x))).toBe(true);
  });

  it('refuses a draft whose cite is not among the person\'s findings, and a second draft for one person', () => {
    const { batchDir, run } = world({ '1.json': [draft(1, undefined, [[fid(1)], [fid(7)]]), draft(2)], '2.json': draft(2) });
    run();
    const refused = lines(join(batchDir, 'lint-refused.jsonl'));
    expect(refused.find((x) => x.politician_id === pid(1)).problems.join(' ')).toMatch(/not one of this person's findings/);
    expect(refused.find((x) => x.politician_id === pid(2)).problems.join(' ')).toMatch(/more than one draft/);
  });

  it('a corrupt or missing code file refuses that person and still writes the others', () => {
    const { batchDir, run } = world({ '1.json': [draft(1), draft(2)] });
    const stage5 = join(batchDir, '..', '..');
    writeFileSync(join(stage5, 'codes', `${pid(1)}.json`), '{corrupt');
    rmSync(join(stage5, 'codes', `${pid(2)}.json`));
    // a third person with a good code file
    writeFileSync(join(batchDir, 'people.json'), JSON.stringify([
      ...JSON.parse(readFileSync(join(batchDir, 'people.json'), 'utf8')),
      { politician_id: pid(3), name: 'Person 3', outcome: 'seated', value: 3, finding_ids: [fid(1), fid(2)], left_out: 0 },
    ]));
    writeFileSync(join(stage5, 'codes', `${pid(3)}.json`), JSON.stringify({
      politician_id: pid(3), topic_key: TOPIC, season: 3, season_id: 's', revision_id: 'r', outcome: 'seated', value: 3,
      reasoning: 'x', tags: [], finding_ids: [fid(1)], codebook: '0.6', coded_by: 'c', coded_at: '2026-10-31T00:00:00Z',
    }));
    writeFileSync(join(stage5, '..', 'store', 'findings', `${pid(3)}.json`), JSON.stringify({ politician_id: pid(3), findings: [finding(1), finding(2)], searches: [] }));
    writeFileSync(join(batchDir, 'drafts', '2.json'), JSON.stringify(draft(3)));
    const r = run();
    expect(r).toMatchObject({ lintedOut: 2, toCheck: 1 });
    expect(lines(join(batchDir, 'summaries.jsonl')).map((x) => x.politician_id)).toEqual([pid(3)]);
    const refused = lines(join(batchDir, 'lint-refused.jsonl'));
    expect(refused.every((x) => /code file unreadable/.test(x.problems.join(' ')))).toBe(true);
  });

  it('records the code file\'s outcome, seat value and sha256 on each summary row', () => {
    const { batchDir, run } = world({ '1.json': [draft(1)] });
    run();
    const [row] = lines(join(batchDir, 'summaries.jsonl'));
    const bytes = readFileSync(join(batchDir, '..', '..', 'codes', `${pid(1)}.json`));
    expect(row).toMatchObject({ code_outcome: 'seated', code_value: 3, code_sha256: createHash('sha256').update(bytes).digest('hex') });
  });

  it('a marked rewrite replaces one person\'s draft and leaves everyone else\'s files alone', () => {
    const { batchDir, run } = world({ '1.json': [draft(1), draft(2)] });
    run();
    const before = lines(join(batchDir, 'summaries.jsonl'));
    // Both people have a Claude check on disk; the rewrite must not touch either file.
    mkdirSync(join(batchDir, 'claude-checks'), { recursive: true });
    for (const n of [1, 2]) writeFileSync(join(batchDir, 'claude-checks', `${pid(n)}.json`), `{"sentinel":${n}}`);
    const p2md = readFileSync(join(batchDir, 'checker', `${pid(2)}.md`), 'utf8');
    writeFileSync(join(batchDir, 'drafts', 'rewrite-1.json'), JSON.stringify(draft(1, ['Voted for a bill on risk orders.'], [[fid(1)]])));
    const r = run();
    expect(r.replaced).toEqual([pid(1)]);
    const after = lines(join(batchDir, 'summaries.jsonl'));
    expect(after.map((x) => x.politician_id)).toEqual([pid(1), pid(2)]);
    expect(after[0].sha256).not.toBe(before[0].sha256);
    expect(after[1].sha256).toBe(before[1].sha256);
    expect(readFileSync(join(batchDir, 'checker', `${pid(1)}.md`), 'utf8')).toContain(after[0].sha256);
    expect(readFileSync(join(batchDir, 'checker', `${pid(2)}.md`), 'utf8')).toBe(p2md);
    for (const n of [1, 2]) expect(readFileSync(join(batchDir, 'claude-checks', `${pid(n)}.json`), 'utf8')).toBe(`{"sentinel":${n}}`);
    expect(lines(join(batchDir, 'lint-refused.jsonl')).some((x) => x.politician_id === pid(1))).toBe(false);
  });

  it('allows one rewrite per person; a second is refused and the first rewrite is kept', () => {
    const { batchDir, run } = world({
      '1.json': [draft(1)],
      'rewrite-1.json': draft(1, ['Voted for a bill on risk orders.'], [[fid(1)]]),
      'rewrite-2.json': draft(1, ['Voted for a second bill.'], [[fid(2)]]),
    });
    const r = run();
    expect(r.replaced).toEqual([pid(1)]);
    const [row] = lines(join(batchDir, 'summaries.jsonl'));
    expect(row.text).toContain('risk orders');
    const refused = lines(join(batchDir, 'lint-refused.jsonl'));
    expect(refused.find((x) => x.file === 'rewrite-2.json').problems.join(' ')).toMatch(/more than one rewrite/);
  });
});
