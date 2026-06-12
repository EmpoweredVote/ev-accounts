---
phase: 116-national-us-house-tiger
plan: 01
subsystem: database
tags: [tiger, geofencing, geo_districts, geofence_boundaries, us_house, shapefile, postgresql]

requires:
  - phase: 110-va-official-records-geofencing
    provides: "TIGER polygon import pattern (per-state zip download, shapefile streaming, ON CONFLICT DO NOTHING)"
  - phase: 69-tiger-district-geofencing
    provides: "CA us_house rows in geo_districts (52 rows) + geofence_boundaries G5200 (52 rows) — skipped via ON CONFLICT"

provides:
  - "436 us_house rows in essentials.geo_districts — all 50 states + DC congressional districts"
  - "436 G5200 rows in essentials.geofence_boundaries — matching polygons for Path 0 geofence lookup"
  - "437 NATIONAL_LOWER rows in essentials.districts with tiger_geoid set — zero NULL rows remain"
  - "backend/scripts/load-national-house-districts.ts — reusable per-state CD119 import script"
  - "migration 342 — idempotent tiger_geoid backfill for all NATIONAL_LOWER districts"

affects:
  - "Path 0 in essentials.ts (tiger_geoid join) — now works for all 50 states not just CA/VA"
  - "GET /api/essentials/representatives/me — House rep lookup now geofence-capable nationally"

tech-stack:
  added: []
  patterns:
    - "Per-state TIGER shapefile loop: iterate FIPS codes, download tl_2024_{FIPS}_cd119.zip, extract, stream, insert"
    - "SKIP_CODES set: ZZ, ZZZ, 000 are non-voting placeholders; '00' is AT-LARGE (valid voting member)"
    - "resolveColumn() helper for TIGER vintage drift (GEOID/GEOID20/GEOID10 candidates)"

key-files:
  created:
    - backend/scripts/load-national-house-districts.ts
    - supabase/migrations/20260612000001_342_national_house_tiger_geoid_backfill.sql
  modified: []

key-decisions:
  - "TIGER CD119 per-state not national: Census does not publish tl_2024_us_cd119.zip; per-state files (tl_2024_{FIPS}_cd119.zip) are the correct approach"
  - "SKIP_CODES excludes '00': at-large states (AK, DE, MT, ND, SD, VT, WY) use CD119FP='00' for their single voting member — this must NOT be skipped"
  - "51 FIPS codes processed: 50 states + DC (FIPS 11); territories (60/66/69/72/78) excluded — non-voting delegates"

requirements-completed: [UHGE-01, UHGE-02, UHGE-03]

duration: 45min
completed: 2026-06-12
---

# Phase 116 Plan 01: National US House TIGER Import Summary

**436 US House TIGER 2024 CD119 polygons imported into geo_districts + geofence_boundaries; tiger_geoid backfilled on all 437 NATIONAL_LOWER districts; Path 0 join verified for TX-1 (Nathaniel Moran, Republican)**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-12T17:00Z
- **Completed:** 2026-06-12T17:45Z
- **Tasks:** 3 of 4 complete (Task 4 = checkpoint:human-verify)
- **Files modified:** 2

## Accomplishments

- Imported 436 US House congressional district polygons (50 states + DC) into `essentials.geo_districts` with `layer='us_house'`; `ON CONFLICT DO NOTHING` preserved all 52 existing CA rows
- Imported 436 matching polygon geometries into `essentials.geofence_boundaries` with `mtfcc='G5200'`; existing rows (from prior phases) were skipped cleanly
- Applied migration 342: backfilled `tiger_geoid = geo_id` on all 437 `NATIONAL_LOWER` districts; zero NULLs remain
- Path 0 join verified: TX-1 (`tiger_geoid='4801'`) returns exactly 1 `NATIONAL_LOWER` row; Nathaniel Moran (R) is linked via offices JOIN

## Task Commits

1. **Task 1: Write load-national-house-districts.ts** - `c514565f` (feat)
2. **Task 2 fix: Remove '00' from SKIP_CODES** - `99a5aeab` (fix — deviation Rule 1)
3. **Task 3: Migration 342 tiger_geoid backfill** - `afd00bd5` (feat)

## Files Created/Modified

- `backend/scripts/load-national-house-districts.ts` — Downloads all 51 per-state TIGER 2024 CD119 zip files, streams each shapefile, inserts geo_districts + geofence_boundaries with ON CONFLICT DO NOTHING
- `supabase/migrations/20260612000001_342_national_house_tiger_geoid_backfill.sql` — Idempotent UPDATE + DO $$ assertion block; applied to production Supabase

## Decisions Made

- **Per-state not national**: Census does not publish `tl_2024_us_cd119.zip`. Script iterates 51 FIPS codes (50 states + DC) and downloads each `tl_2024_{FIPS}_cd119.zip`.
- **'00' is AT-LARGE, not placeholder**: At-large states (AK, DE, ND, SD, VT, WY) use `CD119FP='00'` for their single voting member. The plan's SKIP_CODES including `'00'` was incorrect.
- **Territories excluded**: FIPS 60/66/69/72/78 (AS, GU, MP, PR, VI) have non-voting delegates and were not included in the 51-file loop.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TIGER 2024 national single-file URL does not exist**
- **Found during:** Task 1 (writing + running dry-run)
- **Issue:** Plan specified `tl_2024_us_cd119.zip` as the download URL, but Census does not publish a single national CD119 file. Directory listing shows per-state files only.
- **Fix:** Rewrote script to iterate all 51 FIPS codes (50 states + DC) and download per-state `tl_2024_{FIPS}_cd119.zip` files. This matches how `load-state-tiger-boundaries.ts` already works.
- **Files modified:** `backend/scripts/load-national-house-districts.ts`
- **Verification:** 436 districts processed across 51 state files; dry-run confirmed parsing correct
- **Committed in:** `c514565f` (Task 1 commit)

**2. [Rule 1 - Bug] SKIP_CODES incorrectly included '00' — at-large states skipped**
- **Found during:** Task 2 (live run assertion: 430 < 435 minimum)
- **Issue:** Plan's SKIP_CODES = `new Set(['ZZ', 'ZZZ', '00', '000'])` caused 6 at-large states (AK, DE, ND, SD, VT, WY) to be skipped. These states use `CD119FP='00'` for their single voting House member, not as a placeholder.
- **Fix:** Removed `'00'` from SKIP_CODES. Only `ZZ`, `ZZZ`, `000` remain as placeholder codes (for non-voting territory placeholder districts).
- **Files modified:** `backend/scripts/load-national-house-districts.ts`
- **Verification:** Second run processed 436 districts (>= 435 ✓); AK (`0200`), DE (`1000`), etc. now in geo_districts; AK at-large Path 0 join returns 1 row
- **Committed in:** `99a5aeab` (fix commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs in plan assumptions)
**Impact on plan:** Both bugs were in the plan's research assumptions about TIGER file structure. The fixes are correct and the outcome matches the plan's intended result (435+ districts loaded, Path 0 working).

## Verification Results (pre-checkpoint)

| Check | Result | Status |
|-------|--------|--------|
| `geo_districts WHERE layer='us_house'` | 436 rows | ✓ >= 435 |
| `geofence_boundaries WHERE mtfcc='G5200'` | 436 rows | ✓ >= 435 |
| CA rows preserved: geoid '0601', '0630', '0652' | 3 rows present | ✓ |
| TX rows present: geoid LIKE '48%' | 38 rows present | ✓ |
| DC row: geoid LIKE '11%' | 1 row (1198) | ✓ |
| `NATIONAL_LOWER AND tiger_geoid IS NULL` | 0 rows | ✓ |
| `NATIONAL_LOWER AND tiger_geoid IS NOT NULL` | 437 rows | ✓ >= 430 |
| Path 0 join: TX-1 `tiger_geoid='4801'` | 1 row, district_type=NATIONAL_LOWER | ✓ UHGE-03 |
| Politician linked to TX-1 | Nathaniel Moran (Republican) | ✓ |

## Issues Encountered

- TIGER per-state file discovery required: Directory listing at `https://www2.census.gov/geo/tiger/TIGER2024/CD/` confirmed 56 per-state zip files (51 states + 5 territories). Script iterates the 51 state/DC FIPS codes.
- At-large district encoding: CD119FP='00' encodes both at-large voting members AND was incorrectly assumed to be a placeholder code. The fix was to check the actual shapefile records for AK and verify that '00' is the only district (voting at-large member).

## User Setup Required

None — script runs with existing `DATABASE_URL`. No new environment variables needed.

## Human Verification (Task 4 — checkpoint:human-verify)

Supabase MCP confirmed post-checkpoint:
- `geo_districts WHERE layer='us_house'` = 436 ✓
- `geofence_boundaries WHERE mtfcc='G5200'` = 436 ✓
- `NATIONAL_LOWER AND tiger_geoid IS NULL` = 0 ✓
- Path 0 join for tiger_geoid='4801' returns 1 row (NATIONAL_LOWER, TX-1) ✓

All three UHGE requirements marked [x] in REQUIREMENTS.md.

## Self-Check: PASSED

- backend/scripts/load-national-house-districts.ts — committed c514565f / 99a5aeab
- supabase/migrations/20260612000001_342_national_house_tiger_geoid_backfill.sql — committed afd00bd5
- REQUIREMENTS.md UHGE-01/02/03 marked [x] ✓
- All counts verified via Supabase MCP ✓

---
*Phase: 116-national-us-house-tiger*
*Completed: 2026-06-12*
