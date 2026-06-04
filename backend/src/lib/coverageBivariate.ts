/**
 * coverageBivariate.ts — pure breadth/depth aggregation for the bivariate
 * completeness map. No DB access; unit-tested. coverageMapService feeds it the
 * per-unit (started, depth) pairs it already computes via buildJurisdictions.
 *
 * breadth = fraction of child units that are started (≥1 active politician).
 * depth   = mean composite over the STARTED units only — white space is carried
 *           by breadth, not by dragging depth toward zero.
 */
export interface Unit {
  started: boolean;
  depth: number; // that unit's own composite/depth, 0..100
}

export interface BreadthDepth {
  breadth: number; // 0..1
  depth: number;   // 0..100, one decimal
  started: number;
  total: number;
}

export function aggregateUnits(units: Unit[]): BreadthDepth {
  const total = units.length;
  const startedUnits = units.filter((u) => u.started);
  const started = startedUnits.length;
  const breadth = total > 0 ? started / total : 0;
  const depth =
    started > 0 ? startedUnits.reduce((s, u) => s + u.depth, 0) / started : 0;
  return { breadth, depth: Math.round(depth * 10) / 10, started, total };
}
