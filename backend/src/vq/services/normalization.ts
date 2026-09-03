/**
 * Civic Name Normalization Pipeline
 *
 * Pure functions, no I/O, fully deterministic.
 * Used by the consensus engine to compare submitted answers.
 *
 * Pipeline (normalizeAnswer):
 *   1. Strip diacritics
 *   2. Lowercase
 *   3. Collapse whitespace (tabs → spaces, collapse multiple spaces, trim)
 *   4. Strip prefixed civic titles (Mayor, Rep., Sen., etc.)
 *   5. Strip generational suffixes (Jr., Sr., II, III, IV)
 *   6. Strip middle initials (single letter followed by period)
 *   7. Apply nickname-to-canonical lookup
 *   8. Token-sort (alphabetical) and rejoin
 *   9. Final trim + collapse
 */

import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
// natural 8.x ships its own types; do NOT install @types/natural
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const natural = require('natural') as any;

// JaroWinklerDistance is a plain function exported from natural
const JaroWinklerDistance = natural.JaroWinklerDistance as (
  a: string,
  b: string,
  options?: { ignoreCase?: boolean }
) => number;

// ---------------------------------------------------------------------------
// Similarity threshold — configurable per environment
//
// TOKEN_THRESHOLD: per-token JaroWinkler threshold (0.93 default).
//   Higher than the commonly cited 0.88 because short civic name tokens need
//   a stricter bound — "maria" vs "mario" scores 0.92 whole-string, which
//   would be a false positive at 0.88. At 0.93, only genuine typos and
//   minor transliterations (one transposed or dropped character) pass.
//   Each token must independently clear this threshold.
//
// Note: Metaphone phonetic fallback is intentionally omitted from answersMatch.
//   Short civic name tokens often share the same Metaphone code despite being
//   different names ("john" → JN, "jane" → JN; "maria" → MR, "mario" → MR).
//   JaroWinkler at 0.93 per-token is sufficient for genuine typos.
// ---------------------------------------------------------------------------
const TOKEN_THRESHOLD = parseFloat(
  process.env['NORMALIZATION_THRESHOLD'] ?? '0.93'
);

// ---------------------------------------------------------------------------
// Nickname → canonical first-name lookup
// ---------------------------------------------------------------------------
const NICKNAME_MAP: Record<string, string> = {
  bob: 'robert',
  bobby: 'robert',
  bill: 'william',
  billy: 'william',
  jim: 'james',
  jimmy: 'james',
  joe: 'joseph',
  joey: 'joseph',
  mike: 'michael',
  dan: 'daniel',
  danny: 'daniel',
  dave: 'david',
  ed: 'edward',
  ted: 'theodore',
  dick: 'richard',
  rick: 'richard',
};

// ---------------------------------------------------------------------------
// Title patterns — prefixes stripped before comparison
// Order matters: longer/full forms before abbreviated forms so both match.
// ---------------------------------------------------------------------------
const TITLE_PATTERNS = [
  /^assemblymember\s+/i,
  /^councilmember\s+/i,
  /^representative\s+/i,
  /^governor\s+/i,
  /^senator\s+/i,
  /^mayor\s+/i,
  /^rep\.?\s+/i,
  /^sen\.?\s+/i,
  /^gov\.?\s+/i,
  /^dr\.?\s+/i,
];

// ---------------------------------------------------------------------------
// Generational suffix patterns — stripped from the end of the name
// ---------------------------------------------------------------------------
const SUFFIX_PATTERN = /\s+(?:jr\.?|sr\.?|ii|iii|iv)$/i;

// ---------------------------------------------------------------------------
// Middle-initial pattern — single letter (optionally preceded by another
// initial) surrounded by spaces, or a leading initial before the surname
// ---------------------------------------------------------------------------
const MIDDLE_INITIAL_PATTERN = /(?<=\s)[a-z]\.\s+(?=[a-z])/gi;

// ---------------------------------------------------------------------------
// Leading initial: a single letter at the very start of the string
// e.g. "A. Lincoln" → "Lincoln"
// ---------------------------------------------------------------------------
const LEADING_INITIAL_PATTERN = /^[a-z]\.\s+/i;

// ---------------------------------------------------------------------------
// stripDiacritics
// ---------------------------------------------------------------------------

/**
 * Remove Unicode combining diacritical marks (accents, tildes, etc.)
 * "José" → "Jose", "García" → "Garcia"
 */
export function stripDiacritics(str: string): string {
  return str.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
}

// ---------------------------------------------------------------------------
// normalizeAnswer
// ---------------------------------------------------------------------------

/**
 * Normalize a raw civic name answer to a canonical lowercase token-sorted form.
 * Deterministic and pure — no external calls.
 */
export function normalizeAnswer(raw: string): string {
  // Step 1: strip diacritics
  let s = stripDiacritics(raw);

  // Step 2: lowercase
  s = s.toLowerCase();

  // Step 3: normalize whitespace (tabs, multiple spaces → single space, trim)
  s = s.replace(/\s+/g, ' ').trim();

  // Step 4: strip prefixed civic titles
  for (const pattern of TITLE_PATTERNS) {
    if (pattern.test(s)) {
      s = s.replace(pattern, '').trim();
      break; // Only one title prefix is expected
    }
  }

  // Step 5: strip generational suffixes (Jr., Sr., II, III, IV)
  s = s.replace(SUFFIX_PATTERN, '').trim();

  // Step 6a: strip leading initial (e.g. "a. lincoln" → "lincoln")
  s = s.replace(LEADING_INITIAL_PATTERN, '').trim();

  // Step 6b: strip middle initials (single letter + period between name tokens)
  // Repeat to handle multiple consecutive initials like "a. b."
  let prev = '';
  while (prev !== s) {
    prev = s;
    s = s.replace(MIDDLE_INITIAL_PATTERN, ' ').trim();
  }
  // Collapse any leftover double spaces
  s = s.replace(/\s+/g, ' ').trim();

  // Step 7: apply nickname lookup to each token
  const tokens = s.split(' ');
  const mapped = tokens.map((tok) => NICKNAME_MAP[tok] ?? tok);
  s = mapped.join(' ');

  // Step 8: token-sort (alphabetical)
  const sorted = s.split(' ').sort();
  s = sorted.join(' ');

  // Step 9: final trim + collapse
  s = s.replace(/\s+/g, ' ').trim();

  return s;
}

// ---------------------------------------------------------------------------
// answersMatch
// ---------------------------------------------------------------------------

/**
 * Tokenize a normalized name for comparison purposes.
 * Hyphens are treated as token separators (Garcia-Lopez → ['garcia', 'lopez'])
 * to allow matching against space-separated variants (Garcia Lopez).
 * normalizeAnswer() preserves hyphens in its output for display; this helper
 * expands them only during the comparison step.
 */
function tokenizeForComparison(normalized: string): string[] {
  return normalized
    .replace(/-/g, ' ')     // treat hyphens as spaces for comparison
    .split(' ')
    .filter((t) => t.length > 0);
}

/**
 * Determine whether two raw answer strings refer to the same civic name.
 *
 * Matching strategy (in order):
 *   1. Exact match after normalization
 *   2. Per-token JaroWinkler: ALL tokens must meet threshold AND token counts match.
 *      Hyphens are expanded to spaces before tokenization so "Garcia-Lopez" and
 *      "Garcia Lopez" tokenize to the same set.
 *      Whole-string JaroWinkler is NOT used — it produces false positives for
 *      similar short names (e.g. "Maria Lopez" vs "Mario Lopez" scores 0.93).
 *
 * Note: Metaphone is NOT used as a fallback. Per-token Metaphone causes false
 * positives because short names often share the same Metaphone encoding
 * ("john" → JN, "jane" → JN; "maria" → MR, "mario" → MR).
 * JaroWinkler at 0.93 per-token handles genuine typos and transliterations.
 */
export function answersMatch(
  a: string,
  b: string,
  threshold: number = TOKEN_THRESHOLD
): boolean {
  const normA = normalizeAnswer(a);
  const normB = normalizeAnswer(b);

  // Step 1: exact match after normalization (preserves hyphens)
  if (normA === normB) return true;

  // Expand hyphens to spaces for token-level comparison
  // This allows "Garcia-Lopez" and "Garcia Lopez" to tokenize identically
  const tokensA = tokenizeForComparison(normA);
  const tokensB = tokenizeForComparison(normB);

  // Token count mismatch → different names (missing/extra word)
  if (tokensA.length !== tokensB.length) return false;

  // Step 2: per-token JaroWinkler — ALL tokens must clear the threshold (default 0.93)
  // Per-token prevents whole-string false positives:
  // "Maria Lopez" vs "Mario Lopez" → token "maria"/"mario" = JW 0.92 → correctly fails
  const allTokensMatch = tokensA.every((tokA, i) => {
    const tokB = tokensB[i]!;
    return JaroWinklerDistance(tokA, tokB) >= threshold;
  });
  if (allTokensMatch) return true;

  return false;
}
