# Requirements: Empowered Accounts

**Defined:** 2026-05-19 (v2.3) / 2026-05-21 (v2.4)
**Milestone:** v2.4 2026 Senate Candidates
**Core Value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.

## v2.4 Requirements (Phases 75–76)

### Race Catalog (RACE)

- [ ] **RACE-01**: All 34 Class 2 Senate races cataloged — state, current seat holder, major declared candidates, primary date, and current status (primary/general)

### Candidate Records (CAND)

- [ ] **CAND-01**: New politician records for all major non-incumbent declared candidates (`office_title = "Candidate for U.S. Senate — [State]"`, same schema as sitting senators)
- [ ] **CAND-02**: Office records for non-incumbents linked to their state's NATIONAL_UPPER district (`is_current = false` since they don't hold the seat yet)
- [ ] **CAND-03**: Photos (`photo_origin_url`) for non-incumbent candidates — best-effort from Wikipedia, Ballotpedia, or official campaign sites

### Stance Research (SRES)

- [ ] **SRES-01**: Stances researched for all non-incumbent candidates via research-stances skill — using WebFetch against vote records, ontheissues.org, Ballotpedia, and official sources
- [ ] **SRES-02**: Every candidate stance paired with a context row in `inform.politician_context` containing at least one source URL
- [ ] **SRES-03**: Stance gaps filled for newly-appointed incumbents running for re-election (Armstrong OK, Husted OH) where new roll call vote evidence now exists in the 119th Congress 2nd session record

---

## v2.3 Requirements (Phases 72–74) — COMPLETE

### Senate Infrastructure (SINF)

- [x] **SINF-01**: NATIONAL_UPPER district records exist in `essentials.districts` for all 50 US states — 45 new state entries added alongside the existing CA, IN, MA, ME, TX entries
- [x] **SINF-02**: Government records exist in `essentials.governments` for all 50 states, providing the anchor rows the NATIONAL_UPPER districts FK to (minimal stubs for states without existing full government records)

### Senator Records (SENA)

- [x] **SENA-01**: All 100 sitting 119th Congress US Senators have politician records in `essentials.politicians` (90 new records; CA, IN, MA, ME, TX senators already exist)
- [x] **SENA-02**: All 100 senators have office records in `essentials.offices` with correct `district_id` linking to their state's NATIONAL_UPPER district row
- [x] **SENA-03**: All 100 senators have `photo_origin_url` populated from an official Senate source or Wikipedia (empty string replaced with actual URL)

### Stance Data (SSTA)

- [x] **SSTA-01**: All 100 senators have stance values in `inform.politician_answers` for all CompassV2 topics applicable to federal officials (of the 43 total topics, local-tier topics are skipped; target ≥ 30 applicable topics per senator)
- [x] **SSTA-02**: Every stance record is paired with a context row in `inform.politician_context` containing at least one source URL (citation) per topic
- [x] **SSTA-03**: The 8 existing senators with partial stance data have gaps filled to match the full applicable-topic coverage of newly added senators

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
| Minor/third-party candidates with no polling presence | Focus is major declared candidates; fringe candidates add noise without civic value |
| CompassV2 topic creation (new topics beyond 43) | All 43 topics already exist; this milestone populates stances, not topics |
| Post-primary nominee update automation | Manual update post-primary via admin tool; automated nomination tracking is future work |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SINF-01 | Phase 72 | Complete |
| SINF-02 | Phase 72 | Complete |
| SENA-01 | Phase 73 | Complete |
| SENA-02 | Phase 73 | Complete |
| SENA-03 | Phase 73 | Complete |
| SSTA-01 | Phase 74 | Complete |
| SSTA-02 | Phase 74 | Complete |
| SSTA-03 | Phase 74 | Complete |
| RACE-01 | Phase 75 | Pending |
| CAND-01 | Phase 75 | Pending |
| CAND-02 | Phase 75 | Pending |
| CAND-03 | Phase 75 | Pending |
| SRES-01 | Phase 76 | Pending |
| SRES-02 | Phase 76 | Pending |
| SRES-03 | Phase 76 | Pending |

**Coverage:**
- v2.4 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-19 (v2.3) / 2026-05-21 (v2.4)*
*Last updated: 2026-05-21 — v2.4 requirements added; v2.3 marked complete*
