/**
 * essentialsBrowseService — browse-by-location endpoints.
 *
 * Provides cascading location selection (State → County → City/Township)
 * and area-based politician lookup via PostGIS geofence intersection.
 *
 * This replaces the need for geocoding area queries (cities, ZIPs, counties)
 * which the Census Geocoder cannot handle.
 */

import { pool } from './db.js';
import { cache } from './cache.js';
import type { PoliticianFlatRecord, FinanceSummary } from './essentialsService.js';
import { MTFCC_DISTRICT_TYPE_GUARD, type GeoPair } from './geoIdGuard.js';

// Overlap resolution is pure geometry — it only changes when geofence boundaries
// are (re)loaded, which happens during seeding, not at request time. Caching the
// result keyed by the seed set makes repeat browses of the same area near-instant.
// TTL is kept modest (1h) so a freshly-seeded city surfaces its new overlaps
// within the hour without a manual cache bust.
const OVERLAP_CACHE_TTL_SECONDS = 3600;

// Minimum interior-overlap fraction for a Branch-3 district (county / school /
// legislative) to count as overlapping a browsed area. TIGER polygon boundaries
// are imprecise, so neighboring districts often clip a browsed city by a fraction
// of a percent — real edge slivers that read as broken data (e.g. West Covina
// intersected 7 school districts; 3 are ~20-51% of the city, 4 were <1.2% slivers).
// Measured against the SMALLER of the two polygons so it works whether the seed is
// a small city (district covers X% of the city) or a large county (small district
// sits Y% inside the county). 3% cleanly separates real splits (always >>10% here)
// from boundary-imprecision slivers. Only affects AREA browse, not address lookups
// (those are point-in-polygon via ST_Covers, unaffected).
const MIN_OVERLAP_FRACTION = 0.03;

// FIPS → state abbreviation mapping
// Exported for locationSearchService.ts (212-04) — the resolver needs to map a
// geofence_boundaries.state FIPS code to a USPS abbrev when a matched
// governments row has no state of its own.
export const FIPS_TO_ABBREV: Record<string, string> = {
  '01': 'AL', '02': 'AK', '04': 'AZ', '05': 'AR', '06': 'CA',
  '08': 'CO', '09': 'CT', '10': 'DE', '11': 'DC', '12': 'FL',
  '13': 'GA', '15': 'HI', '16': 'ID', '17': 'IL', '18': 'IN',
  '19': 'IA', '20': 'KS', '21': 'KY', '22': 'LA', '23': 'ME',
  '24': 'MD', '25': 'MA', '26': 'MI', '27': 'MN', '28': 'MS',
  '29': 'MO', '30': 'MT', '31': 'NE', '32': 'NV', '33': 'NH',
  '34': 'NJ', '35': 'NM', '36': 'NY', '37': 'NC', '38': 'ND',
  '39': 'OH', '40': 'OK', '41': 'OR', '42': 'PA', '44': 'RI',
  '45': 'SC', '46': 'SD', '47': 'TN', '48': 'TX', '49': 'UT',
  '50': 'VT', '51': 'VA', '53': 'WA', '54': 'WV', '55': 'WI',
  '56': 'WY',
};

const ABBREV_TO_FIPS: Record<string, string> = {};
for (const [fips, abbrev] of Object.entries(FIPS_TO_ABBREV)) {
  ABBREV_TO_FIPS[abbrev] = fips;
}

export interface BrowseState {
  abbreviation: string;
  fips: string;
  politician_count: number;
}

export interface BrowseArea {
  geo_id: string;
  name: string;
  mtfcc: string;
  area_type: string; // "county", "city", "township"
}

/**
 * Get states that have politician data.
 */
export async function getStatesWithData(): Promise<BrowseState[]> {
  const { rows } = await pool.query(`
    SELECT DISTINCT o.representing_state AS state, COUNT(DISTINCT p.id) AS cnt
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
    WHERE p.is_active = true
    AND o.representing_state IS NOT NULL
    AND o.representing_state != ''
    AND o.representing_state NOT IN ('US')
    GROUP BY o.representing_state
    ORDER BY o.representing_state
  `);

  return rows.map((r) => ({
    abbreviation: r.state as string,
    fips: ABBREV_TO_FIPS[r.state as string] ?? '',
    politician_count: Number(r.cnt),
  }));
}

/**
 * Get browsable areas (counties, cities, townships) for a state.
 * Returns areas from geofence_boundaries grouped by type.
 */
export async function getAreasForState(stateAbbrev: string): Promise<BrowseArea[]> {
  const fips = ABBREV_TO_FIPS[stateAbbrev.toUpperCase()];
  if (!fips) return [];

  const { rows } = await pool.query(`
    SELECT DISTINCT gb.geo_id, gb.name, gb.mtfcc
    FROM essentials.geofence_boundaries gb
    WHERE gb.state = $1
    AND gb.mtfcc IN ('G4020', 'G4110', 'G4120', 'G4040', 'X0001', 'X0002', 'X0003')
    ORDER BY gb.mtfcc, gb.name
  `, [fips]);

  return rows.map((r) => {
    const mtfcc = r.mtfcc as string;
    let area_type = 'other';
    if (mtfcc === 'G4020') area_type = 'county';
    else if (mtfcc === 'G4110' || mtfcc === 'G4120') area_type = 'city';
    else if (mtfcc === 'G4040') area_type = 'township';
    else if (mtfcc === 'X0001') area_type = 'council_district';
    else if (mtfcc === 'X0002') area_type = 'school_subdistrict';
    else if (mtfcc === 'X0003') area_type = 'sboe';

    return {
      geo_id: r.geo_id as string,
      name: r.name as string,
      mtfcc,
      area_type,
    };
  });
}

// Geofence MTFCCs that are valid "seed" areas for overlap resolution: counties,
// places/cities, townships, and explicit local divisions. Legislative geofences
// (G52xx) are never seeds — they are RESULTS of resolution, not browse areas.
const AREA_SEED_MTFCCS = ['G4020', 'G4040', 'G4110', 'G4120', 'X0001'];

/**
 * Resolve every geofence boundary that overlaps a set of seed area geofences,
 * using the bidirectional PostGIS logic that mirrors the address path's
 * ST_Covers stack — but for an AREA (all overlapping districts) rather than a
 * single point:
 *   1. Sub-districts whose representative point falls WITHIN a seed
 *   2. Larger non-city districts that CONTAIN a seed's center point
 *   3. County / school / legislative districts whose interiors GENUINELY overlap
 *      a seed (ST_Intersects but NOT a zero-area boundary touch)
 *
 * Branch 3 is the key to completeness: county (G4020) and school (G54xx) used to
 * be captured by center-containment only (branches 1–2), so an area straddling
 * two counties or two school districts missed the ones not centered on it. They
 * are now matched by real interior overlap, exactly like legislative districts.
 *
 * Returns the matched (geo_id, mtfcc) pairs (seeds excluded — callers prepend
 * their own seeds). Each pair carries the MTFCC of the geofence it came from so
 * downstream district matching can apply MTFCC_DISTRICT_TYPE_GUARD and avoid the
 * 5-digit GEOID collision (e.g. State House 35 vs Salt Lake County, both 49035).
 */
export async function resolveOverlappingGeoPairs(seeds: GeoPair[]): Promise<GeoPair[]> {
  if (seeds.length === 0) return [];
  const seedGeoIds = seeds.map((s) => s.geo_id);
  const seedMtfccs = seeds.map((s) => s.mtfcc);

  // Cache keyed by the canonical (order-independent) seed set.
  const cacheKey = `overlap:v2:${seeds
    .map((s) => `${s.geo_id}::${s.mtfcc}`)
    .sort()
    .join(',')}`;
  const cached = await cache.get<GeoPair[]>(cacheKey);
  if (cached !== null) return cached;

  // Split what used to be a single OR of three spatial predicates into a UNION
  // ALL of three branches, each with an explicit bounding-box pre-filter
  // (`&&`). Postgres cannot drive a GIST index through an OR of mixed-direction
  // spatial predicates, so the old query did a full sequential scan of every
  // geofence polygon (~4s for a single area). With one predicate structure per
  // branch and a `&&` pre-filter, the planner uses the GIST index on
  // geofence_boundaries.geometry to reduce each branch to an index-driven
  // nested-loop join. Result semantics are identical — `&&` is a necessary
  // condition for every branch's exact predicate, and the outer DISTINCT
  // reproduces the original SELECT DISTINCT over the OR.
  const intersectionQuery = `
    SELECT DISTINCT t.geo_id, t.mtfcc
    FROM (
      -- Branch 1: sub-districts whose representative point falls WITHIN the area
      SELECT gb2.geo_id, gb2.mtfcc
      FROM unnest($1::text[], $2::text[]) AS seed(geo_id, mtfcc)
      JOIN essentials.geofence_boundaries gb1
        ON gb1.geo_id = seed.geo_id AND gb1.mtfcc = seed.mtfcc
      JOIN essentials.geofence_boundaries gb2
        ON NOT (gb2.geo_id = gb1.geo_id AND gb2.mtfcc = gb1.mtfcc)
       AND gb1.geometry && gb2.geometry
      WHERE ST_Contains(gb1.geometry, ST_PointOnSurface(gb2.geometry))

      UNION ALL

      -- Branch 2: larger non-city districts that CONTAIN the area's center point
      SELECT gb2.geo_id, gb2.mtfcc
      FROM unnest($1::text[], $2::text[]) AS seed(geo_id, mtfcc)
      JOIN essentials.geofence_boundaries gb1
        ON gb1.geo_id = seed.geo_id AND gb1.mtfcc = seed.mtfcc
      JOIN essentials.geofence_boundaries gb2
        ON NOT (gb2.geo_id = gb1.geo_id AND gb2.mtfcc = gb1.mtfcc)
       AND gb2.geometry && gb1.geometry
      WHERE gb2.mtfcc NOT IN ('G4110', 'G4120')
        AND ST_Contains(gb2.geometry, ST_PointOnSurface(gb1.geometry))

      UNION ALL

      -- Branch 3: county / school / legislative districts that genuinely overlap
      -- the area (interiors intersect). NOT ST_Touches excludes neighbors that
      -- merely share a boundary edge (zero-area touch), which would otherwise
      -- surface adjacent counties / districts for border areas. A real split —
      -- e.g. a city divided across two senate districts, or straddling two
      -- school districts — has overlapping interiors and is kept (verified:
      -- Alpine stays in both SD-19 ~62% and SD-21 ~38%).
      SELECT gb2.geo_id, gb2.mtfcc
      FROM unnest($1::text[], $2::text[]) AS seed(geo_id, mtfcc)
      JOIN essentials.geofence_boundaries gb1
        ON gb1.geo_id = seed.geo_id AND gb1.mtfcc = seed.mtfcc
      JOIN essentials.geofence_boundaries gb2
        ON NOT (gb2.geo_id = gb1.geo_id AND gb2.mtfcc = gb1.mtfcc)
       AND gb1.geometry && gb2.geometry
      WHERE gb2.mtfcc IN ('G5200', 'G5210', 'G5220', 'G4020', 'G5400', 'G5410', 'G5420')
        AND ST_Intersects(gb1.geometry, gb2.geometry)
        AND NOT ST_Touches(gb1.geometry, gb2.geometry)
        -- Drop boundary-imprecision slivers: require a real interior overlap of at
        -- least MIN_OVERLAP_FRACTION of the smaller polygon (see const above).
        AND ST_Area(ST_Intersection(gb1.geometry, gb2.geometry))
            >= ${MIN_OVERLAP_FRACTION} * LEAST(ST_Area(gb1.geometry), ST_Area(gb2.geometry))
    ) t
  `;

  const { rows } = await pool.query(intersectionQuery, [seedGeoIds, seedMtfccs]);
  const result = rows.map((r) => ({ geo_id: r.geo_id as string, mtfcc: r.mtfcc as string }));
  await cache.set(cacheKey, result, OVERLAP_CACHE_TTL_SECONDS);
  return result;
}

/**
 * Compute all overlapping district geo_ids for a given area boundary, plus the
 * area's resolved state abbreviation. Shared by getPoliticiansByArea and the
 * elections-by-area lookup.
 *
 * The returned `geoIds` array always includes the input `geoId` itself first.
 */
export async function getOverlappingGeoIdsForArea(
  geoId: string,
  mtfcc: string
): Promise<{ geoIds: string[]; geoPairs: GeoPair[]; stateAbbrev: string | null }> {
  const matches = await resolveOverlappingGeoPairs([{ geo_id: geoId, mtfcc }]);
  const geoIds = [geoId, ...matches.map((m) => m.geo_id)];
  const geoPairs: GeoPair[] = [{ geo_id: geoId, mtfcc }, ...matches];

  const { rows: areaRows } = await pool.query(
    `SELECT state FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = $2 LIMIT 1`,
    [geoId, mtfcc]
  );

  const stateFips = areaRows.length > 0 ? (areaRows[0].state as string) : null;
  const stateAbbrev = stateFips ? FIPS_TO_ABBREV[stateFips] ?? null : null;

  return { geoIds, geoPairs, stateAbbrev };
}

/** RSLV-06 ambiguity-note shape returned by getCongressionalOverlapNote. */
export interface CongressionalOverlapNote {
  cdGeoIds: string[];
  needsExactAddress: boolean;
}

/**
 * Surfaces the RSLV-06 "we need an exact address" ambiguity signal for a
 * resolved place-name candidate. Reuses getOverlappingGeoIdsForArea as-is — no
 * new PostGIS/ST_Intersects query is written here (the overlap geometry is
 * already GIST-index-driven; see project_geofence_overlap_perf).
 *
 * Filters geoPairs strictly to mtfcc === 'G5200' (current-officeholder
 * congressional-district vintage). 'G5200V26' (the 2026-redistricting-vintage
 * boundary set) is intentionally excluded — that vintage is reserved for the
 * separate elections opt-in join in electionService.ts, never for "who
 * represents you now" (see geoIdGuard.ts's own G5200V26 exclusion comment).
 *
 * - 0 overlapping CDs: honest omission (cdGeoIds: [], needsExactAddress:
 *   false) — never fabricate a representative.
 * - 1 overlapping CD: the area sits entirely inside a single district;
 *   needsExactAddress is false and cdGeoIds carries that district's geo_id so
 *   the /resolve route (Plan 05) can fetch its actual US House representative.
 * - >1 overlapping CDs: the area straddles multiple districts — an exact
 *   address is required to pick one. needsExactAddress is true and cdGeoIds
 *   lists every overlapping district (no auto-pick, per RSLV-07's wrong-state/
 *   silent-collapse guard).
 */
/**
 * 212-07 gap-closure fallback (RSLV-05/06/SC4 blocker) — point-in-polygon
 * lookup used ONLY when the geometry-based overlap above finds zero G5200
 * districts. The ~32k essentials.gazetteer_places rows (and
 * essentials.gazetteer_counties) ingested by migration 1378/D-08 carry NO
 * polygon — only a centroid (intptlat/intptlong) — so
 * getOverlappingGeoIdsForArea's spatial join against
 * essentials.geofence_boundaries legitimately finds nothing for those
 * geo_ids. That is indistinguishable from a genuine zero-overlap area
 * (which never happens for a real US location), so instead of trusting an
 * empty result at face value, look up the place's own Gazetteer centroid and
 * find the congressional district whose polygon contains that point.
 *
 * Looks in gazetteer_places first, then gazetteer_counties (a geo_id is
 * unique to one or the other, never both). Returns null — an honest
 * "cannot determine," never fabricated — when no centroid exists for geoId
 * (not a Gazetteer row at all, e.g. a curated place/county or a state) or
 * the centroid falls inside no CD polygon (e.g. a territory with no voting
 * House seat).
 *
 * The ST_Contains predicate is written directly against
 * essentials.geofence_boundaries.geometry (not wrapped in any function) so
 * the planner can drive it through the existing GIST index — see
 * project_geofence_overlap_perf.
 */
async function findContainingCdFromGazetteerCentroid(geoId: string): Promise<string | null> {
  const { rows: placeRows } = await pool.query<{ lon: number | null; lat: number | null }>(
    `SELECT intptlong AS lon, intptlat AS lat FROM essentials.gazetteer_places WHERE geo_id = $1`,
    [geoId]
  );

  let centroid = placeRows[0];
  if (!centroid) {
    const { rows: countyRows } = await pool.query<{ lon: number | null; lat: number | null }>(
      `SELECT intptlong AS lon, intptlat AS lat FROM essentials.gazetteer_counties WHERE geo_id = $1`,
      [geoId]
    );
    centroid = countyRows[0];
  }

  if (!centroid || centroid.lon == null || centroid.lat == null) return null;

  const { rows: cdRows } = await pool.query<{ geo_id: string }>(
    `SELECT geo_id FROM essentials.geofence_boundaries
      WHERE mtfcc = 'G5200'
        AND ST_Contains(geometry, ST_SetSRID(ST_Point($1::float8, $2::float8), 4326))
      LIMIT 1`,
    [centroid.lon, centroid.lat]
  );

  return cdRows.length > 0 ? cdRows[0].geo_id : null;
}

export async function getCongressionalOverlapNote(
  geoId: string,
  mtfcc: string
): Promise<CongressionalOverlapNote> {
  const { geoPairs } = await getOverlappingGeoIdsForArea(geoId, mtfcc);
  const cdGeoIds = Array.from(
    new Set(geoPairs.filter((p) => p.mtfcc === 'G5200').map((p) => p.geo_id))
  );

  if (cdGeoIds.length === 0) {
    // 212-07: only fires when the primary geometry overlap is empty — never
    // overrides a real (possibly multi-CD) geometry result above.
    const fallbackCd = await findContainingCdFromGazetteerCentroid(geoId);
    if (fallbackCd) {
      return { cdGeoIds: [fallbackCd], needsExactAddress: false };
    }
    return { cdGeoIds: [], needsExactAddress: false };
  }

  return { cdGeoIds, needsExactAddress: cdGeoIds.length > 1 };
}

/**
 * Resolve the full overlapping district stack (city + county + every overlapping
 * school / legislative / state-board district) for a list of government geo_ids,
 * mirroring the area browse. Looks up the area-type geofences for those
 * government geo_ids (plus an optional county geofence), then resolves overlaps
 * via resolveOverlappingGeoPairs.
 *
 * Governments whose boundaries aren't loaded contribute no geofence seeds and so
 * resolve to no district pairs — callers still surface their officials via the
 * direct government → chamber → office path.
 */
export async function getOverlappingGeoIdsForGovernments(
  governmentGeoIds: string[],
  countyGeoId?: string
): Promise<{ geoPairs: GeoPair[]; stateAbbrev: string | null }> {
  if (governmentGeoIds.length === 0) return { geoPairs: [], stateAbbrev: null };

  const lookupGeoIds = countyGeoId ? [...governmentGeoIds, countyGeoId] : governmentGeoIds;
  const { rows: seedRows } = await pool.query(
    `SELECT DISTINCT geo_id, mtfcc, state
       FROM essentials.geofence_boundaries
      WHERE geo_id = ANY($1) AND mtfcc = ANY($2)`,
    [lookupGeoIds, AREA_SEED_MTFCCS]
  );

  const seeds: GeoPair[] = seedRows.map((r) => ({ geo_id: r.geo_id as string, mtfcc: r.mtfcc as string }));
  // Ensure the explicit county seed is present even if its G4020 geofence wasn't
  // returned above (e.g. countyGeoId not among governmentGeoIds).
  if (countyGeoId && !seeds.some((s) => s.geo_id === countyGeoId && s.mtfcc === 'G4020')) {
    seeds.push({ geo_id: countyGeoId, mtfcc: 'G4020' });
  }

  const matches = await resolveOverlappingGeoPairs(seeds);

  // Dedup the union of seeds + matches by (geo_id, mtfcc).
  const seen = new Set<string>();
  const geoPairs = [...seeds, ...matches].filter((p) => {
    const k = `${p.geo_id}::${p.mtfcc}`;
    if (seen.has(k)) return false;
    seen.add(k);
    return true;
  });

  const stateFips = (seedRows.find((r) => r.state)?.state as string | undefined) ?? null;
  const stateAbbrev = stateFips ? FIPS_TO_ABBREV[stateFips] ?? null : null;

  return { geoPairs, stateAbbrev };
}

/**
 * Find all politicians whose districts overlap with a given area boundary.
 * Uses the same bidirectional PostGIS intersection logic as the Go backend.
 *
 * 1. Sub-districts whose center falls WITHIN the area
 * 2. Larger districts that CONTAIN the area's center (excluding city boundaries)
 * 3. Legislative districts that INTERSECT the area
 *
 * Then supplements with statewide officials (senators, governor).
 */
export async function getPoliticiansByArea(
  geoId: string,
  mtfcc: string
): Promise<PoliticianFlatRecord[]> {
  // Step 1: Compute all overlapping district geo_ids + resolved state via shared helper
  const { geoPairs, stateAbbrev } = await getOverlappingGeoIdsForArea(geoId, mtfcc);

  if (geoPairs.length === 0) return [];
  const pairGeoIds = geoPairs.map((p) => p.geo_id);
  const pairMtfccs = geoPairs.map((p) => p.mtfcc);

  // Step 2: Find politicians in matched districts
  const politicianQuery = `
    SELECT DISTINCT ON (p.id)
           p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party, COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url, p.web_form_url,
           p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           p.finance_summary,
           COALESCE(p.valid_from, '') AS term_start,
           COALESCE(p.valid_to, '') AS term_end,
           COALESCE(p.term_date_precision, '') AS term_date_precision,
           COALESCE(p.appointment_date::text, '') AS appointment_date,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.voting_powers, o.representation_note,
           o.is_appointed_position, o.is_vacant, o.vacant_since,
           p.is_appointed, o.faces_retention_vote,
           d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency,
           ch.policy_engagement_level,
           g.name AS government_name,
           g.type AS government_type,
           COALESCE(gvb.display_name, '') AS government_body_name,
           COALESCE(gvb.website_url, '') AS government_body_url,
           COALESCE(ch.website_url, '') AS chamber_url
    FROM essentials.districts d
    JOIN unnest($1::text[], $2::text[]) AS gp(geo_id, mtfcc)
      ON gp.geo_id = d.geo_id AND ${MTFCC_DISTRICT_TYPE_GUARD}
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state
      AND gvb.geo_id = d.geo_id
      AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
    WHERE p.is_active = true
      -- Candidate placeholder offices (mig 196) sit on real statewide districts, which
      -- overlap every area — without this exclusion they leak here even though Step 3
      -- filters them (the 0fc58bb6 fix missed this query; Talarico/Paxton via Allen, TX).
      AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'
    ORDER BY p.id
  `;

  const { rows: polRows } = await pool.query(politicianQuery, [pairGeoIds, pairMtfccs]);

  // Step 3: Use stateAbbrev (resolved by getOverlappingGeoIdsForArea) to add statewide officials
  let statewideRows: typeof polRows = [];
  if (stateAbbrev) {
    const statewideQuery = `
      SELECT DISTINCT ON (p.id)
             p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
             p.preferred_name, p.name_suffix, p.party, COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url, p.web_form_url,
             p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
             p.finance_summary,
           COALESCE(p.valid_from, '') AS term_start,
           COALESCE(p.valid_to, '') AS term_end,
           COALESCE(p.term_date_precision, '') AS term_date_precision,
           COALESCE(p.appointment_date::text, '') AS appointment_date,
             o.title AS office_title, o.representing_state, o.representing_city,
             o.voting_powers, o.representation_note,
             o.is_appointed_position, o.is_vacant, o.vacant_since,
             p.is_appointed, o.faces_retention_vote,
             d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
             ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
             ch.election_frequency,
             ch.policy_engagement_level,
             g.name AS government_name,
             g.type AS government_type,
             COALESCE(gvb.display_name, '') AS government_body_name,
             COALESCE(gvb.website_url, '') AS government_body_url,
             COALESCE(ch.website_url, '') AS chamber_url
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
      LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
      LEFT JOIN essentials.governments g ON g.id = ch.government_id
      LEFT JOIN essentials.government_bodies gvb
        ON gvb.state = d.state
        AND gvb.geo_id = d.geo_id
        AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
      WHERE d.district_type IN ('NATIONAL_UPPER', 'STATE_EXEC', 'NATIONAL_EXEC')
      AND (d.state = $1 OR d.district_type = 'NATIONAL_EXEC')
      AND p.is_active = true
      AND p.is_incumbent = true
      -- Candidate placeholder offices (mig 196 pattern, e.g. "Candidate for U.S. Senate — Texas")
      -- exist for compass/stance reachability only; their holders can be incumbents of OTHER
      -- offices (Talarico TX House, Paxton AG), so is_incumbent alone cannot exclude them.
      AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'
      ORDER BY p.id
    `;
    const result = await pool.query(statewideQuery, [stateAbbrev]);
    statewideRows = result.rows;
  }

  // Combine and deduplicate
  const allRows = [...polRows, ...statewideRows];
  const seen = new Set<string>();
  const uniqueRows = allRows.filter((r) => {
    const id = r.id as string;
    if (seen.has(id)) return false;
    seen.add(id);
    return true;
  });

  const politicians: PoliticianFlatRecord[] = uniqueRows.map((row) => ({
    id: row.id as string,
    external_id: row.external_id != null ? Number(row.external_id) : null,
    first_name: row.first_name ?? '',
    middle_initial: row.middle_initial ?? '',
    last_name: row.last_name ?? '',
    preferred_name: row.preferred_name ?? '',
    name_suffix: row.name_suffix ?? '',
    full_name: row.full_name ?? '',
    party: row.party ?? '',
    photo_origin_url: row.photo_origin_url ?? '',
    web_form_url: row.web_form_url ?? '',
    urls: row.urls ?? null,
    email_addresses: row.email_addresses ?? null,
    office_title: row.office_title ?? '',
    representing_state: row.representing_state ?? '',
    representing_city: row.representing_city ?? '',
    district_type: row.district_type ?? '',
    district_label: row.district_label ?? '',
    district_id: row.district_id ?? '',
    geo_id: row.geo_id ?? '',
    mtfcc: row.mtfcc ?? '',
    chamber_name: row.chamber_name ?? '',
    chamber_name_formal: row.chamber_name_formal ?? '',
    government_name: row.government_name ?? '',
    government_body_name: row.government_body_name ?? '',
    government_body_url: row.government_body_url ?? '',
    chamber_url: row.chamber_url ?? '',
    government_type: row.government_type ?? '',
    is_elected: !row.is_appointed_position,
    voting_powers: (row.voting_powers as 'full' | 'committee_only' | 'non_voting') ?? 'full',
    representation_note: (row.representation_note as string | null) ?? null,
    is_appointed: row.is_appointed ?? false,
    faces_retention_vote: row.faces_retention_vote ?? false,
    election_frequency: row.election_frequency ?? '',
    policy_engagement_level: (row.policy_engagement_level as 'full' | 'record_only' | 'none') ?? 'full',
    committees: [],
    bio_text: row.bio_text ?? null,
    slug: row.slug ?? null,
    is_incumbent: row.is_incumbent ?? false,
    term_start: row.term_start ?? '',
    term_end: row.term_end ?? '',
    term_date_precision: row.term_date_precision ?? '',
    appointment_date: row.appointment_date ?? '',
    office_description: '',
    is_vacant: row.is_vacant ?? false,
    vacant_since: row.vacant_since ?? null,
    next_primary_date: row.next_primary_date ?? '',
    next_general_date: row.next_general_date ?? '',
    images: [],
    finance_summary: (row.finance_summary as FinanceSummary | null) ?? null,
  }));

  // Batch-fetch images and committees
  if (politicians.length > 0) {
    const ids = politicians.map((p) => p.id);
    const [{ rows: imgRows }, { rows: commRows }] = await Promise.all([
      pool.query(
        `SELECT id, politician_id, url, type, COALESCE(photo_license, '') AS photo_license, focal_point
         FROM essentials.politician_images WHERE politician_id = ANY($1)`,
        [ids]
      ),
      pool.query(
        `SELECT m.politician_id,
                COALESCE(c.name, '') AS name,
                COALESCE(m.role, 'Member') AS position
         FROM essentials.legislative_committee_memberships m
         JOIN essentials.legislative_committees c ON c.id = m.committee_id
         WHERE m.politician_id = ANY($1)
         ORDER BY m.is_current DESC, c.name ASC`,
        [ids]
      ),
    ]);
    const imageMap = new Map<string, Array<{ id: string; url: string; type: string; photo_license: string; focal_point: string | null }>>();
    for (const r of imgRows) {
      const pid = r.politician_id as string;
      if (!imageMap.has(pid)) imageMap.set(pid, []);
      imageMap.get(pid)!.push({
        id: r.id as string,
        url: r.url ?? '',
        type: r.type ?? '',
        photo_license: r.photo_license ?? '',
        focal_point: (r.focal_point as string) ?? null,
      });
    }
    const committeeMap = new Map<string, Array<{ name: string; position: string; urls: string[] }>>();
    for (const r of commRows) {
      const pid = r.politician_id as string;
      if (!committeeMap.has(pid)) committeeMap.set(pid, []);
      committeeMap.get(pid)!.push({
        name: r.name ?? '',
        position: r.position ?? 'Member',
        urls: [],
      });
    }
    for (const p of politicians) {
      p.images = imageMap.get(p.id) ?? [];
      (p as { committees: Array<{ name: string; position: string; urls: string[] }> }).committees = committeeMap.get(p.id) ?? [];
    }
  }

  return politicians;
}

// District-politician SELECT shared by the geofence-resolved lookups. Identical
// to getPoliticiansByArea's Step 2 projection so both produce the same shape.
const DISTRICT_POLITICIAN_SELECT = `
  DISTINCT ON (p.id)
  p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
  p.preferred_name, p.name_suffix, p.party,
  COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url, p.web_form_url,
  p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
  p.finance_summary,
  COALESCE(p.valid_from, '') AS term_start,
  COALESCE(p.valid_to, '') AS term_end,
  COALESCE(p.term_date_precision, '') AS term_date_precision,
  COALESCE(p.appointment_date::text, '') AS appointment_date,
  o.title AS office_title, o.representing_state, o.representing_city,
  o.voting_powers, o.representation_note,
  o.is_appointed_position, o.is_vacant, o.vacant_since,
  p.is_appointed, o.faces_retention_vote,
  d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
  ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
  ch.election_frequency, ch.policy_engagement_level,
  g.name AS government_name, g.type AS government_type,
  COALESCE(gvb.display_name, '') AS government_body_name,
  COALESCE(gvb.website_url, '') AS government_body_url,
  COALESCE(ch.website_url, '') AS chamber_url`;

/**
 * Fetch active politicians for a set of resolved (geo_id, mtfcc) district pairs,
 * applying MTFCC_DISTRICT_TYPE_GUARD so the 5-digit GEOID collision and
 * unpopulated districts.mtfcc are both handled. Shared by the geofence-resolved
 * portion of the government-list browse.
 */
async function fetchDistrictPoliticianRows(geoPairs: GeoPair[]): Promise<Record<string, unknown>[]> {
  if (geoPairs.length === 0) return [];
  const { rows } = await pool.query<Record<string, unknown>>(
    `
      SELECT ${DISTRICT_POLITICIAN_SELECT}
      FROM essentials.districts d
      JOIN unnest($1::text[], $2::text[]) AS gp(geo_id, mtfcc)
        ON gp.geo_id = d.geo_id AND ${MTFCC_DISTRICT_TYPE_GUARD}
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
      LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
      LEFT JOIN essentials.governments g ON g.id = ch.government_id
      LEFT JOIN essentials.government_bodies gvb
        ON gvb.state = d.state
        AND gvb.geo_id = d.geo_id
        AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
      WHERE p.is_active = true
        AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'
      ORDER BY p.id
    `,
    [geoPairs.map((p) => p.geo_id), geoPairs.map((p) => p.mtfcc)]
  );
  return rows;
}

/**
 * Find all politicians for a specific list of government geo_ids.
 *
 * Combines three sources, deduped by politician id:
 *   1. Officials linked directly through governments → chambers → offices (city /
 *      township at-large offices, incl. those with no district/geofence record).
 *   2. Statewide + federal officials for the resolved state.
 *   3. The full overlapping district stack (county, school, state board, state
 *      house/senate, US House) resolved from the government geofences — the same
 *      stack the area browse returns.
 */
export async function getPoliticiansByGovernmentList(
  governmentGeoIds: string[],
  stateAbbrev?: string,
  options: { countyGeoId?: string; skipOverlap?: boolean } = {}
): Promise<PoliticianFlatRecord[]> {
  if (governmentGeoIds.length === 0) return [];
  const { countyGeoId, skipOverlap } = options;

  const { rows } = await pool.query<Record<string, unknown>>(`
    SELECT p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party,
           COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
           p.web_form_url, p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           p.finance_summary,
           COALESCE(p.valid_from, '') AS term_start,
           COALESCE(p.valid_to, '') AS term_end,
           COALESCE(p.term_date_precision, '') AS term_date_precision,
           COALESCE(p.appointment_date::text, '') AS appointment_date,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.voting_powers, o.representation_note,
           o.is_appointed_position, o.is_vacant, o.vacant_since,
           p.is_appointed, o.faces_retention_vote,
           -- district_type is a fact about the DISTRICT; governments.type is only a fallback for a
           -- district-less office. The merge below keeps THIS query's row over the overlap query's
           -- row for the same person, so a type derived from g.type silently overwrote a correct
           -- d.district_type (LASC judges JUDICIAL -> COUNTY, King County council -> COUNTY, state
           -- legislators -> '' which the frontend files as Local). Measured 2026-09-23.
           CASE
             WHEN COALESCE(d.district_type, '') <> '' THEN d.district_type
             WHEN g.type IN ('LOCAL', 'City', 'Town', 'Township', 'Village')
                  AND LOWER(o.title) ~ '(mayor|city manager|city administrator|city secretary|village president|town chairperson)'
               THEN 'LOCAL_EXEC'
             WHEN g.type IN ('LOCAL', 'City', 'Town', 'Township', 'Village') THEN 'LOCAL'
             WHEN g.type = 'County' THEN 'COUNTY'
             WHEN g.type = 'School District' THEN 'SCHOOL'
             ELSE ''
           END AS district_type,
           COALESCE(d.label, '') AS district_label,
           COALESCE(d.district_id, '') AS district_id,
           COALESCE(d.geo_id, g.geo_id) AS geo_id, COALESCE(d.mtfcc, '') AS mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency, ch.policy_engagement_level,
           g.name AS government_name, g.type AS government_type,
           COALESCE(ch.website_url, '') AS chamber_url,
           CASE WHEN d.district_type = 'SCHOOL' THEN COALESCE(ch.name_formal, ch.name, '') ELSE '' END AS government_body_name,
           '' AS government_body_url
    FROM essentials.governments g
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = ch.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    WHERE g.geo_id = ANY($1)
      AND p.is_active = true
      AND p.is_vacant = false
      AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'
    ORDER BY p.id
  `, [governmentGeoIds]);

  // Supplemental query: add state-wide and federal officials (same as by-area Step 3)
  let statewideRows: typeof rows = [];
  if (stateAbbrev) {
    const { rows: swRows } = await pool.query<Record<string, unknown>>(`
      SELECT DISTINCT ON (p.id)
             p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
             p.preferred_name, p.name_suffix, p.party,
             COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
             p.web_form_url, p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
             p.finance_summary,
             COALESCE(p.valid_from, '') AS term_start,
             COALESCE(p.valid_to, '') AS term_end,
             COALESCE(p.term_date_precision, '') AS term_date_precision,
             COALESCE(p.appointment_date::text, '') AS appointment_date,
             o.title AS office_title, o.representing_state, o.representing_city,
             o.voting_powers, o.representation_note,
             o.is_appointed_position, o.is_vacant, o.vacant_since,
             p.is_appointed, o.faces_retention_vote,
             d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
             ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
             ch.election_frequency, ch.policy_engagement_level,
             g.name AS government_name, g.type AS government_type,
             COALESCE(gvb.display_name, '') AS government_body_name,
             COALESCE(gvb.website_url, '') AS government_body_url,
             COALESCE(ch.website_url, '') AS chamber_url
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
      LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
      LEFT JOIN essentials.governments g ON g.id = ch.government_id
      LEFT JOIN essentials.government_bodies gvb
        ON gvb.state = d.state
        AND gvb.geo_id = d.geo_id
        AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
      WHERE d.district_type IN ('NATIONAL_UPPER', 'STATE_EXEC', 'NATIONAL_EXEC', 'NATIONAL_JUDICIAL')
        AND (d.state = $1 OR d.district_type IN ('NATIONAL_EXEC', 'NATIONAL_JUDICIAL'))
        AND p.is_active = true
        AND p.is_incumbent = true
      -- Candidate placeholder offices (mig 196 pattern, e.g. "Candidate for U.S. Senate — Texas")
      -- exist for compass/stance reachability only; their holders can be incumbents of OTHER
      -- offices (Talarico TX House, Paxton AG), so is_incumbent alone cannot exclude them.
      AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'
      ORDER BY p.id
    `, [stateAbbrev]);
    statewideRows = swRows;
  }

  // District officials resolved from the government geofences: county, school,
  // state board, state house/senate, and US House reps whose district boundary
  // overlaps the city/place (or the optional county) geofence. Mirrors the
  // address/area path's full overlapping stack via resolveOverlappingGeoPairs +
  // the MTFCC guard. Subsumes the previous county-only and city-geofence
  // congressional/legislative supplements, and additionally surfaces the county
  // + school + state-board officials those omitted (the reported bug).
  // skipOverlap: for a county browse we want only the county government's own
  // officials (board + sheriff/DA/assessor) plus statewide — NOT every district
  // that overlaps the (county-sized) geofence, which would pull in all the cities,
  // school boards, etc. inside it (hundreds of officials).
  let districtRows: typeof rows = [];
  if (!skipOverlap) {
    const { geoPairs: districtPairs } = await getOverlappingGeoIdsForGovernments(governmentGeoIds, countyGeoId);
    districtRows = await fetchDistrictPoliticianRows(districtPairs);
  }

  // Merge and deduplicate by politician ID
  const seen = new Set<string>();
  const allRows = [...rows, ...statewideRows, ...districtRows].filter((r) => {
    const id = r.id as string;
    if (seen.has(id)) return false;
    seen.add(id);
    return true;
  });

  const politicians: PoliticianFlatRecord[] = allRows.map((row) => ({
    id: row.id as string,
    external_id: row.external_id != null ? Number(row.external_id) : null,
    first_name: row.first_name as string ?? '',
    middle_initial: row.middle_initial as string ?? '',
    last_name: row.last_name as string ?? '',
    preferred_name: row.preferred_name as string ?? '',
    name_suffix: row.name_suffix as string ?? '',
    full_name: row.full_name as string ?? '',
    party: row.party as string ?? '',
    photo_origin_url: row.photo_origin_url as string ?? '',
    web_form_url: row.web_form_url as string ?? '',
    urls: row.urls as string[] ?? null,
    email_addresses: row.email_addresses as string[] ?? null,
    office_title: row.office_title as string ?? '',
    representing_state: row.representing_state as string ?? '',
    representing_city: row.representing_city as string ?? '',
    district_type: row.district_type as string ?? '',
    district_label: row.district_label as string ?? '',
    district_id: row.district_id as string ?? '',
    geo_id: row.geo_id as string ?? '',
    mtfcc: row.mtfcc as string ?? '',
    chamber_name: row.chamber_name as string ?? '',
    chamber_name_formal: row.chamber_name_formal as string ?? '',
    government_name: row.government_name as string ?? '',
    government_body_name: row.government_body_name as string ?? '',
    government_body_url: row.government_body_url as string ?? '',
    chamber_url: row.chamber_url as string ?? '',
    government_type: row.government_type as string ?? '',
    is_elected: !(row.is_appointed_position as boolean),
    voting_powers: (row.voting_powers as 'full' | 'committee_only' | 'non_voting') ?? 'full',
    representation_note: (row.representation_note as string | null) ?? null,
    is_appointed: row.is_appointed as boolean ?? false,
    faces_retention_vote: row.faces_retention_vote as boolean ?? false,
    election_frequency: row.election_frequency as string ?? '',
    policy_engagement_level: (row.policy_engagement_level as 'full' | 'record_only' | 'none') ?? 'full',
    committees: [],
    bio_text: row.bio_text as string ?? null,
    slug: row.slug as string ?? null,
    is_incumbent: row.is_incumbent as boolean ?? false,
    term_start: row.term_start as string ?? '',
    term_end: row.term_end as string ?? '',
    term_date_precision: row.term_date_precision as string ?? '',
    appointment_date: row.appointment_date as string ?? '',
    office_description: '',
    next_primary_date: '',
    next_general_date: '',
    images: [],
    is_vacant: row.is_vacant as boolean ?? false,
    vacant_since: (row.vacant_since as string | null) ?? null,
    finance_summary: (row.finance_summary as FinanceSummary | null) ?? null,
  }));

  // Attach images
  if (politicians.length > 0) {
    const ids = politicians.map((p) => p.id);
    const { rows: imgRows } = await pool.query(
      `SELECT id, politician_id, url, type, COALESCE(photo_license, '') AS photo_license, focal_point FROM essentials.politician_images WHERE politician_id = ANY($1)`,
      [ids]
    );
    const imageMap = new Map<string, Array<{ id: string; url: string; type: string; photo_license: string; focal_point: string | null }>>();
    for (const r of imgRows) {
      const pid = r.politician_id as string;
      if (!imageMap.has(pid)) imageMap.set(pid, []);
      imageMap.get(pid)!.push({ id: r.id as string, url: r.url, type: r.type, photo_license: r.photo_license, focal_point: (r.focal_point as string) ?? null });
    }
    for (const p of politicians) p.images = imageMap.get(p.id) ?? [];
  }

  return politicians;
}

// ---------------------------------------------------------------------------
// getStatewideOfficials — "browse a state" entry point.
//
// Returns officials that aren't tied to a specific city/district: state
// executives (Governor, Lt. Gov, AG, Secretary of State, Treasurer, …), the
// state's US Senators, and federal executive/judicial officials. Same statewide
// supplement the by-government-list / by-area paths layer on top of local
// officials, surfaced on its own. State legislature and US House are excluded
// (district-based — they need an address/area).
// ---------------------------------------------------------------------------

function mapBrowseRow(row: Record<string, unknown>): PoliticianFlatRecord {
  return {
    id: row.id as string,
    external_id: row.external_id != null ? Number(row.external_id) : null,
    first_name: (row.first_name as string) ?? '',
    middle_initial: (row.middle_initial as string) ?? '',
    last_name: (row.last_name as string) ?? '',
    preferred_name: (row.preferred_name as string) ?? '',
    name_suffix: (row.name_suffix as string) ?? '',
    full_name: (row.full_name as string) ?? '',
    party: (row.party as string) ?? '',
    photo_origin_url: (row.photo_origin_url as string) ?? '',
    web_form_url: (row.web_form_url as string) ?? '',
    urls: (row.urls as string[]) ?? null,
    email_addresses: (row.email_addresses as string[]) ?? null,
    office_title: (row.office_title as string) ?? '',
    representing_state: (row.representing_state as string) ?? '',
    representing_city: (row.representing_city as string) ?? '',
    district_type: (row.district_type as string) ?? '',
    district_label: (row.district_label as string) ?? '',
    district_id: (row.district_id as string) ?? '',
    geo_id: (row.geo_id as string) ?? '',
    mtfcc: (row.mtfcc as string) ?? '',
    chamber_name: (row.chamber_name as string) ?? '',
    chamber_name_formal: (row.chamber_name_formal as string) ?? '',
    government_name: (row.government_name as string) ?? '',
    government_body_name: (row.government_body_name as string) ?? '',
    government_body_url: (row.government_body_url as string) ?? '',
    chamber_url: (row.chamber_url as string) ?? '',
    government_type: (row.government_type as string) ?? '',
    is_elected: !(row.is_appointed_position as boolean),
    voting_powers: (row.voting_powers as 'full' | 'committee_only' | 'non_voting') ?? 'full',
    representation_note: (row.representation_note as string | null) ?? null,
    is_appointed: (row.is_appointed as boolean) ?? false,
    faces_retention_vote: (row.faces_retention_vote as boolean) ?? false,
    election_frequency: (row.election_frequency as string) ?? '',
    policy_engagement_level: (row.policy_engagement_level as 'full' | 'record_only' | 'none') ?? 'full',
    committees: [],
    bio_text: (row.bio_text as string) ?? null,
    slug: (row.slug as string) ?? null,
    is_incumbent: (row.is_incumbent as boolean) ?? false,
    term_start: (row.term_start as string) ?? '',
    term_end: (row.term_end as string) ?? '',
    term_date_precision: (row.term_date_precision as string) ?? '',
    appointment_date: (row.appointment_date as string) ?? '',
    office_description: '',
    next_primary_date: '',
    next_general_date: '',
    images: [],
    is_vacant: (row.is_vacant as boolean) ?? false,
    vacant_since: (row.vacant_since as string | null) ?? null,
    finance_summary: (row.finance_summary as FinanceSummary | null) ?? null,
  };
}

async function attachBrowseImages(politicians: PoliticianFlatRecord[]): Promise<void> {
  if (politicians.length === 0) return;
  const ids = politicians.map((p) => p.id);
  const { rows: imgRows } = await pool.query(
    `SELECT id, politician_id, url, type, COALESCE(photo_license, '') AS photo_license, focal_point FROM essentials.politician_images WHERE politician_id = ANY($1)`,
    [ids]
  );
  const imageMap = new Map<string, Array<{ id: string; url: string; type: string; photo_license: string; focal_point: string | null }>>();
  for (const r of imgRows) {
    const pid = r.politician_id as string;
    if (!imageMap.has(pid)) imageMap.set(pid, []);
    imageMap.get(pid)!.push({ id: r.id as string, url: r.url as string, type: r.type as string, photo_license: r.photo_license as string, focal_point: (r.focal_point as string) ?? null });
  }
  for (const p of politicians) p.images = imageMap.get(p.id) ?? [];
}

export async function getStatewideOfficials(stateAbbrev: string): Promise<PoliticianFlatRecord[]> {
  const abbrev = (stateAbbrev || '').trim().toUpperCase();
  if (!abbrev || !ABBREV_TO_FIPS[abbrev]) return [];

  const { rows } = await pool.query<Record<string, unknown>>(`
    SELECT DISTINCT ON (p.id)
           p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party,
           COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
           p.web_form_url, p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           p.finance_summary,
           COALESCE(p.valid_from, '') AS term_start,
           COALESCE(p.valid_to, '') AS term_end,
           COALESCE(p.term_date_precision, '') AS term_date_precision,
           COALESCE(p.appointment_date::text, '') AS appointment_date,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.voting_powers, o.representation_note,
           o.is_appointed_position, o.is_vacant, o.vacant_since,
           p.is_appointed, o.faces_retention_vote,
           d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency, ch.policy_engagement_level,
           g.name AS government_name, g.type AS government_type,
           COALESCE(gvb.display_name, '') AS government_body_name,
           COALESCE(gvb.website_url, '') AS government_body_url,
           COALESCE(ch.website_url, '') AS chamber_url
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state
      AND gvb.geo_id = d.geo_id
      AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
    WHERE (
        d.district_type IN ('NATIONAL_UPPER', 'STATE_EXEC', 'NATIONAL_EXEC', 'NATIONAL_JUDICIAL')
        -- DC's citywide seats — see the matching clause in resolveOfficialsAtPoint
        -- (src/lib/essentialsService.ts), which this must stay in step with. Keyed on the at-large
        -- geo_ids rather than district_type because DC's 8 ward seats are CITY_COUNCIL too, and
        -- admitting the type would put all eight wards in the statewide bucket.
        -- This function backs BOTH the D-05 state-scoped fallback in getRepresentativesByCoordinate
        -- and the browse-by-state officials route, so DC's browse view needs it as well.
        OR (lower(d.state) = 'dc' AND d.geo_id IN ('dc-council-at-large', 'dc-sboe-at-large'))
      )
      AND (d.state = $1 OR d.district_type IN ('NATIONAL_EXEC', 'NATIONAL_JUDICIAL'))
      AND p.is_active = true
      AND p.is_incumbent = true
      -- Candidate placeholder offices (mig 196 pattern, e.g. "Candidate for U.S. Senate — Texas")
      -- exist for compass/stance reachability only; their holders can be incumbents of OTHER
      -- offices (Talarico TX House, Paxton AG), so is_incumbent alone cannot exclude them.
      AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'
    ORDER BY p.id
  `, [abbrev]);

  const politicians = rows.map(mapBrowseRow);
  await attachBrowseImages(politicians);
  return politicians;
}

// ---------------------------------------------------------------------------
// getFederalOfficials — "browse the United States" entry point.
//
// Returns ALL federal-tier officials nationally, independent of any state:
// U.S. Senate (NATIONAL_UPPER), U.S. House (NATIONAL_LOWER), the federal
// executive incl. President/VP/Cabinet/independent agencies (NATIONAL_EXEC),
// and the federal judiciary (NATIONAL_JUDICIAL). Unlike getStatewideOfficials
// there is no state filter and US House IS included (the national browse wants
// every representative, not just one state's). Mirrors the same SELECT/joins so
// the frontend classifier groups the results identically.
// ---------------------------------------------------------------------------

export async function getFederalOfficials(): Promise<PoliticianFlatRecord[]> {
  const { rows } = await pool.query<Record<string, unknown>>(`
    SELECT DISTINCT ON (p.id)
           p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party,
           COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
           p.web_form_url, p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           p.finance_summary,
           COALESCE(p.valid_from, '') AS term_start,
           COALESCE(p.valid_to, '') AS term_end,
           COALESCE(p.term_date_precision, '') AS term_date_precision,
           COALESCE(p.appointment_date::text, '') AS appointment_date,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.voting_powers, o.representation_note,
           o.is_appointed_position, o.is_vacant, o.vacant_since,
           p.is_appointed, o.faces_retention_vote,
           d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency, ch.policy_engagement_level,
           g.name AS government_name, g.type AS government_type,
           COALESCE(gvb.display_name, '') AS government_body_name,
           COALESCE(gvb.website_url, '') AS government_body_url,
           COALESCE(ch.website_url, '') AS chamber_url
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state
      AND gvb.geo_id = d.geo_id
      AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
    WHERE d.district_type IN ('NATIONAL_EXEC', 'NATIONAL_JUDICIAL', 'NATIONAL_UPPER', 'NATIONAL_LOWER')
      AND p.is_active = true
      AND p.is_incumbent = true
      -- Candidate placeholder offices (mig 196 pattern, e.g. "Candidate for U.S. Senate — Texas")
      -- exist for compass/stance reachability only; their holders can be incumbents of OTHER
      -- offices (Talarico TX House, Paxton AG), so is_incumbent alone cannot exclude them.
      AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'
    ORDER BY p.id
  `);

  const politicians = rows.map(mapBrowseRow);
  await attachBrowseImages(politicians);
  return politicians;
}
