# Roadmap: Empowered Vote

## Milestones

- ✅ **v1.0 Quality & Consolidation** — Phases 1-7 (shipped 2026-02-18)
- ✅ **v1.1 Essentials UX Polish** — Phases 8-10 (shipped 2026-02-19)
- ✅ **v1.2 Compass Onboarding & UX** — Phases 11-16 (shipped 2026-02-20)
- ✅ **v1.3 Compass Bug Fixes & Title Standardization** — Phases 17-20 (shipped 2026-02-21)
- 🔄 **v1.4 Compass Polish & Tech Debt** — Phases 21-24 (in progress)

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

### v1.4 Compass Polish & Tech Debt

- [x] **Phase 21: Guest Flow Fix** - Fix 401 errors so guests can view and complete the compass without login — completed 2026-02-22
- [x] **Phase 22: Radar Label Fixes** - Fix label clipping, minimum size, and word-wrap in ev-ui RadarChartCore (completed 2026-02-22)
- [x] **Phase 23: UX Cleanup** - Remove stale buttons, fix mobile stat cards, and elevate QuestionText prominence (completed 2026-02-22)
- [ ] **Phase 24: Tech Debt Cleanup** - Remove dropped-column references from EV-Backend CLI tools and vestigial admin fields

## Phase Details

### Phase 21: Guest Flow Fix
**Goal**: Guest users can view the full compass and complete the quiz without hitting authentication errors
**Depends on**: Nothing
**Requirements**: GUEST-01, GUEST-02
**Success Criteria** (what must be TRUE):
  1. A guest user clicking "View Full Compass" sees the full radar chart rendered from their localStorage answers — no 401 error, no blank screen
  2. A guest user who finishes the quiz is routed to a working compass/completion page — no blank screen or console errors
  3. BuildCompass.jsx skips the `/compass/answers` fetch (or handles 401 gracefully) when no session exists
**Plans:** 1/1 plans complete
- [x] 21-01-PLAN.md -- Make BuildCompass guest-safe (localStorage answers for guests, server fetch for logged-in users)

### Phase 22: Radar Label Fixes
**Goal**: Radar chart labels are fully visible and readable at all positions in ev-ui RadarChartCore
**Depends on**: Nothing (ev-ui change, independent of Phase 21)
**Requirements**: LABEL-01, LABEL-02, LABEL-03
**Success Criteria** (what must be TRUE):
  1. Labels on the far left and far right edges of the radar chart are not clipped — no text cut off by the SVG or container boundary
  2. Short single-word labels (e.g., "Misinformation", "Immigration") render at a readable minimum font size — not shrunk below legibility
  3. Multi-word labels that wrap (e.g., "AI Regulation") display all words — no lines truncated or missing
  4. ev-ui is published at a new patch version and CompassV2 is updated to consume it
**Plans:** 2/2 plans complete
Plans:
- [x] 22-01-PLAN.md -- Fix label rendering: wrapLabel, font sizing, dynamic horizontal padding
- [x] 22-02-PLAN.md -- Publish ev-ui 0.1.26, update CompassV2, visual verification

### Phase 23: UX Cleanup
**Goal**: Compass and Library pages are free of stale controls, display correctly on mobile, and give QuestionText appropriate visual weight
**Depends on**: Nothing (independent CompassV2 changes)
**Requirements**: UX-01, UX-02, UX-03, UX-04
**Success Criteria** (what must be TRUE):
  1. The compass page has no "Edit Topics" button — users navigate to Library to edit topics
  2. The Library page has no "Clear" button — the action is removed entirely
  3. The Answered/Remaining stat cards on the Library page fill full width on a mobile screen (no partial-width or misaligned layout)
  4. QuestionText in LibraryDrawer and stance selection views is visually larger and closer to title weight — clearly more prominent than the supporting body text
**Plans:** 2/2 plans complete
Plans:
- [ ] 23-01-PLAN.md -- Remove stale buttons (Edit Topics, Clear) and fix mobile stat card layout
- [ ] 23-02-PLAN.md -- Restructure text hierarchy: question text becomes title, topic name becomes subtitle, poles removed

### Phase 24: Tech Debt Cleanup
**Goal**: EV-Backend CLI tools and CompassV2 admin components no longer reference dropped columns
**Depends on**: Nothing (independent cleanup tasks)
**Requirements**: DEBT-01, DEBT-02, DEBT-03, DEBT-04
**Success Criteria** (what must be TRUE):
  1. compassimport/models.go compiles without any StartPhrase field or start_phrase column reference
  2. cmd/seed/compass_csv_seeder.go compiles without any StartPhrase or start_phrase reference
  3. Admin TopicEditor PATCH request body contains no short_name field
  4. Admin TopicAccordion state initialization contains no editedFields.short_name entry
**Plans:** 2 plans
Plans:
- [ ] 24-01-PLAN.md -- Remove StartPhrase/start_phrase from compassimport package and CSV seeder
- [ ] 24-02-PLAN.md -- Remove vestigial short_name from admin TopicEditor and TopicAccordion

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
| 21. Guest Flow Fix | v1.4 | Complete    | 2026-02-22 | 2026-02-22 |
| 22. Radar Label Fixes | 1/2 | Complete    | 2026-02-22 | - |
| 23. UX Cleanup | 2/2 | Complete    | 2026-02-22 | - |
| 24. Tech Debt Cleanup | v1.4 | 0/? | Not started | - |
