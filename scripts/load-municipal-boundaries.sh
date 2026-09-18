#!/usr/bin/env bash
# =============================================================================
# load-municipal-boundaries.sh
#
# Loads TIGER/Line 2024 MUNICIPAL boundaries into essentials.geofence_boundaries
# for the states in STATES (default MI, PA, OH — the first load):
#
#   COUSUB (county subdivisions) -> G4040    townships, and in MI cities too
#   PLACE  (places)              -> G4110 incorporated + G4210 CDP
#
# Which layers each state gets is per-state and deliberate — see STATE_LAYERS.
# COUSUB is NOT loaded where a state's county subdivisions are statistical
# Census County Divisions rather than governments.
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
#   # a subset — the second wave, the 8 states still unmatched after the first:
#   DB_URL="..." STATES="25 45 20 21 28 38 46 47" REFRESH=1 \
#     ./scripts/load-municipal-boundaries.sh
#
#   ⚠ REFRESH=1 is REQUIRED for that wave: Massachusetts already carries 293
#   G4040 + 58 G4110 rows from an earlier partial load, so the pre-flight would
#   otherwise refuse. The upsert rewrites those 351 in place.
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
declare -A STATE_NAME=(
  [26]=MI [42]=PA [39]=OH
  [25]=MA [45]=SC [20]=KS [21]=KY [28]=MS [38]=ND [46]=SD [47]=TN
)

# ── ⚠⚠ WHICH LAYERS, PER STATE, AND WHY IT IS NOT "BOTH EVERYWHERE" ──────────
#
# COUSUB is a county-subdivision layer, but a county subdivision is TWO
# DIFFERENT THINGS depending on the state, and TIGER tags both **G4040**:
#
#   CLASSFP T1/T9  a township or town — AN ACTUAL GOVERNMENT with a board and
#                  a budget (MI, PA, MA, KS, ND, SD...)
#   CLASSFP C5     a subdivision coextensive with an incorporated place
#   CLASSFP Z1/Z3/Z5/Z9
#                  a CENSUS COUNTY DIVISION or unorganized territory — a
#                  STATISTICAL AREA. No officials, no budget, no board.
#
# Measured from the 2024 files: **SC (299), KY (493), MS (410) and TN (844) are
# 100% Z-class.** Loading their COUSUB would put 2,046 statistical areas into
# the table tagged identically to real governments — and unlike a CDP, which is
# separated by its own MTFCC (G4210), NOTHING IN THE ROW WOULD DISTINGUISH THEM.
# Civic Spaces flagged exactly this in red for California: it hands a reader a
# city row pointing at a statistical division. "A wrong link, not a missing row."
#
# So COUSUB is loaded only where TT actually keys entities to MCDs, and the
# Z-classes are filtered out even there. Every other state gets PLACE alone,
# which is all its TT entities are keyed to. KS/ND/SD do have real townships,
# but TT carries no entity for any of them; they can be added when it does.
declare -A STATE_LAYERS=(
  [26]="cousub place"   # MI — 1,240 of 1,773 TT entities are 10-digit MCDs
  [42]="cousub place"   # PA — 1,546 of 2,551
  [39]="cousub place"   # OH — TT keys places, but 1,309 real T1 townships
  [25]="cousub place"   # MA — the 13 unmatched are C5 city-MCDs
  [45]="place"          # SC — 13 entities, all places; COUSUB is 100% CCD
  [20]="place"          # KS — Wichita only
  [21]="place"          # KY — Lexington-Fayette only; COUSUB is 100% CCD
  [28]="place"          # MS — Biloxi only; COUSUB is 100% CCD
  [38]="place"          # ND — Grand Forks only
  [46]="place"          # SD — Aberdeen only
  [47]="place"          # TN — Nashville-Davidson only; COUSUB is 100% CCD
)

# Override to load a subset: STATES="25 45" ./load-municipal-boundaries.sh
read -r -a STATES <<< "${STATES:-26 42 39}"

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

for tool in ogr2ogr ogrinfo psql curl unzip; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: $tool not found." >&2; exit 1; }
done

# GDAL's data files. The Windows GDAL SDK sets these in GDALShell.bat, which a
# plain shell never runs, so -t_srs dies with "PROJ: Cannot find proj.db" —
# AFTER the downloads and AFTER --dry-run has already reported success. Fill in
# only what is unset, only from a directory that actually exists. The exported
# value must be a NATIVE path: Windows GDAL cannot read an MSYS /c/... string.
if [[ -z "${PROJ_LIB:-}${PROJ_DATA:-}" ]]; then
  for d in "C:/Program Files/GDAL/projlib" /usr/share/proj /usr/local/share/proj; do
    if [[ -f "${d}/proj.db" ]]; then export PROJ_LIB="$d" PROJ_DATA="$d"; break; fi
  done
fi
if [[ -z "${GDAL_DATA:-}" ]]; then
  for d in "C:/Program Files/GDAL/gdal-data" /usr/share/gdal /usr/local/share/gdal; do
    if [[ -d "$d" ]]; then export GDAL_DATA="$d"; break; fi
  done
fi

# Mask the credential, keep the host. See the header note.
mask_url() { printf '%s' "$1" | sed -E 's#(//[^:]+):[^@]*@#\1:****@#'; }

# ⚠⚠ The Z-class exclusion, in ONE place, used by both the count and the load.
# CLASSFP Z1/Z3/Z5/Z9 are Census County Divisions and unorganized territories:
# statistical areas that TIGER tags G4040, identically to real township
# governments. Nothing in the loaded row would tell them apart. PLACE needs no
# equivalent, because its statistical rows (CDPs) carry their own MTFCC, G4210.
where_clause() {
  [[ "$1" == *_cousub.shp ]] && printf "WHERE CLASSFP NOT LIKE 'Z%%'" || printf ''
}

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
# The selected states as a SQL in-list, so every query below follows STATES
# rather than a hardcoded trio. A stale literal here would silently check the
# wrong states — it would not error, it would just reassure.
FIPS_SQL="$(printf "'%s'," "${STATES[@]}" | sed 's/,$//')"

echo "--- pre-flight ---"
EXISTING="$(psql "$DB_URL" -v ON_ERROR_STOP=1 -tAc \
  "select count(*) from essentials.geofence_boundaries
    where mtfcc in ('G4040','G4110','G4210')
      and left(geo_id, 2) in (${FIPS_SQL});")"
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
  for layer in ${STATE_LAYERS[$fips]}; do
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
#
# ⚠ Counted THROUGH THE SAME WHERE CLAUSE the load uses. A raw Feature Count
# would exceed what is staged by the number of filtered rows, and the staging
# guard below — which refuses to upsert unless staged == counted — would fire
# on every cousub file. The count and the load must ask the same question.
TOTAL_FEATURES=0
for shp in "${SHAPEFILES[@]}"; do
  layer="${shp%.shp}"
  n="$(ogrinfo -q -dialect SQLITE -sql \
        "SELECT count(*) AS n FROM \"${layer}\" $(where_clause "$shp")" "$shp" 2>/dev/null \
        | awk -F'= ' '/n \(Integer\)/{print $2}' | tr -d ' ')"
  printf '        %-28s %6s features%s\n' "$shp" "$n" \
    "$([[ "$shp" == *_cousub.shp ]] && echo '  (statistical Z-classes excluded)' || true)"
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
  # -sql, NOT -select: GDAL refuses "-select with -append" outright
  # ("if -append is specified, -select cannot be used"). The layer name of a
  # shapefile is its basename, so the column list has to go through -sql.
  ogr2ogr -f PostgreSQL "PG:${DB_URL}" "$shp" \
    -nln "${STAGING}" -append \
    -t_srs EPSG:4326 -nlt GEOMETRY \
    -lco GEOMETRY_NAME=geom -lco FID= \
    -sql "SELECT GEOID, NAMELSAD, MTFCC, STATEFP FROM \"${shp%.shp}\" $(where_clause "$shp")" \
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
  where source = '${SOURCE_TAG}' and left(geo_id,2) in (${FIPS_SQL})
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
   from tt group by 1
  order by count(*) - count(*) filter (where exists (
             select 1 from essentials.geofence_boundaries g
              where g.geo_id = tt.geoid and g.mtfcc in ('G4110','G4040'))) desc,
           count(*) desc;"
# ⚠⚠ NO `having count(*) >= 50` — THAT THRESHOLD IS WHY SOUTH CAROLINA HID.
# It was in this query to keep the output short, and it silently excluded every
# state with fewer than 50 TT entities: SC's 13 at 0%, and the six states
# carrying a single city each. A gap list built from this output was wrong for
# exactly as long as the threshold was here. Unmatched states now sort first.

# ── Point-in-polygon probes ──────────────────────────────────────────────────
# ⚠ THE PROBES ARE THE REAL TEST. Rows arriving proves the insert ran; only a
# real coordinate resolving to exactly one polygon proves the GEOMETRY is
# usable. One per loaded state, emitted only for the states in STATES so the
# output cannot quietly reassure about a state this run never touched.
declare -A PROBE=(
  [26]="Detroit, MI|-83.0458|42.3314"        [42]="Philadelphia, PA|-75.1652|39.9526"
  [39]="Columbus, OH|-82.9988|39.9612"       [25]="Weymouth, MA|-70.9395|42.2180"
  [45]="Charleston, SC|-79.9311|32.7765"     [20]="Wichita, KS|-97.3301|37.6872"
  [21]="Lexington, KY|-84.5037|38.0406"      [28]="Biloxi, MS|-88.8853|30.3960"
  [38]="Grand Forks, ND|-97.0329|47.9253"    [46]="Aberdeen, SD|-98.4865|45.4647"
  [47]="Nashville, TN|-86.7816|36.1627"
)
echo "--- point-in-polygon spot check (geometry is usable, not just present) ---"
PROBE_SQL=""
for fips in "${STATES[@]}"; do
  IFS='|' read -r label lon lat <<< "${PROBE[$fips]}"
  # MA's probe is a TOWN, so it is checked at G4040; the rest are incorporated
  # places at G4110. Probing the wrong layer would report 0 for a correct load.
  mtfcc='G4110'; [[ "$fips" == 25 ]] && mtfcc='G4040'
  [[ -n "$PROBE_SQL" ]] && PROBE_SQL+=" union all "
  PROBE_SQL+="select '${label}' as probe, '${mtfcc}' as layer, count(*) as hits
    from essentials.geofence_boundaries
   where mtfcc='${mtfcc}'
     and ST_Covers(geometry, ST_SetSRID(ST_MakePoint(${lon}, ${lat}), 4326))"
done
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "$PROBE_SQL;"

psql "$DB_URL" -v ON_ERROR_STOP=1 -q -c "DROP TABLE IF EXISTS ${STAGING};"

echo
echo "Done. Every state listed above should read N/N, every state NOT loaded in"
echo "this run should be unchanged, and each probe should be exactly 1 hit."
