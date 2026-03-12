---
phase: 80-ev-ui-verdict-badge
plan: 01
subsystem: ui
tags: [react, ev-ui, npm-registry, component-library, verdict-badge]

# Dependency graph
requires:
  - phase: 78-visual-refresh
    provides: Amber/cyan verdict badge color pair design decision
  - phase: 79-backend-verdict-endpoints
    provides: Verdict data model (agreed/disagreed enum values)
provides:
  - ev-ui v0.1.42 published to GitHub npm registry with StanceAccordion exported
  - StanceAccordion component with verdictsByTopic prop and inline verdict badges
  - apiUrl prop replacing VITE_API_URL for library portability
  - essentials CompassCard importing StanceAccordion from ev-ui (local copy deleted)
affects:
  - 81-profile-verdict-integration (consumes verdictsByTopic prop from CompassContext)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inline styles for badge rendering in ev-ui — avoids Tailwind dependency in library; consumer provides Tailwind runtime"
    - "apiUrl prop pattern — library components receive API base URL via prop instead of env var"

key-files:
  created:
    - ev-ui/src/StanceAccordion.jsx
    - ev-ui/src/Favicon.jsx
  modified:
    - ev-ui/src/index.js
    - ev-ui/package.json
    - essentials/src/components/CompassCard.jsx
    - essentials/package.json
    - essentials/package-lock.json

key-decisions:
  - "Inline styles (not Tailwind) for verdict badge spans — ensures no Tailwind dependency in ev-ui library; Tailwind classes on other elements remain as plain strings bundled by tsup"
  - "apiUrl prop with default 'https://api.empowered.vote' replaces VITE_API_URL — makes component usable in any consumer without build env dependency"
  - "Favicon.jsx kept as private implementation detail in ev-ui — not exported from index.js"

patterns-established:
  - "Pattern: Library components use apiUrl prop, not import.meta.env, for API base URL"
  - "Pattern: Badge/pill styling uses inline styles in ev-ui to avoid Tailwind coupling"

requirements-completed:
  - PROF-03

# Metrics
duration: 3min
completed: 2026-03-12
---

# Phase 80 Plan 01: ev-ui Verdict Badge Summary

**StanceAccordion migrated to ev-ui v0.1.42 with verdictsByTopic prop rendering cyan/amber inline verdict badges; essentials updated to import from library**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-12T14:01:22Z
- **Completed:** 2026-03-12T14:04:11Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Migrated StanceAccordion from essentials into ev-ui shared library with new `verdictsByTopic` and `apiUrl` props
- Published ev-ui v0.1.42 to GitHub npm registry with StanceAccordion exported
- Updated essentials CompassCard to import from `@chrisandrewsedu/ev-ui`; local copies of StanceAccordion.jsx and Favicon.jsx deleted

## Task Commits

Each task was committed atomically:

1. **Task 1: Create StanceAccordion.jsx and Favicon.jsx in ev-ui** - `874d870` (feat) — in ev-ui repo
2. **Task 2: Export StanceAccordion, bump version, build and publish** - `56d5bd0` (feat) — in ev-ui repo
3. **Task 3: Update essentials CompassCard to import from ev-ui** - `d524a5f` (feat) — in essentials repo

**Plan metadata:** (docs commit — workspace-level planning files)

## Files Created/Modified

- `ev-ui/src/StanceAccordion.jsx` - StanceAccordion with verdictsByTopic, apiUrl, inline verdict badge rendering
- `ev-ui/src/Favicon.jsx` - Favicon sub-component (private impl detail, not exported)
- `ev-ui/src/index.js` - Added StanceAccordion export
- `ev-ui/package.json` - Version bumped from 0.1.41 to 0.1.42
- `essentials/src/components/CompassCard.jsx` - Import changed to ev-ui, apiUrl prop added to both call sites
- `essentials/package.json` - Updated @chrisandrewsedu/ev-ui to 0.1.42
- `essentials/src/components/StanceAccordion.jsx` - DELETED (now in ev-ui)
- `essentials/src/components/Favicon.jsx` - DELETED (now in ev-ui)

## Decisions Made

- Used inline styles (not Tailwind classes) for verdict badge spans — this ensures no Tailwind dependency leaks into ev-ui. The existing Tailwind class names on other elements in the component are bundled as plain strings by tsup; the consumer (essentials) provides the Tailwind runtime.
- `apiUrl` prop defaults to `'https://api.empowered.vote'` — maintains correct behavior when not passed; essentials passes `import.meta.env.VITE_API_URL` explicitly at call sites.
- `Favicon.jsx` is not exported from ev-ui index.js — it's a private implementation detail of StanceAccordion.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The ev-ui and essentials directories each have their own git repositories, requiring commits to each individually rather than the workspace-level repo. This is expected for this multi-repo workspace.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ev-ui v0.1.42 is live on GitHub npm registry — Phase 81 can immediately consume `verdictsByTopic` prop
- essentials already imports from ev-ui v0.1.42 — Phase 81 only needs to wire `verdictsByTopic` from CompassContext at the CompassCard call site
- The prop contract is established: `verdictsByTopic: Record<string, 'agreed' | 'disagreed'> | undefined`

## Self-Check: PASSED

- ev-ui/src/StanceAccordion.jsx: FOUND
- ev-ui/src/Favicon.jsx: FOUND
- SUMMARY.md: FOUND
- essentials/src/components/StanceAccordion.jsx: CONFIRMED DELETED
- essentials/src/components/Favicon.jsx: CONFIRMED DELETED
- ev-ui commit 874d870: FOUND
- ev-ui commit 56d5bd0: FOUND
- essentials commit d524a5f: FOUND

---
*Phase: 80-ev-ui-verdict-badge*
*Completed: 2026-03-12*
