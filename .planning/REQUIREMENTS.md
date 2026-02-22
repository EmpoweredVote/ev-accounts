# Requirements: Empowered Vote Platform

**Defined:** 2026-02-22
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1.5 Requirements

Requirements for v1.5 milestone. Each maps to roadmap phases.

### BallotReady Removal

- [x] **BR-01**: Address search uses geofence-only matching (no BallotReady fallback)
- [x] **BR-02**: User sees federal and state officials from cache when local geofence data is unavailable for their address
- [x] **BR-03**: Background cache warmers (warmFederal, warmState, warmLocal) no longer call BallotReady API
- [x] **BR-04**: BallotReady provider is de-registered from setup (no initialization at startup)

### Candidates

- [x] **CAND-01**: User can view cached candidate/race data from election_records table (no live BallotReady fetch)

### Address Search

- [x] **ADDR-01**: User enters address via Google Maps Places autocomplete widget
- [x] **ADDR-02**: ZIP code search path is removed — address is the only search input
- [x] **ADDR-03**: User sees their validated/confirmed address in search results
- [x] **ADDR-04**: User sees a clear message when local-level data is not available for their area

### Cleanup

- [ ] **CLEAN-01**: BALLOTREADY_API_KEY removed from all environment configurations
- [ ] **CLEAN-02**: Full codebase audit confirms zero active BallotReady API references
- [ ] **CLEAN-03**: Google Maps API billing alerts configured for cost monitoring

## Future Requirements

### Geographic Filters

- **GEO-01**: User can filter politicians by state
- **GEO-02**: User can filter politicians by county
- **GEO-03**: User can filter politicians by city
- **GEO-04**: User can filter politicians by school district

### Candidate Data Enrichment

- **CAND-02**: User sees when candidate data was last updated (freshness indicator)
- **CAND-03**: Alternative data source for candidate/race data beyond cached BallotReady records

## Out of Scope

| Feature | Reason |
|---------|--------|
| ZIP code fallback for privacy | Address-only for v1.5; geographic filters in future milestone |
| New data source integration | v1.5 works from cached data; alternative sources in future |
| TIGER shapefile expansion | Only Monroe County IN + LA County CA; expansion in future milestone |
| Real-time candidate data | Cached-only for v1.5; live data requires new provider |
| PlaceAutocompleteElement migration | Legacy Autocomplete class still works for existing API keys; migrate when needed |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BR-01 | Phase 26 | Complete |
| BR-02 | Phase 26 | Complete |
| BR-03 | Phase 27 | Complete |
| BR-04 | Phase 27 | Complete |
| CAND-01 | Phase 27 | Complete |
| ADDR-01 | Phase 28 | Complete |
| ADDR-02 | Phase 28 | Complete |
| ADDR-03 | Phase 28 | Complete |
| ADDR-04 | Phase 28 | Complete |
| CLEAN-01 | Phase 29 | Pending |
| CLEAN-02 | Phase 29 | Pending |
| CLEAN-03 | Phase 29 | Pending |

**Coverage:**
- v1.5 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-02-22*
*Last updated: 2026-02-22 after roadmap creation*
