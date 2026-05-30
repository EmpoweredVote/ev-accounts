# Phase 64: InformLanding - Research

**Researched:** 2026-05-10
**Domain:** React routing (react-router-dom v6), Zustand auth state, Tailwind v4 CSS
**Confidence:** HIGH — all findings from direct codebase inspection

## Summary

Phase 64 adds an unauthenticated landing page at `app.empowered.vote/`. The root route `/` is currently inside an `<AuthGuard>` that hard-redirects to `login.empowered.vote/login`. The fix requires promoting `DashboardPage` out from the blanket `<AuthGuard>` and giving `/` its own tier-aware split: unauthenticated users see `InformLandingPage`, authenticated users see `DashboardPage`. No new routing libraries are needed — react-router-dom v6 `useNavigate`/`Navigate` handles this cleanly.

The auth store (`useAuthStore`) exposes `isAuthenticated` and `isLoading` as clean booleans, making the tier-aware conditional straightforward. The key UX requirement is no flash of the wrong page: during the SSO check (`isLoading = true`) the root must render a neutral spinner, not the landing page or the dashboard.

`AppNav` already accepts `children` for the right slot; the landing page simply passes Sign In and Create account links as children.

**Primary recommendation:** Add a thin `RootRoute` component that reads `{ isAuthenticated, isLoading }` from `useAuthStore` and renders spinner / `InformLandingPage` / `<Navigate to redirect target>` accordingly; mount it at `/` outside any `AuthGuard`. Remove `DashboardPage` from the `<OnboardingGuard>` wrapper and add it inside `RootRoute`'s authenticated branch only. All other auth-gated routes remain unchanged.

---

## Standard Stack

### Core (already installed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| react-router-dom | v6 | Routing, `<Navigate>`, `<Outlet>` | Already used throughout the app |
| zustand | current | `useAuthStore` — `isAuthenticated`, `isLoading`, `user` | Already the single source of auth truth |
| tailwindcss | v4 | Styling — `@theme` tokens in `app/src/index.css` | App-wide design system |

No new dependencies required for this phase.

### Available Brand Tokens (app/src/index.css)
```
ev-red     #FF5740   Empower features
ev-teal    #00657C   Connect primary
ev-teal-light #59B0C4
ev-yellow  #FED12E   Inform features
ev-black   #1c1c1c
ev-blue    #3B82F6   v2.0 CTAs / primary button (PrimaryButton uses this)
ev-navy    #020618   Dark page background
```

### Available Shared Components
| Component | Location | Interface |
|-----------|----------|-----------|
| `AppNav` | `app/src/components/AppNav.tsx` | `children?: ReactNode` → renders in right slot |
| `PrimaryButton` | `app/src/components/PrimaryButton.tsx` | `w-full` by default — use `className` override to constrain width |
| `SecondaryButton` | `app/src/components/SecondaryButton.tsx` | same as PrimaryButton, dark bg with border |
| `AuthCard` | `app/src/components/AuthCard.tsx` | `bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5` |
| `AuthPageLayout` | `app/src/components/AuthPageLayout.tsx` | `min-h-screen bg-ev-navy` centered layout — auth-context only, not appropriate for landing |

**Do NOT use `AuthPageLayout` for the landing page.** It is designed for the auth flow (ev-navy background, centered narrow card). The landing page needs a full-width document layout.

---

## Architecture Patterns

### Current Route Tree (App.tsx)
```
<Routes>
  /login        → LoginPage         (public)
  /signup       → SignupPage        (public)
  /welcome      → WelcomeScreen     (public, auth-context)

  <AuthGuard>                        (redirects to login.empowered.vote if unauthenticated)
    /onboarding → OnboardingPage
    <OnboardingGuard>
      /         → DashboardPage     ← MUST MOVE OUT
      /profile  → ProfilePage
      /settings/location → UpdateLocationPage
      /contributor → ContributorLayout
    </OnboardingGuard>
  </AuthGuard>

  *             → <Navigate to="/" />
</Routes>
```

### Required Route Tree After Phase 64
```
<Routes>
  /login        → LoginPage         (public)
  /signup       → SignupPage        (public)
  /welcome      → WelcomeScreen     (public)

  /             → <RootRoute />     ← NEW: tier-aware split, no AuthGuard

  <AuthGuard>
    /onboarding → OnboardingPage
    <OnboardingGuard>
      /profile  → ProfilePage       (/ removed from here)
      /settings/location → UpdateLocationPage
      /contributor → ContributorLayout
    </OnboardingGuard>
  </AuthGuard>

  *             → <Navigate to="/" />
</Routes>
```

### Pattern 1: RootRoute — Tier-Aware Split at Route Level

**What:** A thin component that sits at `/` outside `<AuthGuard>`. During `isLoading` it renders a spinner (identical to AuthGuard's loading spinner). When resolved, authenticated users get `DashboardPage` inline; unauthenticated users get `InformLandingPage`.

**Why route-level, not wrapper component:** The OnboardingGuard must still apply for DashboardPage (connected users who haven't onboarded must be redirected to `/onboarding`). By rendering DashboardPage inside RootRoute, we can compose OnboardingGuard logic directly or call it via `<Navigate>` based on the user's `completedOnboarding` and `tier`.

**Example:**
```tsx
// Source: direct analysis of app/src/components/AuthGuard.tsx + app/src/components/OnboardingGuard.tsx
function RootRoute() {
  const { isAuthenticated, isLoading, user } = useAuthStore();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-6 h-6 border-2 border-ev-teal border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <InformLandingPage />;
  }

  // Authenticated: apply onboarding redirect (mirrors OnboardingGuard logic)
  if ((user?.tier === 'connected' || user?.tier === 'empowered') && !user?.completedOnboarding) {
    return <Navigate to="/onboarding" replace />;
  }

  return <DashboardPage />;
}
```

This avoids duplicating OnboardingGuard as a wrapper Route and keeps the `/` routing self-contained.

### Pattern 2: AppNav Right Slot for Auth Links

**What:** Pass auth links as `children` to AppNav. The right slot renders whatever children are provided.

```tsx
// Source: direct inspection of app/src/components/AppNav.tsx
<AppNav>
  <a href="https://login.empowered.vote/login" className="text-sm font-medium text-gray-500 hover:text-ev-teal transition-colors">
    Sign in
  </a>
  <a href="https://login.empowered.vote/signup" className="text-sm font-medium bg-ev-teal text-white px-3 py-1.5 rounded-lg hover:bg-ev-teal/90 transition-colors">
    Create account
  </a>
</AppNav>
```

AppNav renders children in a `flex items-center gap-3` div — the two links will sit side by side.

### Pattern 3: Feature Card Grid (from DashboardPage)

DashboardPage already has a working `grid grid-cols-2 gap-3` feature card layout (lines 636–657 of DashboardPage.tsx). The InformLanding feature card grid should use the same structure. Cards are:
```
bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 space-y-2
hover:border-ev-teal/40 transition-colors group
```
Each card has: colored dot (`w-2 h-2 rounded-full bg-ev-yellow`), name (`text-sm font-semibold`), description (`text-xs text-gray-400`), and "Explore →" link (`text-xs text-ev-teal font-medium`).

### Pattern 4: Page Layout for Landing

The landing page is a public document page, not a modal/card flow. Use `min-h-screen bg-gray-50 dark:bg-ev-black` (matches DashboardPage's outer container). Use `max-w-lg mx-auto px-4` sections for consistent content width with the rest of the app.

### Anti-Patterns to Avoid

- **Wrapping `/` in `<AuthGuard>`:** AuthGuard performs a hard `window.location.href` redirect to login.empowered.vote — this is incompatible with serving unauthenticated users at root.
- **Using `AuthPageLayout` for the landing page:** That component is scoped to auth flows (narrow centered card, ev-navy bg). The landing needs a scrollable document layout.
- **Showing landing page during `isLoading`:** The SSO check in App.tsx (lines 85–147) takes up to 3 seconds. Showing the landing momentarily before snapping to DashboardPage would be a FOUC. Render spinner until `isLoading = false`.
- **Placing a CTA button in the "Participate with your community" section:** Requirements explicitly say no CTA button in that section. Connected value prop is explanatory, not conversion-focused.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Auth state for tier-aware render | Custom hook, context | `useAuthStore` from `app/src/store/authStore.ts` | Already manages `isAuthenticated`, `isLoading`, `user.tier` |
| Spinner during loading | Custom spinner | Exact pattern from `AuthGuard.tsx` | Visually consistent with existing guards |
| Right-slot nav links | Custom nav bar | Pass as `children` to existing `AppNav` | AppNav already handles the right-slot flex layout |
| Feature card grid | New card component | Inline Tailwind (same pattern as DashboardPage FEATURES grid) | No abstraction needed — ~10 lines each |
| Sign in / Create account links | New button components | `<a href>` with Tailwind classes or `PrimaryButton`/`SecondaryButton` + `<Link>` | The "Join the conversation" section is a simple two-button block |

---

## Common Pitfalls

### Pitfall 1: Flash of Wrong Page (FOUC)
**What goes wrong:** RootRoute renders `InformLandingPage` immediately, then snaps to `DashboardPage` once the SSO check completes.
**Why it happens:** `isLoading` starts as `true` in the store but the component renders before the check resolves.
**How to avoid:** Check `isLoading` first and return the spinner. Never show either InformLanding or Dashboard until `isLoading = false`.
**Warning signs:** Users see the hero section briefly before the dashboard loads.

### Pitfall 2: OnboardingGuard Logic Not Applied at Root
**What goes wrong:** Authenticated connected user who hasn't onboarded hits `/` and sees DashboardPage directly instead of being redirected to `/onboarding`.
**Why it happens:** Removing `/` from `<OnboardingGuard>` without replicating its logic inside `RootRoute`.
**How to avoid:** The RootRoute authenticated branch must mirror OnboardingGuard's condition: `if (tier === 'connected' || tier === 'empowered') && !completedOnboarding → <Navigate to="/onboarding" />`.

### Pitfall 3: PrimaryButton is Full-Width by Default
**What goes wrong:** "Create account" and "Sign in" buttons in the "Join the conversation" section each span the full container width.
**Why it happens:** `PrimaryButton` and `SecondaryButton` have `w-full` hardcoded in their className.
**How to avoid:** Pass `className="w-auto px-6"` override to constrain width, or use `<a href>` links with inline Tailwind classes for the landing CTA section. Links to login.empowered.vote/signup and login.empowered.vote/login (external URLs) should use `<a href>`, not react-router `<Link>`.

### Pitfall 4: Feature Card Links — Token Passing
**What goes wrong:** Feature cards on the landing page pass `#access_token=...` in hrefs when no user is authenticated.
**Why it happens:** Copying the FEATURES render pattern from DashboardPage directly, which conditionally appends the token.
**How to avoid:** On InformLandingPage, `accessToken` is always null. Link feature cards to the base URL only — no token appending.

### Pitfall 5: Wildcard Catch-All Redirects to `/` Loops
**What goes wrong:** The `* → <Navigate to="/" />` catch-all redirects back to root, which now renders InformLandingPage for unauthenticated users — potentially fine, but worth verifying no infinite redirect occurs.
**Why it happens:** Not a real loop, just needs verification that the catch-all doesn't interfere with the new root behavior.
**How to avoid:** The catch-all is safe since `RootRoute` at `/` always renders something. No change needed.

---

## Code Examples

### RootRoute Component
```tsx
// Tier-aware split — no AuthGuard, mirrors loading/onboarding logic from existing guards
// Source: analysis of app/src/components/AuthGuard.tsx + OnboardingGuard.tsx
import { Navigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import DashboardPage from './DashboardPage';
import InformLandingPage from './InformLandingPage';

function RootRoute() {
  const { isAuthenticated, isLoading, user } = useAuthStore();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-6 h-6 border-2 border-ev-teal border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <InformLandingPage />;
  }

  if ((user?.tier === 'connected' || user?.tier === 'empowered') && !user?.completedOnboarding) {
    return <Navigate to="/onboarding" replace />;
  }

  return <DashboardPage />;
}
```

### App.tsx Route Change
```tsx
// Remove "/" from inside <OnboardingGuard>, add as standalone route
// Before:
<Route element={<AuthGuard />}>
  <Route element={<OnboardingGuard />}>
    <Route path="/" element={<DashboardPage />} />   // ← remove
    ...

// After:
<Route path="/" element={<RootRoute />} />           // ← add above AuthGuard

<Route element={<AuthGuard />}>
  <Route element={<OnboardingGuard />}>
    // / is gone; /profile, /settings, /contributor remain
```

### AppNav with Auth Links (Unauthenticated)
```tsx
// Source: app/src/components/AppNav.tsx — children render in flex gap-3 right slot
<AppNav>
  <a
    href="https://login.empowered.vote/login"
    className="text-sm font-medium text-gray-500 hover:text-ev-teal dark:text-gray-400 dark:hover:text-ev-teal-light transition-colors"
  >
    Sign in
  </a>
  <a
    href="https://login.empowered.vote/signup"
    className="text-sm font-semibold bg-ev-teal text-white px-4 py-1.5 rounded-lg hover:bg-ev-teal/90 transition-colors"
  >
    Create account
  </a>
</AppNav>
```

### Feature Card Grid (Landing Variant)
```tsx
// Source: DashboardPage.tsx lines 632–657, simplified for unauthenticated context
const LANDING_FEATURES = [
  { name: 'Empowered Essentials', description: '...', baseUrl: 'https://essentials.empowered.vote', dot: 'bg-ev-yellow' },
  { name: 'Empowered Compass',    description: '...', baseUrl: 'https://compass.empowered.vote',   dot: 'bg-ev-yellow' },
  { name: 'Treasury Tracker',     description: '...', baseUrl: 'https://treasurytracker.empowered.vote', dot: 'bg-ev-yellow' },
  { name: 'Fallacy Finders',      description: '...', baseUrl: 'https://falacyfinders.empowered.vote',   dot: 'bg-ev-yellow' },
  { name: 'Empowered Badges',     description: '...', baseUrl: 'https://badges.empowered.vote',    dot: 'bg-ev-yellow' },
];

<div className="grid grid-cols-2 gap-3">
  {LANDING_FEATURES.map((f) => (
    <a
      key={f.name}
      href={f.baseUrl}                // No token — unauthenticated
      target="_blank"
      rel="noopener noreferrer"
      className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 space-y-2 hover:border-ev-teal/40 transition-colors group"
    >
      <div className={`w-2 h-2 rounded-full ${f.dot}`} />
      <p className="text-sm font-semibold text-ev-black dark:text-white leading-snug">{f.name}</p>
      <p className="text-xs text-gray-400 leading-snug">{f.description}</p>
      <p className="text-xs text-ev-teal font-medium group-hover:underline">Explore →</p>
    </a>
  ))}
</div>
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| All auth flows on `app.empowered.vote` (login, signup inline) | Auth on `login.empowered.vote`, `app.empowered.vote` is feature hub | v1.4–v1.7 | Sign In / Create account links must be `<a href="https://login.empowered.vote/...">`, not `<Link to="/login">` |
| `ev-navy` background everywhere | `bg-gray-50 dark:bg-ev-black` for dashboard/content pages | v2.0 (Phase 60) | Landing page should use `bg-gray-50 dark:bg-ev-black` not `bg-ev-navy` (which is auth-flow-only) |

---

## Open Questions

1. **Feature URLs for landing page cards**
   - What we know: DashboardPage FEATURES array has Essentials, Compass, CTC, Validation Quests, Read & Rank, Civic Spaces, Treasury Tracker
   - What's unclear: Requirements list "Empowered Essentials, Empowered Compass, Treasury Tracker, Fallacy Finders, Empowered Badges" — some of these differ from the DashboardPage list (no CTC, VQ, Read & Rank; adds Fallacy Finders and Badges)
   - Recommendation: Use the requirement's list verbatim; stub URLs that aren't yet live with `href="#"` or omit the "Explore →" link

2. **Civic spaces icons in "Participate" section**
   - What we know: Requirements mention "civic spaces icons (Civic Spaces, Common Ground, Symposium)"
   - What's unclear: No icon assets for these three were found in `app/public/`. Only gem images and logo confirmed.
   - Recommendation: Use simple SVG inline icons or emoji-free placeholder circles with Tailwind until icon assets are confirmed

3. **Dark mode default**
   - What we know: The app has `dark:` variants throughout; `AuthPageLayout` uses `bg-ev-navy` always; DashboardPage uses `bg-gray-50 dark:bg-ev-black`
   - What's unclear: Is dark mode on by default for the app? The theme system uses a `dark` class (not `prefers-color-scheme`). The ProfilePage has a `useTheme` hook but DashboardPage doesn't use it.
   - Recommendation: Default to light mode matching DashboardPage — use `bg-gray-50` as base, `dark:bg-ev-black` as override.

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)
- `app/src/App.tsx` — current route tree and AuthGuard usage
- `app/src/components/AuthGuard.tsx` — exact redirect behavior, loading spinner pattern
- `app/src/components/AppNav.tsx` — children prop interface
- `app/src/store/authStore.ts` — `isAuthenticated`, `isLoading`, `user` shape
- `app/src/components/OnboardingGuard.tsx` — onboarding redirect logic to replicate
- `app/src/pages/DashboardPage.tsx` — feature card grid pattern, FEATURES array
- `app/src/index.css` — complete token list
- `app/src/components/PrimaryButton.tsx`, `SecondaryButton.tsx`, `AuthCard.tsx`, `AuthPageLayout.tsx` — reusable component interfaces

### Secondary (MEDIUM confidence)
- Phase 64 requirements as provided in task input

---

## Metadata

**Confidence breakdown:**
- Route surgery (App.tsx changes): HIGH — exact code structure read directly
- RootRoute pattern: HIGH — derived mechanically from AuthGuard + OnboardingGuard
- AppNav right slot: HIGH — exact prop interface verified
- Feature card grid: HIGH — pattern copied directly from DashboardPage
- Feature URLs for landing: LOW — DashboardPage list differs from requirements list; requires product decision
- Icon assets for "Participate" section: LOW — no assets confirmed in repo

**Research date:** 2026-05-10
**Valid until:** 60 days (stable codebase; only invalidated if App.tsx routing is refactored)
