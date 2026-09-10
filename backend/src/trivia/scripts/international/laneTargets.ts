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
