# Architecture Research

**Domain:** Civic tech — geofence import pipeline and LA County coverage expansion (v1.6)
**Researched:** 2026-02-23
**Confidence:** HIGH — based on direct source inspection of all backend files, prior phase summaries, and verified external sources

---

## System Overview

The existing system after v1.5 ships politician data via a geofence-only lookup path. The v1.6 milestone adds coverage by populating the `geofence_boundaries` table with more polygons and the `politicians`/`offices`/`districts` tables with corresponding LA County official records. No new request-path code is needed — the lookup already works; the data is absent.

```
┌─────────────────────────────────────────────────────────────────────┐
│                IMPORT PIPELINE (offline, runs locally or in CI)      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌───────────────┐  ┌────────────────────┐  ┌───────────────────┐  │
│  │ TIGER         │  │ LA County eGIS     │  │ LA City GeoHub   │  │
│  │ Shapefiles    │  │ ArcGIS FeatureServer│  │ ArcGIS REST API  │  │
│  │ (Census FTP)  │  │ (supervisor dists) │  │ (council dists)  │  │
│  └──────┬────────┘  └─────────┬──────────┘  └────────┬─────────┘  │
│         │                     │                       │             │
│         ▼                     ▼                       ▼             │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │           cmd/import-geofences/main.go  (NEW CLI)            │  │
│  │                                                              │  │
│  │  1. Download/read source file (shapefile or GeoJSON)         │  │
│  │  2. Reproject to WGS84 (EPSG:4326) via ogr2ogr if needed    │  │
│  │  3. For each feature:                                        │  │
│  │     a. Map MTFCC code from source to known type              │  │
│  │     b. Build geo_id per TIGER or BallotReady convention      │  │
│  │     c. INSERT INTO essentials.geofence_boundaries            │  │
│  │        ON CONFLICT (geo_id) DO UPDATE SET geometry = ...     │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │           cmd/import-politicians/main.go  (NEW CLI)          │  │
│  │                                                              │  │
│  │  Reads a CSV/JSON manifest of LA County officials            │  │
│  │  Maps to existing politicians/offices/districts tables       │  │
│  │  Uses external_id-keyed upsert (ON CONFLICT DO UPDATE)       │  │
│  │  Links to districts via geo_id → district.geo_id lookup      │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│              DATABASE (Supabase / PostgreSQL + PostGIS)              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  essentials.geofence_boundaries  [PRIMARY WRITE TARGET]             │
│  ┌──────────┬──────────┬──────────┬──────────┬────────────────────┐ │
│  │ geo_id   │ mtfcc    │ state    │ geometry │ source             │ │
│  │ (unique) │ G5200... │ "06"     │ PostGIS  │ "census_tiger_2024"│ │
│  └──────────┴──────────┴──────────┴──────────┴────────────────────┘ │
│                                                                      │
│  essentials.districts  [LINK TABLE — geo_id joins to geofences]     │
│  ┌──────────┬──────────────┬──────────────┬─────────────────────┐  │
│  │ geo_id   │ district_type│ external_id  │ ocd_id              │  │
│  │ "0637001"│ "STATE_UPPER"│ (BallotReady)│ ocd-division/...    │  │
│  └──────────┴──────────────┴──────────────┴─────────────────────┘  │
│                                                                      │
│  essentials.politicians / offices / chambers / governments           │
│  [NEW RECORDS for LA County local officials]                         │
│                                                                      │
│  EXISTING (unchanged) LOOKUP PATH:                                   │
│  geofence_boundaries ←── ST_Contains(geometry, point) ──────────►  │
│  geo_id → districts.geo_id → offices → politicians                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (unchanged request path)
┌─────────────────────────────────────────────────────────────────────┐
│              EV-BACKEND (Go / Chi / GORM)                            │
│  internal/essentials/                                                │
│  ├── geofence_lookup.go  — FindGeoIDsByPoint + FindPoliticians       │
│  │   (unchanged — mtfccToDistrictTypes map may need new entries)     │
│  ├── handlers.go          — SearchPoliticians, GetPoliticianByID     │
│  │   (unchanged)                                                     │
│  └── routes.go            — HTTP route registration                  │
│      (unchanged)                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

### Existing Components (unchanged in v1.6)

| Component | Responsibility | v1.6 Change |
|-----------|---------------|-------------|
| `geofence_lookup.go: FindGeoIDsByPoint()` | PostGIS ST_Contains query against `geofence_boundaries`; returns (geo_id, MTFCC) pairs | None — works correctly once boundaries exist |
| `geofence_lookup.go: FindPoliticiansByGeoMatches()` | Joins geo_id matches to politicians via districts, applies MTFCC type filters | `mtfccToDistrictTypes` may need new MTFCC entries if LA County data sources use codes not yet mapped |
| `geofence_lookup.go: mtfccToDistrictTypes` | Maps MTFCC codes to BallotReady district types for type-restricted SQL WHERE clauses | Add any new MTFCC codes from LA County sources (e.g., G5200 for congressional already present) |
| `handlers.go: SearchPoliticians()` | Geocodes address → geofence lookup → politician DB join | None |
| `essentials.geofence_boundaries` table | Stores polygon geometry with geo_id + MTFCC | New rows inserted by import CLIs |
| `essentials.districts` table | Links district geo_id to politicians; `geo_id` column is the join key | Existing rows have geo_ids matching TIGER; ensure new politician records also have matching geo_ids |

### New Components (v1.6)

| Component | File | Responsibility |
|-----------|------|---------------|
| Geofence import CLI | `EV-Backend/cmd/import-geofences/main.go` | Downloads TIGER shapefiles or reads ArcGIS GeoJSON; reprojects to EPSG:4326; inserts into `geofence_boundaries` with idempotent upsert on `geo_id`; supports `--source tiger`, `--source arcgis-featureserver`, `--state 06`, `--layer cd`, etc. |
| Politician gap-fill CLI | `EV-Backend/cmd/import-politicians/main.go` | Reads a manifest CSV/JSON of LA County officials not yet in the DB; inserts/updates politicians, offices, districts, chambers, governments; uses `external_id`-keyed ON CONFLICT DO UPDATE; links districts to geofences via shared geo_id |
| TIGER download helper | Inside CLI or `internal/import/tiger.go` | Constructs Census FTP URLs from state FIPS + layer name; downloads zip; extracts shapefile; passes to ogr2ogr subprocess |
| ArcGIS REST fetcher | Inside CLI or `internal/import/arcgis.go` | Calls ArcGIS FeatureServer `/query?outFields=*&f=geojson&where=1%3D1`; paginates if needed; returns GeoJSON FeatureCollection |
| MTFCC mapper | Inside CLI or `internal/import/mtfcc.go` | Maps shapefile-provided MTFCC codes (or inferred codes for ArcGIS sources) to BallotReady district types; validates against `mtfccToDistrictTypes` in geofence_lookup.go |
| geo_id builder | Inside CLI | Assembles geo_id per TIGER convention (state FIPS + district number) or BallotReady convention (place FIPS + zero-padded ward) for X0001 city council sub-districts |

---

## Recommended Project Structure

```
EV-Backend/
├── cmd/
│   ├── bulk-import/main.go         # DEPRECATED placeholder (keep, do not delete)
│   ├── compass-import/main.go      # Existing CLI
│   ├── seed/main.go                # Existing CLI
│   ├── backfill-state-exec/main.go # Existing CLI
│   ├── import-geofences/           # NEW
│   │   └── main.go                 # TIGER shapefile + ArcGIS REST → geofence_boundaries
│   └── import-politicians/         # NEW
│       └── main.go                 # Official manifest → politicians/offices/districts upsert
└── internal/
    └── essentials/
        ├── geofence_models.go      # UNCHANGED — GeofenceBoundary struct
        ├── geofence_lookup.go      # MINOR EDIT — mtfccToDistrictTypes may add entries
        └── [all other files]       # UNCHANGED
```

### Structure Rationale

- **`cmd/import-geofences/`:** Follows the existing `cmd/` pattern for standalone CLI tools. Runs locally or in CI, not as a server request handler. The geofence import is a one-time-per-region operation and does not belong in the HTTP request path.
- **`cmd/import-politicians/`:** Separate from geofence import because the two pipelines have different source data (shapefiles vs. manual manifest or structured CSV) and different target tables.
- **No new `internal/` packages required:** The import CLIs are self-contained enough to include helper functions within their own `main.go`. If the helpers grow beyond ~300 lines, extract to `internal/import/` sub-package.

---

## Architectural Patterns

### Pattern 1: Two-Table Join (the critical link between geofences and politicians)

**What:** The lookup pipeline joins `geofence_boundaries.geo_id` to `districts.geo_id`. Both must have matching values for a politician to be returned. This is the central architectural constraint for v1.6: importing a geofence boundary row does nothing unless a `districts` row with the same `geo_id` also exists, and importing a politician record does nothing unless a geofence row covers the address point.

**When to use:** Applies to every data import decision in v1.6. Before inserting a geofence boundary, verify whether a matching `districts` row already exists (from BallotReady data). Before inserting a politician record, verify that a geofence boundary for that district's `geo_id` will exist after the import runs.

**Trade-offs:** Tight coupling between geofences and districts means import order matters. The safe order is: (1) ensure `districts` rows exist (from existing BallotReady data or new insertions), (2) insert matching `geofence_boundaries` rows. The reverse order — insert geofences first, then politicians — also works because the join is read-only at request time.

**Example (the critical join in FindPoliticiansByGeoMatches):**
```go
// geofence_lookup.go — this query is the integration point
// geo_id from geofence_boundaries must match geo_id in districts
query := `
  SELECT DISTINCT ON (p.id) ...
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON o.district_id = d.id
  WHERE (d.geo_id = $1 AND d.district_type = ANY($2))
`
```

### Pattern 2: Idempotent Upsert on geo_id

**What:** Both import CLIs use PostgreSQL `ON CONFLICT (geo_id) DO UPDATE SET geometry = EXCLUDED.geometry, ...` for geofence inserts, and `ON CONFLICT (external_id) DO UPDATE SET ...` for politician inserts. This makes re-running the import safe and allows refreshing boundaries when TIGER releases updated shapefiles annually.

**When to use:** Every INSERT into `geofence_boundaries` and `politicians`. Never use bare INSERT without conflict handling — repeated runs (reruns after error, annual TIGER refresh) must not duplicate rows.

**Trade-offs:** Requires the unique constraint on `geo_id` in `geofence_boundaries` to be present. The model comment in `geofence_models.go` says "unique constraint managed manually" — verify this constraint exists in Supabase before running the import.

**Example:**
```sql
INSERT INTO essentials.geofence_boundaries
  (id, geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
VALUES
  (uuid_generate_v4(), $1, $2, $3, $4, $5,
   ST_GeomFromGeoJSON($6), $7, NOW()::text)
ON CONFLICT (geo_id)
DO UPDATE SET
  geometry   = EXCLUDED.geometry,
  source     = EXCLUDED.source,
  imported_at = EXCLUDED.imported_at;
```

### Pattern 3: ogr2ogr as External Subprocess for Reprojection

**What:** TIGER shapefiles use NAD83 (EPSG:4269). The `geofence_boundaries` table stores WGS84 (EPSG:4326). The Go CLI invokes `ogr2ogr` as a subprocess to reproject and convert shapefiles to GeoJSON, which is then inserted via `ST_GeomFromGeoJSON()`. This is the same approach used in v1.5 for Bloomington imports (ogr2ogr was used interactively; v1.6 automates it).

**When to use:** Any TIGER shapefile import. ArcGIS FeatureServer data (LA County eGIS, LA City GeoHub) is typically served in WGS84 already — skip reprojection for those sources.

**Trade-offs:** Requires ogr2ogr (GDAL) installed in the build/run environment. The alternative — Go shapefile libraries — exist (everystreet/go-shapefile, twpayne/go-shapefile) but are dormant or limited (last release 2021, no support for M/Z shapefile variants). Using ogr2ogr as a subprocess is pragmatic: it handles all shapefile variants and projection math correctly, and GDAL is a standard tool available on any developer machine and in CI.

**Example (Go subprocess call):**
```go
func reprojectShapefile(shpPath, outGeoJSONPath, sourceEPSG, targetEPSG string) error {
    cmd := exec.Command("ogr2ogr",
        "-f", "GeoJSON",
        "-s_srs", "EPSG:"+sourceEPSG,
        "-t_srs", "EPSG:"+targetEPSG,
        outGeoJSONPath,
        shpPath,
    )
    return cmd.Run()
}
```

### Pattern 4: Layer-Based MTFCC Assignment for ArcGIS Sources

**What:** TIGER shapefiles include an MTFCC attribute per feature. ArcGIS FeatureServer data (LA County supervisor districts, LA City council districts) does not include MTFCC — the MTFCC must be assigned based on which layer is being imported. The import CLI accepts a `--mtfcc` flag that is applied to all features from that run.

**When to use:** Any ArcGIS REST source where MTFCC is not embedded in the feature attributes. The correct MTFCC for each LA County layer:

| Source Layer | MTFCC to Assign | District Type Mapped |
|-------------|----------------|---------------------|
| TIGER congressional (tl_2024_06_cd119) | G5200 (from shapefile) | NATIONAL_LOWER |
| TIGER state senate (tl_2024_06_sldu) | G5210 (from shapefile) | STATE_UPPER |
| TIGER state assembly (tl_2024_06_sldl) | G5220 (from shapefile) | STATE_LOWER |
| TIGER county (tl_2024_06_county) | G4020 (from shapefile) | COUNTY, JUDICIAL |
| TIGER unified school district (tl_2024_06_unsd) | G5420 (from shapefile) | SCHOOL |
| LA County supervisor districts (eGIS FeatureServer) | G4020 (inferred — county-level) | COUNTY |
| LA City council districts (GeoHub FeatureServer) | X0001 (inferred — ward sub-district) | LOCAL |
| Other incorporated city boundaries (TIGER G4110) | G4110 (from shapefile) | LOCAL, LOCAL_EXEC |

**Trade-offs:** Assigning MTFCC at the layer level (not per-feature) is correct for all homogeneous layers. It would fail if a single ArcGIS layer mixed district types, which does not occur in practice for the target datasets.

### Pattern 5: geo_id Construction per Source Convention

**What:** The `geo_id` in `geofence_boundaries` must match the `geo_id` in `essentials.districts` for the lookup join to work. TIGER shapefiles include a GEOID attribute that can be used directly. ArcGIS sources and the X0001 ward boundary convention require constructing the geo_id from component fields.

**Conventions:**

| Layer Type | TIGER GEOID Format | Example |
|-----------|-------------------|---------|
| Congressional district | state FIPS (2) + district number (2, zero-padded) | "0637" = CA district 37 |
| State senate (SLDU) | state FIPS (2) + district number (3, zero-padded) | "06037" = CA SD-37 |
| State assembly (SLDL) | state FIPS (2) + district number (3, zero-padded) | "06060" = CA AD-60 |
| County | state FIPS (2) + county FIPS (3) | "06037" = LA County |
| Unified school district | state FIPS (2) + LEA code (5) | "0622590" = LAUSD |
| Incorporated place (city) | state FIPS (2) + place FIPS (5) | "0644000" = LA City |
| City council ward (X0001) | place FIPS (7) + ward number (5, zero-padded) | "064400000001" = LA CD-1 |
| Supervisor district (G4020) | county FIPS (5) + district number (3, zero-padded) | "06037001" = LA Sup Dist 1 |

**Critical:** The geo_id in `geofence_boundaries` must exactly match what BallotReady stored in `essentials.districts.geo_id`. Before importing geofences, query the districts table to see what geo_ids already exist for the target area, and import matching values.

**Example (supervisor district geo_id):**
```go
// LA County FIPS = "06037"
// Supervisor District 1 → geo_id = "06037001"
geoID := fmt.Sprintf("%s%03d", countyFIPS, districtNumber)
```

---

## Data Flow

### Address Lookup (existing, unchanged)

```
User enters address → Google Places Autocomplete → formattedAddress
    ↓
POST /essentials/politicians/search { query: "123 Main St, Los Angeles CA 90012" }
    ↓
GeoClient.Geocode("123 Main St...") → { lat: 34.052, lng: -118.243, state: "CA" }
    ↓
FindGeoIDsByPoint(34.052, -118.243)
  SELECT geo_id, mtfcc FROM essentials.geofence_boundaries
  WHERE ST_Contains(geometry, ST_SetSRID(ST_MakePoint(-118.243, 34.052), 4326))
  → e.g. [{geo_id:"06037", mtfcc:"G4020"}, {geo_id:"0637", mtfcc:"G5200"},
          {geo_id:"06065", mtfcc:"G5210"}, {geo_id:"06049", mtfcc:"G5220"},
          {geo_id:"0644000", mtfcc:"G4110"}, {geo_id:"064400000001", mtfcc:"X0001"}]
    ↓
FindPoliticiansByGeoMatches(matches)
  WHERE (d.geo_id = '06037' AND d.district_type = ANY({'COUNTY','JUDICIAL'}))
     OR (d.geo_id = '0637'  AND d.district_type = ANY({'NATIONAL_LOWER'}))
     OR (d.geo_id = '06065' AND d.district_type = ANY({'STATE_UPPER'}))
     OR (d.geo_id = '06049' AND d.district_type = ANY({'STATE_LOWER'}))
     OR (d.geo_id = '0644000' AND d.district_type = ANY({'LOCAL','LOCAL_EXEC'}))
     OR (d.geo_id = '064400000001' AND d.district_type = ANY({'LOCAL'}))
  → []OfficialOut (county supervisor, House member, senator, assemblymember,
                   mayor/city officials, city council member)
    ↓
fetchOfficialsFromDB(zip, "CA") → supplement with federal+state from DB
    ↓
Deduplicate → return merged []OfficialOut
```

### Import Pipeline (new, offline)

```
Developer runs: go run ./cmd/import-geofences --source tiger --state 06 --layers cd,sldu,sldl,county,unsd,place
    ↓
For each layer:
  Download ZIP from https://www2.census.gov/geo/tiger/TIGER2024/[LAYER]/tl_2024_06_[layer].zip
    ↓
  Run ogr2ogr to reproject NAD83→WGS84, output GeoJSON
    ↓
  Parse GeoJSON features
    ↓
  For each feature:
    geoID  = feature.properties["GEOID"]       (TIGER shapefiles always include GEOID)
    mtfcc  = feature.properties["MTFCC"]        (TIGER shapefiles always include MTFCC)
    geometry = feature.geometry (already WGS84 after ogr2ogr)
    ↓
    INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, geometry, ...)
    ON CONFLICT (geo_id) DO UPDATE SET geometry = EXCLUDED.geometry
    ↓
  Log: imported N features, M conflicts updated

Developer runs: go run ./cmd/import-geofences --source arcgis \
  --url "https://services3.arcgis.com/[...]/FeatureServer/0/query?outFields=*&f=geojson&where=1%3D1" \
  --mtfcc G4020 --state 06 --geo-id-field "SUPERVISORIAL_DISTRICT" --geo-id-prefix "06037"
    ↓
  Fetch paginated GeoJSON from FeatureServer
    ↓
  For each feature:
    distNum = feature.properties["SUPERVISORIAL_DISTRICT"]  (e.g. "1")
    geoID   = "06037" + fmt.Sprintf("%03d", distNum)        (e.g. "06037001")
    mtfcc   = "G4020" (from CLI flag)
    geometry = feature.geometry (FeatureServer returns WGS84)
    ↓
    INSERT INTO essentials.geofence_boundaries ... ON CONFLICT DO UPDATE
```

### Politician Gap-Fill (new, offline)

```
Developer runs: go run ./cmd/import-politicians --manifest la_county_officials.json
    ↓
  Read manifest JSON (array of official records)
    ↓
  For each official:
    Look up district by geo_id in essentials.districts
    If district exists: use existing district.id
    If not: INSERT district (external_id auto-assigned from BallotReady or set to 0 with manual flag)
    ↓
    UPSERT government, chamber, district, politician, office
    ON CONFLICT (external_id) DO UPDATE
    ↓
  Log: inserted N officials, M updated, K districts linked
```

---

## Integration Points

### Census TIGER/Line FTP (geofence source 1)

| Aspect | Details |
|--------|---------|
| Base URL | `https://www2.census.gov/geo/tiger/TIGER2024/` |
| Layer directories | `CD/` (congressional), `SLDU/` (state senate), `SLDL/` (state assembly), `COUNTY/`, `PLACE/`, `UNSD/` (unified school district) |
| File naming | `tl_2024_{state_fips}_{layer}.zip` — e.g., `tl_2024_06_cd119.zip` for CA congressional |
| National layers | `tl_2024_us_county.zip` — some layers are national, not per-state |
| GEOID attribute | Always present in TIGER shapefiles as `GEOID` attribute field |
| MTFCC attribute | Always present in TIGER shapefiles as `MTFCC` attribute field |
| SRID | NAD83 / EPSG:4269 — requires reprojection to WGS84 (EPSG:4326) via ogr2ogr `-s_srs EPSG:4269 -t_srs EPSG:4326` |
| Confidence | HIGH — established Census data product, annual releases |

### LA County eGIS ArcGIS FeatureServer (geofence source 2)

| Aspect | Details |
|--------|---------|
| Hub | `https://egis-lacounty.hub.arcgis.com/` |
| Supervisor districts dataset | Available at `https://egis-lacounty.hub.arcgis.com/datasets/lacounty::supervisorial-districts-current/about` |
| School district boundaries | Available at `https://egis-lacounty.hub.arcgis.com/datasets/lacounty::school-district-boundaries/about` |
| REST query pattern | `[ServiceURL]/FeatureServer/[layerId]/query?outFields=*&f=geojson&where=1%3D1` |
| SRID | ArcGIS Hub serves in WGS84 by default — no reprojection needed |
| Attribute for district number | Supervisor: field named `SUPERVISORIAL_DISTRICT` or similar; must be inspected per dataset |
| Pagination | ArcGIS FeatureServer returns max 1000 or 2000 features per query; use `resultOffset` for pagination |
| Confidence | MEDIUM — URLs discovered, REST pattern standard, specific field names unverified without direct API call |

### LA City GeoHub ArcGIS FeatureServer (geofence source 3)

| Aspect | Details |
|--------|---------|
| Hub | `https://geohub.lacity.org/` |
| Council districts dataset | `https://geohub.lacity.org/datasets/76104f230e384f38871eb3c4782f903d_13/about` |
| REST API | ArcGIS Hub — same `/FeatureServer/[layerId]/query?outFields=*&f=geojson&where=1%3D1` pattern |
| District number attribute | Likely `CD_NUM` or `DISTRICT_N` — verify by fetching one feature |
| MTFCC to assign | X0001 (city council ward sub-district, BallotReady convention — already in mtfccToDistrictTypes) |
| geo_id to build | LA City place FIPS = `0644000`; council district 1 → `064400000001` (matches BallotReady geo_id in districts table) |
| Verify districts exist | Query `essentials.districts WHERE state = 'CA' AND district_type = 'LOCAL'` before import — existing BallotReady records for LA City council members should have these geo_ids |
| Confidence | MEDIUM — dataset exists, REST API pattern standard, specific field names need runtime verification |

### PostGIS (existing, central)

| Aspect | Details |
|--------|---------|
| Table | `essentials.geofence_boundaries` — `geo_id` text unique, `geometry geometry(Geometry,4326)` |
| Spatial index | `idx_geofence_boundaries_geometry` GIST index — already created in `setup.go`; use `VACUUM ANALYZE essentials.geofence_boundaries` after bulk import |
| Geometry validity | Run `ST_MakeValid(geometry)` on all imported geometries before INSERT to handle topology issues (precedent: Bloomington District 2 required ST_MakeValid in Phase 31) |
| Unique constraint on geo_id | Comment in `geofence_models.go` says "unique constraint managed manually" — confirm it exists: `SELECT indexname FROM pg_indexes WHERE tablename = 'geofence_boundaries' AND indexname LIKE '%geo_id%'` |
| SRID check | Validate: `SELECT DISTINCT ST_SRID(geometry) FROM essentials.geofence_boundaries` — must return only 4326 after import |

### essentials.districts (existing join table)

| Aspect | Details |
|--------|---------|
| Role | The `geo_id` column in `districts` is the join key between geofences and politicians |
| Pre-existing records | BallotReady already populated districts for federal and state officials; their geo_ids use TIGER-compatible format |
| Gap-fill requirement | LA County local officials (city council, supervisor) may not have `districts` rows if they were never in BallotReady |
| Verify before importing geofences | `SELECT geo_id, district_type FROM essentials.districts WHERE state = 'CA' LIMIT 50` to see what already exists |
| Lookup during politician import | CLI must JOIN on `geo_id` to find existing `districts.id` — do not blindly create new district rows if one with the same `geo_id` already exists |

---

## New vs Modified Components

### New (create from scratch)

| Component | File | Notes |
|-----------|------|-------|
| Geofence import CLI | `EV-Backend/cmd/import-geofences/main.go` | Replaces deprecated `cmd/bulk-import/main.go` for geofence data; does not reuse any of the old code |
| Politician gap-fill CLI | `EV-Backend/cmd/import-politicians/main.go` | Reads a structured manifest; no live API calls |

### Modified (targeted changes)

| Component | File | Change | Scope |
|-----------|------|--------|-------|
| MTFCC map | `EV-Backend/internal/essentials/geofence_lookup.go` | Add entries for any MTFCC codes that appear in imported data but are not yet in `mtfccToDistrictTypes` | 1-3 lines; only if new MTFCC codes are used |

### Kept Unchanged

| Component | Why |
|-----------|-----|
| `geofence_lookup.go: FindGeoIDsByPoint()` | PostGIS query is correct as-is; new boundaries work automatically |
| `geofence_lookup.go: FindPoliticiansByGeoMatches()` | Join logic is correct; just needs matching data |
| `geofence_models.go` | Schema unchanged |
| `handlers.go` | All request-path handlers unchanged |
| `routes.go` | No new endpoints |
| `setup.go` | No new initialization needed |
| All frontend code | No frontend changes needed for this milestone |

---

## Build Order (dependency-aware)

The dependencies flow strictly from data → schema → import → verification. Parallelism exists within import steps for different layers.

### Step 1: Schema and Constraint Verification (blocking)

Before any import runs, verify:
- Unique constraint on `geofence_boundaries.geo_id` exists in Supabase
- `ST_MakeValid` and `ST_GeomFromGeoJSON` are available (PostGIS already enabled)
- Query existing `districts.geo_id` values for CA to understand what geo_ids already exist from BallotReady

This is a read-only verification step, 15 minutes of SQL queries. It is blocking because import strategy depends on findings.

### Step 2: TIGER Shapefile Geofences — Federal + State (independent of local)

Import order within this step is flexible; all layers are independent of each other:

| Order | Layer | TIGER File | MTFCC | Districts Mapped |
|-------|-------|-----------|-------|-----------------|
| 2a | Congressional districts | `tl_2024_06_cd119.zip` | G5200 | NATIONAL_LOWER |
| 2b | State senate (SLDU) | `tl_2024_06_sldu.zip` | G5210 | STATE_UPPER |
| 2c | State assembly (SLDL) | `tl_2024_06_sldl.zip` | G5220 | STATE_LOWER |
| 2d | County boundaries | `tl_2024_06_county.zip` | G4020 | COUNTY, JUDICIAL |
| 2e | Unified school districts | `tl_2024_06_unsd.zip` | G5420 | SCHOOL |
| 2f | Incorporated places (cities) | `tl_2024_06_place.zip` | G4110 | LOCAL, LOCAL_EXEC |

These feed federal, state, county, school board, and city-level (at-large) politicians — the majority of what LA County addresses need. Steps 2a-2f can run in any order or in parallel.

### Step 3: LA County ArcGIS Geofences — Supervisor Districts (parallel to Step 2)

Fetch supervisor district polygons from LA County eGIS FeatureServer. These use G4020 MTFCC (county-level) and need a geo_id that matches BallotReady's `districts.geo_id` for LA County supervisors. Verify existing `districts` geo_ids before choosing the geo_id format.

### Step 4: LA City GeoHub Geofences — City Council Districts (depends on Step 2f)

Import LA City council district polygons with `mtfcc = 'X0001'` and geo_ids matching `064400000{nn}` format. Step 2f (incorporated places) must complete first because it provides the G4110 polygon for city-level at-large officials, which works independently; Step 4 adds per-district ward precision.

### Step 5: Verify Geofence Coverage

After Steps 2-4, run point-in-polygon tests against known LA County addresses:
- Downtown LA address → should return federal + state + county supervisor + city at-large + city council district members
- Santa Monica address → should return federal + state + county + Santa Monica city officials (from G4110)
- Unincorporated area → federal + state + county (no G4110 or X0001 match — expected)

### Step 6: Politician Gap-Fill (depends on Steps 2-5)

After verifying which addresses return which politicians, identify gaps: addresses that return geofence hits but no politician records for those geo_ids. These are the district/chamber/politician rows that need to be created.

Run `import-politicians` CLI with a manifest of missing officials. The manifest is built manually from a verified source (LA County registrar, BallotReady archived data, official county website).

### Step 7: VACUUM ANALYZE

```sql
VACUUM ANALYZE essentials.geofence_boundaries;
```

Run after all imports complete to update PostGIS planner statistics. Required for optimal GiST index performance after bulk inserts.

### Blocking Dependencies

```
Step 1 (verify schema)
  ↓
Steps 2a-2f (TIGER shapefiles) ←→ Step 3 (LA County ArcGIS)  [parallel]
  ↓
Step 4 (LA City council)
  ↓
Step 5 (verify coverage)
  ↓
Step 6 (politician gap-fill)
  ↓
Step 7 (VACUUM ANALYZE)
```

---

## Scaling Considerations

| Scale | Architecture Notes |
|-------|-------------------|
| Current (100-1k users) | PostGIS GiST index handles thousands of geofence polygons in <50ms per point-in-polygon query; no changes needed |
| Adding CA statewide | All CA congressional (52 districts), SLDU (40), SLDL (80), counties (58), school districts (~1000), places (~1500) — total ~2700 polygons; GiST index handles this without modification |
| Adding all 50 states | ~50k polygons total; GiST index handles millions of polygons; partitioning by state is an option if queries slow beyond 200ms |
| Annual TIGER refresh | Idempotent upsert means re-running import with updated shapefile updates geometries without duplication; safe to automate |

---

## Anti-Patterns

### Anti-Pattern 1: Importing Geofences Without Verifying Matching Districts

**What people do:** Import 58 California county polygons into `geofence_boundaries`, then wonder why county supervisors are not showing up in search results.

**Why it's wrong:** The lookup joins `geofence_boundaries.geo_id` to `essentials.districts.geo_id`. If no `districts` row with that `geo_id` exists, the join returns nothing. The geofence boundary is invisible at query time.

**Do this instead:** Before importing, query `SELECT geo_id, district_type FROM essentials.districts WHERE state = 'CA'` to see what district records already exist from BallotReady. Import geofence boundaries whose `geo_id` matches existing district records first. Then identify which districts have no matching geofence (Step 5) and which districts have no politicians (Step 6).

### Anti-Pattern 2: Using X0001 MTFCC Without Verifying BallotReady District geo_ids

**What people do:** Build X0001 geo_ids as `{placeFIPS}{paddedWardNum}` using a formula, import them, then discover the BallotReady `districts` table uses a slightly different padding or prefix.

**Why it's wrong:** The geo_id join is an exact string match. If BallotReady stored `064400000001` and you imported `06440000001` (different padding), the join fails silently.

**Do this instead:** Before building X0001 geo_ids for LA City council, query `essentials.districts WHERE district_type = 'LOCAL' AND city = 'Los Angeles'` to see the exact format BallotReady used. Use that format exactly. The Bloomington precedent confirmed: BallotReady uses 12-character geo_ids (`18058600000X`), matching the `{7-digit place FIPS}{5-digit zero-padded ward}` formula.

### Anti-Pattern 3: Importing All Politicians from an External Source Without Deduplication

**What people do:** Scrape LA County official website, insert all records into `politicians` table, then discover duplicates when some officials were already imported from BallotReady with different `external_id` values.

**Why it's wrong:** The `politicians` table has a unique index on `external_id`. Gap-fill imports that create new records (external_id = 0 or sentinel value) will not conflict with BallotReady records, but the resulting duplicate records will cause the same official to appear twice in search results.

**Do this instead:** Before inserting any politician, query by full name + office title + geo_id combination to check if a record already exists in the DB. If a BallotReady record exists with a different external_id but the same name and district, update it rather than insert a new one. The politician gap-fill import should be additive only for officials who genuinely have no DB record.

### Anti-Pattern 4: Skipping ST_MakeValid on Imported Geometries

**What people do:** Insert raw geometry from shapefiles or ArcGIS without validation; some features pass silently but others cause later spatial query errors.

**Why it's wrong:** Real-world boundary data from official sources (including ArcGIS FeatureServer) can contain topology issues (self-intersections, nested shells) that pass through the INSERT but break `ST_Contains` queries. This was encountered in Phase 31 (Bloomington District 2 had a nested shells issue from the ArcGIS source).

**Do this instead:** Wrap every geometry in `ST_MakeValid()` before INSERT. For TIGER shapefiles this is rarely needed but costs nothing. For ArcGIS FeatureServer data it is essential.

```sql
ST_MakeValid(ST_GeomFromGeoJSON($1))
-- instead of
ST_GeomFromGeoJSON($1)
```

### Anti-Pattern 5: Rebuilding the Import CLI as a Server-Side Admin Endpoint

**What people do:** Add a new HTTP admin endpoint like `POST /admin/import/tiger?state=06&layer=cd` that downloads and imports TIGER shapefiles on-demand.

**Why it's wrong:** TIGER downloads are large (hundreds of MB per state), take minutes to process, and are only run a few times per year. Wrapping this in an HTTP endpoint adds complexity, timeout risk, and running-in-production risk. The deprecated `cmd/bulk-import/main.go` pattern already shows this lesson was learned.

**Do this instead:** Keep geofence imports as CLI tools that run locally or in a CI job. The import writes directly to Supabase via `DATABASE_URL`. The admin endpoint pattern (`POST /admin/import`) is appropriate for small, fast operations (like the original ZIP-based BallotReady warmer); it is not appropriate for large shapefile downloads.

---

## Sources

- Direct source inspection: `EV-Backend/internal/essentials/geofence_lookup.go` — mtfccToDistrictTypes map, FindGeoIDsByPoint, FindPoliticiansByGeoMatches — HIGH confidence
- Direct source inspection: `EV-Backend/internal/essentials/geofence_models.go` — GeofenceBoundary struct, geo_id unique constraint note — HIGH confidence
- Direct source inspection: `EV-Backend/internal/essentials/models.go` — Politician, District, Office, Chamber models; external_id uniqueIndex — HIGH confidence
- Direct source inspection: `EV-Backend/internal/essentials/setup.go` — GiST index creation, PostGIS extension init — HIGH confidence
- Direct source inspection: `EV-Backend/cmd/bulk-import/main.go` — confirmed deprecated, no reuse value — HIGH confidence
- Phase 31 SUMMARY (31-03-SUMMARY.md) — Bloomington ArcGIS FeatureServer pattern, ST_MakeValid precedent, geo_id format verification against districts table — HIGH confidence
- Phase 31 RESEARCH (31-RESEARCH.md) — X0001 MTFCC, geo_id construction formula, geofence boundary data sources — HIGH confidence
- [LA County Enterprise GIS Hub](https://egis-lacounty.hub.arcgis.com/) — supervisor districts and school district boundary datasets confirmed available — MEDIUM confidence (URLs discovered, field names not verified)
- [LA City GeoHub — Council Districts](https://geohub.lacity.org/datasets/76104f230e384f38871eb3c4782f903d_13/about) — ArcGIS FeatureServer source for LA City council districts — MEDIUM confidence
- [Census TIGER/Line Shapefiles](https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html) — annual shapefile releases, FTP access pattern — HIGH confidence
- [TIGER 2025 Technical Documentation](https://www2.census.gov/geo/pdfs/maps-data/data/tiger/tgrshp2025/TGRSHP2025_TechDoc.pdf) — MTFCC codes and GEOID formats — HIGH confidence (Census authoritative source)
- [ogr2ogr documentation](https://gdal.org/en/stable/programs/ogr2ogr.html) — reprojection flags, GeoJSON output format — HIGH confidence
- [go-shapefile library](https://github.com/everystreet/go-shapefile) — evaluated as insufficient (dormant, limited shape types); ogr2ogr preferred — MEDIUM confidence

---

*Architecture research for: LA County Full Coverage + Repeatable Import Pipeline (v1.6)*
*Researched: 2026-02-23*
