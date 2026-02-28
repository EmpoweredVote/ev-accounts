---
gsd_state_version: 1.0
milestone: v1.9
milestone_name: Compare UX & Search Fixes
status: unknown
last_updated: "2026-02-28T22:07:14.766Z"
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 4
  completed_plans: 4
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-27)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 52 — Compare Politician List Filters (v1.9)

## Current Position

Phase: 52 of 53 (Compare Politician List Filters) — Complete
Plan: 2 of 2 in current phase (52-01 and 52-02 complete)
Status: Complete
Last activity: 2026-02-28 — 52-02: PoliticianFilters integrated into CompareModal complete, phase 52 done

Progress: [████████████████████████] 100% of v1.9 (all plans complete)

## Performance Metrics

**Velocity (v1.8):** 6 phases, 28 plans
**Velocity (v1.7):** 6 phases, 15 plans, 36 tasks (1 plan deferred)
**Velocity (v1.6):** 7 phases, 11 plans, 23 tasks
**Velocity (v1.5):** 6 phases, 13 plans, 25 tasks

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.

Recent decisions affecting current work:
- [v1.5]: Geofence-only search uses ST_Covers point-in-polygon; city-wide searches (SRCH-01) need ST_Intersects on city boundary polygon (G4110 MTFCC)
- [v1.5]: Legacy Google Maps Autocomplete class in use — no migration needed for SRCH-02 fix
- [v1.3]: Compare polygon bug fixed in ev-ui@0.1.21 — inline picker (COMP-01) adds to stable surface
- [51-01]: Module-level cache (cachedList + pendingPromise) chosen for usePoliticianList over React Context — self-contained, no Provider wrapping needed
- [51-01]: InlinePoliticianPicker manages own open/close state locally — single instance renders at a time, no lift-up needed
- [51-02]: handleSwitchPolitician does NOT clear compareAnswers — old radar polygon stays visible during fetch, react-spring morphs when new data arrives
- [51-02]: dropdownValue (topic selection) preserved across politician switches — user sees new politician's stance on the same topic immediately
- [Phase 52]: JUDICIAL district type always mapped to Local in compass filters — chamber_name not available in /compass/politicians endpoint
- [Phase 52]: levelCounts in useFilteredPoliticians reflect state-filtered totals so pills show contextually accurate counts
- [52-02]: useFilteredPoliticians hook reused in CompareModal's internal PoliticianPicker with zero structural changes to CompareModal outer component

### Pending Todos

- **Future phase idea: Census ZCTA-to-Place ZIP mapping for city council politicians** — All 89 cities in city_sources.json have `place_geoid` and `ocd_id_base` that match 381 LOCAL/LOCAL_EXEC politicians. A script could batch-insert zip_politicians rows. Works for 72 at-large cities; district cities would over-show but better than nothing.

### Blockers/Concerns

- SRCH-01: Backend needs to detect city-level vs. point searches and switch ST_Covers to ST_Intersects with city boundary lookup (G4110 MTFCC). Logic is in EV-Backend/internal/essentials/handlers.go. Plan should investigate what Google Places returns for city queries (place_id type, geometry bounds) to determine detection approach.
- COMP-02: State field may not be currently exposed on /compass/politicians endpoint. Verify response shape before planning.
- SRCH-02: Race condition suspected with Google autocomplete re-initialization on results page. Root cause should be confirmed during planning before writing solution.

## Session Continuity

Last session: 2026-02-28
Stopped at: Completed 52-02-PLAN.md — PoliticianFilters integrated into CompareModal, phase 52 complete.
Resume file: None
