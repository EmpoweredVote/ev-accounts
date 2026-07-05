/**
 * Pure helpers for elections mode (no DB). The "metric" is RACE COVERAGE:
 * the fraction of races that have at least one candidate loaded.
 */

export interface RaceRow {
  race_id: string;
  position_name: string;
  seats: number;
  candidate_count: number;
  ocd_id: string | null; // race's district OCD (via office → district), if any
  active_count: number; // non-withdrawn candidates (D-03: null-politician_id rows count here)
  stanced_count: number; // of active_count, how many have ≥1 compass answer
  motivated_count: number; // of active_count, how many have ≥1 contribution
}

export interface ClassifiedCounty {
  status: 'unknown' | 'scored';
  coverage: number; // 0..100 (0 when unknown)
  races: RaceRow[];
}

/** TIGER name → OCD-style slug (shared with coverageMapService). */
export function toSlug(name: string, strip: RegExp): string {
  return name
    .replace(strip, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}
export const PLACE_STRIP = / (city|town)$/i;

/** Coverage % = races with ≥1 candidate ÷ total, one decimal. */
export function raceCoverage(races: RaceRow[]): number {
  if (races.length === 0) return 0;
  const covered = races.filter((r) => r.candidate_count > 0).length;
  return Math.round((covered / races.length) * 1000) / 10;
}

/**
 * A race's tier is set by its weakest active candidate (min/ALL rule, D-01):
 * T3 iff active>0 AND stanced===active AND motivated===active; T2 iff active>0
 * AND (stanced===active OR motivated===active); T1 iff active>0; else T0.
 */
export function classifyRaceTier(r: { active: number; stanced: number; motivated: number }): 0 | 1 | 2 | 3 {
  if (r.active === 0) return 0;
  if (r.stanced === r.active && r.motivated === r.active) return 3;
  if (r.stanced === r.active || r.motivated === r.active) return 2;
  return 1;
}

/** Weighted depth score: T0=0, T1=1/3, T2=2/3, T3=1, averaged and scaled 0..100, one decimal (D-04). */
export function weightedDepthScore(tiers: number[]): number {
  if (tiers.length === 0) return 0;
  const sum = tiers.reduce((acc, t) => acc + t / 3, 0);
  return Math.round((sum / tiers.length) * 100 * 10) / 10;
}

/**
 * Which county (5-digit FIPS) a race belongs to, or null if it can't be pinned to
 * one (federal / state / legislative-district / statewide races).
 *   - .../county:X[/...]  → direct lookup on the county-level prefix, so nested
 *     sub-district OCDs like .../county:salt_lake/council_district:5 resolve to
 *     the parent county.
 *   - .../place:Y[/...]   → the county that place sits in (largest-overlap map);
 *     nested sub-segments like .../place:portland/ward:3 also resolve correctly.
 */
export function resolveRaceCountyFips(
  ocdId: string | null,
  countyOcdToFips: Map<string, string>,
  placeSlugToFips: Map<string, string>,
): string | null {
  if (!ocdId) return null;
  // County: look up the county-level prefix (everything up to & including county:X),
  // so nested sub-district OCDs (.../county:salt_lake/council_district:5) still resolve.
  const county = ocdId.match(/^(.*\/county:[^/]+)/);
  if (county) return countyOcdToFips.get(county[1]) ?? null;
  // Place: the slug, ignoring any trailing sub-segment (.../place:portland/ward:3).
  const place = ocdId.match(/\/place:([^/]+)/);
  if (place) return placeSlugToFips.get(place[1]) ?? null;
  return null; // cd / sldu / sldl / bare state → state-level only
}

/** Classify a county's resolved race set into the unknown / scored buckets. */
export function classifyCounty(races: RaceRow[]): ClassifiedCounty {
  if (races.length === 0) return { status: 'unknown', coverage: 0, races: [] };
  // `scored` with coverage: 0 means races exist here but none have candidates yet (distinct from `unknown` = no races resolve to this county).
  return { status: 'scored', coverage: raceCoverage(races), races };
}

/**
 * Partition a state's races into statewide/legislative vs county/local-pinnable
 * buckets, using resolveRaceCountyFips as the single source of truth for the
 * split (null → statewide, non-null → countyPinnable). Pure, no I/O.
 */
export function classifyRaces(
  races: RaceRow[],
  countyOcdToFips: Map<string, string>,
  placeSlugToFips: Map<string, string>,
): { statewide: RaceRow[]; countyPinnable: RaceRow[] } {
  const statewide: RaceRow[] = [];
  const countyPinnable: RaceRow[] = [];
  for (const r of races) {
    const cf = resolveRaceCountyFips(r.ocd_id, countyOcdToFips, placeSlugToFips);
    (cf ? countyPinnable : statewide).push(r);
  }
  return { statewide, countyPinnable };
}
