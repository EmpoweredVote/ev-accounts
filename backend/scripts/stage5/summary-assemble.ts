/**
 * summary-assemble.ts — position summaries, step 2: turn the writers' drafts into rendered summaries
 * (plan 2026-11-22-position-summaries, task 6).
 *
 *   npx tsx scripts/stage5/summary-assemble.ts --profile <stage5>/topic-profile.json --batch <name> [--store <dir>]
 *
 * Reads `<stage5>/summaries/<batch>/people.json` and every `drafts/*.json` (one SummaryDraft or an array of them).
 * Writes, beside them:
 *   summaries.jsonl     { politician_id, topic_key, text, sha256, sources, cites } per clean draft (cites: one id list per sentence)
 *   lint-refused.jsonl  { politician_id, topic_key, file, problems } per draft that is bad, unknown, or unreadable
 *   checker/<n>.md      one checker prompt per summary, numbered in politician_id order
 * Exit 0 always; it prints the counts. A bad draft never stops the run.
 */
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
export interface AssembleResult { drafted: number; lintedOut: number; toCheck: number }

export function assemble(o: { profile: Profile; batch: string; store?: string }): AssembleResult {
  const { profile } = o;
  const store = o.store ?? STORE;
  const dir = join(profile.stage5, 'summaries', o.batch);
  const people = new Map((JSON.parse(readFileSync(join(dir, 'people.json'), 'utf8')) as PersonRow[]).map((p) => [p.politician_id, p]));
  const draftsDir = join(dir, 'drafts');
  const files = existsSync(draftsDir) ? readdirSync(draftsDir).filter((f) => f.endsWith('.json')).sort((a, b) => a.localeCompare(b, undefined, { numeric: true })) : [];

  const refused: { politician_id: string | null; topic_key: string | null; file: string; problems: string[] }[] = [];
  const refuse = (file: string, d: { politician_id?: unknown; topic_key?: unknown } | null, problems: string[]) =>
    refused.push({ politician_id: typeof d?.politician_id === 'string' ? d.politician_id : null, topic_key: typeof d?.topic_key === 'string' ? d.topic_key : null, file, problems });

  const clean = new Map<string, { draft: SummaryDraft; text: string; sources: string[]; sha256: string; cites: string[][]; findings: Finding[] }>();
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
      if (clean.has(draft.politician_id)) { refuse(file, draft, ['more than one draft for this person; the first one was kept']); continue; }
      let pf: ReturnType<typeof readPersonFindings>;
      try { pf = readPersonFindings(store, draft.politician_id); } catch (e) { refuse(file, draft, [`findings file is unreadable: ${(e as Error).message.slice(0, 120)}`]); continue; }
      const offered = new Set(person.finding_ids);
      const findings = (pf?.findings ?? []).filter((f) => offered.has(f.id));
      const codePath = join(profile.stage5, 'codes', `${draft.politician_id}.json`);
      let code: ReturnType<typeof Stage5CodeSchema.safeParse>;
      if (!existsSync(codePath)) { refuse(file, draft, ['code file unreadable: missing']); continue; }
      try { code = Stage5CodeSchema.safeParse(JSON.parse(readFileSync(codePath, 'utf8'))); } catch (e) { refuse(file, draft, [`code file unreadable: ${(e as Error).message.slice(0, 120)}`]); continue; }
      if (!code.success) { refuse(file, draft, ['code file unreadable: does not match the code schema']); continue; }
      const problems = lintSummary(draft, { findings, code: code.data, sides: profile.sides ?? '' });
      if (problems.length) { refuse(file, draft, problems); continue; }
      const built = buildSummary(draft, findings);
      clean.set(draft.politician_id, { draft, ...built, cites: draft.sentences.map((s) => [...new Set(s.cites)]), findings });
    }
  }

  // Render the checker prompts; a summary whose prompt cannot be built is refused, never half-written.
  const ids = [...clean.keys()].sort();
  const lines: string[] = [];
  const prompts: string[] = [];
  for (const id of ids) {
    const c = clean.get(id)!;
    const person = people.get(id)!;
    const summary = { politician_id: id, topic_key: profile.topic_key, text: c.text, sha256: c.sha256, sources: c.sources, cites: c.cites };
    try {
      prompts.push(checkerPrompt(summary, c.findings, { outcome: person.outcome, ...(person.value != null ? { value: person.value } : {}) }, profile.sides, { personName: person.name, topicName: profile.topic_name, outFile: join(resolve(dir), 'claude-checks', `${prompts.length + 1}.json`) }));
    } catch (e) { refuse('(assembly)', c.draft, [`could not build the checker prompt: ${(e as Error).message}`]); continue; }
    lines.push(JSON.stringify(summary));
  }

  const checkerDir = join(dir, 'checker');
  rmSync(checkerDir, { recursive: true, force: true });
  mkdirSync(checkerDir, { recursive: true });
  prompts.forEach((p, i) => writeFileSync(join(checkerDir, `${i + 1}.md`), p));
  writeFileSync(join(dir, 'summaries.jsonl'), lines.map((l) => `${l}\n`).join(''));
  writeFileSync(join(dir, 'lint-refused.jsonl'), refused.map((r) => `${JSON.stringify(r)}\n`).join(''));
  return { drafted, lintedOut: refused.length, toCheck: prompts.length };
}

export function main(argv: string[]): void {
  const { flags } = parseArgs(argv);
  const last = (k: string) => flags.get(k)?.[flags.get(k)!.length - 1];
  const profilePath = last('profile');
  const batch = last('batch');
  if (!profilePath || !batch) { console.error('usage: summary-assemble.ts --profile <topic-profile.json> --batch <name> [--store <dir>]'); process.exit(2); }
  const profile = JSON.parse(readFileSync(profilePath, 'utf8')) as Profile;
  const r = assemble({ profile, batch, store: last('store') });
  console.log(`drafted ${r.drafted}, linted out ${r.lintedOut}, to check ${r.toCheck}`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try { main(process.argv.slice(2)); } catch (e) { console.error((e as Error).message); process.exit(1); }
}
