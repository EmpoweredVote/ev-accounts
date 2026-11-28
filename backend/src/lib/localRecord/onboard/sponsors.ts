// Sponsor sentence finder for the Bloomington Common Council record.
//
// Pure text parsing: finds the sentences that say who sponsored an item (an ordinance, a resolution, an amendment or
// a reasonable condition) and pulls out the names exactly as printed. A later step resolves names to people. An
// unclear sentence never produces a guessed name: fewer names is better than a wrong one.
import { itemNumberFor, twoDigits } from './minutes.js';

export interface SponsorName {
  printed: string;
  role: 'sponsor' | 'cosponsor';
}
export interface SponsorSentence {
  /** null = the item itself; else "Amendment 01", "Reasonable Condition 16". */
  label: string | null;
  /** Exact text, whitespace collapsed. */
  sentence: string;
  /** Empty when the sentence holds a placeholder. */
  names: SponsorName[];
  /** "[CM sponsor needed]" and similar bracketed text where a name belongs. */
  placeholder: boolean;
}

const collapse = (s: string): string => s.replace(/\s+/g, ' ').trim();

/** Words that end in a period without ending the sentence. */
const ABBREVIATION = /(?:^|\s)(?:Cm|Cms|CM|Mr|Ms|Mrs|Dr|No|Sec|St|[A-Z])$/;

/** Split text into sentences. A period after "Cm." or a single initial does not end a sentence. */
function splitSentences(text: string): string[] {
  const out: string[] = [];
  let start = 0;
  const end = /[.!?]\s+(?=[A-Z"“(\[])/g;
  let m: RegExpExecArray | null;
  while ((m = end.exec(text))) {
    const before = text.slice(start, m.index);
    if (m[0][0] === '.' && ABBREVIATION.test(before)) continue;
    out.push(text.slice(start, m.index + 1));
    start = m.index + m[0].length;
  }
  out.push(text.slice(start));
  return out.map(collapse).filter(Boolean);
}

const MARKER = /\b(co-?sponsored|sponsored|co-?authored|authored)\s+by\b/gi;
/** "authored by Public Works" is not a council sponsor: an authored marker counts only with a council title in its names. */
const COUNCIL_TITLE = /\b(?:Councilmembers?|Council\s+members?|Cms?\.?|CMs?\.?)\s/;
const TITLE = /^(?:Councilmembers?|Councilwoman|Councilman|Councilor|CMs?\.?|Cms?\.?)$/;
const NOT_A_NAME = new Set([
  'The', 'This', 'That', 'It', 'Its', 'These', 'Council', 'Mayor', 'Common', 'City', 'Ordinance', 'Resolution',
  'Amendment', 'Section', 'Title', 'Reasonable', 'Condition', 'RC', 'Bloomington', 'Indiana', 'In', 'If', 'As',
  'Is', 'For', 'To', 'Of', 'On', 'At', 'By', 'With', 'Which', 'Who', 'Committee', 'Code', 'Chapter',
]);

/** Skip a heading caught inside a name list. Returns how many tokens it covers, or 0. */
function headingLength(tokens: string[], i: number): number {
  const t = (k: number) => (tokens[i + k] ?? '').replace(/[,;.:]+$/, '');
  if (/^Amendment$/i.test(t(0)) && /^[0-9Oo]+$/.test(t(1))) return 2;
  if (/^RC$/i.test(t(0)) && /^\d+$/.test(t(1))) return 2;
  if (/^Reasonable$/i.test(t(0)) && /^Condition$/i.test(t(1)) && /^\d+$/.test(t(2))) return 3;
  return 0;
}

const isNameWord = (w: string): boolean => /^[A-Z][A-Za-z'’\-]*$/.test(w) && !NOT_A_NAME.has(w) && !TITLE.test(w);

/** Read the names at the start of `segment` (the text right after "sponsored by"). */
function readNames(segment: string, opts: { commaList?: boolean } = {}): { names: string[]; placeholder: boolean } {
  const tokens = segment
    .replace(/Council\s+members?/gi, 'Councilmember')
    .replace(/([A-Za-z])- (?=[A-Z])/g, '$1-') // a name wrapped at its hyphen: "Piedmont- Smith"
    .split(/\s+/)
    .filter(Boolean);
  // Each name remembers what came before it: "and", a comma/semicolon, or nothing.
  type Sep = 'none' | 'and' | 'comma';
  let found: { text: string; sep: Sep }[] = [];
  let pending: Sep = 'none';
  let sawTitle = false;
  let placeholder = false;
  let current: string[] = [];
  const flush = () => {
    if (current.length) found.push({ text: current.join(' '), sep: pending });
    if (current.length) pending = 'none';
    current = [];
  };
  let i = 0;
  while (i < tokens.length) {
    const skip = headingLength(tokens, i);
    if (skip) {
      i += skip;
      continue;
    }
    const raw = tokens[i];
    if (raw.startsWith('[')) {
      // Bracketed text where a name belongs: skip to the closing bracket and record the placeholder.
      placeholder = true;
      flush();
      while (i < tokens.length && !tokens[i].includes(']')) i++;
      i++;
      continue;
    }
    const word = raw.replace(/[,;]+$/, '');
    const separated = word !== raw;
    if (/^(?:and|&)$/i.test(word)) {
      flush();
      pending = 'and';
      i++;
      continue;
    }
    if (TITLE.test(word)) {
      // Words before the first title ("Dwelling, Triplex, and Dwelling, Councilmembers X") are wrapped heading text.
      if (!sawTitle) {
        current = [];
        found = [];
        pending = 'none';
      }
      sawTitle = true;
      flush();
      i++;
      continue;
    }
    const bare = word.replace(/\.$/, '');
    if (!isNameWord(bare)) break;
    // A trailing period on the last word is the end of the sentence; a period inside a list stops it without that word.
    if (word.endsWith('.') && i < tokens.length - 1) {
      // "Dr.", "J.", "Sec.", "Jr.": an abbreviation, not a name. Drop it and the name it may belong to, and stop.
      current = [];
      break;
    }
    current.push(bare);
    if (separated) {
      flush();
      pending = 'comma';
    }
    i++;
  }
  flush();
  // After the first name, another counts only after "and", or in a comma list that a later "and" closes.
  // "Cm. Sims, Cm. Volan moved to table it" names one person, not two.
  const accepted: string[] = [];
  for (let k = 0; k < found.length; k++) {
    const { text, sep } = found[k];
    // A heading line holds nothing but the names, so a plain comma list is complete there (opts.commaList).
    if (k > 0 && sep !== 'and' && !(sep === 'comma' && (opts.commaList || found.slice(k + 1).some((f) => f.sep === 'and')))) break;
    accepted.push(text);
  }
  let names = accepted;
  // Names read without any title, while a title still follows, mean the sentence is not what it seems: read nothing.
  if (!sawTitle && tokens.slice(i).some((t) => TITLE.test(t.replace(/[,;.]+$/, '')))) names = [];
  return { names, placeholder };
}

function parseSentence(sentence: string): { names: SponsorName[]; placeholder: boolean } | null {
  const markers = [...sentence.matchAll(MARKER)].filter((m, k, all) => {
    if (!/authored/i.test(m[1])) return true;
    const to = k + 1 < all.length ? all[k + 1].index! : sentence.length;
    return COUNCIL_TITLE.test(sentence.slice(m.index! + m[0].length, to));
  });
  if (!markers.length) {
    return /\[[^\]]*sponsor[^\]]*\]/i.test(sentence) ? { names: [], placeholder: true } : null;
  }
  const names: SponsorName[] = [];
  let placeholder = false;
  markers.forEach((m, k) => {
    const from = m.index! + m[0].length;
    const to = k + 1 < markers.length ? markers[k + 1].index! : sentence.length;
    const read = readNames(sentence.slice(from, to));
    if (read.placeholder) placeholder = true;
    const role = /^co/i.test(m[1]) ? 'cosponsor' : 'sponsor';
    for (const printed of read.names) names.push({ printed, role });
  });
  return { names, placeholder };
}

function sentencesWithSponsors(text: string, label: string | null): SponsorSentence[] {
  const out: SponsorSentence[] = [];
  for (const sentence of splitSentences(text)) {
    const parsed = parseSentence(sentence);
    if (parsed) out.push({ label, sentence, names: parsed.names, placeholder: parsed.placeholder });
  }
  return out;
}

/** Sponsor sentences in a legislation-feed synopsis (always about the item itself, so label is null). */
export function sponsorSentencesFromSynopsis(synopsis: string): SponsorSentence[] {
  return sentencesWithSponsors(synopsis, null);
}

const OTHER_ITEM = /^(?:Ordinance|Resolution|Appropriation Ordinance|Amendment|Reasonable Condition|RC)\s+(?:No\.\s*)?\d/i;
const ABOUT_THIS_ITEM = /^(?:This|The)\s+(?:amendment|reasonable condition|RC)\b/i;
/** A sentence that opens "This Ordinance", "The Resolution", "This Appropriation Ordinance": about the item itself. */
const ABOUT_THE_ITEM = /^(?:This|The)\s+(?:Appropriation\s+)?(?:Ordinance|Resolution)\b/i;

/**
 * The sponsor sentences of a feed synopsis that name the item's own sponsors. Allow-list: only a sentence that opens
 * "This Ordinance ...", "This Resolution ..." (or "The ..."). A sentence about an amendment or a condition, or any
 * other wording, is left out: fewer sponsors is better than a wrong one.
 */
export function itemSponsorSentencesFromSynopsis(synopsis: string): SponsorSentence[] {
  return sponsorSentencesFromSynopsis(synopsis).filter((s) => ABOUT_THE_ITEM.test(s.sentence));
}
// Group 1 is set for a sub-amendment heading ("Amendment A to Amendment 01 Synopsis:"). Its sponsors are not
// Amendment 01's, and the record has no label for a sub-amendment, so it never ties to an item (see `nested`).
const HEADING = /\b((?:Sub-?amendment|Amendment|Reasonable Condition|RC)\s+#?[0-9A-Za-z]+\s+to\s+)?(Amendment|Reasonable Condition|RC)\s+#?([0-9Oo]+)(?:\s+\(?revised\)?)?\s+Synopsis\s*:/gi;

interface LocatedSentence extends SponsorSentence {
  /** Where the label's heading starts in the collapsed text. */
  at: number;
  /** A sub-amendment's heading: its sentence never ties to an item, so names in it give an exception, never a row. */
  nested: boolean;
}

function documentSentences(flat: string): LocatedSentence[] {
  const headings = [...flat.matchAll(HEADING)];
  const out: LocatedSentence[] = [];
  headings.forEach((h, k) => {
    const nested = h[1] !== undefined;
    const number = h[3].replace(/[Oo]/g, '0');
    const own = /^amendment$/i.test(h[2]) ? `Amendment ${twoDigits(number)}` : `Reasonable Condition ${Number(number)}`;
    const label = nested ? collapse(`${h[1]}${own}`) : own;
    const from = h.index! + h[0].length;
    const to = k + 1 < headings.length ? headings[k + 1].index! : flat.length;
    // Only the synopsis itself counts: the first sponsor sentence, reached before any sentence that opens with another
    // item ("Ordinance 25-09 was sponsored by ..."), and worded as being about this item ("This amendment ...").
    for (const sentence of splitSentences(flat.slice(from, to))) {
      if (OTHER_ITEM.test(sentence)) break;
      const parsed = parseSentence(sentence);
      if (!parsed) continue;
      if (ABOUT_THIS_ITEM.test(sentence)) {
        out.push({ label, sentence, names: parsed.names, placeholder: parsed.placeholder, at: h.index!, nested });
      }
      break;
    }
  });
  return out;
}

/** Sponsor sentences in a memorandum or minutes, each labelled by its preceding "<Label> Synopsis:" heading. */
export function sponsorSentencesFromDocument(text: string): SponsorSentence[] {
  return documentSentences(collapse(text)).filter((s) => !s.nested).map(({ at: _at, nested: _n, ...s }) => s);
}

// Which item a document sentence belongs to. A synopsis heading ("Amendment 01 Synopsis:") never names its item, so
// the item is the one a motion introduced just before it. Only strong evidence ties; anything else gives null and the
// caller raises sponsor_unresolved (no_item). Checked on 263 cached Bloomington files. A bare "Ordinance 21-03" in
// prose never counts: a synopsis or a note often cites another item ("Passed as Ordinance 2026-02 on January 14").
//   1. Label motion: "... moved/seconded ... Amendment 01 to Ordinance 22-13" (must say moved or seconded, and the
//      label must match the sentence's label).
//   2. Item-opening motion: "... moved/seconded that Ordinance 2026-06 [as amended] be adopted / read / introduced /
//      approved" or "... to adopt / introduce / approve Ordinance 24-05".
// The nearest of the two before the heading wins, unless:
//   - another item number appears between that motion and the heading (the text moved on), or
//   - the chosen motion is of kind 2 and the same label's motion naming a different item is printed after the heading,
//     anywhere up to the next synopsis heading or the next item-opening motion, whichever is later (the end of the
//     document when there is neither). A run of synopsis headings is often printed before the motions that take them
//     up, so the search does not stop at the next heading.
// The caller may add a last check against the document's own roll calls (see `rollCalls`).
//
// ITEM_RE: "No." is optional ("Ordinance No. 2026-06"). The "-?" before the number is for a stray hyphen the real
// minutes print ("Ordinance -21-06").
const ITEM_RE = String.raw`(Appropriation Ordinance|Ordinance|Resolution)\s+(?:No\.?\s*)?-?(\d{2,4}-\s*\d{1,3})`;
const ANY_ITEM = new RegExp(ITEM_RE, 'gi');
const OPENS_ITEM = new RegExp(
  String.raw`\b(?:moved|seconded)\b[^.]{0,120}?(?:\bthat\s+${ITEM_RE}(?:,?\s+as\s+amended,?)?\s+be\s+(?:read|adopted|introduced|approved)\b|\bto\s+(?:adopt|introduce|approve)\s+${ITEM_RE})`,
  'gi',
);

function labelMotion(label: string): RegExp {
  const m = /^(Amendment|Reasonable Condition) (\d+)$/.exec(label)!;
  const n = Number(m[2]);
  const words = m[1] === 'Amendment' ? 'Amendment|Am' : 'Reasonable Conditions?|RCs?';
  return new RegExp(
    String.raw`\b(?:moved|seconded)\b[^.]{0,120}?(?<![0-9A-Za-z])(?:${words})\s+#?[0Oo]*${n}(?![0-9])[^.]{0,40}?\bto\s+${ITEM_RE}`,
    'gi',
  );
}

/** Every item the match names, as record item numbers (null entries for an unknown type are dropped). */
function itemsOf(m: RegExpMatchArray): string[] {
  const out: string[] = [];
  for (let g = 1; g + 1 < m.length; g += 2) {
    if (m[g] === undefined) continue;
    const item = itemNumberFor(m[g], m[g + 1]);
    if (item) out.push(item);
  }
  return out;
}

/** The item a label's synopsis belongs to, or null when the document did not introduce one with strong evidence. */
function itemBefore(flat: string, at: number, label: string, nextHeading: number): string | null {
  const before = flat.slice(0, at);
  const best = { end: -1, item: null as string | null, kind: 0 };
  [labelMotion(label), OPENS_ITEM].forEach((re, kind) => {
    for (const m of before.matchAll(re)) {
      const end = m.index! + m[0].length;
      const item = itemsOf(m)[0] ?? null;
      if (item && end > best.end) Object.assign(best, { end, item, kind });
    }
  });
  if (!best.item) return null;
  // Another item named between the motion and the heading: the text moved on.
  for (const m of flat.slice(best.end, at).matchAll(ANY_ITEM)) {
    if (itemsOf(m)[0] !== best.item) return null;
  }
  // The label's own motion printed after the heading, naming another item, before the next item is opened.
  if (best.kind === 1) {
    const opens = new RegExp(OPENS_ITEM.source, 'gi');
    opens.lastIndex = at;
    const next = opens.exec(flat);
    const to = nextHeading >= flat.length || !next ? flat.length : Math.max(nextHeading, next.index);
    for (const m of flat.slice(at, to).matchAll(labelMotion(label))) {
      const other = itemsOf(m)[0];
      if (other && other !== best.item) return null;
    }
  }
  return best.item;
}

export interface DocumentSponsorSentence extends SponsorSentence {
  /** "Ord 21-03" form; null when no item was introduced before the sentence's heading. */
  itemNumber: string | null;
}

const labelKey = (q: string): string | null => {
  const m = /^(Amendment|Reasonable Condition) (\d+)$/.exec(q);
  return m ? `${m[1]} ${Number(m[2])}` : null;
};

/**
 * Like sponsorSentencesFromDocument, with each sentence tied to its item (see above). `rollCalls` (the same
 * document's parsed roll calls) is a last check: when roll calls carry this label on another item and none on the
 * tied item (and not claimed by another synopsis of the document), the tie is dropped. An amendment with no roll call at all still ties through its motion.
 */
export function sponsorSentencesWithItems(
  text: string,
  rollCalls: { itemNumber: string; question: string }[] = [],
  /**
   * The text before the right margin column was dropped. A "Council Sponsor:" line can sit in that column (Res 2026-13
   * in meeting file 17744), so headings are read from this text when given.
   */
  unmarginedText?: string,
): DocumentSponsorSentence[] {
  return [...synopsisSentencesWithItems(text, rollCalls), ...councilSponsorHeadings(unmarginedText ?? text)];
}

// ---- "Council Sponsor:" agenda headings --------------------------------------------------------------------------
//
// A memorandum prints each item as a heading block: the item line ("Resolution 2026-15"), the title (one to three
// lines) and, at the end of the title, "Council Sponsor: CM Rollo". The item is the one named on that same heading
// block, never the nearest motion (a motion may name another item). A name may wrap onto the next line.

const ITEM_HEADING = /^(?:\d+(?:\.\d+)*\.?\s*)?(Appropriation Ordinance|Ordinance|Resolution)\s+(\d{4}-\d{1,3})(?:\s*\([^)]*\))?$/;
const SPONSOR_LINE = /Council\s+(Co-?\s*)?Sponsors?(?:\s*[:\-\u2013\u2014]\s*|\s+(?=N\/A\b))/i;
/** How far above a Council Sponsor line its item heading may be (title lines in between). */
const HEADING_REACH = 6;

/** A short line that is only name words ("Flaherty", "Piedmont-Smith"): the rest of a name that wrapped. */
const isNameOnly = (line: string): boolean => {
  const words = line.replace(/([A-Za-z])- (?=[A-Z])/g, '$1-').split(/\s+/).filter(Boolean);
  return words.length >= 1 && words.length <= 3 && words.every((w) => isNameWord(w.replace(/[,;]+$/, '')) || /^(?:and|&)$/i.test(w));
};

export function councilSponsorHeadings(text: string): DocumentSponsorSentence[] {
  const lines: string[] = [];
  for (const l of text.replace(/[\u200b\u00ad]/g, '').split('\n').map(collapse).filter(Boolean)) {
    // The marker itself can wrap: "... Council" / "Sponsor: CM Stosberg" (Ord 2026-23, meeting file 17809).
    if (lines.length && /\bCouncil$/.test(lines[lines.length - 1]) && /^(?:Co-?\s*)?Sponsors?\s*[:\-\u2013\u2014]/i.test(l)) lines[lines.length - 1] += ` ${l}`;
    else lines.push(l);
  }
  const out: DocumentSponsorSentence[] = [];
  lines.forEach((line, i) => {
    const m = SPONSOR_LINE.exec(line);
    if (!m) return;
    let rest = line.slice(m.index + m[0].length).trim();
    const sentence0 = line.slice(m.index);
    // "N/A", "None" or nothing: the city says there is no council sponsor.
    if (!rest || /^(?:N\/A|none)\b/i.test(rest)) return;
    // The item: the nearest heading above, with no motion or other text that names an item between.
    let itemNumber: string | null = null;
    for (let j = i - 1; j >= Math.max(0, i - HEADING_REACH); j--) {
      if (/\b(?:moved|seconded)\b/i.test(lines[j])) break;
      // Stay inside this heading's own block: an earlier Council Sponsor line ends the one above. An item line that
      // could not be read (margin text, another form) must not let the search reach the previous item.
      if (SPONSOR_LINE.test(lines[j])) break;
      const h = ITEM_HEADING.exec(lines[j]);
      if (h) {
        itemNumber = itemNumberFor(h[1], h[2]);
        break;
      }
    }
    // The name wraps only when this line ends in a bare title (or "and"/a comma) and the next line is only a name.
    let sentence = sentence0;
    const dangling = /(?:^|\s)(?:CMs?\.?|Cms?\.?|Councilmembers?|and|&)$|,$/.test(rest);
    let held = false;
    if (dangling) {
      const next = lines[i + 1];
      if (next !== undefined && isNameOnly(next)) {
        rest = `${rest} ${next}`;
        sentence = `${sentence0} ${next}`;
      } else held = true;
    }
    const role: 'sponsor' | 'cosponsor' = m[1] ? 'cosponsor' : 'sponsor';
    const read = held ? { names: [] as string[], placeholder: false } : readNames(rest, { commaList: true });
    out.push({
      label: null, sentence: collapse(sentence), placeholder: read.placeholder,
      names: read.names.map((printed) => ({ printed, role })), itemNumber,
    });
  });
  return out;
}

function synopsisSentencesWithItems(
  text: string,
  rollCalls: { itemNumber: string; question: string }[] = [],
): DocumentSponsorSentence[] {
  const flat = collapse(text);
  const located = documentSentences(flat);
  const tied = located.map(({ at, nested, label }, k) =>
    nested ? null : itemBefore(flat, at, label!, k + 1 < located.length ? located[k + 1].at : flat.length),
  );
  return located.map(({ at: _at, nested: _n, ...s }, k) => {
    let itemNumber = tied[k];
    if (itemNumber) {
      const key = labelKey(s.label!);
      const same = located.flatMap((l, j) => (labelKey(l.label!) === key ? [j] : []));
      const mine = rollCalls.filter((r) => labelKey(r.question) === key);
      // Items some synopsis of this label is tied to; roll calls on them are just those items' votes (one document can
      // hold "Amendment 01" on several items).
      const claimedByAny = new Set(same.flatMap((j) => (tied[j] ? [tied[j]!] : [])));
      const unclaimed = mine.some((r) => !claimedByAny.has(r.itemNumber));
      // A roll call with this label on an item no other synopsis claims, and none on the tied item, contradicts the tie.
      const claimed = new Set(same.flatMap((j) => (j !== k && tied[j] ? [tied[j]!] : [])));
      if (mine.length > 0 && !mine.some((r) => r.itemNumber === itemNumber) && mine.some((r) => !claimed.has(r.itemNumber))) itemNumber = null;
      // Two or more synopses of this label tied to the same item, while a roll call of this label sits on an item no
      // synopsis claims: one of them belongs to that other item, and the text does not say which. Drop all of them.
      else if (unclaimed && same.filter((j) => tied[j] === itemNumber).length > 1) itemNumber = null;
    }
    return { ...s, itemNumber };
  });
}
