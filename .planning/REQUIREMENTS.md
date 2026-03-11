# Requirements: Empowered Vote — Local Government Organization

**Defined:** 2026-03-10
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v2026.3.3 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Body Display

- [ ] **BODY-01**: Section headings display specific body names (e.g., "Monroe County Council" instead of "County Council")
- [ ] **BODY-02**: County Commissioners and County Council display as distinct sections for Indiana counties
- [ ] **BODY-03**: Township sections display specific township names (e.g., "Perry Township Trustee")
- [ ] **BODY-04**: City-level sections display specific city names (e.g., "Bloomington Common Council")
- [ ] **BODY-05**: School Board sections display specific district names (e.g., "Monroe County Community School Corporation Board")

### Website Links

- [ ] **LINK-01**: Each government body section displays a link to its official website
- [ ] **LINK-02**: Website URLs stored in database with graceful absence when URL is null
- [ ] **LINK-03**: Monroe County bodies seeded with official website URLs (Commissioners, Council, elected officials)
- [ ] **LINK-04**: Bloomington bodies seeded with official website URLs (City Council)

### Data Foundation

- [ ] **DATA-01**: Database audit confirms current chamber_name_formal values for Monroe County/Bloomington officials
- [ ] **DATA-02**: classify.js routes "commissioner" title keywords to distinct "County Commissioners" group
- [ ] **DATA-03**: All consumer files updated together (LOCAL_ORDER, CATEGORY_DISPLAY_NAMES, GROUP_SORT_OPTIONS)

## Future Requirements

### Member Distinction (deferred)

- **MEMB-01**: At-large vs district badge on council member cards
- **MEMB-02**: Role description under section headings explaining body function

### Expansion (deferred)

- **EXPN-01**: State-configurable body structure for California Board of Supervisors
- **EXPN-02**: LA County bodies seeded with official website URLs
- **EXPN-03**: Meeting/agenda deep links per body

## Out of Scope

| Feature | Reason |
|---------|--------|
| Automated website discovery/scraping | Unreliable for government sites; manual data entry more accurate at this scale |
| Meeting calendar / agenda embed | Per-jurisdiction maintenance burden too high for 2-3 person team |
| Organizational chart visualization | High design complexity, varies by state, not core to discovery |
| At-large member fake district assignment | Misleading — at-large means no district |
| All 92 Indiana counties | Only Monroe County has geofence data; improvements apply automatically as counties are added |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | Phase 72 | Pending |
| LINK-02 | Phase 73 | Pending |
| DATA-02 | Phase 73 | Pending |
| DATA-03 | Phase 73 | Pending |
| LINK-03 | Phase 74 | Pending |
| LINK-04 | Phase 74 | Pending |
| LINK-01 | Phase 75 | Pending |
| BODY-01 | Phase 76 | Pending |
| BODY-02 | Phase 76 | Pending |
| BODY-03 | Phase 76 | Pending |
| BODY-04 | Phase 76 | Pending |
| BODY-05 | Phase 76 | Pending |

**Coverage:**
- v2026.3.3 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-10*
*Last updated: 2026-03-10 after roadmap creation — all 12 requirements mapped to phases 72-76*
