# Coverage honest-completeness redesign — Design

**Date:** 2026-06-04
**Status:** Approved (design), ready for implementation plan
**Area:** `ev-accounts` — admin coverage view (`/admin/coverage`)
**Follows:** the bivariate redesign (PR #21) + UI tweaks (PR #22)

## Problem

The bivariate (breadth × depth) map color makes well-worked-but-narrow states look
further along than they are. California is the clearest case: we've built out 7 of 58
counties deeply, so **depth** (mean completeness over *started* counties only) reads ~85%
and the cell paints a confident teal-green — even though ~88% of the state is untouched.
The depth axis ignores empty space by design, and it visually dominates the 3×3 grid.

Two secondary issues surfaced while investigating:

- **School-district universe undercounts.** `schools_total` counts only *unified* districts
  (TIGER `G5420`). California also has 517 elementary (`G5400`) + 112 secondary (`G5410`)
  districts that aren't counted, so the true school universe is ~982, not 353.
- **Full / Partial / None chips hide the underlying counts.** For headshots and donors,
  a number ("how many of this jurisdiction's politicians have data, out of total") is more
  honest and informative than a tristate word.

(The city denominator was checked and is **not** a problem — all 482 California incorporated
places are geofenced statewide, so `95/482 cities` is an honest fraction.)

## Decisions (locked via brainstorm)

1. **Map color = honest overall completeness, single gradient.** The completeness-mode fill
   (states + counties) uses the **existing composite `score`** — empty units count toward it,
   so the color reflects how complete the *whole* jurisdiction is. No composite weight changes.
2. **Palette = compass-style sage → purple → yellow, gamma-expanded.** Antipartisan (no
   red/blue). Yellow (`#fed12e`, the EV Inform token) is reached only at ~100%. A gamma curve
   (`0.55`) expands the low end so 4% vs 13% vs 30% are distinguishable sage shades instead of
   all washing out. Untracked states stay neutral grey.
3. **Retire the 3×3 bivariate encoding for the fill.** `bivariateColor` / `PALETTE` /
   bucketing are replaced by a pure, unit-tested `completenessColor(score)`. Breadth and depth
   are **not** discarded — they remain as honest numbers in the hover cards and the US overview
   table; they're just no longer encoded in the (misleading) color.
4. **School universe counts all district types.** Backend includes unified + elementary +
   secondary (`G5420` + `G5400` + `G5410`), all as level `school`. This corrects
   `schools_total`, and flows into the composite `score`, breadth, and depth.
5. **Numbers instead of Full/Partial/None for headshots & donors.** In the county drill-down
   table and the county hover card, show `withPhoto / total` and `withDonors / total`
   (politicians with ≥1 photo / with ≥1 contribution, out of total active politicians) — keeping
   the green / amber / grey coloring on the number, exactly like stances. Treasury stays a ✓/✕
   chip (it's a per-jurisdiction yes/no, not a per-politician count). Roster is already `X / Y`.

## Color specification

`completenessColor(score: number | null): string`

- `score == null` (untracked — no coverage YAML) → `#e5e7eb` (gray-200, "not started").
- Otherwise `t = (clamp(score, 0, 100) / 100) ** 0.55`, then interpolate a 3-stop ramp:
  - `t = 0.0` → sage `#cfe3c4`
  - `t = 0.6` → purple `#7d5ba6`
  - `t = 1.0` → yellow `#fed12e`
  - Piecewise-linear RGB: blend sage→purple over `t ∈ [0, 0.6]`, purple→yellow over `t ∈ [0.6, 1]`.
- All hexes + the gamma + the 0.6 knee are tunable constants in the module.

Tracked-but-empty geofences score low (~3% composite floor), so they land in the pale-sage
bottom of the ramp — visibly "barely started" but distinct from untracked grey.

## Component changes

### Backend — `backend/src/lib/coverageMapService.ts`
- **School universe:** the `children` geofence query includes `G5400` and `G5410` in addition
  to `G5420`; all three map to `level: 'school'`. Derive each one's `ocd_id` with a school slug
  (strip the trailing "… school district" / "… elementary school district" / "… union high
  school district" variants). `cities_total`/breadth/depth/`score` then count the true universe.
- **Donor counts:** add a per-jurisdiction donor count to `JurisdictionScore`
  (`donors_n: { withDonors: number; total: number }`) sourced from the `withDonors` value
  `statsByJurisdiction` already computes (politicians with ≥1 contribution / total active —
  the same shape as stances; **not** a count of individual donations). Headshots already carry
  `{ withPhoto, total }`.
- **County-level percentages:** `countyBreakdown` already sums photo / stance / roster signals
  over the populated jurisdictions; also return `donors_pct` (and keep `photo_pct` / `stances_pct`
  / `roster_pct`) on `CountyScore` so the county hover card can show numbers instead of tristate
  words. (The existing `roster`/`stances`/`photos`/`donors` rollup tristates can be dropped from
  `CountyScore` once the hover card stops using them; `treasury` Tristate stays.)
- **Unchanged:** composite axis weights, `aggregateUnits`, the true-county breadth denominator
  (`US_COUNTY_COUNTS`), the `metric=elections` path.

### Frontend — admin SPA
- **New `admin/src/pages/admin/completenessColor.ts`** (replaces the fill role of
  `coverageBivariate.ts`): exports `completenessColor(score)`, the stop constants, gamma, and
  `NOT_STARTED`. Pure + unit-tested. Delete `coverageBivariate.ts` + its test (no longer used —
  the backend's own `coverageBivariate.ts` aggregation module is unaffected).
- **`CoverageMap.tsx`:** completeness fill = `completenessColor(sc?.score ?? null)` for states and
  counties. Replace the in-map `BivariateLegend` overlay with a `CompletenessLegend` gradient bar.
  Hover cards, cursor-following behavior, auto-framing, smaller-map sizing — all unchanged.
- **`CompletenessLegend.tsx`** (replaces `BivariateLegend.tsx`): a horizontal sage→purple→yellow
  gradient bar with "less complete → 100%" end labels, plus the separate grey "not started" chip.
- **`CoverageTable.tsx`:**
  - US overview table: recolor the leading per-state chip with `completenessColor(score)`. Keep the
    Composite / Breadth / Depth / Counties / Cities / Schools / Stances / Photos columns (honest
    numbers).
  - County drill-down table: **Headshots** → `withPhoto / total` and **Donors** →
    `withDonors / total`, each colored full/partial/none via the existing ratio→tristate helper.
    Stances and Roster already numeric. Treasury stays a ✓/✕ chip.
- **`CoverageHoverCard.tsx`** (county card): replace the five Full/Partial/None chips with a
  numeric summary line consistent with the state card — `Rosters X% · Stances Y% · Photos Z% ·
  Donors W%` — using the new county-level percentages; Treasury stays a small ✓/◑/✕ (categorical,
  per-jurisdiction yes/no). The state hover card (breadth bars + `Rosters % · Stances % ·
  Photos %`) is unchanged.

## Out of scope

- Composite axis weights (unchanged — only the *color mapping* of the score changes).
- Breadth/depth aggregation and the Indiana true-county-denominator fix (kept as-is, surfaced as
  numbers only).
- Elections mode (single-hue race-coverage ramp + race drill-down — untouched).
- The stacked layout, map-drives-table, cursor hover card, auto-framing, US overview table
  structure (all from PR #21/#22 — untouched except the recolor noted above).

## Testing

- **Vitest (admin, pure):** `completenessColor` — `null → grey`; `score 100 → #fed12e`;
  monotonic across the ramp; a low score (e.g. 4) is a paler sage than a mid score (e.g. 30);
  the 0.6 knee lands on/near purple.
- **Backend:** existing `coverageBivariate.test.ts` (aggregation) stays green. School-universe and
  donor-count changes are query/shape changes — verified via a throwaway tsx probe against
  production (`node --env-file=backend/.env`), not unit tests.
- **Manual / probe:** CA composite drops after adding all school districts and renders an
  unmistakably-early sage; a fully-complete county renders yellow; `schools_total` for CA ≈ 982;
  county drill-down shows `withPhoto/total` and `withDonors/total`; elections mode unchanged.

## Dependencies / sequencing

Builds directly on `master` (PR #21 + #22 already merged). No external dependencies.
