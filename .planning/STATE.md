# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-23)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.6 LA County Full Coverage — Phase 32

## Current Position

Phase: 32 of 38 (Schema Fixes and Lookup Bug Correction)
Plan: 1 of 1 in current phase
Status: In progress
Last activity: 2026-02-24 — Phase 32 Plan 01 complete (schema fixes + MTFCC map)

Progress: [░░░░░░░░░░] 0% (v1.6 phases 32-38, 0/7 phases complete)

## Performance Metrics

**Velocity (v1.0):** 7 phases, 21 plans
**Velocity (v1.1):** 3 phases, 3 plans
**Velocity (v1.2):** 6 phases, 12 plans, 27 tasks
**Velocity (v1.3):** 4 phases, 7 plans
**Velocity (v1.4):** 5 phases, 9 plans
**Velocity (v1.5):** 6 phases, 13 plans, 25 tasks
**Velocity (v1.6):** Phase 32 — 1 plan, 2 tasks, 2 files, ~1 min

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

- ArcGIS FeatureServer field names for supervisor district number unverified — inspect endpoint before Phase 35 implementation
- Existing geo_id format for LA City council districts must be queried from DB before Phase 36 — Bloomington 12-char format is inferred, not confirmed for CA
- Federal/state CA politician coverage must be verified at Phase 36 start — if BallotReady never warmed CA state officials, Phase 36 scope expands

## Session Continuity

Last session: 2026-02-24
Stopped at: Completed 32-01-PLAN.md — schema fixes and MTFCC lookup bug correction done
Resume file: None
