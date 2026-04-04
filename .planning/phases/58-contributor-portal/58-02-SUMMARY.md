---
phase: 58-contributor-portal
plan: "02"
subsystem: ui
tags: [react, react-router, tailwind, contributor-portal, navigation]

# Dependency graph
requires:
  - phase: 58-01
    provides: "granted_at in /contributor/me response; essentials_data_editor in route guards"
provides:
  - "ContributorLayout — back nav header + Outlet wrapper for /contributor/* routes"
  - "ContributorDashboard — grant card dashboard with locked/empty state and active grants view"
  - "Three stub editor pages: CompassEditorPage, CampaignManagerPage, EssentialsEditorPage"
  - "Route registration for /contributor/* inside OnboardingGuard in App.tsx"
  - "Profile Hub tab bar: Profile (active on DashboardPage) + Contributor tab"
affects:
  - "58-03 (Compass Editor page — replaces CompassEditorPage stub)"
  - "58-04 (Campaign Manager / Essentials Editor — replaces remaining stubs)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ContributorLayout as nested route wrapper with back nav header + Outlet"
    - "ROLE_DISPLAY_NAMES constant for role_slug -> display name mapping"
    - "Role-keyed accent/badge/CTA style maps for grant card visual differentiation"
    - "Aspirational locked state with role descriptions instead of 'no roles' message"

key-files:
  created:
    - app/src/pages/contributor/ContributorLayout.tsx
    - app/src/pages/contributor/ContributorDashboard.tsx
    - app/src/pages/contributor/CompassEditorPage.tsx
    - app/src/pages/contributor/CampaignManagerPage.tsx
    - app/src/pages/contributor/EssentialsEditorPage.tsx
  modified:
    - app/src/App.tsx
    - app/src/pages/DashboardPage.tsx

key-decisions:
  - "ROLE_DISPLAY_NAMES: campaign_manager -> 'Candidate Coordinator' (not 'Campaign Manager')"
  - "Scope label priority: resource_id -> 'Single Politician'; jurisdiction_geoid -> raw geoid; feature_scope=platform -> 'Unrestricted'"
  - "Tab bar always visible to all logged-in users — no conditional fetch to show/hide"
  - "Locked state is aspirational (role descriptions + contact link), not 'you have no roles'"
  - "Role-specific accent colors: ev-yellow for Compass Editor, ev-teal for Essentials Editor, ev-red for Candidate Coordinator"

patterns-established:
  - "Contributor route nesting: /contributor -> ContributorLayout -> ContributorDashboard; /contributor/X -> editor stubs"
  - "Tab bar pattern: active tab uses border-ev-teal + text-ev-teal; inactive uses border-transparent + text-gray-500"

# Metrics
duration: 2min
completed: 2026-04-04
---

# Phase 58 Plan 02: Contributor Portal Frontend Shell Summary

**React Router nested route shell for contributor portal: ContributorLayout + grant card dashboard (locked/active states) + three editor stubs + Profile Hub tab bar**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-04-04T07:16:08Z
- **Completed:** 2026-04-04T07:17:58Z
- **Tasks:** 2
- **Files modified:** 7 (5 created, 2 modified)

## Accomplishments

- Full navigation skeleton: DashboardPage Contributor tab -> /contributor -> grant cards -> editor stub pages
- ContributorDashboard fetches /contributor/me; locked state is warm and aspirational with role descriptions and contact link; active grants render per-role styled cards with scope, date, granter, and CTA
- Three compilable stub pages ready for plans 03 and 04 to replace with full editor implementations
- App builds clean: 55 modules, zero TypeScript errors

## Task Commits

1. **Task 1: ContributorLayout and ContributorDashboard** - `90f104b` (feat)
2. **Task 2: Stub editor pages, App.tsx routes, DashboardPage tab bar** - `a2a1fe5` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `app/src/pages/contributor/ContributorLayout.tsx` - Back nav header + Outlet for /contributor/* routes
- `app/src/pages/contributor/ContributorDashboard.tsx` - Grant card dashboard with locked/active states and tab bar
- `app/src/pages/contributor/CompassEditorPage.tsx` - Stub: "Compass Editor" heading placeholder
- `app/src/pages/contributor/CampaignManagerPage.tsx` - Stub: "Candidate Coordinator" heading placeholder
- `app/src/pages/contributor/EssentialsEditorPage.tsx` - Stub: "Essentials Editor" heading placeholder
- `app/src/App.tsx` - Imports and registers /contributor/* nested routes inside OnboardingGuard
- `app/src/pages/DashboardPage.tsx` - Adds tab bar with Profile (active) and Contributor link

## Decisions Made

- **campaign_manager display name:** "Candidate Coordinator" per plan spec — not "Campaign Manager"
- **Scope label logic:** resource_id -> "Single Politician"; jurisdiction_geoid -> raw geoid value; platform scope -> "Unrestricted"
- **Tab bar always visible:** No grant fetch on DashboardPage to conditionally show/hide the Contributor tab — always shown to all logged-in users
- **Locked state framing:** Role descriptions (Compass Editors, Essentials Editors, Candidate Coordinators) with mailto contact link — aspirational, not restrictive

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Navigation shell complete: DashboardPage -> Contributor tab -> ContributorDashboard -> editor route stubs
- Plan 03 (Compass Editor) can replace CompassEditorPage.tsx stub with full implementation
- Plan 04 (Campaign Manager / Essentials Editor) can replace the remaining two stubs
- Back navigation from editors returns to / (Profile), which ContributorLayout's "Back to Profile" link handles

---
*Phase: 58-contributor-portal*
*Completed: 2026-04-04*
