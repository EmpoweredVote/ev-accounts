# Phase 118: MA TIGER Geofencing — Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Import MA state legislative district boundaries (40 SLDU senate + 160 SLDL house) into `essentials.geofence_boundaries` via the generalized TIGER loader, backfill `tiger_geoid` on `essentials.districts` for MA STATE_UPPER and STATE_LOWER records, and ensure the 6 new MA cities added in migrations 581–596 (Somerville, Lynn, Medford, Fall River, Waltham, New Bedford) have correct district records and `tiger_geoid` linkage so Path 0 resolves MA users to their state legislators and city officials.

Cities in scope for new-city geofencing:
- **Somerville** (migration 581)
- **Lynn** (migration 584)
- **Medford** (migration 591)
- **Fall River** (migration 590)
- **Waltham** (migration 592)
- **New Bedford** (migration 587)

</domain>

<decisions>
## Implementation Decisions

### TIGER Loader (State Legislative)
- **D-01 [LOCKED]:** Run `load-state-tiger-boundaries.ts --state MA --fips 25 --layers sldu,sldl` regardless of whether data is already present — the script uses ON CONFLICT DO NOTHING so it is safe to re-run. Do not assume boundaries are already loaded; run the loader as part of this phase.
- **D-02 [LOCKED]:** MA is already in `STATE_LAYER_ALLOWLIST` and `STATE_RUN_MAKEVALID` in `load-state-tiger-boundaries.ts` — no code change needed to the loader. TIGER vintage 2024 (default), congress 119 (default).
- **D-03 [LOCKED]:** Expected counts after load: G5210=40 (MA Senate / SLDU), G5220=160 (MA House / SLDL). Pre-flight assertions are already embedded in the loader for MA (FIPS '25').

### tiger_geoid Backfill (State Legislative)
- **D-04 [LOCKED]:** After the TIGER load, write a migration to backfill `tiger_geoid` on all MA `essentials.districts` rows where `district_type IN ('STATE_UPPER', 'STATE_LOWER')`. Pattern: match `districts.geo_id` to `geofence_boundaries.geo_id` and copy `geofence_boundaries.geo_id` → `districts.tiger_geoid`. Same approach as Phase 110 VA (migration 321).
- **D-05 [LOCKED]:** Success criterion: `SELECT COUNT(*) FROM essentials.districts WHERE state = 'MA' AND district_type IN ('STATE_UPPER', 'STATE_LOWER') AND tiger_geoid IS NULL` returns 0.

### New MA Cities Geofencing
- **D-06 [LOCKED]:** The 6 new cities (Somerville, Lynn, Medford, Fall River, Waltham, New Bedford) need full district records in `essentials.districts` AND `tiger_geoid` linkage. Researcher must first query the DB to determine if district rows already exist from the seeding migrations. Phase covers BOTH paths: (a) create missing district rows, (b) backfill `tiger_geoid` on existing or newly-created rows.
- **D-07 [LOCKED]:** City council geofencing uses the G4110 place boundary (already in `geofence_boundaries` from MA place layer). The `tiger_geoid` on `essentials.districts` for city LOCAL districts should match the FIPS place geo_id of the city boundary polygon.

### Verification
- **D-08 [LOCKED]:** Run `backend/scripts/verify-ma-tiger-import.sql` — all existing gates must pass (G5210|40, G5220|160, no invalid geometries, no GeometryCollections, correct expected distributions).
- **D-09 [LOCKED]:** Additional verification queries:
  - `tiger_geoid IS NULL` count = 0 for MA STATE_UPPER and STATE_LOWER districts
  - `tiger_geoid IS NULL` count = 0 for the 6 new city LOCAL districts
- **D-10 [LOCKED]:** Path 0 smoke test: run a point-in-polygon lookup for a known MA address (e.g., a Boston/Cambridge address) and confirm it resolves to the correct state rep + senator via the `tiger_geoid` join.

### Wave Structure
- **D-11:** Researcher decides optimal plan structure. Suggested: Plan 1 = TIGER loader run + DB preflight assertions + state legislative tiger_geoid backfill migration. Plan 2 = new city district records + city tiger_geoid backfill. Plan 3 = phase gate (verify script + smoke tests).

### Claude's Discretion
- Exact migration numbering (check MAX(version) from supabase_migrations before each wave)
- Which specific MA address to use for Path 0 smoke test
- Whether to combine state legislative + city backfills into one migration or keep separate
- How to handle the DB preflight (researcher queries the DB to establish current state before writing the plan)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### TIGER Loader
- `backend/scripts/load-state-tiger-boundaries.ts` — Generalized TIGER loader. MA already in STATE_LAYER_ALLOWLIST (sldu, sldl, place, county, cousub, cd). MA MTFCC pre-flight assertions at line ~670 (FIPS '25' block). Run with `--state MA --fips 25 --layers sldu,sldl`. ON CONFLICT DO NOTHING on geofence_boundaries.

### Verification
- `backend/scripts/verify-ma-tiger-import.sql` — All MA TIGER verification queries. Gates: no invalid geometries, G5210|40, G5220|160, point-in-polygon smoke tests for Cambridge/Boston addresses. MUST pass after Phase 118.

### Prior tiger_geoid backfill pattern (Phase 110 VA)
- `.planning/STATE.md` §Phase 110 Status — VAGE-03: `tiger_geoid` backfill applied via migration 321. Same pattern applies for MA STATE_UPPER/STATE_LOWER districts.

### New MA Cities Seeding Migrations
- `backend/migrations/581_somerville_city_government.sql` — Somerville government + district records
- `backend/migrations/584_lynn_city_government.sql` — Lynn government + district records
- `backend/migrations/590_fall_river_city_government.sql` — Fall River government + district records
- `backend/migrations/591_medford_city_government.sql` — Medford government + district records
- `backend/migrations/592_waltham_city_government.sql` — Waltham government + district records
- `backend/migrations/587_new_bedford_city_government.sql` — New Bedford government + district records
- (Read these to confirm whether essentials.districts rows exist for each city before deciding what D-06 requires)

### Existing MA District Infrastructure
- `backend/migrations/150_ma_government_chambers.sql` — MA government stub, chambers
- `backend/migrations/151_ma_state_senate_officials.sql` — MA state senate officials
- `backend/migrations/152_ma_state_house_officials.sql` — MA state house officials

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `backend/scripts/load-state-tiger-boundaries.ts` — Full-featured TIGER loader with MA already configured. No code changes needed; just run with correct args.
- `backend/scripts/verify-ma-tiger-import.sql` — Verification script already written. Add new assertions for tiger_geoid backfill.

### Established Patterns
- **TIGER loader**: `npx tsx scripts/load-state-tiger-boundaries.ts --state MA --fips 25 --layers sldu,sldl` — use session pooler connection (`aws-0-*.pooler.supabase.com:5432`). PROJ_LIB must be set on Windows.
- **tiger_geoid backfill migration**: `UPDATE essentials.districts d SET tiger_geoid = gb.geo_id FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id AND d.state = 'MA' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER')` — same pattern as VA migration 321.
- **Migration numbering**: Always check `SELECT MAX(version) FROM supabase_migrations.schema_migrations` before writing. Last known: 597 (quincy_stances). Next available: 598+.
- **Session pooler**: Use `aws-0-*.pooler.supabase.com:5432` (IPv4) for psql commands on Windows. Direct connection string format in `.env`.

### Integration Points
- `essentials.geofence_boundaries` — where TIGER polygons land; state='25' for MA
- `essentials.districts` — where tiger_geoid needs to be set for Path 0 to work
- Path 0 join: `districts.tiger_geoid = geofence_boundaries.geo_id` WHERE point is inside polygon

</code_context>

<specifics>
## Specific Details

**MA TIGER layer expected counts (from loader pre-flight assertions):**
- sldu: G5210 × 40 (MA Senate districts)
- sldl: G5220 × 160 (MA House districts)
- FIPS: 25 (Massachusetts)

**New city FIPS place geo_ids (for tiger_geoid linkage):**
- Somerville: `2562535` (G4110, already in geofence_boundaries from MA place layer)
- Lynn: `2538875` (G4110)
- Medford: `2541760` (G4110)
- Fall River: `2523000` (G4110)
- Waltham: `2572600` (G4110)
- New Bedford: `2545000` (G4110)
- (Researcher should verify exact geo_ids by querying geofence_boundaries WHERE state='25' AND name LIKE '%city%')

**Point-in-polygon smoke test addresses:**
- Porter Square, Cambridge: (-71.1190, 42.3876) — should resolve MA-05 cd, MA Senate + House
- North Boston: any Boston address should resolve to correct state rep + senator

</specifics>

<deferred>
## Deferred Ideas

- MA campaign finance data for new cities — separate phase
- MA state executive stances — Essentials team scope
- School committee geofencing for new cities — separate phase if needed
- Additional MA cities beyond the 6 in this phase

</deferred>

---

*Phase: 118-ma-tiger-geofencing*
*Context gathered: 2026-06-14 via user conversation*
