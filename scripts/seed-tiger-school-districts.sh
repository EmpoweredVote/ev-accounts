#!/usr/bin/env bash
# =============================================================================
# seed-tiger-school-districts.sh
# Phase 71: TIGER 2024 California school district import
#
# Imports UNSD (unified), ELSD (elementary), and SCSD (secondary) shapefiles
# into essentials.geo_districts. Idempotent (ON CONFLICT DO UPDATE).
#
# Field-name notes:
#   - School shapefiles use NAME (not NAMELSAD) — full friendly name like
#     "Los Angeles Unified School District".
#   - LEA codes are per-layer: UNSDLEA / ELSDLEA / SCSDLEA (not SLDLST).
#   - GEOID is 7 chars (STATEFP 2 + LEA 5), e.g., 0610710 = Los Angeles USD.
#
# Usage:
#   DB_URL="postgresql://postgres.[ref]:[pw]@aws-0-us-east-1.pooler.supabase.com:5432/postgres" \
#     bash scripts/seed-tiger-school-districts.sh
#
# Windows: PROJ_LIB must point to GDAL projlib directory.
# =============================================================================

set -euo pipefail

if [[ -z "${DB_URL:-}" ]]; then
  echo "ERROR: DB_URL required. Use session pooler (aws-0-*.pooler.supabase.com:5432)" >&2
  exit 1
fi

# Windows: PROJ_LIB required for ogr2ogr coordinate transforms
export PROJ_LIB="${PROJ_LIB:-C:/Program Files/GDAL/projlib}"

WORK_DIR="${WORK_DIR:-/tmp/tiger-schools}"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

download_if_missing() {
  local url="$1"; local zip="$2"
  if [[ -f "$zip" ]]; then
    echo "  [skip] $zip already downloaded"
  else
    echo "  [get]  $zip"
    curl -fsSL "$url" -o "$zip"
  fi
  unzip -o -q "$zip"
}

echo "[1/3] Downloading TIGER 2024 California school district shapefiles..."
download_if_missing "https://www2.census.gov/geo/tiger/TIGER2024/UNSD/tl_2024_06_unsd.zip" "unsd.zip"
download_if_missing "https://www2.census.gov/geo/tiger/TIGER2024/ELSD/tl_2024_06_elsd.zip" "elsd.zip"
download_if_missing "https://www2.census.gov/geo/tiger/TIGER2024/SCSD/tl_2024_06_scsd.zip" "scsd.zip"

# Import a single school layer: shapefile -> stage table -> upsert into geo_districts
import_school_layer() {
  local shp="$1"          # full path to .shp
  local layer_name="$2"   # 'school_unified' | 'school_elementary' | 'school_secondary'
  local lea_col="$3"      # 'UNSDLEA' | 'ELSDLEA' | 'SCSDLEA'
  local base
  base="$(basename "$shp" .shp)"

  echo "[2/3] Importing $layer_name from $base..."

  # Drop any leftover stage table from a prior partial run
  psql "$DB_URL" -v ON_ERROR_STOP=1 -c \
    "DROP TABLE IF EXISTS essentials.geo_districts_stage;" >/dev/null

  # Stage import via ogr2ogr — use NAME (not NAMELSAD), and the layer-specific LEA column
  ogr2ogr \
    -f PostgreSQL "$DB_URL" "$shp" \
    -nln essentials.geo_districts_stage \
    -nlt MULTIPOLYGON \
    -t_srs EPSG:4326 \
    -lco GEOMETRY_NAME=geom \
    -lco SCHEMA=essentials \
    -overwrite \
    -sql "SELECT GEOID, ${lea_col} AS district_num, NAME AS name FROM ${base}"

  # Upsert into geo_districts with the canonical layer name
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
}

import_school_layer "$WORK_DIR/tl_2024_06_unsd.shp" "school_unified"     "UNSDLEA"
import_school_layer "$WORK_DIR/tl_2024_06_elsd.shp" "school_elementary"  "ELSDLEA"
import_school_layer "$WORK_DIR/tl_2024_06_scsd.shp" "school_secondary"   "SCSDLEA"

echo "[3/3] Verification — row counts per layer"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  SELECT layer, count(*) AS rows
  FROM essentials.geo_districts
  WHERE layer IN ('school_unified', 'school_elementary', 'school_secondary')
  GROUP BY layer ORDER BY layer;
"

echo ""
echo "Spot-check at LA City Hall (34.0537, -118.2430) — expect Los Angeles Unified School District:"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  SELECT layer, geoid, name
  FROM essentials.resolve_user_districts(
    34.0537, -118.2430,
    ARRAY['school_unified','school_elementary','school_secondary']
  )
  ORDER BY layer;
"

echo ""
echo "=== School district seed complete ==="
