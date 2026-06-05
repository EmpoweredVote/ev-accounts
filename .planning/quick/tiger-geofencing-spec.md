# TIGER Geofencing — Full Spec

**Goal:** Given a user's lat/lng, resolve all their elected representative districts in one fast Postgres query. Store results on the user so subsequent "politicians representing me" queries are pure joins — no live geo lookup.

---

## Phase Plan

| Phase | Layers | Complexity |
|-------|--------|------------|
| 1 (this spec) | CA Assembly, CA Senate, US House | Clean, no overlaps |
| 2 (follow-up) | School Unified, Elementary, Secondary | Overlapping types, display logic TBD |

US Senate is statewide — no geofencing needed. Padilla + Butler apply to every CA user.

---

## Data Sources

All TIGER/Line 2024 shapefiles from Census Bureau. CA FIPS = `06`.

| Layer | File | ~Size | Key Fields |
|-------|------|-------|------------|
| CA Assembly (SLDL) | `tl_2024_06_sldl.zip` | ~1 MB | `GEOID`, `SLDLST`, `NAMELSAD` |
| CA Senate (SLDU) | `tl_2024_06_sldu.zip` | ~500 KB | `GEOID`, `SLDUST`, `NAMELSAD` |
| US House CA (CD) | `tl_2024_06_cd118.zip` | ~1.5 MB | `GEOID`, `CD118FP`, `NAMELSAD` |
| School Unified (Phase 2) | `tl_2024_06_unsd.zip` | ~3 MB | `GEOID`, `UNSDLEA`, `NAME` |
| School Elementary (Phase 2) | `tl_2024_06_elsd.zip` | ~2 MB | `GEOID`, `ELSDLEA`, `NAME` |
| School Secondary (Phase 2) | `tl_2024_06_scsd.zip` | ~1 MB | `GEOID`, `SCSDLEA`, `NAME` |

Download base URL: `https://www2.census.gov/geo/tiger/TIGER2024/{LAYER}/`

GEOID format: `{state_fips}{district_code}` — e.g., CA Assembly District 36 = `06036`.

---

## Prerequisites

- `gdal` installed locally (`brew install gdal` / `apt install gdal-bin`)
- Direct DB connection string to the Supabase Postgres instance (get from Supabase → Settings → Database → Connection string, **not** the pooler — use port 5432 direct for bulk insert)
- PostGIS enabled — verify: `SELECT PostGIS_Version();` should return a version string. If not: `CREATE EXTENSION postgis;`

---

## Migration 089 — Schema

```sql
-- essentials.geo_districts: one row per district polygon from TIGER
CREATE TABLE IF NOT EXISTS essentials.geo_districts (
  id           BIGSERIAL   PRIMARY KEY,
  layer        TEXT        NOT NULL,  -- 'ca_assembly' | 'ca_senate' | 'us_house' | 'school_unified' | 'school_elementary' | 'school_secondary'
  geoid        TEXT        NOT NULL,  -- TIGER GEOID e.g. '06036'
  district_num TEXT        NOT NULL,  -- human-readable e.g. '36'
  name         TEXT,                  -- e.g. 'State Assembly District 36'
  geom         GEOMETRY(MULTIPOLYGON, 4326) NOT NULL,
  UNIQUE (layer, geoid)
);

CREATE INDEX ON essentials.geo_districts USING GIST (geom);
CREATE INDEX ON essentials.geo_districts (layer);
CREATE INDEX ON essentials.geo_districts (layer, district_num);

-- RLS: read-only public access (geometry lookup is non-sensitive)
ALTER TABLE essentials.geo_districts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "geo_districts_public_read" ON essentials.geo_districts
  FOR SELECT USING (true);
```

```sql
-- connect.user_districts: cached resolution results per user
-- Populated/updated whenever user sets or confirms their location
CREATE TABLE IF NOT EXISTS connect.user_districts (
  user_id      UUID  NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  layer        TEXT  NOT NULL,
  geoid        TEXT  NOT NULL,
  district_num TEXT  NOT NULL,
  resolved_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, layer)
);

CREATE INDEX ON connect.user_districts (user_id);

-- RLS: users read their own only
ALTER TABLE connect.user_districts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_districts_own" ON connect.user_districts
  FOR SELECT USING (auth.uid() = user_id);
```

```sql
-- Add tiger_geoid to essentials.districts so we can join TIGER results → politicians
ALTER TABLE essentials.districts ADD COLUMN IF NOT EXISTS tiger_geoid TEXT UNIQUE;
```

---

## Migration 090 — RPC

```sql
-- resolve_user_districts: point-in-polygon for all configured layers
-- Returns one row per matching district. Fast via GIST index (~5ms).
CREATE OR REPLACE FUNCTION essentials.resolve_user_districts(
  p_lat  float8,
  p_lng  float8,
  p_layers text[] DEFAULT ARRAY['ca_assembly', 'ca_senate', 'us_house']
)
RETURNS TABLE(layer text, geoid text, district_num text, name text)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT gd.layer, gd.geoid, gd.district_num, gd.name
  FROM essentials.geo_districts gd
  WHERE gd.layer = ANY(p_layers)
    AND ST_Contains(gd.geom, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326))
$$;

GRANT EXECUTE ON FUNCTION essentials.resolve_user_districts TO authenticated, anon;
```

```sql
-- cache_user_districts: resolves and persists results for a user
-- Called server-side (pool.query) after a user sets their location
CREATE OR REPLACE FUNCTION essentials.cache_user_districts(
  p_user_id UUID,
  p_lat     float8,
  p_lng     float8
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT layer, geoid, district_num
    FROM essentials.resolve_user_districts(p_lat, p_lng)
  LOOP
    INSERT INTO connect.user_districts (user_id, layer, geoid, district_num, resolved_at)
    VALUES (p_user_id, r.layer, r.geoid, r.district_num, now())
    ON CONFLICT (user_id, layer) DO UPDATE
      SET geoid = EXCLUDED.geoid,
          district_num = EXCLUDED.district_num,
          resolved_at = EXCLUDED.resolved_at;
  END LOOP;
END;
$$;
```

---

## Import Process

Run this once per environment (local dev, production). The generated SQL is **not** committed to git — it's too large and the source of truth is the Census Bureau anyway.

### 1. Download and unzip

```bash
mkdir -p /tmp/tiger && cd /tmp/tiger

curl -L "https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_06_sldl.zip" -o sldl.zip && unzip sldl.zip
curl -L "https://www2.census.gov/geo/tiger/TIGER2024/SLDU/tl_2024_06_sldu.zip" -o sldu.zip && unzip sldu.zip
curl -L "https://www2.census.gov/geo/tiger/TIGER2024/CD/tl_2024_06_cd118.zip"  -o cd118.zip && unzip cd118.zip
```

### 2. Import each layer

Replace `$DB_URL` with the Supabase direct connection string (port 5432).

```bash
# CA Assembly (SLDL)
# TIGER uses NAD83 (EPSG:4269) — reproject to WGS84 (EPSG:4326) on import
ogr2ogr \
  -f PostgreSQL "$DB_URL" \
  /tmp/tiger/tl_2024_06_sldl.shp \
  -nln essentials.geo_districts_stage \
  -t_srs EPSG:4326 \
  -lco GEOMETRY_NAME=geom \
  -overwrite \
  -sql "SELECT GEOID, SLDLST AS district_num, NAMELSAD AS name FROM tl_2024_06_sldl"

psql "$DB_URL" -c "
  INSERT INTO essentials.geo_districts (layer, geoid, district_num, name, geom)
  SELECT 'ca_assembly', geoid, district_num, name, geom
  FROM essentials.geo_districts_stage
  ON CONFLICT (layer, geoid) DO UPDATE
    SET name = EXCLUDED.name, geom = EXCLUDED.geom;
  DROP TABLE IF EXISTS essentials.geo_districts_stage;
"

# CA Senate (SLDU)
ogr2ogr \
  -f PostgreSQL "$DB_URL" \
  /tmp/tiger/tl_2024_06_sldu.shp \
  -nln essentials.geo_districts_stage \
  -t_srs EPSG:4326 \
  -lco GEOMETRY_NAME=geom \
  -overwrite \
  -sql "SELECT GEOID, SLDUST AS district_num, NAMELSAD AS name FROM tl_2024_06_sldu"

psql "$DB_URL" -c "
  INSERT INTO essentials.geo_districts (layer, geoid, district_num, name, geom)
  SELECT 'ca_senate', geoid, district_num, name, geom
  FROM essentials.geo_districts_stage
  ON CONFLICT (layer, geoid) DO UPDATE
    SET name = EXCLUDED.name, geom = EXCLUDED.geom;
  DROP TABLE IF EXISTS essentials.geo_districts_stage;
"

# US House CA (CD118)
ogr2ogr \
  -f PostgreSQL "$DB_URL" \
  /tmp/tiger/tl_2024_06_cd118.shp \
  -nln essentials.geo_districts_stage \
  -t_srs EPSG:4326 \
  -lco GEOMETRY_NAME=geom \
  -overwrite \
  -sql "SELECT GEOID, CD118FP AS district_num, NAMELSAD AS name FROM tl_2024_06_cd118"

psql "$DB_URL" -c "
  INSERT INTO essentials.geo_districts (layer, geoid, district_num, name, geom)
  SELECT 'us_house', geoid, district_num, name, geom
  FROM essentials.geo_districts_stage
  ON CONFLICT (layer, geoid) DO UPDATE
    SET name = EXCLUDED.name, geom = EXCLUDED.geom;
  DROP TABLE IF EXISTS essentials.geo_districts_stage;
"
```

### 3. Verify row counts

```sql
SELECT layer, count(*) FROM essentials.geo_districts GROUP BY layer ORDER BY layer;
-- Expected:
--  ca_assembly | 80
--  ca_senate   | 40
--  us_house    | 52
```

### 4. Spot-check a known address

```sql
-- Los Angeles City Hall: 34.0537, -118.2430
SELECT * FROM essentials.resolve_user_districts(34.0537, -118.2430);
-- Should return assembly ~54, senate ~26, us_house ~34 (approx)
```

### 5. Link existing essentials.districts records

After import, populate `tiger_geoid` on existing district records by matching on district type + number. This join is manual the first time — district naming conventions vary — but you only do it once.

```sql
-- Example for CA Assembly — adjust name patterns to match your essentials.districts data
UPDATE essentials.districts d
SET tiger_geoid = gd.geoid
FROM essentials.geo_districts gd
WHERE gd.layer = 'ca_assembly'
  AND d.district_number::text = gd.district_num  -- adjust column name as needed
  AND d.jurisdiction_type = 'state_assembly';     -- adjust as needed
```

---

## Backend Integration

### Wire into location-set flow

Wherever the user's location is saved (currently `POST /api/account/location` or similar), call `cache_user_districts` immediately after:

```typescript
// After saving lat/lng to connected_profiles...
await pool.query(
  'SELECT essentials.cache_user_districts($1, $2, $3)',
  [userId, lat, lng]
);
```

### New endpoint: GET /api/account/districts

Returns the user's cached district resolutions. Inform users get a point-in-polygon lookup on demand; Connected users get the cached result.

```typescript
router.get('/districts', requireAuth, async (req, res) => {
  const { rows } = await pool.query(
    'SELECT layer, geoid, district_num, resolved_at FROM connect.user_districts WHERE user_id = $1',
    [userId]
  );
  res.json({ districts: rows });
});
```

### Politicians-representing-me query

Once `essentials.districts.tiger_geoid` is populated and `connect.user_districts` is populated for a user, the query becomes:

```sql
SELECT p.full_name, p.office_title, d.name AS district_name
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON d.id = o.district_id
JOIN connect.user_districts ud ON ud.geoid = d.tiger_geoid
WHERE ud.user_id = $1
ORDER BY d.layer, p.last_name;
```

No live geo query — pure indexed join.

---

## Supabase Local Dev

Apply migrations via MCP:

```
mcp__supabase-local__apply_migration  name="089_tiger_schema"   sql=<migration_089_content>
mcp__supabase-local__apply_migration  name="090_tiger_rpcs"     sql=<migration_090_content>
```

Then run the import script against the local Supabase instance:
```bash
DB_URL="postgresql://postgres:postgres@localhost:54322/postgres"
# run same ogr2ogr commands above
```

---

## Phase 2 — School Districts (deferred)

Same pattern as Phase 1, with three additional layers:
- `school_unified` — covers most of CA
- `school_elementary` + `school_secondary` — cover areas not in a unified district

A user may match `school_unified` OR both `school_elementary` + `school_secondary`, never all three. The display layer needs to handle this: if a `school_unified` result exists, suppress the elementary/secondary results for UI purposes (they may still be stored).

Backfill note: School board elections are not yet in `essentials.politicians`. When they are, the `tiger_geoid` link on `essentials.districts` is all that's needed to wire them into the politicians-representing-me query.

---

## Refresh Cadence

TIGER boundaries update after each decennial census redistricting cycle. California completed its 2020 cycle in 2022. Next update: ~2032. No automated refresh needed — re-run the import script if/when districts are redrawn.

Exception: Congressional maps can be redrawn mid-cycle by court order (happened in CA in 2023). Check `https://www.census.gov/geo/maps-data/data/tiger-line.html` for updated files if a redistricting event occurs.
