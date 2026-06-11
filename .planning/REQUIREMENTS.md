# Requirements: v2.11 FEC Finance Completion + US House Geofencing

## FEC Finance Completion

- [ ] **FECF-01**: `fix-fec-name-mismatches.ts` updated with committee lookup fallback — after `principal_committees` returns empty, script falls back to `GET /v1/candidate/{id}/committees/` and tries cycles 2026, 2024, 2022 until a committee is found
- [ ] **FECF-02**: `finance_summary` populated for all 4 already-matched politicians (Glenn Ivey, Keith Self, Raphael Warnock, Ted Cruz) by re-running the fixed script live
- [ ] **FECF-03**: FEC candidate IDs resolved for Doug LaMalfa and Eric Swalwell (sitting House members absent from congress-legislators YAML) via direct `GET /v1/candidates/search/?name=X&office=H`; `finance_summary` populated for both; `politician_sources` rows written with confirmed status
- [ ] **FECF-04**: FEC candidate IDs researched for all reachable 2026 Senate candidates in our DB via direct FEC API lookup; `finance_summary` populated for every candidate with an FEC filing; `politician_sources` rows written for all confirmed matches
- [ ] **FECF-05**: Paul Strauss and Ankit Jain (DC Shadow Senators, no FEC filings) each have a `politician_sources` row with `research_status = 'not_applicable'` and a notes field explaining why (shadow delegates do not file with FEC)

## US House Geofencing

- [ ] **UHGE-01**: TIGER 2024 national CD119 shapefile (all 435 congressional districts) imported into `essentials.geo_districts` with `layer = 'us_house'`; existing CA rows (52) are preserved via `ON CONFLICT DO NOTHING`; GIST index verified present
- [ ] **UHGE-02**: `tiger_geoid` backfilled on all `essentials.districts` rows with `district_type = 'NATIONAL_LOWER'` across all states — every House district record has a non-null `tiger_geoid` matching the imported polygon
- [ ] **UHGE-03**: Path 0 geofencing verified working for at least one non-CA US address (e.g. TX or NY congressional district) — `GET /api/essentials/representatives/me` for a user with stored district data returns the correct House rep via the `tiger_geoid` join, confirming the national layer is live

## Future Requirements

- Finance data for VA state officials via VPAP — HTML-only source, deferred (no machine-readable API)
- 2026 Senate candidate finance updates post-primary — nominees will have more complete FEC filings
- Finance data for LA County city officials beyond CAL-ACCESS coverage (Netfile gap documented)

## Out of Scope

- State-level TIGER imports beyond what already exists (CA assembly/senate, VA SLDL/SLDU, DC wards) — each state expansion is a separate milestone
- Senate district geofencing for other states — only US House (NATIONAL_LOWER) is in scope here
- VPAP scraping for VA state officials — non-machine-readable, not worth engineering investment

## Traceability

| REQ | Phase |
|-----|-------|
| FECF-01 | Phase 114 |
| FECF-02 | Phase 114 |
| FECF-03 | Phase 114 |
| FECF-04 | Phase 115 |
| FECF-05 | Phase 115 |
| UHGE-01 | Phase 116 |
| UHGE-02 | Phase 116 |
| UHGE-03 | Phase 116 |
