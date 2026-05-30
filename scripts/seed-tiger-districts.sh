#!/usr/bin/env bash
# =============================================================================
# seed-tiger-districts.sh
# Phase 69 / Plan 02: TIGER 2024 California district import
#
# Imports CA Assembly (SLDL), CA Senate (SLDU), and US House CA (CD118)
# polygons into essentials.geo_districts. Idempotent — safe to re-run.
#
# Prerequisites:
#   - gdal installed (provides ogr2ogr): `brew install gdal` / `apt install gdal-bin`
#   - psql installed (Postgres client)
#   - DB_URL env var set to a DIRECT connection string (port 5432, NOT pooler 6543)
#     Local:  DB_URL="postgresql://postgres:postgres@localhost:54322/postgres"
#     Prod:   from Supabase Dashboard -> Settings -> Database -> Connection string
#
# Usage:
#   DB_URL="..." ./scripts/seed-tiger-districts.sh
#
# Idempotency:
#   - download step: skips files already present in /tmp/tiger
#   - import step: stage table is -overwrite, INSERT uses ON CONFLICT (layer, geoid) DO UPDATE
#   - re-running with the same TIGER vintage is a no-op (geom matches, name matches)
# =============================================================================

set -euo pipefail

if [[ -z "${DB_URL:-}" ]]; then
  echo "ERROR: DB_URL is required."
  echo "  Local:  DB_URL=\"postgresql://postgres:postgres@localhost:54322/postgres\" $0"
  echo "  Prod:   get from Supabase Dashboard -> Settings -> Database -> Connection string (port 5432)"
  exit 1
fi

command -v ogr2ogr >/dev/null 2>&1 || { echo "ERROR: ogr2ogr not found. Install gdal."; exit 1; }
command -v psql    >/dev/null 2>&1 || { echo "ERROR: psql not found. Install postgresql-client."; exit 1; }

WORK_DIR="${WORK_DIR:-/tmp/tiger}"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "=== Phase 69 Plan 02 — TIGER 2024 California district import ==="
echo "Working directory: $WORK_DIR"
echo "DB_URL: ${DB_URL%%@*}@<redacted>"
echo

# ---------------------------------------------------------------------------
# Step 1: Download TIGER 2024 shapefiles (CA = state FIPS 06)
# ---------------------------------------------------------------------------
download_if_missing() {
  local url="$1"
  local zip="$2"
  if [[ -f "$zip" ]]; then
    echo "  [skip] $zip already downloaded"
  else
    echo "  [get ] $url"
    curl -sSL "$url" -o "$zip"
  fi
  # Always (re)unzip — cheap, ensures shapefile siblings exist
  unzip -o -q "$zip"
}

echo "[1/3] Downloading TIGER 2024 shapefiles..."
download_if_missing "https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_06_sldl.zip"  "sldl.zip"
download_if_missing "https://www2.census.gov/geo/tiger/TIGER2024/SLDU/tl_2024_06_sldu.zip"  "sldu.zip"
# CD119 is state-specific in TIGER2024 (Census switched from 118th to 119th Congress; CA=06)
download_if_missing "https://www2.census.gov/geo/tiger/TIGER2024/CD/tl_2024_06_cd119.zip"   "cd119.zip"
echo

# ---------------------------------------------------------------------------
# Step 2: ogr2ogr each layer into a stage table, then INSERT ... ON CONFLICT
# TIGER uses NAD83 (EPSG:4269); we reproject to WGS84 (EPSG:4326) on import
# so geom column type GEOMETRY(MULTIPOLYGON, 4326) accepts the result.
# ---------------------------------------------------------------------------
import_layer() {
  local shp="$1"           # e.g. /tmp/tiger/tl_2024_06_sldl.shp
  local layer_name="$2"    # e.g. ca_assembly
  local district_col="$3"  # SLDLST | SLDUST | CD118FP
  local where_clause="${4:-}"  # optional WHERE filter (used for national files)

  echo "[2/3] Importing $layer_name from $(basename "$shp")..."

  # Drop any leftover stage table from a previous failed run
  psql "$DB_URL" -v ON_ERROR_STOP=1 -c \
    "DROP TABLE IF EXISTS essentials.geo_districts_stage;" >/dev/null

  local sql_query="SELECT GEOID, ${district_col} AS district_num, NAMELSAD AS name FROM $(basename "$shp" .shp)"
  if [[ -n "$where_clause" ]]; then
    sql_query="$sql_query WHERE $where_clause"
  fi

  # ogr2ogr: shapefile -> stage table, reprojected to 4326, geom column named 'geom'
  # -nlt MULTIPOLYGON forces consistent geometry type (some TIGER rows are POLYGON)
  ogr2ogr \
    -f PostgreSQL "$DB_URL" \
    "$shp" \
    -nln essentials.geo_districts_stage \
    -nlt MULTIPOLYGON \
    -t_srs EPSG:4326 \
    -lco GEOMETRY_NAME=geom \
    -lco SCHEMA=essentials \
    -overwrite \
    -sql "$sql_query"

  # Idempotent merge into the canonical table
  psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
    INSERT INTO essentials.geo_districts (layer, geoid, district_num, name, geom)
    SELECT '${layer_name}', geoid, district_num, name, geom
    FROM essentials.geo_districts_stage
    ON CONFLICT (layer, geoid) DO UPDATE
      SET district_num = EXCLUDED.district_num,
          name         = EXCLUDED.name,
          geom         = EXCLUDED.geom;
    DROP TABLE IF EXISTS essentials.geo_districts_stage;
  "
  echo "       $layer_name imported."
  echo
}

import_layer "$WORK_DIR/tl_2024_06_sldl.shp"  "ca_assembly" "SLDLST"
import_layer "$WORK_DIR/tl_2024_06_sldu.shp"  "ca_senate"   "SLDUST"
# CA-specific CD119 file (TIGER2024 uses 119th Congress, state-specific files)
import_layer "$WORK_DIR/tl_2024_06_cd119.shp" "us_house"    "CD119FP"

# ---------------------------------------------------------------------------
# Step 3: Verify row counts + spot-check LA City Hall
# ---------------------------------------------------------------------------
echo "[3/3] Verification"
echo
echo "Row counts (expect ca_assembly=80, ca_senate=40, us_house=52):"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  SELECT layer, count(*) AS rows
  FROM essentials.geo_districts
  GROUP BY layer
  ORDER BY layer;
"

echo "Spot-check — LA City Hall (34.0537, -118.2430) should return 3 rows:"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  SELECT layer, geoid, district_num, name
  FROM essentials.resolve_user_districts(34.0537, -118.2430)
  ORDER BY layer;
"

echo
echo "=== Done. ==="
