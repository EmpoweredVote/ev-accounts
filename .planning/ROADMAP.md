# Roadmap: Empowered Vote

## Milestones

- ✅ **v1.0 Quality & Consolidation** — Phases 1-7 (shipped 2026-02-18)
- 🚧 **v1.1 Essentials UX Polish** — Phases 8-10 (in progress)

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

### 🚧 v1.1 Essentials UX Polish (In Progress)

**Milestone Goal:** Polish the Essentials app layout, building imagery, and term date display for a demo-ready user experience.

- [x] **Phase 8: Layout** - Sidebar stays fixed while representatives panel scrolls independently (completed 2026-02-18)
- [x] **Phase 9: Building Imagery** - Real building photos display per location and tier with scroll-spy on "All" mode (completed 2026-02-18)
- [ ] **Phase 10: Term Dates** - Term dates removed from dashboard cards and surfaced on politician profile pages

## Phase Details

### Phase 8: Layout
**Goal**: Users can browse representatives without the sidebar jumping around
**Depends on**: Nothing (independent)
**Requirements**: LAYOUT-01, LAYOUT-02
**Success Criteria** (what must be TRUE):
  1. User scrolls a long list of representatives and the sidebar (search, tier filter, building image) stays visible at all times
  2. The representatives panel scrolls independently without the full page moving
  3. Sidebar and panel reach their natural bottom edges independently — no clipped content
**Plans:** 1/1 plans complete
Plans:
- [x] 08-01-PLAN.md — Fixed sidebar + independently scrolling representatives panel

### Phase 9: Building Imagery
**Goal**: Users see real building photos matched to their location and the tier they are viewing
**Depends on**: Nothing (independent)
**Requirements**: IMG-01, IMG-02, IMG-03, IMG-04, IMG-05, IMG-06
**Success Criteria** (what must be TRUE):
  1. Federal tier displays a real photograph of the US Capitol (not the SVG placeholder)
  2. State tier displays a real photograph of the relevant state capitol (Indiana State House for IN results, California State Capitol for CA results)
  3. Local tier displays a real photograph of the relevant city hall (Bloomington City Hall for IN, LA City Hall for CA)
  4. Selecting a tier filter (Federal, State, or Local) immediately shows that tier's building photo
  5. In "All" mode, the building photo swaps instantly as the user scrolls from one tier section into another
  6. Searching a location not covered by real photos shows the existing SVG illustrated image instead of a broken image
**Plans:** 1/1 plans complete
Plans:
- [ ] 09-01-PLAN.md — Real building photographs and updated image mapping with human verification

### Phase 10: Term Dates
**Goal**: Users see term dates in the right context — profile detail, not card clutter
**Depends on**: Nothing (independent)
**Requirements**: PROF-01, PROF-02
**Success Criteria** (what must be TRUE):
  1. Dashboard politician cards no longer show start or end dates
  2. A politician's profile page displays their term start and end dates below their title
**Plans**: TBD

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
| 9. Building Imagery | 1/1 | Complete   | 2026-02-18 | - |
| 10. Term Dates | v1.1 | 0/? | Not started | - |
