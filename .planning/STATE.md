# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-23)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.6 LA County Full Coverage — Phase 35

## Current Position

Phase: 35 of 38 (LA County ArcGIS Geofences — Supervisor Districts and City Council Wards)
Plan: 1 of 2 in current phase
Status: Complete
Last activity: 2026-02-24 — Phase 35 Plan 01 complete (5 supervisor districts + 15 LA City council wards imported; all GEO-04 and GEO-07 requirements verified)

Progress: [░░░░░░░░░░] 0% (v1.6 phases 32-38, 0/7 phases complete)

## Performance Metrics

**Velocity (v1.0):** 7 phases, 21 plans
**Velocity (v1.1):** 3 phases, 3 plans
**Velocity (v1.2):** 6 phases, 12 plans, 27 tasks
**Velocity (v1.3):** 4 phases, 7 plans
**Velocity (v1.4):** 5 phases, 9 plans
**Velocity (v1.5):** 6 phases, 13 plans, 25 tasks
**Velocity (v1.6):** Phase 32 — 1 plan, 2 tasks, 2 files, ~1 min; Phase 33 — 1 plan, 2 tasks, 6 files, ~5 min; Phase 34 — 1 plan, 2 tasks, 1 file, ~2 min; Phase 35 Plan 01 — 2 tasks, 3 files, ~4 min

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.0–v1.5 decisions resolved — see `.planning/milestones/` for full history.

**v1.6 Decisions (Phase 32):**
- [32-01] Use `id DESC` (not `imported_at DESC`) for geofence dedup ordering — imported_at may be NULL for pre-existing rows
- [32-01] Dedup error uses log.Printf warning (not Fatal) — table may not exist on fresh database, expected behavior
- [32-01] ST_Covers replaces ST_Contains — identical argument order, Covers returns TRUE for boundary-coincident points
- [32-01] G4120 maps to LOCAL/LOCAL_EXEC (same as G4110) — consolidated cities use identical BallotReady district types as incorporated places
- [32-01] G5400/G5410 map to SCHOOL — all school district variants use the same BallotReady district type as G5420

**v1.6 Decisions (Phase 33):**
- [33-01] v1.6 synthetic external IDs start at -200001 (not -100001) to avoid collision with v1.5 promote_scraped_officials.py range
- [33-01] urllib.parse imports stay inside get_engine() body in utils.py — matches the existing pattern
- [33-01] promote_scraped_officials.py not refactored — v1.5 one-time script kept isolated from pipeline infrastructure
- [33-01] No __init__.py added to scripts/ — scripts run directly, not imported as package

**v1.6 Decisions (Phase 34):**
- [34-01] NAMELSAD column used for G4110 name field (e.g., "Los Angeles city") — matches legislative script pattern, more descriptive than NAME
- [34-01] ocd_id left NULL for G4110 — consistent with Indiana G4110 records; geofence_lookup.go uses geo_id not ocd_id
- [34-01] No FUNCSTAT filter applied — CA G4110 count of exactly 482 is within expected range (450-520)

**v1.6 Decisions (Phase 35 Plan 01):**
- [35-01] Use X0001 MTFCC (not G4020) for supervisor district geofences — G4020 maps to COUNTY/JUDICIAL, but LA supervisors are district_type=LOCAL; X0001 maps to LOCAL
- [35-01] OCD-ID string used as geo_id for X0001 boundaries — direct match to essentials.districts.ocd_id confirmed by DB query, enables Phase 36 join
- [35-01] Direct ALTER TABLE to widen geo_id to varchar(255) — GORM AutoMigrate does not widen existing varchar columns

### Key v1.6 Constraints

- Phase 32 (schema) must complete before any import work — wrong unique constraint silently destroys multi-layer imports
- Phase 33 (utils) must complete before new import scripts — prevents sixth copy of `get_engine()` duplication
- Geofences (Phases 34-35) must complete before politicians (Phases 36-37) — geo_id join dependency
- TIGER sources (Phase 34) before ArcGIS sources (Phase 35) — different integration patterns, TIGER is lower risk
- VACUUM ANALYZE (Phase 38) must be last step after all bulk inserts
- Supabase direct connection only (port 5432) — pooler breaks bulk imports
- Import UNSD (G5420) only, never G5400/G5410 — prevents school board triple-match in LAUSD areas
- Synthetic external IDs start at -200001 — avoids collision with v1.5 -100001-range IDs

### Pending Todos

None.

### Blockers/Concerns

- Remaining city council boundaries (Long Beach, Pasadena, Torrance, Inglewood, Downey, West Covina, Santa Clarita) have TBD ArcGIS URLs — Phase 35 Plan 02 must resolve these
- Federal/state CA politician coverage must be verified at Phase 36 start — if BallotReady never warmed CA state officials, Phase 36 scope expands

## Session Continuity

Last session: 2026-02-24
Stopped at: Completed 35-01-PLAN.md — 5 LA County supervisor districts and 15 LA City council wards imported (20 records), GEO-04 and GEO-07 requirements verified
Resume file: None
