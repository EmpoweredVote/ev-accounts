---
gsd_state_version: 1.0
milestone: v1.9
milestone_name: Compare UX & Search Fixes
status: in_progress
last_updated: "2026-02-28"
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 2
  completed_plans: 1
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-27)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 51 — Compare Inline Picker (v1.9)

## Current Position

Phase: 51 of 53 (Compare Inline Picker)
Plan: 1 of 2 in current phase (51-01 complete)
Status: In progress
Last activity: 2026-02-28 — 51-01: shared hook + InlinePoliticianPicker component complete

Progress: [████████████████████░░] 0% of v1.9 (0/3 phases complete this milestone)

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

### Pending Todos

- **Future phase idea: Census ZCTA-to-Place ZIP mapping for city council politicians** — All 89 cities in city_sources.json have `place_geoid` and `ocd_id_base` that match 381 LOCAL/LOCAL_EXEC politicians. A script could batch-insert zip_politicians rows. Works for 72 at-large cities; district cities would over-show but better than nothing.

### Blockers/Concerns

- SRCH-01: Backend needs to detect city-level vs. point searches and switch ST_Covers to ST_Intersects with city boundary lookup (G4110 MTFCC). Logic is in EV-Backend/internal/essentials/handlers.go. Plan should investigate what Google Places returns for city queries (place_id type, geometry bounds) to determine detection approach.
- COMP-02: State field may not be currently exposed on /compass/politicians endpoint. Verify response shape before planning.
- SRCH-02: Race condition suspected with Google autocomplete re-initialization on results page. Root cause should be confirmed during planning before writing solution.

## Session Continuity

Last session: 2026-02-28
Stopped at: Completed 51-01-PLAN.md — usePoliticianList hook + InlinePoliticianPicker component. 51-02 is next.
Resume file: None
