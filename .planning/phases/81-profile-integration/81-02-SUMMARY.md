---
phase: 81-profile-integration
plan: 02
subsystem: ui
tags: [react, typescript, url-fragment, base64, essentials, read-rank]

# Dependency graph
requires:
  - phase: 79-verdict-backend
    provides: verdict fragment URL format (compass= base64 key)
  - phase: 78-visual-refresh
    provides: ev-muted-blue color token used for CTA styling
provides:
  - buildVerdictFragment utility encodes all session verdicts into base64 compass fragment
  - buildEssentialsProfileUrl builds full Essentials profile URL with verdict fragment
  - View on Essentials CTA on every QuoteResultCard in ResultsPhase
  - View on Essentials CTA in CandidateAlignmentPage stats section
affects:
  - 81-03 (if exists — Essentials profile page fragment consumer)
  - 82-logged-in-sync

# Tech tracking
tech-stack:
  added: []
  patterns:
    - btoa(JSON.stringify({ v })) fragment encoding — idempotent verdict map built from all issues
    - VITE_ESSENTIALS_URL env var with fallback constant pattern
    - Secondary border CTA style: border-ev-muted-blue with hover:bg-ev-muted-blue hover:text-white

key-files:
  created:
    - EV-readrank/src/utils/verdictFragment.ts
  modified:
    - EV-readrank/src/components/ResultsPhase.tsx
    - EV-readrank/src/components/CandidateAlignmentPage.tsx

key-decisions:
  - "buildVerdictFragment encodes ALL session verdicts across all issues — not scoped per candidate link — so one fragment covers the full session"
  - "rankedQuotes assigned 'agreed' idempotently since they are a subset of agreedQuotes — no deduplication logic needed"
  - "EV-readrank is a standalone git repo (separate from workspace root); commits go in EV-readrank/.git, not workspace root"

patterns-established:
  - "verdictFragment.ts: centralized utility for all Essentials deep-link construction — import from '../utils/verdictFragment'"
  - "View on Essentials CTA uses <a> tag (not button) with target=_blank rel=noopener noreferrer — always opens in new tab"

requirements-completed:
  - VERD-05
  - PROF-04

# Metrics
duration: 4min
completed: 2026-03-12
---

# Phase 81 Plan 02: Verdict Fragment Utility and Essentials CTAs Summary

**Verdict fragment encoder utility + "View on Essentials" CTAs wired to both result surfaces in EV-ReadRank, linking politicians to their Essentials profiles with full session verdicts encoded in a base64 compass URL fragment**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-12T14:54:16Z
- **Completed:** 2026-03-12T14:58:25Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Created `verdictFragment.ts` with `buildVerdictFragment` and `buildEssentialsProfileUrl` exports — encodes all agreed/disagreed quote IDs from all issues into `#compass=BASE64({v:{...}})` fragment
- Added "View on Essentials" anchor CTA to `QuoteResultCard` in `ResultsPhase` — secondary blue button style, opens `essentials.empowered.vote/politician/{uuid}#compass=...` in new tab
- Added "View on Essentials" anchor CTA to `CandidateAlignmentPage` stats section — centered below 4-stat grid, same secondary blue treatment

## Task Commits

Each task was committed atomically (in EV-readrank repo):

1. **Task 1: Create verdictFragment.ts utility** - `e286e28` (feat)
2. **Task 2: Add View on Essentials CTAs to ResultsPhase and CandidateAlignmentPage** - `894cc11` (feat)

**Plan metadata:** (see below — docs commit in workspace root)

## Files Created/Modified
- `EV-readrank/src/utils/verdictFragment.ts` - buildVerdictFragment and buildEssentialsProfileUrl utilities
- `EV-readrank/src/components/ResultsPhase.tsx` - issueProgress destructured from store; QuoteResultCard gets issueProgress prop and View on Essentials CTA
- `EV-readrank/src/components/CandidateAlignmentPage.tsx` - buildEssentialsProfileUrl imported; View on Essentials link below stats grid

## Decisions Made
- Fragment encodes ALL session verdicts across all issues — not scoped to the candidate being linked, because the Essentials profile consumer needs the full picture, not a filtered subset
- `rankedQuotes` assigned 'agreed' idempotently (they are already in `agreedQuotes`); no deduplication needed since map assignment is idempotent
- Discovered EV-readrank is a standalone git repo — commits go inside EV-readrank/.git, not the workspace root

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
- Git staging required using EV-readrank's own repo (`cd EV-readrank && git add/commit`) — the workspace root git treats EV-readrank/ as an untracked nested repo. This is expected behavior, not a problem.

## User Setup Required
None — no external service configuration required. `VITE_ESSENTIALS_URL` defaults to `https://essentials.empowered.vote` if not set.

## Next Phase Readiness
- Essentials profile page (phase 82 or wherever fragment consumption happens) can now receive `#compass=BASE64(...)` URL fragments and decode them
- Both EV-ReadRank result surfaces have working Essentials deep-links ready to test end-to-end once Essentials profile page consumes the fragment

---
*Phase: 81-profile-integration*
*Completed: 2026-03-12*
