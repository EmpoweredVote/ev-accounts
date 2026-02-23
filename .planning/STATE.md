# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-22)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.5 complete — BallotReady independence shipped

## Current Position

Phase: 30 of 31 (Fix Compass Calibration Flow Layout and Write-In Option)
Plan: 1 of 2 complete
Status: Phase 30 Plan 01 complete — CalibrationOverlay answer step layout restructured
Last activity: 2026-02-23 — Phase 30 Plan 01 executed: CalibrationOverlay answer step restructured to 50/50 split with question text anchored above stances and radar chart vertically centered

Progress: [██████████] In progress (post-v1.5)

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
| 27-cache-only-candidates-warmer-cleanup | 01 | 7min | 2 | 5 |
| 27-cache-only-candidates-warmer-cleanup | 02 | 5min | 2 | 2 |
| 28-address-autocomplete | 01 | 4min | 1 | 2 |
| 28-address-autocomplete | 02 | 5min | 2 | 2 |
| 29-validation-polish-key-removal | 01 | 8min | 2 | 5 |
| 29-validation-polish-key-removal | 02 | ~10min | 2 | 0 |

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

v1.5 decisions from Phase 27 Plan 01:
- admin.go WarmZip/WarmZipWith removed; runBulkImport returns immediate failure — live warmer no longer available, data import needs new pipeline in a future phase
- cmd/bulk-import deprecated in place (main.go prints message and exits) — file preserved, not deleted
- ensureCandidacyData removed entirely (no stub): profile pages read from DB only
- FederalCache/StateCache/ZipCache GORM models kept in this plan — table drops deferred to Plan 02 (remove all reads before dropping tables)

v1.5 decisions from Phase 27 Plan 02:
- cicero blank import kept in setup.go — handlers.go still directly references cicero types/functions; Phase 29 will audit remaining cicero dependencies
- external_global_id kept in upsert map (data-ingestion path) — not the GetPoliticianByID query ref that was removed in Plan 01
- DROP TABLE IF EXISTS added to Init() before AutoMigrate — idempotent, safe to run on every server start

v1.5 decisions from Phase 28 Plan 01:
- onPlaceSelected does NOT call navigate() — user must explicitly click Search after selecting suggestion (locked plan decision)
- handleKeyDown removed entirely — Google autocomplete handles Enter internally; hasValidSelection guard blocks raw text submission
- Search button disabled prop checks !addressInput.trim() || loadError only; hasValidSelection check inside handleSearch shows hint rather than silently blocking

v1.5 decisions from Phase 28 Plan 02:
- LocalFilterSidebar created locally (not published to ev-ui) to avoid publish cycle — clean migration path if needed later
- dataStatus 'no-geofence-data' message placed in address bar section (above two-panel) so it's always visible regardless of scroll position
- defaultSort and GROUP_SORT_OPTIONS kept as internal code (sort dropdown UI removed, not the underlying sort logic)
- Skeleton sections shown during both 'loading' and 'warming' phases; results rendered only after phase leaves loading state

v1.5 decisions from Phase 29 Plan 01:
- provider/config.go switch statement simplified to only handle default case after ballotready branch removed — no ProviderBallotReady constant remains
- ballotready/ package intentionally left as dead code (failing to compile) — confirms it has no active imports from main codebase
- .env.local POLITICIAN_PROVIDER and BALLOTREADY_KEY removed; server defaults to cicero provider when POLITICIAN_PROVIDER is unset

v1.5 decisions from Phase 29 Plan 02:
- Backend is deployed on Render (not AWS App Runner as originally documented) — BALLOTREADY_KEY was found and removed from Render env vars
- Google Maps API monitoring: informational-only alerting at 5,000 requests/month (50% of free tier) — no quota cap, API fully open

Phase 30 Plan 01 decisions:
- Question text moved into right column as first child — eliminates full-width centering, anchors text directly above stances
- 50/50 split (md:basis-1/2) replaces 60/40 (md:basis-3/5 / md:basis-2/5) to give stances more horizontal breathing room
- items-center on chart column vertically centers radar chart against natural height of question + stances block
- Responsive chart sizing: max-w-[280px] mobile / max-w-[400px] desktop with aspect-square

### Roadmap Evolution

- Phase 30 added: Fix Compass calibration flow layout and write-in option
- Phase 31 added: Essentials profile and district data fixes

### Pending Todos

None.

### Blockers/Concerns

- Phase 28 shadow DOM gap: `PlaceAutocompleteElement` limits Tailwind targeting to outer container; internal styling requires `gmp-place-autocomplete::part(input)` — may require design tradeoff decision

## Session Continuity

Last session: 2026-02-23
Stopped at: Completed 30-fix-compass-calibration-flow-layout-and-write-in-option/30-01-PLAN.md — CalibrationOverlay answer step layout restructured to 50/50 split
Resume file: None
