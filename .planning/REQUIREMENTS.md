# Requirements: Empowered Vote Platform

**Defined:** 2026-02-26
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1.8 Requirements

Requirements for v1.8: Compass Data & Politician Research. Each maps to roadmap phases.

### Stance Research

- [ ] **STANCE-01**: Stance data CSV exists with politician name, topic_key, stance value (1-5), and source URL columns
- [ ] **STANCE-02**: Each stance is supported by multiple reputable sources where possible (news sites, campaign websites, voting records, bills sponsored/signed/vetoed)
- [ ] **STANCE-03**: CA state officials researched — Governor Newsom, Lt. Governor Kounalakis
- [ ] **STANCE-04**: IN state officials researched — Governor Braun, Lt. Governor Beckwith
- [ ] **STANCE-05**: CA US Senators researched — Padilla, Schiff
- [ ] **STANCE-06**: IN US Senators researched — Young, Banks
- [ ] **STANCE-07**: Monroe County, IN US House representative(s) researched
- [ ] **STANCE-08**: All LA County, CA US House representatives researched
- [ ] **STANCE-09**: Bloomington, IN Mayor Thomson researched
- [ ] **STANCE-10**: Los Angeles, CA Mayor Bass researched

### Quote Collection

- [ ] **QUOTE-01**: Direct quotes gathered from target politicians on compass topics
- [ ] **QUOTE-02**: Each quote includes source URL and date of statement
- [ ] **QUOTE-03**: Quotes are verbatim statements from the politicians (not paraphrased)
- [ ] **QUOTE-04**: Quote data formatted as CSV ready for Read & Rank import

### Legacy Cleanup

- [ ] **CLEAN-01**: Old 50-topic topics.json data file removed from repository
- [ ] **CLEAN-02**: Old seeds/topics.go seed function removed
- [ ] **CLEAN-03**: Old seeds/categories.go hardcoded category map removed
- [ ] **CLEAN-04**: 21-topic/5-stance CSV and compass_csv_seeder.go remain as sole source of truth

### Data Import

- [ ] **IMPORT-01**: Import script loads stance research CSV into compass.answers table with politician_id mapping
- [ ] **IMPORT-02**: Import script loads quotes into a format usable by Read & Rank
- [ ] **IMPORT-03**: Import validates stance values are 1-5 and topic_keys match existing topics

## Future Requirements

### Regional Expansion

- **REGION-01**: Expand stance research to additional states/regions
- **REGION-02**: Automate stance research pipeline with web scraping

### Read & Rank Enhancement

- **RR-01**: Real-time quote discovery from RSS feeds or news APIs
- **RR-02**: User-submitted quotes with verification workflow

## Out of Scope

| Feature | Reason |
|---------|--------|
| Automated web scraping for stances | Research quality requires human judgment on source reliability |
| Stances for local/county officials | Starting with high-profile federal and state officials first |
| School board or city council stances | Low public record availability for local officials |
| AI-generated stance summaries | Must be sourced from real public statements, not inferred |
| Expanding beyond CA and IN | Two-state pilot first, expand in future milestone |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| STANCE-01 | — | Pending |
| STANCE-02 | — | Pending |
| STANCE-03 | — | Pending |
| STANCE-04 | — | Pending |
| STANCE-05 | — | Pending |
| STANCE-06 | — | Pending |
| STANCE-07 | — | Pending |
| STANCE-08 | — | Pending |
| STANCE-09 | — | Pending |
| STANCE-10 | — | Pending |
| QUOTE-01 | — | Pending |
| QUOTE-02 | — | Pending |
| QUOTE-03 | — | Pending |
| QUOTE-04 | — | Pending |
| CLEAN-01 | — | Pending |
| CLEAN-02 | — | Pending |
| CLEAN-03 | — | Pending |
| CLEAN-04 | — | Pending |
| IMPORT-01 | — | Pending |
| IMPORT-02 | — | Pending |
| IMPORT-03 | — | Pending |

**Coverage:**
- v1.8 requirements: 21 total
- Mapped to phases: 0
- Unmapped: 21 ⚠️

---
*Requirements defined: 2026-02-26*
*Last updated: 2026-02-26 after initial definition*
