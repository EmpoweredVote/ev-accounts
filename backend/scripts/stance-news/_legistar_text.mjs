// Cut a snippet from a Legistar page WITH ITS ORIGINAL CASE.
//
// 🔴 WHY THIS EXISTS. The first Legistar snippets of 2026-10-05 were sliced straight out of
// `normalizeText(page)`, which lowercases. Two things go wrong with a lowercased snippet:
//  1. It is what gets published as the citation when a reviewer approves the row, and an
//     all-lowercase block of ordinance text is not how the page reads.
//  2. `stanceGate`'s instrument patterns are CASE-SENSITIVE — `/\bChapter\s?\d+\b/` has no `i`
//     flag. The reasoning says "Chapter 2" and matches; a lowercased snippet says "chapter 2"
//     and does not, so `instrument-not-cited` fires on an instrument that IS in the snippet.
//
// The verifier normalizes both sides before matching, so a case-preserving snippet verifies
// exactly as well. Offsets are found on the normalized text and applied to a case-preserving
// twin built by the same pipeline, and the two are asserted to align before any slice is taken.
import { normalizeText } from '../../src/lib/researchVerifier.js';

const stripTags = (html) => html
  .replace(/<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>/g, '')
  .replace(/<[^>]+>/g, ' ');

// The same transformations normalizeText applies, minus the lowercasing.
const preserveCase = (input) => {
  let out = input
    .replace(/&#(\d+);/g, (m, d) => { const c = Number(d); return Number.isSafeInteger(c) ? String.fromCodePoint(c) : m; })
    .replace(/&#[xX]([0-9a-fA-F]+);/g, (m, h) => { const c = parseInt(h, 16); return Number.isSafeInteger(c) ? String.fromCodePoint(c) : m; });
  // The same named-entity table normalizeText uses (researchVerifier.ts HTML_ENTITIES). Kept in
  // sync by the alignment assertion below: if that table ever grows, `aligned` goes false and the
  // caller falls back rather than slicing at an offset that has drifted.
  for (const [e, r2] of [['&amp;', '&'], ['&lt;', '<'], ['&gt;', '>'], ['&quot;', '"'], ['&apos;', "'"], ['&nbsp;', ' '], ['&#39;', "'"]]) {
    out = out.split(e).join(r2);
  }
  out = out.replace(/[“”]/g, '"').replace(/[‘’]/g, "'").replace(/[—–]/g, '-');
  out = out.normalize('NFD').replace(/[̀-ͯ]/g, '');
  return out.replace(/\s+/g, ' ').trim();
};

/**
 * Fetch a Legistar page and return { page, pretty, aligned }.
 *  - `page`   normalized + lowercased, for finding offsets and for checkNameProximity
 *  - `pretty` the same span boundaries with original case, for the stored snippet
 *  - `aligned` false when the two pipelines disagree on length, in which case the caller MUST
 *    fall back to `page` rather than slice `pretty` at an offset that no longer means the same
 *    thing. A silently misaligned slice would be a snippet that is not verbatim anywhere.
 */
export async function fetchLegistar(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error('Legistar page HTTP ' + r.status + ' for ' + url);
  const html = await r.text();
  const stripped = stripTags(html);
  const page = normalizeText(stripped);
  const pretty = preserveCase(stripped);
  const aligned = pretty.length === page.length && pretty.toLowerCase() === page;
  return { html, stripped, page, pretty, aligned };
}

/** Slice [i, j) with original case when the pipelines align, lowercased when they do not. */
export function sliceSnippet({ page, pretty, aligned }, i, j) {
  return aligned ? pretty.slice(i, j) : page.slice(i, j);
}
