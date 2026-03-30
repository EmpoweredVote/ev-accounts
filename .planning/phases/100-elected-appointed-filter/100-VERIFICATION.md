---
phase: 100-elected-appointed-filter
verified: 2026-03-30T18:01:00Z
status: passed
score: 8/8 must-haves verified
re_verification: null
gaps: []
human_verification:
  - test: "Elected filter excludes appointed officials and includes retention judges in browser"
    expected: "Clicking Elected shows only officials where resolved is_appointed=false OR faces_retention_vote=true; Indiana appellate judges remain visible"
    why_human: "Runtime filter behavior against live DB data cannot be verified programmatically without a running server+DB"
  - test: "Appointed filter shows retention judges in browser"
    expected: "Indiana appellate judges with faces_retention_vote=true appear under Appointed filter"
    why_human: "Requires live DB data with retention-vote offices; cannot verify without running server"
  - test: "Mobile segmented control renders and is tappable at 44px height"
    expected: "Segmented control appears below tier pills at mobile breakpoint with minimum 44px touch targets"
    why_human: "Visual/tactile breakpoint behavior requires browser"
  - test: "Back-navigation restores filter state"
    expected: "Navigating to a profile and pressing back restores the appointedFilter value from sessionStorage"
    why_human: "Navigation flow and sessionStorage restore requires browser interaction"
---

# Phase 100: Elected/Appointed Filter Verification Report

**Phase Goal:** Users can filter the main representatives page by Elected, Appointed, or All, with retention judges appearing correctly under both the Elected and Appointed views — backed by verified is_appointed data
**Verified:** 2026-03-30T18:01:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | API response for address search includes `is_appointed` field on every politician | VERIFIED | Field in `PoliticianFlatRecord` interface (line 83), 4 SQL SELECT locations, 3 row mappings in essentialsService.ts |
| 2 | API response for address search includes `faces_retention_vote` field on every politician | VERIFIED | Field in `PoliticianFlatRecord` interface (line 84), 4 SQL SELECT locations (paired with is_appointed), 3 row mappings |
| 3 | `is_appointed` reflects the politician-level override, not just the office-level default | VERIFIED | `resolveIsAppointed` in Results.jsx (line 454): only `is_appointed === true` triggers override, otherwise falls back to `!is_elected` |
| 4 | User sees a segmented control with All / Elected / Appointed options | VERIFIED | SegmentedControl.jsx exists with 3 options wired in both LocalFilterSidebar and Results.jsx mobile bar |
| 5 | Selecting Elected shows only officials where resolved is_appointed=false OR faces_retention_vote=true | VERIFIED | `matchesAppointedFilter` line 465-466: `return !resolved \|\| pol.faces_retention_vote === true` |
| 6 | Selecting Appointed shows only officials where resolved is_appointed=true | VERIFIED | `matchesAppointedFilter` line 468-470: `return resolved === true` |
| 7 | Filter defaults to All — existing experience unchanged | VERIFIED | `useState(cachedResult?.appointedFilter \|\| 'All')` at line 306-308; appointedFilteredByTier short-circuits to `byTier` when filter === 'All' |
| 8 | Both tier filter and type filter work simultaneously | VERIFIED | `appointedFilteredByTier` useMemo inserted between `byTier` and `displayedPoliticians`; both are composed in sequence |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ev-accounts/backend/src/lib/essentialsService.ts` | `is_appointed` and `faces_retention_vote` in PoliticianFlatRecord and all SQL queries | VERIFIED | Interface lines 83-84; 4 SQL locations (lines 391, 514, 569, 1361); 3 row mappings (lines 453-454, 635-636, 1459-1460) |
| `ev-accounts/tests/integration/essentials-fields.test.ts` | Integration test verifying field presence | VERIFIED | 3 tests pass (is_appointed, faces_retention_vote, is_elected regression guard) |
| `essentials/src/components/SegmentedControl.jsx` | Reusable segmented control with `role="radiogroup"` | VERIFIED | 47 lines; `role="radiogroup"`, `role="radio"`, `aria-checked`, `backgroundColor: '#00657c'` active state |
| `essentials/src/components/LocalFilterSidebar.jsx` | Desktop sidebar with Type section | VERIFIED | Imports SegmentedControl, accepts `appointedFilter`/`onAppointedFilterChange` props, renders "Filter by type" SegmentedControl |
| `essentials/src/pages/Results.jsx` | Filter state, useMemo chain, mobile rendering, sessionStorage persistence | VERIFIED | `appointedFilter` state, `resolveIsAppointed`, `matchesAppointedFilter`, `appointedFilteredByTier` useMemo, mobile SegmentedControl at line 978, sessionStorage at line 362 |

**Additional artifact verified (Rule 3 fix documented in SUMMARY):**
| `ev-accounts/backend/src/lib/essentialsBrowseService.ts` | is_appointed and faces_retention_vote in both SQL SELECT clauses and row mapping | VERIFIED | Lines 153, 198 (SQL), line 261-262 (row mapping) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `essentialsService.ts PoliticianFlatRecord` | SQL SELECT clauses | `p.is_appointed, o.faces_retention_vote` in all 4 query locations | WIRED | 4 matches confirmed with grep |
| `Results.jsx appointedFilter state` | `useMemo appointedFilteredByTier` | `matchesAppointedFilter` applied inside tier/group buckets | WIRED | Line 585: `pols.filter(pol => matchesAppointedFilter(pol, appointedFilter))` |
| `Results.jsx appointedFilter state` | `sessionStorage ev:results` | `appointedFilter: appointedFilter` saved at line 362 | WIRED | Confirmed at line 362; `cachedResult?.appointedFilter` restored at line 307 |
| `Results.jsx` | `LocalFilterSidebar` | `onAppointedFilterChange={setAppointedFilter}` prop | WIRED | Line 837 confirmed |
| `appointedFilteredByTier` | `displayedPoliticians` | `displayedPoliticians` reads from `appointedFilteredByTier` not `byTier` | WIRED | Lines 594-598 confirmed |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `Results.jsx` appointedFilteredByTier | `is_appointed`, `faces_retention_vote` from `list` | API `/api/essentials/*` backed by `essentialsService.ts` SQL queries selecting `p.is_appointed, o.faces_retention_vote` | Yes — DB columns from `essentials.politicians` and `essentials.offices` tables | FLOWING |
| `SegmentedControl.jsx` | `value` prop (appointedFilter) | `useState` in Results.jsx, initialized from sessionStorage or 'All' | Yes — state is reactive and flows into useMemo chain | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| TypeScript compiles cleanly | `cd ev-accounts/backend && npm run typecheck` | Exit 0, no errors | PASS |
| Integration test passes | `cd ev-accounts/backend && npm test -- tests/integration/essentials-fields.test.ts` | 3/3 tests pass | PASS |
| essentials frontend builds | `cd essentials && npm run build` | Exit 0, 731 modules transformed | PASS |
| 4 SQL SELECT locations updated | `grep -c "p.is_appointed, o.faces_retention_vote" essentialsService.ts` | 4 | PASS |
| 3 row mappings updated | `grep -c "is_appointed: row.is_appointed" essentialsService.ts` | 3 | PASS |
| Git commits verified | `git log --oneline \| grep aa425cb\|8f85099` (ev-accounts) and `eb2cbc0\|1e2da95` (essentials) | All 4 commits found | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| FILT-01 | Plans 01 and 02 | User can filter the main representatives page by Elected, Appointed, or All | SATISFIED | SegmentedControl wired in both desktop sidebar and mobile; filter logic in matchesAppointedFilter |
| FILT-02 | Plans 01 and 02 | Retention judges appear under both Elected and Appointed filters | SATISFIED | `matchesAppointedFilter` Elected branch: `!resolved \|\| pol.faces_retention_vote === true`; Appointed branch: `resolved === true` (retention judges have `is_appointed=true` per DB backfill noted in SUMMARY) |
| FILT-03 | Plan 02 | Filter defaults to "All" preserving current behavior | SATISFIED | `useState(cachedResult?.appointedFilter \|\| 'All')` line 306; `appointedFilteredByTier` short-circuits to `byTier` when `appointedFilter === 'All'` |

**Note:** FILT-03 is marked as `[ ] Pending` in REQUIREMENTS.md (checkbox unchecked) and "Pending" in the coverage table. This is a REQUIREMENTS.md tracking discrepancy — the implementation is fully present and correct. The checkbox and status column in REQUIREMENTS.md should be updated to reflect completion.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| No blocker anti-patterns found | — | — | — | — |

No TODO/FIXME/placeholder comments found in modified files. No empty return stubs. No hardcoded empty arrays or objects flowing to rendered output.

### Human Verification Required

#### 1. Elected Filter Browser Behavior

**Test:** Search "300 E Kirkwood Ave, Bloomington, IN 47408", click "Elected" in the Type filter
**Expected:** Only elected officials visible; appointed officials (city clerk if applicable) disappear; Indiana appellate judges with retention votes remain visible
**Why human:** Requires live DB data with correct `is_appointed` and `faces_retention_vote` values populated; cannot verify filter output without a running server and database

#### 2. Appointed Filter Shows Retention Judges

**Test:** With same address, click "Appointed" in the Type filter
**Expected:** Indiana appellate judges with `faces_retention_vote=true` also appear in this view (dual-appearance)
**Why human:** Retention judge behavior depends on DB values set during the SQL backfill described in SUMMARY — needs live data to confirm

#### 3. Mobile Segmented Control Rendering

**Test:** Resize browser to <768px, navigate to results
**Expected:** Segmented control appears below tier pills with minimum 44px touch targets
**Why human:** Visual breakpoint behavior requires browser rendering

#### 4. Back-Navigation Filter Persistence

**Test:** Apply a filter (e.g., Elected), click a politician card, press browser back
**Expected:** Filter is restored to "Elected" (not reset to "All")
**Why human:** sessionStorage restore flow requires browser navigation context

### Gaps Summary

No gaps found. All must-haves verified at all three levels (exists, substantive, wired) plus data-flow trace. REQUIREMENTS.md has a stale checkbox for FILT-03 that does not match the implemented code — this is a documentation tracking issue, not a code gap.

---

_Verified: 2026-03-30T18:01:00Z_
_Verifier: Claude (gsd-verifier)_
