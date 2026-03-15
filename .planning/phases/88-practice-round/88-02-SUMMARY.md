---
phase: 88-practice-round
plan: 02
subsystem: ui
tags: [react, typescript, framer-motion, zustand, practice-round, readrank]

# Dependency graph
requires:
  - phase: 88-practice-round-plan-01
    provides: Store v5 with isolated PracticeProgress state, 7 practice actions, practiceData.ts, QuoteCard with onAgree/onDisagree props
provides:
  - PracticeRound component with swipe evaluation, inline matchup UI, desktop sidebar, mobile counter pill, skip link, practice banner
  - PracticeResultsScreen component with character reveals and hub CTA
  - PhaseContainer wired with 'practice' case and auto-redirect for first-time users
affects: [88-03-coachmark, phase-89, phase-90]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "PracticeRound reproduces evaluation layout reading from practiceProgress directly (not reusing EvaluationPhase which reads from getCurrentIssueProgress)"
    - "Inline matchup UI in PracticeRound uses MatchCard directly instead of MatchupPhase to avoid issueProgress coupling"
    - "showResults local state in PracticeRound controls results sub-phase without setting store phase to 'results' — prevents postVerdicts trigger"
    - "PhaseContainer auto-redirect uses empty-dep useEffect to call startPractice() once on mount for new users"

key-files:
  created:
    - EV-readrank/src/components/PracticeRound.tsx
    - EV-readrank/src/components/PracticeResultsScreen.tsx
  modified:
    - EV-readrank/src/components/PhaseContainer.tsx

key-decisions:
  - "PracticeRound reads from practiceProgress directly (not getCurrentIssueProgress) — keeps practice isolated from real issue data"
  - "Results sub-phase tracked via local showResults state (not store phase) — completePractice() sets phase to 'hub' directly, never to 'results'"
  - "PhaseContainer auto-redirect calls startPractice() (not setPhase('practice')) — startPractice initializes practiceProgress; bare setPhase would leave it null"

patterns-established:
  - "Practice matchup: inline MatchCard renders in PracticeRound with separate handlePick, selected state, shakeRef — exact mirror of MatchupPhase but reading from practiceProgress"
  - "PracticeResultsScreen card pattern: character header (name + title from PRACTICE_CHARACTERS lookup) + quote text + verdict badge — simpler than ResultsPhase (no photo, no Essentials link)"

requirements-completed: [ONBD-02]

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 88 Plan 02: Practice Round UI Summary

**PracticeRound and PracticeResultsScreen components with PhaseContainer auto-redirect — complete pizza-topping practice flow isolated from real issue verdict state**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-15T20:13:50Z
- **Completed:** 2026-03-15T20:16:50Z
- **Tasks:** 2 (Task 3 is human-verify checkpoint — returned to orchestrator)
- **Files modified:** 3

## Accomplishments

- PracticeRound renders the full evaluation experience (swipe mode + inline matchup UI) reading from practiceProgress state — never touches issueProgress or triggers postVerdicts
- PracticeResultsScreen shows pizza topping rankings with character name/title reveals from PRACTICE_CHARACTERS and "Start exploring real issues" CTA
- PhaseContainer extended with 'practice' case and mount-only auto-redirect that calls startPractice() for first-time users (practiceCompleted: false)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create PracticeRound and PracticeResultsScreen components** - `0a49e43` (feat)
2. **Task 2: Wire PracticeRound into PhaseContainer with auto-redirect** - `6b564f3` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `EV-readrank/src/components/PracticeRound.tsx` - Practice evaluation container: QuoteCard with practice callbacks, inline MatchCard matchups, practice banner, skip link, desktop ranked sidebar, mobile counter pill
- `EV-readrank/src/components/PracticeResultsScreen.tsx` - Practice results: staggered pizza quote cards with character reveals, agreed/disagreed verdict badges, completePractice() CTA
- `EV-readrank/src/components/PhaseContainer.tsx` - Added PracticeRound import, practiceCompleted/startPractice store reads, mount useEffect auto-redirect, 'practice' case in switch

## Decisions Made

- PracticeRound doesn't reuse EvaluationPhase because that component reads from getCurrentIssueProgress() (requires currentIssueId). Instead PracticeRound reads practiceProgress directly — keeps practice isolated
- Results sub-phase handled via local `showResults` state, not store phase — `completePractice()` sets phase to 'hub' directly. This ensures postVerdicts in PhaseContainer is never called during practice
- PhaseContainer auto-redirect calls `startPractice()` not `setPhase('practice')` — `startPractice` initializes `practiceProgress`; bare `setPhase` would leave it null causing empty UI

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - all TypeScript compiles clean on first attempt.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Complete practice round flow ready for human verification (Task 3 checkpoint)
- After verification, Phase 89 (CoachMark) can build on top of PhaseContainer 'practice' routing
- Verify CoachMark is still absent from ev-ui exports before manual port (per STATE.md blocker)

---
*Phase: 88-practice-round*
*Completed: 2026-03-15*

## Self-Check: PASSED

- PracticeRound.tsx: FOUND (/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/PracticeRound.tsx)
- PracticeResultsScreen.tsx: FOUND (/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/PracticeResultsScreen.tsx)
- PhaseContainer.tsx: FOUND (modified)
- SUMMARY.md: FOUND
- Commit 0a49e43: FOUND
- Commit 6b564f3: FOUND
