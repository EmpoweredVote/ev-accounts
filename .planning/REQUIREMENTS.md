# Requirements: Empowered Vote

**Defined:** 2026-04-03
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v2026.4.1 Requirements

Requirements for Essentials Visual Polish & Election Improvements milestone.

### Data Fixes

- [x] **DATA-01**: Incumbent marker removed from all candidate cards on election page
- [x] **DATA-02**: Ruben Marte candidate record linked to politician profile (fix accent mark mismatch)
- [x] **DATA-03**: Headshot images display with face-centered cropping via CSS object-position
- [x] **DATA-04**: Headshot audit script scans all CDN images and flags badly cropped photos

### Visual Design

- [x] **VIS-01**: Election and representatives pages use tier-level visual differentiation (hue, background pattern, or combination) for Federal/State/Local and sub-tiers
- [x] **VIS-02**: Politician cards display small subtle icons for metadata (on ballot, compass available, branch type) replacing large badges
- [x] **VIS-03**: Icon set evaluated and selected to fit EV design system (subtle, readable, secondary)
- [x] **VIS-04**: Election page information hierarchy improved — race/position structure clearer, party ballot groupings less visually noisy
- [x] **VIS-05**: Icons provide additional detail on hover (desktop) and tap (mobile) — accessible per WCAG

### Landing & Navigation

- [x] **NAV-01**: Landing page explicitly displays coverage areas (Monroe County, IN and Los Angeles County, CA)
- [x] **NAV-02**: Landing page has prominent location shortcut buttons that navigate to pre-loaded representative results

### Prototype

- [x] **PROTO-01**: Standalone /prototype route showing compass-first politician cards with real representative data
- [x] **PROTO-02**: Prototype uses hardcoded mock compass data to demonstrate full vision without database changes

## Future Requirements

Deferred to future milestone. Tracked but not in current roadmap.

### Compass-First Rollout

- **COMP-01**: Compass-first card view as toggle option on representatives page
- **COMP-02**: Compass-first card as default view (requires sufficient stance data coverage)

### Carried Forward

- **PROF-04**: Compass stance data imports for candidates (deferred from v2026.3.8)
- **PROF-05**: Sourced quote imports for candidates (deferred from v2026.3.8)
- County council at-large vs district members distinguished in display (carried from v2026.3.3)
- State-configurable body structure for California Board of Supervisors (carried from v2026.3.3)
- LA County bodies seeded with official website URLs (carried from v2026.3.3)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Full compass-first rollout | Prototype first — evaluate before committing to default view |
| Image re-upload / CDN migration | CSS fix handles cropping; re-upload only if audit finds unfixable source images |
| New icon library dependency (if inline SVG suffices) | Research may conclude inline SVG is sufficient for 3-4 icons |
| Party color coding on election page | Antipartisan principle — never use partisan color associations |
| Browse-by-location for uncovered areas | Only Monroe County IN and LA County CA have data |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | Phase 102 | Complete |
| DATA-02 | Phase 102 | Complete |
| DATA-03 | Phase 102 | Complete |
| VIS-03 | Phase 102 | Complete |
| VIS-01 | Phase 103 | Complete |
| VIS-02 | Phase 103 | Complete |
| VIS-04 | Phase 103 | Complete |
| VIS-05 | Phase 103 | Complete |
| DATA-04 | Phase 103 | Complete |
| NAV-01 | Phase 103 | Complete |
| NAV-02 | Phase 103 | Complete |
| PROTO-01 | Phase 104 | Complete |
| PROTO-02 | Phase 104 | Complete |

**Coverage:**
- v2026.4.1 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-04-03*
*Last updated: 2026-04-03 after roadmap creation*
