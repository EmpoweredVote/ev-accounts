# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-23)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.6 LA County Full Coverage — Phase 32

## Current Position

Phase: 32 of 38 (Schema Fixes and Lookup Bug Correction)
Plan: — of — in current phase
Status: Ready to plan
Last activity: 2026-02-23 — v1.6 roadmap created, Phase 32 ready for planning

Progress: [░░░░░░░░░░] 0% (v1.6 phases 32-38, 0/7 phases complete)

## Performance Metrics

**Velocity (v1.0):** 7 phases, 21 plans
**Velocity (v1.1):** 3 phases, 3 plans
**Velocity (v1.2):** 6 phases, 12 plans, 27 tasks
**Velocity (v1.3):** 4 phases, 7 plans
**Velocity (v1.4):** 5 phases, 9 plans
**Velocity (v1.5):** 6 phases, 13 plans, 25 tasks

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.0–v1.5 decisions resolved — see `.planning/milestones/` for full history.

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

Last session: 2026-02-23
Stopped at: v1.6 roadmap created — Phase 32 ready for planning
Resume file: None
