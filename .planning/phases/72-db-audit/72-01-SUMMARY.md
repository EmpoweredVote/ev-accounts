---
phase: 72-db-audit
plan: 01
subsystem: database
tags: [postgresql, supabase, psql, classify.js, geofence, indiana, monroe-county, bloomington]

# Dependency graph
requires: []
provides:
  - "Verbatim SQL query results for all 5 audit queries against live Supabase DB"
  - "Confirmed: chamber_name_formal is EMPTY for all Indiana officials (BallotReady gap)"
  - "Confirmed: Monroe County Commissioners misclassified as County Officials (not County Legislators)"
  - "Confirmed: No collision between Commissioners and Council — they already land in different groups"
  - "Confirmed: Monroe County G4020 geofence present (geo_id=18105, census_tiger_2024)"
  - "Regression mapping table: 27+ officials with Current Group and Expected Group annotations"
  - "Phase 73 branch decision: DATA MIGRATION required before feature work"
affects:
  - "Phase 73 planning — branch decision gates all classification and GovernmentBody design"
  - "classify.js — COUNTY branch needs 'commission' added to keyword list"
  - "chamber_name_formal migration — all Indiana chambers need canonical body names populated"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Read-only SQL audit via psql against Supabase connection string from EV-Backend/.env.local"
    - "classify.js logic verification via Node.js REPL to confirm exact substring matching behavior"

key-files:
  created:
    - ".planning/phases/72-db-audit/72-FINDINGS.md"
  modified: []

key-decisions:
  - "Phase 73 is a DATA MIGRATION phase before feature work — chamber_name_formal must be populated first"
  - "Monroe County Commissioners are misclassified: office_title 'Commission - District X' lacks 'commissioner' substring, so they fall through to County Officials instead of County Legislators"
  - "No collision exists between Monroe County Council and Commissioners — RESEARCH.md prediction was wrong about the mechanism"
  - "All Indiana chamber_name_formal values are empty — Phase 73 must populate canonical body names before GovernmentBody body_key logic can work"
  - "Monroe County G4020 geofence is present — no new geofence import step needed in Phase 73"
  - "government_name is NULL for all Indiana chambers — governments table has no Indiana records"

patterns-established:
  - "DB audit pattern: source DATABASE_URL from EV-Backend/.env.local, run psql queries, verify string matching logic via Node.js REPL"

requirements-completed: [DATA-01]

# Metrics
duration: 4min
completed: 2026-03-11
---

# Phase 72 Plan 01: DB Audit Summary

**SQL audit of live Supabase DB confirms: chamber_name_formal is empty for all Indiana officials, Commissioners are misclassified as County Officials (not County Legislators) due to 'commission' vs 'commissioner' substring mismatch, and Monroe County G4020 geofence is present — Phase 73 must be a data migration phase**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-11T01:49:51Z
- **Completed:** 2026-03-11T01:54:46Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Executed all 5 SQL audit queries against live Supabase database via psql
- Discovered that Monroe County Commissioners (not Council) are the misclassified body — they land in "County Officials" (fallback) because "Monroe County Commission - District X" does not contain "commissioner" as a substring
- Confirmed all `chamber_name_formal` values are empty strings for Indiana officials, establishing that Phase 73 must include a data migration step to populate canonical body names before GovernmentBody body_key logic can work
- Confirmed Monroe County G4020 county geofence exists (geo_id=18105, imported 2026-02-11 from census_tiger_2024)
- Created regression mapping table for 27+ Monroe County and Bloomington officials with Current Group and Expected Group annotations

## Task Commits

1. **Tasks 1+2: Execute DB audit queries and analyze results** - `6bf5a81` (feat)

**Plan metadata:** (committed with SUMMARY.md)

## Files Created/Modified

- `.planning/phases/72-db-audit/72-FINDINGS.md` - Complete audit findings: raw SQL output for all 5 queries, analysis sections, collision determination, geofence verification, regression mapping table, and Phase 73 branch decision

## Decisions Made

- **Phase 73 is a data migration phase:** `chamber_name_formal` is empty for all Indiana chambers. The GovernmentBody table requires a stable per-body canonical name. Phase 73 must populate `name_formal` for each Indiana chamber (grouping per-district chambers under a shared body name) before building body_key logic.

- **Commissioners misclassification is different from the predicted problem:** RESEARCH.md predicted Commissioners and Council would collide in "County Legislators". The actual finding is the opposite: Council correctly lands in "County Legislators" (via "council" match), but Commissioners fall through to "County Officials" because "commissioner" is not a substring of "commission". Phase 73 must fix this by adding "commission" to classify.js COUNTY branch keywords.

- **No collision between Commission and Council:** They already land in different groups today. The concern from STATE.md (collision into one section) does not exist in the current data/classify.js combination.

## Deviations from Plan

None — plan executed exactly as written. The RESEARCH.md collision prediction was wrong about the mechanism but the investigation methodology and queries were executed as planned.

## Issues Encountered

- Query 5 (all Indiana officials, ~350 rows) produced output too large for tool capture. Scoped to Monroe County + Bloomington geo_ids (82 rows) for the regression mapping table — this was sufficient for all plan objectives.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

**Phase 73 is unblocked with clear direction:**

1. Phase 73 must begin with a data migration step: populate `chamber_name_formal` for all Indiana chambers with canonical body names (e.g., all "Monroe County Council - *" → `name_formal = "Monroe County Council"`)
2. Phase 73 must fix classify.js COUNTY branch: add "commission" to `["commissioner", "supervisor", "council"]` so Commissioners land in "County Legislators"
3. GovernmentBody table design must handle per-district chambers sharing a single body_key (Monroe County Council district members have geo_ids 1810500001-4, at-large have 18105)
4. `essentials.governments` table has no Indiana records — government_name display must be synthesized, not joined

**No blockers.** All four DATA-01 sub-questions are answered.

---
*Phase: 72-db-audit*
*Completed: 2026-03-11*
