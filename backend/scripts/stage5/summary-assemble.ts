/**
 * summary-assemble.ts — position summaries, step 2: turn the writers' drafts into rendered summaries
 * (plan 2026-11-22-position-summaries, task 6).
 *
 *   npx tsx scripts/stage5/summary-assemble.ts --profile <stage5>/topic-profile.json --batch <name> [--store <dir>]
 *
 * Reads `<stage5>/summaries/<batch>/people.json` and every `drafts/*.json` (one SummaryDraft or an array of them).
 * A draft in a file named `drafts/rewrite-*.json` is a marked rewrite: it is read after every other draft and, when
 * clean, replaces that person's earlier draft (once per person; a second rewrite is refused). Every replacement is
 * printed. Writes, beside them:
 *   summaries.jsonl     { politician_id, topic_key, text, sha256, sources, cites, code_outcome, code_value,
 *                       code_sha256 } per clean draft (cites: one id list per sentence; code_*: the code file the
 *                       summary is checked against, which summary-write re-reads before a write)
 *   lint-refused.jsonl  { politician_id, topic_key, file, problems } per draft that is bad, unknown, or unreadable
 *   checker/<politician_id>.md  one checker prompt per summary; it names claude-checks/<politician_id>.json as the
 *                       Claude checker's output. Files are named by person, never by position, so a rewrite changes
 *                       only that person's files. checker/ is rebuilt each run; claude-checks/ is never touched.
 * Exit 0 always; it prints the counts. A bad draft never stops the run.
 */
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { Finding } from '../lib/sourceStore.js';
import { Stage5CodeSchema } from '../lib/stage5Code.js';
import { SummaryDraftSchema, buildSummary, lintSummary, type SummaryDraft } from '../lib/stage5Summary.js';
import { STORE, parseArgs, readPersonFindings } from './coder-io.js';
import { checkerPrompt } from './summary-inputs.js';

interface PersonRow { politician_id: string; name: string; outcome: 'seated' | 'doesnt-fit'; value: number | null; finding_ids: string[] }
export interface Profile { topic_key: string; topic_name?: string; stage5: string; sides: string | null }
/** What a summary was checked against: the code file's outcome, seat value and the sha256 of its exact bytes. */
export interface CodeRecord { code_outcome: string; code_value: number | null; code_sha256: string }

/** Read a code file's record; `{ error }` when it is missing or not JSON. summary-write re-reads it before a write. */
export function readCodeRecord(path: string): CodeRecord | { error: string } {
  if (!existsSync(path)) return { error: 'missing' };
  const bytes = readFileSync(path);
  let j: { outcome?: unknown; value?: unknown };
  try { j = JSON.parse(bytes.toString('utf8')); } catch { return { error: 'not JSON' }; }
  return {
    code_outcome: String(j.outcome ?? ''),
    code_value: typeof j.value === 'number' ? j.value : null,
    code_sha256: createHash('sha256').update(bytes).digest('hex'),
  };
}

export interface AssembleResult { drafted: number; lintedOut: number; toCheck: number; replaced: string[] }

export function assemble(o: { profile: Profile; batch: string; store?: string }): AssembleResult {
  const { profile } = o;
  const store = o.store ?? STORE;
  const dir = join(profile.stage5, 'summaries', o.batch);
  const people = new Map((JSON.parse(readFileSync(join(dir, 'people.json'), 'utf8')) as PersonRow[]).map((p) => [p.politician_id, p]));
  const draftsDir = join(dir, 'drafts');
  const isRewrite = (f: string) => f.startsWith('rewrite-');
  const byName = (a: string, b: string) => a.localeCompare(b, undefined, { numeric: true });
  const all = existsSync(draftsDir) ? readdirSync(draftsDir).filter((f) => f.endsWith('.json')) : [];
  // Ordinary drafts first, then the marked rewrites, so a rewrite always meets the draft it replaces.
  const files = [...all.filter((f) => !isRewrite(f)).sort(byName), ...all.filter(isRewrite).sort(byName)];

  const refused: { politician_id: string | null; topic_key: string | null; file: string; problems: string[] }[] = [];
  const refuse = (file: string, d: { politician_id?: unknown; topic_key?: unknown } | null, problems: string[]) =>
    refused.push({ politician_id: typeof d?.politician_id === 'string' ? d.politician_id : null, topic_key: typeof d?.topic_key === 'string' ? d.topic_key : null, file, problems });

  const clean = new Map<string, { draft: SummaryDraft; text: string; sources: string[]; sha256: string; cites: string[][]; findings: Finding[]; code: CodeRecord }>();
  const rewritten = new Set<string>();
  const replaced: string[] = [];
  let drafted = 0;
  for (const file of files) {
    let raw: unknown;
    try { raw = JSON.parse(readFileSync(join(draftsDir, file), 'utf8')); } catch (e) { refuse(file, null, [`file is not valid JSON: ${(e as Error).message}`]); drafted += 1; continue; }
    for (const item of Array.isArray(raw) ? raw : [raw]) {
      drafted += 1;
      const parsed = SummaryDraftSchema.safeParse(item);
      if (!parsed.success) {
        refuse(file, item as { politician_id?: unknown }, [`draft fails the schema: ${parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ')}`]);
        continue;
      }
      const draft = parsed.data;
      const person = people.get(draft.politician_id);
      if (!person) { refuse(file, draft, ['politician is not in people.json for this batch']); continue; }
      if (draft.topic_key !== profile.topic_key) { refuse(file, draft, [`draft is for ${draft.topic_key}, not ${profile.topic_key}`]); continue; }
      const rewrite = isRewrite(file);
      if (rewrite && rewritten.has(draft.politician_id)) { refuse(file, draft, ['more than one rewrite for this person; the first rewrite was kept']); continue; }
      if (!rewrite && clean.has(draft.politician_id)) { refuse(file, draft, ['more than one draft for this person; the first one was kept']); continue; }
      // A rewrite is used up when it is read, clean or not: the recipe allows one.
      if (rewrite) rewritten.add(draft.politician_id);
      let pf: ReturnType<typeof readPersonFindings>;
      try { pf = readPersonFindings(store, draft.politician_id); } catch (e) { refuse(file, draft, [`findings file is unreadable: ${(e as Error).message.slice(0, 120)}`]); continue; }
      const offered = new Set(person.finding_ids);
      const findings = (pf?.findings ?? []).filter((f) => offered.has(f.id));
      const codePath = join(profile.stage5, 'codes', `${draft.politician_id}.json`);
      let code: ReturnType<typeof Stage5CodeSchema.safeParse>;
      if (!existsSync(codePath)) { refuse(file, draft, ['code file unreadable: missing']); continue; }
      try { code = Stage5CodeSchema.safeParse(JSON.parse(readFileSync(codePath, 'utf8'))); } catch (e) { refuse(file, draft, [`code file unreadable: ${(e as Error).message.slice(0, 120)}`]); continue; }
      if (!code.success) { refuse(file, draft, ['code file unreadable: does not match the code schema']); continue; }
      const codeRecord = readCodeRecord(codePath);
      if ('error' in codeRecord) { refuse(file, draft, [`code file unreadable: ${codeRecord.error}`]); continue; }
      const problems = lintSummary(draft, { findings, code: code.data, sides: profile.sides ?? '' });
      if (problems.length) { refuse(file, draft, problems); continue; }
      const built = buildSummary(draft, findings);
      if (rewrite && clean.has(draft.politician_id)) replaced.push(draft.politician_id);
      clean.set(draft.politician_id, { draft, ...built, cites: draft.sentences.map((s) => [...new Set(s.cites)]), findings, code: codeRecord });
    }
  }

  // Render the checker prompts; a summary whose prompt cannot be built is refused, never half-written.
  const ids = [...clean.keys()].sort();
  const lines: string[] = [];
  const prompts: { id: string; text: string }[] = [];
  for (const id of ids) {
    const c = clean.get(id)!;
    const person = people.get(id)!;
    const summary = { politician_id: id, topic_key: profile.topic_key, text: c.text, sha256: c.sha256, sources: c.sources, cites: c.cites };
    try {
      prompts.push({ id, text: checkerPrompt(summary, c.findings, { outcome: person.outcome, ...(person.value != null ? { value: person.value } : {}) }, profile.sides, { personName: person.name, topicName: profile.topic_name, outFile: join(resolve(dir), 'claude-checks', `${id}.json`) }) });
    } catch (e) { refuse('(assembly)', c.draft, [`could not build the checker prompt: ${(e as Error).message}`]); continue; }
    lines.push(JSON.stringify({ ...summary, ...c.code }));
  }

  const checkerDir = join(dir, 'checker');
  rmSync(checkerDir, { recursive: true, force: true });
  mkdirSync(checkerDir, { recursive: true });
  for (const p of prompts) writeFileSync(join(checkerDir, `${p.id}.md`), p.text);
  writeFileSync(join(dir, 'summaries.jsonl'), lines.map((l) => `${l}\n`).join(''));
  writeFileSync(join(dir, 'lint-refused.jsonl'), refused.map((r) => `${JSON.stringify(r)}\n`).join(''));
  return { drafted, lintedOut: refused.length, toCheck: prompts.length, replaced };
}

export function main(argv: string[]): void {
  const { flags } = parseArgs(argv);
  const last = (k: string) => flags.get(k)?.[flags.get(k)!.length - 1];
  const profilePath = last('profile');
  const batch = last('batch');
  if (!profilePath || !batch) { console.error('usage: summary-assemble.ts --profile <topic-profile.json> --batch <name> [--store <dir>]'); process.exit(2); }
  const profile = JSON.parse(readFileSync(profilePath, 'utf8')) as Profile;
  const r = assemble({ profile, batch, store: last('store') });
  for (const id of r.replaced) console.log(`rewrite replaced the earlier draft for ${id}`);
  console.log(`drafted ${r.drafted}, linted out ${r.lintedOut}, to check ${r.toCheck}`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try { main(process.argv.slice(2)); } catch (e) { console.error((e as Error).message); process.exit(1); }
}
