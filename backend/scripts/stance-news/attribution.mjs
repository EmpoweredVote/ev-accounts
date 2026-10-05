// The attribution matcher, in ONE place.
//
// 🔴 It used to live inline in attribute_quotes.mjs, and the self-test re-implemented it. A control
// that re-implements the thing it tests is not a control: the copy lost a backslash and reported
// four failures against code that was correct, which is the same defect in the other direction.
// Both the tool and its self-test now import this.

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
 * Quotes in `text` that are safely attributable to <first> <surname>.
 * The speech verb is REQUIRED — making it optional attributed a school principal's quote to a
 * councilmember because the NEXT SENTENCE merely began with her name.
 */
export function findAttributed(text, first, surname) {
  const nm = `(?:${first}\\s+)?${surname}`;
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
