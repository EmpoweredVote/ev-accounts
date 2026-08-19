/**
 * zipQueries — SQL text and pure helpers for ZIP (area) resolution.
 *
 * A street address resolves to a POINT, and a point falls on exactly one side of
 * every district line. A ZIP resolves to an AREA, and an area straddles lines.
 * That difference is the whole feature: the honest answer to "who serves 46220"
 * is four state house members, not one.
 *
 * Side-effect-free by design (same reasoning as districtQueries.ts): the DB-touching
 * orchestration lives in essentialsService.ts, so everything here is unit-testable.
 */

import { buildDistrictQuery } from './districtQueries.js';

/** 5-digit or ZIP+4. */
const ZIP_SHAPE = /^(\d{5})(?:-\d{4})?$/;

/**
 * normalizeZip — a 5-digit ZIP, or null when the input is not ZIP-shaped.
 * ZCTAs are 5-digit, and normalizing keeps cache keys single-valued so
 * '46220' and '46220-1234' cannot occupy two entries.
 */
export function normalizeZip(raw: string | null | undefined): string | null {
  const m = ZIP_SHAPE.exec((raw ?? '').trim());
  return m ? m[1] : null;
}

/**
 * The ZIP polygon and its area, resolved once. $1 = normalized 5-digit ZIP.
 *
 * PERFORMANCE: Postgres evaluates this as an InitPlan, so downstream references
 * to `(SELECT g FROM zcta)` are constants and `gb.geometry && (SELECT g FROM zcta)`
 * becomes an INDEX CONDITION. Verified 2026-08-18 against the Indiana ZCTAs:
 * Index Scan using idx_geofence_boundaries_geometry, 43ms for 46220.
 */
export const ZCTA_CTE = `WITH zcta AS (
    SELECT geometry AS g, public.ST_Area(geometry) AS a
    FROM essentials.geofence_boundaries
    WHERE mtfcc = 'G6350' AND geo_id = $1
  )`;

/**
 * Genuine interior overlap with the ZIP polygon.
 *
 * ONE spatial predicate with an explicit && bounding-box prefilter — never an OR
 * of mixed-direction predicates, which cannot drive the GIST index and produced a
 * measured 4,286ms Parallel Seq Scan in the 2026-07-01 browse-stall regression.
 *
 * ST_Touches is excluded so a district that merely shares a border with the ZIP
 * does not count as serving it.
 *
 * Other ZCTAs are filtered out explicitly: roughly 30 neighbouring ZIP polygons
 * intersect any given one. The geoIdGuard exclusion already stops them producing
 * rows, but without this we would still pay to intersect them.
 *
 * G4000 (state outlines) is excluded HERE rather than in FALLBACK_EXCLUDED_MTFCCS,
 * and the difference matters. Statewide seats are resolved separately, by
 * district_type + state, with a >=1% share floor for a second state. Letting the
 * state outline through this predicate smuggles a neighbouring state's whole
 * delegation past that floor: ZIP 46360 (Michigan City) clips Michigan by 0.013%
 * of its area and returned Nessel, Benson, Gilchrist and Peters for an Indiana
 * ZIP — with a bogus 0.013% share attached, because they arrived through the
 * DISTRICT query rather than the statewide one.
 *
 * It is scoped to this predicate because excluding it globally breaks
 * check-address-reachability.mjs, which treats a statewide seat's G4000 polygon as
 * its only proof of reachability. See the long note in geoIdGuard.ts for what is
 * owed there.
 */
export const ZIP_AREA_SPATIAL_PREDICATE = `gb.mtfcc <> 'G6350'
    AND gb.mtfcc <> 'G4000'
    AND gb.geometry OPERATOR(public.&&) (SELECT g FROM zcta)
    AND public.ST_Intersects(gb.geometry, (SELECT g FROM zcta))
    AND NOT public.ST_Touches(gb.geometry, (SELECT g FROM zcta))`;

/**
 * Fraction of the ZIP's area that a district covers.
 *
 * Planar area in EPSG:4326 is correct here BECAUSE IT IS A RATIO: numerator and
 * denominator suffer the same degree-to-metre distortion at the same latitude, so
 * it cancels. A geography cast would cost time and change nothing.
 */
export const ZIP_SHARE_EXPR = `public.ST_Area(public.ST_Intersection(gb.geometry, (SELECT g FROM zcta)))
                     / NULLIF((SELECT a FROM zcta), 0)`;

/**
 * Minimum share of a ZIP a state must cover before its statewide delegation is
 * included. Roughly 1% of ZIPs straddle a state line; without a floor, a
 * few-metre clip would add a second governor and two more senators.
 *
 * CHOSEN, not derived.
 */
export const MULTI_STATE_SHARE_FLOOR = 0.01;

/**
 * Every officeholder whose district overlaps the ZIP, each with its share.
 *
 * Built on buildDistrictQuery, so the column list, the MTFCC-to-district_type
 * mapping and the active/vacant rule are literally the same text the address path
 * uses. $1 = normalized 5-digit ZIP.
 *
 * NOTHING is filtered by share. A >=10% cutoff would drop Bloomington from 47401,
 * and someone living in that slice still has a real council member. Collapsing
 * slivers is the client's job.
 */
export function buildZipDistrictQuery(): string {
  return buildDistrictQuery({
    withPrefix: ZCTA_CTE,
    extraSelect: `, ${ZIP_SHARE_EXPR} AS share, gb.name AS geofence_name`,
    spatialPredicate: ZIP_AREA_SPATIAL_PREDICATE,
    orderByTail: ', share DESC NULLS LAST',
  });
}

/**
 * State FIPS codes for every state covering at least MULTI_STATE_SHARE_FLOOR of
 * the ZIP. G4000 is the state-outline layer and its geo_id IS the state FIPS.
 * Only ~53 polygons, so this is cheap. $1 = normalized 5-digit ZIP.
 *
 * The numeric-FIPS guard is load-bearing: the G4000 layer also holds a NATIONAL
 * outline row (geo_id 'US', name 'United States') which covers every ZIP and is
 * not a state. A FIPS->abbrev lookup happens to miss it, but excluding it here
 * means correctness does not depend on a map lookup failing.
 */
export function buildZipStatesQuery(): string {
  return `${ZCTA_CTE}
    SELECT gb.geo_id AS fips
    FROM essentials.geofence_boundaries gb
    WHERE gb.mtfcc = 'G4000'
      AND gb.geo_id ~ '^[0-9]{2}$'
      AND gb.geometry OPERATOR(public.&&) (SELECT g FROM zcta)
      AND public.ST_Intersects(gb.geometry, (SELECT g FROM zcta))
      AND ${ZIP_SHARE_EXPR} >= ${MULTI_STATE_SHARE_FLOOR}
    ORDER BY 1`;
}

/**
 * The county covering the largest part of the ZIP. Counties are loaded
 * nationwide, so this is always a safe label. $1 = normalized 5-digit ZIP.
 */
export function buildZipCountyQuery(): string {
  return `${ZCTA_CTE}
    SELECT gb.geo_id AS geoid, gb.name
    FROM essentials.geofence_boundaries gb
    WHERE gb.mtfcc = 'G4020'
      AND gb.geometry OPERATOR(public.&&) (SELECT g FROM zcta)
      AND public.ST_Intersects(gb.geometry, (SELECT g FROM zcta))
    ORDER BY public.ST_Area(public.ST_Intersection(gb.geometry, (SELECT g FROM zcta))) DESC
    LIMIT 1`;
}

/**
 * Does a ZCTA polygon exist for this ZIP at all? Lets the caller tell
 * "not a real ZIP" (404) apart from "real ZIP, no offices covered" (200 + []).
 * $1 = normalized 5-digit ZIP.
 */
export function buildZctaExistsQuery(): string {
  return `SELECT 1 FROM essentials.geofence_boundaries
    WHERE mtfcc = 'G6350' AND geo_id = $1 LIMIT 1`;
}

/**
 * Cache key prefix for ZIP lookups.
 *
 * VERSIONED DELIBERATELY. The removed candidateService.getCandidatesByZip wrote
 * `candidates:zip:${zip}` with a 900s TTL, holding every active
 * empowered_profiles row regardless of ZIP. Reusing the unversioned key would
 * serve that payload to this reader for up to 15 minutes after deploy.
 */
export const ZIP_CACHE_KEY_PREFIX = 'candidates:zip:v2:';

/** ZIP boundaries and officeholders both change on the order of months. */
export const ZIP_CACHE_TTL_SECONDS = 3600;

/**
 * rollUpAmbiguity — which offices this ZIP genuinely cannot pin down.
 *
 * COUNTS DISTINCT DISTRICTS, NOT PEOPLE, and that distinction is the whole
 * correctness of this function. Many bodies seat several members in ONE district:
 * ZIP 46220 returns 29 judges on one county court, 10 Marion County officials and
 * 7 school board members from a single school district. Counting people would
 * announce "29 judges serve parts of this ZIP code" when in truth all 29 serve
 * the ENTIRE ZIP and nothing is ambiguous. Verified against prod 2026-08-18:
 * every district_type for 46220 has exactly 1 distinct district.
 *
 * Real ambiguity is TWO DISTRICTS of the same type overlapping the ZIP — two
 * state house districts means the visitor is in one of them and we cannot tell
 * which. Sorted count-descending, then alphabetically for determinism.
 */
export function rollUpAmbiguity(
  rows: Array<{ district_type: string; geo_id: string }>,
): Array<{ district_type: string; count: number }> {
  const districtsByType = new Map<string, Set<string>>();
  for (const r of rows) {
    const dt = r.district_type;
    if (!dt) continue;
    // A row with no geo_id cannot be told apart from another such row, so it
    // counts once for its type rather than inflating the tally.
    const key = r.geo_id ?? '';
    const set = districtsByType.get(dt) ?? new Set<string>();
    set.add(key);
    districtsByType.set(dt, set);
  }
  return [...districtsByType.entries()]
    .map(([district_type, set]) => ({ district_type, count: set.size }))
    .filter(({ count }) => count > 1)
    .sort((a, b) => b.count - a.count || a.district_type.localeCompare(b.district_type));
}
