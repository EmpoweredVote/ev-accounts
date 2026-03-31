---
phase: 101-candidate-profiles
plan: 02
subsystem: ui
tags: [react, routing, candidate-profile, compass-card]

requires:
  - phase: 101-01
    provides: GET /api/essentials/race-candidates/:id endpoint
provides:
  - Unified candidate profile page with incumbent/challenger branching
  - fetchRaceCandidate API function
  - cleanPositionName normalization (leading zeros, federal title abbreviation, ordinal words)
  - All election candidates route to /candidate/:id with race_candidates UUID
affects: [essentials-frontend, compass-integration]

tech-stack:
  added: []
  patterns: [candidate-politician bridging via race_candidates UUID, self-gating component rendering]

key-files:
  created: []
  modified:
    - essentials/src/lib/api.jsx
    - essentials/src/pages/CandidateProfile.jsx
    - essentials/src/components/ElectionsView.jsx
    - essentials/src/pages/Results.jsx

key-decisions:
  - "cleanPositionName enhanced: strips leading zeros (District 061→61), abbreviates federal titles (United States Representative→US Representative), converts ordinal words (Ninth District→District 9)"
  - "All candidate cards route to /candidate/:id with race_candidates UUID — no isPolitician split routing"
  - "CompassCard receives polId (politician UUID), never candidate UUID — prevents stance lookup failures"

patterns-established:
  - "cleanPositionName exported from ElectionsView for reuse across candidate display components"
  - "Candidate profile branches on politician_id: incumbent gets full data + CompassCard, challenger gets minimal view"

requirements-completed: [PROF-01, PROF-02, PROF-03, PROF-04, PROF-05]

duration: 12min
completed: 2026-03-30
---

# Phase 101-02: Frontend Candidate Profile Summary

**Unified candidate profile page — incumbents get full politician data + CompassCard, challengers get clean minimal view, all using race_candidates UUID routing**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-03-30T20:45:00Z
- **Completed:** 2026-03-30T21:10:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- All election candidates navigate to `/candidate/:id` using race_candidates UUID (no more isPolitician split routing)
- Incumbent profiles show full politician data, legislative summary, judicial record, and CompassCard (self-gating)
- Challenger profiles show name, photo/initials, and position — no empty loading states or placeholder sections
- Position name normalization: leading zeros stripped, federal titles abbreviated, ordinal words converted to numbers

## Task Commits

Each task was committed atomically:

1. **Task 1: fetchRaceCandidate + routing fix** - `b667419` (feat)
2. **Task 2: CandidateProfile rewrite** - `f477267` (feat)
3. **Task 3: Position name normalization** - `4fc0907` (fix) — during human verification

## Files Created/Modified
- `essentials/src/lib/api.jsx` - Added fetchRaceCandidate(id) API function
- `essentials/src/pages/CandidateProfile.jsx` - Full rewrite with incumbent/challenger branching + cleanPositionName import
- `essentials/src/components/ElectionsView.jsx` - Enhanced cleanPositionName (leading zeros, federal abbreviations, ordinal words), exported function
- `essentials/src/pages/Results.jsx` - Simplified onCandidateClick to single parameter

## Decisions Made
- Position name normalization done at display layer (cleanPositionName) rather than import time — preserves raw data from SoS
- cleanPositionName exported from ElectionsView rather than creating a separate utility — only two consumers

## Deviations from Plan

### Auto-fixed Issues

**1. Position name display issues caught during human verification**
- **Found during:** Task 3 (human verification checkpoint)
- **Issue:** "District 061" showing with leading zero; "United States Representative, Ninth District" not matching representatives page format
- **Fix:** Enhanced cleanPositionName to strip leading zeros, abbreviate federal titles, convert ordinal words to numbers
- **Files modified:** essentials/src/components/ElectionsView.jsx, essentials/src/pages/CandidateProfile.jsx
- **Verification:** User confirmed display is correct after fix
- **Committed in:** 4fc0907

---

**Total deviations:** 1 auto-fixed (display normalization)
**Impact on plan:** Necessary polish caught during UAT. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Candidate profile system complete — both incumbent and challenger flows verified
- CompassCard and legislative summary wired and self-gating
- Position name display standardized across elections view and candidate profiles

---
*Phase: 101-candidate-profiles*
*Completed: 2026-03-30*
