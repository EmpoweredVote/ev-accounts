---
phase: 59-frontend-profile-sections
verified: 2026-03-03T17:45:00Z
status: gaps_found
score: 3/5 must-haves verified after human testing
re_verification: false
human_verification:
  - test: "Navigate to a federal politician profile (e.g., a US Representative with legislative data) and confirm the LegislativeInlineSummary card renders between the profile card and the children slot — stats row, most-recent-action line, and 'View Full Legislative Record >' link are all visible"
    expected: "Card appears with at least one stat (attendance % or bills advanced), a one-line recent action, and a teal link to /politician/{id}/record"
    why_human: "Requires backend to have legislative data for a test politician; empty-array guard returns null in that case, so the visual only appears for legislators with congressional data"
  - test: "Click 'View Full Legislative Record >' and confirm the /politician/:id/record page loads with Header nav, back button, and three sections: Committees & Leadership, Sponsored Legislation, Voting Record"
    expected: "All three section headers always render regardless of data. Year dropdowns appear on Bills and Votes sections if data exists. Empty state messages appear for sections with no data ('... is not available for this office.')"
    why_human: "Full wiring can only be confirmed end-to-end with real API data; automated checks confirm fetch functions and component rendering but not runtime data flow"
  - test: "Navigate to a local politician profile (school board, sheriff, city council member with no federal legislative data) and confirm the profile renders identically to the pre-Phase-59 experience — no LegislativeInlineSummary card, no broken UI"
    expected: "Profile looks exactly as before Phase 59. No empty card, no error. The guard in LegislativeInlineSummary returns null when recent_bills and recent_votes are both empty."
    why_human: "Requires real API call to /legislative-summary returning empty arrays; the guard logic is verified in code but runtime behavior with actual data must be confirmed"
  - test: "On the full legislative record page, use the year dropdown on Bills or Votes sections — select a specific year, confirm the list filters client-side without a network request"
    expected: "Displayed items change immediately with no spinner or network call. 'Show all N items' link reflects count within the selected year. Selecting 'All years' restores the full list."
    why_human: "Client-side filtering behavior and year dropdown interaction with show-all can only be confirmed interactively"
---

# Phase 59: Frontend Profile Sections — Verification Report

**Phase Goal:** Build frontend profile sections displaying legislative data from Phase B endpoints — endorsements, stances, elections, and contact info rendered in ev-ui components consumed by essentials app

**Note on goal phrasing:** The actual implemented scope (as defined in the PLANs and confirmed in the RESEARCH/CONTEXT files) covers committees/leadership, sponsored legislation, and voting records — which aligns with the ROADMAP success criteria and requirements UI-01 through UI-05. The goal statement references "endorsements, stances, elections" which are Phase B data from phases 55-58; the frontend display built in Phase 59 covers the legislative record specifically (committees, bills, votes), not stances/endorsements/elections from BallotReady candidacy data. This scope matches what was planned and delivered.

**Verified:** 2026-03-03T16:26:09Z
**Status:** human_needed (all automated checks pass; 4 items need human confirmation)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (from ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | Federal profile shows Committees & Leadership section with role badges and leadership positions | VERIFIED | `LegislativeRecord.jsx` CommitteesSection renders with `getRoleBadge()` color map (Chair=evCoral, Vice Chair=evTealLight, Ranking Member=evTeal, Ex Officio=textMuted, Member=borderMedium) and leadership badges in evCoral |
| SC-2 | Federal profile shows Voting Record section with bill title, position (Yea/Nay/Not Voting), and outcome | VERIFIED | `VotingSection` in `LegislativeRecord.jsx` renders `vote.bill_title || vote.vote_question`, position badge via `getPositionBadge()`, and `vote.result` with color coding |
| SC-3 | Federal profile shows Sponsored Legislation defaulting to bills that advanced past introduction | VERIFIED | Backend `/essentials/politician/{id}/bills` filters `status_label != 'Introduced'` by default (handlers.go:3154); `?all=true` param overrides. Frontend `LegislationSection` renders number, title, status badge, introduced_at, Sponsored/Cosponsored label |
| SC-4 | Local politician profile shows empty states or hidden sections — no broken placeholders | VERIFIED (code path) | `LegislativeInlineSummary` returns `null` when `recent_bills.length === 0 && recent_votes.length === 0` (line 76). `LegislativeRecord` renders factual empty messages: "Committee information is not available for this office.", "Sponsored legislation data is not available for this office.", "Voting records are not available for this office." — HUMAN CONFIRMATION needed to verify runtime behavior |
| SC-5 | Session filter lets users toggle between current/previous session data without page reload | VERIFIED (as year dropdown — see note) | Year dropdown on Bills (by `introduced_at`) and Votes (by `vote_date`) sections filters client-side. CONTEXT.md documents the design decision: "No session toggle — 'session' is insider language most citizens won't understand." Year dropdown was the approved replacement. HUMAN CONFIRMATION needed for UI behavior |

**Score:** 5/5 truths verified in code (4 require human confirmation to observe runtime behavior)

**Note on SC-5:** The ROADMAP uses the phrase "Previous Session" but the CONTEXT.md records an explicit design decision to replace the session toggle with a year dropdown, citing UX rationale. The RESEARCH.md maps UI-05 to "Year options derived from `introduced_at` (bills) and `vote_date` (votes)." The implementation satisfies the intent of UI-05 (data filtering) and was the approved approach. This is a scope refinement, not a deviation.

---

## Required Artifacts

### Plan 01 (ev-ui library)

| Artifact | Status | Details |
|----------|--------|---------|
| `ev-ui/src/LegislativeInlineSummary.jsx` | VERIFIED | 197 lines. Guards on empty data (returns null). Derives attendance % and bills-advanced stats. Renders stats row, most-recent-action line, topic tags placeholder div, "View Full Legislative Record >" link. Zero `className=` — all inline styles with tokens.js. |
| `ev-ui/src/LegislativeRecord.jsx` | VERIFIED | 603 lines. Three sections always render (CommitteesSection, LegislationSection, VotingSection). Year dropdowns on bills/votes with `extractYear()` using slice(0,4). Default 25 items, ShowAllLink expands. EmptyState messages present. Zero `className=` — all inline styles. |
| `ev-ui/src/PoliticianProfile.jsx` | VERIFIED | Imports `LegislativeInlineSummary` (line 6). Accepts `legislativeSummary` and `politicianId` props (lines 119-121). Renders `<LegislativeInlineSummary>` between closing topCard div and children slot (lines 491-494). Existing `CommitteeTable` in infoCol unchanged. |
| `ev-ui/src/index.js` | VERIFIED | Exports `LegislativeInlineSummary` (line 12) and `LegislativeRecord` (line 13) as named exports. |
| `ev-ui/package.json` | VERIFIED | Version is `0.1.37`. Build artifacts exist at `ev-ui/dist/index.js` and `ev-ui/dist/index.mjs`. |

### Plan 02 (essentials app wiring)

| Artifact | Status | Details |
|----------|--------|---------|
| `essentials/src/lib/api.jsx` | VERIFIED | All 5 legislative fetch functions present (lines 172-240): `fetchLegislativeSummary`, `fetchLegislativeCommittees`, `fetchLegislativeLeadership`, `fetchLegislativeBills`, `fetchLegislativeVotes`. All return empty arrays/objects on error — never throw. |
| `essentials/src/pages/LegislativeRecord.jsx` | VERIFIED | 103 lines. Imports `Header, LegislativeRecord` from `@chrisandrewsedu/ev-ui`. Uses `Promise.all` to fetch all 5 endpoints in parallel. Passes `loading` boolean. Back button navigates to `/politician/${id}`. |
| `essentials/src/pages/Profile.jsx` | VERIFIED | Imports `fetchLegislativeSummary` (line 3). State `legislativeSummary` initialized to null. `Promise.all([fetchPolitician(id), fetchLegislativeSummary(id)])` in useEffect (lines 44-46). Passes `legislativeSummary={legislativeSummary}` and `politicianId={id}` to `PoliticianProfile` (lines 83-84). |
| `essentials/src/App.jsx` | VERIFIED | Imports `LegislativeRecord` from `./pages/LegislativeRecord` (line 6). Route `/politician/:id/record` registered as flat sibling route (line 15). |
| `essentials/package.json` | VERIFIED | `@chrisandrewsedu/ev-ui: "^0.1.37"`. Installed at `essentials/node_modules/@chrisandrewsedu/ev-ui` at version 0.1.37. |

---

## Key Link Verification

### Plan 01 Key Links

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `PoliticianProfile.jsx` | `LegislativeInlineSummary.jsx` | `import LegislativeInlineSummary from './LegislativeInlineSummary.jsx'` + render with props | WIRED | Import on line 6, render on lines 491-494 with `summary={legislativeSummary}` and `politicianId={politicianId}` |
| `index.js` | `LegislativeInlineSummary.jsx`, `LegislativeRecord.jsx` | Named exports | WIRED | Lines 12-13: `export { default as LegislativeInlineSummary }` and `export { default as LegislativeRecord }` |

### Plan 02 Key Links

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Profile.jsx` | `api.jsx fetchLegislativeSummary` | Import + Promise.all call | WIRED | `import { fetchPolitician, fetchLegislativeSummary } from '../lib/api'` (line 3); called in Promise.all (line 46) |
| `LegislativeRecord.jsx page` | `api.jsx` (4 functions) | Import + Promise.all | WIRED | All 4 functions imported (lines 4-9); called via `Promise.all` (lines 47-53) |
| `App.jsx` | `LegislativeRecord.jsx page` | React Router Route element | WIRED | `import LegislativeRecord from "./pages/LegislativeRecord"` (line 6); `<Route path="/politician/:id/record" element={<LegislativeRecord />} />` (line 15) |
| `LegislativeRecord.jsx page` | `ev-ui LegislativeRecord component` | Import from `@chrisandrewsedu/ev-ui` | WIRED | `import { Header, LegislativeRecord } from '@chrisandrewsedu/ev-ui'` (line 10); rendered with all data props (lines 89-96) |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| UI-01 | 59-01, 59-02 | Committees & Leadership section with current committee assignments, roles, and leadership positions | SATISFIED | `CommitteesSection` renders role badges (Chair/Vice Chair/Ranking Member/Ex Officio/Member with proper token colors). Leadership roles shown as prominent evCoral badges. Empty state: "Committee information is not available for this office." |
| UI-02 | 59-01, 59-02 | Voting Record section with bill title/summary, politician's position, and overall outcome | SATISFIED | `VotingSection` renders `bill_title || vote_question`, position badge via `getPositionBadge()` (Yea=green, Nay=red, Not Voting=muted, Abstain=yellow, Absent=muted), and `vote.result` text. Source link when `bill_url` present. |
| UI-03 | 59-01, 59-02 | Sponsored Legislation with bill number, title, status, and introduction date | SATISFIED | `LegislationSection` renders `bill.number` (bold), `bill.title`, status badge via `getStatusBadge()`, `formatDate(bill.introduced_at)`, and Sponsored/Cosponsored label. |
| UI-04 | 59-01, 59-02 | All legislative sections gracefully show empty states when data unavailable | SATISFIED | `LegislativeInlineSummary` returns null for empty arrays. `LegislativeRecord` always renders section headers with factual EmptyState messages for empty data. No broken placeholders. |
| UI-05 | 59-01, 59-02 | Session filter lets users toggle between current and previous session data | SATISFIED (as year dropdown per CONTEXT.md design decision) | Year dropdown derived from actual data dates (slice(0,4) pattern). Filters client-side via `useState` without additional API calls. Default "All years" with items sorted most-recent-first. CONTEXT.md documents: "No session toggle — 'session' is insider language most citizens won't understand." |

All 5 requirements satisfied. No orphaned requirements found.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `ev-ui/src/LegislativeInlineSummary.jsx` | 178-179 | `{/* Topic tags placeholder — deferred */}` — empty `<div>` with comment | INFO | Intentional deferred feature. The empty div renders nothing visible. The PLAN explicitly calls this out: "Topic tag pills slot: render an empty div with a comment... This is a deferred feature; the visual slot should exist but show nothing." Not a blocker. |
| `ev-ui/src/PoliticianProfile.jsx` | 237, 333, 371 | "placeholder" references | INFO | These refer to the initials-fallback avatar placeholder (shown when no profile image is available). Not a stub — fully implemented feature. |

No blocker anti-patterns found. No TODO/FIXME/HACK/XXX comments in any modified file. No `return {}` or `return []` stubs.

---

## Human Verification Required

### 1. Federal Profile — Legislative Inline Summary Renders

**Test:** Open a US Representative's profile page in the essentials app (a politician with congressional legislative data — committees, bills, votes)
**Expected:** A card appears between the profile card and the children area showing: at least one stat (e.g., "94% attendance" or "3 bills advanced"), one line of most-recent-action text with ellipsis overflow, an empty topic tags div (invisible), and a "View Full Legislative Record >" link in teal
**Why human:** Requires backend data to be present for the tested politician. The empty-array guard returns null for legislators with no congressional data; only a live call can confirm the visual renders for populated data.

### 2. Full Legislative Record Page — All Sections Render

**Test:** Click "View Full Legislative Record >" from a federal politician's profile to reach `/politician/:id/record`
**Expected:** Page loads with Header nav, a back button navigating to `/politician/:id`, and three section headers (Committees & Leadership, Sponsored Legislation, Voting Record) always visible. Sections with data show rows. Sections without data show the factual empty message.
**Why human:** Full routing and component rendering requires the browser; automated checks confirm code path but not runtime DOM output.

### 3. Local Politician Profile — No Inline Summary

**Test:** Open a school board member's, sheriff's, or city council member's profile — a politician with no federal legislative data
**Expected:** Profile renders exactly as it did before Phase 59. No legislative card. No broken UI. No empty card frame.
**Why human:** Requires /legislative-summary endpoint to return empty arrays for that politician. The null-return guard is verified in code but runtime behavior with actual data must be observed.

### 4. Year Dropdown — Client-Side Filtering

**Test:** On the `/politician/:id/record` page with a federal politician who has multi-year bill/vote data, use the year dropdown on the Bills or Votes section
**Expected:** Selecting a year immediately filters the displayed list to that year's items without a network request. The "Show all N items" count updates to reflect the year-filtered count. Selecting "All years" restores the full list. Interaction with "Show all" should expand within the selected year filter.
**Why human:** Interactive state behavior can only be confirmed in a browser; no static analysis can verify that useState triggers re-render correctly without running the app.

---

## Gaps Found (Human Testing — 2026-03-03)

### Gap 1: Inline summary renders as separate card, not inline
- **status: failed**
- **severity: high**
- **requirement: UI-04**
- **description:** `LegislativeInlineSummary` is rendered OUTSIDE the topCard div in `PoliticianProfile.jsx` (line 491, after topCard closes at line 488). It appears as a visually separate card with its own box-shadow below the profile card, rather than being embedded inside the profile card itself. User expectation: the legislative summary should be part of the profile card, not a separate element.
- **root_cause:** Component placement in PoliticianProfile.jsx — rendered after `</div>` for topCard instead of inside it.
- **fix:** Move `<LegislativeInlineSummary>` inside the topCard div, after the info column content, and remove its standalone card styling (box-shadow, separate background). Make it a section within the profile card.

### Gap 2: Stats wording lacks context for general users
- **status: failed**
- **severity: medium**
- **requirement: UI-04**
- **description:** The inline summary shows "100% attendance" and "5 bills advanced" but general voters won't understand what these mean without context. "Attendance" of what? What does "bills advanced" mean in legislative terms? The data is valuable but needs rephrasing with more descriptive labels.
- **root_cause:** `LegislativeInlineSummary.jsx` uses terse labels (lines 86-89) without explanatory context.
- **fix:** Rephrase stats to be more descriptive. E.g., "Voted in 100% of roll calls" instead of "100% attendance". "Authored 5 bills that advanced past introduction" instead of "5 bills advanced". Consider adding a brief subtitle or tooltip.

### Gap 3: Navigation broken — back button loops to legislative record
- **status: failed**
- **severity: high**
- **requirement: UI-04**
- **description:** Profile page uses `navigate(-1)` for back navigation (`Profile.jsx` line 77). When user goes Profile → Legislative Record → back to Profile, then clicks back again, `navigate(-1)` takes them to the Legislative Record instead of the Dashboard. Browser history stack creates a loop.
- **root_cause:** `onBack={() => navigate(-1)}` relies on browser history order, which breaks after visiting the legislative record sub-page.
- **fix:** Change Profile's back button to navigate to a deterministic route (e.g., `/` or the dashboard) instead of using `navigate(-1)`. Similarly check the `LegislativeInlineSummary` link uses `<Link>` or `navigate()` to `/politician/:id/record` rather than a raw `<a href>` to avoid full page reloads that further break history.

### Gap 4: Federal officials show no legislative data
- **status: failed**
- **severity: high**
- **requirement: UI-01, UI-02, UI-03**
- **description:** No federal officials (Congress members) show any legislative information — neither inline summary nor in the full record. The endpoints exist in the backend (`/politician/{id}/legislative-summary`, `/bills`, `/votes`, `/committees`) but either return empty data for federal officials or there's a data population issue. State-level senator (Shelli Yoder) DOES have data, so the pipeline works for some officials.
- **root_cause:** Likely a data issue — federal official bill/vote/committee data may not be populated in the database, or the BallotReady data pipeline doesn't fetch legislative records for federal-level positions. Needs backend investigation.
- **fix:** Investigate backend: check if federal politicians have any rows in the bills, votes, or committees tables. If not, determine whether the BallotReady import pipeline captures legislative data for federal officials or if a different data source is needed (e.g., ProPublica Congress API). This may be a data pipeline gap rather than a frontend bug.

### Gap 5: Local politicians show no committee data
- **status: failed**
- **severity: medium**
- **requirement: UI-01**
- **description:** Local politicians (city council, school board) should at least show committee assignments, but nothing appears. The existing `CommitteeTable` inside `PoliticianProfile` renders from `pol.committees`, and the legislative record page fetches from `/politician/{id}/committees`. Both may be returning empty for local officials.
- **root_cause:** Similar to Gap 4 — likely a data population issue. The BallotReady data may not include committee assignments for local-level positions. Frontend code is correct (CommitteeTable still renders when data exists), but no data is returned from the API.
- **fix:** Investigate backend: check if local politicians have committee data in the database. If the BallotReady pipeline doesn't capture local committee data, this should be documented as a known limitation. The frontend empty-state handling is correct.

---

## Gap Closure Summary

**Gaps requiring frontend fixes (1, 2, 3):** Inline positioning, stat labels, and navigation are straightforward code changes in ev-ui and essentials.

**Gaps requiring investigation (4, 5):** Federal and local data absence may be data pipeline issues rather than frontend bugs. Need backend investigation before determining if frontend changes are needed.

---

_Verified: 2026-03-03T16:26:09Z (automated)_
_Human tested: 2026-03-03T17:45:00Z_
_Verifier: Claude (gsd-verifier) + human_
