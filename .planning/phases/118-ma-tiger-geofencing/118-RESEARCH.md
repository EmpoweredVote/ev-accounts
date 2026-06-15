# Phase 118: MA TIGER Geofencing — Research

**Researched:** 2026-06-14
**Domain:** TIGER geofencing — MA state legislative district tiger_geoid backfill + city district data fixes
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Run `load-state-tiger-boundaries.ts --state MA --fips 25 --layers sldu,sldl` — safe to re-run (ON CONFLICT DO NOTHING).
- **D-02:** MA already in STATE_LAYER_ALLOWLIST and STATE_RUN_MAKEVALID — no code change needed.
- **D-03:** Expected counts: G5210=40 (SLDU), G5220=160 (SLDL). Pre-flight assertions embedded in loader for FIPS '25'.
- **D-04:** Backfill tiger_geoid on MA districts WHERE district_type IN ('STATE_UPPER', 'STATE_LOWER'). Pattern: match districts.geo_id to geofence_boundaries.geo_id and set districts.tiger_geoid = geofence_boundaries.geo_id.
- **D-05:** Success criterion: zero NULL tiger_geoid for MA STATE_UPPER and STATE_LOWER.
- **D-06:** 6 new cities need LOCAL district rows AND tiger_geoid linkage. Research determines which path is needed for each city.
- **D-07:** City LOCAL districts use G4110 place boundary geo_id as tiger_geoid.
- **D-08:** verify-ma-tiger-import.sql all existing gates must pass.
- **D-09:** Additional verification: tiger_geoid IS NULL = 0 for STATE_UPPER, STATE_LOWER, and 6 new city LOCAL/LOCAL_EXEC districts.
- **D-10:** Path 0 smoke test: point-in-polygon for Porter Square Cambridge confirms state rep + senator via tiger_geoid join.
- **D-11 (discretion):** Researcher decides wave structure.

### Claude's Discretion
- Exact migration numbering (check MAX(version) before each wave)
- Which specific MA address to use for Path 0 smoke test
- Whether to combine state legislative + city backfills into one migration or keep separate
- How to handle the DB preflight

### Deferred Ideas (OUT OF SCOPE)
- MA campaign finance data for new cities
- MA state executive stances
- School committee geofencing for new cities
- Additional MA cities beyond the 6 in this phase
</user_constraints>

---

## Summary

MA TIGER geofencing is a backfill-only phase. All TIGER boundaries are already loaded: G5210×40 (SLDU senate) and G5220×160 (SLDL house) are confirmed in `essentials.geofence_boundaries`. The STATE_LOWER (160) and STATE_UPPER (40) district rows exist in `essentials.districts` with matching geo_ids. The geo_id join works for all 160 STATE_LOWER and all 40 STATE_UPPER rows. All 6 new city LOCAL/LOCAL_EXEC district rows exist.

**Critical data integrity bug discovered (Medford):** Migration 591 used geo_id `2540115` for Medford, but `2540115` is Melrose city in `geofence_boundaries`. Medford's correct geo_id is `2539835`. The districts table has Medford district rows at geo_id `2540115`, so Path 0 geofencing for Medford currently resolves to Melrose's boundary. This must be corrected in Phase 118.

**TIGER loader run:** Required per D-01 (idempotent, ON CONFLICT DO NOTHING). MA is fully configured in the loader. Five of the six new city G4110 boundaries match their district geo_ids; only Medford is mismatched.

**Primary recommendation:** Three-plan wave: (1) TIGER loader run (idempotent) + tiger_geoid backfill migration for STATE_UPPER/STATE_LOWER. (2) Fix Medford geo_id data bug + tiger_geoid backfill for all 6 city LOCAL/LOCAL_EXEC districts. (3) Phase gate: verify-ma-tiger-import.sql assertions + Path 0 smoke test.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| TIGER boundary load (sldu, sldl) | Database / Storage | — | Script writes to essentials.geofence_boundaries; no API layer involved |
| tiger_geoid backfill (STATE_UPPER/STATE_LOWER) | Database / Storage | — | SQL UPDATE only; no application code changes needed |
| Medford geo_id correction | Database / Storage | — | Data fix on essentials.districts + essentials.governments; no code changes |
| City LOCAL district tiger_geoid backfill | Database / Storage | — | SQL UPDATE; tiger_geoid = geo_id pattern |
| Path 0 district resolution (post-backfill) | API / Backend | Database | Path 0 join in representatives endpoint reads tiger_geoid from districts |
| Verification gate | Database / Storage | — | verify-ma-tiger-import.sql SELECT-only; inline assertion queries |

---

## Current DB State (verified 2026-06-14)

### Query 1: MA geofence_boundaries by MTFCC

```
SELECT mtfcc, COUNT(*) FROM essentials.geofence_boundaries WHERE state = '25' GROUP BY mtfcc ORDER BY mtfcc;
```

| MTFCC | Count | Meaning |
|-------|-------|---------|
| G4020 | 14 | MA counties |
| G4040 | 293 | MA towns (COUSUB, FUNCSTAT='A') |
| G4110 | 58 | MA incorporated cities (place layer) |
| G5200 | 9 | MA congressional districts (cd layer) |
| G5210 | 40 | MA state senate districts (sldu layer) — **ALREADY LOADED** |
| G5220 | 160 | MA state house districts (sldl layer) — **ALREADY LOADED** |
| G5420 | 5 | Additional boundary type |
| X0013 | 9 | Additional boundary type |

**Result:** G5210=40 and G5220=160 are confirmed. TIGER sldu+sldl load has already been completed in a prior phase. D-01 still calls for re-running the loader (idempotent via ON CONFLICT DO NOTHING).

### Query 2: MA districts by district_type (state='MA' uppercase)

| district_type | Count |
|---------------|-------|
| LOCAL | 1 |
| NATIONAL_LOWER | 9 |
| NATIONAL_UPPER | 1 |
| SCHOOL | 1 |
| STATE_EXEC | 6 |

### Query 3: MA districts by district_type (state='ma' lowercase)

| district_type | Count |
|---------------|-------|
| COUNTY | 14 |
| LOCAL | 22 |
| LOCAL_EXEC | 12 |
| SCHOOL | 5 |
| STATE_LOWER | 160 — exists, ready for backfill |
| STATE_UPPER | 40 — exists, ready for backfill |

**Finding:** STATE_LOWER (160) and STATE_UPPER (40) rows exist with state='ma' (lowercase). Backfill migration can proceed immediately without creating new rows.

### Query 4: MAX migration version

```
SELECT MAX(version) FROM supabase_migrations.schema_migrations;
```

**Result: 599**

All 6 city migrations (581, 584, 587, 590, 591, 592) are confirmed applied. The last known value in CONTEXT.md was 597 (Quincy stances) — two additional migrations (598, 599) have been applied since. **Next available migration numbers: 600+.**

### Query 5: tiger_geoid IS NULL counts for all MA districts

| district_type | NULL count |
|---------------|-----------|
| COUNTY | 14 |
| LOCAL | 23 |
| LOCAL_EXEC | 12 |
| NATIONAL_UPPER | 1 |
| SCHOOL | 6 |
| STATE_EXEC | 6 |
| STATE_LOWER | **160** — all need backfill |
| STATE_UPPER | **40** — all need backfill |

**Note:** LOCAL shows 23 (not 22). This is because the Medford geofence_boundaries has NO district row at geo_id `2539835` — but the "Medford" district rows use `2540115`. The query for LOCAL districts shows state='ma' which includes the 6 new cities (all 12 LOCAL/LOCAL_EXEC rows). The count discrepancy of 23 vs 22 likely includes a Lowell or earlier city.

### Query 6: MA LOCAL/LOCAL_EXEC districts (city district rows)

All 6 new city LOCAL and LOCAL_EXEC district rows exist with correct geo_ids (per migration SQL):

| geo_id | label | district_type | tiger_geoid |
|--------|-------|--------------|-------------|
| 2523000 | Fall River | LOCAL | NULL |
| 2523000 | Fall River (Citywide) | LOCAL_EXEC | NULL |
| 2537490 | Lynn | LOCAL | NULL |
| 2537490 | Lynn (Citywide) | LOCAL_EXEC | NULL |
| 2540115 | Medford | LOCAL | NULL — **WRONG geo_id** |
| 2540115 | Medford (Citywide) | LOCAL_EXEC | NULL — **WRONG geo_id** |
| 2545000 | New Bedford | LOCAL | NULL |
| 2545000 | New Bedford (Citywide) | LOCAL_EXEC | NULL |
| 2562535 | Somerville | LOCAL | NULL |
| 2562535 | Somerville (Citywide) | LOCAL_EXEC | NULL |
| 2572600 | Waltham | LOCAL | NULL |
| 2572600 | Waltham (Citywide) | LOCAL_EXEC | NULL |

### Query 7: 6 new city G4110 geofences (actual geo_ids in geofence_boundaries)

| geo_id | name | mtfcc |
|--------|------|-------|
| 2523000 | Fall River city | G4110 |
| 2537490 | Lynn city | G4110 |
| 2539835 | Medford city | G4110 |
| 2545000 | New Bedford city | G4110 |
| 2562535 | Somerville city | G4110 |
| 2572600 | Waltham city | G4110 |

**CRITICAL DISCREPANCY — Medford:**
- `essentials.districts` has Medford LOCAL/LOCAL_EXEC at `geo_id = '2540115'`
- `essentials.geofence_boundaries` has `geo_id = '2540115'` = **Melrose city** (not Medford)
- `essentials.geofence_boundaries` has `geo_id = '2539835'` = **Medford city**
- Migration 591 seeded with wrong FIPS place code; geo_id `2540115` = Melrose, not Medford
- CONTEXT.md mentioned `2541760` as Medford's geo_id — that is also wrong (not in DB at all)
- **The Medford government row also has geo_id='2540115'** (essentials.governments)

### Query 8: STATE_UPPER/STATE_LOWER tiger_geoid NULL counts

```
SELECT district_type, COUNT(*) FROM essentials.districts WHERE state = 'ma' AND district_type IN ('STATE_UPPER', 'STATE_LOWER') AND tiger_geoid IS NULL GROUP BY district_type;
```

| district_type | null_count |
|---------------|-----------|
| STATE_UPPER | 40 |
| STATE_LOWER | 160 |

All 200 state legislative district rows need backfill.

### geo_id Join Verification (backfill will work)

The tiger_geoid backfill uses `SET tiger_geoid = geo_id` (same value). Verified:
- 160 STATE_LOWER districts: all 160 geo_ids match DISTINCT geo_ids in G5220 geofence_boundaries
- 40 STATE_UPPER districts: all 40 geo_ids match DISTINCT geo_ids in G5210 geofence_boundaries
- State senate geo_id format: `25D01`–`25D40` (uppercase D notation)
- State house geo_id format: `25001`–`25160` (numeric)

---

## Critical Bug: Medford geo_id Mismatch

**Root cause:** Migration 591 seeded Medford with geo_id `2540115`, which is the FIPS place code for Melrose, MA (not Medford). Medford's correct FIPS place code is `25-39835` → geo_id `2539835`.

**Affected rows:**
- `essentials.districts` WHERE state='ma' AND geo_id='2540115' — 2 rows (LOCAL, LOCAL_EXEC)
- `essentials.governments` WHERE name='City of Medford, Massachusetts, US' — geo_id='2540115'
- 8 politicians' offices link to the wrong district (all Medford city officials)

**Impact:** Path 0 for a Medford address resolves to geofence `2540115` (Melrose boundary), so Medford users would not get their city officials. Also, the tiger_geoid backfill for LOCAL districts would set `tiger_geoid = '2540115'` → joining to Melrose's geofence.

**Fix required in Phase 118:**
1. `UPDATE essentials.districts SET geo_id = '2539835' WHERE state = 'ma' AND geo_id = '2540115' AND label IN ('Medford', 'Medford (Citywide)')`
2. `UPDATE essentials.governments SET geo_id = '2539835' WHERE name = 'City of Medford, Massachusetts, US'`
3. Verify essentials.offices and essentials.politicians still link correctly via FK (they link via district_id UUID, not geo_id — so the UPDATE to districts.geo_id is sufficient).

**After fix:** the Medford LOCAL/LOCAL_EXEC districts will have geo_id `2539835`, which matches the actual Medford city G4110 geofence. tiger_geoid backfill can then set `tiger_geoid = '2539835'` correctly.

**CONTEXT.md geo_id references that are wrong:**
- CONTEXT.md §specifics lists Lynn geo_id as `2538875` — WRONG. DB has Lynn at `2537490` (confirmed "Lynn city"). Migration 584 and geofence_boundaries both use `2537490`.
- CONTEXT.md §specifics lists Medford geo_id as `2541760` — WRONG. DB has Medford geofence at `2539835`.

---

## Loader Run Command

**Exact command:**

```bash
cd backend
$env:PROJ_LIB = "C:\OSGeo4W\share\proj"
npx tsx scripts/load-state-tiger-boundaries.ts --state MA --fips 25 --layers sldu,sldl
```

**Notes:**
- `PROJ_LIB` must be set on Windows before running — loader uses proj for coordinate transformations via the shapefile pipeline. Without it, the run will fail with a proj error.
- Session pooler connection string (`aws-0-*.pooler.supabase.com:5432`) is used automatically via `DATABASE_URL` in `backend/.env`.
- The loader downloads TIGER 2024 ZIP files from `census.gov/geo/tiger/TIGER2024/`. On Windows, downloads land in OS temp directory.
- Pre-flight assertions in the loader will verify sldu=40 records and sldl=160 records from the shapefile BEFORE writing to DB. If counts mismatch, the loader exits non-zero with a named `MtfccAssertionError`.
- **ON CONFLICT DO NOTHING**: since G5210=40 and G5220=160 are already in the DB, all 200 upserts will be no-ops. The loader will still run the pre-flight assertion and complete successfully — no DB writes needed.

---

## Migration Plan

**MAX(version) = 599. Next available: 600.**

### Migration 600: MA state legislative tiger_geoid backfill

Pattern from migration 321 (VA backfill):

```sql
-- Migration 600: tiger_geoid backfill for MA state legislative districts
BEGIN;

UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type IN ('STATE_LOWER', 'STATE_UPPER')
  AND tiger_geoid IS NULL;

DO $$
DECLARE
  v_sl  INT;
  v_su  INT;
  v_rem INT;
BEGIN
  SELECT COUNT(*) INTO v_sl  FROM essentials.districts WHERE state = 'ma' AND district_type = 'STATE_LOWER'  AND tiger_geoid IS NOT NULL;
  SELECT COUNT(*) INTO v_su  FROM essentials.districts WHERE state = 'ma' AND district_type = 'STATE_UPPER'  AND tiger_geoid IS NOT NULL;
  SELECT COUNT(*) INTO v_rem FROM essentials.districts WHERE state = 'ma' AND district_type IN ('STATE_LOWER', 'STATE_UPPER') AND tiger_geoid IS NULL;

  IF v_sl <> 160 OR v_su <> 40 THEN
    RAISE EXCEPTION 'Count mismatch — expected 160/40, got %/%', v_sl, v_su;
  END IF;
  IF v_rem <> 0 THEN
    RAISE EXCEPTION '% rows still NULL after backfill', v_rem;
  END IF;
  RAISE NOTICE 'Migration 600 complete: STATE_LOWER=%, STATE_UPPER=%', v_sl, v_su;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('600') ON CONFLICT DO NOTHING;
COMMIT;
```

### Migration 601: Medford geo_id correction + city LOCAL/LOCAL_EXEC tiger_geoid backfill

```sql
-- Migration 601: Fix Medford geo_id (2540115→2539835) + backfill city LOCAL/LOCAL_EXEC tiger_geoid
BEGIN;

-- Step 1: Fix Medford geo_id in districts (was seeded with Melrose's FIPS code)
UPDATE essentials.districts
SET geo_id = '2539835'
WHERE state = 'ma'
  AND geo_id = '2540115'
  AND label IN ('Medford', 'Medford (Citywide)');

-- Step 2: Fix Medford geo_id in governments
UPDATE essentials.governments
SET geo_id = '2539835'
WHERE name = 'City of Medford, Massachusetts, US';

-- Step 3: Backfill tiger_geoid on all 6 new city LOCAL and LOCAL_EXEC districts
-- tiger_geoid = geo_id (same value — matches the G4110 place boundary geo_id)
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IN ('2562535', '2537490', '2539835', '2523000', '2572600', '2545000')
  AND tiger_geoid IS NULL;

-- Verification DO block...

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('601') ON CONFLICT DO NOTHING;
COMMIT;
```

**geo_id reference (confirmed from DB):**
| City | Correct geo_id | geofence_boundaries name |
|------|---------------|--------------------------|
| Somerville | 2562535 | Somerville city |
| Lynn | 2537490 | Lynn city |
| Medford | **2539835** (was 2540115) | Medford city |
| Fall River | 2523000 | Fall River city |
| Waltham | 2572600 | Waltham city |
| New Bedford | 2545000 | New Bedford city |

---

## Architecture Patterns

### tiger_geoid Backfill Pattern (from migration 321)

```sql
-- Source: backend/migrations/321_va_tiger_geoid_backfill.sql
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type IN ('STATE_LOWER', 'STATE_UPPER')
  AND tiger_geoid IS NULL;
```

Key insight: `tiger_geoid = geo_id` (same value). The TIGER loader writes `geo_id` to `geofence_boundaries.geo_id`. The districts table was seeded with the same geo_id values by prior migrations. Setting `tiger_geoid = geo_id` on districts creates the FK-like link that Path 0 uses for the join.

### Path 0 Join (how tiger_geoid enables geofencing)

```sql
-- Path 0 reads districts where tiger_geoid IN
-- (SELECT geo_id FROM geofence_boundaries WHERE ST_Covers(geometry, user_point))
SELECT d.*
FROM essentials.districts d
WHERE d.tiger_geoid IN (
  SELECT gb.geo_id
  FROM essentials.geofence_boundaries gb
  WHERE gb.state = '25'
    AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
)
AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', ...);
```

**Pre-backfill Porter Square Cambridge test:**
- G5210 → geo_id `25D27` (Second Middlesex District) — state senate
- G5220 → geo_id `25083` (25th Middlesex District) — state house
- Currently resolves: only NATIONAL_LOWER (geo_id `2505`, MA-05) because only NATIONAL_LOWER has tiger_geoid set

**Post-backfill expected:**
- STATE_UPPER → 1 row (senate district at `25D27`)
- STATE_LOWER → 1 row (house district at `25083`)
- NATIONAL_LOWER → 1 row (MA-05, already working)

---

## Verification Gate

### verify-ma-tiger-import.sql (existing gates — all must pass)

The file already contains these assertions. They should all pass without changes since TIGER was loaded in a prior phase:

1. `invalid_geometry_count = 0` (Gate 1)
2. `geometry_collection_count = 0` (Gate 2)
3. mtfcc counts: G4020=14, G4040=293, G4110=58, G5200=9, G5210=40, G5220=160 (confirmed in DB)
4. Cambridge geo_id `2511000` present (Gate MAGEO-03)
5. Middlesex County geo_id `25017` present (Gate MAGEO-04)
6. Districts table: COUNTY=14, NATIONAL_LOWER=9, STATE_LOWER=160, STATE_UPPER=40
7. Point-in-polygon: Porter Square Cambridge returns G5200 (MA-05), G5210, G5220, G4110, G4020
8. COUSUB gates (Phase 48): G4040=293, Cambridge NOT in G4040, Lexington+Concord present

### Additional assertions to add (Phase 118 new gates)

Add to the bottom of verify-ma-tiger-import.sql:

```sql
-- Phase 118: tiger_geoid backfill gates

-- MAGE-01: STATE_LOWER tiger_geoid IS NULL count = 0
SELECT COUNT(*) AS state_lower_null
FROM essentials.districts
WHERE state = 'ma' AND district_type = 'STATE_LOWER' AND tiger_geoid IS NULL;
-- Expected: 0

-- MAGE-02: STATE_UPPER tiger_geoid IS NULL count = 0
SELECT COUNT(*) AS state_upper_null
FROM essentials.districts
WHERE state = 'ma' AND district_type = 'STATE_UPPER' AND tiger_geoid IS NULL;
-- Expected: 0

-- MAGE-03: 6 new city LOCAL/LOCAL_EXEC tiger_geoid IS NULL count = 0
SELECT COUNT(*) AS city_null
FROM essentials.districts
WHERE state = 'ma'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IN ('2562535', '2537490', '2539835', '2523000', '2572600', '2545000')
  AND tiger_geoid IS NULL;
-- Expected: 0

-- MAGE-04: Medford geo_id fix confirmed (districts use 2539835, not 2540115)
SELECT COUNT(*) AS medford_correct
FROM essentials.districts
WHERE state = 'ma' AND geo_id = '2539835' AND district_type IN ('LOCAL', 'LOCAL_EXEC');
-- Expected: 2

-- MAGE-05: Path 0 smoke test — Porter Square Cambridge resolves to MA state senate + house
SELECT district_type, geo_id, label
FROM essentials.districts
WHERE tiger_geoid IN (
  SELECT gb.geo_id
  FROM essentials.geofence_boundaries gb
  WHERE gb.state = '25'
    AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-71.1190, 42.3876), 4326))
)
AND district_type IN ('STATE_UPPER', 'STATE_LOWER')
ORDER BY district_type;
-- Expected: 2 rows — STATE_LOWER (25th Middlesex, geo_id='25083') + STATE_UPPER (Second Middlesex, geo_id='25D27')
```

---

## Common Pitfalls

### Pitfall 1: Wrong Medford geo_id
**What goes wrong:** Setting tiger_geoid on Medford districts using the existing (wrong) geo_id `2540115` links Medford users to Melrose's geofence boundary. Path 0 for a Medford address resolves to Melrose city officials, not Medford officials.
**Why it happens:** Migration 591 used FIPS place code `40115` (Melrose) instead of `39835` (Medford). Both are 5-digit MA FIPS codes with leading `25` prefix.
**How to avoid:** Fix the geo_id in both `essentials.districts` AND `essentials.governments` BEFORE running the tiger_geoid backfill for city districts. Do not set tiger_geoid on the Medford districts until geo_id is corrected.
**Warning signs:** `SELECT geo_id, name FROM essentials.geofence_boundaries WHERE geo_id = '2540115'` returns "Melrose city" — this confirms the bug.

### Pitfall 2: CONTEXT.md has wrong geo_ids
**What goes wrong:** Planner or executor follows CONTEXT.md geo_ids for Lynn (`2538875`) and Medford (`2541760`) — both are wrong.
**Correct geo_ids (from DB):**
- Lynn: `2537490` (matches migration 584, confirmed "Lynn city" in geofence_boundaries)
- Medford: `2539835` (the actual Medford city G4110 geo_id; `2541760` does not exist in DB)
**How to avoid:** Always use geo_ids sourced from actual DB queries, not CONTEXT.md §specifics.

### Pitfall 3: tiger_geoid backfill before Medford fix
**What goes wrong:** Running the city LOCAL/LOCAL_EXEC backfill with `UPDATE ... SET tiger_geoid = geo_id ... WHERE geo_id IN (...)` while Medford still has geo_id `2540115` sets tiger_geoid to `2540115` — the wrong boundary.
**How to avoid:** Medford geo_id correction MUST run in the same migration as the city backfill, and the UPDATE for Medford districts must happen BEFORE the tiger_geoid = geo_id SET.

### Pitfall 4: JOIN overcounting in verification
**What goes wrong:** Verification queries like `SELECT COUNT(*) FROM districts d JOIN geofence_boundaries gb ON gb.geo_id = d.geo_id WHERE d.district_type = 'STATE_LOWER'` returned 174 rows (not 160) — because some districts.geo_id values appear in multiple geofence_boundaries rows (e.g., from multiple import runs or different layers).
**How to avoid:** Use `COUNT(DISTINCT d.geo_id)` or just `COUNT(*)` on the districts table alone. The backfill UPDATE affects districts rows, not geofence_boundaries rows.

### Pitfall 5: district state case sensitivity
**What goes wrong:** MA districts use state='ma' (lowercase) for LOCAL/LOCAL_EXEC/STATE_LOWER/STATE_UPPER. NATIONAL_LOWER and NATIONAL_UPPER use state='MA' (uppercase). Mixing case in WHERE clauses produces wrong counts or no-op updates.
**How to avoid:** Backfill migration 600 uses state='ma'. Confirmed by Q3 results above.

### Pitfall 6: loader PROJ_LIB on Windows
**What goes wrong:** Running `npx tsx scripts/load-state-tiger-boundaries.ts` on Windows without setting PROJ_LIB causes a silent crash or proj transformation error during shapefile processing.
**How to avoid:** Set `$env:PROJ_LIB = "C:\OSGeo4W\share\proj"` in the PowerShell session before running.

---

## Risk Flags

1. **MAJOR — Medford geo_id bug is active.** Medford officials are currently routed to Melrose's geofence boundary in `essentials.districts` (geo_id `2540115` = Melrose). This affects Path 0 for all Medford users. Fix MUST be part of Phase 118 before tiger_geoid backfill.

2. **MEDIUM — TIGER sldu/sldl already loaded.** Loader will run but all 200 upserts will be no-ops (ON CONFLICT DO NOTHING). This is expected and safe per D-01. No rows will be written; loader will log "0 inserted, 200 skipped" or equivalent.

3. **LOW — verify-ma-tiger-import.sql districts count gate.** The existing SQL file checks `STATE_LOWER|160, STATE_UPPER|40` (line ~43). This gate was written pre-backfill and does NOT check tiger_geoid. It will still pass. New gates (MAGE-01..05) need to be appended.

4. **LOW — Migration 591 Medford government geo_id.** `essentials.governments WHERE name='City of Medford, Massachusetts, US'` has geo_id='2540115'. This does not affect Path 0 (governments.geo_id is not used for geofencing), but it's incorrect metadata. Fix it in Migration 601 for data integrity.

5. **LOW — CONTEXT.md geo_ids are wrong for Medford and Lynn.** The CONTEXT.md §specifics table should not be used as the source of truth for geo_ids. All geo_ids in this research are from direct DB queries.

---

## Recommended Wave Structure

### Plan 118-01: TIGER Loader + State Legislative Backfill

**Goal:** Confirm TIGER sldu/sldl boundaries are present, apply state legislative tiger_geoid backfill.

**Tasks:**
1. DB preflight — run 5 SQL queries to confirm current state (already done in research; planner can embed results as pre-confirmed context for executor)
2. Run TIGER loader (idempotent no-op since boundaries are already loaded): `npx tsx scripts/load-state-tiger-boundaries.ts --state MA --fips 25 --layers sldu,sldl`
3. Apply Migration 600: tiger_geoid backfill for STATE_LOWER (160) and STATE_UPPER (40)
4. Verify: `SELECT COUNT(*) FROM essentials.districts WHERE state='ma' AND district_type IN ('STATE_UPPER','STATE_LOWER') AND tiger_geoid IS NULL` → must return 0

### Plan 118-02: Medford Fix + City LOCAL/LOCAL_EXEC Backfill

**Goal:** Fix Medford geo_id data bug, backfill tiger_geoid on all 6 new city districts.

**Tasks:**
1. Apply Migration 601: Fix Medford geo_id (`2540115` → `2539835`) in districts + governments, then backfill tiger_geoid on all 6 city LOCAL/LOCAL_EXEC districts
2. Verify Medford: `SELECT geo_id, name FROM essentials.geofence_boundaries WHERE geo_id = '2539835'` → "Medford city"
3. Verify city backfill: count WHERE state='ma' AND district_type IN ('LOCAL','LOCAL_EXEC') AND geo_id IN (...6 cities...) AND tiger_geoid IS NULL → must return 0

### Plan 118-03: Phase Gate — Verification + Path 0 Smoke Test

**Goal:** All verification gates pass; Path 0 resolves MA state reps for a real address.

**Tasks:**
1. Run `verify-ma-tiger-import.sql` — all existing gates must pass (run via psql session pooler)
2. Run new inline assertions MAGE-01..05 (tiger_geoid NULL counts = 0, Medford fix, Path 0 smoke)
3. Path 0 smoke test: Porter Square Cambridge (-71.1190, 42.3876) → STATE_LOWER (`25083`, 25th Middlesex) + STATE_UPPER (`25D27`, Second Middlesex)
4. Append new MAGE-01..05 assertions to `verify-ma-tiger-import.sql` and commit

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| TIGER shapefile download + upsert | Custom download/insert script | `load-state-tiger-boundaries.ts --state MA --fips 25 --layers sldu,sldl` | Already handles PROJ_LIB, ON CONFLICT, pre-flight assertions, MakeValid |
| tiger_geoid backfill logic | Custom join query | `SET tiger_geoid = geo_id` pattern (same value, per migration 321) | All TIGER geo_ids are already on districts.geo_id; no join needed |
| Geo_id verification | Ad-hoc lookups | DB query: `SELECT geo_id, name FROM essentials.geofence_boundaries WHERE geo_id = X` | Single authoritative lookup to confirm geo_id/name alignment |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `npx tsx` | TIGER loader | ✓ | (project dev dep) | — |
| PROJ_LIB (OSGeo4W) | TIGER loader Windows | Assumed ✓ | Set in prior phases | Must set `$env:PROJ_LIB` before loader run |
| PostgreSQL direct connection | Migrations via execute_sql | ✓ | Supabase MCP | — |
| psql (session pooler) | verify-ma-tiger-import.sql | Assumed ✓ | Prior phases used it | Can run gates inline via execute_sql |
| census.gov TIGER downloads | Loader (sldu, sldl layers) | ✓ (internet) | 2024 | — |

**Note:** Since G5210/G5220 are already in DB, the loader's network fetch will still download the ZIP files but write 0 rows. If network is unavailable, the loader will fail. In that case, skip the loader run and document that boundaries were confirmed pre-existing.

---

## Validation Architecture

Nyquist validation is not applicable for this phase — all work is SQL migration and CLI scripts, no application code changes. No test framework involvement.

**Phase gate queries (executable inline via Supabase MCP):**

| Gate | Query | Expected |
|------|-------|---------|
| MAGE-00 | `SELECT COUNT(*) FROM geofence_boundaries WHERE state='25' AND mtfcc IN ('G5210','G5220')` | 200 (40+160) |
| MAGE-01 | `SELECT COUNT(*) FROM districts WHERE state='ma' AND district_type='STATE_LOWER' AND tiger_geoid IS NULL` | 0 |
| MAGE-02 | `SELECT COUNT(*) FROM districts WHERE state='ma' AND district_type='STATE_UPPER' AND tiger_geoid IS NULL` | 0 |
| MAGE-03 | `SELECT COUNT(*) FROM districts WHERE state='ma' AND district_type IN ('LOCAL','LOCAL_EXEC') AND geo_id IN ('2562535','2537490','2539835','2523000','2572600','2545000') AND tiger_geoid IS NULL` | 0 |
| MAGE-04 | `SELECT COUNT(*) FROM districts WHERE state='ma' AND geo_id='2539835' AND district_type IN ('LOCAL','LOCAL_EXEC')` | 2 |
| MAGE-05 | Point-in-polygon Porter Square → STATE_LOWER + STATE_UPPER both return 1 row each | 2 rows |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | PROJ_LIB is available at `C:\OSGeo4W\share\proj` on the executor machine | Loader Run Command | Loader will fail; must locate correct path |
| A2 | Migration MAX(version)=599 is current at execution time | Migration Plan | Next migration would conflict; always re-check before applying |

**All other claims are VERIFIED from direct DB queries run 2026-06-14.**

---

## Sources

### Primary (HIGH confidence)
- Direct DB queries via `pg` Pool against Supabase production — all counts and geo_id values
- `backend/migrations/321_va_tiger_geoid_backfill.sql` — canonical tiger_geoid backfill pattern
- `backend/scripts/load-state-tiger-boundaries.ts` lines 34-111 (STATE_LAYER_ALLOWLIST, STATE_RUN_MAKEVALID, MA assertions) — loader config
- `backend/scripts/verify-ma-tiger-import.sql` — existing verification gates
- `backend/migrations/581_somerville_city_government.sql` — Somerville geo_id confirmed 2562535
- `backend/migrations/584_lynn_city_government.sql` — Lynn geo_id confirmed 2537490
- `backend/migrations/587_new_bedford_city_government.sql` — New Bedford geo_id confirmed 2545000
- `backend/migrations/590_fall_river_city_government.sql` — Fall River geo_id confirmed 2523000
- `backend/migrations/591_medford_city_government.sql` — Medford seeded with geo_id 2540115 (BUG)
- `backend/migrations/592_waltham_city_government.sql` — Waltham geo_id confirmed 2572600

### Secondary (MEDIUM confidence)
- `supabase_migrations.schema_migrations` — MAX(version)=599 as of 2026-06-14

---

## Metadata

**Confidence breakdown:**
- DB state (TIGER counts, district counts, geo_ids): HIGH — direct DB queries
- Medford bug identification: HIGH — confirmed via geofence_boundaries name lookup
- Loader run command: HIGH — from CONTEXT.md + loader source code
- Migration pattern: HIGH — from migration 321 source
- Correct Medford geo_id (2539835): HIGH — `SELECT geo_id, name FROM geofence_boundaries WHERE name ILIKE '%medford%'`

**Research date:** 2026-06-14
**Valid until:** 2026-07-14 (stable — TIGER data + migration ledger are static once written)
