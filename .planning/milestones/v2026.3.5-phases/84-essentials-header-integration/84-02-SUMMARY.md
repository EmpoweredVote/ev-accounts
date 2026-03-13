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
    - CompassV2/src/pages/Login.jsx

key-decisions:
  - "Layout uses named export (export function Layout), imported via { Layout } destructuring in all pages"
  - "Closing </Layout> tag placed after outer page div and before end of return, keeping min-h-screen div as Layout child"
  - "returnTo query param passed to compass.empowered.vote/login so user lands back in Essentials after auth"

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
- **Tasks:** 3 of 3 (checkpoint approved + 2 fixes applied during verification)
- **Files modified:** 7

## Accomplishments
- Removed AuthIndicator floating bubble from App.jsx (import + fixed div wrapper deleted)
- Added `{ Layout }` import and wrapping to all 5 pages: Landing, Results, Profile, LegislativeRecord, CandidateProfile
- Removed Header imports and dead navItems/ctaButton config from Profile, LegislativeRecord, and CandidateProfile
- Removed SiteHeader direct usage from Landing and Results
- Build passes with 67 modules, 0 errors
- Fixed cross-app login redirect: Essentials passes `returnTo` param so Compass redirects user back after auth
- CompassV2 Login page updated to honor `returnTo` query param — user approved in checkpoint verification

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove AuthIndicator from App.jsx** - `4097dba` (feat)
2. **Task 2: Wrap all pages in Layout** - `13da69c` (feat)
3. **Task 3 checkpoint approved; fix: returnTo param for login redirect** - `0dc653d` (fix, essentials)
4. **Fix: CompassV2 Login honors returnTo redirect** - `dd4e87e` (fix, CompassV2)

## Files Created/Modified
- `essentials/src/App.jsx` - Removed AuthIndicator import and fixed-position div wrapper
- `essentials/src/pages/Landing.jsx` - Replaced SiteHeader with Layout wrapping
- `essentials/src/pages/Results.jsx` - Replaced SiteHeader with Layout wrapping
- `essentials/src/pages/Profile.jsx` - Replaced Header + navItems/ctaButton with Layout wrapping
- `essentials/src/pages/LegislativeRecord.jsx` - Replaced Header + navItems/ctaButton with Layout wrapping
- `essentials/src/pages/CandidateProfile.jsx` - Replaced Header + navItems/ctaButton with Layout wrapping
- `CompassV2/src/pages/Login.jsx` - Added returnTo query param support for cross-app redirect after login

## Decisions Made
- Layout uses named export `export function Layout` (not default), so all pages import with `{ Layout }` destructuring
- The outer `<div className="min-h-screen ...">` is kept as the direct child of `<Layout>` to preserve existing page structure

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed cross-app login redirect missing returnTo param**
- **Found during:** Task 3 checkpoint (human-verify)
- **Issue:** After clicking "Sign in" from Essentials, users would authenticate on Compass but land on the Compass home page — not back on the Essentials page they came from. Cross-app auth UX was broken.
- **Fix:** Essentials passes `returnTo=<encoded-Essentials-URL>` to Compass login link; CompassV2 Login page updated to read `returnTo` from query params and redirect after successful auth.
- **Files modified:** `essentials/src/components/Layout.jsx`, `CompassV2/src/pages/Login.jsx`
- **Verification:** User confirmed during checkpoint verification — approved after fix
- **Committed in:** `0dc653d` (essentials), `dd4e87e` (CompassV2)

---

**Total deviations:** 1 auto-fixed (1 bug found during human verification)
**Impact on plan:** Fix was essential for correct cross-app auth UX. No scope creep.

Note: Named export discovery (`import { Layout }` vs `import Layout`) was a minor adjustment, not a deviation — handled inline during Task 2.

## Issues Encountered
- Minor: Layout component uses named export (`export function Layout`) not default export. Plan specified `import Layout from '../components/Layout'` but the actual file required `import { Layout } from '../components/Layout'`. Fixed automatically without impact.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ESS-01 through ESS-04 requirements fully complete and user-verified
- All 5 pages wired to Layout, building successfully, auth-aware header confirmed working
- Phase 85 (ReadRank header integration) is now unblocked
- AuthIndicator.jsx component file can be deleted in future cleanup (no longer imported anywhere)

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
- CompassV2/src/pages/Login.jsx: modified (returnTo redirect)
- Commits 4097dba, 13da69c, 0dc653d (essentials) and dd4e87e (CompassV2) confirmed in git log
- Checkpoint human-verify: approved by user
