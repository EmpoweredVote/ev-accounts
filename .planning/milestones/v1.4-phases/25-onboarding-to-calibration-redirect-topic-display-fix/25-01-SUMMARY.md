---
phase: 25-onboarding-to-calibration-redirect-topic-display-fix
plan: 01
subsystem: ui
tags: [react, calibration, onboarding, routing, url-params]

# Dependency graph
requires: []
provides:
  - "Onboarding now redirects to /results?calibrate=1 to auto-trigger CalibrationOverlay"
  - "Compass.jsx reads ?calibrate=1 URL param and calls handleStartCalibration() on mount"
  - "Library.jsx getVisibleTopics guarded against null category.topics"
affects: [onboarding, calibration, compass, library]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "URL param signaling between pages: ?calibrate=1 param triggers CalibrationOverlay auto-start in Compass.jsx, cleared with replace:true to preserve back-button behavior"

key-files:
  created: []
  modified:
    - CompassV2/src/pages/Onboarding.jsx
    - CompassV2/src/pages/Compass.jsx
    - CompassV2/src/pages/Library.jsx

key-decisions:
  - "Use ?calibrate=1 URL param (not localStorage flag) to signal calibration intent — cleaned from URL with replace:true so browser back button works correctly after entering calibration"
  - "Onboarding handleClose (X button) keeps navigate to /results without calibrate param — dismiss path should not force calibration"
  - "Topic card regression root cause: users never saw topic cards because calibration never auto-triggered after onboarding, leaving them on BelowThresholdChart with no topic pick UI"

patterns-established:
  - "URL param signaling for cross-page intent: ?calibrate=1 cleared with setSearchParams({}, {replace:true}) immediately after reading"

requirements-completed: [ONBOARD-01]

# Metrics
duration: 65min
completed: 2026-02-22
---

# Phase 25 Plan 01: Onboarding-to-Calibration Redirect & Topic Display Fix Summary

**Onboarding now routes to /results?calibrate=1 so the CalibrationOverlay auto-starts via URL param hook in Compass.jsx, giving new users immediate topic pick UI instead of a dead-end BelowThresholdChart**

## Performance

- **Duration:** 65 min
- **Started:** 2026-02-22T17:31:00Z
- **Completed:** 2026-02-22T18:36:30Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments
- Root cause diagnosed: after onboarding, `/results` showed `BelowThresholdChart` but calibration never auto-triggered for brand-new users (no selectedTopics → unansweredCompassTopics empty → needsCalibration false)
- Fixed redirect: Onboarding last-slide button now navigates to `/results?calibrate=1`
- Fixed Compass.jsx: reads `?calibrate=1` on mount, clears it with `replace:true`, calls `handleStartCalibration()` to open CalibrationOverlay welcome step
- Defensive fix: Library.jsx `getVisibleTopics` guards against null `category.topics` and null `short_title` to prevent potential TypeError on malformed API responses

## Task Commits

1. **Task 1: Diagnose and fix topic card display regression** - `fa273f0` (fix)

**Plan metadata:** pending

## Files Created/Modified
- `CompassV2/src/pages/Onboarding.jsx` - Last slide navigates to `/results?calibrate=1` instead of `/results`
- `CompassV2/src/pages/Compass.jsx` - Added `useSearchParams` import and effect to auto-trigger `handleStartCalibration()` when `?calibrate=1` is present; URL param cleared with `replace:true`
- `CompassV2/src/pages/Library.jsx` - `getVisibleTopics` now uses `(category.topics || [])` and `(t.short_title || "")` guards

## Decisions Made
- Used `?calibrate=1` URL param instead of localStorage flag for the calibration intent signal — params are one-shot and self-cleaning, while localStorage would require manual cleanup on every code path
- Cleared the param immediately with `setSearchParams({}, { replace: true })` so the back button navigates cleanly without re-triggering calibration
- `handleClose` (X button dismiss) in Onboarding still goes to `/results` without calibrate param — the dismiss path should not force users into calibration they already closed
- The topic card "regression" was actually a routing/UX issue: cards ARE rendered correctly in Library and CalibrationOverlay pick step, but users never saw CalibrationOverlay pick cards because calibration never auto-started for completely new users

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Defensive null guard in Library.jsx getVisibleTopics**
- **Found during:** Task 1 (investigation of category API response)
- **Issue:** Production API occasionally returns `category.topics = null` for categories with no linked topics; `null.filter()` would throw a TypeError and crash the Library page
- **Fix:** Changed `category.topics.filter(...)` to `(category.topics || []).filter(...)` and added `(t.short_title || "")` guard for safe toLowerCase call
- **Files modified:** `CompassV2/src/pages/Library.jsx`
- **Verification:** Build passes without errors
- **Committed in:** fa273f0 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (defensive null guard)
**Impact on plan:** Necessary correctness fix. No scope creep.

## Issues Encountered
- Initial hypothesis that topic cards were not rendering due to a code regression was incorrect — API data and rendering code are both functional. The actual issue was a routing dead-end: new users arriving at /results from onboarding saw BelowThresholdChart with no auto-triggered calibration, so they never reached the CalibrationOverlay pick step where topic selection cards appear.
- Production API returns topics with `start_phrase` (old field) but no `question_text`/`level` fields. Cards still render correctly using `short_title` as the display name; `getQuestionText` gracefully returns empty string.

## Next Phase Readiness
- Happy path tested: Onboarding → /results?calibrate=1 → CalibrationOverlay welcome → pick topics → answer → /results with radar chart
- Back button behavior preserved: URL param cleared with replace:true so hitting back from calibration does not re-trigger calibration
- No blockers for Phase 25 Plan 02 (if any)

## Self-Check: PASSED

- CompassV2/src/pages/Onboarding.jsx: FOUND (navigate to /results?calibrate=1 on line 106)
- CompassV2/src/pages/Compass.jsx: FOUND (useSearchParams + calibrate effect on lines 230, 317-326)
- CompassV2/src/pages/Library.jsx: FOUND (null guard on line 203)
- .planning/phases/25-onboarding-to-calibration-redirect-topic-display-fix/25-01-SUMMARY.md: FOUND
- commit fa273f0: FOUND (fix(25-01): fix onboarding redirect and topic card display regression)

---
*Phase: 25-onboarding-to-calibration-redirect-topic-display-fix*
*Completed: 2026-02-22*
