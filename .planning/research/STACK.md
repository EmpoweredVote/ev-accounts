# Technology Stack: Location Infrastructure

**Project:** empowered-accounts
**Dimension:** Location infrastructure additions (v1.3 milestone)
**Researched:** 2026-03-09
**Confidence:** HIGH (all three primary questions verified against Supabase official docs, PostGIS official docs, and confirmed Census Bureau URLs)

This file covers only the additive stack decisions for location infrastructure. The base stack (Express 4.x, TypeScript strict, supabase-js v2, Upstash Redis, etc.) remains as documented in the 2026-02-24 version of this file and in `MEMORY.md`. Do not reread the base stack sections — they are not changed.

---

## Question 1: Column Encryption — pgsodium vs pgcrypto vs Vault

### Decision: Vault (key storage) + pgcrypto (encryption functions)

**Do NOT use pgsodium.** Supabase's own documentation states: "We do not recommend using either [Server Key Management or Transparent Column Encryption] on the Supabase platform due to their high level of operational complexity and misconfiguration risk." The `pgsodium` extension "is expected to go through a deprecation cycle in the near future." Supabase removed pgsodium-based column encryption from the dashboard UI specifically because teams kept misconfiguring it.

**Do NOT use pgsodium `SECURITY LABEL` transparent column encryption.** This is the feature being deprecated. It automatically creates triggers and decryption views on labeled columns. The operational risk (trigger ordering, RLS policy gaps, migration complications) outweighs the convenience. Supabase removed it from the UI.

**Use Supabase Vault to store the encryption key as a named secret.** Vault's API is explicitly documented as stable through the pgsodium deprecation — "The Vault extension won't be impacted. Its internal implementation will shift away from pgsodium, but the interface and API will remain unchanged." Vault stores the key outside the database itself; only the encrypted data lives in the table.

**Use pgcrypto (`pgp_sym_encrypt_bytea` / `pgp_sym_decrypt_bytea`) for the actual encrypt/decrypt operations.** pgcrypto is a core Postgres extension, stable, not deprecated, and uses authenticated encryption (PGP format includes integrity checking). The `_bytea` variants are required when the plaintext is binary (lat/lng packed as `float8` bytes) — using `pgp_sym_decrypt` (text variant) on bytea data will produce garbled output.

### The hybrid pattern: Vault key + pgcrypto functions

```sql
-- Step 1: Store the encryption passphrase in Vault (run once, in a migration or manually)
-- Returns a UUID — save this as COORDINATE_ENCRYPTION_KEY_ID env var or hard-reference by name
SELECT vault.create_secret(
  'your-strong-random-passphrase-here',
  'coordinate_encryption_key',
  'Symmetric key for lat/lng column encryption on connected_profiles'
);

-- Step 2: Create a SECURITY DEFINER helper that exposes the decrypted key
-- to privileged functions without exposing vault.decrypted_secrets broadly.
-- SET search_path = '' is required per project convention.
CREATE OR REPLACE FUNCTION connect.get_coordinate_key()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT decrypted_secret
  FROM vault.decrypted_secrets
  WHERE name = 'coordinate_encryption_key'
  LIMIT 1;
$$;

-- Revoke public access; only service role / other SECURITY DEFINER functions call this
REVOKE ALL ON FUNCTION connect.get_coordinate_key() FROM PUBLIC;

-- Step 3: Encrypt lat/lng on write
-- Coordinates are packed as float8 (8 bytes each) → bytea, then PGP-encrypted
-- Column type: bytea NOT NULL
CREATE OR REPLACE FUNCTION connect.upsert_user_location(
  p_user_id uuid,
  p_lat double precision,
  p_lng double precision
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_key text;
  v_enc_lat bytea;
  v_enc_lng bytea;
BEGIN
  -- Retrieve key from Vault (never leaves this function as plaintext)
  SELECT connect.get_coordinate_key() INTO v_key;

  -- Pack float8 to bytea, then encrypt
  -- extensions.pgp_sym_encrypt_bytea because pgcrypto installs in extensions schema
  v_enc_lat := extensions.pgp_sym_encrypt_bytea(
    ('x' || lpad(to_hex(('0'::bytea || p_lat::text::bytea)::text::bigint::bit(64)::text), 16, '0'))::bytea,
    v_key
  );
  -- NOTE: simpler approach — store as text of the float, encrypt as text:
  -- extensions.pgp_sym_encrypt(p_lat::text, v_key) → bytea
  -- Then decrypt with: extensions.pgp_sym_decrypt(enc_col, key)::double precision
  -- This is cleaner and avoids binary float packing complexity.

  UPDATE connect.connected_profiles
  SET
    encrypted_lat = extensions.pgp_sym_encrypt(p_lat::text, v_key),
    encrypted_lng = extensions.pgp_sym_encrypt(p_lng::text, v_key),
    location_updated_at = now()
  WHERE user_id = p_user_id;
END;
$$;

-- Step 4: Decrypt on read (inside resolve_user_jurisdiction)
CREATE OR REPLACE FUNCTION connect.resolve_user_jurisdiction(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_key text;
  v_lat double precision;
  v_lng double precision;
  v_result jsonb;
BEGIN
  SELECT connect.get_coordinate_key() INTO v_key;

  SELECT
    extensions.pgp_sym_decrypt(encrypted_lat, v_key)::double precision,
    extensions.pgp_sym_decrypt(encrypted_lng, v_key)::double precision
  INTO v_lat, v_lng
  FROM connect.connected_profiles
  WHERE user_id = p_user_id;

  -- ST_Contains point-in-polygon lookup (see Question 2)
  SELECT jsonb_build_object(
    'congressional_district', cd.district_number,
    'state_senate_district',  su.district_number,
    'state_house_district',   sl.district_number,
    'county_fips',            co.county_fips,
    'place_name',             pl.place_name
  ) INTO v_result
  FROM geo.congressional_districts  cd,
       geo.state_senate_districts   su,
       geo.state_house_districts    sl,
       geo.counties                 co,
       geo.places                   pl
  WHERE ST_Contains(cd.geom, ST_SetSRID(ST_MakePoint(v_lng, v_lat), 4326))
    AND ST_Contains(su.geom, ST_SetSRID(ST_MakePoint(v_lng, v_lat), 4326))
    AND ST_Contains(sl.geom, ST_SetSRID(ST_MakePoint(v_lng, v_lat), 4326))
    AND ST_Contains(co.geom, ST_SetSRID(ST_MakePoint(v_lng, v_lat), 4326))
    AND ST_Contains(pl.geom, ST_SetSRID(ST_MakePoint(v_lng, v_lat), 4326));

  RETURN v_result;
END;
$$;
```

### Critical schema note for pgcrypto in Supabase

Supabase installs pgcrypto in the `extensions` schema, not `public`. All pgcrypto function calls inside SQL functions with `SET search_path = ''` must be fully qualified:

```sql
extensions.pgp_sym_encrypt(plaintext, key)    -- returns bytea
extensions.pgp_sym_decrypt(ciphertext, key)   -- returns text
```

Because the project convention is `SET search_path = ''` on all SECURITY DEFINER functions, this full qualification is non-optional. A call to bare `pgp_sym_encrypt()` will fail with "function not found."

### Column type

```sql
-- On connect.connected_profiles:
ALTER TABLE connect.connected_profiles
  ADD COLUMN encrypted_lat  bytea,
  ADD COLUMN encrypted_lng  bytea,
  ADD COLUMN location_updated_at timestamptz;
```

Both columns are `bytea`. The application and all RPC callers never see the raw float values. The only columns that exist in the table are the encrypted bytea blobs.

### TypeScript handling of bytea columns

Supabase JS returns `bytea` columns as `string` (base64-encoded) in the Row type generated by `supabase gen types`. This is correct — your TypeScript types will show `encrypted_lat: string | null`. Do not attempt to parse this value in application code. The RPC layer handles all decrypt operations; the application code only receives the output struct from `resolve_user_jurisdiction`, never the raw bytea.

If you ever need to pass `bytea` values to an RPC from TypeScript (you should not for this design), encode them as a hex string prefixed with `\x`.

### What NOT to use

| Avoid | Why |
|-------|-----|
| `pgsodium` SECURITY LABEL transparent column encryption | Explicitly not recommended by Supabase for new projects. Pending deprecation. Removed from Studio UI. Do not use `ENCRYPT WITH KEY ID` syntax. |
| `pgsodium.crypto_aead_det_encrypt()` directly | Same deprecation path as TCE. Do not call pgsodium functions directly in new code. |
| `pgcrypto` raw `encrypt()` / `decrypt()` functions | Lower-level, no integrity checking. Official pgcrypto docs call these "discouraged." Use PGP functions instead. |
| Storing the encryption key in the database | Defeats the purpose of encryption. The key lives in Vault (external to the database's encryption layer). Never store it in a column, a constant in a function body, or an environment variable that gets embedded in a migration. |

---

## Question 2: PostGIS — Enabling and Using ST_Contains

### Enable PostGIS

Via Supabase Dashboard: Database → Extensions → search "postgis" → Enable → create schema `geo` (or use `extensions`). Alternatively via migration:

```sql
CREATE SCHEMA IF NOT EXISTS geo;
CREATE EXTENSION IF NOT EXISTS postgis SCHEMA extensions;
```

Supabase installs PostGIS in the `extensions` schema. Functions like `ST_Contains`, `ST_MakePoint`, `ST_SetSRID` are accessible as `extensions.ST_Contains(...)` or via search_path. In SECURITY DEFINER functions with `SET search_path = ''`, use full qualification:

```sql
extensions.ST_Contains(geom_polygon, extensions.ST_SetSRID(extensions.ST_MakePoint(lng, lat), 4326))
```

### geometry vs geography — Use geometry

For Indiana-scoped data, use `geometry`, not `geography`.

**Why not geography:** The `geography` type performs spheroidal (Haversine) calculations. This is accurate for spanning continents but adds significant CPU cost. Fewer PostGIS functions support `geography` directly. The PostGIS documentation explicitly states: "If your data is geographically compact (contained within a state, county or city), use the geometry type with a Cartesian projection."

**Why geometry is fine here:** Indiana spans roughly 2.5° latitude and 2° longitude. At this scale, the error introduced by planar geometry is negligible for district lookup purposes (well under 100m). Correct district assignment at state boundaries does not require spheroidal math.

**Trap to avoid:** `geometry(4326)` is NOT the same as `geography`. `geometry` with SRID 4326 stores lon/lat coordinates but performs Cartesian math. This is correct and intentional for our use case. Do not confuse the two.

### SRID — Use 4326 (WGS84)

Store all boundary geometries at SRID 4326. Reason: GPS coordinates from browsers and mobile devices are WGS84 by default. Storing boundaries and points in the same SRID means no runtime `ST_Transform` calls. User coordinates arrive as WGS84 floats; they are passed directly to `ST_MakePoint` and matched against WGS84 boundaries.

**TIGER/Line ships in SRID 4269 (NAD83).** Convert to 4326 during import with ogr2ogr (see Question 3). The difference between 4269 and 4326 is sub-meter for CONUS, but using a consistent SRID prevents hard-to-debug query errors.

### Boundary table schema

```sql
-- One table per district type in the geo schema.
-- All use geometry(MultiPolygon, 4326) — TIGER/Line uses MultiPolygon for some districts.
-- Using MultiPolygon for all tables avoids heterogeneous geometry errors.

CREATE TABLE geo.congressional_districts (
  id              serial PRIMARY KEY,
  district_number text        NOT NULL,   -- e.g. '05' (Indiana 5th)
  name            text,
  geom            geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE geo.state_senate_districts (
  id              serial PRIMARY KEY,
  district_number text        NOT NULL,
  geom            geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE geo.state_house_districts (
  id              serial PRIMARY KEY,
  district_number text        NOT NULL,
  geom            geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE geo.counties (
  id          serial PRIMARY KEY,
  county_fips text NOT NULL,   -- e.g. '18105' (Monroe County, IN)
  name        text NOT NULL,
  geom        geometry(MultiPolygon, 4326) NOT NULL
);

CREATE TABLE geo.places (
  id          serial PRIMARY KEY,
  place_fips  text NOT NULL,   -- e.g. '1807000' (Bloomington city, IN)
  place_name  text NOT NULL,
  geom        geometry(MultiPolygon, 4326) NOT NULL
);

-- Spatial indexes are critical — ST_Contains uses them automatically
CREATE INDEX ON geo.congressional_districts  USING GIST (geom);
CREATE INDEX ON geo.state_senate_districts   USING GIST (geom);
CREATE INDEX ON geo.state_house_districts    USING GIST (geom);
CREATE INDEX ON geo.counties                 USING GIST (geom);
CREATE INDEX ON geo.places                   USING GIST (geom);
```

### ST_Contains query pattern

```sql
-- Point-in-polygon: does the district boundary contain the user's location?
-- ST_MakePoint(longitude, latitude) — note: longitude first, latitude second
-- This matches the WGS84 (x=lon, y=lat) convention.

SELECT district_number
FROM geo.congressional_districts
WHERE ST_Contains(
  geom,
  ST_SetSRID(ST_MakePoint(v_lng, v_lat), 4326)
)
LIMIT 1;
```

ST_Contains automatically uses the GIST spatial index — no additional index hint needed. From the PostGIS docs: "This function automatically includes a bounding box comparison that makes use of any spatial indexes that are available on the geometries."

**Note on argument order:** `ST_Contains(A, B)` returns true if A contains B. The polygon (district boundary) is A; the point (user location) is B. `ST_Within(B, A)` is the converse and is equivalent. Either works; `ST_Contains(polygon, point)` is the conventional form when querying "which polygon contains this point."

**Note on lon/lat order in ST_MakePoint:** PostGIS follows the mathematical (x, y) convention where x = longitude and y = latitude. This is the opposite of how humans usually say "lat, lng." Always pass `ST_MakePoint(longitude, latitude)`. The encrypted columns should be stored and named accordingly (`encrypted_lat` / `encrypted_lng`) and care taken to pass them in the correct order on decrypt.

---

## Question 3: Indiana TIGER/Line Data

### Source: Census Bureau TIGER/Line 2024

Base URL: `https://www2.census.gov/geo/tiger/TIGER2024/`

The 2024 vintage is the most recent available. All legal boundaries are as of January 1, 2024. Files were published June 2025.

### Indiana shapefiles (FIPS 18)

All files are for Indiana only except the county file, which is national and must be filtered post-import.

| District Type | Filename | URL | Size |
|---------------|----------|-----|------|
| Congressional districts (119th Congress) | `tl_2024_18_cd119.zip` | `https://www2.census.gov/geo/tiger/TIGER2024/CD/tl_2024_18_cd119.zip` | 447K |
| State Senate (upper) | `tl_2024_18_sldu.zip` | `https://www2.census.gov/geo/tiger/TIGER2024/SLDU/tl_2024_18_sldu.zip` | 1.1M |
| State House (lower) | `tl_2024_18_sldl.zip` | `https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_18_sldl.zip` | 1.6M |
| Counties (national — filter to FIPS 18) | `tl_2024_us_county.zip` | `https://www2.census.gov/geo/tiger/TIGER2024/COUNTY/tl_2024_us_county.zip` | 80M |
| Incorporated places | `tl_2024_18_place.zip` | `https://www2.census.gov/geo/tiger/TIGER2024/PLACE/tl_2024_18_place.zip` | 2.3M |
| Unified school districts | `tl_2024_18_unsd.zip` | `https://www2.census.gov/geo/tiger/TIGER2024/UNSD/tl_2024_18_unsd.zip` | 2.3M |

**On school districts:** Indiana uses Unified School Districts (`UNSD`). The `SCSD` (secondary only) and `ELSD` (elementary only) directories do not have an Indiana file because Indiana uses unified districts. Use `UNSD` only.

**On counties:** There is no state-scoped county file. The national file (`tl_2024_us_county.zip`) is 80MB. Import the full file and filter by `STATEFP = '18'` during import or immediately post-import.

### SRID note

TIGER/Line shapefiles ship with SRID **4269 (NAD83)**. This is documented in the TIGER/Line technical documentation. Convert to 4326 (WGS84) during import. For CONUS data at district scale the difference is sub-meter, but using a consistent SRID prevents query errors and avoids runtime `ST_Transform` calls.

### Download and import commands

The following commands assume:
- `ogr2ogr` is installed (part of the GDAL toolkit: `brew install gdal` or `apt install gdal-bin`)
- The Supabase database connection string is available as `$DATABASE_URL` (direct port 5432 URL, not the pooler)
- All shapefiles have been downloaded and unzipped into a working directory

```bash
# ---- Download ----
curl -O https://www2.census.gov/geo/tiger/TIGER2024/CD/tl_2024_18_cd119.zip
curl -O https://www2.census.gov/geo/tiger/TIGER2024/SLDU/tl_2024_18_sldu.zip
curl -O https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_18_sldl.zip
curl -O https://www2.census.gov/geo/tiger/TIGER2024/COUNTY/tl_2024_us_county.zip
curl -O https://www2.census.gov/geo/tiger/TIGER2024/PLACE/tl_2024_18_place.zip
curl -O https://www2.census.gov/geo/tiger/TIGER2024/UNSD/tl_2024_18_unsd.zip

for f in tl_2024_18_cd119 tl_2024_18_sldu tl_2024_18_sldl tl_2024_us_county tl_2024_18_place tl_2024_18_unsd; do
  unzip "${f}.zip" -d "${f}"
done

# ---- Import: Congressional Districts ----
ogr2ogr \
  -f "PostgreSQL" \
  PG:"$DATABASE_URL" \
  tl_2024_18_cd119/tl_2024_18_cd119.shp \
  -nln "geo.congressional_districts" \
  -nlt MULTIPOLYGON \
  -s_srs EPSG:4269 \
  -t_srs EPSG:4326 \
  -lco GEOMETRY_NAME=geom \
  -overwrite

# ---- Import: State Senate (upper chamber) ----
ogr2ogr \
  -f "PostgreSQL" \
  PG:"$DATABASE_URL" \
  tl_2024_18_sldu/tl_2024_18_sldu.shp \
  -nln "geo.state_senate_districts" \
  -nlt MULTIPOLYGON \
  -s_srs EPSG:4269 \
  -t_srs EPSG:4326 \
  -lco GEOMETRY_NAME=geom \
  -overwrite

# ---- Import: State House (lower chamber) ----
ogr2ogr \
  -f "PostgreSQL" \
  PG:"$DATABASE_URL" \
  tl_2024_18_sldl/tl_2024_18_sldl.shp \
  -nln "geo.state_house_districts" \
  -nlt MULTIPOLYGON \
  -s_srs EPSG:4269 \
  -t_srs EPSG:4326 \
  -lco GEOMETRY_NAME=geom \
  -overwrite

# ---- Import: Counties (national file — filter to Indiana STATEFP=18) ----
ogr2ogr \
  -f "PostgreSQL" \
  PG:"$DATABASE_URL" \
  tl_2024_us_county/tl_2024_us_county.shp \
  -nln "geo.counties" \
  -nlt MULTIPOLYGON \
  -s_srs EPSG:4269 \
  -t_srs EPSG:4326 \
  -lco GEOMETRY_NAME=geom \
  -where "STATEFP = '18'" \
  -overwrite

# ---- Import: Incorporated Places ----
ogr2ogr \
  -f "PostgreSQL" \
  PG:"$DATABASE_URL" \
  tl_2024_18_place/tl_2024_18_place.shp \
  -nln "geo.places" \
  -nlt MULTIPOLYGON \
  -s_srs EPSG:4269 \
  -t_srs EPSG:4326 \
  -lco GEOMETRY_NAME=geom \
  -overwrite

# ---- Import: Unified School Districts ----
ogr2ogr \
  -f "PostgreSQL" \
  PG:"$DATABASE_URL" \
  tl_2024_18_unsd/tl_2024_18_unsd.shp \
  -nln "geo.school_districts" \
  -nlt MULTIPOLYGON \
  -s_srs EPSG:4269 \
  -t_srs EPSG:4326 \
  -lco GEOMETRY_NAME=geom \
  -overwrite
```

**Key ogr2ogr flags:**

| Flag | Purpose |
|------|---------|
| `-nln` | Target table name (schema-qualified) |
| `-nlt MULTIPOLYGON` | Force geometry type to MultiPolygon — some TIGER files mix Polygon and MultiPolygon; forcing avoids type errors |
| `-s_srs EPSG:4269` | Source SRID — TIGER/Line native (NAD83) |
| `-t_srs EPSG:4326` | Target SRID — reproject to WGS84 on import |
| `-lco GEOMETRY_NAME=geom` | Names the geometry column `geom` (matches table schema above) |
| `-where "STATEFP = '18'"` | SQL filter for the national county file — import only Indiana rows |
| `-overwrite` | Replace existing table data on re-run |

**Note on shp2pgsql:** The alternative tool `shp2pgsql` (bundled with PostGIS client tools) also works but does not support `-where` filtering. For the national county file you would need to post-process with a DELETE or use ogr2ogr. ogr2ogr is recommended for consistency across all five shapefiles.

**Note on Supabase connection:** Use the direct database URL (not the connection pooler URL) for `ogr2ogr` imports. The direct URL uses port 5432. The connection pooler (port 6543, Transaction mode) may time out on large imports like the national county file.

### Post-import verification

```sql
-- Confirm counts look right
SELECT count(*) FROM geo.congressional_districts;  -- Indiana has 9 congressional districts
SELECT count(*) FROM geo.state_senate_districts;   -- Indiana State Senate: 50 districts
SELECT count(*) FROM geo.state_house_districts;    -- Indiana House of Representatives: 100 districts
SELECT count(*) FROM geo.counties;                 -- Indiana: 92 counties
SELECT count(*) FROM geo.places;                   -- Indiana: ~583 incorporated places

-- Confirm Bloomington is present
SELECT place_name, place_fips FROM geo.places WHERE place_name ILIKE '%bloomington%';

-- Confirm SRIDs were set correctly
SELECT DISTINCT ST_SRID(geom) FROM geo.congressional_districts;  -- should return 4326
SELECT DISTINCT ST_SRID(geom) FROM geo.counties;                  -- should return 4326

-- Smoke test: point-in-polygon for Bloomington city hall (~39.165, -86.526)
SELECT district_number
FROM geo.congressional_districts
WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint(-86.526, 39.165), 4326));
-- Should return '09' (Indiana's 9th congressional district)
```

---

## Summary: New Extensions Required

| Extension | Schema | Purpose | Status in Supabase |
|-----------|--------|---------|-------------------|
| `pgcrypto` | `extensions` | `pgp_sym_encrypt` / `pgp_sym_decrypt` for coordinate columns | Available by default, enable if not already enabled |
| `postgis` | `extensions` | Geometry storage and spatial functions | Must be explicitly enabled via Dashboard |
| Supabase Vault | built-in | Stores encryption key for coordinate columns | Available by default on all Supabase projects |

No new npm packages are required for location infrastructure. All work happens in SQL (migrations + SECURITY DEFINER RPCs). The TypeScript layer only calls `supabase.rpc('upsert_user_location', ...)` and `supabase.rpc('resolve_user_jurisdiction', ...)` and receives plain JSON back.

---

## Confidence Assessment

| Area | Confidence | Source |
|------|------------|--------|
| pgsodium deprecation status | HIGH | Verified against Supabase official docs (https://supabase.com/docs/guides/database/extensions/pgsodium) — explicit "do not recommend" language |
| Vault API stability | HIGH | Verified: "The Vault extension won't be impacted. Its internal implementation will shift away from pgsodium, but the interface and API will remain unchanged." |
| vault.decrypted_secrets view pattern | HIGH | Verified against https://supabase.com/docs/guides/database/vault — official docs show this exact pattern |
| pgcrypto in extensions schema (Supabase) | HIGH | Verified in GitHub discussion #627 — users confirmed pgcrypto installs in `extensions` schema in Supabase, must be fully qualified |
| pgp_sym_encrypt/decrypt function signatures | HIGH | Verified against https://www.postgresql.org/docs/current/pgcrypto.html |
| PostGIS SRID 4326 recommendation | HIGH | Verified against Supabase PostGIS docs + PostGIS workshop docs |
| geometry vs geography recommendation | HIGH | Verified against PostGIS workshop docs — explicit "geographically compact → use geometry" guidance |
| TIGER/Line SRID 4269 source | HIGH | Confirmed via ogr2ogr community sources and Census Bureau file metadata |
| TIGER/Line file URLs | HIGH | All URLs verified by direct directory listing at www2.census.gov/geo/tiger/TIGER2024/ |
| Indiana county file is national-only | HIGH | Confirmed by fetching the COUNTY/ directory — only tl_2024_us_county.zip exists, no state-scoped files |
| Indiana has no SCSD file | HIGH | Confirmed by fetching SCSD/ directory — FIPS 18 not present; Indiana uses unified districts (UNSD) |
| ogr2ogr flag syntax | MEDIUM | Syntax confirmed via multiple PostGIS loading guides; -nlt, -s_srs, -t_srs, -where, -lco flags are standard ogr2ogr; recommend dry-run with -progress flag before production import |

---

## Sources

- [Supabase Vault Documentation](https://supabase.com/docs/guides/database/vault) — vault.create_secret(), vault.decrypted_secrets view, SECURITY DEFINER pattern
- [pgsodium Pending Deprecation](https://supabase.com/docs/guides/database/extensions/pgsodium) — explicit "do not recommend" statement
- [pgsodium/TCE not recommended discussion](https://github.com/orgs/supabase/discussions/27109) — community confirmation of deprecation
- [Column encryption SQL-only now](https://github.com/orgs/supabase/discussions/18849) — dashboard removal and current SQL-only approach
- [pgcrypto in extensions schema (Supabase)](https://github.com/orgs/supabase/discussions/627) — confirmed schema location
- [PostgreSQL pgcrypto documentation](https://www.postgresql.org/docs/current/pgcrypto.html) — pgp_sym_encrypt_bytea / pgp_sym_decrypt_bytea function signatures
- [Supabase PostGIS documentation](https://supabase.com/docs/guides/database/extensions/postgis) — enable steps, SRID 4326, geometry column creation
- [PostGIS Workshop: Geography](http://postgis.net/workshops/postgis-intro/geography.html) — geometry vs geography guidance: "geographically compact → use geometry type"
- [PostGIS ST_Contains documentation](https://postgis.net/docs/ST_Contains.html) — function signature, automatic spatial index usage
- [Census Bureau TIGER/Line 2024 CD directory](https://www2.census.gov/geo/tiger/TIGER2024/CD/) — verified tl_2024_18_cd119.zip
- [Census Bureau TIGER/Line 2024 SLDU directory](https://www2.census.gov/geo/tiger/TIGER2024/SLDU/) — verified tl_2024_18_sldu.zip
- [Census Bureau TIGER/Line 2024 SLDL directory](https://www2.census.gov/geo/tiger/TIGER2024/SLDL/) — verified tl_2024_18_sldl.zip
- [Census Bureau TIGER/Line 2024 COUNTY directory](https://www2.census.gov/geo/tiger/TIGER2024/COUNTY/) — confirmed national-only file tl_2024_us_county.zip
- [Census Bureau TIGER/Line 2024 PLACE directory](https://www2.census.gov/geo/tiger/TIGER2024/PLACE/) — verified tl_2024_18_place.zip
- [Census Bureau TIGER/Line 2024 UNSD directory](https://www2.census.gov/geo/tiger/TIGER2024/UNSD/) — verified tl_2024_18_unsd.zip
