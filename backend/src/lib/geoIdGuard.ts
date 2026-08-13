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
export const MTFCC_DISTRICT_TYPE_GUARD = `(
    (gp.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')
    OR (gp.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER')
    -- DC ONLY: TIGER files DC's 8 wards as the SLDL layer (G5220, geo_id 11001..11008) because the
    -- DC Council IS DC's legislature. Its ward seats are typed CITY_COUNCIL, and the SBOE's ward
    -- seats SCHOOL_BOARD, so without this clause all 16 stay unreachable by address (migration 1485).
    -- SCOPED TO DC deliberately: unscoped, any state's state-house geofence could match a
    -- same-geo_id council district and surface the wrong officials. G5220 geo_ids are
    -- state-FIPS-prefixed, so 1100N belongs to DC alone.
    OR (gp.mtfcc = 'G5220' AND lower(d.state) = 'dc' AND d.district_type IN ('CITY_COUNCIL','SCHOOL_BOARD'))
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
    OR (gp.mtfcc = 'X0003' AND d.district_type = 'STATE_BOARD')
    OR (gp.mtfcc LIKE 'X%' AND gp.mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND d.district_type IN ('LOCAL','COUNTY'))
    -- G5200V26 (2026-vintage congressional boundaries) is intentionally excluded from this
    -- catch-all: only the elections opt-in join (electionService.ts) may resolve against it.
    OR (gp.mtfcc NOT IN ('G5210','G5220','G5200','G4020','G4040','G4110','G4120','G5400','G5410','G5420','G5200V26') AND gp.mtfcc NOT LIKE 'X%')
  )`;

/** A geo_id paired with the MTFCC of the layer it was sourced from. */
export interface GeoPair {
  geo_id: string;
  mtfcc: string;
}
