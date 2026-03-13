# Requirements: Empowered Vote Platform

**Defined:** 2026-03-12
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v2026.3.5 Requirements

### Navigation (ev-ui SiteHeader)

- [x] **NAV-01**: User sees production `.empowered.vote` URLs for all three apps in the SiteHeader Features dropdown (compass, essentials, readrank)

### Essentials Header

- [x] **ESS-01**: User sees SiteHeader at the top of every Essentials page (Landing, Results, Profile, LegislativeRecord, CandidateProfile)
- [x] **ESS-02**: Logged-in user sees their username in the Essentials header with a logout option
- [x] **ESS-03**: Logged-out user sees a "Sign in" link in the Essentials header that navigates to Compass login
- [x] **ESS-04**: User can log out from Essentials — session is cleared and page resets to logged-out state

### ReadRank Header

- [x] **RR-01**: Logged-in user sees their username in the ReadRank header with a logout option
- [x] **RR-02**: Logged-out user sees a "Sign in" link in the ReadRank header that navigates to Compass login
- [x] **RR-03**: User can log out from ReadRank — session is cleared

## Future Requirements

### Local Government Display

- **LOCAL-01**: County council at-large vs district members distinguished in display (carried from v2026.3.3)
- **LOCAL-02**: State-configurable body structure for California Board of Supervisors (carried from v2026.3.3)
- **LOCAL-03**: LA County bodies seeded with official website URLs (carried from v2026.3.3)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Login page in Essentials or ReadRank | Login lives on Compass only; sign in links navigate there |
| Logout redirect to Compass | Each app stays on its own page/resets locally |
| Header customization per-app | Consistent branding is the goal; Compass model is used as-is |
| Mobile nav drawer changes | Existing SiteHeader mobile behavior unchanged |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| NAV-01 | Phase 83 | Complete |
| ESS-01 | Phase 84 | Complete |
| ESS-02 | Phase 84 | Complete |
| ESS-03 | Phase 84 | Complete |
| ESS-04 | Phase 84 | Complete |
| RR-01 | Phase 85 | Complete |
| RR-02 | Phase 85 | Complete |
| RR-03 | Phase 85 | Complete |

**Coverage:**
- v2026.3.5 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-12*
*Last updated: 2026-03-12 after roadmap creation (v2026.3.5)*
