# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-22)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.5 Address Verification & BallotReady Independence — Phase 26 ready to plan

## Current Position

Phase: 26 of 29 (Geofence-Only Search)
Plan: —
Status: Ready to plan
Last activity: 2026-02-22 — v1.5 roadmap created, phases 26-29 defined

Progress: [░░░░░░░░░░] 0% (v1.5)

## Performance Metrics

**Velocity (v1.0):** 7 phases, 21 plans
**Velocity (v1.1):** 3 phases, 3 plans
**Velocity (v1.2):** 6 phases, 12 plans, 27 tasks
**Velocity (v1.3):** 4 phases, 7 plans
**Velocity (v1.4):** 5 phases, 9 plans

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.0–v1.4 decisions resolved — see `.planning/milestones/` for full history.

v1.5 key decisions entering Phase 26:
- Frontend (Phase 28) is fully parallel to backend (Phases 26-27); sequenced here for dependency clarity only
- `ballotready/` package directory kept (not deleted) to preserve admin import pipeline
- Federal/state fallback path implemented in Phase 26 alongside fallback removal — never shipped separately to avoid blank-page states
- Legacy Google Maps `Autocomplete` class acceptable for Phase 28 (existing key predates March 2025 cutoff); `PlaceAutocompleteElement` preferred for forward compatibility

### Pending Todos

None.

### Blockers/Concerns

- Phase 27 research flag: `fetchCandidatesFromDB` join path from `election_records` to `zip_politicians` needs schema inspection before writing SQL — confirm join keys and upcoming-election filter before execution
- Phase 28 shadow DOM gap: `PlaceAutocompleteElement` limits Tailwind targeting to outer container; internal styling requires `gmp-place-autocomplete::part(input)` — may require design tradeoff decision
- Phase 29 dependency: Google for Nonprofits credits status unknown; confirm before shipping to production to avoid unexpected billing

## Session Continuity

Last session: 2026-02-22
Stopped at: v1.5 roadmap created — ready to plan Phase 26
Resume file: None
