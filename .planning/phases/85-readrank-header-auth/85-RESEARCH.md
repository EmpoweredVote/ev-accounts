# Phase 85: ReadRank Header Auth - Research

**Researched:** 2026-03-12
**Domain:** React auth state wiring + ev-ui SiteHeader integration (TypeScript app)
**Confidence:** HIGH

## Summary

Phase 85 mirrors the Essentials header integration (Phase 84) but applied to the ReadRank app (`EV-ReadRank/`). The core work is the same pattern: upgrade ev-ui, extend auth state to expose `userName`, and wire a `profileMenu` prop into `SiteHeader`. The primary difference is that ReadRank is a **TypeScript** app using **Zustand** for state (not React Context), and its existing `useAuthState` hook is a local hook — not a context.

The current `useAuthState.ts` hook fetches `/auth/me` with `credentials: 'include'` but only exposes `{ isLoggedIn: boolean, loading: boolean }`. It does not capture `userName` from the response. The `/auth/me` endpoint returns `{ user_id, username, completed_onboarding }` — `username` is available, just not surfaced. The hook must be extended to capture and return `userName`.

The current `App.tsx` already imports and renders `SiteHeader` from `@chrisandrewsedu/ev-ui` at version `^0.1.41`. The ev-ui library is at `0.1.49` (which has the correct production URLs from Phase 83). The package must be bumped to `^0.1.49`. After that, `App.tsx` needs to read auth state and pass a conditional `profileMenu` to `SiteHeader`. There is no Layout wrapper concept in ReadRank — `SiteHeader` is rendered directly in `MainApp` in `App.tsx`. This is simpler: one file to change for the auth wiring.

**Primary recommendation:** Extend `useAuthState.ts` to return `userName`, bump ev-ui to `^0.1.49`, then update `App.tsx` to build `profileMenu` conditionally and pass it to `SiteHeader`. No new files needed — two targeted edits.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RR-01 | Logged-in user sees their username in the ReadRank header with a logout option | `/auth/me` returns `username`; `useAuthState` must surface it; `profileMenu.label` shows it |
| RR-02 | Logged-out user sees a "Sign in" link in the ReadRank header that navigates to compass.empowered.vote/login | `SiteHeader` accepts `profileMenu` with link items; same pattern as Essentials Phase 84 |
| RR-03 | After logging out from ReadRank, session is cleared and header switches to "Sign in" state | `POST /auth/logout` with `credentials: 'include'`; reset local `isLoggedIn`/`userName` state |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @chrisandrewsedu/ev-ui | ^0.1.49 | SiteHeader component with profileMenu support + correct production URLs | Workspace component library; Phase 83 updated the URLs |
| zustand | ^5.0.9 | App-wide state (already installed) | ReadRank state management — not used for auth in this phase |
| react / react-dom | ^19.2.0 | UI framework | Already installed |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| VITE_API_URL env var | n/a | Backend base URL for auth calls | Already wired in useAuthState.ts |

**Installation (ev-ui upgrade only):**
```bash
cd EV-ReadRank && npm install @chrisandrewsedu/ev-ui@^0.1.49
```

## Architecture Patterns

### Current ReadRank Auth Architecture
```
useAuthState.ts          — hook, fetches /auth/me on mount, returns { isLoggedIn, loading }
App.tsx / MainApp        — renders <SiteHeader logoSrc=... /> (no profileMenu today)
```

### Target Architecture After Phase 85
```
useAuthState.ts          — extended: returns { isLoggedIn, userName, loading }
App.tsx / MainApp        — builds profileMenu from auth state, passes to SiteHeader
```

No new files. No context provider. No Layout wrapper concept. The auth hook + `App.tsx` change is sufficient.

### Pattern 1: Extending useAuthState to Capture Username
**What:** Parse the JSON response from `/auth/me` to extract `username`, surface it as `userName` in the return value.
**When to use:** Always — this is the only place the auth fetch lives.

```typescript
// Source: EV-ReadRank/src/hooks/useAuthState.ts (current + proposed extension)
const API_BASE = (import.meta.env as Record<string, string>).VITE_API_URL
  || 'https://api.empowered.vote';

export interface AuthState {
  isLoggedIn: boolean;
  userName: string | null;   // ADD THIS
  loading: boolean;
}

export function useAuthState(): AuthState & { logout: () => Promise<void> } {
  const [state, setState] = useState<AuthState>({ isLoggedIn: false, userName: null, loading: true });

  useEffect(() => {
    fetch(`${API_BASE}/auth/me`, { credentials: 'include' })
      .then(async res => {
        if (res.ok) {
          const data = await res.json();
          setState({ isLoggedIn: true, userName: data.username ?? null, loading: false });
        } else {
          setState({ isLoggedIn: false, userName: null, loading: false });
        }
      })
      .catch(() => setState({ isLoggedIn: false, userName: null, loading: false }));
  }, []);

  const logout = async () => {
    try {
      await fetch(`${API_BASE}/auth/logout`, { method: 'POST', credentials: 'include' });
    } catch (err) {
      console.error('Logout error:', err);
    }
    setState({ isLoggedIn: false, userName: null, loading: false });
  };

  return { ...state, logout };
}
```

### Pattern 2: profileMenu in App.tsx
**What:** Build `profileMenu` conditionally from `useAuthState()` result and pass to `SiteHeader`.
**When to use:** Always — `SiteHeader` renders the profile button only when `profileMenu` is provided.

```typescript
// Source: ev-ui/src/SiteHeader.jsx interface (verified from source)
// Pattern mirrors essentials/src/components/Layout.jsx from Phase 84

function MainApp() {
  const { isLoggedIn, userName, logout } = useAuthState();

  const profileMenu = isLoggedIn
    ? {
        label: userName || 'Account',
        items: [{ label: 'Sign out', onClick: logout }],
      }
    : {
        label: 'Account',
        items: [{ label: 'Sign in', href: 'https://compass.empowered.vote/login' }],
      };

  return (
    <div className="min-h-screen bg-ev-white">
      <SiteHeader
        logoSrc={`${import.meta.env.BASE_URL}EVLogo.svg`}
        profileMenu={profileMenu}
      />
      <DevHelper />
      <ProgressHeader />
      <main className="container mx-auto px-4 py-8 max-w-4xl">
        <PhaseContainer />
      </main>
    </div>
  );
}
```

### Anti-Patterns to Avoid
- **Conditionally omitting profileMenu for logged-out:** Essentials Phase 84 showed always passing profileMenu (with a Sign In link item) is cleaner than toggling between a profile button and a separate sign-in link. Keep a single consistent prop.
- **Using Zustand store for auth state:** ReadRank's Zustand store persists to localStorage. Auth state should NOT be persisted — it must be fetched fresh on mount. The existing `useAuthState` hook pattern (local useState + useEffect) is correct. Do NOT migrate auth into the Zustand store.
- **Calling res.ok without parsing JSON:** The current hook returns only `isLoggedIn`. To get `userName`, the response body must be parsed when `res.ok` is true. Parse JSON only on 200 — don't parse error responses.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Profile dropdown UI | Custom dropdown component | ev-ui SiteHeader `profileMenu` prop | Already built, tested, styled consistently |
| Auth fetch | New fetch utility | Extend existing `useAuthState.ts` | Pattern already established and working |
| Session termination | Custom cookie clearing | `POST /auth/logout` with `credentials: 'include'` | Backend handles HTTP-only cookie deletion |

**Key insight:** The entire auth UI surface — profile button, dropdown, items — is owned by ev-ui `SiteHeader`. Phase 85 is purely about feeding it data.

## Common Pitfalls

### Pitfall 1: TypeScript Interface Not Updated
**What goes wrong:** `useAuthState` is extended to return `userName` and `logout` but the `AuthState` interface is not updated — TypeScript compile error in App.tsx when destructuring.
**Why it happens:** Adding fields to a hook return without updating the exported interface.
**How to avoid:** Update the `AuthState` interface first, then implement. Also update the function return type annotation if it's explicit.
**Warning signs:** `Property 'userName' does not exist on type 'AuthState'` at build time.

### Pitfall 2: ev-ui Version Mismatch
**What goes wrong:** `profileMenu` prop does not exist on the installed version (^0.1.41). Header renders without profile button at all.
**Why it happens:** Forgetting to bump the package version before testing.
**How to avoid:** Bump to `^0.1.49` and run `npm install` before any dev server testing.
**Warning signs:** No profile icon appears in the header, no TypeScript error (SiteHeader accepts `profileMenu` as optional — it just silently omits the button if prop is absent on old version).

### Pitfall 3: Stale Loading State Flash
**What goes wrong:** On page load, `loading: true` briefly shows the logged-out "Sign in" state before the `/auth/me` fetch completes, causing a visual flicker.
**Why it happens:** `useAuthState` initializes with `isLoggedIn: false` synchronously.
**How to avoid:** Do not render `profileMenu` (or render a loading placeholder) while `loading` is `true`. Pass `profileMenu={undefined}` until loading completes — `SiteHeader` renders no profile button when profileMenu is absent, which is acceptable.
**Warning signs:** Brief "Sign in" flash for logged-in users on hard refresh.

### Pitfall 4: logout() Not Async-Safe
**What goes wrong:** `logout()` call fails silently if the network request rejects — user still sees "Sign out" in header.
**Why it happens:** Missing try/catch around the fetch.
**How to avoid:** The pattern from Phase 84 wraps the fetch in try/catch and always resets state regardless of fetch success. Always clear local state even if the network call fails.

## Code Examples

### /auth/me Response Shape (verified from backend)
```json
{
  "user_id": "string",
  "username": "string",
  "completed_onboarding": true
}
```
Source: `EV-Backend/internal/auth/handlers.go` — `MeResponse` struct.

### SiteHeader profileMenu Interface (verified from ev-ui source)
```javascript
// Source: ev-ui/src/SiteHeader.jsx
profileMenu = {
  label: string,           // shown as dropdown header
  items: [
    { label: string, onClick: fn }    // button item (logout)
    // OR
    { label: string, href: string }   // link item (sign in)
  ]
}
```

### ev-ui Published Version
ev-ui is at `0.1.49` (confirmed from `ev-ui/package.json`). ReadRank currently has `^0.1.41`. Bump to `^0.1.49`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `useAuthState` returns `{ isLoggedIn, loading }` only | Must return `{ isLoggedIn, userName, loading, logout }` | Phase 85 | Enables header to show username + sign out |
| `SiteHeader` rendered with no `profileMenu` | `profileMenu` passed conditionally | Phase 85 | Activates profile dropdown in header |
| ev-ui `^0.1.41` | ev-ui `^0.1.49` | Phase 83 shipped | Correct production URLs in Features dropdown |

## Open Questions

1. **Loading state treatment**
   - What we know: `SiteHeader` renders no profile button when `profileMenu` is undefined/null
   - What's unclear: Whether the planner wants to explicitly handle `loading: true` (hide button, show placeholder) or accept a brief no-button period
   - Recommendation: Suppress `profileMenu` while loading (pass `undefined`) — this avoids the flicker and is consistent with ev-ui's intent for the optional prop

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected (TypeScript + Vite project, no test config found) |
| Config file | None — Wave 0 gap |
| Quick run command | `cd EV-ReadRank && npm run build` (TypeScript compile as proxy) |
| Full suite command | `cd EV-ReadRank && npm run build` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RR-01 | Logged-in user sees username + logout in header | manual-only | n/a — no test framework | N/A |
| RR-02 | Logged-out user sees "Sign in" link in header | manual-only | n/a — no test framework | N/A |
| RR-03 | Logout clears session and header switches state | manual-only | n/a — no test framework | N/A |

Manual-only justification: No test framework is installed in EV-ReadRank. TypeScript compilation (`npm run build`) validates structural correctness. Visual auth state requires a running dev server and live session.

### Sampling Rate
- **Per task commit:** `cd EV-ReadRank && npm run build` — TypeScript compile must exit 0
- **Per wave merge:** `cd EV-ReadRank && npm run build`
- **Phase gate:** Build green + human checkpoint confirming header auth state before `/gsd:verify-work`

### Wave 0 Gaps
None required for Phase 85 — no new test infrastructure needed. The phase is two targeted file edits with TypeScript compilation as the automated gate. Human verification on dev server covers the three requirements.

## Sources

### Primary (HIGH confidence)
- `EV-ReadRank/src/hooks/useAuthState.ts` — current hook implementation, confirmed returns no userName
- `EV-ReadRank/src/App.tsx` — confirmed SiteHeader rendered with no profileMenu today
- `EV-ReadRank/package.json` — confirmed ev-ui at ^0.1.41, must bump to ^0.1.49
- `ev-ui/src/SiteHeader.jsx` — confirmed profileMenu prop interface (label + items array)
- `ev-ui/package.json` — confirmed ev-ui current version is 0.1.49
- `EV-Backend/internal/auth/handlers.go` — confirmed MeResponse returns `username` field
- `.planning/phases/84-essentials-header-integration/84-01-PLAN.md` — verified Pattern: profileMenu construction, logout implementation, sign-in link

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` — confirmed sign-in links go to `compass.empowered.vote/login`; logout stays on current page

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified from package.json files and ev-ui source
- Architecture: HIGH — App.tsx structure confirmed, hook confirmed, backend endpoint confirmed
- Pitfalls: HIGH — derived from Phase 84 plan execution and TypeScript-specific issues

**Research date:** 2026-03-12
**Valid until:** 2026-04-12 (stable — no fast-moving dependencies)
