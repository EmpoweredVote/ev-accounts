// Sponsor sentence finder for the Bloomington Common Council record.
//
// Pure text parsing: finds the sentences that say who sponsored an item (an ordinance, a resolution, an amendment or
// a reasonable condition) and pulls out the names exactly as printed. A later step resolves names to people. An
// unclear sentence never produces a guessed name: fewer names is better than a wrong one.
import { twoDigits } from './minutes.js';

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
    // A trailing period on the last word is the end of the sentence; a period inside a list ends the list after this name.
    current.push(bare);
    if (word.endsWith('.') && i < tokens.length - 1) break;
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
const HEADING = /\b(Amendment|Reasonable Condition|RC)\s+#?([0-9Oo]+)(?:\s+\(?revised\)?)?\s+Synopsis\s*:/gi;

/** Sponsor sentences in a memorandum or minutes, each labelled by its preceding "<Label> Synopsis:" heading. */
export function sponsorSentencesFromDocument(text: string): SponsorSentence[] {
  const flat = collapse(text);
  const headings = [...flat.matchAll(HEADING)];
  const out: SponsorSentence[] = [];
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
      if (ABOUT_THIS_ITEM.test(sentence)) out.push({ label, sentence, names: parsed.names, placeholder: parsed.placeholder });
      break;
    }
  });
  return out;
}
