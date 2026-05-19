# Requirements: Empowered Accounts

**Defined:** 2026-05-19
**Milestone:** v2.3 US Senate Coverage
**Core Value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.

## v2.3 Requirements (Phases 72–74)

### Senate Infrastructure (SINF)

- [x] **SINF-01**: NATIONAL_UPPER district records exist in `essentials.districts` for all 50 US states — 45 new state entries added alongside the existing CA, IN, MA, ME, TX entries
- [x] **SINF-02**: Government records exist in `essentials.governments` for all 50 states, providing the anchor rows the NATIONAL_UPPER districts FK to (minimal stubs for states without existing full government records)

### Senator Records (SENA)

- [ ] **SENA-01**: All 100 sitting 119th Congress US Senators have politician records in `essentials.politicians` (90 new records; CA, IN, MA, ME, TX senators already exist)
- [ ] **SENA-02**: All 100 senators have office records in `essentials.offices` with correct `district_id` linking to their state's NATIONAL_UPPER district row
- [ ] **SENA-03**: All 100 senators have `photo_origin_url` populated from an official Senate source or Wikipedia (empty string replaced with actual URL)

### Stance Data (SSTA)

- [ ] **SSTA-01**: All 100 senators have stance values in `inform.politician_answers` for all CompassV2 topics applicable to federal officials (of the 43 total topics, local-tier topics are skipped; target ≥ 30 applicable topics per senator)
- [ ] **SSTA-02**: Every stance record is paired with a context row in `inform.politician_context` containing at least one source URL (citation) per topic
- [ ] **SSTA-03**: The 8 existing senators with partial stance data have gaps filled to match the full applicable-topic coverage of newly added senators

---

## v3 Requirements (Deferred)

### Finance Integration
- **FIN-01**: Senator profiles surface campaign finance summary (top donors, total raised, top industries) pulled from Transparent Motivations — front-end handled by Essentials app; no schema change needed in accounts repo

### Additional Federal Coverage
- **FED-01**: US House Representatives coverage (435 members) — same infrastructure pattern as Senate; deferred until Senate is complete
- **FED-02**: Extend TIGER geofencing to all 50 states — current CA-only; deferred until federal coverage warrants it

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full state government infrastructure (chambers, state legislature) for all 50 states | This milestone adds federal stubs only; full state coverage comes when we do state-level coverage per state |
| Finance data stored in accounts schema | Essentials handles TM data display; accounts is politician identity only |
| Historical senators / former officeholders | 119th Congress incumbents only; historical coverage is a separate content effort |
| Candidate challengers for 2026 Senate races | Separate from incumbent profiles; candidate ingestion is a distinct workflow |
| CompassV2 topic creation (new topics beyond 43) | All 43 topics already exist; this milestone populates stances, not topics |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SINF-01 | Phase 72 | Complete |
| SINF-02 | Phase 72 | Complete |
| SENA-01 | Phase 73 | Pending |
| SENA-02 | Phase 73 | Pending |
| SENA-03 | Phase 73 | Pending |
| SSTA-01 | Phase 74 | Pending |
| SSTA-02 | Phase 74 | Pending |
| SSTA-03 | Phase 74 | Pending |

**Coverage:**
- v2.3 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-19*
*Last updated: 2026-05-19 — initial v2.3 definition*
