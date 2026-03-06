# Phase 65: Fix Compass Page Refresh Losing Onboarding State - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix page refresh losing onboarding/calibration state in CompassV2. Users who refresh mid-calibration, mid-resume-mode, or mid-quiz should seamlessly return to their exact position. Also fix the topics-loading race condition that causes the CalibrationOverlay to initialize with wrong state.

</domain>

<decisions>
## Implementation Decisions

### Recovery behavior
- Resume at exact question index on refresh (calibration_progress already stores step, pickedTopics, currentIndex — just needs race condition fixed)
- Seamless resume — no toast or "picking up where you left off" message
- If all topics are answered and user refreshes on the "complete" celebration screen, skip celebration and go straight to compass
- Resume-mode flow (user adding more topics to existing compass) must also survive refresh — bring them back to the same resume-mode overlay at the same question

### Loading race condition
- Gate CalibrationOverlay initialization on topics array being non-empty — don't initialize until topics have loaded from API
- Show branded EV coral loading spinner while topics are loading (centered in overlay area)
- Prevent needsCalibration flicker: treat calibration state as "pending" until topics load — don't render compass or overlay until we can accurately compute needsCalibration
- If topics API fails entirely, show friendly error message ("Couldn't load topics") with retry button — don't proceed with broken state

### Quiz page persistence
- Persist currentIndex to localStorage so /quiz survives refresh at the same question
- Also persist quiz mode (curated vs full) alongside currentIndex
- Clear quiz progress on both quiz completion AND compass reset (Clear Compass in profile menu)
- If saved quiz state doesn't match current topic data (e.g., curated topics changed on server), clear saved state and restart quiz from beginning

### Edge cases
- No expiry on calibration_progress — resume indefinitely, even days later
- If selectedTopics in localStorage reference topic IDs that no longer exist (admin deleted topic), filter them out silently; if this drops below 3 topics, trigger calibration to pick more
- Don't add multi-tab handling — last-write-wins is acceptable

### Claude's Discretion
- Whether HelpGuard needs fixing for /quiz redirect (check if /quiz is already in GUARD_BYPASS)
- Exact implementation of the topics-loading gate (useEffect dependency, loading state variable, etc.)
- Loading spinner component choice (reuse existing or lightweight inline)
- How to structure the "pending" calibration state to prevent flicker

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches for the fix. The key principle is: refresh should be invisible to the user. They should never notice they refreshed.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CalibrationOverlay` already saves `calibration_progress` to localStorage (step, pickedTopics, currentIndex) — persistence infrastructure exists, just has a race condition
- `CompassContext` already persists selectedTopics, answers, writeIns, invertedSpokes to localStorage — these all survive refresh correctly
- `Layout.jsx` handleClearCompass already clears all localStorage keys — quiz progress cleanup should be added here

### Established Patterns
- State initialization from localStorage uses lazy initializers: `useState(() => JSON.parse(localStorage.getItem(...)))` — quiz persistence should follow this pattern
- `calibration_completed` and `calibration_skipped` localStorage flags gate the HelpGuard redirect — well-established pattern
- Topics are fetched via `refreshData()` in CompassContext on mount — async, typically <1s

### Integration Points
- `Compass.jsx` lines 257-259: `calibrationActive` initialized from localStorage — needs to wait for topics before computing `resumeMode`
- `CalibrationOverlay.jsx` line 255-265: init effect fires with stale `resumeMode` because `initializedRef.current` is set before topics load — core bug location
- `CalibrationOverlay.jsx` line 271: `resumeMode` sessions skip saving progress — this needs to change so resume-mode progress also persists
- `Quiz.jsx` line 185: `currentIndex` is pure React state (not persisted) — add localStorage persistence here
- `Compass.jsx` lines 267-268: `needsCalibration` computation depends on topics being loaded — needs a "pending" state

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 65-fix-compass-page-refresh-losing-onboarding-state*
*Context gathered: 2026-03-05*
