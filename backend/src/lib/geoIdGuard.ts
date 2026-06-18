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
    OR (gp.mtfcc = 'G5200' AND d.district_type = 'NATIONAL_LOWER')
    OR (gp.mtfcc = 'G4020' AND d.district_type IN ('COUNTY','JUDICIAL'))
    OR (gp.mtfcc = 'G4040' AND d.district_type IN ('LOCAL','LOCAL_EXEC'))
    OR (gp.mtfcc IN ('G4110','G4120') AND d.district_type IN ('LOCAL','LOCAL_EXEC'))
    OR (gp.mtfcc IN ('G5400','G5410','G5420') AND d.district_type = 'SCHOOL')
    OR (gp.mtfcc = 'X0001' AND d.district_type IN ('LOCAL','COUNTY'))
    OR (gp.mtfcc = 'X0002' AND d.district_type = 'SCHOOL')
    OR (gp.mtfcc = 'X0003' AND d.district_type = 'STATE_BOARD')
    OR (gp.mtfcc LIKE 'X%' AND gp.mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND d.district_type IN ('LOCAL','COUNTY'))
    OR (gp.mtfcc NOT IN ('G5210','G5220','G5200','G4020','G4040','G4110','G4120','G5400','G5410','G5420') AND gp.mtfcc NOT LIKE 'X%')
  )`;

/** A geo_id paired with the MTFCC of the layer it was sourced from. */
export interface GeoPair {
  geo_id: string;
  mtfcc: string;
}
