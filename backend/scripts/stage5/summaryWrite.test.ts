import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { shownSha256 } from '../lib/stage5QuoteCheck.js';
import { REQUIRED, applyWrite, evaluate, loadBatch, run, writeReports } from './summary-write.js';

const AT = '2026-11-22T10:00:00Z';
const mkText = (n: string) => `${n} voted for the bill [1].`;
const check = (pid: string, sha: string, family: 'claude' | 'gpt' | 'gemini', ok = true) => ({
  politician_id: pid, topic_key: 'gun-policy', text_sha256: sha, checker: `${family}-x`, family, at: AT,
  verdict: ok ? 'pass' : 'fail',
  sentences: [{ index: 0, verdict: ok ? 'pass' : 'fail', reason: ok ? 'fine' : `${family} says unsupported` }],
});

interface Setup { profile: string; dir: string }
function setup(opts: { fails?: Record<string, 'claude' | 'gpt'>; skipClaude?: string[]; badSha?: string } = {}): Setup {
  const stage5 = mkdtempSync(join(tmpdir(), 'sw-'));
  const dir = join(stage5, 'summaries', 'b1');
  mkdirSync(join(dir, 'claude-checks'), { recursive: true });
  const ids = ['p1', 'p2', 'p3'];
  const rows = ids.map((id) => {
    const text = mkText(id);
    return { politician_id: id, topic_key: 'gun-policy', text, sha256: id === opts.badSha ? 'deadbeef' : shownSha256(text), sources: [`https://x.gov/${id}`], cites: [['f1']] };
  });
  writeFileSync(join(dir, 'summaries.jsonl'), rows.map((r) => JSON.stringify(r)).join('\n') + '\n');
  writeFileSync(join(dir, 'people.json'), JSON.stringify(ids.map((id) => ({ politician_id: id, name: `Name ${id}`, outcome: 'seated', value: 1, finding_ids: ['f1'] }))));
  const lines: string[] = [];
  for (const r of rows) {
    const sha = shownSha256(r.text);
    for (const fam of ['gpt', 'gemini'] as const) lines.push(JSON.stringify(check(r.politician_id, sha, fam, opts.fails?.[r.politician_id] !== fam)));
    if (!opts.skipClaude?.includes(r.politician_id)) {
      writeFileSync(join(dir, 'claude-checks', `${r.politician_id}.json`), JSON.stringify(check(r.politician_id, sha, 'claude', opts.fails?.[r.politician_id] !== 'claude')));
    }
  }
  writeFileSync(join(dir, 'checks.jsonl'), lines.join('\n') + '\n');
  const profile = join(stage5, 'topic-profile.json');
  writeFileSync(profile, JSON.stringify({ topic_key: 'gun-policy', stage5, sides: null }));
  return { profile, dir };
}

/** A fake database: context rows keyed by politician id; records every statement. */
function fakeDb(opts: { status?: string; missing?: string[] } = {}) {
  const log: { sql: string; params?: unknown[] }[] = [];
  const ctx = new Map<string, { reasoning: string; sources: string[] }>(
    ['p1', 'p2', 'p3'].filter((p) => !opts.missing?.includes(p)).map((p) => [p, { reasoning: `old ${p}`, sources: [`https://old/${p}`] }]));
  const q = async (sql: string, params?: unknown[]) => {
    log.push({ sql, params });
    const s = sql.replace(/\s+/g, ' ').trim();
    if (s.startsWith('SELECT id::text AS id, number, name, status FROM inform.seasons')) return { rows: [{ id: 'S3', number: 3, name: 'Season 3', status: opts.status ?? 'draft' }], rowCount: 1 };
    if (s.includes('FROM inform.seasons WHERE id')) return { rows: [{ status: opts.status ?? 'draft' }], rowCount: 1 };
    if (s.includes('FROM inform.compass_topics')) return { rows: [{ id: 'T1' }], rowCount: 1 };
    if (s.startsWith('SELECT reasoning')) { const c = ctx.get(String(params![0])); return { rows: c ? [c] : [], rowCount: c ? 1 : 0 }; }
    if (s.startsWith('UPDATE inform.politician_context')) {
      const pid = String(params![0]);
      if (!ctx.has(pid)) return { rows: [], rowCount: 0 };
      ctx.set(pid, { reasoning: String(params![3]), sources: params![4] as string[] });
      return { rows: [], rowCount: 1 };
    }
    return { rows: [], rowCount: 0 };
  };
  return { q, log, ctx, updates: () => log.filter((l) => l.sql.includes('UPDATE inform.politician_context')) };
}

describe('summary-write', () => {
  it('requires claude, gpt and gemini', () => { expect(REQUIRED).toEqual(['claude', 'gpt', 'gemini']); });

  it('dry run writes nothing to the database, and writes PREVIEW.md and held.md', async () => {
    const { profile, dir } = setup({ fails: { p2: 'gpt' } });
    const db = fakeDb();
    const r = await run({ profile, batch: 'b1', q: db.q });
    expect(db.updates()).toHaveLength(0);
    expect(db.log.some((l) => /^\s*(BEGIN|INSERT|UPDATE|DELETE)/i.test(l.sql))).toBe(false);
    expect(r.applied).toBe(false);
    expect(r.passed).toBe(2);
    const preview = readFileSync(join(dir, 'PREVIEW.md'), 'utf8');
    expect(preview).toContain('Name p1');
    expect(preview).toContain('p1 voted for the bill [1].');
    expect(preview).toContain('https://x.gov/p1');
    expect(preview).not.toContain('p2 voted for the bill [1].');
    const held = readFileSync(join(dir, 'held.md'), 'utf8');
    expect(held).toContain('Name p2');
    expect(held).toContain('gpt says unsupported');
    expect(existsSync(join(dir, 'old-context.jsonl'))).toBe(false);
  });

  it('apply refuses without --yes', async () => {
    const { profile } = setup();
    const db = fakeDb();
    await expect(run({ profile, batch: 'b1', q: db.q, apply: true })).rejects.toThrow(/--yes/);
    await expect(run({ profile, batch: 'b1', q: db.q, apply: true, yes: '   ' })).rejects.toThrow(/--yes/);
    expect(db.updates()).toHaveLength(0);
  });

  it('apply refuses a non-draft season', async () => {
    const { profile } = setup();
    const db = fakeDb({ status: 'open' });
    await expect(run({ profile, batch: 'b1', q: db.q, apply: true, yes: 'go' })).rejects.toThrow(/draft/);
    expect(db.updates()).toHaveLength(0);
  });

  it('held and failed rows are not written', async () => {
    const { profile } = setup({ fails: { p2: 'gpt', p3: 'claude' } });
    const db = fakeDb();
    const r = await run({ profile, batch: 'b1', q: db.q, apply: true, yes: 'yes write them' });
    expect(r.written).toEqual(['p1']);
    expect(db.updates().map((u) => u.params![0])).toEqual(['p1']);
    expect(db.ctx.get('p2')!.reasoning).toBe('old p2');
    expect(db.ctx.get('p3')!.reasoning).toBe('old p3');
    expect(db.ctx.get('p1')!.reasoning).toBe('p1 voted for the bill [1].');
    expect(db.log.some((l) => l.sql.trim() === 'COMMIT')).toBe(true);
  });

  it('a missing Claude check holds the summary', async () => {
    const { profile } = setup({ skipClaude: ['p1'] });
    const db = fakeDb();
    const r = await run({ profile, batch: 'b1', q: db.q, apply: true, yes: 'go' });
    expect(r.written).toEqual(['p2', 'p3']);
  });

  it('old reasoning is saved before the overwrite', async () => {
    const { profile, dir } = setup();
    const db = fakeDb();
    let savedBeforeFirstUpdate = false;
    const q: typeof db.q = async (sql, params) => {
      if (sql.includes('UPDATE inform.politician_context') && !savedBeforeFirstUpdate) {
        savedBeforeFirstUpdate = existsSync(join(dir, 'old-context.jsonl'));
      }
      return db.q(sql, params);
    };
    await run({ profile, batch: 'b1', q, apply: true, yes: 'go' });
    expect(savedBeforeFirstUpdate).toBe(true);
    const old = readFileSync(join(dir, 'old-context.jsonl'), 'utf8').trim().split('\n').map((l) => JSON.parse(l));
    expect(old.map((o) => o.politician_id).sort()).toEqual(['p1', 'p2', 'p3']);
    expect(old.find((o) => o.politician_id === 'p1')).toMatchObject({ reasoning: 'old p1', sources: ['https://old/p1'] });
  });

  it('the UPDATE carries the sha and is an update, never an insert', async () => {
    const { profile } = setup();
    const db = fakeDb();
    await run({ profile, batch: 'b1', q: db.q, apply: true, yes: 'go' });
    const u = db.updates()[0];
    expect(u.sql).toContain('summary_sha256');
    expect(db.log.some((l) => /INSERT/i.test(l.sql))).toBe(false);
    expect(u.params).toContain(shownSha256(mkText('p1')));
  });

  it('a person with no context row in the season is refused, not inserted', async () => {
    const { profile } = setup();
    const db = fakeDb({ missing: ['p2'] });
    const r = await run({ profile, batch: 'b1', q: db.q, apply: true, yes: 'go' });
    expect(r.written).toEqual(['p1', 'p3']);
    expect(r.refused.map((x) => x.politician_id)).toEqual(['p2']);
    expect(r.refused[0].reason).toMatch(/no context row/);
    expect(db.log.some((l) => /INSERT/i.test(l.sql))).toBe(false);
  });

  it('refuses a row whose stored sha256 differs from the recomputed one', () => {
    const { dir } = setup({ badSha: 'p1' });
    const b = loadBatch(dir);
    const ev = evaluate(b.summaries, b.checks, REQUIRED);
    const p1 = ev.find((e) => e.summary.politician_id === 'p1')!;
    expect(p1.verdict).not.toBe('passed');
    expect(p1.problems.join(' ')).toMatch(/sha256/);
  });

  it('rejects a claude-checks file that is not a claude check or fails the schema', () => {
    const { dir } = setup();
    writeFileSync(join(dir, 'claude-checks', 'bad.json'), JSON.stringify({ nope: 1 }));
    writeFileSync(join(dir, 'claude-checks', 'wrongfam.json'), JSON.stringify(check('p1', shownSha256(mkText('p1')), 'gpt')));
    const b = loadBatch(dir);
    expect(b.problems.filter((p) => /bad\.json|wrongfam\.json/.test(p))).toHaveLength(2);
  });

  it('writes the batch agreement rate', () => {
    const { dir } = setup({ fails: { p2: 'gpt' } });
    const b = loadBatch(dir);
    const ev = evaluate(b.summaries, b.checks, REQUIRED);
    const out = writeReports(dir, b, ev, 'gun-policy');
    expect(out.agreement).toBeCloseTo(2 / 3);
  });
});
