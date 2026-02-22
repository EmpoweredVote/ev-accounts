# Requirements: Empowered Vote Platform

**Defined:** 2026-02-22
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1.4 Requirements

Requirements for compass polish, bug fixes, and tech debt cleanup. Each maps to roadmap phases.

### Guest Flow

- [x] **GUEST-01**: Guest user clicking "View Full Compass" sees the full radar chart using localStorage answers (no 401 error)
- [x] **GUEST-02**: Guest user completing the full quiz is routed to a working completion/compass page (no blank screen)

### Radar Chart Labels

- [ ] **LABEL-01**: Radar chart labels on the far left and far right edges are not clipped by the container
- [ ] **LABEL-02**: Short single-word labels (Misinformation, Immigration, Medicare/Medicaid) render at a readable minimum font size
- [ ] **LABEL-03**: Multi-word labels that wrap (e.g., "AI Regulation") display all words without truncation

### UX Cleanup

- [ ] **UX-01**: "Edit Topics" button removed from the compass page — users edit topics via the Library
- [ ] **UX-02**: "Clear" button removed from the Library page
- [ ] **UX-03**: Answered/Remaining stat cards on the Library page fill full width on mobile screens
- [ ] **UX-04**: QuestionText is more visually prominent on LibraryDrawer and stance selection views (larger size, closer to title weight)

### Tech Debt

- [ ] **DEBT-01**: compassimport/models.go no longer references dropped StartPhrase column
- [ ] **DEBT-02**: cmd/seed/compass_csv_seeder.go no longer references StartPhrase/start_phrase
- [ ] **DEBT-03**: Admin TopicEditor no longer sends vestigial short_name field in PATCH body
- [ ] **DEBT-04**: Admin TopicAccordion no longer initializes vestigial editedFields.short_name

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
| LABEL-01 | Phase 22 | Pending |
| LABEL-02 | Phase 22 | Pending |
| LABEL-03 | Phase 22 | Pending |
| UX-01 | Phase 23 | Pending |
| UX-02 | Phase 23 | Pending |
| UX-03 | Phase 23 | Pending |
| UX-04 | Phase 23 | Pending |
| DEBT-01 | Phase 24 | Pending |
| DEBT-02 | Phase 24 | Pending |
| DEBT-03 | Phase 24 | Pending |
| DEBT-04 | Phase 24 | Pending |

**Coverage:**
- v1.4 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-02-22*
*Last updated: 2026-02-22 after Phase 21 guest flow fix — GUEST-01, GUEST-02 complete*
