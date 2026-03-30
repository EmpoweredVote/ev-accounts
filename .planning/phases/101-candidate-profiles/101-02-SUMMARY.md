---
phase: 101-candidate-profiles
plan: 02
subsystem: frontend
tags: [react, jsx, essentials, elections, candidates, profile]

# Dependency graph
requires:
  - phase: 101-01
    provides: GET /api/essentials/race-candidates/:id with CandidateDetail including nullable politician_id
  - phase: 99-election-central-page
    provides: ElectionsView component and election data rendering
provides:
  - fetchRaceCandidate(id) API function in essentials/src/lib/api.jsx
  - Unified CandidateProfile.jsx with incumbent/challenger branching and CompassCard
  - Fixed ElectionsView.jsx routing — all candidates use /candidate/:id
  - Simplified onCandidateClick handler in Results.jsx
affects:
  - User-facing candidate profile pages in essentials app

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "polId state separate from URL id param — prevents CompassCard receiving candidate UUID instead of politician UUID (Pitfall 4)"
    - "fetchRaceCandidate as first fetch, branching on politician_id null/non-null for incumbent/challenger"
    - "Self-gating CompassCard: rendered only when polId is non-null (incumbent), CompassCard internally gates on stance existence"
    - "Challenger minimal render: only name, photo, position banner — no CompassCard, no legislative, no judicial"
    - "Not-found state via notFound state var when fetchRaceCandidate returns null"

key-files:
  created: []
  modified:
    - essentials/src/lib/api.jsx
    - essentials/src/components/ElectionsView.jsx
    - essentials/src/pages/Results.jsx
    - essentials/src/pages/CandidateProfile.jsx

key-decisions:
  - "publicFetch used for fetchRaceCandidate (not apiFetch) — election data is public, no auth needed"
  - "polId initialized null, set only when candidate.politician_id exists — CompassCard never receives candidate UUID"
  - "candidateBanner always shows 'Candidate for [position_name]' — data comes from fetchRaceCandidate response, no separate elections fetch"
  - "Challenger branch uses photo_origin_url mapping from candidate.photo_url for PoliticianProfile parity"

requirements-completed: [PROF-01, PROF-02, PROF-03, PROF-04, PROF-05]

# Metrics
duration: 15min
completed: 2026-03-30
---

# Phase 101 Plan 02: Candidate Profile Frontend Summary

**Rewritten CandidateProfile.jsx with incumbent/challenger branching; fixed ElectionsView routing to always use race_candidates UUID; added fetchRaceCandidate API function**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-30T20:44:30Z
- **Completed:** 2026-03-30T21:00:00Z (paused at human-verify checkpoint)
- **Tasks:** 2 of 3 (Task 3 is human-verify checkpoint)
- **Files modified:** 4

## Accomplishments

- Added `fetchRaceCandidate(id)` to `essentials/src/lib/api.jsx` using `publicFetch` (public endpoint, no auth required)
- Fixed `ElectionsView.jsx`: PoliticianCard `id` prop and `onClick` always use `candidate.candidate_id` (removed the `politician_id || candidate_id` split)
- Fixed `Results.jsx`: `onCandidateClick` simplified to one argument, always navigates to `/candidate/${id}` (no `isPolitician` ternary)
- Rewrote `CandidateProfile.jsx` with full incumbent/challenger branching:
  - **Incumbent path** (politician_id non-null): fetches full politician + legislative summary + judicial record in parallel, renders PoliticianProfile with all data + CompassCard
  - **Challenger path** (politician_id null): builds minimal pol object from candidate data only, renders PoliticianProfile with minimal data — no CompassCard, no legislative, no judicial
  - **Not-found state**: renders "Candidate not found" when fetchRaceCandidate returns null (withdrawn/invalid candidate)
  - `polId` state separate from URL `id` parameter — prevents CompassCard receiving candidate UUID instead of politician UUID
  - Candidate banner shows "Candidate for [position_name]" with optional election date

## Task Commits

Each task was committed atomically:

1. **Task 1: Add fetchRaceCandidate and fix ElectionsView/Results routing** - `b667419` (feat)
2. **Task 2: Rewrite CandidateProfile with incumbent/challenger branching** - `f477267` (feat)

**Task 3: Human verification** — checkpoint pending user verification

## Files Created/Modified

- `essentials/src/lib/api.jsx` — Added `fetchRaceCandidate(id)` using publicFetch
- `essentials/src/components/ElectionsView.jsx` — PoliticianCard always uses `candidate.candidate_id`; onClick passes one arg
- `essentials/src/pages/Results.jsx` — `onCandidateClick` simplified to `(id)`, always navigates to `/candidate/${id}`
- `essentials/src/pages/CandidateProfile.jsx` — Full rewrite with incumbent/challenger branching, not-found state, CompassCard integration

## Decisions Made

- `publicFetch` for `fetchRaceCandidate` — consistent with other election endpoints; race candidate data is public
- `polId` as separate state from `id` URL param — critical to prevent CompassCard receiving wrong UUID type
- `candidateData.position_name` used directly from fetchRaceCandidate response — no second fetch to elections API needed
- Challenger branch maps `candidate.photo_url` to `photo_origin_url` for PoliticianProfile prop compatibility

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all data is wired from live API endpoints.

## User Setup Required

Task 3 requires human verification:
1. Run `cd essentials && npm run dev`
2. Run `cd ev-accounts/backend && npm run dev`
3. Navigate to essentials dev URL, enter Bloomington IN address
4. Test incumbent candidate click (full profile + CompassCard)
5. Test challenger candidate click (minimal profile, no CompassCard)
6. Test `/candidate/00000000-0000-0000-0000-000000000000` (not-found state)

---
*Phase: 101-candidate-profiles*
*Completed: 2026-03-30*

## Self-Check: PASSED

- api.jsx fetchRaceCandidate: FOUND (b667419)
- ElectionsView.jsx candidate_id routing: FOUND (b667419)
- Results.jsx simplified handler: FOUND (b667419)
- CandidateProfile.jsx rewrite: FOUND (f477267)
- Commit b667419: FOUND
- Commit f477267: FOUND
