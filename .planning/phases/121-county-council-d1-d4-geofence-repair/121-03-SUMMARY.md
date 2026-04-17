---
phase: 121-county-council-d1-d4-geofence-repair
plan: 03
subsystem: database
tags: [postgis, geofence, monroe-county, county-council, sql, race-linking, gis]

# Dependency graph
requires:
  - phase: 121-02
    provides: 4 geofence_boundaries rows (geo_id 18105-mcc-d1..d4, mtfcc=X-MCC-DIST) + 4 districts rows (election-mcc-d1..d4)
provides:
  - Edited link-monroe-county-races-to-geofences.sql with §2a/§2e/§3f changes
  - 4 per-district MCC offices linked to election-mcc-d{N} districts
  - 4 MCC Council races linked to per-district offices (not county-wide geo_id=18105)
  - evidence/smoke-kirkwood-dev.txt — green [121-geo] PASS captured verbatim
affects: [121-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Unconditional NULL-out + re-link pattern for race migration (clears any prior linkage regardless of source district)"
    - "§3f two-step: UPDATE races SET office_id=NULL WHERE position_name LIKE ... then UPDATE SET office_id=new WHERE office_id IS NULL"

key-files:
  created:
    - .planning/phases/121-county-council-d1-d4-geofence-repair/evidence/smoke-kirkwood-dev.txt
  modified:
    - ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql

key-decisions:
  - "§3f NULL-out widened to unconditional clear (by election + position_name) rather than filtering by geo_id='18105' — pre-existing linkage used geo_ids 1810500001-4 (not 18105), so the narrow WHERE clause missed all 4 races on the first run"
  - "Pre-existing council offices at 1810500001-4 (mtfcc=X0001, source=monroe_county_arcgis_council_districts_2022) left as orphans — races re-linked to new election-mcc-d{N} offices but old offices not deleted (FK handling out of scope)"
  - "Smoke test run from main ev-accounts repo (node_modules present) rather than worktree scripts dir — worktree lacks node_modules installation"

requirements-completed: [GEO-01, GEO-02]

# Metrics
duration: 30min
completed: 2026-04-17
---

# Phase 121 Plan 03: Wave 2 Re-link + Smoke Verification Summary

**link-monroe-county-races-to-geofences.sql re-wires 4 MCC Council races through per-district election-mcc-d{N} offices to Phase 121 polygons; [121-geo] PASS confirmed with District 4 for Kirkwood**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-04-17T00:14:00Z
- **Completed:** 2026-04-17T00:44:00Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- Edited `link-monroe-county-races-to-geofences.sql` with 3 targeted changes: §2a removes 4 MCC District entries from the county-wide VALUES list, §2e adds 4 per-district offices linked to `election-mcc-d{N}` districts, §3f unconditionally re-links the 4 MCC Council races to those offices
- Ran script against DB: INSERT 0 4 (§2e created 4 new offices), UPDATE 4 (§3f NULL-out), UPDATE 4 (§3f re-link) — all 46 races linked, 0 unlinked
- Verified idempotency on second run: all INSERTs 0, UPDATE 4+4 (correct — §3f is a deterministic re-link, not accumulative)
- Captured green smoke in `evidence/smoke-kirkwood-dev.txt`: `[121-geo] PASS: Kirkwood returns exactly 1 MCC Council race: Monroe County Council District 4`, `exit_code=0`

## DB State After Re-link

| Query | Result |
|-------|--------|
| Offices in election-mcc-d% districts | 4 |
| Races linked to election-mcc-d% districts | 4 |
| Races linked to shared county geo_id=18105 | 0 |
| Total races linked | 46/46 |
| Unlinked races | 0 |

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Edit link SQL — remove §2a MCC entries, add §2e + §3f, run against DB | `6e33415` | link-monroe-county-races-to-geofences.sql |
| 2 | Run extended smoke test against DB and capture green output | `68b0fde` | evidence/smoke-kirkwood-dev.txt |

## Files Created/Modified

- `ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql` — 3 edits: §2a shrunk to 6 county-wide offices (no MCC districts), new §2e creates 4 per-district offices, new §3f re-links 4 MCC races unconditionally
- `.planning/phases/121-county-council-d1-d4-geofence-repair/evidence/smoke-kirkwood-dev.txt` — Full stderr+stdout of audit-112-geofence.ts run, captures PASS line and exit_code=0

## Decisions Made

- **§3f NULL-out widened:** Initial WHERE clause `d_old.geo_id = '18105' AND d_old.district_type = 'COUNTY'` failed because the pre-existing linkage used `geo_id IN (1810500001, 1810500002, 1810500003, 1810500004)` — a different set of per-district rows that already existed before Phase 121. Changed to unconditional clear keyed on `position_name LIKE 'Monroe County Council District%'` and `election_date = '2026-05-05'`.
- **Old offices left as orphans:** The pre-existing offices at geo_ids `1810500001-4` (mtfcc=X0001) are no longer referenced by any race but remain in the `essentials.offices` table. Deleting them would require FK cascade analysis across unrelated queries — deferred to future cleanup.
- **Smoke run via main ev-accounts repo:** The worktree's `ev-accounts/backend/` has no `node_modules` installation (it's a planning-repo copy of scripts only). Ran `npx tsx scripts/audit-112-geofence.ts` from `/Users/chrisandrews/Documents/GitHub/ev-accounts/backend` which has `dotenv` and `pg` available.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] §3f NULL-out WHERE clause didn't match pre-existing district linkage**
- **Found during:** Task 1 (first script run — UPDATE returned 0 rows for the NULL-out step)
- **Issue:** Plan specified `d_old.geo_id = '18105' AND d_old.district_type = 'COUNTY'` in the §3f NULL-out. The actual pre-existing MCC Council offices linked to geo_ids `1810500001`-`1810500004` (not `18105`) — these are separate per-district rows from `monroe_county_arcgis_council_districts_2022` source, predating Phase 121.
- **Fix:** Changed NULL-out to unconditional: `FROM essentials.elections e WHERE r.election_id = e.id AND e.election_date = '2026-05-05' AND e.state = 'IN' AND r.position_name LIKE 'Monroe County Council District%'` — clears any prior linkage regardless of which district the old office belonged to.
- **Files modified:** `ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql` (§3f NULL-out UPDATE)
- **Verification:** Second run: UPDATE 4 (NULL-out) + UPDATE 4 (re-link), all 4 races confirmed at `election-mcc-d{N}`
- **Committed in:** `6e33415` (Task 1 commit, revised before finalizing)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug in WHERE clause assumption)
**Impact on plan:** Fix required for re-link to work. No scope creep — the §3f logic change is contained within the script.

## Known Orphans

The 4 old per-district offices at geo_ids `1810500001`-`1810500004` (integer district primary keys `1`, `2`, `3`, `4`) are no longer referenced by any race in the 2026-05-05 election. They are harmless orphans. A future cleanup plan may want to:
```sql
-- Identify orphaned offices (verify no other races reference them first)
SELECT o.id, o.title, d.geo_id
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.geo_id IN ('1810500001','1810500002','1810500003','1810500004')
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.office_id = o.id);
```

## Issues Encountered

None beyond the auto-fixed §3f WHERE clause bug documented above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Wave 2 complete: 4 MCC Council races linked to per-district `election-mcc-d{N}` offices on production DB
- Smoke test `[121-geo] PASS` captured in evidence file
- Plan 04 can proceed: doc correction (GAP-REPORT.md PATTERN-004) + production verification

---
*Phase: 121-county-council-d1-d4-geofence-repair*
*Completed: 2026-04-17*
