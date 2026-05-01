/**
 * researchVerifier — deterministic verification of stance-research evidence.
 *
 * Pipeline: parsed CSVs → fetch each source URL → for each snippet, check it
 * appears verbatim on the page (after normalization) and the politician's
 * name appears within 500 characters of the match. No LLM involved.
 *
 * See docs/superpowers/specs/2026-04-30-stance-research-verification-design.md
 */

const HTML_ENTITIES: Record<string, string> = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&apos;': "'",
  '&nbsp;': ' ',
  '&#39;': "'",
};

export function normalizeText(input: string): string {
  let out = input;
  // HTML entities first (before quote normalization, since &quot; → ")
  for (const [entity, replacement] of Object.entries(HTML_ENTITIES)) {
    out = out.split(entity).join(replacement);
  }
  // Curly quotes → straight quotes
  out = out
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'");
  // Em / en dashes → hyphen
  out = out.replace(/[—–]/g, '-');
  // Lowercase
  out = out.toLowerCase();
  // Collapse all whitespace runs to single space
  out = out.replace(/\s+/g, ' ');
  // Trim
  return out.trim();
}

export const MIN_SNIPPET_WORDS = 25;

export type SnippetVerdict =
  | { verdict: 'verified'; matchOffset: number }
  | { verdict: 'snippet_not_found' }
  | { verdict: 'snippet_too_short' }
  | { verdict: 'name_not_present' }
  | { verdict: 'url_broken'; reason: string };

export function matchSnippet(
  snippet: string,
  pageText: string,
): SnippetVerdict {
  const wordCount = snippet.trim().split(/\s+/).filter(Boolean).length;
  if (wordCount < MIN_SNIPPET_WORDS) {
    return { verdict: 'snippet_too_short' };
  }
  const normalizedSnippet = normalizeText(snippet);
  const normalizedPage = normalizeText(pageText);
  const offset = normalizedPage.indexOf(normalizedSnippet);
  if (offset === -1) {
    return { verdict: 'snippet_not_found' };
  }
  return { verdict: 'verified', matchOffset: offset };
}


export const NAME_PROXIMITY_CHARS = 500;

// Last names common enough that a bare match is too coincidence-prone — require
// a title qualifier (Sen./Rep./Mayor/Gov./Pres./Councilor/etc.) nearby.
const COMMON_LAST_NAMES = new Set([
  'smith', 'johnson', 'williams', 'brown', 'jones', 'garcia', 'miller',
  'davis', 'rodriguez', 'martinez', 'hernandez', 'lopez', 'gonzalez',
  'wilson', 'anderson', 'thomas', 'taylor', 'moore', 'jackson', 'martin',
  'lee', 'thompson', 'white', 'harris', 'clark', 'lewis', 'robinson',
  'walker', 'young', 'allen', 'king', 'wright', 'scott', 'green', 'baker',
  'adams', 'nelson', 'hill', 'campbell', 'mitchell', 'roberts', 'carter',
  'phillips', 'evans', 'turner', 'parker', 'edwards', 'collins',
]);

const TITLE_PATTERN = /\b(sen|sen\.|senator|rep|rep\.|representative|gov|gov\.|governor|pres|pres\.|president|mayor|councilor|councilman|councilwoman|councilmember|delegate|asm|asm\.|assemblymember|judge|justice|chief|sheriff|hon|hon\.|honorable)\b/;

export function checkNameProximity(args: {
  fullName: string;
  lastName: string;
  pageText: string;
  matchOffsetInNormalized: number;
}): SnippetVerdict {
  const { fullName, lastName, pageText, matchOffsetInNormalized } = args;
  if (matchOffsetInNormalized < 0) {
    return { verdict: 'snippet_not_found' };
  }
  const normalizedPage = normalizeText(pageText);
  const fullNameLower = normalizeText(fullName);
  const lastNameLower = normalizeText(lastName);

  // Window: 500 chars before snippet start to 500 chars after snippet start.
  const windowStart = Math.max(0, matchOffsetInNormalized - NAME_PROXIMITY_CHARS);
  const windowEnd = Math.min(
    normalizedPage.length,
    matchOffsetInNormalized + NAME_PROXIMITY_CHARS,
  );
  const window = normalizedPage.slice(windowStart, windowEnd);

  // Full name in window → verified.
  if (window.includes(fullNameLower)) {
    return { verdict: 'verified', matchOffset: matchOffsetInNormalized };
  }

  // Last name in window?
  if (window.includes(lastNameLower)) {
    const isCommon = COMMON_LAST_NAMES.has(lastNameLower);
    if (!isCommon) {
      return { verdict: 'verified', matchOffset: matchOffsetInNormalized };
    }
    // Common last name — require title qualifier within 30 chars before each
    // occurrence of the last name in the window.
    let idx = window.indexOf(lastNameLower);
    while (idx !== -1) {
      const lookbehind = window.slice(Math.max(0, idx - 30), idx);
      if (TITLE_PATTERN.test(lookbehind)) {
        return { verdict: 'verified', matchOffset: matchOffsetInNormalized };
      }
      idx = window.indexOf(lastNameLower, idx + 1);
    }
  }

  return { verdict: 'name_not_present' };
}
