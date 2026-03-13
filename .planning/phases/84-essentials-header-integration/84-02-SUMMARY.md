---
phase: 84-essentials-header-integration
plan: 02
subsystem: ui
tags: [react, ev-ui, SiteHeader, Layout, auth, essentials]

requires:
  - phase: 84-01
    provides: Layout component with auth-aware SiteHeader via CompassContext

provides:
  - All 5 Essentials pages render SiteHeader via Layout (no standalone Header/SiteHeader)
  - AuthIndicator floating bubble removed from App.jsx
  - Profile, LegislativeRecord, CandidateProfile cleaned of dead navItems/ctaButton vars

affects: [essentials deployment, ev-ui consumers]

tech-stack:
  added: []
  patterns:
    - "Page-level Layout wrapping: pages import { Layout } from '../components/Layout' and wrap return JSX"
    - "Named export pattern: Layout uses named export, imported with destructuring"

key-files:
  created: []
  modified:
    - essentials/src/App.jsx
    - essentials/src/pages/Landing.jsx
    - essentials/src/pages/Results.jsx
    - essentials/src/pages/Profile.jsx
    - essentials/src/pages/LegislativeRecord.jsx
    - essentials/src/pages/CandidateProfile.jsx

key-decisions:
  - "Layout uses named export (export function Layout), imported via { Layout } destructuring in all pages"
  - "Closing </Layout> tag placed after outer page div and before end of return, keeping min-h-screen div as Layout child"

patterns-established:
  - "Layout wrapping pattern: return (<Layout><div className='min-h-screen ...'>...</div></Layout>)"

requirements-completed: [ESS-01, ESS-02, ESS-03, ESS-04]

duration: 15min
completed: 2026-03-13
---

# Phase 84 Plan 02: Essentials Header Integration (Wire Layout) Summary

**Layout component wired into all 5 Essentials pages; AuthIndicator floating bubble removed; dead navItems/ctaButton vars cleaned from 3 pages; build confirmed passing**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-13T00:25:00Z
- **Completed:** 2026-03-13T00:40:00Z
- **Tasks:** 2 of 3 (Task 3 is checkpoint:human-verify — awaiting user)
- **Files modified:** 6

## Accomplishments
- Removed AuthIndicator floating bubble from App.jsx (import + fixed div wrapper deleted)
- Added `{ Layout }` import and wrapping to all 5 pages: Landing, Results, Profile, LegislativeRecord, CandidateProfile
- Removed Header imports and dead navItems/ctaButton config from Profile, LegislativeRecord, and CandidateProfile
- Removed SiteHeader direct usage from Landing and Results
- Build passes with 67 modules, 0 errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove AuthIndicator from App.jsx** - `4097dba` (feat)
2. **Task 2: Wrap all pages in Layout** - `13da69c` (feat)

## Files Created/Modified
- `essentials/src/App.jsx` - Removed AuthIndicator import and fixed-position div wrapper
- `essentials/src/pages/Landing.jsx` - Replaced SiteHeader with Layout wrapping
- `essentials/src/pages/Results.jsx` - Replaced SiteHeader with Layout wrapping
- `essentials/src/pages/Profile.jsx` - Replaced Header + navItems/ctaButton with Layout wrapping
- `essentials/src/pages/LegislativeRecord.jsx` - Replaced Header + navItems/ctaButton with Layout wrapping
- `essentials/src/pages/CandidateProfile.jsx` - Replaced Header + navItems/ctaButton with Layout wrapping

## Decisions Made
- Layout uses named export `export function Layout` (not default), so all pages import with `{ Layout }` destructuring
- The outer `<div className="min-h-screen ...">` is kept as the direct child of `<Layout>` to preserve existing page structure

## Deviations from Plan

None — plan executed exactly as written. The only discovery was that Layout uses a named export rather than default (plan said `import Layout`, actual file uses `export function Layout`). Adjusted import syntax to `{ Layout }` which is correct.

## Issues Encountered
- Minor: Layout component uses named export (`export function Layout`) not default export. Plan specified `import Layout from '../components/Layout'` but the actual file required `import { Layout } from '../components/Layout'`. Fixed automatically without impact.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 5 pages wired to Layout and building successfully
- Checkpoint awaiting: user must run `npm run dev` in essentials/ and visually verify SiteHeader appears on all pages, profile dropdown shows correct logged-in/logged-out state, and floating AuthIndicator bubble is gone

---
*Phase: 84-essentials-header-integration*
*Completed: 2026-03-13*

## Self-Check: PASSED
- essentials/src/App.jsx: modified (AuthIndicator removed)
- essentials/src/pages/Landing.jsx: modified (Layout import added)
- essentials/src/pages/Results.jsx: modified (Layout import added)
- essentials/src/pages/Profile.jsx: modified (Layout import added)
- essentials/src/pages/LegislativeRecord.jsx: modified (Layout import added)
- essentials/src/pages/CandidateProfile.jsx: modified (Layout import added)
- Commits 4097dba and 13da69c confirmed in essentials git log
