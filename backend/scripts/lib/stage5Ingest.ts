/**
 * stage5Ingest.ts — Stage 5 coding: what happens to a coder's batch file before any code counts.
 *
 * A coder writes ONE file for its batch (`{ batch, codes: [...] }`). `finalizeCode` turns each entry into a
 * full `Stage5Code`: the season fields come from the run's coder config (never from the coder), `coded_at` is
 * the moment of ingest, and `evidence_basis` is computed from the kinds of the findings the code cites
 * (`basisOf`), so it can never disagree with them. `checkAtIngest` then runs `checkCode` plus three text
 * checks that the stance gate would otherwise raise much later, after the evidence and gate work is spent:
 *
 * 1. a bill named in the reasoning that is not in this person's on-topic findings (one coder copied a list of
 *    Yes votes onto four people in Georgia; a ruling's example bill is never the person's own record);
 * 2. an annex or ruling label (S3, Q2, C2, H12, R5-AZ …) in the reasoning — voters read it, and the gate
 *    reads S1-S8 as Senate bills (Michigan 85 trims, Georgia 4);
 * 3. quote marks round words found in no cited finding's passage, no quoted span of its note and no cited
 *    bill's text or title (the gate's `quote-not-in-snippet`, caught at coding time).
 *
 * These checks are deliberately NOT in `checkCode`: that one runs again at write time on every code already
 * coded, and codes approved before these rules existed must still write. Pure.
 */
import { basisOf, checkCode, type Stage5Code } from './stage5Code.js';
import type { Finding, PersonFindings } from './sourceStore.js';
import { canonicalizeInstrumentId, extractInstrumentIdentifiers, extractQuotedPhrases } from './stanceGate.js';
import { normalizeText } from '../../src/lib/researchVerifier.js';

/** The fields a run fixes once, in its coder config; the coder never writes them. */
export interface CodeHeader {
  topic_key: string;
  season: number;
  season_id: string;
  revision_id: string;
  codebook: string;
  coded_by?: string;
}

/** What a bill looks like to the text checks: the store's title and operative text. */
export interface InstrumentText {
  title?: string;
  operative_text?: string;
}

export interface IngestContext {
  /** Instrument id → its title and operative text (only the ones this person's findings name are read). */
  instruments: ReadonlyMap<string, InstrumentText>;
  /** The served rung texts (and the question): a quote of the ladder is not a claim about the person. */
  rungTexts: readonly string[];
}

/** A store instrument id: `GA-HB-1324-2025`, `MA-H-4135-AMDT-4-2023`, `VA-HB-5020-SP1-2020`. */
export const STORE_ID_RE = /\b[A-Z]{2}-[A-Z]+(?:-[A-Z0-9]+)*-(?:19|20)\d{2}\b/g;

/**
 * An annex or ruling label written into reasoning: S1-S8, Q1-Q7, C2, C37, D1, H12, L1, W3, R8, R5-L, R5-AZ,
 * and the numbered rung rulings R4-1 to R4-4 (gun-policy annex, 2026-11-12).
 * No space and no period inside, at most two or three digits, so a bill ("S. 2747", "S 1496", "H 3003",
 * "SB 204") never matches. Codebook section numbers (V1-V6, V4.1) are left alone: the coder prompt is written
 * in them and the gate does not misread them.
 * Only R takes a `-<number>` suffix: no annex numbers another prefix that way, and "Q3-24" or "H1-25" read
 * as a fiscal quarter or half-year, not a label.
 */
export const LABEL_RE = /(?<![\w.#-])(?:[SQCDLW]\d{1,2}|H\d{1,2}|R\d{1,2}(?:-(?:[A-Z]{1,3}|\d{1,2}))?)(?![\w.-]*\d)(?!-[A-Za-z])/g;

/** `GA-HB-1324-2025` → `hb1324`, the gate's canonical form; null for ids with no number after the type. */
export function storeIdToken(id: string): string | null {
  const m = /^[A-Z]{2}-([A-Z]+)-0*(\d+)\b/.exec(id);
  return m ? `${m[1].toLowerCase()}${m[2]}` : null;
}

/** Every bill this person's on-topic findings name, as exact store ids and as the gate's canonical tokens. */
export function personBills(pf: PersonFindings, topicKey: string, instruments: ReadonlyMap<string, InstrumentText>): { ids: Set<string>; tokens: Set<string> } {
  const ids = new Set<string>();
  const tokens = new Set<string>();
  const addText = (t: string | undefined) => {
    if (!t) return;
    for (const s of t.match(STORE_ID_RE) ?? []) { ids.add(s); const k = storeIdToken(s); if (k) tokens.add(k); }
    for (const raw of extractInstrumentIdentifiers(t.replace(STORE_ID_RE, ' '))) tokens.add(canonicalizeInstrumentId(raw));
  };
  for (const f of pf.findings) {
    if (!f.topic_keys.includes(topicKey)) continue;
    if (f.instrument_id) {
      ids.add(f.instrument_id);
      const k = storeIdToken(f.instrument_id);
      if (k) tokens.add(k);
      addText(instruments.get(f.instrument_id)?.title);
    }
    addText(f.note); addText(f.passage); addText(f.motion); f.subjects.forEach(addText);
  }
  return { ids, tokens };
}

/** Annex or ruling labels used in `text`, in order of first use. */
export function labelsIn(text: string): string[] {
  return [...new Set(text.match(LABEL_RE) ?? [])];
}

/** Bills named in `text` that are not among this person's bills. Labels are reported apart, never here. */
export function strangeBills(text: string, bills: { ids: Set<string>; tokens: Set<string> }): string[] {
  const out: string[] = [];
  for (const s of new Set(text.match(STORE_ID_RE) ?? [])) if (!bills.ids.has(s)) out.push(s);
  const rest = text.replace(STORE_ID_RE, ' ').replace(LABEL_RE, ' ');
  const seen = new Set<string>();
  for (const raw of extractInstrumentIdentifiers(rest)) {
    const tok = canonicalizeInstrumentId(raw);
    if (seen.has(tok)) continue;
    seen.add(tok);
    if (!bills.tokens.has(tok)) out.push(raw.trim());
  }
  return out;
}

const flat = (s: string) => normalizeText(s).replace(/\s+/g, ' ').trim();
const words = (s: string) => s.split(/\s+/).filter(Boolean).length;

/**
 * Quoted spans (four words or more, the gate's own floor) found in none of `sources`. A coder's ellipsis or
 * bracketed insertion splits a quote into pieces; each piece of two words or more must be found (the
 * `quote_fix.py` trim later turns such a quote into the act's exact pieces).
 */
export function unsourcedQuotes(text: string, sources: readonly string[], rungTexts: readonly string[]): string[] {
  const hay = sources.map(flat);
  const rungs = rungTexts.map(flat);
  const out: string[] = [];
  for (const q of extractQuotedPhrases(text)) {
    if (words(q) < 4) continue;
    const nq = flat(q);
    if (rungs.some((r) => r.includes(nq))) continue;
    const pieces = q.split(/\s*(?:\.\.\.|…|\[[^\]]*\])\s*/).map(flat).filter((p) => words(p) >= 2);
    const inOne = (texts: string[]) => texts.some((h) => pieces.every((p) => h.includes(p)));
    if (!pieces.length || !(pieces.every((p) => hay.some((h) => h.includes(p))) || inOne(rungs))) out.push(q);
  }
  return out;
}

/** The texts a quote in this code may come from: cited passages, quoted spans of cited notes, cited bills. */
export function quoteSources(cited: Finding[], instruments: ReadonlyMap<string, InstrumentText>): string[] {
  const out: string[] = [];
  for (const f of cited) {
    if (f.passage) out.push(f.passage);
    out.push(...extractQuotedPhrases(f.note));
    if (f.instrument_id) {
      const ins = instruments.get(f.instrument_id);
      if (ins?.operative_text) out.push(ins.operative_text);
      if (ins?.title) out.push(ins.title);
    }
  }
  return out;
}

/**
 * One coder entry → a full code. Header fields win over anything the coder wrote; `evidence_basis` is
 * computed from the cited on-topic findings (left out for no-stance, or when nothing cited is on file —
 * `checkCode` then names the missing finding); `coded_at` is `now`.
 */
export function finalizeCode(entry: Record<string, unknown>, header: CodeHeader, pf: PersonFindings | undefined, now: Date): Stage5Code {
  const code: Record<string, unknown> = { tags: [], finding_ids: [], ...entry };
  Object.assign(code, {
    topic_key: header.topic_key, season: header.season, season_id: header.season_id,
    revision_id: header.revision_id, codebook: header.codebook,
    coded_by: header.coded_by ?? (typeof entry.coded_by === 'string' ? entry.coded_by : 'stage5-coder'),
    coded_at: now.toISOString(),
  });
  delete code.evidence_basis;
  if (pf && (code.outcome === 'seated' || code.outcome === 'doesnt-fit')) {
    const byId = new Map(pf.findings.map((f) => [f.id, f]));
    const cited = (code.finding_ids as string[]).map((id) => byId.get(id)).filter((f): f is Finding => !!f && f.topic_keys.includes(header.topic_key));
    if (cited.length) code.evidence_basis = basisOf(cited);
  }
  return code as Stage5Code;
}

/** Every problem with one code at ingest, in plain words the coder can act on; empty means it passes. */
export function checkAtIngest(code: Stage5Code, pf: PersonFindings, ctx: IngestContext): string[] {
  const out = checkCode(code, pf);
  const reasoning = code.reasoning ?? '';
  for (const l of labelsIn(reasoning)) {
    out.push(`the reasoning uses the label "${l}": write the rule in words. Voters read the reasoning, and the gate reads S1-S8 as Senate bills`);
  }
  const bills = personBills(pf, code.topic_key, ctx.instruments);
  for (const b of strangeBills(reasoning, bills)) {
    out.push(`the reasoning names ${b}, which is not in this person's findings: name only their own bills (for a ruling's example bill, state the rule in words)`);
  }
  const byId = new Map(pf.findings.map((f) => [f.id, f]));
  const cited = code.finding_ids.map((id) => byId.get(id)).filter((f): f is Finding => !!f);
  const uncited = pf.findings.filter((f) => f.topic_keys.includes(code.topic_key) && !code.finding_ids.includes(f.id));
  for (const q of unsourcedQuotes(reasoning, quoteSources(cited, ctx.instruments), ctx.rungTexts)) {
    const home = uncited.find((f) => !unsourcedQuotes(`"${q}"`, quoteSources([f], ctx.instruments), []).length);
    out.push(home
      ? `the reasoning quotes "${q}" from finding ${home.id.slice(0, 12)}…, which the code does not cite: cite it, or drop the quote marks`
      : `the reasoning puts quote marks round "${q}", which is in no cited finding's passage and no cited bill's text: copy the words exactly, or drop the quote marks`);
  }
  return out;
}

/** The rung texts and the question from a ladder written as `Question: "…"` and `N. text` lines. */
export function rungTextsFromLadder(ladder: string): string[] {
  const out: string[] = [];
  for (const line of ladder.split('\n')) {
    const r = /^\s*\d(?:\.5)?\.\s+(.+?)\s*$/.exec(line);
    if (r) out.push(r[1]);
    const q = /Question:\s*"(.+)"/.exec(line);
    if (q) out.push(q[1]);
  }
  return out;
}
