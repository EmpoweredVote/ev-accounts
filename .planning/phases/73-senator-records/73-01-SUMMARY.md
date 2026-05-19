---
phase: 73-senator-records
plan: 01
subsystem: database
tags: [sql, migrations, essentials, politicians, offices, senators, bioguide, postgres]

# Dependency graph
requires:
  - phase: 72-senate-infrastructure
    provides: 50 NATIONAL_UPPER districts (one per state) + government FK column live in migration 174
provides:
  - Migration 175 applied: 42 new US Senator politician rows (AK through MS)
  - 42 office rows linked to correct NATIONAL_UPPER district per state
  - Photo URLs from unitedstates.github.io CDN for all 42 new senators
  - Photo backfill for existing CA/IN senators (Adam B. Schiff, Todd Young, Jim Banks)
  - office_id back-filled on all 42 new politician rows
affects: [73-02-plan, 74-stance-research, essentials-representatives-me]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CTE-style idempotent senator INSERT: WITH ins_p AS (INSERT ... ON CONFLICT (external_id) DO NOTHING RETURNING id) + NOT EXISTS office guard"
    - "Bioguide photo URL: https://unitedstates.github.io/images/congress/225x275/{BIOGUIDE}.jpg"
    - "Existing-senator photo backfill: name+state JOIN pattern (no external_id needed)"

key-files:
  created:
    - backend/migrations/175_us_senators_ak_mo.sql
  modified: []

key-decisions:
  - "Cindy Hyde-Smith bioguide corrected from H001102 (404) to H001079 — confirmed via unitedstates/congress-legislators YAML"
  - "Adam B. Schiff DB full_name is 'Adam B. Schiff' (includes middle initial B.) — backfill SQL uses this exact string"
  - "Alex Padilla already had non-null photo_origin_url (city of Inglewood URL) — IS NULL OR = '' guard made the UPDATE a no-op, which is acceptable per plan spec"
  - "External_id range -400001 to -400042 assigned to this batch; plan 73-02 continues from -400043"

patterns-established:
  - "Bioguide pre-verification: curl HEAD check before writing migration, using unitedstates/congress-legislators YAML as authoritative fallback for IDs that return 404"
  - "DB full_name check before writing name-based backfill SQL: always query the live DB to confirm exact full_name before writing WHERE p.full_name = '...' conditions"

# Metrics
duration: 7min
completed: 2026-05-19
---

# Phase 73 Plan 01: Senator Records (AK-MS) Summary

**42 new US senators (AK through MS) inserted with offices, GitHub CDN photos, and office_id backfill in a single idempotent migration — bioguide correction found and applied for Cindy Hyde-Smith.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-05-19T16:40:42Z
- **Completed:** 2026-05-19T16:48:37Z
- **Tasks:** 3 (Task 1: bioguide verification, Task 2: write migration, Task 3: apply + verify)
- **Files modified:** 1

## Accomplishments

- Verified all 4 flagged bioguide IDs before writing migration — caught and corrected one error (H001102 for Hyde-Smith was wrong; actual ID is H001079)
- Created `backend/migrations/175_us_senators_ak_mo.sql`: 1,464-line idempotent migration covering 42 senators, 42 offices, 42 photo UPDATEs, 4 existing-senator backfills, and office_id sweep
- Applied migration to remote Supabase and verified all 6 required counts; confirmed idempotency on second apply (all no-ops)

## Task Commits

Each task was committed atomically:

1. **Task 1: Bioguide verification** - `28cf30c` (chore)
2. **Tasks 2+3: Write and apply migration 175** - `9259160` (feat)

**Plan metadata:** (committed with SUMMARY + STATE update)

## Files Created/Modified

- `backend/migrations/175_us_senators_ak_mo.sql` — 1,464-line idempotent BEGIN/COMMIT migration; 42 senator CTEs, 42 photo UPDATEs, 4 existing-senator backfills, office_id sweep

## Decisions Made

1. **Cindy Hyde-Smith bioguide corrected H001102 → H001079.** Research file listed H001102, which returns HTTP 404 on the unitedstates.github.io CDN. Correct ID confirmed via `legislators-current.yaml` from unitedstates/congress-legislators repo. H001079 returns HTTP 200, 8.8KB JPEG.

2. **Adam B. Schiff full_name includes middle initial.** DB query confirmed the existing row has `full_name = 'Adam B. Schiff'`. The Section C backfill WHERE clause uses this exact string. If the name were 'Adam Schiff', the UPDATE would silently match 0 rows.

3. **Alex Padilla photo backfill is a no-op (expected).** Padilla's row has `photo_origin_url = 'https://www.cityofinglewood.org/ImageRepository/Document?documentID=18881'` which is non-null and non-empty. The IS NULL OR = '' guard correctly skips this row. Verification query 4 still passes because the URL is non-null.

4. **External_id sequence -400001 to -400042 for this batch.** Plan 73-02 should start at -400043 (or any value ≤ -400043 that doesn't conflict with the -400001 to -400042 range used here).

## Verification Results

All queries run against remote Supabase after first apply:

| Check | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| New senators (external_id BETWEEN -400042 AND -400001) | 42 | 42 | YES |
| New offices for this batch | 42 | 42 | YES |
| New senators with no photo | 0 | 0 | YES |
| CA/IN existing senators with non-null photo | 4 | 4 | YES |
| New senators with office_id IS NULL | 0 | 0 | YES |
| Total NATIONAL_UPPER senators | 52 | 52 | YES |

**Idempotency:** Second apply — all 42 INSERTs returned 0 rows, all UPDATEs returned 0 rows. Confirmed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Cindy Hyde-Smith bioguide ID correction**
- **Found during:** Task 1 (bioguide verification)
- **Issue:** Research file listed H001102 for Cindy Hyde-Smith (MS), which returns HTTP 404 on the unitedstates.github.io CDN. Photo would have been silently set to a broken URL.
- **Fix:** Fetched `legislators-current.yaml` from unitedstates/congress-legislators repo. Confirmed bioguide = H001079. H001079 returns HTTP 200 + 8.8KB JPEG. Migration uses H001079 with a comment noting the correction.
- **Files modified:** `backend/migrations/175_us_senators_ak_mo.sql` (used correct ID from the start)
- **Verification:** `curl -s -w "HTTP:%{http_code} SIZE:%{size_download}" https://unitedstates.github.io/images/congress/225x275/H001079.jpg` → HTTP:200 SIZE:8788

**2. [Rule 2 - Missing Critical] DB full_name check before writing backfill SQL**
- **Found during:** Pre-Task 2 (DB query to confirm existing senator names)
- **Issue:** Plan specified `full_name = 'Adam Schiff'` but the actual DB row has `full_name = 'Adam B. Schiff'`. Without this check, the backfill UPDATE would have matched 0 rows silently.
- **Fix:** Queried the live DB before writing the migration: `SELECT p.full_name, p.photo_origin_url FROM essentials.politicians p JOIN essentials.offices o ... WHERE d.district_type = 'NATIONAL_UPPER'`. Used the confirmed name 'Adam B. Schiff' in the migration.
- **Files modified:** `backend/migrations/175_us_senators_ak_mo.sql`
- **Verification:** UPDATE returned 1 row on first apply (confirmed the name matched).

## Next Phase Readiness

Plan 73-02 can start immediately:
- Migration 176 available (no conflicts)
- External_id range for 73-02: suggest -400043 through -400090 (or any new range; the -400001 to -400042 range is now taken)
- States remaining: MT, NC, ND, NE, NH, NJ, NM, NV, NY, OH, OK, OR, PA, RI, SC, SD, TN, TX, UT, VA, VT, WA, WI, WV, WY (25 states = 50 senators)
- Additionally: 6 existing-senator photo backfills needed (MA Warren, MA Markey, ME Collins, ME King, TX Cornyn, TX Cruz — all have Wikipedia URLs, not GitHub CDN URLs)
- SENA-01, SENA-02, SENA-03 will be closed when 73-02 completes
