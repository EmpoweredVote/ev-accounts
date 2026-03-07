---
phase: 67-compass-api-integration
verified: 2026-03-07T00:00:00Z
status: human_needed
score: 11/11 automated truths verified
re_verification: false
human_verification:
  - test: "Open Essentials app while logged into CompassV2 at same browser session. Search an address on the Results page."
    expected: "A small teal initials circle appears in the top-right corner of the screen, confirming the session cookie from api.empowered.vote is shared via the .empowered.vote domain."
    why_human: "Cross-domain cookie sharing requires live browser session; can't verify programmatically from source alone."
  - test: "On the Results page, locate a politician who has compass stances (currently ~23 of 800+). Confirm a small compass badge button appears on their card."
    expected: "Only politicians with stances show the badge. Politicians without stances show no badge."
    why_human: "Badge visibility depends on runtime data returned by /compass/politicians; which politicians have stances can't be verified statically."
  - test: "Click a compass badge on a politician card."
    expected: "A tooltip-style popover appears with a mini radar chart showing the politician's stance polygon. Clicking outside or scrolling dismisses the popover."
    why_human: "Popover positioning, rendering correctness, and dismiss behavior require visual/interaction testing."
  - test: "While logged in with compass answers, click a compass badge."
    expected: "The popover shows two polygons: pink for politician stances, blue for the user's answers."
    why_human: "User overlay rendering depends on runtime /compass/answers data."
  - test: "While NOT logged in, click a compass badge."
    expected: "The popover shows a greyed-out compass icon and 'Take the Quiz' CTA button, not an empty/broken chart."
    why_human: "CTA mode depends on runtime auth state and userAnswers being empty array."
---

# Phase 67: Compass API Integration — Verification Report

**Phase Goal:** Essentials can fetch logged-in user compass answers and politician stances from the existing API
**Verified:** 2026-03-07
**Status:** human_needed (all automated checks passed; 5 items require browser testing)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Success Criteria (from ROADMAP.md)

| #   | Success Criterion                                                                 | Status     | Evidence                                                                                          |
|-----|-----------------------------------------------------------------------------------|------------|---------------------------------------------------------------------------------------------------|
| 1   | A logged-in user's compass answers are accessible from Essentials when the API is called | ? HUMAN  | `fetchUserAnswers()` calls `/compass/answers` with `credentials: include`; runtime needed to confirm session sharing works cross-domain |
| 2   | An Essentials profile/results page can fetch all stance records for a given politician | ✓ VERIFIED | `CompassPreview.jsx` calls `fetchPoliticianAnswers(politicianId)` on mount and renders result via `RadarChartCore` |
| 3   | CORS and credentials are correctly configured for essentials' origin               | ✓ VERIFIED | `essentials.empowered.vote` + `essentials-dev.empowered.vote` in CORS allow-list (middleware.go L63-64); `Access-Control-Allow-Credentials: true` set (L84); all fetch calls use `credentials: "include"` |

---

### Observable Truths — Plan 01

| #   | Truth                                                                                       | Status     | Evidence                                                                                   |
|-----|---------------------------------------------------------------------------------------------|------------|--------------------------------------------------------------------------------------------|
| 1   | Session cookies in production use Domain `.empowered.vote` for cross-app session sharing    | ✓ VERIFIED | `handlers.go` L45: `domain := ".empowered.vote"`; branched to `""` when `PORT == "" \|\| HasPrefix("5050")` |
| 2   | Session cookies in local dev do NOT set a Domain (current behavior preserved)               | ✓ VERIFIED | `handlers.go` L52: `domain = ""` when local dev condition met                             |
| 3   | `fetchUserAnswers()` exported from `essentials/src/lib/compass.js`                         | ✓ VERIFIED | L24-36: exported async function, calls `/compass/answers`, returns `[]` on 401/error       |
| 4   | `fetchSelectedTopics()` exported from `essentials/src/lib/compass.js`                      | ✓ VERIFIED | L40-52: exported async function, calls `/compass/selected-topics`, returns `[]` on 401/error |
| 5   | `fetchPoliticiansWithStances()` exported from `essentials/src/lib/compass.js`              | ✓ VERIFIED | L56-67: exported async function, calls `/compass/politicians`, returns `[]` on error       |

### Observable Truths — Plan 02

| #   | Truth                                                                                          | Status     | Evidence                                                                                   |
|-----|------------------------------------------------------------------------------------------------|------------|--------------------------------------------------------------------------------------------|
| 1   | `CompassProvider` wraps entire Essentials app and provides auth state + compass data           | ✓ VERIFIED | `App.jsx` L12-22: `<CompassProvider>` wraps all `<Routes>`                                |
| 2   | Context provides `isLoggedIn`, `userName`, `userAnswers`, `selectedTopics`, `allTopics`, `politicianIdsWithStances`, `compassLoading` | ✓ VERIFIED | `CompassContext.jsx` L82-101: all 7 values in `useMemo` value object |
| 3   | Auth check (`GET /auth/me`) runs on every page load                                            | ✓ VERIFIED | `CompassContext.jsx` L34-36: fetches `/auth/me` inside `useEffect([])` on mount            |
| 4   | When logged in, a small initials circle appears in the nav bar right side                      | ? HUMAN    | `AuthIndicator.jsx` returns a 32px teal circle with initials when `isLoggedIn && userName`; requires live browser to confirm |
| 5   | When not logged in, nav bar right side is empty                                                | ? HUMAN    | `AuthIndicator.jsx` L5: `if (!isLoggedIn \|\| !userName) return null`; requires live session |
| 6   | Compass data fetches on mount (topics, user answers, selected topics, politician stance list)   | ✓ VERIFIED | `CompassContext.jsx` L39-56: `Promise.all([fetchTopics(), fetchPoliticiansWithStances()])` always; user data gated on `authRes.ok` |

### Observable Truths — Plan 03

| #   | Truth                                                                                              | Status     | Evidence                                                                                  |
|-----|-----------------------------------------------------------------------------------------------------|------------|-------------------------------------------------------------------------------------------|
| 1   | Politicians with compass stances show a compass badge/button on their card in the Results page      | ? HUMAN    | `Results.jsx` L493, 505: `onCompassClick` prop set only when `politicianIdsWithStances.has(pol.id)`; badge visibility depends on runtime data |
| 2   | Politicians without compass stances do NOT show a compass badge                                    | ✓ VERIFIED | `Results.jsx` L505: `onCompassClick={hasStances ? ... : undefined}` — `undefined` means `PoliticianCard` renders no badge |
| 3   | Tapping/clicking the compass badge shows a mini radar chart preview                                | ? HUMAN    | `CompassPreview` rendered via portal at `Results.jsx` L784-794; requires browser to confirm |
| 4   | The preview shows the politician's stance data as a radar polygon                                  | ✓ VERIFIED | `CompassPreview.jsx` L334-344: `<RadarChartCore topics={topics} data={polData} .../>` when `hasData` |
| 5   | If logged in with compass answers, preview shows user's overlay                                    | ? HUMAN    | `CompassPreview.jsx` L338: `compareData={Object.keys(userData).length > 0 ? userData : {}}` — logic correct; requires runtime confirmation |
| 6   | Tapping outside the preview dismisses it                                                           | ✓ VERIFIED | `CompassPreview.jsx` L95-104: `pointerdown` listener on document with 50ms delay; L88-92: scroll listener |
| 7   | The preview feels like a tooltip/popover, not a modal                                              | ? HUMAN    | Portal + `position:fixed` + no backdrop on desktop; requires visual confirmation          |

**Automated Score:** 11/11 truths verifiable without human pass automated checks.
**Human Score:** 5 items require browser testing.

---

## Required Artifacts

| Artifact                                              | Provides                                              | Status     | Details                                                             |
|-------------------------------------------------------|-------------------------------------------------------|------------|---------------------------------------------------------------------|
| `EV-Backend/internal/auth/handlers.go`                | Cookie Domain branching in `sessionCookie()`          | ✓ VERIFIED | L42-65: `domain := ".empowered.vote"`, branched to `""` in local dev; Go build passes with zero errors |
| `essentials/src/lib/compass.js`                       | `fetchUserAnswers`, `fetchSelectedTopics`, `fetchPoliticiansWithStances` | ✓ VERIFIED | All 3 functions exported; existing 3 functions unchanged; Vite build passes |
| `essentials/src/contexts/CompassContext.jsx`          | `CompassProvider` + `useCompass` hook                 | ✓ VERIFIED | Exports `CompassProvider` and `useCompass`; all 7 context values provided via `useMemo` |
| `essentials/src/components/AuthIndicator.jsx`         | Small avatar/initials indicator for nav bar           | ✓ VERIFIED | Exports default; returns `null` when logged out, initials circle when logged in |
| `essentials/src/App.jsx`                              | App wrapped with `CompassProvider`                    | ✓ VERIFIED | L12: `<CompassProvider>` wraps all routes; `AuthIndicator` in fixed overlay L13-15 |
| `essentials/src/components/CompassPreview.jsx`        | Mini radar chart tooltip/popover component            | ✓ VERIFIED | Exports default; uses portal, fetches politician answers, renders `RadarChartCore`, handles CTA mode |
| `essentials/src/pages/Results.jsx`                    | Compass badge integration on `PoliticianCard`         | ✓ VERIFIED | L188: `useCompass()` called; L493-512: `onCompassClick` conditional on `hasStances`; L784: `CompassPreview` rendered |

---

## Key Link Verification

### Plan 01 Key Links

| From                             | To                         | Via                              | Status     | Details                                                     |
|----------------------------------|----------------------------|----------------------------------|------------|-------------------------------------------------------------|
| `essentials/src/lib/compass.js`  | `/compass/answers`         | `fetch` with `credentials: include` | ✓ WIRED | L26-28: `fetch(\`${API}/compass/answers\`, { credentials: "include" })` |
| `essentials/src/lib/compass.js`  | `/compass/selected-topics` | `fetch` with `credentials: include` | ✓ WIRED | L42-44: `fetch(\`${API}/compass/selected-topics\`, { credentials: "include" })` |
| `essentials/src/lib/compass.js`  | `/compass/politicians`     | `fetch` with `credentials: include` | ✓ WIRED | L58-60: `fetch(\`${API}/compass/politicians\`, { credentials: "include" })` |

### Plan 02 Key Links

| From                                        | To                      | Via                                   | Status     | Details                                                          |
|---------------------------------------------|-------------------------|---------------------------------------|------------|------------------------------------------------------------------|
| `essentials/src/contexts/CompassContext.jsx` | `/auth/me`              | `fetch` on mount                      | ✓ WIRED    | L34-36: `fetch(\`${API}/auth/me\`, { credentials: "include" })` inside `useEffect([])` |
| `essentials/src/contexts/CompassContext.jsx` | `essentials/src/lib/compass.js` | imports 4 functions        | ✓ WIRED    | L1-7: imports `fetchTopics`, `fetchUserAnswers`, `fetchSelectedTopics`, `fetchPoliticiansWithStances` |
| `essentials/src/App.jsx`                    | `CompassContext.jsx`    | wraps Routes with `CompassProvider`   | ✓ WIRED    | L7: import; L12-22: `<CompassProvider>` wraps all routes         |

### Plan 03 Key Links

| From                                       | To                                   | Via                                  | Status     | Details                                                                   |
|--------------------------------------------|--------------------------------------|--------------------------------------|------------|---------------------------------------------------------------------------|
| `essentials/src/pages/Results.jsx`         | `CompassContext.jsx`                 | `useCompass()` for `politicianIdsWithStances` | ✓ WIRED | L19: import; L188: destructuring all 4 needed values |
| `essentials/src/pages/Results.jsx`         | `CompassPreview.jsx`                 | renders `CompassPreview` on badge click | ✓ WIRED | L6: import; L784-794: conditional render when `previewPol` set |
| `essentials/src/components/CompassPreview.jsx` | `@chrisandrewsedu/ev-ui` `RadarChartCore` | renders mini `RadarChartCore` | ✓ WIRED | L3: import; L335: `<RadarChartCore topics={topics} data={polData} .../>` |
| `essentials/src/components/CompassPreview.jsx` | `essentials/src/lib/compass.js` | `fetchPoliticianAnswers` + `buildAnswerMapByShortTitle` | ✓ WIRED | L4: import; L44: `fetchPoliticianAnswers(politicianId)` called on mount; L152: `buildAnswerMapByShortTitle` called |

---

## Requirements Coverage

| Requirement | Source Plans    | Description                                              | Status        | Evidence                                                                                       |
|-------------|-----------------|----------------------------------------------------------|---------------|------------------------------------------------------------------------------------------------|
| DATA-01     | 67-01, 67-02    | Logged-in users' compass answers accessible from Essentials | ✓ SATISFIED | `fetchUserAnswers()` + `fetchSelectedTopics()` exist in compass.js; `CompassContext` calls them on mount and exposes via `useCompass()`; session cookie domain enables sharing |
| DATA-03     | 67-01, 67-02, 67-03 | Politician compass stances fetchable from Essentials    | ✓ SATISFIED | `fetchPoliticiansWithStances()` provides IDs for badge gating; `fetchPoliticianAnswers()` in `CompassPreview` fetches per-politician answers; `RadarChartCore` renders them |

**No orphaned requirements.** REQUIREMENTS.md maps DATA-02 to Phase 68 (Pending) — not in scope for Phase 67.

---

## Anti-Patterns Found

| File                                     | Line | Pattern         | Severity | Impact                                                  |
|------------------------------------------|------|-----------------|----------|---------------------------------------------------------|
| `essentials/src/App.jsx`                 | 2    | Unused import: `BrowserRouter` imported but not rendered in this file | Info | Build succeeds without error; `BrowserRouter` is correctly rendered in `main.jsx`; vestigial import from prior structure — no functional impact |

No blockers or warnings found. The `AuthIndicator` `return null` at L5 is intentional guarded rendering, not a stub.

---

## Planned Deviations (Accepted)

One deviation from the original plan spec was documented and accepted within the plan itself:

**Hover vs click-to-toggle (Plan 03):** The objective described "hover (desktop) or tap (mobile)" but the plan's own Task 2 documented the fallback: "Use click-to-toggle for both desktop and mobile. The user requested hover behavior, but since PoliticianCard is from ev-ui and we cannot easily attach mouse events to its internal compass button, click-to-toggle with dismiss-on-outside-click is the pragmatic approach." This is reflected in the implementation. The human checkpoint in Task 3 confirmed approval.

---

## Human Verification Required

### 1. Cross-domain session cookie sharing

**Test:** Log into CompassV2 at `compass.empowered.vote`. Open Essentials at `essentials.empowered.vote`. Search an address. Observe top-right corner.
**Expected:** A small teal circle with your initials appears in the top-right — proving the `.empowered.vote` domain cookie is shared.
**Why human:** Cookie domain sharing requires a real browser with actual TLS + DNS; can't verify from source code alone.

### 2. Compass badge appears only on politicians with stance data

**Test:** Search an address that returns results. Scan through the politician cards.
**Expected:** Only a small number (~23) of 800+ politicians show a small teal compass button on their card. All other cards have no badge.
**Why human:** Badge visibility depends on the runtime response from `/compass/politicians`; which politicians have stances is live data.

### 3. Compass badge click opens mini radar chart popover

**Test:** Click a compass badge button on a politician card that has one.
**Expected:** A tooltip-style popover appears near the button with a mini radar chart showing the politician's stance polygon. Clicking outside or scrolling dismisses it.
**Why human:** Popover positioning (above/below depending on viewport space), render quality, and dismiss behavior require visual/interaction testing.

### 4. User overlay when logged in with compass data

**Test:** While logged in with compass answers, click a compass badge.
**Expected:** The popover shows two polygons: pink for the politician's stances and blue for the user's answers. A legend "Pink = politician, blue = you" appears.
**Why human:** Depends on runtime `userAnswers` from `/compass/answers` being non-empty.

### 5. CTA mode when user has no compass data

**Test:** While NOT logged in (or logged in with no compass answers), click a compass badge.
**Expected:** The popover shows a greyed-out compass icon and a "Take the Quiz" button linking to `compass.empowered.vote`, not an empty or broken chart.
**Why human:** CTA mode depends on runtime `userAnswers === []`; requires testing without a completed compass.

---

## Gaps Summary

No gaps found. All 11 automatically-verifiable truths passed. The 5 human verification items are behavioral/visual checks that cannot be confirmed from source code inspection; they do not indicate missing or broken code — all supporting logic is correctly implemented and wired.

Build verification:
- `go build` in `EV-Backend`: passes (zero errors)
- `npx vite build` in `essentials`: passes (65 modules, 759ms, zero errors)

Commit chain verified in essentials repo: `a158c93` (67-01) → `28f76a6`, `74d62ba` (67-02) → `050d31e`, `a8f96ee`, `985b4b3` (67-03)
Commit verified in EV-Backend repo: `d55d730` (67-01)

---

_Verified: 2026-03-07_
_Verifier: Claude (gsd-verifier)_
