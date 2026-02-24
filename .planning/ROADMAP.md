# Roadmap: Empowered Vote

## Milestones

- ✅ **v1.0 Quality & Consolidation** — Phases 1-7 (shipped 2026-02-18)
- ✅ **v1.1 Essentials UX Polish** — Phases 8-10 (shipped 2026-02-19)
- ✅ **v1.2 Compass Onboarding & UX** — Phases 11-16 (shipped 2026-02-20)
- ✅ **v1.3 Compass Bug Fixes & Title Standardization** — Phases 17-20 (shipped 2026-02-21)
- ✅ **v1.4 Compass Polish & Tech Debt** — Phases 21-25 (shipped 2026-02-22)
- ✅ **v1.5 Address Verification & BallotReady Independence** — Phases 26-31 (shipped 2026-02-23)
- 🚧 **v1.6 LA County Full Coverage** — Phases 32-38 (in progress)

## Phases

<details>
<summary>✅ v1.0 Quality & Consolidation (Phases 1-7) — SHIPPED 2026-02-18</summary>

- [x] Phase 1: Auth Safety Audit (1/1 plans) — completed 2026-02-17
- [x] Phase 2: Guest-First Auth (3/3 plans) — completed 2026-02-17
- [x] Phase 3: Compass Visual Fixes (2/2 plans) — completed 2026-02-18
- [x] Phase 4: Compass UX Enhancements (8/8 plans) — completed 2026-02-18
- [x] Phase 5: Essentials Improvements (5/5 plans) — completed 2026-02-18
- [x] Phase 6: Audit Gap Closure (1/1 plan) — completed 2026-02-18
- [x] Phase 7: Integration Polish (1/1 plan) — completed 2026-02-18

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v1.1 Essentials UX Polish (Phases 8-10) — SHIPPED 2026-02-19</summary>

- [x] Phase 8: Layout (1/1 plans) — completed 2026-02-18
- [x] Phase 9: Building Imagery (1/1 plans) — completed 2026-02-18
- [x] Phase 10: Term Dates (1/1 plans) — completed 2026-02-18

Full details: `.planning/milestones/v1.1-ROADMAP.md`

</details>

<details>
<summary>✅ v1.2 Compass Onboarding & UX (Phases 11-16) — SHIPPED 2026-02-20</summary>

- [x] Phase 11: Tech Debt Cleanup (1/1 plans) — completed 2026-02-19
- [x] Phase 12: Quick UX Fixes (2/2 plans) — completed 2026-02-19
- [x] Phase 13: Topic Selection Enforcement (2/2 plans) — completed 2026-02-19
- [x] Phase 14: Guided Onboarding Flow (4/4 plans) — completed 2026-02-19
- [x] Phase 15: Help Page Update (2/2 plans) — completed 2026-02-19
- [x] Phase 16: Audit Bug Fixes (1/1 plan) — completed 2026-02-20

Full details: `.planning/milestones/v1.2-ROADMAP.md`

</details>

<details>
<summary>✅ v1.3 Compass Bug Fixes & Title Standardization (Phases 17-20) — SHIPPED 2026-02-21</summary>

- [x] Phase 17: Title Standardization (Backend) (2/2 plans) — completed 2026-02-21
- [x] Phase 18: Title Display (Frontend) (2/2 plans) — completed 2026-02-21
- [x] Phase 19: Calibration Flow Fixes (2/2 plans) — completed 2026-02-21
- [x] Phase 20: Compare Bug Fix (1/1 plan) — completed 2026-02-21

Full details: `.planning/milestones/v1.3-ROADMAP.md`

</details>

<details>
<summary>✅ v1.4 Compass Polish & Tech Debt (Phases 21-25) — SHIPPED 2026-02-22</summary>

- [x] Phase 21: Guest Flow Fix (1/1 plans) — completed 2026-02-22
- [x] Phase 22: Radar Label Fixes (2/2 plans) — completed 2026-02-22
- [x] Phase 23: UX Cleanup (2/2 plans) — completed 2026-02-22
- [x] Phase 24: Tech Debt Cleanup (2/2 plans) — completed 2026-02-22
- [x] Phase 25: Onboarding-to-Calibration Redirect & Topic Display Fix (2/2 plans) — completed 2026-02-22

Full details: `.planning/milestones/v1.4-ROADMAP.md`

</details>

<details>
<summary>✅ v1.5 Address Verification & BallotReady Independence (Phases 26-31) — SHIPPED 2026-02-23</summary>

- [x] Phase 26: Geofence-Only Search (2/2 plans) — completed 2026-02-22
- [x] Phase 27: Cache-Only Candidates & Warmer Cleanup (2/2 plans) — completed 2026-02-22
- [x] Phase 28: Address Autocomplete (2/2 plans) — completed 2026-02-23
- [x] Phase 29: Validation, Polish & Key Removal (2/2 plans) — completed 2026-02-23
- [x] Phase 30: Fix Compass Calibration Layout & Write-in (2/2 plans) — completed 2026-02-23
- [x] Phase 31: Essentials Profile & District Data Fixes (3/3 plans) — completed 2026-02-23

Full details: `.planning/milestones/v1.5-ROADMAP.md`

</details>

### 🚧 v1.6 LA County Full Coverage (In Progress)

**Milestone Goal:** Expand geofence coverage so any LA County address returns the full hierarchy of representatives — federal, state, county, city, school board — with a repeatable import pipeline for future regional expansion.

#### Phase Details

### Phase 32: Schema Fixes and Lookup Bug Correction
**Goal**: The database schema and geofence lookup code are correct and safe for multi-layer imports
**Depends on**: Nothing (first phase of milestone)
**Requirements**: SCHEMA-01, SCHEMA-02, SCHEMA-03
**Success Criteria** (what must be TRUE):
  1. `geofence_boundaries` has a composite unique constraint on `(geo_id, mtfcc)` — idempotent upserts across boundary types do not silently drop rows
  2. `geofence_lookup.go` uses `ST_Covers` instead of `ST_Contains` — addresses on district boundary lines return results
  3. `mtfccToDistrictTypes` includes G4110, G4120, G5400, G5410 — city, place, and school district boundaries map to correct district types
**Plans:** 1/1 plans complete
Plans:
- [ ] 32-01-PLAN.md — Schema constraint, spatial predicate fix, and MTFCC map expansion

### Phase 33: Pipeline Infrastructure
**Goal**: A shared utility layer and pinned dependency manifest exist so all new import scripts use consistent patterns
**Depends on**: Phase 32
**Requirements**: PIPE-01, PIPE-02, PIPE-03
**Success Criteria** (what must be TRUE):
  1. `EV-Backend/scripts/utils.py` exists with `get_engine()`, `load_env()`, and `next_ext_id()` — new scripts import from it rather than duplicating logic
  2. `EV-Backend/scripts/requirements.txt` pins geopandas 1.1.2, SQLAlchemy 2.0.46, psycopg2-binary, requests, and shapely — any developer can reproduce the import environment with one `pip install -r`
  3. A new developer can run any import script against a fresh Supabase project by following the documented `DATABASE_URL` setup (direct connection, port 5432)
**Plans**: TBD

### Phase 34: TIGER Geofences — Federal, State, School, and City Boundaries
**Goal**: Federal legislative, state legislative, school district, and incorporated city boundaries for the LA County area are in the database
**Depends on**: Phase 33
**Requirements**: GEO-01, GEO-02, GEO-03, GEO-05, GEO-06
**Success Criteria** (what must be TRUE):
  1. Congressional district boundaries (G5200) are present in `geofence_boundaries` — searching an LA County address returns a U.S. House district match
  2. CA State Senate (G5210) and State Assembly (G5220) boundaries are present — state legislative officials appear for LA County addresses
  3. Unified School District boundaries (G5420) are present — school district officials can be linked for LAUSD and other LA County districts
  4. Incorporated place boundaries (G4110) are present for all 88 LA County cities — city council officials can be linked per city
  5. All imported geometries pass `ST_IsValid` — no silent insert failures from topology errors
**Plans**: TBD

### Phase 35: LA County ArcGIS Geofences — Supervisor Districts and City Council Wards
**Goal**: LA County supervisor district boundaries and LA City council ward boundaries are in the database from their authoritative GIS sources
**Depends on**: Phase 34
**Requirements**: GEO-04, GEO-07, GEO-08
**Success Criteria** (what must be TRUE):
  1. 5 LA County Supervisorial District polygons (G4020) are in `geofence_boundaries` with `geo_id` values matching `essentials.districts` — unincorporated LA County addresses return a supervisor match
  2. 15 LA City council ward boundaries (X0001) are in `geofence_boundaries` — LA City addresses return the correct council member ward
  3. City council district/ward boundaries for LA County incorporated cities with district-based elections are imported where source data is available
**Plans**: TBD

### Phase 36: Politician Gap-Fill — Supervisors and LA City Council
**Goal**: LA County supervisors and LA City council members exist in the database with geo_ids that join to the Phase 35 geofences, enabling the full local hierarchy for the highest-impact addresses
**Depends on**: Phase 35
**Requirements**: POL-01, POL-02, POL-05
**Success Criteria** (what must be TRUE):
  1. 5 LA County supervisor records exist in `essentials.politicians` with matching `districts.geo_id` values — an unincorporated LA County address returns all 5 supervisors in the correct tier
  2. 15 LA City council member records and 1 LA City mayor record exist with matching `districts.geo_id` values — an LA City address returns the correct council member and mayor
  3. A duplicate detection query after import returns zero rows — no politician appears twice from both BallotReady cache and manual gap-fill
**Plans**: TBD

### Phase 37: Politician Gap-Fill — City Councils and School Boards
**Goal**: City council members for all 87 other incorporated LA County cities and school board members for LA County unified school districts are populated in the database
**Depends on**: Phase 36
**Requirements**: POL-03, POL-04
**Success Criteria** (what must be TRUE):
  1. City council member records exist for the 87 incorporated LA County cities (excluding LA City covered in Phase 36) — any incorporated-city address returns local council representatives
  2. School board member records exist for LA County unified school districts — any address in an LAUSD or other UNSD boundary returns school board representatives
  3. All new politician records link to district rows whose `geo_id` values match `geofence_boundaries` rows imported in Phase 34 — no politician record is orphaned from a boundary
**Plans**: TBD

### Phase 38: Validation and Performance
**Goal**: Any LA County address returns the complete representative hierarchy, the PostGIS index is active, and the import pipeline is documented as repeatable for future regions
**Depends on**: Phase 37
**Requirements**: VAL-01, VAL-02, VAL-03, VAL-04
**Success Criteria** (what must be TRUE):
  1. Point-in-polygon verification passes for three test addresses: one incorporated city address, one unincorporated area address, and one address on a district boundary — each returns the correct representative hierarchy with no missing tiers
  2. `VACUUM ANALYZE essentials.geofence_boundaries` has been run after all bulk inserts — `EXPLAIN ANALYZE` on a point-in-polygon query shows Index Scan, not Seq Scan
  3. Any LA County address entered into the Essentials search returns federal, state, county, city, and school board representatives — the full five-tier hierarchy is present with no empty tiers for covered areas
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Auth Safety Audit | v1.0 | 1/1 | Complete | 2026-02-17 |
| 2. Guest-First Auth | v1.0 | 3/3 | Complete | 2026-02-17 |
| 3. Compass Visual Fixes | v1.0 | 2/2 | Complete | 2026-02-18 |
| 4. Compass UX Enhancements | v1.0 | 8/8 | Complete | 2026-02-18 |
| 5. Essentials Improvements | v1.0 | 5/5 | Complete | 2026-02-18 |
| 6. Audit Gap Closure | v1.0 | 1/1 | Complete | 2026-02-18 |
| 7. Integration Polish | v1.0 | 1/1 | Complete | 2026-02-18 |
| 8. Layout | v1.1 | 1/1 | Complete | 2026-02-18 |
| 9. Building Imagery | v1.1 | 1/1 | Complete | 2026-02-18 |
| 10. Term Dates | v1.1 | 1/1 | Complete | 2026-02-18 |
| 11. Tech Debt Cleanup | v1.2 | 1/1 | Complete | 2026-02-19 |
| 12. Quick UX Fixes | v1.2 | 2/2 | Complete | 2026-02-19 |
| 13. Topic Selection Enforcement | v1.2 | 2/2 | Complete | 2026-02-19 |
| 14. Guided Onboarding Flow | v1.2 | 4/4 | Complete | 2026-02-19 |
| 15. Help Page Update | v1.2 | 2/2 | Complete | 2026-02-19 |
| 16. Audit Bug Fixes | v1.2 | 1/1 | Complete | 2026-02-20 |
| 17. Title Standardization (Backend) | v1.3 | 2/2 | Complete | 2026-02-21 |
| 18. Title Display (Frontend) | v1.3 | 2/2 | Complete | 2026-02-21 |
| 19. Calibration Flow Fixes | v1.3 | 2/2 | Complete | 2026-02-21 |
| 20. Compare Bug Fix | v1.3 | 1/1 | Complete | 2026-02-21 |
| 21. Guest Flow Fix | v1.4 | 1/1 | Complete | 2026-02-22 |
| 22. Radar Label Fixes | v1.4 | 2/2 | Complete | 2026-02-22 |
| 23. UX Cleanup | v1.4 | 2/2 | Complete | 2026-02-22 |
| 24. Tech Debt Cleanup | v1.4 | 2/2 | Complete | 2026-02-22 |
| 25. Onboarding-to-Calibration Redirect | v1.4 | 2/2 | Complete | 2026-02-22 |
| 26. Geofence-Only Search | v1.5 | 2/2 | Complete | 2026-02-22 |
| 27. Cache-Only Candidates & Warmer Cleanup | v1.5 | 2/2 | Complete | 2026-02-22 |
| 28. Address Autocomplete | v1.5 | 2/2 | Complete | 2026-02-23 |
| 29. Validation, Polish & Key Removal | v1.5 | 2/2 | Complete | 2026-02-23 |
| 30. Fix Compass Calibration Layout & Write-in | v1.5 | 2/2 | Complete | 2026-02-23 |
| 31. Essentials Profile & District Data Fixes | v1.5 | 3/3 | Complete | 2026-02-23 |
| 32. Schema Fixes and Lookup Bug Correction | 1/1 | Complete    | 2026-02-24 | - |
| 33. Pipeline Infrastructure | v1.6 | 0/TBD | Not started | - |
| 34. TIGER Geofences — Federal, State, School, City | v1.6 | 0/TBD | Not started | - |
| 35. LA County ArcGIS Geofences — Supervisor Districts and City Council Wards | v1.6 | 0/TBD | Not started | - |
| 36. Politician Gap-Fill — Supervisors and LA City Council | v1.6 | 0/TBD | Not started | - |
| 37. Politician Gap-Fill — City Councils and School Boards | v1.6 | 0/TBD | Not started | - |
| 38. Validation and Performance | v1.6 | 0/TBD | Not started | - |
