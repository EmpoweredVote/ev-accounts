---
phase: 04-compass-ux-enhancements
plan: 02
subsystem: ui
tags: [react, localstorage, prng, hash, stance-randomization, compass]

# Dependency graph
requires: []
provides:
  - Seeded stance randomization in CompassContext using guestId + topicId djb2 hash
  - getOrCreateGuestId() helper persisting guestId in localStorage across sessions
  - shouldFlip(guestId, topicId) deterministic boolean hash replacing Math.random()
  - initRandomInversions updated to accept topic objects (id + short_title)
  - Quiz.jsx calls initRandomInversions in both curated and full modes
affects: [04-03, 04-04]

# Tech tracking
tech-stack:
  added: []
  patterns: [djb2-style unsigned 32-bit hash for per-user deterministic randomization, localStorage guest ID for persistent identity without auth]

key-files:
  created: []
  modified:
    - CompassV2/src/components/CompassContext.jsx
    - CompassV2/src/pages/Quiz.jsx

key-decisions:
  - "QUIZ-08: initRandomInversions accepts topic objects (id + short_title) not string arrays — enables hash-seeding on topic.id"
  - "guestId stored in localStorage and NOT cleared on logout — stance order persists across login/logout cycles on same browser"
  - "shouldFlip uses djb2-style hash: hash = ((hash * 31) + charCode) >>> 0, returns (hash & 1) === 1 for ~50% flip rate"
  - "Full mode now also receives stance inversions — removed mode !== curated guard in Quiz.jsx"

patterns-established:
  - "Seeded PRNG pattern: guestId (localStorage UUID) + entity ID → deterministic binary decision via hash"
  - "Existing topics guard (hasExisting check) prevents re-randomizing topics that already have an inversion state"

requirements-completed: [QUIZ-08]

# Metrics
duration: 2min
completed: 2026-02-18
---

# Phase 4 Plan 02: Seeded Stance Randomization Summary

**Replaced Math.random() stance flipping with a djb2-style hash of localStorage guestId + topicId, making stance inversion deterministic and stable per user per topic across all sessions and page reloads**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-18T01:32:19Z
- **Completed:** 2026-02-18T01:34:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Deterministic stance randomization: same guest always sees same flip pattern, no matter how many times they reload
- guestId UUID generated on first visit and persisted in localStorage — survives logout, survives registration
- Full quiz mode now also applies stance inversions (was previously curated-only due to a mode guard)
- Build verified clean after both changes

## Task Commits

Each task was committed atomically (CompassV2 repo):

1. **Task 1: Implement seeded stance randomization in CompassContext** - `0123118` (feat)
2. **Task 2: Update Quiz.jsx to call initRandomInversions with topic objects in both modes** - `277521f` (feat)

**Plan metadata:** (workspace repo docs commit — see final commit below)

## Files Created/Modified
- `CompassV2/src/components/CompassContext.jsx` - Added getOrCreateGuestId(), shouldFlip(); rewrote initRandomInversions to use hash instead of Math.random()
- `CompassV2/src/pages/Quiz.jsx` - Removed curated-mode guard; passes topic objects in both modes

## Decisions Made
- `initRandomInversions` signature changed from `(shortTitles: string[])` to `(topicsArray: {id, short_title}[])` — topic objects are required to access the numeric `id` for the hash seed
- guestId intentionally NOT cleared during logout (Layout.jsx logout flow unchanged) — returning users on same browser keep their stance order
- Full mode uses `topics` (all active topics) for the inversion seed call, since there are no selectedTopics in full mode

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- CompassV2 is its own git repository (not tracked by the workspace root `.planning` repo). Commits were made with `git -C /path/to/CompassV2` — behavior identical, just needed to target the correct repo.

## Next Phase Readiness
- Stance randomization is now stable; 04-03 and 04-04 can build on top without concerns about flip instability
- guestId infrastructure available for any future per-user personalization that doesn't require auth

---
*Phase: 04-compass-ux-enhancements*
*Completed: 2026-02-18*
