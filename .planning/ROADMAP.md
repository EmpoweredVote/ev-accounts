# Roadmap: Empowered Vote

## Milestones

- ✅ **v1.0 Quality & Consolidation** — Phases 1-7 (shipped 2026-02-18)
- ✅ **v1.1 Essentials UX Polish** — Phases 8-10 (shipped 2026-02-19)
- ✅ **v1.2 Compass Onboarding & UX** — Phases 11-16 (shipped 2026-02-20)
- 🚧 **v1.3 Compass Bug Fixes & Title Standardization** — Phases 17-20 (in progress)

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

### 🚧 v1.3 Compass Bug Fixes & Title Standardization (In Progress)

**Milestone Goal:** Fix calibration flow edge cases, standardize topic naming from server through display, and eliminate the double-overlay compare bug.

- [x] **Phase 17: Title Standardization (Backend)** - Canonical topic naming established as server-side source of truth (completed 2026-02-21)
- [ ] **Phase 18: Title Display (Frontend)** - Compass labels, Library cards, and calibration all render clean names from server data
- [ ] **Phase 19: Calibration Flow Fixes** - Compass handles all mixed answered/unanswered topic states without dead ends
- [ ] **Phase 20: Compare Bug Fix** - Comparison overlay renders exactly one shape on the radar chart

## Phase Details

### Phase 17: Title Standardization (Backend)
**Goal**: All topic naming fields (title, short_name, question_text) are consistent and canonical in the database, eliminating the source of downstream display mismatches
**Depends on**: Nothing (first phase of v1.3)
**Requirements**: TITLE-01
**Success Criteria** (what must be TRUE):
  1. Every topic in the database has a title, short_name, and question_text that are internally consistent with each other
  2. The API response for topics returns names that match what the compass labels, Library cards, and calibration cards should display
  3. No topic has a question_text that begins with "Where do you stand on" when fetched from the server
**Plans:** 2/2 plans complete

Plans:
- [ ] 17-01-PLAN.md — Draft and review standardized topic naming content (tension titles, spoke labels, custom questions) for all 21 topics
- [ ] 17-02-PLAN.md — Apply approved names to database, remove deprecated ShortName/StartPhrase columns, clean up handlers

### Phase 18: Title Display (Frontend)
**Goal**: Compass labels, Library cards, and calibration cards all render identical topic names sourced from the server, with no "Where do you stand on..." prefix visible to users
**Depends on**: Phase 17
**Requirements**: TITLE-02, TITLE-03
**Success Criteria** (what must be TRUE):
  1. Library cards display the topic name only (no "Where do you stand on..." prefix)
  2. Calibration cards display the same topic name as Library cards for the same topic
  3. Compass radar chart spoke labels match the topic names shown in Library and calibration
  4. A user scanning Library, then calibration, then the compass sees the same name for every topic in all three places
**Plans:** 2 plans

Plans:
- [ ] 18-01-PLAN.md — Add parseTensionTitle helper, clean getQuestionText fallback, update Library cards and calibration pick step with two-line tension title
- [ ] 18-02-PLAN.md — Update LibraryDrawer, CalibrationOverlay answer step, Quiz, and ComparePanel with tension titles and QuestionText placement

### Phase 19: Calibration Flow Fixes
**Goal**: The compass correctly routes users into calibration whenever they have unanswered topics, handles mixed answered/unanswered state without empty spokes, and never leaves users in a dead end when topic count drops below 3
**Depends on**: Phase 18
**Requirements**: CALIB-01, CALIB-02, CALIB-03
**Success Criteria** (what must be TRUE):
  1. A user who navigates to the compass with unanswered topics on their compass is auto-routed into calibration, starting at the first unanswered topic (not from the beginning)
  2. A user with mixed answered and unanswered topics sees a compass with no empty spokes or missing spoke positions
  3. A user whose answered topic count drops below 3 sees the calibration entry prompt instead of a dead-end "answer more topics" message
  4. A user who completes calibration from a mixed state arrives at a fully rendered compass without needing to refresh
**Plans**: TBD

### Phase 20: Compare Bug Fix
**Goal**: The comparison politician overlay renders exactly once on the radar chart, eliminating the double-shape visual artifact on the compare page
**Depends on**: Phase 19
**Requirements**: COMP-01
**Success Criteria** (what must be TRUE):
  1. Selecting a politician to compare on the radar chart produces exactly one colored overlay shape
  2. The overlay shape does not flicker, duplicate, or stack multiple transparent layers when navigating to the compare page
  3. Removing the comparison and re-adding it produces the same single clean overlay
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
| 9. Building Imagery | v1.1 | 1/1 | Complete | 2026-02-18 |
| 10. Term Dates | v1.1 | 1/1 | Complete | 2026-02-18 |
| 11. Tech Debt Cleanup | v1.2 | 1/1 | Complete | 2026-02-19 |
| 12. Quick UX Fixes | v1.2 | 2/2 | Complete | 2026-02-19 |
| 13. Topic Selection Enforcement | v1.2 | 2/2 | Complete | 2026-02-19 |
| 14. Guided Onboarding Flow | v1.2 | 4/4 | Complete | 2026-02-19 |
| 15. Help Page Update | v1.2 | 2/2 | Complete | 2026-02-19 |
| 16. Audit Bug Fixes | v1.2 | 1/1 | Complete | 2026-02-20 |
| 17. Title Standardization (Backend) | 2/2 | Complete    | 2026-02-21 | - |
| 18. Title Display (Frontend) | v1.3 | 0/2 | Not started | - |
| 19. Calibration Flow Fixes | v1.3 | 0/TBD | Not started | - |
| 20. Compare Bug Fix | v1.3 | 0/TBD | Not started | - |
