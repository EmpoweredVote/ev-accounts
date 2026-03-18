---
phase: quick
plan: 005
type: execute
wave: 1
depends_on: []
files_modified:
  - admin/src/pages/Login.tsx
  - app/src/App.tsx
  - app/src/components/AuthGuard.tsx
autonomous: true

must_haves:
  truths:
    - "User logs in once on accounts.empowered.vote and lands on profile.empowered.vote authenticated"
    - "Profile app redirects unauthenticated users to accounts login with redirect param"
    - "Token passed via hash fragment, never in query string or server logs"
  artifacts:
    - path: "admin/src/pages/Login.tsx"
      provides: "Accounts login passes token via hash fragment on redirect"
      contains: "#access_token="
    - path: "app/src/App.tsx"
      provides: "Token extraction from hash fragment on mount"
      contains: "access_token"
    - path: "app/src/components/AuthGuard.tsx"
      provides: "External redirect to accounts login"
      contains: "accounts.empowered.vote"
  key_links:
    - from: "admin/src/pages/Login.tsx"
      to: "app/src/App.tsx"
      via: "hash fragment #access_token=TOKEN on redirect URL"
      pattern: "access_token"
    - from: "app/src/components/AuthGuard.tsx"
      to: "admin/src/pages/Login.tsx"
      via: "redirect to accounts.empowered.vote/login?redirect="
      pattern: "accounts\\.empowered\\.vote/login"
---

<objective>
Fix the double-login flow between accounts.empowered.vote and profile.empowered.vote so users authenticate once.

Purpose: Currently users must log in separately on both apps. After this fix, accounts is the auth hub — profile delegates to it and receives the token back via URL hash fragment.

Output: Three file changes that complete the single-sign-on loop.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@admin/src/pages/Login.tsx
@admin/src/lib/redirect.ts
@app/src/App.tsx
@app/src/pages/LoginPage.tsx
@app/src/components/AuthGuard.tsx
@app/src/store/authStore.ts
@app/src/lib/api.ts
</context>

<tasks>

<task type="auto">
  <name>Task 1: Accounts login — append access_token hash fragment to redirect URL</name>
  <files>admin/src/pages/Login.tsx</files>
  <action>
  In the `handleSubmit` function, modify the redirect logic (lines 67-71) so that when redirecting to an external URL, the access token is appended as a hash fragment.

  Current code:
  ```
  if (validRedirect) {
    window.location.href = validRedirect;
  } else {
    window.location.href = 'https://profile.empowered.vote';
  }
  ```

  Change to:
  ```
  const target = validRedirect || 'https://profile.empowered.vote';
  window.location.href = `${target}#access_token=${token}`;
  ```

  This passes the token via hash fragment. Hash fragments are never sent to servers, never logged by web servers, and Supabase already uses this pattern for magic links. The `token` variable is already in scope (line 45).

  Do NOT change anything else in Login.tsx — the local setAuth call (lines 58-64) should remain so accounts itself stays authenticated.
  </action>
  <verify>Read the file and confirm the redirect lines now include `#access_token=`.</verify>
  <done>Both redirect paths (validRedirect and default profile URL) append the hash fragment with the access token.</done>
</task>

<task type="auto">
  <name>Task 2: Profile App.tsx — extract token from hash fragment on mount</name>
  <files>app/src/App.tsx</files>
  <action>
  Modify the `useEffect` at the top of the App component (lines 25-48) to check for a hash fragment token BEFORE checking localStorage.

  The new logic at the start of the useEffect should be:

  ```typescript
  // Check for token passed via hash fragment from accounts login
  const hash = window.location.hash;
  if (hash.includes('access_token=')) {
    const params = new URLSearchParams(hash.substring(1)); // strip the #
    const hashToken = params.get('access_token');
    if (hashToken) {
      // Clean the URL immediately (remove hash fragment with token)
      window.history.replaceState(null, '', window.location.pathname + window.location.search);
      // Set token in store so apiFetch picks it up
      useAuthStore.setState({ accessToken: hashToken });
      // Persist to localStorage
      localStorage.setItem('ev_token', hashToken);
      // Fetch user profile with this token
      apiFetch<MeResponse>('/account/me')
        .then((me) => {
          const user: User = {
            id: me.id,
            email: me.email,
            tier: me.tier,
            displayName: me.display_name,
            completedOnboarding: me.completed_onboarding,
            locationConsent: me.location_consent,
          };
          setAuth(hashToken, user);
        })
        .catch(() => {
          clearAuth();
        });
      return; // Skip localStorage check — we have a fresh token
    }
  }
  ```

  Place this block BEFORE the existing `const token = getStoredToken();` line. The `return` ensures we don't also run the localStorage path.

  The rest of the useEffect (localStorage check) stays exactly as-is for returning users who already have a stored token.

  Do NOT remove the second useEffect that syncs accessToken to localStorage (lines 50-54) — it remains useful.
  </action>
  <verify>Read the file and confirm the hash fragment extraction is present. Then run `cd C:/EV-Accounts && npx tsc --noEmit --project app/tsconfig.json 2>&1 | head -20` to check for type errors.</verify>
  <done>Profile app extracts access_token from hash fragment, calls /account/me, sets auth state, and cleans the URL — all before falling back to localStorage token check.</done>
</task>

<task type="auto">
  <name>Task 3: AuthGuard — redirect to accounts login instead of internal /login</name>
  <files>app/src/components/AuthGuard.tsx</files>
  <action>
  Change the AuthGuard so unauthenticated users are redirected to the accounts app login page (external) instead of the internal `/login` route.

  Replace:
  ```tsx
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  ```

  With:
  ```tsx
  if (!isAuthenticated) {
    // Redirect to accounts auth hub with return URL
    const returnUrl = encodeURIComponent(window.location.origin + window.location.pathname);
    window.location.href = `https://accounts.empowered.vote/login?redirect=${returnUrl}`;
    // Return spinner while redirect happens
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-6 h-6 border-2 border-ev-teal border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }
  ```

  This sends the user to accounts.empowered.vote/login with a `?redirect=` param pointing back to the profile page they were trying to access. The accounts login page already validates redirect URLs against *.empowered.vote (see `admin/src/lib/redirect.ts`).

  The `Navigate` import from react-router-dom can be removed since it is no longer used. Check if `Outlet` is still needed (it is — for the authenticated children). Final import should be: `import { Outlet } from 'react-router-dom';`

  Profile's own LoginPage.tsx and `/login` route in App.tsx remain as fallback — do NOT delete them. They serve as a direct-access option if someone navigates to profile.empowered.vote/login directly.
  </action>
  <verify>Read the file. Confirm `Navigate` import is removed, redirect URL points to accounts.empowered.vote, and `Outlet` is still returned for authenticated users. Run `cd C:/EV-Accounts && npx tsc --noEmit --project app/tsconfig.json 2>&1 | head -20` to check for type errors.</verify>
  <done>Unauthenticated users on profile are redirected to accounts.empowered.vote/login with a redirect param back to profile. The full SSO loop works: profile -> accounts login -> profile#access_token=TOKEN -> authenticated.</done>
</task>

</tasks>

<verification>
1. `npx tsc --noEmit --project app/tsconfig.json` — no type errors in profile app
2. `npx tsc --noEmit --project admin/tsconfig.json` — no type errors in accounts app (if tsconfig exists)
3. Manual flow test: visit profile.empowered.vote unauthenticated -> redirects to accounts.empowered.vote/login?redirect=... -> login -> redirects back to profile.empowered.vote#access_token=... -> profile extracts token, authenticates, cleans URL
</verification>

<success_criteria>
- Accounts login appends #access_token=TOKEN to redirect URLs
- Profile extracts token from hash fragment on mount and authenticates
- AuthGuard redirects unauthenticated profile users to accounts login with redirect param
- No TypeScript compilation errors in either app
- Profile's own /login route still works as fallback
</success_criteria>

<output>
After completion, create `.planning/quick/005-fix-double-login-accounts-to-profile/005-SUMMARY.md`
</output>
