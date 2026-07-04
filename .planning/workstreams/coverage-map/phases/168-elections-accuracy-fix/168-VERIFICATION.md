---
phase: 168-elections-accuracy-fix
verified: 2026-07-04T18:10:00Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
---

# Phase 168: Elections Accuracy Fix Verification Report

**Phase Goal:** Elections coverage numbers are computed correctly — a state with only statewide/legislative races can no longer show an undifferentiated 100%, and clicking into a state never contradicts its own map score.
**Verified:** 2026-07-04
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `getElectionsStateScores` reports statewide/legislative coverage and county/local-pinnable coverage as two separately-computed numbers per state | VERIFIED | `backend/src/lib/electionsMapService.ts:139-151` — `classifyRaces(races, countyMap, placeMap)` splits into `{statewide, countyPinnable}`; `coverage`/`races_total`/`races_covered` computed from `statewide` only, `countyCoverage.{coverage,races_total,races_covered}` computed independently from `countyPinnable`. |
| 2 | A state whose races are all cd/sldu/sldl/bare-state (Michigan case) reports `countyCoverage.status === 'unknown'`, never a fake 0% | VERIFIED | `electionsMapService.ts:147-149`: `countyPinnable.length === 0 ? {status:'unknown', coverage:0,...} : {status:'scored',...}`. Confirmed live in 168-03-SUMMARY.md human walkthrough (MI: county reads "N/A — no county-level races"). |
| 3 | Both the statewide split and county drill-down derive their buckets from the same `resolveRaceCountyFips` classifier over the same race set/date anchor | VERIFIED | `classifyRaces` (electionsMap.ts:74-86) calls `resolveRaceCountyFips` per race; `getElectionsCountyScores` (electionsMapService.ts:176-182) calls the identical `resolveRaceCountyFips` function directly on the same `racesForStateDate(code, nd.date)` result. Single shared classifier, no duplicate logic. |
| 4 | `elections:us` payload carries the statewide/legislative race list per state with no new DB query and no new cache key | VERIFIED | `statewideRaces: statewide` added to pushed object (electionsMapService.ts:150); cache key unchanged, `cached('elections:us', ...)` (line 127); `grep -c "elections:"` cache keys unchanged — only pre-existing `elections:us` and `elections:county:${code}` keys exist. |
| 5 | Route-level test proves `/coverage/map?metric=elections&level=state` forwards the partitioned payload unmodified | VERIFIED | `backend/src/routes/admin.test.ts` (4 tests, run and confirmed passing) asserts `res.body` `toEqual({states:[stateElection]})` against the mocked service return — exact pass-through confirmed against actual route handler in `admin.ts:191-194`, which does `res.json({states: await getElectionsStateScores(...)})` with no transformation. |
| 6 | Test asserts a state's `countyCoverage` denominator is internally consistent with the county endpoint (ELEC-03 route-layer contract) | VERIFIED (with noted limitation) | `admin.test.ts:105-126` asserts `mi.countyCoverage.races_total === countyDrilldownTotal`. Test passes. Code review (168-REVIEW.md IN-02, Info severity) correctly notes this is tautological — both sides are fixture constants, not derived from real partition logic — so it verifies route-forwarding, not the partition invariant itself. This is an accepted Info-level gap, not a blocker; the invariant itself (single shared classifier) is proven at the unit level by truth #3. |
| 7 | Test runs without a live DB (mocked service + auth) | VERIFIED | `admin.test.ts:11-28` mocks `db.js`, `supabase.js`, `middleware/auth.js`, `middleware/requireAdmin.js`, `lib/electionsMapService.js`. Full suite run confirms 4/4 pass with no live DB. |
| 8 | State choropleth fill in elections mode is colored by statewide/legislative coverage, not the old lumped number | VERIFIED | `CoverageMap.tsx:210`: `metric === 'elections' ? electionStateColor(es) : completenessColor(...)`; `electionStateColor` (line 37-41) reads `s.coverage`, which is now the statewide-only field per truth #1. |
| 9 | Clicking a state in elections mode shows a statewide-races panel listing statewide/legislative races with candidate coverage, alongside the existing county view | VERIFIED | `CoveragePage.tsx:173-175`: `{metric === 'elections' && selected && <StatewideRacesPanel stateElection={...} loading={statesLoading}/>}` renders as a sibling to the map (which retains its own county drill-down); `StatewideRacesPanel.tsx` renders a table of `statewideRaces` with `position_name` and `{candidate_count}/{seats} candidates` per row, plus an empty-state row. |
| 10 | A state with no county-pinnable races shows "N/A — no county-level races", visually distinct from a real 0% | VERIFIED | Two independent renderings confirmed: (a) `CoverageMap.tsx` state hover readout (line 158) and `electionStateColor`/`electionCountyColor` (lines 37-46, post-fix) both distinguish `NOT_STARTED` (no election)/`NO_RACE_DATA` gray (no county races or `races_total===0`)/scored (`coverage<=0 ? 0.01 : coverage`, preventing a real 0% from collapsing into the `NOT_STARTED` sentinel); (b) `StatewideRacesPanel.tsx:39-43` header shows "N/A — no county-level races" when `countyCoverage.status==='unknown'`. |
| 11 | Michigan case end-to-end: real statewide coverage in fill/readout, N/A county number, populated statewide-races panel — no contradiction between state view and county drill-down | VERIFIED | 168-03-SUMMARY.md documents live human verification against local backend+admin (2026-07-04): MI shows "100% · county: N/A — no county-level races" in readout, "Statewide & legislative races (13)" panel populated, county choropleth all-gray "no race data" legend — consistent, no contradiction. Reviewer approved. |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/src/lib/electionsMap.ts` | `classifyRaces` pure partition helper reusing `resolveRaceCountyFips` | VERIFIED | Exported at line 74; single-pass loop calling `resolveRaceCountyFips`, no duplicate classifier (lines 74-86). |
| `backend/src/lib/electionsMap.test.ts` | Unit tests for `classifyRaces` (all-statewide, mixed, empty) | VERIFIED | `npx vitest run src/lib/electionsMap.test.ts` → 14/14 tests pass (executed directly, not taken from SUMMARY claim). |
| `backend/src/lib/electionsMapService.ts` | `getElectionsStateScores` partitioned; extended `StateElection` shape | VERIFIED | `countyCoverage`/`statewideRaces` present on interface (lines 13-26) and populated in the per-state loop (lines 139-151). |
| `backend/src/routes/admin.test.ts` | Route-level test for `/coverage/map` elections branches incl. ELEC-03 assertion | VERIFIED | File exists, `npx vitest run src/routes/admin.test.ts` → 4/4 tests pass (executed directly). |
| `admin/src/pages/admin/StatewideRacesPanel.tsx` | New panel component, ≥25 lines, lists statewide races | VERIFIED | 76 lines; renders table + empty state + loading state (post-review addition) + N/A county-pinnable readout in header. |
| `admin/src/pages/admin/CoveragePage.tsx` | Panel mounted in elections+selected branch alongside county view | VERIFIED | Line 173-175, sibling to map (map retains county drill-down), gated opposite of the completeness table block. |
| `admin/src/pages/admin/CoverageMap.tsx` | State fill/readout repointed to statewide coverage; N/A vs 0% distinction on both axes | VERIFIED | `electionStateColor` (post-fix, commit `cd94bfe9`) now mirrors `electionCountyColor`'s three-way `NOT_STARTED`/`NO_RACE_DATA`/scored-with-0%-guard distinction. |
| `admin/src/pages/admin/coverageTypes.ts` | `StateElection` extended to mirror backend contract | VERIFIED | Lines 32-37: `countyCoverage` + `statewideRaces: ElectionRace[]` match backend field-for-field. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `electionsMapService.ts` | `electionsMap.ts` | `classifyRaces`/`resolveRaceCountyFips` import | WIRED | Import at line 11; called at line 139. |
| `getElectionsStateScores` | `countyOcdToFips`/`placeSlugToFips` | `Promise.all` inside per-state loop | WIRED | Lines 134-138, mirrors `getElectionsCountyScores`'s existing pattern (lines 168-173). |
| `admin.test.ts` | `admin.ts` | supertest against mounted router, service mocked | WIRED | Confirmed route forwards mock payload unmodified via passing assertions. |
| `CoveragePage.tsx` | `StatewideRacesPanel.tsx` | conditional render gated `metric==='elections' && selected`, fed from `elecStatesByFips` | WIRED | Line 173-175; data sourced from the same lazily-fetched `elecStates` state, no new fetch. |
| `CoverageMap.tsx` | `StateElection.countyCoverage` | state hover readout branch mirroring `electionCountyColor`'s unknown/scored distinction | WIRED | Line 158 (readout) + lines 37-41 (fill), both post-fix. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|---------------------|--------|
| `StatewideRacesPanel` | `stateElection.statewideRaces` | `elecStates` (fetched via `apiFetch('/admin/coverage/map?metric=elections&level=state')`) → `getElectionsStateScores()` → `racesForStateDate()` real SQL against `essentials.races`/`race_candidates`/`offices`/`districts` | Yes | FLOWING |
| `CoverageMap` fill/readout | `es.coverage`, `es.countyCoverage` | Same `elecStatesByFips` map, same DB-backed source | Yes | FLOWING |
| Route `/coverage/map` | passthrough of service return | `getElectionsStateScores`/`getElectionsCountyScores`, no route-level aggregation/transformation | Yes (confirmed no static empty-array fallback except on legitimate no-election-found case) | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `classifyRaces` unit tests | `npx vitest run src/lib/electionsMap.test.ts` | 14/14 passed | PASS |
| `admin.test.ts` route tests | `npx vitest run src/routes/admin.test.ts` | 4/4 passed | PASS |
| Backend typecheck (elections files) | `npx tsc --noEmit -p tsconfig.json \| grep -i electionsMap` | no output (clean) | PASS |
| Admin typecheck (touched files) | `npx tsc --noEmit \| grep -iE 'coverageTypes\|StatewideRacesPanel\|CoverageMap\|CoveragePage'` | no output (clean) | PASS |
| Full backend suite regression check | `npm test` | 631 passed / 20 failed / 4 skipped — all 20 failures are pre-existing DB/env/architecture-dependent tests (coordinate leakage, compass auth, gems, treasury-cities, tribal-land, arcgis coverage, browseResolution) unrelated to this phase's files; zero failures in `electionsMap.test.ts` or `admin.test.ts` | PASS (no regression) |

### Probe Execution

No `scripts/*/tests/probe-*.sh` probes declared or found for this phase (not a migration/CLI/tooling phase). Skipped — not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| ELEC-01 | 168-01, 168-03 | Elections coverage reports statewide/legislative and county/local-pinnable races as separately computed metrics; no undifferentiated 100% | SATISFIED | `classifyRaces` partition (168-01) + repointed state fill (168-03) — truths #1, #3, #8 |
| ELEC-02 | 168-03 | Clicking a state shows a statewide-races panel with candidate coverage | SATISFIED | `StatewideRacesPanel` mounted in `CoveragePage` — truth #9 |
| ELEC-03 | 168-01, 168-02, 168-03 | State-level and county-level numbers computed from consistent denominators; no contradiction | SATISFIED | Shared classifier (168-01), route-level consistency test (168-02, with noted Info-level tautology limitation), N/A-vs-0% on both axes (168-03) — truths #3, #6, #10, #11 |

No orphaned requirements: REQUIREMENTS.md traceability table maps ELEC-01/02/03 → Phase 168 exclusively; all three appear in at least one plan's `requirements:` frontmatter field.

### Anti-Patterns Found

None. Scanned all 8 touched/created files (`electionsMap.ts`, `electionsMap.test.ts`, `electionsMapService.ts`, `admin.test.ts`, `coverageTypes.ts`, `StatewideRacesPanel.tsx`, `CoveragePage.tsx`, `CoverageMap.tsx`) for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER` and placeholder/not-implemented language — zero matches.

Two Info-level findings from `168-REVIEW.md` remain unfixed but are explicitly non-blocking (Info severity, not Warning/Critical, and out of the phase's must-have scope):
- IN-01: `stateCovered`/`countyCovered` numerator duplicated in `electionsMapService.ts` alongside `raceCoverage`'s internal filter (maintainability note, not a correctness defect for this phase's goal).
- IN-02: ELEC-03 route test is tautological (see truth #6 above) — accepted with documented limitation.
- IN-03: Candidate cell label `{count}/{seats} candidates` could read as a ratio — cosmetic.
- IN-04: Pre-existing `any`-typed refs in `CoverageMap.tsx`, not introduced by this phase.

Both code-review Warnings (WR-01: state fill missing 0%-vs-N/A distinction; WR-02: panel blank during lazy-fetch window) were fixed in commit `cd94bfe9` — confirmed by direct code inspection and git diff against the pre-fix commit `8987c4f4`, not merely trusted from the SUMMARY narrative.

### Human Verification Required

None outstanding. The plan's `checkpoint:human-verify` task (168-03 Task 3, Michigan-case walkthrough) was already executed and approved per 168-03-SUMMARY.md, with specific before/after readouts documented (MI: "100% · county: N/A — no county-level races", panel "Statewide & legislative races (13)"). This satisfies the deferred human-verification requirement; no further human action is needed to close this phase.

### Deferred Items

Two items were explicitly identified during 168-03 human verification and captured as out-of-scope follow-ups, matching later roadmap phases:

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Depth-aware 3-tier candidate coverage indicator (names / names+stances-or-TM / all three) | Phase 168.1 | ROADMAP.md: "Phase 168.1: Depth-Aware 3-Tier Elections Coverage (INSERTED)... Depends on: Phase 168... Requirements: ELEC-04, ELEC-05, ELEC-06" |
| 2 | Seeding missing statewide offices (e.g. MI Governor/Senate) / expected-slate denominator | Not yet scheduled to a specific phase | 168-03-SUMMARY.md "Next Phase Readiness": "Seed missing statewide offices... and/or make coverage relative to the expected office slate" — flagged as a data-seeding concern, not a code defect within ELEC-01/02/03's scope |

Neither deferred item affects the phase-168 goal: the goal is about *computing coverage correctly from whatever race data exists*, not about the completeness of the underlying seeded election data or the depth of the coverage metric itself (both are explicitly separate, later-scoped concerns per the roadmap).

### Gaps Summary

No gaps. All 11 derived observable truths (covering ROADMAP.md's 3 formal Success Criteria plus PLAN-frontmatter must-haves across all three plans) are verified directly against the codebase — not inferred from SUMMARY.md narrative. Both backend test suites (`electionsMap.test.ts`, `admin.test.ts`) were re-executed independently and pass. Both admin and backend TypeScript compile clean for all touched files. The full backend test suite shows zero regressions attributable to this phase (the 20 pre-existing failures are DB/env/architecture-dependent and unchanged from the documented pre-phase baseline). The two code-review Warnings (WR-01, WR-02) were verified fixed by direct code diff inspection, not merely trusted from the SUMMARY claim. The one Info-level test-quality gap (IN-02, tautological ELEC-03 route assertion) does not block phase completion — the actual denominator-consistency invariant is enforced structurally by the single shared `resolveRaceCountyFips` classifier (verified at the unit level) and confirmed live in the human Michigan walkthrough.

---

*Verified: 2026-07-04*
*Verifier: Claude (gsd-verifier)*
