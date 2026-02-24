# Project Research Summary

**Project:** v1.6 LA County Full Coverage & Repeatable Import Pipeline
**Domain:** Civic tech — geofence expansion and politician data pipeline
**Researched:** 2026-02-23
**Confidence:** HIGH

## Executive Summary

The v1.6 milestone is a data pipeline problem, not a software architecture problem. The existing Go backend's `geofence_lookup.go` already implements the correct point-in-polygon query and MTFCC-to-district-type translation. The lookup infrastructure works; the geofence boundaries and local politician records for LA County are simply absent from the database. The entire scope of this milestone is: import the right boundary polygons, populate the right politician records, and ensure the two sides join correctly via `geo_id`. No new API endpoints, no frontend changes, and no new Go packages are required.

The recommended approach is a Python-based import pipeline (geopandas 1.1.2 + SQLAlchemy 2.0.46 + psycopg2) layered over the existing PostgreSQL/PostGIS database. This stack is already proven across five existing import scripts in `EV-Backend/scripts/`. TIGER shapefiles cover federal, state, county, school, and incorporated-city boundaries; the LA County eGIS ArcGIS FeatureServer fills the gap for supervisor district boundaries not available from TIGER at sufficient accuracy. Geofences must be imported first to establish which `geo_id` values are needed, then politician records are created or verified to ensure matching `districts.geo_id` values. For federal and state officials, records likely already exist from BallotReady; only local officials (5 supervisors, 15 LA City council members) require manual gap-fill at v1.6 scope.

The dominant risks are schema and data quality issues that fail silently: the `geofence_boundaries` unique constraint must be changed from `geo_id` to `(geo_id, mtfcc)` before any multi-layer import, invalid geometries must be repaired with `ST_MakeValid` before promotion from staging, and the Supabase direct connection (port 5432) must be used instead of the pooler (port 6543). A pre-existing bug in `geofence_lookup.go` — `ST_Contains` instead of `ST_Covers` — will cause addresses on district boundaries to return zero results and must be fixed before LA County testing. All six pitfalls identified in PITFALLS.md have specific verification queries that should be run as post-import checks.

## Key Findings

### Recommended Stack

The import pipeline requires no new core technologies. The established Python + geopandas + SQLAlchemy pattern used in existing scripts handles both TIGER shapefiles (via `geopandas.read_file()` + `to_postgis()`) and ArcGIS FeatureServer GeoJSON (via `requests` + `gpd.GeoDataFrame.from_features()`). A shared `utils.py` should be extracted to eliminate duplicated `get_engine()`, `load_env()`, and URL-encoding logic that currently exists in five separate scripts. Synthetic external IDs for non-BallotReady records must start at -200001 to avoid colliding with any -100001-range IDs created in v1.5.

**Core technologies:**
- `geopandas 1.1.2`: Read shapefiles/GeoJSON, reproject CRS, write to PostGIS — the established pattern in all existing import scripts; requires Python 3.10+ and shapely 2.x
- `SQLAlchemy 2.0.46`: Engine for `to_postgis()` — required version; 2.1 is beta; pin explicitly
- `psycopg2-binary >=2.9`: Bulk upserts via `execute_values()` with `ON CONFLICT` — use for politician records; `to_postgis()` for geometry-only inserts
- `requests >=2.32`: Download TIGER ZIPs and fetch ArcGIS FeatureServer GeoJSON — already in use across existing scripts
- `shapely >=2.0`: Geometry validation (`.buffer(0)` for topology repair) — pulled in automatically by geopandas
- `ogr2ogr` (GDAL, system dependency): TIGER shapefiles are NAD83 (EPSG:4269); reprojection to WGS84 (EPSG:4326) handled via ogr2ogr subprocess; GDAL 3.5+ required for `-makevalid` flag to avoid GeometryCollection output

**What not to add:** no Go CLI for shapefiles (no mature Go shapefile library), no `arcgis` Python SDK (50MB, requires auth, overkill), no `luigi`/`prefect`/`airflow` (quarterly import does not need a workflow system), no `alembic` (GORM AutoMigrate handles schema).

### Expected Features

**Must have (table stakes — v1.6 MVP, full hierarchy for any LA County address):**
- TIGER congressional district boundaries (G5200, ~14 districts) — enables NATIONAL_LOWER match
- TIGER CA State Senate boundaries (G5210, ~11 districts) — enables STATE_UPPER match
- TIGER CA State Assembly boundaries (G5220, ~24 districts) — enables STATE_LOWER match
- LA County Supervisorial District boundaries from eGIS ArcGIS (G4020, 5 districts) — enables COUNTY match; TIGER lacks precision
- School district boundaries (G5420, 80+ districts) — enables SCHOOL match; import UNSD only, never G5400/G5410
- TIGER incorporated places (G4110, 88 cities) — enables LOCAL match for city councils
- Politician gap-fill: 5 LA County supervisors — minimum to return county-level results
- Politician gap-fill: 15 LA City council members + mayor — highest-population city, most users
- Diagnostic SQL: geo_id match rate between `geofence_boundaries` and `districts` — prevents silent failures
- Idempotent upsert: `ON CONFLICT (geo_id, mtfcc) DO UPDATE` on geofence_boundaries

**Should have (competitive, v1.6.x):**
- Politician gap-fill for remaining 87 city councils via data-entry tool
- School board member records for 80+ districts (hundreds of records — staged effort)
- LA City council ward boundaries (X0001, 15 districts) once politician records exist
- Coverage dashboard SQL view showing MTFCC coverage with district + politician match rate

**Defer (v2+):**
- Automated TIGER vintage refresh — handle as a planned event on redistricting cycles (2031), not automation
- Expansion to other CA counties — same pipeline, new politician data required per county
- Full national coverage — boundary pipeline is solved; politician data sourcing is the blocker
- Voting precinct (VTD) boundaries — different use case; separate table if ever needed
- Real-time LA County official sync — requires new data provider contract

### Architecture Approach

The architecture is a strict separation between the offline import pipeline and the unchanged online request path. The Go backend's `geofence_lookup.go` requires zero changes for the lookup to work with LA County data — new boundary rows in `essentials.geofence_boundaries` and new politician rows linked via matching `districts.geo_id` are the entire deliverable. The import pipeline consists of Python scripts that write directly to Supabase via `DATABASE_URL`. The critical join is `geofence_boundaries.geo_id = districts.geo_id`; both sides must use identical geo_id values or the join silently returns zero results.

**Major components:**
1. `EV-Backend/scripts/utils.py` (NEW) — shared `get_engine()`, `load_env()`, `next_ext_id()` extracted from existing scripts; URL-encoding pattern for Supabase passwords with special characters
2. `EV-Backend/scripts/import_tiger_ca.py` (NEW) — downloads TIGER shapefiles for California layers not yet imported (congressional, state leg, school districts, incorporated places); handles NAD83→WGS84 reprojection; applies `ST_MakeValid`
3. `EV-Backend/scripts/import_lacounty_gis.py` (NEW) — fetches LA County ArcGIS FeatureServer data (supervisor districts, city boundaries); assigns MTFCC manually per layer; builds consistent geo_ids (`06037{NNN}` format for supervisors)
4. `EV-Backend/scripts/import_lacounty_officials.py` (NEW) — politician gap-fill from structured manifest; uses `execute_values()` with `ON CONFLICT (external_id) DO NOTHING`; checks for existing records before inserting
5. `EV-Backend/scripts/verify_lacounty.py` (NEW) — point-in-polygon verification for test addresses (incorporated city, unincorporated area, contested boundary); post-import diagnostic queries
6. `EV-Backend/internal/essentials/geofence_lookup.go` (MINOR EDIT) — add missing MTFCC codes (G4110, G4120, G5400, G5410) to `mtfccToDistrictTypes`; replace `ST_Contains` with `ST_Covers` (pre-existing bug)

**Key patterns:**
- Import order: schema verification → geofences → coverage diagnostic → politician gap-fill → VACUUM ANALYZE
- `(geo_id, mtfcc)` composite unique constraint is the correct key for idempotent geofence upserts
- `ST_MakeValid()` wraps every geometry before INSERT — mandatory, not optional
- All imports use Supabase direct connection (port 5432), never the pooler (port 6543)
- Import only UNSD (G5420) school districts — not G5400 or G5410 — to prevent triple-match in LAUSD
- Geo_id format must exactly match what BallotReady stored in `districts.geo_id` — verify from DB before building import logic for any layer

### Critical Pitfalls

1. **`ON CONFLICT (geo_id)` silently drops valid boundaries across MTFCC types** — the unique constraint must be `(geo_id, mtfcc)` before the first multi-layer import; verify with post-import count-per-MTFCC query; this is a schema change required before any data lands.

2. **Invalid geometries fail silently — no error, no row, no district** — run `SELECT COUNT(*), mtfcc FROM staging WHERE NOT ST_IsValid(geometry)` before promoting staging to production; wrap all inserts in `ST_Multi(ST_CollectionExtract(ST_MakeValid(geometry), 3))`; verify GDAL version is 3.5+ if using `-makevalid` flag.

3. **Supabase pooler (port 6543) breaks ogr2ogr and bulk imports** — always use direct connection (port 5432, `db.*.supabase.co` hostname); add a preflight `psql "$DATABASE_URL" -c "SELECT 1"` validation before any import logic; partial imports through the pooler create inconsistent table state with no error.

4. **Incomplete MTFCC map returns wrong politicians via permissive fallback** — audit `mtfccToDistrictTypes` before the first LA County import; add G4110, G4120, G5400, G5410 at minimum; run post-import query for unmapped codes in the table; the permissive fallback returns unfiltered results for unknown codes.

5. **Politician deduplication fails across BallotReady + manual sources** — before inserting any politician, check for existing record by normalized `(last_name, first_name, district.geo_id)` match; run duplicate detection query after every gap-fill batch; staging module was not designed for bulk politician creation and lacks external_id-keyed deduplication.

6. **School district triple-match for LAUSD addresses** — importing G5400 + G5410 + G5420 for the same area causes the same school board member to appear 2-3x in results; import UNSD (G5420) only for LA County; document the decision; verify with `SELECT mtfcc, COUNT(*) FROM geofence_boundaries WHERE mtfcc IN ('G5400','G5410','G5420') GROUP BY mtfcc`.

## Implications for Roadmap

The build order is strictly dependency-driven. Geofences must exist before politicians can be linked. Schema correctness must be verified before any boundary data lands in production. The `ST_Contains` → `ST_Covers` bug fix and MTFCC map expansion are prerequisites that must ship before any geofence data is tested with real addresses. All six pitfalls have specific verification queries that belong in the import pipeline as automated post-import checks, not manual steps.

### Phase 1: Schema Verification and Bug Fixes

**Rationale:** All subsequent work depends on these being correct. A wrong unique constraint silently destroys import results. The `ST_Contains` bug means boundary testing is unreliable until fixed. These changes are small (1-10 lines each) and low-risk but are hard blockers — no import work should proceed until they are confirmed.
**Delivers:** Correct `(geo_id, mtfcc)` composite unique constraint confirmed or created on `geofence_boundaries`; `ST_Covers` replacing `ST_Contains` in `geofence_lookup.go` line 42; expanded `mtfccToDistrictTypes` with G4110, G4120, G5400, G5410; verified direct-connection `DATABASE_URL` with port 5432.
**Addresses:** Pitfalls 1, 3, 4 — prevents the three most damaging silent failure modes.
**Avoids:** Importing any boundary data before the schema is correct; testing address lookups before the boundary-match bug is fixed.

### Phase 2: Shared Utils and Pipeline Scaffolding

**Rationale:** Five existing scripts duplicate `get_engine()`, `load_env()`, and URL-encoding logic. Extracting `utils.py` before writing new scripts prevents a sixth and seventh copy. The `requirements.txt` pin prevents version drift between developer machines.
**Delivers:** `EV-Backend/scripts/utils.py` with shared database utilities; `requirements.txt` with pinned versions (geopandas 1.1.2, SQLAlchemy 2.0.46, psycopg2-binary, requests, shapely); documented `DATABASE_URL` setup for direct Supabase connection.
**Uses:** Python + geopandas + SQLAlchemy + psycopg2 stack from STACK.md.
**Implements:** Shared utils component; lays groundwork for all subsequent import scripts.

### Phase 3: TIGER Shapefile Geofences — Federal and State Layers

**Rationale:** Congressional, state senate, and state assembly boundaries are independent of each other and of local data. They feed the highest-visibility officials (U.S. Representatives, senators, assembly members) and their politician records likely already exist from BallotReady. This phase produces immediate visible results for any LA County address without requiring any manual politician entry.
**Delivers:** Geofence boundaries for G5200 (congressional, ~14 LA County districts), G5210 (CA Senate, ~11), G5220 (CA Assembly, ~24), G4020 (county, 1 LA County polygon), G5420 (unified school districts, 80+), G4110 (incorporated places, 88 cities); all with `ST_MakeValid` applied and staging-to-production migration validated.
**Addresses:** Congressional, state senate, state assembly, county, school, and city boundary imports from FEATURES.md P1 list.
**Avoids:** Importing G5400 or G5410 school district layers alongside G5420; importing without `ST_MakeValid`; using pooler connection; importing all 58 CA counties when only LA County-relevant boundaries are needed.

### Phase 4: LA County ArcGIS Geofences — Supervisor Districts

**Rationale:** Supervisor district boundaries are not available from TIGER at the precision needed and must come from the LA County eGIS ArcGIS FeatureServer. This is a separate source with different integration patterns (ArcGIS REST vs. Census FTP), a different geo_id construction requirement, and field names that must be verified at runtime before the import logic is written.
**Delivers:** 5 supervisor district polygons in `geofence_boundaries` with `mtfcc = 'G4020'` and `geo_id` values in `06037{NNN}` format matching BallotReady's convention; verified ArcGIS FeatureServer field names and CRS (must request `outSR=4326` to avoid EPSG:2229 coordinates).
**Addresses:** LA County Supervisorial District boundaries from FEATURES.md P1 list.
**Avoids:** Using TIGER county boundary for supervisor districts (wrong granularity — one county polygon, not 5 supervisor districts); assuming ArcGIS data is already in WGS84 without checking; truncating at the 1000-feature FeatureServer default (use pagination).

### Phase 5: Geofence Coverage Diagnostic

**Rationale:** Before creating any politician records, the diagnostic step identifies which imported `geo_id` values already have matching `districts` rows (from BallotReady) and which do not. This determines the exact scope of gap-fill work in Phase 6 and prevents creating unnecessary duplicate district rows.
**Delivers:** SQL diagnostic report: for each imported geofence boundary, does a matching `districts` row exist? For each matching district, does at least one politician record exist? Categorized by MTFCC type. Point-in-polygon tests for 3+ LA County addresses (incorporated city, unincorporated area, address on a district boundary line).
**Addresses:** GEOID ↔ geo_id diagnostic query from FEATURES.md P1 list; Anti-Pattern 1 from ARCHITECTURE.md (importing geofences without verifying matching districts).
**Avoids:** Creating politician records for districts that already exist from BallotReady; building gap-fill manifests before knowing which geo_ids are genuinely missing.

### Phase 6: Politician Gap-Fill — Supervisors and LA City Council

**Rationale:** Phase 5 identifies exactly which district geo_ids have zero politicians. The v1.6 MVP scope for gap-fill is: 5 LA County supervisors (low entry effort, high value — county residents see no results without these) and 15 LA City council members (highest-population city). Federal and state politicians are expected to already exist from BallotReady.
**Delivers:** 5 LA County supervisor records in `politicians`/`offices`/`districts` with geo_ids matching Phase 4 geofences; 15 LA City council member records with geo_ids matching Phase 3 G4110 city boundary; deduplication check passes (zero rows in post-import duplicate detection query); `import_lacounty_officials.py` with documented manifest JSON format for future county expansions.
**Addresses:** Politician gap-fill for supervisors and LA City council from FEATURES.md P1 list; Pitfall 5 (deduplication).
**Avoids:** Inserting politicians before verifying no matching record exists by normalized name + district; using staging module (`/staging/*`) for bulk import (it lacks `external_id`-keyed deduplication at scale).

### Phase 7: End-to-End Validation and VACUUM ANALYZE

**Rationale:** A full-stack test with real LA County addresses confirms the pipeline produced correct results before declaring the milestone complete. VACUUM ANALYZE is required for the PostGIS query planner to use the GiST index after bulk inserts.
**Delivers:** `verify_lacounty.py` with address-based point-in-polygon tests; `VACUUM ANALYZE essentials.geofence_boundaries`; confirmed `EXPLAIN ANALYZE` shows Index Scan (not Seq Scan); all items in PITFALLS.md "Looks Done But Isn't" checklist verified green; import pipeline documented as repeatable for future regions.
**Addresses:** Performance trap (missing VACUUM ANALYZE) and UX pitfalls (unincorporated area test, district label patterns) from PITFALLS.md.
**Avoids:** Shipping without confirming the GiST index is active post-bulk-insert; skipping the unincorporated area test (Altadena) that catches boundary bleed-through from adjacent incorporated cities.

### Phase Ordering Rationale

- **Schema before data:** The `(geo_id, mtfcc)` constraint fix is non-negotiable first. Importing any boundary data with the wrong constraint produces silent data loss that is invisible until Phase 5 diagnostic reveals it — by which point fixing the constraint and re-running is extra work.
- **Geofences before politicians:** The diagnostic in Phase 5 uses imported geofences to determine which `geo_id` values need politician records. Doing gap-fill before geofences means building to unknown targets and risks creating districts with placeholder geo_ids that don't match any boundary.
- **Federal/state before local (Phase 3):** These are highest-impact, most likely to have existing BallotReady politician records, and use a single well-tested TIGER FTP source. Delivers visible results fastest.
- **LA County ArcGIS separate from TIGER (Phase 4):** Different source, different integration pattern, different geo_id construction formula. Keeping it isolated reduces debugging surface.
- **Diagnostic before gap-fill (Phase 5 before Phase 6):** The diagnostic determines the exact scope of Phase 6. Without it, gap-fill risks duplicating existing BallotReady records or creating records for districts that don't yet have geofence boundaries.
- **VACUUM ANALYZE last:** Required after all bulk inserts to update PostGIS planner statistics; must come after all import phases are complete.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (LA County ArcGIS):** ArcGIS FeatureServer field names for supervisor district number are unverified — must inspect the actual endpoint response (`?outFields=*&f=geojson&resultRecordCount=1`) before building geo_id construction. Expected to be `SUPERVISORIAL_DISTRICT` or similar but requires runtime confirmation. MEDIUM confidence.
- **Phase 6 (Politician gap-fill, X0001 geo_id format):** The exact `geo_id` format stored by BallotReady for LA City council members must be queried from `essentials.districts` before constructing geo_ids for new records. The 12-character format from Bloomington (`{7-digit place FIPS}{5-digit ward}`) is the inferred standard but must be verified against actual LA City data in the DB.

Phases with standard patterns (skip deeper research):
- **Phase 1 (Schema fixes):** Verified SQL patterns; `ST_Covers` vs `ST_Contains` is a known, documented PostGIS difference; MTFCC codes sourced from Census official documentation.
- **Phase 2 (Utils scaffolding):** Extract existing patterns; no new design decisions required.
- **Phase 3 (TIGER shapefiles):** Census TIGER FTP structure is HIGH confidence; geopandas import pattern is established across 5 existing scripts with no variation needed.
- **Phase 5 (Diagnostic):** All SQL patterns are documented in PITFALLS.md; no research needed.
- **Phase 7 (Validation):** Standard PostGIS diagnostic queries; VACUUM ANALYZE is a known step.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Python + geopandas + SQLAlchemy pattern is production-proven in 5 existing scripts; library versions verified against PyPI release notes and geopandas changelog |
| Features | HIGH | TIGER layer coverage and priority list derived directly from existing MTFCC map in codebase; BallotReady gap identified from code inspection of `handlers.go` and `setup.go` |
| Architecture | HIGH | Existing lookup path inspected in `geofence_lookup.go`; import pipeline follows established `cmd/` and `scripts/` patterns; two-table join mechanics verified from source |
| Pitfalls | HIGH (PostGIS, Supabase) / MEDIUM (ArcGIS field names, dedup at scale) | PostGIS geometry behaviors and Supabase pooler limitations verified against official docs and GDAL issue tracker; ArcGIS field names and rate limits are observed/inferred rather than officially documented |

**Overall confidence:** HIGH

### Gaps to Address

- **ArcGIS FeatureServer field names (Phase 4):** The attribute name for supervisor district number in the LA County eGIS FeatureServer is not verified. Inspect the actual API response before building the import script. This is a 5-minute check but must happen before Phase 4 implementation.

- **Existing geo_id format for LA City council districts (Phase 6):** Before building X0001 geo_ids for LA City council members, query `SELECT geo_id, district_type FROM essentials.districts WHERE state = 'CA' AND district_type = 'LOCAL'` to confirm exact format. The Bloomington 12-character format is inferred as the standard.

- **Federal/state politician coverage verification (Phase 5):** Research assumes federal and state CA politicians exist in the DB from BallotReady cache warming. Verify at Phase 5 start with: `SELECT district_type, COUNT(*) FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON o.district_id = d.id WHERE d.state = 'CA' GROUP BY district_type`. If counts are zero or low, Phase 6 scope expands significantly.

- **LA County school district GEOID alignment:** TIGER UNSD GEOIDs for LA County school districts must align with any existing `districts.geo_id` values in the DB. If BallotReady never fetched school board data for CA, importing G5420 geofences will have no matching district rows and Phase 6 scope expands to include school board member records (hundreds of records — currently deferred to v1.6.x).

## Sources

### Primary (HIGH confidence)
- `EV-Backend/internal/essentials/geofence_lookup.go` — MTFCC-to-district-type map, `FindGeoIDsByPoint`, `FindPoliticiansByGeoMatches`, `ST_Contains` bug location
- `EV-Backend/internal/essentials/geofence_models.go` — `GeofenceBoundary` struct, geo_id unique constraint note ("managed manually")
- `EV-Backend/internal/essentials/models.go` — `Politician`, `District`, `Office` models; `external_id` uniqueIndex
- `EV-Backend/internal/essentials/setup.go` — GiST index creation, PostGIS extension initialization
- `EV-Backend/scripts/import_ca_legislative_geofences.py` — established Python + geopandas import pattern
- `EV-Backend/scripts/promote_scraped_officials.py` — established dedup pattern with synthetic external_id
- `https://www2.census.gov/geo/tiger/TIGER2024/` — Census TIGER FTP directory structure and shapefile naming conventions
- `https://arcgis.gis.lacounty.gov/arcgis/rest/services/LACounty_Dynamic/Political_Boundaries/MapServer/27` — Supervisorial Districts endpoint verified February 2026
- `https://dpw.gis.lacounty.gov/dpw/rest/services/CityBoundaries/MapServer` — City boundaries polygon service verified February 2026
- Census TIGER 2024 Technical Documentation Appendix E — authoritative MTFCC code definitions
- PostGIS docs: ST_MakeValid, ST_IsValid, ST_Covers vs ST_Contains semantics, GiST indexing
- Supabase docs: direct connection vs pooler (port 5432 vs 6543), prepared statement limitations in transaction mode

### Secondary (MEDIUM confidence)
- `https://egis-lacounty.hub.arcgis.com/` — LA County Enterprise GIS Hub; dataset URLs confirmed, field names unverified without direct API call
- `https://geohub.lacity.org/datasets/76104f230e384f38871eb3c4782f903d_13/about` — LA City GeoHub council districts; ArcGIS FeatureServer pattern standard, specific field names need runtime verification
- GDAL GitHub issue #6340 — `-makevalid` GeometryCollection behavior in GDAL < 3.5
- Crunchy Data: PostGIS performance, ST_MakeValid, loading data overview
- OpenSanctions deduplication article — multi-source record deduplication patterns
- Phase 31 SUMMARY and RESEARCH docs — Bloomington ArcGIS FeatureServer pattern, ST_MakeValid precedent, X0001 geo_id format verification

### Tertiary (LOW confidence)
- LA County GIS Hub rate limits — observed behavior only; no official documentation; paginate with `resultOffset` as a precaution
- School board member existence in BallotReady import — assumed absent based on BallotReady's historical focus on election candidates rather than current officeholders; must be verified by querying the DB

---
*Research completed: 2026-02-23*
*Ready for roadmap: yes*
