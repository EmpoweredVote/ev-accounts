---
phase: 73-senator-records
plan: 02
subsystem: database
tags: [sql, migrations, essentials, politicians, offices, senators, bioguide, postgres, appointed]

# Dependency graph
requires:
  - phase: 73-senator-records
    plan: 01
    provides: Migration 175 applied — 42 senators (AK-MS), external_ids -400001 through -400042, 52 total
  - phase: 72-senate-infrastructure
    provides: 50 NATIONAL_UPPER districts (one per state) + chamber UUID 7cbe07bc-...
provides:
  - Migration 176 applied: 48 new US Senator politician rows (MT through WY)
  - 48 office rows linked to correct NATIONAL_UPPER district per state
  - Photo URLs from unitedstates.github.io CDN (or official senate.gov for 2 recently-appointed)
  - Jon Husted (OH) and Alan Armstrong (OK) correctly flagged: is_appointed=true + is_appointed_position=true
  - Photo backfill for 6 existing MA/ME/TX senators (no-ops — they already had Wikipedia URLs)
  - office_id back-filled on all 48 new politician rows
  - Phase 73 complete: 100 senators, all 50 states, 0 missing photos
affects: [74-stance-research, essentials-representatives-me, inform-politician-answers]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CTE-style idempotent senator INSERT: same pattern as migration 175"
    - "Fallback photo URL for recently-appointed senators not yet on unitedstates CDN: use official senate.gov portrait URL"
    - "Appointed senator flags: is_appointed=true on politician + is_appointed_position=true on office"
    - "Existing-senator photo no-op: IS NULL OR = '' guard skips rows with Wikipedia URLs"

key-files:
  created:
    - backend/migrations/176_us_senators_mt_wy.sql
  modified: []

key-decisions:
  - "Bill Hagerty bioguide corrected from H001099 (404) to H000601 — confirmed via unitedstates/congress-legislators YAML"
  - "Jon Husted (OH, appointed) photo falls back to https://www.husted.senate.gov/wp-content/uploads/2025/10/Husted_OfficialPortrait.webp — not yet on unitedstates CDN"
  - "Alan Armstrong (OK, appointed) photo falls back to https://www.armstrong.senate.gov/wp-content/uploads/2026/03/pic-scaled.jpg — not yet on unitedstates CDN"
  - "MA/ME/TX senator photo backfills are no-ops: all 6 already have Wikipedia URLs (non-null); IS NULL OR = '' guard skips them. Confirmed acceptable per plan spec."
  - "OK has 2 senators: James Lankford (-400063, elected) + Alan Armstrong (-400064, appointed replacement after Lankford became SBA Administrator)"

patterns-established:
  - "Recently-appointed senators (seated <1yr) may not appear in unitedstates.github.io CDN yet — fall back to official .senate.gov portrait URL"
  - "Bioguide pre-verification is mandatory before writing migration: 3 of 4 flagged IDs in this batch required correction or fallback"

# Metrics
duration: 9min
completed: 2026-05-19
---

# Phase 73 Plan 02: Senator Records (MT-WY) Summary

**48 new US senators (MT through WY) inserted with offices, photos, and appointed flags in migration 176 — Phase 73 complete with 100 senators across all 50 states, 2 senators each, 0 missing photos.**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-05-19T16:52:51Z
- **Completed:** 2026-05-19T17:02:23Z
- **Tasks:** 2 (Task 1: bioguide verification, Task 2: write + apply migration)
- **Files modified:** 1

## Accomplishments

- Verified all 4 flagged bioguide IDs before writing migration — caught 1 error (H001099 for Hagerty was wrong; actual ID is H000601) and found 2 fallback URLs for recently-appointed senators (Husted, Armstrong) not yet on the unitedstates CDN
- Created `backend/migrations/176_us_senators_mt_wy.sql`: 1,726-line idempotent migration covering 48 senators, 48 offices, 48 photo UPDATEs (including 2 fallback senate.gov URLs), 6 existing-senator no-op backfills, and office_id sweep
- Applied migration to remote Supabase, verified all 7 required checks, confirmed idempotency on second apply (all no-ops)
- Phase 73 complete: 100 senators, 50 states x 2 each, 0 missing photos, 2 appointed senators correctly flagged

## Task Commits

Each task was committed atomically:

1. **Task 1: Bioguide verification** - `c0a14bd` (chore)
2. **Task 2: Write and apply migration 176** - `6720c0a` (feat)

**Plan metadata:** (committed with SUMMARY + STATE update)

## Files Created/Modified

- `backend/migrations/176_us_senators_mt_wy.sql` — 1,726-line idempotent BEGIN/COMMIT migration; 48 senator CTEs, 48 photo UPDATEs, 6 existing-senator no-op backfills, office_id sweep

## Decisions Made

1. **Bill Hagerty bioguide corrected H001099 → H000601.** Research file listed H001099, which returns HTTP 404 on the unitedstates.github.io CDN. Correct ID confirmed via `legislators-current.yaml`. H000601 returns HTTP 200, 11.4KB JPEG.

2. **Jon Husted (OH, appointed) photo uses senate.gov fallback.** Bioguide H001104 confirmed as correct in the legislators YAML but no photo exists yet in the unitedstates CDN (recently appointed Jan 2025). Official portrait from `https://www.husted.senate.gov/wp-content/uploads/2025/10/Husted_OfficialPortrait.webp` verified HTTP 200, 177KB WebP.

3. **Alan Armstrong (OK, appointed) photo uses senate.gov fallback.** Bioguide A000383 confirmed correct in YAML but not yet on CDN. Official portrait from `https://www.armstrong.senate.gov/wp-content/uploads/2026/03/pic-scaled.jpg` verified HTTP 200, 431KB JPEG.

4. **MA/ME/TX photo backfills are no-ops (expected).** All 6 existing senators (Warren, Markey, Collins, King, Cornyn, Cruz) already have Wikipedia URLs. IS NULL OR = '' guard correctly skips them. Verification query still passes because all URLs are non-null. This matches the Padilla pattern from plan 73-01.

5. **OK has 2 senators in DB: Lankford (-400063) + Armstrong (-400064).** James Lankford resigned to become SBA Administrator; Alan Armstrong was appointed to fill his vacancy. Both are correctly represented as current incumbents. Armstrong has `is_appointed=true` and `is_appointed_position=true`.

## Verification Results

All queries run against remote Supabase after first apply:

| Check | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| Total NATIONAL_UPPER senators | 100 | 100 | YES |
| Wrong district_type for new batch | 0 | 0 | YES |
| Senators missing photo_origin_url | 0 | 0 | YES |
| States with exactly 2 senators | 50 rows all=2 | 50 rows all=2 | YES |
| Appointed senators (both flags true) | 2 (Husted OH, Armstrong OK) | 2 | YES |
| New senators this batch (external_id range) | 48 | 48 | YES |
| Ben Ray Luján accent intact | 'Ben Ray Luján' | 'Ben Ray Luján' | YES |
| MA/ME/TX senators have photo_origin_url | 6 non-null | 6 non-null | YES |

**Idempotency:** Second apply — all 48 INSERTs returned 0 rows, all UPDATEs returned 0 rows. Confirmed.

### Final 50-State Breakdown (both migrations combined)

All 50 states confirmed at exactly 2 senators each:
AK AL AR AZ CA CO CT DE FL GA HI IA ID IL IN KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX UT VA VT WA WI WV WY

### Migration Numbers

- Migration 175 (plan 73-01): 42 senators AK-MS
- Migration 176 (plan 73-02): 48 senators MT-WY
- **Next available migration number for Phase 74:** 177

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Bill Hagerty bioguide ID correction**
- **Found during:** Task 1 (bioguide verification)
- **Issue:** Research file listed H001099 for Bill Hagerty (TN), which returns HTTP 404 on the unitedstates.github.io CDN.
- **Fix:** Fetched `legislators-current.yaml` from unitedstates/congress-legislators repo. Confirmed bioguide = H000601. H000601 returns HTTP 200, 11.4KB JPEG. Migration uses H000601 with a comment noting the correction.
- **Files modified:** `backend/migrations/176_us_senators_mt_wy.sql` (used correct ID from the start)
- **Verification:** `curl -sIL https://unitedstates.github.io/images/congress/225x275/H000601.jpg` → HTTP:200 SIZE:11449

**2. [Rule 2 - Missing Critical] Fallback URLs for Husted and Armstrong (recently-appointed senators)**
- **Found during:** Task 1 (bioguide verification)
- **Issue:** Bioguides H001104 (Husted) and A000383 (Armstrong) are correct per the legislators YAML but have no photos on the unitedstates CDN (recently appointed in 2025 — CDN lags new senators). Without a fallback, these senators would have null photo_origin_url violating the "zero senators missing photos" success criterion.
- **Fix:** Found official senate.gov portrait URLs for both. Husted: `husted.senate.gov/wp-content/uploads/2025/10/Husted_OfficialPortrait.webp` (177KB WebP). Armstrong: `armstrong.senate.gov/wp-content/uploads/2026/03/pic-scaled.jpg` (431KB JPEG). Both verified HTTP 200.
- **Files modified:** `backend/migrations/176_us_senators_mt_wy.sql`
- **Verification:** Both photo_origin_url values confirmed non-null in post-migration query.

---

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical)
**Impact on plan:** Both auto-fixes essential for correct data. Without them, 3 senators would have broken/missing photo URLs. No scope creep.

## Issues Encountered

None — migration applied cleanly on first attempt.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 73 is complete:
- Migration 176 applied and idempotent
- 100 senators reachable via NATIONAL_UPPER (all 50 states, 2 each)
- All senator politician_ids exist for `inform.politician_answers` and `inform.politician_context` rows
- Next migration available: 177

Phase 74 (Stance Research + Ingestion) can begin immediately:
- All politician_ids for US senators now available
- Jon Husted (OH) and Alan Armstrong (OK) correctly flagged `is_appointed=true` so downstream consumers can distinguish elected vs appointed senators

---
*Phase: 73-senator-records*
*Completed: 2026-05-19*
