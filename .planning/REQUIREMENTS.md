# Requirements: Empowered Vote Platform

**Defined:** 2026-02-27
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1.9 Requirements

Requirements for v1.9 Compare UX & Search Fixes. Each maps to roadmap phases.

### Compare

- [x] **COMP-01**: User can switch the compared politician via an inline dropdown without reopening the full-screen modal
- [x] **COMP-02**: User can filter the politician list by state
- [x] **COMP-03**: User can filter the politician list by level (Federal / State / Local)

### Search

- [x] **SRCH-01**: Searching a city name or ZIP code returns all representatives whose districts overlap that area (not just the single geocoded point's geofences)
- [x] **SRCH-02**: Searching from the results page works correctly on the first attempt (no page refresh or double-entry required)

## v2.0 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Cross-App Integration

- **XAPP-01**: User's Essentials address search surfaces "my reps" first in Compass compare picker (via local storage or shared session)
- **XAPP-02**: Compass radar overlay displayed on Essentials politician profile pages (with guest localStorage support)
- **XAPP-03**: Read & Rank quotes and agree/disagree status shown on Essentials politician profiles

### Compare Enhancements

- **COMP-04**: User can compare themselves against 2-3 politicians simultaneously on one radar chart

## Out of Scope

| Feature | Reason |
|---------|--------|
| Cross-app session sharing | Privacy concerns; deferred until apps are unified in v2.0 |
| Multi-politician comparison overlays | UI complexity; deferred to v2.0 |
| Compass overlay on Essentials profiles | Cross-app architecture needed; v2.0 |
| Read & Rank integration on profiles | Requires cross-app architecture; v2.0 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| COMP-01 | Phase 51 | Complete |
| COMP-02 | Phase 52 | Complete |
| COMP-03 | Phase 52 | Complete |
| SRCH-01 | Phase 53 | Complete |
| SRCH-02 | Phase 53 | Complete |

**Coverage:**
- v1.9 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-27*
*Last updated: 2026-02-27 after roadmap creation (phases 51-53 assigned)*
