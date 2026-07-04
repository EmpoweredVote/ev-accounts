# Phase 168: Elections Accuracy Fix - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.
> Re-homed from the offline Phase 148 draft (milestone v2.20 → v2.23, coverage-map workstream) on 2026-07-04.

**Date:** 2026-07-04
**Phase:** 168-elections-accuracy-fix (originally discussed as 148)
**Areas discussed:** Map fill, Panel model, Empty case, Classifier seam

---

## Map fill — what the state choropleth color represents

| Option | Description | Selected |
|--------|-------------|----------|
| Statewide/legislative number | Fill by statewide/legislative coverage % (the number the Michigan bug wrongly showed as 100%); county drill-down keeps its own coloring. Simplest. | ✓ |
| County-pinnable number | Fill by county/local coverage %; consistent with drill-down but a statewide-only state paints 0%/gray despite covered statewide races. | |
| Split/bivariate fill | Show both numbers in the fill; richer but heavier + Phase-169 coupling. | |
| Toggle between the two | Sub-control to switch which number colors the map; adds UI state. | |

**User's choice:** Statewide/legislative number
**Notes:** The statewide/legislative number is the one the bug misreported, so it is the primary signal to fix and surface on the map.

---

## Panel model — how the statewide-races panel coexists with county drill-down

| Option | Description | Selected |
|--------|-------------|----------|
| Panel + county view together | State click shows statewide-races panel AND county choropleth/drill-down at once. Best matches "never contradicts its own score." | ✓ |
| Panel replaces county view | State click opens panel; further action enters county drill-down. Cleaner but hides county side. | |
| Panel as a table below map | Reuse completeness-mode table pattern (currently gated off for elections). Lowest new-UI cost. | |

**User's choice:** Panel + county view together
**Notes:** Showing both halves of the split at once makes internal consistency visible without extra clicks.

---

## Empty case — state with no county-pinnable races (Michigan)

| Option | Description | Selected |
|--------|-------------|----------|
| N/A — no county races | Show county number as N/A / "no county-level races" instead of 0% or 100%. Directly kills the misleading-percentage bug. | ✓ |
| 0% with distinct styling | Show 0% but distinguish "zero races" from "races with zero candidates". Risks reading as poor coverage. | |
| Hide the county number | Omit the county metric when denominator is zero. Simplest but loses the explicit signal. | |

**User's choice:** N/A — no county races
**Notes:** Must remain visually distinct from a real 0% (races exist but no candidates yet).

---

## Classifier seam — how far Phase 168 goes toward Phase 169's coverageCore.ts

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse existing helper in place | Treat resolveRaceCountyFips() as the single classifier; both lenses call it. No new abstraction; leave coverageCore.ts to Phase 169. | ✓ |
| Add thin classifier fn now | Introduce a small named classifier wrapping existing logic. Slightly more structure. | |
| Build coverageCore.ts now | Start the shared core module this phase. Pulls Phase-169 scope forward; more risk. | |

**User's choice:** Reuse existing helper in place
**Notes:** Keeps Phase 168 isolated and low-risk per the roadmap's "front-load lowest-risk fix" framing.

---

## Claude's Discretion

- Exact panel layout/placement (side vs above the map), styling, and hover-card/table reuse — provided both panel and county view are visible together on state click.
- Caching approach for the two per-state numbers and the precise new API payload shape.
- Optional small readability wrapper around `resolveRaceCountyFips`, as long as no new shared module is introduced.

## Deferred Ideas

- `coverageCore.ts` shared jurisdiction-signals module — Phase 169.
- Bivariate/split-swatch state fill showing both numbers — deferred.
- Metric-toggle sub-control for map coloring — deferred.
- DB-derived nationwide coverage (Phase 169), city/place drill-down (Phase 170), user-relevant 3-axis lens (Phase 171), port-ready public API (Phase 172).
