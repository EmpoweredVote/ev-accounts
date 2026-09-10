/**
 * The lane registry: which collection each lane writes into.
 *
 * Lives in its own module so both the cron and the pipeline entry point can
 * read it without importing each other.
 */

import type { Lane } from './lanes.js';
import type { Volatility } from './question-generator.js';

export interface LaneTarget {
  lane: Lane;
  collectionSlug: string;
  prefix: string;
  volatility: Volatility;
}

/** Every lane the pipeline can serve. A lane whose collection does not exist
 *  yet is skipped with a warning at run time — see runNightlyPipeline. */
export const INTERNATIONAL_LANES: readonly LaneTarget[] = [
  { lane: 'iran',    collectionSlug: 'war-in-iran',     prefix: 'wiran', volatility: 'fast' },
  { lane: 'world',   collectionSlug: 'world-news',      prefix: 'wnews', volatility: 'fast' },
  { lane: 'us',      collectionSlug: 'us-news',         prefix: 'usnws', volatility: 'fast' },
  { lane: 'climate', collectionSlug: 'climate-change',  prefix: 'climc', volatility: 'medium' },
];

/**
 * Is this fingerprint too empty to be worth remembering?
 *
 * The claim-extraction schema sets no minimum length on subject, attribute or
 * value, so a schema-compliant response can return blanks — and normalisation
 * can empty a half on its own, because `normalizeText` drops noise words: a
 * subject of "the" or "people" normalizes to "".
 *
 * Recording such a claim is worse than dropping it. The first one is stored
 * under a key like "|deaths", and every later claim that normalizes to the
 * same half-blank key reads as a duplicate of it — a silent, cumulative
 * mislabelling. So BOTH halves of the topic key and the value must be
 * non-empty.
 */
export function isDegenerate(keys: { topicKey: string; valueKey: string }): boolean {
  const [subject = '', attribute = ''] = keys.topicKey.split('|');
  // fingerprintClaim already trims each part; trimmed again here because this
  // is a public predicate that must not depend on its caller having done so.
  return (
    subject.trim() === '' ||
    attribute.trim() === '' ||
    keys.valueKey.trim() === ''
  );
}

/**
 * Split the lane registry by whether each lane's collection actually resolved.
 *
 * A lane whose collection does not exist yet is skipped, never fatal: three of
 * the four collections are created in a later plan, and aborting the run over
 * them would take the working lanes down too.
 */
export function partitionTargets(
  targets: readonly LaneTarget[],
  resolvedSlugs: ReadonlySet<string>,
): { served: LaneTarget[]; missing: LaneTarget[] } {
  const served: LaneTarget[] = [];
  const missing: LaneTarget[] = [];

  for (const target of targets) {
    if (resolvedSlugs.has(target.collectionSlug)) {
      served.push(target);
    } else {
      missing.push(target);
    }
  }

  return { served, missing };
}
