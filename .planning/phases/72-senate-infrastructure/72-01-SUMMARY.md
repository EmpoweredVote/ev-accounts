---
phase: 72-senate-infrastructure
plan: 01
subsystem: database
tags: [postgres, supabase, essentials, districts, governments, senate, migration]

# Dependency graph
requires:
  - phase: 71-school-districts-profile-display
    provides: migration 173 as the base (173_me_state_house_officials.sql was the last applied migration)
provides:
  - essentials.districts.government_id column (UUID FK to essentials.governments)
  - 50 NATIONAL_UPPER district rows (one per US state) in essentials.districts
  - 50 state-level government stubs in essentials.governments
  - CA junk NATIONAL_UPPER row deleted (e8ffae97)
  - IN duplicate NATIONAL_UPPER row deleted (ed02bc1b), Todd Young reassigned to canonical
affects:
  - phase: 73-senator-records (needs NATIONAL_UPPER districts for office FK)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Idempotent government stub inserts: SELECT...WHERE NOT EXISTS pattern prevents duplicate rows on re-run"
    - "Idempotent district inserts: NOT EXISTS guard on (district_type, state) pair"
    - "government_id backfill: UPDATE with correlated subquery + ORDER BY id LIMIT 1 handles IN's 22 duplicate government rows deterministically"

key-files:
  created:
    - backend/migrations/174_senate_infrastructure.sql
  modified: []

key-decisions:
  - "Migration number 174 (not 172 as originally written in plan — 172 and 173 were consumed by quick tasks 52-01 and 52-02 after the plan was authored)"
  - "MA skipped in Step 6 district inserts (fd703947-... already existed); MA government stub still inserted in Step 5"
  - "government_id backfill uses ORDER BY g.id LIMIT 1 to handle IN's 22 duplicate government rows deterministically"
  - "Applied via psql directly to remote Supabase using session pooler DATABASE_URL (MCP tools not available in this session)"

patterns-established:
  - "government_id FK: NATIONAL_UPPER districts now have a typed FK to essentials.governments, enabling JOIN-based senator queries by state in Phase 73"

# Metrics
duration: 4min
completed: 2026-05-19
---

# Phase 72 Plan 01: Senate Infrastructure Summary

**Migration 174 applied — 50 NATIONAL_UPPER districts with government_id FKs, 46 new government stubs, CA/IN data quality fixes, fully idempotent**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-19T14:11:52Z
- **Completed:** 2026-05-19T14:16:27Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Migration 174 applied cleanly with no errors — 50 NATIONAL_UPPER district rows now exist (one per state)
- All 50 rows have a non-null government_id FK to essentials.governments (verified Query B = 0)
- 46 state government stubs created (MA + 45 missing states); existing CA/IN/ME/TX rows retained
- CA junk NATIONAL_UPPER row (e8ffae97, geo_id='') deleted; IN orphan row (ed02bc1b) deleted after Todd Young's office was reassigned to canonical IN district
- Second migration apply confirmed fully idempotent (all INSERT 0 0, UPDATE 0, COMMIT with only a NOTICE on ADD COLUMN IF NOT EXISTS)

## Task Commits

1. **Task 1: Write migration 174** - `f595c77` (feat)
2. **Task 2: Apply migration + verify** - no separate commit (DB operation, verified below)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `backend/migrations/174_senate_infrastructure.sql` — 7-step idempotent migration: DDL column add, CA/IN cleanup, 46 government stubs, 45 NATIONAL_UPPER districts, government_id backfill

## Pre/Post State

| Metric | Pre | Post |
|--------|-----|------|
| NATIONAL_UPPER districts | 7 | 50 |
| States with government row | 4 (CA, IN, ME, TX) | 50 (all) |
| essentials.districts.government_id column | missing | present, FK to governments |
| CA junk row (e8ffae97) | exists | deleted |
| IN orphan row (ed02bc1b) | exists | deleted |
| Todd Young district_id | ed02bc1b (orphan) | 343b3268 (canonical) |

## Verification Query Results

**Query A** — NATIONAL_UPPER count:
```
 national_upper_count
----------------------
                   50
```
PASS (expected 50)

**Query B** — rows with null/bad government_id:
```
 rows_with_bad_government_id
-----------------------------
                           0
```
PASS (expected 0)

**Query C** — states with government row:
```
 states_with_government
------------------------
                     50
```
PASS (expected 50)

**Query D — sanity checks:**
```
ca_junk_remaining = 0          PASS (expected 0)
in_orphan_remaining = 0        PASS (expected 0)
Todd Young district_id = 343b3268-d048-4e6d-97de-963590dfddf8   PASS (expected canonical)
in_national_upper = 1          PASS (expected 1)
```

**Idempotency:** Second apply succeeded with all INSERT 0 0, UPDATE 0, COMMIT. PASS.

## UUIDs of Cleanup Operations

| Operation | UUID | Action |
|-----------|------|--------|
| CA junk NATIONAL_UPPER row | e8ffae97-d5df-4061-b85b-a0aa3c790f4e | Deleted |
| IN orphan NATIONAL_UPPER row | ed02bc1b-d184-4233-954a-12206250ece5 | Deleted |
| Todd Young's office | fa8e5ddc-cf1a-4aed-86c9-f7281e25e3c5 | Reassigned district_id |
| Canonical IN NATIONAL_UPPER row | 343b3268-d048-4e6d-97de-963590dfddf8 | Retained, now has 2 offices |
| MA existing NATIONAL_UPPER row | fd703947-... | Retained (skipped in Step 6) |

## Decisions Made

- **Migration number 174**: Plan was originally written with 172, but quick tasks 52-01 and 52-02 consumed 172 and 173 after the plan was authored. Corrected to 174 per user instruction.
- **psql direct apply**: MCP Supabase tools were not available in this session. Applied via psql to the session pooler URL `aws-0-us-west-1.pooler.supabase.com:5432` — consistent with the v2.2 migration apply pattern established in Phase 69.
- **ORDER BY g.id LIMIT 1 in backfill**: IN has 22 duplicate "State of Indiana" rows in essentials.governments. The backfill uses `ORDER BY g.id LIMIT 1` to deterministically pick one government row for each state without error.

## Deviations from Plan

None — plan executed exactly as written (with the pre-noted migration number correction from 172 to 174).

## Issues Encountered

None. Migration applied cleanly on first attempt. All 7 steps executed as expected:
- Step 1: ADD COLUMN IF NOT EXISTS — success
- Step 2: DELETE CA junk — 1 row deleted
- Step 3: UPDATE Todd Young office — 1 row updated
- Step 4: DELETE IN orphan — 1 row deleted
- Steps 5/6: 46 government inserts + 45 district inserts (91 total INSERT 0 1)
- Step 7: UPDATE 50 (all NATIONAL_UPPER rows backfilled with government_id)

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Phase 73 (Senator Records) can proceed. All prerequisites are met:
- SINF-01 complete: 50 NATIONAL_UPPER districts exist, one per state
- SINF-02 complete: All 50 states have at least one row in essentials.governments
- All 50 NATIONAL_UPPER rows have government_id FKs
- 10 existing senators (CA: Padilla + Schiff, IN: Young + Banks, MA: Warren + Markey, ME: Collins + King, TX: Cornyn + Cruz) already have office records pointing to correct NATIONAL_UPPER districts
- 90 new senator records needed in Phase 73

---
*Phase: 72-senate-infrastructure*
*Completed: 2026-05-19*
