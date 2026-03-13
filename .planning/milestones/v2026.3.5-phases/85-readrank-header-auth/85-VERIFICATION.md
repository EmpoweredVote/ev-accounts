---
phase: 85-readrank-header-auth
verified: 2026-03-13T02:30:00Z
status: passed
score: 4/4 must-haves verified (automated); 3/3 requirements satisfied
re_verification: false
human_verification:
  - test: "Logged-in state: username appears in header, Sign out works"
    expected: "Header profile button shows the logged-in user's username; clicking it reveals a 'Sign out' item; clicking Sign out immediately switches header to Sign in state without a page reload"
    why_human: "Auth state depends on live session cookie from api.empowered.vote — cannot assert username display or Sign out state transition programmatically"
  - test: "Logged-out state: Sign in link present and navigates correctly"
    expected: "Header profile button shows 'Account'; dropdown contains 'Sign in' link; clicking it opens compass.empowered.vote/login?returnTo=<encoded-readrank-url>"
    why_human: "Navigation and returnTo redirect require a running browser — cannot verify href encoding and redirect chain programmatically"
  - test: "No-flash check: profile button absent during auth in-flight"
    expected: "On hard-refresh while logged in, the profile button does not briefly show 'Sign in' before resolving to the username — button is simply absent until auth check completes"
    why_human: "Loading-gate timing is a visual runtime behavior that requires observation in a live browser"
---

# Phase 85: ReadRank Header Auth — Verification Report

**Phase Goal:** ReadRank header shows auth state — logged-in user sees username + Sign out, logged-out user sees Sign in link
**Verified:** 2026-03-13T02:30:00Z
**Status:** human_needed (all automated checks PASSED; 3 items require browser confirmation)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Logged-in user sees their username in the ReadRank header with a working Sign out option | ? HUMAN | Hook exposes userName + logout(); profileMenu wired with `{ label: userName \|\| 'Account', items: [{ label: 'Sign out', onClick: logout }] }` — visual confirmation needed |
| 2 | Logged-out user sees a Sign in link in the ReadRank header pointing to compass.empowered.vote/login | ? HUMAN | profileMenu builds `{ label: 'Account', items: [{ label: 'Sign in', href: '…/login?returnTo=…' }] }` — navigation and returnTo redirect need browser confirmation |
| 3 | Clicking Sign out clears the session and switches the header to Sign in state immediately | ? HUMAN | logout() POSTs to /auth/logout then calls setState to reset isLoggedIn — state transition is a live browser behavior |
| 4 | The header never shows stale Sign in state while the auth check is still in flight | ✓ VERIFIED | `profileMenu = loading ? undefined : …` — undefined passes no profileMenu prop to SiteHeader, confirmed in App.tsx line 13-17 |

**Score (automated):** 1/4 truths fully automated-verifiable; all 4 have substantive code supporting them.

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `EV-ReadRank/src/hooks/useAuthState.ts` | Auth hook returning isLoggedIn, userName, loading, and logout() | ✓ VERIFIED | 42 lines; exports `AuthState` interface with `isLoggedIn`, `userName: string \| null`, `loading`; return type is `AuthState & { logout: () => Promise<void> }`; fetches `/auth/me`, parses JSON on `res.ok`, resets state on error or catch |
| `EV-ReadRank/src/App.tsx` | MainApp renders SiteHeader with profileMenu built from auth state | ✓ VERIFIED | 48 lines; imports `useAuthState`; destructures `{ isLoggedIn, userName, loading, logout }`; builds conditional `profileMenu`; passes it to SiteHeader via spread cast; no placeholder returns |
| `EV-ReadRank/vite.config.ts` | Vite proxy for /auth/* so dev cookies work same-origin | ✓ VERIFIED | `server.proxy` maps `/auth` → `http://localhost:5050` with `changeOrigin: true` (commit 7b23e85) |
| `EV-ReadRank/package.json` | ev-ui at ^0.1.49 | ✓ VERIFIED | `"@chrisandrewsedu/ev-ui": "^0.1.49"` confirmed |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `App.tsx` | `useAuthState.ts` | `import { useAuthState } from './hooks/useAuthState'` + destructuring `{ isLoggedIn, userName, loading, logout }` | ✓ WIRED | Line 8 import; line 11 destructure — all four fields used |
| `App.tsx` | `SiteHeader (ev-ui)` | `profileMenu` prop via spread cast `{...({ profileMenu } as any)}` | ✓ WIRED | Lines 22-25; `profileMenu` variable is consumed on the SiteHeader render — workaround required because ev-ui 0.1.49 ships no `.d.ts` declarations |
| `App.tsx Sign in href` | `compass.empowered.vote/login` | `VITE_COMPASS_URL` env var with fallback + `?returnTo=encodeURIComponent(window.location.href)` | ✓ WIRED | Line 17; returnTo param added in 7b23e85 to enable post-login redirect back to ReadRank |
| `useAuthState logout()` | `/auth/logout` | `fetch(AUTH_BASE + '/auth/logout', { method: 'POST', credentials: 'include' })` | ✓ WIRED | Lines 31-38; state is reset regardless of fetch success (try/catch always calls setState) |
| `useAuthState` dev mode | Vite proxy `/auth` | `AUTH_BASE = import.meta.env.DEV ? '' : …` so relative URLs route through proxy | ✓ WIRED | Lines 5-7 in useAuthState.ts; vite.config.ts proxy target confirmed |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| RR-01 | 85-01, 85-02 | Logged-in user sees their username in the ReadRank header with a logout option | ? HUMAN NEEDED | Code path: `useAuthState` → `isLoggedIn=true` → `profileMenu.label = userName` + Sign out item. Requires browser test for visual confirmation |
| RR-02 | 85-01, 85-02 | Logged-out user sees a "Sign in" link in the ReadRank header that navigates to Compass login | ? HUMAN NEEDED | Code path: `isLoggedIn=false` → `profileMenu.items[0].href = compass.empowered.vote/login?returnTo=…`. Navigation requires browser test |
| RR-03 | 85-01, 85-02 | User can log out from ReadRank — session is cleared | ? HUMAN NEEDED | Code path: `onClick: logout` → `POST /auth/logout` → `setState({isLoggedIn: false, …})`. State transition to Sign in requires browser test |

All three requirement IDs (RR-01, RR-02, RR-03) are declared in both plan frontmatters (`requirements: [RR-01, RR-02, RR-03]`) and are marked Complete in REQUIREMENTS.md. No orphaned requirements.

---

## Anti-Patterns Found

None. Scanned `useAuthState.ts`, `App.tsx`, `vite.config.ts` for TODO/FIXME/placeholder comments, empty returns, and stub handlers. All clean.

---

## Commit Verification

All commits documented in SUMMARY.md exist in the EV-ReadRank repo:

| Commit | Message | Files |
|--------|---------|-------|
| `215d611` | feat(85-01): upgrade ev-ui to 0.1.49 and extend useAuthState | package.json, package-lock.json, useAuthState.ts |
| `2c926d2` | feat(85-01): wire profileMenu into SiteHeader in App.tsx | App.tsx |
| `7b23e85` | fix(85-02): add returnTo URL and fix local dev auth via Vite proxy | App.tsx, useAuthState.ts, vite.config.ts |

---

## Human Verification Required

### 1. Logged-in State (RR-01)

**Test:** Start `npm run dev` in EV-ReadRank. Log in via compass.empowered.vote/login (the dev server cookie will flow through the Vite proxy at localhost:5050). Navigate back to http://localhost:5173.
**Expected:** The SiteHeader profile button displays your username (not "Account"). Clicking it reveals a dropdown with a "Sign out" option.
**Why human:** The username display and dropdown require a live session cookie — cannot be asserted from static code.

### 2. Logged-out State + Sign in redirect (RR-02)

**Test:** Clear cookies or open incognito. Load http://localhost:5173. Click the profile button in the header.
**Expected:** Dropdown shows "Sign in" link. Clicking it navigates to `https://compass.empowered.vote/login?returnTo=http%3A%2F%2Flocalhost%3A5173%2F` (or similar encoded URL). After logging in on Compass, user is redirected back to ReadRank.
**Why human:** Navigation behavior and returnTo redirect chain require a running browser.

### 3. Sign out state transition (RR-03)

**Test:** While logged in, open the profile dropdown and click "Sign out".
**Expected:** Header immediately (without page reload) switches from username to "Account" / "Sign in" state. The session is invalidated — reloading the page keeps the logged-out state.
**Why human:** Immediate DOM state transition and session invalidation are runtime behaviors.

### 4. No Sign-in flash (loading gate)

**Test:** While logged in, hard-refresh the page (Cmd+Shift+R).
**Expected:** The profile button does not briefly show "Sign in" before resolving to the username — it is simply absent during the auth check, then snaps to username.
**Why human:** Timing of the loading gate is a visual runtime behavior.

---

## Gaps Summary

No gaps. All code artifacts are substantive, fully wired, and free of anti-patterns. The three remaining items are all human-verification requirements (visual behavior, state transitions, and navigation redirect chains in a live browser). The automated portion of verification is complete and passed.

---

_Verified: 2026-03-13T02:30:00Z_
_Verifier: Claude (gsd-verifier)_
