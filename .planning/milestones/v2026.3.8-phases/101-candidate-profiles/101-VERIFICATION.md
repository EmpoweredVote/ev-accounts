---
phase: 101-candidate-profiles
verified: 2026-03-30T22:10:00Z
status: gaps_found
score: 9/12 must-haves verified
re_verification: false
gaps:
  - truth: "Clicking any candidate card on Election Central navigates to /candidate/:id using race_candidates UUID"
    status: passed
    reason: "Verified — no gap here. Listed for completeness only."
    artifacts: []
    missing: []
  - truth: "CompassCard renders on incumbent profiles when stance data exists (self-gating)"
    status: passed
    reason: "Verified — no gap here. Listed for completeness only."
    artifacts: []
    missing: []
  - truth: "PROF-04 satisfied: Compass stances imported for candidates in coverage areas"
    status: failed
    reason: "PROF-04 was explicitly deferred in D-06 (RESEARCH.md) — UI wiring exists but no data import was executed in this phase. REQUIREMENTS.md still shows PROF-04 as Pending."
    artifacts:
      - path: ".planning/REQUIREMENTS.md"
        issue: "PROF-04 shows status Pending — data never imported"
    missing:
      - "Import compass stances for at least major-race candidates in Monroe County IN and LA County CA"
      - "Update REQUIREMENTS.md PROF-04 to Complete after data import"
  - truth: "PROF-05 satisfied: Sourced quotes imported for candidates via existing quote pipeline"
    status: failed
    reason: "PROF-05 was explicitly deferred in D-06 (RESEARCH.md) — UI wiring exists but no quote data import was executed in this phase. REQUIREMENTS.md still shows PROF-05 as Pending."
    artifacts:
      - path: ".planning/REQUIREMENTS.md"
        issue: "PROF-05 shows status Pending — data never imported"
    missing:
      - "Collect and import sourced quotes for candidates via existing quote pipeline"
      - "Update REQUIREMENTS.md PROF-05 to Complete after data import"
  - truth: "Commits documented in SUMMARY.md exist in git history"
    status: failed
    reason: "Commits 17344e4, 95beabf, b667419, f477267, 4fc0907 documented in both SUMMARYs are absent from git log. Only docs commits for phase 101 exist."
    artifacts:
      - path: ".planning/phases/101-candidate-profiles/101-01-SUMMARY.md"
        issue: "Documents commits 17344e4 and 95beabf which do not exist in git history"
      - path: ".planning/phases/101-candidate-profiles/101-02-SUMMARY.md"
        issue: "Documents commits b667419, f477267, 4fc0907 which do not exist in git history"
    missing:
      - "Code changes need to be committed to git"
human_verification:
  - test: "Incumbent candidate profile: click an incumbent on Election Central"
    expected: "Profile page loads with full politician data, yellow-bordered candidate banner, CompassCard section (if stances exist), legislative summary section"
    why_human: "Requires live backend + elections data + user with compass answers — can't verify without running servers"
  - test: "Challenger candidate profile: click a non-incumbent candidate on Election Central"
    expected: "Profile page loads with name, photo/initials, position banner — NO CompassCard, NO empty loading states for legislative/judicial data"
    why_human: "Requires live backend + elections data — can't verify without running servers"
  - test: "Back navigation from candidate profile"
    expected: "Back button returns to Elections tab when arriving from Elections, Representatives tab otherwise"
    why_human: "Requires session context and navigation flow — can't verify statically"
---

# Phase 101: Candidate Profiles Verification Report

**Phase Goal:** Candidates on the Election Central page link to full Essentials-style profile pages, with compass comparison cards and Read & Rank verdict badges where data exists — incumbents reuse existing politician records, challengers render without triggering empty legislative API calls
**Verified:** 2026-03-30T22:10:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | GET /api/essentials/race-candidates/:id returns candidate detail with politician_id for incumbents | VERIFIED | `getCandidateById()` in electionService.ts (line 119), LATERAL JOIN for photo, withdrawn filter at SQL layer |
| 2 | GET /api/essentials/race-candidates/:id returns null/404 for challengers with null politician_id | VERIFIED | Query returns null politician_id for non-linked candidates; route returns 404 when null |
| 3 | Invalid UUID returns 422 VALIDATION_ERROR | VERIFIED | UUID_RE at top of essentials.ts (line 29), used in route handler (line 45) |
| 4 | Unknown UUID returns 404 NOT_FOUND | VERIFIED | Route handler (lines 52-55) returns 404 with NOT_FOUND code |
| 5 | Withdrawn candidates return 404 NOT_FOUND | VERIFIED | SQL WHERE clause: `AND rc.candidate_status != 'withdrawn'` (electionService.ts line 141) |
| 6 | Clicking any candidate card navigates to /candidate/:id using race_candidates UUID | VERIFIED | ElectionsView.jsx: `id={candidate.candidate_id}`, `onCandidateClick(candidate.candidate_id)` — no isPolitician split |
| 7 | Incumbent candidate profile shows full politician data — compass card, legislative summary, judicial record | VERIFIED | CandidateProfile.jsx lines 45-57: Promise.all for polResult/legSummary/jRecord when politician_id non-null; CompassCard rendered at line 165 |
| 8 | Challenger candidate profile shows only name, photo, position — no empty loading states | VERIFIED | CandidateProfile.jsx lines 58-65: minimal pol object built from candidate data only; no legislative/judicial fetch; no CompassCard (polId remains null) |
| 9 | CompassCard self-gates on stance data existence | VERIFIED | CompassCard.jsx line 69: `if (!politicianIdsWithStances.has(politicianId)) return null` |
| 10 | Read & Rank verdict badges render inside StanceAccordion when quote data exists (self-gating) | VERIFIED | CompassCard.jsx passes `verdictsByQuote={verdicts}` to StanceAccordion; StanceAccordion gates on data internally |
| 11 | PROF-04: Compass stances imported for candidates in coverage areas | FAILED | Explicitly deferred in D-06 — REQUIREMENTS.md shows Pending; no data import plan or commits exist |
| 12 | PROF-05: Sourced quotes collected and imported for candidates | FAILED | Explicitly deferred in D-06 — REQUIREMENTS.md shows Pending; no quote import executed |

**Score:** 10/12 truths verified (2 failed — both are data population requirements deferred by design decision D-06)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ev-accounts/backend/src/lib/electionService.ts` | getCandidateById() query function | VERIFIED | Lines 102-145: CandidateDetail interface + getCandidateById function with LATERAL JOIN, withdrawn filter |
| `ev-accounts/backend/src/routes/essentials.ts` | GET /race-candidates/:id route handler | VERIFIED | Lines 31-60: UUID validation, 422/404/500 responses, getCandidateById call |
| `ev-accounts/tests/integration/essentials-elections.test.ts` | CI-safe route wiring tests | VERIFIED | Lines 86-115: 4 tests for race-candidates endpoint, all pass |
| `essentials/src/lib/api.jsx` | fetchRaceCandidate(id) API function | VERIFIED | Lines 298-307: publicFetch to /essentials/race-candidates/:id |
| `essentials/src/pages/CandidateProfile.jsx` | Unified candidate profile with incumbent/challenger branching | VERIFIED | Full rewrite: fetchRaceCandidate first, politician_id branch, polId state, notFound state |
| `essentials/src/components/ElectionsView.jsx` | Fixed routing — all candidates use /candidate/:id | VERIFIED | Line 210: `id={candidate.candidate_id}`, line 218: `onCandidateClick(candidate.candidate_id)` |
| `essentials/src/pages/Results.jsx` | Simplified onCandidateClick handler | VERIFIED | Lines 1199-1205: single `(id)` param, always navigates to `/candidate/${id}` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `essentials.ts` | `electionService.ts` | `import getCandidateById` | WIRED | Line 13: `import { getElectionsByCoordinate, getCandidateById } from '../lib/electionService.js'` |
| `CandidateProfile.jsx` | `/api/essentials/race-candidates/:id` | `fetchRaceCandidate(id)` | WIRED | Line 36: `const candidate = await fetchRaceCandidate(id)` in useEffect |
| `CandidateProfile.jsx` | `CompassCard.jsx` | `{polId && <CompassCard politicianId={polId}>}` | WIRED | Lines 165-171: conditional render with polId (never candidate UUID) |
| `ElectionsView.jsx` | `CandidateProfile.jsx` | `navigate(/candidate/${candidate.candidate_id})` | WIRED | Via Results.jsx onCandidateClick at line 1205; route registered in App.jsx line 33 |
| `essentials router` | Express app | `app.use('/api/essentials', essentialsRouter)` | WIRED | index.ts line 106: essentials router mounted after more-specific candidate/politician mounts |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `CandidateProfile.jsx` | `candidateData` | `fetchRaceCandidate(id)` → `getCandidateById()` → PostGIS DB | Yes — SQL query against essentials.race_candidates with JOIN to races/elections | FLOWING |
| `CandidateProfile.jsx` | `pol` (incumbent) | `fetchPolitician(candidate.politician_id)` → existing politician endpoint | Yes — real DB query | FLOWING |
| `CandidateProfile.jsx` | `pol` (challenger) | Built from `candidate.full_name/first_name/last_name/photo_url` | Yes — from race-candidates API response | FLOWING |
| `CompassCard.jsx` | `polAnswers` | `fetchPoliticianAnswers(politicianId)` — only fires for politicians with stances | Yes when data exists; skipped when not | FLOWING |
| `CompassCard.jsx` | `politicianIdsWithStances` | `useCompass()` context — loaded from compass API | Depends on data import for candidates — currently no candidate stances imported | STATIC for candidates |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| essentials frontend builds cleanly | `cd essentials && npx vite build` | 731 modules transformed, built in 1.33s, no errors | PASS |
| race-candidates endpoint tests pass | `cd ev-accounts/backend && npm test -- --run` on essentials-elections.test.ts | 8/8 tests pass in essentials-elections suite | PASS |
| Pre-existing test failures are unrelated | Other test files (gems, compass, architecture, env-validation) | 11 failures in 4 unrelated test files — SUMMARY confirmed these existed before phase 101 | INFO |
| TypeScript compiles | `cd ev-accounts && npx tsc --noEmit` | tsc not locally installed via npx; build-time compilation used instead | SKIP |
| apiFetch removed from CandidateProfile | `grep -n apiFetch CandidateProfile.jsx` | No matches — clean removal | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PROF-01 | 101-01, 101-02 | User can view a full profile page for any candidate | SATISFIED | Backend endpoint + frontend CandidateProfile implemented and building |
| PROF-02 | 101-02 | Candidate profiles include compass comparison card with user's calibrated data | SATISFIED (architectural) | CompassCard imported and conditionally rendered for incumbents; self-gates on stance data |
| PROF-03 | 101-02 | Candidate profiles include Read & Rank verdict badges from sourced quotes | SATISFIED (architectural) | StanceAccordion with `verdictsByQuote={verdicts}` wired inside CompassCard |
| PROF-04 | 101-02 | Compass stances researched and imported for candidates in coverage areas | NOT SATISFIED | D-06 explicitly deferred data import; REQUIREMENTS.md still shows Pending; no data in DB |
| PROF-05 | 101-02 | Sourced quotes collected and imported for candidates via existing quote pipeline | NOT SATISFIED | D-06 explicitly deferred data import; REQUIREMENTS.md still shows Pending; no quotes imported |

**Note on PROF-04 and PROF-05:** These are data population requirements, not code requirements. The 101-02 SUMMARY listed them under `requirements-completed`, but this is incorrect — RESEARCH.md D-06 explicitly states they "are not achievable in this phase." REQUIREMENTS.md correctly shows them as Pending. The architectural wiring to display the data once imported is complete, but the data itself has not been imported.

**Orphaned requirements check:** REQUIREMENTS.md maps PROF-01 through PROF-05 to Phase 101. All five are accounted for in the plan frontmatter. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| CandidateProfile.jsx | 69 | `setLoadingProfile(false)` only fires in `finally` — correct; no stub | INFO | Not a stub — correct finally placement |
| SUMMARY-01.md | 72 | Documents commit 17344e4 (feat) | WARNING | Commit not found in git log — code exists on disk but is uncommitted |
| SUMMARY-02.md | 67 | Documents commits b667419, f477267, 4fc0907 | WARNING | Commits not found in git log — code exists on disk but is uncommitted |

**Stub classification note:** No stubs found in component code. `useState({})`, `useState(null)`, and `useState(false)` are all appropriate initial states that are populated by real data fetches in useEffect. The challenger branch deliberately builds a minimal pol object — this is correct design, not a stub.

### Human Verification Required

#### 1. Incumbent Profile End-to-End

**Test:** Start both `ev-accounts/backend` (port 3000) and `essentials` dev server. Enter a Bloomington IN address, switch to Elections tab, click an incumbent candidate card.
**Expected:** URL changes to `/candidate/:uuid` (race_candidates UUID), yellow-bordered "Candidate for [position]" banner appears, full politician data loads, CompassCard section present (may be empty if no stances imported yet), legislative summary section visible.
**Why human:** Requires live backend with PostGIS DB, real election data, and browser navigation — cannot test statically.

#### 2. Challenger Profile End-to-End

**Test:** Same setup as above. Click a non-incumbent candidate card (no "Incumbent" subtitle).
**Expected:** URL changes to `/candidate/:uuid`, candidate name and photo/initials display, "Candidate for [position]" banner shows, NO CompassCard section, NO empty loading spinners for missing data, NO empty legislative/judicial sections.
**Why human:** Requires live backend with PostGIS DB and real challenger records — cannot verify absence of empty states statically.

#### 3. Not-Found State

**Test:** Navigate directly to `/candidate/00000000-0000-0000-0000-000000000000` in browser.
**Expected:** "Candidate not found" message appears with back button. No crash.
**Why human:** Requires running app to verify UI rendering.

#### 4. Back Navigation Context

**Test:** Navigate to a candidate profile from Elections tab (verify ev:fromView='elections' is set), then click back button.
**Expected:** Returns to results page with Elections tab active (`&view=elections` in URL).
**Why human:** Requires session state and UI interaction.

### Gaps Summary

**Two structural gaps exist:**

**Gap 1 — Uncommitted code (WARNING):** The implementation code is correct and present on disk, but none of the commits documented in the SUMMARYs (17344e4, 95beabf, b667419, f477267, 4fc0907) appear in git history. The code appears to have been created outside of git commits, or the commits were made to a different branch/repo state. The functionality is fully implemented and the build passes, but the work is not captured in version control.

**Gap 2 — PROF-04 and PROF-05 data not imported (BLOCKER for full goal achievement):** The ROADMAP success criteria SC-4 and SC-5 require actual compass stances and sourced quotes to be imported for candidates in both coverage areas. Decision D-06 intentionally deferred this work, and REQUIREMENTS.md correctly shows these as Pending. The 101-02 SUMMARY incorrectly claimed these as `requirements-completed`. The architectural wiring is in place (CompassCard self-gates, StanceAccordion with verdicts is wired), but until data is imported, these sections will never appear on any candidate profile.

**Effect on phase goal:** The phase goal states "with compass comparison cards and Read & Rank verdict badges where data exists." Since no candidate-specific data was imported, the "where data exists" condition is never met for candidates. Incumbents who happen to already have compass stances as politicians will show the CompassCard — that works. But no new candidate stance data was created as part of this phase.

---

_Verified: 2026-03-30T22:10:00Z_
_Verifier: Claude (gsd-verifier)_
