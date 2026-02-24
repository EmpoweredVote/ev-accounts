# LA County Data Import Pipeline Runbook

**Version:** v1.6
**Last run:** February 2026
**Result:** All 16/16 test addresses pass full tier verification

## Overview

This runbook documents the complete data pipeline that powers address-based politician lookups for LA County. When a user enters any LA County address, the system returns their full representative hierarchy:

- **Federal** — US House member (from congressional district geofence)
- **State** — State Senator and Assembly member (from legislative district geofences)
- **County** — LA County Supervisor (from custom supervisor district geofence)
- **City** — Mayor and City Council member (from city boundary + council ward geofences)
- **School** — School Board member(s) (from school district geofence)

The pipeline runs in strict phase order. Each phase's output is a prerequisite for the next. Steps 1-3 build the geofence layer; Steps 4-5 import and link politicians.

**Target audience:** A developer repeating this process for a new county or region.

---

## Prerequisites

Before running any import steps, ensure the following are in place.

### Python Environment

```bash
cd EV-Backend/scripts
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Required packages (from `requirements.txt`): `geopandas`, `psycopg2-binary`, `SQLAlchemy`, `requests`, `rapidfuzz`, `shapely`

### Database Connection

**CRITICAL: Use direct connection (port 5432), NOT the pooler (port 6543).**

The Supabase transaction pooler (port 6543) breaks two operations in this pipeline:
1. `VACUUM ANALYZE` — cannot run inside a transaction block
2. Multi-statement geopandas imports — pooler resets state between statements

Create `EV-Backend/.env.local` (never commit this):
```
DATABASE_URL=postgresql://postgres.xxxxx:password@aws-0-us-east-1.pooler.supabase.com:5432/postgres
BALLOTREADY_API_KEY=your-key-here
```

The connection string URI must use **port 5432** (direct). Get it from Supabase dashboard: **Project Settings > Connection > Connection string (URI)**.

### Go Backend

The Go backend (`EV-Backend`) must be run before any import steps to trigger GORM AutoMigrate, which creates the database tables and indexes.

```bash
cd EV-Backend
go run .
# Wait for "Server running on port 5050", then Ctrl+C
```

AutoMigrate creates `essentials.geofence_boundaries` with a composite unique constraint on `(geo_id, mtfcc)` and a GiST index on the `geometry` column.

---

## Phase 1: Schema Setup

**What this does:** Creates all database tables, constraints, and indexes via GORM AutoMigrate.

### Steps

1. Run the Go backend to trigger AutoMigrate:
   ```bash
   cd EV-Backend
   go run .
   ```
   Wait for the "Server running on port 5050" message, then stop it. AutoMigrate runs on startup.

2. Verify the composite unique constraint exists on `geofence_boundaries`:
   ```sql
   SELECT constraint_name
   FROM information_schema.table_constraints
   WHERE table_schema = 'essentials'
     AND table_name = 'geofence_boundaries'
     AND constraint_type = 'UNIQUE';
   -- Expected: one row with unique constraint on (geo_id, mtfcc)
   ```

3. Verify `geofence_lookup.go` uses `ST_Covers` (not `ST_Contains`):
   ```bash
   grep -n "ST_Covers\|ST_Contains" EV-Backend/internal/essentials/geofence_lookup.go
   # Expected: all spatial predicates use ST_Covers
   ```
   **Why this matters:** `ST_Contains` returns FALSE for points exactly on a boundary. `ST_Covers` returns TRUE. Phase 32 confirmed this fix — boundary-edge addresses would silently fail without it.

4. Verify the MTFCC-to-district-type map in `geofence_lookup.go` includes all required codes:
   ```bash
   grep -n "G4110\|G4120\|G5400\|G5410\|G5420\|X0001" EV-Backend/internal/essentials/geofence_lookup.go
   ```
   Expected entries: G4110 (cities), G4120 (consolidated cities), G5400/G5410 (school districts, mapped to SCHOOL), X0001 (custom supervisor/council districts, mapped to LOCAL).

### What varies by region

Nothing — the schema and GORM models are universal. AutoMigrate handles all DDL.

---

## Phase 2: TIGER Shapefile Import

**What this does:** Imports federal, state, school, and city boundary geofences from Census TIGER/Line shapefiles.

**Script:** `EV-Backend/scripts/import_ca_legislative_geofences.py`
**Script:** `EV-Backend/scripts/import_ca_place_boundaries.py`

### Data Sources (CA / v1.6 vintage: 2024)

Download these shapefiles from the Census TIGER FTP:

| File | MTFCC | Coverage | URL |
|------|-------|----------|-----|
| `tl_2024_us_cd119.zip` | G5200 | Congressional Districts | `https://www2.census.gov/geo/tiger/TIGER2024/CD/tl_2024_us_cd119.zip` |
| `tl_2024_06_sldu.zip` | G5210 | CA State Senate | `https://www2.census.gov/geo/tiger/TIGER2024/SLDU/tl_2024_06_sldu.zip` |
| `tl_2024_06_sldl.zip` | G5220 | CA State Assembly | `https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_06_sldl.zip` |
| `tl_2024_06_unsd.zip` | G5420 | CA Unified School Districts | `https://www2.census.gov/geo/tiger/TIGER2024/UNSD/tl_2024_06_unsd.zip` |
| `tl_2024_06_place.zip` | G4110 | CA Incorporated Places | `https://www2.census.gov/geo/tiger/TIGER2024/PLACE/tl_2024_06_place.zip` |

### Steps

1. Run the legislative geofences script (imports G5200, G5210, G5220, and G5420):
   ```bash
   cd EV-Backend/scripts
   source .venv/bin/activate
   python3 import_ca_legislative_geofences.py
   ```
   The script downloads shapefiles, filters to CA boundaries (FIPS 06), and upserts into `essentials.geofence_boundaries`. Script output shows row counts per MTFCC.

2. Run the place boundaries script (imports G4110 — incorporated cities):
   ```bash
   python3 import_ca_place_boundaries.py
   ```
   Imports 482 CA incorporated city boundaries. Uses `NAMELSAD` column for `geo_id` (e.g., "Los Angeles city"), consistent with the legislative script.

3. Verify row counts per MTFCC:
   ```sql
   SELECT mtfcc, COUNT(*) as count
   FROM essentials.geofence_boundaries
   GROUP BY mtfcc
   ORDER BY mtfcc;
   ```
   Expected after Phase 2 (LA County filter active):
   - G5200: ~53 rows (CA congressional districts)
   - G5210: 40 rows (CA state senate districts)
   - G5220: 80 rows (CA state assembly districts)
   - G5420: ~400+ rows (CA unified school districts)
   - G4110: 482 rows (CA incorporated places)

4. Verify geometry validity:
   ```sql
   SELECT COUNT(*) as invalid_count
   FROM essentials.geofence_boundaries
   WHERE NOT ST_IsValid(geometry);
   -- Expected: 0
   ```

### School districts: G5420 only (not G5400/G5410)

**CRITICAL:** Import `tl_2024_06_unsd.zip` (unified school districts, G5420) only. Do NOT import `elsd` (G5400, elementary) or `scsd` (G5410, secondary) shapefiles.

If all three are imported, an address in an LAUSD area matches all three records for each LAUSD board member, tripling the school tier results. Unified-only (`unsd`) is the correct level for elected school board representation.

### What varies by region

| Element | LA County (v1.6) | What changes for another state/region |
|---------|-----------------|--------------------------------------|
| State FIPS | `06` | Use the two-digit FIPS code for the target state |
| TIGER vintage year | `2024` | Update annually; check `https://www2.census.gov/geo/tiger/` for latest |
| Congressional district file | `tl_2024_us_cd119` | 119th Congress; update when a new Congress begins |
| School district type | `unsd` (unified) | Some states use `elsd`/`scsd` — verify which type matches elected board seats |

---

## Phase 3: Local Geofence Import

**What this does:** Imports custom geofences for LA County supervisor districts and city council ward boundaries. These are not available in TIGER — they must be sourced from ArcGIS FeatureServer APIs.

**Script:** `EV-Backend/scripts/import_arcgis_geofences.py`
**Config:** `EV-Backend/scripts/arcgis_sources.json`

All local geofences use MTFCC `X0001` (custom/non-TIGER). The `geo_id` for each boundary is set to the district's OCD-ID (e.g., `ocd-division/country:us/state:ca/county:los_angeles/council_district:2`), which matches the `essentials.districts.ocd_id` column used in Phase 4.

### 3a. LA County Supervisor Districts

**Source:** LA County ArcGIS (EsriJSON FeatureServer)
**MTFCC:** X0001
**geo_id format:** OCD-ID string (e.g., `ocd-division/country:us/state:ca/county:los_angeles/council_district:1`)

5 supervisor district boundaries covering the entire county. These are critical: unincorporated areas (40% of LA County land) rely on supervisor geofences for their only "local" representative.

Configuration is in `arcgis_sources.json` under the supervisor district entry. Run:
```bash
cd EV-Backend/scripts
source .venv/bin/activate
python3 import_arcgis_geofences.py --source supervisor_districts
```

### 3b. LA City Council Wards

**Source:** LA City GeoHub (GeoJSON)
**MTFCC:** X0001
**geo_id format:** OCD-ID string (e.g., `ocd-division/country:us/state:ca/place:los_angeles/council_district:1`)

15 council ward boundaries for the City of Los Angeles. LA City uses a separate GeoHub endpoint from the ArcGIS-based sources.

```bash
python3 import_arcgis_geofences.py --source la_city_wards
```

### 3c. Other City Council Wards

**Script:** `import_arcgis_geofences.py` (config-driven)
**Config:** `arcgis_sources.json`

The `arcgis_sources.json` file maps each city to its ArcGIS FeatureServer URL, layer ID, and district field name. Run all configured city sources:

```bash
python3 import_arcgis_geofences.py --all
```

Cities with ward-level boundaries in v1.6: Long Beach, Torrance, Pasadena, Inglewood, West Covina, Glendale, Compton, and others.

**Note on geometry validation:** Some ArcGIS sources return multi-polygon districts. The import script uses `shapely.unary_union` to dissolve duplicate district IDs (e.g., Inglewood CD=2 had two polygons) and sets `quality_flag='geometry_dissolved'` on affected records.

### 3d. Gap Cities (Documented Missing Sources)

These 5 cities have no discoverable ArcGIS FeatureServer for council district boundaries as of February 2026:

| City | Population | Notes |
|------|-----------|-------|
| Santa Clarita | ~230,000 | At-large council; no ward boundaries found |
| Downey | ~113,000 | No GIS source found |
| El Monte | ~116,000 | No GIS source found |
| Palmdale | ~170,000 | No GIS source found |
| Pomona | ~153,000 | No GIS source found |

**Impact:** Addresses in these cities return city council members from Phase 4 scraping (politicians exist) but cannot route to the correct council member via geofence. City council tier is absent for point-in-polygon lookups in these cities.

**Expected behavior in validation:** Addresses in these cities should NOT require the "city council" tier — mark them as not expected in the test address config.

### Verification

After all local geofence imports, verify X0001 counts:
```sql
SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE mtfcc = 'X0001';
-- Expected v1.6: ~65-75 rows (5 supervisor + 15 LA City + ~50 other city ward boundaries)
```

Check for any invalid geometries in X0001:
```sql
SELECT geo_id FROM essentials.geofence_boundaries
WHERE mtfcc = 'X0001' AND NOT ST_IsValid(geometry);
-- Expected: 0 rows
```

### What varies by region

| Element | LA County (v1.6) | What changes for another region |
|---------|-----------------|--------------------------------|
| Supervisor ArcGIS URL | `arcgis_sources.json` | Each county has its own GIS portal — search county name + "ArcGIS supervisor districts" |
| Number of supervisor districts | 5 | Varies: most counties have 3-7 supervisors |
| City ward sources | `arcgis_sources.json` per city | City GIS portals — search "city name GIS open data" |
| Gap cities | Santa Clarita, Downey, El Monte, Palmdale, Pomona | Document missing sources in comments in `arcgis_sources.json` |
| OCD-ID format | `ocd-division/country:us/state:ca/county:los_angeles/council_district:N` | Change state and county slug; verify OCD-ID registry if needed |

---

## Phase 4: Politician Data Gap-Fill

**What this does:** Imports politicians not available via BallotReady (local officials, school boards) and links all politicians to their geofences via `geo_id`.

This phase has strict ordering within it:
1. `gap_fill_geo_ids.py` — must run first (links existing BallotReady politicians to geofences)
2. `scrape_la_officials.py` — imports LA County supervisors + LA City officials
3. `scrape_city_councils.py` — imports remaining city council members
4. `scrape_school_boards.py` — imports school board members

### 4a. Populate geo_ids on Existing Politicians

**Script:** `EV-Backend/scripts/gap_fill_geo_ids.py`

BallotReady politicians are already in `essentials.politicians` (from the API cache layer) but their `essentials.districts` records have no `geo_id` — the geofence join fails silently. This script runs SQL updates to populate `geo_id` from the matching OCD-ID patterns.

```bash
cd EV-Backend/scripts
source .venv/bin/activate
python3 gap_fill_geo_ids.py
```

**Key behavior:**
- For `LOCAL` districts: sets `geo_id = ocd_id` (direct OCD-ID match to geofence boundaries)
- For `LOCAL_EXEC` (mayor) in LA City: sets `geo_id = '0644000'` (Census GEOID for Los Angeles place, matching the G4110 geofence imported in Phase 2)

After running, verify:
```sql
SELECT COUNT(*) FROM essentials.districts
WHERE district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS NOT NULL;
-- Should be higher than before running the script
```

### 4b. Scrape LA County and LA City Officials

**Script:** `EV-Backend/scripts/scrape_la_officials.py`

Imports officials not available via BallotReady:
- 5 LA County Supervisors (county-level)
- 15 LA City Council members (ward assignments from Phase 3 geofences)
- LA City Mayor, Controller, City Attorney, DA, Sheriff, Assessor, and other county officials

```bash
python3 scrape_la_officials.py
```

The script uses fuzzy name matching (rapidfuzz, threshold=1) to check for duplicate names before inserting. It assigns synthetic external IDs starting at -200001 (see "Synthetic External IDs" below).

After running, verify:
```sql
SELECT COUNT(*) FROM essentials.politicians
WHERE external_id <= -200001;
-- Should match the number of scraped officials inserted
```

### 4c. Scrape City Councils

**Script:** `EV-Backend/scripts/scrape_city_councils.py`
**Config:** `EV-Backend/scripts/city_sources.json`

Imports council members for all incorporated cities not covered by `scrape_la_officials.py`. Sources vary by city:
- California SOS cities-towns.pdf (PDF roster — some cities)
- City websites (scraped directly — most cities)
- Manual verification for edge cases

The script is config-driven via `city_sources.json`. Each entry specifies the data source, scraping strategy, and seat assignments.

```bash
python3 scrape_city_councils.py
```

### 4d. Scrape School Boards

**Script:** `EV-Backend/scripts/scrape_school_boards.py`
**Config:** `EV-Backend/scripts/school_sources.json`

Imports school board members for all LA County school districts. School district websites widely use Cloudflare CDN protection that blocks automated scraping.

**Strategy used for v1.6:** Hardcoded roster approach — board member names were verified from public records (school district meeting minutes, agenda PDFs, California SOS filings) as of February 2026. The `school_sources.json` file contains the rosters.

```bash
python3 scrape_school_boards.py
```

**LAUSD behavior:** All 7 LAUSD board members share a single district record with `geo_id='0622710'` (the whole-district LAUSD boundary). Trustee area sub-boundaries are not publicly available in ArcGIS. Any address within the LAUSD service area returns all 7 board members — this is correct behavior, not a bug.

After running, verify:
```sql
SELECT COUNT(*) FROM essentials.politicians
WHERE external_id <= -200001;
-- Total scraped politicians; cross-check against expected count from school_sources.json
```

### Synthetic External ID Ranges

Politicians imported via scraping receive negative `external_id` values to distinguish them from BallotReady-sourced politicians (which have positive external IDs from BallotReady's ID space).

| Range | Used by | Notes |
|-------|---------|-------|
| -1 to -100000 | Reserved / historical | Do not use |
| -100001 to -199999 | v1.5 pipeline (`promote_scraped_officials.py`) | Do not reuse |
| -200001 to -299999 | v1.6 pipeline (Phases 33-37) | Current range |
| -300001 and below | Next region | Use this range for the next county import |

**Why negative IDs matter:** The upsert logic in BallotReady warmer goroutines uses `external_id` for conflict detection. Negative IDs guarantee no collision with any BallotReady-assigned positive ID.

### What varies by region

| Element | LA County (v1.6) | What changes for another region |
|---------|-----------------|--------------------------------|
| CA SOS PDF | California cities-towns.pdf | Each state's Secretary of State publishes a different roster format |
| School board scraping | Hardcoded rosters (anti-scrape protection) | Some states have open school board APIs; check state education department |
| External ID range | -200001 | Use next available range: -300001 for the third region, etc. |
| Fuzzy match threshold | 1 (last name) | Increase to 2 only for regions with very long/unique names; threshold 1 prevents collision on short names like "Hahn" |

---

## Phase 5: Validation and Performance

**What this does:** Runs VACUUM ANALYZE to refresh query planner statistics, confirms GiST index is active, and validates the full representative hierarchy for 16 representative LA County addresses.

**Script:** `EV-Backend/scripts/validate_la_county.py`

### Step 1: Run VACUUM ANALYZE

VACUUM ANALYZE refreshes the PostgreSQL query planner statistics for `essentials.geofence_boundaries`. After bulk imports, statistics are stale — the query planner may choose a sequential scan over the GiST index, degrading performance significantly.

This command runs automatically as the first step in `validate_la_county.py`. It requires a direct database connection (port 5432) and cannot run inside a transaction.

### Step 2: Run the Validation Script

```bash
cd EV-Backend/scripts
source .venv/bin/activate
python3 validate_la_county.py
```

The script performs three operations in order:
1. **VACUUM ANALYZE** — refreshes planner statistics (VAL-02)
2. **GiST index confirmation** — runs `EXPLAIN ANALYZE` on a test query and checks for absence of "Seq Scan" (VAL-03)
3. **PIP tier verification** — runs the full point-in-polygon query for 16 representative addresses and checks each expected tier is present (VAL-01, VAL-04)

### Step 3: Interpret the Pass/Fail Report

The script prints a per-address summary table followed by overall PASS/FAIL:

```
Address                                 | Result | Tiers Found
----------------------------------------|--------|------------------
Pasadena City Hall (incorporated)       | PASS   | federal, state_senate, state_assembly, county, city, school
East LA (unincorporated)                | PASS   | federal, state_senate, state_assembly, county, school
...
OVERALL: 16/16 addresses PASS | GiST: PASS | OVERALL: PASS
```

**Expected results for LA County v1.6:**

| Address type | Expected tiers | Notes |
|---|---|---|
| Incorporated city with ward boundaries | 6 tiers | federal, state_senate, state_assembly, county, city, school |
| Unincorporated community | 5 tiers | No city tier — no incorporated city boundary |
| Gap city (Santa Clarita, Downey, etc.) | 5 tiers required | City council absent — no ArcGIS boundaries available |
| Boundary edge | 5+ tiers | ST_Covers returns TRUE for boundary-coincident points |

**County tier note:** LA County Supervisors have `district_type='LOCAL'` and `mtfcc='X0001'` (not `COUNTY`/`G4020`). This is the Phase 35-01 decision. The validation script detects the supervisor tier via `ocd_id LIKE '%county:los_angeles/council_district%'` or `office_title LIKE '%Supervisor%'`, not via `district_type='COUNTY'`.

**Federal tier note:** US Senators and President/VP/Cabinet are returned via a statewide supplement query in the production handler (`fetchStatewideFromDB`), not via geofence. The validation script must call the actual API endpoint or run the statewide query separately to confirm these tiers. Congressional district members (US House, `NATIONAL_LOWER`) come from G5200 geofences.

**School tier note:** For addresses within LAUSD, all 7 board members are returned because they share one whole-district boundary. This is correct behavior — mark validation as "at least 1 school member" not "exactly 1".

### Step 4: Fix Any Failures

If addresses fail:

1. **Missing geofence tier** — check `geofence_boundaries` for the expected MTFCC at that coordinate:
   ```sql
   SELECT geo_id, mtfcc
   FROM essentials.geofence_boundaries
   WHERE ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-118.2427, 34.0537), 4326));
   ```

2. **Geofence present but no politician** — check `districts` has a matching `geo_id` and `politicians` is linked:
   ```sql
   SELECT p.full_name, d.district_type, d.geo_id
   FROM essentials.politicians p
   JOIN essentials.offices o ON o.politician_id = p.id
   JOIN essentials.districts d ON o.district_id = d.id
   WHERE d.geo_id = 'expected-geo-id' AND p.is_active = true;
   ```

3. **Politician present but wrong geo_id** — re-run `gap_fill_geo_ids.py` and check district update logic

4. **Re-run validation** after any fix to confirm resolution

---

## Known Limitations (LA County v1.6)

These are accepted gaps in the current implementation:

1. **LAUSD returns all 7 board members for any LAUSD address.** LAUSD trustee area sub-boundaries are not publicly available in ArcGIS as of February 2026. All board members share the whole-district boundary (`geo_id='0622710'`).

2. **5 gap cities have no council ward boundaries.** Santa Clarita, Downey, El Monte, Palmdale, and Pomona do not have discoverable ArcGIS FeatureServer sources for council district polygons. City council members from scraping exist in the database but cannot be routed via geofence for these cities.

3. **Federal officials (US Senate, President/VP) are from statewide supplement, not geofences.** The production handler (`SearchPoliticians`) calls `fetchStatewideFromDB` to add `NATIONAL_UPPER` and `NATIONAL_EXEC` officials. These are not stored in `geofence_boundaries`.

4. **BallotReady API dependency for federal and state legislators.** Addresses outside the 90-day cache window rely on BallotReady API calls to populate `NATIONAL_LOWER`, `STATE_UPPER`, and `STATE_LOWER` records. The geofences route these officials correctly once they are cached.

---

## What Varies by Region — Summary Table

| Element | LA County (v1.6) | What changes |
|---------|-----------------|--------------|
| State FIPS code | `06` (California) | Two-digit FIPS for the target state |
| TIGER vintage year | `2024` | Update annually; check Census TIGER FTP |
| Congressional district file | `tl_2024_us_cd119` | Update when Congress changes (119th → 120th, etc.) |
| ArcGIS supervisor sources | `arcgis_sources.json` | Each county has a different GIS portal; search county name + ArcGIS |
| ArcGIS city council sources | `arcgis_sources.json` per city | Search city name + "GIS open data" or "ArcGIS" |
| CA SOS PDF | California cities-towns.pdf | Each state SOS publishes a different format |
| External ID range | -200001 to -299999 | Next available range: -300001 |
| Gap cities | Santa Clarita, Downey, El Monte, Palmdale, Pomona | Varies by region — document in `arcgis_sources.json` |
| Validation script | `validate_la_county.py` | Create a new validation script with test addresses for the new region |
| School district type | `unsd` (unified, G5420) | Verify which TIGER school district type covers elected boards in the target state |
| Fuzzy match threshold | 1 (last name) | Increase only for long/unusual names; 1 is default |
| LAUSD-style whole-district boards | Applicable to large unified districts | Document which school districts lack ward boundaries |

---

## Quick Execution Checklist

Use this checklist when running the pipeline for a new region:

```
[ ] 1. Create .env.local with DATABASE_URL using port 5432 (direct connection)
[ ] 2. Run Go backend to trigger AutoMigrate (creates tables + indexes)
[ ] 3. Verify (geo_id, mtfcc) unique constraint on geofence_boundaries
[ ] 4. Download TIGER shapefiles for the target state (correct vintage year)
[ ] 5. Run import_ca_legislative_geofences.py (adapt for new state FIPS)
[ ] 6. Run import_ca_place_boundaries.py (adapt for new state FIPS)
[ ] 7. Verify row counts per MTFCC; verify ST_IsValid = 0 invalid geometries
[ ] 8. Source ArcGIS URLs for county supervisor + city council ward boundaries
[ ] 9. Update arcgis_sources.json with new region's sources + document any gaps
[ ] 10. Run import_arcgis_geofences.py for all local sources
[ ] 11. Run gap_fill_geo_ids.py (links BallotReady politicians to geofences)
[ ] 12. Run scrape_la_officials.py (adapt for new region's county officials)
[ ] 13. Run scrape_city_councils.py (adapt city_sources.json for new region)
[ ] 14. Run scrape_school_boards.py (adapt school_sources.json for new region)
[ ] 15. Run validate_la_county.py (create a new validation script for the region)
[ ] 16. Confirm 100% of test addresses pass; document any accepted gaps
```

---

## Troubleshooting Reference

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `VACUUM cannot run inside a transaction block` | psycopg2 autocommit not set | Set `conn.autocommit = True` before VACUUM |
| `EXPLAIN ANALYZE` shows `Seq Scan` | Statistics stale after bulk imports | Run `VACUUM ANALYZE essentials.geofence_boundaries` first |
| Address returns no officials | geo_id mismatch or missing geofence | Run PIP query directly; check geofence_boundaries for that coordinate |
| County supervisor missing | district_type='LOCAL' for X0001 MTFCCs | Detect supervisor via ocd_id LIKE or office_title LIKE '%Supervisor%' |
| City tier missing for incorporated city | Missing G4110 boundary or geo_id not populated | Re-run import_ca_place_boundaries.py; verify geo_id in districts |
| Duplicate school board members | G5400/G5410 imported alongside G5420 | Remove non-unified school district boundaries; import G5420 only |
| `connection refused on port 6543` | Wrong Supabase connection string | Use port 5432 (direct connection), not 6543 (pooler) |
| Politician in DB but no geofence match | Missing geo_id on district record | Re-run gap_fill_geo_ids.py; verify district.geo_id is populated |
| Script fails with `module not found` | Virtual environment not activated | `source EV-Backend/scripts/.venv/bin/activate` |
