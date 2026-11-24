/**
 * Shared MTFCC → district_type guard for essentials.districts lookups.
 *
 * TIGER 5-digit GEOIDs are reused across layers, so a `geo_id` is ambiguous:
 * "49021" is simultaneously State Senate District 21 (state 49 + SLDU 021),
 * State House District 21 (SLDL 021), AND Iron County (county 021). Matching
 * essentials.districts on geo_id alone therefore leaks unrelated counties and
 * cross-chamber districts (the "Alpine community shows Iron County" bug).
 *
 * Pair each candidate geo_id with the MTFCC of the geofence/slot it came from
 * and require district_type to match that MTFCC. This SQL fragment expects the
 * (geo_id, mtfcc) pair source aliased `gp` and essentials.districts aliased `d`.
 * Mirrors the inline guard in getRepresentativesByAddress (essentialsService.ts).
 */
/**
 * MTFCCs that must NOT reach the district-join catch-all clause.
 *
 * The catch-all (`mtfcc NOT IN (...) AND mtfcc NOT LIKE 'X%'`) means "match any
 * district_type for this geo_id", so any layer NOT listed here joins to a
 * district purely on a bare geo_id string match.
 *
 * G5200V26: 2026-vintage congressional boundaries — only the elections opt-in
 *   join (electionService.ts) may resolve against it.
 * G6350: ZIP Code Tabulation Areas. A ZCTA has no districts of its own, and its
 *   geo_id is a bare 5-digit ZIP ('46220') that can collide with district
 *   geo_ids. ZIPs resolve by AREA OVERLAP (resolveOfficialsInArea), never by
 *   geo_id — so admitting them here would attach arbitrary officials to a ZIP
 *   AND, because this clause is shared, to any address lookup as well.
 * G4000: state outlines. A statewide seat (Governor, Senator, state supreme
 *   court) has no polygon of its own and is resolved by district_type + state in
 *   buildStatewideQuery. Because G4000 ALSO reached those districts through this
 *   catch-all, and the two result sets are concatenated without dedup, every
 *   address lookup returned statewide officials TWICE: measured 2026-08-18
 *   against prod, one Bloomington address returned 139 politicians with 28
 *   DUPLICATED — both Indiana senators and four supreme court justices among
 *   them. Now 111 with 0 duplicates.
 *
 *   ⚠ EXCLUDING THIS BREAKS check-address-reachability.mjs UNLESS THAT SCRIPT
 *   MODELS THE STATEWIDE PATH. It defines reachability purely through this guard,
 *   and 13 occupied state-level court districts (12 IN + 1 WI JUDICIAL, geo_id =
 *   2-char state FIPS) satisfy it ONLY via their G4000 outline. A first attempt
 *   on 2026-08-19 excluded G4000 without touching the script and turned master
 *   CI red on the zero-tolerance ST_COVERS_ROUNDTRIP check; it was reverted the
 *   same day and re-landed here together with STATEWIDE_RESOLVED in that script.
 *   Keep the two in step.
 *
 * SINGLE SOURCE OF TRUTH — districtQueries.ts interpolates
 * FALLBACK_EXCLUDED_MTFCC_SQL_LIST rather than restating the list. Guarded by
 * geoIdGuard.test.ts.
 */
export const FALLBACK_EXCLUDED_MTFCCS: readonly string[] = [
  'G5210', 'G5220', 'G5200', 'G4020', 'G4040', 'G4110', 'G4120',
  'G5400', 'G5410', 'G5420', 'G5200V26', 'G6350', 'G4000',
];

/** The same list rendered for a SQL `IN (...)` clause. */
export const FALLBACK_EXCLUDED_MTFCC_SQL_LIST: string =
  FALLBACK_EXCLUDED_MTFCCS.map((m) => `'${m}'`).join(',');

/**
 * MTFCCs whose (geo_id, mtfcc) PAIR can never match a district under
 * MTFCC_DISTRICT_TYPE_GUARD — no clause names them AND no catch-all admits them.
 * Resolving them is work whose every row is discarded downstream.
 *
 * 🔴 THIS LIST IS DERIVED FROM THE GUARD BELOW, NOT CHOSEN. It is exactly the
 * members of FALLBACK_EXCLUDED_MTFCCS that have no explicit clause of their own,
 * plus X0004, which the `X%` catch-all excludes by name and no clause restores.
 * `geoIdGuard.test.ts` recomputes it from the guard text and fails if the two
 * drift — because a type added to the guard and left in this list would become a
 * SILENT correctness bug (the pairs would stop being produced and the districts
 * would quietly disappear), not a slow page.
 *
 * ── WHY IT EXISTS: measured against prod 2026-11-24 ────────────────────────────
 * resolveOverlappingGeoPairs' branch 1 had no type filter at all, while branches
 * 2 and 3 do, so it detoasted and point-tested every polygon whose bounding box
 * met the seed — ~5,000 for a state seed. Reported from Civic Spaces as the
 * slowest call in a member's app boot (7,199 ms on a real browser). Per-branch
 * EXPLAIN (ANALYZE, BUFFERS), state seeds:
 *
 *                       California        Texas
 *   branch 1 cold        2,595 ms       3,433 ms     ← no filter; 17,001 / 19,969 reads
 *   branch 2                10 ms             —
 *   branch 3 cold        2,930 ms       1,001 ms     ← ST_Intersection, already type-filtered
 *
 * ⚠ The original report named branch 3 alone. It IS expensive, but branch 1 costs
 * as much in California and MORE THAN THREE TIMES as much in Texas — so a fix
 * aimed only at branch 3 would have left most of the Texas cost in place.
 *
 * With this filter, measured at EQUAL cache warmth (the first trimmed-vs-cold
 * comparison read 33× and was wrong — it was the measurer's own warm buffer
 * cache; re-running both warm is what separated the two effects):
 *
 *   branch 1 warm, untrimmed   CA 1,065 ms   TX 255 ms
 *   branch 1 warm, trimmed     CA   126 ms   TX  88 ms
 *
 * Pairs carried downstream fall from 4,606 to 2,751 for California — exactly the
 * 1,803 G6350 + 52 G5200V26 the per-type breakdown predicted — and 3,746 to 1,727
 * for Texas.
 *
 * 🟢 CORRECTNESS GATE, RUN BEFORE SHIPPING: the set of essentials.districts rows
 * surviving MTFCC_DISTRICT_TYPE_GUARD is IDENTICAL with and without the filter —
 * 1,606 for California, 540 for Texas — with the guard extracted verbatim from
 * this file rather than retyped.
 * 🔴 AND THE POSITIVE CONTROL TOOK THREE ATTEMPTS, WHICH IS THE PART WORTH
 * KEEPING. Dropping G4020 lost nothing because BRANCH 3 BACKFILLS IT; dropping
 * G4040 lost nothing because county subdivisions match no California district at
 * all. Only dropping G4110 went red — losing exactly the 215 districts the
 * per-type breakdown predicted, which is what proves the comparison reads the
 * right rows rather than merely being able to fail. ▶ A control aimed at a type
 * another branch also supplies tests nothing.
 *
 * ⚠ NOT A CACHE-KEY CHANGE. The result is provably identical, so `overlap:v2`
 * keys stay valid and are NOT versioned up — bumping would invalidate every warm
 * key at deploy and stampede the very cold path this change exists to shrink.
 *
 * ⚠ G4040 is NOT in this list although it matched 0 California districts: that is
 * a fact about California's county subdivisions, not about the guard, and the
 * guard does admit G4040 as LOCAL/LOCAL_EXEC elsewhere. Only types dead BY
 * CONSTRUCTION belong here.
 */
export const UNRESOLVABLE_PAIR_MTFCCS: readonly string[] = [
  'G6350',     // ZCTAs — no districts of their own; resolve by area overlap, never by geo_id
  'G4000',     // state outlines — statewide seats come from buildStatewideQuery + stateAbbrev
  'G5200V26',  // 2026 congressional vintage — the elections COORDINATE path resolves it from
               // d.geo_id (electionService.ts), never from an incoming pair
  'X0004',     // named in the X%-catch-all's exclusion list and restored by no clause
];

/** The same list rendered for a SQL `NOT IN (...)` clause. */
export const UNRESOLVABLE_PAIR_MTFCC_SQL_LIST: string =
  UNRESOLVABLE_PAIR_MTFCCS.map((m) => `'${m}'`).join(',');

export const MTFCC_DISTRICT_TYPE_GUARD = `(
    (gp.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')
    OR (gp.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER')
    -- DC ONLY: TIGER files DC's 8 wards as the SLDL layer (G5220, geo_id 11001..11008) because the
    -- DC Council IS DC's legislature. Its ward seats are typed CITY_COUNCIL, and the SBOE's ward
    -- seats STATE_BOARD_EDUCATION (migration 1852 reclassified DC's board from SCHOOL_BOARD), so
    -- without this clause all 16 stay unreachable by address (migrations 1485, 1852).
    -- SCOPED TO DC deliberately: unscoped, any state's state-house geofence could match a
    -- same-geo_id council district and surface the wrong officials. G5220 geo_ids are
    -- state-FIPS-prefixed, so 1100N belongs to DC alone.
    OR (gp.mtfcc = 'G5220' AND lower(d.state) = 'dc' AND d.district_type IN ('CITY_COUNCIL','STATE_BOARD_EDUCATION'))
    OR (gp.mtfcc = 'G5200' AND d.district_type = 'NATIONAL_LOWER')
    OR (gp.mtfcc = 'G4020' AND d.district_type IN ('COUNTY','JUDICIAL'))
    -- PR ONLY: a municipio IS both the county-equivalent and the municipality. TIGER files all 78
    -- in the county layer (G4020), but civically they are municipalities whose executive is an
    -- alcalde, so they are typed LOCAL_EXEC like every other mayor rather than COUNTY — otherwise
    -- every "find the mayors" query silently misses all 78 (migration 1728).
    -- SCOPED TO PR deliberately, same argument as DC above: G4020 geo_ids are state-FIPS-prefixed,
    -- so 72xxx belongs to Puerto Rico alone. Unscoped, a mainland county geofence could match a
    -- same-geo_id LOCAL_EXEC seat and surface the wrong official.
    OR (gp.mtfcc = 'G4020' AND lower(d.state) = 'pr' AND d.district_type = 'LOCAL_EXEC')
    OR (gp.mtfcc = 'G4040' AND d.district_type IN ('LOCAL','LOCAL_EXEC'))
    OR (gp.mtfcc IN ('G4110','G4120') AND d.district_type IN ('LOCAL','LOCAL_EXEC'))
    OR (gp.mtfcc IN ('G5400','G5410','G5420') AND d.district_type = 'SCHOOL')
    OR (gp.mtfcc = 'X0001' AND d.district_type IN ('LOCAL','COUNTY'))
    OR (gp.mtfcc = 'X0002' AND d.district_type = 'SCHOOL')
    OR (gp.mtfcc = 'X0003' AND d.district_type = 'STATE_BOARD_EDUCATION')
    -- X0029: appellate districts whose geometry is a union of whole counties and so has no TIGER
    -- layer of its own — Indiana Court of Appeals Districts 1-3 (migration 1832) and California's
    -- Second Appellate District, geo_id '06-appellate-district-2' (migration CA_0189). EXPLICIT rather
    -- than left to the X catch-all below, which admits only LOCAL/COUNTY and would therefore leave
    -- every one of these seats unreachable by address.
    OR (gp.mtfcc = 'X0029' AND d.district_type = 'JUDICIAL')
    -- X-CA-SBOE: California's four Board of Equalization districts, loaded from the 2021 Citizens
    -- Redistricting Commission map (migration CA_0205). No TIGER layer, and BOE-1/BOE-4 split San
    -- Bernardino County, so not a union of counties either. EXPLICIT for the same reason as X0029:
    -- the X catch-all below admits only LOCAL/COUNTY, which would leave every BOE member unreachable.
    OR (gp.mtfcc = 'X-CA-SBOE' AND d.district_type = 'STATE_BOARD')
    -- X-ST-BOARD: elected state-level boards that are NOT boards of education and whose
    -- districts have no TIGER layer of their own — the University of Colorado Board of Regents,
    -- whose eight districts ARE the congressional districts and are loaded as copies of the
    -- G5200 polygons (CC_0366). EXPLICIT for the same reason as X-CA-SBOE, and kept in step with
    -- GEOFENCE_DISTRICT_JOIN in districtQueries.ts.
    OR (gp.mtfcc = 'X-ST-BOARD' AND d.district_type = 'STATE_BOARD')
    OR (gp.mtfcc LIKE 'X%' AND gp.mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND d.district_type IN ('LOCAL','COUNTY'))
    -- G5200V26 (2026-vintage congressional boundaries) is intentionally excluded from this
    -- catch-all: only the elections opt-in join (electionService.ts) may resolve against it.
    OR (gp.mtfcc NOT IN (${FALLBACK_EXCLUDED_MTFCC_SQL_LIST}) AND gp.mtfcc NOT LIKE 'X%')
  )`;

/** A geo_id paired with the MTFCC of the layer it was sourced from. */
export interface GeoPair {
  geo_id: string;
  mtfcc: string;
}
