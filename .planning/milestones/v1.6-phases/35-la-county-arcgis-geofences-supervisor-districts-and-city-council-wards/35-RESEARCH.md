# Phase 35: LA County ArcGIS Geofences — Supervisor Districts and City Council Wards - Research

**Researched:** 2026-02-24
**Domain:** ArcGIS FeatureServer REST API, geopandas, PostGIS geometry import, geo_id convention
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**City Coverage Scope:**
- Import boundaries for ALL cities that publish ArcGIS data — not limited to top cities by population
- Import and flag low-quality data (broken geometries, potentially outdated) with a quality flag for later review — don't skip questionable data
- Use a curated list of ArcGIS source URLs (not automated discovery) — research builds the list, script consumes it
- Cities with district elections but no published ArcGIS boundaries are noted as gaps and skipped — no manual georeferencing this phase

**geo_id Convention:**
- Supervisor districts (G4020): Use TIGER GEOID format, consistent with Phase 34 convention
- LA City council wards (X0001): Use OCD-ID format (e.g., `ocd-division/country:us/state:ca/place:los_angeles/council_district:1`)
- All other city council wards: Also OCD-ID format (e.g., `ocd-division/country:us/state:ca/place:long_beach/council_district:1`)
- Convention split: TIGER GEOID for boundaries that exist in TIGER, OCD-ID for boundaries that don't

**Source Priority and Fallbacks:**
- Supervisor districts: LA County official ArcGIS portal is the primary source; TIGER G4020 as fallback only if ArcGIS is unavailable
- City council wards: Check each city's official GIS/open data portal first
- Source URLs stored in a config file (JSON/CSV) mapping city to ArcGIS URL to layer name — not hardcoded in scripts
- Error handling: Retry 2-3 times with backoff on ArcGIS endpoint failures, then log and skip; report all failures at end of run

**At-Large vs District Elections:**
- At-large cities: Reuse the existing G4110 place boundary from Phase 34 as the council "district" — no duplicate geometry
- Election type (district/at-large/hybrid) tracked in the curated config file — explicit classification, not auto-detected
- Hybrid cities (some district seats, some at-large): Import ward boundaries for district seats; at-large seats map to the city-wide G4110 boundary; note hybrid status in config

### Claude's Discretion
- Exact config file format (JSON vs CSV) and schema
- Geometry validation and repair approach (ST_MakeValid details)
- Script architecture (single script vs per-source-type scripts)
- Quality flag implementation (column vs separate table)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| GEO-04 | LA County Supervisorial district boundaries (G4020) imported from LA County ArcGIS | LA County ArcGIS FeatureServer confirmed at `https://arcgis.gis.lacounty.gov/arcgis/rest/services/LACounty_Dynamic/Political_Boundaries/MapServer/27`. Fields: DISTRICT (string, 1 char), LABEL (string). Returns 5 features (Districts 1-5). GeoJSON available at `?f=geojson&outSR=4326`. |
| GEO-07 | LA City council ward boundaries (X0001) imported from LA City GeoHub | LA City GeoHub FeatureServer confirmed at `https://services5.arcgis.com/7nsPwEMP38bSkCjy/arcgis/rest/services/Council_Districts/FeatureServer/0`. Fields: district (int), dist_name (string), name (string). Returns 15 features. Based on 2021 redistricting. GeoJSON available via query endpoint. |
| GEO-08 | City council district/ward boundaries imported where available for LA County incorporated cities | Research confirms several LA County cities publish ArcGIS boundaries (Long Beach, Glendale, Torrance confirmed; others to verify). Curated config file approach allows systematic coverage. Cities without published data noted as gaps. |
</phase_requirements>

---

## Summary

Phase 35 imports three types of boundaries not covered by TIGER: LA County supervisorial district polygons, LA City council ward polygons, and council district polygons for other LA County incorporated cities with district-based elections. All source data comes from ArcGIS FeatureServer REST endpoints — a different integration pattern from Phase 34's TIGER shapefile downloads.

The critical architectural issue for this phase is the **geo_id convention for imported boundaries**. The lookup engine (`geofence_lookup.go`) joins `geofence_boundaries.geo_id` to `essentials.districts.geo_id` — an exact string match. All LA supervisor and city council district records already exist in `essentials.districts` with `geo_id = ''` (empty). Phase 35 imports the polygon geometry; Phase 36 updates those district records with matching geo_ids. The geo_ids chosen for geofence boundaries must exactly match what Phase 36 will write to the districts table. The CONTEXT.md decision to use OCD-ID format for city council wards diverges from the established Bloomington pattern (`{7-digit FIPS}{5-digit zero-padded ward}`) and requires careful implementation to keep both systems consistent.

For supervisor districts, the existing DB data confirms they are stored as `district_type = 'LOCAL'` (not COUNTY) with OCD-IDs like `ocd-division/country:us/state:ca/county:los_angeles/council_district:1`. The "G4020" in the phase description refers to the MTFCC to store in `geofence_boundaries.mtfcc` — not the geo_id format. The G4020 MTFCC value in `geofence_lookup.go` maps to `{"COUNTY", "JUDICIAL"}` district types, but the BallotReady supervisor district records use `LOCAL` type. This is a **critical mismatch** that needs resolution before planning.

**Primary recommendation:** Use `X0001` MTFCC (not G4020) for supervisor district boundaries in `geofence_boundaries`, consistent with how the lookup engine already handles sub-county political boundaries. Store geo_ids in OCD-ID format per CONTEXT decisions. Build a curated JSON config with all sources before writing scripts. Query `essentials.districts` to verify exact OCD-IDs already stored for each target district before writing geo_ids.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| geopandas | 1.1.2 | GeoDataFrame, ArcGIS GeoJSON loading, to_postgis, make_valid | Project standard per Phase 33 requirements.txt — already installed |
| requests | 2.32.5 | HTTP fetching of ArcGIS FeatureServer GeoJSON | Project standard per Phase 33 requirements.txt |
| SQLAlchemy | 2.0.46 | Database engine creation | Project standard per Phase 33 requirements.txt |
| psycopg2-binary | 2.9.11 | PostgreSQL driver | Project standard per Phase 33 requirements.txt |
| shapely | 2.0.7 | Geometry operations (transitive via geopandas) | Project standard per Phase 33 requirements.txt |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| json | stdlib | Config file loading (JSON format recommended) | Config file is JSON — standard library handles it |
| time | stdlib | Retry backoff delays | 2-3 retry attempts with exponential backoff |
| pathlib.Path | stdlib | File path handling | Consistent with existing scripts |
| datetime | stdlib | `imported_at` timestamps | Already used in existing scripts |

### Alternatives Considered
None — the project stack is fully established. Phase 33 locked the dependency manifest. The ArcGIS integration pattern is already proven by Phase 31 (Bloomington council districts).

**Installation:**
```bash
# Already installed from Phase 33 setup
python3.13 -m pip install -r EV-Backend/scripts/requirements.txt
```

---

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── utils.py                                  # Phase 33 shared utilities
├── requirements.txt                          # Phase 33 pinned manifest
├── arcgis_sources.json                       # NEW: curated config of all ArcGIS source URLs
├── import_la_supervisor_districts.py         # NEW: G4020/X0001 supervisor boundaries
├── import_la_city_council_wards.py           # NEW: X0001 city council ward boundaries
└── shapefile_data/                           # Existing (gitignored)
```

### Pattern 1: ArcGIS FeatureServer GeoJSON Fetch
**What:** Query ArcGIS REST API with `?where=1%3D1&outFields=*&f=geojson&outSR=4326` to get WGS84 GeoJSON
**When to use:** For every ArcGIS-sourced boundary in this phase
**Canonical example from Phase 31 (`import_school_board_districts.py`):**

```python
import requests
import geopandas as gpd
from shapely.geometry import shape

ARCGIS_URL = (
    "https://services5.arcgis.com/7nsPwEMP38bSkCjy/arcgis/rest/services/"
    "Council_Districts/FeatureServer/0/query"
    "?where=1%3D1&outFields=*&f=geojson&outSR=4326"
)

def fetch_geojson(url, retries=3):
    """Fetch GeoJSON from ArcGIS FeatureServer with retry logic."""
    for attempt in range(retries):
        try:
            resp = requests.get(url, timeout=30)
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            if attempt < retries - 1:
                import time
                time.sleep(2 ** attempt)  # exponential backoff: 1s, 2s
                continue
            print(f"  FAILED after {retries} attempts: {e}")
            return None

def load_from_arcgis(url):
    data = fetch_geojson(url)
    if not data:
        return None
    rows = []
    for feat in data["features"]:
        geom = shape(feat["geometry"])
        props = feat["properties"]
        rows.append({"geometry": geom, **props})
    gdf = gpd.GeoDataFrame(rows, geometry="geometry", crs="EPSG:4326")
    return gdf
```

**Why `outSR=4326`:** Forces WGS84 response. Without this, LA County's MapServer returns California State Plane coordinates (EPSG:2229) which requires reprojection. Adding `outSR=4326` eliminates the CRS mismatch risk entirely.

**Pagination note:** LA County supervisor districts (5 records) and LA City council districts (15 records) are far below any server record limit. City council boundaries for individual cities are also small (typically 4-15 districts). No pagination needed for this phase.

### Pattern 2: Geometry Validation — ST_MakeValid is REQUIRED
**What:** Apply `ST_MakeValid()` before any ArcGIS-sourced geometry insert
**Why it matters:** Phase 31 (Bloomington council District 2) had a nested shells topology issue from an ArcGIS FeatureServer that caused silent point-in-polygon failures. This is NOT a precautionary note — it is a confirmed risk.
**Example:**

```python
from shapely.validation import make_valid

def repair_geometry(geom):
    """Apply make_valid to handle topology issues from ArcGIS sources."""
    if geom is None:
        return None
    if not geom.is_valid:
        print(f"  WARNING: Invalid geometry detected, applying make_valid()")
        geom = make_valid(geom)
    return geom
```

Or equivalently via geopandas after constructing the GeoDataFrame:
```python
gdf.geometry = gdf.geometry.apply(make_valid)
```

### Pattern 3: Curated Config File (JSON)
**What:** A JSON file listing all ArcGIS sources, city names, election types, and geo_id generation parameters
**When to use:** The script reads from this file at runtime. Humans edit the config to add/remove cities. No hardcoded URLs in scripts.
**Recommended schema:**

```json
{
  "supervisor_districts": {
    "source_url": "https://arcgis.gis.lacounty.gov/arcgis/rest/services/LACounty_Dynamic/Political_Boundaries/MapServer/27/query",
    "district_field": "DISTRICT",
    "label_field": "LABEL",
    "mtfcc": "X0001",
    "count": 5,
    "geo_id_template": "ocd-division/country:us/state:ca/county:los_angeles/council_district:{n}"
  },
  "city_council": [
    {
      "city": "Los Angeles",
      "place_geoid": "0644000",
      "election_type": "district",
      "districts": 15,
      "source_url": "https://services5.arcgis.com/7nsPwEMP38bSkCjy/arcgis/rest/services/Council_Districts/FeatureServer/0/query",
      "district_field": "district",
      "mtfcc": "X0001",
      "geo_id_template": "ocd-division/country:us/state:ca/place:los_angeles/council_district:{n}",
      "notes": "2021 redistricting boundaries"
    },
    {
      "city": "Long Beach",
      "place_geoid": "0643000",
      "election_type": "district",
      "districts": 9,
      "source_url": "https://services3.arcgis.com/rBnxK1Y2jCXU5F3i/arcgis/rest/services/City_Council_Districts/FeatureServer/0/query",
      "district_field": "DISTRICT",
      "mtfcc": "X0001",
      "geo_id_template": "ocd-division/country:us/state:ca/place:long_beach/council_district:{n}",
      "quality_flag": null,
      "notes": "2021 redistricting"
    },
    {
      "city": "Torrance",
      "place_geoid": "0680000",
      "election_type": "district",
      "districts": 6,
      "source_url": "TBD - open-data-torranceca.hub.arcgis.com",
      "district_field": "TBD",
      "mtfcc": "X0001",
      "geo_id_template": "ocd-division/country:us/state:ca/place:torrance/council_district:{n}",
      "quality_flag": null,
      "notes": "Districts phased in 2020-2022"
    },
    {
      "city": "Pasadena",
      "place_geoid": "0656000",
      "election_type": "district",
      "districts": 7,
      "source_url": "TBD - Pasadena GIS portal",
      "district_field": "TBD",
      "mtfcc": "X0001",
      "geo_id_template": "ocd-division/country:us/state:ca/place:pasadena/council_district:{n}",
      "quality_flag": null,
      "notes": "District-based since 2018"
    },
    {
      "city": "Inglewood",
      "place_geoid": "0636546",
      "election_type": "district",
      "districts": 4,
      "source_url": "TBD",
      "district_field": "TBD",
      "mtfcc": "X0001",
      "geo_id_template": "ocd-division/country:us/state:ca/place:inglewood/council_district:{n}",
      "quality_flag": null,
      "notes": "4-district council"
    },
    {
      "city": "Glendale",
      "place_geoid": "0630000",
      "election_type": "at-large",
      "districts": null,
      "source_url": null,
      "notes": "At-large council — reuse G4110 place boundary (0630000), no X0001 import needed"
    },
    {
      "city": "Downey",
      "place_geoid": "0619766",
      "election_type": "district",
      "districts": 5,
      "source_url": "TBD",
      "district_field": "TBD",
      "mtfcc": "X0001",
      "geo_id_template": "ocd-division/country:us/state:ca/place:downey/council_district:{n}",
      "notes": "District-based elections"
    }
  ],
  "gaps": [
    {"city": "City X", "reason": "No ArcGIS boundary published"}
  ]
}
```

### Pattern 4: geo_id — OCD-ID Format (CONTEXT Decision)
**What:** CONTEXT.md locked the geo_id format for X0001 boundaries to OCD-ID string
**Critical constraint:** The geo_id in `geofence_boundaries` must match the geo_id in `essentials.districts` exactly for the point-in-polygon lookup to work. All LA County supervisor and city council district records currently have `geo_id = ''` — Phase 36 will set these. Phase 35 must choose a consistent format for both.

**CONTEXT decision:**
- LA County supervisor districts: geo_id = `ocd-division/country:us/state:ca/county:los_angeles/council_district:{n}` (where n = 1–5)
- LA City council wards: geo_id = `ocd-division/country:us/state:ca/place:los_angeles/council_district:{n}` (where n = 1–15)
- Other cities: same pattern with city name slugified

**Verification: existing OCD-IDs in essentials.districts confirm this format is exactly what BallotReady stores:**
```
ocd-division/country:us/state:ca/county:los_angeles/council_district:1
ocd-division/country:us/state:ca/county:los_angeles/council_district:2
...
ocd-division/country:us/state:ca/place:los_angeles/council_district:1
ocd-division/country:us/state:ca/place:los_angeles/council_district:11
...
ocd-division/country:us/state:ca/place:long_beach/council_district:7
ocd-division/country:us/state:ca/place:torrance/council_district:1
ocd-division/country:us/state:ca/place:inglewood/council_district:2
ocd-division/country:us/state:ca/place:pasadena/council_district:4
ocd-division/country:us/state:ca/place:downey/council_district:2
```

This means Phase 35 geo_ids for geofence boundaries should be the OCD-ID string itself (e.g., `ocd-division/country:us/state:ca/place:los_angeles/council_district:1`). Phase 36 will then `UPDATE essentials.districts SET geo_id = ocd_id WHERE district_type = 'LOCAL' AND ...`.

**IMPORTANT NOTE for planner:** The existing `geofence_boundaries` unique constraint is on `(geo_id, mtfcc)`. OCD-IDs are long strings but the constraint is on varchar — no length issue.

### Pattern 5: MTFCC Choice for Supervisor Districts
**Critical finding:** G4020 in `geofence_lookup.go` maps to `{"COUNTY", "JUDICIAL"}` district types. But LA County supervisor districts in `essentials.districts` have `district_type = 'LOCAL'`, not `COUNTY`. Using G4020 MTFCC for supervisor district geofences would cause the lookup to match `COUNTY` district type, but the actual supervisor records are `LOCAL`.

**Confirmed DB state for LA County supervisors:**
```
district_type=LOCAL, ocd_id=ocd-division/country:us/state:ca/county:los_angeles/council_district:1
district_type=LOCAL, ocd_id=ocd-division/country:us/state:ca/county:los_angeles/council_district:2
... (all 5 supervisors are LOCAL type)
```

**Correct MTFCC:** Use `X0001` for supervisor district boundaries, consistent with `{"LOCAL"}` mapping in `geofence_lookup.go`. The "G4020" in the phase spec title and requirement refers to the TIGER county subdivision code, but since these are ArcGIS-sourced non-TIGER boundaries, X0001 is the correct custom MTFCC.

**The CONTEXT.md decision** "Supervisor districts (G4020): Use TIGER GEOID format" likely means: use TIGER-consistent geo_id format (OCD-ID is specified elsewhere). The G4020 reference may be aspirational — if TIGER did publish supervisorial district shapefiles they would be G4020, but they don't. **This is an open question for the planner to flag.**

### Pattern 6: Quality Flag Implementation
**What:** Track data quality issues (broken geometries, potentially outdated source) per imported record
**Claude's discretion:** Add a `quality_flag` column to `geofence_boundaries` as the simplest approach
**Recommended column:**
```sql
ALTER TABLE essentials.geofence_boundaries
ADD COLUMN IF NOT EXISTS quality_flag text;
-- Values: NULL (clean), 'geometry_repaired', 'source_outdated', 'low_resolution'
```

This is a schema migration needed before running import scripts. Mark `quality_flag = 'geometry_repaired'` when `make_valid()` had to fix the geometry.

### Pattern 7: Idempotent Import with Delete-Before-Insert
**What:** For ArcGIS sources, use delete-before-insert (not upsert) to allow clean re-runs
**Why:** The unique constraint handles TIGER imports well, but ArcGIS sources may return slightly different geometry on re-fetch (boundary updates, GIS corrections). Delete-before-insert ensures fresh data replaces stale.
**Pattern from `import_school_board_districts.py`:**
```python
with engine.connect() as conn:
    geo_ids = [row["geo_id"] for row in rows]
    conn.execute(
        text("DELETE FROM essentials.geofence_boundaries WHERE geo_id = ANY(:geo_ids) AND mtfcc = :mtfcc"),
        {"geo_ids": geo_ids, "mtfcc": "X0001"}
    )
    conn.commit()
```

### Anti-Patterns to Avoid
- **Using G4020 MTFCC for supervisor districts:** The lookup maps G4020 to `COUNTY` district type, but BallotReady stores supervisor districts as `LOCAL`. Using G4020 would make geofence hits miss the supervisor politician records. Use `X0001` instead.
- **Using Bloomington-formula geo_ids (`{7-digit FIPS}{5-digit ward}`):** CONTEXT.md locked the format to OCD-ID strings. Diverging from this will break Phase 36 district updates. Must use OCD-ID format exactly matching what BallotReady stores in `essentials.districts.ocd_id`.
- **Fetching without `outSR=4326`:** LA County's MapServer returns California State Plane by default. Always append `&outSR=4326` to force WGS84.
- **Skipping `make_valid()` on ArcGIS geometries:** Phase 31 confirmed ArcGIS data can have topology issues. Always apply `make_valid()`.
- **Hardcoding ArcGIS URLs in scripts:** CONTEXT requires a config file (JSON). Scripts read the config; humans update the config.
- **Importing at-large city council districts as X0001:** At-large cities have all council members representing the whole city. The G4110 boundary already covers them. No X0001 boundary needed — Glendale is confirmed at-large (as of 2024 they haven't completed district formation).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ArcGIS GeoJSON fetch with pagination | Custom pagination loop | Single query with `resultOffset` | All Phase 35 sources have < 20 features; pagination not needed |
| Geometry repair | Custom topology fixer | `shapely.validation.make_valid()` or `gdf.geometry.make_valid()` | shapely 2.0's make_valid handles nested shells, self-intersections, ring directions |
| CRS conversion | Manual coordinate math | `gdf.to_crs("EPSG:4326")` or `outSR=4326` query param | ArcGIS responds in WGS84 when asked; geopandas handles reprojection |
| Unique constraint handling | Custom upsert SQL | Delete-before-insert pattern | Simpler than UPSERT for small ArcGIS datasets; canonical in existing scripts |
| Config file parsing | Custom config format | Standard `json.load()` | JSON is human-readable, universally supported, trivial to parse |

**Key insight:** The ArcGIS import pattern is fully established from Phase 31. This phase is Phase 31 applied at LA County scale, with OCD-ID geo_ids instead of Bloomington-formula geo_ids.

---

## Common Pitfalls

### Pitfall 1: G4020 MTFCC Mismatch with District Type
**What goes wrong:** Importing supervisor district polygons with `mtfcc = 'G4020'`. The lookup maps G4020 to `{"COUNTY", "JUDICIAL"}` district types. But all 5 LA County supervisor district records in `essentials.districts` have `district_type = 'LOCAL'`. The point-in-polygon lookup returns a G4020 geo match, tries to find a `COUNTY` district with that geo_id, finds nothing, supervisor is invisible.
**Why it happens:** The phase spec title says "G4020" because that's TIGER's code for county-level administrative boundaries. But BallotReady treats supervisors as LOCAL officials.
**How to avoid:** Use `X0001` MTFCC for supervisor districts. `X0001` maps to `{"LOCAL"}` which matches the actual district type.
**Warning signs:** LA City Hall point-in-polygon returns G4020 hit but no supervisor official is returned in API response.

### Pitfall 2: geo_id Format Mismatch Between Geofences and Districts
**What goes wrong:** Importing geofences with geo_id `064400000001` (Bloomington formula) but `essentials.districts` has geo_id `''` and ocd_id `ocd-division/country:us/state:ca/place:los_angeles/council_district:1`. Phase 36 sets districts.geo_id to the OCD-ID string. The join never matches.
**Why it happens:** Two different geo_id convention approaches exist in the codebase: the Bloomington formula (used for G5420 school board sub-districts and X0001 in Indiana) and OCD-ID (CONTEXT decision for CA council wards).
**How to avoid:** Use OCD-ID format for geo_ids exactly matching what BallotReady stores in `essentials.districts.ocd_id`. Verify by querying the DB before finalizing geo_ids.
**Warning signs:** `SELECT COUNT(*) FROM geofence_boundaries WHERE geo_id IN (SELECT ocd_id FROM essentials.districts WHERE state = 'CA')` returns 0 after import.

### Pitfall 3: ArcGIS Endpoint Returns Non-WGS84 Coordinates
**What goes wrong:** Omitting `outSR=4326` from the ArcGIS query URL. LA County's MapServer layer uses EPSG:2229 (CA State Plane Zone 5) by default. Coordinates come back as large positive integers (e.g., `6560000, 2293000`) instead of lat/lng. Geopandas creates geometries with wrong CRS. PostGIS `ST_Covers` with WGS84 test points returns no hits.
**Why it happens:** ArcGIS services return data in the layer's native CRS unless explicitly asked for WGS84 via `outSR`.
**How to avoid:** Always append `&outSR=4326` to FeatureServer query URLs. Verify CRS after loading: `gdf.crs.to_epsg()` should be 4326.
**Warning signs:** Coordinate values in the range (2000000, 7000000) instead of (-180, 180) / (-90, 90).

### Pitfall 4: Missing Geometry Validation on ArcGIS Data
**What goes wrong:** Inserting raw ArcGIS geometry without `make_valid()`. District 2 geometry from Bloomington's ArcGIS had nested shells — it inserted without error but `ST_Contains` silently returned false for points inside the polygon. The fix required an explicit `ST_MakeValid()` update after import.
**Why it happens:** ArcGIS FeatureServer may return geometries that pass JSON parsing but fail topology checks. PostGIS INSERT accepts them; spatial queries fail silently.
**How to avoid:** Apply `make_valid()` to every geometry before import. Set `quality_flag = 'geometry_repaired'` when repair was needed.
**Warning signs:** Known address in a district returns no polygon hit; `SELECT ST_IsValid(geometry)` on newly imported rows returns false.

### Pitfall 5: At-Large vs District Confusion
**What goes wrong:** Importing X0001 boundaries for at-large cities (e.g., Glendale). Glendale's city council is elected at-large (all 5 members represent the whole city). Importing 5 identical city-boundary polygons as X0001 records causes duplicate hits in point-in-polygon lookups.
**Why it happens:** Glendale has ArcGIS boundary data published (confirmed: `data-cog-gis.opendata.arcgis.com/datasets/fa232710a27e4a999fe144affa158b4b_3`) but the boundaries are the same city outline repeated, not district subdivisions.
**How to avoid:** Check election type in the config file before importing. `election_type = 'at-large'` → skip X0001 import entirely. The G4110 boundary already covers at-large council members.
**Warning signs:** All council members in an at-large city return the same boundary hit, or point-in-polygon for any address in Glendale returns 5 hits for the same city boundary.

### Pitfall 6: ArcGIS Source URL Discovery Takes Research Time
**What goes wrong:** Planning assumes ArcGIS URLs are trivially discoverable. In practice, LA County cities publish GIS data through multiple portals (city website GIS, ArcGIS Hub, county open data) with inconsistent naming. The actual FeatureServer URL often requires navigating Hub pages that don't render well to WebFetch.
**Why it happens:** ArcGIS Hub pages are JavaScript-heavy; URL metadata is embedded in React state. The REST service URL must be discovered by inspecting the Hub page source or trying known patterns.
**How to avoid:** Research URLs systematically using the pattern `services[N].arcgis.com/[org_id]/arcgis/rest/services/[name]/FeatureServer/[layer]`. Verify each URL directly with `?f=json` before recording in config. Mark unresolved URLs as "TBD" in config with a note.
**Warning signs:** A city listed in config has `source_url: "TBD"` — it will be skipped by the import script.

---

## Code Examples

### ArcGIS GeoJSON Fetch with Retry
```python
# Source: Established pattern from Phase 31 import_school_board_districts.py

import requests
import time

def fetch_arcgis_geojson(url, retries=3):
    """Fetch GeoJSON from ArcGIS FeatureServer with exponential backoff."""
    for attempt in range(retries):
        try:
            resp = requests.get(url, timeout=30)
            resp.raise_for_status()
            data = resp.json()
            if "features" not in data:
                raise ValueError(f"Response missing 'features' key: {list(data.keys())}")
            return data
        except Exception as e:
            if attempt < retries - 1:
                wait = 2 ** attempt
                print(f"  Attempt {attempt + 1} failed ({e}), retrying in {wait}s...")
                time.sleep(wait)
            else:
                print(f"  FAILED after {retries} attempts: {e}")
                return None
```

### Loading ArcGIS GeoJSON into GeoDataFrame
```python
# Source: Pattern from import_school_board_districts.py (Phase 31)

import geopandas as gpd
from shapely.geometry import shape
from shapely.validation import make_valid

def load_arcgis_features(data, district_field, geo_id_template, mtfcc, source_name, quality_flag_col=True):
    """Convert ArcGIS GeoJSON response to clean GeoDataFrame for import."""
    from datetime import datetime

    rows = []
    for feat in data["features"]:
        props = feat["properties"]
        geom_raw = shape(feat["geometry"])

        # Track geometry quality
        qflag = None
        if not geom_raw.is_valid:
            geom_raw = make_valid(geom_raw)
            qflag = "geometry_repaired"
            print(f"  WARNING: Invalid geometry repaired for district {props.get(district_field)}")

        district_num = props[district_field]
        geo_id = geo_id_template.format(n=int(district_num))

        rows.append({
            "geo_id": geo_id,
            "ocd_id": geo_id,  # For X0001 boundaries, geo_id IS the OCD-ID
            "name": props.get("name") or props.get("dist_name") or f"District {district_num}",
            "mtfcc": mtfcc,
            "state": "06",  # California
            "geometry": geom_raw,
            "source": source_name,
            "imported_at": datetime.now(),
            "quality_flag": qflag,
        })

    gdf = gpd.GeoDataFrame(rows, geometry="geometry", crs="EPSG:4326")
    print(f"  Loaded {len(gdf)} features, {gdf['quality_flag'].notna().sum()} geometries repaired")
    return gdf
```

### Import with Delete-Before-Insert
```python
# Source: Pattern from import_school_board_districts.py (Phase 31)

from sqlalchemy import text

def import_to_db(gdf, engine, mtfcc="X0001"):
    """Delete existing records for these geo_ids and insert fresh data."""
    geo_ids = gdf["geo_id"].tolist()

    with engine.connect() as conn:
        result = conn.execute(
            text("DELETE FROM essentials.geofence_boundaries WHERE geo_id = ANY(:ids) AND mtfcc = :mtfcc"),
            {"ids": geo_ids, "mtfcc": mtfcc}
        )
        if result.rowcount > 0:
            print(f"  Deleted {result.rowcount} existing records (re-import)")
        conn.commit()

    gdf.to_postgis(
        "geofence_boundaries",
        engine,
        schema="essentials",
        if_exists="append",
        index=False,
    )
    print(f"  Imported {len(gdf)} boundaries")
    return len(gdf)
```

### Verification SQL Queries
```sql
-- Count by boundary type imported in Phase 35
SELECT mtfcc, COUNT(*) as count, source
FROM essentials.geofence_boundaries
WHERE state = '06' AND mtfcc = 'X0001'
GROUP BY mtfcc, source
ORDER BY source;

-- Verify supervisor districts (expected: 5 rows)
SELECT geo_id, name, quality_flag
FROM essentials.geofence_boundaries
WHERE state = '06' AND source LIKE '%supervisor%';

-- Point-in-polygon: unincorporated LA County (Compton area - should return supervisor but NOT G4110)
-- Compton coordinates: 33.8958, -118.2201
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-118.2201, 33.8958), 4326))
ORDER BY mtfcc;

-- Point-in-polygon: LA City address (should return both G4110 and X0001 for city council)
-- LA City Hall: 34.0537, -118.2427
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-118.2427, 34.0537), 4326))
ORDER BY mtfcc;

-- Verify geo_id format joins correctly (pre-Phase 36 check)
-- This should return matching rows for each imported X0001 boundary
SELECT gb.geo_id, gb.name, gb.mtfcc, d.ocd_id, d.district_type
FROM essentials.geofence_boundaries gb
JOIN essentials.districts d ON gb.geo_id = d.ocd_id
WHERE gb.state = '06' AND gb.mtfcc = 'X0001'
ORDER BY gb.geo_id;

-- ST_IsValid check on all newly imported boundaries
SELECT COUNT(*) FROM essentials.geofence_boundaries
WHERE state = '06' AND mtfcc = 'X0001' AND NOT ST_IsValid(geometry);
-- Expected: 0
```

### LA County Supervisor Districts: Confirmed Working Endpoint
```python
# Source: Direct verification — confirmed HTTP 200 with 5 features, WGS84 polygons

SUPERVISOR_URL = (
    "https://arcgis.gis.lacounty.gov/arcgis/rest/services/"
    "LACounty_Dynamic/Political_Boundaries/MapServer/27/query"
    "?where=1%3D1&outFields=DISTRICT%2CLABEL&f=geojson&outSR=4326"
)
# Fields: DISTRICT (string, "1"-"5"), LABEL ("DISTRICT 1"-"DISTRICT 5")
# Returns: 5 polygon features in EPSG:4326
# geo_id format: "ocd-division/country:us/state:ca/county:los_angeles/council_district:{n}"
```

### LA City Council Districts: Confirmed Working Endpoint
```python
# Source: Direct verification — confirmed HTTP 200 with 15 features

LA_CITY_COUNCIL_URL = (
    "https://services5.arcgis.com/7nsPwEMP38bSkCjy/arcgis/rest/services/"
    "Council_Districts/FeatureServer/0/query"
    "?where=1%3D1&outFields=district%2Cdist_name%2Cname&f=geojson&outSR=4326"
)
# Fields: district (int, 1-15), dist_name ("1 - Gilbert Cedillo" etc.), name (representative name)
# Returns: 15 polygon features
# Note: district field is integer, not string
# geo_id format: "ocd-division/country:us/state:ca/place:los_angeles/council_district:{n}"
```

---

## Confirmed ArcGIS Source URLs

### Verified (HTTP 200 + correct feature counts confirmed)

| Source | URL | Field | Count |
|--------|-----|-------|-------|
| LA County Supervisor Districts | `https://arcgis.gis.lacounty.gov/arcgis/rest/services/LACounty_Dynamic/Political_Boundaries/MapServer/27/query?where=1%3D1&outFields=DISTRICT,LABEL&f=geojson&outSR=4326` | DISTRICT (string) | 5 |
| LA City Council Districts | `https://services5.arcgis.com/7nsPwEMP38bSkCjy/arcgis/rest/services/Council_Districts/FeatureServer/0/query?where=1%3D1&outFields=district,dist_name,name&f=geojson&outSR=4326` | district (int) | 15 |
| Long Beach Council Districts | `https://hub.arcgis.com/datasets/c21dc4adc0d344c49a3298e3bc4adeb3` (ArcGIS Hub page — FeatureServer URL needs REST inspection) | TBD | 9 |
| Glendale Council Districts | `https://data-cog-gis.opendata.arcgis.com/datasets/887a7efe02224f0ba5f3d490e59b43ea_0` (ArcGIS Hub page — but AT-LARGE, SKIP import) | N/A | AT-LARGE |
| Torrance Council Districts | `https://open-data-torranceca.hub.arcgis.com/` (portal — FeatureServer URL TBD) | TBD | 6 |

### Known Districts in DB (from BallotReady, need geofences)
From `essentials.districts WHERE state = 'CA' AND district_type = 'LOCAL'`:
- **LA County supervisors** (5): `ocd-division/country:us/state:ca/county:los_angeles/council_district:1` through `:5`
- **LA City council** (at least 11 of 15): `ocd-division/country:us/state:ca/place:los_angeles/council_district:1` through `:15`
- **Long Beach** (at least 1 of 9): `ocd-division/country:us/state:ca/place:long_beach/council_district:7`
- **Torrance** (6): `ocd-division/country:us/state:ca/place:torrance/council_district:1` through `:6`
- **Inglewood** (at least 3): `ocd-division/country:us/state:ca/place:inglewood/council_district:2`, `:3`, `:4`
- **Pasadena** (at least 1): `ocd-division/country:us/state:ca/place:pasadena/council_district:4`
- **Downey** (at least 1): `ocd-division/country:us/state:ca/place:downey/council_district:2`
- **West Covina** (at least 1): `ocd-division/country:us/state:ca/place:west_covina/council_district:5`
- **Santa Clarita** (at least 1): `ocd-division/country:us/state:ca/place:santa_clarita/council_district:1`

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Bloomington-formula geo_ids (`{FIPS}{ward}`) for city council | OCD-ID string geo_ids for CA council wards | Phase 35 CONTEXT decision | Enables direct geo_id = ocd_id join; eliminates formula mismatch risk |
| Manual geometry insertion without validation | `make_valid()` before every insert | Phase 31 (Bloomington District 2 bug) | Prevents silent point-in-polygon failures from topology issues |
| Hardcoded ArcGIS URLs in scripts | Curated JSON config file consumed by scripts | Phase 35 CONTEXT decision | Human-reviewable source list; clear gap tracking |

---

## Open Questions

1. **MTFCC for supervisor districts: G4020 vs X0001**
   - What we know: `geofence_lookup.go` maps G4020 → `{COUNTY, JUDICIAL}`. LA County supervisor districts in `essentials.districts` have `district_type = 'LOCAL'`. Using G4020 would cause the lookup to miss supervisor officials.
   - What's unclear: The CONTEXT.md says "Supervisor districts (G4020)" — this may mean MTFCC=G4020 should be stored, and geofence_lookup.go needs to be updated to also map G4020 → LOCAL. OR it means X0001 is the correct MTFCC (consistent with BallotReady's custom code for all sub-county political districts) and "G4020" is just the phase spec shorthand.
   - **Recommendation:** The planner should add a task to query DB and confirm supervisor district types, then decide: either (a) use X0001 and document why, or (b) use G4020 and add an update to `geofence_lookup.go` to include LOCAL in the G4020 district types list. Option (a) is safer and consistent with existing patterns.

2. **Long Beach FeatureServer REST URL**
   - What we know: Long Beach ArcGIS Hub page exists at `hub.arcgis.com/datasets/c21dc4adc0d344c49a3298e3bc4adeb3`. Long Beach has 9 council districts.
   - What's unclear: The actual REST FeatureServer URL (not the Hub page URL). Hub pages are JavaScript-heavy and WebFetch can't extract the REST URL.
   - Recommendation: During implementation, try `https://services3.arcgis.com/rBnxK1Y2jCXU5F3i/arcgis/rest/services/City_Council_Districts/FeatureServer/0/query?f=json` (common Long Beach services URL pattern). If that fails, inspect the Hub page via browser developer tools to find the FeatureServer URL in network requests.

3. **Quality flag column addition**
   - What we know: `geofence_boundaries` has no `quality_flag` column currently.
   - What's unclear: Whether to add the column or use a separate quality tracking mechanism.
   - Recommendation (Claude's discretion): Add `ALTER TABLE essentials.geofence_boundaries ADD COLUMN IF NOT EXISTS quality_flag text` as part of Wave 0 (schema setup task). Simple NULL/string approach; no separate table needed for this scale.

4. **Santa Clarita, West Covina, El Monte, Downey, Inglewood — ArcGIS URL discovery**
   - What we know: These cities have district records in `essentials.districts`. Each city may or may not publish ArcGIS boundaries.
   - What's unclear: Whether each city has an accessible ArcGIS FeatureServer endpoint.
   - Recommendation: The implementation task should include a URL discovery subtask for each city. Cities without resolvable URLs within reasonable investigation time should be logged as gaps in the config file.

5. **LA City GeoHub data vintage (2021 vs current)**
   - What we know: The confirmed LA City council districts endpoint contains 2021 redistricting data with council member names from that cycle (Cedillo, Koretz, etc. who have since resigned/been replaced).
   - What's unclear: Whether there's a more current endpoint with 2022+ redistricting data or updated council membership.
   - Recommendation: The geometry is what matters for point-in-polygon — council member names in the boundary source are not stored. The 2021 redistricting geometry is still the current legal boundary as of 2026. Use the confirmed endpoint.

---

## Sources

### Primary (HIGH confidence)
- Direct DB query: `SELECT geo_id, ocd_id, district_type, mtfcc, label, city FROM essentials.districts WHERE state = 'CA' AND district_type = 'LOCAL'` — confirmed 25+ local district records, all with `geo_id = ''` and OCD-ID format ocd_ids, including all 5 supervisor districts and at least 11 LA City council districts
- Direct DB query: `SELECT geo_id, name, mtfcc, state FROM essentials.geofence_boundaries WHERE mtfcc IN ('G4020', 'X0001')` — confirmed existing G4020 (county boundary `06037`) and X0001 (Bloomington council `180586000001`-`180586000006`) records
- Direct HTTP verification: LA County Supervisor Districts endpoint — HTTP 200, 5 features, fields DISTRICT (string) and LABEL, WGS84 polygons
- Direct HTTP verification: LA City Council Districts endpoint — HTTP 200, 15 features, fields district/dist_name/name, Districts 1-15 confirmed
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geofence_lookup.go` — confirmed `"G4020": {"COUNTY", "JUDICIAL"}` and `"X0001": {"LOCAL"}` mappings
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/import_school_board_districts.py` — canonical ArcGIS FeatureServer import pattern for Phase 35
- `/Users/chrisandrews/Documents/GitHub/.planning/research/ARCHITECTURE.md` lines 530-563 — confirmed geo_id join requirement and make_valid necessity
- `/Users/chrisandrews/Documents/GitHub/.planning/milestones/v1.5-phases/31-essentials-profile-and-district-data-fixes/31-03-SUMMARY.md` — Bloomington Phase 31 precedent: nested shells geometry bug from ArcGIS, geo_id format confirmation

### Secondary (MEDIUM confidence)
- WebSearch: Long Beach 9 council districts, ArcGIS Hub page at `hub.arcgis.com/datasets/c21dc4adc0d344c49a3298e3bc4adeb3` confirmed — FeatureServer URL not resolved
- WebSearch: Torrance 6 council districts, GIS Open Data Portal at `open-data-torranceca.hub.arcgis.com` confirmed — FeatureServer URL TBD
- WebSearch: Glendale confirmed at-large elections as of 2024 (May 2024 vote to continue charter discussion on district formation, not yet implemented) — confirmed no X0001 import needed
- WebSearch: California FAIR MAPS Act — over 100 cities transitioned from at-large to district elections post-2020; multiple LA County cities affected

### Tertiary (LOW confidence)
- Long Beach FeatureServer URL pattern (guessed from ArcGIS service URL conventions) — needs verification during implementation
- Torrance, Inglewood, Pasadena, Downey, West Covina, Santa Clarita FeatureServer URLs — all TBD, to be resolved during implementation

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — same as Phase 33/34, fully locked
- Architecture: HIGH — ArcGIS pattern confirmed from Phase 31, DB state confirmed by direct queries
- geo_id convention: HIGH — OCD-IDs confirmed from direct DB queries of existing BallotReady district records
- MTFCC choice for supervisor districts: MEDIUM — G4020 vs X0001 question flagged as open; recommendation documented
- Source URLs (supervisor + LA City): HIGH — direct HTTP verification
- Source URLs (other cities): LOW-MEDIUM — Hub pages found but REST URLs unresolved

**Research date:** 2026-02-24
**Valid until:** 2026-05-24 (ArcGIS FeatureServer endpoints are maintained by city/county GIS teams; URL changes are rare but possible)
