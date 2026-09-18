#!/usr/bin/env bash
# =============================================================================
# load-municipal-boundaries.sh
#
# Loads TIGER/Line 2024 MUNICIPAL boundaries for Michigan, Pennsylvania and Ohio
# into essentials.geofence_boundaries:
#
#   COUSUB (county subdivisions) -> G4040    townships, and in MI cities too
#   PLACE  (places)              -> G4110 incorporated + G4210 CDP
#
# ---------------------------------------------------------------------------
# WHY
# ---------------------------------------------------------------------------
# Civic Spaces shows a tool row only when a deep link exists for the active
# slice ("no match, no row"). It matches on geoid against this table. Measured
# 2026-09-18, MI, PA and OH had ZERO municipal boundary rows of any type, so
# every Treasury Tracker entity in those states was invisible to it:
#
#     PA  2,551 TT municipal entities   0 matched   0.0%
#     MI  1,773                         0 matched   0.0%
#     OH    253                         0 matched   0.0%
#
# against MN/IN/CA/FL/VA at 100%. This is that gap, and nothing else: no new
# service, no cron, no schema change. One idempotent load into an existing
# table, run by hand.
#
# ---------------------------------------------------------------------------
# PREREQUISITES
# ---------------------------------------------------------------------------
#   - ogr2ogr (GDAL 3.x)     `ogr2ogr --version`
#   - psql, curl, unzip
#   - DB_URL: a DIRECT or SESSION-mode connection string on port 5432.
#     NOT the transaction pooler on 6543 — multi-statement SQL fails there.
#
#     read -rsp 'DB password: ' PGPW && \
#       export DB_URL="postgresql://postgres:$PGPW@db.<ref>.supabase.co:5432/postgres" && \
#       unset PGPW
#
#     The role must hold CREATE (for the staging table) plus INSERT/UPDATE on
#     essentials.geofence_boundaries. Measured: `postgres` has both; `ev_api`
#     has the writes but NO CREATE in any schema, so it cannot stage.
#
# ---------------------------------------------------------------------------
# USAGE
# ---------------------------------------------------------------------------
#   DB_URL="..." ./scripts/load-municipal-boundaries.sh            # load
#   DB_URL="..." ./scripts/load-municipal-boundaries.sh --dry-run  # download + report, no writes
#   DB_URL="..." REFRESH=1 ./scripts/load-municipal-boundaries.sh  # re-load over existing rows
#
# ---------------------------------------------------------------------------
# IDEMPOTENCY AND SAFETY
# ---------------------------------------------------------------------------
#   - Downloads skip files already in WORK_DIR.
#   - The upsert is ON CONFLICT (geo_id, mtfcc) DO UPDATE, the table's own
#     unique key, so a re-run rewrites the same rows rather than duplicating.
#   - A PRE-FLIGHT refuses to run if those states already carry rows at those
#     MTFCCs, unless REFRESH=1. A silent second load is the failure mode this
#     exists to prevent.
#   - The staging table is created and dropped by this script. It is the only
#     DDL performed.
#
#   MTFCC IS READ FROM THE SHAPEFILE, NEVER HARDCODED. The PLACE file mixes
#   incorporated places (G4110) with CDPs (G4210) — MI alone is 533 + 212 —
#   and the table already distinguishes them. Hardcoding G4110 would relabel
#   every CDP as an incorporated municipality: wrong, and it looks right.
#
#   The connection string is NEVER echoed unmasked. `${DB_URL%%@*}` leaves the
#   password and hides the HOSTNAME — the redaction inverted. That idiom is in
#   seed-tiger-districts.sh:43 and is not copied here.
# =============================================================================

set -euo pipefail

TIGER_YEAR=2024
SOURCE_TAG='census_tiger_2024'
STAGING='public._staging_municipal_boundaries'
WORK_DIR="${WORK_DIR:-/tmp/tiger-municipal}"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

# state FIPS -> abbreviation, for readable output only. The `state` column
# stores the two-digit FIPS, matching every row already in the table.
declare -A STATE_NAME=( [26]=MI [42]=PA [39]=OH )
STATES=(26 42 39)
LAYERS=(cousub place)

# ── Guards ───────────────────────────────────────────────────────────────────
if [[ -z "${DB_URL:-}" ]]; then
  echo "ERROR: DB_URL is required (direct or SESSION-mode, port 5432)." >&2
  echo "  read -rsp 'DB password: ' PGPW && export DB_URL=\"postgresql://postgres:\$PGPW@db.<ref>.supabase.co:5432/postgres\" && unset PGPW" >&2
  exit 1
fi

if [[ "$DB_URL" == *":6543"* ]]; then
  echo "ERROR: that is the TRANSACTION pooler (6543). Multi-statement SQL fails there." >&2
  echo "  Use the direct connection or the SESSION pooler, both on port 5432." >&2
  exit 1
fi

for tool in ogr2ogr psql curl unzip; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: $tool not found." >&2; exit 1; }
done

# Mask the credential, keep the host. See the header note.
mask_url() { printf '%s' "$1" | sed -E 's#(//[^:]+):[^@]*@#\1:****@#'; }

echo "=== TIGER ${TIGER_YEAR} municipal boundaries — MI · PA · OH ==="
echo "Target : $(mask_url "$DB_URL")"
echo "Work   : ${WORK_DIR}"
echo "Source : ${SOURCE_TAG}"
[[ $DRY_RUN == 1 ]] && echo "Mode   : DRY RUN — downloads and reports, writes nothing"
echo

echo "--- connectivity ---"
psql "$DB_URL" -v ON_ERROR_STOP=1 -tAc \
  "select 'connected as ' || current_user || ', ' || count(*) || ' existing boundary rows'
     from essentials.geofence_boundaries;"

# ── Pre-flight: refuse a silent second load ──────────────────────────────────
echo
echo "--- pre-flight ---"
EXISTING="$(psql "$DB_URL" -v ON_ERROR_STOP=1 -tAc \
  "select count(*) from essentials.geofence_boundaries
    where mtfcc in ('G4040','G4110','G4210')
      and left(geo_id, 2) in ('26','42','39');")"
echo "        MI/PA/OH rows at G4040/G4110/G4210: ${EXISTING}"

if [[ "$EXISTING" != "0" && "${REFRESH:-0}" != "1" ]]; then
  echo "ERROR: those states already carry ${EXISTING} row(s) at those MTFCCs." >&2
  echo "  This script expects to be the first load. Re-run with REFRESH=1 to" >&2
  echo "  rewrite them deliberately (the upsert is keyed on (geo_id, mtfcc))." >&2
  exit 1
fi

# ── Download ─────────────────────────────────────────────────────────────────
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo
echo "--- download ---"
SHAPEFILES=()
for fips in "${STATES[@]}"; do
  for layer in "${LAYERS[@]}"; do
    base="tl_${TIGER_YEAR}_${fips}_${layer}"
    url="https://www2.census.gov/geo/tiger/TIGER${TIGER_YEAR}/${layer^^}/${base}.zip"
    if [[ ! -f "${base}.shp" ]]; then
      [[ -f "${base}.zip" ]] || curl -sSL --fail -o "${base}.zip" "$url"
      unzip -oq "${base}.zip"
      echo "        ${STATE_NAME[$fips]} ${layer}: downloaded"
    else
      echo "        ${STATE_NAME[$fips]} ${layer}: cached"
    fi
    SHAPEFILES+=("${base}.shp")
  done
done

echo
echo "--- source feature counts (the load is checked against THESE, not against"
echo "    what TT expects — a state-complete layer holds units TT does not) ---"
TOTAL_FEATURES=0
for shp in "${SHAPEFILES[@]}"; do
  n="$(ogrinfo -so -al "$shp" 2>/dev/null | awk -F': ' '/^Feature Count/{print $2}')"
  printf '        %-28s %6s features\n' "$shp" "$n"
  TOTAL_FEATURES=$(( TOTAL_FEATURES + n ))
done
echo "        ---------------------------------------------"
printf '        %-28s %6s\n' "TOTAL" "$TOTAL_FEATURES"

if [[ $DRY_RUN == 1 ]]; then
  echo
  echo "Dry run — nothing written."
  exit 0
fi

# ── Stage ────────────────────────────────────────────────────────────────────
echo
echo "--- staging ---"
psql "$DB_URL" -v ON_ERROR_STOP=1 -q <<SQL
DROP TABLE IF EXISTS ${STAGING};
CREATE TABLE ${STAGING} (
  geoid    text,
  namelsad text,
  mtfcc    text,
  statefp  text,
  geom     geometry(Geometry, 4326)
);
SQL

for shp in "${SHAPEFILES[@]}"; do
  # -t_srs: TIGER ships NAD83; the table is 4326 throughout.
  # -nlt GEOMETRY: island townships arrive as MULTIPOLYGON, mainland as POLYGON,
  #                and the target column holds both already.
  ogr2ogr -f PostgreSQL "PG:${DB_URL}" "$shp" \
    -nln "${STAGING}" -append \
    -t_srs EPSG:4326 -nlt GEOMETRY \
    -lco GEOMETRY_NAME=geom -lco FID= \
    -select GEOID,NAMELSAD,MTFCC,STATEFP \
    -progress >/dev/null
  echo "        staged ${shp}"
done

STAGED="$(psql "$DB_URL" -v ON_ERROR_STOP=1 -tAc "select count(*) from ${STAGING};")"
echo "        staged rows: ${STAGED} (source features: ${TOTAL_FEATURES})"
if [[ "$STAGED" != "$TOTAL_FEATURES" ]]; then
  echo "ERROR: staged ${STAGED} rows from ${TOTAL_FEATURES} features — refusing to upsert." >&2
  echo "  The staging table is left in place for inspection: ${STAGING}" >&2
  exit 1
fi

# ── Upsert ───────────────────────────────────────────────────────────────────
echo
echo "--- upsert ---"
psql "$DB_URL" -v ON_ERROR_STOP=1 <<SQL
INSERT INTO essentials.geofence_boundaries
  (geo_id, name, state, mtfcc, geometry, source, imported_at)
SELECT s.geoid, s.namelsad, s.statefp, s.mtfcc, s.geom, '${SOURCE_TAG}', now()
  FROM ${STAGING} s
ON CONFLICT (geo_id, mtfcc) DO UPDATE
  SET geometry    = EXCLUDED.geometry,
      name        = EXCLUDED.name,
      state       = EXCLUDED.state,
      source      = EXCLUDED.source,
      imported_at = EXCLUDED.imported_at;
SQL

# ── Verify ───────────────────────────────────────────────────────────────────
echo
echo "--- loaded, by state and type ---"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c \
"select left(geo_id,2) as state_fips, mtfcc, count(*) as rows
   from essentials.geofence_boundaries
  where source = '${SOURCE_TAG}' and left(geo_id,2) in ('26','42','39')
    and mtfcc in ('G4040','G4110','G4210')
  group by 1,2 order by 1,2;"

echo "--- the number that matters: Treasury Tracker coverage ---"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c \
"with tt as (
   select state, geoid from treasury.municipalities
    where geoid is not null and length(geoid) in (7,10)
 )
 select tt.state,
        count(*) as tt_entities,
        count(*) filter (where exists (
          select 1 from essentials.geofence_boundaries g
           where g.geo_id = tt.geoid and g.mtfcc in ('G4110','G4040'))) as matched
   from tt group by 1 having count(*) >= 50 order by 2 desc;"

echo "--- point-in-polygon spot check (geometry is usable, not just present) ---"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c \
"select 'Detroit, MI' as probe, count(*) as g4110_hits from essentials.geofence_boundaries
  where mtfcc='G4110' and ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-83.0458, 42.3314), 4326))
 union all
 select 'Philadelphia, PA', count(*) from essentials.geofence_boundaries
  where mtfcc='G4110' and ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-75.1652, 39.9526), 4326))
 union all
 select 'Columbus, OH', count(*) from essentials.geofence_boundaries
  where mtfcc='G4110' and ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-82.9988, 39.9612), 4326));"

psql "$DB_URL" -v ON_ERROR_STOP=1 -q -c "DROP TABLE IF EXISTS ${STAGING};"

echo
echo "Done. Expect PA 2551/2551, MI 1773/1773, OH 253/253 above, every other"
echo "state unchanged, and exactly 1 hit per point-in-polygon probe."
