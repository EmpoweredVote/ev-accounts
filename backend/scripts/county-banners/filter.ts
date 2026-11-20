/**
 * Stage 3 -- THE GATES. Everything here runs BEFORE the operator sees a candidate.
 *
 * 🔴 WHY BEFORE. The operator's attention is the scarcest resource in this programme --
 * roughly 35 working sessions for the country. A candidate that reaches the review page,
 * gets chosen, gets cropped, and is THEN found to be 900px wide or non-free has cost
 * that attention twice and delivered nothing.
 *
 * 🔴 A FILE WE CANNOT CREDIT IS A FILE WE CANNOT SHOW. Essentials' banner generator
 * already drops assets with no author, by design. So an unattributable file is not a
 * weak candidate, it is not a candidate.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */
import type { CandidateFile } from './types.js';

/** The shipped asset is 1700x540. Anything smaller cannot be built without upscaling. */
export const MIN_LONG_EDGE = 1700;

/**
 * Licences this pipeline may ship.
 *
 * 🔴 A LICENCE IS READ, NEVER INFERRED. `null` means we did not read one, which is a
 * different outcome from reading one and finding it non-free -- see the two counters.
 */
export const FREE_LICENCE = /^(cc0|cc[ _-]?by|public domain|pd-|gfdl|free art licen[cs]e|attribution$|no restrictions)/i;

/**
 * 🔴 NonCommercial and NoDerivatives are NOT free, and the bare 'cc by' prefix admits
 * both: 'CC BY-NC 4.0' and 'CC BY-ND 2.0' match it. Checked first, for that reason.
 */
export const NON_FREE_LICENCE = /(^|[\s_-])(nc|nd)([\s_-]|$)|noncommercial|no[ -]?derivat|all rights reserved|fair use|non-?free/i;

export type RejectReason = 'too_small' | 'licence_absent' | 'licence_non_free' | 'licence_unreadable' | 'author_absent';

export interface FilterResult {
  kept: CandidateFile[];
  rejected: Record<RejectReason, number>;
}

/**
 * Apply the three gates, cheapest first, counting every rejection by reason.
 *
 * The counts are the point as much as the keeps: they are what lets a county with zero
 * candidates say WHY it has zero. "No photographs exist" and "every photograph is too
 * small" are different findings and only one of them is worth a round-2 search.
 */
export function filterCandidates(files: CandidateFile[]): FilterResult {
  const rejected: Record<RejectReason, number> = {
    too_small: 0, licence_absent: 0, licence_non_free: 0, licence_unreadable: 0, author_absent: 0,
  };
  const kept: CandidateFile[] = [];
  for (const f of files) {
    if (Math.max(f.width, f.height) < MIN_LONG_EDGE) { rejected.too_small++; continue; }
    if (f.licence === null) { rejected.licence_absent++; continue; }
    const licence = f.licence.trim();
    if (NON_FREE_LICENCE.test(licence)) { rejected.licence_non_free++; continue; }
    // 🔴 A licence we cannot classify is NOT a licence we read and refused. Counting it
    // as non-free tells the operator something untrue about the file, and hides a
    // vocabulary gap behind a number that looks like a finding.
    if (!FREE_LICENCE.test(licence)) { rejected.licence_unreadable++; continue; }
    if (f.author === null) { rejected.author_absent++; continue; }
    kept.push(f);
  }
  return { kept, rejected };
}
