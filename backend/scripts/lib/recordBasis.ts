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
 * - exception, name_format 'surname-initial': a common surname printed once on the whole page with no
 *   initial after it is one member of that chamber (the page prints initials to tell namesakes apart).
 * Known limit: a namesake who is absent from the page, in the same chamber, with an uncommon surname
 * cannot be detected by the page alone.
 *
 * Layout rules (SourceRules) come from the passage's source profile (see `profileOf`, sourceProfiles.ts,
 * a later task) — GENERIC_RULES when a passage's source has none. Five chamber rule kinds: 'nearest-before'
 * reads the chamber word closest before the actor (today's default); 'word-before-floor' reads the
 * chamber word immediately before "Floor", ignoring an intervening motion/stage; 'page-header' reads
 * the first chamber word on the page; 'bill-origin' reads the bill token itself (S.. = upper, A../H.. =
 * lower); 'none' skips the chamber test entirely (e.g. a nonpartisan city council).
 */
import { normalizeText, COMMON_LAST_NAMES } from '../../src/lib/researchVerifier.js';
import { verbatimIn, instrumentKey, normalizeInstrumentForm, type Passage } from './coderLabel.js';

// instrumentKey lives in coderLabel.ts (the validator groups by it too); re-exported so existing
// callers keep one import site.
export { instrumentKey };

export type RecordFinding =
  | 'person-not-in-snapshot' | 'provision-missing' | 'instrument-mismatch' | 'vote-not-evidenced'
  | 'tally-unreadable' | 'near-unanimous-vote' | 'name-collision' | 'no-record-passage' | 'chamber-not-evidenced' | 'tally-other-vote'
  | 'amendment-markup-lost' | 'provision-deleted';

/** A legislative seat's chamber; null when the seat is not a legislator's (the chamber test is skipped). */
export type Chamber = 'upper' | 'lower';

export type VoteBlockRule = 'aye-count' | 'whole-page';
export type ChamberRule = 'nearest-before' | 'word-before-floor' | 'word-before-reading' | 'reading-else-bill-origin' | 'page-header' | 'bill-origin' | 'none';
export type TallyFormat = 'labelled' | 'dash-ayes-nays';
export type NameFormat = 'surname' | 'surname-initial' | 'last-first' | 'full-name';
/**
 * How a source prints amended text (amendment-markup spec §1): 'final' — the page prints the law as
 * it will read, no markup to lose (CA chaptered text); 'marked' — deletions are recoverable from the
 * page's markup (AZ HTML strike-through, or an IN bill-text PDF read with pdfMarkedText); 'unmarked' —
 * deletions are NOT recoverable (a PDF read without strike detection, or a plain-text copy).
 */
export type AmendmentText = 'final' | 'marked' | 'unmarked';
export interface SourceRules { vote_block: VoteBlockRule; chamber: ChamberRule; not_chamber_after: string[]; name_format: NameFormat; tally_format: TallyFormat; amendment_text: AmendmentText }
export const VOTE_BLOCK_RULES: readonly VoteBlockRule[] = ['aye-count', 'whole-page'];
export const CHAMBER_RULES: readonly ChamberRule[] = ['nearest-before', 'word-before-floor', 'word-before-reading', 'reading-else-bill-origin', 'page-header', 'bill-origin', 'none'];
export const TALLY_FORMATS: readonly TallyFormat[] = ['labelled', 'dash-ayes-nays'];
export const NAME_FORMATS: readonly NameFormat[] = ['surname', 'surname-initial', 'last-first', 'full-name'];
export const AMENDMENT_TEXTS: readonly AmendmentText[] = ['final', 'marked', 'unmarked'];
/** Today's layout rules. A source with no profile is read with these (and CONFIRM flags it). */
export const GENERIC_RULES: SourceRules = { vote_block: 'aye-count', chamber: 'nearest-before', not_chamber_after: [], name_format: 'surname', tally_format: 'labelled', amendment_text: 'final' };
/** Per actor passage: the rules of its source and the seat's chamber in that body. */
export type PassageProfile = { rules: SourceRules; chamber: Chamber | null };
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

export function parseTally(q: string, format: TallyFormat = 'labelled'): { ayes: number; noes: number } | null {
  const s = q.replace(/\s+/g, ' ');
  if (format === 'dash-ayes-nays') {
    // "16-14-0-0-0": Ayes-Nays-NV-Excused-Vacant (Arizona). Exactly one such run, else ambiguous.
    const runs = [...s.matchAll(/(?<![\d-])(\d+)-(\d+)(?:-\d+){1,4}(?![\d-])/g)];
    return runs.length === 1 ? { ayes: Number(runs[0][1]), noes: Number(runs[0][2]) } : null;
  }
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
 * Does this page ever print the instrument's bill number? The page's long chamber-bill forms
 * ("Senate Bill 208") are first mapped to the short prefix ("sb208"), the same mapping instrumentKey
 * uses (coderLabel.ts `normalizeInstrumentForm`) — the IN bill-listing page prints only the long form,
 * never "SB 208". Then compared with whitespace, periods and hyphens stripped, so "SB-1174" /
 * "SB 1174" / "sb1174" all match — but the token must not be immediately followed by a digit, so a
 * short instrument ("SB 20") does not match a page about a different, longer bill number
 * ("SB 1174" / "Senate Bill 208").
 */
export function pageShowsInstrument(pageText: string, instrument: string | null | undefined): boolean {
  const token = billTokenOf(instrument);
  if (!token) return false;
  const compact = normalizeInstrumentForm(pageText.toLowerCase()).replace(/[\s.-]/g, '');
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
// 'rep' matches 'sen': Indiana's author line titles a Representative "Rep. Ben Smaltz" (HB 1296,
// 2022), and without it that line showed no chamber at all ("House Bill" names the bill's origin).
const CHAMBER_WORD: Record<string, Chamber> = { senate: 'upper', sen: 'upper', house: 'lower', rep: 'lower', assembly: 'lower', asm: 'lower' };
// A chamber word followed by these names a bill's origin or a stage ("Senate Bill", "Motion Assembly
// 3rd Reading" on a SENATE floor vote of an Assembly bill, CA AB 1955), not where the vote happened.
const NOT_CHAMBER_NEXT = /^(bills?|enrolled|joint|concurrent|resolutions?|amendments?|reading)$/;
const ORDINAL = /^(1st|2nd|3rd|first|second|third)$/;
function chamberAt(p: string[], k: number, extra: ReadonlySet<string>): Chamber | null {
  const c = CHAMBER_WORD[p[k]];
  if (!c) return null;
  if (p[k] === 'assembly' && p[k - 1] === 'general') return null;
  const next = p[k + 1];
  if (next !== undefined && (NOT_CHAMBER_NEXT.test(next) || extra.has(next))) return null;
  if (next !== undefined && ORDINAL.test(next) && p[k + 2] === 'reading') return null; // "Assembly 3rd Reading", not "Senate First Regular Session"
  return c;
}
/** The nearest chamber word BEFORE token index `a`: the chamber of the vote that lists the actor. */
/** The token after the surname marks an AZ BillStatus co-sponsor ("Nguyen (Co-Sponsor)"). */
function isCoSponsorListing(p: string[], a: number): boolean {
  return p[a + 1] === 'co-sponsor';
}

function chamberBefore(p: string[], a: number, extra: ReadonlySet<string>): Chamber | null {
  for (let k = a - 1; k >= 0; k--) { const c = chamberAt(p, k, extra); if (c) return c; }
  return null;
}
/** The chamber of the vote/act that names the actor, read by the source's chamber rule. */
function actorChamber(rule: ChamberRule, pt: string[], a: number, instrument: string | null | undefined, extra: ReadonlySet<string>, bounds: number[]): Chamber | null {
  switch (rule) {
    case 'nearest-before': return chamberBefore(pt, a, extra);
    case 'word-before-floor': {
      // Bound the scan to the actor's own vote block: a CA-style page prints each vote's OWN
      // "Location <Chamber> Floor" label just before that vote's aye count -- which, by
      // ayeBoundaries' own reckoning, sits inside the PRECEDING block, not the block it actually
      // labels. So the region must reach back to the block before last (start = the boundary before
      // the actor's own), not merely to the actor's own boundary -- otherwise a vote with no floor
      // label of its own would silently borrow whatever floor label came before it on the page.
      const b = blockOf(bounds, a);
      const start = b >= 1 ? bounds[b - 1] : 0;
      for (let k = a - 1; k >= start; k--) if (pt[k + 1] === 'floor') { const c = chamberAt(pt, k, extra); if (c) return c; }
      return null;
    }
    case 'word-before-reading': {
      // "Senate Third Reading" on an Arizona vote page names the chamber that voted (unlike CA's
      // "Motion Assembly 3rd Reading", the bill's origin): the chamber word directly before
      // "[ordinal] reading", bounded like word-before-floor.
      const b = blockOf(bounds, a);
      const start = b >= 1 ? bounds[b - 1] : 0;
      for (let k = a - 1; k >= start; k--) {
        const c = CHAMBER_WORD[pt[k]];
        if (c && (pt[k + 1] === 'reading' || ((ORDINAL.test(pt[k + 1] ?? '') || pt[k + 1] === 'final') && pt[k + 2] === 'reading'))) return c;
      }
      return null;
    }
    case 'reading-else-bill-origin':
      // AZ BillStatus: one URL prefix serves both the vote dialog ("House Third Reading - HB…", which
      // names the chamber that voted) and the overview (a sponsor list with no reading line, where the
      // bill's own house of origin is the sponsor's chamber — bill-origin, with its co-author guard).
      // v3: on the overview only the PRIME sponsor takes the bill's chamber. A co-sponsor list mixes
      // both chambers with no label (SB 1165 (2022) lists Senate co-sponsors, then House ones such as
      // Rep. Nguyen), so a co-sponsor's chamber is unknown from that page (null): checkRecordGroup lets
      // another actor page of the same instrument settle it, and fails closed when none does.
      return actorChamber('word-before-reading', pt, a, instrument, extra, bounds)
        ?? (isCoSponsorListing(pt, a) ? null : actorChamber('bill-origin', pt, a, instrument, extra, bounds));
    case 'page-header':
      for (let k = 0; k < pt.length; k++) { const c = chamberAt(pt, k, extra); if (c) return c; }
      return null;
    case 'bill-origin': {
      const tok = billTokenOf(instrument);
      if (!tok) return null;
      let origin: Chamber | null = null;
      if (tok.startsWith('s')) origin = 'upper';
      else if (tok.startsWith('a') || tok.startsWith('h')) origin = 'lower';
      if (!origin) return null;
      // A co-author printed on the same page can sit in the OTHER chamber (final review fix 1: a
      // namesake co-author, e.g. "Coauthors: Assembly Member Quirk" on a Senate-origin bill, must not
      // pass for a Senator named Quirk just because the bill itself started in the Senate). The nearest
      // chamber word before the actor's own surname is the actor's own title, if the page prints one;
      // that overrides the bill's chamber of origin. No chamber word nearby (the common case: a Digest
      // that opens "SB 580, Durazo." with no title) keeps the bill-origin reading.
      const before = chamberBefore(pt, a, extra);
      if (before && before !== origin) return null;
      return origin;
    }
    case 'none': return null;
  }
}

// Amendment-markup spec §2/§4: fences are exactly `[deleted: … ]`, and a literal `]` inside the
// deleted text is written `〕` by the fence writer, so the first `]` after `[deleted: ` always closes
// it. Matched against the SAME normalizeText'd page text a quote's span is located in — normalizeText
// only lowercases and collapses whitespace, so the fence delimiters survive unchanged.
const DELETED_FENCE_RE = /\[deleted: [^\]]*\]/g;
/** An opening `[deleted: ` with no closing `]` anywhere after it (a truncated snapshot, most likely a
 * page cut off mid-fetch) — fail closed by treating it as a fence that runs to the end of the page,
 * rather than reading none of it as deleted. */
const OPEN_FENCE_RE = /\[deleted: /g;
/** Both Indiana's ("is amended to read") and Arizona's (all-caps, since normalizeText lowercases
 * everything) forms read the same after normalizeText. The plural ("Sections … are amended to read")
 * covers a multi-section amendment. */
const AMENDED_TO_READ_RE = /(?:is|are) amended to read/;

/** Every `[deleted: …]` fence's [start, end) character span in a normalizeText'd page. A `[deleted: `
 * with no closing `]` anywhere in the rest of the page runs to the end of the page (fail closed on a
 * truncated snapshot) rather than matching nothing at all. */
function fenceSpans(normalizedPage: string): [number, number][] {
  const spans: [number, number][] = [];
  const closedStarts = new Set<number>();
  for (const m of normalizedPage.matchAll(DELETED_FENCE_RE)) {
    spans.push([m.index!, m.index! + m[0].length]);
    closedStarts.add(m.index!);
  }
  for (const m of normalizedPage.matchAll(OPEN_FENCE_RE)) {
    if (!closedStarts.has(m.index!)) spans.push([m.index!, normalizedPage.length]);
  }
  return spans;
}

/** Every start index of `needle` in `haystack` (overlapping matches included, fail closed rather than
 * judging only the first — a provision quoted twice on one page, once outside a fence and once inside
 * it, must still be caught when the fenced copy is not the first one found). */
function allIndicesOf(haystack: string, needle: string): number[] {
  if (needle.length === 0) return [];
  const out: number[] = [];
  let i = haystack.indexOf(needle);
  while (i !== -1) { out.push(i); i = haystack.indexOf(needle, i + 1); }
  return out;
}

export function checkRecordGroup(i: {
  passages: Passage[]; snapshotText: ReadonlyMap<string, string>; fullName: string;
  /** The seat's chamber (seatChamber(office_title)), used when a passage has no profile. */
  chamber?: Chamber | null;
  /** The source profile of a passage (sourceProfiles.ts). Absent/null -> GENERIC_RULES + i.chamber. */
  profileOf?: (p: Passage) => PassageProfile | null;
  /** Amendment-markup spec §3/§4: what this passage's snapshot shows about kept deletions. Absent
   * (no snapshots.json amendment_markup available to the caller) reads as 'unknown' — fail closed. */
  markupOf?: (p: Passage) => 'kept' | 'none' | 'unknown';
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
  // Memoised per passage: profileOf can be an expensive load (a later task reads it from disk), and
  // this function is otherwise called up to three times per passage (located, the chamber loop, the
  // name-collision loop).
  const profCache = new WeakMap<Passage, PassageProfile>();
  const prof = (p: Passage): PassageProfile => {
    let v = profCache.get(p);
    if (!v) { v = i.profileOf?.(p) ?? { rules: GENERIC_RULES, chamber: i.chamber ?? null }; profCache.set(p, v); }
    return v;
  };

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
    const bounds = prof(p).rules.vote_block === 'whole-page' ? [] : ayeBoundaries(pt);
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

  // The vote that lists the actor must be the seat's chamber, read by the source's chamber rule.
  // Skipped when the seat has no chamber here or the source has none ('none'). Fails closed when no
  // occurrence shows it. The search starts at the surname, so a title inside the actor_quote counts
  // ("Authored by: Sen. Shelli Yoder").
  // An AZ overview co-sponsor line cannot show the chamber (see 'reading-else-bill-origin'). It is
  // deferred: it passes when another actor page of this instrument shows the seat's chamber, and fails
  // closed when it is the group's only actor evidence.
  let chamberShown = false;
  let deferred = false;
  for (const l of located) {
    const { rules, chamber } = prof(l.p);
    if (!chamber || rules.chamber === 'none') continue;
    // Normalised the SAME way as page tokens (words()), so a profile author's "Concurrence" or
    // "3rd Reading" matches the lowercased, punctuation-stripped token the page actually produces.
    // A multi-word entry can never match a single page token, so it is dropped rather than silently
    // reduced to its first word.
    const extra = new Set(rules.not_chamber_after.map((w) => words(w)).filter((t) => t.length === 1).map((t) => t[0]));
    const inQuote = Math.max(0, words(l.p.actor_quote!).indexOf(last));
    if (l.occ.some((a) => actorChamber(rules.chamber, l.pt, a + inQuote, l.p.instrument, extra, l.bounds) === chamber)) { chamberShown = true; continue; }
    const coSponsorOnly = rules.chamber === 'reading-else-bill-origin' && l.occ.length > 0 && l.occ.every((a) =>
      isCoSponsorListing(l.pt, a + inQuote) && actorChamber('word-before-reading', l.pt, a + inQuote, l.p.instrument, extra, l.bounds) === null);
    if (coSponsorOnly) deferred = true;
    else out.add('chamber-not-evidenced');
  }
  if (deferred && !chamberShown) out.add('chamber-not-evidenced');

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
    const fullNameRequired = prof(p).rules.name_format === 'full-name';
    if (blockCount < 2 && !common && !fullNameRequired) continue;
    // 'surname-initial' (Indiana roll calls): the page lists the whole chamber and prints an initial
    // whenever two members share a surname ("Smith, V", "Young, J"). A surname printed ONCE on the
    // whole page, with no initial after it, therefore names exactly one member of that chamber — a
    // common surname needs no given name there. (The chamber and date checks still apply.)
    if (prof(p).rules.name_format === 'surname-initial' && common) {
      const onPage = pt.map((w, k) => (w === last ? k : -1)).filter((k) => k >= 0);
      if (onPage.length === 1 && (pt[onPage[0] + 1] ?? '').length !== 1) continue;
    }
    const aq = words(p.actor_quote!);
    const idx = aq.map((w, k) => (w === last ? k : -1)).filter((k) => k >= 0);
    const qualified = idx.some((k) =>
      (k > 0 && givenNames.includes(aq[k - 1])) || (aq[k + 1] !== undefined && aq[k + 1].length === 1 && aq[k + 1] === first[0]));
    if (!qualified) out.add('name-collision');
  }

  // The provision is verbatim on some page of the group. For each such page, amendment-markup spec
  // §4 fails closed: a quote sitting inside a `[deleted: …]` fence is words the law REMOVES, never
  // the provision; and a page that shows amending language ("is amended to read") from a source
  // whose markup is not known-kept means any deletion could be silently missing from what the coder
  // read as the provision.
  const provisionPassages = i.passages.filter((p) => p.provision_quote && verbatimIn(textOf(p), p.provision_quote));
  if (provisionPassages.length === 0) out.add('provision-missing');
  for (const p of provisionPassages) {
    const page = normalizeText(textOf(p));
    const q = normalizeText(p.provision_quote!);
    const starts = allIndicesOf(page, q);
    if (starts.length === 0) {
      // verbatimIn (a substring test) said this quote is on the page, but indexOf cannot find it —
      // should not happen, since both read the same normalizeText'd string, but fail closed rather
      // than silently passing a quote this check cannot itself locate.
      out.add('provision-deleted');
    } else {
      const spans = fenceSpans(page);
      // ANY occurrence overlapping a fence is enough — a provision quoted twice on one page (a
      // digest and the operative section, say) is deleted if even one copy sits inside a fence,
      // regardless of which occurrence comes first.
      if (starts.some((start) => { const end = start + q.length; return spans.some(([fs, fe]) => start < fe && fs < end); })) {
        out.add('provision-deleted');
      }
    }
    const { rules } = prof(p);
    const markup = i.markupOf?.(p) ?? 'unknown';
    if (AMENDED_TO_READ_RE.test(page) && rules.amendment_text !== 'final' && markup !== 'kept') out.add('amendment-markup-lost');
  }

  // A vote must come from a vote page, with a word-bounded, readable and divided tally.
  if (i.passages.some((p) => p.record_kind === 'vote')) {
    const votePages = actorPassages.filter((p) => p.record_kind === 'vote');
    if (votePages.length === 0) out.add('vote-not-evidenced');
    for (const p of votePages) {
      const t = p.tally_quote && quoteWordsIn(textOf(p), p.tally_quote) ? parseTally(p.tally_quote, prof(p).rules.tally_format) : null;
      // A 0-0 tally proves no division at all: fail closed (final review fix 3).
      if (!t || t.ayes + t.noes === 0) out.add('tally-unreadable');
      else if (isNearUnanimous(t)) out.add('near-unanimous-vote');
    }
  }
  return { findings: [...out], actorPassages };
}
