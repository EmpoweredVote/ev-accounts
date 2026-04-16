/**
 * normalizeDonorName — Shared donor name normalization function.
 *
 * Used by all 5 campaign finance adapters (FEC, Cal-Access, Indiana,
 * LA Socrata, LA County Netfile) and the Phase 25 backfill script.
 *
 * Normalization pipeline (order is LOCKED — do not reorder steps):
 *   1. NULL / empty input → return 'anonymous'
 *   2. Trim whitespace; collapse internal whitespace runs to single space
 *   3. Strip periods (.) entirely — "J. Smith" → "J Smith"
 *   4. Replace hyphens (-) with space — "Garcia-Lopez" → "Garcia Lopez"
 *   5. Unaccent via NFD decomposition + diacritic strip, then lowercase
 *   6. LAST, FIRST reorder — conservative comma heuristic:
 *      - Only when exactly one comma is present
 *      - AND neither side contains digits, ampersands (&), or org keywords
 *      - Org keywords: LLC, INC, CORP, THE, FUND, PAC, COMMITTEE, ASSOC
 *      - If ambiguous, strip comma and collapse whitespace (leave order as-is)
 *   7. Final trim; if empty after all transforms → return 'anonymous'
 *
 * Examples:
 *   null              → 'anonymous'
 *   ''                → 'anonymous'
 *   'SMITH, JOHN'     → 'john smith'
 *   "EMILY'S LIST, INC" → "emilys list inc"  (INC is org keyword — not reordered)
 *   'J. Garcia-Lopez' → 'j garcia lopez'
 *   '  Multiple   Spaces  ' → 'multiple spaces'
 *   'Cárdenas, Tony'  → 'tony cardenas'
 */

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/**
 * Org keywords that signal a comma is part of a business name, not LAST, FIRST.
 * Checked against the uppercase form of each side of the comma.
 */
const ORG_KEYWORDS = new Set([
  'LLC', 'INC', 'CORP', 'THE', 'FUND', 'PAC', 'COMMITTEE', 'ASSOC',
]);

/** Regex matching digits within a string. */
const HAS_DIGIT = /\d/;

/** Regex matching ampersands within a string. */
const HAS_AMPERSAND = /&/;

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/**
 * containsOrgKeyword returns true if any whitespace-delimited token in the
 * given string (already uppercased) is present in ORG_KEYWORDS.
 */
function containsOrgKeyword(upper: string): boolean {
  for (const token of upper.trim().split(/\s+/)) {
    if (ORG_KEYWORDS.has(token)) return true;
  }
  return false;
}

/**
 * sideIsOrgLike returns true if the given comma-side string looks like it
 * belongs to a business / org name rather than a personal name.
 *
 * A side is org-like if it contains:
 *   - Any digit
 *   - Any ampersand
 *   - Any org keyword (LLC, INC, CORP, etc.)
 */
function sideIsOrgLike(side: string): boolean {
  if (HAS_DIGIT.test(side)) return true;
  if (HAS_AMPERSAND.test(side)) return true;
  if (containsOrgKeyword(side.toUpperCase())) return true;
  return false;
}

/**
 * unaccent removes diacritic marks from a string using NFD decomposition.
 * "Cárdenas" → "Cardenas", "García" → "Garcia", etc.
 */
function unaccent(s: string): string {
  return s.normalize('NFD').replace(/\p{Mn}/gu, '');
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * normalizeDonorName converts a raw donor name from any data source into a
 * consistent lowercase ASCII form suitable for exact, prefix, and fuzzy search.
 *
 * @param raw - Donor name as received from the source (may be null/undefined/empty).
 * @returns Normalized name string, or 'anonymous' for null / empty / unresolvable input.
 */
export function normalizeDonorName(raw: string | null | undefined): string {
  // Step 1: NULL or empty → anonymous
  if (raw == null || raw.trim() === '') {
    return 'anonymous';
  }

  // Step 2: Trim + collapse internal whitespace runs
  let name = raw.trim().replace(/\s+/g, ' ');

  // Step 3: Strip periods entirely
  name = name.replace(/\./g, '');

  // Step 4: Replace hyphens with space
  name = name.replace(/-/g, ' ');

  // Step 5: Unaccent via NFD decomposition, then lowercase
  name = unaccent(name).toLowerCase();

  // Collapse again after step 4 expansion (e.g. "a - b" → "a   b" → "a b")
  name = name.replace(/\s+/g, ' ').trim();

  // Step 6: LAST, FIRST reorder — conservative comma heuristic
  const commaCount = (name.match(/,/g) ?? []).length;
  if (commaCount === 1) {
    const commaIdx = name.indexOf(',');
    const left = name.slice(0, commaIdx).trim();   // LAST part (before comma)
    const right = name.slice(commaIdx + 1).trim(); // FIRST part (after comma)

    if (!sideIsOrgLike(left) && !sideIsOrgLike(right)) {
      // Personal name — reorder to FIRST LAST
      name = `${right} ${left}`.replace(/\s+/g, ' ').trim();
    } else {
      // Org name or ambiguous — strip comma, preserve order
      name = `${left} ${right}`.replace(/\s+/g, ' ').trim();
    }
  } else if (commaCount > 1) {
    // Multiple commas — ambiguous; strip all commas and collapse
    name = name.replace(/,/g, ' ').replace(/\s+/g, ' ').trim();
  }
  // commaCount === 0: no comma, leave as-is

  // Step 7: Final trim; if empty → anonymous
  name = name.trim();
  if (name === '') {
    return 'anonymous';
  }

  return name;
}
