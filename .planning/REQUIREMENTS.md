# Requirements: v2.14 MA City Expansion Wave 2

**Milestone:** v2.14  
**Status:** Active  
**Last updated:** 2026-06-15

Full civic data layer for 7 remaining MA cities — Newton, Somerville, Lynn, Fall River, Waltham, Medford, and New Bedford. Each city currently has a government stub + 1 chamber in DB with zero districts, officials, or stances.

---

## Officials Seeding (MAOF)

- [ ] **MAOF-01**: Newton district + politician + office records committed and applied (migration)
- [ ] **MAOF-02**: Somerville district + politician + office records committed and applied
- [ ] **MAOF-03**: Lynn district + politician + office records committed and applied
- [ ] **MAOF-04**: Fall River district + politician + office records committed and applied
- [ ] **MAOF-05**: Waltham district + politician + office records committed and applied
- [ ] **MAOF-06**: Medford district + politician + office records committed and applied
- [ ] **MAOF-07**: New Bedford district + politician + office records committed and applied

## Stances (MAST)

All stances must follow Chair methodology: sourced from primary sources, real URL in `inform.politician_context`, honest-skip where no documentable record exists.

- [ ] **MAST-01**: Sourced stances + context rows for all Newton officials (honest-skip where no record)
- [ ] **MAST-02**: Sourced stances + context rows for all Somerville officials
- [ ] **MAST-03**: Sourced stances + context rows for all Lynn officials
- [ ] **MAST-04**: Sourced stances + context rows for all Fall River officials
- [ ] **MAST-05**: Sourced stances + context rows for all Waltham officials
- [ ] **MAST-06**: Sourced stances + context rows for all Medford officials
- [ ] **MAST-07**: Sourced stances + context rows for all New Bedford officials

## Geofencing (MAGE)

Ward/district boundary polygons imported into `essentials.geo_districts` + `essentials.geofence_boundaries`; `tiger_geoid` backfilled on city council district rows; Path 0 join verified via SQL assertion.

Continues MAGE numbering from Phase 119 (MAGE-10..15).

- [ ] **MAGE-16**: Newton ward polygons imported; tiger_geoid backfilled on district rows; Path 0 verified
- [ ] **MAGE-17**: Somerville ward polygons imported; tiger_geoid backfilled; Path 0 verified
- [ ] **MAGE-18**: Lynn ward polygons imported; tiger_geoid backfilled; Path 0 verified
- [ ] **MAGE-19**: Fall River ward polygons imported; tiger_geoid backfilled; Path 0 verified
- [ ] **MAGE-20**: Waltham ward polygons imported; tiger_geoid backfilled; Path 0 verified
- [ ] **MAGE-21**: Medford ward polygons imported; tiger_geoid backfilled; Path 0 verified
- [ ] **MAGE-22**: New Bedford ward polygons imported; tiger_geoid backfilled; Path 0 verified

---

## Future Requirements

- Stance research for remaining MA cities not yet in DB (Lawrence, Framingham, Haverhill, Malden, etc.)
- MA school district geofencing for cities added in v2.14

## Out of Scope

- MA state executive stances (covered by Essentials team)
- School district records for v2.14 cities (deferred)
- Cities with population < 50k (deferred)

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| MAOF-01 | Phase 120 | Pending |
| MAOF-02 | Phase 120 | Pending |
| MAOF-03 | Phase 120 | Pending |
| MAOF-04 | Phase 120 | Pending |
| MAOF-05 | Phase 120 | Pending |
| MAOF-06 | Phase 120 | Pending |
| MAOF-07 | Phase 120 | Pending |
| MAST-01 | Phase 121 | Pending |
| MAST-02 | Phase 121 | Pending |
| MAST-06 | Phase 121 | Pending |
| MAST-03 | Phase 122 | Pending |
| MAST-04 | Phase 122 | Pending |
| MAST-05 | Phase 122 | Pending |
| MAST-07 | Phase 122 | Pending |
| MAGE-16 | Phase 123 | Pending |
| MAGE-17 | Phase 123 | Pending |
| MAGE-18 | Phase 123 | Pending |
| MAGE-19 | Phase 123 | Pending |
| MAGE-20 | Phase 123 | Pending |
| MAGE-21 | Phase 123 | Pending |
| MAGE-22 | Phase 123 | Pending |
