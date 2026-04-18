# Phase 121: County Council D1→D4 Geofence Repair - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 121-county-council-d1-d4-geofence-repair
**Areas discussed:** Ground truth, Fix scope

---

## Ground Truth (Kirkwood Ave → which MCC district?)

Contradiction surfaced during analysis:
- `ROADMAP.md` §Phase 121 success criteria #1 asserts the correct answer is **D4** (not D1).
- `GAP-REPORT.md` PATTERN-004 asserts the correct answer is **D1** (returned D4 is the bug).
- `research/benchmark/ballotpedia.md` independently states Kirkwood = County Council **D1**.

| Option | Description | Selected |
|--------|-------------|----------|
| D1 is correct (roadmap is wrong) | Trust PATTERN-004 + Ballotpedia benchmark. Correct ROADMAP as part of this phase. | |
| D4 is correct (GAP-REPORT is wrong) | Trust ROADMAP success criteria. Update GAP-REPORT. | |
| Verify first, don't lock yet | Treat ground truth as unknown. Researcher must consult Monroe County authority before planning. | ✓ |

**User's choice:** Verify first, don't lock yet.
**Notes:** D-01 locks this into CONTEXT.md — ground truth is a research prerequisite.

---

## Fix Scope — polygon repair vs. structural reimport

Scout finding: `link-monroe-county-races-to-geofences.sql` lines ~166–186 link all
four Monroe County Council District races to the SAME county-wide district
(`geo_id='18105'`, `district_type='COUNTY'`). No sub-county MCC polygons appear
to exist in `essentials.geofence_boundaries`.

### Q1 — How should the fix handle this?

| Option | Description | Selected |
|--------|-------------|----------|
| Full structural fix: import 4 polygons + 4 districts | Source 4 MCC polygons, insert geofence rows, create 4 districts, re-link each office. Actually enables correct ST_Covers matching. | |
| Narrow fix: confirm bad polygon exists, swap it | Trust "single polygon repair" framing; escalate if no sub-district polygons exist. | |
| Diagnose first, scope later | Researcher verifies at live-DB level; planner picks approach after findings. | ✓ |

**User's choice:** Diagnose first, scope later.
**Notes:** D-02 + D-03 capture this — diagnosis is a research prerequisite, planner
picks structural vs. targeted after findings.

### Q2 — If sub-district polygons need to be imported, where do they come from?

| Option | Description | Selected |
|--------|-------------|----------|
| Monroe County GIS / ArcGIS (authoritative) | Pull from Monroe County's GIS portal — highest trust, matches LA County ArcGIS pattern. | ✓ |
| TIGER 2024 Voting District (VTD) files | US Census TIGER VTD layer — consistent with township/county TIGER pattern but VTDs are precincts, need aggregation. | |
| Indiana state redistricting dataset | IN SoS / legislative portal; may not include county-level council districts. | |
| Researcher decides | Let research step compare sources and recommend. | |

**User's choice:** Monroe County GIS / ArcGIS.
**Notes:** D-04 — do not fall back to TIGER VTDs without escalating.

### Q3 — If new polygons arrive, schema wiring?

| Option | Description | Selected |
|--------|-------------|----------|
| 4 new `essentials.districts` rows, one per CC district | Distinct district_ids + geo_ids, one office per district. Rewrite the relevant SQL block. | |
| Reuse existing county district, add new columns | Keep shared 18105 district, add sub-district pointer. Invasive schema change. | |
| Researcher proposes | Let researcher inspect schema and propose minimal approach. | ✓ |

**User's choice:** Researcher proposes.
**Notes:** D-05 — planner finalizes after researcher's proposal.

---

## Continuation Check

| Option | Description | Selected |
|--------|-------------|----------|
| A few more questions (verification coverage, adjacent-issue boundary) | | |
| Ready for context | | ✓ |

**User's choice:** Ready for context.
**Notes:** Verification coverage and adjacent-issue boundary captured as Claude's
Discretion (D-07) and Deferred (Phase 126 items) respectively.

---

## Claude's Discretion

- Exact diagnostic SQL the researcher runs against the live DB.
- Whether to extend `audit-112-geofence.ts` or add a new MCC-specific smoke test.
- Whether verification expands to representative D2/D3/D4 addresses.
- Whether the SQL repair lives in a new migration, one-off script, or edit to the
  existing `link-monroe-county-races-to-geofences.sql` (idempotency preserved).

## Deferred Ideas

- Mt Tabor Rd geocoding failure and rural-address geocoding gaps (AUDIT-08) → Phase 126.
- Township polygon fallbacks (COALESCE-to-county in §1c) → Phase 126.
- MCC-style sub-district polygon coverage for other Indiana counties — out of Tier 1.
- Frontend display of "your council district: D-N" — not needed for GEO-01/GEO-02.
