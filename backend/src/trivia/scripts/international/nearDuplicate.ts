/**
 * Trigram near-duplicate net.
 *
 * Catches paraphrase that survives claim fingerprinting because the extractor
 * structured the same fact differently on two nights. Scoped across every
 * featured lane's collection ids, not one lane, so a routing misclassification
 * becomes a skipped duplicate rather than a visible one.
 *
 * The comparison pool is bounded by collection and status only — never by
 * time. Curated evergreen questions are the oldest rows in a lane's
 * collection and carry no claim fingerprints, so they are the one thing only
 * Layer 2 can see; any age bound here would hide precisely them.
 */

/**
 * Measured via `extensions.similarity` on 8 fixture pairs (2026-09-10):
 * duplicates ranged 0.2759-0.8850, distincts (coincidental same-answer
 * pairs) ranged 0.1438-0.1776 — the ranges do not overlap. But Layer 2
 * (this file) isn't responsible for all 5 duplicates: Layer 1 (claim
 * fingerprint) already catches 4 of them, leaving only the wiran-1578/
 * 1661 paraphrase ("89" vs "89 years old") at 0.5873 as Layer 2's actual
 * requirement. So the binding window is just (0.1776, 0.5873] — catch
 * 0.5873, never fire on 0.1776. 0.55 sits inside it with margin both
 * ways; dropping it to ~0.25 to also catch pairs Layer 1 already owns
 * would trade a solved problem for false positives on unrelated
 * questions that share topic vocabulary.
 */
export const NEAR_DUP_THRESHOLD = 0.55;

export interface SimilarityHit {
  externalId: string;
  similarity: number;
}

export interface SimilarityProbe {
  /** Most similar question in the given collections, across all of time. */
  mostSimilar(
    text: string,
    collectionIds: readonly number[],
  ): Promise<SimilarityHit | null>;
}

/**
 * Returns a checker that resolves to the offending hit when `text` is too
 * similar to something already in the pool, or `null` when it is acceptable.
 */
export function makeNearDuplicateCheck(
  probe: SimilarityProbe,
  threshold: number = NEAR_DUP_THRESHOLD,
) {
  return async function check(
    text: string,
    collectionIds: readonly number[],
  ): Promise<SimilarityHit | null> {
    const hit = await probe.mostSimilar(text, collectionIds);
    if (!hit) return null;
    return hit.similarity >= threshold ? hit : null;
  };
}
