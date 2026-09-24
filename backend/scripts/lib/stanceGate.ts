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
  MIN_SNIPPET_WORDS, normalizeText, normName, normTopic, stanceKey, type EvidenceRow, type StanceRow,
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
/**
 * Every check this gate can emit. Exported as a value so a reader of gate-findings.json
 * (verify-stance-research.ts) can refuse a check_id this gate never writes, rather than
 * trusting any string.
 */
export const GATE_CHECK_IDS = [
  'unknown-politician', 'ambiguous-politician', 'duplicate-row', 'value-out-of-range', 'topic-not-in-season',
  'topic-out-of-scope', 'level-unknown', 'no-source', 'source-without-snippet', 'snippet-too-short',
  'evidence-type-invalid', 'record-no-instrument', 'statement-needs-review', 'party-inference',
  'reasoning-empty', 'ballotpedia-only', 'source-no-path', 'pointer-only-source', 'instrument-not-cited',
  'quote-not-in-snippet',
] as const;
export type GateCheckId = typeof GATE_CHECK_IDS[number];
export interface GateFinding {
  full_name: string; topic_key: string; check_id: GateCheckId; severity: 'high' | 'medium'; what: string;
}

// Two regexes, deliberately different case sensitivity:
//   PARTY_NAMES is case-SENSITIVE because its list includes the ADJECTIVE "Democratic", which has
//     an unrelated lowercase common-word sense ("the democratic process" = relating to democracy,
//     not the party). Capitalization is the only signal that distinguishes them, so this regex
//     must not be loosened to `/i`. It also excludes "Democratic Republic" (a negative lookahead)
//     — "the Democratic Republic of the Congo" is a country name, not a party tell; "Democratic
//     nominee" and "the Democratic caucus" are unaffected and still flagged.
//   PARTY_NOUNS_ANY_CASE (below) covers only the NOUN forms — "democrat(s)", "republican(s)",
//     "gop" — which name the party in any case: a noun has no such unrelated sense, so "a lifelong
//     democrat" is a party tell whether or not it happens to be capitalized. It excludes ONLY the
//     fixed legal phrase "republican(s) form of government" (a negative lookahead) — the Article
//     IV Guarantee Clause wording, not the party. Fix round 2 (controller ruling): the exclusion
//     was widened to bare "republican(s) government" in round 1 and that let real party mentions
//     through ("the republican government of the state", "under republican government, taxes
//     fell") — bare "republican government" is ambiguous (it can mean the GOP-led government, not
//     a form of government), and a missed party mention (false negative) costs more than an extra
//     row sent back to research (false positive), so it is deliberately NOT excluded. "a lifelong
//     republican" and "Republicans in the chamber" were never excluded and still flag.
/** Capitalised party names only: "the democratic process" is not a party tell; "Democratic nominee" is. */
export const PARTY_NAMES = /\b(Democrats?|Democratic(?!\s+Republic\b)|Republicans?|GOP|Libertarians?|Lincoln Party|Green Party)\b/;
export const PARTY_PHRASES =
  /\b(party (?:line|platform|affiliation|position)|as an? (?:conservative|liberal|progressive)|consistent with (?:her|his|their) party)\b/i;
/** The noun forms only, any case — "Republic"/"democratic process"/"republican form of government" do not match; bare "republican government" DOES match (see block comment above). */
export const PARTY_NOUNS_ANY_CASE = /\b(democrats?|republicans?(?!\s+form\s+of\s+government\b)|gop)\b/i;

const wordCount = (s: string) => normalizeText(s).split(' ').filter(Boolean).length;

// C57: mirrors check-stance-sources.mjs's BALLOTPEDIA_ONLY predicate (backend/scripts/check-stance-sources.mjs,
// ~L226-239) for PRE-WRITE use: every source URL is on ballotpedia.org. That script also carves out a
// Candidate_Connection survey deep link (the candidate's own words, published nowhere else) once a stance is
// already live; pre-write there is no such row yet to preserve, so any ballotpedia-only row here is simply
// sent back for a stronger source.
function isBallotpediaUrl(url: string): boolean {
  try { return /(^|\.)ballotpedia\.org$/i.test(new URL(url).hostname); } catch { return /ballotpedia\.org/i.test(url); }
}

// C58: mirrors check-stance-sources.mjs's PRIMARY_SITE_NO_PATH predicate (~L206-218) — a source URL that is
// a bare domain with no path. Medium, not high: a bare root belonging to the subject can still support the
// claim (see that script's comment for the measured rationale); it just needs a path for precision.
function hasNoPath(url: string): boolean {
  try {
    const u = new URL(url);
    return u.pathname === '' || u.pathname === '/';
  } catch { return false; } // an unparseable URL is a NON_URL_SOURCE-shaped problem, not this one
}

// Mirrored (not imported) from .claude/skills/research-stances/scripts/build-and-check.mjs's
// POINTER_ONLY_SOURCE: that script lives outside backend/'s tsconfig rootDir. VOTE411 answers are the
// candidate's own words, but LWV terms bar reproducing them without written permission, so they cannot be a
// cited source. lwvlac.org is deliberately left OUT — open question for the program owner (task 6 brief,
// 2026-09-23) — keep in sync with the original if it changes.
const POINTER_ONLY_SOURCE = /vote411\.org|thevoterguide\.org/i;

// Identifier-bearing subset of NAMES_INSTRUMENT (chair-evidence-patterns.mjs): the forms that NAME a
// specific instrument by number, letter or dated title, as opposed to a bare "Act"/"Ordinance", "voted
// yes", "roll call" or "Commissioners Court approved" — which say something happened but cannot themselves
// be looked up in a source's text. NAMES_INSTRUMENT is NEVER widened for this gate; if a future widening of
// NAMES_INSTRUMENT adds a new IDENTIFIER-bearing form, copy it here too (a new bare-action form needs no
// change here). Each pattern tolerates an optional period/space between the letters ("HB" / "H.B." / "HB.")
// so extraction does not depend on which spelling the reasoning happened to use; comparison against a
// snippet is done separately, by canonicalizing both sides (canonicalizeInstrumentId, below).
const INSTRUMENT_IDENTIFIER_PATTERNS: RegExp[] = [
  /\bH\.?B\.?\s?\d+\b/,
  /\bS\.?B\.?\s?\d+\b/,
  /\b(?:House|Senate) Bill \d{1,4}\b/,
  /\bS\.?L\.?\s?20\d{2}-\d{1,4}\b/,
  /\bH\.?R\.?\s?\d+\b/,
  /\bS\.?J\.?\s?Res\.?\s?\d+\b/,
  /\bA\.?B\.?-?\s?\d+\b/,
  /\bLD\s?\d+\b/,
  /\bSJR\s?\d+\b/,
  /\bChapter\s?\d+\b/,
  /\bResolution No\.?\s?\d+\b/,
  /\bOrdinance No\.?\s?\d+\b/,
  /\bMeasure \d+\.\d+\b/,
  /\bO-\d{4,5}\b/,
  /\bR-\d{5,6}\b/,
  /\bProposition [A-Z0-9]{1,3}\b/,
  /(?<![A-Za-z]\.)\bS\.?\s?\d{1,4}\b/,
  /\bBan of (?:19|20)\d{2}\b/,
  /\bR-\d{1,4}-\d{2}\b/,
];

/** Every identifier-bearing instrument mention in `text`, as raw matched substrings (may repeat). */
function extractInstrumentIdentifiers(text: string): string[] {
  const out: string[] = [];
  for (const pattern of INSTRUMENT_IDENTIFIER_PATTERNS) {
    const re = new RegExp(pattern.source, pattern.flags.includes('g') ? pattern.flags : `${pattern.flags}g`);
    out.push(...(text.match(re) ?? []));
  }
  return out;
}

/**
 * Canonical form for comparing an instrument identifier against snippet text: normalize (case,
 * whitespace, curly quotes — normalizeText), then collapse each run of letters or digits together with no
 * separator — "H.B. 1001", "HB 1001" and "HB1001" all become "hb1001". Digits stay grouped as their own run
 * (never split), so this cannot accidentally straddle an unrelated word boundary elsewhere in the snippet.
 */
function canonicalizeInstrumentId(text: string): string {
  return (normalizeText(text).match(/[a-z]+|\d+/g) ?? []).join('');
}

/** Text inside straight ("...") or curly (“...”) double quotes in `text`, in order, one entry per span. */
function extractQuotedPhrases(text: string): string[] {
  return [...text.matchAll(/"([^"]+)"|“([^”]+)”/g)].map((m) => m[1] ?? m[2] ?? '');
}

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
  if (row.reasoning.trim().length === 0) add('reasoning-empty', 'high', 'reasoning is empty for a scored row');

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
    if (hasNoPath(url)) add('source-no-path', 'medium', `source URL has no path: ${url}`);
    if (POINTER_ONLY_SOURCE.test(url)) {
      add('pointer-only-source', 'high', `source is VOTE411 / thevoterguide.org: ${url}. LWV terms bar reproducing this without written permission, so it cannot be a cited source.`);
    }
  }
  if (row.source_urls.length > 0 && row.source_urls.every(isBallotpediaUrl)) {
    add('ballotpedia-only', 'high', 'every source is on ballotpedia.org — cite the underlying record, filing or report Ballotpedia draws on');
  }

  if (row.evidence_type === 'record') {
    if (!NAMES_INSTRUMENT.test(row.reasoning)) add('record-no-instrument', 'high', 'record evidence must name the bill, act, ordinance or recorded vote');
    // C68: citation control in the OTHER direction — naming an instrument in the reasoning is not enough;
    // it must actually appear in one of the row's cited snippets, or the citation is one-way.
    const identifiers = [...new Set(extractInstrumentIdentifiers(row.reasoning).map(canonicalizeInstrumentId))];
    const snippetsCanon = ctx.evidence.map((e) => canonicalizeInstrumentId(e.snippet));
    for (const id of identifiers) {
      if (!snippetsCanon.some((s) => s.includes(id))) {
        add('instrument-not-cited', 'high', `reasoning names an instrument (canonical "${id}") that does not appear in any cited snippet`);
      }
    }
  } else if (row.evidence_type === 'statement') {
    add('statement-needs-review', 'medium', "statement evidence (the person's own words) goes to human review");
  } else {
    add('evidence-type-invalid', 'high', `evidence_type "${row.evidence_type}" must be record or statement`);
  }

  if (PARTY_NAMES.test(row.reasoning) || PARTY_PHRASES.test(row.reasoning) || PARTY_NOUNS_ANY_CASE.test(row.reasoning)) {
    add('party-inference', 'high', 'reasoning names a party or partisan frame — party is never evidence');
  }

  // C69: a quoted passage in the reasoning that isn't in any cited snippet is either a wrong sentence or a
  // fabricated quote — quotation marks are a promise the words were said, and this checks the promise.
  const quotes = extractQuotedPhrases(row.reasoning).filter((q) => wordCount(q) >= 4);
  for (const q of quotes) {
    const nq = normalizeText(q);
    if (!ctx.evidence.some((e) => normalizeText(e.snippet).includes(nq))) {
      add('quote-not-in-snippet', 'high', `reasoning quotes text not found verbatim in any cited snippet: "${q}"`);
    }
  }
  return out;
}

/**
 * How many DISTINCT people (politician_ids) in the bundle share each normalized full_name — >1
 * means the name is ambiguous. Distinct ids, not entries: one person listed twice (a --race and
 * a --politician for the same id) is still one person, and must not read as a namesake.
 */
function nameCounts(politicians: BundlePolitician[]): Map<string, number> {
  const ids = new Map<string, Set<string>>();
  for (const p of politicians) {
    const k = normName(p.full_name);
    ids.set(k, (ids.get(k) ?? new Set<string>()).add(p.politician_id));
  }
  return new Map([...ids].map(([k, set]) => [k, set.size]));
}

export function checkBatch(
  rows: ResearchRow[], topics: BundleTopic[], politicians: BundlePolitician[], evidence: EvidenceRow[],
): GateFinding[] {
  const topicByKey = new Map(topics.map((t) => [normTopic(t.topic_key), t]));
  const polByName = new Map(politicians.map((p) => [normName(p.full_name), p]));
  // I4: build-stance-topic-bundle dedupes politicians.json by id, not by name, so two distinct
  // people can share a full_name in one bundle. polByName above (last-match-wins) silently picks
  // one of them for the row's scope/level checks, and toStanceRows' per-row politician_id can
  // never tell them apart either — so a shared name is flagged here explicitly, rather than
  // letting the verifier's single-id resolution quietly resolve onto whichever namesake matched
  // last.
  const counts = nameCounts(politicians);
  // C1: two proposed values for one (person, topic) pair. Each row's snippets can "verify" the
  // other's, and both reach decidePublish — so neither may be written; the pair is re-researched
  // as ONE row (a re-research pass REPLACES a pair's rows, it never appends).
  //
  // R5: this counts EVERY row of the pair, null value or not. A value=null row is not itself a
  // second proposal (it is never flagged), but verifyEvidence joins evidence by (name, topic) —
  // not by row — so a blank sibling's source_urls still verify the scored row's snippets. Counting
  // only non-null rows let a research.csv with one blank row and one scored row for the same pair
  // pass silently while the scored row quietly borrowed the blank row's sources.
  const rowsPerPair = new Map<string, number>();
  for (const r of rows) {
    const k = stanceKey(r.full_name, r.topic_key);
    rowsPerPair.set(k, (rowsPerPair.get(k) ?? 0) + 1);
  }
  return rows.flatMap((r) => {
    const key = stanceKey(r.full_name, r.topic_key);
    const findings = checkStanceRow(r, {
      topic: topicByKey.get(normTopic(r.topic_key)),
      politician: polByName.get(normName(r.full_name)),
      evidence: evidence.filter((e) => stanceKey(e.full_name, e.topic_key) === key),
    });
    const n = counts.get(normName(r.full_name)) ?? 0;
    if (n > 1) {
      findings.push({
        full_name: r.full_name, topic_key: r.topic_key, check_id: 'ambiguous-politician', severity: 'high',
        what: `${n} people in politicians.json share this name — research them in separate batches`,
      });
    }
    const dup = rowsPerPair.get(key) ?? 0;
    // Only the NON-NULL rows of a duplicated pair are flagged — a null row produces no findings
    // of its own (checkStanceRow already returns early for it, above), but it still counts toward
    // `dup` so a blank-plus-scored pair is caught too (R5).
    if (r.value !== null && dup > 1) {
      findings.push({
        full_name: r.full_name, topic_key: r.topic_key, check_id: 'duplicate-row', severity: 'high',
        what: `research.csv has ${dup} rows for this pair — keep exactly one; a re-research pass replaces the row`,
      });
    }
    return findings;
  });
}

export function toStanceRows(rows: ResearchRow[], topics: BundleTopic[], politicians: BundlePolitician[]): StanceRow[] {
  const polByName = new Map(politicians.map((p) => [normName(p.full_name), p]));
  const counts = nameCounts(politicians);
  // R4: same idea as the full_name canonicalization below, for topic_key — matched through the
  // same normTopic the gate and verifier already key on.
  const topicByKey = new Map(topics.map((t) => [normTopic(t.topic_key), t]));
  return rows.map((r) => {
    const k = normName(r.full_name);
    // Ambiguous names never carry an id — see checkBatch above. An id chosen from a name
    // collision is worse than no id: it looks resolved and can write onto the wrong namesake.
    const ambiguous = (counts.get(k) ?? 0) > 1;
    const match = ambiguous ? undefined : polByName.get(k);
    const topicMatch = topicByKey.get(normTopic(r.topic_key));
    return {
      // The bundle's canonical spelling when the row matched one person, so every downstream
      // reader (verifier, review queue, publish-report) sees one spelling for one person.
      full_name: match?.full_name ?? r.full_name,
      politician_id: match?.politician_id ?? '',
      // The bundle topic's canonical spelling when the row's key matched one (case/whitespace
      // variants collapse to the same topic_key downstream, same reasoning as full_name above).
      topic_key: topicMatch?.topic_key ?? r.topic_key,
      value: r.value,
      reasoning: r.reasoning,
    };
  });
}
