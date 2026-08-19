#!/usr/bin/env bash
# =============================================================================
# load-zcta-boundaries.sh
# Nationwide ZIP Code Tabulation Area (ZCTA) import -> essentials.geofence_boundaries
#
# ---------------------------------------------------------------------------
# PREREQUISITE — READ THIS FIRST. NOT OPTIONAL.
#
# 'G6350' MUST already be excluded from the district-join catch-all clause
# (FALLBACK_EXCLUDED_MTFCCS in backend/src/lib/geoIdGuard.ts) IN THE DEPLOYED
# BACKEND — not merely committed on a branch.
#
# Why: that clause means "match any district_type for this geo_id". A ZCTA's
# geo_id is a bare 5-digit ZIP, which collides with district geo_ids. Measured
# 2026-08-18 with only the 807 Indiana ZCTAs loaded: 65 ZIP geo_ids ALREADY
# collide with essentials.districts.geo_id. None of those districts currently
# carry offices, so nothing leaks yet — the bug is latent, not live. Loading
# 33.8k ZIPs multiplies that surface ~40x, and the first collision that lands on
# a district WITH offices attaches wrong officials to ADDRESS lookups, not just
# ZIP ones.
#
# Step 0 below refuses to run if the guard is missing from origin/master.
# ---------------------------------------------------------------------------
#
# TIGER ships ZCTAs as ONE nationwide file (529 MB) — there are no per-state
# slices, so coverage is all-or-nothing.
#
# Geometries are simplified to ~55m on import. A ZCTA is only ever a QUERY
# SHAPE, never the district geometry an address resolves against, so the cost is
# a sub-point shift in share percentages. Full resolution would add an estimated
# 0.8-1.2 GB to a table whose geometry is currently 445 MB across 16,186 rows.
#
# Prerequisites: gdal (ogr2ogr), postgresql-client (psql)
# Usage: DB_URL="postgresql://...:5432/postgres" ./scripts/load-zcta-boundaries.sh
#
# Idempotent AND resumable:
#   - download: skipped when the zip is already present
#   - stage table: -overwrite
#   - merge: ON CONFLICT (geo_id, mtfcc) DO UPDATE  <- (geo_id, mtfcc), never geo_id
#   - state backfill: batched by leading digit, WHERE state IS NULL
#
# EVERY write in this script is scoped to mtfcc='G6350'. It cannot touch another
# layer's rows.
# =============================================================================

set -euo pipefail

if [[ -z "${DB_URL:-}" ]]; then
  echo "ERROR: DB_URL is required (direct connection, port 5432 — NOT the 6543 pooler)."
  exit 1
fi

command -v ogr2ogr >/dev/null 2>&1 || { echo "ERROR: ogr2ogr not found. Install gdal."; exit 1; }
command -v psql    >/dev/null 2>&1 || { echo "ERROR: psql not found. Install postgresql-client."; exit 1; }

# ---------------------------------------------------------------------------
# Step 0: refuse to run without the deployed G6350 guard
# ---------------------------------------------------------------------------
if [[ "${SKIP_GUARD_CHECK:-0}" != "1" ]]; then
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  echo "[0/5] Verifying the G6350 district-join guard is on origin/master..."
  git -C "$REPO_ROOT" fetch origin master --quiet 2>/dev/null || true
  if ! git -C "$REPO_ROOT" show origin/master:backend/src/lib/geoIdGuard.ts 2>/dev/null | grep -q "G6350"; then
    echo
    echo "REFUSING TO RUN: origin/master's geoIdGuard.ts does not exclude G6350."
    echo
    echo "  Loading ZCTAs now would expose the ADDRESS path — not just ZIP lookups —"
    echo "  to districts matched on a bare 5-digit geo_id. Merge and deploy the guard"
    echo "  first, then re-run."
    echo
    echo "  (Override with SKIP_GUARD_CHECK=1 only if you have verified the running"
    echo "  backend another way.)"
    exit 1
  fi
  echo "       guard present on origin/master."
  echo
fi

WORK_DIR="${WORK_DIR:-/tmp/tiger-zcta}"
SIMPLIFY_TOLERANCE="${SIMPLIFY_TOLERANCE:-0.0005}"   # degrees, ~55m
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

ZIP_FILE="tl_2024_us_zcta520.zip"
SHP_FILE="$WORK_DIR/tl_2024_us_zcta520.shp"
URL="https://www2.census.gov/geo/tiger/TIGER2024/ZCTA520/$ZIP_FILE"

# ---------------------------------------------------------------------------
# Step 1: download (529 MB)
# ---------------------------------------------------------------------------
if [[ -f "$ZIP_FILE" ]]; then
  echo "[1/5] [skip] $ZIP_FILE already downloaded"
else
  echo "[1/5] Downloading $URL (529 MB — this takes a while)..."
  curl -sSL --fail "$URL" -o "$ZIP_FILE"
fi
unzip -o -q "$ZIP_FILE"
[[ -f "$SHP_FILE" ]] || { echo "ERROR: $SHP_FILE missing after unzip."; exit 1; }

# ---------------------------------------------------------------------------
# Step 2: stage table
# TIGER is NAD83 (EPSG:4269); reproject to 4326 to match geofence_boundaries.
# ---------------------------------------------------------------------------
echo "[2/5] Staging shapefile -> essentials.geofence_zcta_stage ..."
psql "$DB_URL" -v ON_ERROR_STOP=1 -c \
  "DROP TABLE IF EXISTS essentials.geofence_zcta_stage;" >/dev/null

ogr2ogr \
  -f PostgreSQL "$DB_URL" \
  "$SHP_FILE" \
  -nln essentials.geofence_zcta_stage \
  -nlt MULTIPOLYGON \
  -t_srs EPSG:4326 \
  -lco GEOMETRY_NAME=geom \
  -lco SCHEMA=essentials \
  -overwrite \
  -sql "SELECT ZCTA5CE20 AS zcta5 FROM tl_2024_us_zcta520"

psql "$DB_URL" -v ON_ERROR_STOP=1 -c \
  "CREATE INDEX IF NOT EXISTS idx_zcta_stage_geom ON essentials.geofence_zcta_stage USING gist (geom);"

echo "       staged rows:"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c \
  "SELECT count(*) AS staged FROM essentials.geofence_zcta_stage;"

# ---------------------------------------------------------------------------
# Step 3: merge, simplified
# `state` is left NULL here and backfilled in Step 4 — the dominant-county
# spatial join is far too slow to hold open inside this statement.
# ---------------------------------------------------------------------------
echo "[3/5] Merging into geofence_boundaries (simplify tolerance ${SIMPLIFY_TOLERANCE}) ..."
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  INSERT INTO essentials.geofence_boundaries
    (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
  SELECT s.zcta5,
         NULL,
         s.zcta5,
         NULL,
         'G6350',
         public.ST_SimplifyPreserveTopology(s.geom, ${SIMPLIFY_TOLERANCE}),
         'census_tiger_2024',
         now()
  FROM essentials.geofence_zcta_stage s
  WHERE s.zcta5 IS NOT NULL
  ON CONFLICT (geo_id, mtfcc) DO UPDATE
    SET geometry    = EXCLUDED.geometry,
        name        = EXCLUDED.name,
        source      = EXCLUDED.source,
        imported_at = now(),
        state       = NULL;
"

# ---------------------------------------------------------------------------
# Step 4: dominant-state backfill, batched
# ZCTAs cross state lines, so `state` is the state covering the largest share.
# It is an indexing/display convenience — resolveOfficialsInArea derives states
# spatially and never reads this column for correctness.
# ---------------------------------------------------------------------------
echo "[4/5] Backfilling dominant state FIPS (10 batches) ..."
for d in 0 1 2 3 4 5 6 7 8 9; do
  echo "       batch ${d}xxxx ..."
  psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
    UPDATE essentials.geofence_boundaries z
    SET state = (
      SELECT LEFT(c.geo_id, 2)
      FROM essentials.geofence_boundaries c
      WHERE c.mtfcc = 'G4020'
        AND c.geometry OPERATOR(public.&&) z.geometry
        AND public.ST_Intersects(c.geometry, z.geometry)
      ORDER BY public.ST_Area(public.ST_Intersection(c.geometry, z.geometry)) DESC
      LIMIT 1
    )
    WHERE z.mtfcc = 'G6350'
      AND z.state IS NULL
      AND z.geo_id LIKE '${d}%';
  "
done

psql "$DB_URL" -v ON_ERROR_STOP=1 -c \
  "DROP TABLE IF EXISTS essentials.geofence_zcta_stage;"

# ---------------------------------------------------------------------------
# Step 5: verification
# ---------------------------------------------------------------------------
echo "[5/5] Verification"

echo
echo "Row count (expect ~33,800) / states (expect ~56) / unresolved state (expect 0):"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  SELECT count(*) AS zcta_rows,
         count(DISTINCT state) AS states,
         count(*) FILTER (WHERE state IS NULL) AS unresolved_state
  FROM essentials.geofence_boundaries WHERE mtfcc = 'G6350';
"

echo "Geometry validity (expect invalid = 0):"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  SELECT count(*) FILTER (WHERE NOT public.ST_IsValid(geometry)) AS invalid
  FROM essentials.geofence_boundaries WHERE mtfcc = 'G6350';
"

echo "GUARD — no ZCTA may reach an OFFICE through the district join (expect 0):"
echo "        (geo_id collisions alone are expected and harmless; offices are not)"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  SELECT count(DISTINCT gb.geo_id) AS colliding_zip_geo_ids,
         count(o.id)               AS leaked_offices
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id
  LEFT JOIN essentials.offices o ON o.district_id = d.id
  WHERE gb.mtfcc = 'G6350';
"

echo "Ground truth — 46220 district counts must be UNCHANGED by simplification"
echo "               (pre-import, measured 2026-08-18: G5200=1, G5210=3, G5220=4):"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  WITH zcta AS (
    SELECT geometry AS g FROM essentials.geofence_boundaries
    WHERE mtfcc = 'G6350' AND geo_id = '46220'
  )
  SELECT gb.mtfcc, count(*) AS overlapping_districts
  FROM essentials.geofence_boundaries gb, zcta z
  WHERE gb.mtfcc IN ('G5200','G5210','G5220')
    AND gb.geometry OPERATOR(public.&&) z.g
    AND public.ST_Intersects(gb.geometry, z.g)
    AND NOT public.ST_Touches(gb.geometry, z.g)
  GROUP BY gb.mtfcc ORDER BY gb.mtfcc;
"

echo "Index sanity — the ZIP overlap must be an Index Scan, never a Seq Scan:"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  EXPLAIN
  WITH zcta AS (
    SELECT geometry AS g FROM essentials.geofence_boundaries
    WHERE mtfcc = 'G6350' AND geo_id = '46220'
  )
  SELECT gb.geo_id FROM essentials.geofence_boundaries gb
  WHERE gb.mtfcc <> 'G6350'
    AND gb.geometry OPERATOR(public.&&) (SELECT g FROM zcta)
    AND public.ST_Intersects(gb.geometry, (SELECT g FROM zcta));
" | grep -qi "Seq Scan on geofence_boundaries" \
  && { echo "       FAIL: Seq Scan on geofence_boundaries — GIST index not used."; exit 1; } \
  || echo "       PASS: no Seq Scan on geofence_boundaries."

echo
echo "Table size after import:"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  SELECT pg_size_pretty(pg_total_relation_size('essentials.geofence_boundaries')) AS total,
         pg_size_pretty(sum(pg_column_size(geometry))) AS geometry_bytes
  FROM essentials.geofence_boundaries;
"

echo
echo "=== Done. ==="
