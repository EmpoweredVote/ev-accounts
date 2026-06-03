# Requirements: Empowered Accounts

**Defined:** 2026-06-02 (v2.6)
**Milestone:** v2.6 Data Quality & Elections
**Core Value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.

## v2.6 Requirements (Phases 87–90, 99)

### Stance Accuracy (SACC)

- [x] **SACC-01**: Audit script produces a complete accuracy report across all ~1,049 politicians — flag scores, prioritized correction list, and evidence summary for each flagged case
- [x] **SACC-02**: All politicians confirmed as having accuracy issues are individually re-researched with real sources and corrected via migration(s); each correction requires at least one fetched source URL
- [x] **SACC-03**: Party string inconsistency resolved — all politicians have a normalized party value (no mixed "Democrat" / "Democratic" entries)
- [x] **SACC-04**: Researcher agent (`SKILL.md`) updated with five-chairs framing to prevent future stance inversions

### Gap-fill (GAPF)

- [ ] **GAPF-01**: Audit all existing politicians for < 10 stances; produce a prioritized target list (sorted by politician prominence + coverage gap size)
- [x] **GAPF-02**: Research and ingest missing stances for all identified targets; every new stance row paired with a context row containing at least one source URL

### Campaign Finance (FINA)

- [ ] **FINA-01**: `finance_summary` JSONB column added to `inform.politicians` storing `{ total_raised, top_donors: [{ name, amount }], cycle, source }`; migration applied
- [ ] **FINA-02**: FEC API ingestion script built and run; finance data loaded for all federal politicians (senators + 2026 candidates) with `total_raised`, `top_donors` (top 10 by employer string), `cycle`, `source: "FEC"`; uses `congress-legislators` YAML for bioguide → FEC ID crosswalk
- [ ] **FINA-03**: `GET /api/essentials/politicians` and single-politician endpoints return `finance_summary` when non-null; `null` for politicians with no data; fully backward-compatible

### Elections (ELEC)

- [ ] **ELEC-01**: Elections page at `/elections` human-verified — all displayed politicians, races, and dates confirmed accurate
- [ ] **ELEC-02**: All issues found during ELEC-01 verification resolved (UI bugs, data errors, or missing coverage)
- [ ] **ELEC-03**: Elections feature declared shipped — smoke test passes; feature noted in MILESTONES.md

---

## v2.5 Requirements (Phases 77–78) — COMPLETE

### City Infrastructure (CITY)

- [x] **CITY-01**: Government stub records for San Jose, San Diego, Berkeley, and Fremont in `essentials.governments`
- [x] **CITY-02**: City council district records for all 4 cities in `essentials.districts` — full seat count per city, typed as `CITY_COUNCIL`, FK'd to their government row
- [x] **CITY-03**: Politician records for all San Jose city officials
- [x] **CITY-04**: Politician records for all San Diego city officials
- [x] **CITY-05**: Politician records for all Berkeley city officials
- [x] **CITY-06**: Politician records for all Fremont city officials
- [x] **CITY-07**: Office records for all new officials linked to their correct city council district
- [x] **CITY-08**: `photo_origin_url` populated for all new officials

### City Stances (CSTA)

- [x] **CSTA-01**: Stance research for San Jose officials — Matt Mahan only; SJ council deferred due to evidence gaps
- [x] **CSTA-02**: Stance research for all San Diego officials (184 stances, migration applied)
- [x] **CSTA-03**: Stance research for all Berkeley officials (154 stances, migration applied)
- [x] **CSTA-04**: Stance research for all Fremont officials (56 stances, migration applied)
- [x] **CSTA-05**: Every stance row paired with context row containing at least one source URL — verified 0 orphans across 591 rows

---

## v2.4 Requirements (Phases 75–76) — COMPLETE

### Race Catalog (RACE)

- [x] **RACE-01**: All 34 Class 2 Senate races cataloged — state, current seat holder, major declared candidates, primary date, and current status

### Candidate Records (CAND)

- [x] **CAND-01**: New politician records for all major non-incumbent declared candidates
- [x] **CAND-02**: Office records for non-incumbents linked to their state's NATIONAL_UPPER district
- [x] **CAND-03**: Photos (`photo_origin_url`) for non-incumbent candidates

### Stance Research (SRES)

- [x] **SRES-01**: Stances researched for all non-incumbent candidates via research-stances skill
- [x] **SRES-02**: Every candidate stance paired with a context row containing at least one source URL
- [x] **SRES-03**: Stance gaps filled for newly-appointed incumbents running for re-election (Armstrong OK, Husted OH)

---

## v2.3 Requirements (Phases 72–74) — COMPLETE

### Senate Infrastructure (SINF)

- [x] **SINF-01**: NATIONAL_UPPER district records for all 50 US states in `essentials.districts`
- [x] **SINF-02**: Government records in `essentials.governments` for all 50 states

### Senator Records (SENA)

- [x] **SENA-01**: All 100 119th Congress US Senators have politician records
- [x] **SENA-02**: All 100 senators have office records with correct `district_id`
- [x] **SENA-03**: All 100 senators have `photo_origin_url` from official Senate source or Wikipedia

### Stance Data (SSTA)

- [x] **SSTA-01**: All 100 senators have stances for all applicable CompassV2 topics (≥ 30 per senator)
- [x] **SSTA-02**: Every stance record paired with a context row containing at least one source URL
- [x] **SSTA-03**: 8 existing senators with partial stances filled to full applicable-topic coverage

---

## v3 Requirements (Deferred)

### Additional Federal Coverage

- **FED-01**: US House Representatives coverage (435 members) — deferred until Senate is complete
- **FED-02**: Extend TIGER geofencing to all 50 states — deferred until federal coverage warrants it

### Campaign Finance (Deferred from v2.6)

- **FINA-CA**: Cal-Access ingestion for CA state officials (Assembly + Senate) — deferred; requires bulk download + join pipeline
- **FINA-CITY**: City-level finance ingestion via per-city NetFile portals (SF Ethics, SD Open Data, Berkeley/Fremont/SJ NetFile API) — deferred; different source per city, partially undocumented APIs
- **FINA-OR**: Multnomah County finance via ORESTAR — deferred; no API, manual export only
- **FINA-IND**: `top_industries` field in finance_summary — deferred; requires OpenSecrets bulk data access (must apply; API discontinued Apr 2025)

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full state government infrastructure for all 50 states | Federal stubs only; full state coverage in a dedicated state-level milestone |
| Automated finance data scheduled refresh | Manual FEC ingestion for Alpha scale; automated pipeline deferred |
| Finance data display UI (politician profile page) | Display belongs in partner apps (CompassV2, Essentials); accounts repo owns API + data |
| Post-primary nominee update automation | Manual update post-primary; automated nomination tracking is future work |
| US House Representatives coverage | Deferred — Senate + city officials first |
| CompassV2 topic creation (new topics beyond 43) | All 43 topics already exist; this milestone populates and corrects stances only |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SACC-01 | Phase 87 | Complete |
| SACC-04 | Phase 87 | Complete |
| SACC-02 | Phase 88 | Complete |
| SACC-03 | Phase 88 | Complete |
| GAPF-01 | Phase 89 | Pending |
| GAPF-02 | Phase 89 | Complete |
| FINA-01 | Phase 90 | Pending |
| FINA-02 | Phase 90 | Pending |
| FINA-03 | Phase 90 | Pending |
| ELEC-01 | Phase 99 | Pending |
| ELEC-02 | Phase 99 | Pending |
| ELEC-03 | Phase 99 | Pending |
| CITY-01–08 | Phase 77 | Complete |
| CSTA-01–05 | Phase 78 | Complete |
| RACE-01 | Phase 75 | Complete |
| CAND-01–03 | Phase 75 | Complete |
| SRES-01–03 | Phase 76 | Complete |
| SINF-01–02 | Phase 72 | Complete |
| SENA-01–03 | Phase 73 | Complete |
| SSTA-01–03 | Phase 74 | Complete |

**Coverage:**

- v2.6 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-19 (v2.3) / 2026-05-21 (v2.4) / 2026-05-22 (v2.5) / 2026-06-02 (v2.6)*
*Last updated: 2026-06-02 — v2.6 requirements defined; v2.5 CITY+CSTA marked complete; GAPF+FINA carried forward with updated scope*
