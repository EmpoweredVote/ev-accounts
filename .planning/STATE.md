---
gsd_state_version: 1.0
milestone: v1.9
milestone_name: Compare UX & Search Fixes
status: unknown
last_updated: "2026-02-28T23:26:02.015Z"
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 6
  completed_plans: 6
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-27)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 53 — Search Accuracy Bug Fix (v1.9)

## Current Position

Phase: 53 of 53 (Search Accuracy Bug Fix) — In Progress
Plan: 1 of 2 complete in current phase (53-01 complete)
Status: In Progress
Last activity: 2026-02-28 - Completed 53-01: Area intersection search — SearchPoliticians now routes city/ZIP/county queries through ST_Intersects boundary overlap

Progress: [█████████████████████████] 83% of v1.9 (5 of 6 plans complete)

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
- [Phase 53-01]: IsAreaQuery deny-list approach: point types (street_address, premise, subpremise, route) return false; all other result types treated as area — errs toward broader civic search results
- [Phase 53-01]: ZIP queries no longer special-cased in SearchPoliticians — all queries geocode through area/point detection; GET /politicians/{zip} kept for backward compatibility
- [Phase 53-02]: Single search path: removed ZIP vs address branching in usePoliticianData — all queries use searchPoliticians(query)
- [Phase 53-02]: searchKey pattern: state counter incremented on each search forces hook re-fetch even for same query text, fixing same-location re-search bug

### Pending Todos

- **Future phase idea: Census ZCTA-to-Place ZIP mapping for city council politicians** — All 89 cities in city_sources.json have `place_geoid` and `ocd_id_base` that match 381 LOCAL/LOCAL_EXEC politicians. A script could batch-insert zip_politicians rows. Works for 72 at-large cities; district cities would over-show but better than nothing.

### Blockers/Concerns

- SRCH-01: RESOLVED — Area intersection search implemented in 53-01. ST_Intersects boundary overlap now used for city/ZIP/county queries.
- COMP-02: State field may not be currently exposed on /compass/politicians endpoint. Verify response shape before planning.
- SRCH-02: Race condition suspected with Google autocomplete re-initialization on results page. Root cause should be confirmed during planning before writing solution.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 1 | Fix compare page showing 0s for missing stances and investigate Kerry Thomson Trans-Athletes stance | 2026-02-28 | cf0fb2b | [1-fix-compare-page-showing-0s-for-missing-](./quick/1-fix-compare-page-showing-0s-for-missing-/) |

## Session Continuity

Last session: 2026-02-28
Stopped at: Completed 53-search-accuracy-bug-fix 53-01-PLAN.md — Area intersection search for city/ZIP/county queries
Resume file: None
