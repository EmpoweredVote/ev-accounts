/**
 * summary-write.ts — position summaries, step 4: decide which summaries passed every check and, only on the
 * runner's explicit yes, write them into the draft season's politician_context rows (plan 2026-11-22-position-
 * summaries, task 8).
 *
 *   npx tsx scripts/stage5/summary-write.ts --profile <stage5>/topic-profile.json --batch <name> [--apply --yes "<runner's words>"]
 *
 * The check set for each summary is `<batch>/checks.jsonl` (the GPT and Gemini checks) plus one JSON file per Claude
 * checker in `<batch>/claude-checks/` (an object or an array; a missing `checker` is filled with "claude-subagent" and a missing `at` with the file's mtime; each must pass SummaryCheckSchema and be family
 * 'claude'). Required families: claude, gpt, gemini (`summaryVerdict`). Before a summary is trusted, its text is
 * re-hashed with `shownSha256`; a stored sha256 that differs refuses the row. Every check, of every family, must give
 * a verdict on every sentence: a check that skips sentence k is a failed check ("claude check skipped sentence k").
 * The code file (`<stage5>/codes/<politician_id>.json`) is re-read: a row whose code outcome, seat value or file sha256
 * differs from what summary-assemble recorded is held ("code changed since check").
 *
 * Dry run (default): writes PREVIEW.md (table, then each passed summary with numbered sources) and held.md (each held
 * or failed person, every failing sentence, every checker's reason) and prints the all-pass rate (all three checks
 * present and passing) and, per outside family, its verdict agreement with Claude (summaries checked by both whose
 * summary-level pass/fail matches). PREVIEW.md carries both. No writes.
 * Apply: needs `--yes` with the runner's words; the season must be the draft one (assertDraftSeason). In ONE
 * transaction: SELECT each passed person's current reasoning/sources, append them to `old-context.jsonl`, then
 * `UPDATE ... WHERE politician_id, topic_id, season_id`. An UPDATE only: a person with no context row in the season is
 * refused, never inserted (a summary never creates a seat or a blank).
 * Exit 2: bad arguments. Exit 1: refused.
 */
import { appendFileSync, existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { assertDraftSeason } from '../lib/stage5Write.js';
import { shownSha256 } from '../lib/stage5QuoteCheck.js';
import { resolveSeasonTarget } from '../lib/seasonTarget.js';
import { SummaryCheckSchema, agreementRate, summaryVerdict, type SummaryCheck } from '../lib/stage5Summary.js';
import { parseArgs } from './coder-io.js';
import { readCodeRecord, type CodeRecord } from './summary-assemble.js';

type Query = (sql: string, params?: unknown[]) => Promise<{ rows: any[]; rowCount?: number | null }>;
type Family = SummaryCheck['family'];
export const REQUIRED: Family[] = ['claude', 'gpt', 'gemini'];

export interface SummaryRow {
  politician_id: string; topic_key: string; text: string; sha256: string; sources: string[]; cites: string[][];
  /** Written by summary-assemble: the code the summary was checked against. A row without them is held. */
  code_outcome?: string; code_value?: number | null; code_sha256?: string;
}
/** The code file as it is now, for one person. */
export type CodeLookup = (politicianId: string) => CodeRecord | { error: string };
type OutsideFamily = Exclude<Family, 'claude'>;
export type FamilyAgreement = Record<OutsideFamily, { agree: number; both: number }>;
interface PersonRow { politician_id: string; name?: string; outcome?: string }
export interface Batch { dir: string; summaries: SummaryRow[]; checks: SummaryCheck[]; people: Map<string, PersonRow>; problems: string[] }
export interface Evaluated {
  summary: SummaryRow; verdict: 'passed' | 'held' | 'failed'; allAgree: boolean; problems: string[]; checks: SummaryCheck[];
}

const readJsonl = (path: string) => readFileSync(path, 'utf8').split('\n').filter((l) => l.trim());

/** Read the batch: summaries, people (optional), checks.jsonl and claude-checks/*.json. Bad check files are listed in `problems`, never trusted. */
export function loadBatch(dir: string): Batch {
  const problems: string[] = [];
  const summaries = readJsonl(join(dir, 'summaries.jsonl')).map((l) => JSON.parse(l) as SummaryRow);
  const people = new Map<string, PersonRow>();
  if (existsSync(join(dir, 'people.json'))) {
    for (const p of JSON.parse(readFileSync(join(dir, 'people.json'), 'utf8')) as PersonRow[]) people.set(p.politician_id, p);
  }
  const checks: SummaryCheck[] = [];
  const take = (v: unknown, where: string) => {
    const p = SummaryCheckSchema.safeParse(v);
    if (p.success) { checks.push(p.data); return p.data; }
    problems.push(`${where}: not a valid check (${p.error.issues[0]?.message ?? 'schema'})`);
    return null;
  };
  const cf = join(dir, 'checks.jsonl');
  if (existsSync(cf)) {
    readJsonl(cf).forEach((l, i) => {
      let v: unknown;
      try { v = JSON.parse(l); } catch { problems.push(`checks.jsonl line ${i + 1}: not JSON`); return; }
      take(v, `checks.jsonl line ${i + 1}`);
    });
  }
  const cdir = join(dir, 'claude-checks');
  if (existsSync(cdir)) {
    for (const f of readdirSync(cdir).filter((n) => n.endsWith('.json')).sort()) {
      let v: unknown;
      try { v = JSON.parse(readFileSync(join(cdir, f), 'utf8')); } catch { problems.push(`claude-checks/${f}: not JSON`); continue; }
      // The checker template gives no `checker` or `at`; fill those two (never `family`) before validating.
      const mtime = statSync(join(cdir, f)).mtime.toISOString();
      for (const raw of Array.isArray(v) ? v : [v]) {
        const item = raw && typeof raw === 'object' && !Array.isArray(raw)
          ? { ...(raw as Record<string, unknown>), checker: (raw as any).checker ?? 'claude-subagent', at: (raw as any).at ?? mtime }
          : raw;
        const before = checks.length;
        const c = take(item, `claude-checks/${f}`);
        if (c && c.family !== 'claude') { checks.length = before; problems.push(`claude-checks/${f}: family is ${c.family}, not claude`); }
      }
    }
  }
  return { dir, summaries, checks, people, problems };
}

const failedCheck = (c: SummaryCheck) => c.verdict === 'fail' || c.sentences.some((x) => x.verdict === 'fail');

/**
 * A check must give a verdict on every sentence of the summary (indexes exactly 0..n-1), whatever its family — the
 * outside checks are held to it by `toCheck`, and this holds the Claude check to it too. A check that skips a sentence
 * (or names one the summary does not have) becomes a failed check, with one failing entry per gap.
 */
export function requireCoverage(c: SummaryCheck, n: number): SummaryCheck {
  const have = new Set(c.sentences.map((x) => x.index));
  const missing = Array.from({ length: n }, (_, k) => k).filter((k) => !have.has(k));
  const extra = c.sentences.filter((x) => x.index >= n);
  if (!missing.length && !extra.length) return c;
  return {
    ...c, verdict: 'fail', sentences: [
      ...c.sentences,
      ...missing.map((k) => ({ index: k, verdict: 'fail' as const, reason: `${c.family} check skipped sentence ${k + 1}` })),
      ...extra.map((x) => ({ index: x.index, verdict: 'fail' as const, reason: `${c.family} check names sentence ${x.index + 1}, which the summary does not have` })),
    ],
  };
}

/** Why a row's code record no longer matches the code file; null when it matches. */
function codeDrift(s: SummaryRow, codeNow: CodeLookup): string | null {
  if (s.code_outcome === undefined || s.code_value === undefined || s.code_sha256 === undefined) {
    return 'code changed since check: the row carries no code record (re-run summary-assemble); row held';
  }
  const now = codeNow(s.politician_id);
  if ('error' in now) return `code changed since check: the code file is ${now.error}; row held`;
  const diffs: string[] = [];
  if (now.code_outcome !== s.code_outcome) diffs.push(`outcome ${s.code_outcome} -> ${now.code_outcome}`);
  if (now.code_value !== s.code_value) diffs.push(`value ${s.code_value} -> ${now.code_value}`);
  if (now.code_sha256 !== s.code_sha256) diffs.push('code file bytes');
  return diffs.length ? `code changed since check (${diffs.join(', ')}); row held` : null;
}

/**
 * One verdict per summary. A row whose stored sha256 is not the hash of its text is refused (held, with the reason).
 * With `codeNow`, a row whose code file changed since it was assembled (outcome, value or bytes) is held.
 */
export function evaluate(summaries: SummaryRow[], checks: SummaryCheck[], required: Family[], topicKey?: string, codeNow?: CodeLookup): Evaluated[] {
  const count = new Map<string, number>();
  for (const s of summaries) count.set(`${s.politician_id}|${s.topic_key}`, (count.get(`${s.politician_id}|${s.topic_key}`) ?? 0) + 1);
  return summaries.map((s) => {
    const problems: string[] = [];
    if (topicKey !== undefined && s.topic_key !== topicKey) problems.push(`topic_key ${s.topic_key} is not ${topicKey}; row refused`);
    const n = count.get(`${s.politician_id}|${s.topic_key}`) ?? 1;
    if (n > 1) problems.push(`duplicate: ${n} rows for this person and topic; every one refused`);
    const real = shownSha256(s.text);
    if (real !== s.sha256) problems.push(`stored sha256 ${s.sha256} is not the hash of the text (${real}); row refused`);
    if (codeNow) { const d = codeDrift(s, codeNow); if (d) problems.push(d); }
    const nSentences = s.cites?.length ?? splitSentences(s.text).length;
    const mine = checks
      .filter((c) => c.politician_id === s.politician_id && c.topic_key === s.topic_key && c.text_sha256 === real)
      .map((c) => requireCoverage(c, nSentences));
    const verdict = problems.length ? 'held' : summaryVerdict(mine, real, required);
    const allAgree = problems.length === 0 && required.every((f) => mine.some((c) => c.family === f)) && !mine.some(failedCheck);
    return { summary: s, verdict, allAgree, problems, checks: mine };
  });
}

/** Split a summary's text at each closing `[n]` + punctuation, so a failing sentence index can be shown as words. */
export function splitSentences(text: string): string[] {
  return text.split(/(?<=\[[\d,\s]+\][.!?])\s+/).filter(Boolean);
}

/**
 * For each outside family: among summaries that have both a Claude check and a check of that family, how many give
 * the same summary-level verdict (any failed check of a family = that family fails the summary).
 */
export function familyAgreement(ev: Evaluated[]): FamilyAgreement {
  const verdictOf = (cs: SummaryCheck[], f: Family) => {
    const x = cs.filter((c) => c.family === f);
    return x.length === 0 ? null : x.some(failedCheck) ? 'fail' : 'pass';
  };
  const out = { gpt: { agree: 0, both: 0 }, gemini: { agree: 0, both: 0 } };
  for (const f of ['gpt', 'gemini'] as const) {
    for (const e of ev) {
      const cl = verdictOf(e.checks, 'claude'); const o = verdictOf(e.checks, f);
      if (cl === null || o === null) continue;
      out[f].both += 1;
      if (cl === o) out[f].agree += 1;
    }
  }
  return out;
}

const pct = (a: number, b: number) => `${((a / b) * 100).toFixed(0)}%`;
const LABEL: Record<OutsideFamily, string> = { gpt: 'GPT', gemini: 'Gemini' };
/** "GPT agrees with Claude on 1 of 3 (33%); Gemini agrees with Claude on 2 of 3 (67%)". */
export function familyAgreementText(fa: FamilyAgreement): string {
  return (['gpt', 'gemini'] as const).map((f) => fa[f].both
    ? `${LABEL[f]} agrees with Claude on ${fa[f].agree} of ${fa[f].both} (${pct(fa[f].agree, fa[f].both)})`
    : `${LABEL[f]} agrees with Claude on 0 of 0 (no summary checked by both)`).join('; ');
}

export function writeReports(dir: string, b: Batch, ev: Evaluated[], topicKey: string): { agreement: number; familyAgreement: FamilyAgreement; passed: number; held: number; failed: number } {
  const name = (id: string) => b.people.get(id)?.name ?? id;
  const outcome = (id: string) => b.people.get(id)?.outcome ?? '';
  const agreement = agreementRate(ev.map((e) => ({ all_agree: e.allAgree })));
  const fa = familyAgreement(ev);
  const passed = ev.filter((e) => e.verdict === 'passed');
  const notPassed = ev.filter((e) => e.verdict !== 'passed');
  const table = ['| Person | Outcome | Verdict | Every check agrees |', '| --- | --- | --- | --- |',
    ...ev.map((e) => `| ${name(e.summary.politician_id)} | ${outcome(e.summary.politician_id)} | ${e.verdict} | ${e.allAgree ? 'yes' : 'no'} |`)].join('\n');
  const preview = [
    `# Position summaries to write: ${topicKey}`, '',
    `${passed.length} of ${ev.length} passed every check. All-pass rate ${(agreement * 100).toFixed(0)}% (all three checks present and passing).`, '',
    `Verdict agreement with Claude, per summary: ${familyAgreementText(fa)}.`, '', table, '',
    ...passed.flatMap((e) => [
      `## ${name(e.summary.politician_id)}`, '', e.summary.text, '',
      ...e.summary.sources.map((u, i) => `${i + 1}. ${u}`), '',
    ]),
  ].join('\n');
  writeFileSync(join(dir, 'PREVIEW.md'), preview);

  const heldMd = [`# Held and failed summaries: ${topicKey}`, '', `${notPassed.length} of ${ev.length}.`, '',
    ...notPassed.flatMap((e) => {
      const sents = splitSentences(e.summary.text);
      const lines = [`## ${name(e.summary.politician_id)} (${e.summary.politician_id}) — ${e.verdict}`, '', e.summary.text, ''];
      for (const p of e.problems) lines.push(`- PROBLEM: ${p}`);
      for (const f of REQUIRED) if (!e.checks.some((c) => c.family === f)) lines.push(`- no ${f} check on this text`);
      for (const c of e.checks) {
        lines.push(`- ${c.checker} (${c.family}): ${c.verdict}`);
        for (const s of c.sentences) {
          lines.push(`  - sentence ${s.index + 1} ${s.verdict}${s.verdict === 'fail' && sents[s.index] ? ` — "${sents[s.index]}"` : ''}: ${s.reason}`);
        }
      }
      return [...lines, ''];
    })].join('\n');
  writeFileSync(join(dir, 'held.md'), heldMd);
  return { agreement, familyAgreement: fa, passed: passed.length, held: ev.filter((e) => e.verdict === 'held').length, failed: ev.filter((e) => e.verdict === 'failed').length };
}

export interface WriteResult { written: string[]; refused: { politician_id: string; reason: string }[] }

/**
 * The write, in one transaction. Season re-checked inside (held FOR SHARE). Old reasoning/sources are selected for every
 * passed person and appended to old-context.jsonl before the first UPDATE. Update only: a missing row is refused.
 */
export async function applyWrite(q: Query, o: { rows: Evaluated[]; topicKey: string; seasonId: string; dir: string }): Promise<WriteResult> {
  const written: string[] = [];
  const refused: WriteResult['refused'] = [];
  await q('BEGIN');
  try {
    const { rows: sr } = await q('SELECT status FROM inform.seasons WHERE id = $1 FOR SHARE', [o.seasonId]);
    if (sr[0]?.status !== 'draft') throw new Error(`season ${o.seasonId} is no longer a draft (${sr[0]?.status ?? 'missing'}); nothing written`);
    const { rows: tr } = await q('SELECT id::text AS id FROM inform.compass_topics WHERE topic_key = $1', [o.topicKey]);
    if (tr.length !== 1) throw new Error(`topic "${o.topicKey}" not found in inform.compass_topics; nothing written`);
    const topicId = tr[0].id as string;

    const todo: { e: Evaluated; old: { reasoning: string | null; sources: string[] | null } }[] = [];
    for (const e of o.rows) {
      const { rows } = await q(
        'SELECT reasoning, sources FROM inform.politician_context WHERE politician_id = $1 AND topic_id = $2 AND season_id = $3',
        [e.summary.politician_id, topicId, o.seasonId]);
      if (rows.length === 0) { refused.push({ politician_id: e.summary.politician_id, reason: 'no context row in the draft season (a summary never creates one)' }); continue; }
      todo.push({ e, old: rows[0] });
    }
    const savedAt = new Date().toISOString();
    if (todo.length) {
      appendFileSync(join(o.dir, 'old-context.jsonl'), todo.map(({ e, old }) => JSON.stringify({
        saved_at: savedAt, politician_id: e.summary.politician_id, topic_id: topicId, season_id: o.seasonId,
        reasoning: old.reasoning, sources: old.sources,
      }) + '\n').join(''));
    }
    for (const { e } of todo) {
      const r = await q(
        `UPDATE inform.politician_context
            SET reasoning = $4, sources = $5::text[], summary_sha256 = $6, updated_at = now()
          WHERE politician_id = $1 AND topic_id = $2 AND season_id = $3`,
        [e.summary.politician_id, topicId, o.seasonId, e.summary.text, e.summary.sources, e.summary.sha256]);
      if (r.rowCount !== 1) throw new Error(`UPDATE for ${e.summary.politician_id} changed ${r.rowCount ?? 0} rows; nothing written`);
      written.push(e.summary.politician_id);
    }
    await q('COMMIT');
  } catch (err) {
    await q('ROLLBACK');
    throw err;
  }
  return { written, refused };
}

export interface RunResult extends WriteResult { applied: boolean; passed: number; held: number; failed: number; agreement: number; familyAgreement: FamilyAgreement; problems: string[] }

export async function run(o: { profile: string; batch: string; q?: Query; apply?: boolean; yes?: string }): Promise<RunResult> {
  const profile = JSON.parse(readFileSync(o.profile, 'utf8')) as { topic_key: string; stage5: string };
  if (o.apply && !(o.yes ?? '').trim()) throw new Error('--apply needs --yes "<the runner\'s words>"; nothing written');
  const dir = join(profile.stage5, 'summaries', o.batch);
  const b = loadBatch(dir);
  const ev = evaluate(b.summaries, b.checks, REQUIRED, profile.topic_key, (pid) => readCodeRecord(join(profile.stage5, 'codes', `${pid}.json`)));
  const rep = writeReports(dir, b, ev, profile.topic_key);
  let result: WriteResult = { written: [], refused: [] };
  if (o.apply) {
    if (!o.q) throw new Error('--apply needs a database connection');
    const season = await resolveSeasonTarget('draft', o.q);
    assertDraftSeason(season);
    result = await applyWrite(o.q, { rows: ev.filter((e) => e.verdict === 'passed'), topicKey: profile.topic_key, seasonId: season.id, dir });
    appendFileSync(join(dir, 'write-log.jsonl'), JSON.stringify({ at: new Date().toISOString(), yes: o.yes, written: result.written, refused: result.refused }) + '\n');
  }
  return { ...result, applied: !!o.apply, ...rep, problems: b.problems };
}

async function main(argv: string[]): Promise<void> {
  const { flags } = parseArgs(argv);
  const last = (k: string) => flags.get(k)?.[flags.get(k)!.length - 1];
  const profile = last('profile'); const batch = last('batch');
  if (!profile || !batch) { console.error('usage: summary-write.ts --profile <topic-profile.json> --batch <name> [--apply --yes "<runner\'s words>"]'); process.exit(2); }
  const apply = flags.has('apply');
  let q: Query | undefined;
  if (apply) {
    if (!(last('yes') ?? '').trim()) { console.error('--apply needs --yes "<the runner\'s words>"; nothing written'); process.exit(1); }
    const { pool } = await import('../../src/lib/db.js');
    const client = await pool.connect();
    q = (sql, params) => client.query(sql, params as unknown[]);
    try { await finish(await run({ profile, batch, q, apply, yes: last('yes') })); } finally { client.release(); await pool.end(); }
    return;
  }
  await finish(await run({ profile, batch }));
}

/** The run's one-line tally: counts, the all-pass rate, and each outside family's verdict agreement with Claude. */
export function summaryLine(r: Pick<RunResult, 'passed' | 'held' | 'failed' | 'agreement' | 'familyAgreement'>): string {
  return `passed ${r.passed}, held ${r.held}, failed ${r.failed}; all-pass rate ${(r.agreement * 100).toFixed(0)}%; ${familyAgreementText(r.familyAgreement)}`;
}

function finish(r: RunResult): void {
  for (const p of r.problems) console.log(`WARNING: ${p}`);
  console.log(summaryLine(r));
  if (r.applied) {
    console.log(`written ${r.written.length}: ${r.written.join(', ')}`);
    for (const x of r.refused) console.log(`REFUSED ${x.politician_id}: ${x.reason}`);
  } else console.log('dry run: nothing written to the database. See PREVIEW.md and held.md.');
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch((e) => { console.error((e as Error).message); process.exit(1); });
}
