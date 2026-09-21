/**
 * Lane assignment for the nightly news pipeline.
 *
 * The claim extractor returns which topics apply to a story; this module
 * decides the single lane it lands in. Exactly one lane per story is what
 * makes it impossible for one fact to appear in two collections that sit
 * side by side on the Featured shelf.
 */

export type Lane = 'iran' | 'climate' | 'us' | 'world';

/** Most specific wins; `world` is the sink. */
export const LANE_PRECEDENCE: readonly Lane[] = ['iran', 'climate', 'us', 'world'] as const;

const KNOWN_LANES = new Set<string>(LANE_PRECEDENCE);

export function isLane(value: string): value is Lane {
  return KNOWN_LANES.has(value);
}

/**
 * Resolve a story's topic tags to exactly one lane.
 * Unrecognised tags are ignored; an empty or fully unrecognised list is `world`.
 */
export function resolveLane(topics: readonly string[]): Lane {
  const present = new Set(topics.filter(isLane));
  for (const lane of LANE_PRECEDENCE) {
    if (present.has(lane)) return lane;
  }
  return 'world';
}
