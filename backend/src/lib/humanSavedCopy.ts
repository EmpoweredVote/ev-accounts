/**
 * humanSavedCopy — a person-saved copy of an own-site page that the pipeline cannot read itself
 * (a JS-only SPA). Ruling 2026-10-07 (Chris Andrews), option B — see
 * docs/superpowers/specs/2026-10-07-human-saved-source-verification-proposal.md.
 *
 * A saved copy is NOT machine verification. It never makes a snippet `verified`, never counts toward
 * the verifier's source threshold, and never yields a published span. It is a convenience for the
 * reviewer: "does this snippet appear in the copy a person saved?", plus the file's sha256 so a later
 * edit of the file is detectable. The reviewer still approves the URL through the existing
 * hand-verified path, which publishes a link only.
 */
import { createHash } from 'node:crypto';
import { matchSnippet, type MatchOptions } from './researchVerifier.js';

export interface HumanSavedMark {
  /** sha256 of the saved file's raw bytes (utf8 text), hex. */
  sha256: string;
  /** snippet_index of every snippet found in the copy (convenience check only). */
  snippets_found: number[];
  snippets_total: number;
}

export const sha256Hex = (raw: string): string => createHash('sha256').update(raw, 'utf8').digest('hex');

/** Check the row's snippets against the saved copy's TEXT. Never produces a verdict or a span. */
export function markHumanSaved(
  copy: { rawSha256: string; text: string },
  snippets: { snippet: string; snippet_index: number }[],
  match?: MatchOptions,
): HumanSavedMark {
  const found = snippets
    .filter((s) => matchSnippet(s.snippet, copy.text, match).verdict === 'verified')
    .map((s) => s.snippet_index);
  return { sha256: copy.rawSha256, snippets_found: found, snippets_total: snippets.length };
}
