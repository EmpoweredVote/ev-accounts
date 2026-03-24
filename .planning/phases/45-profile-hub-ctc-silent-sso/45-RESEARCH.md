# Phase 45: Profile Hub + CTC Silent SSO - Research

**Researched:** 2026-03-24
**Domain:** Frontend silent SSO — React/Zustand auth initialization, cross-origin credentialed fetch, spinner delay pattern
**Confidence:** HIGH

## Summary

This phase is a frontend integration task: two existing React apps (Profile Hub at `app/src` and CTC at `C:/Project Test/frontend/src`) need to call `GET /api/auth/session` on load, inherit the `ev_session` cookie set by Phase 44, and write the returned tokens into their respective localStorage + Zustand stores. Both apps already have auth initialization hooks (`App.tsx` useEffect for Profile Hub, `AuthInitializer.tsx` for CTC) — the work is inserting the SSO check into these existing initialization paths.

The CTC already has a full logout flow (`Header.tsx` calls `authService.logout()` + `clearAuth()` + `navigate('/login')`). It needs updating to: add `credentials: 'include'` to the logout call and show the "signed out" toast, then stay on the same page (remove `navigate`). Profile Hub's logout is currently a bare `clearAuth()` button in `DashboardPage.tsx` — it needs to become a proper API-calling logout with cookie clearing and the same toast.

Neither app has a toast library. Both apps use hand-rolled UI patterns. The toast for "You've been signed out" must be built inline — a simple fixed-position div with auto-dismiss, matching each app's existing style conventions.

**Primary recommendation:** Insert the SSO check as an async step at the top of each app's existing auth initializer, with a 150ms spinner delay via `setTimeout`, 3-second timeout via `Promise.race`, one retry on 5xx, and immediate fall-through on 401 or network error. Write tokens to the exact localStorage keys each app already uses (`ev_token` for Profile Hub, `ev_refresh_token` for CTC). Dispatch auth state using each app's existing `setAuth` store method.

## Standard Stack

No new libraries needed. Both apps already have everything required.

### Core (already installed)
| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `zustand` | Profile Hub: ^5.0.11, CTC: ^4.4.7 | Auth store state | Both apps use `useAuthStore` with `setAuth` / `clearAuth` methods |
| `react` | Profile Hub: ^18.3.1, CTC: ^18.2.0 | Component rendering | Both on React 18 |
| `react-router-dom` | Both: ^6.21.1 | Routing | Used for post-logout navigation in CTC |

### No New Installations Required

Both apps use Vite + React + Zustand + Tailwind. No toast library exists in either app — hand-roll the toast inline (matching each app's existing style patterns).

**Installation:**
```bash
# Nothing to install
```

## Architecture Patterns

### App File Map

**Profile Hub changes:**
```
app/src/
├── App.tsx                    # Add silent SSO check in mount useEffect
├── pages/DashboardPage.tsx    # Upgrade logout button: API call + cookie clear + toast
└── lib/api.ts                 # No changes needed (apiFetch already uses VITE_API_URL)
```

**CTC changes:**
```
C:/Project Test/frontend/src/
├── components/AuthInitializer.tsx   # Add SSO check branch before refresh token path
├── services/accountsApi.ts          # Add ssoSessionCheck() function with credentials: 'include'
└── components/layout/Header.tsx     # Update handleLogout: add credentials, toast, stay on page
```

### Pattern 1: Silent SSO Check with Spinner Delay

**What:** On mount, check if the app is already in an auth state. If not, call `GET /api/auth/session` with `credentials: 'include'`. Show spinner only if the check takes longer than 150ms.

**When to use:** At the start of auth initialization in both apps.

**Profile Hub implementation** — the mount `useEffect` in `App.tsx` currently has two branches: (1) hash fragment token, (2) localStorage `ev_token`. The SSO check inserts as branch (3) — only runs when no hash fragment AND no stored `ev_token`.

```typescript
// Pattern: delayed spinner + 3s timeout + 1 retry
async function silentSsoCheck(): Promise<{ access_token: string; refresh_token: string } | null> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 3000);

  try {
    const res = await fetch(`${API_BASE}/api/auth/session`, {
      credentials: 'include',
      signal: controller.signal,
    });
    clearTimeout(timeoutId);

    if (res.status === 401) return null; // not logged in elsewhere — fall through immediately

    if (!res.ok) {
      // 5xx — retry once after 1s
      await new Promise((r) => setTimeout(r, 1000));
      const retry = await fetch(`${API_BASE}/api/auth/session`, { credentials: 'include' });
      if (!retry.ok) return null;
      return retry.json();
    }

    return res.json();
  } catch {
    // Network error, timeout, CORS — fall through silently
    clearTimeout(timeoutId);
    return null;
  }
}
```

**Spinner delay — 150ms debounce:**
```typescript
// In Profile Hub App.tsx useEffect:
let spinnerTimer: ReturnType<typeof setTimeout> | undefined;
spinnerTimer = setTimeout(() => setLoading(true), 150);

const result = await silentSsoCheck();
clearTimeout(spinnerTimer);

if (result) {
  // Write tokens and fetch /me to hydrate user
  localStorage.setItem('ev_token', result.access_token);
  useAuthStore.setState({ accessToken: result.access_token });
  // ... apiFetch('/account/me') to get User shape
} else {
  setLoading(false);
}
```

**Key detail:** `setLoading(true)` is the Profile Hub pattern — it already initializes `isLoading: true`, so the spinner already shows on first render. The 150ms delay is only needed to PREVENT showing a spinner that wasn't there before. For Profile Hub, where `isLoading` starts `true`, the pattern is actually: keep `isLoading: true` during the SSO check (it already is), and the 150ms applies to NOT setting loading if we resolve fast. For CTC, `AuthInitializer` renders a spinner when `isLoading` is true — same logic applies.

### Pattern 2: CTC SSO Check — Guard Against Conflict

**What:** CTC decision: only run SSO check if `ev_refresh_token` is absent from localStorage.

**When to use:** As the first branch in `AuthInitializer.tsx`'s `initializeAuth`.

```typescript
// In AuthInitializer.tsx — existing initializeAuth:
const storedRefresh = localStorage.getItem('ev_refresh_token');

if (!storedRefresh) {
  // No local session — try silent SSO before giving up
  const ssoResult = await silentSsoCheck();

  if (ssoResult) {
    // Write using CTC's existing key names
    localStorage.setItem('ev_refresh_token', ssoResult.refresh_token);
    // Set access token in store — then fetch profile + admin status as existing code does
    useAuthStore.getState().setAuth(ssoResult.access_token, {
      id: '', email: '', tier: 'inform', // minimal; full profile fetched next
    });
    // Proceed with parallel profile + admin fetch (reuse existing code)
    // ...
  } else {
    // No cookie session either — resolve unauthenticated
    clearAuth();
    setLoading(false);
    useAuthStore.getState().setTierResolved(true);
    return;
  }
}
// Existing ev_refresh_token path continues below unchanged...
```

**Why this structure matters:** The existing `AuthInitializer` has a fully built-out auth success path (parallel `fetchAccountProfile` + admin status check, setting `tierResolved`, etc.). The SSO check should feed INTO this path, not duplicate it. Write `ev_refresh_token` to localStorage first, then fall through to the existing refresh token path — code reuse, not duplication.

**Simpler alternative:** After a successful SSO check, write the refresh token to localStorage and then let the existing `storedRefresh` path handle the rest — simply `return initializeAuth()` (recursive call, or restructure so the storedRefresh branch runs after SSO write).

### Pattern 3: Logout Upgrade

**Profile Hub — DashboardPage.tsx:**

Current: `onClick={clearAuth}` — no API call, no cookie clearing, no toast.

Required upgrade:
```typescript
const handleLogout = async () => {
  try {
    await fetch(`${API_BASE}/api/auth/logout`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
      },
    });
  } catch {
    // Network failure — still clear local auth
  }
  clearAuth();
  setToastVisible(true);  // "You've been signed out"
  setTimeout(() => setToastVisible(false), 3000);
};
```

**CTC — Header.tsx:**

Current `handleLogout`:
```typescript
const handleLogout = async () => {
  try {
    if (accessToken) await authService.logout(accessToken);  // no credentials: 'include'
  } catch { /* ignore */ } finally {
    clearAuth();
    navigate('/login');  // ← must change to "stay on page"
  }
};
```

Required changes:
1. Update `authService.logout()` to add `credentials: 'include'` to the fetch (or call the accounts API directly with credentials in handleLogout)
2. Remove `navigate('/login')` — stay on current page
3. Show "You've been signed out" toast

Note: `accountsApiFetch` in `accountsApi.ts` explicitly does NOT include `credentials: 'include'` (comment in the file says "Do NOT use credentials: 'include'"). For logout, the cookie must be cleared, so this one call needs credentials. Either: (a) add a separate `accountsApiCredentialedFetch` function, or (b) pass `credentials: 'include'` directly in `authService.logout()` options.

### Pattern 4: Toast Component (Hand-Rolled)

**Profile Hub** — uses Tailwind v4. Add inline toast state to `DashboardPage.tsx` (the component that has the logout button):

```tsx
{/* Fixed bottom-right toast */}
{toastVisible && (
  <div className="fixed bottom-6 right-6 bg-gray-900 text-white text-sm px-4 py-3 rounded-lg shadow-lg z-50">
    You&apos;ve been signed out
  </div>
)}
```

**CTC** — uses inline CSS style objects (Bebas Neue font, brand colors). Match the existing admin toast style from `FlagDetailPanel.tsx`:

```tsx
{toastVisible && (
  <div style={{
    position: 'fixed',
    bottom: '24px',
    right: '24px',
    backgroundColor: '#1C1510',
    color: '#ECE7D9',
    padding: '12px 16px',
    borderRadius: '2px',
    border: '1px solid #3D2E22',
    fontFamily: "'Lora', Georgia, serif",
    fontSize: '13px',
    zIndex: 50,
    boxShadow: '0 4px 16px rgba(0,0,0,0.4)',
  }}>
    You&apos;ve been signed out
  </div>
)}
```

### Pattern 5: Endpoint URL for SSO Check

**Profile Hub:** `apiFetch` uses `VITE_API_URL/api` or `/api` (Vite proxy). For the SSO check `fetch`, use the same base: `import.meta.env.VITE_API_URL ? ${import.meta.env.VITE_API_URL}/api/auth/session : /api/auth/session`.

**CTC:** `accountsApiFetch` uses `VITE_EMPOWERED_ACCOUNTS_URL || 'http://localhost:3001'`. The SSO session endpoint is on the accounts API, so use `${ACCOUNTS_API_URL}/api/auth/session` with `credentials: 'include'`.

The key difference: Profile Hub talks to its own backend (same origin via proxy), while CTC talks cross-origin to the accounts API. The CORS `credentials: true` update from Phase 44 enables this for CTC.

### Anti-Patterns to Avoid

- **Writing `access_token` to CTC's `ev_refresh_token` key:** CTC stores the refresh token under `ev_refresh_token`. The SSO check returns both `access_token` and `refresh_token`. Write `refresh_token` to `ev_refresh_token`, use `access_token` for the store's `accessToken` field.
- **Calling SSO check when `ev_refresh_token` already exists:** The locked decision says skip the check if a local session exists. Violating this disrupts existing CTC sessions.
- **Showing spinner immediately on every load:** The 150ms delay prevents spinner flash on fast connections. `isLoading` starts `true` in both apps — the goal is to NOT set it true artificially if the check resolves fast. Both apps already start in loading state, so the effective pattern is: start a 150ms timer, if SSO resolves before timer fires, clear timer (user never saw spinner transition). If timer fires first, spinner is already showing (it was there from initial load). The 150ms delay prevents the edge case of `isLoading` toggling fast on/off.
- **Retrying on 401:** 401 means no session cookie — retry will return the same result. Only retry on 5xx (server error, worth retrying once).
- **Not including `credentials: 'include'`:** The `ev_session` cookie is HttpOnly — it cannot be read by JS, only sent automatically. Without `credentials: 'include'`, the browser strips the cookie from the request. This is the #1 failure mode.
- **Duplicate auth initialization logic in CTC:** Don't duplicate the `fetchAccountProfile` + admin status fetch in the SSO branch. Funnel through the existing `ev_refresh_token` path by writing the token first.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Toast notifications | A full toast system with queue/stack | A single-use `useState` boolean + fixed div | Phase 45 needs exactly one toast message; overkill is waste |
| Token refresh | Another token exchange function | The existing `exchangeRefreshToken()` in CTC's `accountsApi.ts` | Already handles rotation, error cases, localStorage write |
| Auth state management | New auth patterns | Existing `setAuth` / `clearAuth` / `setTierResolved` in each app's store | Both stores are already correct; SSO just feeds them |
| Retry logic | A retry library | Inline `await new Promise(r => setTimeout(r, 1000))` + second fetch | One retry is trivial inline; no library needed |

**Key insight:** This phase is 100% wiring. Every primitive (fetch, Zustand store, Vite proxy, cookie handling) is already in place. The planner should produce tasks that insert SSO check logic into existing files, not create new infrastructure.

## Common Pitfalls

### Pitfall 1: CTC `accountsApiFetch` has `credentials: 'include'` explicitly excluded

**What goes wrong:** Using `accountsApiFetch` for the session check — it explicitly omits credentials and has a comment saying NOT to include them.

**Why it happens:** `accountsApiFetch` was designed for Bearer token calls, not cookie-based calls.

**How to avoid:** Add a dedicated `ssoSessionCheck()` function in `accountsApi.ts` that uses native `fetch` with `credentials: 'include'`. Do NOT modify `accountsApiFetch` (it's correct for its purpose).

**Warning signs:** Session endpoint returns 401 in CTC even when cookie is present — because the cookie was never sent.

### Pitfall 2: CTC already has logout — but it navigates to `/login`

**What goes wrong:** Leaving `navigate('/login')` in CTC's `handleLogout`. Per locked decisions, after logout the user stays on the current page and sees unauthenticated state.

**Why it happens:** The existing logout pre-dates the SSO decision.

**How to avoid:** Remove `navigate('/login')` from `handleLogout`. The component will re-render with `isAuthenticated: false` and show the appropriate unauthenticated UI.

**Warning signs:** After logout from CTC, user is redirected to `/login` page instead of staying put.

### Pitfall 3: Profile Hub logout calls `clearAuth` only — no cookie clearing

**What goes wrong:** `DashboardPage.tsx` currently has `onClick={clearAuth}` — a bare call. This clears local state but does NOT call `POST /api/auth/logout` and does NOT clear the `ev_session` cookie. After "logging out" from Profile Hub, the CTC SSO check would immediately re-authenticate the user on next load.

**Why it happens:** Logout predates SSO; local-only auth didn't need a server call.

**How to avoid:** Replace the bare `onClick={clearAuth}` with a proper `handleLogout` async function that calls `POST /api/auth/logout` (with `credentials: 'include'`) before `clearAuth()`.

**Warning signs:** After "signing out" from Profile Hub, opening CTC signs the user back in automatically.

### Pitfall 4: Profile Hub `apiFetch` doesn't support `credentials: 'include'`

**What goes wrong:** The `apiFetch` helper in Profile Hub has no `credentials: 'include'`. It's fine for regular Bearer token calls, but the SSO endpoint requires cookie transmission.

**Why it happens:** `apiFetch` was designed for authenticated calls, not for the unauthenticated SSO check.

**How to avoid:** Use native `fetch` directly for the SSO check call (not `apiFetch`). The SSO check is one call that runs before auth is established — `apiFetch` is irrelevant here. For the logout call, also use native `fetch` with `credentials: 'include'` + manual Authorization header, or extend `apiFetch` to accept a `credentials` option.

### Pitfall 5: `isLoading` timing in Profile Hub

**What goes wrong:** In `App.tsx`, `setLoading(false)` is called in the `else` branch (no stored token). If SSO check is inserted before this but runs async, there's a window where `isLoading` is true (initial state) but the SSO check hasn't resolved yet. The AuthGuard/spinner shows. This is actually CORRECT behavior — just ensure `setLoading(false)` is always called at the end of every code path (including SSO check failure).

**How to avoid:** Every code path in the mount useEffect must call `setLoading(false)` or `clearAuth()` (which sets isLoading: false). Missing a branch leaves the app stuck on the spinner forever.

**Warning signs:** App shows infinite spinner on first load for unauthenticated users.

### Pitfall 6: Token key mismatch between apps

**What goes wrong:** CTC uses `ev_refresh_token` for the refresh token. Profile Hub uses `ev_token` for the access token. Writing the wrong token to the wrong key causes immediate auth failure.

**Correct mapping:**
- **Profile Hub:** store `access_token` in `localStorage('ev_token')` + Zustand `accessToken`
- **CTC:** store `refresh_token` in `localStorage('ev_refresh_token')` + `access_token` in Zustand `accessToken`

CTC's existing `exchangeRefreshToken` path writes to `ev_refresh_token` — the SSO check must do the same.

## Code Examples

### GET /api/auth/session — confirmed response shape (Phase 44)

```typescript
// Source: backend/src/routes/auth.ts (Phase 44, commit fac2d91)
// Response on 200:
{
  access_token: string;   // new Supabase JWT access token
  refresh_token: string;  // new refresh token (Supabase rotated it)
}
// Response on 401: empty body (no JSON)
```

### CTC: ssoSessionCheck function (add to accountsApi.ts)

```typescript
// Source: derived from Phase 44 endpoint contract + locked decisions
export async function ssoSessionCheck(): Promise<{
  access_token: string;
  refresh_token: string;
} | null> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 3000);

  const attemptFetch = async () =>
    fetch(`${ACCOUNTS_API_URL}/api/auth/session`, {
      credentials: 'include',
      signal: controller.signal,
    });

  try {
    const res = await attemptFetch();
    clearTimeout(timeoutId);

    if (res.status === 401) return null; // not logged in elsewhere
    if (res.ok) return res.json();

    // 5xx: retry once after 1s
    await new Promise((r) => setTimeout(r, 1000));
    const retry = await fetch(`${ACCOUNTS_API_URL}/api/auth/session`, {
      credentials: 'include',
    });
    if (!retry.ok) return null;
    return retry.json();
  } catch {
    clearTimeout(timeoutId);
    return null; // network error, timeout, CORS — fall through silently
  }
}
```

### Profile Hub: silentSsoCheck function (add inline in App.tsx or extract to lib/api.ts)

```typescript
// ACCOUNTS_API is the accounts API base URL — same origin in Profile Hub (proxied)
const ACCOUNTS_SSO_URL = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api/auth/session`
  : '/api/auth/session';

async function silentSsoCheck(): Promise<{ access_token: string; refresh_token: string } | null> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 3000);

  try {
    const res = await fetch(ACCOUNTS_SSO_URL, {
      credentials: 'include',
      signal: controller.signal,
    });
    clearTimeout(timeoutId);

    if (res.status === 401) return null;
    if (res.ok) return res.json();

    await new Promise((r) => setTimeout(r, 1000));
    const retry = await fetch(ACCOUNTS_SSO_URL, { credentials: 'include' });
    if (!retry.ok) return null;
    return retry.json();
  } catch {
    clearTimeout(timeoutId);
    return null;
  }
}
```

### CTC: AuthInitializer — SSO-augmented structure

```typescript
// Source: inspection of AuthInitializer.tsx
const initializeAuth = async () => {
  const storedRefresh = localStorage.getItem('ev_refresh_token');

  if (!storedRefresh) {
    // NEW: try silent SSO check before giving up
    const ssoResult = await ssoSessionCheck();

    if (!ssoResult) {
      // No local session, no cookie session — unauthenticated
      clearAuth();
      setLoading(false);
      useAuthStore.getState().setTierResolved(true);
      return;
    }

    // SSO success: write refresh token so the existing path handles the rest
    localStorage.setItem('ev_refresh_token', ssoResult.refresh_token);
    // NOTE: do NOT return here — fall through to the existing ev_refresh_token path below
    // The existing path calls exchangeRefreshToken() which reads ev_refresh_token from localStorage
  }

  // Existing path: exchange stored refresh token for new access token
  // (unchanged — handles profile fetch, admin status, setTierResolved, etc.)
  try {
    const data = await exchangeRefreshToken();
    // ... existing code unchanged ...
  }
};
```

**Simplest approach:** After writing `ev_refresh_token` to localStorage, call `initializeAuth()` again (recursion with guard) OR restructure by extracting the refresh path into a shared inner function.

### Profile Hub: App.tsx SSO-augmented mount useEffect

```typescript
// Existing branch order: (1) hash fragment, (2) stored ev_token, (3) SSO check [NEW], (4) unauthenticated
useEffect(() => {
  const hash = window.location.hash;
  if (hash.includes('access_token=')) {
    // ... existing hash fragment handling (unchanged) ...
    return;
  }

  const token = getStoredToken();
  if (token) {
    // ... existing token restore path (unchanged) ...
    return;
  }

  // NEW: no local token — try silent SSO
  (async () => {
    const ssoResult = await silentSsoCheck();
    if (ssoResult) {
      localStorage.setItem('ev_token', ssoResult.access_token);
      useAuthStore.setState({ accessToken: ssoResult.access_token });
      try {
        const me = await apiFetch<MeResponse>('/account/me');
        const user: User = {
          id: me.id,
          email: me.email,
          tier: me.tier,
          displayName: me.display_name,
          completedOnboarding: me.completed_onboarding,
          locationConsent: me.location_consent,
        };
        setAuth(ssoResult.access_token, user);
      } catch {
        clearAuth();
      }
    } else {
      setLoading(false);  // existing: resolves spinner for unauthenticated users
    }
  })();
}, []);
```

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| Hash fragment token passing (Profile Hub `App.tsx`) | Silent SSO via HttpOnly cookie | Phase 44 adds the cookie-based path; hash fragment remains for backward compat |
| CTC direct Supabase refresh (`exchangeRefreshToken` calls Supabase Auth endpoint) | CTC still uses direct Supabase refresh for existing sessions; SSO check via accounts API for new sessions | Hybrid: existing sessions use their own refresh path; SSO check bootstraps NEW sessions |
| No cross-app auth | ev_session cookie enables cross-app auth after Phase 44+45 | Phase 45 is the client side of what Phase 44 built server-side |

**Current CTC logout:** calls `authService.logout()` (no credentials, no cookie clear) + `navigate('/login')`. After this phase: calls logout with `credentials: 'include'`, clears cookie server-side, stays on page.

**Current Profile Hub logout:** bare `clearAuth()` button click. After this phase: async handler that calls `POST /logout` with credentials, then `clearAuth()`.

## Open Questions

1. **Profile Hub `apiFetch` — should it support `credentials: 'include'`?**
   - What we know: `apiFetch` has no credentials option. Logout via `POST /api/auth/logout` needs credentials for cookie clearing.
   - What's unclear: Whether to extend `apiFetch` or use native fetch for the two credential-needed calls (session check + logout).
   - Recommendation: Use native `fetch` for both the SSO check and logout in Profile Hub. These are edge-case calls at app boundaries; not worth extending `apiFetch` for two callsites.

2. **CTC `authService.logout()` vs direct fetch for logout**
   - What we know: `authService.logout()` calls `accountsApiFetch` which explicitly omits credentials. The comment says "DO NOT use credentials: 'include'."
   - What's unclear: Whether to modify `authService.logout()` or bypass it for the SSO-aware logout.
   - Recommendation: Update `authService.logout()` to accept an optional `withCredentials: boolean` parameter, or add a dedicated `logoutWithCookieClear()` function. The cleanest path is adding a `withCredentials` option to `accountsApiFetch` so logout can pass it through.

3. **Profile Hub DashboardPage `accessToken` availability**
   - What we know: `DashboardPage.tsx` calls `const { user, clearAuth } = useAuthStore()` — does not destructure `accessToken`.
   - What's unclear: Whether `accessToken` should be added to the destructure for the logout API call.
   - Recommendation: Add `accessToken` to the `useAuthStore()` destructure in `DashboardPage.tsx`. The logout API call needs it for the `Authorization` header (even though Phase 44 clears the cookie regardless of JWT validity).

## Sources

### Primary (HIGH confidence)
- Read `C:/EV-Accounts/app/src/App.tsx` — current Profile Hub auth initialization, localStorage key `ev_token`, `MeResponse` shape
- Read `C:/EV-Accounts/app/src/store/authStore.ts` — `setAuth(token, user)` signature, `clearAuth()` removes `ev_token`
- Read `C:/EV-Accounts/app/src/components/AuthGuard.tsx` — spinner pattern (`border-t-transparent rounded-full animate-spin`), redirect logic
- Read `C:/EV-Accounts/app/src/pages/DashboardPage.tsx` — current logout is bare `onClick={clearAuth}`, no API call
- Read `C:/EV-Accounts/app/src/lib/api.ts` — `apiFetch` uses `VITE_API_URL/api` or `/api` proxy, no `credentials`
- Read `C:/Project Test/frontend/src/components/AuthInitializer.tsx` — SSO insertion point, `ev_refresh_token` key, `exchangeRefreshToken()` path, existing profile+admin fetch pattern
- Read `C:/Project Test/frontend/src/store/authStore.ts` — `setAuth(token, user, extras)`, `clearAuth()` removes `ev_refresh_token`, `tierResolved` pattern
- Read `C:/Project Test/frontend/src/services/accountsApi.ts` — `ACCOUNTS_API_URL`, `accountsApiFetch` explicitly excludes credentials, `exchangeRefreshToken()` calls Supabase directly
- Read `C:/Project Test/frontend/src/services/authService.ts` — `authService.logout()` uses `accountsApiFetch` (no credentials)
- Read `C:/Project Test/frontend/src/components/layout/Header.tsx` — CTC has logout button in hamburger menu, calls `authService.logout()` + `clearAuth()` + `navigate('/login')`
- Read `C:/EV-Accounts/.planning/phases/44-accounts-api-sso-infrastructure/44-02-SUMMARY.md` — confirms `GET /api/auth/session` returns `{ access_token, refresh_token }`, 401 is empty body
- Read `C:/EV-Accounts/backend/src/routes/auth.ts` (grep) — confirmed endpoint exists, cookie options pattern
- Read `C:/Project Test/frontend/package.json` — no toast library; framer-motion present but not for SSO
- Read `C:/EV-Accounts/app/package.json` — no toast library; only zustand, react, react-router, tailwind

### Secondary (MEDIUM confidence)
- Vite proxy config in both apps — `/api` proxied to backend; CTC needs direct `ACCOUNTS_API_URL` for cross-origin calls
- CTC hand-rolled Toast pattern in `FlagDetailPanel.tsx` — inline style conventions confirmed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — read both package.json files; no new libraries needed
- Architecture: HIGH — read all relevant source files; insertion points confirmed
- CTC auth dispatch pattern: HIGH — read `AuthInitializer.tsx` and `authStore.ts` fully; pattern clear
- Profile Hub auth init: HIGH — read `App.tsx` fully; insertion point clear
- Toast implementation: HIGH — both apps use hand-rolled patterns; no library present
- Pitfalls: HIGH — derived from direct code inspection, not speculation

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable domain — auth patterns and Zustand API change infrequently)
