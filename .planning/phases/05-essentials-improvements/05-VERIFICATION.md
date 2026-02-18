---
phase: 05-essentials-improvements
verified: 2026-02-18T18:00:00Z
status: passed
score: 16/16 must-haves verified
re_verification: false
---

# Phase 5: Essentials Improvements Verification Report

**Phase Goal:** Voters can optionally see candidates alongside officials, the federal section is ordered correctly, and profiles show position dates and building imagery
**Verified:** 2026-02-18
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Federal section order is U.S. Senate > U.S. House > President/VP > Cabinet > Agencies > Executive (Other) | VERIFIED | `classify.js` line 8: FEDERAL_ORDER starts with "U.S. Senate", "U.S. House", then "President / VP" |
| 2 | OfficialOut JSON includes term_start and term_end fields when data exists | VERIFIED | `handlers.go` lines 159-160: TermStart/TermEnd in OfficialOut with omitempty; populated in all 4 construction paths |
| 3 | Existing API consumers continue to work (all new fields use omitempty) | VERIFIED | Both TermStart and TermEnd use `json:"term_start,omitempty"` and `json:"term_end,omitempty"` |
| 4 | PoliticianCard renders a coral badge pill when badge prop is provided | VERIFIED | `PoliticianCard.jsx` line 191: `{badge && <span style={styles.badge}>{badge}</span>}` with `backgroundColor: colors.evCoral` |
| 5 | Card without badge prop renders identically to current version | VERIFIED | Conditional render `{badge && ...}` — when badge is falsy nothing is rendered |
| 6 | ev-ui published as version 0.1.17 | VERIFIED | `ev-ui/package.json` version: "0.1.17" |
| 7 | Term dates appear below politician cards in "Mon YYYY — Mon YYYY" format | VERIFIED | `Results.jsx` lines 34-46: formatTermDate + getTermLine helpers; em-dash separator (U+2014) |
| 8 | Cards with no term_start data show no date line | VERIFIED | `getTermLine()` returns null when term_start absent; conditional render `{!isCandidate && termLine && ...}` |
| 9 | Building image in FilterSidebar changes based on active tier | VERIFIED | `Results.jsx` line 401: `buildingImageSrc={activeBuildingImage}` driven by scrollActiveTier/selectedFilter state |
| 10 | Scroll-spy swaps building image as user scrolls between tier sections (All filter) | VERIFIED | IntersectionObserver at line 367 with `-40% 0px -60% 0px` rootMargin; all three tier divs have data-tier attributes |
| 11 | Bloomington and Los Angeles show curated images; others show fallbacks | VERIFIED | `buildingImages.js`: CURATED for bloomington and "los angeles" keys; FALLBACK for all other localities |
| 12 | GET /essentials/candidates/{zip} returns JSON array of candidate objects | VERIFIED | `routes.go` line 20: `r.Get("/candidates/{zip}", GetCandidatesByZip)`; handler builds CandidateOut slice and calls writeJSON |
| 13 | Each candidate has is_candidate: true, election_date, election_name, district_type | VERIFIED | `CandidateOut` struct has all four fields; IsCandidate hardcoded to true in handler |
| 14 | Only future elections returned (electionDayGte uses today's date) | VERIFIED | `client.go` line 530: `today := time.Now().Format("2006-01-02")` passed as electionDayGte; GraphQL filter at line 480 |
| 15 | Withdrawn and uncertified candidacies are excluded | VERIFIED | `handlers.go` line 3683: `if c.Withdrawn { continue }`; GraphQL query uses `candidacies(includeUncertified: false)` |
| 16 | Candidates shown only when toggle is on; not fetched until then | VERIFIED | `Results.jsx` line 188: `if (!showCandidates) { setCandidateData([]); return; }` — no fetch until toggle true |

**Score:** 16/16 truths verified

---

### Required Artifacts

| Artifact | Provides | Status | Details |
|----------|----------|--------|---------|
| `essentials/src/lib/classify.js` | Reordered FEDERAL_ORDER constant | VERIFIED | Line 8: ["U.S. Senate", "U.S. House", "President / VP", ...] — legislative first |
| `EV-Backend/internal/essentials/handlers.go` | OfficialOut with TermStart/TermEnd + CandidateOut + GetCandidatesByZip | VERIFIED | Lines 159-160 (TermStart/TermEnd), lines 3599-3725 (Candidates section); all wired |
| `ev-ui/src/PoliticianCard.jsx` | PoliticianCard with optional badge prop | VERIFIED | Line 27: badge in props destructuring; line 191: conditional badge span with evCoral style |
| `ev-ui/package.json` | Version 0.1.17 | VERIFIED | "version": "0.1.17" |
| `essentials/src/pages/Results.jsx` | Toggle state, candidate fetch, scroll-spy, term dates, building image wiring | VERIFIED | 529 lines; all features present — showCandidates (167), fetchCandidates (196), IntersectionObserver (367), formatTermDate (34), getBuildingImages (241), data-tier divs (462/480/498) |
| `essentials/src/lib/buildingImages.js` | Building image mapping with curated + fallback | VERIFIED | Exports getBuildingImages(); CURATED for bloomington/"los angeles"; FALLBACK otherwise |
| `essentials/src/lib/api.jsx` | fetchCandidates function | VERIFIED | Lines 141-166: exported fetchCandidates, fetches /essentials/candidates/{zip}, returns [] on error |
| `essentials/package.json` | ev-ui ^0.1.17 dependency | VERIFIED | "@chrisandrewsedu/ev-ui": "^0.1.17" |
| `EV-Backend/internal/essentials/ballotready/client.go` | FetchRacesByZip with racesByZipQuery | VERIFIED | Lines 476-524 (query), lines 529-575 (FetchRacesByZip with pagination) |
| `EV-Backend/internal/essentials/ballotready/types.go` | RaceNode, CandidacyNode, etc. types | VERIFIED | Lines 299-376: all 8 Phase D types defined |
| `EV-Backend/internal/essentials/routes.go` | /candidates/{zip} route registered | VERIFIED | Line 20: `r.Get("/candidates/{zip}", GetCandidatesByZip)` |
| `essentials/public/images/*.svg` | 7 building image SVG placeholders | VERIFIED | All 7 files present: us-capitol.svg, indiana-state-capitol.svg, california-state-capitol.svg, bloomington-city-hall.svg, la-city-hall.svg, city-hall-generic.svg, state-capitol-generic.svg |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `handlers.go` OfficialOut | `essentials.politicians.valid_from/valid_to` | SQL SELECT in fetchOfficialsFromDB, fetchFederalAndStateFromDBFiltered, GetPoliticianByID, normalizedToOfficialOut | WIRED | `p.valid_from` and `p.valid_to` in SQL at lines 2168-2169, 2454-2455, 3131-3132; ValidFrom/ValidTo in row structs at lines 2140-2141, 2429-2430, 3106-3107; populated via off.ValidFrom/ValidTo in normalizedToOfficialOut at lines 2782-2783 |
| `Results.jsx` | `ev-ui FilterSidebar` | buildingImageSrc prop driven by activeBuildingImage derived from scroll-spy or filter state | WIRED | Line 401: `buildingImageSrc={activeBuildingImage}`; activeBuildingImage at lines 358-361 derives from scrollActiveTier (scroll-spy) or selectedFilter |
| `Results.jsx` | OfficialOut API response | pol.term_start and pol.term_end fields in getTermLine | WIRED | Lines 42-46: getTermLine reads pol.term_start and pol.term_end; used in renderPoliticianCard at line 66 |
| `Results.jsx` | `api.jsx fetchCandidates` | Called when showCandidates toggled on | WIRED | Lines 188-204: useEffect fires on showCandidates/activeQuery change; calls fetchCandidates(activeQuery) at line 196 |
| `Results.jsx` | `PoliticianCard badge prop` | badge="Candidate" for is_candidate entries | WIRED | Line 76: `badge={isCandidate ? 'Candidate' : undefined}` in renderPoliticianCard |
| `api.jsx fetchCandidates` | `EV-Backend /essentials/candidates/{zip}` | GET fetch to candidates endpoint | WIRED | Line 151: `fetch(\`${API}/essentials/candidates/${zip}\`)` with credentials: "include" |
| `handlers.go GetCandidatesByZip` | `ballotready.FetchRacesByZip` | Type assertion to BallotReadyProvider then Client().FetchRacesByZip | WIRED | Lines 3664-3671: `brProvider.Client().FetchRacesByZip(r.Context(), zip)` |
| `ballotready/client.go` | BallotReady GraphQL API | races query with location.zip filter and electionDay gte filter | WIRED | Lines 477-524: query uses `location: { zip: $zip }` and `filterBy: { electionDay: { gte: $electionDayGte } }` |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| ESST-01 | 05-04, 05-05 | Candidates appear in Essentials results with opt-in toggle (default: officials only) | SATISFIED | Toggle defaults false (line 167); fetchCandidates only called when showCandidates=true; classifiedCandidates merged into byTier |
| ESST-02 | 05-02, 05-05 | Candidates visually differentiated via badge or label | SATISFIED | PoliticianCard accepts badge prop (ev-ui 0.1.17); Results.jsx passes badge="Candidate" for is_candidate entries |
| ESST-03 | 05-04, 05-05 | Election date shown on candidate cards | SATISFIED | renderPoliticianCard renders election_date in coral (#ff5740) below candidate cards via formatElectionDate; election_name shown with em-dash separator |
| ESST-04 | 05-03 | Building images shown for federal/state/local sections | SATISFIED | buildingImages.js exports getBuildingImages(); 7 SVG placeholders in public/images/; FilterSidebar receives activeBuildingImage prop |
| ESST-05 | 05-01 | Federal section reordered — U.S. Senate and U.S. House shown before executive branch | SATISFIED | FEDERAL_ORDER in classify.js starts with ["U.S. Senate", "U.S. House", "President / VP", ...] |
| ESST-06 | 05-01, 05-03 | Position start date and end date shown on politician profile card | SATISFIED | Backend: TermStart/TermEnd in OfficialOut populated from p.valid_from/p.valid_to in all 4 code paths; Frontend: formatTermDate/getTermLine helpers render "Mon YYYY — Mon YYYY" below each card |

No orphaned requirements found. All 6 ESST requirements were claimed by plans and verified in the codebase.

---

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `essentials/public/images/*.svg` | SVG placeholders instead of real photographs | Info | Intentional MVP decision per plan; real photos can replace by updating buildingImages.js filenames. No functional impact. |

No TODO/FIXME/PLACEHOLDER comments found in any modified files. No empty implementations or stub handlers detected.

---

### Human Verification Required

The following behaviors require human testing because they are visual or interactive:

#### 1. Building image scroll-spy swap

**Test:** On the Results page for any ZIP code with All filter selected, scroll slowly through the Local, State, and Federal sections.
**Expected:** The building image in the FilterSidebar changes from the local government image to the state capitol image to the US Capitol image as each tier section crosses the viewport midpoint.
**Why human:** IntersectionObserver behavior is viewport-dependent and cannot be verified by static code inspection.

#### 2. Candidate badge visibility

**Test:** Enable the "Show Candidates" toggle for a ZIP code with upcoming elections. Inspect candidate cards.
**Expected:** A coral-colored pill badge labeled "CANDIDATE" appears in the top-right corner of each candidate card, visually distinct from official cards.
**Why human:** Visual rendering and color appearance require browser inspection to confirm.

#### 3. Toggle default state and lazy fetch behavior

**Test:** Load the Results page. Observe the network tab.
**Expected:** No request to `/essentials/candidates/{zip}` is made on page load. Only after checking "Show Candidates" does the request fire.
**Why human:** Network timing behavior requires browser devtools to verify.

#### 4. Election date display on candidate cards

**Test:** Enable the toggle when upcoming elections exist. Inspect candidate cards.
**Expected:** Below each candidate card, the election date appears in coral text in "Nov 2026 — U.S. Senate" format.
**Why human:** Requires actual BallotReady data to be returned from the API (live data or mock server).

#### 5. SVG placeholder image rendering

**Test:** Load the Results page for any ZIP code.
**Expected:** The sidebar shows a building image (even as an SVG placeholder). No broken image icon.
**Why human:** SVG files were created but their contents are not verified to render correctly in all browsers.

---

### Build Status

| Project | Build Command | Result |
|---------|---------------|--------|
| EV-Backend (Go) | `go build -o /dev/null .` | PASSED — no errors or warnings |
| essentials (React) | `npx vite build` | PASSED — 64 modules, 646ms, no errors |

---

### Gaps Summary

No gaps found. All must-haves from all five plans are verified at all three levels (exists, substantive, wired). Both codebases compile cleanly.

The only outstanding items are 5 human verification tests that require browser interaction to confirm visual and interactive behaviors — all automated checks pass.

---

_Verified: 2026-02-18_
_Verifier: Claude (gsd-verifier)_
