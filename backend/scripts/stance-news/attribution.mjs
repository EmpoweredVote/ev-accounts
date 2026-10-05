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

/**
 * Name pattern: first and each middle token optional, surname required.
 * 🔴 Every part is regex-escaped. A middle INITIAL carries a dot — "Roger J. Reinert" produced
 * `(?:J.\s+)?`, where the dot matches any character. Harmless there, dangerous in general.
 */
const esc = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
/**
 * 🔴 `requireFirst` is for a surname that is also an ordinary English word. Kaohly Her is the
 * case in this programme. With the first name optional the pattern is effectively a bare `Her`,
 * and two things go wrong at once: attribution can fire on the pronoun, and the ambiguity check
 * in attribute_quotes.mjs reads any title-case headline — "Mayor Backs Her Budget Plan",
 * "Residents Told Her They Wanted More Shelter Beds" — as naming a DIFFERENT person called Her,
 * and excludes the article. That is the false-zero direction, and no stoplist can enumerate
 * every English verb. For such a name, require the full name and do not use bare-surname
 * attribution at all.
 */
export function nameRe(first, middles = [], surname, { requireFirst = false } = {}) {
  const mid = (middles || []).map((m) => `(?:${esc(m)}\\s+)?`).join('');
  return requireFirst ? `${esc(first)}\\s+${mid}${esc(surname)}` : `(?:${esc(first)}\\s+)?${mid}${esc(surname)}`;
}

/**
 * Quotes in `text` safely attributable to this person.
 * The speech verb is REQUIRED — making it optional attributed a school principal's quote to a
 * councilmember because the NEXT SENTENCE merely began with her name.
 */
export function findAttributed(text, first, middles, surname, opts = {}) {
  // Back-compat: findAttributed(text, first, surname)
  if (typeof middles === 'string' && surname === undefined) { surname = middles; middles = []; }
  const nm = nameRe(first, middles, surname, opts);
  const re = quoteRe();
  const out = [];
  let m;
  while ((m = re.exec(text)) !== null) {
    const end = m.index + m[0].length;
    const after = text.slice(end, end + 70);
    const before = text.slice(Math.max(0, m.index - 70), m.index);
    // 🔴 CONSECUTIVE QUOTES BELONG TO THE LAST-NAMED SPEAKER. This caught a rec-centre worker's
    // testimony being attributed to Council President Noecker:
    //     "We're not asking for much," said Rosie Kohnen, a community rec leader on the East Side.
    //     "I mean, I barely make it. … I've been homeless before."  Noecker said AFSCME had…
    // The second quote is still Kohnen's; "Noecker said …" begins a NEW sentence. Requiring a
    // speech verb — the fix for the school-principal bug — does not catch this, because the verb
    // is there.
    //
    // ⚠ MY FIRST FIX FOR THIS WAS WRONG and is worth recording. I rejected any quote ending in
    // terminal punctuation, reasoning that an attribution tag follows a comma. That dropped 24 of
    // Mayor Her's 88 quotes, including
    //     "Are we saying we're investing, or taking credit for other people's work?" Her asked.
    // which is textbook attribution. Terminal punctuation is NOT the discriminator; a preceding
    // attribution to a DIFFERENT NAMED PERSON is. Requiring a capitalised name means "…," she
    // said' and '…," the governor said' do not trip it.
    const prevSpeaker = new RegExp(`(?:${VERB})\\s+([A-Z][a-z]+\\s+[A-Z][a-z]+)|([A-Z][a-z]+\\s+[A-Z][a-z]+)\\s+(?:${VERB})`, 'g');
    let otherSpoke = false;
    for (const pm of before.matchAll(prevSpeaker)) {
      const who = (pm[1] || pm[2] || '').trim();
      if (who && !new RegExp(nm, 'i').test(who)) otherSpoke = true;
    }
    const tagA = !otherSpoke && (new RegExp(`^[,.]?\\s*(?:${VERB})\\s+(?:${TITLE})?${nm}`, 'i').test(after)
      || new RegExp(`^[,.]?\\s*${nm}\\s+(?:${VERB})`, 'i').test(after));
    // `before` is unaffected: "Noecker said, "..."" puts the tag ahead of the quote, where the
    // quote's own final punctuation says nothing about who is speaking.
    const tagB = new RegExp(`${nm}\\s+(?:${VERB})[,:]?\\s*$`, 'i').test(before);
    if (tagA || tagB) out.push(m[1].trim());
  }
  return out;
}
