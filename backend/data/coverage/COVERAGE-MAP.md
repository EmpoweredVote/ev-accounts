# Coverage Map — how the % is calculated

The coverage map (`/admin/coverage/map`) colors each geography (US states → counties
→ jurisdictions) by a single **0–100% composite completeness score**. This doc explains
exactly what that number counts, so there's no guessing about whether a column is
"really" tracked.

- **Backend:** `backend/src/lib/coverageMapService.ts`
- **Endpoint:** `GET /api/admin/coverage/map?level=state` and `?level=county&state=<code>` (admin-gated)
- **Frontend:** `admin/src/pages/admin/CoverageMapPage.tsx`

This is **separate** from the tabular coverage tracker (`/admin/coverage`,
`coverageService.ts`, the per-state `*.yaml` files). The map reuses some of the same
signals but computes its own rollup score. The YAML schema is documented in
[`README.md`](./README.md).

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
- **Gray** = `null` score = the state has **no coverage YAML** (untracked). Not the same
  as 0%.
- **Faint teal (~3%)** = tracked, but the jurisdiction has only its boundary, no people.
- **Darker teal** = real coverage. The color ramp uses a gamma curve so the clustered
  low scores still separate visually.

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
