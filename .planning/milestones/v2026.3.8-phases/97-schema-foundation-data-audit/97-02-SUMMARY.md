---
phase: 97-schema-foundation-data-audit
plan: 02
subsystem: database
tags: [postgresql, supabase, data-audit, is_appointed, essentials, phase-100]

# Dependency graph
requires:
  - phase: 97-schema-foundation-data-audit
    provides: Research on is_appointed data model, audit query patterns, D-09 report-then-fix principle
provides:
  - Runnable audit script for is_appointed data quality (ev-accounts/backend/scripts/audit-is-appointed.ts)
  - IS_APPOINTED_AUDIT.md with full findings: 78,879 active politicians, 77,099 NULL offices (97.6%), 1 direct mismatch
  - Backfill plan with P1/P2/P3 priorities before Phase 100 filter UI ships
  - Discovery that 77,626 NULL-office records are BallotReady campaign finance records (not real officials)
  - Phase 100 filter implementation notes (politician-first is_appointed lookup logic)
affects: [97-03, 100, filter-ui, essentials-service]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "READ-ONLY audit scripts per D-09: report-then-fix, no automatic data corrections"
    - "pg.Pool for standalone audit scripts (not supabase client) — direct DB connection"

key-files:
  created:
    - ev-accounts/backend/scripts/audit-is-appointed.ts
    - .planning/phases/97-schema-foundation-data-audit/IS_APPOINTED_AUDIT.md
  modified: []

key-decisions:
  - "Phase 100 filter must use politician.is_appointed first (individual override), then fall back to offices.is_appointed_position — handles Courtney Daily interim-appointment-to-elected-seat edge case"
  - "78,879 'active politicians' includes ~77,626 BallotReady campaign finance records (PACs, committees) with is_active=true but no office/geofence linkage — geofence-based search naturally excludes them"
  - "Phase 100 filter is NOT blocked: geofence join excludes campaign finance records, and 1,277 well-classified Bloomington officials are the primary demo use case"
  - "NULL is_appointed_position (97.6% of offices) defaults to elected via COALESCE(is_appointed_position, false) — safe default for most titles, but Judge offices need manual classification before Phase 100"

patterns-established:
  - "Politician-first appointment check: effectiveIsAppointed = politician.is_appointed ?? office.is_appointed_position ?? false"

requirements-completed: [DATA-05]

# Metrics
duration: ~45min
completed: 2026-03-29
---

# Phase 97 Plan 02: is_appointed Data Quality Audit Summary

**Two-tier READ-ONLY audit revealing 77,099 NULL-classified offices (97.6%) — mostly BallotReady campaign finance records — with 1 direct mismatch (Courtney Daily interim appointment) and a prioritized backfill plan for Phase 100 filter readiness**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-03-29T19:43:00Z
- **Completed:** 2026-03-29T20:30:00Z
- **Tasks:** 2 (Task 1: audit script creation + run; Task 2: findings documentation + user review)
- **Files modified:** 2

## Accomplishments

- Created and ran a two-tier READ-ONLY audit script against production DB (78,879 active politicians scanned)
- Discovered the "97.6% NULL offices" figure is misleading: ~77,626 records are BallotReady campaign finance records (PACs/committees), not real officials — real officials with unclassified offices number ~3,304
- Documented 1 direct politician/office mismatch (Courtney Daily, interim appointment to elected Bloomington City Council seat) and designed filter logic to handle it
- Confirmed Phase 100 filter is not blocked: geofence-based search naturally excludes campaign finance records, and Bloomington demo data is well-classified

## Task Commits

Each task was committed atomically:

1. **Task 1: Create and run is_appointed audit script** - `f6147fc` (feat — ev-accounts worktree)
2. **Task 2: Review audit results and document findings** - `e757c4b` (feat — audit report)

**Plan metadata:** _(this summary commit — docs: complete 97-02 plan)_

## Files Created/Modified

- `ev-accounts/backend/scripts/audit-is-appointed.ts` - Standalone TypeScript audit script with two-tier queries (Tier 1: offices with NULL/suspect classification; Tier 2: politician/office mismatch detection), formatted table output, read-only per D-09
- `.planning/phases/97-schema-foundation-data-audit/IS_APPOINTED_AUDIT.md` - Full audit findings report with summary counts, office-level and politician-level findings, recommended fixes, backfill plan (P1/P2/P3), and Phase 100 filter implementation notes

## Decisions Made

**1. Politician-first appointment lookup in Phase 100 filter**
The Courtney Daily case (interim appointment to elected seat) requires checking `politicians.is_appointed` before `offices.is_appointed_position`. Established filter logic:
```typescript
const effectiveIsAppointed =
  politician.is_appointed !== null
    ? politician.is_appointed
    : office.is_appointed_position !== null
    ? office.is_appointed_position
    : false;
```

**2. Campaign finance records are a data hygiene issue, not a Phase 100 blocker**
~77,626 BallotReady records with `data_source IS NULL` and committee names (e.g., "COMMITTEE TO ELECT...") have `is_active = true` but no office/chamber/geofence linkage. They never appear in address-based searches. Phase 100 filter should add `WHERE ch.id IS NOT NULL` as an explicit guard, but this is defensive — geofence join already excludes them.

**3. Judge offices are Priority 1 before Phase 100 wide rollout**
141 Judge offices and 29 Superior Court Judge offices have NULL `is_appointed_position`. IN appellate judges are appointed (with retention votes); IN circuit judges are elected. CA superior court judges are elected. These need classification before the filter ships to ensure judges appear under the correct filter tab.

## Deviations from Plan

None — plan executed as written. The audit was read-only per D-09. The checkpoint was human-verified and approved.

## Issues Encountered

None — the audit script ran successfully against production. The unexpected finding about campaign finance records (volume inflation) was surfaced and documented rather than masked.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

**Phase 97 Plan 03** (faces_retention_vote schema column) can proceed immediately — the audit confirmed the business need (IN appellate judges face retention votes and need this flag for correct filter UI display).

**Phase 100** (Elected/Appointed Filter UI) has clear prerequisites:
- P1-A: Implement politician-first filter logic (code change, ~2-4 hours)
- P1-B/C: Classify Judge and Superior Court Judge offices (data fix, ~4-8 hours)
- P2-A: Bulk set safe elected-position titles to `is_appointed_position = false` (~1-2 hours)

The Bloomington demo use case is fully covered: 1,277 well-classified officials include all city council members and the 9 manually-entered appointed city officials needed for the filter demonstration.

**Blocker resolved:** The STATE.md concern "is_appointed data quality for post-v1.5 officials unknown until audit query runs; if predominantly defaulted false, Phase 100 is blocked until manual backfill completes" — this blocker can now be removed. Phase 100 is not blocked; backfill tasks are scoped and can be parallelized with filter UI development.

## Self-Check: PASSED

- FOUND: `.planning/phases/97-schema-foundation-data-audit/97-02-SUMMARY.md`
- FOUND: `.planning/phases/97-schema-foundation-data-audit/IS_APPOINTED_AUDIT.md`
- FOUND: `ev-accounts/backend/scripts/audit-is-appointed.ts`
- FOUND: commit `e757c4b` (audit findings report)

---
*Phase: 97-schema-foundation-data-audit*
*Completed: 2026-03-29*
