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

/** One entry in `generation_jobs.notes.rejections`. Shape varies by reason;
 *  only `lane` is read here, and it is absent on cluster errors thrown before
 *  a lane was resolved. */
export type Rejection = Record<string, unknown>;

/**
 * Split rejections into per-lane buckets plus the ones belonging to no served
 * lane.
 *
 * Nothing may be dropped. `no-target` rejections exist precisely BECAUSE
 * their lane is unserved, so a per-lane filter can never match them, and a
 * cluster that threw before its lane was resolved has no lane at all. Both
 * classes are `unroutable` and get spliced into every served lane's notes —
 * without that they vanished from every job row, which is the invariant four
 * separate development-round violations were about.
 */
export function partitionRejections(
  rejections: readonly Rejection[],
  servedLanes: ReadonlySet<Lane>,
): { unroutable: Rejection[]; forLane(lane: Lane): Rejection[] } {
  const unroutable: Rejection[] = [];
  const byLane = new Map<Lane, Rejection[]>();

  for (const rejection of rejections) {
    const lane = rejection.lane as Lane | undefined;
    if (lane === undefined || !servedLanes.has(lane)) {
      unroutable.push(rejection);
      continue;
    }
    const bucket = byLane.get(lane);
    if (bucket) {
      bucket.push(rejection);
    } else {
      byLane.set(lane, [rejection]);
    }
  }

  return {
    unroutable,
    forLane: (lane: Lane) => byLane.get(lane) ?? [],
  };
}

/**
 * True when every attempted cluster errored — a systemic failure, not a quiet
 * night.
 *
 * A cluster-level throw is caught and counted per cluster, so a fully
 * systemic failure would otherwise never reach the pipeline's own catch and
 * the run would finalise as 'success' with the damage visible only as a large
 * `clusterErrors` count buried in notes.
 *
 * `attempted === 0` is not a failure: no clusters attempted means the feeds
 * were quiet (or the run was skipped upstream), and the feed-blackout check
 * owns that case. Only "every attempted cluster threw" counts: 20 clusters
 * rejected as duplicates plus one throw is a success with one cluster error.
 * `>=` rather than `===` is defensive — errors should never exceed attempts,
 * but if they ever do that is still systemic.
 */
export function isSystemicClusterFailure(attempted: number, errors: number): boolean {
  return attempted > 0 && errors >= attempted;
}
