import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import type { Finding } from '../lib/sourceStore.js';
import { buildSummary } from '../lib/stage5Summary.js';
import { readFileSync } from 'node:fs';
import { capFindings, checkerPrompt, main, selectPeople, writerPersonBlock, writerPrompt } from './summary-inputs.js';

const TOPIC = 'gun-policy';
const RUNG_TEXT = 'Limit who may have a gun, such as by court orders that take guns from a person found dangerous';
const pid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;

function finding(n: number, over: Partial<Finding> = {}): Finding {
  return {
    id: `f${n}`.padEnd(64, '0'), kind: 'record', url: `https://example.gov/bill/${n}`, date: `2024-01-${String(n % 28 + 1).padStart(2, '0')}`,
    date_precision: 'day', act: 'yea', instrument_id: `PA-HB-${n}-2024`, motion: `final passage ${n}`,
    note: `Voted yea on HB ${n}, a bill about extreme risk orders.`, subjects: ['erpo'], topic_keys: [TOPIC],
    provenance: { fetched_by: 't', fetched_at: '2026-01-01T00:00:00Z', method: 'webfetch' }, ...over,
  } as Finding;
}

function code(id: string, outcome: string, ids: string[] = [], value?: number) {
  return {
    politician_id: id, topic_key: TOPIC, season: 3, season_id: 's', revision_id: 'r', outcome, ...(value ? { value } : {}),
    reasoning: `That is rung 3, '${RUNG_TEXT}'.`, tags: [], finding_ids: ids, codebook: '0.6', coded_by: 'stage5-coder', coded_at: '2026-10-31T00:00:00Z',
  };
}

function world(people: { n: number; outcome: string; findings: Finding[]; state?: string; value?: number }[]) {
  const dir = mkdtempSync(join(tmpdir(), 'summary-inputs-'));
  const stage5 = join(dir, 'stage5'); const store = join(dir, 'store');
  mkdirSync(join(stage5, 'codes'), { recursive: true }); mkdirSync(join(store, 'findings'), { recursive: true });
  const rows = ['politician_id\tfull_name\toffice_id\tlevel\tstate\tscope\tleaving\trace_ids\toffice'];
  for (const p of people) {
    const id = pid(p.n);
    rows.push(`${id}\tPerson ${p.n}\to\tstate\t${p.state ?? 'pa'}\tsitting\tunknown\t\tState Representative`);
    writeFileSync(join(stage5, 'codes', `${id}.json`), JSON.stringify(code(id, p.outcome, p.findings.slice(0, 1).map((f) => f.id), p.value)));
    writeFileSync(join(store, 'findings', `${id}.json`), JSON.stringify({ politician_id: id, findings: p.findings, searches: [] }));
  }
  writeFileSync(join(stage5, 'roster.tsv'), rows.join('\n') + '\n');
  return { stage5, store };
}

describe('selectPeople', () => {
  it('includes only seated and doesnt-fit people with ≥1 topic finding', () => {
    const { stage5, store } = world([
      { n: 1, outcome: 'seated', value: 3, findings: [finding(1)] },
      { n: 2, outcome: 'doesnt-fit', findings: [finding(2)] },
      { n: 3, outcome: 'no-stance', findings: [finding(3)] },
      { n: 4, outcome: 'seated', value: 3, findings: [finding(4, { topic_keys: ['taxes'] })] },
      { n: 5, outcome: 'seated', value: 2, findings: [finding(5)], state: 'ca' },
    ]);
    const all = selectPeople({ stage5, store, topicKey: TOPIC });
    expect(all.selected.map((p) => p.politician_id)).toEqual([pid(1), pid(2), pid(5)]);
    expect(all.skipped.map((s) => s.why).sort()).toEqual(['no finding on the topic', 'no-stance']);
    expect(selectPeople({ stage5, store, topicKey: TOPIC, state: 'ca' }).selected.map((p) => p.politician_id)).toEqual([pid(5)]);
    expect(selectPeople({ stage5, store, topicKey: TOPIC, people: [pid(2)] }).selected.map((p) => p.politician_id)).toEqual([pid(2)]);
  });
});

describe('capFindings', () => {
  it('caps findings at --max-findings, newest and records first, and lists the count left out', () => {
    const fs = [
      finding(1, { date: '2020-01-01' }), finding(2, { date: '2024-06-01' }), finding(3, { date: '2022-01-01' }),
      finding(4, { kind: 'own-words', act: undefined, instrument_id: undefined, motion: undefined, passage: 'words', date: '2025-01-01' }),
    ];
    const r = capFindings(fs, [], 3);
    expect(r.offered.map((f) => f.id[1])).toEqual(['2', '3', '1']); // records, newest first; own-words is the one left out
    expect(r.left_out).toBe(1);
    // a finding the coder cited is kept even when it is old and the cap is tight
    const kept = capFindings(fs, [fs[0].id], 1);
    expect(kept.offered[0].id).toBe(fs[0].id);
    expect(kept.left_out).toBe(3);
  });
});

describe('writer prompt', () => {
  it("contains the seven writing rules and the person's outcome, never the rung text", () => {
    const { stage5, store } = world([{ n: 1, outcome: 'seated', value: 3, findings: [finding(1)] }]);
    const [p] = selectPeople({ stage5, store, topicKey: TOPIC }).selected;
    const block = writerPersonBlock(p, capFindings(p.findings, p.code.finding_ids, 25), '1,2,3/4,5', new Map([['PA-HB-1-2024', 'Extreme risk orders']]));
    const prompt = writerPrompt([block], { topicKey: TOPIC, topicName: 'gun policy', date: '2026-11-22', sides: '1,2,3/4,5', outFile: '/abs/drafts/1.json' });
    for (let i = 1; i <= 7; i++) expect(prompt).toContain(`\n${i}. `);
    expect(prompt).toContain('Every sentence carries at least one citation, and each cited finding supports what the sentence says.');
    expect(prompt).toContain('Neutral tone: the words a news wire would use, no adjectives of judgement.');
    expect(prompt).toContain('seat: seated, value 3');
    expect(prompt).toContain('(Extreme risk orders)');
    expect(prompt).toContain(p.findings[0].id);
    expect(prompt).not.toContain(RUNG_TEXT);
    expect(prompt).not.toMatch(/\{\{/);
  });
});

describe('checker prompt', () => {
  it("contains the summary, every cited finding's full note and URL, the outcome and the sides", () => {
    const fs = [finding(1, { note: 'A long note about HB 1 that must appear whole, including its last words.' }),
      finding(2, { kind: 'own-words', act: undefined, instrument_id: undefined, motion: undefined, passage: 'I back red flag laws.', url: 'https://example.com/speech' }),
      finding(3)];
    const draft = { politician_id: pid(1), topic_key: TOPIC, sentences: [
      { text: 'She voted for HB 1.', cites: [fs[0].id] }, { text: 'She said she backs red flag laws.', cites: [fs[1].id, fs[0].id] }] };
    const built = buildSummary(draft, fs);
    const prompt = checkerPrompt({ politician_id: pid(1), topic_key: TOPIC, text: built.text, sha256: built.sha256, sources: built.sources, cites: draft.sentences.map((s) => s.cites) },
      fs, { outcome: 'seated', value: 3 }, '1,2,3/4,5', { family: 'gpt' });
    expect(prompt).toContain(built.text);
    expect(prompt).toContain('A long note about HB 1 that must appear whole, including its last words.');
    expect(prompt).toContain('https://example.gov/bill/1');
    expect(prompt).toContain('https://example.com/speech');
    expect(prompt).toContain('I back red flag laws.');
    expect(prompt).toContain('seated, value 3; the person\'s side is 1,2,3');
    expect(prompt).toContain('`sides`: 1,2,3/4,5');
    expect(prompt).toContain(built.sha256);
    expect(prompt).toContain('"family": "gpt"');
    expect(prompt).toContain('1. She said she backs red flag laws [2, 1].'); // sentence index 1 is shown
    expect(prompt).not.toContain(fs[2].id); // an uncited finding is not shown
    expect(prompt).not.toMatch(/\{\{/);
  });

  it('refuses cites that do not match the sentences', () => {
    const f = finding(1);
    const b = buildSummary({ politician_id: pid(1), topic_key: TOPIC, sentences: [{ text: 'One.', cites: [f.id] }, { text: 'Two.', cites: [f.id] }] }, [f]);
    expect(() => checkerPrompt({ politician_id: pid(1), topic_key: TOPIC, text: b.text, sha256: b.sha256, sources: b.sources, cites: [[f.id]] }, [f], { outcome: 'doesnt-fit' }, null)).toThrow(/sentences/);
  });
});

describe('CLI', () => {
  it('writes writer prompts of --per-file people and people.json, and nothing for the checker', () => {
    const { stage5, store } = world([1, 2, 3].map((n) => ({ n, outcome: 'seated', value: 3, findings: [finding(n), finding(n + 10)] })));
    const profile = join(stage5, 'topic-profile.json');
    writeFileSync(profile, JSON.stringify({ topic_key: TOPIC, topic_name: 'gun policy', stage5, sides: '1,2,3/4,5' }));
    main(['--profile', profile, '--batch', 'pa-01', '--state', 'pa', '--per-file', '2', '--max-findings', '1', '--store', store]);
    const out = join(stage5, 'summaries', 'pa-01');
    expect(readFileSync(join(out, 'writer', '1.md'), 'utf8')).toContain(`politician_id ${pid(2)}`);
    expect(readFileSync(join(out, 'writer', '2.md'), 'utf8')).toContain(`politician_id ${pid(3)}`);
    const people = JSON.parse(readFileSync(join(out, 'people.json'), 'utf8'));
    expect(people).toHaveLength(3);
    expect(people[0]).toMatchObject({ outcome: 'seated', value: 3, left_out: 1, writer_file: 'writer/1.md' });
    expect(people[0].finding_ids).toHaveLength(1);
  });
});
