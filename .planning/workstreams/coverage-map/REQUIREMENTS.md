# Requirements: Empowered Accounts — v2.23 Coverage Map 1.1

**Defined:** 2026-07-04
**Workstream:** coverage-map (parallel to v2.22 US House Candidate Coverage)
**Core Value:** Every platform feature can answer "does this user have permission to do X?" with a single join — and for this milestone: the coverage map answers "what does a user in this area actually get?" truthfully, from live data.

> **History note:** This milestone was originally drafted as "v2.20 Coverage Map 1.1 / Phases 148–152" in an offline clone before the team's real v2.20 (US House Wave 1) had synced. Those identifiers were already shipped upstream, so the work was re-homed here: **milestone v2.23, phases 168–172**, in the `coverage-map` workstream. Requirement IDs (CMAP/ELEC/CITY/UAPI) are unchanged.

## v2.23 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Coverage Core (CMAP)

- [ ] **CMAP-01**: Admin sees DB-derived completeness coverage for all 50 states on the map — no state is hidden or gray solely because it lacks a coverage YAML file
- [ ] **CMAP-02**: Coverage YAML files act only as an import-targets overlay (expected_seats, planned imports) on the DB-derived base — admin can still see "what's left to import" where targets exist
- [ ] **CMAP-03**: Map and API distinguish "not yet covered/imported" from "confirmed no data expected" as distinct visual and response states — never conflated with zero
- [ ] **CMAP-04**: Jurisdictions with unknown roster size (no expected_seats target) surface roster completeness as unknown rather than silently renormalizing the axis away
- [ ] **CMAP-05**: Coverage table shows a per-criterion breakdown (which axes each geography met) at state, county, and city levels — not just an aggregate score
- [ ] **CMAP-06**: Existing admin map functionality (7-axis completeness, hover cards, county drill-down, table) works unchanged on the DB-derived base for previously YAML-tracked states

### Elections Accuracy (ELEC)

- [x] **ELEC-01**: Elections coverage reports statewide/legislative races and county/local-pinnable races as separately computed metrics per state — a state with only statewide races can no longer display an undifferentiated 100%
- [x] **ELEC-02**: Clicking a state in elections mode shows a statewide-races panel listing its statewide/legislative races with candidate coverage
- [x] **ELEC-03**: State-level and county-level elections numbers are computed from consistent denominators — clicking a state never shows data that contradicts its map score (the Michigan bug)
- [x] **ELEC-04**: Elections coverage is measured as a 3-tier depth indicator (Tier 1 = candidate names only; Tier 2 = names + compass stances OR transparent motivations; Tier 3 = names + stances + transparent motivations), replacing the single breadth count of races with ≥1 candidate — with tier thresholds defined once and reused by backend computation and UI
- [ ] **ELEC-05**: Per-race and per-panel readouts show a covered/total breakdown by tier (each race row shows its own tier; the panel header shows totals per tier), so admin sees depth of civic data, not just whether any candidate name exists
- [ ] **ELEC-06**: The `StateElection`/`RaceRow` payload contract and the state choropleth fill + legend reflect the tiered metric — a state with names but no stances/motivations no longer reads as fully covered

### City Drill-down (CITY)

- [ ] **CITY-01**: Admin can click a county and see its incorporated places rendered as a third zoom level, colored by coverage, with boundaries served from existing PostGIS geofence data
- [ ] **CITY-02**: Unresearched cities render as a distinct "not yet covered" state, and the incorporated-places-only scope is labeled so CDP-heavy counties don't read as broken

### User Metric & Port-Ready API (UAPI)

- [ ] **UAPI-01**: A user-relevant coverage metric (officials present + stances present + elections data present) is computed per geography, structurally separate from the admin 7-axis composite
- [ ] **UAPI-02**: Public `/api/coverage/*` endpoints expose the user-relevant metric with independent response types, cache headers, and no admin-internal fields — consumable by Essentials without auth
- [ ] **UAPI-03**: The coverage API contract is documented for the Essentials team following the existing integration-doc conventions

## Future Requirements

Deferred to a later milestone. Tracked but not in the current roadmap.

### Essentials Consumption

- **ESSC-01**: Essentials frontend renders the user-facing coverage map from `/api/coverage/*`
- **ESSC-02**: Nationwide place-level coverage rollup via precomputed summary table (only needed once Essentials shows a national city-level view)

### Coverage Analytics

- **CHIST-01**: Historical coverage trend tracking (coverage-over-time snapshots)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Essentials UI work | This milestone ships the port-ready API only; UI lives in the Essentials repo later |
| Single unified coverage score for admin + users | The explicit anti-feature this milestone fixes — two separately-computed, separately-labeled metrics |
| Deep per-field completeness (photos/donors/treasury %) in the public API | Re-couples Essentials to admin internals; user metric is the three-part answer only |
| Real-time recomputation on every page load | Data changes on day/week cadence; cached/TTL computation matches existing patterns |
| Nationwide address→place geocoding capability | Long-tail boundary problem; city drill-down uses TIGER places already in PostGIS |
| Fourth zoom level (neighborhood/precinct) | No requirement backing; drill-down UX value drops sharply past city level |
| CDP (census-designated place) boundaries | Places layer is intentionally incorporated-places-only (elected governments); labeled, not expanded |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CMAP-01 | 169 | Pending |
| CMAP-02 | 169 | Pending |
| CMAP-03 | 169 | Pending |
| CMAP-04 | 169 | Pending |
| CMAP-05 | 170 | Pending |
| CMAP-06 | 169 | Pending |
| ELEC-01 | 168 | Complete |
| ELEC-02 | 168 | Complete |
| ELEC-03 | 168 | Complete |
| ELEC-04 | 168.1 | Complete |
| ELEC-05 | 168.1 | Pending |
| ELEC-06 | 168.1 | Pending |
| CITY-01 | 170 | Pending |
| CITY-02 | 170 | Pending |
| UAPI-01 | 171 | Pending |
| UAPI-02 | 172 | Pending |
| UAPI-03 | 172 | Pending |

**Coverage:**

- v2.23 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-04*
*Re-homed from the offline v2.20/148–152 draft to v2.23/168–172 (coverage-map workstream) on 2026-07-04*
