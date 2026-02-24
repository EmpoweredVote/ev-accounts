# Phase 35: LA County ArcGIS Geofences — Supervisor Districts and City Council Wards - Context

**Gathered:** 2026-02-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Import LA County supervisor district boundaries (G4020), LA City council ward boundaries (X0001), and city council ward boundaries for other LA County incorporated cities from authoritative ArcGIS sources. Phase 34 already provides TIGER boundaries (federal, state, school, city). This phase fills the non-TIGER local governance boundaries.

</domain>

<decisions>
## Implementation Decisions

### City Coverage Scope
- Import boundaries for ALL cities that publish ArcGIS data — not limited to top cities by population
- Import and flag low-quality data (broken geometries, potentially outdated) with a quality flag for later review — don't skip questionable data
- Use a curated list of ArcGIS source URLs (not automated discovery) — research builds the list, script consumes it
- Cities with district elections but no published ArcGIS boundaries are noted as gaps and skipped — no manual georeferencing this phase

### geo_id Convention
- Supervisor districts (G4020): Use TIGER GEOID format, consistent with Phase 34 convention
- LA City council wards (X0001): Use OCD-ID format (e.g., `ocd-division/country:us/state:ca/place:los_angeles/council_district:1`)
- All other city council wards: Also OCD-ID format (e.g., `ocd-division/country:us/state:ca/place:long_beach/council_district:1`)
- Convention split: TIGER GEOID for boundaries that exist in TIGER, OCD-ID for boundaries that don't

### Source Priority & Fallbacks
- Supervisor districts: LA County official ArcGIS portal is the primary source; TIGER G4020 as fallback only if ArcGIS is unavailable
- City council wards: Check each city's official GIS/open data portal first — most CA cities with district elections publish ward boundaries
- Source URLs stored in a config file (JSON/CSV) mapping city to ArcGIS URL to layer name — not hardcoded in scripts
- Error handling: Retry 2-3 times with backoff on ArcGIS endpoint failures, then log and skip; report all failures at end of run

### At-Large vs District Elections
- At-large cities: Reuse the existing G4110 place boundary from Phase 34 as the council "district" — no duplicate geometry
- Election type (district/at-large/hybrid) tracked in the curated config file — explicit classification, not auto-detected
- Hybrid cities (some district seats, some at-large): Import ward boundaries for district seats; at-large seats map to the city-wide G4110 boundary; note hybrid status in config

### Claude's Discretion
- Exact config file format (JSON vs CSV) and schema
- Geometry validation and repair approach (ST_MakeValid details)
- Script architecture (single script vs per-source-type scripts)
- Quality flag implementation (column vs separate table)

</decisions>

<specifics>
## Specific Ideas

- Follow the existing import script pattern from Phase 34 (`import_ca_place_boundaries.py`) for consistency
- The curated source config should be human-reviewable — someone should be able to audit which cities are covered and which are gaps
- OCD-ID format for council wards aligns with the Open Civic Data standard used by civic data organizations

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 35-la-county-arcgis-geofences-supervisor-districts-and-city-council-wards*
*Context gathered: 2026-02-24*
