// The attribution matcher, in ONE place.
//
// 🔴 It used to live inline in attribute_quotes.mjs, and the self-test re-implemented it. A control
// that re-implements the thing it tests is not a control: the copy lost a backslash and reported
// four failures against code that was correct, which is the same defect in the other direction.
// Both the tool and its self-test import this.

export const VERB = 'said|says|told|added|argued|noted|explained|wrote|asked|countered|replied';

// 🔴 THE TITLE LIST IS A VOCABULARY, and it was Saint Paul's: it accepted "councilmember" and
// "council president" but not "Councilor", which is what Duluth and WDIO write. `said Councilor
// Durwachter` failed to attribute, so a member with a rich record returned four quotes from 38
// articles. Every optional title that can sit between the speech verb and the name belongs here.
export const TITLE = '(?:\\d+(?:st|nd|rd|th)\\s+district\\s+(?:city\\s+)?council(?:or|member|man|woman)|at\\s+large\\s+council(?:or|member)'
  + '|council\\s*member|councilmember|council\\s*president|council\\s*vice\\s*president|councilor|councillor|counselor'
  + '|council\\s*woman|councilwoman|council\\s*man|councilman|alderman|alderwoman|mayor|vice\\s*president|president'
  + '|chair|commissioner|supervisor|trustee)\\s+';

const LQ = String.fromCharCode(8220), RQ = String.fromCharCode(8221);

// 🔴🔴 BOTH quote styles, and the pairing is ANCHORED.
// The matcher used to accept curly marks only, while sweep_duluth.mjs normalises &#8220;/&#8221; to
// STRAIGHT quotes — so the two halves of the pipeline disagreed and the attributor was near-blind on
// every outlet that emits entities.
// Accepting straight quotes alone is not enough: they are NOT DIRECTIONAL, so one unpaired `"`
// anywhere earlier in the page shifts every pair after it. WDIO's page carries
// `"Right to Repair ordinance".` in running text, and from there the pairing was off by one, so the
// article produced ZERO attributions although it quotes the member by name beside a speech verb.
// Anchoring restores the parity: an opening mark follows start-of-text, whitespace or a bracket, and
// a closing mark is followed by whitespace, punctuation or end-of-text.
export const quoteRe = () => new RegExp(`(?:^|[\\s(\\[])[${LQ}"]([^${RQ}"]{35,500})[${RQ}"](?=[\\s.,;:!?)\\]]|$)`, 'g');

/**
 * Split a full name into { first, middles, surname }.
 *
 * 🔴🔴 This used to be `const [FIRST, ...rest] = name.split(/\s+/); const SURNAME = rest.join(' ')`,
 * which gives "Lynn Marie Nephew" the surname "Marie Nephew". Nothing matched, and the member
 * returned ZERO attributed quotes from 42 articles. Passing the two-token form instead made her own
 * MIDDLE NAME look like a different person — "Marie Nephew" — and excluded 34 of those 42 articles
 * as ambiguous. One middle name broke the tool in both directions at once.
 *
 * The surname is the LAST token. Tokens between first and surname belong to the same person and must
 * be forgiven by the ambiguity check, never counted as somebody else's first name.
 */
export function parseName(full) {
  const parts = String(full).trim().split(/\s+/);
  return { first: parts[0], middles: parts.slice(1, -1), surname: parts[parts.length - 1] };
}

/** Name pattern: first and each middle token optional, surname required. */
export function nameRe(first, middles = [], surname) {
  const mid = (middles || []).map((m) => `(?:${m}\\s+)?`).join('');
  return `(?:${first}\\s+)?${mid}${surname}`;
}

/**
 * Quotes in `text` safely attributable to this person.
 * The speech verb is REQUIRED — making it optional attributed a school principal's quote to a
 * councilmember because the NEXT SENTENCE merely began with her name.
 */
export function findAttributed(text, first, middles, surname) {
  // Back-compat: findAttributed(text, first, surname)
  if (typeof middles === 'string' && surname === undefined) { surname = middles; middles = []; }
  const nm = nameRe(first, middles, surname);
  const re = quoteRe();
  const out = [];
  let m;
  while ((m = re.exec(text)) !== null) {
    const end = m.index + m[0].length;
    const after = text.slice(end, end + 70);
    const before = text.slice(Math.max(0, m.index - 70), m.index);
    const tagA = new RegExp(`^[,.]?\\s*(?:${VERB})\\s+(?:${TITLE})?${nm}`, 'i').test(after)
      || new RegExp(`^[,.]?\\s*${nm}\\s+(?:${VERB})`, 'i').test(after);
    const tagB = new RegExp(`${nm}\\s+(?:${VERB})[,:]?\\s*$`, 'i').test(before);
    if (tagA || tagB) out.push(m[1].trim());
  }
  return out;
}
