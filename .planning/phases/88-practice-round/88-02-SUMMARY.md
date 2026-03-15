---
phase: 88-practice-round
plan: 02
subsystem: ui
tags: [react, typescript, framer-motion, zustand, practice-round, readrank, onboarding]

# Dependency graph
requires:
  - phase: 88-practice-round-plan-01
    provides: Store v5 with isolated PracticeProgress state, 7 practice actions, practiceData.ts, QuoteCard with onAgree/onDisagree props
provides:
  - PracticeRound component with splash intro, swipe evaluation, inline matchup UI, desktop sidebar, mobile counter pill, skip link, practice banner
  - PracticeResultsScreen component with character emoji avatars, pizza rankings, and hub CTA
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
    - "Splash screen leads with feature value prop then warm-up context — same pattern as Compass CalibrationOverlay welcome step"
    - "Character emoji avatars: emoji + colored background (40x40 rounded square) matching essentials politician photo pattern"

key-files:
  created:
    - EV-readrank/src/components/PracticeRound.tsx
    - EV-readrank/src/components/PracticeResultsScreen.tsx
  modified:
    - EV-readrank/src/components/PhaseContainer.tsx
    - EV-readrank/src/data/practiceData.ts

key-decisions:
  - "PracticeRound reads from practiceProgress directly (not getCurrentIssueProgress) — keeps practice isolated from real issue data"
  - "Results sub-phase tracked via local showResults state (not store phase) — completePractice() sets phase to 'hub' directly, never to 'results'"
  - "PhaseContainer auto-redirect calls startPractice() (not setPhase('practice')) — startPractice initializes practiceProgress; bare setPhase would leave it null"
  - "Practice splash added (user-requested): leads with Read & Rank feature value prop before pizza practice warm-up"
  - "Character emoji avatars added (user-requested): emoji + avatarColor fields added to PRACTICE_CHARACTERS; disagreed cards desaturated"

patterns-established:
  - "Practice matchup: inline MatchCard renders in PracticeRound with separate handlePick, selected state, shakeRef — exact mirror of MatchupPhase but reading from practiceProgress"
  - "PracticeResultsScreen card pattern: character avatar (emoji + color) + name/title from PRACTICE_CHARACTERS + quote text + verdict badge — simpler than ResultsPhase (no photo CDN, no Essentials link)"

requirements-completed: [ONBD-01, ONBD-02, ONBD-03, ONBD-04]

# Metrics
duration: ~75min (includes checkpoint + user-requested enhancements)
completed: 2026-03-15
---

# Phase 88 Plan 02: Practice Round UI Summary

**PracticeRound with splash intro and inline matchups, PracticeResultsScreen with character emoji avatars, and PhaseContainer auto-redirect — complete pizza-topping practice flow verified by user and isolated from real issue verdict state**

## Performance

- **Duration:** ~75 min (including checkpoint review and user-requested enhancements)
- **Started:** 2026-03-15T20:13:50Z
- **Completed:** 2026-03-15T20:31:22Z
- **Tasks:** 3 (2 auto + 1 checkpoint:human-verify — APPROVED)
- **Files modified:** 4

## Accomplishments

- PracticeRound renders full evaluation experience (splash intro, swipe mode + inline matchup UI) reading from practiceProgress state — never touches issueProgress or triggers postVerdicts
- PracticeResultsScreen shows pizza topping rankings with staggered reveals, character emoji avatars (chef hat, monocle, pinched fingers, flexing, art palette), and "Start exploring real issues" CTA
- PhaseContainer extended with 'practice' case and mount-only auto-redirect that calls startPractice() for first-time users (practiceCompleted: false)
- User verified all checkpoint criteria: first-time auto-redirect, swipe/matchup flow, skip, results with character reveals, hub landing, no postVerdicts calls

## Task Commits

1. **Task 1: Create PracticeRound and PracticeResultsScreen components** - `0a49e43` (feat)
2. **Task 2: Wire PracticeRound into PhaseContainer with auto-redirect** - `6b564f3` (feat)
3. **Task 3: Human verification checkpoint** - APPROVED by user

**User-requested enhancements during checkpoint review:**
- `b55abf8` feat(88-02): add practice round splash screen before evaluation
- `44b1afe` feat(88-02): add Read & Rank feature intro to practice splash screen
- `55e2da1` feat(88-02): add character avatars to practice results screen

## Files Created/Modified

- `EV-readrank/src/components/PracticeRound.tsx` - Practice evaluation container: splash intro screen, QuoteCard with practice callbacks, inline MatchCard matchups, practice banner, skip link, desktop ranked sidebar, mobile counter pill
- `EV-readrank/src/components/PracticeResultsScreen.tsx` - Practice results: staggered pizza quote cards with character emoji avatars, agreed/disagreed verdict badges, completePractice() CTA
- `EV-readrank/src/components/PhaseContainer.tsx` - Added PracticeRound import, practiceCompleted/startPractice store reads, mount useEffect auto-redirect, 'practice' case in switch
- `EV-readrank/src/data/practiceData.ts` - Added emoji and avatarColor fields to PRACTICE_CHARACTERS entries

## Decisions Made

- PracticeRound doesn't reuse EvaluationPhase because that component reads from getCurrentIssueProgress() (requires currentIssueId). Instead PracticeRound reads practiceProgress directly — keeps practice isolated
- Results sub-phase handled via local `showResults` state, not store phase — `completePractice()` sets phase to 'hub' directly. This ensures postVerdicts in PhaseContainer is never called during practice
- PhaseContainer auto-redirect calls `startPractice()` not `setPhase('practice')` — `startPractice` initializes `practiceProgress`; bare `setPhase` would leave it null causing empty UI
- Splash screen leads with the Read & Rank feature value prop (reads, swipes, matchups, politician matches) before introducing pizza practice as warm-up — gives new users full context for what they're learning

## Deviations from Plan

### User-Requested Enhancements (during checkpoint review)

Three enhancements were added at user request after the checkpoint was returned — not auto-fixes but deliberate feature additions:

**1. Practice splash screen (`b55abf8`)**
- **Added during:** Task 3 checkpoint review
- **Addition:** Centered intro screen before first swipe card, explaining the mechanic with pizza card illustration
- **Files modified:** EV-readrank/src/components/PracticeRound.tsx

**2. Read & Rank feature intro on splash (`44b1afe`)**
- **Added during:** Task 3 checkpoint review (follow-up)
- **Addition:** Splash leads with feature name and value prop before the pizza warm-up context
- **Files modified:** EV-readrank/src/components/PracticeRound.tsx

**3. Character emoji avatars on results screen (`55e2da1`)**
- **Added during:** Task 3 checkpoint review (follow-up)
- **Addition:** Emoji avatars with colored backgrounds; added `emoji` and `avatarColor` to PRACTICE_CHARACTERS; disagreed cards rendered desaturated
- **Files modified:** EV-readrank/src/components/PracticeResultsScreen.tsx, EV-readrank/src/data/practiceData.ts

---

**Total deviations:** 3 user-requested enhancements
**Impact on plan:** All within practice round scope. Enhances new-user onboarding quality. No scope creep.

## Issues Encountered

None - TypeScript compiled clean after both auto tasks. No blocking issues during execution.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Complete practice round flow verified by user — first-time users see splash, swipe pizza quotes, get matchups, see character-revealed results, then land on hub
- Returning users bypass practice cleanly (practiceCompleted: true in localStorage after v5 migration)
- Practice never contaminates real issue data or triggers postVerdicts
- Phase 89 (CoachMark) can begin — verify CoachMark absent from ev-ui exports before manual port (per STATE.md blocker)

---
*Phase: 88-practice-round*
*Completed: 2026-03-15*

## Self-Check: PASSED

- PracticeRound.tsx: FOUND (EV-readrank/src/components/PracticeRound.tsx)
- PracticeResultsScreen.tsx: FOUND (EV-readrank/src/components/PracticeResultsScreen.tsx)
- PhaseContainer.tsx: FOUND (modified)
- practiceData.ts: FOUND (modified)
- Commit 0a49e43: FOUND
- Commit 6b564f3: FOUND
- Commit b55abf8: FOUND
- Commit 44b1afe: FOUND
- Commit 55e2da1: FOUND
