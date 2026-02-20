# Requirements: Empowered Vote Platform

**Defined:** 2026-02-18
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1.2 Requirements

Requirements for Compass Onboarding & UX milestone. Each maps to roadmap phases.

### Onboarding

- [x] **ONBD-01**: First-time user sees a "Calibrate your Compass" overlay on the empty compass page instead of the "Start Quiz" button at the bottom of Library
- [x] **ONBD-02**: Guided onboarding presents topic cards one at a time with stance selection, and the compass renders in real time as each topic is answered
- [x] **ONBD-03**: User can stop the guided flow after answering 3 topics (compass is usable) or continue up to 8
- [x] **ONBD-04**: After onboarding completes, user lands on their compass with all answered topics displayed
- [x] **ONBD-05**: `/help` onboarding page is updated to reflect the new drawer-based flow and guided onboarding

### Topic Selection

- [x] **TSEL-01**: User cannot add more than 8 topics to the compass via any path (drawer, onboarding, or quiz)
- [x] **TSEL-02**: User needs at least 3 answered topics before the compass renders meaningfully
- [x] **TSEL-03**: Topic cards in Library show a clear visual indicator when the topic is on the compass, with a way to remove it

### Library UX

- [x] **LIBR-01**: Library page defaults to showing all topics (not "unanswered only")
- [x] **LIBR-02**: "Start Quiz" fixed bottom button is removed/replaced by the onboarding overlay on the compass

### Question Framing

- [x] **QFRM-01**: Default question framing changes from "What should the government do about..." to "Where do you stand on [topic]?"
- [x] **QFRM-02**: Content pass on topic titles that are too vague for the new framing (e.g., "Misinformation" becomes more descriptive)

### Tech Debt

- [x] **DEBT-01**: RadarChart.jsx dead code block (lines 9-263) is removed
- [x] **DEBT-02**: CompassV2 ev-ui version pin updated from ^0.1.16 to ^0.1.19
- [x] **DEBT-03**: Duplicated question_text fallback string consolidated into a shared helper

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Content & Data

- **DATA-01**: More topics added to compass question bank
- **DATA-02**: More politicians available for comparison on compass
- **DATA-03**: Richer stance data from BallotReady surfaced in compass comparison

### Results Experience

- **RSLT-01**: Shareable compass results (link or image)
- **RSLT-02**: Save/bookmark compass results
- **RSLT-03**: Compare compass results across time

## Out of Scope

| Feature | Reason |
|---------|--------|
| Mobile native app | Web-first, mobile later |
| Full quiz mode redesign | Only onboarding flow for this milestone; full quiz mode stays as-is |
| Topic content creation | This milestone improves framing of existing topics, not creating new ones |
| Backend API changes | All changes are frontend-only in CompassV2 |
| Politician comparison UX | Out of scope — focus is on getting users to their first compass |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEBT-01 | Phase 11 | Complete |
| DEBT-02 | Phase 11 | Complete |
| DEBT-03 | Phase 11 | Complete |
| LIBR-01 | Phase 12 | Complete |
| QFRM-01 | Phase 12 | Complete |
| QFRM-02 | Phase 12 | Complete |
| TSEL-01 | Phase 13 | Complete |
| TSEL-02 | Phase 13 | Complete |
| TSEL-03 | Phase 13 | Complete |
| ONBD-01 | Phase 14 | Complete |
| ONBD-02 | Phase 14 | Complete |
| ONBD-03 | Phase 14 | Complete |
| ONBD-04 | Phase 14 | Complete |
| LIBR-02 | Phase 14 | Complete |
| ONBD-05 | Phase 15 | Complete |

**Coverage:**
- v1.2 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

---
*Requirements defined: 2026-02-18*
*Last updated: 2026-02-18 after roadmap creation*
