---
phase: 05-essentials-improvements
plan: 01
subsystem: ui, api
tags: [react, go, classify, essentials, politicians, term-dates]

# Dependency graph
requires: []
provides:
  - FEDERAL_ORDER constant with legislative-first ordering (Senate > House > President/VP > Cabinet)
  - OfficialOut API response includes term_start and term_end fields from politicians.valid_from/valid_to
affects:
  - essentials frontend (Dashboard/Results federal section display order)
  - any consumer of /essentials/politicians/* endpoints (term dates now available)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "All new OfficialOut fields use omitempty — backward-compatible API extension"
    - "term dates sourced from p.valid_from/p.valid_to columns already present in DB"

key-files:
  created: []
  modified:
    - essentials/src/lib/classify.js
    - EV-Backend/internal/essentials/handlers.go

key-decisions:
  - "FEDERAL_ORDER: legislative branch (Senate, House) before executive branch — matches user requirement"
  - "TermStart/TermEnd use omitempty: existing API consumers see no breaking change when dates are empty"
  - "normalizedToOfficialOut populated from off.ValidFrom/ValidTo (provider.NormalizedOfficial fields at lines 25-26)"

patterns-established:
  - "OfficialOut fields: always add with omitempty for backward compatibility"

requirements-completed: [ESST-05, ESST-06]

# Metrics
duration: 3min
completed: 2026-02-18
---

# Phase 5 Plan 01: Federal Section Reorder + Term Dates Summary

**Legislative-first federal ordering (Senate > House) and term_start/term_end fields exposed in all four OfficialOut construction paths**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-18T17:00:22Z
- **Completed:** 2026-02-18T17:03:10Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- Reordered FEDERAL_ORDER constant so U.S. Senate and U.S. House appear before President/VP and Cabinet
- Added TermStart/TermEnd fields to OfficialOut struct with json omitempty tags
- Populated term dates in all four construction paths: fetchOfficialsFromDB, fetchFederalAndStateFromDBFiltered, GetPoliticianByID, normalizedToOfficialOut
- Backend compiles cleanly with no breaking changes

## Task Commits

Each task was committed atomically (two repos):

1. **Task 1 (Part A): Reorder FEDERAL_ORDER** - `dd09e82` in essentials repo (feat)
2. **Task 1 (Part B): Add term_start/term_end to OfficialOut** - `41b5ffa` in EV-Backend repo (feat)

## Files Created/Modified
- `essentials/src/lib/classify.js` - Reordered FEDERAL_ORDER: Senate > House > President/VP > Cabinet > Agencies > Executive (Other)
- `EV-Backend/internal/essentials/handlers.go` - Added TermStart/TermEnd to OfficialOut struct and all four construction sites; added ValidFrom/ValidTo to row structs and SELECT queries

## Decisions Made
- Federal ordering: legislative branch first matches the user requirement (Senate > House > President/VP > Cabinet > Agencies)
- Used `omitempty` on both new fields so existing API consumers continue to work when dates are absent
- `normalizedToOfficialOut` populates from `off.ValidFrom`/`off.ValidTo` which are already present on `provider.NormalizedOfficial` (lines 25-26 of provider/types.go)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- EV-Backend and essentials are separate git repositories (not tracked in the workspace root repo). Committed changes in each repo individually. This is normal for this workspace structure.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Federal section ordering fix is live in essentials frontend
- Term dates available in API responses for all politician endpoints — frontend can now display term start/end when present
- Ready for plan 02

---
*Phase: 05-essentials-improvements*
*Completed: 2026-02-18*
