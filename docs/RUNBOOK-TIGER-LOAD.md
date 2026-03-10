# Indiana TIGER/Line District Boundaries — Load Runbook

## Overview

This runbook loads Indiana TIGER/Line 2024 boundary data into `inform.district_boundaries` for use by `connect.resolve_user_jurisdiction`. Migration 031 creates the empty table and spatial index; this runbook populates it with boundary polygons for five district types (congressional, state senate, state house, county, school district). Must be run once per environment — production and local dev are separate Supabase projects and each requires its own load.

---

## Prerequisites

Before starting, confirm all of the following:

- **Migration 031 applied** — `inform.district_boundaries` table exists (run `\dt inform.` in psql)
- **Migration 032 applied** — `connect.upsert_user_location` and `connect.resolve_user_jurisdiction` RPCs exist
- **GDAL/ogr2ogr installed** — run `ogr2ogr --version`; expect `GDAL 3.x.x`
- **DATABASE_URL set** — must be the direct connection string: `postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres`
  - Do NOT use the pooler (`pooler.supabase.com:6543`) — multi-statement SQL fails on the pooler
- **psql available** — used for verification queries in Steps 4 and 5

---

## Step 1: Create the Vault Secret

This MUST happen before any RPC call. Both RPCs (`upsert_user_location` and `resolve_user_jurisdiction`) look up the encryption key by name at call time. If the secret is not found, the RPC raises an exception.

### Option A — SQL (run in Supabase Dashboard SQL Editor or psql)

First, generate a cryptographically random key:

```bash
openssl rand -base64 32
# Example output: K7gNU3sdo+OL0wNhqoVWhr3g6s1xYv72ol/pe/Unols=
```

Then create the Vault secret:

```sql
SELECT vault.create_secret(
  'K7gNU3sdo+OL0wNhqoVWhr3g6s1xYv72ol/pe/Unols=',  -- Replace with your generated key
  'location_encryption_key',                           -- This exact name is what the RPCs look up
  'AES256 symmetric key for coordinate encryption'
);
```

### Option B — Supabase Dashboard UI

Database → Vault → "Add new secret"
- Name: `location_encryption_key`
- Value: your generated key (output of `openssl rand -base64 32`)

### Important Notes

- **The secret name must be exactly `location_encryption_key`** — the RPCs look it up by this exact string. Any variation (capitalization, spacing, truncation) causes a runtime exception.
- **Minimum 32 characters** — use `openssl rand -base64 32` to generate a suitable key.
- **Never commit the key value to git** and never include it in any migration file. Keys in migration history are permanent exposure.
- **The same key must be used in every environment where the RPCs are called.** Coordinates encrypted with one key cannot be decrypted with a different key. If you rotate the key, all previously stored coordinates become unreadable.

---

## Step 2: Download TIGER/Line 2024 Shapefiles

Indiana FIPS state code: **18**

Download all 5 archives and unzip them. Note the `.shp` file path for each — these paths go into Step 3.

| District Type        | Census Bureau URL |
|----------------------|-------------------|
| Congressional (119th Congress) | `https://www2.census.gov/geo/tiger/TIGER2024/CD/tl_2024_18_cd119.zip` |
| State Senate (Upper Chamber)   | `https://www2.census.gov/geo/tiger/TIGER2024/SLDU/tl_2024_18_sldu.zip` |
| State House (Lower Chamber)    | `https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_18_sldl.zip` |
| Counties (national file)       | `https://www2.census.gov/geo/tiger/TIGER2024/COUNTY/tl_2024_us_county.zip` |
| Unified School Districts       | `https://www2.census.gov/geo/tiger/TIGER2024/UNSD/tl_2024_18_unsd.zip` |

```bash
# Download and unzip all 5
curl -O https://www2.census.gov/geo/tiger/TIGER2024/CD/tl_2024_18_cd119.zip
curl -O https://www2.census.gov/geo/tiger/TIGER2024/SLDU/tl_2024_18_sldu.zip
curl -O https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_18_sldl.zip
curl -O https://www2.census.gov/geo/tiger/TIGER2024/COUNTY/tl_2024_us_county.zip
curl -O https://www2.census.gov/geo/tiger/TIGER2024/UNSD/tl_2024_18_unsd.zip

unzip tl_2024_18_cd119.zip -d tl_2024_18_cd119/
unzip tl_2024_18_sldu.zip  -d tl_2024_18_sldu/
unzip tl_2024_18_sldl.zip  -d tl_2024_18_sldl/
unzip tl_2024_us_county.zip -d tl_2024_us_county/
unzip tl_2024_18_unsd.zip  -d tl_2024_18_unsd/
```

Note: `tl_2024_18_place.zip` (incorporated places / municipalities) exists at the Census Bureau but is NOT loaded in this phase. City-level jurisdiction resolution is deferred. Load it in a future phase if needed.

---

## Step 3: Load Boundary Data

Run one `ogr2ogr` command per district type. All 5 commands append to the same `inform.district_boundaries` table.

### Flags reference (identical across all 5 commands)

| Flag | Purpose |
|------|---------|
| `-f PostgreSQL` | Output format |
| `"PG:$DATABASE_URL"` | Direct connection (not pooler) |
| `-nln district_boundaries` | Target table name |
| `-lco SCHEMA=inform` | Target schema |
| `-lco GEOMETRY_NAME=geom` | Geometry column name matches migration |
| `-nlt PROMOTE_TO_MULTI` | Forces Polygon → MultiPolygon; TIGER/Line may include MultiPolygon features for non-contiguous districts |
| `-s_srs EPSG:4269 -t_srs EPSG:4326` | Reprojects NAD83 → WGS84; TIGER/Line ships in NAD83, PostGIS works in WGS84 |
| `-append -update` | Appends rows to existing table (does not drop/recreate) |
| `-sql "SELECT ..."` | Selects and renames TIGER/Line columns to match the table schema; injects `district_type` constant |

### Replace `/path/to/` with the directory where you unzipped each archive.

```bash
# 1. Congressional Districts (Indiana has 9 seats — 119th Congress)
ogr2ogr -f PostgreSQL \
  "PG:$DATABASE_URL" \
  -nln district_boundaries \
  -lco SCHEMA=inform \
  -lco GEOMETRY_NAME=geom \
  -nlt PROMOTE_TO_MULTI \
  -s_srs EPSG:4269 -t_srs EPSG:4326 \
  -append -update \
  -sql "SELECT GEOID AS geoid, NAMELSAD AS name, 'congressional' AS district_type FROM tl_2024_18_cd119" \
  /path/to/tl_2024_18_cd119/tl_2024_18_cd119.shp

# 2. State Senate (50 districts)
ogr2ogr -f PostgreSQL \
  "PG:$DATABASE_URL" \
  -nln district_boundaries \
  -lco SCHEMA=inform \
  -lco GEOMETRY_NAME=geom \
  -nlt PROMOTE_TO_MULTI \
  -s_srs EPSG:4269 -t_srs EPSG:4326 \
  -append -update \
  -sql "SELECT GEOID AS geoid, NAMELSAD AS name, 'state_senate' AS district_type FROM tl_2024_18_sldu" \
  /path/to/tl_2024_18_sldu/tl_2024_18_sldu.shp

# 3. State House (100 districts)
ogr2ogr -f PostgreSQL \
  "PG:$DATABASE_URL" \
  -nln district_boundaries \
  -lco SCHEMA=inform \
  -lco GEOMETRY_NAME=geom \
  -nlt PROMOTE_TO_MULTI \
  -s_srs EPSG:4269 -t_srs EPSG:4326 \
  -append -update \
  -sql "SELECT GEOID AS geoid, NAMELSAD AS name, 'state_house' AS district_type FROM tl_2024_18_sldl" \
  /path/to/tl_2024_18_sldl/tl_2024_18_sldl.shp

# 4. Counties (national file — filter to Indiana FIPS 18; Indiana has 92 counties)
# NOTE: -where and -sql are mutually exclusive in ogr2ogr. Use WHERE inside the -sql clause only.
ogr2ogr -f PostgreSQL \
  "PG:$DATABASE_URL" \
  -nln district_boundaries \
  -lco SCHEMA=inform \
  -lco GEOMETRY_NAME=geom \
  -nlt PROMOTE_TO_MULTI \
  -s_srs EPSG:4269 -t_srs EPSG:4326 \
  -append -update \
  -sql "SELECT GEOID AS geoid, NAMELSAD AS name, 'county' AS district_type FROM tl_2024_us_county WHERE STATEFP='18'" \
  /path/to/tl_2024_us_county/tl_2024_us_county.shp

# 5. Unified School Districts (~290 districts)
ogr2ogr -f PostgreSQL \
  "PG:$DATABASE_URL" \
  -nln district_boundaries \
  -lco SCHEMA=inform \
  -lco GEOMETRY_NAME=geom \
  -nlt PROMOTE_TO_MULTI \
  -s_srs EPSG:4269 -t_srs EPSG:4326 \
  -append -update \
  -sql "SELECT GEOID AS geoid, NAMELSAD AS name, 'school_district' AS district_type FROM tl_2024_18_unsd" \
  /path/to/tl_2024_18_unsd/tl_2024_18_unsd.shp
```

### After all 5 loads — update planner statistics

```sql
VACUUM ANALYZE inform.district_boundaries;
```

---

## Step 4: Post-Load Verification

Run all queries in psql and confirm the expected results before proceeding to RPC smoke tests.

```sql
-- Query 1: Confirm SRID is 4326 (WGS84).
-- If this returns 4269, the reprojection flags were missing — reload the affected file.
SELECT DISTINCT ST_SRID(geom) FROM inform.district_boundaries;
-- Expected: 4326


-- Query 2: Row counts by district type.
SELECT district_type, count(*)
FROM inform.district_boundaries
GROUP BY district_type
ORDER BY district_type;
-- Expected:
--   congressional   |   9    (Indiana 119th Congress seats)
--   county          |  92    (Indiana counties)
--   school_district | ~290   (varies by year; confirm > 200)
--   state_house     | 100
--   state_senate    |  50


-- Query 3: Bloomington, IN point-in-polygon smoke test.
-- Bloomington coordinates: lat=39.1653, lng=-86.5264
-- ST_MakePoint takes (longitude, latitude) — NOT (latitude, longitude).
-- Indiana 9th Congressional District GEOID: '1809'
SELECT geoid, name, district_type
FROM inform.district_boundaries
WHERE ST_Covers(
  geom,
  ST_SetSRID(ST_MakePoint(-86.5264, 39.1653), 4326)
)
ORDER BY district_type;
-- Expected: 5 rows
--   congressional   | Congressional District 9 (Indiana) | 1809
--   county          | Monroe County                       | <Monroe County GEOID>
--   school_district | <Monroe County school district>     | <GEOID>
--   state_house     | <Indiana House district>            | <GEOID>
--   state_senate    | <Indiana Senate district>           | <GEOID>
-- If the congressional row is missing or shows a GEOID other than '1809',
-- check SRID (Query 1) and coordinate order (lng first, lat second).
```

Note: In psql (outside a SECURITY DEFINER function), `ST_Covers`, `ST_MakePoint`, and `ST_SetSRID` resolve from the `extensions` schema automatically. Inside an RPC with `SET search_path = ''`, the `extensions.` prefix is mandatory — this is already handled in the migration 032 RPCs.

---

## Step 5: RPC Smoke Tests

After the Vault secret is created (Step 1) and boundaries are loaded (Step 3), test both RPCs end-to-end.

These tests require an existing `connect.connected_profiles` row. Find a test user ID:

```sql
SELECT user_id FROM connect.connected_profiles LIMIT 1;
-- Copy the UUID value — replace <test-user-id> in the commands below.
```

### Test 1: Upsert user location (Bloomington, IN)

```sql
SELECT connect.upsert_user_location(
  '<test-user-id>',
  39.1653,   -- lat
  -86.5264   -- lng
);
-- Expected: void return (no error message)
-- If exception: "location_encryption_key not found in Vault" → run Step 1.
```

### Test 2: Verify encryption (coordinates must be ciphertext, not plaintext)

```sql
SELECT encrypted_lat, location_consent, location_set_at
FROM connect.connected_profiles
WHERE user_id = '<test-user-id>';
-- encrypted_lat must show '\x...' hex ciphertext — NOT '39.1653' or any float literal.
--   Plaintext = pgcrypto not working or wrong key used.
-- location_consent must be: true
-- location_set_at must be: a recent timestamp
```

### Test 3: Resolve jurisdiction (must return district GEOIDs, no raw coordinates)

```sql
SELECT connect.resolve_user_jurisdiction('<test-user-id>');
-- Expected output shape (JSON):
-- {
--   "congressional": "1809",
--   "county": "<Monroe County GEOID>",
--   "state_house": "<district GEOID>",
--   "state_senate": "<district GEOID>",
--   "school_district": "<district GEOID>"
-- }
-- The JSON must NOT contain: lat, lng, or any float values.
-- If result is null or empty object: check that Bloomington coordinates
--   resolved correctly in Step 4 Query 3.
```

---

## Troubleshooting

### 1. Exception: "location_encryption_key not found in Vault"

**Cause:** The Vault secret was not created before calling the RPC.

**Fix:** Run Step 1. Then retry the RPC call.

---

### 2. ST_SRID query returns 4269 (not 4326)

**Cause:** The `-s_srs EPSG:4269 -t_srs EPSG:4326` flags were omitted from the ogr2ogr command. The data loaded without reprojection and is stored in NAD83.

**Fix:** Truncate the affected rows and reload with the correct flags:

```sql
-- Remove affected rows (example: county loaded without reprojection)
DELETE FROM inform.district_boundaries WHERE district_type = 'county';
```

Then rerun the ogr2ogr command for that district type with all flags present.

---

### 3. Row count mismatch — county shows 0 rows (or all US counties loaded)

**Cause A (0 rows):** The `-sql` clause is missing the `WHERE STATEFP='18'` filter, and ogr2ogr rejected the command because a standalone `-where` flag was combined with `-sql` (they are mutually exclusive).

**Cause B (3,200+ rows):** The `-where STATEFP='18'` was added as a standalone flag instead of inside `-sql`. This causes ogr2ogr to ignore the `-where` silently and load all US counties.

**Fix for both:** Ensure the county command uses `-sql "SELECT ... FROM tl_2024_us_county WHERE STATEFP='18'"` with the `WHERE` clause inside the SQL string. No standalone `-where` flag.

---

### 4. Bloomington smoke test (Step 4 Query 3) returns 0 rows

**Cause:** Coordinate order is reversed in the `ST_MakePoint` call, or SRID is 4269 (not 4326).

**Fix — coordinate order:** `ST_MakePoint` takes **(longitude, latitude)** — NOT (latitude, longitude):
```sql
-- Correct:   ST_MakePoint(-86.5264, 39.1653)
-- Incorrect: ST_MakePoint(39.1653, -86.5264)
```

**Fix — SRID mismatch:** Run Query 1. If result is 4269, follow Troubleshooting item 2 above.
