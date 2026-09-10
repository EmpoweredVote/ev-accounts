/**
 * Trigram near-duplicate net.
 *
 * Catches paraphrase that survives claim fingerprinting because the extractor
 * structured the same fact differently on two nights. Scoped across every
 * featured lane's collection ids, not one lane, so a routing misclassification
 * becomes a skipped duplicate rather than a visible one.
 */

/** Tuned against the spec's regression fixtures. */
export const NEAR_DUP_THRESHOLD = 0.55;
export const NEAR_DUP_WINDOW_DAYS = 14;

export interface SimilarityHit {
  externalId: string;
  similarity: number;
}

export interface SimilarityProbe {
  mostSimilar(
    text: string,
    collectionIds: readonly number[],
    since: Date,
  ): Promise<SimilarityHit | null>;
}

/**
 * Returns a checker that resolves to the offending hit when `text` is too
 * similar to something already in the pool, or `null` when it is acceptable.
 */
export function makeNearDuplicateCheck(
  probe: SimilarityProbe,
  threshold: number = NEAR_DUP_THRESHOLD,
  now: () => Date = () => new Date(),
) {
  return async function check(
    text: string,
    collectionIds: readonly number[],
  ): Promise<SimilarityHit | null> {
    const since = new Date(now().getTime() - NEAR_DUP_WINDOW_DAYS * 24 * 60 * 60 * 1000);
    const hit = await probe.mostSimilar(text, collectionIds, since);
    if (!hit) return null;
    return hit.similarity >= threshold ? hit : null;
  };
}
