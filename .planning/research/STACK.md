# Stack Research — v1.6 LA County Full Coverage

**Domain:** Civic engagement platform — geofence expansion and politician data pipeline
**Researched:** 2026-02-23
**Confidence:** HIGH

---

## Scope

This document covers only *new or changed* stack decisions for v1.6. The existing stack (Go 1.24.3 + Chi + GORM + PostgreSQL/PostGIS, React 19 + Vite + Tailwind, Python import scripts) is retained as-is. Research focuses on four areas:

1. Bulk TIGER shapefile import into PostGIS
2. LA County GIS Portal API/data access
3. Politician record creation with deduplication against existing `external_id`-keyed records
4. Repeatable import pipeline tooling

---

## 1. TIGER Shapefile Import Pipeline

### Current State

The project already has working shapefile import scripts in `EV-Backend/scripts/`:

| Script | Status | What it does |
|--------|--------|--------------|
| `import_shapefiles_fixed.py` | Working, production-proven | Downloads TIGER shapefiles, reprojects to EPSG:4326, calls `gdf.to_postgis()` |
| `import_ca_legislative_geofences.py` | Working, production-proven | CA congressional + state legislative districts with OCD-ID generation |
| `import_missing_geofences.py` | Working, production-proven | IN SLDL + CD with upsert conflict handling |
| `import_shapefiles.sh` | Superseded | Uses `ogr2ogr` into a staging table; replaced by Python scripts |

The Python approach (`geopandas` + `SQLAlchemy` + `to_postgis()`) is the established pattern. **Do not switch to `ogr2ogr` or introduce a Go-based shapefile reader.**

### Stack Decision: Keep Python + GeoPandas + SQLAlchemy

**Confidence: HIGH**

GeoPandas 1.1.2 (current stable, PyPI) is the correct choice because:
- `to_postgis()` handles EPSG reprojection, geometry type promotion, and schema-qualified table names in one call
- `gdf.read_file()` handles shapefile, GeoJSON, and ArcGIS FeatureServer GeoJSON in a single API
- Already in use across 5 existing scripts — no new learning curve
- `sqlalchemy.create_engine()` with psycopg2 is the battle-tested pattern; the existing scripts already handle URL-encoding of special characters in Supabase passwords

**Why not `ogr2ogr` (shell):** The bash script in `import_shapefiles.sh` used `ogr2ogr` into a staging table then ran a SQL migration. This adds complexity (two-step import), requires GDAL installed on the developer machine, and lacks the per-record duplicate handling the Python scripts implement. The Python scripts supersede it.

**Why not a Go CLI for shapefiles:** There is no mature Go shapefile library that integrates cleanly with PostGIS. The `github.com/jonas-p/go-shp` package exists but lacks CRS reprojection and PostGIS geometry encoding. Adding a Go CLI for shapefile import would require wrapping GDAL via cgo. Python + GeoPandas is a complete, maintained solution.

### Required Python Libraries

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `geopandas` | `1.1.2` | Read shapefiles/GeoJSON, reproject, write to PostGIS | Latest stable; requires Python 3.10+ |
| `SQLAlchemy` | `2.0.46` | Database engine for `to_postgis()` | `2.0.x` required; `2.1.0b1` is beta |
| `psycopg2-binary` | `2.9.x` | PostgreSQL adapter | `-binary` variant avoids libpq compile dependency |
| `requests` | `2.32.x` | Download Census files, ArcGIS FeatureServer GeoJSON | Already used in existing scripts |
| `shapely` | `2.0.x` | Geometry validation (`ST_MakeValid` equivalent) | Pulled in automatically by geopandas |

### TIGER Shapefile Coverage for LA County

The following Census TIGER files are needed for full LA County coverage. The existing `import_ca_legislative_geofences.py` already handles congressional + state legislative districts. Remaining gaps:

| TIGER File | MTFCC | What it covers | Census URL pattern |
|-----------|-------|----------------|--------------------|
| Counties | `G4020` | LA County boundary | `TIGER2024/COUNTY/tl_2024_us_county.zip` |
| Unified School Districts | `G5420` | LAUSD + other unified districts | `TIGER2024/UNSD/tl_2024_06_unsd.zip` |
| Congressional Districts (119th) | `G5200` | All CA CDs | `TIGER2024/CD/tl_2024_06_cd119.zip` |
| State Senate (SLDU) | `G5210` | CA Senate districts | `TIGER2024/SLDU/tl_2024_06_sldu.zip` |
| State Assembly (SLDL) | `G5220` | CA Assembly districts | `TIGER2024/SLDL/tl_2024_06_sldl.zip` |

The CA legislative and congressional TIGER files are **already imported** per v1.5 work. The county boundary and school district TIGER files need to be verified and imported if missing.

**City boundary coverage** is NOT available via TIGER at the granularity needed for LA County city council districts. LA County has 88 incorporated cities each with their own city council. The TIGER `PLACE` layer (G4110) provides incorporated place boundaries but does **not** give city council ward sub-districts — those require the LA County GIS Portal (see Section 2).

### Installation

```bash
pip install geopandas==1.1.2 SQLAlchemy==2.0.46 psycopg2-binary requests shapely
```

Or add to a `requirements.txt` in `EV-Backend/scripts/`:

```
geopandas==1.1.2
SQLAlchemy==2.0.46
psycopg2-binary>=2.9
requests>=2.32
shapely>=2.0
```

---

## 2. LA County GIS Portal Data Access

### Available Endpoints (Verified)

LA County maintains ArcGIS REST services at `arcgis.gis.lacounty.gov`. The relevant layers are:

| Dataset | Endpoint | Layer ID | Format |
|---------|----------|----------|--------|
| Supervisorial Districts (Current) | `https://arcgis.gis.lacounty.gov/arcgis/rest/services/LACounty_Dynamic/Political_Boundaries/MapServer/27/query` | 27 | GeoJSON (with `?f=geojson&outSR=4326&where=1=1`) |
| City Boundaries (polygons) | `https://dpw.gis.lacounty.gov/dpw/rest/services/CityBoundaries/MapServer/0/query` | 0 | GeoJSON |
| School District Boundaries (LACOE) | `https://egis2.lacounty.gov/arcgis/rest/services/LACOE/HARS/MapServer` | varies | GeoJSON |

**Critical note on Supervisorial Districts:** The Political_Boundaries MapServer at layer 27 uses California State Plane Coordinate System, Zone 5 (EPSG:2229), **not** WGS84. Always pass `outSR=4326` in the query parameters to get WGS84 output. Failure to specify `outSR=4326` will produce coordinates in US survey feet that will silently corrupt the PostGIS geometry.

**Critical note on record limits:** ArcGIS FeatureServer/MapServer services impose a `maxRecordCount` (typically 1000). LA County has 88 incorporated cities — this fits within a single request. But school districts may require pagination. Use `resultOffset` and `resultRecordCount` parameters for pagination when needed.

### Stack Decision: `requests` + `geopandas.GeoDataFrame.from_features()` for ArcGIS Data

**Confidence: HIGH**

Pattern already established by `import_school_board_districts.py`:

```python
import requests
import geopandas as gpd

url = (
    "https://arcgis.gis.lacounty.gov/arcgis/rest/services/"
    "LACounty_Dynamic/Political_Boundaries/MapServer/27/query"
    "?where=1%3D1&outFields=DISTRICT,LABEL&outSR=4326&f=geojson"
)
resp = requests.get(url)
gdf = gpd.read_file(resp.text)  # or gpd.GeoDataFrame.from_features(resp.json()['features'])
```

`geopandas.read_file()` can read a GeoJSON string or URL directly. No additional ArcGIS SDK needed.

**Why not the ArcGIS Python API (`arcgis` package):** The `arcgis` package is Esri's official SDK but requires authentication for many operations, adds a large dependency (~50MB), and is overkill for read-only GeoJSON queries. The `requests` + `read_file()` pattern is simpler and already proven in the codebase.

### MTFCC Codes for LA County GIS Data

LA County GIS Portal data does **not** use MTFCC codes — those are TIGER-specific. The import pipeline must assign MTFCC codes manually when inserting into `essentials.geofence_boundaries`:

| Source | What it represents | Assign MTFCC | District type |
|--------|-------------------|--------------|---------------|
| Supervisorial Districts | Board of Supervisors districts (5 districts) | `G4020` | `COUNTY` |
| City Boundaries | Incorporated city polygons (88 cities) | `G4110` | `LOCAL_EXEC` |
| City Council Districts | Sub-district wards within cities | `X0001` | `LOCAL` |
| School District Boundaries | LAUSD + unified districts | `G5420` | `SCHOOL` |

**The `geo_id` field** must be set consistently. For supervisorial districts, use `06037SD{N}` format (e.g., `06037SD1`). For city boundaries, prefer Census GEOID (FIPS) if available from the ArcGIS source; fall back to `lacounty_city_{id}` if not. Consistency matters because `essentials.districts.geo_id` must match `essentials.geofence_boundaries.geo_id` for the lookup to work.

### No New Libraries Needed for LA County GIS

`requests` is already in use across existing scripts. `geopandas.read_file()` already handles GeoJSON. No new Python packages are required.

---

## 3. Politician Record Creation with Deduplication

### Current Deduplication Approach

The codebase has an established pattern in `promote_scraped_officials.py`:

1. Scrape or import raw officials into `essentials.scraped_officials` staging table
2. Run name-matching against `essentials.politicians` (exact → likely → possible → none)
3. For matched records: update existing district `geo_id` and `mtfcc` fields
4. For unmatched records: create new politicians, offices, districts with synthetic `external_id` (negative integers starting at -100001)
5. Mark scraped records as `promoted`

This pattern is correct. **Do not replace it.** The key insight is that `external_id` is the primary deduplication key — it comes from BallotReady and is globally unique. For locally-created records (from scraping/GIS), negative synthetic `external_id` values avoid collision.

### Stack Decision: psycopg2 with `ON CONFLICT DO NOTHING` / `DO UPDATE`

**Confidence: HIGH**

For the geofence import pipeline, use `psycopg2.extras.execute_values()` for bulk upserts:

```python
from psycopg2.extras import execute_values

# Upsert geofence boundaries (conflict on geo_id + mtfcc)
execute_values(cur, """
    INSERT INTO essentials.geofence_boundaries
        (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
    VALUES %s
    ON CONFLICT (geo_id, mtfcc) DO UPDATE SET
        geometry = EXCLUDED.geometry,
        name = EXCLUDED.name,
        imported_at = EXCLUDED.imported_at
""", rows)
```

For politician records, use `ON CONFLICT (external_id) DO NOTHING` to preserve existing BallotReady data:

```python
execute_values(cur, """
    INSERT INTO essentials.politicians
        (id, external_id, first_name, last_name, full_name, party, source, ...)
    VALUES %s
    ON CONFLICT (external_id) DO NOTHING
""", rows)
```

**Why `DO NOTHING` for politicians:** BallotReady-sourced records are richer (photos, bio, experience) than scraped records. If a politician already exists from BallotReady, the scraped data should not overwrite it.

**Why `execute_values` not `to_postgis`:** `to_postgis()` is ideal for geometry data (handles WKB encoding automatically). For non-geometry politician records, `execute_values()` is faster, more explicit about conflict handling, and easier to audit.

### Required psycopg2 Usage Pattern

The existing scripts use a consistent URL-encoding pattern for Supabase passwords containing special characters:

```python
from urllib.parse import urlparse, quote_plus, urlunparse

def get_engine():
    raw_url = os.getenv("DATABASE_URL")
    parsed = urlparse(raw_url)
    if parsed.password:
        encoded_pw = quote_plus(parsed.password)
        netloc = f"{parsed.username}:{encoded_pw}@{parsed.hostname}"
        if parsed.port:
            netloc += f":{parsed.port}"
        safe_url = urlunparse((parsed.scheme, netloc, parsed.path,
                               parsed.params, parsed.query, parsed.fragment))
    else:
        safe_url = raw_url
    return create_engine(safe_url)
```

Every new import script must use this pattern. Supabase connection strings contain `@` in the password, which breaks naive URL parsing.

### Synthetic External ID Strategy

For records created from GIS/scrape sources (not BallotReady), use negative integers:

```python
EXT_ID_COUNTER = -200001  # Start at -200001 for v1.6 (v1.5 used -100001)

def next_ext_id():
    global EXT_ID_COUNTER
    val = EXT_ID_COUNTER
    EXT_ID_COUNTER -= 1
    return val
```

Using a new starting range (-200001) avoids collisions with any synthetic IDs created during the `promote_scraped_officials.py` run in v1.5.

---

## 4. Repeatable Import Pipeline Tooling

### Current Pipeline Structure

The existing scripts are standalone one-off importers. The v1.6 goal is a repeatable pipeline for future regional expansion. The architecture should remain **a collection of Python scripts** — not a Go CLI, not a Makefile-based build system, not a scheduled job system.

Rationale: The team is 2-3 devs. Scripts are easier to audit, modify, and re-run selectively than compiled CLI tools or workflow systems. The import pipeline runs maybe quarterly — not a production hot path.

### Recommended Structure for v1.6

```
EV-Backend/scripts/
├── requirements.txt          # Pin all Python dependencies
├── utils.py                  # Shared: get_engine(), load_env(), next_ext_id(), import_individually()
├── import_tiger_ca.py        # TIGER shapefiles for California (already largely done)
├── import_lacounty_gis.py    # LA County GIS Portal: supervisor districts, city boundaries
├── import_lacounty_officials.py  # Politician records from lavote.gov scraper output
├── promote_officials.py      # Deduplication and promotion to essentials schema
└── verify_lacounty.py        # Point-in-polygon verification for test addresses
```

The key structural improvement over the current state is a shared `utils.py`. All scripts currently duplicate the `get_engine()` / `load_env()` / URL-encoding logic. Extract into a single module.

### Stack Decision: Shared `utils.py`, No New Frameworks

**Confidence: HIGH**

Do not add:
- `click` or `argparse` CLI frameworks — the existing `argparse` usage in `lavote_scraper.py` is sufficient
- `luigi`, `prefect`, `airflow` task scheduling — way too heavy for a quarterly one-off import
- `alembic` migrations for schema changes — GORM AutoMigrate handles schema in Go
- `poetry` or `pipenv` — a plain `requirements.txt` with pinned versions is sufficient for a 5-file script collection

### `.env.local` Autodiscovery Pattern

Every script should auto-discover `DATABASE_URL` from `../.env.local` (the EV-Backend root env file). This pattern is already in `import_ca_legislative_geofences.py` and `promote_scraped_officials.py`:

```python
def load_env():
    if os.getenv("DATABASE_URL"):
        return
    env_path = Path(__file__).parent.parent / ".env.local"
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith("DATABASE_URL="):
                    os.environ["DATABASE_URL"] = line.split("=", 1)[1]
                    return
    print("Error: DATABASE_URL not set and .env.local not found")
    sys.exit(1)
```

Every new script must include this function verbatim (or import from `utils.py` once that exists).

---

## Recommended Stack (New Additions Only)

### Core Technologies

No new core technologies. The import pipeline is Python scripts that connect to the existing PostgreSQL/PostGIS database.

### Supporting Libraries (Import Pipeline)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `geopandas` | `1.1.2` | Read shapefiles, GeoJSON; reproject; write to PostGIS | All geometry imports (TIGER + ArcGIS GeoJSON) |
| `SQLAlchemy` | `2.0.46` | Engine for `to_postgis()` | Geometry imports only; use raw psycopg2 for politician records |
| `psycopg2-binary` | `>=2.9` | Direct DB operations, bulk upserts | Politician/district/office record creation |
| `requests` | `>=2.32` | Download TIGER ZIPs, fetch ArcGIS GeoJSON | All HTTP downloads |
| `shapely` | `>=2.0` | Geometry validation, `ST_MakeValid` equivalent | When ArcGIS data has geometry errors (call `.buffer(0)` to fix) |
| `beautifulsoup4` | `>=4.12` | HTML parsing for lavote.gov scraper | Already in use; only for scraper scripts |

No new Go packages needed. No new npm packages needed. No changes to the existing Go backend for geofence data loading.

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| Python `geopandas` scripts | Go CLI with CGO + GDAL | No mature Go shapefile library; CGO introduces build complexity; GDAL dependency on the machine anyway |
| Python `geopandas` scripts | `ogr2ogr` shell scripts | Two-step import (staging → final); requires GDAL; lacks per-record conflict handling; already superseded |
| `psycopg2` + `execute_values` for politician records | `to_postgis()` for all data | `to_postgis()` doesn't support `ON CONFLICT`; upsert logic requires raw SQL |
| `requirements.txt` with pinned versions | `poetry`/`pipenv` | Import scripts are not a Python package; lockfile tooling adds overhead for 5 scripts run quarterly |
| ArcGIS REST GeoJSON via `requests` | `arcgis` Python package | Esri SDK is 50MB, requires authentication tokens, overkill for read-only GeoJSON queries |
| Negative synthetic `external_id` values | UUID-based identifiers | `external_id` is INT in the schema; maintaining int type avoids schema changes |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `ogr2ogr` (GDAL CLI) | Requires system GDAL install; staging table pattern; superseded by Python scripts | `geopandas.to_postgis()` |
| `arcgis` Python SDK | 50MB dependency; auth required; overkill for GeoJSON reads | `requests` + `geopandas.read_file()` |
| `luigi`/`prefect`/`airflow` | Heavy task orchestration for a quarterly one-off import | Plain Python scripts with shared `utils.py` |
| `alembic` migrations | Schema managed by GORM AutoMigrate in Go server | Keep GORM AutoMigrate; script-only schema changes via `db.Exec()` |
| Any new Go packages | No Go code needed for data import | All import work stays in Python scripts |
| `geoalchemy2` directly | Only needed if writing raw geometry SQL; `to_postgis()` handles it | `geopandas.to_postgis()` uses it internally |
| TIGER `PLACE` for LA city council | TIGER provides city *boundaries*, not city *council ward sub-districts* | LA County eGIS ArcGIS FeatureServer per city |

---

## Stack Patterns by Use Case

**If importing TIGER shapefiles (congressional, state legislative, county, school):**
- Use `geopandas.read_file(shp_path)` to load
- Filter by `STATEFP == '06'` (California)
- Reproject with `.to_crs("EPSG:4326")` if not already WGS84
- Assign `mtfcc` from the TIGER filename/field
- Generate OCD-ID from GEOID using the established `geoid_to_ocd_id()` pattern in `import_ca_legislative_geofences.py`
- Call `gdf.to_postgis("geofence_boundaries", engine, schema="essentials", if_exists="append")`
- Handle `UniqueViolation` by falling back to `import_individually()` (already in 3 scripts)

**If importing LA County GIS Portal data (supervisor districts, city boundaries):**
- Fetch with `requests.get(url + "?where=1%3D1&outSR=4326&f=geojson")`
- Parse with `gpd.read_file(resp.text)` or `gpd.GeoDataFrame.from_features(resp.json()['features'])`
- Manually assign `mtfcc` based on the layer type (G4020 for supervisorial, G4110 for city boundaries)
- Generate a consistent `geo_id` (e.g., `06037SD1` for Supervisor District 1)
- Import via `to_postgis()` with `if_exists="append"`
- Handle `outSR=4326` — the Political_Boundaries MapServer uses CA State Plane (EPSG:2229) by default; **always** pass `outSR=4326`

**If creating politician records from scraped/GIS data:**
- Always check for `external_id` conflict first
- Use negative synthetic `external_id` starting at -200001 (not -100001, already used in v1.5)
- Use `psycopg2.extras.execute_values()` with `ON CONFLICT (external_id) DO NOTHING`
- Always link district `geo_id` to a corresponding `geofence_boundaries.geo_id` (import geofences first)
- Mark with `source = 'scraped'` or `source = 'lacounty_gis'` for auditability

---

## Version Compatibility

| Package | Version | Compatible With | Notes |
|---------|---------|-----------------|-------|
| `geopandas` | `1.1.2` | `SQLAlchemy 2.0.x` | geopandas 1.1 raised minimum tested SA to 2.0 |
| `geopandas` | `1.1.2` | `psycopg2 2.9.x` | Supports both psycopg2 and psycopg (v3) |
| `SQLAlchemy` | `2.0.46` | `psycopg2-binary 2.9.x` | psycopg2 remains default dialect for `postgresql://` URLs in SA 2.0 |
| `SQLAlchemy` | `2.0.46` | `geopandas 1.1.2` | SA 2.1 is beta only; use 2.0.46 |
| `shapely` | `2.0.x` | `geopandas 1.1.2` | geopandas 1.x requires shapely 2.x |
| `psycopg2-binary` | `2.9.x` | `PostgreSQL 15` (Supabase) | -binary avoids libpq compile; works for import scripts |

---

## LA County GIS Portal — Verified Endpoints

| Dataset | URL | Notes |
|---------|-----|-------|
| Supervisorial Districts (Current) | `https://arcgis.gis.lacounty.gov/arcgis/rest/services/LACounty_Dynamic/Political_Boundaries/MapServer/27/query?where=1%3D1&outFields=DISTRICT,LABEL&outSR=4326&f=geojson` | 5 districts; default CRS is EPSG:2229 — always add `outSR=4326` |
| City Boundaries (polygons) | `https://dpw.gis.lacounty.gov/dpw/rest/services/CityBoundaries/MapServer/0/query?where=1%3D1&outSR=4326&f=geojson` | 88 incorporated cities; maintained by LA County DPW |
| School Districts (LACOE) | `https://egis2.lacounty.gov/arcgis/rest/services/LACOE/HARS/MapServer` | Multiple layers; verify active layer ID before importing |

These endpoints were verified February 2026 (HIGH confidence — confirmed via direct ArcGIS REST API responses).

---

## Integration with Existing Go/PostGIS Stack

No changes to the Go backend are needed for this milestone. The import pipeline writes directly to the same `essentials.geofence_boundaries` and `essentials.politicians` tables that the Go backend reads from.

The existing `FindGeoIDsByPoint()` and `FindPoliticiansByGeoMatches()` in `geofence_lookup.go` will automatically return LA County officials once:
1. Geofence boundaries are imported (geofence_boundaries rows with correct geo_id + mtfcc)
2. Politician records exist (politicians + offices + districts rows with matching geo_id on districts)

The `mtfccToDistrictTypes` map in `geofence_lookup.go` already handles the MTFCC codes needed:

```go
"G4020": {"COUNTY", "JUDICIAL"},    // County — Supervisorial districts
"G4110": {"LOCAL", "LOCAL_EXEC"},   // Incorporated Place — City boundaries
"G5420": {"SCHOOL"},                // Unified School District
"X0001": {"LOCAL"},                 // City council sub-districts
```

No Go code changes are needed unless a new MTFCC is introduced.

---

## Sources

- `EV-Backend/scripts/import_ca_legislative_geofences.py` — established Python + geopandas import pattern, HIGH confidence
- `EV-Backend/scripts/promote_scraped_officials.py` — established dedup pattern, HIGH confidence
- `EV-Backend/internal/essentials/geofence_lookup.go` — MTFCC → district_type mapping, HIGH confidence
- [GeoPandas 1.1.2 changelog](https://geopandas.org/en/stable/docs/changelog.html) — current stable release February 2026, HIGH confidence
- [geopandas.GeoDataFrame.to_postgis docs](https://geopandas.org/en/stable/docs/reference/api/geopandas.GeoDataFrame.to_postgis.html) — requires SQLAlchemy 2.0 + psycopg2, HIGH confidence
- [SQLAlchemy releases](https://github.com/sqlalchemy/sqlalchemy/releases) — 2.0.46 current stable January 2026, HIGH confidence
- [arcgis.gis.lacounty.gov Political_Boundaries MapServer/27](https://arcgis.gis.lacounty.gov/arcgis/rest/services/LACounty_Dynamic/Political_Boundaries/MapServer/27) — Supervisorial Districts endpoint verified, HIGH confidence
- [dpw.gis.lacounty.gov CityBoundaries MapServer](https://dpw.gis.lacounty.gov/dpw/rest/services/CityBoundaries/MapServer) — City boundaries polygon service, HIGH confidence
- [psycopg2 docs execute_values](https://www.psycopg.org/docs/) — psycopg2 2.9.11 current stable, HIGH confidence
- Census TIGER/Line FTP `https://www2.census.gov/geo/tiger/TIGER2024/` — directory structure verified, HIGH confidence

---

*Stack research for: v1.6 LA County Full Coverage — geofence expansion and politician data pipeline*
*Researched: 2026-02-23*
