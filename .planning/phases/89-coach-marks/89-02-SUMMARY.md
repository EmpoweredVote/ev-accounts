---
phase: 89-coach-marks
plan: "02"
subsystem: ui
tags: [react, framer-motion, coach-marks, forwardRef, zustand, tour]

# Dependency graph
requires:
  - phase: 89-coach-marks-01
    provides: CoachMark component with 4-rect interactive spotlight, Zustand store with coachMarksCompleted/completeCoachMarks

provides:
  - forwardRef on QuoteCard exposing motion.div root for spotlight targeting
  - forwardRef on RankedListSidebar exposing outer container for desktop step 2 spotlight
  - forwardRef on InlineRankPanel exposing outer container for mobile step 2 spotlight
  - 2-step coach mark tour wired into EvaluationPhase with 500ms delay trigger
  - Step 1 interactive spotlight on swipe card with auto-advance on first swipe
  - Step 2 spotlight on rank panel (sidebar desktop / InlineRankPanel mobile) after first agree
  - Permanent dismissal via Got it / Skip All / Escape writing coachMarksCompleted=true to store

affects: [phase-90-location-filter, EvaluationPhase consumers]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "forwardRef pattern for spotlight targets: convert React.FC to React.forwardRef<HTMLDivElement, Props> and add displayName"
    - "Tour state local to EvaluationPhase (useState<1|2|null>) with Zustand for persistence"
    - "Auto-advance tour step by intercepting agree/disagree callbacks at EvaluationPhase level"
    - "coachMarkOverlay variable rendered in both desktop and mobile returns — CoachMark portals to body so placement in JSX tree is irrelevant"

key-files:
  created: []
  modified:
    - EV-readrank/src/components/QuoteCard.tsx
    - EV-readrank/src/components/AgreedQuotesSidebar.tsx
    - EV-readrank/src/components/InlineRankPanel.tsx
    - EV-readrank/src/components/EvaluationPhase.tsx
    - EV-readrank/src/components/CoachMark.tsx

key-decisions:
  - "Tour state (tourStep) is local to EvaluationPhase not the store — ephemeral per-session, only persistence needed is coachMarksCompleted"
  - "Step 1 uses allowSpotlightInteraction=true (4-rect approach) so user can actually swipe the card through the spotlight"
  - "Step 2 deferred until rankedQuotes.length >= 1 — guarantees sidebar has content before spotlighting it"
  - "handleCardAgree/handleCardDisagree wrap store actions to intercept tour step advancement from drag swipes; handleButtonSwipe also advances tour for keyboard/button path"
  - "Mobile step 2: auto-open InlineRankPanel via useEffect when tourStep===2 and rankedQuotes.length>=1"

patterns-established:
  - "forwardRef conversion: keep same component name, add displayName, ref on outermost element"
  - "Coach mark overlay extracted to coachMarkOverlay variable — included in both desktop and mobile branches without duplication of logic"

requirements-completed: [ONBD-05, ONBD-06]

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 89 Plan 02: Coach Mark Tour Wiring Summary

**2-step interactive coach mark tour wired into EvaluationPhase with forwardRef spotlight targets, auto-advance on first swipe, and permanent Zustand-backed dismissal**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-15T23:06:57Z
- **Completed:** 2026-03-15T23:10:00Z
- **Tasks:** 2 of 2 completed (Task 3 is human-verify checkpoint)
- **Files modified:** 5

## Accomplishments
- QuoteCard, RankedListSidebar, and InlineRankPanel all converted to React.forwardRef with displayName, exposing root DOM nodes for CoachMark spotlight targeting
- 2-step tour wired into EvaluationPhase: step 1 appears after 500ms with interactive spotlight on swipe card; step 2 spotlights rank panel (sidebar desktop / InlineRankPanel mobile) after first agree
- All dismissal paths (Got it, Skip All, Escape, Next) call completeCoachMarks() for permanent one-time-only behavior
- Production build passes with zero TypeScript errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Add forwardRef to QuoteCard, RankedListSidebar, and InlineRankPanel** - `2a3c0ff` (feat)
2. **Task 2: Wire 2-step coach mark tour into EvaluationPhase** - `1a13ecb` (feat)
3. **Auto-fix: CoachMark JSX.Element return type** - `6ab8600` (fix)

## Files Created/Modified
- `EV-readrank/src/components/QuoteCard.tsx` - Converted to React.forwardRef<HTMLDivElement, QuoteCardProps>; ref on motion.div root
- `EV-readrank/src/components/AgreedQuotesSidebar.tsx` - Converted RankedListSidebar to React.forwardRef<HTMLDivElement>; ref on outer container div
- `EV-readrank/src/components/InlineRankPanel.tsx` - Converted to React.forwardRef<HTMLDivElement, InlineRankPanelProps>; ref on outer div
- `EV-readrank/src/components/EvaluationPhase.tsx` - Full tour orchestration: CoachMark import, store destructuring, tourStep state, 3 refs, 2 useEffects, 4 handlers, updated QuoteCard/Sidebar/InlineRankPanel JSX, coachMarkOverlay
- `EV-readrank/src/components/CoachMark.tsx` - Auto-fix: Caret return type JSX.Element → React.ReactElement

## Decisions Made
- Tour state (tourStep) is local to EvaluationPhase — ephemeral, only coachMarksCompleted needs Zustand persistence
- Step 1 uses allowSpotlightInteraction=true so users can actually swipe the card through the spotlight (proves the interaction)
- Both drag swipes (handleCardAgree/handleCardDisagree) and button/keyboard swipes (handleButtonSwipe) advance the tour step to ensure consistent behavior regardless of input method
- Mobile step 2 auto-opens InlineRankPanel via useEffect when tourStep transitions to 2

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] CoachMark.tsx Caret function used JSX.Element return type**
- **Found during:** Build verification after Task 2
- **Issue:** `JSX.Element` return type requires the JSX namespace to be in scope; this tsconfig doesn't import it, causing `error TS2503: Cannot find namespace 'JSX'`
- **Fix:** Changed `): JSX.Element {` to `): React.ReactElement {` — functionally equivalent, always available via the React import
- **Files modified:** `EV-readrank/src/components/CoachMark.tsx`
- **Verification:** `npm run build` succeeds with zero errors
- **Committed in:** `6ab8600` (separate fix commit)

---

**Total deviations:** 1 auto-fixed (1 blocking build error)
**Impact on plan:** Fix was necessary for production build to succeed. The issue was in Plan 01's CoachMark.tsx output — not introduced by Plan 02 changes.

## Issues Encountered
- `npx tsc --noEmit` passed cleanly (isolated tsconfig), but `npm run build` (which uses `tsc -b`) caught the JSX.Element error in CoachMark.tsx — the `-b` flag uses a different tsconfig strictness. Fixed immediately per Rule 3.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Coach mark tour is fully wired and ready for human verification (Task 3 checkpoint)
- After human verification, Phase 89 is complete
- Phase 90 (location filter) can begin without coach mark dependencies

---
*Phase: 89-coach-marks*
*Completed: 2026-03-15*
