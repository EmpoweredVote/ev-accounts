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
import { usableCoderDraft, type CoderSummary } from '../lib/stage5CoderSummary.js';
import { Stage5CodeSchema, type Stage5Code } from '../lib/stage5Code.js';
import type { SummaryCheck } from '../lib/stage5Summary.js';
import { REPO, STORE, coderSummariesDir, coderSummariesOn, displayName, instrumentIndex, instrumentTexts, parseArgs, readPersonFindings, readRosters } from './coder-io.js';

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
      politician_id: id, name: row?.full_name ? displayName(row.full_name) : '(name not on roster)', office: row?.office ?? '',
      level: row?.level ?? '', state: row?.state ?? '', code, findings,
    });
  }
  return { selected, skipped };
}

const GATE_MEANING: Record<string, string> = {
  'multi-subject': 'the bill covers several subjects, so this vote shows no position on guns',
  'near-unanimous': 'nearly everyone voted the same way, so this vote shows no position',
};

/** A gated vote, in words the writer can act on; '' when the finding is not gated. */
export function gateLabel(f: Pick<Finding, 'gate_by_topic'>): string {
  const kinds = [...new Set(Object.values(f.gate_by_topic ?? {}).filter((g) => g && g !== 'none'))];
  return kinds.length ? `gated: ${kinds.map((k) => `${k} (${GATE_MEANING[k] ?? 'this vote shows no position'})`).join('; ')}` : '';
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
    gateLabel(f),
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

/**
 * How much of a bill's stored text the writer and checker see. Measured 2026-11-22 over the 163 bills cited in the first
 * gun-policy summary batches: median 1,732 characters, longest 5,809, and a 1,500 cap cut 100 of them (61%), which left
 * true claims unprovable from the text shown. 6,000 cuts none of those and adds about 550 characters a bill.
 */
export const BILL_TEXT_CAP = 6000;

/**
 * Each cited bill's text, once, capped: the same words the coder read, so a summary can say what the bill does instead
 * of only what its title is about. Empty when no bill has stored text.
 */
/** A bill's plain subject lines, as the bill reading wrote them from the whole bill: `<stage5>/subjects.json`. */
export function readBillSubjects(stage5: string): Map<string, string[]> {
  const file = join(stage5, 'subjects.json');
  if (!existsSync(file)) return new Map();
  const raw = JSON.parse(readFileSync(file, 'utf8')) as Record<string, unknown>;
  const clean = (v: unknown) => (Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string' && !!x.trim() && !/\b(rungs?|ladder)\b/i.test(x)) : []);
  return new Map(Object.entries(raw).map(([k, v]) => [k, clean(v)] as [string, string[]]).filter(([, v]) => v.length > 0));
}

export const READING_LABEL = 'Our reading of the full bill:';
export const EXCERPT_LABEL = 'Stored excerpt of the bill:';

/**
 * What writer and checker are shown for one bill: the bill reading's subject lines, then the stored excerpt. The
 * excerpt was chosen to place people on the ladder, so it is often too short to describe the bill: in the 2026-11-22
 * Nevada trial 21 of 45 failed sentences made a claim the reading states and the excerpt (297 to 1,919 characters)
 * does not show. A subject line that names a rung is dropped by readBillSubjects.
 */
export function billTextWithReading(operativeText: string | undefined, subjects: string[] | undefined): string {
  const text = (operativeText ?? '').trim();
  if (!subjects?.length) return text;
  return `${READING_LABEL} ${subjects.join('; ')}.${text ? ` ${EXCERPT_LABEL} ${text}` : ''}`;
}

/** One bill's stored text on one line, capped; '' when there is none. */
export function cappedBillText(id: string, texts: Map<string, string> | undefined, cap = BILL_TEXT_CAP): string {
  const t = texts?.get(id)?.replace(/\s+/g, ' ').trim();
  if (!t) return '';
  return t.length > cap ? `${t.slice(0, cap)} … [cut at ${cap} of ${t.length} characters]` : t;
}

export function billTextBlock(ids: string[], texts: Map<string, string> | undefined, cap = BILL_TEXT_CAP): string {
  const seen = [...new Set(ids)].filter((id) => texts?.get(id)?.trim());
  if (!seen.length) return '';
  return `bill text (what each bill does; describe a bill from this, not from its title alone):\n${seen.map((id) => `- ${id}: ${cappedBillText(id, texts, cap)}`).join('\n')}`;
}

export function writerPersonBlock(p: Selected, o: Offered, sides: string | null, titles: Map<string, string>, texts?: Map<string, string>): string {
  const cited = new Set(p.code.finding_ids);
  const head = `### ${p.name} — politician_id ${p.politician_id}\n${[p.office, p.level, p.state].filter(Boolean).join(', ')}\n${seatLine(p.code, sides)}`;
  const note = o.left_out ? `\n(${o.left_out} older or lesser finding${o.left_out === 1 ? '' : 's'} not shown; cite only what is listed.)` : '';
  const bills = billTextBlock(o.offered.map((f) => f.instrument_id).filter((x): x is string => !!x), texts);
  return `${head}\nfindings (${o.offered.length}):\n${o.offered.map((f) => findingLine(f, titles, cited.has(f.id))).join('\n')}${note}${bills ? `\n${bills}` : ''}`;
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
  /** Each rendered sentence, from buildSummary. Required once a summary has an opening line with no marker. */
  sentences?: string[];
}

/** Sentences of a rendered summary: each ends in `[n, m]` then closing punctuation (the writer writes no brackets). */
/** Same key buildSummary numbers by: no #fragment, no trailing slash. */
function urlKeyOf(url: string): string {
  return url.replace(/#.*$/, '').replace(/\/+$/, '');
}

export function splitRendered(text: string): string[] {
  return text.split(/(?<=\[\d[\d, ]*\][.!?]+)\s+/).filter((s) => s.trim());
}

/** What one marker of one sentence rests on, read from the findings by code (never by the checker). */
export interface MarkerFacts { ref: number; findings: Finding[]; line: string; gatedOnly: boolean }

const SPONSOR_ACTS = new Set(['sponsor', 'author']);
const VOTE_ACTS = new Set(['yea', 'nay', 'abstain']);
const gatesOf = (f: Finding) => [...new Set(Object.values(f.gate_by_topic ?? {}).filter((g) => g && g !== 'none'))];

/**
 * The cited findings of one sentence, grouped by marker number, with the facts a script can read exactly: whether each
 * is a vote or a sponsorship, and whether it is gated. A checker left to find these itself caught a gated vote in 2 to
 * 5 of 5 runs on the same text (consistency test, 2026-11-22).
 */
export function markersOf(findings: Finding[], numberOf: (id: string) => number): MarkerFacts[] {
  const by = new Map<number, Finding[]>();
  for (const f of findings) { const n = numberOf(f.id); by.set(n, [...(by.get(n) ?? []), f]); }
  return [...by.entries()].map(([ref, fs]) => {
    const records = fs.filter((f) => f.kind === 'record');
    if (!records.length) return { ref, findings: fs, line: `[${ref}] statement: own words (a statement, not a vote or sponsorship).`, gatedOnly: false };
    const what = (f: Finding) => {
      const gate = gatesOf(f).length ? `, GATED: ${gatesOf(f).join(', ')}` : '';
      if (SPONSOR_ACTS.has(f.act ?? '')) return `sponsorship (${f.motion ?? f.act})${gate}`;
      if (VOTE_ACTS.has(f.act ?? '')) return `vote (${f.act}${f.against_bill ? ', against_bill: a vote AGAINST the bill' : ''})${gate}`;
      return `act (${f.act ?? 'not stated'})${gate}`;
    };
    const bills = [...new Set(records.map((f) => f.instrument_id).filter(Boolean))].sort().join(', ') || 'record';
    const gated = records.some((f) => gatesOf(f).length > 0);
    const gatedOnly = gated && records.every((f) => gatesOf(f).length > 0);
    const notes = [
      records.some((f) => SPONSOR_ACTS.has(f.act ?? '')) ? '' : 'No sponsorship finding.',
      records.some((f) => VOTE_ACTS.has(f.act ?? '')) ? '' : 'No vote finding.',
      !gated ? '' : gatedOnly ? 'Every finding cited for this marker is gated.' : 'A non-gated finding on the same bill is also cited.',
    ].filter(Boolean);
    return { ref, findings: fs, line: `[${ref}] ${bills}: ${[...new Set(records.map(what))].join('; ')}.${notes.length ? ` ${notes.join(' ')}` : ''}`, gatedOnly };
  });
}

/** The facts block of the checker prompt: one line per marker per sentence, then what the opening line may rest on. */
export function checkerFacts(markers: MarkerFacts[][]): string {
  const out: string[] = [];
  markers.forEach((ms, i) => { if (ms.length) out.push(`Sentence ${i}:`, ...ms.map((m) => `  ${m.line}`)); });
  const all = markers.flat();
  const gated = [...new Set(all.filter((m) => m.gatedOnly).map((m) => m.ref))].sort((a, b) => a - b);
  if (gated.length) {
    const free = [...new Set(all.map((m) => m.ref))].filter((r) => !gated.includes(r)).sort((a, b) => a - b);
    out.push(`Opening line: the lean may not rest on these markers, whose every finding is gated: ${gated.map((r) => `[${r}]`).join(', ')}. Markers that may count: ${free.map((r) => `[${r}]`).join(', ') || 'none'}.`);
  }
  return out.join('\n');
}

export function checkerPrompt(
  summary: SummaryForCheck,
  findings: Finding[],
  outcome: Outcome,
  sides: string | null,
  opts: { personName?: string; topicName?: string; family?: SummaryCheck['family']; template?: string; outFile?: string; titles?: Map<string, string>; texts?: Map<string, string> } = {},
): string {
  const sentences = summary.sentences ?? splitRendered(summary.text);
  if (sentences.length !== summary.cites.length) {
    throw new Error(`checkerPrompt: ${sentences.length} sentences in the text but cites for ${summary.cites.length}`);
  }
  const byId = new Map(findings.map((f) => [f.id, f]));
  for (const ids of summary.cites) for (const id of ids) {
    if (!byId.has(id)) throw new Error(`checkerPrompt: cited finding ${id} is not among the findings supplied`);
  }
  const fullFinding = (f: Finding) => [
    `  kind: ${f.kind}`, `  date: ${f.date} (${f.date_precision})`,
    f.act ? `  act: ${f.act}` : '', f.against_bill ? '  against_bill: true (a Yea here is a vote AGAINST the bill)' : '',
    f.local_record ? '  local_record: true' : '', f.instrument_id ? `  instrument: ${f.instrument_id}${opts.titles?.get(f.instrument_id) ? ` (${opts.titles.get(f.instrument_id)})` : ''}` : '',
    f.motion ? `  motion: ${f.motion}` : '',
    f.gate_by_topic ? `  gate: ${JSON.stringify(f.gate_by_topic)}` : '',
    `  url: ${f.url}`, `  note: ${f.note}`,
    f.passage ? `  passage: ${JSON.stringify(f.passage)}` : '',
  ].filter(Boolean).join('\n');
  const numberOfId = (id: string) => { const u = byId.get(id)?.url ?? ''; const k = urlKeyOf(u); return summary.sources.findIndex((x) => urlKeyOf(x) === k) + 1; };
  const citeLine = (s: string, ids: string[]) => (/\[\d[\d, ]*\]/.test(s)
    ? `cites findings: ${ids.map((id) => `[${numberOfId(id)}] ${id}`).join(', ')}`
    : 'opening line, no marker: judge it against every finding the summary cites');
  // A sentence with no marker is the opening line: it rests on every finding, so it gets no facts and no evidence of its own.
  const hasMarker = (sn: string) => /\[\d[\d, ]*\]/.test(sn);
  const markers = summary.cites.map((ids, i) => (hasMarker(sentences[i]) ? markersOf(ids.map((id) => byId.get(id)!), numberOfId) : []));
  // The evidence under the sentence it supports: the checker no longer matches three lists by a 64-character id.
  const evidence = sentences.map((sn, i) => {
    if (!markers[i].length) return `### Sentence ${i}\n\n> ${sn}\n\nThe opening line: judge it against every finding under the other sentences.`;
    const printed = new Set<string>();
    const blocks = markers[i].flatMap((m) => m.findings.map((f) => {
      const inst = f.instrument_id; const text = inst ? cappedBillText(inst, opts.texts) : '';
      const bill = !inst || !text ? '' : printed.has(inst) ? `\n  bill text of ${inst}: printed above` : `\n  bill text of ${inst}: ${text}`;
      if (inst) printed.add(inst);
      return `[${m.ref}] finding ${f.id}\n${fullFinding(f)}${bill}`;
    }));
    return `### Sentence ${i}\n\n> ${sn}\n\n${blocks.join('\n\n')}`;
  }).join('\n\n');
  const shown = `${summary.text}\n\nBy sentence (index from 0):\n${sentences.map((s, i) => `${i}. ${s}\n   ${citeLine(s, summary.cites[i])}`).join('\n')}`;
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
    FACTS: checkerFacts(markers),
    FINDINGS: evidence,
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
  if (!profilePath || !batch) { console.error('usage: summary-inputs.ts --profile <topic-profile.json> --batch <name> [--state xx] [--people a,b] [--max-findings 25] [--coder-summaries <dir>]'); process.exit(2); }
  const profile = JSON.parse(readFileSync(profilePath, 'utf8')) as { topic_key: string; topic_name?: string; stage5: string; sides: string | null };
  const subjects = readBillSubjects(profile.stage5);
  const max = Number(flag(flags, 'max-findings') ?? 25);
  const perFile = Number(flag(flags, 'per-file') ?? 10);
  const store = flag(flags, 'store') ?? STORE;
  const people = flag(flags, 'people')?.split(',').map((s) => s.trim()).filter(Boolean);
  const { selected, skipped } = selectPeople({ stage5: profile.stage5, store, topicKey: profile.topic_key, state: flag(flags, 'state'), people });
  if (selected.length === 0) { console.error('no one to write for; skipped:', JSON.stringify(skipped.slice(0, 5))); process.exit(1); }

  const out = join(profile.stage5, 'summaries', batch);
  mkdirSync(join(out, 'writer'), { recursive: true });
  mkdirSync(join(out, 'drafts'), { recursive: true });
  // --coder-summaries: people whose summary the coder wrote, for the code they still hold, need no writer.
  const coderDir = flag(flags, 'coder-summaries') ?? (coderSummariesOn(profile.stage5) ? coderSummariesDir(profile.stage5) : undefined);
  const coderDrafts: unknown[] = [];
  const fromCoder = new Set<string>();
  if (coderDir) {
    for (const p of selected) {
      const file = join(coderDir, `${p.politician_id}.json`);
      const got = usableCoderDraft(existsSync(file) ? (JSON.parse(readFileSync(file, 'utf8')) as CoderSummary) : undefined, p.code);
      if (got.draft) { coderDrafts.push(got.draft); fromCoder.add(p.politician_id); }
      else if (existsSync(file)) console.log(`  ${p.politician_id}: coder summary not used (${got.why}); the writer writes this one`);
    }
    if (coderDrafts.length) writeFileSync(join(out, 'drafts', 'coder.json'), JSON.stringify(coderDrafts, null, 2) + '\n');
  }
  const forWriter = selected.filter((p) => !fromCoder.has(p.politician_id));
  const index = existsSync(join(store, 'instruments')) ? instrumentIndex(store) : new Map<string, string>();
  const date = new Date().toISOString().slice(0, 10);
  const manifest: unknown[] = [];
  for (const p of selected.filter((x) => fromCoder.has(x.politician_id))) {
    manifest.push({ politician_id: p.politician_id, name: p.name, outcome: p.code.outcome, value: p.code.value ?? null,
      finding_ids: p.findings.map((f) => f.id), left_out: 0, writer_file: null, draft_file: 'drafts/coder.json' });
  }
  for (let i = 0, n = 1; i < forWriter.length; i += perFile, n++) {
    const group = forWriter.slice(i, i + perFile);
    const blocks = group.map((p) => {
      const o = capFindings(p.findings, p.code.finding_ids, max);
      const got = instrumentTexts(store, index, o.offered.map((f) => f.instrument_id).filter((x): x is string => !!x));
      const titles = new Map([...got].map(([k, v]) => [k, v.title]));
      const texts = new Map([...got].map(([k, v]) => [k, billTextWithReading(v.operative_text, subjects.get(k))]));
      manifest.push({
        politician_id: p.politician_id, name: p.name, outcome: p.code.outcome, value: p.code.value ?? null,
        finding_ids: o.offered.map((f) => f.id), left_out: o.left_out, writer_file: `writer/${n}.md`, draft_file: `drafts/${n}.json`,
      });
      return writerPersonBlock(p, o, profile.sides, titles, texts);
    });
    const prompt = writerPrompt(blocks, {
      topicKey: profile.topic_key, topicName: profile.topic_name ?? profile.topic_key, date, sides: profile.sides,
      outFile: join(out, 'drafts', `${n}.json`),
    });
    writeFileSync(join(out, 'writer', `${n}.md`), prompt);
  }
  writeFileSync(join(out, 'people.json'), JSON.stringify(manifest, null, 2) + '\n');
  console.log(`${selected.length} people, ${Math.ceil(forWriter.length / perFile)} writer prompts in ${out}; skipped ${skipped.length}${coderDir ? `; ${fromCoder.size} summaries taken from the coder` : ''}`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try { main(process.argv.slice(2)); } catch (e) { console.error((e as Error).message); process.exit(1); }
}
