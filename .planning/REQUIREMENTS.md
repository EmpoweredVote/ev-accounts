# Requirements: Empowered Vote Platform

**Defined:** 2026-02-23
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1.6 Requirements

Requirements for LA County Full Coverage milestone. Each maps to roadmap phases.

### Schema & Bug Fixes

- [x] **SCHEMA-01**: Geofence_boundaries table has composite unique constraint on (geo_id, mtfcc)
- [x] **SCHEMA-02**: Address lookup uses ST_Covers instead of ST_Contains for boundary matching
- [x] **SCHEMA-03**: MTFCC-to-district-type map includes G4110, G4120, G5400, G5410

### Pipeline Infrastructure

- [x] **PIPE-01**: Shared utils.py extracted from existing import scripts with get_engine, load_env, next_ext_id
- [x] **PIPE-02**: requirements.txt with pinned versions for all import script dependencies
- [x] **PIPE-03**: Import pipeline is parameterized and documented for reuse with other regions

### Geofence Boundaries

- [x] **GEO-01**: Congressional district boundaries (G5200) imported for LA County area
- [x] **GEO-02**: CA State Senate district boundaries (G5210) imported for LA County area
- [x] **GEO-03**: CA State Assembly district boundaries (G5220) imported for LA County area
- [ ] **GEO-04**: LA County Supervisorial district boundaries (G4020) imported from LA County ArcGIS
- [x] **GEO-05**: Unified School District boundaries (G5420) imported for LA County area
- [x] **GEO-06**: Incorporated place/city boundaries (G4110) imported for LA County area
- [ ] **GEO-07**: LA City council ward boundaries (X0001) imported from LA City GeoHub
- [ ] **GEO-08**: City council district/ward boundaries imported where available for LA County incorporated cities

### Politician Data

- [ ] **POL-01**: 5 LA County supervisors created with matching district geo_ids
- [ ] **POL-02**: 15 LA City council members + mayor created with matching district geo_ids
- [ ] **POL-03**: City council members for all 87 other incorporated LA County cities populated
- [ ] **POL-04**: School board members for 80+ LA County unified school districts populated
- [ ] **POL-05**: All politician records deduplicated against existing BallotReady-cached records

### Validation & Performance

- [ ] **VAL-01**: Point-in-polygon verification passes for test addresses (incorporated city, unincorporated area, boundary edge)
- [ ] **VAL-02**: VACUUM ANALYZE run on geofence_boundaries after all imports
- [ ] **VAL-03**: GiST index confirmed active (EXPLAIN ANALYZE shows Index Scan, not Seq Scan)
- [ ] **VAL-04**: Any LA County address returns full representative hierarchy (federal, state, county, city, school board)

## Future Requirements

### Statewide Expansion

- **STATE-01**: TIGER shapefile import for all 58 California counties
- **STATE-02**: Politician gap-fill for other CA county supervisors
- **STATE-03**: City council members for non-LA County cities

### National Coverage

- **NATL-01**: Repeatable pipeline applied to all 50 states
- **NATL-02**: Automated TIGER vintage refresh on redistricting cycles

## Out of Scope

| Feature | Reason |
|---------|--------|
| Statewide CA coverage beyond LA County | Pipeline is reusable; LA County is proof of concept |
| Automated TIGER refresh | Redistricting cycles are ~10 years; manual quarterly runs sufficient |
| Real-time official sync | Requires new data provider contract |
| Voting precinct (VTD) boundaries | Different use case; separate table if ever needed |
| Non-California states | Same pipeline, but politician data sourcing is the blocker |
| School board members for elementary/secondary districts | Import UNSD (G5420) only to prevent triple-match in LAUSD areas |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCHEMA-01 | Phase 32 | Complete |
| SCHEMA-02 | Phase 32 | Complete |
| SCHEMA-03 | Phase 32 | Complete |
| PIPE-01 | Phase 33 | Complete |
| PIPE-02 | Phase 33 | Complete |
| PIPE-03 | Phase 33 | Complete |
| GEO-01 | Phase 34 | Complete |
| GEO-02 | Phase 34 | Complete |
| GEO-03 | Phase 34 | Complete |
| GEO-04 | Phase 35 | Pending |
| GEO-05 | Phase 34 | Complete |
| GEO-06 | Phase 34 | Complete |
| GEO-07 | Phase 35 | Pending |
| GEO-08 | Phase 35 | Pending |
| POL-01 | Phase 36 | Pending |
| POL-02 | Phase 36 | Pending |
| POL-03 | Phase 37 | Pending |
| POL-04 | Phase 37 | Pending |
| POL-05 | Phase 36 | Pending |
| VAL-01 | Phase 38 | Pending |
| VAL-02 | Phase 38 | Pending |
| VAL-03 | Phase 38 | Pending |
| VAL-04 | Phase 38 | Pending |

**Coverage:**
- v1.6 requirements: 23 total
- Mapped to phases: 23
- Unmapped: 0

---
*Requirements defined: 2026-02-23*
*Last updated: 2026-02-23 after roadmap creation*
