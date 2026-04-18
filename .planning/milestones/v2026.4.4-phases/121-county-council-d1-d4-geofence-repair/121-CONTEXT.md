# Phase 121: County Council D1→D4 Geofence Repair - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix Monroe County Council (MCC) district resolution so that a voter at a Kirkwood Ave
Bloomington address is returned the correct single Monroe County Council district via
the address-based PostGIS lookup — not all four MCC districts, and not the wrong one.

**In scope:**
- Diagnose end-to-end at the DB level: does `essentials.geofence_boundaries` hold any
  sub-county MCC district polygons? Are the 4 `Monroe County Council District N` offices
  each linked to the right district / geo_id? What does a live `ST_Covers` query return
  for the Kirkwood point?
- Determine the authoritative correct MCC district for 200 W Kirkwood Ave, Bloomington IN
  47404 from Monroe County's own elections/GIS source (ground truth is currently disputed
  between ROADMAP.md and GAP-REPORT.md — see D-01).
- If sub-district polygons are missing, source them from Monroe County GIS / ArcGIS,
  import into `essentials.geofence_boundaries`, and re-link each MCC District office
  to the right geofence.
- If a single polygon is mis-coordinated, repair it.
- Verify the fix using the same Kirkwood test address pattern from Phase 119 and the
  `scripts/audit-112-geofence.ts` smoke test.

**Out of scope:**
- Mt Tabor Rd geocoding failure (AUDIT-08) and rural address geocoding — belongs to
  Phase 126 Geofence Hardening.
- Township polygon fallbacks (`link-monroe-county-races-to-geofences.sql` §1c COALESCE
  to county geofence) — Phase 126.
- Any other county's council districts, or any non-council sub-county districts.
- Data sourcing for candidate records (Phase 117, Phase 120).
- Frontend UI changes — this is a backend / data repair only.

</domain>

<decisions>
## Implementation Decisions

### Ground Truth
- **D-01:** The correct Monroe County Council district for 200 W Kirkwood Ave,
  Bloomington IN 47404 is **currently unverified**. ROADMAP.md §Phase 121 says "D4 not
  D1"; GAP-REPORT PATTERN-004 and `research/benchmark/ballotpedia.md` both say D1 is
  correct. Research step must consult an authoritative source (Monroe County Elections
  website / Monroe County GIS precinct-to-council-district map) to establish ground
  truth **before any data is written**. Whichever of ROADMAP or GAP-REPORT is wrong
  must be corrected as part of this phase's documentation updates.

### Fix Scope
- **D-02:** Diagnose first, scope later. The research step must confirm at the
  live-DB level (not just by reading SQL scripts) whether sub-district MCC polygons
  exist in `essentials.geofence_boundaries`, and what the `Monroe County Council
  District N` offices are currently linked to. Scout evidence suggests all four link
  to the shared county-wide `geo_id='18105'` record, but this must be verified
  against production/dev DB, not inferred from the seed script.
- **D-03:** The planner picks the fix approach **after** diagnosis:
  - If sub-district polygons are missing: structural import (source 4 polygons, insert
    rows, re-link offices, rewrite the relevant block of
    `scripts/link-monroe-county-races-to-geofences.sql`).
  - If a single existing polygon is mis-coordinated: targeted polygon repair.
  - Either way, all four MCC District races must ultimately resolve to their own
    distinct geofence so an address matches exactly one.

### Data Source
- **D-04:** Authoritative polygon source is **Monroe County GIS / ArcGIS**. This
  matches the existing pattern for LA County (per CLAUDE.md "Geofences: TIGER 2024
  shapefiles + ArcGIS (LA County)"). Do not fall back to TIGER VTDs or state
  redistricting datasets without escalating — those are precinct-level, not
  council-district-level, and would require aggregation logic that's out of scope
  for a Tier 1 pre-primary fix.

### Schema Wiring
- **D-05:** Researcher proposes the minimal schema-consistent approach for
  representing 4 MCC sub-districts in `essentials.districts` (likely: 4 new rows
  with `district_type='LOCAL'` or `'COUNTY'` and distinct `geo_id` values matching
  the 4 new geofence rows). Planner finalizes after reviewing the proposal against
  the existing district / office join pattern.

### Verification
- **D-06:** Use the Kirkwood Ave address from Phase 119 as the canonical test
  (`D-09` in 119-CONTEXT carries forward). Final verification happens **on production**
  (api.empowered.vote) after Render deploy — consistent with Phase 118 / Phase 119
  verification approach.
- **D-07:** Verification must prove *exclusivity*, not just inclusion — a Kirkwood
  address must return exactly one MCC District race, not all four. The
  `scripts/audit-112-geofence.ts` smoke test already queries the Kirkwood coordinate
  (`-86.534947, 39.166646`) via `ST_Covers` and can be extended.

### Claude's Discretion
- Exact diagnostic SQL the researcher runs against the live DB.
- Whether to extend `audit-112-geofence.ts` or add a new MCC-specific smoke test.
- Whether to add coverage for representative addresses in D2/D3/D4 as well, or keep
  verification focused on Kirkwood only (researcher/planner decides based on available
  authoritative precinct maps).
- Whether the SQL repair lives in a new migration, a one-off script, or an edit to
  the existing `link-monroe-county-races-to-geofences.sql` (with idempotency preserved).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §"Phase 121: County Council D1→D4 Geofence Repair" — phase goal
  and success criteria (note: the "D4 not D1" assertion in success criteria #1 is
  disputed — see D-01).
- `.planning/REQUIREMENTS.md` GEO-01, GEO-02 — acceptance criteria.

### Gap Report & Prior Audit Context
- `.planning/GAP-REPORT.md` §"PATTERN-004 — County Council D1→D4 Geofence Binding Bug"
  — states the bug direction as "should be D1, returns D4" (opposite of ROADMAP; see D-01).
- `.planning/GAP-REPORT.md` §"AUDIT-08 — Geofence Smoke Test" — original finding.
- `.planning/research/benchmark/ballotpedia.md` — benchmark references Kirkwood as
  "County Commissioner District 1, County Council District 1".

### Prior Phase Context
- `.planning/phases/119-read-rank-location-filter-repair/119-CONTEXT.md` — establishes
  the Kirkwood canonical test address and the production-verification discipline this
  phase inherits.

### Backend — Geofence & District Data
- `ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql` §§1a, 2a, 3a
  — current wiring that links all 4 MCC District offices to the same county-wide
  `geo_id='18105'` district. Root-cause surface area for this phase.
- `ev-accounts/backend/scripts/seed-monroe-county-2026-primary.sql` — upstream seed
  for the Monroe County 2026 primary races, including the 4 MCC District races that
  get linked by the script above.
- `ev-accounts/backend/scripts/audit-112-geofence.ts` — existing smoke test pattern
  (6 pre-geocoded Monroe County addresses + `ST_Covers` query); Kirkwood at
  `lat=39.166646, lng=-86.534947`. Verification harness for this phase.

### Backend — Runtime Services Affected
- `ev-accounts/backend/src/lib/essentialsService.ts` — address-based politician lookup
  (Census Geocoder + PostGIS intersect) that ultimately returns the MCC district(s).
- `ev-accounts/backend/src/lib/electionService.ts` — races → offices → districts →
  geofence_boundaries pipeline (the Part A path from the SQL comments).

### Schema (from CLAUDE.md)
- `essentials.geofence_boundaries` — PostGIS polygons keyed by `(geo_id, mtfcc)`.
- `essentials.districts` — links `geo_id` + `district_type` + `district_id` to
  offices.
- `essentials.offices` — joins races to districts.

### Authoritative External Sources (researcher MUST consult)
- Monroe County, IN official elections website / precinct maps — ground-truth
  source for Kirkwood's correct MCC district and for the canonical 4 MCC polygons.
- Monroe County GIS / ArcGIS portal — authoritative polygon data source per D-04.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`scripts/audit-112-geofence.ts`** — working PostGIS smoke test with 6 pre-geocoded
  Monroe County addresses and a standardized CSV output. Reusable harness for fix
  verification; add D1/D2/D3/D4 representative addresses or extend the Kirkwood
  assertion to check exact MCC district count = 1.
- **`link-monroe-county-races-to-geofences.sql`** — idempotent `INSERT ... WHERE NOT
  EXISTS` pattern for districts / offices / race linking. The same idempotency
  contract applies to the 4-polygon MCC insertion.
- **LA County ArcGIS import precedent** — per CLAUDE.md, the workspace already does
  ArcGIS-sourced geofence imports for LA County. Whatever pattern that uses is the
  template to mirror for Monroe County MCC.

### Established Patterns
- **PostGIS `ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(lng, lat), 4326))`** —
  canonical intersect query shape (from audit-112-geofence.ts line ~214 and the
  SQL file's footer comment).
- **`(geo_id, mtfcc)` composite uniqueness** on `essentials.geofence_boundaries` —
  new MCC polygon rows must pick distinct geo_ids; likely something like
  `18105-mcc-d1` through `18105-mcc-d4` or similar, with an appropriate MTFCC
  (county sub-division or a custom local-government code).
- **Races → offices → districts → geofence** join chain — the planner must not
  invent a new shape; just extend the existing one with per-district rows.

### Integration Points
- `essentialsService.ts` returns politicians via address → PostGIS intersect.
  Correct sub-district geofences there will immediately flow through Essentials,
  Compass, and Read & Rank without frontend changes.
- `electionService.ts` races-by-address path uses the same geofence chain — fix
  propagates here automatically.
- No frontend changes needed. No schema migrations beyond data inserts (unless
  researcher finds a missing column, which is unlikely).

</code_context>

<specifics>
## Specific Ideas

- Kirkwood test address: `200 W Kirkwood Ave, Bloomington IN 47404`
  (lat=39.166646, lng=-86.534947) — already pre-geocoded in
  `scripts/audit-112-geofence.ts`.
- Before writing ANY data, the researcher must resolve the D1-vs-D4 contradiction
  between ROADMAP and GAP-REPORT by consulting Monroe County's own precinct-to-CC
  map. Writing based on the wrong ground truth would silently reinforce the bug.
- The existing `link-monroe-county-races-to-geofences.sql` block that links all
  four MCC District offices to the shared county district (lines ~166–186) is the
  direct surface-area for the repair.
- Success shape: the Kirkwood address returns exactly ONE MCC District race
  (not four, not a wrong one).

</specifics>

<deferred>
## Deferred Ideas

- Mt Tabor Rd geocoding failure and rural-address geocoding gaps (AUDIT-08) —
  belongs to Phase 126: Geofence Hardening.
- Township polygon fallbacks (the COALESCE-to-county pattern in
  `link-monroe-county-races-to-geofences.sql` §1c) — Phase 126.
- Extending MCC-style sub-district polygon coverage to other counties (LA is
  handled; Indiana beyond Monroe is not in Tier 1 scope).
- Frontend display of "your council district: D-N" — not needed for GEO-01/GEO-02;
  correct race return is sufficient.

</deferred>

---

*Phase: 121-county-council-d1-d4-geofence-repair*
*Context gathered: 2026-04-16*
