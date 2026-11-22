/**
 * stage5Summary.ts — checked, cited position summaries (plan 2026-11-22-position-summaries, task 3).
 *
 * A summary is 1-5 sentences (ruling 2026-11-22: one piece of evidence is often enough): an optional opening line in
 * plain words with no marker, then sentences whose parts each carry citations `[n]` / `[n, m]` (ruling 2026-11-22,
 * runner: one paragraph about the person, acts grouped by what they did, not one bill per sentence). A writer produces a `SummaryDraft` (sentences with finding ids); `buildSummary` renders the text,
 * numbers the sources by first use, and hashes the exact text; `lintSummary` applies the mechanical rules only
 * (whether a sentence describes the right side needs judgement and is left to the checkers). Outside-model
 * checks are `SummaryCheck`s; `summaryVerdict` combines them for one text hash. Pure.
 */
import { z } from 'zod';
import type { Finding } from './sourceStore.js';
import type { Stage5Code } from './stage5Code.js';
import { namesParty, shownSha256 } from './stage5QuoteCheck.js';

export const SummaryDraftSchema = z.object({
  politician_id: z.string().min(1),
  topic_key: z.string().min(1),
  /**
   * A sentence is either `{text, cites}` (one marker set at the end), `{parts: [{text, cites}]}` (a marker set after
   * each part, so one sentence can group several acts), or the opening line `{text, lead: true}` (no marker; it rests
   * on every finding the summary cites). Which shape is legal where is lintSummary's job, not the schema's.
   */
  sentences: z.array(z.object({
    text: z.string().optional(),
    cites: z.array(z.string()).optional(),
    parts: z.array(z.object({ text: z.string(), cites: z.array(z.string()) })).optional(),
    lead: z.boolean().optional(),
  })),
});
export type SummaryDraft = z.infer<typeof SummaryDraftSchema>;

export const SummaryCheckSchema = z.object({
  politician_id: z.string().min(1),
  topic_key: z.string().min(1),
  text_sha256: z.string().min(1),
  checker: z.string().min(1),
  family: z.enum(['claude', 'gpt', 'gemini']),
  sentences: z.array(z.object({ index: z.number().int().min(0), verdict: z.enum(['pass', 'fail']), reason: z.string() })),
  verdict: z.enum(['pass', 'fail']),
  /** ISO timestamp with a zone; compared as a time, never as text. */
  at: z.string().datetime({ offset: true }),
}).refine((c) => c.verdict !== 'pass' || c.sentences.every((x) => x.verdict !== 'fail'), {
  message: 'verdict pass is invalid when any sentence fails',
  path: ['verdict'],
});
export type SummaryCheck = z.infer<typeof SummaryCheckSchema>;

/** Two findings are on "the same URL" after trimming a trailing slash and a #fragment. */
function urlKey(url: string): string {
  return url.replace(/#.*$/, '').replace(/\/+$/, '');
}

const CLOSING = /([.!?]+)$/;

/** Split a sentence into its words and its closing punctuation ('.' when it has none). */
function splitClosing(text: string): { body: string; close: string } {
  const t = text.trim();
  const m = CLOSING.exec(t);
  return m ? { body: t.slice(0, m.index).trimEnd(), close: m[1] } : { body: t, close: '.' };
}

type DraftSentence = SummaryDraft['sentences'][number];

/** The sentence's parts, whatever shape it was written in. The lead is one part with no cites. */
function partsOf(sn: DraftSentence): { text: string; cites: string[] }[] {
  if (sn.parts) return sn.parts;
  return [{ text: sn.text ?? '', cites: sn.lead ? [] : (sn.cites ?? []) }];
}

/** Every finding id a sentence cites, in order, duplicates removed. */
function citesOf(sn: DraftSentence): string[] {
  return [...new Set(partsOf(sn).flatMap((p) => p.cites))];
}

/**
 * Render the draft: numbers by first use of a URL across the sentences in order; within a part, numbers in the
 * order it cites them, duplicates removed. A part's marker goes before its closing punctuation (the last part) or
 * before a trailing comma, semicolon or colon (any other part). The lead line carries no marker. `sentences` is
 * each rendered sentence; `cites` is each sentence's finding ids, the lead's being every id the summary cites.
 * `sha256` is of the exact UTF-8 text, no normalisation. Throws on a cite that is not among `findings`.
 */
export function buildSummary(draft: SummaryDraft, findings: Finding[]): { text: string; sources: string[]; sha256: string; sentences: string[]; cites: string[][] } {
  const byId = new Map(findings.map((f) => [f.id, f]));
  const numberOf = new Map<string, number>(); // urlKey → n
  const sources: string[] = [];
  const number = (id: string): number => {
    const f = byId.get(id);
    if (!f) throw new Error(`buildSummary: cite ${id} is not among the findings supplied`);
    const k = urlKey(f.url);
    let n = numberOf.get(k);
    if (n === undefined) { n = sources.length + 1; numberOf.set(k, n); sources.push(f.url); }
    return n;
  };
  const sentences: string[] = [];
  for (const sn of draft.sentences) {
    if (sn.lead) { const { body, close } = splitClosing(sn.text ?? ''); sentences.push(`${body}${close}`); continue; }
    const ps = partsOf(sn);
    const out: string[] = [];
    ps.forEach((p, i) => {
      const nums: number[] = [];
      for (const id of p.cites) { const n = number(id); if (!nums.includes(n)) nums.push(n); }
      const last = i === ps.length - 1;
      const { body, close } = last ? splitClosing(p.text) : splitJoin(p.text);
      out.push(`${body} [${nums.join(', ')}]${close}`);
    });
    sentences.push(out.join(' ').replace(/ ([,;:])/g, '$1'));
  }
  const all = [...new Set(draft.sentences.filter((x) => !x.lead).flatMap(citesOf))];
  const cites = draft.sentences.map((x) => (x.lead ? all : citesOf(x)));
  const text = sentences.join(' ');
  return { text, sources, sha256: shownSha256(text), sentences, cites };
}

/** Split a non-final part into its words and a trailing `,` `;` or `:` ('' when it has none). */
function splitJoin(text: string): { body: string; close: string } {
  const t = text.trim();
  const m = /([,;:])$/.exec(t);
  return m ? { body: t.slice(0, m.index).trimEnd(), close: m[1] } : { body: t, close: '' };
}

const ABBREVIATIONS = new Set(['u.s.', 'sen.', 'rep.', 'gov.', 'mr.', 'mrs.', 'ms.', 'dr.', 'st.', 'jr.', 'no.', 'e.g.', 'i.e.']);

/** True when the text holds a sentence break inside it: [.!?] then whitespace then a capital, not after an abbreviation. */
function holdsMoreThanOneSentence(text: string): boolean {
  const re = /[.!?]+(?=\s+[A-Z])/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(text))) {
    const raw = /(\S+)$/.exec(text.slice(0, m.index + m[0].length))?.[1] ?? '';
    if (/^[A-Z]\.$/.test(raw)) continue; // a middle initial ("Danica A. Roem"), not a sentence end
    if (!ABBREVIATIONS.has(raw.toLowerCase())) return true;
  }
  return false;
}

const LADDER_WORDS = /\b(rungs?|ladder)\b/i;
const RUNG_NUMBER = /\b(?:option|position|level|step|chair)\s+[1-5]\b/i;
const REPEAT_WORDS: { re: RegExp; label: string; min: number }[] = [
  { re: /\boften\b/i, label: 'often', min: 3 },
  { re: /\bconsistently\b/i, label: 'consistently', min: 3 },
  { re: /\brepeatedly\b/i, label: 'repeatedly', min: 3 },
  { re: /\bmore than once\b/i, label: 'more than once', min: 2 },
];

/** Mechanical problems with a draft, in plain words; empty = clean. */
export function lintSummary(draft: SummaryDraft, ctx: { findings: Finding[]; code: Stage5Code; sides: string }): string[] {
  const problems: string[] = [];
  const ids = new Set(ctx.findings.map((f) => f.id));
  const n = draft.sentences.length;
  if (n < 1 || n > 5) problems.push(`a summary has 1-5 sentences; this has ${n}`);
  if (n >= 2 && !draft.sentences[0].lead) {
    problems.push('a summary of two or more sentences opens with a plain-direction line ("lead": true): which way the person leans, or that the record is mixed');
  }
  const everyCite = new Set(draft.sentences.filter((x) => !x.lead).flatMap(citesOf));
  draft.sentences.forEach((s, i) => {
    const at = `sentence ${i + 1}`;
    if (s.parts && (s.text !== undefined || s.cites !== undefined)) problems.push(`${at}: give either text or parts, not both`);
    if (s.lead) {
      if (i !== 0) problems.push(`${at}: the opening line must be the first sentence`);
      if (n < 2) problems.push(`${at}: the opening line needs at least one cited sentence after it`);
      if (s.cites?.length || s.parts) problems.push(`${at}: the opening line carries no cites and no parts; it rests on every sentence after it`);
    }
    const ps = partsOf(s);
    const text = ps.map((p) => p.text.trim()).join(' ');
    if (!text) problems.push(`${at}: empty`);
    if (holdsMoreThanOneSentence(text)) problems.push(`${at}: holds more than one sentence; make each sentence its own entry`);
    if (/\[\d[\d,\s]*\]/.test(text)) problems.push(`${at}: write no citation markers in the text; list finding ids in cites`);
    if (!s.lead) {
      ps.forEach((p, j) => {
        const where = ps.length > 1 ? `${at}, part ${j + 1}` : at;
        if (!p.text.trim() && ps.length > 1) problems.push(`${where}: empty`);
        if (p.cites.length === 0) problems.push(`${where}: no citation`);
        for (const id of p.cites) if (!ids.has(id)) problems.push(`${where}: cites ${id}, which is not one of this person's findings`);
      });
    }
    const m = LADDER_WORDS.exec(text) ?? RUNG_NUMBER.exec(text);
    if (m) problems.push(`${at}: uses ladder wording ("${m[0]}")`);
    if (namesParty(text)) problems.push(`${at}: names a party`);
    const distinct = s.lead ? everyCite.size : new Set(citesOf(s)).size;
    for (const r of REPEAT_WORDS) {
      if (r.re.test(text) && distinct < r.min) {
        problems.push(`${at}: says "${r.label}" with ${distinct} distinct cited finding${distinct === 1 ? '' : 's'}; needs ${r.min}`);
      }
    }
  });
  return problems;
}

/**
 * Combine checks for one text. Only checks on `sha256` count, and every one of them counts: a check fails when its
 * verdict or any sentence verdict is 'fail'; a re-run never clears an earlier fail (a rewrite has a new sha). Any fail
 * holds, a claude fail fails outright, and a required family with no check holds.
 */
export function summaryVerdict(checks: SummaryCheck[], sha256: string, required: SummaryCheck['family'][]): 'passed' | 'held' | 'failed' {
  const mine = checks.filter((c) => c.text_sha256 === sha256);
  const failed = (c: SummaryCheck) => c.verdict === 'fail' || c.sentences.some((x) => x.verdict === 'fail');
  if (mine.some((c) => c.family === 'claude' && failed(c))) return 'failed';
  if (mine.some(failed)) return 'held';
  for (const fam of required) if (!mine.some((c) => c.family === fam)) return 'held';
  return 'passed';
}

/** Share of items on which every checker agreed; 0 for none. */
export function agreementRate(verdicts: { all_agree: boolean }[]): number {
  return verdicts.length === 0 ? 0 : verdicts.filter((v) => v.all_agree).length / verdicts.length;
}
