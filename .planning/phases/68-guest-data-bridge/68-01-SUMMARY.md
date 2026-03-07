---
phase: 68-guest-data-bridge
plan: 01
subsystem: ui
tags: [react, localstorage, url-fragment, compass, guest-data, cross-origin]

# Dependency graph
requires:
  - phase: 67-compass-api-integration
    provides: CompassContext with boot priority skeleton, CompassPreview CTA mode, fetchPoliticiansWithStances
provides:
  - URL fragment parser for #compass=BASE64 format (parseCompassFragment)
  - Guest compass localStorage cache utilities (saveGuestCompass, loadGuestCompass, clearGuestCompass, GUEST_COMPASS_KEY)
  - Answer format converter short_title keyed to API [{topic_id, value}] format (convertGuestAnswersToApiFormat)
  - CompassContext boot priority: fragment > API > localStorage cache > empty (CTA)
  - CTA link with ?return= param pointing back to current profile page
affects: [68-02-PLAN, CompassV2 fragment encoder, Essentials profile page flow]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - URL fragment as cross-origin data bridge (#compass=BASE64 format)
    - Guest compass localStorage cache keyed by GUEST_COMPASS_KEY constant
    - Boot priority waterfall: parse URL sync first, then async auth, then decide data source
    - Same-tab CTA navigation with ?return= for back-navigation flow

key-files:
  created: []
  modified:
    - essentials/src/lib/compass.js
    - essentials/src/contexts/CompassContext.jsx
    - essentials/src/components/CompassPreview.jsx

key-decisions:
  - "Fragment parsed synchronously BEFORE any async await — ensures it's available for the auth/data branching decision"
  - "Same-tab CTA navigation (no target=_blank) to enable the return banner flow in Plan 02"
  - "clearGuestCompass() called on logged-in path — clean separation: logged-in users always get API data only"
  - "Guest fragment data written to localStorage immediately after parse so future page loads use cache"
  - "No write-ins in fragment (optional display text, not essential for compass overlay)"

patterns-established:
  - "URL fragment bridge pattern: CompassV2 encodes, Essentials decodes — no shared localStorage needed"
  - "Boot waterfall: synchronous parse first, async operations second, decision based on results"

requirements-completed: [DATA-02]

# Metrics
duration: 15min
completed: 2026-03-07
---

# Phase 68 Plan 01: Guest Data Bridge (Essentials Side) Summary

**URL fragment bridge for cross-origin guest compass data: parse #compass=BASE64 into CompassContext with fragment > API > localStorage > empty boot priority and CTA link with ?return= param**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-07T20:15:00Z
- **Completed:** 2026-03-07T20:30:07Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added 6 new exports to compass.js: `parseCompassFragment`, `convertGuestAnswersToApiFormat`, `saveGuestCompass`, `loadGuestCompass`, `clearGuestCompass`, `GUEST_COMPASS_KEY`
- Rewrote CompassContext `loadAll()` with explicit boot priority waterfall (fragment > API > localStorage > empty)
- Guest compass data now persists across browser close via localStorage cache
- CTA "Take the Quiz" link sends users to CompassV2 with `?return=` pointing to their current profile page, enabling back-navigation in Plan 02

## Task Commits

Each task was committed atomically in the `essentials` git repo:

1. **Task 1: Add fragment parser/serializer utilities to compass.js** - `3c0980e` (feat)
2. **Task 2: Update CompassContext boot priority and CTA return link** - `ca987c7` (feat)

## Files Created/Modified
- `essentials/src/lib/compass.js` - Added GUEST_COMPASS_KEY constant and 5 utility functions for fragment parsing and localStorage guest cache management
- `essentials/src/contexts/CompassContext.jsx` - Rewrote loadAll() with fragment > API > localStorage > empty priority; imports 5 new utilities; clearGuestCompass on login
- `essentials/src/components/CompassPreview.jsx` - Added useLocation import, returnUrl + ctaHref construction, updated CTA link href and removed target="_blank"

## Decisions Made
- Fragment parsed synchronously before any async operations — this ensures the fragment value is captured before `await` yields control, and the URL is clean before React renders
- Same-tab CTA (no `target="_blank"`) — necessary for the `?return=` flow since Plan 02 will render a return banner on CompassV2 that links back; new-tab would break the back-navigation UX
- `clearGuestCompass()` on logged-in path — logged-in users always get fresh API data; stale guest cache could confuse state if user logs in after guest quiz
- Guest fragment cached immediately — ensures `#compass=...` URL (which gets stripped) leaves behind a localStorage record for page refreshes and future visits

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- `essentials/` is a separate git repository nested inside the workspace. Commits were made using `git -C /path/to/essentials` rather than from the workspace root. This is expected behavior for the project structure.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Essentials side of the bridge is complete
- Plan 02 (CompassV2 encoder) can now add the `serializeForFragment()` function and the `?return=` redirect handling on the CompassV2 side
- The fragment format contract (`#compass=BASE64({"a":{...},"s":[...]})`) is now implemented on the Essentials decoder side — Plan 02 must produce exactly this format

---
*Phase: 68-guest-data-bridge*
*Completed: 2026-03-07*
