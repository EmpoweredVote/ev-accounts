# Requirements: Empowered Vote — Read & Rank Redesign

**Defined:** 2026-03-14
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v2026.3.6 Requirements

Requirements for the Read & Rank redesign milestone. Each maps to roadmap phases.

### Flow Redesign

- [x] **FLOW-01**: User evaluates quotes and ranks inline in a single unified phase (no separate ranking screen)
- [x] **FLOW-02**: After agreeing with 2+ quotes, user is prompted to insert new agreed quote into ranked list via drag
- [x] **FLOW-03**: Desktop shows live ranked list in sidebar during evaluation
- [x] **FLOW-04**: Mobile shows inline insert-into-list ranking between quotes after 2nd agree
- [x] **FLOW-05**: Rank order determines alignment weight (no diamond/gold badge system)
- [x] **FLOW-06**: Zustand store migrated to version 2 with clean-reset for returning users

### Onboarding

- [x] **ONBD-01**: First-time users see a practice round with pizza topping quotes before real issues
- [x] **ONBD-02**: Practice round teaches swipe agree/disagree and insert-into-list ranking mechanics
- [x] **ONBD-03**: Practice round verdicts never reach backend or fragment encoder
- [x] **ONBD-04**: User can skip practice round; skip cleans up all partial practice state
- [ ] **ONBD-05**: Coach marks spotlight key UI elements on first real issue (swipe area, rank panel)
- [x] **ONBD-06**: Coach marks permanently dismissed after first completion via store flag

### Location Filtering

- [ ] **LOC-01**: Hub page has optional address input using Google Maps Places autocomplete
- [ ] **LOC-02**: When address provided, only issues with quotes from user's representatives are shown
- [ ] **LOC-03**: Issues with fewer than 2 quotes from local reps are hidden from hub
- [ ] **LOC-04**: Cross-app context: if user arrives from Essentials with address context, auto-apply filter
- [ ] **LOC-05**: User can clear location filter to see all issues

### Results

- [ ] **RSLT-01**: Results cards are visually cleaner with less information density per card
- [ ] **RSLT-02**: "Who said it" reveal has a dramatic staggered animation moment
- [ ] **RSLT-03**: "View on Essentials" is the primary CTA on result cards
- [ ] **RSLT-04**: CandidateAlignmentPage stays in ReadRank with visual polish matching new design

### Chrome & Design

- [x] **CHRM-01**: ProgressHeader removed entirely
- [x] **CHRM-02**: AnimationOptionsPage and /animation-options route removed
- [x] **CHRM-03**: Reset functionality moved to account/profile menu (matching Compass pattern)
- [ ] **CHRM-04**: Visual redesign applied across all components (revert editorial WIP, design from scratch)

## Future Requirements

### Cross-App Integration

- **XAPP-01**: Read & Rank alignment data surfaced on Essentials politician profiles
- **XAPP-02**: "My reps" surfacing on Compass compare page

### Advanced Features

- **ADV-01**: Multi-issue summary / cross-issue alignment score
- **ADV-02**: Share results card / social sharing
- **ADV-03**: Pairwise compare as alternative ranking mechanic

## Out of Scope

| Feature | Reason |
|---------|--------|
| Backend endpoint changes | Client-side filtering sufficient at current data scale (~61 quotes) |
| Multi-politician comparison | Separate milestone scope |
| Social sharing / image generation | Infrastructure complexity not justified |
| Pairwise compare ranking | Future experiment; insert-into-list is v1 |
| ev-ui CoachMark publish | Single consumer; copy + TS port simpler |
| IP-based geolocation | Privacy concerns; explicit address input preferred |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FLOW-06 | Phase 86 | Complete |
| CHRM-01 | Phase 86 | Complete |
| CHRM-02 | Phase 86 | Complete |
| CHRM-03 | Phase 86 | Complete |
| FLOW-01 | Phase 87 | Complete |
| FLOW-02 | Phase 87 | Complete |
| FLOW-03 | Phase 87 | Complete |
| FLOW-04 | Phase 87 | Complete |
| FLOW-05 | Phase 87 | Complete |
| ONBD-01 | Phase 88 | Complete |
| ONBD-02 | Phase 88 | Complete |
| ONBD-03 | Phase 88 | Complete |
| ONBD-04 | Phase 88 | Complete |
| ONBD-05 | Phase 89 | Pending |
| ONBD-06 | Phase 89 | Complete |
| LOC-01 | Phase 90 | Pending |
| LOC-02 | Phase 90 | Pending |
| LOC-03 | Phase 90 | Pending |
| LOC-04 | Phase 90 | Pending |
| LOC-05 | Phase 90 | Pending |
| RSLT-01 | Phase 91 | Pending |
| RSLT-02 | Phase 91 | Pending |
| RSLT-03 | Phase 91 | Pending |
| RSLT-04 | Phase 91 | Pending |
| CHRM-04 | Phase 91 | Pending |

**Coverage:**
- v2026.3.6 requirements: 25 total
- Mapped to phases: 25
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-14*
*Last updated: 2026-03-14 — traceability updated with phase numbers 86-91*
