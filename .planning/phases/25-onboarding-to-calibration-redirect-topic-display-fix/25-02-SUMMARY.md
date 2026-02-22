---
phase: 25-onboarding-to-calibration-redirect-topic-display-fix
plan: 02
subsystem: ui
tags: [react, calibration, onboarding, routing, state-management]

# Dependency graph
requires:
  - phase: 25-onboarding-to-calibration-redirect-topic-display-fix-01
    provides: "?calibrate=1 URL param mechanism for fresh-from-onboarding flow"
provides:
  - "needsCalibration condition extended to auto-trigger CalibrationOverlay for users with zero selected topics (returning uncalibrated users)"
affects: [onboarding, calibration, compass]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dual-path calibration trigger: ?calibrate=1 URL param for fresh-from-onboarding; needsCalibration=true for returning uncalibrated users with zero selected topics"

key-files:
  created: []
  modified:
    - CompassV2/src/pages/Compass.jsx

key-decisions:
  - "Expand needsCalibration to OR-in selectedTopics.length === 0 — covers returning users who arrive at /results directly without the ?calibrate=1 param"
  - "calibration_skipped and calibration_completed flags still gate the trigger — no regression for users who explicitly skipped or already finished calibration"

patterns-established:
  - "Dual-path calibration entry: URL param for direct post-onboarding handoff, state-derived condition for returning users"

requirements-completed: [ONBOARD-02, ONBOARD-03, ONBOARD-04]

# Metrics
duration: 7min
completed: 2026-02-22
---

# Phase 25 Plan 02: Onboarding-to-Calibration Redirect & Topic Display Fix Summary

**needsCalibration condition expanded to OR-in selectedTopics.length === 0, ensuring CalibrationOverlay auto-triggers for returning uncalibrated users who arrive at /results without the ?calibrate=1 URL param**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-22T18:39:54Z
- **Completed:** 2026-02-22T18:45:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Diagnosed that 25-01's ?calibrate=1 mechanism handles fresh-from-onboarding users, but returning users who navigate directly to /results without the param were left seeing BelowThresholdChart manually
- Extended needsCalibration condition: `(unansweredCompassTopics.length > 0 || selectedTopics.length === 0)` replaces bare `unansweredCompassTopics.length > 0`
- Returning uncalibrated users (0 topics, no skip/complete flags) now see CalibrationOverlay welcome step automatically on /results
- All existing guards respected: calibration_skipped and calibration_completed prevent re-triggering for users who already engaged with calibration
- Build verified: npm run build passes without errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix onboarding redirect to trigger calibration flow** - `673d9e5` (fix) — in CompassV2 repo

**Plan metadata:** pending

## Files Created/Modified
- `CompassV2/src/pages/Compass.jsx` - Expanded needsCalibration derivation to include selectedTopics.length === 0 condition

## Decisions Made
- The ?calibrate=1 URL param approach from 25-01 already covers the fresh-from-onboarding case. The 25-02 fix adds coverage for returning users who bypass the URL param path entirely.
- Used OR condition (`|| selectedTopics.length === 0`) to preserve existing unanswered-topics trigger while adding the new zero-topics trigger.
- calibration_completed flag still correctly prevents re-triggering when a user has completed calibration and later drops below 3 topics (they see BelowThresholdChart instead, which is the intended behavior).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- The 25-02 plan was written before 25-01 was executed, proposing the needsCalibration fix as the primary mechanism. However 25-01 implemented a different (URL param-based) approach that fully resolves the fresh-from-onboarding case. The 25-02 fix is complementary, covering the returning uncalibrated user scenario — both mechanisms together provide complete coverage.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- ONBOARD-02, ONBOARD-03, ONBOARD-04 requirements satisfied
- Happy path fully covered: fresh user (onboarding → ?calibrate=1 → CalibrationOverlay), returning user (direct /results → CalibrationOverlay via needsCalibration)
- Phase 25 complete — all 4 ONBOARD requirements satisfied across 25-01 and 25-02

## Self-Check: PASSED

- CompassV2/src/pages/Compass.jsx: FOUND (needsCalibration expanded with selectedTopics.length === 0 condition)
- .planning/phases/25-onboarding-to-calibration-redirect-topic-display-fix/25-02-SUMMARY.md: FOUND
- commit 673d9e5: FOUND (fix(25-02): auto-trigger calibration for fresh users with no selected topics, in CompassV2 repo)
- REQUIREMENTS.md: ONBOARD-02, ONBOARD-03, ONBOARD-04 marked complete
- ROADMAP.md: Phase 25 updated to 2/2 plans complete

---
*Phase: 25-onboarding-to-calibration-redirect-topic-display-fix*
*Completed: 2026-02-22*
