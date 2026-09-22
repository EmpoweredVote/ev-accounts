/**
 * stanceGate — deterministic checks on the STANCE side of a research batch.
 *
 * The snippet verifier (src/lib/researchVerifier.ts) proves a quoted passage is really on the
 * cited page. It does not ask whether a row cites anything at all, whether the evidence can tell
 * ONE chair from its neighbour, whether party stood in for evidence, or whether the topic is a
 * question this season asks of this office. Those are these checks. Pure — no DB, no network —
 * so every rule, and every refusal, is pinned by stanceGate.test.ts.
 *
 * Two evidence classes (operator decision 2026-09-22):
 *   record    — something done in office. Must name the instrument (NAMES_INSTRUMENT). The
 *               regex is NOT widened here: a separate lane, not a looser gate.
 *   statement — the person's own words. No instrument to name, so it goes to human review.
 */
import { NAMES_INSTRUMENT } from './chair-evidence-patterns.mjs';
import {
  MIN_SNIPPET_WORDS, normalizeText, type EvidenceRow, type StanceRow,
} from '../../src/lib/researchVerifier.js';
import { appliesToLevel, type Level, type TopicApplicability } from '../../src/lib/topicApplicability.js';

export interface ResearchRow {
  full_name: string;
  topic_key: string;
  value: number | null;
  reasoning: string;
  evidence_type: string;
  source_urls: string[];
}
export interface BundleTopic extends TopicApplicability {
  topic_id: string;
  topic_key: string;
  topic_revision_id: string;
  question_number: number;
  title: string;
  question_text: string;
  stances: { value: number; text: string }[];
}
export interface BundlePolitician { full_name: string; politician_id: string; level: Level | null; race_id: string | null }
export type GateCheckId =
  | 'unknown-politician' | 'value-out-of-range' | 'topic-not-in-season' | 'topic-out-of-scope'
  | 'level-unknown' | 'no-source' | 'source-without-snippet' | 'snippet-too-short'
  | 'evidence-type-invalid' | 'record-no-instrument' | 'statement-needs-review' | 'party-inference';
export interface GateFinding {
  full_name: string; topic_key: string; check_id: GateCheckId; severity: 'high' | 'medium'; what: string;
}

/** Capitalised party names only: "the democratic process" is not a party tell; "Democratic nominee" is. */
export const PARTY_NAMES = /\b(Democrats?|Democratic|Republicans?|GOP|Libertarians?|Lincoln Party|Green Party)\b/;
export const PARTY_PHRASES =
  /\b(party (?:line|platform|affiliation|position)|as an? (?:conservative|liberal|progressive)|consistent with (?:her|his|their) party)\b/i;

const wordCount = (s: string) => normalizeText(s).split(' ').filter(Boolean).length;

export function checkStanceRow(
  row: ResearchRow,
  ctx: { topic: BundleTopic | undefined; politician: BundlePolitician | undefined; evidence: EvidenceRow[] },
): GateFinding[] {
  const out: GateFinding[] = [];
  const add = (check_id: GateCheckId, severity: 'high' | 'medium', what: string) =>
    out.push({ full_name: row.full_name, topic_key: row.topic_key, check_id, severity, what });

  // value=null is the researcher's explicit "insufficient evidence": nothing proposed, nothing to gate.
  if (row.value === null) return out;

  if (!ctx.politician) add('unknown-politician', 'high', `${row.full_name} is not in politicians.json — rebuild the bundle with this person`);
  if (!Number.isInteger(row.value) || row.value < 1 || row.value > 5) add('value-out-of-range', 'high', `value ${row.value} is not an integer 1-5`);

  if (!ctx.topic) {
    add('topic-not-in-season', 'high', `${row.topic_key} is not a question the open season asks — it cannot be written`);
  } else if (ctx.politician) {
    if (!ctx.politician.level) add('level-unknown', 'medium', `office level unknown for ${row.full_name}; scope not checked`);
    else if (!appliesToLevel(ctx.topic, ctx.politician.level)) add('topic-out-of-scope', 'high', `${row.topic_key} does not apply at the ${ctx.politician.level} level`);
  }

  if (row.source_urls.length === 0) add('no-source', 'high', 'no source URL');
  for (const url of row.source_urls) {
    const forUrl = ctx.evidence.filter((e) => e.source_url === url);
    if (forUrl.length === 0) add('source-without-snippet', 'high', `no evidence.csv snippet for ${url}`);
    for (const e of forUrl) {
      const n = wordCount(e.snippet);
      if (n < MIN_SNIPPET_WORDS) add('snippet-too-short', 'high', `snippet ${e.snippet_index} for ${url} has ${n} words (< ${MIN_SNIPPET_WORDS})`);
    }
  }

  if (row.evidence_type === 'record') {
    if (!NAMES_INSTRUMENT.test(row.reasoning)) add('record-no-instrument', 'high', 'record evidence must name the bill, act, ordinance or recorded vote');
  } else if (row.evidence_type === 'statement') {
    add('statement-needs-review', 'medium', "statement evidence (the person's own words) goes to human review");
  } else {
    add('evidence-type-invalid', 'high', `evidence_type "${row.evidence_type}" must be record or statement`);
  }

  if (PARTY_NAMES.test(row.reasoning) || PARTY_PHRASES.test(row.reasoning)) {
    add('party-inference', 'high', 'reasoning names a party or partisan frame — party is never evidence');
  }
  return out;
}

export function checkBatch(
  rows: ResearchRow[], topics: BundleTopic[], politicians: BundlePolitician[], evidence: EvidenceRow[],
): GateFinding[] {
  const topicByKey = new Map(topics.map((t) => [t.topic_key, t]));
  const polByName = new Map(politicians.map((p) => [p.full_name.toLowerCase(), p]));
  return rows.flatMap((r) => checkStanceRow(r, {
    topic: topicByKey.get(r.topic_key),
    politician: polByName.get(r.full_name.toLowerCase()),
    evidence: evidence.filter((e) => e.full_name.toLowerCase() === r.full_name.toLowerCase() && e.topic_key === r.topic_key),
  }));
}

export function toStanceRows(rows: ResearchRow[], politicians: BundlePolitician[]): StanceRow[] {
  const polByName = new Map(politicians.map((p) => [p.full_name.toLowerCase(), p]));
  return rows.map((r) => ({
    full_name: r.full_name,
    politician_id: polByName.get(r.full_name.toLowerCase())?.politician_id ?? '',
    topic_key: r.topic_key,
    value: r.value,
    reasoning: r.reasoning,
  }));
}
