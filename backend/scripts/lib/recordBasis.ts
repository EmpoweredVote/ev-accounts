/**
 * recordBasis — CONFIRM for a RECORD basis (confirm-basis spec §2, defect D1). A vote is usually two
 * pages: a vote page that names the person but has no bill text, and the bill text that has the
 * provision but names no voters. So a record is judged as one GROUP of passages on one instrument:
 * one passage must show the person acting (actor_quote), some passage must carry the provision, and
 * a vote must come from a vote page with a readable, divided tally. The coders copy each fact
 * verbatim (codebook 0.3); code only checks and reads it. Fail closed: anything unreadable is a finding.
 *
 * Known limit (name-collision, fix round 1): a namesake who is absent from the page cannot be
 * detected; only a surname printed twice ON THE PAGE is caught, and only when the actor_quote fails
 * to carry a qualifying first name (immediately before the surname) or initial (immediately after it).
 */
import { normalizeText } from '../../src/lib/researchVerifier.js';
import { verbatimIn, type Passage } from './coderLabel.js';

export type RecordFinding =
  | 'person-not-in-snapshot' | 'provision-missing' | 'instrument-mismatch' | 'vote-not-evidenced'
  | 'tally-unreadable' | 'near-unanimous-vote' | 'name-collision' | 'no-record-passage';

/** All numbers matching `pattern` (an alternation, e.g. "ayes|yeas") immediately labelling a count. */
function numbersFor(pattern: string, s: string): number[] {
  const re = new RegExp(`\\b(?:${pattern})\\b(?:\\s+count)?\\s*[:\\-]?\\s*(\\d+)`, 'gi');
  return [...s.matchAll(re)].map((m) => Number(m[1]));
}

/**
 * Reads one side (Aye or No) of a tally. Plural/labelled forms ("Ayes 40", "Noes: 2") are tried
 * first; the singular ("aye", "yea", "no", "nay") is used only when no plural form is present at
 * all — a roll-call sheet reads "Yea 42 ... Nay 6", never "Yeas ... Nays" in that style. If more than
 * one candidate count turns up for the chosen form (e.g. a "Roll Call No: 334" label competing with a
 * genuine "Nay 5"), the read is ambiguous and fails closed rather than guessing which one is real.
 */
function readSide(pluralAlt: string, singularAlt: string, s: string): number | null {
  const plural = numbersFor(pluralAlt, s);
  const candidates = plural.length > 0 ? plural : numbersFor(singularAlt, s);
  return candidates.length === 1 ? candidates[0] : null;
}

export function parseTally(q: string): { ayes: number; noes: number } | null {
  const s = q.replace(/\s+/g, ' ');
  const ayes = readSide('ayes|yeas', 'aye|yea', s);
  const noes = readSide('noes|nays', 'no|nay', s);
  return ayes !== null && noes !== null ? { ayes, noes } : null;
}

export const isNearUnanimous = (t: { ayes: number; noes: number }): boolean =>
  t.ayes + t.noes > 0 && t.noes / (t.ayes + t.noes) < 0.1;

export function instrumentKey(s: string | null | undefined): string | null {
  if (!s || !s.trim()) return null;
  let out = s.toLowerCase().replace(/[–—]/g, '-');
  // A hyphen directly between a letter and a digit is bill-number punctuation ("SB-1174"), not a
  // range, so it must not survive to distinguish "SB-1174" from "SB 1174". A hyphen between two
  // digits (a session range like "2023-2024") IS the range and must be kept — different sessions of
  // the same bill number are different instruments.
  out = out.replace(/([a-z])-(\d)/g, '$1$2').replace(/(\d)-([a-z])/g, '$1$2');
  return out.replace(/[\s.]/g, '');
}

/** The instrument key without its "(session)" suffix, e.g. 'sb1174 (2023-2024)' -> 'sb1174'. */
function billTokenOf(instrument: string | null | undefined): string | null {
  const key = instrumentKey(instrument);
  if (!key) return null;
  const paren = key.indexOf('(');
  return paren === -1 ? key : key.slice(0, paren);
}

/**
 * Does this page ever print the instrument's bill number? Compares against the page with
 * whitespace, periods and hyphens stripped, so "SB-1174" / "SB 1174" / "sb1174" all match — but the
 * token must not be immediately followed by a digit, so a short instrument ("SB 11") does not match
 * a page about a different, longer bill number ("SB 1174").
 */
function pageShowsInstrument(pageText: string, instrument: string | null | undefined): boolean {
  const token = billTokenOf(instrument);
  if (!token) return false;
  const compact = pageText.toLowerCase().replace(/[\s.\-]/g, '');
  let idx = compact.indexOf(token);
  while (idx !== -1) {
    const next = compact[idx + token.length];
    if (!next || !/[0-9]/.test(next)) return true;
    idx = compact.indexOf(token, idx + 1);
  }
  return false;
}

// Tokenises on Unicode letters/digits (so accented names like "Peña" survive) and drops apostrophes
// entirely rather than turning them into a word break, so "O'Brien" is one token, not two.
const words = (s: string) => normalizeText(s).replace(/['’]/g, '').replace(/[^\p{L}\p{N}\s-]/gu, ' ').split(/\s+/).filter(Boolean);

const SUFFIX_RE = /^(jr|sr|ii|iii|iv)$/;
/** Name tokens via the SAME normalisation as page text, suffixes (Jr, Sr, II...) dropped. */
const nameWords = (full: string): string[] => words(full).filter((w) => !SUFFIX_RE.test(w));
const lastNameOf = (full: string): string => { const t = nameWords(full); return t[t.length - 1] ?? ''; };
const firstNameOf = (full: string): string => { const t = nameWords(full); return t[0] ?? ''; };

/**
 * A quote counts as verbatim only if its WORDS appear as a contiguous run in the page's words —
 * character-level substring matching lets a short quote ('Ayes Lee') match mid-word inside a longer,
 * different one ('Ayes Leeds'), or a tally ('Yeas 4') match inside a bigger count ('Yeas 46').
 */
function quoteWordsIn(page: string, quote: string): boolean {
  const q = words(quote);
  if (q.length === 0) return false;
  const p = words(page);
  outer: for (let i = 0; i + q.length <= p.length; i++) {
    for (let k = 0; k < q.length; k++) if (p[i + k] !== q[k]) continue outer;
    return true;
  }
  return false;
}

export function checkRecordGroup(i: { passages: Passage[]; snapshotText: ReadonlyMap<string, string>; fullName: string }):
  { findings: RecordFinding[]; actorPassages: Passage[] } {
  // A group with nothing labelled a record (all statements, say) has no vote/sponsorship basis to
  // judge at all.
  if (!i.passages.some((p) => p.v3_class === 'record')) {
    return { findings: ['no-record-passage'], actorPassages: [] };
  }

  const out = new Set<RecordFinding>();
  const last = lastNameOf(i.fullName);
  const first = firstNameOf(i.fullName);
  const textOf = (p: Passage) => i.snapshotText.get(p.snapshot_id) ?? '';

  // One instrument for the whole group, and each page must actually show that bill's number.
  const keys = new Set(i.passages.map((p) => instrumentKey(p.instrument)));
  if (keys.size !== 1 || keys.has(null)) out.add('instrument-mismatch');
  if (i.passages.some((p) => !pageShowsInstrument(textOf(p), p.instrument))) out.add('instrument-mismatch');

  // The actor: a word-bounded verbatim actor_quote that names the person.
  const actorPassages = i.passages.filter((p) => p.actor_quote && quoteWordsIn(textOf(p), p.actor_quote) && words(p.actor_quote).includes(last));
  if (actorPassages.length === 0) out.add('person-not-in-snapshot');

  // A surname two members share on the page needs a qualifying first name or initial: the FULL
  // first name immediately before the surname ('Greg Walker'), or a single-letter initial
  // immediately after it ('Walker G'). A single letter BEFORE the surname never qualifies — it may
  // belong to the previous name on the page ('Smith G Walker K': that "G" is Smith's, not Walker's).
  for (const p of actorPassages) {
    const pageCount = words(textOf(p)).filter((w) => w === last).length;
    if (pageCount < 2) continue;
    const aq = words(p.actor_quote!);
    const idx = aq.map((w, k) => (w === last ? k : -1)).filter((k) => k >= 0);
    const qualified = idx.some((k) =>
      aq[k - 1] === first || (aq[k + 1] !== undefined && aq[k + 1].length === 1 && aq[k + 1] === first[0]));
    if (!qualified) out.add('name-collision');
  }

  // The provision is verbatim on some page of the group.
  if (!i.passages.some((p) => p.provision_quote && verbatimIn(textOf(p), p.provision_quote))) out.add('provision-missing');

  // A vote must come from a vote page, with a word-bounded, readable and divided tally.
  if (i.passages.some((p) => p.record_kind === 'vote')) {
    const votePages = actorPassages.filter((p) => p.record_kind === 'vote');
    if (votePages.length === 0) out.add('vote-not-evidenced');
    for (const p of votePages) {
      const t = p.tally_quote && quoteWordsIn(textOf(p), p.tally_quote) ? parseTally(p.tally_quote) : null;
      if (!t) out.add('tally-unreadable');
      else if (isNearUnanimous(t)) out.add('near-unanimous-vote');
    }
  }
  return { findings: [...out], actorPassages };
}
