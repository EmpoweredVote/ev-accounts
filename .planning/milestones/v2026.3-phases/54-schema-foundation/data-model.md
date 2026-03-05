# Data Model Inventory — Phase 54 Schema Foundation

**Purpose:** Confirms what legislative data is actually available per jurisdiction before any import phase begins. Tables in the schema remain empty for jurisdictions where data is unavailable — no schema changes are needed for empty states.

**Scope:** Federal, Indiana, California, Bloomington IN, LA County CA

---

## Jurisdiction × Data Type Availability Matrix

| Jurisdiction | Sessions | Committees | Memberships | Leadership | Bills | Cosponsors | Votes | IDs |
|---|---|---|---|---|---|---|---|---|
| Federal | Yes (congress-legislators YAML + Congress.gov API v3) | Yes (congress-legislators YAML committees files + Congress.gov) | Yes (congress-legislators YAML, per-session) | Yes (congress-legislators YAML — derived from committee chair positions and leadership titles) | Yes (Congress.gov API v3 — all introduced legislation) | Yes (Congress.gov API v3 — cosponsor endpoint per bill) | House: Yes (Congress.gov API v3), Senate: Yes (LegiScan — Congress.gov v3 excludes Senate roll calls) | bioguide (congress-legislators YAML primary) |
| Indiana | Yes (LegiScan — session list per state) | Yes (LegiScan — committee directory) | Yes (LegiScan — committee members per session) | No (not in LegiScan — would require manual entry or separate scraping) | Yes (LegiScan — full bill text and status) | Yes (LegiScan — cosponsor field on bill) | Yes (LegiScan — roll call votes with member attribution) | legiscan_id (LegiScan person ID) |
| California | Yes (LegiScan) | Yes (LegiScan) | Yes (LegiScan) | No (not in LegiScan) | Yes (LegiScan) | Yes (LegiScan) | Yes (LegiScan) | legiscan_id (LegiScan person ID) |
| Bloomington IN | Manual (city council terms require manual entry) | Partial (city website listing, may require HTML scraping — no structured API) | Partial (city website committee pages, unconfirmed machine-readable format) | No (no structured source) | Partial (city clerk meeting minutes available, but bill-level data unconfirmed from structured source) | No | No (no individual vote attribution from any structured source — confirmed infeasible) | Manual name match only |
| LA County CA | Manual (board of supervisors terms) | Yes (Legistar web API — `webapi.legistar.com/v1/LACounty/Bodies`) | Yes (Legistar web API — `/BodyMembers` endpoint) | No (no structured source) | Partial (Legistar matters — agenda items, not full bill text) | No | No (no individual vote attribution — Legistar tracks matter status, not member vote records) | legistar_id (Legistar person/body ID) |

---

## Schema Coverage Summary

The 8 legislative tables created in Plan 54-01 cover all data types in the matrix:

| Table | Covers |
|-------|--------|
| `essentials.legislative_sessions` | Sessions column |
| `essentials.legislative_committees` | Committees column |
| `essentials.legislative_committee_memberships` | Memberships column |
| `essentials.legislative_leadership_roles` | Leadership column |
| `essentials.legislative_bills` | Bills column |
| `essentials.legislative_bill_cosponsors` | Cosponsors column |
| `essentials.legislative_votes` | Votes column |
| `essentials.legislative_politician_id_map` | IDs column (all jurisdictions) |

Tables remain empty for jurisdictions where data is unavailable. No schema changes are needed — the existing tables handle all reachable data types.

---

## ID Bridge Status

The `essentials.legislative_politician_id_map` table supports the following ID types:

| ID Type | Source | Jurisdiction | Phase |
|---------|--------|--------------|-------|
| `bioguide` | unitedstates/congress-legislators YAML | Federal (US Congress) | Phase 54 (this plan) |
| `legiscan` | LegiScan person ID | Indiana, California | Phase 57 |
| `legistar` | Legistar web API | LA County CA | Phase 58 |
| `ocd_person` | Open Civic Data person ID | Multi-jurisdiction (verification layer) | TBD |
| `openstates` | Open States person ID | State legislatures (verification layer) | TBD |

Phase 54 populates `bioguide` only. Future phases add `legiscan` (Phase 57) and `legistar` (Phase 58). The bridge table is the prerequisite for all import phases — without it, imported data cannot be linked to existing politician records.

---

## Notes on Data Gaps

### Federal
- **Leadership roles:** congress-legislators YAML does not have a structured `leadership_role` field. Leadership is derived from known titles in the `terms` array (e.g., `title: "Speaker of the House"`) and from committee chair designations. This requires a small inference step during import rather than direct field mapping.
- **Senate votes:** Congress.gov API v3 does not include Senate roll call votes as of March 2026. LegiScan covers US Senate voting records and is the confirmed source for Senate vote data.

### State (Indiana, California)
- **Leadership roles:** LegiScan does not include chamber leadership information (Speaker, Majority Leader, etc.). These roles would require manual data entry or a separate state government website scraper — out of scope for this milestone.

### Local (Bloomington IN, LA County CA)
- **Individual vote attribution:** Both jurisdictions lack machine-readable individual vote records from any structured source. Bloomington city council and LA County Board of Supervisors track votes at the matter/item level, not per-member. This is confirmed infeasible — the `legislative_votes` table will remain empty for these jurisdictions.
- **Bloomington OnBoard REST API:** Endpoints not confirmed as of Phase 54 research. Requires direct validation against `data.bloomington.in.gov` before Phase 58 design. Fallback is HTML scraping, but vote data remains unavailable regardless of scraping method.
- **LA County Legistar token:** Manual validation of `webapi.legistar.com/v1/LACounty/VoteRecords` needed before Phase 58. Token gating may limit access to matter-level data only (consistent with no individual vote attribution).
