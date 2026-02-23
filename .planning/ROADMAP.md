# Roadmap: Empowered Vote

## Milestones

- ✅ **v1.0 Quality & Consolidation** — Phases 1-7 (shipped 2026-02-18)
- ✅ **v1.1 Essentials UX Polish** — Phases 8-10 (shipped 2026-02-19)
- ✅ **v1.2 Compass Onboarding & UX** — Phases 11-16 (shipped 2026-02-20)
- ✅ **v1.3 Compass Bug Fixes & Title Standardization** — Phases 17-20 (shipped 2026-02-21)
- ✅ **v1.4 Compass Polish & Tech Debt** — Phases 21-25 (shipped 2026-02-22)
- ✅ **v1.5 Address Verification & BallotReady Independence** — Phases 26-29 (shipped 2026-02-23)

## Phases

<details>
<summary>✅ v1.0 Quality & Consolidation (Phases 1-7) — SHIPPED 2026-02-18</summary>

- [x] Phase 1: Auth Safety Audit (1/1 plans) — completed 2026-02-17
- [x] Phase 2: Guest-First Auth (3/3 plans) — completed 2026-02-17
- [x] Phase 3: Compass Visual Fixes (2/2 plans) — completed 2026-02-18
- [x] Phase 4: Compass UX Enhancements (8/8 plans) — completed 2026-02-18
- [x] Phase 5: Essentials Improvements (5/5 plans) — completed 2026-02-18
- [x] Phase 6: Audit Gap Closure (1/1 plan) — completed 2026-02-18
- [x] Phase 7: Integration Polish (1/1 plan) — completed 2026-02-18

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v1.1 Essentials UX Polish (Phases 8-10) — SHIPPED 2026-02-19</summary>

- [x] Phase 8: Layout (1/1 plans) — completed 2026-02-18
- [x] Phase 9: Building Imagery (1/1 plans) — completed 2026-02-18
- [x] Phase 10: Term Dates (1/1 plans) — completed 2026-02-18

Full details: `.planning/milestones/v1.1-ROADMAP.md`

</details>

<details>
<summary>✅ v1.2 Compass Onboarding & UX (Phases 11-16) — SHIPPED 2026-02-20</summary>

- [x] Phase 11: Tech Debt Cleanup (1/1 plans) — completed 2026-02-19
- [x] Phase 12: Quick UX Fixes (2/2 plans) — completed 2026-02-19
- [x] Phase 13: Topic Selection Enforcement (2/2 plans) — completed 2026-02-19
- [x] Phase 14: Guided Onboarding Flow (4/4 plans) — completed 2026-02-19
- [x] Phase 15: Help Page Update (2/2 plans) — completed 2026-02-19
- [x] Phase 16: Audit Bug Fixes (1/1 plan) — completed 2026-02-20

Full details: `.planning/milestones/v1.2-ROADMAP.md`

</details>

<details>
<summary>✅ v1.3 Compass Bug Fixes & Title Standardization (Phases 17-20) — SHIPPED 2026-02-21</summary>

- [x] Phase 17: Title Standardization (Backend) (2/2 plans) — completed 2026-02-21
- [x] Phase 18: Title Display (Frontend) (2/2 plans) — completed 2026-02-21
- [x] Phase 19: Calibration Flow Fixes (2/2 plans) — completed 2026-02-21
- [x] Phase 20: Compare Bug Fix (1/1 plan) — completed 2026-02-21

Full details: `.planning/milestones/v1.3-ROADMAP.md`

</details>

<details>
<summary>✅ v1.4 Compass Polish & Tech Debt (Phases 21-25) — SHIPPED 2026-02-22</summary>

- [x] Phase 21: Guest Flow Fix (1/1 plans) — completed 2026-02-22
- [x] Phase 22: Radar Label Fixes (2/2 plans) — completed 2026-02-22
- [x] Phase 23: UX Cleanup (2/2 plans) — completed 2026-02-22
- [x] Phase 24: Tech Debt Cleanup (2/2 plans) — completed 2026-02-22
- [x] Phase 25: Onboarding-to-Calibration Redirect & Topic Display Fix (2/2 plans) — completed 2026-02-22

Full details: `.planning/milestones/v1.4-ROADMAP.md`

</details>

### ✅ v1.5 Address Verification & BallotReady Independence (Shipped 2026-02-23)

**Milestone Goal:** Replace BallotReady API dependency with Google Maps address validation and PostGIS geofence-only politician matching, making the platform self-sufficient with cached data.

- [x] **Phase 26: Geofence-Only Search** - Remove BallotReady fallback from address search; return federal/state from cache when local geofence is empty
- [x] **Phase 27: Cache-Only Candidates & Warmer Cleanup** - Replace live candidate fetch with DB query; stub warmers; de-register BallotReady provider (completed 2026-02-22)
- [x] **Phase 28: Address Autocomplete** - Google Maps Places autocomplete replaces plain text input; remove ZIP path; show confirmed address and no-coverage message (completed 2026-02-22)
- [x] **Phase 29: Validation, Polish & Key Removal** - Grep audit confirms zero BallotReady call sites; BALLOTREADY_KEY removed from Render production env; Google Maps billing alert configured (completed 2026-02-23)

## Phase Details

### Phase 26: Geofence-Only Search
**Goal**: Address search returns politicians using geofence matching only, with federal and state officials from cache when local geofence data is unavailable — no BallotReady fallback executes
**Depends on**: Phase 25 (preceding milestone complete)
**Requirements**: BR-01, BR-02
**Success Criteria** (what must be TRUE):
  1. Searching an address in a geofence-covered area (Monroe County IN or LA County CA) returns local politicians matched by PostGIS point-in-polygon — no BallotReady API call fires
  2. Searching an address outside any covered geofence area (e.g., rural Iowa) returns federal and state officials from cache rather than an empty page
  3. The `X-Data-Status: no-geofence-data` response header is present when local geofence returns zero results
  4. The search response never returns a completely empty politician list for a valid US address
**Plans**: 2 plans
Plans:
- [x] 26-01-PLAN.md — Backend: remove BallotReady fallback, implement geofence-only search with federal/state cache fallback
- [x] 26-02-PLAN.md — Frontend: address-only input, formatted address display, local empty-state message

### Phase 27: Cache-Only Candidates & Warmer Cleanup
**Goal**: All remaining BallotReady live API call sites are replaced — candidates come from the database, warmers are fully removed, and the BallotReady provider is de-registered at startup
**Depends on**: Phase 26
**Requirements**: BR-03, BR-04, CAND-01
**Success Criteria** (what must be TRUE):
  1. The candidate toggle on the Essentials dashboard shows candidates sourced from `essentials.election_records` with no live BallotReady fetch occurring
  2. A politician profile page loads candidacy data (endorsements, stances, elections) from the database without triggering a background goroutine to BallotReady
  3. The backend starts without initializing or logging any BallotReady provider connection
  4. ZIP-based cache warmers (`warmFederal`, `warmState`, `warmLocal`) are fully deleted — no stubs, no dead code
**Plans**: 2 plans
Plans:
- [ ] 27-01-PLAN.md — DB-only candidate endpoint and warmer/cache cleanup
- [ ] 27-02-PLAN.md — BallotReady provider deregistration and cache table removal

### Phase 28: Address Autocomplete
**Goal**: Users enter their address using Google Maps Places autocomplete as the sole search input — the ZIP code path is removed and every search result shows the validated address
**Depends on**: Phase 26 (backend clean; frontend can proceed in parallel but phases here for clarity)
**Requirements**: ADDR-01, ADDR-02, ADDR-03, ADDR-04
**Success Criteria** (what must be TRUE):
  1. The Essentials dashboard and landing page show an address autocomplete field — no ZIP code input is present anywhere in the search flow
  2. Typing a partial address produces Google Maps suggestions; selecting one triggers a politician search
  3. After selecting an address, the results page displays the confirmed formatted address (e.g., "Showing results for Bloomington, IN") so users know what was searched
  4. When an address is outside geofence coverage, a visible message explains that local representative data is not yet available for their area
  5. If the Google Maps API fails to load, the autocomplete degrades to a plain text input that still submits to the backend
**Plans**: 2 plans
Plans:
- [ ] 28-01-PLAN.md — Hook extension (loadError) + Landing page address-only refactor with selection validation and degraded mode
- [ ] 28-02-PLAN.md — Results page layout restructure: full-width address bar, local sidebar, loading skeletons, formatted address display, no-geofence message

### Phase 29: Validation, Polish & Key Removal
**Goal**: All BallotReady references are confirmed gone via grep audit, the API key is decommissioned from all environments, and Google Maps billing monitoring is in place
**Depends on**: Phase 27, Phase 28
**Requirements**: CLEAN-01, CLEAN-02, CLEAN-03
**Success Criteria** (what must be TRUE):
  1. Running `grep -r "ballotReadyClient\|BallotReady\|BALLOTREADY" EV-Backend/` returns zero matches in Go source files
  2. `BALLOTREADY_API_KEY` is absent from App Runner environment variables and all Netlify environment configs — the backend starts and operates normally without it
  3. A Google Cloud billing alert is active and configured to notify at a monthly threshold so autocomplete cost spikes are caught before they compound
**Plans**: 2 plans
Plans:
- [ ] 29-01-PLAN.md — Codebase audit, provider config cleanup, and .env.local key removal
- [ ] 29-02-PLAN.md — AWS environment verification and Google Cloud Monitoring alert setup

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Auth Safety Audit | v1.0 | 1/1 | Complete | 2026-02-17 |
| 2. Guest-First Auth | v1.0 | 3/3 | Complete | 2026-02-17 |
| 3. Compass Visual Fixes | v1.0 | 2/2 | Complete | 2026-02-18 |
| 4. Compass UX Enhancements | v1.0 | 8/8 | Complete | 2026-02-18 |
| 5. Essentials Improvements | v1.0 | 5/5 | Complete | 2026-02-18 |
| 6. Audit Gap Closure | v1.0 | 1/1 | Complete | 2026-02-18 |
| 7. Integration Polish | v1.0 | 1/1 | Complete | 2026-02-18 |
| 8. Layout | v1.1 | 1/1 | Complete | 2026-02-18 |
| 9. Building Imagery | v1.1 | 1/1 | Complete | 2026-02-18 |
| 10. Term Dates | v1.1 | 1/1 | Complete | 2026-02-18 |
| 11. Tech Debt Cleanup | v1.2 | 1/1 | Complete | 2026-02-19 |
| 12. Quick UX Fixes | v1.2 | 2/2 | Complete | 2026-02-19 |
| 13. Topic Selection Enforcement | v1.2 | 2/2 | Complete | 2026-02-19 |
| 14. Guided Onboarding Flow | v1.2 | 4/4 | Complete | 2026-02-19 |
| 15. Help Page Update | v1.2 | 2/2 | Complete | 2026-02-19 |
| 16. Audit Bug Fixes | v1.2 | 1/1 | Complete | 2026-02-20 |
| 17. Title Standardization (Backend) | v1.3 | 2/2 | Complete | 2026-02-21 |
| 18. Title Display (Frontend) | v1.3 | 2/2 | Complete | 2026-02-21 |
| 19. Calibration Flow Fixes | v1.3 | 2/2 | Complete | 2026-02-21 |
| 20. Compare Bug Fix | v1.3 | 1/1 | Complete | 2026-02-21 |
| 21. Guest Flow Fix | v1.4 | 1/1 | Complete | 2026-02-22 |
| 22. Radar Label Fixes | v1.4 | 2/2 | Complete | 2026-02-22 |
| 23. UX Cleanup | v1.4 | 2/2 | Complete | 2026-02-22 |
| 24. Tech Debt Cleanup | v1.4 | 2/2 | Complete | 2026-02-22 |
| 25. Onboarding-to-Calibration Redirect & Topic Display Fix | v1.4 | 2/2 | Complete | 2026-02-22 |
| 26. Geofence-Only Search | 2/2 | Complete    | 2026-02-22 | - |
| 27. Cache-Only Candidates & Warmer Cleanup | 2/2 | Complete    | 2026-02-22 | - |
| 28. Address Autocomplete | 2/2 | Complete    | 2026-02-23 | - |
| 29. Validation, Polish & Key Removal | 2/2 | Complete    | 2026-02-23 | 2026-02-23 |

### Phase 30: Fix Compass calibration flow layout and write-in option

**Goal:** Fix the answer step layout in CalibrationOverlay to be cohesive (50/50 chart/stances split, question text above stances not centered on page) and add the write-in option that already exists in Quiz/LibraryDrawer but is missing from the calibration flow
**Depends on:** Phase 29
**Plans:** 2/2 plans complete

Plans:
- [ ] 30-01-PLAN.md — Layout restructure: 50/50 split, question text above stances, chart vertical centering
- [ ] 30-02-PLAN.md — Write-in integration: dnd-kit drag-and-drop, stance positioning, topic-change restoration

### Phase 31: Essentials profile and district data fixes

**Goal:** [To be planned]
**Depends on:** Phase 30
**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd:plan-phase 31 to break down)
