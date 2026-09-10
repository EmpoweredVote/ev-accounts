/**
 * Claim fingerprinting for cross-day and cross-lane deduplication.
 *
 * A fingerprint has two halves, and the split carries meaning:
 *   topicKey — who/what the claim is about (subject + attribute)
 *   valueKey — the answer
 *
 * Same topicKey + same valueKey  => duplicate: the fact is already covered.
 * Same topicKey + different value => contradiction: two live answers to one
 *                                    question, which is worse than a duplicate.
 */

export interface ClaimTriple {
  subject: string;
  attribute: string;
  value: string;
}

export interface ClaimKeys {
  topicKey: string;
  valueKey: string;
}

/**
 * Words carrying no identifying information: unit nouns, approximation hedges,
 * and articles. Dropping them makes "89" and "89 years old" collide, which is
 * the wiran-1578 / wiran-1661 case.
 */
const NOISE_WORDS = new Set([
  // approximation and comparison hedges
  'approximately', 'approx', 'about', 'around', 'over', 'under', 'nearly',
  'almost', 'least', 'at', 'more', 'than', 'up', 'to', 'some', 'roughly',
  // articles and copulas
  'a', 'an', 'the', 'of', 'in', 'on', 'and', 'or', 'is', 'was', 'were',
  // unit and counting nouns
  'year', 'years', 'month', 'months', 'day', 'days', 'hour', 'hours',
  'week', 'weeks', 'old', 'aged', 'age',
  'person', 'people', 'passenger', 'passengers', 'survivor', 'survivors',
  'nation', 'nations', 'country', 'countries', 'state', 'states',
  'seat', 'seats', 'vote', 'votes', 'percent', 'pct',
  'metre', 'metres', 'meter', 'meters', 'km', 'kilometre', 'kilometres',
  'kilometer', 'kilometers', 'foot', 'feet', 'mile', 'miles',
  'advertisement', 'advertisements', 'ad', 'ads',
  'barrel', 'barrels', 'flight', 'flights', 'airport', 'airports',
  'lodging', 'lodgings', 'complaint', 'complaints', 'institution', 'institutions',
  'cascade', 'cascades', 'attack', 'attacks', 'tanker', 'tankers',
  'total', 'each', 'per',
]);

/** Lowercase, strip accents and punctuation, collapse whitespace. */
function baseNormalize(raw: string): string {
  return raw
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    // strip a trailing possessive 's so "Canada's" collides with "Canada"
    .replace(/[’']s\b/g, '')
    .replace(/[’']/g, '')
    .replace(/[^a-z0-9.%\s-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Drop noise words and re-join. Preserves numbers, including decimals. */
function stripNoise(text: string): string {
  return text
    .split(' ')
    .filter(token => token.length > 0 && !NOISE_WORDS.has(token))
    .join(' ')
    .trim();
}

/**
 * Normalise a claim's value. Thousands separators are removed before
 * punctuation stripping so "1,287" becomes "1287" rather than "1 287".
 *
 * The lookahead requires the comma to be followed by one or more complete
 * three-digit groups with no trailing digit, rather than capturing exactly
 * three digits as part of the match. Because the digits after the comma are
 * matched by lookahead (zero-width) instead of being consumed, each comma is
 * removed independently and the next comma is still visible to the regex on
 * the following match attempt. That makes multi-group numbers collapse in
 * one pass: "1,234,567" becomes "1234567", not the single-group-only
 * "1234,567" a consuming capture group would leave behind.
 */
export function normalizeValue(raw: string): string {
  const digitsJoined = raw.replace(/(\d),(?=(?:\d{3})+(?!\d))/g, '$1');
  return stripNoise(baseNormalize(digitsJoined));
}

/** Normalise a subject or attribute. Same rules, kept separate for clarity. */
function normalizeText(raw: string): string {
  return stripNoise(baseNormalize(raw));
}

export function fingerprintClaim(triple: ClaimTriple): ClaimKeys {
  const subject = normalizeText(triple.subject);
  const attribute = normalizeText(triple.attribute);
  return {
    topicKey: `${subject}|${attribute}`,
    valueKey: normalizeValue(triple.value),
  };
}
