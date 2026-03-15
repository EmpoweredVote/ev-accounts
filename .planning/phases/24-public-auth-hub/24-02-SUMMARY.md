---
phase: 24-public-auth-hub
plan: 02
subsystem: ui
tags: [react, vite, zustand, react-router, headlessui, auth, invite-code]

# Dependency graph
requires:
  - phase: 24-01
    provides: signup_with_invite RPC, request-access endpoint, is_admin on /api/account/me
  - phase: 23-central-profile-page-admin-tier-promotion
    provides: GET /api/account/profile/:userId endpoint (reused as /profile/me)
provides:
  - Tier-neutral Login page with redirect callout and Create one link
  - Signup page with invite code, legal name, covenant callout, request-access modal
  - User-facing ProfilePage as post-login destination for all tiers
  - AuthGuard component (auth-only, no admin requirement)
  - Updated AdminGuard redirecting non-admins to /profile
  - redirect.ts utility validating *.empowered.vote ?redirect= params
  - Extended authStore User interface with tier, completedOnboarding, isAdmin
  - Rewired App.tsx routing with /signup, /profile, public-first default
affects: [any future phase extending accounts.empowered.vote frontend, CompassV2 redirect integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Post-login /account/me fetch pattern for tier-aware routing
    - getValidRedirect() domain whitelist for cross-app SSO redirects
    - AuthGuard (auth only) vs AdminGuard (auth + admin) split for route protection
    - Session restore via /account/me (not /admin/me) works for all tiers

key-files:
  created:
    - admin/src/lib/redirect.ts
    - admin/src/pages/Signup.tsx
    - admin/src/pages/ProfilePage.tsx
    - admin/src/components/AuthGuard.tsx
  modified:
    - admin/src/store/authStore.ts
    - admin/src/pages/Login.tsx
    - admin/src/components/AdminGuard.tsx
    - admin/src/App.tsx

key-decisions:
  - "Post-login GET /account/me (not /admin/me) for session restore and tier data — works for all tiers"
  - "Default /* redirect changed from /admin to /login — public-first routing"
  - "AdminGuard redirects non-admins to /profile instead of showing error page"
  - "admin_token sessionStorage key kept despite name — stores JWT for any user, backward-compat artifact"
  - "Request access modal uses headlessui Dialog (already installed), not inline state"
  - "getValidRedirect() returns null for untrusted domains, no error thrown — silent ignore"

patterns-established:
  - "Redirect validation: getValidRedirect() checks hostname === empowered.vote || endsWith .empowered.vote"
  - "Cross-app redirect pattern: ?redirect= on /login and /signup, preserved through Create one link"
  - "AuthGuard vs AdminGuard: two distinct guards for auth-only vs auth+admin route protection"

# Metrics
duration: ~45min
completed: 2026-03-14
---

# Phase 24 Plan 02: Frontend — Login Rebrand + Signup Flow + ProfilePage + Routing Summary

**Tier-neutral auth hub replacing admin-only Login with civic-branded Signup, ProfilePage, and *.empowered.vote redirect validation using React Router + Zustand**

## Performance

- **Duration:** ~45 min
- **Completed:** 2026-03-14
- **Tasks:** 3 implementation + 1 human checkpoint (approved)
- **Files modified:** 8

## Accomplishments

- Replaced admin-only Login.tsx with tier-neutral "Sign in to Empowered Vote" page — non-admin users no longer hit a 403 wall
- Built Signup.tsx with invite code, legal name, covenant callout, and request-access modal backed by the Phase 24-01 endpoints
- Created ProfilePage as the post-login destination for all tiers with tier badge, XP/gems display, admin panel link for admins, and sign-out
- Added AuthGuard (auth-only), updated AdminGuard to redirect non-admins to /profile, rewired App.tsx routing to public-first

## Task Commits

Each task was committed atomically:

1. **Task 1: Auth store + redirect utility + Login.tsx** - `e1f4544` (feat)
2. **Task 2: Signup.tsx + Request Access modal** - `b45f450` (feat)
3. **Task 3: App.tsx routing + ProfilePage + AuthGuard** - `55605dd` (feat)
4. **Task 4: Human checkpoint** - approved

## Files Created/Modified

- `admin/src/store/authStore.ts` - Extended User interface with tier, completedOnboarding, isAdmin
- `admin/src/lib/redirect.ts` - getValidRedirect() and getAppNameFromRedirect() for *.empowered.vote trust
- `admin/src/pages/Login.tsx` - Full replacement: tier-neutral branding, post-login /account/me fetch, redirect callout
- `admin/src/pages/Signup.tsx` - New: email/password/legal-name/invite-code form, covenant callout, request-access modal
- `admin/src/pages/ProfilePage.tsx` - New: profile data display, tier badge, gems/XP, conditional Admin Panel link, sign-out
- `admin/src/components/AuthGuard.tsx` - New: auth-only route guard (no admin check)
- `admin/src/components/AdminGuard.tsx` - Updated: non-admin users redirect to /profile (not error page)
- `admin/src/App.tsx` - Rewired: /signup + /profile routes, session restore via /account/me, default redirect to /login

## Decisions Made

- **Post-login GET /account/me instead of /admin/me** — the is_admin field added in Plan 01 makes /account/me the single source of truth for tier routing; non-admin logins no longer fail.
- **Default catch-all redirects to /login not /admin** — accounts.empowered.vote is now a public portal, not an admin-only tool.
- **AdminGuard redirects to /profile on non-admin** — clean UX instead of error page; users land somewhere useful.
- **admin_token sessionStorage key preserved** — JWT for any authenticated user, not just admins; renaming would break existing admin sessions.
- **Silent redirect validation** — getValidRedirect() returns null for untrusted domains without throwing; no error state needed for the validation itself.

## Deviations from Plan

None - plan executed exactly as written. Human checkpoint passed on first verify.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- accounts.empowered.vote is now a fully functional public auth portal for the Empowered Vote platform
- Signup + invite flow complete end-to-end (backend Phase 24-01 + frontend Phase 24-02)
- Phase 24 is complete — no remaining plans in this phase
- Future phases can build on the redirect utility and AuthGuard pattern for additional protected routes
- CompassV2 can implement ?redirect= on its login/signup to return users back after auth

---
*Phase: 24-public-auth-hub*
*Completed: 2026-03-14*
