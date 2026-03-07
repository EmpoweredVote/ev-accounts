---
phase: 68-guest-data-bridge
plan: 02
subsystem: ui
tags: [react, url-fragment, compass, guest-data, cross-origin, return-banner, compare-panel]

# Dependency graph
requires:
  - phase: 68-guest-data-bridge/01
    provides: Fragment parser/decoder on Essentials side, CTA ?return= param pattern, GUEST_COMPASS_KEY localStorage cache
provides:
  - serializeCompassFragment() utility — encodes CompassV2 localStorage state into #compass=BASE64 format
  - ReturnBanner component — persistent banner when ?return= param present, links back to Essentials with compass fragment
  - ComparePanel "View full profile on Essentials" link — outbound link with compass fragment appended
  - Layout integration — ReturnBanner rendered above SiteHeader (fixed position, z-60 with spacer div)
affects: [human-verify-68-02, full bidirectional guest bridge complete]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - sessionStorage for cross-page banner persistence (survives HelpGuard redirects)
    - Fixed-position banner above CalibrationOverlay (z-[60] vs z-50)
    - serializeCompassFragment reads directly from localStorage for URL-safe cross-origin data
    - VITE_ESSENTIALS_URL env var with hardcoded fallback for Essentials base URL

key-files:
  created:
    - CompassV2/src/components/ReturnBanner.jsx
  modified:
    - CompassV2/src/components/CompassContext.jsx
    - CompassV2/src/components/Layout.jsx
    - CompassV2/src/components/ComparePanel.jsx

key-decisions:
  - "ReturnBanner uses sessionStorage (not state/localStorage) — persists across React Router navigations and HelpGuard redirects within the session"
  - "Fixed position banner (z-[60]) rather than document-flow div — avoids CalibrationOverlay (z-50) covering the banner"
  - "serializeCompassFragment includes invertedSpokes (i key) in addition to answers (a) and selectedTopics (s) — complete state transfer"
  - "ComparePanel Essentials link uses same-tab navigation (no target=_blank) — guest navigates TO Essentials, expected destination"
  - "VITE_ESSENTIALS_URL env var with hardcoded fallback — no env var config needed for existing deploys"

patterns-established:
  - "Cross-origin fragment encode: btoa(JSON.stringify({a, s, i})) — matches Essentials decoder contract"
  - "sessionStorage banner persistence: read ?return= param once, store in sessionStorage, dismiss clears both"

requirements-completed: [DATA-02]

# Metrics
duration: 20min
completed: 2026-03-07
---

# Phase 68 Plan 02: CompassV2 Outbound Bridge Summary

**ReturnBanner component and serializeCompassFragment encoder complete the bidirectional guest bridge: CompassV2 serializes answers into #compass=BASE64 fragments and shows a persistent return banner when arriving from Essentials CTA**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-03-07T20:30:00Z
- **Completed:** 2026-03-07T20:50:00Z
- **Tasks:** 2 auto tasks complete (Task 3 is human-verify checkpoint)
- **Files modified:** 4

## Accomplishments
- Added `serializeCompassFragment()` to CompassContext.jsx — encodes answers + selectedTopics + invertedSpokes into `#compass=BASE64` format matching Essentials decoder
- Created `ReturnBanner.jsx` — thin persistent banner (fixed, z-60) showing when `?return=` param present, uses sessionStorage for cross-navigation persistence, dismissible with X button
- Updated `Layout.jsx` — imports and renders `<ReturnBanner />` above `<SiteHeader>`
- Updated `ComparePanel.jsx` — "View full profile on Essentials" link with compass fragment, VITE_ESSENTIALS_URL env var support

## Task Commits

Each task was committed atomically in the CompassV2 git repository:

1. **Task 1: Add serializeCompassFragment utility and ReturnBanner component** - `01534d4` (feat)
2. **Task 2: Wire ReturnBanner into Layout and add Essentials profile link on ComparePanel** - `7ac670b` (feat)
3. **Fix: Resolve guest compass bridge verification issues** - `815fc10` (fix)

## Files Created/Modified
- `CompassV2/src/components/ReturnBanner.jsx` - New component: persistent banner with sessionStorage persistence, dismiss clears session key, return link appends compass fragment
- `CompassV2/src/components/CompassContext.jsx` - Added `serializeCompassFragment()` export with invertedSpokes included in payload
- `CompassV2/src/components/Layout.jsx` - Added ReturnBanner import and rendering above SiteHeader
- `CompassV2/src/components/ComparePanel.jsx` - Added ESSENTIALS_URL constant, serializeCompassFragment import, "View full profile" link below InlinePoliticianPicker

## Decisions Made
- **sessionStorage for banner URL** — survives React Router navigations and HelpGuard redirects within a browser session, clears on tab close. Simple and correct for the use case.
- **Fixed position banner (z-[60])** — CalibrationOverlay uses z-50; banner must float above it. Added spacer `<div className="h-9" />` to prevent content being hidden behind the fixed banner.
- **Includes invertedSpokes in fragment** — serializeCompassFragment encodes `{a, s, i}` (not just `{a, s}` as in the initial spec), because spoke inversions are part of the complete compass view. Essentials decoder already handles optional `i` key.
- **Same-tab navigation for "View full profile"** — guest is navigating TO Essentials as the destination; no need for a new tab

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ReturnBanner uses sessionStorage instead of component state for URL persistence**
- **Found during:** Task 1 verification
- **Issue:** Plan spec stored returnUrl in useState — this loses the value on React Router navigations (component remounts) and HelpGuard redirects
- **Fix:** Store `?return=` in sessionStorage under SESSION_KEY constant on first render; read sessionStorage as fallback on subsequent mounts
- **Files modified:** CompassV2/src/components/ReturnBanner.jsx
- **Verification:** Banner persists across page navigations within CompassV2
- **Committed in:** 815fc10 (fix commit)

**2. [Rule 1 - Bug] Fixed position banner requires spacer div to prevent content overlap**
- **Found during:** Task 1 verification
- **Issue:** Plan spec used document-flow div (non-fixed) but CalibrationOverlay (z-50) would cover it; switching to fixed position required a spacer to avoid hiding content behind the banner
- **Fix:** Used `position: fixed; z-[60]` for the banner div, added sibling `<div className="h-9" />` spacer
- **Files modified:** CompassV2/src/components/ReturnBanner.jsx
- **Committed in:** 815fc10 (fix commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug)
**Impact on plan:** Both fixes required for correct cross-navigation behavior and visual correctness. No scope creep.

## Issues Encountered
- `CompassV2/` is a separate git repository nested inside the workspace. Commits were made using `git -C /path/to/CompassV2` rather than from the workspace root. This is expected behavior for the project structure.

## User Setup Required
None - no external service configuration required. VITE_ESSENTIALS_URL defaults to `https://essentials.empowered.vote`.

## Next Phase Readiness
- Both sides of the guest compass bridge are complete:
  - Essentials: fragment parser + localStorage cache + CTA with ?return= (Plan 01)
  - CompassV2: serializeCompassFragment encoder + ReturnBanner + ComparePanel outbound link (Plan 02)
- Human verification (Task 3 checkpoint) required to confirm the full bidirectional flow works end-to-end
- After human verification, Phase 68 is complete

---
*Phase: 68-guest-data-bridge*
*Completed: 2026-03-07*
