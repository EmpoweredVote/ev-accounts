# Requirements: Empowered Vote Platform

**Defined:** 2026-02-22
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1.4 Requirements

Requirements for compass polish, bug fixes, and tech debt cleanup. Each maps to roadmap phases.

### Guest Flow

- [x] **GUEST-01**: Guest user clicking "View Full Compass" sees the full radar chart using localStorage answers (no 401 error)
- [x] **GUEST-02**: Guest user completing the full quiz is routed to a working completion/compass page (no blank screen)

### Radar Chart Labels

- [x] **LABEL-01**: Radar chart labels on the far left and far right edges are not clipped by the container
- [x] **LABEL-02**: Short single-word labels (Misinformation, Immigration, Medicare/Medicaid) render at a readable minimum font size
- [x] **LABEL-03**: Multi-word labels that wrap (e.g., "AI Regulation") display all words without truncation

### UX Cleanup

- [x] **UX-01**: "Edit Topics" button removed from the compass page — users edit topics via the Library
- [x] **UX-02**: "Clear" button removed from the Library page
- [x] **UX-03**: Answered/Remaining stat cards on the Library page fill full width on mobile screens
- [x] **UX-04**: QuestionText is more visually prominent on LibraryDrawer and stance selection views (larger size, closer to title weight)

### Tech Debt

- [x] **DEBT-01**: compassimport/models.go no longer references dropped StartPhrase column
- [x] **DEBT-02**: cmd/seed/compass_csv_seeder.go no longer references StartPhrase/start_phrase
- [x] **DEBT-03**: Admin TopicEditor no longer sends vestigial short_name field in PATCH body
- [x] **DEBT-04**: Admin TopicAccordion no longer initializes vestigial editedFields.short_name

### Onboarding & Topic Display

- [x] **ONBOARD-01**: Topic/issue cards display correctly across all compass views (Library, CalibrationOverlay pick step, Quiz) — regression from recent changes fixed
- [ ] **ONBOARD-02**: After completing onboarding (/help), user is redirected to calibration flow (not /results)
- [ ] **ONBOARD-03**: After calibration completes (3+ topics answered), user arrives at /results with their radar chart
- [ ] **ONBOARD-04**: Back button during calibration navigates within calibration steps only — does not exit to onboarding or Library

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Compare UX

- **COMP-02**: Compare page UX review and improvements (pending user testing)

### Infrastructure

- **INFRA-01**: BallotReady transform.go SubAreaName → RepresentingCity mapping fix (frontend workaround in place)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Essentials bugs/improvements | Separate milestone — Compass-only focus for v1.4 |
| Full quiz mode redesign | Onboarding flow sufficient — v1.2 shipped calibration |
| Compare page UX overhaul | Needs more user testing before scoping |
| BallotReady RepresentingCity fix | Frontend workaround in Results.jsx works — low priority |
| New features or capabilities | v1.4 is polish and cleanup only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| GUEST-01 | Phase 21 | Complete |
| GUEST-02 | Phase 21 | Complete |
| LABEL-01 | Phase 22 | Complete |
| LABEL-02 | Phase 22 | Complete |
| LABEL-03 | Phase 22 | Complete |
| UX-01 | Phase 23 | Complete |
| UX-02 | Phase 23 | Complete |
| UX-03 | Phase 23 | Complete |
| UX-04 | Phase 23 | Complete |
| DEBT-01 | Phase 24 | Complete |
| DEBT-02 | Phase 24 | Complete |
| DEBT-03 | Phase 24 | Complete |
| DEBT-04 | Phase 24 | Complete |
| ONBOARD-01 | Phase 25 | Complete |
| ONBOARD-02 | Phase 25 | Pending |
| ONBOARD-03 | Phase 25 | Pending |
| ONBOARD-04 | Phase 25 | Pending |

**Coverage:**
- v1.4 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0

---
*Requirements defined: 2026-02-22*
*Last updated: 2026-02-22 after Phase 25 onboarding/topic display fix requirements added*
