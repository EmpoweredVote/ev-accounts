# Coverage Map — how the % is calculated

The coverage map lives at `/admin/coverage` (stacked above the tabular tracker — the two
were merged into one tab; `/admin/coverage/map` now redirects there). Three lenses:

- **Local** (the completeness metric) colors each geography (US states → counties →
  jurisdictions) by an **honest single completeness gradient** over the composite `score`
  (see "Completeness coloring" below) — empty units count, so the color reflects how
  complete the *whole* jurisdiction is. **Breadth** and **depth** are still computed and
  surfaced as numbers in the hover cards, but no longer drive the color.
- **Federal & state** colors EVERY state (no YAML required) by federal + state-office
  coverage, live from the DB — see "Federal & state lens" below. This lens exists because
  the local composite deliberately ignores federal/state officials, which made states with
  a fully-loaded congressional delegation read as "not started".
- **Elections** — race coverage for each state's nearest upcoming election (end of doc).

This doc explains exactly what those numbers count, so there's no guessing about whether
a column is "really" tracked.

- **Backend:** `backend/src/lib/coverageMapService.ts` (rollup `score` + breadth/depth) and
  `backend/src/lib/coverageBivariate.ts` (pure breadth/depth aggregation, unit-tested)
- **Endpoint:** `GET /api/admin/coverage/map?level=state` and `?level=county&state=<code>` (admin-gated)
- **Frontend:** `admin/src/pages/admin/CoveragePage.tsx` (orchestrator) →
  `CoverageMap.tsx` (map) + `CoverageTable.tsx` (table); the fill color is the pure,
  unit-tested `admin/src/pages/admin/completenessColor.ts`

This shares the per-state `*.yaml` files + `coverageService.ts` with the tabular
tracker, but the map computes its own rollup score and breadth/depth. The YAML schema is
documented in [`README.md`](./README.md).

---

## TL;DR — what each axis tracks

A jurisdiction's score is a **weighted average of 7 axes**, each normalized to 0–1.
"Is it tracking stances / donors / candidates?" — here's the definitive answer:

| Axis | Weight | Tracked? | Where the value comes from |
|------|-------:|----------|----------------------------|
| **roster** | 0.35 | ✅ live | active politicians loaded ÷ `expected_seats` (capped at 1). **N/A** when `expected_seats` is unknown — then it's dropped and the other weights renormalize. |
| **stances** | 0.30 | ✅ live | fraction of the jurisdiction's active politicians with **≥1 compass answer in `inform.politician_answers`**. (Was keyed on `last_stances_researched_at`, but that timestamp is unstamped for bulk-loaded states — CA/OR showed 0 despite hundreds with answers — so it now counts the actual answer rows.) |
| **populated** | 0.10 | ✅ live | 1 if the jurisdiction has ≥1 active politician, else 0. |
| **headshots** | 0.10 | ✅ live | fraction of the jurisdiction's active politicians that have a photo. |
| **treasury** | 0.10 | ✅ live + YAML | `full` if the jurisdiction's `geo_id` has ≥1 loaded budget in the `treasury` schema; otherwise falls back to the YAML `treasury` flag. |
| **donors** | 0.03 | ✅ live | fraction of the jurisdiction's politicians with **≥1 contribution**, joined `transparent_motivations.contributions → politician_sources.essentials_politician_id`. (Was a YAML-only flag that read `none` everywhere even though e.g. CA has 260 politicians with donor data.) |
| **geofenced** | 0.02 | ✅ (≈ constant) | 1 if a TIGER boundary exists. In the map every jurisdiction is geofenced by definition, so this is a tiny near-constant floor — intentionally small (see below). |
| **candidates** | — | ❌ **NOT counted** | Deliberately excluded from the map score today. (Candidate/election coverage is a planned separate "elections mode" — see end of doc.) |

> Tristate axes (`treasury`, `donors`) map `none → 0`, `partial → 0.5`, `full → 1`.

The weights live in one place — `DEFAULT_WEIGHTS` in `coverageMapService.ts` — and are
meant to be tuned.

---

## The formula

For one jurisdiction:

```
score = Σ(weightᵢ × valueᵢ) / Σ(weightᵢ)     // over the axes that apply, ×100
```

- The **roster** axis is only included when `expected_seats` is known. When it's
  dropped, the denominator shrinks, so the remaining axes are effectively
  renormalized (an untracked jurisdiction is still scored fairly on the 6 axes it has).
- Result is rounded to one decimal (e.g. `24.4`).

### Worked example — a boundary-only county (no officials loaded)
```
geofenced = 1, everything else = 0, roster N/A
score = (0.02×1) / (0.02 + 0.10 + 0.10 + 0.30 + 0.10 + 0.03) = 0.02 / 0.65 ≈ 3.1%
```
That ~3% floor is why empty counties read as faint teal, not gray. (Gray = a state
with **no coverage YAML at all** — see "not started".)

---

## Geography rollup

The single per-county / per-state number is a **mean of the composite scores of the
jurisdictions inside it**:

- **County score** = mean composite over: the county government + every **place** and
  **school district** whose boundary **overlaps that county the most** (`ST_Area` of
  the intersection — robust to offshore parts like San Francisco's Farallon Islands).
- **State score** = mean composite over every jurisdiction in the state.
- Empty/sparse jurisdictions pull the average down, so the color blends *breadth*
  (how much of the area is covered) and *depth* (how complete each piece is) into one
  number.

### "Not started" vs "low"
- **Gray** = `null` score = the state has **no coverage YAML** (untracked locally). Not
  the same as 0% — and since the federal lens landed, not the same as "we have nothing":
  hovering a gray state shows its federal delegation summary, and clicking it opens the
  federal/state roster instead of a local tracker it doesn't have.
- **Pale sage (~3%)** = tracked, but the jurisdiction has only its boundary, no people.
- **Deeper sage → purple → yellow** = increasing real coverage. The ramp uses a gamma
  curve so the clustered low scores still separate visually (see "Completeness coloring").

> The single composite `score` drives BOTH the **table** and the **completeness map
> fill** (and the elections-mode ramp uses its own race-coverage %). An earlier bivariate
> (breadth × depth) fill made well-worked-but-narrow states look too far along (e.g.
> California's 7 deeply-built counties painted confident teal-green while ~88% of the
> state was untouched), so the fill is now the honest composite below.

---

## Completeness coloring (completeness map fill)

The completeness map fill is a **single honest gradient** over the composite `score` —
empty units already drag the score down, so the color reflects how complete the *whole*
jurisdiction is. California reads an unmistakably-early sage; only a genuinely complete
county/state approaches yellow.

- **Gradient:** gamma-expanded `sage → purple → yellow`. `t = (score/100) ** 0.55` (the
  gamma spreads the crowded low end so 4% vs 13% vs 30% are distinguishable sage shades),
  then sage → purple over `t ∈ [0, 0.6]` and purple → yellow over `t ∈ [0.6, 1]`. Yellow
  (`#fed12e`, the EV Inform token) is reached only at ~100%. Antipartisan — deliberately
  no red/blue. Pure function: `admin/src/pages/admin/completenessColor.ts` (unit-tested).
- **Untracked** (no coverage YAML → null score) stays neutral **grey** (`#e5e7eb`).
- **Breadth & depth still exist** (`backend/src/lib/coverageBivariate.ts` aggregation +
  the true-county-count denominator for breadth, `US_COUNTY_COUNTS` in
  `coverageMapService.ts`) and ride alongside `score` in the endpoint response — but they
  are surfaced as **numbers** in the hover cards + US overview table, not encoded in the
  color.
- **Hover cards** convey *what's* covered: state → `n/N counties` + breadth bars
  (counties / cities / schools started) + `Rosters X% · Stances Y% · Photos Z%`; county →
  `n/N populated` + jurisdictions inside (county govt, cities X/Y, schools X/Y) +
  `Rosters % · Stances % · Photos % · Donors %` + a Treasury indicator. **The completeness
  fill + hover apply to completeness only** — elections mode keeps its single-hue
  race-coverage ramp + race-list drill-down.

### School-district universe

The `school` universe counts **all** TIGER district types — unified (`G5420`) +
elementary (`G5400`) + secondary (`G5410`) — not just unified, so `schools_total` and the
composite `score` reflect the true denominator (e.g. California ≈ 982 districts, not 353).

### Headshots & donors as counts

In the county drill-down table, **headshots** and **donors** show `have / total`
(politicians with a photo / with ≥1 contribution, out of total active) with green/amber/
grey coloring — the same shape as stances — instead of Full / Partial / None chips.

---

## Data freshness & gotchas

- **Live from the DB.** roster/stances/populated/headshots/treasury/donors are computed
  from `essentials.*` + `inform.politician_answers` + the `treasury` and
  `transparent_motivations` schemas on every request — **no `coverage-sync` or YAML edit
  is needed** for new data to appear. (`coverage-sync` only snapshots the *table* view's
  columns; the map ignores those snapshots.)
- **10-minute cache.** Results are cached in-process per state for 10 minutes. New data
  appears within ~10 min, or immediately via `?refresh=1` on the endpoint, or after a
  redeploy (which clears the cache).
- **Stances = answer rows, not the timestamp.** The stances axis counts politicians with
  ≥1 row in `inform.politician_answers`. The table's "Last Researched" *date* still comes
  from `last_stances_researched_at`, so a jurisdiction can show stance coverage with a
  blank date when the answers were bulk-loaded without stamping the timestamp (honest:
  "we have the stances, date unknown" — we don't fabricate a date).
- **Donors = live contributions.** The donors axis is the fraction of a jurisdiction's
  politicians with ≥1 row in `transparent_motivations.contributions` (joined via
  `politician_sources.essentials_politician_id`). The old YAML `donors` flag is no longer
  used by the map. Donor data is FEC-sourced and currently concentrated in CA (~260
  politicians); states with no contribution data correctly read `none`.

---

## Federal & state lens

**Backend:** `backend/src/lib/federalCoverage.ts`. **Endpoint:** the `federal` block rides
on every state in `GET /api/admin/coverage/map?level=state` (all 56 states/territories are
now returned — untracked states carry `tracked: false`, `score: null` and zeroed local
fields); the per-member roster is `GET /api/admin/coverage/federal?state=<code>`.

Active politicians are classified by `districts.ocd_id` shape + `offices.title`
(`TIER_CASE_SQL` — shared by the rollup and the roster so they can't disagree):

| Tier | Match | Notes |
|------|-------|-------|
| **senate** | bare `state:xx` district + title `Senator` / `U.S. Senate%` | State senators can't collide — they sit at `/sldu:` districts. Verified: exactly 100 across 50 states. |
| **house** | `/cd:` district | Includes the six non-voting delegates (DC + territories, ADR 0003) — that IS the delegation. DC's shadow senators also sit at `cd:98` but hold no seat in Congress → classified `statewide`. |
| **governor** | bare state + `role_canonical`/title `Governor` | Exactly 50. |
| **statewide** | any other bare-state officeholder | AG, SoS, treasurer, courts, DC mayor/council, shadow senators. |
| **stateleg** | `/sldu:` or `/sldl:` district | Only loaded for tracked states. |
| **candidate** | title `Candidate for …` | 2026 Senate challengers seated by the migration-1459 backfill — tracked PEOPLE, not officeholders. Never counted as a filled seat; surfaced as their own roster section. |

**Denominators are honest:** Senate = 2 for the 50 states (0 for DC/territories), House =
the state's `/cd:` district count in `essentials.districts`, legislature = loaded
`/sldu:`+`/sldl:` district count (0 ⇒ unknown ⇒ axis dropped). We never invent a universe
we haven't loaded.

**Score** (`federalStateScore`, unit-tested): weighted renormalising composite —
senate roster 0.2 · house districts covered 0.3 · governor 0.1 · delegation stances 0.2 ·
delegation photos 0.1 · legislature districts covered 0.1. Axes with no denominator (DC
has no Senate seats; most states have no legislative districts loaded) are dropped and the
rest renormalise, same as the local composite's roster axis.

**Roster rendering rule (ADR 0003):** the per-member panel must render
`representation_note` alongside any seat with `voting_powers ≠ 'full'` — the note is what
keeps a tribal or territorial seat from reading as an ordinary one.

The US overview table now lists **all 56** states with a Local column group (— for
untracked) and a Federal & state group; breadth/depth left the table for space but remain
in the state hover cards.

---

## Elections mode

Toggle the map to **Elections** to recolor by **race coverage** — `races with ≥1
candidate ÷ total races` — for each state's **nearest upcoming election date** (all
`elections` rows on that date, every level). State % composites all races; county %
counts only races resolving to that county (`…/county:X` or `…/place:Y`, including nested sub-district races like `…/county:X/council_district:N`). Counties
where no races resolve show **"no race data"** (a distinct neutral fill, not 0%); a
state with no upcoming election is grey.

- **Backend:** `electionsMapService.ts` (rollup + 10-min cache) + pure helpers in
  `electionsMap.ts`. Endpoint: `GET /api/admin/coverage/map?metric=elections&level=state|county&state=<code>`.
- **Data:** `essentials.elections / races / race_candidates`; a race maps to geography
  via `races.office_id → offices.district_id → districts.ocd_id`. Races that don't
  resolve to a county (federal / state / legislative-district) count toward the state %
  only. `?refresh=1` busts the cache.
