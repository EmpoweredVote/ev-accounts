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
