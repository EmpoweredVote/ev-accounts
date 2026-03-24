# Phase 46: Essentials + CompassV2 Silent SSO - Research

**Researched:** 2026-03-24
**Domain:** Frontend silent SSO — React Context-based auth initialization, cross-origin credentialed fetch, Netlify proxy cookie handling
**Confidence:** HIGH

## Summary

Phase 46 replicates the Phase 45 silent SSO pattern into two additional React apps: Essentials (`C:/Transparent Motivations/essentials`) and CompassV2 (`C:/EV-CompassV2`). Both apps use React Context (not Zustand) for auth state. Both use an identical `auth.js` module (same code verbatim) with a `TOKEN_KEY = 'ev_token'`, `getToken()`, `clearToken()`, `setToken()`, `extractHashToken()`, `apiFetch()`, and `publicFetch()`. Auth initialization is embedded in a `useEffect` inside `CompassProvider` in each app's `CompassContext.jsx`. Neither app has a standalone `AuthInitializer` component.

The key structural difference from Phase 45 targets: auth state in these apps lives in `CompassContext` (not Zustand), and `isLoggedIn`/`username` are plain React `useState` values. The SSO check inserts at the same logical point — the existing `useEffect` that runs `extractHashToken()` then checks `getToken()` before calling `/account/me`. Both apps are deployed on Netlify with `/api/*` proxied to `https://ev-accounts-api.onrender.com/api/:splat`, so `GET /api/auth/session` resolves same-origin with the proxy forwarding the cookie.

Logout in both apps already calls `POST /auth/logout` via `apiFetch` but does NOT pass `credentials: 'include'`, so the `ev_session` cookie is never cleared. The fix is the same for both: add `credentials: 'include'` to the logout fetch call. Essentials' logout lives in `CompassContext.jsx` (`logout` function). CompassV2's logout lives in `Layout.jsx` (`logout` function) and there is a second duplicate logout in `Home.jsx` (stub page, safe to update in parallel).

**Primary recommendation:** Insert the SSO check as a new async branch in the existing auth `useEffect` in each app's `CompassContext.jsx`. Add `credentials: 'include'` to each app's logout fetch call. No new files, no new libraries, no new state shape — pure wiring into existing patterns.

## Standard Stack

No new libraries needed. Both apps already have everything required.

### Core (already installed)
| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `react` | ^19.1.x | Component rendering | Both apps on React 19 |
| `react-router-dom` / `react-router` | ^7.x | Routing | Essentials uses `react-router-dom`, CompassV2 uses `react-router` |
| `vite` | ^6–7 | Build tool | Both use Netlify `/api` proxy — no CORS issue for SSO check |

### No New Installations Required

Neither app has Zustand — both use React Context. No toast library exists in either app. Per locked decisions, logout is silent (no toast needed for Phase 46 — contrast with Phase 45 which required a "You've been signed out" toast). The context says "silent upgrade" with no notification.

**Installation:**
```bash
# Nothing to install
```

## Architecture Patterns

### App File Map

**Essentials changes:**
```
C:/Transparent Motivations/essentials/src/
├── contexts/CompassContext.jsx   # Insert SSO check in auth useEffect + add credentials to logout
└── lib/auth.js                   # No changes needed (apiFetch already uses VITE_API_URL)
```

**CompassV2 changes:**
```
C:/EV-CompassV2/src/
├── components/CompassContext.jsx  # Insert SSO check in auth useEffect
├── components/Layout.jsx          # Add credentials: 'include' to logout fetch
└── pages/Home.jsx                 # Update duplicate logout (add credentials: 'include')
```

### Pattern 1: Where Auth Initialization Lives (both apps)

Both `CompassContext.jsx` files have an identical auth bootstrap `useEffect`:

```javascript
// Source: both CompassContext.jsx files (verified by inspection)
useEffect(() => {
  extractHashToken();          // Synchronous — extract token from URL hash
  if (!getToken()) return;     // If no token, skip /account/me check → unauthenticated state
  publicFetch('/account/me')
    .then(r => {
      if (r.status === 401) { clearToken(); return null; }
      return r.ok ? r.json() : null;
    })
    .then(data => {
      if (data) {
        setIsLoggedIn(true);
        setUsername(data.display_name || null);
      }
    })
    .catch(() => {});
}, []);
```

The SSO check inserts in the `if (!getToken()) return;` branch. Instead of returning immediately, it runs the silent SSO check, and if successful, sets the token via `setToken()` and proceeds to `/account/me`.

### Pattern 2: SSO Check Function

Identical to Phase 45's pattern. Use native `fetch` (not `apiFetch` — `apiFetch` doesn't pass `credentials: 'include'`). The endpoint is `/api/auth/session` which resolves via Netlify proxy (same origin — no cross-origin issue).

```javascript
// Source: derived from Phase 45 pattern + Phase 44 endpoint contract
async function silentSsoCheck() {
  const API_BASE = import.meta.env.VITE_API_URL
    ? `${import.meta.env.VITE_API_URL.replace(/\/+$/, '')}/api`
    : '/api';
  const url = `${API_BASE}/auth/session`;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 2000);

  const attemptFetch = () =>
    fetch(url, { credentials: 'include', signal: controller.signal });

  try {
    const res = await attemptFetch();
    clearTimeout(timeoutId);
    if (res.status === 401) return null;
    if (res.ok) return res.json();
    // 5xx: retry once after 1s
    await new Promise((r) => setTimeout(r, 1000));
    const retry = await fetch(url, { credentials: 'include' });
    if (!retry.ok) return null;
    return retry.json();
  } catch {
    clearTimeout(timeoutId);
    return null; // timeout, network error — fall through silently
  }
}
```

**Timeout:** 2 seconds (per locked decisions — context says 2-second timeout, Phase 45 used 3 seconds; use 2 seconds for Phase 46).

**URL construction note:** Both apps' `auth.js` constructs `API_BASE` as `VITE_API_URL/api` or `/api`. The session endpoint is `/api/auth/session`. So the path passed to `fetch` should use the same `API_BASE` construction. Do NOT import `apiFetch` for this — it prepends `/api` and sets `Content-Type`, but it does not pass `credentials: 'include'`.

### Pattern 3: Augmented Auth useEffect

The modified `useEffect` in both `CompassContext.jsx` files:

```javascript
// Source: Phase 45 pattern adapted to React Context auth bootstrap
useEffect(() => {
  extractHashToken();

  const token = getToken();
  if (token) {
    // Existing path: token present — validate with /account/me
    publicFetch('/account/me')
      .then(r => {
        if (r.status === 401) { clearToken(); return null; }
        return r.ok ? r.json() : null;
      })
      .then(data => {
        if (data) {
          setIsLoggedIn(true);
          setUsername(data.display_name || null);
          // Essentials also sets: data.completed_onboarding ? localStorage.setItem("help_seen", "true")
        }
      })
      .catch(() => {});
    return;
  }

  // NEW: no local token — try silent SSO check
  silentSsoCheck().then(result => {
    if (!result) return; // No session — stay in unauthenticated state (already the default)

    // SSO success: store token, then validate via /account/me
    setToken(result.access_token);
    publicFetch('/account/me')
      .then(r => {
        if (r.status === 401) { clearToken(); return null; }
        return r.ok ? r.json() : null;
      })
      .then(data => {
        if (data) {
          setIsLoggedIn(true);
          setUsername(data.display_name || null);
          // CompassV2 also: data.completed_onboarding && localStorage.setItem("help_seen", "true")
        }
      })
      .catch(() => {});
  });
}, []);
```

**Why `publicFetch` (not `apiFetch`) for the /account/me call after SSO:** `publicFetch` does not redirect to login on 401 — it returns the raw response. `apiFetch` would call `redirectToLogin()` on 401, which is wrong in this silent initialization path. This is already the pattern in the existing code.

**`compassLoading` note (Essentials only):** Essentials' `CompassContext` has a `compassLoading` state that starts `true` and is set to `false` in the `finally` block of `loadAll()`. This `loadAll` function runs in a SEPARATE `useEffect` — not the auth `useEffect`. The auth `useEffect` does not control `compassLoading`. Therefore: the SSO check runs independently and does not delay the main data load. This is correct behavior per locked decisions (soft block = SSO check before unauthenticated render). The `compassLoading` spinner from `loadAll` provides the natural loading gate.

**`compassLoading` note (CompassV2):** CompassV2 does NOT have a `compassLoading` state. Auth state (`isLoggedIn`) starts as `false` and renders guest state immediately. The locked decision says "soft block" — hold unauthenticated render while SSO check fires. CompassV2 does NOT currently have any loading gate for auth. To implement the soft block, CompassV2 needs an `authChecking` state (boolean, starts `true`, set to `false` when auth `useEffect` completes). Components that should not render in guest mode until the check completes should gate on `authChecking`. The simplest approach: add `authChecking` to `CompassContext` and export it; consumers can check it.

### Pattern 4: Logout Upgrade — Add `credentials: 'include'`

**Essentials — `CompassContext.jsx` `logout` function (current):**
```javascript
const logout = async () => {
  try {
    await apiFetch('/auth/logout', { method: 'POST' });
  } catch (err) {
    console.error('Logout error:', err);
  }
  clearToken();
  setIsLoggedIn(false);
  setUserName(null);
  setUserAnswers([]);
  setSelectedTopics([]);
  setVerdicts({});
};
```

Issue: `apiFetch` does not pass `credentials: 'include'`. The logout call never clears the `ev_session` cookie.

Fix: Use native `fetch` with `credentials: 'include'` instead of `apiFetch`. The locked decision says: clear local state regardless of API call success.

```javascript
const logout = async () => {
  const API_BASE = import.meta.env.VITE_API_URL
    ? `${import.meta.env.VITE_API_URL.replace(/\/+$/, '')}/api`
    : '/api';
  const token = getToken();
  try {
    await fetch(`${API_BASE}/auth/logout`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    });
  } catch {
    // Network failure — still clear local state
  }
  clearToken();
  setIsLoggedIn(false);
  setUserName(null);
  setUserAnswers([]);
  setSelectedTopics([]);
  setVerdicts({});
};
```

**CompassV2 — `Layout.jsx` `logout` function (current):**
```javascript
const logout = () => {
  apiFetch('/auth/logout', { method: "POST" })
    .then((res) => {
      if (!res || !res.ok) throw new Error("Logout failed");
      return res.text();
    })
    .then(() => {
      clearToken();
      // clears localStorage keys + sets state
      navigate("/");
    })
    .catch((err) => {
      console.error(err);
      clearToken();
      navigate("/");
    });
};
```

Issues:
1. `apiFetch` does not pass `credentials: 'include'`
2. `navigate("/")` navigates away on logout — per locked decisions, users stay on current page

Fix: Replace `apiFetch` with native `fetch` + `credentials: 'include'`. Remove `navigate("/")`.

```javascript
const logout = async () => {
  const API_BASE = import.meta.env.VITE_API_URL
    ? `${import.meta.env.VITE_API_URL.replace(/\/+$/, '')}/api`
    : '/api';
  const token = getToken();
  try {
    await fetch(`${API_BASE}/auth/logout`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    });
  } catch {
    // Network failure — still clear local state
  }
  clearToken();
  localStorage.removeItem("compareUser");
  localStorage.removeItem("invertedSpokes");
  localStorage.removeItem("selectedTopics");
  localStorage.removeItem("answers");
  localStorage.removeItem("writeIns");
  setSelectedTopics([]);
  setAnswers({});
  setWriteIns({});
  setIsLoggedIn(false);
  // No navigate() — stay on current page per locked decisions
};
```

**CompassV2 `Home.jsx` duplicate logout:** `Home.jsx` has a separate `logout` function that also calls `apiFetch('/auth/logout')` and navigates. This is a stub page (`<h1>Hello, world :)</h1>`) but still needs the same fix. Update to use native fetch with credentials and remove `navigate("/")`.

### Anti-Patterns to Avoid

- **Using `apiFetch` for the SSO session check:** `apiFetch` does not pass `credentials: 'include'`, so the `ev_session` cookie is never sent. The session endpoint returns 401 silently and the SSO check always fails.
- **Using `apiFetch` for logout:** Same issue — cookie is never cleared, leading to re-authentication on next page load.
- **Calling `redirectToLogin()` in the SSO check failure path:** `apiFetch` calls `redirectToLogin()` on 401. This is wrong during the silent SSO check — a 401 means "no cookie session" not "expired token." Use `publicFetch` or native `fetch`.
- **Blocking `compassLoading` on SSO check (Essentials):** The `compassLoading` gate in Essentials comes from the `loadAll` function in a separate `useEffect`. Do NOT move the SSO check into `loadAll` or delay `compassLoading` settlement waiting for SSO. The SSO check is fast; if it races with `loadAll`, the worst outcome is the API fetches happen before auth is resolved — acceptable for public data.
- **Forgetting `authChecking` state in CompassV2:** CompassV2 has no loading gate for auth. Without an `authChecking` state, the app renders guest UI immediately before the SSO check completes, producing the exact mid-render swap the locked decisions prohibit.
- **Navigating away on logout:** Both apps currently call `navigate()` after logout. Remove these per locked decisions — user stays on the current page.
- **Duplicating the `/account/me` fetch logic:** After SSO token write, the existing `/account/me` path (using `publicFetch`) should be reused — do NOT write a separate user-fetching flow in the SSO success branch.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cookie-credentialed fetch | `accountsApiFetch` wrapper variant | Native `fetch` with `credentials: 'include'` | One-time use; wrapper adds no value |
| Auth state management | New auth context or Zustand store | Existing `isLoggedIn` / `setIsLoggedIn` in CompassContext | Both apps' existing patterns; SSO just feeds them |
| Token storage | New localStorage key | Existing `TOKEN_KEY = 'ev_token'` via `setToken()` | Both apps already use this key for access tokens |
| Toast notifications | Any toast component | None needed | Locked decisions: logout is silent, no notifications |

**Key insight:** These are purely Inform-tier apps — the logged-in state is an enhancement over a fully-functional anonymous baseline. The SSO check is a "nice to have" that should never interrupt or degrade the unauthenticated user experience.

## Common Pitfalls

### Pitfall 1: `apiFetch` 401 Handler Redirects to Login During SSO Init

**What goes wrong:** If the SSO check or the post-SSO `/account/me` call uses `apiFetch`, a 401 response calls `redirectToLogin()` which immediately navigates away from the page. For a user with no session (the common case), this redirects them to accounts.empowered.vote on every page load.

**Why it happens:** `apiFetch` in both apps explicitly calls `redirectToLogin()` on 401. This is correct for authenticated API calls but wrong for the silent init path.

**How to avoid:** The existing code already uses `publicFetch` for the `/account/me` call in the auth `useEffect` — this is the correct pattern. Maintain this: never use `apiFetch` in the auth initialization path.

**Warning signs:** Users without sessions are redirected to `accounts.empowered.vote/login` on every page load.

### Pitfall 2: CompassV2 Has No Auth Loading Gate

**What goes wrong:** CompassV2 renders guest UI immediately (`isLoggedIn` starts `false`). The SSO check is async. Without a loading gate, users see guest UI before the check resolves, producing a mid-render swap when the check succeeds — the exact anti-pattern the locked decisions prohibit.

**Why it happens:** CompassV2's auth check was originally fire-and-forget (token already in localStorage or not — fast synchronous check). The SSO check introduces async latency.

**How to avoid:** Add `authChecking: true` state to `CompassContext`. Set it `false` when the auth `useEffect` completes (both success and failure paths). Key rendering components (at minimum: the profile menu in `Layout.jsx` that shows "Sign in" vs. username) should show a neutral placeholder while `authChecking` is `true`.

**Warning signs:** Logged-in users briefly see "Sign in" before it flips to their username.

### Pitfall 3: Essentials `apiFetch` Redirects on 401 for Normal Essentials API Calls

**What goes wrong:** Essentials' `apiFetch` (in `lib/auth.js`) also calls `redirectToLogin()` on 401. This is intentional for authorized API calls. If the SSO check accidentally uses this function, it will redirect.

**Why it happens:** Confusion between `apiFetch` (redirects on 401) and raw `fetch` / `publicFetch` (does not).

**How to avoid:** Use native `fetch` for the SSO session check and the logout call. The existing `publicFetch` in CompassV2 is equivalent to Essentials' `apiFetch` minus the redirect — but Essentials does NOT have a `publicFetch`. For Essentials, use native `fetch` directly.

**Warning signs:** Users without sessions are redirected to login on initial page load.

### Pitfall 4: CompassV2 Logout Navigates Away

**What goes wrong:** CompassV2's current `logout()` in `Layout.jsx` calls `navigate("/")` after clearing state. Per locked decisions, logout stays on the current page.

**Why it happens:** The existing logout predates the SSO stay-in-place decision.

**How to avoid:** Remove all `navigate()` calls from the logout handler. The `setIsLoggedIn(false)` will cause the profile menu to switch from "Logout" to "Sign in" in place. No navigation needed.

**Warning signs:** After logout from CompassV2, user is redirected to `/` instead of staying on their current page.

### Pitfall 5: Token Key Mismatch

**What goes wrong:** Phase 45's CTC used `ev_refresh_token`. These apps use `ev_token` (access token only). Writing the SSO response's `refresh_token` to `ev_token` would cause immediate auth failure on subsequent API calls.

**Correct mapping for Phase 46:**
- Both Essentials and CompassV2: store `access_token` from SSO response in `localStorage('ev_token')` via `setToken(result.access_token)`
- Ignore `refresh_token` — these apps do not have a refresh token path

**Warning signs:** API calls immediately fail with 401 after SSO check succeeds.

### Pitfall 6: `compassLoading` in Essentials Is Driven by a Different useEffect

**What goes wrong:** Modifying `setCompassLoading` in the auth `useEffect` (or expecting `compassLoading` to gate the SSO check display) conflicts with Essentials' existing `loadAll()` effect which owns `compassLoading`.

**Why it happens:** Essentials has two `useEffect` blocks: one for auth (`extractHashToken` + token check) and one for data loading (`loadAll`). They are independent.

**How to avoid:** Do not touch `compassLoading` or `setCompassLoading` in the auth `useEffect`. The data loading gate is already present and will hold until `loadAll()` finishes. The SSO check should complete well before data loading finishes.

## Code Examples

### GET /api/auth/session — confirmed response shape (Phase 44)

```javascript
// Source: backend/src/routes/auth.ts (Phase 44)
// Response on 200:
{ access_token: string, refresh_token: string }
// Response on 401: empty body (no JSON)
```

### Essentials — Augmented auth useEffect in CompassContext.jsx

```javascript
// Source: derived from existing Essentials CompassContext.jsx auth useEffect + Phase 45 pattern
useEffect(() => {
  let cancelled = false;

  async function initAuth() {
    // 1. Extract Bearer token from URL hash if present
    extractHashToken();

    const token = getToken();
    if (token) {
      // Existing path: token present — validate
      const res = await publicFetch('/account/me').catch(() => null);  // NOTE: Essentials uses apiFetch here currently
      if (!cancelled && res) {
        if (res.status === 401) { clearToken(); }
        else if (res.ok) {
          const data = await res.json();
          setIsLoggedIn(true);
          setUserName(data.display_name ?? null);
        }
      }
      return;
    }

    // 2. No local token — try silent SSO
    const API_BASE = import.meta.env.VITE_API_URL
      ? `${import.meta.env.VITE_API_URL.replace(/\/+$/, '')}/api`
      : '/api';
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 2000);

    try {
      const ssoRes = await fetch(`${API_BASE}/auth/session`, {
        credentials: 'include',
        signal: controller.signal,
      });
      clearTimeout(timeoutId);

      if (!ssoRes.ok) { return; } // 401 or 5xx — stay unauthenticated
      const ssoData = await ssoRes.json();
      if (!ssoData?.access_token) return;

      setToken(ssoData.access_token);

      // Validate token via /account/me
      const meRes = await fetch(`${API_BASE}/account/me`, {
        headers: { Authorization: `Bearer ${ssoData.access_token}` },
      }).catch(() => null);

      if (!cancelled && meRes && meRes.ok) {
        const me = await meRes.json();
        if (!cancelled) {
          setIsLoggedIn(true);
          setUserName(me.display_name ?? null);
        }
      }
    } catch {
      clearTimeout(timeoutId);
      // Timeout or network error — stay unauthenticated silently
    }
  }

  initAuth();
  return () => { cancelled = true; };
}, []);
```

Note: In the existing code, Essentials `CompassContext` uses `apiFetch` for the `/account/me` call in its auth `useEffect`. This will redirect on 401. The fix for Phase 46 is to use native `fetch` (or `publicFetch` if one is added to `auth.js`) for this call — not just for the SSO path but also for the existing token validation path. This resolves a pre-existing edge case where an expired token causes an unwanted redirect during app boot.

### CompassV2 — Augmented auth useEffect with authChecking gate

```javascript
// Source: derived from existing CompassV2 CompassContext.jsx + Phase 45 pattern
const [authChecking, setAuthChecking] = useState(true); // NEW

useEffect(() => {
  async function initAuth() {
    extractHashToken();

    const token = getToken();
    if (token) {
      // Existing path
      publicFetch('/account/me')
        .then(r => {
          if (r.status === 401) { clearToken(); return null; }
          return r.ok ? r.json() : null;
        })
        .then(data => {
          if (data) {
            setIsLoggedIn(true);
            setUsername(data.display_name || null);
            if (data.completed_onboarding) {
              localStorage.setItem("help_seen", "true");
            }
          }
        })
        .catch(() => {})
        .finally(() => setAuthChecking(false));  // NEW
      return;
    }

    // Silent SSO check
    const API_BASE = import.meta.env.VITE_API_URL
      ? `${import.meta.env.VITE_API_URL.replace(/\/+$/, '')}/api`
      : '/api';
    const controller = new AbortController();
    setTimeout(() => controller.abort(), 2000);

    try {
      const ssoRes = await fetch(`${API_BASE}/auth/session`, {
        credentials: 'include',
        signal: controller.signal,
      });
      if (ssoRes.ok) {
        const ssoData = await ssoRes.json();
        if (ssoData?.access_token) {
          setToken(ssoData.access_token);
          const meRes = await publicFetch('/account/me').catch(() => null);
          if (meRes && meRes.ok) {
            const me = await meRes.json();
            setIsLoggedIn(true);
            setUsername(me.display_name || null);
            if (me.completed_onboarding) {
              localStorage.setItem("help_seen", "true");
            }
          }
        }
      }
    } catch {
      // Timeout, network error — stay unauthenticated
    } finally {
      setAuthChecking(false);  // NEW — always release the gate
    }
  }

  initAuth();
}, []);
```

## State of the Art

| Old Approach | Current Approach (after Phase 46) | Notes |
|--------------|-----------------------------------|-------|
| No cross-app auth | ev_session cookie enables cross-app auth | Phase 44 built the server side |
| `apiFetch` for logout (no credentials) | Native `fetch` with `credentials: 'include'` for logout | Clears shared cookie |
| `apiFetch` for auth init /account/me (redirects on 401) | `publicFetch` / native `fetch` for auth init | No unwanted redirect on expired token at boot |
| CompassV2: immediate guest render, no loading gate | CompassV2: `authChecking` state gates initial render | Prevents mid-render swap |

**Deprecated patterns being fixed:**
- `navigate("/")` after logout in CompassV2 — violates stay-in-place requirement
- `apiFetch` for logout — never sends cookie credentials
- Essentials auth `useEffect` calling `apiFetch` for `/account/me` — unwanted redirect side-effect

## Open Questions

1. **Essentials `CompassContext.jsx` auth useEffect uses `apiFetch` for `/account/me`**
   - What we know: `apiFetch` redirects to login on 401. In the init path this can cause a redirect when a user has an expired token from a previous session.
   - What's unclear: Whether Phase 46 scope includes fixing this pre-existing issue or only adding SSO.
   - Recommendation: Fix it in Phase 46 since the SSO path requires native fetch anyway — create a `publicFetch` function in Essentials' `auth.js` (matching CompassV2's existing `publicFetch`) and use it for `/account/me` in the auth init path.

2. **CompassV2 `authChecking` — which components need to respect it?**
   - What we know: The profile menu in `Layout.jsx` shows "Sign in" vs. username based on `isLoggedIn`. During SSO check this would flash "Sign in" then update to the username.
   - What's unclear: Whether any other UI components would produce a visible flash.
   - Recommendation: Minimal approach — gate only the profile menu in `Layout.jsx` on `authChecking` (show nothing / neutral placeholder). The rest of the UI is public data that renders the same whether logged in or not.

3. **Essentials `compassLoading` vs SSO check timing**
   - What we know: `loadAll()` is async and resolves after fetching topics + politicians. The auth `useEffect` is separate and faster. SSO check adds ~200ms–2000ms latency to auth.
   - What's unclear: Whether `loadAll()` should wait for SSO to resolve before running (to ensure auth state is set before fetching user answers).
   - Recommendation: Keep them independent. `loadAll()` checks `getToken()` during execution — if SSO finishes first, the token will be present when `loadAll()` runs the auth check. If `loadAll()` wins the race, it falls back to guest data, and the SSO branch can trigger a data refresh after setting auth state. This is acceptable for Phase 46 scope.

## Sources

### Primary (HIGH confidence)
- Read `C:/Transparent Motivations/essentials/src/contexts/CompassContext.jsx` — full auth bootstrap, logout function, token key, data loading pattern
- Read `C:/Transparent Motivations/essentials/src/lib/auth.js` — `TOKEN_KEY = 'ev_token'`, `getToken()`, `setToken()`, `clearToken()`, `extractHashToken()`, `apiFetch()` with 401→redirect behavior
- Read `C:/Transparent Motivations/essentials/src/components/Layout.jsx` — logout surfaces via `useCompass().logout` in profile menu
- Read `C:/Transparent Motivations/essentials/netlify.toml` — `/api/*` proxied to `ev-accounts-api.onrender.com` (same-origin for SSO check)
- Read `C:/EV-CompassV2/src/components/CompassContext.jsx` — full auth bootstrap, `authChecking` gap identified, `publicFetch` present, no loading gate for auth
- Read `C:/EV-CompassV2/src/lib/auth.js` — identical to Essentials auth.js except adds `publicFetch` (no redirect on 401)
- Read `C:/EV-CompassV2/src/components/Layout.jsx` — logout with `navigate("/")`, needs both credentials fix and navigate removal
- Read `C:/EV-CompassV2/src/pages/Home.jsx` — duplicate logout, stub page, needs same fix
- Read `C:/EV-CompassV2/netlify.toml` — `/api/*` proxied to `ev-accounts-api.onrender.com`
- Read `C:/EV-Accounts/.planning/phases/45-profile-hub-ctc-silent-sso/45-RESEARCH.md` — authoritative SSO pattern, Phase 44 endpoint contract confirmed
- Read `C:/EV-Accounts/.planning/phases/45-profile-hub-ctc-silent-sso/45-01-SUMMARY.md` — Profile Hub implementation confirmed shipped
- Read `C:/EV-Accounts/.planning/phases/45-profile-hub-ctc-silent-sso/45-02-SUMMARY.md` — CTC implementation confirmed shipped
- Read `C:/EV-Accounts/app/src/App.tsx` — shipped Profile Hub SSO pattern (authoritative implementation reference)

### Secondary (MEDIUM confidence)
- `package.json` inspection — React 19, no Zustand, no toast library confirmed for both apps
- Vite config inspection — no VITE_API_URL in production → uses Netlify `/api` proxy

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — read both package.json files; no new libraries
- Essentials auth pattern: HIGH — read CompassContext.jsx and auth.js in full
- CompassV2 auth pattern: HIGH — read CompassContext.jsx and auth.js in full
- Logout files: HIGH — read Layout.jsx for both apps; CompassV2 Home.jsx identified as second logout site
- authChecking gap in CompassV2: HIGH — confirmed no loading gate exists in CompassContext.jsx
- API URL construction: HIGH — both apps use identical `VITE_API_URL/api` or `/api` pattern; Netlify proxy confirmed
- Pitfalls: HIGH — derived from direct code inspection, not speculation

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable domain — auth patterns change infrequently)
