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
# geo_id is a bare 5-digit ZIP, and county geo_ids are 5-digit state+county FIPS
# — the SAME numeric space. '11001' is both Floral Park NY and Washington DC;
# '18055' is both Hellertown PA and Greene County, Indiana. Collisions are not a
# risk to be minimised, they are ARITHMETICALLY GUARANTEED.
#
# Step 0 below refuses to run if the guard is missing from origin/master.
# ---------------------------------------------------------------------------
#
# ---------------------------------------------------------------------------
# GEOMETRY IS LOADED AT FULL RESOLUTION. DO NOT ADD SIMPLIFICATION BACK.
#
# This script used to run ST_SimplifyPreserveTopology(geom, 0.0005) (~55m), on
# the reasoning that a ZCTA is "only ever a QUERY SHAPE" so the cost is "a
# sub-point shift in share percentages".
#
# That reasoning is wrong at borders, and it shipped a real regression on
# 2026-08-18. Simplifying the ZIP layer while the county layer stays at full
# resolution makes shared borders diverge, which CREATES overlaps that do not
# exist in the source data:
#
#   ZCTA 46360  gained Berrien County, MICHIGAN   (no overlap at full res)
#   ZCTA 47401  gained Lawrence County, IN        (no overlap at full res)
#
# 46360 gaining a Michigan county re-leaked Michigan officials into an Indiana
# ZIP — the exact bug the ZIP feature had already fixed. Nationwide, 259 ZIPs
# pulled in an out-of-state county that carried offices.
#
# The error is NOT a shift in share magnitude, which would indeed be harmless.
# It changes district SET MEMBERSHIP, and NO tolerance above zero fixes that:
# a smaller tolerance shrinks the spurious sliver's area but the district is
# still in the result set.
#
# Cost of full resolution, measured: 51,266,155 points and ~783 MB of geometry
# for 33,791 rows, versus 4,538,093 points / ~71 MB simplified. The table went
# from 636 MB to ~1.4 GB. That is the correct trade.
# ---------------------------------------------------------------------------
#
# TIGER ships ZCTAs as ONE nationwide file (529 MB) — there are no per-state
# slices, so coverage is all-or-nothing.
#
# Prerequisites: gdal (ogr2ogr), postgresql-client (psql)
#
# Usage:
#   DB_URL="postgresql://...:5432/postgres" ./scripts/load-zcta-boundaries.sh
#
# If DB_URL's role cannot CREATE in the essentials schema (the ev_api role in
# backend/.env CANNOT — see Step 0), also pass a role that can:
#   DB_URL="..." DDL_DB_URL="postgresql://postgres:...@...:5432/postgres" \
#     ./scripts/load-zcta-boundaries.sh
#
# Idempotent AND resumable:
#   - download: skipped when the zip is already present
#   - stage table: dropped and recreated
#   - merge: ON CONFLICT (geo_id, mtfcc) DO UPDATE  <- (geo_id, mtfcc), never geo_id
#   - state backfill: batched by leading digit, WHERE state IS NULL
#
# EVERY write is scoped to mtfcc='G6350'. It cannot touch another layer's rows.
# =============================================================================

set -euo pipefail

if [[ -z "${DB_URL:-}" ]]; then
  echo "ERROR: DB_URL is required (direct or SESSION-mode connection, port 5432)."
  echo "       The :6543 transaction pooler cannot run COPY or DDL."
  exit 1
fi

# Role used for DDL (stage table create/drop). Defaults to DB_URL; override when
# DB_URL's role lacks CREATE on the essentials schema.
DDL_DB_URL="${DDL_DB_URL:-$DB_URL}"

command -v ogr2ogr >/dev/null 2>&1 || { echo "ERROR: ogr2ogr not found. Install gdal."; exit 1; }
command -v psql    >/dev/null 2>&1 || { echo "ERROR: psql not found. Install postgresql-client."; exit 1; }

# PROJ database. Without it ogr2ogr cannot reproject NAD83 -> WGS84 and dies with
# "PROJ: proj_identify: Cannot find proj.db". Only set when not already provided.
if [[ -z "${PROJ_DATA:-}${PROJ_LIB:-}" ]]; then
  for candidate in "/c/Program Files/GDAL/projlib" "/usr/share/proj" "/usr/local/share/proj"; do
    if [[ -f "$candidate/proj.db" ]]; then
      export PROJ_DATA="$candidate"
      export PROJ_LIB="$candidate"
      echo "       PROJ_DATA=$candidate"
      break
    fi
  done
fi

# Every statement below that can exceed a role's statement_timeout is prefixed
# with this. Supavisor IGNORES the `options=-c statement_timeout=...` connection
# parameter (verified 2026-08-18: it still reported 30s), so the timeout can only
# be lifted with an in-session SET. It is session-local and changes no role
# config. The merge alone takes 45-80s; ev_api's default timeout is 30s.
NO_TIMEOUT="SET statement_timeout = '0';"

# ---------------------------------------------------------------------------
# Step 0: preflight — refuse to run before spending 529 MB of download
# ---------------------------------------------------------------------------
if [[ "${SKIP_GUARD_CHECK:-0}" != "1" ]]; then
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  echo "[0/6] Preflight."
  echo "      - G6350 district-join guard on origin/master ..."
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
  echo "        guard present."
fi

# Privilege preflight. This exists because the previous version of this script
# discovered the problem only AFTER downloading 529 MB and staging: ogr2ogr
# created the stage table itself, and backend/.env's DATABASE_URL is the ev_api
# role, for which has_schema_privilege('essentials','CREATE') is FALSE (it is
# false on `public` too). ogr2ogr then failed with permission denied.
echo "      - CREATE privilege for the DDL role ..."
CAN_CREATE="$(psql "$DDL_DB_URL" -tAc \
  "SELECT has_schema_privilege('essentials','CREATE');" 2>/dev/null || echo 'f')"
if [[ "$CAN_CREATE" != "t" ]]; then
  DDL_ROLE="$(psql "$DDL_DB_URL" -tAc 'SELECT current_user;' 2>/dev/null || echo 'unknown')"
  echo
  echo "REFUSING TO RUN: role '$DDL_ROLE' cannot CREATE in schema essentials,"
  echo "  so the stage table cannot be created."
  echo
  echo "  Pass a role that can, and keep the bulk load on the ordinary role:"
  echo "    DB_URL=\"<app role>\" DDL_DB_URL=\"<postgres role>\" $0"
  echo
  echo "  Do NOT work around this by granting CREATE to the app role for the run —"
  echo "  a mid-run failure leaves the grant in place."
  exit 1
fi
echo "        ok ($(psql "$DDL_DB_URL" -tAc 'SELECT current_user;' 2>/dev/null))"

# Write privileges for the loading role.
echo "      - INSERT/UPDATE on geofence_boundaries for the load role ..."
CAN_WRITE="$(psql "$DB_URL" -tAc \
  "SELECT has_table_privilege('essentials.geofence_boundaries','INSERT')
      AND has_table_privilege('essentials.geofence_boundaries','UPDATE');" 2>/dev/null || echo 'f')"
[[ "$CAN_WRITE" == "t" ]] || { echo "REFUSING TO RUN: load role cannot INSERT/UPDATE geofence_boundaries."; exit 1; }
echo "        ok"
echo

WORK_DIR="${WORK_DIR:-/tmp/tiger-zcta}"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

ZIP_FILE="tl_2024_us_zcta520.zip"
SHP_FILE="$WORK_DIR/tl_2024_us_zcta520.shp"
URL="https://www2.census.gov/geo/tiger/TIGER2024/ZCTA520/$ZIP_FILE"

# ---------------------------------------------------------------------------
# Step 1: download (529 MB)
# ---------------------------------------------------------------------------
if [[ -f "$ZIP_FILE" ]]; then
  echo "[1/6] [skip] $ZIP_FILE already downloaded"
else
  echo "[1/6] Downloading $URL (529 MB — this takes a while)..."
  curl -sSL --fail "$URL" -o "$ZIP_FILE"
fi
unzip -o -q "$ZIP_FILE"
[[ -f "$SHP_FILE" ]] || { echo "ERROR: $SHP_FILE missing after unzip."; exit 1; }

# Feature count from the source, used to prove the load was complete.
EXPECTED_FEATURES="$(ogrinfo -so -al "$SHP_FILE" 2>/dev/null \
  | grep -i '^Feature Count:' | head -1 | tr -dc '0-9')"
[[ -n "$EXPECTED_FEATURES" ]] || { echo "ERROR: could not read feature count from $SHP_FILE"; exit 1; }
echo "       source feature count: $EXPECTED_FEATURES"

# ---------------------------------------------------------------------------
# Step 2: stage table
#
# Created explicitly rather than by ogr2ogr, so the DDL can run as a different
# role from the bulk load (see Step 0). Column names/types match what the
# PostgreSQL driver would have created, so `-append` maps by name.
# ---------------------------------------------------------------------------
echo "[2/6] Creating essentials.geofence_zcta_stage ..."
LOAD_ROLE="$(psql "$DB_URL" -tAc 'SELECT current_user;')"
psql "$DDL_DB_URL" -v ON_ERROR_STOP=1 -q -c "
  DROP TABLE IF EXISTS essentials.geofence_zcta_stage;
  CREATE TABLE essentials.geofence_zcta_stage (
    ogc_fid serial PRIMARY KEY,
    zcta5   varchar,
    geom    public.geometry(MultiPolygon, 4326)
  );
  GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE
    ON essentials.geofence_zcta_stage TO \"$LOAD_ROLE\";
  GRANT USAGE, SELECT
    ON SEQUENCE essentials.geofence_zcta_stage_ogc_fid_seq TO \"$LOAD_ROLE\";
"

# TIGER is NAD83 (EPSG:4269); reproject to 4326 to match geofence_boundaries.
#
# -gt 2000 is load-bearing, not tuning. ogr2ogr defaults to one transaction for
# the whole layer, so PG_USE_COPY issues a single COPY covering all 33.8k
# features. Against a role with a 30s statement_timeout that COPY was cancelled
# at line 33407 of 33791 — 384 rows short — and the whole thing rolled back.
# Committing every 2000 features keeps each COPY to a couple of seconds.
echo "[2/6] Loading shapefile (full resolution, committing every 2000 features) ..."
ogr2ogr \
  -f PostgreSQL "$DB_URL" \
  "$SHP_FILE" \
  -nln essentials.geofence_zcta_stage \
  -nlt MULTIPOLYGON \
  -t_srs EPSG:4326 \
  -append \
  -gt 2000 \
  -progress \
  --config PG_USE_COPY YES \
  -sql "SELECT ZCTA5CE20 AS zcta5 FROM tl_2024_us_zcta520"

# ogr2ogr EXITS 0 EVEN WHEN THE COPY FAILED. On 2026-08-18 it printed
# "ERROR 1: COPY statement failed / canceling statement due to statement timeout"
# and still returned 0, so the calling shell reported success on an empty table.
# The row count is the only trustworthy signal.
echo
STAGED="$(psql "$DB_URL" -v ON_ERROR_STOP=1 -tAc \
  "SELECT count(*) FROM essentials.geofence_zcta_stage;")"
echo "       staged rows: $STAGED (expected $EXPECTED_FEATURES)"
if [[ "$STAGED" != "$EXPECTED_FEATURES" ]]; then
  echo "ERROR: staged row count does not match the shapefile feature count."
  echo "       ogr2ogr's exit code is not reliable here — check its output above"
  echo "       for a cancelled COPY. Re-run; the script re-creates the stage table."
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 3: merge, at FULL RESOLUTION
#
# `state` is left NULL here and backfilled in Step 4 — the dominant-county
# spatial join is far too slow to hold open inside this statement.
# ---------------------------------------------------------------------------
echo "[3/6] Merging into geofence_boundaries (full resolution, no simplification) ..."
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  $NO_TIMEOUT
  INSERT INTO essentials.geofence_boundaries
    (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
  SELECT s.zcta5,
         NULL,
         s.zcta5,
         NULL,
         'G6350',
         s.geom,
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
echo "[4/6] Backfilling dominant state FIPS (10 batches) ..."
for d in 0 1 2 3 4 5 6 7 8 9; do
  echo "       batch ${d}xxxx ..."
  psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
    $NO_TIMEOUT
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

# ---------------------------------------------------------------------------
# Step 5: drop the stage table (as the DDL role that created it)
# ---------------------------------------------------------------------------
echo "[5/6] Dropping stage table ..."
psql "$DDL_DB_URL" -v ON_ERROR_STOP=1 -q -c \
  "DROP TABLE IF EXISTS essentials.geofence_zcta_stage;"

# ---------------------------------------------------------------------------
# Step 6: verification
# ---------------------------------------------------------------------------
echo "[6/6] Verification"
FAILED=0

echo
echo "Row count / states / unresolved state:"
echo "  NOTE: unresolved_state is EXPECTED to be ~17, NOT 0. The county layer"
echo "  (G4020) covers 50 states + DC + Puerto Rico and has NO rows for the US"
echo "  Virgin Islands, Guam, the Northern Marianas or American Samoa, so those"
echo "  territories' ZCTAs have no county to derive a dominant state from."
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  $NO_TIMEOUT
  SELECT count(*) AS zcta_rows,
         count(DISTINCT state) AS states,
         count(*) FILTER (WHERE state IS NULL) AS unresolved_state
  FROM essentials.geofence_boundaries WHERE mtfcc = 'G6350';
"

echo "Geometry validity (expect invalid = 0):"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  $NO_TIMEOUT
  SELECT count(*) FILTER (WHERE NOT public.ST_IsValid(geometry)) AS invalid
  FROM essentials.geofence_boundaries WHERE mtfcc = 'G6350';
"

# Proves the geometry was NOT simplified. Simplified at 0.0005 the layer held
# ~4.5M points; at full resolution ~51.3M. Anything near the low figure means
# a simplification crept back in — see the header for why that is a bug.
echo "Resolution check (full-res is ~51M points; ~4.5M means simplification is back):"
POINTS="$(psql "$DB_URL" -v ON_ERROR_STOP=1 -tAc \
  "$NO_TIMEOUT SELECT sum(public.ST_NPoints(geometry))
   FROM essentials.geofence_boundaries WHERE mtfcc = 'G6350';")"
echo "       total points: $POINTS"
if [[ "$POINTS" -lt 20000000 ]]; then
  echo "       FAIL: too few points — the layer looks simplified."
  FAILED=1
else
  echo "       PASS: full resolution."
fi

# The guard check, stated correctly.
#
# The previous version asserted that a raw
#   geofence_boundaries.geo_id = districts.geo_id
# join returns zero offices. That is not achievable and never was: county geo_ids
# are 5-digit FIPS sharing a numeric space with 5-digit ZIPs, so once the
# nationwide layer is loaded this join finds ~1,909 colliding geo_ids and ~1,425
# offices. Measured with only the 807 Indiana ZCTAs it happened to be 0, and that
# was extrapolated to 40x the surface.
#
# It also never referenced the application guard at all. What actually matters is
# that no OFFICE is reachable through a district whose geo_id IS a ZIP the ZIP
# query would resolve — which is what FALLBACK_EXCLUDED_MTFCCS prevents.
echo "GUARD — offices reachable via a district whose geo_id collides with a ZIP:"
echo "        (informational: collisions are unavoidable and are handled in code"
echo "         by FALLBACK_EXCLUDED_MTFCCS; verify behaviour with the API check below)"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  $NO_TIMEOUT
  SELECT count(DISTINCT gb.geo_id) AS colliding_zip_geo_ids,
         count(o.id)               AS offices_behind_collisions
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id
  LEFT JOIN essentials.offices o ON o.district_id = d.id
  WHERE gb.mtfcc = 'G6350';
"
echo "        BEHAVIOURAL CHECK (this is the one that matters) — for a ZIP whose"
echo "        string collides with an out-of-state county carrying offices, the API"
echo "        must not return that county's officials. Known collisions to try:"
echo "          48439 (MI) vs Tarrant County TX   55025 (MN) vs Dane County WI"
echo "          53035 (WI) vs Kitsap County WA    32003 (FL) vs Clark County NV"
echo "        curl -s \$API/api/essentials/candidates/48439 | grep -c Tarrant   # expect 0"

echo "Ground truth — 46220 district counts (expect G5200=1, G5210=3, G5220=4):"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  $NO_TIMEOUT
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
echo "        WARNING: this fixture checks ONLY the state-legislative layers. It"
echo "        passed unchanged (1/3/4) on 2026-08-18 while simplification was"
echo "        silently adding COUNTY overlaps to 259 ZIPs. Do not read a pass here"
echo "        as 'the geometry is fine'. The county check below is the sharper one."

# The check the 46220 fixture cannot make. At full resolution a ZCTA's county
# shares should sum to 1: counties tile the country, so any shortfall or excess
# means the ZIP layer and the county layer disagree about the same border.
echo "County-share closure (each ZIP's county shares must sum to ~1.0):"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  $NO_TIMEOUT
  WITH sample AS (
    SELECT geo_id, geometry FROM essentials.geofence_boundaries
    WHERE mtfcc = 'G6350' AND geo_id IN
      ('46360','47401','40820','63673','86044','89439','78701','10001')
  ),
  shares AS (
    SELECT s.geo_id,
           sum(public.ST_Area(public.ST_Intersection(c.geometry, s.geometry))
               / NULLIF(public.ST_Area(s.geometry),0)) AS total_share,
           count(*) AS counties
    FROM sample s
    JOIN essentials.geofence_boundaries c
      ON c.mtfcc = 'G4020'
     AND c.geometry OPERATOR(public.&&) s.geometry
     AND public.ST_Intersects(c.geometry, s.geometry)
     AND NOT public.ST_Touches(c.geometry, s.geometry)
    GROUP BY s.geo_id
  )
  SELECT geo_id, counties, round(total_share::numeric, 6) AS total_share,
         CASE WHEN abs(total_share - 1) < 0.001 THEN 'ok' ELSE 'SUSPECT' END AS verdict
  FROM shares ORDER BY geo_id;
"

echo "Index sanity — the ZIP overlap must be an Index Scan, never a Seq Scan:"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  $NO_TIMEOUT
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
  && { echo "       FAIL: Seq Scan on geofence_boundaries — GIST index not used."; FAILED=1; } \
  || echo "       PASS: no Seq Scan on geofence_boundaries."

echo
echo "Table size after import:"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  $NO_TIMEOUT
  SELECT pg_size_pretty(pg_total_relation_size('essentials.geofence_boundaries')) AS total,
         pg_size_pretty(sum(pg_column_size(geometry))) AS geometry_bytes
  FROM essentials.geofence_boundaries;
"

echo
echo "REMINDER: the ZIP endpoint caches results for ZIP_CACHE_TTL_SECONDS (3600s)"
echo "in Upstash Redis under 'candidates:zip:v2:<zip>'. The HTTP max-age=300 header"
echo "is NOT the real TTL, and a ?cachebust= param does not help — the key is the"
echo "ZIP alone. To see this import's effect immediately, query a ZIP nobody has"
echo "requested in the last hour."

echo
if [[ "$FAILED" -ne 0 ]]; then
  echo "=== FINISHED WITH FAILURES — see FAIL lines above. ==="
  exit 1
fi
echo "=== Done. ==="
