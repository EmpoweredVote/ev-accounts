# Feature Research — v1.6 LA County Full Coverage & Repeatable Import Pipeline

**Domain:** Civic engagement — geofence boundary import, politician data pipeline, regional expansion
**Researched:** 2026-02-23
**Confidence:** HIGH (existing codebase directly inspected; TIGER/Census docs verified; LA County GIS Portal confirmed; MTFCC mapping already implemented in geofence_lookup.go)

---

## Scope Note

This file covers only the NEW features for v1.6. The existing infrastructure — PostGIS point-in-polygon queries, MTFCC-to-district-type mapping, `essentials.geofence_boundaries` table, `essentials.districts` geo_id column, and the Bloomington city council import (X0001 MTFCC) — is already built and working. Research here addresses: what TIGER boundary types are needed for LA County full coverage, what LA County GIS Portal provides beyond TIGER, how politician records gap-fill should work, and what a repeatable pipeline requires.

---

## Boundary Type Inventory: LA County

Understanding what to import requires knowing what boundary types exist and which political bodies they represent. The existing MTFCC mapping in `geofence_lookup.go` defines the full translation table — import work must populate geometry for each of these codes.

### TIGER/Line Shapefiles (U.S. Census Bureau)

All available from `https://www2.census.gov/geo/tiger/TIGER2025/` — free, public domain, annual vintage.

| TIGER Layer | MTFCC Code | District Type (existing mapping) | What it covers in LA County | Already imported? |
|-------------|-----------|----------------------------------|------------------------------|-------------------|
| Congressional Districts (119th) | G5200 | `NATIONAL_LOWER` | ~14 congressional districts overlap LA County | No |
| State Legislative Upper (CA Senate) | G5210 | `STATE_UPPER` | ~11 CA Senate districts | No |
| State Legislative Lower (CA Assembly) | G5220 | `STATE_LOWER` | ~24 CA Assembly districts | No |
| Unified School Districts | G5420 | `SCHOOL` | 80+ unified school districts | No |
| County boundaries | G4020 | `COUNTY` / `JUDICIAL` | LA County itself (one polygon) | No |
| Places (incorporated cities) | G4110 | `LOCAL` / `LOCAL_EXEC` | 88 incorporated cities | No |

Note: TIGER does NOT include county supervisor districts or community service area (CSA) boundaries — those come from LA County GIS Portal.

### LA County GIS Portal (egis-lacounty.hub.arcgis.com)

Free ArcGIS Hub with REST API endpoints and direct Shapefile/GeoJSON download. No TIGER equivalent for these layers.

| Layer | MTFCC to Use | District Type | What it covers | Available format |
|-------|-------------|---------------|----------------|-----------------|
| Supervisorial Districts (Current, 2021 redistricting) | G4020 (county-level admin) | `COUNTY` / `LOCAL_EXEC` | 5 supervisor districts covering all of LA County | Shapefile, GeoJSON, ArcGIS REST |
| School District Boundaries (LA County EGIS) | G5420 | `SCHOOL` | All school districts in the county, maintained by Registrar-Recorder | Shapefile, GeoJSON |
| City Boundaries (legal) | G4110 | `LOCAL` | 88 incorporated cities + unincorporated boundaries | Shapefile, GeoJSON |
| Countywide Statistical Areas (CSAs) | X0001 or G4110 | `LOCAL` | ~140 unincorporated named communities | Shapefile, GeoJSON |

Note: The LA County GIS supervisor district data uses 2021 post-redistricting boundaries, which are the current official boundaries until 2031. These are NOT in TIGER with this level of precision.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features that LA County users assume exist. Missing these = address search returns visibly incomplete results — federal-only or nothing.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Congressional district boundary import | Any civic address lookup for LA County users must return their U.S. Representative. CA has 14 districts that overlap LA County (CDs 25, 27-34, 36-38, 40, 42, 43 in the 119th Congress). Without geofences for these, the backend cannot match. | LOW | Download `tl_2025_us_cd119.zip` from TIGER FTP. Filter by STATEFP=06 (California). Run `ogr2ogr` into `essentials.geofence_boundaries` with MTFCC=G5200. GEOIDs are district-level and match the `geo_id` column in `essentials.districts`. |
| CA State Senate district boundary import | Users expect their state senator. 11 CA Senate districts overlap LA County. | LOW | Download `tl_2025_06_sldu.zip` (California SLDU). Same ogr2ogr pattern with MTFCC=G5210. |
| CA State Assembly district boundary import | Users expect their Assembly member. 24 CA Assembly districts touch LA County. | LOW | Download `tl_2025_06_sldl.zip` (California SLDL). MTFCC=G5220. |
| School district boundary import | School board elections are the most numerous local elections. Users with children especially expect to see their school board. LA County has 80+ school districts. | MEDIUM | LA County GIS Portal has a single school district layer maintained by the Registrar-Recorder with all district types combined. Alternatively use TIGER `tl_2025_06_unsd.zip` for unified districts. The LA County portal layer is preferred as it includes elementary and secondary splits maintained locally. |
| City boundary import (incorporated places) | LA County's 88 cities each have their own city council. For residents of any incorporated city, city council is a core local representative. | MEDIUM | TIGER PLACE layer (`tl_2025_06_place.zip`) covers incorporated places. Filter by COUNTYFP=037 (LA County) or use TIGER's place-county relationship file. MTFCC=G4110 already maps to LOCAL district type. City names must match politician records for the geo_id linkage to work. |
| Supervisor district boundary import | LA County Board of Supervisors (5 members) governs unincorporated areas and county services. For the ~1M unincorporated residents of LA County, supervisors are their primary local representatives. | LOW | Download from LA County GIS Portal: `Supervisorial Districts (Current)` layer — not available from TIGER at sufficient accuracy. GeoJSON or Shapefile format, ArcGIS REST endpoint confirmed. |
| Politician records for LA County offices | Geofences without matching politician records return zero results. For any new district type (school board, city council, supervisors), politician records must exist in `essentials.politicians` and `essentials.districts` with matching `geo_id` values. | HIGH | This is the largest work item. Politician records for state/federal offices may already exist from BallotReady import (check `essentials.politicians` where `source='ballotready'` and `representing_state='CA'`). Local politicians (city council, school board, supervisors) likely do NOT exist — they must be created manually or sourced from an alternative. |

### Differentiators (Competitive Advantage)

Features that make the LA County expansion trustworthy and reusable — not just a one-off import.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Repeatable import script (shell/bash + ogr2ogr) | Running a single script that downloads, validates, and loads a TIGER layer into PostGIS means future regional expansions (e.g., Cook County IL, Harris County TX) follow the same pattern without reinventing. | MEDIUM | Pattern: download ZIP from TIGER FTP → unzip → run ST_MakeValid → insert into geofence_boundaries with correct MTFCC, Source="census_tiger_2025", state filter. Parameterized by state FIPS and layer type. A shell script with documented parameters is sufficient — Go CLI is optional. |
| GEOID → geo_id linkage validation step | TIGER GEOIDs must match the `geo_id` values stored in `essentials.districts` for the geofence lookup to return politicians. A validation query (SELECT districts with no matching geofence_boundary, and geofence_boundaries with no matching district) catches mismatches before deploys. | LOW | Add a SQL diagnostic query to the import tooling. Run after every import to surface unmatched boundaries. |
| Source + vintage metadata on every imported boundary | Tagging each row with `source="census_tiger_2025"` and `valid_from`/`valid_to` dates allows future updates to replace boundaries by vintage without manual cleanup. The existing `GeofenceBoundary` model already has these columns — they just need to be populated. | LOW | Already modeled. Only enforcement needed: import script always sets source and valid_from. |
| Idempotent import (upsert, not re-import) | Re-running the import script after a TIGER update should update changed boundaries, not create duplicates. | LOW | `geo_id` + `mtfcc` can serve as a composite unique key (note: `GeofenceBoundary` has a comment "unique constraint managed manually"). Add a PostgreSQL `ON CONFLICT (geo_id, mtfcc) DO UPDATE` clause to the import. Requires confirming the unique constraint exists or adding it. |
| Politician deduplication by external_id (BallotReady) | For state and federal politicians already in the DB from BallotReady imports, new records must not be created. Match by `external_id` (BallotReady integer ID) as the primary key. geo_id linkage must update the existing `essentials.districts` row rather than creating a new politician. | MEDIUM | The `Politician` model already has `external_id` with a uniqueIndex. The gap is ensuring `essentials.districts.geo_id` is set correctly for CA districts so the geofence lookup hits them. Run a diagnostic: for CA politicians in DB, does their district have a `geo_id` that matches the TIGER GEOID? |
| Coverage dashboard / import log | A simple admin endpoint or SQL view showing which MTFCC types have geofence boundaries, how many, and when last imported, gives the team visibility into coverage gaps without a full GIS client. | LOW | Could be a SQL view on `essentials.geofence_boundaries GROUP BY mtfcc, source`. No UI required for v1.6 — a query in the README is sufficient. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Automated nightly TIGER sync | TIGER publishes new vintages annually (September). Automating annual re-imports sounds appealing. | TIGER vintages only matter after redistricting (every 10 years) or major changes. The 2025 vintage is valid until 2030 boundaries change. Automating annual re-imports creates operational complexity for no real benefit. Redistricting is a known event — handle it as a planned migration. | Manual import on redistricting events (2031 for current boundaries). Script is repeatable so the manual step is low-effort. |
| Real-time politician data sync for LA County local offices | Keeping city council and school board members up-to-date as officials change | This requires an API that has the data (BallotReady is removed; no other free API covers local officials). Manual data entry is slow. Automated sync requires a new data provider contract. | Initial import covers known officers. Data-entry tool (`/staging/*`) allows volunteers to submit and review changes. Accept staleness on local officials; federal/state data is more complete. |
| Using PostGIS TIGER geocoder (tiger schema) instead of custom geofence table | PostGIS ships with a TIGER geocoder extension that auto-loads data | The PostGIS TIGER geocoder is designed for address-level geocoding (house numbers, street segments). EV's use case is point-in-polygon (lat/lng → district). The TIGER geocoder adds a 500MB+ database footprint and schema complexity for a different problem. | Keep the existing `essentials.geofence_boundaries` table with ST_Contains queries. It's purpose-built for point-in-polygon. |
| Voting precinct (VTD) boundaries | VTDs are the most granular geographic unit in TIGER and are used for precinct-level election results | VTDs do not correspond to representative bodies. They are election administration units, not districts. Importing them would create false matches in the MTFCC mapping and flood search results with phantom "districts" that have no politicians. | Do not import VTD layer. If precinct-level election results become a feature, create a separate `election_precincts` table with no politician linkage. |
| Los Angeles City Council district boundaries (separate layer) | LA City has 15 council districts — very relevant for city residents | LA City council districts are X0001 MTFCC (BallotReady custom code, same as Bloomington). The LA County GIS Portal has an "LA City Council Districts (2021)" layer. However, without LA City council member records in `essentials.politicians`, importing the boundaries produces no results. Politicians must come first. | Import LA City council boundaries only after politician records for LA City council members are in the DB. This is a dependency, not an anti-feature. Flag as a phase sequencing requirement. |
| Full state of California TIGER import | "While we're at it, let's cover all of CA" | Full CA includes 58 counties with hundreds of incorporated places. Local politician data does not exist for most of them. Importing boundaries with no matching politician records wastes storage and creates confusing empty results. | Import only LA County-relevant boundaries (filter by county FIPS 037 or state FIPS 06 for state-level layers). Expand county by county as politician data is added. |

---

## Feature Dependencies

```
TIGER Congressional District Geofences (G5200)
    └──enables──> Geofence match for NATIONAL_LOWER officials
            └──requires──> Existing CA politicians in DB with district geo_id = TIGER GEOID
                    └──validation──> Diagnostic query: unmatched geofences ↔ districts

TIGER State Senate Geofences (G5210)
    └──enables──> Geofence match for STATE_UPPER officials
            └──same dependency──> CA state senator records in DB with matching geo_id

TIGER State Assembly Geofences (G5220)
    └──enables──> Geofence match for STATE_LOWER officials

LA County Supervisor District Geofences (G4020 from LA County GIS)
    └──enables──> Geofence match for COUNTY officials
            └──requires──> 5 supervisor politician records in DB with geo_id matching supervisor district GEOID
                    └──gap-fill required──> supervisor records likely NOT in DB from BallotReady

TIGER/LA County School District Geofences (G5420)
    └──enables──> Geofence match for SCHOOL officials
            └──requires──> School board member records with matching geo_id
                    └──gap-fill required──> school board records likely NOT in DB from BallotReady

TIGER City Boundaries (G4110)
    └──enables──> Geofence match for LOCAL officials (city council)
            └──requires──> City council member records with matching geo_id
                    └──conditional──> LA City council boundaries (X0001) need city council records
                    └──conditional──> Smaller city councils may not be in BallotReady data

Politician gap-fill (any source)
    └──requires first──> Boundary geofences imported (know which geo_ids need records)
    └──requires first──> Diagnostic query identifying which geo_ids have 0 politicians
    └──options for source──>
            BallotReady historical data (dead package exists as reference)
            Manual entry via /staging/* data-entry tool
            Scraped from official sources (city/county websites)

Repeatable import script
    └──enables──> Future regional expansion without per-region custom code
            └──parameterized by──> state FIPS, county FIPS, TIGER layer type, MTFCC
            └──outputs──> Idempotent upsert into essentials.geofence_boundaries

GEOID ↔ geo_id validation query
    └──blocks deployment of──> Any new boundary type until mismatches are resolved
    └──requires──> Both geofences AND districts tables populated
```

### Dependency Notes

- **Geofences before politicians (for new boundary types):** Import the boundary first to learn which `geo_id` values are needed. Then ensure politician records have districts with those `geo_id` values. This avoids creating districts with placeholder GEOIDs.
- **Federal/state politicians likely already exist:** The BallotReady import (pre-v1.5 removal) fetched CA federal and state officials. Check `essentials.politicians WHERE source='ballotready'` filtered for CA representatives. Their districts may already have `geo_id` values from BallotReady's OCD-ID data. If so, congressional/state boundary import just needs the geofence geometry — no new politician records needed.
- **Local politician gap-fill is the hard part:** City council members, school board members, and supervisors are NOT in the BallotReady import data (BallotReady focused on state/federal and candidates). These must come from a separate source — the staging data-entry tool is the only in-platform option without a new API provider.
- **LA City council districts depend on X0001 MTFCC:** The existing X0001 mapping (`LOCAL`) is correct for city council sub-districts. LA City council districts would use the same MTFCC as Bloomington city council. The boundary layer exists in LA County GIS Portal. Politician records are the blocker.
- **Supervisor districts conflict note:** G4020 maps to `["COUNTY", "JUDICIAL"]`. Supervisor districts ARE county-level administration so G4020 is the right MTFCC. However, the existing JUDICIAL mapping for G4020 is for county-level judicial courts (same geo_id). In LA County, county court judges would share the same geofence as supervisors. This is correct behavior — the district_type filter in `FindPoliticiansByGeoMatches` prevents cross-matching.

---

## MVP Definition

### Launch With (v1.6)

Minimum viable set to achieve full hierarchy coverage for LA County addresses.

- [ ] TIGER congressional district boundaries imported for LA County (G5200, ~14 districts) — enables NATIONAL_LOWER match
- [ ] TIGER CA Senate district boundaries imported (G5210, ~11 districts) — enables STATE_UPPER match
- [ ] TIGER CA Assembly district boundaries imported (G5220, ~24 districts) — enables STATE_LOWER match
- [ ] LA County Supervisorial District boundaries imported (5 districts, from LA County GIS Portal) — enables COUNTY match
- [ ] LA County school district boundaries imported (G5420, 80+ districts, from LA County EGIS or TIGER UNSD) — enables SCHOOL match
- [ ] TIGER incorporated places imported for LA County cities (G4110, 88 cities) — enables LOCAL match for city councils
- [ ] Diagnostic SQL: for each imported geofence, does a district + politician exist? Surface unmatched geo_ids as a report
- [ ] Politician gap-fill for LA County supervisors (5 records) — minimum needed to show county-level results
- [ ] Politician gap-fill for at least LA City council members (15 members) — LA City is the largest single city
- [ ] Repeatable import script documented with parameters for state FIPS, county FIPS, TIGER layer — usable for next region
- [ ] Idempotent upsert: `ON CONFLICT (geo_id, mtfcc) DO UPDATE` on geofence_boundaries

### Add After Validation (v1.6.x)

Features to add once core coverage is working and tested with real LA County addresses.

- [ ] Politician gap-fill for remaining 87 city councils (data entry tool for most, manual for largest) — full LOCAL coverage
- [ ] Politician gap-fill for LA County school board members (80+ school districts) — full SCHOOL coverage
- [ ] Coverage dashboard query showing MTFCC coverage with district + politician match rate
- [ ] LA City council district boundaries (X0001, 15 districts) imported once LA City council records exist
- [ ] "Showing results for Los Angeles, CA" building image — LA city hall photograph for LOCAL tier

### Future Consideration (v2+)

Features to defer: scope creep or requires non-existent data sources.

- [ ] Automated TIGER vintage refresh — handle as planned event on redistricting cycles, not automation
- [ ] Expansion to other CA counties (San Diego, Orange County) — same pipeline, new politician data needed
- [ ] Full national coverage — requires politician data for every county, not a boundary problem
- [ ] Voting precinct (VTD) boundaries — different use case, separate table if ever needed
- [ ] Real-time LA County official sync — requires new data provider contract

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Congressional district boundaries (G5200) | HIGH — every address shows U.S. Rep | LOW — single ogr2ogr command, filter CA | P1 |
| CA Senate boundaries (G5210) | HIGH — every address shows state senator | LOW — single ogr2ogr command | P1 |
| CA Assembly boundaries (G5220) | HIGH — every address shows Assembly member | LOW — single ogr2ogr command | P1 |
| LA County supervisor boundaries (GIS Portal) | HIGH — county residents expect supervisors | LOW — GeoJSON download, one insert | P1 |
| School district boundaries (G5420) | HIGH — school board elections are high-volume | MEDIUM — 80+ districts, GEOID matching | P1 |
| City boundaries (G4110) | HIGH — 88 cities with city councils | MEDIUM — TIGER PLACE layer, county filter | P1 |
| Politician gap-fill: 5 supervisors | HIGH — needed for supervisor districts to return results | LOW — 5 records, manual entry acceptable | P1 |
| Politician gap-fill: 15 LA City council | HIGH — largest city, most users | MEDIUM — 15 records + district geo_id linkage | P1 |
| GEOID ↔ geo_id diagnostic query | HIGH — prevents silent failures | LOW — SQL query, run after every import | P1 |
| Repeatable import script | MEDIUM — enables future regions | MEDIUM — parameterized bash + ogr2ogr | P1 |
| Idempotent upsert | MEDIUM — safe re-runs | LOW — single SQL change | P1 |
| Politician gap-fill: 87 remaining city councils | HIGH value when complete | HIGH — hundreds of records, data sourcing | P2 |
| School board member records (80+ districts) | HIGH value when complete | HIGH — hundreds of records, data sourcing | P2 |
| LA City council district boundaries (X0001) | MEDIUM — needed for ward-level precision | LOW — boundary only, blocked on politician records | P2 |
| Coverage dashboard SQL view | MEDIUM — ops visibility | LOW | P2 |
| LA City hall building photo | LOW — visual polish | LOW | P3 |

**Priority key:**
- P1: Must have for v1.6 launch — full federal/state/county/school coverage for any LA County address
- P2: Should have — completes local city council and school board coverage
- P3: Nice to have — visual polish and ops tooling

---

## TIGER Boundary Import: Technical Notes

### Layer Download URLs (2025 Vintage)

All from `https://www2.census.gov/geo/tiger/TIGER2025/`:

| Layer | Directory | File Pattern | Filter for LA County |
|-------|-----------|--------------|----------------------|
| Congressional Districts (119th) | `CD119/` | `tl_2025_us_cd119.zip` | STATEFP = '06' (California) |
| CA State Senate | `SLDU/` | `tl_2025_06_sldu.zip` | State-scoped, no county filter needed |
| CA State Assembly | `SLDL/` | `tl_2025_06_sldl.zip` | State-scoped, no county filter needed |
| Unified School Districts | `UNSD/` | `tl_2025_06_unsd.zip` | STATEFP='06'; spatial intersection with LA County |
| Places (incorporated cities) | `PLACE/` | `tl_2025_06_place.zip` | STATEFP='06'; COUNTYFP via relationship file or spatial filter |
| County | `COUNTY/` | `tl_2025_us_county.zip` | STATEFP='06', COUNTYFP='037' |

### GEOID Format by Layer Type

TIGER GEOIDs follow predictable patterns that must match `essentials.districts.geo_id`:

| Layer | GEOID Format | Example |
|-------|-------------|---------|
| Congressional Districts | `STATEFP(2) + CD number(2)` | `0633` = CA 33rd district |
| State Senate (SLDU) | `STATEFP(2) + district(3)` | `06025` = CA Senate district 25 |
| State Assembly (SLDL) | `STATEFP(2) + district(3)` | `06050` = CA Assembly district 50 |
| Places | `STATEFP(2) + PLACEFP(5)` | `0644000` = City of Los Angeles |
| Unified School Districts | `STATEFP(2) + UNSDLEA(5)` | `0610000` = specific district |
| County | `STATEFP(2) + COUNTYFP(3)` | `06037` = LA County |

Critical note: The `geo_id` values in `essentials.districts` come from BallotReady's `geo_id` field, which uses Census GEOIDs. They should match — but verify with the diagnostic query before assuming alignment.

### ogr2ogr Command Pattern

```bash
# Congressional Districts (G5200) — filter CA only
ogr2ogr -f PostgreSQL \
  PG:"host=HOST dbname=DB user=USER password=PASS" \
  tl_2025_us_cd119.shp \
  -nln essentials.geofence_boundaries_staging \
  -where "STATEFP = '06'" \
  -t_srs EPSG:4326 \
  -nlt PROMOTE_TO_MULTI \
  -sql "SELECT GEOID as geo_id, 'G5200' as mtfcc, NAMELSAD as name, STATEFP as state, 'census_tiger_2025' as source FROM tl_2025_us_cd119"
```

Then upsert from staging:
```sql
INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, name, state, source, geometry)
SELECT geo_id, mtfcc, name, state, source, ST_Multi(ST_MakeValid(wkb_geometry))
FROM essentials.geofence_boundaries_staging
ON CONFLICT (geo_id, mtfcc) DO UPDATE
  SET geometry = EXCLUDED.geometry,
      source = EXCLUDED.source,
      imported_at = now();
```

### LA County GIS Portal: ArcGIS REST Download

Supervisorial Districts available via ArcGIS feature service confirmed active:

- REST endpoint: `https://arcgis.gis.lacounty.gov/arcgis/rest/services/LACounty_Dynamic/Political_Boundaries/MapServer/27`
- Layer: "Supervisorial District (Current)" (ID: 27)
- Download formats: Shapefile, GeoJSON, CSV, KML via eGIS Hub
- Hub URL: `https://egis-lacounty.hub.arcgis.com/datasets/lacounty::supervisorial-districts-current/about`

School District Boundaries (LA County EGIS Hub):
- Layer: "School District Boundaries" (ID: 25 in Political_Boundaries service)
- Hub: `https://egis-lacounty.hub.arcgis.com/datasets/lacounty::school-district-boundaries/about`
- Alternative: TIGER UNSD layer (statewide, same GEOID format)

City Boundaries:
- Hub: `https://hub.arcgis.com/datasets/lacounty::la-county-city-boundaries`
- LA County city boundaries vs. TIGER PLACE: TIGER PLACE is preferred (standard GEOID, consistent MTFCC)

---

## Politician Record Gap-Fill Strategy

### What Likely Already Exists (from BallotReady Import, pre-v1.5)

State and federal officials for California were fetched during the BallotReady cache warming period. These records have `external_id` from BallotReady and their districts should have `geo_id` populated from BallotReady's `geo_id` field. The congressional and state legislative boundary imports (G5200, G5210, G5220) primarily need the geometry — not new politician records.

**Verification query:**
```sql
SELECT district_type, COUNT(*) as count
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.state = 'CA'
GROUP BY district_type;
```

If this returns rows for `NATIONAL_LOWER`, `STATE_UPPER`, `STATE_LOWER`, those politicians exist. Missing `geo_id` values on their districts is the only remaining gap.

### What Does NOT Exist (requires gap-fill)

Local LA County officials were NOT fetched by the BallotReady warmer. BallotReady's API was address-specific and local results depended on cache warming for specific ZIP codes. LA County local offices (supervisors, city councils, school boards) require separate sourcing.

**Deduplication strategy for manual gap-fill:**

1. External ID first: if the politician was ever fetched from BallotReady, they have an `external_id`. Match on `external_id` before creating a new record. The `Politician.ExternalID` field has a `uniqueIndex` — duplicate external IDs will fail at DB level.
2. No external ID (locally sourced): assign a synthetic negative integer or use a separate source tag (`source='manual'`) to avoid collisions with BallotReady's positive integer IDs. The staging tool (`/staging/*`) supports manual politician creation and review workflow.
3. Name + district as soft match: if a politician appears in both a BallotReady partial record and manual entry, compare full_name + district_type + state. Do not merge automatically — flag for human review via the staging workflow.
4. OCD-ID as secondary identifier: LA County supervisors and some city officials have OCD-IDs (Open Civic Data identifiers). If known, store in `essentials.districts.ocd_id` and `essentials.geofence_boundaries.ocd_id`. OCD-IDs are stable across data sources and can resolve duplicates when BallotReady external_id is unknown.

### Data Sources for Gap-Fill

| Politician type | Count in LA County | Data source | Effort |
|-----------------|-------------------|-------------|--------|
| U.S. Representatives | ~14 | Likely in DB already | Verify geo_id |
| CA State Senators | ~11 | Likely in DB already | Verify geo_id |
| CA Assembly members | ~24 | Likely in DB already | Verify geo_id |
| LA County Supervisors | 5 | Manual entry (official site: bos.lacounty.gov) | 1-2 hours |
| LA City Council | 15 | Manual entry (lacity.gov/council) | 2-4 hours |
| LA City Mayor/exec | 1-3 | Manual entry | 30 min |
| School board members | ~300+ across 80+ districts | Too many for manual; requires data sourcing | Deferred to v1.6.x or later |
| Other city councils | ~800+ across 87 cities | Too many for manual | Deferred to v2+ |

The realistic v1.6 MVP focuses on: verify federal/state records exist, add 5 supervisors, add 15 LA City council members. School boards and smaller city councils are deferred.

---

## Competitor Reference: How Comparable Tools Handle Regional Coverage

| Tool | Coverage model | Boundary source | Gap-fill for local officials |
|------|----------------|-----------------|-------------------------------|
| Ballotpedia "Who Represents Me" | National, all districts | Proprietary data + TIGER | Comprehensive editorial team |
| Google "Who represents me" | National federal + state | Proprietary | Does not cover local elections |
| My Reps (DataMade) | City of Chicago focus | Custom shapefiles | Manual curation |
| vote.gov | Links to state election offices | None (redirection model) | N/A |
| OpenStates | State legislative only | TIGER SLDU/SLDL | No local |
| EV Essentials (v1.6 target) | LA County full hierarchy | TIGER + LA County GIS | Manual entry for supervisors + LA City council; deferred for rest |

**Key observation:** No tool covers all local levels (city council, school board) comprehensively without a large editorial/data team or paid API. The realistic EV approach is: cover the high-value local offices (supervisors, largest cities) manually and build the import pipeline infrastructure so coverage can grow incrementally.

---

## Sources

- U.S. Census Bureau TIGER/Line Shapefiles 2025: https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html
- TIGER FTP directory: https://www2.census.gov/geo/tiger/TIGER2025/
- LA County GIS Portal — Political Boundaries ArcGIS REST: https://arcgis.gis.lacounty.gov/arcgis/rest/services/LACounty_Dynamic/Political_Boundaries/MapServer/layers
- LA County Enterprise GIS Hub: https://egis-lacounty.hub.arcgis.com/
- LA County Supervisorial Districts (Current): https://egis-lacounty.hub.arcgis.com/datasets/lacounty::supervisorial-districts-current/about
- LA County City Boundaries: https://hub.arcgis.com/datasets/lacounty::la-county-city-boundaries
- LA County School District Boundaries: https://egis-lacounty.hub.arcgis.com/datasets/lacounty::school-district-boundaries/about
- LA County Open Data Portal: https://data.lacounty.gov/
- OCD-ID standard for civic data deduplication: https://medium.com/cicero-data/how-to-use-open-civic-data-identifiers-to-organize-political-data-c27755702509
- ogr2ogr PostGIS import documentation: https://docs.geoserver.geo-solutions.it/edu/en/adding_data/shp_postgis_ogr.html
- PostGIS loading data overview: https://www.crunchydata.com/blog/loading-data-into-postgis-an-overview
- EV Codebase: `EV-Backend/internal/essentials/geofence_models.go`, `EV-Backend/internal/essentials/geofence_lookup.go` (MTFCC mapping), `EV-Backend/internal/essentials/models.go` (District.geo_id, Politician.external_id)
- EV PROJECT.md — v1.6 milestone definition

---

*Feature research for: v1.6 LA County Full Coverage & Repeatable Import Pipeline*
*Researched: 2026-02-23*
