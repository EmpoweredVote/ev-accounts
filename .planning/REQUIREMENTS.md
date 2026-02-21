# Requirements: Empowered Vote Platform

**Defined:** 2026-02-20
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1.3 Requirements

Requirements for Compass bug fixes and title standardization. Each maps to roadmap phases.

### Calibration Flow

- [x] **CALIB-01**: User navigating to compass with unanswered topics on their compass is auto-routed into calibration starting at the first unanswered topic
- [x] **CALIB-02**: Compass page correctly handles mixed answered/unanswered topics without showing empty spokes or dead-end states
- [x] **CALIB-03**: If user's answered topic count drops below 3, compass shows calibration entry instead of "answer more" dead end

### Title Standardization

- [x] **TITLE-01**: All topic naming (title, short_name, question_text) is standardized in the database as a single source of truth
- [x] **TITLE-02**: Library cards and calibration cards display clean topic names without "Where do you stand on..." prefix
- [x] **TITLE-03**: Topic name mismatches resolved — compass labels, Library cards, and calibration all render identically from the same server data

### Compare

- [ ] **COMP-01**: Comparison politician renders exactly one overlay shape on the radar chart (fix double overlay bug)

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Compare UX

- **COMP-02**: Compare page UX review and improvements (pending user testing)

### Tech Debt

- **DEBT-01**: BallotReady transform.go SubAreaName → RepresentingCity mapping fix
- **DEBT-02**: Settings gear placement and spoke inversion persistence across views

## Out of Scope

| Feature | Reason |
|---------|--------|
| Essentials bugs/improvements | Separate milestone — Compass-only focus for v1.3 |
| Backend-only BallotReady fixes | Deferred — frontend workaround in place |
| Full quiz mode redesign | Onboarding flow sufficient — v1.2 shipped calibration |
| Compare page UX overhaul | Needs more user testing before scoping |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TITLE-01 | Phase 17 | Complete |
| TITLE-02 | Phase 18 | Complete |
| TITLE-03 | Phase 18 | Complete |
| CALIB-01 | Phase 19 | Complete |
| CALIB-02 | Phase 19 | Complete |
| CALIB-03 | Phase 19 | Complete |
| COMP-01 | Phase 20 | Pending |

**Coverage:**
- v1.3 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0

---
*Requirements defined: 2026-02-20*
*Last updated: 2026-02-20 after roadmap creation*
