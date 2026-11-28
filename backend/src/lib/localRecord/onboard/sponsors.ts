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

const MARKER = /\b(co-?sponsored|sponsored)\s+by\b/gi;
const TITLE = /^(?:Councilmembers?|Councilwoman|Councilman|Councilor|Cms?\.?|CM\.?)$/;
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
function readNames(segment: string): { names: string[]; placeholder: boolean } {
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
    if (k > 0 && sep !== 'and' && !(sep === 'comma' && found.slice(k + 1).some((f) => f.sep === 'and'))) break;
    accepted.push(text);
  }
  let names = accepted;
  // Names read without any title, while a title still follows, mean the sentence is not what it seems: read nothing.
  if (!sawTitle && tokens.slice(i).some((t) => TITLE.test(t.replace(/[,;.]+$/, '')))) names = [];
  return { names, placeholder };
}

function parseSentence(sentence: string): { names: SponsorName[]; placeholder: boolean } | null {
  const markers = [...sentence.matchAll(MARKER)];
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
const HEADING = /\b(Amendment|Reasonable Condition|RC)\s+#?([0-9Oo]+)(?:\s+\(?revised\)?)?\s+Synopsis\s*:/gi;

interface LocatedSentence extends SponsorSentence {
  /** Where the label's heading starts in the collapsed text. */
  at: number;
}

function documentSentences(flat: string): LocatedSentence[] {
  const headings = [...flat.matchAll(HEADING)];
  const out: LocatedSentence[] = [];
  headings.forEach((h, k) => {
    const number = h[2].replace(/[Oo]/g, '0');
    const label = /^amendment$/i.test(h[1]) ? `Amendment ${twoDigits(number)}` : `Reasonable Condition ${Number(number)}`;
    const from = h.index! + h[0].length;
    const to = k + 1 < headings.length ? headings[k + 1].index! : flat.length;
    // Only the synopsis itself counts: the first sponsor sentence, reached before any sentence that opens with another
    // item ("Ordinance 25-09 was sponsored by ..."), and worded as being about this item ("This amendment ...").
    for (const sentence of splitSentences(flat.slice(from, to))) {
      if (OTHER_ITEM.test(sentence)) break;
      const parsed = parseSentence(sentence);
      if (!parsed) continue;
      if (ABOUT_THIS_ITEM.test(sentence)) {
        out.push({ label, sentence, names: parsed.names, placeholder: parsed.placeholder, at: h.index! });
      }
      break;
    }
  });
  return out;
}

/** Sponsor sentences in a memorandum or minutes, each labelled by its preceding "<Label> Synopsis:" heading. */
export function sponsorSentencesFromDocument(text: string): SponsorSentence[] {
  return documentSentences(collapse(text)).map(({ at: _at, ...s }) => s);
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
//   - the chosen motion is of kind 2 and the same label's motion naming a different item is printed after the heading.
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
function itemBefore(flat: string, at: number, label: string, to: number): string | null {
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
  // The label's own motion printed after the heading, naming another item.
  if (best.kind === 1) {
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
): DocumentSponsorSentence[] {
  const flat = collapse(text);
  const located = documentSentences(flat);
  const tied = located.map(({ at }, k) =>
    itemBefore(flat, at, located[k].label!, k + 1 < located.length ? located[k + 1].at : flat.length),
  );
  return located.map(({ at: _at, ...s }, k) => {
    let itemNumber = tied[k];
    if (itemNumber) {
      // A roll call with this label on an item that no other synopsis of this document claims, and none on the tied
      // item, contradicts the tie. (Roll calls on items other synopses are tied to are just those items' votes: one
      // document can hold "Amendment 01" on several items.)
      const claimed = new Set(located.flatMap((l, j) => (j !== k && labelKey(l.label!) === labelKey(s.label!) && tied[j] ? [tied[j]!] : [])));
      const mine = rollCalls.filter((r) => labelKey(r.question) === labelKey(s.label!));
      if (mine.length > 0 && !mine.some((r) => r.itemNumber === itemNumber) && mine.some((r) => !claimed.has(r.itemNumber))) itemNumber = null;
    }
    return { ...s, itemNumber };
  });
}
