# Phase 53: Search Accuracy & Bug Fix - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Essentials search returns all relevant representatives for area-level queries (cities, ZIP codes, and other non-address queries) by using geofence boundary intersection instead of point-in-polygon. Fix the results-page re-search bug so it works correctly on first attempt. Street address (point-in-polygon) searches must continue working exactly as they do now.

</domain>

<decisions>
## Implementation Decisions

### Area vs. Point Detection
- Use Google Geocoding API result types to auto-detect area vs point queries
- Result types like "locality" (city), "postal_code" (ZIP), "administrative_area_level_2" (county) trigger area search
- Result type "street_address" or "premise" keeps current point-in-polygon (ST_Covers) behavior
- Anything that isn't a specific street address gets area treatment — cities, ZIPs, counties, neighborhoods, etc.

### Result Scope for Area Queries
- Return ALL representatives whose districts overlap the queried area boundary
- No cap or filtering — user sees the full picture even if 20+ results for a large city
- Show an area label in the UI (e.g., "Representatives for Los Angeles, CA") so users understand why there are many results
- Claude handles federal/state supplementation dedup — no duplicate politicians in results

### ZIP Code Area Behavior
- Switch ZIP queries to geofence boundary intersection (same approach as city queries)
- ZIPs already have TIGER boundaries in geofence_boundaries table — use ST_Intersects
- Retire the old zip_politicians warming/caching flow entirely — single code path via geofence intersection
- Remove frontend warming/retry logic (202 + Retry-After polling) — geofence queries are synchronous from PostGIS
- This is a significant simplification: one search path for all query types

### Results Page Re-search Bug
- Re-searching from the results page must feel seamless and identical to searching from the landing page
- Old results clear immediately, new results load with loading state
- Must work correctly on first attempt — no page refresh or double-entry required
- Keep the autocomplete requirement — user must select a suggestion from Google Places to ensure valid, geocodable input

### Claude's Discretion
- Technical approach for geofence intersection queries (ST_Intersects vs ST_Overlaps, query optimization)
- How to handle edge cases where geofence boundary data is missing for a queried area
- Frontend state management fix for the re-search bug (likely sessionStorage/cache invalidation issue)
- Deduplication strategy for federal/state supplemental officials
- How to handle the transition from warming/polling to synchronous responses in the frontend hook

</decisions>

<specifics>
## Specific Ideas

- Success criteria explicitly require: point-in-polygon searches (street addresses) must NOT be affected by the area detection change
- The `is_contained` field on zip_politicians can be retired along with the old flow
- Google Places autocomplete on the frontend already distinguishes place types — could inform detection if needed as a supplement to backend result types

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FindGeoIDsByPoint()` in `geofence_lookup.go`: existing point-in-polygon query — keep for address searches
- `FindPoliticiansByGeoMatches()` in `geofence_lookup.go`: existing politician lookup by geo matches with MTFCC disambiguation — reusable for area results
- `geofence_boundaries` table: already has TIGER boundaries for cities (G4110, G4120), ZIPs, counties (G4020), school districts, congressional districts, state legislative districts
- `mtfccToDistrictTypes` map: existing MTFCC-to-district-type mapping for disambiguation
- Google geocoding client (`geocoding/google.go`): returns `Result` with Lat, Lng, State, City, County, Zip, Formatted — needs to also return result type info

### Established Patterns
- `SearchPoliticians` handler: geocodes → geofence lookup → politician lookup → supplement federal/state → respond
- `fetchStatewideFromDB()` and `fetchFederalAndStateFromDB()`: existing supplemental fetchers for federal/state officials
- Frontend `usePoliticianData` hook: routes ZIP vs address queries differently — will need simplification
- `searchPoliticians()` in `api.jsx`: POST to `/essentials/politicians/search` — single entry point for all non-ZIP queries

### Integration Points
- `SearchPoliticians` handler needs new area-intersection code path alongside existing point-in-polygon
- `usePoliticianData` hook needs warming/retry logic removed, simplified to single synchronous flow
- `Results.jsx` needs state management fix for re-search bug + area label display
- Google geocoding `Result` struct needs to expose result type for area detection
- Routes: ZIP endpoint may redirect to search endpoint or be unified

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 53-search-accuracy-bug-fix*
*Context gathered: 2026-02-28*
