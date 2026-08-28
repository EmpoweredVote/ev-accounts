# Phase 119: MA City Council District Geofencing - Research

**Researched:** 2026-06-15
**Domain:** GIS boundary import, PostGIS, ArcGIS FeatureServer, district re-linking SQL
**Confidence:** HIGH (GIS URLs verified via live API calls; field names confirmed)

---

## Summary

Phase 119 upgrades MA city council geofencing from citywide blobs to per-ward/district polygons for five cities (Worcester, Springfield, Lowell, Brockton, Quincy), plus a trivial tiger_geoid backfill for Boston's existing 9 X0013 district rows.

Every GIS data source has been verified via live ArcGIS REST API calls in this session. Worcester has a city-maintained FeatureServer with 5 pre-dissolved council district polygons. Springfield, Lowell, Brockton, and Quincy all have ward data in MassGIS's `WARDSPRECINCTS2022_POLY` FeatureServer at a precinct level — these must be dissolved per ward in PostGIS using `ST_Union`. Cambridge is at-large — no geofencing needed, skip entirely.

**Primary recommendation:** Two import scripts: (1) a Worcester-specific script hitting the city's own FeatureServer (5 pre-dissolved polygons, ready to use), and (2) a reusable MassGIS precinct-dissolution script parameterized by city and ward count for Springfield/Lowell/Brockton/Quincy.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| GIS boundary import | CLI script (Node.js) | Database (PostGIS) | Matches established Boston pattern — fetchJson + pg pool |
| Ward polygon dissolution | Database (PostGIS ST_Union) | — | MassGIS data is at precinct level; dissolve must happen server-side |
| tiger_geoid backfill | Database (SQL migration) | — | Pure SQL UPDATE, no application logic needed |
| Office re-linking | Database (SQL migration) | — | UPDATE essentials.offices SET district_id = new_id |
| Path 0 geofencing | Database (PostGIS ST_Contains) | API | Already implemented in essentials service |

---

## Boston: tiger_geoid Backfill — Status and Spec

### Current State [VERIFIED: grep backend/migrations]

Migration 347 created 9 per-district LOCAL district rows:
- geo_id = `boston-ma-council-district-1` through `boston-ma-council-district-9`
- mtfcc = `X0013`
- state = `ma`

No subsequent migration has set `tiger_geoid` on these 9 rows. The search `grep -r "boston-ma-council-district" migrations/` returns ONLY `347_boston_government.sql`.

Additionally, migration 347 created:
- 1 LOCAL_EXEC row: geo_id='2507000', mtfcc=NULL
- 1 LOCAL at-large row: geo_id='2507000', mtfcc=NULL

The citywide G4110 rows (`2507000`) were backfilled by migration 622 — confirmed: geo_ids `2507000` is NOT in the 622 IN(...) list. Wait — migration 622 covers `2562535, 2537490, 2539835, 2523000, 2572600, 2545000`. Boston (`2507000`) is NOT in that list. So Boston's citywide LOCAL and LOCAL_EXEC tiger_geoid are also NULL.

### Boston Backfill Migration Spec

```sql
-- Step A: per-district X0013 rows (9 rows)
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type = 'LOCAL'
  AND geo_id LIKE 'boston-ma-council-district-%'
  AND mtfcc = 'X0013'
  AND tiger_geoid IS NULL;

-- Step B: citywide LOCAL row (geo_id='2507000', mtfcc=NULL)
-- tiger_geoid = geo_id = '2507000' → joins on G4110 geofence for at-large councillors
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2507000'
  AND district_type = 'LOCAL'
  AND tiger_geoid IS NULL;

-- Step C: citywide LOCAL_EXEC row (Mayor Wu)
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2507000'
  AND district_type = 'LOCAL_EXEC'
  AND tiger_geoid IS NULL;
```

Post-verification gate: 9 X0013 rows have tiger_geoid NOT NULL; 2 citywide rows (LOCAL + LOCAL_EXEC) at `2507000` have tiger_geoid NOT NULL; 0 NULL remain for Boston.

---

## GIS Data Sources

### Worcester — City-Owned FeatureServer (5 Pre-Dissolved Polygons)

**URL:** `https://services1.arcgis.com/j8dqo2DJE7mVUBU1/arcgis/rest/services/Council_Districts_2026/FeatureServer/0` [VERIFIED: live API call returned 5 features]

**Field:** `Council_District` (SmallInteger, values 1–5)

**Also verified:** Alternative 2020-census version at `City_Council_Districts_Based_on_2020_Census_Data/FeatureServer` returns layer-not-found on layer 0 — use the `Council_Districts_2026` service instead.

**Usage:** Query `where=1=1&outFields=Council_District&outSR=4326&f=geojson` → 5 features, one per district, already dissolved. No ST_Union needed.

**geo_id slug pattern:** `worcester-ma-council-district-{N}` (N = 1..5)

**mtfcc:** `X0014` (X0013 is claimed by Boston MA council districts; next available is X0014) [ASSUMED — need to confirm no other city claimed X0014 first; check load-boston-council-boundaries.ts registry comment]

**Note from load-boston-council-boundaries.ts comments:**
> Registry: X0005=LA County, X0006=SF, X0007=SD, X0008=Fremont, X0009=Berkeley, X0010=SJ, X0011=Sacramento, X0012=Portland OR council. Next available is X0014.

So X0013 is Boston. X0014 is next available for Worcester.

### Springfield, Lowell, Brockton, Quincy — MassGIS Precincts (Dissolve Required)

**URL:** `https://services6.arcgis.com/hNDcO07QfnsUMldG/arcgis/rest/services/WARDSPRECINCTS2022_POLY/FeatureServer/0` [VERIFIED: live API call returned field schema and ward counts]

**Fields:**
- `TOWN` (String): uppercase city name — `'SPRINGFIELD'`, `'LOWELL'`, `'BROCKTON'`, `'QUINCY'`
- `WARD` (String): ward number as string — `"1"` through `"8"` (no "Ward" prefix)
- `PRECINCT` (String): precinct within ward
- `WP_NAME`, `WP_DISTRIC`, `TOWN_ID`, `POP_2020`, geometry

**Ward counts verified via live API statistics query:**

| City | TOWN filter | Distinct Wards | Precincts/Ward | Total rows |
|------|-------------|---------------|----------------|------------|
| Springfield | `TOWN='SPRINGFIELD'` | 8 (1–8) | 8 each | 64 |
| Lowell | `TOWN='LOWELL'` | 8 (1–8) | 4 each | 32 |
| Brockton | `TOWN='BROCKTON'` | 7 (1–7) | 4 each | 28 |
| Quincy | `TOWN='QUINCY'` | 6 (1–6) | 5 each | 30 |

**Ward numbers match councillor count exactly:** [VERIFIED against migration files 352/353/354/355]

**Dissolution approach:** Fetch all precinct features for a city, group by WARD, union geometries in PostGIS:
```sql
INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
SELECT
  'springfield-ma-council-ward-' || ward_num,
  'springfield-ma-council-ward-' || ward_num,
  'Ward ' || ward_num,
  '25',
  'X0014',
  public.ST_MakeValid(public.ST_Union(
    public.ST_MakeValid(
      public.ST_ForcePolygonCCW(
        public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON(geometry_json)), 4326)
      )
    )
  )),
  'massgis_wardsprecincts2022',
  now()
FROM collected_precincts
GROUP BY ward_num
ON CONFLICT (geo_id, mtfcc) DO NOTHING;
```

### mtfcc Assignment — Updated Registry

| mtfcc | Owner |
|-------|-------|
| X0005 | LA County council districts |
| X0006 | SF city council districts |
| X0007 | SD city council districts |
| X0008 | Fremont council districts |
| X0009 | Berkeley council districts |
| X0010 | SJ council districts |
| X0011 | Sacramento council districts |
| X0012 | Portland OR council districts |
| X0013 | Boston MA council districts |
| X0014 | Worcester, Springfield, Lowell, Brockton, Quincy MA council/ward districts (Phase 119) |

Using a single X0014 for all Phase 119 cities is reasonable since geo_id values are globally unique. [ASSUMED — the unique constraint is (geo_id, mtfcc), so sharing X0014 across cities is fine as long as geo_ids don't collide]

---

## geo_id Slug Patterns

| City | Pattern | Example |
|------|---------|---------|
| Boston | `boston-ma-council-district-{N}` | `boston-ma-council-district-1` |
| Worcester | `worcester-ma-council-district-{N}` | `worcester-ma-council-district-1` |
| Springfield | `springfield-ma-council-ward-{N}` | `springfield-ma-council-ward-1` |
| Lowell | `lowell-ma-council-district-{N}` | `lowell-ma-council-district-1` |
| Brockton | `brockton-ma-council-ward-{N}` | `brockton-ma-council-ward-1` |
| Quincy | `quincy-ma-council-ward-{N}` | `quincy-ma-council-ward-1` |

Note: Springfield uses "Ward" in slug (city uses "Ward 1–8" language). Lowell uses "district" (city uses "District 1–8" language). Worcester uses "district" (city uses "District 1–5"). Brockton uses "ward". Quincy uses "ward".

---

## Import Script Strategy

### Two Scripts

**Script 1: `load-worcester-council-boundaries.ts`**
- Mirrors `load-boston-council-boundaries.ts` exactly
- Fetch from `Council_Districts_2026/FeatureServer/0`, field `Council_District`
- 5 features, pre-dissolved, no ST_Union
- geo_id prefix: `worcester-ma-council-district-`
- mtfcc: `X0014`
- EXPECTED_COUNT = 5, MAX_DISTRICT = 5

**Script 2: `load-ma-ward-boundaries.ts`** (parameterized for 4 cities)
- Accepts `--city SPRINGFIELD|LOWELL|BROCKTON|QUINCY` and `--ward-count N`
- Fetches all precincts for that city from MassGIS
- Collects geometries grouped by WARD field
- Dissolves per-ward using ST_Union in the INSERT SQL (all precincts for one ward in a single query call, or collect in memory and build multi-geometry union)
- geo_id prefix: configurable per city (see slug table above)
- mtfcc: `X0014`
- source: `massgis_wardsprecincts2022`

**Preferred implementation:** Collect all features in memory (up to 64 rows max), group by WARD number, then for each ward run one INSERT with `ST_Union` of the collected precinct GeoJSON geometries. Use `ST_MakeValid` on each precinct before union (handles self-intersections in source data).

**Script separation rationale:** Worcester has a separate, higher-quality source (city-owned, pre-dissolved). The MassGIS precinct-dissolution approach is only needed for the 4 cities with no city-level dissolved layer.

**Alternative considered — one parameterized script for all 5:** Would work but complicates the Worcester case unnecessarily. Two scripts is cleaner.

---

## District Re-Linking SQL Approach

### Current State (Tier 2 — all councillors share citywide LOCAL district)

All 5 cities currently have:
- 1 LOCAL district row with geo_id = city FIPS code (e.g., `2582000` for Worcester)
- All district councillors' `offices.district_id` pointing to that single LOCAL row

### Target State

For each district councillor:
- New per-ward district row: `geo_id = '{city}-ma-council-{district|ward}-{N}'`, mtfcc='X0014'
- `offices.district_id` updated from citywide LOCAL → per-ward LOCAL

For at-large councillors: keep pointing to citywide LOCAL district (no change).

### Re-Linking SQL Pattern

The migration for each city needs three steps:

**Step 1: Insert per-ward district rows** (N rows per city)
```sql
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'worcester-ma-council-district-1', 'District 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-1' AND district_type = 'LOCAL' AND state = 'ma'
);
-- ... repeat for Districts 2-5
```

**Step 2: tiger_geoid backfill on new district rows**
```sql
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id IN ('worcester-ma-council-district-1', 'worcester-ma-council-district-2', ...)
  AND tiger_geoid IS NULL;
```

**Step 3: Re-link district councillors' offices**

The district councillors are identified by external_id. The linking uses the office's current `district_id` (pointing at citywide LOCAL) and updates it to the new per-ward row. Since we know which external_id maps to which district (from the original migration), the UPDATE is deterministic:

```sql
-- Worcester District 1: Tony Economou (-258200007) → worcester-ma-council-district-1
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-1'
    AND district_type = 'LOCAL'
    AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -258200007
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2582000'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);
-- ... one UPDATE per district councillor
```

**Why not a generic UPDATE?** The mapping from district councillor to ward number is fixed (established in the original migration's title strings like 'City Councilor (District 1)'). Hardcoding by external_id is safer and more auditable than parsing title strings.

**At-large councillors:** No change needed. Their `offices.district_id` remains pointing to the citywide LOCAL row.

### City-by-City Re-Linking Summary

**Worcester (5 districts, external_ids -258200007..-258200011):**
- -258200007 Tony Economou → worcester-ma-council-district-1
- -258200008 Robert A. Bilotta → worcester-ma-council-district-2
- -258200009 John P. Fresolo → worcester-ma-council-district-3
- -258200010 Luis A. Ojeda → worcester-ma-council-district-4
- -258200011 Jose A. Rivera → worcester-ma-council-district-5

**Springfield (8 wards, external_ids -256700002 Fenton W2..-256700009 Govan W8):**
Need to confirm Ward N → external_id mapping from migration 352.

**Lowell (8 districts, external_ids -253700003..-253700012 for all 10 councillors including City Manager and Mayor):**
Districts 1-8 are the 8 district councillors. Rourke=D1, Robinson=D2, Juran=D3, McDonough=D4, Scott=D5, Chau=D6, Liang=D7, Descoteaux=D8. At-large: Mercier, Nuon. Need to confirm external_id assignments.

**Brockton (7 wards, external_ids -250900002..-250900008 for ward councillors):**
Green=W1, Tavares=W2, Griffin=W3, Nicastro=W4, Thompson=W5, Lally=W6, Asack=W7.

**Quincy (6 wards, external_ids -255574502..-255574507):**
Jacobs=W1, Ash=W2, Hubley=W3, Ryan=W4, McKee=W5, Riley=W6.

---

## Migration Architecture for Phase 119

Next available migration number: **659** (Phase 117-03 MA stance migrations consumed 656–658 after this research was written.) [VERIFIED: ls migrations/6*.sql]

### Recommended Migration Sequence

| Migration | Purpose |
|-----------|---------|
| 659 | Boston tiger_geoid backfill (11 rows: 9 X0013 + LOCAL_EXEC + LOCAL at-large) |
| 660 | Worcester: 5 per-district rows + tiger_geoid backfill + 5 office re-links |
| 661 | Springfield: 8 per-ward rows + tiger_geoid backfill + 8 office re-links |
| 662 | Lowell: 8 per-district rows + tiger_geoid backfill + 8 office re-links |
| 663 | Brockton: 7 per-ward rows + tiger_geoid backfill + 7 office re-links |
| 664 | Quincy: 6 per-ward rows + tiger_geoid backfill + 6 office re-links |

Each migration runs AFTER the corresponding city's import script has loaded ward polygons into `geofence_boundaries`. Migration has a pre-flight assertion that the required geo_ids are present in `geofence_boundaries` with mtfcc='X0014'.

### Pre-Flight Pattern (Boston pattern adapted)

```sql
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'worcester-ma-council-district-%' AND mtfcc = 'X0014';
  IF v_count < 5 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 5 X0014 worcester-ma-council-district-* rows, found %. Run load-worcester-council-boundaries.ts first.', v_count;
  END IF;
END $$;
```

---

## Architecture Patterns

### System Architecture Diagram

```
                     Import Scripts
                          |
          ┌───────────────┴───────────────┐
          │                               │
   load-worcester-council-boundaries.ts   load-ma-ward-boundaries.ts
          │                               │ (--city SPRINGFIELD|LOWELL|BROCKTON|QUINCY)
          │                               │
   ArcGIS FeatureServer              MassGIS WARDSPRECINCTS2022_POLY
   Council_Districts_2026            FeatureServer (precinct polygons)
   (5 dissolved district polygons)   (group by WARD → ST_Union in PostGIS)
          │                               │
          └───────────────┬───────────────┘
                          ▼
              essentials.geofence_boundaries
              (geo_id='city-ma-council-ward-N', mtfcc='X0014')
                          │
                    SQL Migrations
                    (659 → 664)
                          │
                          ▼
              essentials.districts
              per-ward LOCAL rows with tiger_geoid set
                          │
                          ▼
              essentials.offices
              district_id re-linked from citywide → per-ward
                          │
                          ▼
                    Path 0 Join
              ST_Contains(gb.geometry, user_point)
              WHERE d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
```

### Recommended Project Structure

No new directories needed. Scripts follow the established pattern in `backend/scripts/`. Migrations go in `backend/migrations/`.

```
backend/
├── scripts/
│   ├── load-boston-council-boundaries.ts    (existing, proven)
│   ├── load-worcester-council-boundaries.ts (new — mirrors Boston script)
│   └── load-ma-ward-boundaries.ts           (new — parameterized for 4 cities)
└── migrations/
    ├── 659_boston_council_tiger_geoid_backfill.sql
    ├── 660_worcester_council_district_geofencing.sql
    ├── 661_springfield_council_ward_geofencing.sql
    ├── 662_lowell_council_district_geofencing.sql
    ├── 663_brockton_council_ward_geofencing.sql
    └── 664_quincy_council_ward_geofencing.sql
```

### load-ma-ward-boundaries.ts Key Pattern

The key difference from the Boston script: MassGIS returns precinct polygons (multiple per ward), not dissolved ward polygons. The script must:

1. Fetch all features for `TOWN='CITY'` with `outFields=WARD,geometry`
2. Group by WARD number into a Map<number, string[]> (ward → array of GeoJSON geometries)
3. For each ward, INSERT with `ST_Union(ARRAY[geom1, geom2, ...])` or collect geometry strings and pass as array

**PostGIS ST_Union with multiple inputs from JavaScript:**

Option A — Multiple ST_GeomFromGeoJSON calls unioned:
```sql
INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
VALUES ($1, $2, '25', 'X0014',
  public.ST_MakeValid(
    public.ST_Union(ARRAY[
      public.ST_MakeValid(public.ST_ForcePolygonCCW(public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($3)), 4326))),
      public.ST_MakeValid(public.ST_ForcePolygonCCW(public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($4)), 4326))),
      ...
    ])
  ),
  $5, now())
ON CONFLICT (geo_id, mtfcc) DO NOTHING
```

Option B — Pass geometry array via unnest + aggregate (cleaner for variable counts):
```sql
INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
SELECT $1, $2, '25', 'X0014',
  public.ST_MakeValid(public.ST_Union(
    public.ST_MakeValid(public.ST_ForcePolygonCCW(
      public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON(geom_json)), 4326)
    ))
  )),
  $5, now()
FROM unnest($3::text[]) AS geom_json
ON CONFLICT (geo_id, mtfcc) DO NOTHING
```

**Option B is preferred** — passes an array of GeoJSON strings to PostgreSQL, avoids building a dynamic SQL string in JS, and handles any number of precincts per ward cleanly.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ward polygon dissolution | Custom JavaScript union | PostGIS `ST_Union` | Topological edge cases, slivers, shared borders |
| Geometry validation | Manual GeoJSON checks | `ST_MakeValid` + `ST_ForcePolygonCCW` | Boston pattern already validated; winding order requirements for PostGIS |
| Geometry transformation | Manual coordinate conversion | `ST_SetSRID(ST_Force2D(...), 4326)` | MassGIS serves Web Mercator or 4326 but needs explicit SRID |
| Ward–council correspondence | Scraping city websites | Existing migration files (351-355) have the roster | Already verified 2026-06-10 |

---

## Common Pitfalls

### Pitfall 1: mtfcc Namespace Collision
**What goes wrong:** Using X0013 for non-Boston cities — pre-flight assertion in existing migrations checks `mtfcc='X0013'` is Boston-only.
**How to avoid:** Use X0014 for all Phase 119 cities. The unique constraint is `(geo_id, mtfcc)` so multiple cities can share X0014 as long as geo_ids are unique.
**Warning signs:** The load-boston-council-boundaries.ts pre-flight explicitly rejects non-Boston X0013 rows — will fail if Worcester uses X0013.

### Pitfall 2: Precinct vs. Ward Polygons
**What goes wrong:** Importing precinct polygons instead of ward polygons — Path 0 returns a precinct-level match with no corresponding district row.
**How to avoid:** Explicitly use `ST_Union` grouped by WARD before inserting. Verify row count in geofence_boundaries equals expected ward count (not precinct count).
**Warning signs:** Post-import count of X0014 rows for a city equals precinct count (64 for Springfield) instead of ward count (8).

### Pitfall 3: TOWN Field Case Sensitivity
**What goes wrong:** Querying `TOWN='Springfield'` (mixed case) returns 0 results — MassGIS TOWN field is uppercase.
**How to avoid:** Always use uppercase: `TOWN='SPRINGFIELD'`, `TOWN='LOWELL'`, `TOWN='BROCKTON'`, `TOWN='QUINCY'`.
**Warning signs:** Count query returns 0 for the city.

### Pitfall 4: Springfield, IL ArcGIS Confusion
**What goes wrong:** ArcGIS Hub item `73fe21e85af5489f9fec487be90a1882` is Springfield, IL (Sangamon County), not Springfield, MA.
**How to avoid:** Use MassGIS `WARDSPRECINCTS2022_POLY` FeatureServer filtered by `TOWN='SPRINGFIELD'` for Springfield, MA. Do NOT use the `73fe21e85af5489f9fec487be90a1882` shapefile.
**Warning signs:** Item owner is "tlgarrison" on sangis.maps.arcgis.com — wrong state.

### Pitfall 5: Worcester Council Districts vs. Voting Wards
**What goes wrong:** Using MassGIS precinct data (WARD 1–10, 10 voting wards) for Worcester instead of the city's own council district layer (Districts 1–5).
**Why it happens:** MassGIS has Worcester wards 1–10 with 60 precinct rows. But Worcester city council uses Districts 1–5 (NOT the 10 voting wards). The city's own FeatureServer (`Council_Districts_2026`) returns the correct 5 dissolved council district polygons.
**How to avoid:** Worcester MUST use `Council_Districts_2026` FeatureServer — NOT MassGIS.
**Warning signs:** Importing 10 polygons or 60 rows for Worcester instead of 5.

### Pitfall 6: Office Re-Link Doesn't Guard Against Double-Link
**What goes wrong:** Running the re-link migration twice re-applies the UPDATE to offices already pointing at the correct per-ward district, with no-op but also no harm — UNLESS the citywide district was already re-used for a different INSERT.
**How to avoid:** Add `WHERE district_id = (SELECT id FROM districts WHERE geo_id = '{citywide_fips}' AND district_type = 'LOCAL')` to the UPDATE — this naturally makes it a no-op on second run.

### Pitfall 7: Lowell Has NO LOCAL_EXEC District
**What goes wrong:** Generating a LOCAL_EXEC backfill for Lowell — migration 353 explicitly does NOT create a LOCAL_EXEC row (Plan E council-manager model).
**How to avoid:** Boston migration spec: backfill LOCAL_EXEC (`2507000`) AND LOCAL (`2507000`). Lowell: backfill only the single LOCAL row (`2537000`). Never add a LOCAL_EXEC row for Lowell.

### Pitfall 8: outSR=4326 Required on MassGIS Queries
**What goes wrong:** Omitting `outSR=4326` from the FeatureServer query — MassGIS serves in Web Mercator (WKID 102100/3857) by default.
**How to avoid:** Always append `&outSR=4326` to FeatureServer queries. Boston script has `CRITICAL: outSR=4326 IS REQUIRED` note.
**Warning signs:** Geometries appear in wrong location or PostGIS reports unexpected SRIDs.

---

## Standard Stack

### Core
| Library | Purpose | Why Standard |
|---------|---------|--------------|
| `pg` (Pool) | DB writes | Existing pattern in all boundary import scripts |
| Node.js `https` | ArcGIS fetch | Proven in load-boston-council-boundaries.ts |
| `dotenv` | DATABASE_URL config | Standard env pattern |
| `tsx` | Run TypeScript scripts | Existing devDependency |
| PostGIS `ST_Union`, `ST_MakeValid`, `ST_ForcePolygonCCW` | Geometry operations | Already in Supabase/Postgres; proven in Boston import |

No new packages needed — all tooling is already installed.

---

## Package Legitimacy Audit

No new packages are installed in this phase. All scripts use existing dependencies.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Environment Availability

| Dependency | Required By | Available | Notes |
|------------|------------|-----------|-------|
| Node.js / tsx | Import scripts | ✓ | In use across all prior phases |
| `pg` package | DB writes in scripts | ✓ | In backend/package.json |
| DATABASE_URL env var | pg Pool connection | ✓ | Supabase session pooler |
| PostGIS (ST_Union, ST_MakeValid) | Ward dissolution | ✓ | Supabase has PostGIS |
| PROJ_LIB (GDAL) | NOT needed | — | No ogr2ogr — pure ArcGIS FeatureServer fetch |
| Internet access | ArcGIS + MassGIS REST APIs | ✓ | Public endpoints, no auth |

**Missing dependencies:** None. This phase does NOT use ogr2ogr/GDAL (pure HTTP fetch approach).

---

## Phase Requirements Map

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAGE-10 | Boston 9 per-district X0013 geofence rows have tiger_geoid set | SQL migration 659; trivial UPDATE WHERE geo_id LIKE 'boston-ma-council-district-%' |
| MAGE-11 | Worcester 5 per-district X0014 geofence rows loaded; 5 LOCAL district rows with tiger_geoid; 5 district councillors' offices re-linked | load-worcester-council-boundaries.ts + migration 660 |
| MAGE-12 | Springfield 8 per-ward X0014 geofence rows loaded (dissolved from MassGIS precincts); 8 LOCAL ward rows with tiger_geoid; 8 ward councillors' offices re-linked | load-ma-ward-boundaries.ts --city SPRINGFIELD + migration 661 |
| MAGE-13 | Lowell 8 per-district X0014 geofence rows loaded; 8 LOCAL district rows with tiger_geoid; 8 district councillors' offices re-linked | load-ma-ward-boundaries.ts --city LOWELL + migration 662 |
| MAGE-14 | Brockton 7 per-ward X0014 geofence rows loaded; 7 LOCAL ward rows with tiger_geoid; 7 ward councillors' offices re-linked | load-ma-ward-boundaries.ts --city BROCKTON + migration 663 |
| MAGE-15 | Quincy 6 per-ward X0014 geofence rows loaded; 6 LOCAL ward rows with tiger_geoid; 6 ward councillors' offices re-linked | load-ma-ward-boundaries.ts --city QUINCY + migration 664 |
</phase_requirements>

---

## Open Questions (RESOLVED)

1. **Springfield external_id to ward mapping** — RESOLVED
   - What we know: Springfield migration 352 has ward councillors at external_ids -256700002 through -256700009, with title strings like 'City Councilor (Ward 2)', 'City Councilor (Ward 3)' etc.
   - **RESOLVED mapping (confirmed from migration 352 body, used in 119-03-PLAN.md migration 661):**
     W1=Perez(-256700004), W2=Fenton(-256700002), W3=Edwards(-256700003), W4=Brown(-256700005), W5=Click-Bruce(-256700006), W6=Davila(-256700007), W7=Martin(-256700008), W8=Govan(-256700009)

2. **Lowell district councillors' external_ids** — RESOLVED
   - What we know: Migration 353 has 12 politicians total (-253700001 = Golden, -253700002 = Gitschier). District councillors are -253700003 through -253700012 (Mercier, Nuon at-large; Rourke D1, Robinson D2, Juran D3, McDonough D4, Scott D5, Chau D6, Liang D7, Descoteaux D8).
   - **RESOLVED mapping (confirmed from migration 353 body, used in 119-03-PLAN.md migration 662):**
     At-large/admin (no re-link): City Manager Golden(-253700001), Mayor Gitschier(-253700002), Mercier(-253700003), Nuon(-253700004)
     D1=Rourke(-253700005), D2=Robinson(-253700006), D3=Juran(-253700007), D4=McDonough(-253700008), D5=Scott(-253700009), D6=Chau(-253700010), D7=Liang(-253700011), D8=Descoteaux(-253700012)

3. **MassGIS TOWN='WORCESTER' returns 10 voting wards, not 5 council districts**
   - What we know: Worcester has 10 voting wards (per MassGIS) but 5 council districts (per the city's own FeatureServer).
   - Confirmed: The city FeatureServer is the correct source. Do NOT use MassGIS for Worcester.
   - Recommendation: Script comment must explicitly warn against using MassGIS for Worcester.

4. **Path 0 join — at-large councillors post-migration**
   - What we know: At-large councillors (e.g. Worcester's 5 at-large) keep `district_id` pointing to the citywide LOCAL row (geo_id='2582000'). That row's tiger_geoid would = '2582000' which joins the G4110 citywide polygon.
   - What's unclear: Do we also set tiger_geoid on the citywide LOCAL rows for the 4 Tier-2 cities (Worcester, Springfield, Brockton, Quincy)? Migration 622 set tiger_geoid on 6 cities' LOCAL+LOCAL_EXEC rows, but not these 4.
   - Recommendation: Yes — include tiger_geoid = geo_id on ALL district rows (both citywide and per-ward) in each migration. This enables at-large councillors to also appear via Path 0.

---

## Security Domain

No authentication, no user input, no API endpoints added in this phase. All work is:
- Admin CLI scripts run by operators
- SQL migrations with pre-flight guards
- No user-facing surface area changes

ASVS V5 (Input Validation): The ArcGIS field values (ward numbers) must be validated as integers in range before use in geo_id construction — already established pattern in load-boston-council-boundaries.ts (T-108-01 mitigation).

---

## Validation Architecture

### Phase Gate Verification Queries

For each city, after scripts + migrations, verify:

```sql
-- Gate 1: geofence_boundaries has correct X0014 count
SELECT COUNT(*) FROM essentials.geofence_boundaries
WHERE geo_id LIKE '{city}-ma-council-%-*' AND mtfcc = 'X0014';
-- Expected: 5 (Worcester) / 8 (Springfield) / 8 (Lowell) / 7 (Brockton) / 6 (Quincy)

-- Gate 2: district rows exist with tiger_geoid set
SELECT COUNT(*) FROM essentials.districts
WHERE state = 'ma' AND geo_id LIKE '{city}-ma-council-%' AND tiger_geoid IS NOT NULL;

-- Gate 3: Path 0 join works for a sample address in each city
SELECT d.geo_id, d.district_type, d.label
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
WHERE ST_Contains(gb.geometry, ST_SetSRID(ST_Point({test_lon}, {test_lat}), 4326))
  AND d.state = 'ma';

-- Gate 4: district councillors re-linked (no longer point to citywide LOCAL row)
SELECT COUNT(*) FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE p.external_id BETWEEN -{city_min} AND -{city_max}
  AND d.geo_id = '{city_fips}'  -- should be 0 after re-link
  AND d.district_type = 'LOCAL';
```

### Test addresses for Path 0 validation

| City | Test Address / Coordinates | Expected District |
|------|---------------------------|-------------------|
| Boston | Faneuil Hall ~(-71.056, 42.360) | District 1 (or whichever district covers downtown) |
| Worcester | City Hall ~(-71.803, 42.262) | District 1 |
| Springfield | City Hall ~(-72.589, 42.102) | Ward area for downtown |
| Lowell | City Hall ~(-71.310, 42.634) | District area for downtown |
| Brockton | City Hall ~(-71.018, 42.082) | Ward area for downtown |
| Quincy | City Hall ~(-71.003, 42.251) | Ward area for downtown |

---

## Sources

### Primary (HIGH confidence — verified via live API calls)

- `services1.arcgis.com/j8dqo2DJE7mVUBU1/.../Council_Districts_2026/FeatureServer/0` — Worcester city council districts, 5 features confirmed, fields confirmed
- `services6.arcgis.com/hNDcO07QfnsUMldG/.../WARDSPRECINCTS2022_POLY/FeatureServer/0` — MassGIS wards/precincts 2022, field schema confirmed (TOWN, WARD, PRECINCT), ward counts verified for all 4 cities
- `backend/migrations/347_boston_government.sql` — Boston X0013 district structure confirmed
- `backend/migrations/351-355_*.sql` — City council structures for all 5 cities confirmed
- `backend/scripts/load-boston-council-boundaries.ts` — Import pattern confirmed (mtfcc registry, outSR requirement, bulk/fallback pattern)
- `backend/migrations/619_*.sql`, `622_*.sql` — tiger_geoid backfill pattern confirmed

### Secondary (MEDIUM confidence)

- ArcGIS item metadata `massgis.maps.arcgis.com/sharing/rest/search` — used to discover MassGIS FeatureServer item IDs and URLs
- Brockton web map item `291e7e9c7acd477e9f069f6eb13b5d62` — confirmed Brockton wards data exists as embedded featureCollection (not a hosted FeatureServer)
- `hub.arcgis.com/maps/worcesterma::city-council-districts-based-on-2020-census-data` — confirmed 5-district structure

### Tertiary (context)

- `opendata.worcesterma.gov` — confirmed council districts portal existence

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ~~X0014 availability~~ VERIFIED — grep backend/migrations and backend/scripts confirms X0014 appears only in load-boston-council-boundaries.ts registry comment ("Next available is X0014"), never in a migration | — | Resolved |
| A2 | MassGIS WARDSPRECINCTS2022_POLY geometry is in 4326 when outSR=4326 specified | Import Script Strategy | Script inserts geometries with wrong SRID → Path 0 join fails silently |
| A3 | Springfield Ward 1–8 in MassGIS aligns with Ward 1–8 in migration 352 councillor title strings | District Re-Linking | Wrong councillor linked to wrong ward → geofencing returns wrong representative |
| A4 | Boston citywide LOCAL and LOCAL_EXEC rows (geo_id='2507000') do NOT yet have tiger_geoid set (migration 622 didn't include them) | Boston Backfill | If already set, migration 656 Step B/C are no-ops — safe but the backfill is harmless |
| A5 | Quincy citywide rows (geo_id='2555745') also lack tiger_geoid (not in migration 622's IN list) — same for Worcester '2582000', Springfield '2567000', Brockton '2509000', Lowell '2537000' | District Re-Linking — at-large coverage | At-large councillors won't appear in Path 0 results without this fix |

**Note on A5:** This is an implicit backfill needed in each city's migration — the citywide LOCAL (and LOCAL_EXEC where present) rows also need tiger_geoid set so at-large/mayor officials appear in geofenced results. Pattern: `UPDATE essentials.districts SET tiger_geoid = geo_id WHERE state='ma' AND geo_id = '{city_fips}' AND tiger_geoid IS NULL`.

---

## Metadata

**Confidence breakdown:**
- GIS data URLs: HIGH — all verified via live ArcGIS API calls this session
- Ward counts: HIGH — verified via statistics queries against live services
- Script approach: HIGH — direct adaptation of proven Boston pattern
- Migration SQL: HIGH — based on confirmed existing patterns from 619/622
- External_id → ward mappings: MEDIUM — read from migration headers; planner must verify by reading each migration body
- mtfcc X0014 availability: ASSUMED — grep confirms X0013 is Boston-only; X0014 needs pre-flight check

**Research date:** 2026-06-15
**Valid until:** 2026-09-15 (ArcGIS FeatureServer URLs may change; MassGIS data stable)
