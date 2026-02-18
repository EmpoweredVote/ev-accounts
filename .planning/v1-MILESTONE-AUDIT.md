---
milestone: v1
audited: 2026-02-18T22:00:00Z
status: gaps_found
scores:
  requirements: 19/21
  phases: 5/5
  integration: 19/21
  flows: 5/6
gaps:
  requirements:
    - id: "QUIZ-01"
      status: "partial"
      phase: "Phase 4"
      claimed_by_plans: ["04-01-PLAN.md", "04-03-PLAN.md", "04-06-PLAN.md"]
      completed_by_plans: ["04-01-PLAN.md", "04-03-PLAN.md", "04-06-PLAN.md"]
      verification_status: "passed"
      evidence: "Library.jsx and ComparePanel.jsx use question_text correctly. Quiz.jsx lines 530 and 615 still render currentTopic.title instead of question_text. The quiz card heading — where users primarily encounter issues — shows the category title, not the question prompt."
    - id: "AUTH-05"
      status: "partial"
      phase: "Phase 2"
      claimed_by_plans: ["02-01-PLAN.md", "02-03-PLAN.md"]
      completed_by_plans: ["02-01-PLAN.md", "02-03-PLAN.md"]
      verification_status: "passed"
      evidence: "SavePromptModal.jsx inline registration (modal path) correctly sends guest_state to /auth/register. However, Register.jsx (standalone /register page) does not include guest_state in POST body. The save-prompt banner links to /register — guests who use the banner CTA path silently lose their localStorage answers on account creation."
  integration:
    - from: "Phase 5 candidates"
      to: "classify.js"
      issue: "CandidateOut.ChamberName declared but never populated in GetCandidatesByZip handler. classifyCategory() uses chamber_name for executive sub-type grouping. Federal/state executive candidates will misclassify as 'Executive (Other)' regardless of actual chamber."
      severity: "low"
  flows:
    - name: "Guest quiz → banner registration"
      breaks_at: "Register.jsx does not send guest_state"
      affected_requirements: ["AUTH-05"]
tech_debt:
  - phase: 03-compass-visual-fixes
    items:
      - "Commented-out old RadarChart implementation in CompassV2/src/components/RadarChart.jsx (lines 9-262) — dead code"
  - phase: 05-essentials-improvements
    items:
      - "SVG placeholder images instead of real building photographs in essentials/public/images/"
      - "CandidateOut.ChamberName not populated — affects candidate tier grouping accuracy for executive races"
  - phase: cross-phase
    items:
      - "REQUIREMENTS.md checkboxes not updated for Phases 1-3 (AUTH-01 through AUTH-06, QUIZ-04 through QUIZ-07 still show [ ] Pending despite being complete)"
      - "AUTH-02 and AUTH-03 missing from all SUMMARY frontmatter requirements-completed fields (functionally satisfied per verification but undocumented)"
      - "17 human verification items across all phases remain untested (browser-based visual/interactive checks)"
---

# v1 Milestone Audit: Empowered Vote — Quality & Consolidation

**Audited:** 2026-02-18
**Status:** gaps_found
**Score:** 19/21 requirements satisfied

## Phase Verification Summary

| Phase | Status | Score | Key Findings |
|-------|--------|-------|-------------|
| 1. Auth Safety Audit | PASSED | 3/3 | All artifacts verified. 1 human test (live DB integration) |
| 2. Guest-First Auth | PASSED | 5/5 | All success criteria verified. 6 human tests pending |
| 3. Compass Visual Fixes | PASSED | 8/8 | All code checks pass. 3 human visual tests pending |
| 4. Compass UX Enhancements | PASSED (human_needed) | 6/6 | Infinite fetch loop fixed. 3 human tests pending |
| 5. Essentials Improvements | PASSED | 16/16 | All artifacts verified. 5 human tests pending |

## 3-Source Requirements Cross-Reference

| REQ-ID | Description | VERIFICATION | SUMMARY | REQUIREMENTS.md | Integration | Final |
|--------|-------------|-------------|---------|-----------------|-------------|-------|
| AUTH-01 | Audit cookie/session configuration | passed | 01-01 | `[ ]` | wired | **satisfied** |
| AUTH-02 | Quiz without login | passed | *missing* | `[ ]` | wired | **satisfied** |
| AUTH-03 | Guest localStorage persistence | passed | *missing* | `[ ]` | wired | **satisfied** |
| AUTH-04 | Save prompt after quiz completion | passed | 02-03 | `[ ]` | wired | **satisfied** |
| AUTH-05 | Guest state merges on account creation | passed | 02-01, 02-03 | `[ ]` | **partial** | **partial** |
| AUTH-06 | Admin-only clear compass | passed | 02-01 | `[ ]` | wired | **satisfied** |
| QUIZ-01 | Question prompts on issue cards | passed | 04-01, 04-03, 04-06 | `[x]` | **partial** | **partial** |
| QUIZ-02 | Question prompts on compare page | passed | 04-03 | `[x]` | wired | **satisfied** |
| QUIZ-03 | Clickable issue cards with popup | passed | 04-05, 04-08 | `[x]` | wired | **satisfied** |
| QUIZ-04 | Compass fits without scrolling | passed | 03-01 | `[ ]` | wired | **satisfied** |
| QUIZ-05 | Title cutoff fixed | passed | 03-01 | `[ ]` | wired | **satisfied** |
| QUIZ-06 | Dashed/solid spoke distinction removed | passed | 03-02 | `[ ]` | wired | **satisfied** |
| QUIZ-07 | Help box updated | passed | 03-02 | `[ ]` | wired | **satisfied** |
| QUIZ-08 | Stance order randomized per user | passed | 04-02, 04-05 | `[x]` | wired | **satisfied** |
| QUIZ-09 | Level indicators on issue cards | passed | 04-01, 04-03, 04-06 | `[x]` | wired | **satisfied** |
| ESST-01 | Candidates with opt-in toggle | passed | 05-04, 05-05 | `[x]` | wired | **satisfied** |
| ESST-02 | Candidates visually differentiated | passed | 05-02, 05-05 | `[x]` | wired | **satisfied** |
| ESST-03 | Election date on candidate cards | passed | 05-04, 05-05 | `[x]` | wired | **satisfied** |
| ESST-04 | Building images for tiers | passed | 05-03 | `[x]` | wired | **satisfied** |
| ESST-05 | Federal section reordered | passed | 05-01 | `[x]` | wired | **satisfied** |
| ESST-06 | Term dates on profile cards | passed | 05-01, 05-03 | `[x]` | wired | **satisfied** |

## Unsatisfied Requirements

### QUIZ-01: Issue cards show question/prompt instead of category title (PARTIAL)

**Phase:** 4 — Compass UX Enhancements
**What works:** Library.jsx and ComparePanel.jsx correctly use `question_text` with fallback.
**What's broken:** Quiz.jsx lines 530 and 615 render `currentTopic.title` as the card heading in both full and curated quiz modes. The `question_text` field is in the topic context but never read by Quiz.jsx.
**Fix:** Replace `{currentTopic.title}` with `{currentTopic.question_text || currentTopic.title}` at Quiz.jsx lines 530 and 615.
**Impact:** The quiz page — where users primarily encounter and answer issue questions — shows the bare category title instead of the question prompt.

### AUTH-05: Guest localStorage state merges to server on account creation (PARTIAL)

**Phase:** 2 — Guest-First Auth
**What works:** SavePromptModal.jsx inline registration (modal path) correctly assembles `guest_state` and sends it to `POST /auth/register`. Backend RegisterHandler processes it correctly.
**What's broken:** The standalone Register.jsx page (`/register`) does not include `guest_state` in its POST body. The save-prompt banner's "Sign up" CTA links to `/register`, so guests who use the banner path silently lose their localStorage answers.
**Fix:** Import `useCompass` in Register.jsx, build `guest_state` from localStorage answers/writeIns, and include it in the registration POST body.
**Impact:** Guests who register via the banner (instead of the modal) lose all quiz answers.

## Cross-Phase Integration Issues

### CandidateOut.ChamberName Not Populated (Low)

`CandidateOut` declares `ChamberName` at `handlers.go:3615` but `GetCandidatesByZip` never assigns it. `classifyCategory()` uses `chamber_name` to discriminate executive sub-types. Federal/state executive candidates will fall through to "Executive (Other)" regardless of actual position. Functional but affects grouping accuracy.

## E2E Flow Verification

| Flow | Status | Details |
|------|--------|---------|
| Guest quiz → modal registration | COMPLETE | Guest takes quiz → results → 1.5s modal → inline register with guest_state → answers persist |
| Guest quiz → banner registration | **BROKEN** | Banner "Sign up" links to /register → Register.jsx drops guest_state → answers lost |
| Admin clear compass | COMPLETE | Admin login → profile dropdown → Clear compass → DELETE /answers/me (admin-gated) |
| Compass visual rendering | COMPLETE | Viewport sizing, label wrapping, spoke uniformity all verified |
| Library drawer with write-in | COMPLETE | Question prompts + level badges → card click → drawer → DnD write-in → persist |
| Essentials ZIP discovery | COMPLETE | ZIP → officials → federal reorder → term dates → toggle candidates → badges + election dates → building images scroll-spy |

## Tech Debt Summary

| Phase | Items |
|-------|-------|
| Phase 3 | Dead code: commented-out old RadarChart implementation (RadarChart.jsx lines 9-262) |
| Phase 5 | SVG placeholder images instead of real building photographs |
| Phase 5 | CandidateOut.ChamberName unpopulated — candidate executive grouping inaccurate |
| Cross-phase | REQUIREMENTS.md checkboxes not updated for Phases 1-3 (10 items show `[ ]` despite being complete) |
| Cross-phase | AUTH-02, AUTH-03 missing from SUMMARY frontmatter (functionally satisfied, documentation gap) |
| Cross-phase | 17 human verification items across all phases remain untested |

**Total: 6 tech debt items across 3 phases + cross-phase**

## Human Verification Items (Aggregated)

17 items across all phases require browser-based testing:

- **Phase 1:** Integration tests against live DB (1 item)
- **Phase 2:** Guest quiz flow, save prompt timing, inline registration, banner dismiss, admin visibility, guest sign-in button (6 items)
- **Phase 3:** Viewport fit, label wrapping, spoke visual uniformity (3 items)
- **Phase 4:** Write-in persistence (guest + logged-in), network tab loop check (3 items)
- **Phase 5:** Building scroll-spy, candidate badge, toggle lazy fetch, election dates, SVG rendering (5 items)

These are visual/interactive behaviors that cannot be verified from static code analysis. None are blockers — all code-level checks pass.

---

*Audited: 2026-02-18T22:00:00Z*
*Auditor: Claude (audit-milestone orchestrator)*
