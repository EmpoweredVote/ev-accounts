# Phase 168: Elections Accuracy Fix - Context

**Gathered:** 2026-07-04
**Status:** Ready for planning

> **Re-homed:** originally discussed as Phase 148 in an offline draft (milestone "v2.20 Coverage Map 1.1") before those identifiers were found to be already-shipped upstream. Now **Phase 168, milestone v2.23**, in the `coverage-map` workstream. Design decisions below are unchanged; code references re-verified against current `master` (the four elections files were untouched by the 216 commits since the June-29 base).

<domain>
## Phase Boundary

Fix the admin coverage map's **elections mode** so its numbers are computed correctly and internally consistent. Today `getElectionsStateScores()` composites *every* race at a state's nearest election date into one % (all levels lumped), while the county drill-down (`getElectionsCountyScores` → `resolveRaceCountyFips`) only counts county/place-pinnable races. A state with only statewide/legislative races therefore paints an undifferentiated 100% while every county reads empty (the Michigan bug).

This phase:
- Splits state elections coverage into **two separately-computed numbers per state** — statewide/legislative race coverage and county/local-pinnable race coverage — both derived from **one shared geographic-scope classifier** (`resolveRaceCountyFips`'s FIPS-vs-null result *is* that classifier).
- Adds a **statewide-races panel** on state click (ELEC-02), shown alongside the existing county view.
- Ensures state-level and county-level numbers use **consistent denominators** over the same race data so a state's map score never contradicts its own drill-down (ELEC-03).

**Requirements:** ELEC-01, ELEC-02, ELEC-03 (see the workstream `REQUIREMENTS.md`).

**Explicitly NOT in scope:** no schema changes; no new `coverageCore.ts` module (that is Phase 169); no Essentials/public-facing UI; no changes to the completeness metric or its map.
</domain>

<decisions>
## Implementation Decisions

### Map Coloring (ELEC-01 surfacing)
- **D-01:** The state choropleth fill in elections mode is colored by the **statewide/legislative coverage number** — this is the number the Michigan bug wrongly reported as 100%, so it is the primary signal to fix and show. The county/local-pinnable number is not what colors the state map; it drives the county drill-down as before.

### Statewide-Races Panel (ELEC-02)
- **D-02:** Clicking a state shows the **statewide-races panel AND the county view together** — the panel lists the state's statewide/legislative races with their candidate coverage, presented beside/above the county choropleth+drill-down rather than replacing it. Rationale: showing both halves of the split at once is what makes "never contradicts its own map score" visible to the admin without extra clicks.
- Note: elections mode currently renders only the map + a text readout (`CoveragePage.tsx` gates the `CoverageTable` to completeness mode only). The panel is **net-new UI** — no existing elections table/panel to extend.

### Empty / N-A Representation (ELEC-03)
- **D-03:** A state with **no county-pinnable races** (denominator = 0, the Michigan case) displays its county number as **"N/A — no county-level races"**, not 0% and not 100%. This must be visually distinct from "races exist but have zero candidates" (which is a real 0%). Truthful representation of "nothing of this type here" is the direct antidote to the misleading-percentage bug.

### Shared Classifier Seam (Phase-169 boundary)
- **D-04:** **Reuse the existing `resolveRaceCountyFips()` helper in place** as the single geographic-scope classifier — both the state split (statewide/legislative vs county-pinnable) and the county drill-down call the same function so the buckets are defined once. Do **not** build `coverageCore.ts` this phase; that extraction is Phase 169's job. This keeps Phase 168 isolated and low-risk per the roadmap's "front-load lowest-risk fix" framing.
- The classifier boundary is settled by the roadmap: `county:`/`place:` OCDs → county-pinnable; `cd`/`sldu`/`sldl`/bare-state (null result) → statewide/legislative. Legislative-district races belong in the statewide/legislative bucket.

### Claude's Discretion
- Exact layout/placement of the statewide-races panel relative to the map (side vs above), styling, and whether it reuses existing hover-card/table styling — planner/UI decides, provided both panel and county view are visible together on state click.
- How the two per-state numbers are cached (the service already has a 10-min in-process cache keyed per view) and the precise shape of the new API payload.
- Whether to add a small named wrapper around `resolveRaceCountyFips` for readability, as long as no new shared module is introduced.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase & Requirements
- `.planning/workstreams/coverage-map/ROADMAP.md` — Phase 168 section (goal, success criteria, Michigan root-cause writeup) + v2.23 milestone key-context paragraph
- `.planning/workstreams/coverage-map/REQUIREMENTS.md` — ELEC-01, ELEC-02, ELEC-03 full text

### Elections Mode Design (existing feature this phase corrects)
- `docs/superpowers/specs/2026-05-31-elections-mode-design.md` — original elections-mode design (race-coverage metric, state-composite vs county semantics)
- `docs/superpowers/plans/2026-05-31-elections-mode.md` — implementation plan for the current elections mode

### Code under change
- `backend/src/lib/electionsMap.ts` — pure helpers: `resolveRaceCountyFips` (the geographic-scope classifier), `raceCoverage`, `classifyCounty`, `RaceRow`
- `backend/src/lib/electionsMapService.ts` — `getElectionsStateScores` (the bug, ~line 121) + `getElectionsCountyScores`; DB queries + 10-min cache
- `backend/src/lib/electionsMap.test.ts` — existing unit tests for the pure helpers (extend here)
- `backend/src/routes/admin.ts` — `GET /coverage/map?metric=elections` (state + county branches, ~line 168)
- `admin/src/pages/admin/CoveragePage.tsx` — elections data fetch + layout (panel goes here)
- `admin/src/pages/admin/CoverageMap.tsx` — choropleth fill (`electionStateColor`, `electionCountyColor`) + readout
- `admin/src/pages/admin/coverageTypes.ts` — `StateElection`, `CountyElection`, `ElectionRace` types (extend for the two-number split)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`resolveRaceCountyFips(ocdId, countyMap, placeMap)`** — already classifies a race as county-pinnable (returns FIPS) vs statewide/legislative (returns null). This is the shared classifier; both new state numbers and the existing county buckets derive from it.
- **`raceCoverage(races)`** — computes covered÷total to one decimal; reuse for each of the two numbers over its own filtered race set.
- **`racesForStateDate(stateAbbr, date)`** — already fetches all races (with `ocd_id`) for the nearest date; partition its output by classifier result to produce both numbers with no extra query.
- **10-min in-process cache** (`cached()` in `electionsMapService.ts`) — extend the cached payload shape rather than adding new cache keys where possible.

### Established Patterns
- Nearest-upcoming-election-date semantics (`nextElectionDate`) drive both state and county scores — keep both numbers anchored to the **same date** so denominators stay consistent (this is core to ELEC-03).
- Elections mode uses a single-hue ramp + text readout; completeness mode uses the bivariate map + `CoverageTable`. Elections has **no** table today — the statewide panel is new.

### Integration Points
- `GET /admin/coverage/map?metric=elections&level=state` returns `{ states: StateElection[] }` — extend `StateElection` with the second (county-pinnable) number + statewide race list (or a companion field) for the panel.
- Frontend: `CoveragePage.tsx` state (`elecStates`, `selected`) + `CoverageMap.tsx` fill functions consume the new fields; panel renders in the elections branch that currently only shows the map.

### Sync note (2026-07-04)
- Verified against current `master`: `git rev-list --count <june29-base>..origin/master` = **0** for all four elections files. The design references above are still accurate; no re-grounding needed on the code side. The Michigan bug is still live (`getElectionsStateScores` still composites all races into one number).
</code_context>

<specifics>
## Specific Ideas

- **The Michigan case is the acceptance anchor:** a state with only statewide races must show its real statewide/legislative coverage in the map fill, its county number as "N/A — no county-level races," and clicking it must open a statewide-races panel — with nothing in the state view contradicting the county drill-down.
- Distinguish two kinds of "zero": `N/A` (no races of that scope resolve here — denominator 0) vs `0%` (races exist but none have candidates yet). The existing `classifyCounty` already separates `unknown` (no resolvable races) from `scored` coverage:0 — mirror that distinction in the state-level numbers.
</specifics>

<deferred>
## Deferred Ideas

- **`coverageCore.ts` shared jurisdiction-signals module** — extracting the geographic-scope classifier into a reusable core is explicitly Phase 169 (DB-Derived Coverage Core). Phase 168 only reuses `resolveRaceCountyFips` in place.
- **Bivariate / split-swatch fill** showing both numbers in the state color — considered for D-01 but deferred; single number (statewide/legislative) colors the map this phase.
- **Metric-toggle sub-control** to switch which number colors the map — considered and deferred; adds interaction surface beyond an accuracy fix.
- **DB-derived nationwide coverage (beyond YAML-tracked states)** and **city/place drill-down** — Phases 169/170. **User-relevant 3-axis lens** and **port-ready public API** — Phases 171/172.

</deferred>

---

*Phase: 168-elections-accuracy-fix (workstream: coverage-map)*
*Context gathered: 2026-07-04 (re-homed from offline Phase 148 draft)*
