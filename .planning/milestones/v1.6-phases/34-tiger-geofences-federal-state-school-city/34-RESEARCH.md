# Phase 34: TIGER Geofences — Federal, State, School, and City Boundaries - Research

**Researched:** 2026-02-24
**Domain:** Census TIGER/Line shapefile import, geopandas, PostGIS geometry validation
**Confidence:** HIGH

## Summary

Phase 34's goal is to populate `geofence_boundaries` with federal, state, school district, and incorporated city boundaries for the LA County area. The headline finding is that **four of the five requirement groups (GEO-01 through GEO-03 and GEO-05) are already satisfied** by prior imports. The live database already contains all 52 CA Congressional districts (G5200), all 40 CA State Senate districts (G5210), all 80 CA State Assembly districts (G5220), and all 346 CA Unified School Districts (G5420) — including LAUSD (`geo_id='0622710'`) and 59 other LA County-area UNSDs. All existing CA boundaries pass `ST_IsValid` (0 invalid geometries confirmed by direct query).

The sole remaining work for Phase 34 is **GEO-06: importing CA incorporated place boundaries (G4110)**. California has approximately 482 incorporated cities and towns; currently 0 G4110 records exist for state=`06`. The TIGER PLACE shapefile for CA is at `https://www2.census.gov/geo/tiger/TIGER2024/PLACE/tl_2024_06_place.zip` (9.8 MB, confirmed HTTP 200). The import must filter to `MTFCC == 'G4110'` to exclude CDPs (G4150) and other feature classes included in the same shapefile. The legacy `import_shapefiles_fixed.py` already defines this URL but does not apply the MTFCC filter.

The Phase 34 plan should produce a single new script — `import_ca_place_boundaries.py` — modeled after `import_ca_legislative_geofences.py` (the canonical Phase 33-era script), using `from utils import get_engine, load_env`, filtering to `MTFCC == 'G4110'`, importing all ~482 CA incorporated places statewide, and closing with a verification query confirming the LA County point-in-polygon test hits city boundaries correctly.

**Primary recommendation:** Write `import_ca_place_boundaries.py` following the canonical script pattern. Import all CA G4110 (statewide, ~482 records). Do not spatially filter to LA County only — the pipeline is designed for regional reuse. Run the script once, verify with `ST_IsValid` and point-in-polygon test for a known LA County address.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| GEO-01 | Congressional district boundaries (G5200) imported for LA County area | ALREADY SATISFIED: 52 CA G5200 records in DB (geo_ids 0601-0652), covers all 52 CA CDs including LA-area CDs 25-40. Confirmed by `import_ca_legislative_geofences.py` prior run. |
| GEO-02 | CA State Senate district boundaries (G5210) imported for LA County area | ALREADY SATISFIED: 40 CA G5210 records in DB (geo_ids 06001-06040), full statewide coverage. All pass ST_IsValid. |
| GEO-03 | CA State Assembly district boundaries (G5220) imported for LA County area | ALREADY SATISFIED: 80 CA G5220 records in DB (geo_ids 06001-06080), full statewide coverage. All pass ST_IsValid. |
| GEO-05 | Unified School District boundaries (G5420) imported for LA County area | ALREADY SATISFIED: 346 CA G5420 records in DB (statewide), 60 intersect LA County boundary including LAUSD (geo_id='0622710'). All pass ST_IsValid. |
| GEO-06 | Incorporated place/city boundaries (G4110) imported for LA County area | NOT YET DONE: 0 CA G4110 records in DB. Requires: download tl_2024_06_place.zip, filter MTFCC==G4110, import ~482 CA cities. New script needed. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| geopandas | 1.1.2 | Shapefile loading, CRS reprojection, to_postgis, is_valid/make_valid | Project standard per Phase 33 requirements.txt — already installed |
| SQLAlchemy | 2.0.46 | Database engine creation | Project standard per Phase 33 requirements.txt |
| psycopg2-binary | 2.9.11 | PostgreSQL driver | Project standard per Phase 33 requirements.txt |
| requests | 2.32.5 | HTTP download of TIGER ZIP | Project standard per Phase 33 requirements.txt |
| shapely | 2.0.7 | Geometry operations (transitive via geopandas) | Project standard per Phase 33 requirements.txt |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| zipfile | stdlib | Extract downloaded TIGER ZIPs | Already used in existing scripts |
| pathlib.Path | stdlib | File path handling | Already used in existing scripts |
| datetime | stdlib | `imported_at` timestamps | Already used in existing scripts |

### Alternatives Considered
None — the project stack is fully established. Phase 33 locked the dependency manifest.

**Installation:**
```bash
# Already installed from Phase 33 setup
python3.13 -m pip install -r EV-Backend/scripts/requirements.txt
```

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── utils.py                          # Phase 33 shared utilities
├── requirements.txt                  # Phase 33 pinned manifest
├── import_ca_legislative_geofences.py  # Canonical pattern (G5200, G5210, G5220)
├── import_ca_place_boundaries.py     # NEW: G4110 incorporated places
└── shapefile_data/                   # Downloaded/extracted shapefiles (gitignored)
    ├── tl_2024_06_place.zip
    └── tl_2024_06_place/
        └── tl_2024_06_place.shp
```

### Pattern 1: Canonical TIGER Import Script Structure
**What:** Download → Extract → Filter → Reproject → Clean → Import → Verify
**When to use:** Every new TIGER shapefile import
**Template from `import_ca_legislative_geofences.py`:**

```python
#!/usr/bin/env python3
"""
Import CA incorporated place boundaries (G4110) from Census TIGER/Line.

Imports:
  - Incorporated Places (cities/towns) for California — MTFCC G4110

These link to essentials.districts via geo_id for address-based politician lookups.
"""

import os, sys, requests, zipfile, geopandas as gpd
from sqlalchemy import text
from pathlib import Path
from datetime import datetime

sys.path.insert(0, str(Path(__file__).parent))
from utils import get_engine, load_env

YEAR = 2024
CA_FIPS = "06"
WORK_DIR = Path("./shapefile_data")

PLACE_URL = f"https://www2.census.gov/geo/tiger/TIGER{YEAR}/PLACE/tl_{YEAR}_{CA_FIPS}_place.zip"
MTFCC_FILTER = "G4110"  # Incorporated Place only; G4150=CDP, G4210=other
```

### Pattern 2: MTFCC Filtering — Critical for G4110
**What:** TIGER PLACE shapefile contains multiple feature classes in a single file
**Why it matters:** G4150 (CDPs — unincorporated communities) must be excluded. G4110 (incorporated cities) is what `geofence_lookup.go` maps to `LOCAL`/`LOCAL_EXEC` district types.
**Example:**
```python
# Source: TIGER PLACE shapefile has MTFCC column with G4110, G4150, G4210 values
gdf = gpd.read_file(shp_path)
gdf = gdf[gdf['STATEFP'] == CA_FIPS]          # CA only
gdf = gdf[gdf['MTFCC'] == 'G4110']            # Incorporated places only (CRITICAL)
```

**MTFCC values in TIGER PLACE file:**
- `G4110` — Incorporated Place (city, town, village) → **import these**
- `G4150` — Census Designated Place (unincorporated community) → **skip**
- `G4210` — Other (administrative) → **skip**

### Pattern 3: geo_id Format for G4110
**What:** TIGER PLACE GEOID = `STATEFP(2) + PLACEFP(5)` = 7 characters
**Examples:**
- Los Angeles city: `0644000`
- Long Beach: `0641992`
- Pasadena: `0656000`

**How this joins to politicians:** When Phase 37 creates city council politician records, their `essentials.districts.geo_id` will be set to the matching TIGER GEOID (same pattern as Indiana Bloomington = `'1805860'` which matches the G4110 boundary `geo_id='1805860'`).

**Note on existing Indiana records:** Indiana G4110 records in the DB use this exact format and have `ocd_id = NULL`. CA records should follow the same pattern — `ocd_id` is not needed for the geofence lookup to work (confirmed: `geofence_lookup.go` queries `d.geo_id`, not `d.ocd_id`).

### Pattern 4: ST_IsValid Check — Post-Import Verification
**What:** TIGER data is generally valid but the success criterion explicitly requires checking
**How geopandas detects invalid geometries:**
```python
invalid = gdf[~gdf.geometry.is_valid]
if len(invalid) > 0:
    print(f"  WARNING: {len(invalid)} invalid geometries — applying make_valid()")
    gdf.geometry = gdf.geometry.make_valid()
```

**Post-import SQL check (verification step):**
```sql
SELECT COUNT(*)
FROM essentials.geofence_boundaries
WHERE state = '06' AND mtfcc = 'G4110'
AND NOT ST_IsValid(geometry);
-- Expected: 0
```

### Pattern 5: Idempotent Import — Unique Constraint Handling
**What:** `geofence_boundaries` has `UNIQUE (geo_id, mtfcc)` constraint (Phase 32)
**Behavior:** `to_postgis(if_exists='append')` will raise on duplicate. Use the established `import_individually` fallback pattern from `import_ca_legislative_geofences.py`.

```python
try:
    gdf_clean.to_postgis("geofence_boundaries", engine, schema='essentials',
                         if_exists='append', index=False)
except Exception as e:
    if "unique" in str(e).lower() or "duplicate" in str(e).lower():
        return import_individually(gdf_clean, engine)
    raise
```

### Anti-Patterns to Avoid
- **Importing all PLACE records without MTFCC filter:** The PLACE shapefile contains G4150 (CDPs). CDPs do not correspond to elected city councils. Importing them would cause false positive city council matches for unincorporated communities.
- **Filtering to LA County spatially:** TIGER PLACE has only `STATEFP` (not `COUNTYFP`) in the PLACE file. Spatial filtering against the LA County boundary adds complexity and breaks the pipeline's reusability for other CA counties. Import all CA G4110 (~482 records — manageable size).
- **Using the legacy `import_shapefiles_fixed.py` as a template:** It doesn't filter by MTFCC and uses `get_db_engine()` (non-canonical name). Always model new scripts on `import_ca_legislative_geofences.py`.
- **Skipping the ST_IsValid check:** It's an explicit success criterion (#5). Include both the pre-import Python check (`gdf.geometry.is_valid`) and the post-import SQL verification.
- **Setting ocd_id for G4110:** The existing Indiana G4110 records have NULL ocd_id, the lookup code doesn't use it, and PLACE OCD-IDs require non-trivial name normalization. Leave NULL for consistency.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Geometry validity repair | Custom polygon fixer | `gdf.geometry.make_valid()` | geopandas 1.1.2 wraps shapely 2.0's `make_valid()` which handles self-intersections, ring directions, and duplicate points |
| CRS detection/reprojection | Manual coordinate transformation | `gdf.to_crs("EPSG:4326")` | geopandas handles CRS metadata and projects correctly; TIGER ships in NAD83 (EPSG:4269) by default |
| ZIP download with progress | Custom download logic | Reuse `download_file()` pattern from `import_ca_legislative_geofences.py` | Already works, handles streaming, progress reporting, and skip-if-exists |
| MTFCC filtering logic | Complex string parsing | `gdf[gdf['MTFCC'] == 'G4110']` | MTFCC is a clean categorical column in TIGER shapefiles |

**Key insight:** The import pattern is fully established. This phase adds one new script that is ~80% copy of the existing canonical script with a different URL, different MTFCC filter, and a simpler (no OCD-ID) record structure.

## Common Pitfalls

### Pitfall 1: Importing CDPs alongside Incorporated Places
**What goes wrong:** PLACE shapefile contains both G4110 (cities) and G4150 (CDPs). Without the MTFCC filter, Malibu (a CDP in many areas) and other unincorporated communities get imported as if they were cities. This causes the lookup to return city council officials for addresses in unincorporated LA County.
**Why it happens:** The existing `import_shapefiles_fixed.py` imports `place_ca` without filtering — it was written before the MTFCC-filtering discipline was established.
**How to avoid:** Always filter `gdf = gdf[gdf['MTFCC'] == 'G4110']` immediately after loading.
**Warning signs:** Row count after import is much higher than ~482 (full CA G4110 count). CA has ~480 incorporated places; ~1100+ CDPs.

### Pitfall 2: Unique Constraint Failure on Re-run
**What goes wrong:** Running the import script twice raises a psycopg2 unique constraint violation, aborting the entire import batch mid-way.
**Why it happens:** `to_postgis(if_exists='append')` does a batch INSERT that fails if any row already exists.
**How to avoid:** Use the `import_individually()` fallback that catches the exception and falls through to row-by-row mode, skipping duplicates.
**Warning signs:** `ERROR: duplicate key value violates unique constraint "geofence_boundaries_geo_id_mtfcc_key"`.

### Pitfall 3: CRS Mismatch — TIGER Ships in NAD83 Not WGS84
**What goes wrong:** TIGER PLACE shapefile uses EPSG:4269 (NAD83). PostGIS geometry column expects EPSG:4326 (WGS84). Without reprojection, ST_Covers queries with `ST_SetSRID(ST_MakePoint(lng, lat), 4326)` will silently fail to match.
**Why it happens:** NAD83 and WGS84 differ by up to ~2 meters in CONUS — small enough to pass visual inspection but sufficient to miss boundary-adjacent points.
**How to avoid:** Always check `if gdf.crs != "EPSG:4326": gdf = gdf.to_crs("EPSG:4326")` — same pattern used in all existing scripts.
**Warning signs:** Import succeeds but LA City Hall point-in-polygon test returns no G4110 hits.

### Pitfall 4: FUNCSTAT Filter — Active Places Only
**What goes wrong:** TIGER PLACE includes places with `FUNCSTAT = 'F'` (fictitious) or `'N'` (nonfunctioning). These can create false G4110 matches for dissolved cities or statistical areas.
**Why it happens:** Census tracks historical and statistical boundaries alongside active governmental places.
**How to avoid:** Filter `gdf = gdf[gdf['FUNCSTAT'] == 'A']` (active governmental) if this produces unexpectedly high counts. However: the existing Indiana import didn't use this filter and produced clean results (566 G4110 records = valid Indiana incorporated places count). For CA, verify the final count is approximately 482.
**Warning signs:** Final count significantly above 482 after MTFCC filter.
**Confidence:** LOW — this is a precautionary note; the existing pattern does not apply FUNCSTAT filtering and works correctly for Indiana.

### Pitfall 5: geo_id Collision Between States
**What goes wrong:** A 7-character geo_id like `0644000` (LA city, CA) collides with a same-MTFCC record from another state that happens to have the same GEOID. The unique constraint is on `(geo_id, mtfcc)` not `(geo_id, mtfcc, state)`.
**Why it happens:** TIGER GEOIDs include the state FIPS as a prefix, so collision is impossible: `06` (CA) prefixes are distinct from `18` (IN) prefixes. This is a non-issue in practice but worth confirming — CA place geo_ids all start with `06`, Indiana with `18`.
**How to avoid:** No action needed — TIGER GEOIDs embed the state FIPS prefix.

## Code Examples

### Complete import_ca_place_boundaries.py (canonical template)

```python
#!/usr/bin/env python3
"""
Import California incorporated place boundaries from Census TIGER/Line shapefiles.

Imports:
  - Incorporated Places (cities/towns) for California — MTFCC G4110

These link to essentials.districts via geo_id for address-based city council lookups.
geo_id format: STATEFP(2) + PLACEFP(5) = 7 chars (e.g., "0644000" for Los Angeles city)

Requires: python3.13 -m pip install -r requirements.txt
Usage: DATABASE_URL="postgresql://..." python3 import_ca_place_boundaries.py
  Or: automatically reads from ../.env.local
"""

import sys
import requests
import zipfile
import geopandas as gpd
from sqlalchemy import text
from pathlib import Path
from datetime import datetime

sys.path.insert(0, str(Path(__file__).parent))
from utils import get_engine, load_env

YEAR = 2024
CA_FIPS = "06"
WORK_DIR = Path("./shapefile_data")
PLACE_URL = f"https://www2.census.gov/geo/tiger/TIGER{YEAR}/PLACE/tl_{YEAR}_{CA_FIPS}_place.zip"
MTFCC_FILTER = "G4110"  # Incorporated Place only — exclude G4150 (CDP) and G4210


def download_file(url, dest):
    if dest.exists():
        print(f"  Already downloaded: {dest.name}")
        return
    print(f"  Downloading: {dest.name}...")
    response = requests.get(url, stream=True)
    response.raise_for_status()
    total_size = int(response.headers.get('content-length', 0))
    downloaded = 0
    with open(dest, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
            downloaded += len(chunk)
            if total_size > 0:
                pct = (downloaded / total_size) * 100
                print(f"\r    Progress: {pct:.1f}%", end='', flush=True)
    print(f"\r  Downloaded: {dest.name}          ")


def extract_shapefile(zip_path, extract_dir):
    if extract_dir.exists():
        print(f"  Already extracted: {extract_dir.name}")
        return
    print(f"  Extracting: {zip_path.name}...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_dir)


def import_individually(gdf, engine):
    """Import records one by one, skipping duplicates"""
    imported = 0
    skipped = 0
    for idx in range(len(gdf)):
        single = gdf.iloc[[idx]]
        try:
            single.to_postgis("geofence_boundaries", engine,
                              schema='essentials', if_exists='append', index=False)
            imported += 1
        except Exception:
            skipped += 1
    print(f"  Imported {imported}, skipped {skipped} duplicates")
    return imported


def import_to_postgis(shp_path, engine):
    print(f"  Loading shapefile: {shp_path.name}...")
    gdf = gpd.read_file(shp_path)

    # Filter to CA incorporated places only
    if 'STATEFP' in gdf.columns:
        gdf = gdf[gdf['STATEFP'] == CA_FIPS]
    gdf = gdf[gdf['MTFCC'] == MTFCC_FILTER]   # G4110 only — exclude CDPs

    if len(gdf) == 0:
        print("  No records found after filtering")
        return 0

    # Reproject to WGS84
    if gdf.crs != "EPSG:4326":
        print(f"  Reprojecting from {gdf.crs} to EPSG:4326...")
        gdf = gdf.to_crs("EPSG:4326")

    # Validate geometry before import
    invalid_mask = ~gdf.geometry.is_valid
    if invalid_mask.any():
        print(f"  WARNING: {invalid_mask.sum()} invalid geometries — applying make_valid()")
        gdf.geometry = gdf.geometry.make_valid()

    # Build clean dataframe
    name_col = 'NAMELSAD' if 'NAMELSAD' in gdf.columns else 'NAME'
    records = []
    for _, row in gdf.iterrows():
        records.append({
            'geo_id': row['GEOID'],
            'name': row.get(name_col, ''),
            'mtfcc': row.get('MTFCC', MTFCC_FILTER),
            'state': row.get('STATEFP', CA_FIPS),
            'geometry': row['geometry'],
            'source': f'census_tiger_{YEAR}',
            'imported_at': datetime.now().isoformat(),
        })
        # Note: ocd_id intentionally NULL (consistent with Indiana G4110 pattern)

    gdf_clean = gpd.GeoDataFrame(records, geometry='geometry', crs="EPSG:4326")
    print(f"  Found {len(gdf_clean)} CA incorporated places (G4110)")
    print(f"  Sample: {gdf_clean['name'].head(5).tolist()}")

    try:
        gdf_clean.to_postgis("geofence_boundaries", engine,
                             schema='essentials', if_exists='append', index=False)
        print(f"  Imported {len(gdf_clean)} records")
        return len(gdf_clean)
    except Exception as e:
        if "unique" in str(e).lower() or "duplicate" in str(e).lower():
            print("  Some records exist, importing individually...")
            return import_individually(gdf_clean, engine)
        print(f"  Import failed: {e}")
        raise


def verify_import(engine):
    """Verify import: count, validity, point-in-polygon test"""
    print(f"\n{'=' * 60}")
    print("Verification")
    print(f"{'=' * 60}")
    with engine.connect() as conn:
        # Count
        r = conn.execute(text(
            "SELECT COUNT(*) FROM essentials.geofence_boundaries "
            "WHERE state = '06' AND mtfcc = 'G4110'"
        ))
        print(f"\n  CA G4110 records: {r.scalar()}")

        # ST_IsValid check (success criterion #5)
        r2 = conn.execute(text(
            "SELECT COUNT(*) FROM essentials.geofence_boundaries "
            "WHERE state = '06' AND mtfcc = 'G4110' AND NOT ST_IsValid(geometry)"
        ))
        invalid_count = r2.scalar()
        print(f"  Invalid geometries: {invalid_count} (expected: 0)")

        # Point-in-polygon test: LA City Hall (34.0537, -118.2427)
        print("\n  Point-in-polygon test (LA City Hall: 34.0537, -118.2427):")
        r3 = conn.execute(text("""
            SELECT geo_id, name, mtfcc
            FROM essentials.geofence_boundaries
            WHERE ST_Covers(
                geometry,
                ST_SetSRID(ST_MakePoint(-118.2427, 34.0537), 4326)
            )
            AND mtfcc = 'G4110'
        """))
        hits = list(r3)
        if hits:
            for row in hits:
                print(f"    {row[2]} | geo_id={row[0]} | {row[1]}")
            print("  SUCCESS: LA City Hall resolves to G4110 boundary")
        else:
            print("  WARNING: No G4110 hit for LA City Hall")

        # Test a suburban city: Pasadena City Hall (34.1478, -118.1445)
        print("\n  Point-in-polygon test (Pasadena City Hall: 34.1478, -118.1445):")
        r4 = conn.execute(text("""
            SELECT geo_id, name, mtfcc
            FROM essentials.geofence_boundaries
            WHERE ST_Covers(
                geometry,
                ST_SetSRID(ST_MakePoint(-118.1445, 34.1478), 4326)
            )
            AND mtfcc = 'G4110'
        """))
        hits4 = list(r4)
        for row in hits4:
            print(f"    {row[2]} | geo_id={row[0]} | {row[1]}")


def main():
    print("=" * 60)
    print("Import California Incorporated Place Boundaries (G4110)")
    print(f"Source: Census TIGER/Line {YEAR}")
    print("=" * 60)

    load_env()
    engine = get_engine()

    with engine.connect() as conn:
        r = conn.execute(text(
            "SELECT COUNT(*) FROM essentials.geofence_boundaries "
            "WHERE state = '06' AND mtfcc = 'G4110'"
        ))
        print(f"\n  Current CA G4110 count: {r.scalar()}")

    WORK_DIR.mkdir(exist_ok=True)

    filename = WORK_DIR / Path(PLACE_URL.split('/')[-1])
    download_file(PLACE_URL, filename)

    extract_dir = WORK_DIR / filename.stem
    extract_shapefile(filename, extract_dir)

    shp_files = list(extract_dir.glob("*.shp"))
    if not shp_files:
        print(f"  No .shp file found in {extract_dir}")
        return

    count = import_to_postgis(shp_files[0], engine)

    print(f"\n{'=' * 60}")
    print(f"Import complete! Total new records: {count}")
    print(f"{'=' * 60}")

    verify_import(engine)


if __name__ == "__main__":
    main()
```

### Verification SQL Queries (run after import)

```sql
-- Count CA incorporated places (G4110)
SELECT COUNT(*) FROM essentials.geofence_boundaries
WHERE state = '06' AND mtfcc = 'G4110';
-- Expected: ~482 (California has approximately 482 incorporated cities/towns)

-- ST_IsValid check (GEO-06 success criterion #5)
SELECT COUNT(*) FROM essentials.geofence_boundaries
WHERE state = '06' AND mtfcc = 'G4110' AND NOT ST_IsValid(geometry);
-- Expected: 0

-- Full LA County address test: LA City Hall
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE ST_Covers(
    geometry,
    ST_SetSRID(ST_MakePoint(-118.2427, 34.0537), 4326)
)
ORDER BY mtfcc;
-- Expected G4110 hit: geo_id='0644000', name='Los Angeles'

-- Confirm all 5 MTFCC types now present for CA
SELECT mtfcc, COUNT(*) as count
FROM essentials.geofence_boundaries
WHERE state = '06'
GROUP BY mtfcc
ORDER BY mtfcc;
-- Expected: G4020(1), G4040(404), G4110(~482), G5200(52), G5210(40), G5220(80), G5420(346)

-- GEO-01 verification: LA County address returns NATIONAL_LOWER match
-- (already working based on prior imports)
SELECT geo_id, name, mtfcc FROM essentials.geofence_boundaries
WHERE ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-118.2427, 34.0537), 4326))
AND mtfcc = 'G5200';
-- Expected: geo_id='0634', name='Congressional District 34'
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `import_shapefiles_fixed.py` imports all PLACE MTFCC types | Filter to `MTFCC == 'G4110'` only | Phase 34 | Prevents false city matches for CDPs in unincorporated LA County areas |
| No geometry validation before import | `gdf.geometry.is_valid` check + `make_valid()` if needed | Phase 34 | Ensures success criterion #5 passes; avoids silent PostGIS topology errors |
| Ad-hoc script with duplicated utilities | `from utils import get_engine, load_env` | Phase 33 | All new scripts follow canonical pattern |

**Deprecated/outdated:**
- `import_shapefiles_fixed.py` `place_ca` entry: Lists the CA PLACE URL but doesn't filter MTFCC. Don't use as template for G4110 import — it's a legacy script.

## Open Questions

1. **CA G4110 exact count (482 confirmed vs actual)**
   - What we know: Census records ~482 incorporated places in CA as of 2024. Indiana has 566 G4110 records from TIGER.
   - What's unclear: The exact count after filtering `MTFCC == 'G4110'` from the CA PLACE shapefile.
   - Recommendation: Accept any count between 450-520 as valid. If significantly outside this range, check the MTFCC filter and FUNCSTAT=`'A'` requirement.

2. **FUNCSTAT filter — should we add it?**
   - What we know: TIGER PLACE includes FUNCSTAT field: A=active governmental, B=active, F=fictitious, N=nonfunctioning, S=statistical, I=inactive.
   - What's unclear: Whether CA has any nonfunctioning (F/N/S) incorporated places that would inflate the count or cause false matches.
   - Recommendation: Don't add FUNCSTAT filter initially. If count is unexpectedly high (>520), investigate FUNCSTAT values and add `gdf = gdf[gdf['FUNCSTAT'].isin(['A', 'B'])]`.
   - Confidence: LOW — not verified against actual CA PLACE file content.

3. **Does Phase 34 need to re-run `import_ca_legislative_geofences.py`?**
   - What we know: GEO-01/02/03 are already satisfied (52 CDs, 40 SLDU, 80 SLDL all present, all pass ST_IsValid).
   - What's unclear: Whether the success criteria require fresh verification evidence (a verification run) vs just checking current DB state.
   - Recommendation: The planner should include a verification task that checks the existing CA G5200/G5210/G5220/G5420 counts and ST_IsValid status, without re-importing. The data is already correct.

## Validation Architecture

> nyquist_validation is not present in .planning/config.json (`workflow.nyquist_validation` key absent) — skipping this section.

## Sources

### Primary (HIGH confidence)
- Direct DB query: `SELECT mtfcc, COUNT(*) FROM essentials.geofence_boundaries WHERE state = '06' GROUP BY mtfcc` — confirmed existing counts (G5200: 52, G5210: 40, G5220: 80, G5420: 346, G4110: 0)
- Direct DB query: `ST_IsValid` check on all CA boundaries — 0 invalid geometries confirmed
- Direct DB query: LA City Hall point-in-polygon (G5200, G5210, G5220, G5420, G4020, G4040 all hit; G4110 missing — confirms G4110 is the gap)
- Direct DB query: `essentials.districts` schema — districts.`geo_id` matches geofence_boundaries.`geo_id` for Bloomington IN (confirmed join pattern)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geofence_lookup.go` — confirmed `FindPoliticiansByGeoMatches` uses `d.geo_id` (not ocd_id) for matching; G4110 maps to `['LOCAL', 'LOCAL_EXEC']`
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/import_ca_legislative_geofences.py` — canonical script pattern confirmed
- `curl -sI https://www2.census.gov/geo/tiger/TIGER2024/PLACE/tl_2024_06_place.zip` — HTTP 200, 9.8 MB confirmed
- `curl -sI https://www2.census.gov/geo/tiger/TIGER2024/UNSD/tl_2024_06_unsd.zip` — HTTP 200, 4.3 MB confirmed (needed for GEO-05 verification only)
- `/Users/chrisandrews/Documents/GitHub/.planning/STATE.md` — key v1.6 constraint: "Import UNSD (G5420) only, never G5400/G5410"
- `/Users/chrisandrews/Documents/GitHub/.planning/REQUIREMENTS.md` — GEO-01 through GEO-06 confirmed

### Secondary (MEDIUM confidence)
- WebSearch: geopandas 1.1.2 `make_valid()` and `is_valid` — verified by official geopandas docs URL at https://geopandas.org/en/stable/docs/reference/api/geopandas.GeoSeries.make_valid.html
- California incorporated place count ~482 — consistent with Census Bureau data, confirmed by TIGER PLACE structure
- TIGER PLACE MTFCC values (G4110, G4150, G4210) — from TIGER/Line Technical Documentation, cross-referenced with existing Indiana import results showing G4110: 566 records

### Tertiary (LOW confidence)
- FUNCSTAT filtering need — not verified against actual CA PLACE shapefile content
- Exact CA G4110 count (482 estimate) — not verified by downloading/inspecting the actual file

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — same as Phase 33, fully locked
- Architecture: HIGH — direct DB queries confirm current state and gap; canonical pattern confirmed from existing scripts
- Pitfalls: MEDIUM-HIGH — MTFCC filter pitfall is confirmed from legacy script analysis; FUNCSTAT pitfall is LOW confidence (precautionary)

**Research date:** 2026-02-24
**Valid until:** 2026-05-24 (TIGER 2024 files are stable; CA incorporated place count changes only via Census BAS process, which is annual)
