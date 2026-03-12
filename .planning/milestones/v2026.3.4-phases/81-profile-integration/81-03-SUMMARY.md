---
phase: 81-profile-integration
plan: "03"
subsystem: ui
tags: [react, localStorage, url-fragment, compass, verdicts, context]

# Dependency graph
requires:
  - phase: 81-01
    provides: StanceAccordion verdictsByQuote prop in ev-ui
  - phase: 81-02
    provides: buildVerdictFragment emitting v key in EV-ReadRank URL fragment

provides:
  - parseCompassFragment handles verdict-only fragments (v key without a/s)
  - guest verdict localStorage helpers (saveGuestVerdicts, loadGuestVerdicts, clearGuestVerdicts)
  - CompassContext exposes verdicts state field from fragment > localStorage > empty
  - CompassCard passes verdictsByQuote={verdicts} to both StanceAccordion call sites

affects:
  - phase-82-logged-in-sync (will consume verdicts state for API sync)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Verdict priority chain: API (deferred) > fragment.v > localStorage guestVerdicts > {}"
    - "Fragment permissiveness: parseCompassFragment returns non-null for verdict-only fragments (answers=null)"
    - "Parallel bridges: compass bridge and verdict bridge share same URL fragment but managed independently in context"

key-files:
  created: []
  modified:
    - essentials/src/lib/compass.js
    - essentials/src/contexts/CompassContext.jsx
    - essentials/src/components/CompassCard.jsx

key-decisions:
  - "parseCompassFragment returns non-null for verdict-only fragments — answers field is nullable, not required"
  - "Verdict state is independent of compass answers — user may have verdicts with no compass data"
  - "fragment.answers null check added to guard convertGuestAnswersToApiFormat call in loadAll()"
  - "Phase 82 deferred: clearGuestVerdicts on auth.ok is the only logged-in action; API fetch skipped"

patterns-established:
  - "Nullable fragment.answers: call convertGuestAnswersToApiFormat only when fragment.answers !== null"
  - "Parallel priority blocks: compass priority block and verdict priority block are independent in loadAll()"

requirements-completed:
  - VERD-06
  - PROF-01
  - PROF-02

# Metrics
duration: 12min
completed: 2026-03-12
---

# Phase 81 Plan 03: Profile Integration - Essentials Verdict Wiring Summary

**Guest verdict URL fragment parsed and cached in Essentials: CompassContext exposes verdicts, StanceAccordion receives verdictsByQuote at both call sites to render agreed/disagreed badges**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-12T17:23:34Z
- **Completed:** 2026-03-12T17:35:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Updated `parseCompassFragment` to return non-null for verdict-only fragments — `answers` is nullable, `verdicts` always extracted from `v` key
- Added `GUEST_VERDICTS_KEY`, `saveGuestVerdicts`, `loadGuestVerdicts`, `clearGuestVerdicts` helpers to `compass.js` mirroring the existing guest compass pattern
- Wired `verdicts` state through `CompassContext` with correct priority chain: clears on auth, saves fragment on guest with verdicts, loads localStorage fallback
- Added `fragment.answers !== null` guard to prevent crash when verdict-only fragment arrives (no compass data)
- `CompassCard` now passes `verdictsByQuote={verdicts}` to both `StanceAccordion` instances (logged-in path and guest path)

## Task Commits

Each task was committed atomically (in `essentials/` repo):

1. **Task 1: Add guest verdict helpers and update parseCompassFragment** - `a836cb0` (feat)
2. **Task 2: Add verdicts state to CompassContext and pass verdictsByQuote through CompassCard** - `8041c15` (feat)

**Plan metadata:** `c34d536` (docs: complete Essentials verdict wiring plan)

## Files Created/Modified
- `essentials/src/lib/compass.js` - Updated parseCompassFragment (verdict-only support), added GUEST_VERDICTS_KEY + saveGuestVerdicts/loadGuestVerdicts/clearGuestVerdicts
- `essentials/src/contexts/CompassContext.jsx` - Added verdicts state, verdict priority block in loadAll(), fragment.answers null guard, verdicts in useMemo
- `essentials/src/components/CompassCard.jsx` - Added verdicts to useCompass() destructure, verdictsByQuote={verdicts} on both StanceAccordion call sites

## Decisions Made
- `parseCompassFragment` is now permissive: returns non-null when `v` key has entries even if `a`/`s` are absent. The `answers` field is nullable (`null` when no compass data).
- `fragment.answers !== null` guard added to the `else if (fragment)` branch — prevents `convertGuestAnswersToApiFormat` from crashing on a verdict-only fragment.
- Verdict priority block is independent of the compass priority block in `loadAll()` — they run sequentially and are not nested.
- Phase 82 deferred: on `authRes.ok`, the only verdict action is `clearGuestVerdicts()` — no API fetch of stored verdicts.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- `essentials/` is a separate git repo from the workspace root (has its own `.git/`). Commits were made with `cd essentials && git add ... && git commit` rather than from workspace root. This is expected behavior per the workspace structure.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Guest verdict path is now end-to-end complete: Read & Rank session -> buildVerdictFragment -> URL fragment -> parseCompassFragment -> guestVerdicts localStorage -> CompassContext.verdicts -> StanceAccordion.verdictsByQuote -> agreed/disagreed badges
- Phase 82 (logged-in sync) can now implement API fetch of verdicts and merge them into CompassContext.verdicts — the hook is already in place (the `authRes.ok` branch currently only calls `clearGuestVerdicts`)
- No blockers for next phase

## Self-Check: PASSED

- FOUND: essentials/src/lib/compass.js
- FOUND: essentials/src/contexts/CompassContext.jsx
- FOUND: essentials/src/components/CompassCard.jsx
- FOUND: .planning/phases/81-profile-integration/81-03-SUMMARY.md
- FOUND commit: a836cb0 (Task 1)
- FOUND commit: 8041c15 (Task 2)
- FOUND commit: c34d536 (metadata)

---
*Phase: 81-profile-integration*
*Completed: 2026-03-12*
