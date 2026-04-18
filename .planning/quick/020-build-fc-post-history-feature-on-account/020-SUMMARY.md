---
phase: quick-020
plan: 020
subsystem: ui
tags: [react, typescript, fetch, zustand, pagination, fc, civic-spaces]

# Dependency graph
requires:
  - phase: quick-019
    provides: login.empowered.vote rename — no direct dep but same sprint
provides:
  - PostHistory React component with cursor-based FC post fetching
  - Posts tab on DashboardPage for Connected-tier users
affects: [civic-spaces-integration, fan-out-post-history-v2]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "External fetch (not apiFetch) for cross-origin FC requests — apiFetch prefixes VITE_API_URL, FC is a different host"
    - "401 on external call → useAuthStore.getState().clearAuth() (triggers AuthGuard redirect)"
    - "Tab content gated on cp (connected_profile presence) — Posts require Connected tier"

key-files:
  created:
    - app/src/components/PostHistory.tsx
  modified:
    - app/src/pages/DashboardPage.tsx

key-decisions:
  - "Use raw fetch() for FC calls, not apiFetch — apiFetch prepends VITE_API_URL/api, incompatible with external host"
  - "Auth source is useAuthStore (user.id + accessToken), not supabase.auth.getSession() — /app has no supabase client"
  - "401 → clearAuth() not local error state — AuthGuard handles redirect to login"
  - "Posts tab gated on cp truthy — Inform-tier users won't have FC posts"
  - "No client re-sort — server returns newest-first; cursor semantics must be preserved"

patterns-established:
  - "PostHistory fan-out pattern: external service fetch with bearer token from authStore — reusable for Civic Spaces v2"

# Metrics
duration: 3min
completed: 2026-04-17
---

# Quick Task 020: FC Post History on Dashboard Summary

**PostHistory component with cursor pagination fetching fc.empowered.vote/api/users/{id}/posts, mounted in a new Posts tab on DashboardPage for Connected users**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-17T00:00:00Z
- **Completed:** 2026-04-17T00:02:09Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- New `PostHistory` component (192 lines) with loading/empty/error states, cursor-based Load more pagination, and a 4-line row layout (community name, thread title link, excerpt, pseudonym + timestamp + edited badge)
- `DashboardPage` updated with a third tab "Posts" (between Referrals and Contributor) — gated on `cp` so only Connected-tier users see it
- `authorPseudonym` is the sole author field rendered — no `displayName` or `legal_name` fallback anywhere in the component

## Task Commits

1. **Task 1: Create PostHistory component** - `eea4ea6` (feat)
2. **Task 2: Add Posts tab to DashboardPage** - `0da4072` (feat)

## Files Created/Modified

- `app/src/components/PostHistory.tsx` — New component: fetches FC posts via raw fetch with Bearer token from useAuthStore; handles 401/403/5xx; cursor-based pagination; 4-line row layout
- `app/src/pages/DashboardPage.tsx` — Added `import PostHistory`; widened `activeTab` union to include `'posts'`; added Posts tab button (gated on `cp`) and `<PostHistory />` content block

## Decisions Made

- **Raw fetch for FC, not apiFetch** — `apiFetch` prepends `VITE_API_URL/api`; using it for `https://fc.empowered.vote/...` would double-prefix and fail. Raw `fetch()` with manual `Authorization: Bearer` header is the correct pattern for external service calls from `/app`.
- **Auth from useAuthStore, not supabase client** — the `/app` frontend has no exposed Supabase client; all auth state lives in Zustand. `user.id` and `accessToken` are read directly from the store.
- **401 → `clearAuth()` not local error** — AuthGuard redirects to `/login` when `isAuthenticated` becomes false; this matches the spec's "redirect to login" requirement without duplicating redirect logic.
- **Posts tab gated on `cp`** — Inform-tier users won't have FC post history (no community participation); this matches the Referrals gating pattern.

## Deviations from Plan

None — plan executed exactly as written. The auth source note in the context (`useAuthStore` not `supabase.auth.getSession()`) was already accounted for in the spec.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. The FC endpoint at `https://fc.empowered.vote/api/users/:id/posts` is called from the client; no backend changes needed.

## Next Phase Readiness

- Post History v1 complete. Component is reusable as a fan-out pattern for Civic Spaces integration.
- **v2 follow-up:** When Civic Spaces API becomes available, consider a `Promise.allSettled([fcPosts, civicSpacesPosts])` fan-out in a parent component, merging results by `createdAt` and rendering in a unified feed.
- **FC endpoint contract:** The component depends on `FCPostsResponse` shape (`data: FCPost[], meta: { cursor, hasMore }`). If the FC service changes this contract, `PostHistory.tsx` is the only file to update.

---
*Phase: quick-020*
*Completed: 2026-04-17*
