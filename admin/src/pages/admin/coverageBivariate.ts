/**
 * Pure bivariate coloring for the completeness coverage map.
 *
 *   X axis = breadth (fraction of child units started, 0..1)
 *   Y axis = depth   (mean composite over started units, 0..100)
 *
 * Each axis is bucketed low/med/high → a 3×3 Teal × Amber grid:
 *   teal  = deep & narrow, amber = broad & shallow, olive = both high,
 *   near-white = empty (0 started). Antipartisan — deliberately no red/blue.
 *
 * Thresholds + hexes are the tunable design constants. Untracked geographies
 * (no coverage YAML) use NOT_STARTED grey, painted by the caller — distinct from
 * the near-white "tracked but empty" cell.
 */
export type Bucket = 'low' | 'med' | 'high';

// breadth thresholds (fraction): <0.10 low · <0.50 med · >=0.50 high
export const BREADTH_THRESHOLDS = { low: 0.1, high: 0.5 };
// depth thresholds (0..100 composite): <33 low · <66 med · >=66 high
export const DEPTH_THRESHOLDS = { low: 33, high: 66 };

export const NOT_STARTED = '#e5e7eb'; // gray-200 — untracked / no coverage file

// PALETTE[depthBucket][breadthBucket] — rows = depth, cols = breadth.
export const PALETTE: Record<Bucket, Record<Bucket, string>> = {
  high: { low: '#2f8f8f', med: '#36806a', high: '#3f6b3a' },
  med:  { low: '#a9cdc0', med: '#aab98a', high: '#ad9c4a' },
  low:  { low: '#ece8e0', med: '#ead9a8', high: '#e6c34d' },
};

export function bucketBreadth(b: number): Bucket {
  if (b < BREADTH_THRESHOLDS.low) return 'low';
  if (b < BREADTH_THRESHOLDS.high) return 'med';
  return 'high';
}

export function bucketDepth(d: number): Bucket {
  if (d < DEPTH_THRESHOLDS.low) return 'low';
  if (d < DEPTH_THRESHOLDS.high) return 'med';
  return 'high';
}

/** (breadth 0..1, depth 0..100) → teal×amber hex. */
export function bivariateColor(breadth: number, depth: number): string {
  return PALETTE[bucketDepth(depth)][bucketBreadth(breadth)];
}
