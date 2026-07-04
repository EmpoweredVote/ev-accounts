# Roadmap: Empowered Accounts — v2.23 Coverage Map 1.1

**Workstream:** coverage-map (runs parallel to the v2.22 US House Candidate Coverage workstream)

> **Numbering note:** Re-homed from an offline draft that used the already-shipped identifiers "v2.20 / Phases 148–152". Now **v2.23, Phases 168–172** — following the v2.22 House milestone (which used through phase 167). Requirement IDs unchanged.

---

### v2.23 Coverage Map 1.1 (Phases 168–172) — IN PROGRESS

**Milestone goal:** Make the coverage map an accurate, database-derived reflection of what users actually get in their area (officials + stances + elections), with full national → state → county → city drill-down and a port-ready API for Essentials.

**Key context:** Root cause of the Michigan 100%-but-empty bug: `getElectionsStateScores()` counts all upcoming races with ≥1 candidate regardless of geography, while the county drill-down (`resolveRaceCountyFips`) only shows county/place-pinnable races — a state with only statewide/legislative races shows 100% and all-unknown counties. Second gap: the completeness map only renders YAML-tracked states (~9), hiding real nationwide coverage. Target architecture: a shared jurisdiction-signals core (`coverageCore.ts`) with two thin lenses — the existing admin 7-axis "everything view" (re-sourced from DB, not YAML) and a new 3-axis "user-relevant" lens (officials + stances + elections). YAML is inverted from gate to optional import-targets overlay. No Essentials UI work this milestone.

---

#### Phase 168: Elections Accuracy Fix

**Goal:** Elections coverage numbers are computed correctly — a state with only statewide/legislative races can no longer show an undifferentiated 100%, and clicking into a state never contradicts its own map score.

**Depends on:** Nothing (first phase; isolated, no schema change; front-loads the highest-value, lowest-risk fix)

**Requirements:** ELEC-01, ELEC-02, ELEC-03

**Success Criteria** (what must be TRUE):

  1. Admin viewing the elections map sees statewide/legislative race coverage and county/local-pinnable race coverage reported as two separate numbers per state, both computed from one shared geographic-scope classifier.
  2. Clicking a state in elections mode opens a panel listing that state's statewide/legislative races with their candidate coverage.
  3. A state with only statewide races (the Michigan case) no longer displays 100% while every county drill-down shows empty — state-level and county-level numbers are computed from consistent denominators over the same race data.

**Plans:** TBD

---

#### Phase 169: DB-Derived Coverage Core

**Goal:** The admin coverage map's completeness picture comes from the live database for every state in the union — no state is invisible or miscounted because a coverage YAML file does or doesn't exist for it.

**Depends on:** Phase 168 (the shared geographic-scope classifier this phase generalizes originates there; the extraction must be verified as behavior-preserving before new surface area is built on top)

**Requirements:** CMAP-01, CMAP-02, CMAP-03, CMAP-04, CMAP-06

**Success Criteria** (what must be TRUE):

  1. Admin sees completeness data rendered for all 50 states on the map, including states that have never had a coverage YAML file.
  2. For states with a coverage YAML file, admin still sees "what's left to import" (expected_seats, planned imports) as an overlay on top of the DB-derived numbers — YAML never gates whether a state/county appears.
  3. Admin can visually distinguish, and the API response structurally distinguishes, "not yet covered/imported" from "confirmed nothing exists here" — these are never conflated with a plain zero.
  4. A jurisdiction with no known roster target (no expected_seats) shows its roster axis as explicitly unknown rather than being silently renormalized out of the score.
  5. Every existing admin map feature (7-axis completeness, hover cards, county drill-down, table) continues to work unchanged for the states that were already YAML-tracked before this phase.

**Plans:** TBD

**UI hint:** yes

---

#### Phase 170: City/Place Drill-down

**Goal:** Admin can drill down a third level — from county to the incorporated cities/places inside it — and see per-criterion coverage at every level of the state → county → city hierarchy.

**Depends on:** Phase 169 (must be built against the DB-derived universe, not the YAML-gated one, to avoid rework once the core inverts)

**Requirements:** CITY-01, CITY-02, CMAP-05

**Success Criteria** (what must be TRUE):

  1. Admin can click a county on the map and see its incorporated places rendered as a third zoom level, colored by coverage, using existing PostGIS geofence boundary data (`essentials.geofence_boundaries`, `G4110`) with no new data ingestion required.
  2. Cities with no researched civic data render as a visually distinct "not yet covered" state, and the UI labels the incorporated-places-only scope so CDP-heavy counties (e.g. rural AZ/NM/CA) don't read as broken.
  3. The coverage table shows a per-criterion breakdown (which axes each geography met) at the state, county, and city levels — not just a single aggregate score.

**Plans:** TBD

**UI hint:** yes

---

#### Phase 171: User-Relevant Coverage Metric

**Goal:** A resident-facing question — "what do I actually get at my address?" — has its own simple, structurally separate answer, distinct from the admin's internal data-quality composite.

**Depends on:** Phase 168 (uses the fixed elections split as an input signal); Phase 169 (built on the shared jurisdiction-signals core, not duplicating its PostGIS spatial joins)

**Requirements:** UAPI-01

**Success Criteria** (what must be TRUE):

  1. Every geography has a computed 3-axis metric (officials present + stances present + elections data present) that is structurally separate from the admin 7-axis composite — a distinct response shape, not a filtered view of the same score.
  2. The user-relevant metric and the admin view can each be inspected independently for the same geography without one overwriting or being derived by trimming the other.

**Plans:** TBD

---

#### Phase 172: Port-Ready Public API

**Goal:** A partner team (Essentials) can integrate against a documented, stable, public coverage endpoint contract without needing admin credentials or internal knowledge of the admin data model.

**Depends on:** Phase 171 (the user-relevant metric is the payload this API exposes; built last, against an already-stabilized core, since an external consumer contract is the most expensive thing to change after the fact)

**Requirements:** UAPI-02, UAPI-03

**Success Criteria** (what must be TRUE):

  1. `GET /api/coverage/*` endpoints return the user-relevant coverage metric over HTTP with no authentication required, matching the existing `/api/essentials/*` public-route posture.
  2. Responses use independently-defined types (never a trimmed reuse of admin `CountyScore`/`StateScore`) with appropriate cache headers, and contain no admin-internal fields (no treasury, donor, or YAML roster-target data).
  3. A written integration reference for the Essentials team exists, following the same document conventions as `COMPASSV2-INTEGRATION.md` / `ESSENTIALS-INTEGRATION.md`.

**Plans:** TBD

---

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 168. Elections Accuracy Fix | 0/TBD | Not started | - |
| 169. DB-Derived Coverage Core | 0/TBD | Not started | - |
| 170. City/Place Drill-down | 0/TBD | Not started | - |
| 171. User-Relevant Coverage Metric | 0/TBD | Not started | - |
| 172. Port-Ready Public API | 0/TBD | Not started | - |

---
*Roadmap re-homed from the offline v2.20/148–152 draft to v2.23/168–172 (coverage-map workstream) on 2026-07-04. 14/14 requirements mapped.*
