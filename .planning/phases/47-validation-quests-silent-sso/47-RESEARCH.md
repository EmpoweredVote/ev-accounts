# Phase 47: Validation Quests Silent SSO - Research

**Researched:** 2026-03-24
**Domain:** Frontend silent SSO — Supabase JS `setSession`, cross-origin credentialed fetch, React context auth initialization
**Confidence:** HIGH

## Summary

Phase 47 is a VQ-only frontend change: the `AuthProvider` in `AuthContext.tsx` needs to silently call `GET /api/auth/session` on load when Supabase reports no active session, then initialize the Supabase client via `supabase.auth.setSession()` with the returned tokens. Once `setSession()` completes, Supabase's `onAuthStateChange` fires `SIGNED_IN`, which the existing `AuthProvider` already handles by calling `fetchUserProfile()`. Logout gains a preceding `POST /api/auth/logout` call to clear the shared cookie before `supabase.auth.signOut()`.

**Critical structural difference from Phase 46:** VQ uses Supabase JS directly for auth state (not localStorage tokens). This means the SSO handoff mechanism is `supabase.auth.setSession({ access_token, refresh_token })`, NOT a raw `setToken()` call to localStorage. After `setSession()` succeeds, Supabase emits `SIGNED_IN` to `onAuthStateChange` — the existing VQ auth machinery takes over from there. VQ is also deployed on Render as a static site with NO Netlify proxy, so the `GET /api/auth/session` and `POST /api/auth/logout` calls are cross-origin requests to `VITE_ACCOUNTS_API_URL` (`https://ev-accounts-api.onrender.com`), requiring `credentials: 'include'`.

**Current auth architecture (read directly from source):** `AuthContext.tsx` initializes auth via `onAuthStateChange`. Per an existing comment in the file: `onAuthStateChange` fires `INITIAL_SESSION` synchronously on mount with the stored session if any, so no separate `getSession()` call is needed for the normal path. The SSO check must insert as an async step that runs AFTER `onAuthStateChange` confirms null session. The `signOut()` function currently calls only `supabase.auth.signOut()`. The `AuthContextValue` type exports: `session`, `user`, `profile`, `isLoadingProfile`, `signOut`.

**Primary recommendation:** Add an `isAuthChecking` state to `AuthProvider`. In the auth `useEffect`, after `onAuthStateChange` is subscribed, call `supabase.auth.getSession()` — if null, fire the silent SSO check. Use `supabase.auth.setSession()` to initialize. Gate all protected routes behind `isAuthChecking` in `PrivateRoute`. Upgrade `signOut()` to call `POST /api/auth/logout` first.

## Standard Stack

No new libraries needed. VQ already has everything required.

### Core (already installed)
| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `@supabase/supabase-js` | 2.98.0 | Auth state management + `setSession` + `onAuthStateChange` | Installed; VQ uses Supabase JS directly for auth |
| `react` | ^19.2.0 | Component rendering | React 19 |
| `react-router` | ^7.13.1 | Routing | Used for `PrivateRoute` and deep link preservation |

### No New Installations Required

VQ has no localStorage-based token pattern — auth state lives entirely in Supabase's session store. No toast library exists. Locked decisions: all failures are silent, no toast needed.

**Installation:**
```bash
# Nothing to install
```

## Architecture Patterns

### App File Map

```
/c/Validation Quests/frontend/src/
├── contexts/AuthContext.tsx    # Core changes: SSO check + isAuthChecking state + logout upgrade
├── routes/PrivateRoute.tsx     # Gate on isAuthChecking before checking session
└── types/auth.ts               # Add isAuthChecking to AuthContextValue type (if typed there)
```

Check `types/auth.ts` exists and exports `AuthContextValue` — `isAuthChecking: boolean` must be added to the type definition.

### Pattern 1: Where the SSO Check Inserts

**What:** The existing `AuthProvider` subscribes to `onAuthStateChange` and relies on `INITIAL_SESSION` to restore an existing session synchronously. The SSO check runs AFTER this subscription is set up, using `supabase.auth.getSession()` to check if `INITIAL_SESSION` produced a session.

**When to use:** Inside `AuthProvider`'s `useEffect`, after the `onAuthStateChange` subscription is established.

**Why this order matters:** Supabase's `onAuthStateChange` handles `INITIAL_SESSION` on mount, restoring persisted sessions from localStorage automatically. The SSO check should only run when `INITIAL_SESSION` produced null. Checking `getSession()` after the subscription is set ensures we don't race.

```typescript
// Source: verified from AuthContext.tsx + auth-js GoTrueClient.js setSession implementation
useEffect(() => {
  let cancelled = false;

  const {
    data: { subscription },
  } = supabase.auth.onAuthStateChange((_event, newSession) => {
    setSession(newSession);
    setUser(newSession?.user ?? null);

    if (newSession?.user) {
      setTimeout(() => fetchUserProfile(newSession.access_token), 0);
    } else {
      setProfile(null);
    }
  });

  // After subscription: check if INITIAL_SESSION gave us a session.
  // If not, try silent SSO.
  async function initSso() {
    const { data } = await supabase.auth.getSession();
    if (data.session) {
      // Session already present — INITIAL_SESSION handled it. Release gate.
      if (!cancelled) setIsAuthChecking(false);
      return;
    }

    // No session — attempt silent SSO check
    const accountsApiUrl = import.meta.env.VITE_ACCOUNTS_API_URL as string;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 3000);

    try {
      const res = await fetch(`${accountsApiUrl}/api/auth/session`, {
        credentials: 'include',
        signal: controller.signal,
      });
      clearTimeout(timeoutId);

      if (!res.ok) {
        // 401 = no cookie session (expected), 5xx = server error — both silent
        console.error('[SSO] Session check failed:', res.status >= 500 ? `${res.status} server error` : '401 no session');
        return;
      }

      const ssoData = await res.json() as { access_token: string; refresh_token: string };
      if (!ssoData?.access_token || !ssoData?.refresh_token) return;

      // Initialize Supabase session — this fires SIGNED_IN on onAuthStateChange
      const { error } = await supabase.auth.setSession({
        access_token: ssoData.access_token,
        refresh_token: ssoData.refresh_token,
      });

      if (error) {
        // setSession rejection (invalid/expired tokens) — silent fallback
        console.error('[SSO] setSession failed:', error.message);
      }
      // If setSession succeeds, onAuthStateChange fires SIGNED_IN → fetchUserProfile runs
    } catch (err) {
      clearTimeout(timeoutId);
      // AbortError (3s timeout) or network error — silent fallback
      if (err instanceof Error && err.name !== 'AbortError') {
        console.error('[SSO] Unexpected error:', err.message);
      }
    } finally {
      if (!cancelled) setIsAuthChecking(false);
    }
  }

  void initSso();

  return () => {
    cancelled = true;
    subscription.unsubscribe();
  };
}, []); // eslint-disable-line react-hooks/exhaustive-deps
```

**Key:** `setIsAuthChecking(false)` is called in the `finally` block of the SSO path, and immediately in the session-present branch. The 3-second timeout is from locked decisions.

### Pattern 2: isAuthChecking State Shape

```typescript
// Add to AuthProvider state:
const [isAuthChecking, setIsAuthChecking] = useState(true);  // true = hold routes

// Add to AuthContext.Provider value:
<AuthContext.Provider value={{ session, user, profile, isLoadingProfile, signOut, isAuthChecking }}>
```

**Why true initially:** The loading state should start as `true` and resolve to `false` when init completes. This ensures no route renders before the check resolves, per locked decisions: "Hold all routes behind auth loading state on first render — nothing renders until the check resolves (max wait: 3s)."

### Pattern 3: PrivateRoute Update

```typescript
// Source: verified from PrivateRoute.tsx + CONTEXT.md decisions
export function PrivateRoute() {
  const { session, isAuthChecking } = useAuth();
  const location = useLocation();

  // Hold all rendering until SSO check completes (max 3s)
  if (isAuthChecking) {
    return null; // or a minimal loading placeholder matching VQ's style
  }

  if (!session) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  return <Outlet />;
}
```

**Note on deep links:** `PrivateRoute` already preserves `location` in `state={{ from: location }}` for deep link restoration. `LoginPage` already reads `location.state.from` and navigates back after login. The SSO check, when it succeeds, fires `SIGNED_IN` which updates `session` — `PrivateRoute` then renders `<Outlet />`. Deep links are automatically preserved because the user is still on the original URL when SSO resolves.

### Pattern 4: Logout Upgrade

Current `signOut()` in `AuthContext.tsx`:
```typescript
async function signOut(): Promise<void> {
  await supabase.auth.signOut();
}
```

Issues: Does not call `POST /api/auth/logout`, so the `ev_session` cookie is never cleared. User logs out of VQ but remains SSO-authenticated everywhere else.

Updated `signOut()`:
```typescript
async function signOut(): Promise<void> {
  const accountsApiUrl = import.meta.env.VITE_ACCOUNTS_API_URL as string;
  const token = session?.access_token;

  try {
    await fetch(`${accountsApiUrl}/api/auth/logout`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    });
  } catch {
    // Network failure — still proceed with Supabase local signout
  }

  await supabase.auth.signOut();
  // onAuthStateChange fires SIGNED_OUT → clears session/user/profile automatically
}
```

**Order per locked decisions:** `POST /api/auth/logout` first, then `supabase.auth.signOut()`. If API call fails, continue to local signout.

**Note:** `Header.tsx` calls `void signOut()` from `useAuth()`. No changes needed to `Header.tsx` — the upgrade is entirely inside `AuthContext.tsx`.

### Pattern 5: setSession API Behavior (verified from auth-js source)

`supabase.auth.setSession({ access_token, refresh_token })`:
- Requires BOTH `access_token` AND `refresh_token` — throws `AuthSessionMissingError` if either is missing
- If `access_token` is expired, it calls `_callRefreshToken(refresh_token)` internally before proceeding
- If successful and not expired: calls `_getUser(access_token)` then saves session and fires `SIGNED_IN` to `onAuthStateChange`
- Returns `{ data: { user, session }, error }` — does NOT throw (returns error in result)
- After `setSession()` fires `SIGNED_IN`, the existing `onAuthStateChange` handler in `AuthProvider` calls `setTimeout(() => fetchUserProfile(access_token), 0)` — profile loads automatically

**What this means for implementation:** There is no need to manually call `fetchUserProfile()` after `setSession()`. The `SIGNED_IN` event from `onAuthStateChange` handles it. The VQ auth machinery is fully event-driven and "just works" once `setSession()` succeeds.

### Pattern 6: Mid-Session SIGNED_OUT Handling

Per locked decisions: "On mid-session SIGNED_OUT event (token expiry, revocation from another app): react to `onAuthStateChange`, render unauthenticated — do NOT re-attempt the SSO check."

The existing `onAuthStateChange` handler already does the right thing: when `newSession` is null (i.e., `SIGNED_OUT`), it calls `setProfile(null)`. No additional code needed. The `isAuthChecking` state is only relevant during initial load — mid-session `SIGNED_OUT` events do not need to re-gate routes.

### Anti-Patterns to Avoid

- **Calling `setSession()` with only `access_token`:** The function requires both tokens and throws `AuthSessionMissingError` if `refresh_token` is missing. The Phase 44 endpoint returns both — use both.
- **Calling `fetchUserProfile()` manually after `setSession()`:** Not needed. `setSession()` fires `SIGNED_IN` → `onAuthStateChange` → `setTimeout(fetchUserProfile, 0)`. Double-calling it creates a race condition.
- **Starting `isAuthChecking` as `false`:** If false initially, `PrivateRoute` evaluates `session` before SSO check runs, immediately redirecting to `/login`. Must start `true`.
- **Setting `isAuthChecking = false` in `onAuthStateChange`:** The handler fires on every auth event, including `TOKEN_REFRESHED`. Setting `isAuthChecking = false` there would fire on the wrong event. Set it only in the `initSso` function's `finally` / session-present branch.
- **Using `apiFetch` from `apiClient.ts` for the SSO check:** `apiFetch` does not pass `credentials: 'include'` and does not target `VITE_ACCOUNTS_API_URL`. Use native `fetch` directly.
- **Using VQ's `VITE_API_URL` (VQ backend) instead of `VITE_ACCOUNTS_API_URL`:** VQ has two API env vars. The session endpoint is on the accounts API, not VQ's own backend. Always use `VITE_ACCOUNTS_API_URL`.
- **Forgetting the `credentials: 'include'` on the SSO check:** Without it, the `ev_session` httpOnly cookie is not sent. The endpoint returns 401 silently and SSO never works.
- **Forgetting `credentials: 'include'` on the logout call:** Same issue — without it, the cookie is never cleared.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Auth state initialization | Manual session storage read + parse | `supabase.auth.onAuthStateChange` + `supabase.auth.getSession()` | Supabase handles persistence, refresh, and event dispatch |
| Session handoff from accounts API | Manual localStorage write | `supabase.auth.setSession({ access_token, refresh_token })` | Only correct way to initialize VQ's Supabase client; also handles expired tokens by auto-refreshing |
| Profile loading after SSO | Separate `fetchUserProfile()` call post-setSession | Rely on `onAuthStateChange` SIGNED_IN event | setSession fires SIGNED_IN which triggers the existing profile fetch |
| Toast/error UI | Any error component | Nothing | Locked decisions: all failures are silent, console.error only |

**Key insight:** VQ's auth is 100% event-driven through Supabase's `onAuthStateChange`. The SSO check's only job is to call `setSession()` — after that, VQ's existing machinery handles everything.

## Common Pitfalls

### Pitfall 1: `isAuthChecking` Race Between `onAuthStateChange` and `initSso`

**What goes wrong:** `onAuthStateChange` fires `INITIAL_SESSION` synchronously (with null session). `initSso` is async. If `isAuthChecking` is set to false in the `INITIAL_SESSION` handler (based on null), routes render before SSO check completes.

**Why it happens:** The `onAuthStateChange` callback fires immediately and synchronously when called during mount, but `initSso` is async and runs after.

**How to avoid:** Do NOT set `isAuthChecking = false` inside `onAuthStateChange`. Set it only inside `initSso` — in the "session already present" branch (fast path) and in the `finally` block of the SSO fetch (slow path). The `onAuthStateChange` handler should never touch `isAuthChecking`.

**Warning signs:** `PrivateRoute` briefly shows the route before redirecting to `/login` — or vice versa.

### Pitfall 2: Cross-Origin Request to `ev-accounts-api.onrender.com` (Not Proxied)

**What goes wrong:** VQ is deployed on Render as a static site — there is no Netlify proxy. The `VITE_ACCOUNTS_API_URL` is `https://ev-accounts-api.onrender.com`. Both the SSO session check and logout call are genuinely cross-origin requests.

**Why it matters:** Unlike Phase 45/46 where Netlify proxied `/api/*` to the accounts API (making it same-origin), VQ must make real cross-origin requests. This means:
1. The `credentials: 'include'` option on the fetch is mandatory (not just good practice)
2. The accounts API CORS config (`CORS_ORIGIN` env var in production) must include VQ's origin (`https://empowered-validation-quests.onrender.com` or the production domain)
3. The accounts API already has `credentials: true` in its cors config (confirmed from Phase 44) and exact-origin matching — VQ's production origin must be in `CORS_ORIGIN`

**How to avoid:** Verify the accounts API's Render `CORS_ORIGIN` env var includes VQ's production origin before deploying. The plan should include a render.yaml / Render dashboard update step for CORS_ORIGIN.

**Warning signs:** Browser console: "The value of the 'Access-Control-Allow-Origin' header in the response must not be the wildcard '*'" or "CORS policy: No 'Access-Control-Allow-Origin' header is present."

### Pitfall 3: `setSession` Requires Both Tokens

**What goes wrong:** Calling `supabase.auth.setSession({ access_token })` without `refresh_token` throws `AuthSessionMissingError` which propagates as an unhandled rejection if not caught.

**Why it happens:** The Phase 44 endpoint returns both tokens. If the response is malformed or only `access_token` is extracted, `setSession` will throw.

**How to avoid:** Always validate both tokens before calling `setSession`. The check in Pattern 1 above (`!ssoData?.access_token || !ssoData?.refresh_token`) prevents this.

**Warning signs:** Console shows `AuthSessionMissingError: Auth session missing!` on SSO check path.

### Pitfall 4: `isAuthChecking` Exported from Context

**What goes wrong:** `PrivateRoute` calls `useAuth()` to get `isAuthChecking`, but the type definition (`AuthContextValue`) doesn't include it — TypeScript error blocks compilation.

**Why it happens:** `AuthContextValue` is defined in `types/auth.ts` (or inline in `AuthContext.tsx`). The new field must be added to the type.

**How to avoid:** Add `isAuthChecking: boolean` to `AuthContextValue` type. Add `isAuthChecking` to the `AuthContext.Provider value` prop.

**Warning signs:** TypeScript compilation error: "Property 'isAuthChecking' does not exist on type 'AuthContextValue'."

### Pitfall 5: FeedPage and Public Routes Flash During Auth Check

**What goes wrong:** `PrivateRoute` is gated on `isAuthChecking`, but `FeedPage` and `LoginPage` are public routes NOT behind `PrivateRoute`. They render immediately with `session = null`, showing guest UI, then flip to authenticated UI when SSO completes.

**Why it matters:** Per locked decisions: "Hold all routes behind auth loading state on first render." But the locked decisions also say "Use VQ's existing app launch/loading state — no new loading treatment needed; SSO check slots into existing initialization."

**Resolution:** The locked decision says `PrivateRoute` holds protected routes. Public routes (Feed, Login) do NOT need to hold. The Header will briefly show "Sign in" before flipping to the user's name on the SSO success path — this is acceptable per "SSO check slots into existing initialization." Only `PrivateRoute` needs `isAuthChecking` gating.

**Warning signs:** This is not actually a bug per locked decisions, but the planner should document the expected behavior explicitly so implementers don't over-engineer.

### Pitfall 6: `useAuth()` TypeScript Error in `PrivateRoute` After Adding `isAuthChecking`

**What goes wrong:** `PrivateRoute.tsx` currently destructures `{ session }` from `useAuth()`. After adding `isAuthChecking` to the context, the destructure must be updated. If the type is not also updated, TypeScript will flag it.

**How to avoid:** Update the destructure in `PrivateRoute.tsx` to `{ session, isAuthChecking }`.

## Code Examples

### GET /api/auth/session — confirmed response shape (Phase 44)

```typescript
// Source: backend/src/routes/auth.ts (Phase 44)
// Success (200):
{ access_token: string, refresh_token: string }
// No session (401): empty body — res.status(401).end()
```

### supabase.auth.setSession — verified API signature (auth-js 2.98.0)

```typescript
// Source: @supabase/auth-js dist/main/GoTrueClient.js (installed in VQ)
const { data, error } = await supabase.auth.setSession({
  access_token: string,   // REQUIRED — throws AuthSessionMissingError if missing
  refresh_token: string,  // REQUIRED — throws AuthSessionMissingError if missing
});
// data.session — the initialized session (or null on failure)
// data.user — the user object (or null on failure)
// error — AuthError on invalid/expired tokens (not thrown; returned)
// Side effect: fires SIGNED_IN on onAuthStateChange if successful
```

### supabase.auth.getSession — for checking existing session

```typescript
// Source: @supabase/supabase-js v2 standard API
const { data } = await supabase.auth.getSession();
// data.session — Session | null
// null if no session stored (INITIAL_SESSION produced null)
```

### AuthContext.tsx — full modified shape

Key additions to existing file:
1. `const [isAuthChecking, setIsAuthChecking] = useState(true);`
2. SSO fetch logic after `onAuthStateChange` subscription
3. `isAuthChecking` in Provider value
4. Upgraded `signOut()` with pre-logout API call

### PrivateRoute.tsx — with isAuthChecking gate

```typescript
// Source: derived from existing PrivateRoute.tsx + CONTEXT.md decisions
export function PrivateRoute() {
  const { session, isAuthChecking } = useAuth();
  const location = useLocation();

  if (isAuthChecking) {
    return null; // Hold rendering — max 3s wait per locked decisions
  }

  if (!session) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  return <Outlet />;
}
```

## State of the Art

| Old Approach | New Approach (after Phase 47) | Notes |
|--------------|-------------------------------|-------|
| VQ requires explicit login | VQ silently inherits ev_session cookie | `supabase.auth.setSession()` is the handoff mechanism |
| `signOut()` = `supabase.auth.signOut()` only | `signOut()` = API logout + Supabase signout | Clears shared cookie |
| No auth loading gate | `isAuthChecking` gates PrivateRoute | Prevents premature redirect to /login |
| `onAuthStateChange` handles all auth init | SSO check + setSession feeds into `onAuthStateChange` | Event-driven; setSession fires SIGNED_IN automatically |

**Deprecated patterns being fixed:**
- `signOut()` without cookie clear — works for VQ-only auth, breaks cross-app SSO

## Open Questions

1. **VQ's production origin in accounts `CORS_ORIGIN`**
   - What we know: Phase 44 ships CORS with `credentials: true` and exact-origin matching. Accounts' `CORS_ORIGIN` env var must include VQ's production origin.
   - What's unclear: The current Render env var value for `CORS_ORIGIN` is not visible from the codebase. It may or may not already include VQ's origin.
   - Recommendation: The plan should include an explicit step: verify/add `https://empowered-validation-quests.onrender.com` (or the custom domain if one exists) to accounts' `CORS_ORIGIN` in Render dashboard. This is a deployment config step, not a code change.

2. **`isAuthChecking` renders null for protected routes during 3s window**
   - What we know: Locked decisions say "hold all routes" during SSO check. `PrivateRoute` returning null means authenticated users navigating directly to `/history` see a blank flash before content.
   - What's unclear: Whether the UX is acceptable or a minimal skeleton/spinner is preferred.
   - Recommendation: The locked decisions say "no new loading treatment" — `null` return is acceptable. The planner can note this explicitly. If the team later decides a spinner is needed, it can be added without changing the logic.

3. **`types/auth.ts` location of `AuthContextValue`**
   - What we know: `AuthContext.tsx` imports `AuthContextValue` from `@/types/auth`. We know `contexts/AuthContext.tsx` uses this type.
   - What was confirmed: The import `import type { AuthContextValue, UserProfile } from '@/types/auth'` is in `AuthContext.tsx` (line 4). The type file at `types/auth.ts` needs `isAuthChecking: boolean` added.
   - Recommendation: The plan should include a task step to update `types/auth.ts` alongside the context changes.

## Sources

### Primary (HIGH confidence)
- Read `/c/Validation Quests/frontend/src/contexts/AuthContext.tsx` — full auth provider, `onAuthStateChange` subscription, `fetchUserProfile`, `signOut` function confirmed
- Read `/c/Validation Quests/frontend/src/lib/supabase.ts` — single client instance, `createClient` with `supabaseUrl` + `supabaseAnonKey`, no custom options
- Read `/c/Validation Quests/frontend/src/lib/apiClient.ts` — `apiFetch` confirmed to NOT pass `credentials: 'include'`, uses `VITE_API_URL` (VQ backend, not accounts API)
- Read `/c/Validation Quests/frontend/src/routes/PrivateRoute.tsx` — current `{ session }` check, `Navigate` to `/login`, `state={{ from: location }}`
- Read `/c/Validation Quests/frontend/src/routes/router.tsx` — `PrivateRoute` wraps `/history`, `/users/:userId/history`, `/quests/:id/contest`, `/notifications`, `/profile`; feed/login are public
- Read `/c/Validation Quests/frontend/src/pages/LoginPage.tsx` — reads `location.state.from` for deep link restoration; already handles SSO case (session triggers navigate)
- Read `/c/Validation Quests/frontend/src/components/layout/Header.tsx` — calls `void signOut()` from `useAuth()`, no direct `supabase` calls in logout
- Read `/c/Validation Quests/frontend/vite.config.ts` — no proxy config; confirms cross-origin nature of API calls
- Read `/c/Validation Quests/render.yaml` — `VITE_ACCOUNTS_API_URL: https://ev-accounts-api.onrender.com`, `VITE_API_URL: https://empowered-validation-quests.onrender.com` — two separate backends
- Read `/c/Validation Quests/frontend/node_modules/@supabase/auth-js/dist/main/GoTrueClient.js` — `setSession()` requires both tokens, fires `SIGNED_IN`, returns `{ data, error }` (no throw for auth errors)
- Read `/c/EV-Accounts/backend/src/index.ts` — CORS config confirmed `credentials: true`, exact-origin matching from `CORS_ORIGIN` env var
- Read `/c/EV-Accounts/.planning/phases/44-accounts-api-sso-infrastructure/44-RESEARCH.md` — Phase 44 endpoint contract: `{ access_token, refresh_token }` on 200, empty body 401
- Read `/c/EV-Accounts/.planning/phases/46-essentials-compassv2-silent-sso/46-RESEARCH.md` — parallel SSO phase patterns; key difference is Phase 47 uses `setSession()` not `setToken()`
- Read `/c/Validation Quests/frontend/package.json` — `@supabase/supabase-js ^2.98.0` confirmed installed

### Secondary (MEDIUM confidence)
- `@supabase/auth-js` source inspection — `onAuthStateChange` fires `INITIAL_SESSION` synchronously on registration with existing stored session

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — read package.json directly; no new libraries needed
- Supabase setSession API: HIGH — read GoTrueClient.js source directly from installed node_modules
- AuthContext structure: HIGH — read AuthContext.tsx in full; all relevant state and handlers confirmed
- Cross-origin deployment: HIGH — read render.yaml directly; no proxy, confirmed two separate API origins
- CORS accounts config: HIGH — read accounts backend/src/index.ts; credentials: true already in place
- Pitfalls: HIGH — derived from direct code inspection + Phase 44/45/46 research patterns

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable domain — Supabase JS and React auth patterns change infrequently)
