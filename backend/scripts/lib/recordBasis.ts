/**
 * recordBasis — CONFIRM for a RECORD basis (confirm-basis spec §2, defect D1). A vote is usually two
 * pages: a vote page that names the person but has no bill text, and the bill text that has the
 * provision but names no voters. So a record is judged as one GROUP of passages on one instrument:
 * one passage must show the person acting (actor_quote), some passage must carry the provision, and
 * a vote must come from a vote page with a readable, divided tally. The coders copy each fact
 * verbatim (codebook 0.3); code only checks and reads it. Fail closed: anything unreadable is a finding.
 *
 * Namesake guard on the actor page (final review fix 2, ruling 2026-09-26 "Fix it now"):
 * - chamber: when the seat is a legislator's, the actor page must name the seat's chamber (a House
 *   roll call listing another "Adams" is not Senator Adams's vote) -> otherwise 'chamber-not-evidenced';
 * - common surname (COMMON_LAST_NAMES) or a surname printed twice on the page: the actor_quote must
 *   carry a qualifier — a full given name (first or middle, 2+ letters) immediately before the
 *   surname ('Greg Walker', 'Stuart Adams') or the first initial immediately after it ('Walker G',
 *   'Adams J. S.') -> otherwise 'name-collision'.
 * Known limit: a namesake who is absent from the page, in the same chamber, with an uncommon surname
 * cannot be detected by the page alone.
 */
import { normalizeText, COMMON_LAST_NAMES } from '../../src/lib/researchVerifier.js';
import { verbatimIn, instrumentKey, type Passage } from './coderLabel.js';

// instrumentKey lives in coderLabel.ts (the validator groups by it too); re-exported so existing
// callers keep one import site.
export { instrumentKey };

export type RecordFinding =
  | 'person-not-in-snapshot' | 'provision-missing' | 'instrument-mismatch' | 'vote-not-evidenced'
  | 'tally-unreadable' | 'near-unanimous-vote' | 'name-collision' | 'no-record-passage' | 'chamber-not-evidenced' | 'tally-other-vote';

/** A legislative seat's chamber; null when the seat is not a legislator's (the chamber test is skipped). */
export type Chamber = 'upper' | 'lower';
export function seatChamber(officeTitle: string | null | undefined): Chamber | null {
  const t = officeTitle ?? '';
  if (/\bsenator\b/i.test(t)) return 'upper';
  if (/\brepresentative\b|\bassembly\s*(?:member|man|woman)\b|\bassemblymember\b|\bdelegate\b/i.test(t)) return 'lower';
  return null;
}
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

/** Every start index of the token run `q` in `p`. */
function runStarts(p: string[], q: string[]): number[] {
  const out: number[] = [];
  if (q.length === 0) return out;
  outer: for (let i = 0; i + q.length <= p.length; i++) {
    for (let k = 0; k < q.length; k++) if (p[i + k] !== q[k]) continue outer;
    out.push(i);
  }
  return out;
}

/**
 * Vote blocks. A page can print several votes on one bill (a floor vote and a concurrence vote; one
 * per chamber). A block starts at a labelled aye COUNT — "Ayes Count 30", "Yea 42", "Ayes: 40" — and
 * runs to the next one; the text before the first is the page header (block -1). A bare "Ayes Allen,
 * …" (a name list, no number) is not a boundary.
 */
const AYE_LABEL = new Set(['ayes', 'yeas', 'aye', 'yea']);
const isNum = (w: string | undefined) => w !== undefined && /^\d+$/.test(w);
function ayeBoundaries(p: string[]): number[] {
  const out: number[] = [];
  for (let k = 0; k < p.length; k++) {
    if (!AYE_LABEL.has(p[k])) continue;
    let j = k + 1;
    if (p[j] === 'count' || p[j] === '-') j++;
    if (isNum(p[j])) out.push(k);
  }
  return out;
}
/** The block (index into ayeBoundaries, -1 = header) holding token index `a`. */
const blockOf = (bounds: number[], a: number) => { let b = -1; for (let k = 0; k < bounds.length; k++) if (bounds[k] <= a) b = k; return b; };

/**
 * Chamber words as tokens, with their NON-chamber uses removed: "General Assembly" (the whole Indiana
 * legislature) and "<Chamber> Bill / Resolution / …" (a bill's origin, printed on the other chamber's
 * pages). Without this an Indiana Senate roll call passed for a House seat (final review 2026-09-26).
 */
const CHAMBER_WORD: Record<string, Chamber> = { senate: 'upper', sen: 'upper', house: 'lower', assembly: 'lower', asm: 'lower' };
// A chamber word followed by these names a bill's origin or a stage ("Senate Bill", "Motion Assembly
// 3rd Reading" on a SENATE floor vote of an Assembly bill, CA AB 1955), not where the vote happened.
const NOT_CHAMBER_NEXT = /^(bills?|enrolled|joint|concurrent|resolutions?|amendments?|reading)$/;
const ORDINAL = /^(1st|2nd|3rd|first|second|third)$/;
function chamberAt(p: string[], k: number): Chamber | null {
  const c = CHAMBER_WORD[p[k]];
  if (!c) return null;
  if (p[k] === 'assembly' && p[k - 1] === 'general') return null;
  if (p[k + 1] !== undefined && NOT_CHAMBER_NEXT.test(p[k + 1])) return null;
  if (p[k + 1] !== undefined && ORDINAL.test(p[k + 1]) && p[k + 2] === 'reading') return null; // "Assembly 3rd Reading", not "Senate First Regular Session"
  return c;
}
/** The nearest chamber word BEFORE token index `a`: the chamber of the vote that lists the actor. */
function chamberBefore(p: string[], a: number): Chamber | null {
  for (let k = a - 1; k >= 0; k--) { const c = chamberAt(p, k); if (c) return c; }
  return null;
}

export function checkRecordGroup(i: {
  passages: Passage[]; snapshotText: ReadonlyMap<string, string>; fullName: string;
  /** The seat's chamber (seatChamber(office_title)). Omitted/null skips the chamber test. */
  chamber?: Chamber | null;
}):
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

  // Where on each actor page the actor_quote sits, and which vote block that is. When the passage
  // also carries a tally_quote, only occurrences in the tally's block count — the actor and the count
  // must describe the same vote (a page often prints the same short name run in two votes).
  const located = actorPassages.map((p) => {
    const pt = words(textOf(p));
    const bounds = ayeBoundaries(pt);
    let occ = runStarts(pt, words(p.actor_quote!));
    const tallyStarts = p.tally_quote ? runStarts(pt, words(p.tally_quote)) : [];
    if (tallyStarts.length > 0) {
      const tb = new Set(tallyStarts.map((t) => blockOf(bounds, t)));
      const same = occ.filter((a) => tb.has(blockOf(bounds, a)));
      if (same.length === 0) out.add('tally-other-vote');
      else occ = same;
    }
    return { p, pt, bounds, occ };
  });

  // The vote that lists the actor must be the seat's chamber: the nearest chamber word before the
  // actor_quote (skipped when the seat is not a legislator's). Fails closed when no occurrence has it.
  if (i.chamber) {
    // Search back from the surname itself, so a title inside the actor_quote counts ("Authored by:
    // Sen. Shelli Yoder" — the IN author line names no chamber before it).
    for (const l of located) {
      const inQuote = words(l.p.actor_quote!).indexOf(last);
      if (!l.occ.some((a) => chamberBefore(l.pt, a + Math.max(0, inQuote)) === i.chamber)) out.add('chamber-not-evidenced');
    }
  }

  // A common surname, or a surname two members share on the page, needs a qualifier in the
  // actor_quote: the given name the person goes by, in full, immediately before the surname
  // ('Greg Walker'; 'Stuart Adams' for "J. Stuart Adams"), or the first initial immediately after it
  // ('Walker G'). The name gone by is the first given name, or the middle one only when the first is a
  // bare initial — any other middle name would let a namesake whose first name it is pass ('Lee Smith'
  // for "John Lee Smith"). A single letter BEFORE the surname never qualifies — it may belong to the
  // previous name on the page ('Smith G Walker K': that "G" is Smith's, not Walker's).
  const given = nameWords(i.fullName).slice(0, -1);
  const givenNames = (given[0]?.length === 1 ? given.slice(1, 2) : given.slice(0, 1)).filter((w) => w.length > 1);
  const common = COMMON_LAST_NAMES.has(last);
  for (const { p, pt, bounds, occ } of located) {
    // Count the surname inside the actor's own vote block, not the whole page: a page that prints two
    // votes lists the same member twice (Durazo, SB 57), which is not two members. The largest count
    // over the candidate occurrences decides — fail closed.
    const blockCount = Math.max(0, ...occ.map((a) => {
      const b = blockOf(bounds, a);
      const from = b < 0 ? 0 : bounds[b]; const to = b + 1 < bounds.length ? bounds[b + 1] : pt.length;
      return pt.slice(from, to).filter((w) => w === last).length;
    }));
    if (blockCount < 2 && !common) continue;
    const aq = words(p.actor_quote!);
    const idx = aq.map((w, k) => (w === last ? k : -1)).filter((k) => k >= 0);
    const qualified = idx.some((k) =>
      (k > 0 && givenNames.includes(aq[k - 1])) || (aq[k + 1] !== undefined && aq[k + 1].length === 1 && aq[k + 1] === first[0]));
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
      // A 0-0 tally proves no division at all: fail closed (final review fix 3).
      if (!t || t.ayes + t.noes === 0) out.add('tally-unreadable');
      else if (isNearUnanimous(t)) out.add('near-unanimous-vote');
    }
  }
  return { findings: [...out], actorPassages };
}
