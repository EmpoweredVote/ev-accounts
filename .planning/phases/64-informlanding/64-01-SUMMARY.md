---
phase: 64-informlanding
plan: 01
title: "Tier-Aware Routing — RootRoute Surgery"
subsystem: app-routing
tags: [routing, react-router, auth, inform-landing, rss-guard]

dependency-graph:
  requires: []
  provides:
    - RootRoute component (spinner | InformLandingPage | /onboarding redirect | DashboardPage)
    - InformLandingPage stub (replaced by plan 64-02)
    - / mounted outside AuthGuard in App.tsx
  affects:
    - 64-02 (builds the real InformLandingPage that replaces the stub)
    - 65 (DashboardPage now mounted by RootRoute, not directly in App.tsx)

tech-stack:
  added: []
  patterns:
    - Tier-aware split route component — reads useAuthStore, renders correct page based on isLoading/isAuthenticated/user.tier

key-files:
  created:
    - app/src/components/RootRoute.tsx
    - app/src/pages/InformLandingPage.tsx (stub)
  modified:
    - app/src/App.tsx

decisions:
  - "Named export for RootRoute (matches AuthGuard/OnboardingGuard pattern); default export for InformLandingPage (matches page convention)"
  - "Spinner classes match AuthGuard.tsx exactly — same border-ev-teal spinner, same min-h-screen wrapper"
  - "DashboardPage import removed from App.tsx entirely; RootRoute owns the import"

metrics:
  duration: "2 minutes"
  completed: "2026-05-11"
  tasks: 2/2
---

# Phase 64 Plan 01: Tier-Aware Routing — RootRoute Surgery Summary

**One-liner:** Moved `/` outside AuthGuard into a `RootRoute` that renders spinner during SSO check, `InformLandingPage` for unauthenticated users, and `DashboardPage` for authenticated+onboarded users.

## What Changed in App.tsx Route Tree

**Before:**
```
<Routes>
  <Route path="/login" ... />
  <Route path="/signup" ... />
  <Route path="/welcome" ... />
  <Route element={<AuthGuard />}>          ← / was inside here
    <Route path="/onboarding" ... />
    <Route element={<OnboardingGuard />}>
      <Route path="/" element={<DashboardPage />} />   ← unauthenticated visit → login.empowered.vote redirect
      <Route path="/profile" ... />
      <Route path="/settings/location" ... />
      <Route path="/contributor" ... />
    </Route>
  </Route>
  <Route path="*" ... />
</Routes>
```

**After:**
```
<Routes>
  <Route path="/login" ... />
  <Route path="/signup" ... />
  <Route path="/welcome" ... />
  <Route path="/" element={<RootRoute />} />    ← OUTSIDE AuthGuard — public access
  <Route element={<AuthGuard />}>
    <Route path="/onboarding" ... />
    <Route element={<OnboardingGuard />}>
      <Route path="/profile" ... />              ← DashboardPage removed from here
      <Route path="/settings/location" ... />
      <Route path="/contributor" ... />
    </Route>
  </Route>
  <Route path="*" ... />
</Routes>
```

## RootRoute Decision Flow

```
isLoading=true
  → spinner (prevent flash of wrong content during SSO check)

isLoading=false && !isAuthenticated
  → <InformLandingPage /> (no redirect to login.empowered.vote)

isLoading=false && isAuthenticated && (tier=connected|empowered) && !completedOnboarding
  → <Navigate to="/onboarding" replace />

isLoading=false && isAuthenticated && (onboarded OR tier=inform)
  → <DashboardPage />
```

The spinner uses the same classes as `AuthGuard.tsx` to avoid visual inconsistency:
`w-6 h-6 border-2 border-ev-teal border-t-transparent rounded-full animate-spin`

## InformLandingPage Stub

`app/src/pages/InformLandingPage.tsx` is a minimal placeholder that renders a centered gray message. It exists solely so this plan compiles independently of plan 64-02. Plan 64-02 will overwrite this file with the real landing page implementation (LAND-02 through LAND-05).

## Deviations from Plan

None — plan executed exactly as written.

## Success Criteria Met

- [x] `RootRoute.tsx` exists and exports named `RootRoute` with spinner | InformLandingPage | Navigate | DashboardPage logic
- [x] `App.tsx` has `<Route path="/" element={<RootRoute />} />` mounted above `<AuthGuard>`
- [x] `DashboardPage` no longer mounted directly in `App.tsx` (RootRoute owns it)
- [x] TypeScript compiles cleanly (`tsc --noEmit` passes)
- [x] Production build succeeds (`npm run build` — 259 kB JS bundle, no errors)
- [x] LAND-01 routing requirement satisfied
