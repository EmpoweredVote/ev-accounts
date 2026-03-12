# Requirements: Empowered Vote Platform

**Defined:** 2026-03-11
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v2026.3.4 Requirements

Requirements for Read & Rank Integration milestone. Each maps to roadmap phases.

### App Extraction

- [x] **EXTR-01**: Read & Rank extracted to standalone GitHub repo (`ev-readrank` or similar)
- [x] **EXTR-02**: Read & Rank deployed to `readrank.empowered.vote` on Cloudflare Pages with SPA routing
- [x] **EXTR-03**: Backend CORS allowlist updated to include `readrank.empowered.vote`
- [x] **EXTR-04**: ev-ui dependency updated from ^0.1.6 to current ^0.1.41
- [x] **EXTR-05**: Zustand persist key namespaced with migration from old key

### Visual Design

- [x] **DSGN-01**: Read & Rank hub/landing page styled with EV brand (ev-coral, ev-muted-blue, Manrope)
- [x] **DSGN-02**: QuoteCard and swipe UI visually polished to match platform design language
- [x] **DSGN-03**: ResultsPhase layout refreshed with card-based design matching CompassV2/Essentials

### Verdict Storage

- [x] **VERD-01**: `compass.quote_verdicts` table created with (user_id, quote_id) unique constraint
- [x] **VERD-02**: POST /compass/verdicts endpoint for bulk upsert (authenticated)
- [x] **VERD-03**: GET /compass/verdicts endpoint for current user's verdicts (authenticated)
- [x] **VERD-04**: GET /essentials/quotes filtered by politician_id (extends existing endpoint)
- [x] **VERD-05**: Guest verdict fragment encoding in URL when navigating to Essentials
- [ ] **VERD-06**: Essentials reads and caches guest verdicts from URL fragment to localStorage

### Profile Integration

- [ ] **PROF-01**: CompassContext extended with verdicts state field (priority: API > fragment > localStorage)
- [x] **PROF-02**: StanceAccordion displays agree/disagree verdict badges inline under each topic
- [x] **PROF-03**: ev-ui updated to v0.1.42+ with verdict badge prop on StanceAccordion
- [x] **PROF-04**: "View on Essentials" CTA in Read & Rank results linking to politician profile with verdict fragment

### Cross-App Sync

- [ ] **SYNC-01**: Read & Rank POSTs verdicts to backend when user is logged in
- [ ] **SYNC-02**: Essentials fetches logged-in user's verdicts from backend as highest-priority source

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Profile Enhancements

- **PROF-05**: "Explore this topic on Read & Rank" deep-link from StanceAccordion with ?topic= pre-selection
- **PROF-06**: Verdict history view ("all quotes I evaluated for this politician")
- **PROF-07**: Read & Rank progress indicator across all issues on Essentials profile

### Guest Persistence

- **GUST-01**: Persistent guest verdict storage via iframe relay at shared.empowered.vote
- **GUST-02**: Retire URL fragment compass bridge once shared mechanism verified

### Local Government (carried from v2026.3.3)

- **BODY-01**: County council at-large vs district members distinguished in display
- **BODY-02**: State-configurable body structure for California Board of Supervisors
- **BODY-03**: LA County bodies seeded with official website URLs

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Real-time cross-tab verdict sync | Zero practical value — users don't have both apps open simultaneously |
| Aggregated verdict analytics | Contradicts anti-partisan mission — verdicts must stay private and personal |
| Full politician profile inside Read & Rank | Duplicates Essentials; link to Essentials profile instead |
| Automatic verdict migration from EV-prototypes origin | Impossible — different origin, no cookie sharing, zero user overlap |
| Verdict-weighted compass alignment score | Mixing quotes with stance data produces unreliable hybrid — keep separate |
| Cross-device verdict sync for guests | Requires account creation or device-linking; out of scope until demand proven |
| iframe postMessage relay for guest storage | Fragile, Safari ITP issues; URL fragment bridge sufficient for MVP |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| EXTR-01 | Phase 77 | Complete |
| EXTR-02 | Phase 77 | Complete |
| EXTR-03 | Phase 77 | Complete |
| EXTR-04 | Phase 77 | Complete |
| EXTR-05 | Phase 77 | Complete |
| DSGN-01 | Phase 78 | Complete |
| DSGN-02 | Phase 78 | Complete |
| DSGN-03 | Phase 78 | Complete |
| VERD-01 | Phase 79 | Complete |
| VERD-02 | Phase 79 | Complete |
| VERD-03 | Phase 79 | Complete |
| VERD-04 | Phase 79 | Complete |
| PROF-03 | Phase 80 | Complete |
| VERD-05 | Phase 81 | Complete |
| VERD-06 | Phase 81 | Pending |
| PROF-01 | Phase 81 | Pending |
| PROF-02 | Phase 81 | Complete |
| PROF-04 | Phase 81 | Complete |
| SYNC-01 | Phase 82 | Pending |
| SYNC-02 | Phase 82 | Pending |

**Coverage:**
- v2026.3.4 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-11*
*Last updated: 2026-03-11 after roadmap creation*
