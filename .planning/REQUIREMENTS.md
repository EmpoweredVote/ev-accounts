# Requirements: Empowered Accounts — v2.10

**Defined:** 2026-06-08
**Core Value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.

## v2.10 Requirements

### VAIN — Virginia Official Records

- [ ] **VAIN-01**: Politician + office records for all 100 VA House delegates committed and applied (migration 308)
- [ ] **VAIN-02**: Politician + office records for 11 VA federal House reps committed and applied (migration 311)
- [ ] **VAIN-03**: `photo_origin_url` populated for all new VA officials (executives, senators, delegates, House reps)

### VAGE — Virginia Geofencing

- [ ] **VAGE-01**: TIGER 2024 VA SLDL polygons (100 House delegate districts) imported into `essentials.geo_districts` with GIST index
- [ ] **VAGE-02**: TIGER 2024 VA SLDU polygons (40 Senate districts) imported into `essentials.geo_districts`
- [ ] **VAGE-03**: `tiger_geoid` backfilled on all VA `essentials.districts` records for dual-column Path 0 join

### VAST — Virginia Stances

- [ ] **VAST-01**: Sourced stances for VA state executives (Governor, Lt. Governor, AG)
- [ ] **VAST-02**: Sourced stances for all 40 VA state senators
- [ ] **VAST-03**: Sourced stances for all 100 VA House delegates (honest-skip where no documentable evidence)
- [ ] **VAST-04**: Sourced stances for 11 VA House reps (federal topics)
- [ ] **VAST-05**: Every new stance paired with `inform.politician_context` containing ≥1 real source URL

### VAFI — Virginia Finance

- [ ] **VAFI-01**: FEC `finance_summary` fetched and stored for all 11 VA House reps
- [ ] **VAFI-02**: VPAP data assessed for VA state officials; finance data ingested where machine-readable

### LAFI — LA County Finance

- [x] **LAFI-01**: CAL-ACCESS data assessed; finance data ingested for LA City Mayor + all Council members + Controller + Clerk
- [x] **LAFI-02**: Netfile assessed for other LA County cities; finance data ingested where accessible machine-readable data exists

## Future Requirements

### VA State Stances (Scale)

- **VAST-F01**: Full stance coverage for all 140 VA General Assembly members across all 43 CompassV2 topics (Phase 111/112 will cover what's documentable; full coverage deferred as evidence allows)

### Additional State Coverage

- **MDIN-01**: Maryland officials full expansion (state senators, delegates, governor, federal) — started in Phase 103 with 6 officials
- **INEX-01**: Indiana coverage expansion beyond the Bloomington pilot (state senators, delegates, governor)

## Out of Scope

| Feature | Reason |
|---------|--------|
| VA municipal officials (city councils, mayors) | Cities in scope: LA, SF, SJ, SD, Berkeley, Fremont, DC. VA cities deferred — state coverage first |
| VA school board geofencing | SBED layer not yet imported for any state; consistent deferral |
| VPAP scraping / unofficial data | Only machine-readable official sources; honest-skip if inaccessible |
| LA County officials beyond Phase 108 set | Phase 108 seeded 72 officials; additional LA cities are a future expansion |
| Netfile deep-dive if API is paywalled | Document finding and close requirement with that finding, same as DC OCF pattern |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| VAIN-01 | Phase 110 | Pending |
| VAIN-02 | Phase 110 | Pending |
| VAIN-03 | Phase 110 | Pending |
| VAGE-01 | Phase 110 | Pending |
| VAGE-02 | Phase 110 | Pending |
| VAGE-03 | Phase 110 | Pending |
| VAST-01 | Phase 111 | Pending |
| VAST-02 | Phase 111 | Pending |
| VAST-03 | Phase 112 | Pending |
| VAST-04 | Phase 113 | Pending |
| VAST-05 | Phase 111, 112, 113 | Pending |
| VAFI-01 | Phase 113 | Pending |
| VAFI-02 | Phase 113 | Pending |
| LAFI-01 | Phase 109 | Complete |
| LAFI-02 | Phase 109 | Complete |

**Coverage:**
- v2.10 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-08*
*Last updated: 2026-06-08 — roadmap created; Phases 109-113 mapped*
