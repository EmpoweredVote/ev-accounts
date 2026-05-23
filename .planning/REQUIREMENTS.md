# Requirements: Empowered Accounts

**Defined:** 2026-05-22 (v2.5)
**Milestone:** v2.5 City Officials Expansion
**Core Value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.

## v2.5 Requirements (Phases 77–80)

### City Infrastructure (CITY)

- [ ] **CITY-01**: Government stub records for San Jose, San Diego, Berkeley, and Fremont in `essentials.governments` (create if not present; reuse existing rows if already present)
- [ ] **CITY-02**: City council district records for all 4 cities in `essentials.districts` — full seat count per city, typed as `CITY_COUNCIL`, FK'd to their government row
- [ ] **CITY-03**: Politician records for all San Jose city officials (mayor + full council + key appointed roles such as City Attorney, City Clerk, City Administrator)
- [ ] **CITY-04**: Politician records for all San Diego city officials
- [ ] **CITY-05**: Politician records for all Berkeley city officials
- [ ] **CITY-06**: Politician records for all Fremont city officials
- [ ] **CITY-07**: Office records for all new officials linked to their correct city council district (or city-wide seat for mayor and at-large roles)
- [ ] **CITY-08**: `photo_origin_url` populated for all new officials from official city sites, Wikipedia, or Ballotpedia

### City Stances (CSTA)

- [ ] **CSTA-01**: Stance research for all San Jose officials — all 43 topics attempted; city-level topics included; `data-centers` excluded; migration applied
- [ ] **CSTA-02**: Stance research for all San Diego officials (same scope)
- [ ] **CSTA-03**: Stance research for all Berkeley officials (same scope)
- [ ] **CSTA-04**: Stance research for all Fremont officials (same scope)
- [ ] **CSTA-05**: Every stance row paired with a context row in `inform.politician_context` containing at least one source URL

### Gap-fill (GAPF)

- [ ] **GAPF-01**: Audit existing politicians for sparse topic coverage — identify records with < 10 stances where additional evidence is plausibly available (priority: SF officials just ingested with low counts; secondary: any politician in DB with thin coverage)
- [ ] **GAPF-02**: Research and ingest missing topics for all identified politicians; every new stance row paired with a context row

### Campaign Finance (FINA)

- [ ] **FINA-01**: Schema for campaign finance summary — `finance_summary` JSONB column on `inform.politicians` storing `{ total_raised, top_donors: [{ name, amount }], top_industries: [{ name, amount }], cycle, source }` — migration applied
- [ ] **FINA-02**: Finance data ingested for all new city officials and top-priority existing politicians (senators, SF officials) using FEC API (federal) and FPPC Cal-Access (CA state/local); stored via `gen_migration.py`-equivalent ingestion
- [ ] **FINA-03**: Finance summary surfaced on `GET /api/essentials/politicians` response — new `finance_summary` field included when non-null; backward-compatible (null for politicians with no data)

---

## v2.4 Requirements (Phases 75–76) — COMPLETE

### Race Catalog (RACE)

- [x] **RACE-01**: All 34 Class 2 Senate races cataloged — state, current seat holder, major declared candidates, primary date, and current status (primary/general)

### Candidate Records (CAND)

- [x] **CAND-01**: New politician records for all major non-incumbent declared candidates (`office_title = "Candidate for U.S. Senate — [State]"`, same schema as sitting senators)
- [x] **CAND-02**: Office records for non-incumbents linked to their state's NATIONAL_UPPER district (`is_current = false` since they don't hold the seat yet)
- [x] **CAND-03**: Photos (`photo_origin_url`) for non-incumbent candidates — best-effort from Wikipedia, Ballotpedia, or official campaign sites

### Stance Research (SRES)

- [x] **SRES-01**: Stances researched for all non-incumbent candidates via research-stances skill — using WebFetch against vote records, ontheissues.org, Ballotpedia, and official sources
- [x] **SRES-02**: Every candidate stance paired with a context row in `inform.politician_context` containing at least one source URL
- [x] **SRES-03**: Stance gaps filled for newly-appointed incumbents running for re-election (Armstrong OK, Husted OH) where new roll call vote evidence now exists in the 119th Congress 2nd session record

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

### Additional Federal Coverage
- **FED-01**: US House Representatives coverage (435 members) — same infrastructure pattern as Senate; deferred until Senate is complete
- **FED-02**: Extend TIGER geofencing to all 50 states — current CA-only; deferred until federal coverage warrants it

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full state government infrastructure (chambers, state legislature) for all 50 states | Federal stubs only; full state coverage comes with dedicated state-level milestone |
| City officials outside CA | v2.5 focuses on CA cities that already have TIGER geofencing context; other states deferred |
| Automated finance data scraping / scheduled refresh | Manual FEC/FPPC ingestion for Alpha scale; automated pipeline deferred |
| Finance data display UI (politician profile page) | Display belongs in partner apps (CompassV2, Essentials); accounts repo owns the API + data |
| Post-primary nominee update automation | Manual update post-primary via admin tool; automated nomination tracking is future work |
| US House Representatives coverage | Deferred — scope is city officials expansion for v2.5 |
| CompassV2 topic creation (new topics beyond 43) | All 43 topics already exist; this milestone populates stances only |

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
| RACE-01 | Phase 75 | Complete |
| CAND-01 | Phase 75 | Complete |
| CAND-02 | Phase 75 | Complete |
| CAND-03 | Phase 75 | Complete |
| SRES-01 | Phase 76 | Complete |
| SRES-02 | Phase 76 | Complete |
| SRES-03 | Phase 76 | Complete |
| CITY-01 | Phase 77 | Pending |
| CITY-02 | Phase 77 | Pending |
| CITY-03 | Phase 77 | Pending |
| CITY-04 | Phase 77 | Pending |
| CITY-05 | Phase 77 | Pending |
| CITY-06 | Phase 77 | Pending |
| CITY-07 | Phase 77 | Pending |
| CITY-08 | Phase 77 | Pending |
| CSTA-01 | Phase 78 | Pending |
| CSTA-02 | Phase 78 | Pending |
| CSTA-03 | Phase 78 | Pending |
| CSTA-04 | Phase 78 | Pending |
| CSTA-05 | Phase 78 | Pending |
| GAPF-01 | Phase 79 | Pending |
| GAPF-02 | Phase 79 | Pending |
| FINA-01 | Phase 80 | Pending |
| FINA-02 | Phase 80 | Pending |
| FINA-03 | Phase 80 | Pending |

**Coverage:**
- v2.5 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-19 (v2.3) / 2026-05-21 (v2.4) / 2026-05-22 (v2.5)*
*Last updated: 2026-05-22 — v2.5 requirements added; v2.4 marked complete*
