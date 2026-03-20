# Phase 40: Frontend Auth Updates - Research

**Researched:** 2026-03-20
**Domain:** Multi-app frontend auth migration (cookie/session → Bearer token)
**Confidence:** HIGH — all 4 repos inspected directly (CompassV2, Essentials locally; Read & Rank, Treasury Tracker via GitHub)

---

## Summary

All four frontend apps currently send `credentials: "include"` on every fetch call, relying on HTTP-only session cookies set by the Go server (`api.empowered.vote`). The ev-accounts backend (`accounts.empowered.vote`) uses `Authorization: Bearer {token}` headers — the token being a Supabase JWT retrieved from the ev-accounts `/auth/login` REST endpoint. No app currently has `@supabase/supabase-js` installed (CompassV2 and Essentials confirmed locally; Read & Rank and Treasury Tracker confirmed via package.json on GitHub).

The migration pattern is established by the existing ev-accounts `/app` (Auth Hub) codebase: call `POST /api/auth/login` → receive `access_token` → store in `localStorage` as `ev_token` → attach as `Authorization: Bearer {token}` on every request via a shared `apiFetch()` wrapper. This is documented in `docs/COMPASSV2-INTEGRATION.md` and implemented in `app/src/lib/api.ts` and `app/src/store/authStore.ts`.

CompassV2 requires the most work: it has its own Login and Register pages (which must become Auth Hub redirects), plus 20+ files using `credentials: "include"`. Essentials and Read & Rank each have a thin auth hook that needs updating. Treasury Tracker has no backend API calls at all and only needs its Netlify proxy target updated. The ev-accounts `GET /api/account/me` returns `display_name` (not `username`) — CompassV2 code that reads `data.username` must change to `data.display_name`. CORS is controlled by the `CORS_ORIGIN` Render env var, which needs all 4 frontend origins added before direct Bearer token calls work.

**Primary recommendation:** Create one shared `apiFetch()` wrapper per app. Replace every `credentials: "include"` fetch call with a call through that wrapper. Update `VITE_API_URL` to `https://accounts.empowered.vote` in all apps. Update Netlify proxy targets. Add hash fragment token extraction on app init.

---

## App-by-App Findings

### CompassV2

**Location:** `/c/EV-CompassV2/` (local)
**Language:** React 19 + JavaScript (JSX, no TypeScript)
**No Supabase SDK installed** — confirmed via `package.json`

**Current auth pattern:**
- Every fetch call uses `credentials: "include"` (cookie-based)
- `VITE_API_URL` in `.env.production` = `https://api.empowered.vote` (Go server)
- Netlify proxy in `netlify.toml`: `/api/*` → Go server `https://ev-backend-h3n8.onrender.com/:splat`
- `CompassContext.jsx` calls `/auth/me` with `credentials: "include"` on mount; stores `isLoggedIn` + `username` in context
- `ProtectedRoute.jsx` calls `/auth/me` with `credentials: "include"` on mount
- `AdminRoute.jsx` calls `/auth/admin-check` with `credentials: "include"`
- `Login.jsx` calls `POST /auth/login` with `credentials: "include"`, then `GET /auth/me`; reads `data.username` and `data.completed_onboarding`
- `Register.jsx` calls `POST /auth/register` with `credentials: "include"` and a `guest_state` body containing local quiz answers
- `Layout.jsx` calls `POST /auth/logout` with `credentials: "include"`
- All admin components (`src/components/admin/*.jsx`) use `credentials: "include"`
- `usePoliticianList.js` hook uses `credentials: "include"`

**Files that need changes:**

| File | Change |
|------|--------|
| `src/lib/auth.js` (NEW) | Token storage + `apiFetch()` wrapper + `extractHashToken()` |
| `src/components/CompassContext.jsx` | Replace all `credentials: "include"` with `apiFetch()`; update `data.username` → `data.display_name`; add hash fragment extraction on mount |
| `src/components/ProtectedRoute.jsx` | Replace cookie fetch with Bearer token fetch |
| `src/components/AdminRoute.jsx` | Replace `credentials: "include"` with Bearer token fetch |
| `src/components/Layout.jsx` | Update logout: call `POST /auth/logout` with Bearer header, then `clearToken()` |
| `src/pages/Login.jsx` | **REPLACE** with redirect to Auth Hub |
| `src/pages/Register.jsx` | **REPLACE** with redirect to Auth Hub signup |
| `src/pages/Home.jsx` | Replace fetch credentials |
| `src/pages/BuildCompass.jsx` | Replace fetch credentials |
| `src/pages/Compass.jsx` | Replace fetch credentials |
| `src/pages/Library.jsx` | Replace fetch credentials |
| `src/pages/Quiz.jsx` | Replace fetch credentials |
| All `src/components/admin/*.jsx` | Replace fetch credentials |
| `src/hooks/usePoliticianList.js` | Replace fetch credentials |
| `.env.production` | `VITE_API_URL=https://accounts.empowered.vote` |
| `netlify.toml` | Update proxy target from Go server to `https://accounts.empowered.vote/api` |

**Key complexity — guest-answer migration on register:** `Register.jsx` contains a `buildGuestState()` function that reads local quiz answers and sends them to `/auth/register` as `guest_state`. The Auth Hub signup flow doesn't accept `guest_state`. When Register.jsx becomes a redirect, this migration logic disappears. For Phase 40 scope (auth model change only), this is an accepted behavior change — document in the runbook.

**Key complexity — "please log in again" banner:** The banner goes on the Auth Hub login page (`app/src/pages/LoginPage.tsx`), not on CompassV2's login page (which no longer exists). Show the banner when the user arrives via a `redirect` parameter.

---

### Essentials

**Location:** `/c/Transparent Motivations/essentials/` (local)
**Language:** React 19 + JavaScript (JSX, no TypeScript)
**No Supabase SDK installed** — confirmed via `package.json`

**Current auth pattern:**
- Auth check: `fetch(`${API}/auth/me`, { credentials: "include" })` in `CompassContext.jsx` on mount; stores `isLoggedIn` + `userName` in context
- All fetches: `credentials: "include"` throughout `src/lib/api.jsx`, `src/lib/compass.js`, `src/lib/adminApi.js`
- `API = import.meta.env.VITE_API_URL || "/api"` — no `.env.production` found locally; Netlify dashboard env var must be set
- Netlify proxy in `netlify.toml`: `/api/*` → `https://ev-backend-h3n8.onrender.com/:splat`
- No login/register pages — Essentials has no local auth UI at all
- `logout` function in `CompassContext.jsx` calls `POST /auth/logout` with `credentials: "include"`
- `AuthIndicator.jsx` shows user initials when logged in but has no "log in" button

**Files that need changes:**

| File | Change |
|------|--------|
| `src/lib/auth.js` (NEW) | Token storage + `apiFetch()` wrapper + `extractHashToken()` |
| `src/lib/api.jsx` | Replace all `credentials: "include"` with `apiFetch()`; import from auth.js |
| `src/lib/compass.js` | Replace all `credentials: "include"` with `apiFetch()` |
| `src/lib/adminApi.js` | Replace all `credentials: "include"` with `apiFetch()` |
| `src/contexts/CompassContext.jsx` | Replace auth check with Bearer token; update logout; add hash fragment extraction on mount; add Auth Hub redirect link when not logged in |
| `netlify.toml` | Update proxy target to `https://accounts.empowered.vote/api` |
| Netlify dashboard | Update `VITE_API_URL` env var to `https://accounts.empowered.vote` |

**Key complexity — no login UI:** Essentials has no login button. After migration, when an unauthenticated user wants to log in, there is no path. A minimal "Sign in" link must be added (likely in `Layout.jsx` or `AuthIndicator.jsx`) that redirects to the Auth Hub with a return URL. This is a small UI addition within Phase 40 scope (needed to make auth work).

---

### Read & Rank

**Location:** GitHub only (`https://github.com/EmpoweredVote/read-rank`)
**Language:** React 19 + TypeScript
**No Supabase SDK** — confirmed via package.json

**Current auth pattern:**
- `src/hooks/useAuthState.ts` — calls `GET /auth/me` with `credentials: 'include'` on mount. In dev uses relative URL (Vite proxy). In prod uses `VITE_API_URL || 'https://api.empowered.vote'`
- `src/utils/verdictSync.ts` — calls `POST /compass/verdicts` with `credentials: 'include'`, uses `VITE_API_URL || 'https://api.empowered.vote'`
- `App.tsx` — uses `useAuthState()` hook; has a sign-in link that redirects to external Compass URL with return parameter (redirect pattern already exists)
- No Netlify proxy — Read & Rank makes direct API calls using the full URL from `VITE_API_URL`

**Files that need changes:**

| File | Change |
|------|--------|
| `src/lib/auth.ts` (NEW) | Token storage + `apiFetch()` wrapper + `extractHashToken()` |
| `src/hooks/useAuthState.ts` | Replace `credentials: 'include'` with Bearer token; add hash fragment extraction on mount; add localStorage token management |
| `src/utils/verdictSync.ts` | Replace `credentials: 'include'` with Bearer token header |
| `src/App.tsx` | Call `extractHashToken()` on mount; update sign-in redirect to point to Auth Hub |
| `src/utils/verdictFragment.ts` | Check for any fetch calls (likely none — pure local state) |
| `.env.production` | Update `VITE_API_URL` to `https://accounts.empowered.vote` |

**Key complexity — `searchPoliticians()` API call:** `App.tsx` calls `searchPoliticians()` when an `address` query param is present. That function lives in `src/utils/` (not yet inspected fully). It must also be migrated to Bearer token auth. LOW confidence on whether it uses `credentials: "include"` — inspect during planning.

---

### Treasury Tracker

**Location:** GitHub only (`https://github.com/EmpoweredVote/treasury-tracker`)
**Language:** React 19 + TypeScript
**No Supabase SDK** — confirmed via package.json

**Current auth pattern:**
- **No backend API calls** — `App.tsx` loads all data from local static JSON files (`./data/{dataset}-{year}.json` and `./data/{dataset}-{year}-linked.json`)
- No auth state management in App.tsx or main.tsx
- Netlify proxy in `netlify.toml`: `/api/*` → Go server `https://ev-backend-h3n8.onrender.com/:splat` (currently unused since app loads static files)
- `@chrisandrewsedu/ev-ui` is installed but any auth components from it are not wired up

**Files that need changes:**

| File | Change |
|------|--------|
| `netlify.toml` | Update proxy target from Go server to `https://accounts.empowered.vote/api` |
| `.env.production` (if exists) | Add `VITE_API_URL=https://accounts.empowered.vote` |

**No JS/TS changes required** — the app makes no backend calls. The success criterion "no requests reach the Go server" is trivially met since Treasury Tracker already makes no requests to `api.empowered.vote`. The change is the Netlify proxy update to ensure future API calls route correctly.

**Note on success criterion:** The requirements say "Treasury Tracker loads public treasury data from the ev-accounts API URL." Since Treasury Tracker currently loads static JSON from bundled `./data/` files (not from the API), this criterion is interpreted as: the Netlify proxy is updated, no hardcoded Go server URLs exist, and the infrastructure is ready for future API-backed treasury routes.

---

## Standard Stack

No new libraries are needed. All 4 apps use native `fetch()`. The pattern is established by the ev-accounts Auth Hub.

### Core Pattern (no new libraries)

| Component | Implementation | Why |
|-----------|---------------|-----|
| HTTP client | Native `fetch()` | Already used in all apps |
| Token storage | `localStorage.setItem('ev_token', token)` | Established in Auth Hub (`app/src/store/authStore.ts`) |
| Token retrieval | `localStorage.getItem('ev_token')` | Same |
| Token attachment | `Authorization: Bearer ${token}` header in shared `apiFetch()` wrapper | Established pattern |
| Auth check on mount | `GET /api/auth/me` with Bearer header | ev-accounts endpoint |
| Login | Redirect to Auth Hub `https://accounts.empowered.vote/login?redirect={encodeURIComponent(location.href)}` | COMPASSV2-INTEGRATION.md |
| Token extraction | Parse `#access_token=` from `window.location.hash` on app init | Auth Hub pattern |
| Token expiry handling | On 401 response, clear `ev_token`, redirect to Auth Hub | COMPASSV2-INTEGRATION.md §3 |
| Logout | `POST /api/auth/logout` with Bearer header, then `localStorage.removeItem('ev_token')` | Auth Hub pattern |

**No new `npm install` needed.** No `@supabase/supabase-js` installation required in any frontend. The ev-accounts `/auth/login` endpoint handles Supabase auth internally and returns the JWT directly.

**Clarification on CONTEXT.md "Supabase JS SDK" decision:** The CONTEXT.md says "apps call `supabase.auth.signIn()`." In practice, the established codebase pattern (Auth Hub `app/src/pages/LoginPage.tsx`) calls `POST /api/auth/login` on the ev-accounts REST API, which wraps Supabase internally. The frontends do NOT use the Supabase JS SDK directly. None of the 4 apps have `@supabase/supabase-js` installed. The planner should use the REST endpoint + Bearer token pattern, not install and configure `@supabase/supabase-js` in each frontend.

---

## Architecture Patterns

### Pattern 1: Shared `apiFetch()` Wrapper

Each app needs ONE new file (e.g., `src/lib/auth.js` for JSX apps, `src/lib/auth.ts` for TSX apps):

```javascript
// Pattern source: app/src/lib/api.ts (ev-accounts Auth Hub)
const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

export const TOKEN_KEY = 'ev_token';

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

export function extractHashToken() {
  const hash = window.location.hash;
  if (!hash.includes('access_token=')) return null;
  const params = new URLSearchParams(hash.substring(1));
  const token = params.get('access_token');
  if (!token) return null;
  // Clean URL — token must not persist in address bar
  window.history.replaceState(null, '', window.location.pathname + window.location.search);
  localStorage.setItem(TOKEN_KEY, token);
  return token;
}

export async function apiFetch(path, options = {}) {
  const token = getToken();
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (res.status === 401) {
    clearToken();
    const returnUrl = encodeURIComponent(window.location.href);
    window.location.href = `https://accounts.empowered.vote/login?redirect=${returnUrl}`;
    return null;
  }

  return res;
}
```

Note: When `VITE_API_URL = 'https://accounts.empowered.vote'`, the API_BASE becomes `https://accounts.empowered.vote/api` — making direct cross-origin requests. This requires CORS to allow the frontend's origin (see CORS section below). If CORS is not configured to allow all 4 domains, use the Netlify proxy approach instead (omit `VITE_API_URL`, let `API_BASE` fall back to `'/api'`, and configure the proxy to forward to ev-accounts).

### Pattern 2: Token Extraction on App Init

Call `extractHashToken()` on app initialization before first render or in the root component's first `useEffect`. The token must be stored before any auth-dependent rendering occurs.

```javascript
// In root component useEffect (established pattern from app/src/App.tsx):
useEffect(() => {
  const hashToken = extractHashToken(); // stores in localStorage, cleans URL
  const token = hashToken ?? getToken();
  if (token) {
    apiFetch('/auth/me')
      .then(res => res?.json())
      .then(data => {
        if (data) {
          setIsLoggedIn(true);
          setUsername(data.display_name || null);
          // NOTE: ev-accounts returns 'display_name', not 'username'
        }
      })
      .catch(() => clearToken());
  }
}, []);
```

### Pattern 3: Netlify Proxy Update

All 3 apps with Netlify proxies (CompassV2, Essentials, Treasury Tracker) need their proxy target updated:

```toml
# BEFORE (Go server):
[[redirects]]
  from = "/api/*"
  to = "https://ev-backend-h3n8.onrender.com/:splat"
  status = 200
  force = true

# AFTER (ev-accounts):
[[redirects]]
  from = "/api/*"
  to = "https://accounts.empowered.vote/api/:splat"
  status = 200
  force = true
```

Note: When using the Netlify proxy approach (API_BASE = '/api'), cookies are NOT sent because there is no cookie auth in the new system. The Bearer token header is attached by `apiFetch()` before the request goes through Netlify's proxy layer — this works correctly.

### Pattern 4: Login Page Becomes Auth Hub Redirect (CompassV2)

```javascript
// CompassV2 src/pages/Login.jsx — replace entire component
import { useEffect } from "react";

function Login() {
  useEffect(() => {
    const returnTo = new URLSearchParams(window.location.search).get("return")
      || sessionStorage.getItem("auth_return_url")
      || (window.location.origin + "/results");
    sessionStorage.removeItem("auth_return_url");
    const redirectUrl = encodeURIComponent(returnTo);
    window.location.replace(
      `https://accounts.empowered.vote/login?redirect=${redirectUrl}`
    );
  }, []);
  return null;
}

export default Login;
```

### Pattern 5: "Please Log In Again" Banner (Auth Hub)

Add to `app/src/pages/LoginPage.tsx` — show when user arrives via redirect parameter (meaning they were sent here by a frontend app after cookies expired):

```tsx
// Show banner when arriving with a redirect param (user was redirected from an app)
const hasRedirect = new URLSearchParams(window.location.search).has('redirect');

// In JSX:
{hasRedirect && (
  <div className="mb-4 p-3 bg-ev-teal/10 border border-ev-teal rounded-lg text-sm text-ev-teal-light text-center">
    We've made some improvements — please log in again.
  </div>
)}
```

### Anti-Patterns to Avoid

- **`credentials: "include"` on any fetch call** — Remove all instances; this is the pattern being replaced.
- **Hardcoded `https://api.empowered.vote`** — Replace with `VITE_API_URL` env var or relative `/api` path.
- **Installing `@supabase/supabase-js` in frontend apps** — Not needed. The ev-accounts REST endpoint handles Supabase auth.
- **Storing tokens in sessionStorage** — Use localStorage for persistence across tabs and page reloads.
- **Reading `data.username` from `/auth/me` response** — ev-accounts returns `display_name`, not `username`. All code reading `data.username` must change to `data.display_name`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token refresh | Custom refresh loop | ev-accounts `/auth/login` re-auth via Auth Hub redirect | ev-accounts exposes no refresh token to external apps; re-auth is the documented pattern |
| JWT decode/validate | Client-side JWT parsing | Trust server 401 response | Server validates token; client doesn't need to inspect claims |
| Auth state management library | New Zustand store | Simple `localStorage.getItem('ev_token')` + React state | 4 apps already have their own state management |
| Cookie clearing | `document.cookie` manipulation | Nothing needed | Cookies are server-side; they expire naturally |
| CORS proxy middleware | Custom express proxy | Netlify proxy redirect | Netlify already provides this; just update the target URL |

---

## Common Pitfalls

### Pitfall 1: `VITE_API_URL` Netlify Dashboard Not Updated

**What goes wrong:** `.env.production` in the repo is updated to `https://accounts.empowered.vote`, but the Netlify dashboard env var `VITE_API_URL` still points to the Go server. Netlify build injects dashboard env vars at build time, overriding `.env.production`. App still hits Go server.

**Why it happens:** Netlify env vars take precedence over file-based env vars. The `.env.production` file change has no effect in production if the dashboard var isn't updated too.

**How to avoid:** Update both the file AND the Netlify dashboard env var. Verify after deploy by checking network tab in browser — confirm requests go to `accounts.empowered.vote`.

**Warning signs:** Netlify build succeeds, app deployed, but login still uses cookie auth.

---

### Pitfall 2: Hash Fragment Token Not Extracted Before Auth Check

**What goes wrong:** App mounts → auth check fires with no token → user appears logged out → hash fragment with token is still in the URL → second render picks it up → user appears logged in. Flash of logged-out state, or worse, a redirect to login that immediately redirects back.

**Why it happens:** React renders on mount before `useEffect` runs; auth check must come AFTER hash extraction.

**How to avoid:** `extractHashToken()` must run synchronously or in the very first `useEffect`, BEFORE any component that checks auth state renders. Follow the `app/src/App.tsx` pattern — extract in the root `useEffect`, use the token immediately for `/auth/me`, and set auth state in one operation.

**Warning signs:** Users get a momentary redirect to login immediately after returning from Auth Hub.

---

### Pitfall 3: `data.username` Still Read After Migration

**What goes wrong:** CompassContext.jsx and Login.jsx read `data.username` from the `/auth/me` response. The ev-accounts `/auth/me` endpoint returns `display_name`, not `username` (verified from `backend/src/routes/account.ts` line 153). The field will be `undefined` after migration, breaking the displayed username.

**Why it happens:** The Go server's auth response used `username`. ev-accounts uses `display_name`.

**How to avoid:** Every instance of `data.username` in all 4 apps must be changed to `data.display_name`. Search for `data.username`, `.username`, `setUsername(data.username)` in all files during migration.

**Warning signs:** Username shows as `undefined` or empty string after login.

---

### Pitfall 4: CORS Blocks Direct Bearer Token Calls

**What goes wrong:** `VITE_API_URL=https://accounts.empowered.vote` causes the app to make cross-origin requests with `Authorization` headers. The browser sends a CORS preflight. If ev-accounts CORS only allows `accounts.empowered.vote` (its own domain), the preflight is rejected and all API calls fail.

**Why it happens:** CORS is controlled by `CORS_ORIGIN` env var in `backend/src/index.ts`. In production, it reads `env.CORS_ORIGIN.split(',')`. If the 4 frontend origins aren't in that list, cross-origin requests are blocked.

**How to avoid:**
- Option A: Add all 4 frontend domains to `CORS_ORIGIN` Render env var (comma-separated list) before cutover.
- Option B: Keep Netlify proxy approach — apps use relative `/api/` paths, Netlify forwards to ev-accounts. No CORS issue since the browser sees same-origin requests.
- **Recommended for Phase 40:** Add all 4 domains to `CORS_ORIGIN` on Render. This is a one-line env var change with no code changes. Runbook must include this step.

**Warning signs:** Browser console shows `CORS policy: No 'Access-Control-Allow-Origin' header` after deployment.

---

### Pitfall 5: Admin Routes Stop Working After Migration

**What goes wrong:** CompassV2's `AdminRoute.jsx` calls `GET /auth/admin-check`. If this endpoint doesn't exist on ev-accounts (it may be Go-specific), admin routes break for all admin users.

**Why it happens:** The Go server had `/auth/admin-check`. ev-accounts may not have an identical endpoint — it uses `GET /api/auth/me` which returns `is_admin: boolean`.

**How to avoid:** Replace `AdminRoute.jsx` logic from "call `/auth/admin-check`" to "call `/auth/me` and check `data.is_admin === true`". Confirmed: ev-accounts `GET /api/account/me` returns `is_admin` field (from `backend/src/routes/account.ts` line 156).

**Warning signs:** Admin users get 404 or 401 when navigating to `/admin`.

---

## Code Examples

### Shared `apiFetch()` Wrapper (src/lib/auth.js)

```javascript
// Source: app/src/lib/api.ts + docs/COMPASSV2-INTEGRATION.md
const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

export const TOKEN_KEY = 'ev_token';
export const AUTH_HUB_URL = 'https://accounts.empowered.vote';

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

export function setToken(token) {
  localStorage.setItem(TOKEN_KEY, token);
}

export function extractHashToken() {
  const hash = window.location.hash;
  if (!hash.includes('access_token=')) return null;
  const params = new URLSearchParams(hash.substring(1));
  const token = params.get('access_token');
  if (!token) return null;
  window.history.replaceState(null, '', window.location.pathname + window.location.search);
  setToken(token);
  return token;
}

export function redirectToLogin(returnUrl = window.location.href) {
  const redirectParam = encodeURIComponent(returnUrl);
  window.location.href = `${AUTH_HUB_URL}/login?redirect=${redirectParam}`;
}

export async function apiFetch(path, options = {}) {
  const token = getToken();
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (res.status === 401) {
    clearToken();
    redirectToLogin();
    return null;
  }

  return res;
}
```

### CompassContext.jsx — Auth Check Migration

```javascript
// BEFORE:
useEffect(() => {
  fetch(`${API}/auth/me`, { credentials: "include" })
    .then(r => r.ok ? r.json() : null)
    .then(data => {
      if (data) {
        setIsLoggedIn(true);
        setUsername(data.username || null);  // OLD: data.username
      }
    });
}, []);

// AFTER:
import { extractHashToken, getToken, apiFetch } from '../lib/auth';

useEffect(() => {
  const init = async () => {
    extractHashToken(); // extract + store if present in URL hash
    const token = getToken();
    if (!token) return;
    const res = await apiFetch('/auth/me');
    if (!res) return; // 401 handled by apiFetch (redirect)
    const data = await res.json();
    if (data) {
      setIsLoggedIn(true);
      setUsername(data.display_name || null);  // NEW: data.display_name
      if (data.completed_onboarding) {
        localStorage.setItem("help_seen", "true");
      }
    }
  };
  init().catch(() => {});
}, []);
```

### AdminRoute.jsx — is_admin Check Migration

```javascript
// BEFORE: separate /auth/admin-check endpoint
fetch(`${import.meta.env.VITE_API_URL}/auth/admin-check`, {
  credentials: "include",
})

// AFTER: use /auth/me + check is_admin field
import { apiFetch } from '../lib/auth';

useEffect(() => {
  apiFetch('/auth/me')
    .then(res => res?.json())
    .then(data => {
      setAdminStatus(data?.is_admin === true ? "authorized" : "unauthorized");
    })
    .catch(() => setAdminStatus("unauthorized"));
}, []);
```

### Netlify Proxy Update (all 3 apps)

```toml
# netlify.toml — update proxy target
[[redirects]]
  from = "/api/*"
  to = "https://accounts.empowered.vote/api/:splat"
  status = 200
  force = true

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

---

## State of the Art

| Old Approach | Current Approach | Impact on Phase 40 |
|--------------|------------------|-------------------|
| Cookie-based sessions (Go server) | Bearer JWT tokens (ev-accounts) | All 4 apps must switch |
| Go server at `api.empowered.vote` | Express at `accounts.empowered.vote` | `VITE_API_URL` change in all apps |
| In-app login/register UI (CompassV2) | Centralized Auth Hub redirect | Login/Register pages become redirects |
| Netlify proxy → Go server | Netlify proxy → ev-accounts | `netlify.toml` change in 3 apps |
| Response field: `data.username` | Response field: `data.display_name` | All frontend code reading `.username` must change |
| Admin check: `/auth/admin-check` | Admin check: `/account/me` → `is_admin: boolean` | AdminRoute.jsx logic changes |

**VERIFIED response shape** of `GET /api/account/me` (from `backend/src/routes/account.ts` line 150):
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "display_name": "Display Name",
  "avatar_url": null,
  "tier": "inform|connected|empowered",
  "is_admin": false,
  "completed_onboarding": false,
  "location_consent": false,
  "verification_rating": 60,
  "vq_hold_active": false,
  "red_gem_quests_unlocked": false,
  "account_standing": "active",
  "jurisdiction": null,
  "created_at": "...",
  "updated_at": "..."
}
```
Note: `username` does NOT appear in this response. Only `display_name`. All frontend code must use `data.display_name`.

**VERIFIED CORS config** (from `backend/src/index.ts` lines 38-46):
CORS is controlled by `CORS_ORIGIN` Render env var (comma-separated list of origins). In production, if `CORS_ORIGIN` is not set or doesn't include the frontend domains, all cross-origin requests with `Authorization` headers are rejected. **The `CORS_ORIGIN` env var on Render must include all 4 frontend deployment URLs before cutover.**

---

## Runbook Structure (Three-Party Coordination)

The CONTEXT.md requires a written cutover runbook. Required sections:

**Section 1: Pre-Cutover Checklist (staging)**
- All 4 apps built with `VITE_API_URL=https://accounts.empowered.vote` in staging
- ev-accounts `CORS_ORIGIN` on Render includes all 4 staging domains
- CompassV2: login → calibration → compare flow completes
- Essentials: auth check on mount returns correct user; all fetch calls work
- Read & Rank: auth state loads; verdicts sync correctly
- Treasury Tracker: no console errors about api.empowered.vote
- Auth Hub: "please log in again" banner shows when arriving with `?redirect=` param

**Section 2: Cutover Window (simultaneous)**
- Deploy order: ev-accounts `CORS_ORIGIN` update first → then all 4 apps simultaneously
- Deploy method: merge to main → Netlify auto-deploy for all 4 apps
- Timing: low-traffic window (weekday morning, Alpha users not active)

**Section 3: Rollback Plan**
- Revert `VITE_API_URL` in each repo to `https://api.empowered.vote` (Netlify dashboard env var)
- Revert `netlify.toml` proxy targets
- Old cookie sessions on Go server remain valid for their TTL (~1 hour)
- No database changes to roll back

**Section 4: User Communication**
- Post in user Discord/Slack: "We've updated our login system. If you see a login screen, just log in again — your data is safe."
- Timing: just before cutover window

**Section 5: Go/No-Go Criteria**
- All staging tests pass (ED + Claude verify)
- Chris Andrews confirms production deploy readiness
- User (ED) approves cutover window

**Section 6: Monitoring (1-3 day window)**
- Monitor Render logs for ev-accounts API errors
- Monitor Netlify deploy logs for 4 apps
- Check browser console errors (CORS, 401, etc.)
- Watch for user reports of login failures

**Parties:**
- User (ED): Approves Go/No-Go; posts user communication; monitors for user reports
- Claude: Makes all code changes; writes runbook; validates in staging
- Chris Andrews: Reviews PRs (owns 4 repos); deploys to production; monitors logs

---

## Open Questions

1. **CompassV2 Register guest-answer migration (ACCEPTED BEHAVIOR CHANGE)**
   - What we know: `Register.jsx` migrates local quiz answers to the server on registration via `POST /auth/register` with `guest_state` body. This migration logic disappears when Register.jsx becomes an Auth Hub redirect.
   - Decision: Drop for Phase 40. Alpha users who had local answers before registering lose them. Document in runbook.

2. **Read & Rank `searchPoliticians()` function auth pattern (LOW confidence)**
   - What we know: `App.tsx` calls `searchPoliticians()` when an `address` query param is present. Function lives somewhere in `src/utils/` or `src/hooks/`.
   - What's unclear: Does it use `credentials: "include"`? (Not inspected during research.)
   - Recommendation: Inspect `src/utils/searchPoliticians.ts` or equivalent during planning. If it uses cookies, migrate to `apiFetch()`.

3. **Read & Rank and Treasury Tracker production deployment URLs**
   - What we know: Both repos are on Netlify. CONTEXT.md lists GitHub URLs but not deployment domains.
   - What's unclear: Exact URLs for staging and production Netlify deployments (needed for `CORS_ORIGIN` env var).
   - Recommendation: Chris Andrews provides these before staging cutover. Add to `CORS_ORIGIN` env var on Render before staging tests.

4. **Auth Hub "please log in again" banner — when to show (LOW confidence)**
   - What we know: CONTEXT.md says "brief banner on login screen."
   - Recommended implementation: Show when user arrives at login page with a `?redirect=` parameter. This means the user was sent here from a frontend app (not a direct visit to accounts.empowered.vote/login).

---

## Sources

### Primary (HIGH confidence)
- `/c/EV-CompassV2/` — full source inspection (CompassContext.jsx, Login.jsx, Register.jsx, ProtectedRoute.jsx, AdminRoute.jsx, netlify.toml, .env.production, package.json)
- `/c/Transparent Motivations/essentials/` — full source inspection (CompassContext.jsx, api.jsx, compass.js, adminApi.js, netlify.toml, package.json)
- `/c/EV-Accounts/app/src/` — Auth Hub source (api.ts, App.tsx, LoginPage.tsx, authStore.ts) — establishes the Bearer token pattern
- `/c/EV-Accounts/backend/src/middleware/auth.ts` — confirms `Authorization: Bearer` header extraction
- `/c/EV-Accounts/backend/src/routes/auth.ts` — confirms `/auth/login` returns `access_token` (Supabase JWT), confirms `/auth/me` response shape
- `/c/EV-Accounts/backend/src/routes/account.ts` — confirms `GET /api/account/me` returns `display_name` (not `username`), confirms `is_admin` field
- `/c/EV-Accounts/backend/src/index.ts` — confirms CORS controlled by `CORS_ORIGIN` Render env var
- `/c/EV-Accounts/docs/COMPASSV2-INTEGRATION.md` — official integration spec for CompassV2

### Secondary (MEDIUM confidence)
- `https://github.com/EmpoweredVote/read-rank` — source inspected via GitHub web (useAuthState.ts raw content confirmed; verdictSync.ts content confirmed; netlify.toml confirmed no proxy; package.json confirmed no Supabase SDK)
- `https://github.com/EmpoweredVote/treasury-tracker` — source inspected via GitHub web (App.tsx confirmed static file loading only; netlify.toml confirmed proxy target; package.json confirmed no Supabase SDK)
- `/c/EV-Accounts/PLATFORM-CONSOLIDATION.md` — context on Read & Rank auth needs, Treasury Tracker scope

### Tertiary (LOW confidence)
- GitHub web listing of Read & Rank components directory (components not individually inspected — `searchPoliticians()` utility location and auth pattern unconfirmed)

---

## Metadata

**Confidence breakdown:**
- CompassV2 auth pattern: HIGH — full source read
- Essentials auth pattern: HIGH — full source read
- Read & Rank auth pattern: HIGH — key files (`useAuthState.ts`, `verdictSync.ts`) read verbatim from GitHub
- Treasury Tracker auth pattern: HIGH — `App.tsx` confirmed no backend calls; netlify.toml confirmed proxy target
- ev-accounts Bearer token pattern: HIGH — middleware source read
- `/auth/me` response shape (`display_name` vs `username`): HIGH — confirmed from `account.ts` line 153
- CORS configuration: HIGH — confirmed `CORS_ORIGIN` env var pattern from `index.ts`; specific current value unknown (Render env var)
- Read & Rank `searchPoliticians()` auth pattern: LOW — function not directly inspected

**Research date:** 2026-03-20
**Valid until:** 2026-04-20 (stable codebase)
