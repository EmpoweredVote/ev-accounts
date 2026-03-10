# Phase 19: Location Schema & RPCs - Research

**Researched:** 2026-03-10
**Domain:** PostgreSQL pgcrypto (pgp_sym_encrypt), PostGIS (ST_Covers, spatial indexing), Supabase Vault, TIGER/Line 2024 shapefiles, ogr2ogr
**Confidence:** HIGH (primary findings from official PostgreSQL docs, PostGIS docs, TIGER/Line Census Bureau, Supabase docs; verified with direct codebase inspection)

---

## Summary

Phase 19 is a pure database phase: add encrypted coordinate columns to `connected_profiles`, create a PostGIS boundary table, write two SECURITY DEFINER RPCs, and document the TIGER/Line data load runbook. No TypeScript changes. No new API routes.

The core technical stack is entirely locked by the CONTEXT.md decisions: pgcrypto `pgp_sym_encrypt_bytea` / `pgp_sym_decrypt_bytea` for coordinate encryption, Supabase Vault for key storage, and PostGIS `ST_Covers` for boundary queries. The most important operational detail is that in Supabase, pgcrypto and PostGIS both live in the `extensions` schema — all function calls inside `SET search_path = ''` RPCs must use fully-qualified `extensions.pgp_sym_encrypt_bytea(...)` and `extensions.ST_Covers(...)` names. Omitting the schema qualifier will cause silent failures or wrong-schema resolution.

The migration numbering is `backend/migrations/031` (following 030). The `supabase/migrations/` counterpart uses timestamp prefix `20260310000031_`. The TIGER/Line data load is a runbook step, not a migration — the boundary table is created empty by the migration and populated manually using ogr2ogr.

One important discrepancy exists between CONTEXT.md and LOC-05 on the `resolve_user_jurisdiction` return shape — documented in the Open Questions section. The CONTEXT.md (later, more authoritative) trims the return to 5 district IDs only. LOC-05 includes `city`, `state`, and `geo_precision` fields that CONTEXT.md drops. The planner must pick one canonical spec.

**Primary recommendation:** Follow CONTEXT.md for return shape (5 district type IDs, no `city`/`state`/`geo_precision`). Use `extensions.` prefix for all pgcrypto and PostGIS function calls. Load 5 TIGER/Line layers: state-level files for CD, SLDU, SLDL, UNSD, and filter the national COUNTY file by `STATEFP='18'`.

---

## Standard Stack

This phase uses no npm packages. It is entirely PostgreSQL extensions and CLI tooling.

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| pgcrypto | built into Supabase (PostgreSQL 17) | `pgp_sym_encrypt_bytea` / `pgp_sym_decrypt_bytea` — coordinate encryption | Locked by CONTEXT.md; handles IV generation automatically; `bytea` output maps to project column type |
| PostGIS | pre-installed in Supabase (extensions schema) | `ST_Covers`, `ST_MakePoint`, `ST_SetSRID`, spatial GIST index | Locked by project decisions; already enabled per Phase 17 DEPLOY.md |
| Supabase Vault | built into Supabase | Stores encryption key (`vault.create_secret`, `vault.decrypted_secrets` view) | Locked by CONTEXT.md; keeps key separate from data and backups |
| ogr2ogr (GDAL) | any current version (3.x) | Loads TIGER/Line shapefiles into PostGIS with reprojection | Standard tool for shapefile-to-PostgreSQL loading; supports `-where` filter, `-t_srs` reprojection |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| psql | system | Run post-load SRID verification queries, direct DB inspection | Verification steps after ogr2ogr load and after RPC smoke tests |
| Supabase Dashboard → Vault UI | web | Create the `location_encryption_key` secret before running migration | One-time setup before first RPC call; alternatively via SQL |

### No npm Dependencies

This phase creates no Node.js code. All work is SQL migrations and a runbook document.

---

## Architecture Patterns

### Migration File Structure

Phase 19 uses two migration files (following project convention of one concern per file):

```
backend/migrations/
  031_location_schema.sql    # ADD COLUMN, CREATE TABLE district_boundaries, GIST index, RLS
  032_location_rpcs.sql      # connect.upsert_user_location, connect.resolve_user_jurisdiction

supabase/migrations/
  20260310000031_location_schema.sql    # same logical content, BEGIN/COMMIT wrapped
  20260310000032_location_rpcs.sql      # same logical content, BEGIN/COMMIT wrapped
```

The `backend/migrations/` files are the production deployment path (no BEGIN/COMMIT, applied via psql). The `supabase/migrations/` files are the local dev path (BEGIN/COMMIT wrapped).

### Pattern 1: SECURITY DEFINER with SET search_path = '' and Extensions Schema

All RPCs in this project follow this pattern. With `SET search_path = ''`, ALL function references — including pgcrypto and PostGIS — must use fully-qualified schema names.

```sql
-- Source: project pattern (migration 023, 027, 028, 029, 030) + Supabase discussions/627
CREATE OR REPLACE FUNCTION connect.upsert_user_location(
  p_user_id uuid,
  p_lat     float8,
  p_lng     float8
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_key text;
BEGIN
  -- Fetch encryption key from Vault (vault schema, decrypted_secrets view)
  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
   WHERE name = 'location_encryption_key'
   LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'location_encryption_key not found in Vault';
  END IF;

  -- extensions. prefix required: pgcrypto lives in extensions schema in Supabase
  UPDATE connect.connected_profiles
     SET encrypted_lat      = extensions.pgp_sym_encrypt_bytea(
                                 p_lat::text::bytea,
                                 v_key,
                                 'cipher-algo=aes256'
                               ),
         encrypted_lng      = extensions.pgp_sym_encrypt_bytea(
                                 p_lng::text::bytea,
                                 v_key,
                                 'cipher-algo=aes256'
                               ),
         location_consent   = true,
         location_set_at    = now()
   WHERE user_id = p_user_id;
END;
$$;
```

### Pattern 2: Vault Secret Lookup Inside SECURITY DEFINER

The `vault` schema is accessible inside SECURITY DEFINER functions via its fully-qualified name. Because SECURITY DEFINER elevates privileges, the function can read `vault.decrypted_secrets` even though RLS would block a normal user role.

```sql
-- Source: Supabase Vault docs (supabase.com/docs/guides/database/vault)
DECLARE
  v_key text;
BEGIN
  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
   WHERE name = 'location_encryption_key'
   LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'location_encryption_key not found in Vault';
  END IF;
  -- use v_key for pgp_sym_encrypt_bytea / pgp_sym_decrypt_bytea calls
END;
```

### Pattern 3: ST_Covers Point-in-Polygon with SRID

The requirements specify `extensions.ST_Covers` and `extensions.ST_MakePoint(lng, lat)` — longitude first.

```sql
-- Source: PostGIS docs (postgis.net/docs/ST_MakePoint.html, ST_Covers.html)
-- LOC-05 confirms: extensions.ST_MakePoint(lng, lat) — longitude FIRST

SELECT geoid, name, district_type
  FROM inform.district_boundaries
 WHERE extensions.ST_Covers(
         geom,
         extensions.ST_SetSRID(
           extensions.ST_MakePoint(v_lng, v_lat),  -- lng first (X), then lat (Y)
           4326
         )
       );
```

ST_Covers is preferred over ST_Contains for point-in-polygon because it correctly handles boundary-coincident points. ST_Contains has a geometric quirk where points on a polygon's boundary may return false; ST_Covers does not have this issue.

### Pattern 4: district_boundaries Table Schema

One table stores all 5 district types. The `district_type` column disambiguates rows during ST_Covers queries.

```sql
-- Recommended schema for inform.district_boundaries
CREATE TABLE IF NOT EXISTS inform.district_boundaries (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  district_type text        NOT NULL
    CHECK (district_type IN ('congressional', 'state_senate', 'state_house', 'county', 'school_district', 'place')),
  geoid         text        NOT NULL,
  name          text        NOT NULL,  -- NAMELSAD from TIGER/Line
  geom          geometry(MultiPolygon, 4326) NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_district_boundaries_geom
  ON inform.district_boundaries USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_district_boundaries_type
  ON inform.district_boundaries (district_type);
```

Note on geometry type: TIGER/Line polygon features are often `MultiPolygon` (counties, congressional districts can be non-contiguous). Using `geometry(MultiPolygon, 4326)` is safe. Alternatively, `geometry(Geometry, 4326)` accepts both Polygon and MultiPolygon.

### Recommended Project Structure for Phase 19

```
backend/migrations/
  031_location_schema.sql          # column additions + district_boundaries table + GIST index
  032_location_rpcs.sql            # two SECURITY DEFINER RPCs

supabase/migrations/
  20260310000031_location_schema.sql
  20260310000032_location_rpcs.sql

docs/
  RUNBOOK-TIGER-LOAD.md            # ogr2ogr commands, FIPS filter, SRID verification
```

Alternatively the runbook steps live inside the existing DEPLOY.md as a new section.

### Anti-Patterns to Avoid

- **Unqualified pgcrypto calls:** `pgp_sym_encrypt_bytea(...)` without `extensions.` prefix silently resolves wrong or errors when `SET search_path = ''`. Always use `extensions.pgp_sym_encrypt_bytea(...)`.
- **Unqualified PostGIS calls:** Same issue — `ST_Covers`, `ST_MakePoint`, `ST_SetSRID` must all be `extensions.ST_Covers(...)` etc.
- **ST_MakePoint(lat, lng) — wrong order:** PostGIS X=longitude, Y=latitude. `ST_MakePoint(lng, lat)`. Getting this backwards will produce geometrically incorrect results that may still pass the query (just match wrong districts).
- **Using ST_Contains instead of ST_Covers:** ST_Contains may return false for boundary-coincident points. Use ST_Covers.
- **Querying `vault.decrypted_secrets` without SECURITY DEFINER:** Normal authenticated users cannot read Vault. The RPC must be SECURITY DEFINER for Vault access to work.
- **Storing lat/lng as text before encrypting:** `pgp_sym_encrypt_bytea` takes `bytea` input. Convert float8 to text, then cast to bytea: `p_lat::text::bytea`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| IV generation for symmetric encryption | Custom IV injection into AES | `pgp_sym_encrypt_bytea` with `cipher-algo=aes256` | PGP symmetric format handles random IV automatically via its encrypted prefix block |
| Key storage outside DB | Environment variable or separate table | Supabase Vault (`vault.create_secret`, `vault.decrypted_secrets`) | Vault keeps key encrypted at rest using Supabase-managed key; key never appears in DB dumps or replication |
| Boundary containment logic | Custom geometry math | PostGIS `ST_Covers` | Handles all edge cases including boundary coincidence, dateline crossing, projection math |
| Shapefile reprojection | Manual coordinate transformation | `ogr2ogr -s_srs EPSG:4269 -t_srs EPSG:4326` | GDAL handles datum transformation (NAD83→WGS84) correctly; near-identical but not identical projections |
| State filtering of national shapefiles | Download all-state file then delete rows | `ogr2ogr -where "STATEFP='18'"` | Filters at import time; no wasted storage or cleanup step |

**Key insight:** pgcrypto PGP functions handle the full OpenPGP packet format including IV, session key, and integrity check. Do not use the raw `encrypt()` function — it requires manual IV management and produces no integrity check.

---

## Common Pitfalls

### Pitfall 1: Missing extensions. Prefix on pgcrypto/PostGIS Functions

**What goes wrong:** RPC compiles successfully but fails at runtime with "function pgp_sym_encrypt_bytea does not exist" or silently resolves to a wrong-schema function.

**Why it happens:** Supabase installs pgcrypto and PostGIS in the `extensions` schema. `SET search_path = ''` prevents automatic schema search. Without explicit `extensions.` prefix, function is not found.

**How to avoid:** Always write `extensions.pgp_sym_encrypt_bytea(...)`, `extensions.pgp_sym_decrypt_bytea(...)`, `extensions.ST_Covers(...)`, `extensions.ST_MakePoint(...)`, `extensions.ST_SetSRID(...)`.

**Warning signs:** `ERROR: function pgp_sym_encrypt_bytea(bytea, text, text) does not exist` at RPC call time despite pgcrypto being enabled.

### Pitfall 2: Longitude/Latitude Coordinate Order in ST_MakePoint

**What goes wrong:** Districts returned are wrong — point maps to a different location, possibly in a different state, or ST_Covers returns no match.

**Why it happens:** `ST_MakePoint(x, y)` uses Cartesian convention: X=longitude (east/west), Y=latitude (north/south). Calling `ST_MakePoint(lat, lng)` produces a geometrically inverted point.

**How to avoid:** Always write `ST_MakePoint(v_lng, v_lat)` — longitude first. LOC-05 explicitly specifies this.

**Warning signs:** Bloomington, IN (lng=-86.526, lat=39.165) smoke test returns wrong congressional district or no match.

### Pitfall 3: TIGER/Line SRID is 4269, Not 4326

**What goes wrong:** ST_Covers returns no matches or incorrect results despite geometrically correct data.

**Why it happens:** TIGER/Line shapefiles use EPSG:4269 (NAD83). Supabase coordinates are stored as EPSG:4326 (WGS84). If the boundary geometries are loaded as 4269 but the query point uses 4326 SRID, PostGIS may reject the comparison or produce incorrect results.

**How to avoid:** Use `ogr2ogr -s_srs EPSG:4269 -t_srs EPSG:4326` to reproject to WGS84 on load. Run post-load verification: `SELECT ST_SRID(geom) FROM inform.district_boundaries LIMIT 1;` — must return `4326`.

**Warning signs:** Post-load SRID query returns `4269` or `0`.

### Pitfall 4: geometry Type Mismatch (Polygon vs MultiPolygon)

**What goes wrong:** ogr2ogr load fails with geometry type constraint violation, or some geometries silently fail to load.

**Why it happens:** TIGER/Line counties and congressional districts can be MultiPolygon (islands, non-contiguous areas). If the table declares `geometry(Polygon, 4326)`, MultiPolygon features fail constraint.

**How to avoid:** Declare column as `geometry(MultiPolygon, 4326)` or `geometry(Geometry, 4326)`. Use `-nlt PROMOTE_TO_MULTI` in ogr2ogr to force all Polygon features to MultiPolygon.

**Warning signs:** Row count after ogr2ogr load is less than expected; Indiana has 9 congressional districts, 50 state senate, 100 state house seats.

### Pitfall 5: Vault Secret Not Created Before RPC Is Called

**What goes wrong:** `upsert_user_location` throws `location_encryption_key not found in Vault` at first call.

**Why it happens:** The migration creates the RPC but doesn't create the Vault secret. The secret must be created separately (via Supabase Dashboard Vault UI or `vault.create_secret()` SQL) before the RPC can succeed.

**How to avoid:** Document Vault secret creation as the first runbook step, before any RPC testing. The migration itself cannot create the secret (that would embed the key value in a migration file — a security anti-pattern).

**Warning signs:** RPC exists, columns exist, but first call raises exception.

### Pitfall 6: pgp_sym_decrypt_bytea Returns bytea, Not float8

**What goes wrong:** Cannot directly use decrypted value in ST_MakePoint — type mismatch error.

**Why it happens:** Encryption path was `p_lat::text::bytea → encrypted`. Decryption returns `bytea`. Must reverse: `decrypt_result::text::float8`.

**How to avoid:** In `resolve_user_jurisdiction`, after decryption:
```sql
v_lat := extensions.pgp_sym_decrypt_bytea(v_encrypted_lat, v_key)::text::float8;
v_lng := extensions.pgp_sym_decrypt_bytea(v_encrypted_lng, v_key)::text::float8;
```

**Warning signs:** `ERROR: operator does not exist: bytea = float8` or similar type error in RPC.

### Pitfall 7: national COUNTY File is 80MB — Filter on Load, Not After

**What goes wrong:** Loading the entire national county shapefile (all 50 states + territories) into `district_boundaries` and then deleting non-Indiana rows — wastes time and storage.

**Why it happens:** TIGER/Line county data ships as a single national file `tl_2024_us_county.zip`. State legislative and congressional data are per-state files.

**How to avoid:** Use `ogr2ogr -where "STATEFP='18'"` to load only Indiana counties. Verify: Indiana has exactly 92 counties.

**Warning signs:** `district_boundaries` row count for `district_type='county'` is much larger than 92 after load.

---

## Code Examples

### RPC Skeleton: connect.upsert_user_location

```sql
-- Source: project pattern (migrations 023/027/029/030) + PostgreSQL pgcrypto docs
-- LOC-03 spec + CONTEXT.md decisions
CREATE OR REPLACE FUNCTION connect.upsert_user_location(
  p_user_id uuid,
  p_lat     float8,
  p_lng     float8
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_key text;
BEGIN
  -- Two-pass validation (project pattern: validate before write)
  IF p_lat IS NULL OR p_lng IS NULL THEN
    RAISE EXCEPTION 'lat and lng are required';
  END IF;
  -- Basic range check
  IF p_lat < -90 OR p_lat > 90 THEN
    RAISE EXCEPTION 'lat out of range: %', p_lat;
  END IF;
  IF p_lng < -180 OR p_lng > 180 THEN
    RAISE EXCEPTION 'lng out of range: %', p_lng;
  END IF;

  -- Fetch key from Vault (SECURITY DEFINER allows vault schema access)
  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
   WHERE name = 'location_encryption_key'
   LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'location_encryption_key not found in Vault';
  END IF;

  -- Atomic write: encrypt coords, set consent and timestamp
  UPDATE connect.connected_profiles
     SET encrypted_lat    = extensions.pgp_sym_encrypt_bytea(
                               p_lat::text::bytea, v_key, 'cipher-algo=aes256'
                             ),
         encrypted_lng    = extensions.pgp_sym_encrypt_bytea(
                               p_lng::text::bytea, v_key, 'cipher-algo=aes256'
                             ),
         location_consent = true,
         location_set_at  = now()
   WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'connected_profile not found for user_id %', p_user_id;
  END IF;
END;
$$;
```

### RPC Skeleton: connect.resolve_user_jurisdiction

```sql
-- Source: PostGIS docs (ST_Covers, ST_MakePoint) + pgcrypto docs + CONTEXT.md return shape
CREATE OR REPLACE FUNCTION connect.resolve_user_jurisdiction(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_key           text;
  v_encrypted_lat bytea;
  v_encrypted_lng bytea;
  v_lat           float8;
  v_lng           float8;
  v_point         geometry;
  v_result        jsonb;
BEGIN
  -- Fetch key
  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
   WHERE name = 'location_encryption_key' LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'location_encryption_key not found in Vault';
  END IF;

  -- Fetch encrypted coords; verify consent
  SELECT encrypted_lat, encrypted_lng INTO v_encrypted_lat, v_encrypted_lng
    FROM connect.connected_profiles
   WHERE user_id = p_user_id
     AND location_consent = true;

  IF v_encrypted_lat IS NULL THEN
    RAISE EXCEPTION 'no location on file for user %', p_user_id;
  END IF;

  -- Decrypt (bytea → text → float8)
  v_lat := extensions.pgp_sym_decrypt_bytea(v_encrypted_lat, v_key)::text::float8;
  v_lng := extensions.pgp_sym_decrypt_bytea(v_encrypted_lng, v_key)::text::float8;

  -- Build geometry point (longitude FIRST per PostGIS X/Y convention)
  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(v_lng, v_lat), 4326);

  -- Build jurisdiction result (null per type when no boundary match)
  SELECT jsonb_build_object(
    'congressional',  MAX(geoid) FILTER (WHERE district_type = 'congressional'),
    'state_senate',   MAX(geoid) FILTER (WHERE district_type = 'state_senate'),
    'state_house',    MAX(geoid) FILTER (WHERE district_type = 'state_house'),
    'county',         MAX(geoid) FILTER (WHERE district_type = 'county'),
    'school_district',MAX(geoid) FILTER (WHERE district_type = 'school_district')
  )
  INTO v_result
  FROM inform.district_boundaries
  WHERE extensions.ST_Covers(geom, v_point);

  -- Raw coordinates never returned — only jurisdiction struct
  RETURN v_result;
END;
$$;
```

### ogr2ogr Load Commands (Runbook)

```bash
# Source: GDAL ogr2ogr docs (gdal.org/en/stable/drivers/vector/pg.html)
# + TIGER/Line 2024 Census Bureau filenames (census.gov TIGER2024 directories)

# Indiana FIPS: 18
# Source SRID: EPSG:4269 (NAD83 — what TIGER/Line ships in)
# Target SRID: EPSG:4326 (WGS84 — what the project stores)

# 1. Congressional Districts (119th Congress)
#    Source: https://www2.census.gov/geo/tiger/TIGER2024/CD/tl_2024_18_cd119.zip
ogr2ogr -f PostgreSQL \
  PG:"$DATABASE_URL" \
  -nln district_boundaries \
  -lco SCHEMA=inform \
  -lco GEOMETRY_NAME=geom \
  -nlt PROMOTE_TO_MULTI \
  -s_srs EPSG:4269 -t_srs EPSG:4326 \
  -sql "SELECT GEOID AS geoid, NAMELSAD AS name, 'congressional' AS district_type FROM tl_2024_18_cd119" \
  /path/to/tl_2024_18_cd119.shp \
  -append -update

# 2. State Senate (Upper Chamber)
#    Source: https://www2.census.gov/geo/tiger/TIGER2024/SLDU/tl_2024_18_sldu.zip
ogr2ogr -f PostgreSQL \
  PG:"$DATABASE_URL" \
  -nln district_boundaries \
  -lco SCHEMA=inform \
  -lco GEOMETRY_NAME=geom \
  -nlt PROMOTE_TO_MULTI \
  -s_srs EPSG:4269 -t_srs EPSG:4326 \
  -sql "SELECT GEOID AS geoid, NAMELSAD AS name, 'state_senate' AS district_type FROM tl_2024_18_sldu" \
  /path/to/tl_2024_18_sldu.shp \
  -append -update

# 3. State House (Lower Chamber)
#    Source: https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_18_sldl.zip
ogr2ogr -f PostgreSQL \
  PG:"$DATABASE_URL" \
  -nln district_boundaries \
  -lco SCHEMA=inform \
  -lco GEOMETRY_NAME=geom \
  -nlt PROMOTE_TO_MULTI \
  -s_srs EPSG:4269 -t_srs EPSG:4326 \
  -sql "SELECT GEOID AS geoid, NAMELSAD AS name, 'state_house' AS district_type FROM tl_2024_18_sldl" \
  /path/to/tl_2024_18_sldl.shp \
  -append -update

# 4. Counties (national file — filter to Indiana STATEFP='18')
#    Source: https://www2.census.gov/geo/tiger/TIGER2024/COUNTY/tl_2024_us_county.zip
ogr2ogr -f PostgreSQL \
  PG:"$DATABASE_URL" \
  -nln district_boundaries \
  -lco SCHEMA=inform \
  -lco GEOMETRY_NAME=geom \
  -nlt PROMOTE_TO_MULTI \
  -s_srs EPSG:4269 -t_srs EPSG:4326 \
  -where "STATEFP='18'" \
  -sql "SELECT GEOID AS geoid, NAMELSAD AS name, 'county' AS district_type FROM tl_2024_us_county WHERE STATEFP='18'" \
  /path/to/tl_2024_us_county.shp \
  -append -update

# 5. Unified School Districts
#    Source: https://www2.census.gov/geo/tiger/TIGER2024/UNSD/tl_2024_18_unsd.zip
ogr2ogr -f PostgreSQL \
  PG:"$DATABASE_URL" \
  -nln district_boundaries \
  -lco SCHEMA=inform \
  -lco GEOMETRY_NAME=geom \
  -nlt PROMOTE_TO_MULTI \
  -s_srs EPSG:4269 -t_srs EPSG:4326 \
  -sql "SELECT GEOID AS geoid, NAMELSAD AS name, 'school_district' AS district_type FROM tl_2024_18_unsd" \
  /path/to/tl_2024_18_unsd.shp \
  -append -update
```

**Note on `-sql` vs `-where`:** For per-state files (congressional, SLDU, SLDL, UNSD), use `-sql` to select and rename columns. For the national county file, combine `-where "STATEFP='18'"` with `-sql` or use `-where` alone and let ogr2ogr map columns. The important thing is that `geoid`, `name`, and `district_type` land in the correct columns.

**Alternative approach:** Pre-extract columns and district_type labels with a `-sql` SELECT statement, which is cleaner for remapping column names from TIGER/Line's original names (GEOID, NAMELSAD) to the table schema (geoid, name).

### Post-Load Verification Queries

```sql
-- Source: Direct schema inspection pattern from project (migration 17 research)

-- 1. Verify SRID is 4326 (not 4269)
SELECT DISTINCT ST_SRID(geom) FROM inform.district_boundaries;
-- Expected: single row with value 4326

-- 2. Row counts by district type
SELECT district_type, count(*) FROM inform.district_boundaries GROUP BY district_type ORDER BY district_type;
-- Expected (Indiana):
--   congressional   | 9     (119th Congress, Indiana has 9 seats)
--   county          | 92    (Indiana has 92 counties)
--   school_district | ~290  (Indiana UNSD count varies by year)
--   state_house     | 100
--   state_senate    | 50

-- 3. Smoke test: Bloomington, IN → Indiana 9th congressional district
-- Bloomington, IN: lat=39.1653, lng=-86.5264
SELECT geoid, name, district_type
  FROM inform.district_boundaries
 WHERE ST_Covers(
         geom,
         ST_SetSRID(ST_MakePoint(-86.5264, 39.1653), 4326)
       );
-- Expected rows include congressional geoid = '1809' (Indiana 9th)
-- Also Monroe County, IN state senate/house districts, Monroe County schools

-- 4. Verify encryption: inspect encrypted_lat must be bytea, not float
SELECT encrypted_lat FROM connect.connected_profiles WHERE encrypted_lat IS NOT NULL LIMIT 1;
-- Expected: '\x...' hex bytea, NOT a float like '39.165...'

-- 5. Verify resolve_user_jurisdiction returns no raw coordinates
SELECT connect.resolve_user_jurisdiction('<test_user_id>');
-- Expected: { "congressional": "1809", "county": "...", ... }
-- Must NOT contain lat, lng, or any float values
```

### Creating the Vault Secret (Runbook Step)

```sql
-- Source: Supabase Vault docs (supabase.com/docs/guides/database/vault)
-- Run this ONCE in Supabase Dashboard SQL Editor or via psql, BEFORE running RPCs.
-- The secret name 'location_encryption_key' is what the RPCs look up.
-- Use a strong random key (32+ bytes).

SELECT vault.create_secret(
  'your-strong-random-encryption-key-here',  -- REPLACE with real key
  'location_encryption_key',                 -- name the RPCs use
  'AES256 key for coordinate encryption'     -- description
);
```

Alternatively, use Supabase Dashboard → Database → Vault → "Add new secret" button.

### GIST Index Creation

```sql
-- Source: PostGIS spatial indexing docs (postgis.net/documentation/faq/spatial-indexes/)
-- USING GIST is mandatory — omitting it creates a b-tree index which does not accelerate spatial queries

CREATE INDEX IF NOT EXISTS idx_district_boundaries_geom
  ON inform.district_boundaries USING GIST (geom);

-- Secondary index for district_type equality filter (used in resolve_user_jurisdiction query)
CREATE INDEX IF NOT EXISTS idx_district_boundaries_type
  ON inform.district_boundaries (district_type);

-- After populating the table, run VACUUM ANALYZE for planner statistics
VACUUM ANALYZE inform.district_boundaries;
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| pgcrypto `encrypt()` with manual IV | `pgp_sym_encrypt_bytea()` with OpenPGP packet format | This project's decision | IV generated automatically; integrity check included; `cipher-algo=aes256` option available |
| ST_Contains for point-in-polygon | ST_Covers | PostGIS recommendation (current docs) | Correct handling of boundary-coincident points |
| pgsodium for column encryption | Supabase Vault + pgcrypto | Supabase deprecating pgsodium standalone | Vault is the current Supabase-endorsed pattern for secret/key management |
| Direct extension schema access | Fully-qualified `extensions.` prefix | Supabase security requirement | Required when `SET search_path = ''` is used (project standard) |

---

## Open Questions

### 1. Return Shape Discrepancy: CONTEXT.md vs LOC-05

**What we know:**

CONTEXT.md (the later, more authoritative document, gathered 2026-03-10) specifies:
```
{ congressional, state_senate, state_house, county, school_district }
```
IDs only, no names, null per type when no match.

LOC-05 (the requirements spec) specifies:
```
{ city, state, county, congressional_district, state_upper, state_lower, school_district, geo_precision }
```
Uses different key names (`congressional_district` vs `congressional`, `state_upper`/`state_lower` vs `state_senate`/`state_house`). Includes `city`, `state`, `geo_precision` fields not in CONTEXT.md. Also says `place` returns null for unincorporated addresses.

**What's unclear:** Which spec is canonical? CONTEXT.md explicitly says "Return ID only per district" and drops city/state/geo_precision. This appears to be an intentional simplification. LOC-05 includes `place` boundaries (the TIGER `PLACE` layer) which CONTEXT.md drops from the boundary scope (only 5 types: congressional, state_senate, state_house, county, school_district — no place).

**Recommendation:** Use CONTEXT.md as the canonical spec. It is the later document, reflects deliberate design decisions, and its simplicity (5 district IDs) is coherent with the stated scope. The planner should confirm this and close LOC-05's `city`, `state`, `geo_precision` fields as intentionally deferred/dropped. Key names to use: `congressional`, `state_senate`, `state_house`, `county`, `school_district`.

### 2. The `place` Layer in LOC-04

**What we know:** LOC-04 says "six Indiana TIGER/Line 2024 shapefiles loaded" including `place`. CONTEXT.md says "All 5 district types: congressional, state_senate, state_house, county, school_district" — no mention of `place`.

**What's unclear:** Whether `place` boundaries need to be loaded. LOC-05 mentions `city` returns null for unincorporated addresses — suggesting `place` data was in scope, but CONTEXT.md decisions drop it.

**Recommendation:** Do not load `place` in Phase 19 (follow CONTEXT.md). If `city` is needed in Phase 20+, the `place` layer can be added then. Document in the runbook that `tl_2024_18_place.zip` exists at the Census Bureau but is not loaded in Phase 19.

### 3. ogr2ogr Column Remapping Syntax (Minor)

**What we know:** When loading TIGER/Line files, the native column names are `GEOID` and `NAMELSAD`. The project table uses `geoid` and `name`. The `district_type` value must be injected (it's not in the shapefile).

**What's unclear:** The cleanest ogr2ogr approach for injecting a constant `district_type` value. The `-sql` option supports constant expressions in SELECT: `SELECT GEOID, NAMELSAD, 'congressional' AS district_type FROM ...`. This should work, but the exact behavior with `-append` and column mapping may need testing.

**Recommendation:** Test ogr2ogr load against a local dev database before running against production. Use the `-sql` approach to inject `district_type`. If `-sql` causes issues with column mapping, use a two-step approach: load with natural column names, then run an UPDATE to set `district_type`.

### 4. migration_numbering for backend/migrations vs supabase/migrations

**What we know:** `backend/migrations/030` exists. `supabase/migrations/` ends at `20260304000030`. The next migration in both systems would be `031`.

**What's unclear:** Whether this phase produces one migration or two (schema + RPCs separate). Phase 9 used separate files (029_xp_schema, 030_xp_rpcs). Following that pattern, Phase 19 would use 031 + 032.

**Recommendation:** Use two migrations: `031_location_schema.sql` (columns + table + indexes) and `032_location_rpcs.sql` (two RPCs). Follows Phase 9 precedent. Keeps schema and code separate, which aids rollback.

---

## Sources

### Primary (HIGH confidence)

- PostgreSQL pgcrypto official docs — function signatures for `pgp_sym_encrypt_bytea`, `pgp_sym_decrypt_bytea`, cipher-algo options, IV handling: https://www.postgresql.org/docs/current/pgcrypto.html
- PostGIS official docs — ST_Covers vs ST_Contains behavior, ST_MakePoint signature (longitude first), ST_SetSRID: https://postgis.net/docs/ST_MakePoint.html and https://postgis.net/docs/ST_Covers.html
- Supabase Vault official docs — `vault.decrypted_secrets` view schema, `vault.create_secret()` function, security pattern: https://supabase.com/docs/guides/database/vault
- TIGER/Line 2024 Census Bureau FTP — Indiana shapefile filenames confirmed by directory listing: https://www2.census.gov/geo/tiger/TIGER2024/
  - `tl_2024_18_cd119.zip` (congressional)
  - `tl_2024_18_sldu.zip` (state senate)
  - `tl_2024_18_sldl.zip` (state house)
  - `tl_2024_us_county.zip` (national, filter by STATEFP='18')
  - `tl_2024_18_unsd.zip` (unified school districts)
- GDAL ogr2ogr PostgreSQL driver docs — connection string formats, `-lco SCHEMA=`, `-nlt PROMOTE_TO_MULTI`, `-where`, `-s_srs`/`-t_srs`: https://gdal.org/en/stable/drivers/vector/pg.html
- Direct codebase inspection: `backend/migrations/023, 027, 028, 029, 030` — SECURITY DEFINER + SET search_path = '' pattern confirmed; `supabase/migrations/027` — PostGIS spatial_ref_sys RLS
- Direct codebase inspection: `supabase/migrations/004` — `connected_profiles` table structure

### Secondary (MEDIUM confidence)

- Supabase GitHub discussion #627 — pgcrypto installed in `extensions` schema, must use `extensions.pgp_sym_encrypt()` with SET search_path = '': https://github.com/orgs/supabase/discussions/627
- Supabase GitHub discussion #20936 — confirms `public.pgp_sym_encrypt()` or `extensions.pgp_sym_encrypt()` required when SET search_path omitted: https://github.com/orgs/supabase/discussions/20936
- PostGIS spatial indexing FAQ — USING GIST mandatory (not b-tree), VACUUM ANALYZE after load: https://postgis.net/documentation/faq/spatial-indexes/

### Tertiary (LOW confidence)

- WebSearch results for ogr2ogr -where "STATEFP='18'" — confirmed as standard pattern but individual ogr2ogr examples were not from authoritative sources. The GDAL official docs above cover this.

---

## Metadata

**Confidence breakdown:**

- pgcrypto functions (signatures, cipher-algo, IV): HIGH — from official PostgreSQL docs
- extensions. schema prefix requirement: HIGH — from Supabase docs + codebase discussion threads; LOC-05 explicitly specifies this
- Supabase Vault access pattern: HIGH — from official Supabase Vault docs
- PostGIS ST_Covers/ST_MakePoint: HIGH — from official PostGIS docs
- TIGER/Line 2024 filenames: HIGH — fetched directly from Census Bureau FTP directory listings
- ogr2ogr flags (-s_srs, -t_srs, -where, -nlt PROMOTE_TO_MULTI): HIGH — from GDAL official docs
- Migration numbering (031/032): HIGH — direct filesystem inspection
- Return shape discrepancy: HIGH — both documents read directly; uncertainty is a genuine spec conflict, not a research gap
- Indiana district counts (9 congressional, 50 senate, 100 house, 92 counties): MEDIUM — standard knowledge, should verify against TIGER row count post-load

**Research date:** 2026-03-10
**Valid until:** 2026-04-10 (TIGER/Line 2024 filenames stable; pgcrypto and PostGIS APIs stable; Supabase Vault API marked stable)
