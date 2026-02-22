# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-22)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.5 Address Verification & BallotReady Independence — Phase 26 in progress

## Current Position

Phase: 26 of 29 (Geofence-Only Search)
Plan: 2 of 2 complete
Status: Phase 26 Plan 02 complete
Last activity: 2026-02-22 — Phase 26 Plan 02 executed: frontend address input, formatted address display, local empty-state

Progress: [███░░░░░░░] 37% (v1.5)

## Performance Metrics

**Velocity (v1.0):** 7 phases, 21 plans
**Velocity (v1.1):** 3 phases, 3 plans
**Velocity (v1.2):** 6 phases, 12 plans, 27 tasks
**Velocity (v1.3):** 4 phases, 7 plans
**Velocity (v1.4):** 5 phases, 9 plans

**v1.5 progress:**
| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 26-geofence-only-search | 01 | 3min | 2 | 3 |
| 26-geofence-only-search | 02 | 1min | 2 | 3 |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.0–v1.4 decisions resolved — see `.planning/milestones/` for full history.

v1.5 key decisions entering Phase 26:
- Frontend (Phase 28) is fully parallel to backend (Phases 26-27); sequenced here for dependency clarity only
- `ballotready/` package directory kept (not deleted) to preserve admin import pipeline
- Federal/state fallback path implemented in Phase 26 alongside fallback removal — never shipped separately to avoid blank-page states
- Legacy Google Maps `Autocomplete` class acceptable for Phase 28 (existing key predates March 2025 cutoff); `PlaceAutocompleteElement` preferred for forward compatibility

v1.5 decisions from Phase 26 Plan 01:
- Use fetchFederalAndStateFromDB (not fetchStatewideFromDB) in no-geofence path — includes NATIONAL_LOWER and STATE_UPPER/STATE_LOWER
- International addresses (empty State from geocoder) return 422 Unprocessable Entity
- Nil GeoClient returns 503 Service Unavailable — no BallotReady escape hatch remains
- ZIP delegation to handleZipLookup preserved inside SearchPoliticians until Phase 28

v1.5 decisions from Phase 26 Plan 02:
- All searches route through ?q= parameter from UI — backend isZip5 check still handles ZIP strings server-side
- formattedAddress only populated in address search branch (not ZIP branch) — correct behavior, ZIP branch has no X-Formatted-Address header
- Local empty-state condition includes activeQuery guard so message never appears on initial Dashboard load

### Pending Todos

None.

### Blockers/Concerns

- Phase 27 research flag: `fetchCandidatesFromDB` join path from `election_records` to `zip_politicians` needs schema inspection before writing SQL — confirm join keys and upcoming-election filter before execution
- Phase 28 shadow DOM gap: `PlaceAutocompleteElement` limits Tailwind targeting to outer container; internal styling requires `gmp-place-autocomplete::part(input)` — may require design tradeoff decision
- Phase 29 dependency: Google for Nonprofits credits status unknown; confirm before shipping to production to avoid unexpected billing

## Session Continuity

Last session: 2026-02-22
Stopped at: Completed 26-geofence-only-search/26-02-PLAN.md
Resume file: None
