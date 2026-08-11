/**
 * electionsMapService.ts — "elections mode" for the coverage map.
 *
 * Recolors geographies by RACE COVERAGE (races with ≥1 candidate ÷ total) for each
 * state's NEAREST upcoming election DATE. State % composites every race at that date
 * (all levels); county % counts only races that resolve to the county. See
 * docs/superpowers/specs/2026-05-31-elections-mode-design.md.
 */
import { pool } from './db.js';
import { STATE_ABBR_TO_FIPS } from './treasuryService.js';
import { HAS_ANY_CONTRIBUTION_SQL } from './donorCoverage.js';
import {
  toSlug, PLACE_STRIP, raceCoverage, resolveRaceCountyFips, classifyCounty, classifyRaces,
  classifyRaceTier, weightedDepthScore, type RaceRow,
} from './electionsMap.js';

export interface StateElection {
  fips: string;
  code: string;
  election_date: string;
  election_type: string;
  // Statewide/legislative races only (D-01: this is the number that colors the map).
  coverage: number;
  races_total: number;
  races_covered: number;
  // Weighted 3-tier depth score (D-04) over statewide/legislative races, 0..100.
  depthScore: number;
  // Per-tier tallies over the same statewide/legislative race set.
  tierCounts: { t0: number; t1: number; t2: number; t3: number };
  // County/local-pinnable races only, N/A-safe via `status` (D-03: never a fake 0%).
  countyCoverage: { status: 'unknown' | 'scored'; coverage: number; races_total: number; races_covered: number };
  // Full statewide/legislative race list for the ELEC-02 panel — no new query.
  statewideRaces: (RaceRow & { tier: 0 | 1 | 2 | 3 })[];
}

export interface CountyElection {
  fips: string;
  name: string;
  status: 'unknown' | 'scored';
  coverage: number;
  races: RaceRow[];
}

/** Nearest upcoming election date for a state (2-letter), or null. */
export async function nextElectionDate(stateAbbr: string): Promise<{ date: string; type: string } | null> {
  const { rows } = await pool.query<{ election_date: string; election_type: string }>(
    `SELECT to_char(election_date,'YYYY-MM-DD') AS election_date, election_type
       FROM essentials.elections
      WHERE state = $1 AND election_date >= CURRENT_DATE
      ORDER BY election_date, election_type
      LIMIT 1`,
    [stateAbbr],
  );
  return rows[0] ? { date: rows[0].election_date, type: rows[0].election_type } : null;
}

/**
 * Signals (these come from the ACTUAL data, not proxy flags):
 *   stanced — candidate's politician has ≥1 compass answer in inform.politician_answers.
 *     NOT politicians.last_stances_researched_at: that timestamp is unstamped for
 *     bulk-loaded states (CA/OR have 0 stamped despite 228/108 with answers), so
 *     it badly under-reported stance coverage.
 *   motivated — candidate's politician has ≥1 contribution. The contributions table keys on
 *     politician_source_id, which is NOT an essentials id — it joins through
 *     transparent_motivations.politician_sources.essentials_politician_id.
 */
/** All races (any level) across every elections row on a given date for a state. */
export async function racesForStateDate(stateAbbr: string, date: string): Promise<RaceRow[]> {
  const { rows } = await pool.query<{
    race_id: string; position_name: string; seats: number; candidate_count: string; ocd_id: string | null;
    active_count: string; stanced_count: string; motivated_count: string;
  }>(
    `SELECT r.id AS race_id, r.position_name, r.seats,
            COUNT(rc.id) AS candidate_count, d.ocd_id,
            COUNT(rc.id) FILTER (
              WHERE essentials.is_live_candidate(rc.candidate_status, rc.result))           AS active_count,
            COUNT(rc.id) FILTER (
              WHERE essentials.is_live_candidate(rc.candidate_status, rc.result)
                AND ans.politician_id IS NOT NULL)                                          AS stanced_count,
            COUNT(rc.id) FILTER (
              WHERE essentials.is_live_candidate(rc.candidate_status, rc.result)
                AND ${HAS_ANY_CONTRIBUTION_SQL})                                             AS motivated_count
       FROM essentials.elections e
       JOIN essentials.races r ON r.election_id = e.id
       LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
       LEFT JOIN essentials.offices o ON o.id = r.office_id
       LEFT JOIN essentials.districts d ON d.id = o.district_id
       LEFT JOIN essentials.politicians p ON p.id = rc.politician_id
       LEFT JOIN (SELECT DISTINCT politician_id FROM inform.politician_answers) ans
              ON ans.politician_id = p.id
      WHERE e.state = $1 AND e.election_date = $2
      GROUP BY r.id, r.position_name, r.seats, d.ocd_id`,
    [stateAbbr, date],
  );
  return rows.map((r) => ({
    race_id: r.race_id,
    position_name: r.position_name,
    seats: Number(r.seats),
    candidate_count: Number(r.candidate_count),
    ocd_id: r.ocd_id,
    active_count: Number(r.active_count),
    stanced_count: Number(r.stanced_count),
    motivated_count: Number(r.motivated_count),
  }));
}

/** county OCD → 5-digit FIPS for a state (FIPS string). */
export async function countyOcdToFips(stateFips: string): Promise<Map<string, string>> {
  const { rows } = await pool.query<{ ocd_id: string; geo_id: string }>(
    `SELECT ocd_id, geo_id FROM essentials.geofence_boundaries
      WHERE state = $1 AND mtfcc = 'G4020' AND ocd_id IS NOT NULL`,
    [stateFips],
  );
  return new Map(rows.map((r) => [r.ocd_id, r.geo_id]));
}

/** place slug → county FIPS (largest boundary overlap). Places lack ocd_id, so slug from name. */
export async function placeSlugToFips(stateFips: string): Promise<Map<string, string>> {
  const { rows } = await pool.query<{ name: string; county_fips: string | null }>(
    `SELECT p.name,
       (SELECT c.geo_id FROM essentials.geofence_boundaries c
         WHERE c.state = $1 AND c.mtfcc = 'G4020' AND ST_Intersects(c.geometry, p.geometry)
         ORDER BY ST_Area(ST_Intersection(c.geometry, p.geometry)) DESC LIMIT 1) AS county_fips
       FROM essentials.geofence_boundaries p
      WHERE p.state = $1 AND p.mtfcc = 'G4110' AND p.name IS NOT NULL`,
    [stateFips],
  );
  const m = new Map<string, string>();
  for (const r of rows) if (r.county_fips) m.set(toSlug(r.name, PLACE_STRIP), r.county_fips);
  return m;
}

/** county FIPS → TIGER county name (for labels). */
export async function countyNames(stateFips: string): Promise<Map<string, string>> {
  const { rows } = await pool.query<{ geo_id: string; name: string }>(
    `SELECT geo_id, name FROM essentials.geofence_boundaries WHERE state = $1 AND mtfcc = 'G4020'`,
    [stateFips],
  );
  return new Map(rows.map((r) => [r.geo_id, r.name]));
}

const CACHE_TTL_MS = 10 * 60 * 1000;
const cache = new Map<string, { at: number; data: unknown }>();
function cached<T>(key: string, refresh: boolean, build: () => Promise<T>): Promise<T> {
  const hit = cache.get(key);
  if (!refresh && hit && Date.now() - hit.at < CACHE_TTL_MS) return Promise.resolve(hit.data as T);
  return build().then((data) => { cache.set(key, { at: Date.now(), data }); return data; });
}

/** Lowercase 2-letter codes of states that have ≥1 upcoming election. */
async function statesWithUpcomingElections(): Promise<string[]> {
  const { rows } = await pool.query<{ state: string }>(
    `SELECT DISTINCT state FROM essentials.elections WHERE election_date >= CURRENT_DATE`,
  );
  return rows.map((r) => r.state.toLowerCase());
}

/** US choropleth: race coverage for each state's nearest upcoming election. */
export async function getElectionsStateScores(opts: { refresh?: boolean } = {}): Promise<StateElection[]> {
  return cached('elections:us', !!opts.refresh, async () => {
    const out: StateElection[] = [];
    for (const code of await statesWithUpcomingElections()) {
      const fips = STATE_ABBR_TO_FIPS[code];
      if (!fips) continue;
      const nd = await nextElectionDate(code.toUpperCase());
      if (!nd) continue;
      const [races, countyMap, placeMap] = await Promise.all([
        racesForStateDate(code.toUpperCase(), nd.date),
        countyOcdToFips(fips),
        placeSlugToFips(fips),
      ]);
      const { statewide, countyPinnable } = classifyRaces(races, countyMap, placeMap);
      const stateCovered = statewide.filter((r) => r.candidate_count > 0).length;
      const countyCovered = countyPinnable.filter((r) => r.candidate_count > 0).length;
      const tierCounts = { t0: 0, t1: 0, t2: 0, t3: 0 };
      const statewideWithTier = statewide.map((r) => {
        const tier = classifyRaceTier({ active: r.active_count, stanced: r.stanced_count, motivated: r.motivated_count });
        tierCounts[`t${tier}` as keyof typeof tierCounts]++;
        return { ...r, tier };
      });
      out.push({
        fips, code,
        election_date: nd.date, election_type: nd.type,
        coverage: raceCoverage(statewide),
        races_total: statewide.length, races_covered: stateCovered,
        depthScore: weightedDepthScore(statewideWithTier.map((r) => r.tier)),
        tierCounts,
        countyCoverage: countyPinnable.length === 0
          ? { status: 'unknown', coverage: 0, races_total: 0, races_covered: 0 }
          : { status: 'scored', coverage: raceCoverage(countyPinnable), races_total: countyPinnable.length, races_covered: countyCovered },
        statewideRaces: statewideWithTier,
      });
    }
    return out;
  });
}

/** County choropleth + race drill-down for one state's nearest upcoming election. */
export async function getElectionsCountyScores(
  stateCode: string,
  opts: { refresh?: boolean } = {},
): Promise<{ state: string; state_fips: string; election_date: string | null; election_type: string | null; counties: CountyElection[] } | null> {
  const code = stateCode.toLowerCase();
  const fips = STATE_ABBR_TO_FIPS[code];
  if (!fips) return null;
  return cached(`elections:county:${code}`, !!opts.refresh, async () => {
    const nd = await nextElectionDate(code.toUpperCase());
    if (!nd) return { state: code, state_fips: fips, election_date: null, election_type: null, counties: [] };
    const [races, countyMap, placeMap, names] = await Promise.all([
      racesForStateDate(code.toUpperCase(), nd.date),
      countyOcdToFips(fips),
      placeSlugToFips(fips),
      countyNames(fips),
    ]);
    // bucket county-resolvable races by county fips
    const byCounty = new Map<string, RaceRow[]>();
    for (const r of races) {
      const cf = resolveRaceCountyFips(r.ocd_id, countyMap, placeMap);
      if (!cf) continue;
      const arr = byCounty.get(cf) ?? [];
      arr.push(r);
      byCounty.set(cf, arr);
    }
    // every county in the state, classified (unknown if no resolvable races)
    const counties: CountyElection[] = [...names.entries()].map(([cf, name]) => {
      const c = classifyCounty(byCounty.get(cf) ?? []);
      return { fips: cf, name, status: c.status, coverage: c.coverage, races: c.races };
    }).sort((a, b) => a.name.localeCompare(b.name));
    return { state: code, state_fips: fips, election_date: nd.date, election_type: nd.type, counties };
  });
}
