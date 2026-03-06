---
phase: 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity
plan: 04
subsystem: ui
tags: [react, localStorage, framer-motion, coach-mark, onboarding, tour]

# Dependency graph
requires:
  - phase: 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity
    provides: CoachMark component (66-01), post-cal tour + write-in hint (66-02), Library + Compare tours (66-03)
provides:
  - All onboarding localStorage flags confirmed present in handleClearCompass (Layout.jsx)
  - Post-cal tour fixed: reduced to 3 steps, compare button spotlight uses callback ref, spoke flip message clarified as visual-only
  - Topic picker subtitle updated to "Pick the issues that matter most to you when you vote"
  - Full onboarding system verified end-to-end with user testing
affects: [phase-65, compass-onboarding, compassv2-layout]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Callback ref for dynamic spotlight targets in tour steps"
    - "Tour step count reduction: remove low-value steps discovered during real user testing"

key-files:
  created: []
  modified:
    - CompassV2/src/components/Layout.jsx
    - CompassV2/src/pages/Compass.jsx
    - CompassV2/src/components/CalibrationOverlay.jsx

key-decisions:
  - "Post-cal tour reduced from 4 to 3 steps: removed help button step (? button too subtle and low-value for tour)"
  - "Compare button spotlight fixed with callback ref instead of document.querySelector to survive re-renders"
  - "Spoke flip coach mark message updated to clarify it is a visual-only change, not a stance change"
  - "Topic picker subtitle changed from generic 'Pick topics' to 'Pick the issues that matter most to you when you vote'"

patterns-established:
  - "Callback ref pattern: attach ref with useCallback to DOM node for dynamically mounted tour targets"
  - "Onboarding flag naming: onboarding_* pattern for all localStorage tour/hint keys"
  - "All onboarding flags cleared together in handleClearCompass alongside calibration/quiz flags"

requirements-completed: [ONBOARD-01, ONBOARD-02, ONBOARD-03, ONBOARD-04, ONBOARD-05, ONBOARD-06]

# Metrics
duration: 45min
completed: 2026-03-06
---

# Phase 66 Plan 04: Onboarding Flag Cleanup and End-to-End Verification Summary

**Post-cal tour fixed (3 steps, working spotlight), topic picker subtitle clarified for voting context, full onboarding system verified end-to-end**

## Performance

- **Duration:** ~45 min
- **Completed:** 2026-03-06
- **Tasks:** 2 (1 no-op verification, 1 human-verify with fixes applied)
- **Files modified:** 3

## Accomplishments

- Task 1 (flag cleanup): All 5 onboarding localStorage flags were already present in handleClearCompass from Plans 02+03 — no code changes needed, confirmed complete
- Task 2 (end-to-end verification): User tested the full flow and surfaced two issues that were fixed immediately
- Post-cal tour reduced from 4 to 3 steps — help button step removed (button too small and subtle to spotlight effectively)
- Compare button spotlight fixed: switched from `document.querySelector` to a callback ref passed via prop, ensuring the ref survives re-renders when the button conditionally mounts
- Spoke flip coach mark message updated to make clear it changes the visual axis only, not the user's actual stance
- Topic picker subtitle updated from a generic prompt to "Pick the issues that matter most to you when you vote" — connects topic selection to the user's voting purpose

## Task Commits

Each task was committed atomically:

1. **Task 1: Consolidate onboarding flag cleanup in Layout.jsx** - no commit (all flags already present, no changes needed)
2. **Task 2: Verify complete onboarding flow end-to-end** - `087a1a8` (feat: topic picker subtitle) and `6431e6b` (fix: post-cal tour 3 steps, compare spotlight, spoke flip message)

## Files Created/Modified

- `CompassV2/src/pages/Compass.jsx` - Post-cal tour reduced to 3 steps; compare button spotlight wired via callback ref prop passed to Compare button
- `CompassV2/src/components/CalibrationOverlay.jsx` - Topic picker subtitle updated to voting-framed copy
- `CompassV2/src/components/Layout.jsx` - Confirmed: all 5 onboarding flags (spokeFlip, postCalTour, compareTour, libraryTour, writeInHint) present in handleClearCompass — no change needed

## Decisions Made

- Removed the help button (?) tour step: the button is small, the spotlight cutout looked awkward, and users can discover it naturally. 3-step tour is cleaner.
- Used callback ref (via prop) instead of DOM query for the compare button spotlight: `document.querySelector` was fragile when the button conditionally mounted; callback ref fires reliably on mount/unmount.
- Spoke flip message clarified: original wording implied changing stances — updated to say it changes the visual axis only so users understand it is a display toggle, not a preference change.
- Topic picker subtitle rewritten: "Pick topics you care about" is vague. "Pick the issues that matter most to you when you vote" gives clear purpose and sets expectation for what the compass measures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed compare button callback ref — spotlight was not targeting the button**
- **Found during:** Task 2 (end-to-end verification, user testing)
- **Issue:** Post-cal tour step 2 (compare button spotlight) was not positioning correctly because `document.querySelector` ran before the button mounted
- **Fix:** Added a `setCompareRef` callback ref prop to the Compare button; Compass.jsx now passes this ref down so CoachMark receives the live DOM node
- **Files modified:** `CompassV2/src/pages/Compass.jsx`
- **Verification:** User confirmed spotlight correctly targets the Compare button after fix
- **Committed in:** `6431e6b`

**2. [Rule 1 - Bug] Post-cal tour: help button step removed — step 4 targeted non-viable element**
- **Found during:** Task 2 (end-to-end verification, user testing)
- **Issue:** Help (?) button too small and outside Compass component tree; spotlight looked visually poor
- **Fix:** Removed step 4; tour is now 3 steps (spoke chart, compare button, back-to-library link)
- **Files modified:** `CompassV2/src/pages/Compass.jsx`
- **Verification:** 3-step tour confirmed working; no dead step
- **Committed in:** `6431e6b`

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs discovered during human verification)
**Impact on plan:** Both fixes required for functional correctness of the tour. No scope creep. Tour is tighter and more polished.

## Issues Encountered

- Spoke flip coach mark copy was ambiguous — users could interpret it as changing their stance preference rather than the visual axis. Fixed by rewriting the message to say "this changes the visual axis only."

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 66 complete: all 6 onboarding requirements (ONBOARD-01 through ONBOARD-06) satisfied
- Full onboarding system is live: CoachMark component, simplified welcome screen, post-cal 3-step tour, write-in hint, Library 2-step tour, Compare 4-step tour
- All tours are one-time-only, respect user dismissal, and reset cleanly when compass is reset
- No blockers for next phase

---
*Phase: 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity*
*Completed: 2026-03-06*
