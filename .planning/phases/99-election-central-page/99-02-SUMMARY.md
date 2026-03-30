---
phase: 99-election-central-page
plan: 02
subsystem: ui
tags: [react, tailwind, ev-ui, elections, tabs]

requires:
  - phase: 99-01
    provides: GET /api/essentials/elections-by-address endpoint with district_type
  - phase: 98-election-data-import
    provides: Election/race/candidate data in essentials schema
provides:
  - Elections tab on Results page with tier-grouped race cards
  - Context-aware back navigation (Elections vs Representatives breadcrumb)
  - Primary ballot labeling (party shown for primaries only)
affects: [candidate-profiles, essentials-ui, ev-ui]

tech-stack:
  added: []
  patterns:
    - "sessionStorage ev:fromView for cross-page navigation context"
    - "seeded shuffle for antipartisan candidate ordering"
    - "primary_party displayed only for primary election_type races"

key-files:
  created:
    - essentials/src/components/ElectionsView.jsx
  modified:
    - essentials/src/pages/Results.jsx
    - essentials/src/pages/Profile.jsx
    - essentials/src/pages/CandidateProfile.jsx
    - essentials/src/lib/api.jsx
    - ev-accounts/backend/src/lib/electionService.ts

key-decisions:
  - "Primary elections show party ballot labels — antipartisan exception because voters must choose a party ballot"
  - "Dot indicator uses ev-yellow (Inform pillar color) not ev-muted-blue"
  - "Back navigation is context-aware: breadcrumb says 'Elections' or 'Representatives' based on origin"
  - "Candidates navigated via politician_id when linked, candidate_id otherwise"
  - "Local candidates deferred — Indiana SoS data only covers state/federal races"

patterns-established:
  - "ev:fromView sessionStorage pattern for tab-aware back navigation"
  - "inferDistrictType in backend parses position_name for accurate classification"

requirements-completed: [ELEC-01, ELEC-02, ELEC-03, ELEC-04, ELEC-05, ELEC-06, ELEC-07]

duration: 45min
completed: 2026-03-30
---

# Phase 99-02: Elections Tab UI Summary

**Elections tab on Results page with tier-grouped races, CategorySection grid cards, primary ballot labels, and context-aware back navigation**

## Performance

- **Duration:** ~45 min (interactive with user feedback)
- **Started:** 2026-03-30T09:30:00Z
- **Completed:** 2026-03-30T10:15:00Z
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 6

## Accomplishments
- Elections tab accessible via ?view=elections URL param with lazy-loaded data
- Races grouped by election date, then tier (Local > State > Federal), then position
- CategorySection grid layout matching Representatives tab card dimensions
- Primary ballot labels ("— Democratic Primary" / "— Republican Primary") for primaries
- Seeded-random candidate ordering, incumbent badges, election date with countdown badge
- Context-aware back navigation: breadcrumb says "Elections" or "Representatives"

## Task Commits

1. **Task 1: fetchElectionsByAddress + ElectionsView** - `92460ca` + `24f24b2` (feat)
2. **Task 2: Tab toggle + Results.jsx integration** - `24f24b2` (feat)
3. **Task 3: Visual verification** - User approved after iterative fixes

**Iterative fixes after user feedback:**
- `7524e7c` - Horizontal cards, fix classification, strip leading zeros
- `83b0c32` - Backend: better district_type inference + photo enrichment
- `d30bc60` - CategorySection grid, ev-yellow dot, merge duplicate races
- `71a17d5` - Primary ballot labels (revert merge, show party for primaries)
- `03a0ae2` - Context-aware back navigation

## Files Created/Modified
- `essentials/src/components/ElectionsView.jsx` - Elections tab content with tier grouping, seeded shuffle, countdown
- `essentials/src/pages/Results.jsx` - Tab toggle, elections state, lazy fetch, view switching
- `essentials/src/pages/Profile.jsx` - Context-aware back navigation
- `essentials/src/pages/CandidateProfile.jsx` - Context-aware back navigation
- `essentials/src/lib/api.jsx` - fetchElectionsByAddress function
- `ev-accounts/backend/src/lib/electionService.ts` - inferDistrictType + photo enrichment

## Decisions Made
- Primary elections show party labels — antipartisan exception because voters must choose a party ballot
- Dot indicator uses ev-yellow (#FED12E) for Inform pillar identity
- Back navigation stores origin view in sessionStorage (ev:fromView)
- Candidates with politician_id navigate to /politician/ (full profile), others to /candidate/
- Local race candidates deferred — SoS data only covers state/federal; Monroe County data needed

## Deviations from Plan

Initial agent created a standalone Elections page instead of a tab — reverted and rebuilt correctly inline. Multiple iterations with user feedback to match Representatives tab card layout, fix race grouping, and add primary ballot labels.

## Issues Encountered
- classifyCategory returned "Executive (Other)" for all state races because synthetic district_type was STATE_EXEC — fixed with inferDistrictType parsing position_name
- Duplicate race sections for same position — caused by separate party primary races, resolved by showing party ballot labels instead of merging

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Elections tab complete for state/federal races with existing data
- Local candidate data import needed from Monroe County Clerk (future phase)
- Deeper breadcrumb trail (Representatives > Matt Pierce) deferred to future phase

---
*Phase: 99-election-central-page*
*Completed: 2026-03-30*
