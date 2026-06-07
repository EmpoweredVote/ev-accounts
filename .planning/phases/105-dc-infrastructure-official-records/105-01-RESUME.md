# Phase 105-01 Resume Checkpoint

Execution interrupted at context limit. Tasks 1 and 2 are committed. Resume from Task 3.

## Committed so far
- `d8cfbcd` feat(105-01): migration 284 — DC government stub + 19 district records (DCIN-01, DCIN-02)
- `f0a6c10` feat(105-01): extend load-state-tiger-boundaries.ts for DC sldl — allowlist, type map, MTFCC assertion (DCIN-03)

## Deviation noted
Migration 284 verification: `SELECT COUNT(*) FROM essentials.districts WHERE state='DC'` returns 20 (not 19). The extra row is geo_id='1198' district_type='NATIONAL_LOWER' — a pre-existing Cicero-era import, NOT created by migration 284. All 19 new rows (9 CITY_COUNCIL + 9 SCHOOL_BOARD + 1 NATIONAL_LOWER dc-national-lower) exist with correct government_id FKs. This is acceptable and noted in SUMMARY.md.

## Task 3: Run geofence_boundaries import + Seed geo_districts + Create seed script (DCIN-03)

### Step A — Run live geofence_boundaries import:
```bash
cd C:/EV-Accounts
npx tsx backend/scripts/load-state-tiger-boundaries.ts --state DC --fips 11 --layers sldl
```
Expected output: "Inserted (boundaries): 8" — 8 ward polygons in geofence_boundaries with state='11', mtfcc='G5220'.

### Step B — Create seed-dc-ward-geo-districts.sh:

The script needs to be created at `backend/scripts/seed-dc-ward-geo-districts.sh`. It:
1. Downloads tl_2024_11_sldl.zip from https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_11_sldl.zip
2. Reprojects NAD83 → EPSG:4326 via ogr2ogr into a staging table
3. Inserts into essentials.geo_districts with layer='dc_ward', geoid='11001'-'11008'

**Windows ogr2ogr requirements** (PITFALL-8):
- Use SESSION POOLER URL, not direct DB host
- Set PROJ_LIB="C:/Program Files/GDAL/projlib"
- Check ogr2ogr version first: `ogr2ogr --version`

After creating the script, run it: `bash backend/scripts/seed-dc-ward-geo-districts.sh`

### Verification:
```sql
SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE state = '11' AND mtfcc = 'G5220';
-- Expected: 8

SELECT COUNT(*) FROM essentials.geo_districts WHERE layer = 'dc_ward';
-- Expected: 8

SELECT geoid, district_num, name FROM essentials.geo_districts WHERE layer = 'dc_ward' ORDER BY geoid;
-- Expected: 11001-11008, district_num 1-8, name Ward 1-8
```

### Commit Task 3:
```
feat(105-01): seed DC ward geo_districts + geofence_boundaries — 8 ward polygons (DCIN-03)
```
Include: `backend/scripts/seed-dc-ward-geo-districts.sh` + verify outputs

---

## Task 4: Migration 285 — tiger_geoid Backfill + RPC Default Extension (DCIN-04)

Create `supabase/migrations/20260607000003_285_dc_tiger_geoid_backfill_rpc_update.sql`.

**FIRST**: Read migration 090 to check if cache_user_districts passes explicit p_layers to resolve_user_districts or calls it with no args. If no args → only resolve_user_districts needs updating.

File: `supabase/migrations/20260509000002_090_tiger_resolve_user_districts_rpcs.sql`

### Section 1 — tiger_geoid backfill (8 hardcoded UPDATEs):
```sql
UPDATE essentials.districts SET tiger_geoid = '11001' WHERE geo_id = 'dc-ward-1' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11002' WHERE geo_id = 'dc-ward-2' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11003' WHERE geo_id = 'dc-ward-3' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11004' WHERE geo_id = 'dc-ward-4' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11005' WHERE geo_id = 'dc-ward-5' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11006' WHERE geo_id = 'dc-ward-6' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11007' WHERE geo_id = 'dc-ward-7' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11008' WHERE geo_id = 'dc-ward-8' AND state = 'DC';
```

### Section 2 — resolve_user_districts with dc_ward in DEFAULT:
```sql
DROP FUNCTION IF EXISTS essentials.resolve_user_districts(float8, float8, text[]);

CREATE OR REPLACE FUNCTION essentials.resolve_user_districts(
  p_lat    float8,
  p_lng    float8,
  p_layers text[] DEFAULT ARRAY[
    'ca_assembly', 'ca_senate', 'us_house',
    'school_unified', 'school_elementary', 'school_secondary',
    'dc_ward'
  ]
)
RETURNS TABLE(layer text, geoid text, district_num text, name text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
  SELECT gd.layer, gd.geoid, gd.district_num, gd.name
  FROM essentials.geo_districts gd
  WHERE gd.layer = ANY(p_layers)
    AND public.ST_Contains(gd.geom, public.ST_SetSRID(public.ST_MakePoint(p_lng, p_lat), 4326))
$$;

GRANT EXECUTE ON FUNCTION essentials.resolve_user_districts(float8, float8, text[])
  TO authenticated, anon;
```

### Section 3 — check cache_user_districts (read migration 090 first):
Only DROP/CREATE if it passes a hardcoded ARRAY to resolve_user_districts. If it calls resolve_user_districts() with NO args, Section 2 alone is sufficient.

Apply migration via `mcp__supabase-local__apply_migration`.

### Verification:
```sql
SELECT tiger_geoid FROM essentials.districts WHERE state = 'DC' AND district_type = 'CITY_COUNCIL' AND geo_id LIKE 'dc-ward-%' ORDER BY geo_id;
-- Expected: 8 rows, '11001' through '11008'

SELECT COUNT(*) FROM essentials.districts WHERE state = 'DC' AND district_type = 'CITY_COUNCIL' AND tiger_geoid IS NULL;
-- Expected: 1 (only dc-council-at-large)

SELECT * FROM essentials.resolve_user_districts(38.9072, -77.0369);
-- Expected: row with layer='dc_ward' (DC downtown coordinates)
```

### Commit Task 4:
```
feat(105-01): migration 285 — tiger_geoid backfill + dc_ward in RPC default (DCIN-04)
```

---

## After Task 4: Write SUMMARY.md + Commit

Create `.planning/phases/105-dc-infrastructure-official-records/105-01-SUMMARY.md` using summary template.

Then update STATE.md + ROADMAP.md for plan 105-01 completion via gsd-sdk:
```bash
gsd-sdk query roadmap.update-plan-progress 105 105-01 complete
```

Commit: `docs(105-01): SUMMARY.md + tracking update`

---

## Then: Wave 2 — Plan 105-02

Spawn gsd-executor for 105-02 (DC official records — 27 politicians). Plan is at:
`.planning/phases/105-dc-infrastructure-official-records/105-02-PLAN.md`

Pre-flight: confirm 285 is max version, 19 DC district rows exist, range -600001..-600030 is free, EHN does NOT exist.
