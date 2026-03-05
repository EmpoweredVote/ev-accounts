# Requirements: Empowered Vote Platform

**Defined:** 2026-03-05
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v2026.4 Requirements

Requirements for milestone v2026.4: State Data Completion & Image Coverage.

### State Legislative Data

- [x] **STATE-01**: Indiana committee data imported via IGA direct API with current session memberships
- [x] **STATE-02**: California committee data imported via appropriate state legislature API
- [x] **STATE-03**: Indiana legislative data verified complete — bills, votes, and committee memberships cross-referenced against known legislators
- [x] **STATE-04**: California legislative data verified complete — bills, votes, and committee memberships cross-referenced against known legislators
- [x] **STATE-05**: Import scripts documented and repeatable for future sessions
- [x] **STATE-06**: All state legislative data accessible through existing API endpoints without modification

### Headshot Coverage

- [x] **PHOTO-01**: All ~300 politicians from headshot_research_manifest.csv researched for headshot availability
- [x] **PHOTO-02**: Headshots sourced through manual browser research for cities blocked by Cloudflare/CivicPlus
- [ ] **PHOTO-03**: All sourced headshots uploaded to Supabase Storage CDN
- [ ] **PHOTO-04**: politician_images database records updated for all newly sourced headshots
- [ ] **PHOTO-05**: Coverage validation report confirms 80%+ headshot coverage for LA County local officials

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Cross-App Integration

- **XAPP-01**: "My reps" surfacing on compare page (Essentials address → Compass compare)
- **XAPP-02**: Compass overlay on Essentials profiles
- **XAPP-03**: Multi-politician comparison (2-3 overlays at once)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| New state expansion beyond IN + CA | Pipeline reusable but data work deferred |
| Automated headshot scraping improvements | Manual approach chosen for reliability |
| Bio/education/experience for city council | High per-city effort, not in scope |
| Real-time vote syncing | Ops complexity; weekly batch sufficient |
| School board data enrichment | Low data availability |
| New API endpoints | Existing endpoints should serve state data without modification |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| STATE-01 | Phase 60 | Complete |
| STATE-02 | Phase 60 | Complete |
| STATE-03 | Phase 61 | Complete |
| STATE-04 | Phase 61 | Complete |
| STATE-05 | Phase 62 | Complete |
| STATE-06 | Phase 62 | Complete |
| PHOTO-01 | Phase 63 | Complete |
| PHOTO-02 | Phase 63 | Complete |
| PHOTO-03 | Phase 64 | Pending |
| PHOTO-04 | Phase 64 | Pending |
| PHOTO-05 | Phase 64 | Pending |

**Coverage:**
- v2026.4 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0

---
*Requirements defined: 2026-03-05*
*Last updated: 2026-03-05 after roadmap creation*
