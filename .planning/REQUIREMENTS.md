# Requirements: Empowered Accounts — v2.8 District of Columbia Coverage

**Defined:** 2026-06-07
**Core Value:** Every DC elected official — Mayor, Council, AG, School Board, Shadow Senators — has a complete civic profile (photo, sourced stances, finance data) and DC users are geofenced to their ward so they see the right representatives.

## v2.8 Requirements

### DCIN — DC Infrastructure

- [ ] **DCIN-01**: `essentials.governments` stub created for Washington D.C. (DC)
- [ ] **DCIN-02**: `essentials.districts` records created — 8 CITY_COUNCIL ward districts (Ward 1–8), 9 SCHOOL_BOARD seat districts (Wards 1–8 + 1 at-large), 1 NATIONAL_LOWER at-large delegate seat for EHN; all FK'd to DC government
- [ ] **DCIN-03**: TIGER 2024 DC ward boundary polygons (8 wards) imported into `essentials.geo_districts` (CITY_COUNCIL layer) with GIST index, so point-in-polygon geofencing resolves DC users to their ward
- [ ] **DCIN-04**: `tiger_geoid` backfilled on DC ward district records so `(tiger_geoid, district_type)` dual-column Path 0 join works for DC users

### DCOF — DC Official Records

- [ ] **DCOF-01**: Politician records created for Mayor Muriel Bowser + all 13 DC Council members (Chairman Phil Mendelson + 8 ward + 4 at-large); office records FK'd to correct ward district
- [ ] **DCOF-02**: Politician records created for Attorney General Brian Schwalb + 2 DC Shadow Senators (Paul Strauss, Michael D. Brown); office records FK'd to DC government
- [ ] **DCOF-03**: Politician records created for all 9 DC School Board (SBOE) members; office records FK'd to SCHOOL_BOARD district records
- [ ] **DCOF-04**: `photo_origin_url` populated for all new DC officials (official council/DC.gov pages or Wikipedia); Eleanor Holmes Norton record verified in DB and `photo_origin_url` updated if missing

### DCST — DC Stance Research

- [x] **DCST-01**: Stances + `inform.politician_context` rows (at least one real source URL each) for Mayor Bowser + all 13 DC Council members + AG Schwalb — city-scope topics: housing, homelessness, climate, civil rights, childcare, immigration, taxes, voting
- [ ] **DCST-02**: Stances + context rows for all 9 SBOE members — education-focused topics: school vouchers, childcare, civil rights
- [ ] **DCST-03**: Stances + context rows for Shadow Senators — DC statehood/voting rights focus; Eleanor Holmes Norton stances verified and gaps filled

### DCFI — DC Finance

- [ ] **DCFI-01**: FEC `finance_summary` fetched and stored for Eleanor Holmes Norton using existing FEC ingestion script; `finance_summary` column updated on her politician record
- [ ] **DCFI-02**: DC Office of Campaign Finance (OCF) data researched for Mayor Bowser + DC Council members; `finance_summary` populated for officials where accessible machine-readable data exists

## Future Requirements

### DC Elections

- **DCEL-01**: DC elections seeded (next is November 2026 general); DC ward races surfaced via Elections Central geofencing
- **DCEL-02**: DC primary results (2026) ingested once filed

### DC Geofencing Expansion

- **DCGF-01**: DC users see all geofenced representatives (ward council member, shadow senators, EHN) in `/representatives/me` without manual setup
- **DCGF-02**: DC school board members surfaced in school district section of Profile Location tab

## Out of Scope

- DC statehood debate as a compass topic (outside the 21 existing CompassV2 topics)
- DC budget / Treasury Tracker integration (separate repo: `C:\treasury-tracker`)
- DC Advisory Neighborhood Commission (ANC) members — hyper-local, 345 commissioners, out of scope for Alpha
- Non-elected DC appointed officials (agency heads, DCPS superintendent, etc.)

## Traceability

| Phase | Requirements | Count |
|-------|-------------|-------|
| 105 — DC Infrastructure + Official Records | DCIN-01, DCIN-02, DCIN-03, DCIN-04, DCOF-01, DCOF-02, DCOF-03, DCOF-04 | 8 |
| 106 — DC Stance Research | DCST-01, DCST-02, DCST-03 | 3 |
| 107 — DC Finance | DCFI-01, DCFI-02 | 2 |
| **Total** | | **13 / 13** ✓ |
