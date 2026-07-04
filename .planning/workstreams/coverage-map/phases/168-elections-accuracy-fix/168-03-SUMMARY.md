---
phase: 168-elections-accuracy-fix
plan: 03
subsystem: admin-ui
tags: [react, typescript, elections, coverage-map, choropleth, admin]

# Dependency graph
requires: ["168-01"]
provides:
  - "admin/src/pages/admin/StatewideRacesPanel.tsx — net-new panel listing statewide/legislative races with candidate coverage"
  - "State choropleth fill + hover readout repointed to statewide/legislative coverage (D-01)"
  - "N/A — no county-level races readout, visually distinct from a real 0% (D-03)"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Frontend StateElection type mirrors the Plan-01 backend contract (countyCoverage {status,coverage,...} + statewideRaces)"
    - "unknown/scored vocabulary reused from the existing county fill for the N/A vs 0% distinction"

key-files:
  created:
    - admin/src/pages/admin/StatewideRacesPanel.tsx
  modified:
    - admin/src/pages/admin/coverageTypes.ts
    - admin/src/pages/admin/CoveragePage.tsx
    - admin/src/pages/admin/CoverageMap.tsx

key-decisions:
  - "No new fetch/query/endpoint: statewideRaces and countyCoverage arrive as part of the already-lazily-fetched elecStates array; only new render output was required (onSelectState already sets selected on any state click)"
  - "Reused the exact unknown/scored vocabulary the county fill already implements, so the N/A vs real-0% distinction is consistent with the county choropleth"

requirements-completed: [ELEC-01, ELEC-02, ELEC-03]

# Metrics
duration: 15min
completed: 2026-07-04
---

# Phase 168 Plan 03: Surface Corrected Elections Numbers in the Admin UI Summary

**The admin elections coverage map now colors the state choropleth by the statewide/legislative coverage number (D-01), shows a net-new `StatewideRacesPanel` alongside the existing county view when a state is clicked (D-02), and renders a state's county-pinnable number as "N/A — no county-level races" — visually distinct from a real 0% (D-03) — making the Michigan bug's corrected numbers visible in one click.**

## Performance

- **Duration:** ~15 min (execution to checkpoint) + human verification
- **Completed:** 2026-07-04
- **Tasks:** 3 completed (2 code tasks + 1 human-verify walkthrough)
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments
- Extended the frontend `StateElection` type in `coverageTypes.ts` to mirror the Plan-01 backend contract (`countyCoverage` + `statewideRaces`)
- Built net-new `StatewideRacesPanel.tsx` listing a state's statewide/legislative races with per-race candidate counts (ELEC-02)
- Repointed the `CoverageMap` state choropleth fill and hover readout to the statewide/legislative coverage number, not the old lumped number (D-01)
- Rendered the county-pinnable number as "N/A — no county-level races" when `countyCoverage.status === 'unknown'`, reusing the county fill's `unknown`/`scored` vocabulary so N/A is visually distinct from a real 0% (D-03)
- Mounted the panel in the previously panel-less elections branch of `CoveragePage`, rendered together with the existing county view (D-02)

## Task Commits

Each code task was committed atomically:

1. **Task 1: Extend StateElection type + build StatewideRacesPanel + repoint CoverageMap fill/readout** - `e04c1f00` (feat)
2. **Task 2: Mount StatewideRacesPanel in CoveragePage elections branch** - `3ec1dd20` (feat)
3. **Task 3: Michigan-case manual walkthrough (D-01/D-02/D-03 visual verify)** - human-verified, approved (no code)

## Files Created/Modified
- `admin/src/pages/admin/StatewideRacesPanel.tsx` (NEW) — panel listing statewide/legislative races with candidate coverage
- `admin/src/pages/admin/coverageTypes.ts` — `StateElection` extended with `countyCoverage` + `statewideRaces`
- `admin/src/pages/admin/CoveragePage.tsx` — panel mounted in the `metric === 'elections' && selected` branch, alongside the county view
- `admin/src/pages/admin/CoverageMap.tsx` — state fill/readout repointed to statewide coverage; N/A vs 0% county-number distinction

## Verification (Task 3 — human walkthrough)

Verified live against a local backend (:3000) + admin dev server (:5174) on merged `master`:

- **D-01:** US states map in elections mode colors Michigan by its statewide/legislative number; hover readout reads "Michigan 100% · county: N/A — no county-level races". The 100% is the *accurate* statewide-only figure (13/13 seeded statewide/legislative races have ≥1 candidate per `raceCoverage`), no longer a lumped artifact.
- **D-02:** Clicking Michigan renders the "Statewide & legislative races (13)" panel (its 13 U.S. House district races, correctly bucketed as non-county-pinnable by `classifyRaces`) together with the county drill-down.
- **D-03:** Panel header shows "County-pinnable: N/A — no county-level races"; the county choropleth is all-gray with the "no race data" legend — distinct from a real 0%.
- **No contradiction:** the state view (statewide 100%, county N/A) is consistent with the county drill-down (no county races).

Human reviewer approved the fix. Two out-of-scope observations were captured as follow-ups (see Next Phase Readiness).

## Decisions Made
- No new fetch/query/endpoint — the corrected numbers arrive on the already-lazily-fetched `elecStates` array; only render output changed.
- Reused the existing `unknown`/`scored` county-fill vocabulary for the N/A distinction, keeping the state and county views consistent.

## Deviations from Plan
- **Verification path:** because there is no frontend test runner configured for `admin/` (per RESEARCH.md), task 3 is a human walkthrough. To enable it, the orchestrator merged tasks 1–2 to `master` first and ran the app locally (backend :3000 + Vite :5174) rather than verifying inside the isolated worktree. No code change resulted from verification.
- One environment note (same as 168-01/168-02): `admin/node_modules` was absent in the worktree at spawn; ran `npm ci` (lockfile-only, zero new packages) for `tsc --noEmit` verification.

## Issues Encountered
- Verification surfaced two product-level observations that are **out of scope** for this accuracy-fix phase and were deferred by the reviewer:
  1. Coverage measures *breadth* (races with ≥1 candidate name), not *depth* (compass stances / transparent motivations); a richer 3-tier candidate indicator (names · names+stances-or-TM · all three) with covered/total was requested for a future phase.
  2. Some expected statewide offices (e.g. MI Governor, Senate) are not present in the seeded data for the 2026 general, so they cannot factor into the denominator — a data-seeding / expected-slate concern, not a code defect.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness

Phase 168's accuracy fix (state/county partition) is complete and visible in the admin UI. Two follow-ups captured as todos for a future phase in this milestone:
- Depth-aware 3-tier candidate coverage indicator (covered/total by stances/transparent-motivations tier).
- Seed missing statewide offices (MI Governor + Senate 2026) and/or make coverage relative to the expected office slate.

---
*Phase: 168-elections-accuracy-fix*
*Completed: 2026-07-04*

## Self-Check: PASSED

All created/modified files verified present:
- FOUND: admin/src/pages/admin/StatewideRacesPanel.tsx
- FOUND: admin/src/pages/admin/coverageTypes.ts (modified)
- FOUND: admin/src/pages/admin/CoveragePage.tsx (modified)
- FOUND: admin/src/pages/admin/CoverageMap.tsx (modified)

All code commits verified present in git log:
- FOUND: e04c1f00 (feat)
- FOUND: 3ec1dd20 (feat)
