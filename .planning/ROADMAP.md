# Roadmap: Empowered Vote — Quality & Consolidation

## Overview

Five phases that harden the auth foundation, open the compass to guests, fix visual regressions, enrich the compass UX with question context and stance randomization, then surface candidate data and display improvements in Essentials. Each phase delivers a coherent, testable capability before the next begins. The result is a platform that runs without login friction, renders correctly across screen sizes, and gives voters clear context about their elected officials and candidates.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Auth Safety Audit** - Verify cookie/session config is stable before any auth model changes
- [ ] **Phase 2: Guest-First Auth** - Users take the full quiz without logging in; admin controls tightened
- [ ] **Phase 3: Compass Visual Fixes** - Fix sizing, title clipping, and spoke visual artifacts
- [x] **Phase 4: Compass UX Enhancements** - Question prompts, stance randomization, interactive issue cards, level indicators
- [ ] **Phase 5: Essentials Improvements** - Candidate display, building imagery, federal reordering, position dates

## Phase Details

### Phase 1: Auth Safety Audit
**Goal**: The existing auth flow is confirmed safe before any session/cookie changes ship
**Depends on**: Nothing (first phase)
**Requirements**: AUTH-01
**Success Criteria** (what must be TRUE):
  1. A developer can log in, stay logged in across tab reloads, and log out without any changes to behavior from current production
  2. Cookie configuration is documented — domain, SameSite, Secure, and HttpOnly settings are written down with a note on what changes before domain goes live
  3. All Chi routes are categorized as public, guest-ok, or auth-required in a written audit so guest auth work has a clear contract
**Plans**: 1 plan

Plans:
- [ ] 01-01-PLAN.md — Middleware unit tests, auth integration tests, and auth audit document with route manifest and Phase 2 handoff

### Phase 2: Guest-First Auth
**Goal**: Users can use the compass fully without creating an account, and admin controls are correctly gated
**Depends on**: Phase 1
**Requirements**: AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06
**Success Criteria** (what must be TRUE):
  1. A user who has never logged in can open the compass, answer questions, and see their radar chart without being redirected to login
  2. A guest who closes the browser and returns sees their previous answers already populated (localStorage persistence)
  3. After a guest completes the quiz, a save prompt appears — not a login gate before viewing results
  4. When a guest creates an account, their answers carry over to the new account (server-wins if account already had answers)
  5. "Clear compass" is not visible to regular users — it appears only in the profile dropdown for admin accounts
**Plans**: 3 plans

Plans:
- [ ] 02-01-PLAN.md — Backend: RegisterHandler accepts guest_state, auto-login on register, DELETE /compass/answers/me (admin-only)
- [ ] 02-02-PLAN.md — Frontend: CompassContext localStorage-first, route ungating, Quiz/Compass server call guards, Layout guest indicator + admin clear
- [ ] 02-03-PLAN.md — Frontend: Save prompt modal with inline registration, banner nudge, Login.jsx server-wins merge toast

### Phase 3: Compass Visual Fixes
**Goal**: The compass visualization renders correctly at all viewport sizes with no visual artifacts from spoke inversion
**Depends on**: Phase 1
**Requirements**: QUIZ-04, QUIZ-05, QUIZ-06, QUIZ-07
**Success Criteria** (what must be TRUE):
  1. On a standard laptop browser (1280px wide), the full compass chart fits on screen without any vertical scroll
  2. Long issue titles do not push the chart to the left or cause any label clipping at the chart edge
  3. Inverted spokes and non-inverted spokes look identical — no dashed/solid line difference is visible
  4. The help box contains no references to dashed or solid lines
**Plans**: 2 plans

Plans:
- [ ] 03-01-PLAN.md — Fix compass chart viewport sizing (max-height constraint) and label overflow (2-line cap + font-size fallback); publish ev-ui 0.1.15
- [ ] 03-02-PLAN.md — Remove dashed/solid spoke visual distinction from RadarChartCore; remove help box legend from SpokeHint; publish ev-ui 0.1.16

### Phase 4: Compass UX Enhancements
**Goal**: Issue cards and the compass show meaningful question prompts, stances arrive in a stable randomized order per user, and users can edit answers inline from the library
**Depends on**: Phase 2 (stance seed from guest identity), Phase 3 (visual fixes landed)
**Requirements**: QUIZ-01, QUIZ-02, QUIZ-03, QUIZ-08, QUIZ-09
**Success Criteria** (what must be TRUE):
  1. Every issue card and the compare page show a question or prompt (e.g., "What should the government do about X?") instead of a bare category title
  2. The order of stances on an issue is flipped or not-flipped permanently for each user — it never changes between sessions for the same user on the same issue
  3. A user on the Library page can click any issue card and see a popup with the question, all stances, their current selection highlighted, and can change their selection without navigating away
  4. Each issue card shows a badge or label indicating whether the issue is federal, state, or local in scope
**Plans**: 8 plans

Plans:
- [x] 04-01-PLAN.md — Backend: add question_text + level columns to compass.topics; extend PATCH handler; admin TopicEditor textarea + dropdown
- [x] 04-02-PLAN.md — Frontend: seeded stance randomization using guestId + topicId hash (replaces Math.random); both quiz modes
- [x] 04-03-PLAN.md — Frontend: question text as card primary label + ComparePanel header + level badges on Library cards
- [x] 04-04-PLAN.md — Frontend: slide-in drawer on Library cards for inline answer editing with instant save
- [x] 04-05-PLAN.md — Gap closure: fix LibraryDrawer crash (null stances) + Quiz.jsx stance flip rendering
- [x] 04-06-PLAN.md — Gap closure: multi-select level (string to array) + admin save persistence fix + Library badge array rendering
- [x] 04-07-PLAN.md — Gap closure: guest Library visibility fix + drawer answer state hydration after login
- [x] 04-08-PLAN.md — Gap closure: LibraryDrawer write-in stance support with drag-to-position

### Phase 5: Essentials Improvements
**Goal**: Voters can optionally see candidates alongside officials, the federal section is ordered correctly, and profiles show position dates and building imagery
**Depends on**: Phase 1
**Requirements**: ESST-01, ESST-02, ESST-03, ESST-04, ESST-05, ESST-06
**Success Criteria** (what must be TRUE):
  1. By default, Essentials shows only elected officials; a toggle reveals candidates who are running for office in the same results
  2. Candidate cards are visually distinct from official cards — a badge or label makes the distinction unmistakable
  3. Candidate cards show the election date for the race they are running in
  4. The federal section shows U.S. Senate and U.S. House before executive branch officials (President/VP, Cabinet, Agencies)
  5. A politician's profile card shows their position start date and, where known, their end date
  6. Section headers for federal, state, and local tiers show a relevant building image (U.S. Capitol, state capitol, local city hall)
**Plans**: 5 plans

Plans:
- [ ] 05-01-PLAN.md — Federal category reorder in classify.js + backend term dates (valid_from/valid_to) in OfficialOut DTO
- [ ] 05-02-PLAN.md — ev-ui PoliticianCard badge prop + publish 0.1.17
- [ ] 05-03-PLAN.md — Frontend term date rendering on cards + building images with scroll-spy in Results.jsx
- [ ] 05-04-PLAN.md — Backend GET /essentials/candidates/{zip} endpoint with BallotReady races query + CandidateOut DTO
- [ ] 05-05-PLAN.md — Frontend candidate toggle, badge rendering, election date display in Results.jsx

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5
Note: Phase 3 depends only on Phase 1 and can run in parallel with Phase 2 if two developers are available.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Auth Safety Audit | 0/1 | Not started | - |
| 2. Guest-First Auth | 0/3 | Not started | - |
| 3. Compass Visual Fixes | 0/2 | Not started | - |
| 4. Compass UX Enhancements | 8/8 | Complete | 2026-02-18 |
| 5. Essentials Improvements | 4/5 | In Progress|  |
