---
phase: 84-essentials-header-integration
verified: 2026-03-13T01:00:00Z
status: human_needed
score: 7/7 automated must-haves verified
re_verification: false
human_verification:
  - test: "SiteHeader visible on every page at runtime"
    expected: "Navigating to Landing, Results, Profile, LegislativeRecord, and CandidateProfile in the dev server shows the SiteHeader at the top of each page"
    why_human: "Layout is wired and build passes, but actual DOM rendering and visual correctness cannot be confirmed without a running browser"
  - test: "Logged-in user sees username and Sign out in header dropdown"
    expected: "When authenticated via compass.empowered.vote, clicking the profile icon in the header shows the username as the label and a Sign out button"
    why_human: "Auth state is loaded at runtime from /auth/me — cannot verify session cookie behavior or the displayed value statically"
  - test: "Logged-out user sees Sign in link in header dropdown"
    expected: "When not authenticated, clicking the profile icon shows a Sign in link pointing to compass.empowered.vote/login with a returnTo query param encoding the current URL"
    why_human: "returnTo encoding uses window.location.href at render time; must be verified in a live browser"
  - test: "Sign out clears header state without page redirect"
    expected: "Clicking Sign out calls logout(), which POSTs to /auth/logout, then the header immediately switches from username to Sign in with no full-page navigation"
    why_human: "Reactive state transition and network call require a running browser session to observe"
  - test: "AuthIndicator floating bubble is absent on all pages"
    expected: "No initials bubble appears in the top-right corner of any page"
    why_human: "AuthIndicator.jsx still exists as a file; its absence from all pages is confirmed by grep but visual confirmation is a human concern"
---

# Phase 84: Essentials Header Integration Verification Report

**Phase Goal:** Integrate the shared SiteHeader from ev-ui into the Essentials app so every page has a consistent, auth-aware navigation header with sign-in/sign-out functionality.
**Verified:** 2026-03-13T01:00:00Z
**Status:** human_needed (all automated checks passed)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | ev-ui v0.1.49 is installed in essentials (SiteHeader with updated URLs) | VERIFIED | `package.json` line 13: `"@chrisandrewsedu/ev-ui": "^0.1.49"` |
| 2 | CompassContext exposes a logout() function that POSTs to /auth/logout and resets isLoggedIn, userName, userAnswers, selectedTopics, verdicts | VERIFIED | Lines 143-154 of CompassContext.jsx; `logout` included in useMemo value at line 168 |
| 3 | Layout component renders SiteHeader with profileMenu when logged in, or Sign in link item when logged out | VERIFIED | Layout.jsx lines 7-24: conditional profileMenu; SiteHeader rendered at line 24 |
| 4 | All 5 pages import and use Layout (Landing, Results, Profile, LegislativeRecord, CandidateProfile) | VERIFIED | grep confirms `import { Layout }` and `<Layout>` present in all 5 page files |
| 5 | No page imports Header or SiteHeader directly | VERIFIED | grep of `import.*(Header\|SiteHeader)` in pages/ returns no matches |
| 6 | AuthIndicator floating bubble removed from App.jsx | VERIFIED | App.jsx has no AuthIndicator import or usage; only CompassProvider + Routes remain |
| 7 | No dead navItems or ctaButton vars remain in pages | VERIFIED | grep of `navItems\|ctaButton` in pages/ returns no matches |

**Score:** 7/7 automated truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `essentials/package.json` | ev-ui ^0.1.49 dependency | VERIFIED | Line 13 confirms `^0.1.49` |
| `essentials/src/contexts/CompassContext.jsx` | logout function in context value | VERIFIED | logout defined at line 143, included in useMemo value at line 168 |
| `essentials/src/components/Layout.jsx` | Auth-aware SiteHeader wrapper | VERIFIED | 28-line substantive component; imports SiteHeader and useCompass; conditional profileMenu; renders children |
| `essentials/src/App.jsx` | Clean shell — no AuthIndicator | VERIFIED | 24 lines; CompassProvider + BrowserRouter + Routes only |
| `essentials/src/pages/Landing.jsx` | Layout-wrapped, no standalone SiteHeader | VERIFIED | Imports Layout, renders `<Layout>`, no Header/SiteHeader import |
| `essentials/src/pages/Results.jsx` | Layout-wrapped, no standalone SiteHeader | VERIFIED | Imports Layout, renders `<Layout>`, no Header/SiteHeader import |
| `essentials/src/pages/Profile.jsx` | Layout-wrapped, Header import replaced | VERIFIED | Imports Layout, renders `<Layout>`, no Header import |
| `essentials/src/pages/LegislativeRecord.jsx` | Layout-wrapped, Header import replaced | VERIFIED | Imports Layout, renders `<Layout>`, no Header import |
| `essentials/src/pages/CandidateProfile.jsx` | Layout-wrapped, Header import replaced | VERIFIED | Imports Layout, renders `<Layout>`, no Header import |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Layout.jsx` | `CompassContext.jsx` | `useCompass()` hook | WIRED | Line 5 of Layout.jsx: `const { isLoggedIn, userName, logout } = useCompass()` |
| `Layout.jsx` | `@chrisandrewsedu/ev-ui SiteHeader` | `profileMenu` prop | WIRED | Line 24: `<SiteHeader logoSrc="/EVLogo.svg" profileMenu={profileMenu} />` |
| All 5 pages | `Layout.jsx` | `import { Layout }` + JSX wrapping | WIRED | grep confirms import and `<Layout>` in all 5 page files |
| `App.jsx` | AuthIndicator removal | deleted import + fixed div | WIRED | AuthIndicator absent from App.jsx entirely |
| `Layout.jsx` | Sign in redirect with returnTo | `window.location.href` encoded in href | WIRED | Line 17: `href: \`https://compass.empowered.vote/login?returnTo=...\`` |
| `CompassV2/src/pages/Login.jsx` | returnTo redirect after auth | `searchParams.get("returnTo")` + `window.location.href` | WIRED | Lines 14, 27-28, 85-86, 91-92 of Login.jsx confirm returnTo is read and applied on successful auth |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| ESS-01 | 84-02 | User sees SiteHeader at the top of every Essentials page | SATISFIED | All 5 pages use `<Layout>` which renders SiteHeader as first child |
| ESS-02 | 84-01, 84-02 | Logged-in user sees their username in the Essentials header with a logout option | SATISFIED | Layout builds profileMenu with `userName \|\| "Account"` label and `{ label: "Sign out", onClick: logout }` item when `isLoggedIn` is true |
| ESS-03 | 84-01, 84-02 | Logged-out user sees a "Sign in" link in the Essentials header that navigates to Compass login | SATISFIED | Layout builds profileMenu with `{ label: "Sign in", href: "https://compass.empowered.vote/login?returnTo=..." }` when `isLoggedIn` is false |
| ESS-04 | 84-01, 84-02 | User can log out from Essentials — session is cleared and page resets to logged-out state | SATISFIED | `logout()` POSTs to `/auth/logout`, then calls `setIsLoggedIn(false)`, `setUserName(null)`, `setUserAnswers([])`, `setSelectedTopics([])`, `setVerdicts({})` |

All 4 requirements satisfied. All 4 are marked `[x]` in REQUIREMENTS.md and mapped to Phase 84 in the status table.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `essentials/src/components/AuthIndicator.jsx` | File still exists but is orphaned (no imports) | Info | No functional impact; dead file can be deleted in future cleanup |

No blocker or warning-level anti-patterns found in any modified file.

### Human Verification Required

#### 1. SiteHeader visible on every page at runtime

**Test:** Run `npm run dev` in `essentials/`, then navigate to `/`, `/results?q=Beverly+Hills+CA`, and any `/politician/:id` route.
**Expected:** SiteHeader appears at the top of each page with the EV logo.
**Why human:** Build passes and Layout is wired, but visual rendering requires a browser.

#### 2. Logged-in user sees username and Sign out in header dropdown

**Test:** After authenticating via compass.empowered.vote, visit the Essentials app and click the profile icon in the header.
**Expected:** Dropdown label shows the authenticated username; a "Sign out" button is present.
**Why human:** Auth state is determined at runtime by `/auth/me` — cannot verify the displayed username statically.

#### 3. Logged-out user sees Sign in link with correct returnTo

**Test:** Without an active session, click the profile icon in the header.
**Expected:** Dropdown shows "Sign in" link; clicking it navigates to `https://compass.empowered.vote/login?returnTo=<encoded-current-URL>`.
**Why human:** `window.location.href` is runtime-only; must be confirmed in a browser.

#### 4. Sign out clears header state without redirect

**Test:** While logged in, click "Sign out" in the header dropdown.
**Expected:** Header immediately switches from username state to "Sign in" state. No full-page navigation occurs.
**Why human:** React state transition and network call require a running browser to observe.

#### 5. AuthIndicator floating bubble is absent on all pages

**Test:** Navigate all pages and confirm no floating initials bubble appears in the top-right corner.
**Expected:** No floating element in any corner. The `AuthIndicator.jsx` file exists but is unused.
**Why human:** Visual confirmation requires a browser.

### Gaps Summary

No gaps found. All automated must-haves are fully satisfied:

- ev-ui v0.1.49 is installed
- CompassContext exports a working `logout()` function included in the context value
- Layout.jsx is substantive, correctly wired to both SiteHeader and useCompass, and handles both auth states
- All 5 pages import and use Layout with no residual Header/SiteHeader imports
- App.jsx is clean — no AuthIndicator
- The returnTo cross-app login redirect is implemented in both Layout.jsx and CompassV2/Login.jsx
- Build produces 67 modules with 0 errors

The only items requiring resolution are runtime behaviors that must be human-verified in a browser session.

---

_Verified: 2026-03-13T01:00:00Z_
_Verifier: Claude (gsd-verifier)_
