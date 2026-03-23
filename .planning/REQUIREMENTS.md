# Requirements: Treasury Tracker Expansion

**Defined:** 2026-03-22
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v2026.3.7 Requirements

Requirements for Treasury Tracker Expansion milestone. Each maps to roadmap phases.

### Schema & Backend

- [x] **SCHM-01**: Budget unique index includes dataset_type (three-column: city_id, fiscal_year, dataset_type)
- [x] **SCHM-02**: City model has entity_type field (city/county/township) with composite unique on (name, state, entity_type)
- [x] **SCHM-03**: Budget model has fiscal_year_start_month field (default 1, set to 7 for California entities)

### Data Migration

- [x] **DATA-01**: Bloomington operating budget data migrated from static JSON to Supabase via treasury API
- [x] **DATA-02**: Bloomington revenue data migrated from static JSON to Supabase
- [x] **DATA-03**: Bloomington salary data migrated from static JSON to Supabase
- [x] **DATA-04**: Static JSON fallback in dataLoader.ts guarded to Bloomington city only

### Indiana Expansion

- [ ] **IND-01**: Ellettsville operating budget imported from Indiana Gateway (pipe-delimited format)
- [ ] **IND-02**: Monroe County operating budget imported from Indiana Gateway
- [ ] **IND-03**: Import script handles pipe-delimited format with explicit delimiter and encoding configuration

### LA Data

- [ ] **LA-01**: LA County expenditure data imported from data.lacounty.gov
- [ ] **LA-02**: LA City appropriations data imported from data.lacity.org Socrata CSV
- [ ] **LA-03**: Fiscal year start month set to 7 for all California entities

### Entity Switcher

- [ ] **UI-01**: User can switch between entities (cities/counties) via dropdown on treasury tracker
- [ ] **UI-02**: Hero card, breadcrumbs, and dataset tabs update dynamically per selected entity
- [ ] **UI-03**: Entity switcher groups entities by type (city vs county)
- [x] **UI-04**: dataLoader.ts cache key includes entity type to prevent cross-entity collisions

### Visual Refresh

- [x] **VIS-01**: Tailwind CSS 4 installed in treasury-tracker with ev-ui tailwind-preset
- [x] **VIS-02**: ev-ui upgraded from ^0.1.6 to current version
- [x] **VIS-03**: UI chrome (header, cards, tabs, buttons) uses EV design tokens
- [ ] **VIS-04**: Chart colors updated to use EV brand-aligned data visualization palette
- [x] **VIS-05**: Typography uses Manrope consistent with other EV apps

## Future Requirements

### Backend Migration

- **PORT-01**: Treasury API routes ported from Go/Chi to Express/ev-accounts
- **PORT-02**: Frontend API client updated to point at ev-accounts endpoints

### Additional Data

- **TXNS-01**: Transaction-level checkbook data for LA (requires separate transactions table + paginated API)
- **COMP-01**: Side-by-side jurisdiction comparison layout
- **TREND-01**: Year-over-year trend charts
- **REV-01**: Revenue and salary data for LA entities
- **SCHOOL-01**: School district budget data

## Out of Scope

| Feature | Reason |
|---------|--------|
| Transaction-level checkbook data | Millions of rows; requires separate table architecture + pagination — v2+ |
| Side-by-side jurisdiction comparison | High UI complexity; OpenGov-level feature — v2+ |
| SiteHeader integration | User deferred to future milestone |
| Go → Express treasury port | User chose to keep Go for now; port in separate milestone |
| School district budgets | User explicitly deferred |
| PDF parsing for LA County adopted budget | Unreliable; use expenditure transactions from open data portal instead |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCHM-01 | Phase 92 | Complete |
| SCHM-02 | Phase 92 | Complete |
| SCHM-03 | Phase 92 | Complete |
| DATA-01 | Phase 92 | Complete |
| DATA-02 | Phase 92 | Complete |
| DATA-03 | Phase 92 | Complete |
| DATA-04 | Phase 92 | Complete |
| IND-01 | Phase 93 | Pending |
| IND-02 | Phase 93 | Pending |
| IND-03 | Phase 93 | Pending |
| LA-01 | Phase 94 | Pending |
| LA-02 | Phase 94 | Pending |
| LA-03 | Phase 94 | Pending |
| UI-01 | Phase 95 | Pending |
| UI-02 | Phase 95 | Pending |
| UI-03 | Phase 95 | Pending |
| UI-04 | Phase 95 | Complete |
| VIS-01 | Phase 96 | Complete |
| VIS-02 | Phase 96 | Complete |
| VIS-03 | Phase 96 | Complete |
| VIS-04 | Phase 96 | Pending |
| VIS-05 | Phase 96 | Complete |

**Coverage:**
- v2026.3.7 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-22*
*Last updated: 2026-03-22 after roadmap creation*
