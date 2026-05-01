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
