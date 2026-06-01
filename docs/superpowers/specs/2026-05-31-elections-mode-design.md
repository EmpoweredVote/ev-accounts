# Elections mode for the Coverage Map — Design

**Date:** 2026-05-31
**Status:** Approved (design), pending build plan
**Area:** `ev-accounts` — admin coverage map

## Problem

The coverage map (`/admin/coverage/map`) currently colors geographies by **data
completeness** (roster/stances/headshots/treasury/donors/geofenced). Candidate/election
data is deliberately excluded from that score. We want a second lens — an **Elections
mode** — that recolors the same map by **election readiness**: how many of a state's
upcoming races have candidates loaded, surfaced alongside the election date. This tells
the team where candidate data is missing ahead of an election, which the completeness
score can't show.

## Existing system this builds on

- **Map feature:** `backend/src/lib/coverageMapService.ts`, route
  `GET /api/admin/coverage/map?level=state|county&state=<code>`, page
  `admin/src/pages/admin/CoverageMapPage.tsx`. US → county → jurisdiction drill-down,
  10-min in-process cache, choropleth via `react-simple-maps` + us-atlas TopoJSON.
  Scoring documented in `backend/data/coverage/COVERAGE-MAP.md`.
- **Elections data (verified against the live DB):**
  - `essentials.elections` — `id, name, election_date (date), election_type
    (general|primary|special), jurisdiction_level (state|county|city), state (2-letter,
    e.g. 'CA'), description`.
  - `essentials.races` — `id, election_id, office_id, position_name, primary_party,
    seats (int), description`.
  - `essentials.race_candidates` — `id, race_id, politician_id, full_name, is_incumbent,
    candidate_status, …`.
  - Current data: 15 elections, 828 races, 727 candidates, spanning 2026–2027
    (primary/general/special) across CA, IN, MA, ME, OR, TX, UT.
  - A race reaches geography via `races.office_id → offices.district_id →
    districts.ocd_id`. **Reachability is partial** — e.g. CA primary 22/72 races resolve
    to an OCD, IN 5/46, UT 67/138, **TX 0/23**. Many that do resolve are keyed at
    state/congressional/legislative level (`…/state:ca`, `…/cd:N`, `…/sldu:N`), not county.

## Design decisions (locked)

1. **Metric = race coverage** — `races with ≥1 candidate ÷ total races` for the relevant
   geography's next upcoming election. Clean 0–100%; answers "have we started filling in
   each contest?"
2. **Scope = the state's nearest upcoming election DATE** — the soonest
   `election_date >= today`. Aggregate **all `elections` rows on that date** (across every
   `jurisdiction_level`) and **all of their races**. The displayed date/type is that date.
   Grouping by date (not by a single election row) is what makes the state number a true
   composite, and it auto-advances over time. Grouping by *date* (rather than across all
   future elections) avoids double-counting the same offices that appear in both the
   primary and the general (those are on different dates — see Data wrinkle below).
3. **State % = composite of ALL races on that date — every level** (federal, state,
   county, city), not just top-of-ticket. A state where the governor + congress are
   loaded but hundreds of local races are empty should read low, not "done."
4. **Granularity = US → county**, mirroring completeness mode's drill, with graceful
   handling of the geography gaps (below).
5. **The county rollup is the only place geography filtering applies.** A county's % counts
   only races that resolve to that county (county-level + places within it). State /
   federal / legislative-district races still count toward the **state** %, they just
   can't be pinned to a single county. A county with only such races over it reads
   **"unknown"**, not a misleading 0%.
5. **"Unknown" is a distinct visual** (hatched/neutral, labeled "no race data") — *not*
   the same as completeness mode's gray "not started", and *not* 0%.

## How it works

### Toggle
A **Completeness ↔ Elections** switch at the top of the map page. Completeness mode is
unchanged. Elections mode swaps the color basis, legend, hover, and drill-down panel.

### Metric & geography rollup
Per state, take the **nearest upcoming election date** and the set of **all races** in
every `elections` row on that date. Then:

- **State color** = race coverage over **that entire race set** — every level (federal,
  state, county, city). This is the composite the team cares about.
- **County color** = race coverage over the **subset of that set that resolves to the
  county** — i.e. the race's `district.ocd_id` is `…/county:X` (that county) or `…/place:Y`
  where place Y's boundary overlaps the county most (reuse the existing largest-overlap
  mapping). Federal / state / legislative-district / statewide races are *not* dropped from
  the data — they still count toward the **state** %, they just can't be attributed to a
  single county, so they don't appear in any county's denominator.

### Three-state classification (per geography)
| State | Condition | Visual |
|-------|-----------|--------|
| **Unknown** | no races resolve to this geography | hatched neutral, "no race data" — distinct from "not started" |
| **0% covered** | races resolve here, none have ≥1 candidate | low end of the elections gradient |
| **>0%** | ≥1 resolved race has candidates | gradient to 100% |

States with **no upcoming election** at all → treated as "not started"/untracked (gray),
same as completeness mode for untracked states.

### Date display
Hover and the detail panel show the driving election: e.g. `Primary · Jun 2, 2026`.

## Backend

- Extend the endpoint with a `metric` param (default `completeness`):
  `GET /api/admin/coverage/map?metric=elections&level=state|county&state=<code>`.
- New logic (sibling module `electionsMapService.ts`, or a section of
  `coverageMapService.ts`):
  - **Next election date per state:** `MIN(election_date)` where `election_date >=
    CURRENT_DATE`, then select **all `elections` rows on that date** (there can be more
    than one — see Data wrinkle) and **all their races**.
  - **Races + candidate counts:** races for those election(s), each with
    `COUNT(race_candidates) > 0` as covered, plus `seats` and the resolved
    `district.ocd_id` (LEFT JOIN through offices/districts).
  - **Rollup:** state coverage = covered ÷ total races; county coverage = covered ÷ total
    over county-resolvable races, bucketed by largest-overlap (reusing the existing helper).
  - **Response shapes:**
    - `level=state`: `[{ fips, code, name, election_date, election_type, coverage,
      races_total, races_covered }]` (states with no upcoming election omitted).
    - `level=county`: `{ state, election_date, election_type, counties: [{ fips, name,
      status: 'unknown'|'scored', coverage, races: [{ position_name, seats,
      candidate_count, covered }] }] }`.
  - Reuse the 10-min cache, keyed including the metric.

## Frontend

- `CoverageMapPage` gains a `metric: 'completeness' | 'elections'` state + a toggle
  control. Fetches the matching endpoint.
- **Elections coloring:** an elections color scale (distinct enough from the teal
  completeness ramp is optional; can reuse the teal ramp). "Unknown" geographies render
  with a hatch/neutral fill and are non-interactive or show "no race data" on hover.
- **Hover:** name + `election_type · date` + coverage% (or "no race data").
- **Drill-down panel (county):** lists the county's **races** — position, seats,
  candidate count, covered ✓/✗ — instead of the completeness breakdown.
- Legend swaps to an elections legend with a "no race data" swatch.

## Data wrinkle (verified against live data)

- Races for an election event can be split across **multiple `elections` rows** sharing a
  date — e.g. CA 2026-06-02 has a `county`-level row (72 races) *and* a `state`-level row
  (0 races). The `jurisdiction_level` tag on the election row does **not** cleanly
  partition race levels (CA's "county" primary row contains federal/state/local races).
  → That's why scope is **by date, aggregating all rows on it**, and a race's true level
  comes from its `district.ocd_id`, not the election's `jurisdiction_level`.
- The same offices appear as separate races in the **primary** and the **general** (ME has
  190 + 190). These are on **different dates**, so date-scoping the "next" election counts
  each office once. Aggregating across all future elections would double-count — explicitly
  out of scope.

## Edge cases / graceful degradation

- **TX (0 races resolve to geography):** every TX county reads "unknown"; the TX *state*
  color still works (state-level coverage over all its races). This is honest given the
  data.
- **State with no upcoming election:** gray "not started" (same as untracked in
  completeness mode).
- **Race with `seats` but 0 candidates:** counts toward the denominator, lowers coverage.
- **Multiple elections same day / special elections:** "next upcoming" picks the soonest;
  ties broken deterministically (e.g. by `election_type` then `id`).

## Testing

- **Vitest:** next-election selection (today boundary, ties), race-coverage math,
  unknown-vs-0% classification, county resolution via largest-overlap, state-level races
  excluded from counties.
- **Manual:** toggle + drill on **UT** (138 primary races, 67 geo-resolvable) and **TX**
  (0 resolvable → all counties "unknown", state still colored).

## Out of scope (future)

- Filling in race→geography links so more races resolve to counties (data task, separate).
- Per-race candidate *completeness* (candidates ÷ seats) or contested-ness — this design
  uses simple race coverage.
- A user-selectable election dropdown (we use auto "next upcoming per state").
- Surfacing elections data in the public-facing apps (admin-only for now).
