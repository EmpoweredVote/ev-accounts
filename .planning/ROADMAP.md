# Roadmap: Empowered Vote

## Milestones

- ✅ **v1.0 Quality & Consolidation** — Phases 1-7 (shipped 2026-02-18)
- ✅ **v1.1 Essentials UX Polish** — Phases 8-10 (shipped 2026-02-19)
- 🚧 **v1.2 Compass Onboarding & UX** — Phases 11-15 (in progress)

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

### 🚧 v1.2 Compass Onboarding & UX (In Progress)

**Milestone Goal:** Make the compass quiz intuitive for first-time users with guided onboarding, and fix UX issues that create friction.

- [x] **Phase 11: Tech Debt Cleanup** - Remove dead code, align dependency versions, consolidate duplicated helpers (completed 2026-02-19)
- [x] **Phase 12: Quick UX Fixes** - Fix Library default filter and update question framing across all topics (completed 2026-02-19)
- [ ] **Phase 13: Topic Selection Enforcement** - Cap compass at 8 topics, enforce 3-topic minimum, add on-compass visual indicators to Library cards
- [ ] **Phase 14: Guided Onboarding Flow** - Replace "Start Quiz" with calibration overlay and guided card-by-card onboarding with live compass rendering
- [ ] **Phase 15: Help Page Update** - Update /help to reflect the new guided onboarding and drawer-based flow

## Phase Details

### Phase 11: Tech Debt Cleanup
**Goal**: Codebase is clean — dead code removed, dependency versions aligned, duplicated strings consolidated
**Depends on**: Nothing (first v1.2 phase)
**Requirements**: DEBT-01, DEBT-02, DEBT-03
**Success Criteria** (what must be TRUE):
  1. RadarChart.jsx no longer contains the commented-out block (lines 9-263 removed)
  2. CompassV2 package.json pins ev-ui at ^0.1.19, matching essentials
  3. question_text fallback string exists in exactly one place in the codebase and is imported wherever needed
**Plans**: 1 plan
- [ ] 11-01-PLAN.md — Remove dead code, update ev-ui version, consolidate question_text fallback

### Phase 12: Quick UX Fixes
**Goal**: Library opens showing all topics by default, and question framing is clear and consistent
**Depends on**: Phase 11
**Requirements**: LIBR-01, QFRM-01, QFRM-02
**Success Criteria** (what must be TRUE):
  1. User opens Library and sees all topics without toggling any filter
  2. Every issue card displays "Where do you stand on [topic]?" as the framing prompt
  3. Formerly vague topic titles read as specific, answerable questions in the new framing
**Plans**: 2 plans
- [ ] 12-01-PLAN.md — Add short_name backend field, update question framing, replace Library checkbox with toggle switch
- [ ] 12-02-PLAN.md — Draft and apply topic title rewrites (with user approval checkpoint)

### Phase 13: Topic Selection Enforcement
**Goal**: Users cannot over-fill or under-use the compass — limits are enforced everywhere, and Library cards show current compass status
**Depends on**: Phase 12
**Requirements**: TSEL-01, TSEL-02, TSEL-03
**Success Criteria** (what must be TRUE):
  1. User with 8 topics on the compass cannot add a ninth via the Library drawer, onboarding, or quiz — the add action is disabled or blocked
  2. Compass page does not render the chart until the user has at least 3 answered topics
  3. A Library card for a topic already on the compass shows a visual indicator (e.g., checkmark or "On compass" label) distinguishable from cards not yet added
  4. User can remove a topic from the compass directly from its Library card
**Plans**: 2 plans
- [ ] 13-01-PLAN.md — Library page: counter badge, on-compass card indicators, add/remove toggle with confirmation popover, cap enforcement
- [ ] 13-02-PLAN.md — Compass page: 3-topic minimum with progress dots, drawer remove action, AddTopicModal cap enforcement

### Phase 14: Guided Onboarding Flow
**Goal**: A first-time user arriving at an empty compass is guided through topic selection one card at a time, with the compass rendering live as they answer
**Depends on**: Phase 13
**Requirements**: ONBD-01, ONBD-02, ONBD-03, ONBD-04, LIBR-02
**Success Criteria** (what must be TRUE):
  1. User with no compass data sees a "Calibrate your Compass" overlay on the compass page, not a blank chart
  2. Activating the overlay presents topic cards one at a time with stance selection, and the compass behind updates in real time after each answer
  3. After answering 3 topics, user can exit the guided flow and land on a usable compass — or continue up to 8
  4. After completing or exiting onboarding, user is on the compass page with all answered topics displayed
  5. "Start Quiz" fixed bottom button is absent from the Library page — the overlay on the compass serves this entry point
**Plans**: TBD

### Phase 15: Help Page Update
**Goal**: The /help page accurately describes how the compass and Library work after v1.2 changes
**Depends on**: Phase 14
**Requirements**: ONBD-05
**Success Criteria** (what must be TRUE):
  1. /help page describes the "Calibrate your Compass" onboarding overlay as the starting point for new users
  2. /help page references the drawer-based Library flow (no mention of obsolete "Start Quiz" button)
  3. Instructions on /help match the actual UI — a first-time user reading the page can follow along without confusion
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
| 11. Tech Debt Cleanup | 1/1 | Complete    | 2026-02-19 | - |
| 12. Quick UX Fixes | 2/2 | Complete    | 2026-02-19 | - |
| 13. Topic Selection Enforcement | 1/2 | In Progress|  | - |
| 14. Guided Onboarding Flow | v1.2 | 0/TBD | Not started | - |
| 15. Help Page Update | v1.2 | 0/TBD | Not started | - |
