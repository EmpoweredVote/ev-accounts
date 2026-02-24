# Requirements: Empowered Vote Platform

**Defined:** 2026-02-23
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1.6 Requirements

Requirements for LA County Full Coverage milestone. Each maps to roadmap phases.

### Schema & Bug Fixes

- [ ] **SCHEMA-01**: Geofence_boundaries table has composite unique constraint on (geo_id, mtfcc)
- [ ] **SCHEMA-02**: Address lookup uses ST_Covers instead of ST_Contains for boundary matching
- [ ] **SCHEMA-03**: MTFCC-to-district-type map includes G4110, G4120, G5400, G5410

### Pipeline Infrastructure

- [ ] **PIPE-01**: Shared utils.py extracted from existing import scripts with get_engine, load_env, next_ext_id
- [ ] **PIPE-02**: requirements.txt with pinned versions for all import script dependencies
- [ ] **PIPE-03**: Import pipeline is parameterized and documented for reuse with other regions

### Geofence Boundaries

- [ ] **GEO-01**: Congressional district boundaries (G5200) imported for LA County area
- [ ] **GEO-02**: CA State Senate district boundaries (G5210) imported for LA County area
- [ ] **GEO-03**: CA State Assembly district boundaries (G5220) imported for LA County area
- [ ] **GEO-04**: LA County Supervisorial district boundaries (G4020) imported from LA County ArcGIS
- [ ] **GEO-05**: Unified School District boundaries (G5420) imported for LA County area
- [ ] **GEO-06**: Incorporated place/city boundaries (G4110) imported for LA County area
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
| SCHEMA-01 | — | Pending |
| SCHEMA-02 | — | Pending |
| SCHEMA-03 | — | Pending |
| PIPE-01 | — | Pending |
| PIPE-02 | — | Pending |
| PIPE-03 | — | Pending |
| GEO-01 | — | Pending |
| GEO-02 | — | Pending |
| GEO-03 | — | Pending |
| GEO-04 | — | Pending |
| GEO-05 | — | Pending |
| GEO-06 | — | Pending |
| GEO-07 | — | Pending |
| GEO-08 | — | Pending |
| POL-01 | — | Pending |
| POL-02 | — | Pending |
| POL-03 | — | Pending |
| POL-04 | — | Pending |
| POL-05 | — | Pending |
| VAL-01 | — | Pending |
| VAL-02 | — | Pending |
| VAL-03 | — | Pending |
| VAL-04 | — | Pending |

**Coverage:**
- v1.6 requirements: 23 total
- Mapped to phases: 0
- Unmapped: 23 (pending roadmap)

---
*Requirements defined: 2026-02-23*
*Last updated: 2026-02-23 after initial definition*
