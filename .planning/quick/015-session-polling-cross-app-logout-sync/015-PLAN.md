---
phase: quick
plan: 015
type: execute
wave: 1
depends_on: []
files_modified:
  - /c/EV-Accounts/app/src/App.tsx
  - /c/EV-CompassV2/src/components/CompassContext.jsx
  - /c/Validation Quests/frontend/src/contexts/AuthContext.tsx
  - /c/Civic Spaces/src/hooks/useAuth.ts
  - /c/read-rank/src/hooks/useAuthState.ts
autonomous: true

must_haves:
  truths:
    - "User logs out from any EV app and all other open tabs detect the logout within 60 seconds"
    - "Sleeping/hidden tabs do not fire polling requests"
    - "Network errors do not cause false logouts"
  artifacts:
    - path: "/c/EV-Accounts/app/src/App.tsx"
      provides: "Session polling useEffect"
      contains: "setInterval.*60"
    - path: "/c/EV-CompassV2/src/components/CompassContext.jsx"
      provides: "Session polling useEffect"
      contains: "setInterval.*60"
    - path: "/c/Validation Quests/frontend/src/contexts/AuthContext.tsx"
      provides: "Session polling useEffect"
      contains: "setInterval.*60"
    - path: "/c/Civic Spaces/src/hooks/useAuth.ts"
      provides: "Session polling useEffect"
      contains: "setInterval.*60"
    - path: "/c/read-rank/src/hooks/useAuthState.ts"
      provides: "Session polling useEffect"
      contains: "setInterval.*60"
  key_links:
    - from: "all 5 apps"
      to: "GET /api/auth/session"
      via: "fetch with credentials: include"
      pattern: "fetch.*session.*credentials.*include"
    - from: "401 response"
      to: "local auth clear"
      via: "each app's logout/clearAuth function"
      pattern: "status === 401"
---

<objective>
Add session polling to all 5 locally-available EV apps so that when a user logs out from any app (clearing the ev_session httpOnly cookie), every other open tab detects the logout within 60 seconds and clears local auth state.

Purpose: Cross-app logout sync. Currently, logging out from one app leaves other tabs authenticated with stale tokens in memory/localStorage.
Output: Each app gains a useEffect that polls GET /api/auth/session every 60s (credentials: include). A 401 response triggers local logout. Hidden tabs skip polling. Network errors are ignored (no false logouts).
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
No backend work needed. GET /api/auth/session already exists on the accounts API. It returns tokens when ev_session cookie is present, 401 when absent.

All 5 repos are local. Each has a different auth pattern but the polling logic is identical in shape:
- Guard on authenticated state
- Skip if document.visibilityState !== 'visible'
- fetch session URL with credentials: include
- 401 = call local logout function
- catch = ignore (network error, do not log out)
- 60 second interval, cleaned up on unmount or auth state change
</context>

<tasks>

<task type="auto">
  <name>Task 1: EV-Accounts/app — Add session polling to App.tsx</name>
  <files>/c/EV-Accounts/app/src/App.tsx</files>
  <action>
Add a new `useEffect` in the `App` component (after the existing `accessToken` localStorage sync effect, around line 154). This effect polls GET /api/auth/session when the user is authenticated.

Implementation:
```tsx
// Cross-app logout sync — detect ev_session cookie cleared by another app
useEffect(() => {
  if (!accessToken) return;

  const API_URL = import.meta.env.VITE_API_URL || '';
  const SESSION_URL = `${API_URL}/api/auth/session`;

  const poll = async () => {
    if (document.visibilityState !== 'visible') return;
    try {
      const res = await fetch(SESSION_URL, { credentials: 'include' });
      if (res.status === 401) {
        clearAuth();
      }
    } catch {
      // Network error — don't log out (transient failure)
    }
  };

  const id = setInterval(poll, 60_000);
  return () => clearInterval(id);
}, [accessToken, clearAuth]);
```

`clearAuth` is already destructured from `useAuthStore()` at line 28. `accessToken` is also already destructured there. No new imports needed.

Commit to the EV-Accounts repo: `feat: add session polling for cross-app logout sync`
  </action>
  <verify>
Run `cd /c/EV-Accounts/app && npx tsc --noEmit` — no type errors.
Visually confirm the useEffect is placed after the existing effects and before the return JSX.
  </verify>
  <done>App.tsx contains a 60s interval polling /api/auth/session that calls clearAuth() on 401, skips hidden tabs, ignores network errors.</done>
</task>

<task type="auto">
  <name>Task 2: EV-CompassV2 — Add session polling to CompassContext.jsx</name>
  <files>/c/EV-CompassV2/src/components/CompassContext.jsx</files>
  <action>
Add a new `useEffect` inside the `CompassProvider` component, after the existing selectedTopics sync effect (around line 238). This effect polls GET /api/auth/session when the user is logged in.

Implementation:
```jsx
// Cross-app logout sync — detect ev_session cookie cleared by another app
useEffect(() => {
  if (!isLoggedIn) return;

  const SESSION_URL = `${API_BASE}/auth/session`;

  const poll = async () => {
    if (document.visibilityState !== 'visible') return;
    try {
      const res = await fetch(SESSION_URL, { credentials: 'include' });
      if (res.status === 401) {
        clearToken();
        setIsLoggedIn(false);
        setUsername(null);
      }
    } catch {
      // Network error — don't log out
    }
  };

  const id = setInterval(poll, 60_000);
  return () => clearInterval(id);
}, [isLoggedIn]);
```

`API_BASE` is already imported from `'../lib/auth'` at line 3. `clearToken` is already imported from the same module. `setIsLoggedIn` and `setUsername` are already state setters in the component.

Note: `API_BASE` is `'https://api.empowered.vote/api'` — so the session URL becomes `https://api.empowered.vote/api/auth/session` which is correct (same domain as the accounts API).

Commit to the EV-CompassV2 repo: `feat: add session polling for cross-app logout sync`
  </action>
  <verify>
Open `/c/EV-CompassV2/src/components/CompassContext.jsx` and confirm the new useEffect is placed before the return statement.
No type checking needed (JSX file).
  </verify>
  <done>CompassContext.jsx contains a 60s interval polling /api/auth/session that calls clearToken() + setIsLoggedIn(false) + setUsername(null) on 401, skips hidden tabs, ignores network errors.</done>
</task>

<task type="auto">
  <name>Task 3: Validation Quests — Add session polling to AuthContext.tsx</name>
  <files>/c/Validation Quests/frontend/src/contexts/AuthContext.tsx</files>
  <action>
Add a new `useEffect` inside the `AuthProvider` component, after the existing `useEffect` block (after line 97). This effect polls GET /api/auth/session when a Supabase session exists.

Implementation:
```tsx
// Cross-app logout sync — detect ev_session cookie cleared by another app
useEffect(() => {
  if (!session) return;

  const accountsApiUrl = import.meta.env.VITE_ACCOUNTS_API_URL as string;
  if (!accountsApiUrl) return;
  const SESSION_URL = `${accountsApiUrl}/api/auth/session`;

  const poll = async () => {
    if (document.visibilityState !== 'visible') return;
    try {
      const res = await fetch(SESSION_URL, { credentials: 'include' });
      if (res.status === 401) {
        await signOut();
      }
    } catch {
      // Network error — don't log out
    }
  };

  const id = setInterval(poll, 60_000);
  return () => clearInterval(id);
}, [session]);
```

`session` is already state in the component (line 12). `signOut` is already defined in the component (line 156). `VITE_ACCOUNTS_API_URL` is already used in the component. No new imports needed.

Note: VQ uses Supabase auth so `signOut()` handles both the accounts API logout POST and `supabase.auth.signOut()` — full cleanup. The `onAuthStateChange` handler then clears the session/user/profile state.

Commit to the Validation Quests repo: `feat: add session polling for cross-app logout sync`
  </action>
  <verify>
Run `cd "/c/Validation Quests/frontend" && npx tsc --noEmit` — no type errors.
Confirm the useEffect is placed after the main auth useEffect and before `initializeSession`.
  </verify>
  <done>AuthContext.tsx contains a 60s interval polling /api/auth/session that calls signOut() on 401, skips hidden tabs, ignores network errors.</done>
</task>

<task type="auto">
  <name>Task 4: Civic Spaces — Add session polling to useAuth.ts</name>
  <files>/c/Civic Spaces/src/hooks/useAuth.ts</files>
  <action>
Add a new `useEffect` inside the `useAuth` hook, after the existing `storage` event listener effect (after line 137). This effect polls GET /api/auth/session when the user is authenticated.

Implementation:
```ts
// Cross-app logout sync — detect ev_session cookie cleared by another app
useEffect(() => {
  if (!authState.isAuthenticated) return;

  const poll = async () => {
    if (document.visibilityState !== 'visible') return;
    try {
      const res = await fetch(ACCOUNTS_SESSION_URL, { credentials: 'include' });
      if (res.status === 401) {
        localStorage.removeItem('cs_token');
        setAuthState({ userId: null, isAuthenticated: false, isLoading: false });
      }
    } catch {
      // Network error — don't log out
    }
  };

  const id = setInterval(poll, 60_000);
  return () => clearInterval(id);
}, [authState.isAuthenticated]);
```

`ACCOUNTS_SESSION_URL` is already defined at line 3 as `'https://accounts-api.empowered.vote/api/auth/session'`. `setAuthState` is already the state setter. `cs_token` is the localStorage key used throughout the hook. No new imports needed.

Commit to the Civic Spaces repo: `feat: add session polling for cross-app logout sync`
  </action>
  <verify>
Run `cd "/c/Civic Spaces" && npx tsc --noEmit` — no type errors.
Confirm the useEffect is placed after the storage listener effect and before the return statement.
  </verify>
  <done>useAuth.ts contains a 60s interval polling ACCOUNTS_SESSION_URL that clears cs_token + resets authState on 401, skips hidden tabs, ignores network errors.</done>
</task>

<task type="auto">
  <name>Task 5: read-rank — Add session polling to useAuthState.ts</name>
  <files>/c/read-rank/src/hooks/useAuthState.ts</files>
  <action>
Add a new `useEffect` inside the `useAuthState` hook, after the existing SSO useEffect (after line 60, before the `logout` function definition). This effect polls GET /api/auth/session when the user is logged in.

Implementation:
```ts
// Cross-app logout sync — detect ev_session cookie cleared by another app
useEffect(() => {
  if (!state.isLoggedIn) return;

  const SESSION_URL = `${API_HUB_URL}/api/auth/session`;

  const poll = async () => {
    if (document.visibilityState !== 'visible') return;
    try {
      const res = await fetch(SESSION_URL, { credentials: 'include' });
      if (res.status === 401) {
        clearToken();
        setState({ isLoggedIn: false, userName: null, jurisdictionState: null, loading: false });
      }
    } catch {
      // Network error — don't log out
    }
  };

  const id = setInterval(poll, 60_000);
  return () => clearInterval(id);
}, [state.isLoggedIn]);
```

`API_HUB_URL` is already imported from `'../lib/auth'` at line 2. `clearToken` is already imported from the same module. `setState` is the existing state setter. No new imports needed.

Commit to the read-rank repo: `feat: add session polling for cross-app logout sync`
  </action>
  <verify>
Run `cd /c/read-rank && npx tsc --noEmit` — no type errors.
Confirm the useEffect is placed after the SSO effect and before the logout function.
  </verify>
  <done>useAuthState.ts contains a 60s interval polling /api/auth/session that calls clearToken() + resets state on 401, skips hidden tabs, ignores network errors.</done>
</task>

</tasks>

<verification>
After all 5 tasks complete:
1. Each file contains a new useEffect with `setInterval(poll, 60_000)`
2. Each poll function checks `document.visibilityState !== 'visible'` before fetching
3. Each poll function calls the app-specific logout on 401
4. Each poll function catches and ignores network errors
5. Each interval is cleaned up in the useEffect return
6. No TypeScript errors in any repo with TS files
</verification>

<success_criteria>
- 5 files modified across 5 repos, each with a session polling useEffect
- Zero backend changes needed (GET /api/auth/session already exists)
- Each repo has its own atomic commit
- Not covered (noted): CTC, Essentials, Treasury Tracker (not locally available)
</success_criteria>

<output>
After completion, create `/c/EV-Accounts/.planning/quick/015-session-polling-cross-app-logout-sync/015-SUMMARY.md`
</output>
