/**
 * ONE character-reference table, shared by the page extractor and the snippet matcher.
 *
 * There used to be two. `verificationFetch.htmlToText` decoded a page as it was extracted, and
 * `researchVerifier.normalizeText` decoded again as it compared — each from its own private copy of
 * the list. They drifted, and the drift was invisible: a page and the snippet cut from it carried
 * the SAME undecoded `&mdash;`, so matching succeeded while the stored span — the text a voter
 * reads under "why this position?" — kept the raw reference. Measured 2026-10-06: 8 of 263 rows in
 * `inform.politician_context_evidence` (CC_0194 decoded them).
 *
 * `researchVerifier` is deliberately fetcher-agnostic and must not import `verificationFetch`, so
 * the table lives here and both import it. Add a reference once, in this file.
 *
 * 🔴 `&amp;` IS DECODED LAST, and the order is load bearing. A doubly-escaped `&amp;mdash;` must
 * resolve one step per pass — to `&mdash;`, and no further — rather than collapsing straight to an
 * em dash because the ampersand was expanded first and the result was then matched again by a
 * later entry in the same loop. CC_0194's SQL decodes in this same order for the same reason.
 */
export const HTML_ENTITIES: Record<string, string> = {
  '&nbsp;': ' ',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&apos;': "'",
  '&#39;': "'",
  // The typographic references a news page actually emits. Without them the extractor handed on
  // literal `&ldquo;` text, and a snippet that honestly typed a real “ or — could never match it.
  '&ldquo;': '“',
  '&rdquo;': '”',
  '&lsquo;': '‘',
  '&rsquo;': '’',
  '&mdash;': '—',
  '&ndash;': '–',
  '&hellip;': '…',
  // § turns up in the statute text this corpus cites constantly ("RCW § 35.21.830").
  '&sect;': '§',
  '&amp;': '&', // last — see the note above
};

/**
 * Decode numeric character references (`&#8217;` decimal, `&#x2019;` hex).
 *
 * Neither form appears in {@link HTML_ENTITIES}, so left alone they survive as literal `&#8217;`
 * text: "you&#8217;re" would never fold to "you're" and would fail to match a snippet that
 * honestly types a straight apostrophe. Ported from `scripts/verify-quotes.mjs`, which hit this on
 * a live wave. `String.fromCodePoint` also handles names and quotes outside the BMP; a malformed
 * reference (bad digits) is left as-is rather than throwing.
 */
export function decodeNumericEntities(input: string): string {
  return input
    .replace(/&#(\d+);/g, (match, dec: string) => {
      const code = Number(dec);
      return Number.isSafeInteger(code) ? String.fromCodePoint(code) : match;
    })
    .replace(/&#[xX]([0-9a-fA-F]+);/g, (match, hex: string) => {
      const code = parseInt(hex, 16);
      return Number.isSafeInteger(code) ? String.fromCodePoint(code) : match;
    });
}

/**
 * Turn character references into the characters they stand for, and change nothing else.
 *
 * This is NOT `normalizeText`: it keeps case, real quotation marks, dashes, diacritics and
 * spacing, because its output is read by people — the extracted page, and the citation span stored
 * beside a published stance. A malformed reference is left alone rather than guessed at.
 */
export function decodeEntities(input: string): string {
  let out = decodeNumericEntities(input);
  for (const [entity, replacement] of Object.entries(HTML_ENTITIES)) {
    out = out.split(entity).join(replacement);
  }
  return out;
}
