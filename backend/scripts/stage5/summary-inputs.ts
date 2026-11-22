/**
 * summary-inputs.ts — position summaries, step 1: the writer prompts and the checker prompt
 * (plan 2026-11-22-position-summaries, task 5).
 *
 *   npx tsx scripts/stage5/summary-inputs.ts --profile <stage5>/topic-profile.json --batch <name>
 *     [--state <xx|federal>] [--people <id,id>] [--max-findings 25] [--per-file 10] [--store <source-store dir>]
 *
 * Reads `<stage5>/codes/<politician_id>.json` (flat), keeps people coded `seated` or `doesnt-fit` that have at least
 * one finding on the topic in the source store, and writes into `<stage5>/summaries/<batch>/`:
 *   writer/<n>.md   a writer prompt for ~10 people (the template + findings; the outcome, never the rung text)
 *   people.json     per person: id, name, outcome, value, finding ids offered, how many were left out
 * A writer returns `SummaryDraft[]` to `<batch>/drafts/<n>.json`. The checker prompt is built by `checkerPrompt()`,
 * which the assembler (task 6) calls once it has rendered a summary; this tool does not write checker prompts.
 */
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { Finding } from '../lib/sourceStore.js';
import { fillTemplate } from '../lib/stage5Template.js';
import { Stage5CodeSchema, type Stage5Code } from '../lib/stage5Code.js';
import type { SummaryCheck } from '../lib/stage5Summary.js';
import { REPO, STORE, instrumentIndex, instrumentTexts, parseArgs, readPersonFindings, readRosters } from './coder-io.js';

const TEMPLATES = join(REPO, '.claude/skills/season-topic-prep/templates');
export const WRITER_TEMPLATE = join(TEMPLATES, 'stage5-summary-writer.md');
export const CHECKER_TEMPLATE = join(TEMPLATES, 'stage5-summary-checker.md');

export type Outcome = { outcome: 'seated' | 'doesnt-fit'; value?: number };

export interface Selected {
  politician_id: string;
  name: string;
  office: string;
  level: string;
  state: string;
  code: Stage5Code;
  /** Every finding on the topic, as stored. */
  findings: Finding[];
}

export interface Offered {
  offered: Finding[];
  left_out: number;
}

/** Date as a sortable key: the stored date text, '' when unknown (sorts oldest). */
const dateKey = (f: Finding) => f.date ?? '';

/**
 * Cap a person's findings. Kept first: findings the coder cited, then records before own words, then newest first.
 * The count left out is returned so the prompt can say so.
 */
export function capFindings(findings: Finding[], citedIds: string[], max: number): Offered {
  const cited = new Set(citedIds);
  const ranked = [...findings].sort((a, b) =>
    Number(cited.has(b.id)) - Number(cited.has(a.id))
    || Number(b.kind === 'record') - Number(a.kind === 'record')
    || dateKey(b).localeCompare(dateKey(a))
    || a.id.localeCompare(b.id));
  const offered = ranked.slice(0, max);
  return { offered, left_out: ranked.length - offered.length };
}

export interface SelectOpts {
  stage5: string;
  store: string;
  topicKey: string;
  state?: string;
  people?: string[];
}

/** People to write for: coded seated or doesnt-fit, with at least one finding on the topic. */
export function selectPeople(o: SelectOpts): { selected: Selected[]; skipped: { id: string; why: string }[] } {
  const rosterPath = join(o.stage5, 'roster.tsv');
  const roster = existsSync(rosterPath) ? readRosters([rosterPath]) : new Map();
  const codesDir = join(o.stage5, 'codes');
  const ids = o.people?.length ? o.people : readdirSync(codesDir).filter((f) => f.endsWith('.json')).map((f) => f.slice(0, -5));
  const selected: Selected[] = [];
  const skipped: { id: string; why: string }[] = [];
  for (const id of ids.sort()) {
    const file = join(codesDir, `${id}.json`);
    if (!existsSync(file)) { skipped.push({ id, why: 'no code file' }); continue; }
    const parsed = Stage5CodeSchema.safeParse(JSON.parse(readFileSync(file, 'utf8')));
    if (!parsed.success) { skipped.push({ id, why: 'code does not parse' }); continue; }
    const code = parsed.data;
    if (code.topic_key !== o.topicKey) { skipped.push({ id, why: `code is for ${code.topic_key}` }); continue; }
    if (code.outcome === 'no-stance') { skipped.push({ id, why: 'no-stance' }); continue; }
    const row = roster.get(id);
    if (o.state) {
      const want = o.state.toLowerCase();
      const ok = want === 'federal' ? row?.level === 'federal' : (row?.state ?? '').toLowerCase() === want;
      if (!ok) { skipped.push({ id, why: 'outside --state' }); continue; }
    }
    const pf = readPersonFindings(o.store, id);
    const findings = (pf?.findings ?? []).filter((f) => f.topic_keys.includes(o.topicKey));
    if (findings.length === 0) { skipped.push({ id, why: 'no finding on the topic' }); continue; }
    selected.push({
      politician_id: id, name: row?.full_name ?? '(name not on roster)', office: row?.office ?? '',
      level: row?.level ?? '', state: row?.state ?? '', code, findings,
    });
  }
  return { selected, skipped };
}

/** One finding as the writer sees it. */
function findingLine(f: Finding, titles: Map<string, string>, citedByCoder: boolean): string {
  const bits = [
    `id: ${f.id}`, `kind: ${f.kind}`, `date: ${f.date}`,
    f.act ? `act: ${f.act}` : '',
    f.against_bill ? 'against_bill: true (a Yea here is a vote AGAINST the bill)' : '',
    f.local_record ? 'local_record: true' : '',
    f.instrument_id ? `instrument: ${f.instrument_id}${titles.get(f.instrument_id) ? ` (${titles.get(f.instrument_id)})` : ''}` : '',
    f.motion ? `motion: ${f.motion}` : '',
    citedByCoder ? 'coder-cited' : '',
  ].filter(Boolean);
  const passage = f.passage ? `\n    passage: ${JSON.stringify(f.passage)}` : '';
  return `- ${bits.join(' | ')}\n    note: ${f.note}${passage}\n    url: ${f.url}`;
}

/** The seat line: the outcome and side only, never the rung's words. */
export function seatLine(code: Pick<Stage5Code, 'outcome' | 'value'>, sides: string | null): string {
  if (code.outcome !== 'seated') return 'seat: none (doesnt-fit); nothing in the findings fits one position';
  const side = sideOf(code.value, sides);
  return `seat: seated, value ${code.value}${side ? `; the person's side is ${side}, so nothing may point to the other side` : ''}`;
}

/** The side of "1,2,3/4,5" a value is on, as the group text ("1,2,3"); null with no sides or no match. */
export function sideOf(value: number | undefined, sides: string | null): string | null {
  if (value === undefined || !sides) return null;
  return sides.split('/').find((g) => g.split(',').some((n) => Number(n) === value || Number(n) === Math.round(value))) ?? null;
}

export function writerPersonBlock(p: Selected, o: Offered, sides: string | null, titles: Map<string, string>): string {
  const cited = new Set(p.code.finding_ids);
  const head = `### ${p.name} — politician_id ${p.politician_id}\n${[p.office, p.level, p.state].filter(Boolean).join(', ')}\n${seatLine(p.code, sides)}`;
  const note = o.left_out ? `\n(${o.left_out} older or lesser finding${o.left_out === 1 ? '' : 's'} not shown; cite only what is listed.)` : '';
  return `${head}\nfindings (${o.offered.length}):\n${o.offered.map((f) => findingLine(f, titles, cited.has(f.id))).join('\n')}${note}`;
}

export interface WriterOpts {
  topicKey: string;
  topicName: string;
  date: string;
  sides: string | null;
  outFile: string;
  template?: string;
}

/** The filled writer prompt for a group of people. Throws (TemplateFillError) on an unfilled slot. */
export function writerPrompt(blocks: string[], o: WriterOpts): string {
  return fillTemplate(o.template ?? readFileSync(WRITER_TEMPLATE, 'utf8'), {
    TOPIC_KEY: o.topicKey, TOPIC_NAME: o.topicName, DATE: o.date,
    SIDES: o.sides ?? 'none ruled for this topic', PEOPLE: blocks.join('\n\n'), OUT_FILE: o.outFile,
  });
}

/** The summary as the assembler renders it. `cites[i]` are the finding ids sentence i cites. */
export interface SummaryForCheck {
  politician_id: string;
  topic_key: string;
  text: string;
  sha256: string;
  sources: string[];
  cites: string[][];
}

/** Sentences of a rendered summary: each ends in `[n, m]` then closing punctuation (the writer writes no brackets). */
export function splitRendered(text: string): string[] {
  return text.split(/(?<=\[\d[\d, ]*\][.!?]+)\s+/).filter((s) => s.trim());
}

export function checkerPrompt(
  summary: SummaryForCheck,
  findings: Finding[],
  outcome: Outcome,
  sides: string | null,
  opts: { personName?: string; topicName?: string; family?: SummaryCheck['family']; template?: string; outFile?: string } = {},
): string {
  const sentences = splitRendered(summary.text);
  if (sentences.length !== summary.cites.length) {
    throw new Error(`checkerPrompt: ${sentences.length} sentences in the text but cites for ${summary.cites.length}`);
  }
  const byId = new Map(findings.map((f) => [f.id, f]));
  const order: string[] = [];
  for (const ids of summary.cites) for (const id of ids) if (!order.includes(id)) order.push(id);
  const full = order.map((id) => {
    const f = byId.get(id);
    if (!f) throw new Error(`checkerPrompt: cited finding ${id} is not among the findings supplied`);
    const lines = [
      `finding ${id}`, `  kind: ${f.kind}`, `  date: ${f.date} (${f.date_precision})`,
      f.act ? `  act: ${f.act}` : '', f.against_bill ? '  against_bill: true (a Yea here is a vote AGAINST the bill)' : '',
      f.local_record ? '  local_record: true' : '', f.instrument_id ? `  instrument: ${f.instrument_id}` : '',
      f.motion ? `  motion: ${f.motion}` : '',
      f.gate_by_topic ? `  gate: ${JSON.stringify(f.gate_by_topic)}` : '',
      `  url: ${f.url}`, `  note: ${f.note}`,
      f.passage ? `  passage: ${JSON.stringify(f.passage)}` : '',
    ].filter(Boolean);
    return lines.join('\n');
  });
  const shown = `${summary.text}\n\nBy sentence (index from 0):\n${sentences.map((s, i) => `${i}. ${s}\n   cites findings: ${summary.cites[i].join(', ')}`).join('\n')}`;
  const outcomeText = outcome.outcome === 'seated'
    ? `seated, value ${outcome.value}${sideOf(outcome.value, sides) ? `; the person's side is ${sideOf(outcome.value, sides)}` : ''}`
    : 'doesnt-fit: on-topic evidence that fits no single position; no seat';
  return fillTemplate(opts.template ?? readFileSync(CHECKER_TEMPLATE, 'utf8'), {
    TOPIC_KEY: summary.topic_key,
    TOPIC_NAME: opts.topicName ?? summary.topic_key,
    PERSON: opts.personName ?? summary.politician_id,
    SUMMARY: shown,
    REFERENCES: summary.sources.map((u, i) => `[${i + 1}] ${u}`).join('\n'),
    OUTCOME: outcomeText,
    FINDINGS: full.join('\n\n'),
    SIDES: sides ?? 'none ruled for this topic',
    POLITICIAN_ID: summary.politician_id,
    TEXT_SHA256: summary.sha256,
    FAMILY: opts.family ?? 'claude',
    OUT_FILE: opts.outFile ?? '(none given: reply with the JSON only)',
  });
}

// ---------- CLI ----------

function flag(flags: Map<string, string[]>, k: string): string | undefined {
  return flags.get(k)?.[flags.get(k)!.length - 1];
}

export function main(argv: string[]): void {
  const { flags } = parseArgs(argv);
  const profilePath = flag(flags, 'profile');
  const batch = flag(flags, 'batch');
  if (!profilePath || !batch) { console.error('usage: summary-inputs.ts --profile <topic-profile.json> --batch <name> [--state xx] [--people a,b] [--max-findings 25]'); process.exit(2); }
  const profile = JSON.parse(readFileSync(profilePath, 'utf8')) as { topic_key: string; topic_name?: string; stage5: string; sides: string | null };
  const max = Number(flag(flags, 'max-findings') ?? 25);
  const perFile = Number(flag(flags, 'per-file') ?? 10);
  const store = flag(flags, 'store') ?? STORE;
  const people = flag(flags, 'people')?.split(',').map((s) => s.trim()).filter(Boolean);
  const { selected, skipped } = selectPeople({ stage5: profile.stage5, store, topicKey: profile.topic_key, state: flag(flags, 'state'), people });
  if (selected.length === 0) { console.error('no one to write for; skipped:', JSON.stringify(skipped.slice(0, 5))); process.exit(1); }

  const out = join(profile.stage5, 'summaries', batch);
  mkdirSync(join(out, 'writer'), { recursive: true });
  mkdirSync(join(out, 'drafts'), { recursive: true });
  const index = existsSync(join(store, 'instruments')) ? instrumentIndex(store) : new Map<string, string>();
  const date = new Date().toISOString().slice(0, 10);
  const manifest: unknown[] = [];
  for (let i = 0, n = 1; i < selected.length; i += perFile, n++) {
    const group = selected.slice(i, i + perFile);
    const blocks = group.map((p) => {
      const o = capFindings(p.findings, p.code.finding_ids, max);
      const titles = new Map([...instrumentTexts(store, index, o.offered.map((f) => f.instrument_id).filter((x): x is string => !!x))].map(([k, v]) => [k, v.title]));
      manifest.push({
        politician_id: p.politician_id, name: p.name, outcome: p.code.outcome, value: p.code.value ?? null,
        finding_ids: o.offered.map((f) => f.id), left_out: o.left_out, writer_file: `writer/${n}.md`, draft_file: `drafts/${n}.json`,
      });
      return writerPersonBlock(p, o, profile.sides, titles);
    });
    const prompt = writerPrompt(blocks, {
      topicKey: profile.topic_key, topicName: profile.topic_name ?? profile.topic_key, date, sides: profile.sides,
      outFile: join(out, 'drafts', `${n}.json`),
    });
    writeFileSync(join(out, 'writer', `${n}.md`), prompt);
  }
  writeFileSync(join(out, 'people.json'), JSON.stringify(manifest, null, 2) + '\n');
  console.log(`${selected.length} people, ${Math.ceil(selected.length / perFile)} writer prompts in ${out}; skipped ${skipped.length}`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try { main(process.argv.slice(2)); } catch (e) { console.error((e as Error).message); process.exit(1); }
}
