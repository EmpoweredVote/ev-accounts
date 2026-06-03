# Coverage tab redesign — unified map+table with bivariate color — Design

**Date:** 2026-06-03
**Status:** Approved (design), to be implemented in a future session
**Area:** `ev-accounts` — admin coverage view

## Problem

The admin coverage view is split across two nav items / routes (`/admin/coverage`
tabular tracker + `/admin/coverage/map` choropleth). We want **one** Coverage tab.
Separately, the map's single-teal gradient + mean composite score **conflates breadth
and depth**: e.g. Indiana looks meaningfully covered because one county (Monroe) is
built out, even though no other county has data. And a bare % per geography doesn't
convey *what* is covered.

## Decisions (locked via visual brainstorm)

1. **One tab, stacked, single page scroll.** Merge the two routes into `/admin/coverage`:
   the map on top, the full coverage **table directly below** it, the **whole page
   scrolls** (no inner scroll container). Drop the separate "Coverage Map" nav item;
   redirect `/admin/coverage/map` → `/admin/coverage`.
2. **The map is the table's selector.** Clicking a state on the map selects it and the
   table below shows that state's full breakdown (replaces the table's separate state
   dropdown). Drilling to a county focuses the table on that county's jurisdictions.
3. **Bivariate color (completeness mode)** — color encodes two dimensions:
   - **Breadth** = fraction of the geography's child units that are *started* (≥1 active
     politician). State → over its counties; County → over its jurisdictions (county +
     cities + schools).
   - **Depth** = mean composite completeness over the **started units only** (white space
     is carried by breadth, not by dragging depth down).
   - Each bucketed **low / med / high** → a **3×3 Teal × Amber** grid (teal = deep,
     amber = broad, olive = both high, near-white = empty). A 2D legend sits by the map.
   - Thresholds are tunable constants.
4. **Hover cards** give a sense of *what's* covered, not just a %.
5. Elections mode keeps its own race-coverage coloring + race-list drill-down; bivariate
   + hover apply to **completeness** only. Elections lives inside the same stacked layout.

## Bivariate specifics

- **Palette (Teal × Amber), X = breadth, Y = depth.** 9 cells; near-white at both-low,
  teal at high-depth/low-breadth, amber at high-breadth/low-depth, olive at both-high.
  (Antipartisan — deliberately no red/blue.) Suggested starting hex (tune in preview):
  ```
  depth\breadth   low        med        high
  high            #2f8f8f    #36806a    #3f6b3a
  med             #a9cdc0    #aab98a    #ad9c4a
  low             #ece8e0    #ead9a8    #e6c34d
  ```
- **Bucket thresholds (starting points, tunable):** breadth `<10% / 10–50% / ≥50%`;
  depth `<33% / 33–66% / ≥66%`. A geography with 0 started → the near-white "empty" cell.
- A state/county with no coverage YAML / not tracked stays the existing neutral grey
  ("not started"), distinct from the empty bivariate cell.

## Hover cards

- **State hover:** `"<n>/<N> counties"` headline; breadth bars for **counties / cities /
  schools started**; one-line depth summary (`Rosters X% · Stances Y% · Photos Z%`).
- **County hover:** `"<n>/<N> populated"` headline; jurisdictions inside (County government
  ✓/started, Cities X/Y started, School districts X/Y started); axis chips
  (Roster / Stances / Photos / Treasury / Donors as ✓ / ◑ / ✕).

## Backend

The map endpoint returns breadth/depth + hover breakdown per geography, alongside the
existing composite `score` (the table still uses score). Build on the existing
`buildJurisdictions` data (per-jurisdiction populated + composite) — mostly aggregation,
no new heavy queries.

- `getStateScores()` → per state add: `breadth`, `depth`, started counts per category
  (`counties_started/total`, `cities_started/total`, `schools_started/total`), and depth
  summary (`roster_pct`, `stances_pct`, `photo_pct`).
- `getCountyScores(state)` → per county add: `breadth`, `depth`, jurisdiction-inside
  counts (county govt status, cities started/total, schools started/total).
- Endpoint response shapes extend; `?metric=elections` path unchanged.

## Frontend

- Consolidate `CoverageMapPage` + `CoverageTrackerPage` into one page at `/admin/coverage`
  (map component stacked above the table component; shared cells already in
  `coverageCells.tsx`). Remove the `coverage/map` route + nav item; redirect old path.
- **Bivariate fill**: `(breadth, depth) → 3×3 bucket → teal×amber hex`; pure function,
  unit-tested. 2D legend component.
- **Hover-card component** (state + county variants) with the content above.
- Table component is driven by the map's selected state (map click sets the state).
- Elections mode: unchanged coloring/drill-down, rendered in the same layout.

## Out of scope

- Bivariate/hover for elections mode (keeps race-coverage single-hue).
- Changing the underlying composite axis weights (separate concern).
- The stances/donors data-source fix (separate — PR #20; this assumes it's merged).

## Testing

- **Vitest (pure):** breadth/depth aggregation, 3×3 bucketing at threshold boundaries,
  bivariate color lookup (all 9 cells + empty + not-started).
- **Manual:** Indiana reads teal (narrow-but-deep); a broad-shallow state reads amber;
  UT/CA spot-checks; hover cards for state + county; whole-page scroll; map click drives
  the table; `/admin/coverage/map` redirects.

## Dependencies / sequencing

- Merge **PR #20** (stances from `inform.politician_answers`, donors from
  `transparent_motivations`) first — bivariate depth relies on correct per-axis signals.
- Then this redesign builds on the corrected signals.
