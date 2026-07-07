# Phase 168: Elections Accuracy Fix - Research

**Researched:** 2026-07-04
**Domain:** TypeScript backend service refactor (pure functions + DB aggregation) + React admin UI (new panel)
**Confidence:** HIGH

## Summary

This phase fixes a well-isolated bug in a small, already-well-tested module. `getElectionsStateScores()` in `backend/src/lib/electionsMapService.ts` (lines 121-140) composites every race — statewide, legislative, county, and place level — into a single coverage percentage per state. Meanwhile `getElectionsCountyScores()` (lines 143-175) already does the correct thing: it calls `resolveRaceCountyFips()` to bucket races by county, and any race that doesn't resolve to a county (returns `null`) is silently dropped from the county view. The result: a state like Michigan with only statewide/legislative races on its next election date shows 100% on the state map (all races "covered" in the lumped composite) while every county shows "no race data" — an internally contradictory result with no visual explanation.

The fix is a partition, not a rewrite: `racesForStateDate()` already returns every race with its `ocd_id`; the same `resolveRaceCountyFips()` classifier already exists and returns `FIPS | null`. `getElectionsStateScores()` needs to call this classifier per race and split into two `raceCoverage()` calls instead of one. No new module, no schema change, no new query — this is confirmed by CONTEXT.md's D-04 and verified directly in the code. The remaining work is: (1) extend `StateElection` with the second number + an N/A-safe shape (denominator 0 must not collapse to `coverage: 0`), (2) extend the API payload to carry the statewide/legislative race list for the panel (ELEC-02), (3) build one net-new React panel component, and (4) wire it into `CoveragePage.tsx`'s currently panel-less elections branch.

**Primary recommendation:** Add a `classifyRaces(races, countyMap, placeMap)` splitting helper (or reuse `resolveRaceCountyFips` inline) in `electionsMap.ts`, mirroring the existing `unknown`/`scored` distinction from `classifyCounty` for the new `statewide` bucket so N/A is representable at the type level, not just as a UI string.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Race geographic-scope classification (county-pinnable vs statewide/legislative) | API / Backend (pure helper, `electionsMap.ts`) | — | Pure function, no I/O; must stay framework-agnostic and unit-testable per D-04 |
| Two-number state coverage computation | API / Backend (`electionsMapService.ts`) | Database / Storage (query source) | Aggregation over `essentials.races`/`race_candidates`; already the home of `getElectionsStateScores` |
| 10-min in-process cache | API / Backend | — | Existing `cached()` helper in `electionsMapService.ts`; extend payload shape in place |
| API contract (`/coverage/map?metric=elections`) | API / Backend (`admin.ts` route) | — | Route already branches on `metric`/`level`; only the response shape changes |
| Statewide-races panel rendering | Browser / Client (`CoveragePage.tsx` + new component) | — | Net-new UI, no SSR involved (admin SPA) |
| Map fill color (state choropleth) | Browser / Client (`CoverageMap.tsx`) | — | `electionStateColor` already isolated; swap which field it reads |
| N/A vs 0% visual distinction | Browser / Client | API / Backend (must emit distinguishable value) | Backend must not encode "no denominator" as `0` — UI can't recover the distinction otherwise |

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (Map Coloring):** The state choropleth fill in elections mode is colored by the **statewide/legislative coverage number** — this is the number the Michigan bug wrongly reported as 100%, so it is the primary signal to fix and show. The county/local-pinnable number is not what colors the state map; it drives the county drill-down as before.
- **D-02 (Statewide-Races Panel):** Clicking a state shows the **statewide-races panel AND the county view together** — the panel lists the state's statewide/legislative races with their candidate coverage, presented beside/above the county choropleth+drill-down rather than replacing it. Elections mode currently renders only the map + a text readout (`CoveragePage.tsx` gates `CoverageTable` to completeness mode only). The panel is **net-new UI** — no existing elections table/panel to extend.
- **D-03 (Empty/N-A Representation):** A state with **no county-pinnable races** (denominator = 0, the Michigan case) displays its county number as **"N/A — no county-level races"**, not 0% and not 100%. Must be visually distinct from "races exist but have zero candidates" (a real 0%).
- **D-04 (Shared Classifier Seam):** **Reuse the existing `resolveRaceCountyFips()` helper in place** as the single geographic-scope classifier — both the state split and the county drill-down call the same function. Do **not** build `coverageCore.ts` this phase (Phase 169's job). Classifier boundary: `county:`/`place:` OCDs → county-pinnable; `cd`/`sldu`/`sldl`/bare-state (null result) → statewide/legislative. Legislative-district races belong in the statewide/legislative bucket.

### Claude's Discretion

- Exact layout/placement of the statewide-races panel relative to the map (side vs above), styling, and whether it reuses existing hover-card/table styling — provided both panel and county view are visible together on state click.
- How the two per-state numbers are cached (extend the existing 10-min in-process cache rather than adding new cache keys where possible) and the precise shape of the new API payload.
- Whether to add a small named wrapper around `resolveRaceCountyFips` for readability, as long as no new shared module is introduced.

### Deferred Ideas (OUT OF SCOPE)

- **`coverageCore.ts` shared jurisdiction-signals module** — Phase 169 (DB-Derived Coverage Core). Phase 168 only reuses `resolveRaceCountyFips` in place.
- **Bivariate / split-swatch fill** showing both numbers in the state color — considered for D-01 but deferred; single number (statewide/legislative) colors the map this phase.
- **Metric-toggle sub-control** to switch which number colors the map — considered and deferred.
- **DB-derived nationwide coverage (beyond YAML-tracked states)** and **city/place drill-down** — Phases 169/170.
- **User-relevant 3-axis lens** and **port-ready public API** — Phases 171/172.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ELEC-01 | Elections coverage reports statewide/legislative races and county/local-pinnable races as separately computed metrics per state — a state with only statewide races can no longer display an undifferentiated 100% | `getElectionsStateScores` split confirmed at `backend/src/lib/electionsMapService.ts:121-140`; classifier `resolveRaceCountyFips` at `backend/src/lib/electionsMap.ts:46-60` returns FIPS-vs-null, the exact partition needed. `StateElection` type extension at `admin/src/pages/admin/coverageTypes.ts:31-34`. |
| ELEC-02 | Clicking a state in elections mode shows a statewide-races panel listing its statewide/legislative races with candidate coverage | `RaceRow` (`electionsMap.ts:6-12`) already carries `position_name`, `seats`, `candidate_count` — sufficient fields for the panel with zero new query. Mount point: `admin/src/pages/admin/CoveragePage.tsx` elections branch (currently only renders `CoverageMap`, lines 156-167; `CoverageTable` gated to completeness at line 171). |
| ELEC-03 | State-level and county-level elections numbers are computed from consistent denominators — clicking a state never shows data that contradicts its map score | Both `getElectionsStateScores` and `getElectionsCountyScores` already call `racesForStateDate(stateAbbr, nd.date)` anchored to the same `nextElectionDate()` result — the shared date anchor already exists; the fix must preserve it and additionally derive the state's two numbers from a race set fetched with the identical date query used by the county endpoint. |

## Standard Stack

This phase adds **no new dependencies**. It is a refactor within the existing stack:

### Core (existing, unchanged)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| TypeScript | project-pinned | Backend + shared types | Existing codebase language |
| Vitest | project-pinned (`vitest run`) | Unit tests for pure helpers (`electionsMap.test.ts`) | Existing test runner, confirmed via `backend/vitest.config.ts` |
| Express | project-pinned | `admin.ts` route layer | Existing router |
| React | project-pinned | Admin SPA (`CoveragePage.tsx`, `CoverageMap.tsx`) | Existing frontend |
| react-simple-maps | project-pinned | Choropleth rendering | Already imported in `CoverageMap.tsx:14`; unaffected — only the data feeding `electionStateColor`/`electionCountyColor` changes |
| supertest | project-pinned (devDependency) | Route-level integration tests (pattern seen in `people.test.ts`) | Confirmed present via `backend/vitest.config.ts` alias `'supertest'` |

**No installation required.** No `Package Legitimacy Audit` needed — this phase introduces zero new external packages `[VERIFIED: grep of all touched files' imports — see Code to Ground section below]`.

## Package Legitimacy Audit

**Not applicable.** This phase touches only existing files (`electionsMap.ts`, `electionsMapService.ts`, `admin.ts`, `CoveragePage.tsx`, `CoverageMap.tsx`, `coverageTypes.ts`) and adds no new imports from outside the current dependency set. Confirmed by reading every file's import block during grounding (Step "Code to Ground" below) — no new package names appear anywhere in the design. If the planner introduces a new UI dependency for the panel (e.g., a table/list library), it must re-run the Package Legitimacy Gate at that time; none is expected to be necessary since `CoverageTable.tsx` already demonstrates the plain-`<table>` pattern to copy.

## Code to Ground (current shape, verified against `master` at research time)

All four files named in CONTEXT.md's sync note were confirmed **unchanged** since the June-29 base (`git log -1` on each shows last touch `54f53461 fix(coverage-map): guard against null names in geofence_boundaries queries`, which did not modify the elections files). Line numbers below are exact as of this research pass.

### `backend/src/lib/electionsMap.ts` (68 lines total) — pure helpers, no DB
```typescript
// Lines 6-12
export interface RaceRow {
  race_id: string;
  position_name: string;
  seats: number;
  candidate_count: number;
  ocd_id: string | null; // race's district OCD (via office → district), if any
}

// Lines 14-18
export interface ClassifiedCounty {
  status: 'unknown' | 'scored';
  coverage: number; // 0..100 (0 when unknown)
  races: RaceRow[];
}

// Lines 30-35
export function raceCoverage(races: RaceRow[]): number {
  if (races.length === 0) return 0;
  const covered = races.filter((r) => r.candidate_count > 0).length;
  return Math.round((covered / races.length) * 1000) / 10;
}

// Lines 46-60 — THE SHARED CLASSIFIER (D-04)
export function resolveRaceCountyFips(
  ocdId: string | null,
  countyOcdToFips: Map<string, string>,
  placeSlugToFips: Map<string, string>,
): string | null {
  if (!ocdId) return null;
  const county = ocdId.match(/^(.*\/county:[^/]+)/);
  if (county) return countyOcdToFips.get(county[1]) ?? null;
  const place = ocdId.match(/\/place:([^/]+)/);
  if (place) return placeSlugToFips.get(place[1]) ?? null;
  return null; // cd / sldu / sldl / bare state → state-level only
}

// Lines 63-67
export function classifyCounty(races: RaceRow[]): ClassifiedCounty {
  if (races.length === 0) return { status: 'unknown', coverage: 0, races: [] };
  return { status: 'scored', coverage: raceCoverage(races), races };
}
```
`[VERIFIED: direct file read, backend/src/lib/electionsMap.ts]`

**Key fact for the planner:** `resolveRaceCountyFips` returns `null` for exactly the races that belong in the "statewide/legislative" bucket (`cd:`, `sldu:`, `sldl:`, bare state OCD, or `ocdId === null`). This is a perfect partition function — `races.filter(r => resolveRaceCountyFips(r.ocd_id, countyMap, placeMap) === null)` is the statewide/legislative set; the inverse (non-null result) is the county-pinnable set. No new classifier logic is needed, only a call-site change in `getElectionsStateScores`.

### `backend/src/lib/electionsMapService.ts` (176 lines total)

**The bug — `getElectionsStateScores`, lines 121-140:**
```typescript
export async function getElectionsStateScores(opts: { refresh?: boolean } = {}): Promise<StateElection[]> {
  return cached('elections:us', !!opts.refresh, async () => {
    const out: StateElection[] = [];
    for (const code of await statesWithUpcomingElections()) {
      const fips = STATE_ABBR_TO_FIPS[code];
      if (!fips) continue;
      const nd = await nextElectionDate(code.toUpperCase());
      if (!nd) continue;
      const races = await racesForStateDate(code.toUpperCase(), nd.date);
      const covered = races.filter((r) => r.candidate_count > 0).length;
      out.push({
        fips, code,
        election_date: nd.date, election_type: nd.type,
        coverage: raceCoverage(races),          // <-- BUG: lumps ALL races (any level)
        races_total: races.length, races_covered: covered,
      });
    }
    return out;
  });
}
```
`races` here is **every** race at the state's nearest date regardless of `ocd_id` — county, place, cd, sldu, sldl, bare-state all mixed into one `raceCoverage()` call. This is confirmed as the exact bug described in CONTEXT.md and the phase objective.

**The correct pattern already exists next door — `getElectionsCountyScores`, lines 143-175:**
```typescript
export async function getElectionsCountyScores(
  stateCode: string,
  opts: { refresh?: boolean } = {},
): Promise<{ state: string; state_fips: string; election_date: string | null; election_type: string | null; counties: CountyElection[] } | null> {
  const code = stateCode.toLowerCase();
  const fips = STATE_ABBR_TO_FIPS[code];
  if (!fips) return null;
  return cached(`elections:county:${code}`, !!opts.refresh, async () => {
    const nd = await nextElectionDate(code.toUpperCase());
    if (!nd) return { state: code, state_fips: fips, election_date: null, election_type: null, counties: [] };
    const [races, countyMap, placeMap, names] = await Promise.all([
      racesForStateDate(code.toUpperCase(), nd.date),
      countyOcdToFips(fips),
      placeSlugToFips(fips),
      countyNames(fips),
    ]);
    const byCounty = new Map<string, RaceRow[]>();
    for (const r of races) {
      const cf = resolveRaceCountyFips(r.ocd_id, countyMap, placeMap);
      if (!cf) continue;  // <-- races that don't resolve are DROPPED here, not tracked as "statewide"
      const arr = byCounty.get(cf) ?? [];
      arr.push(r);
      byCounty.set(cf, arr);
    }
    const counties: CountyElection[] = [...names.entries()].map(([cf, name]) => {
      const c = classifyCounty(byCounty.get(cf) ?? []);
      return { fips: cf, name, status: c.status, coverage: c.coverage, races: c.races };
    }).sort((a, b) => a.name.localeCompare(b.name));
    return { state: code, state_fips: fips, election_date: nd.date, election_type: nd.type, counties };
  });
}
```
Note the `if (!cf) continue;` at line 163 — this is where statewide/legislative races currently vanish entirely from the county view (they're simply never counted anywhere sensible). The state score, meanwhile, counts them all in its lumped total. That asymmetry — statewide races counted once (wrongly, lumped) on the state side and zero times on the county side — is the root of the Michigan bug, not just "state uses one bucket, county uses another."

**Anchor for ELEC-03:** Both functions call `nextElectionDate(code.toUpperCase())` then `racesForStateDate(code.toUpperCase(), nd.date)` — same state, same date, same underlying query. This shared anchor already guarantees denominator consistency *if* the state function partitions its races the same way the county function does. The fix should call `countyOcdToFips(fips)` and `placeSlugToFips(fips)` inside `getElectionsStateScores` too (currently it does not — it only calls `racesForStateDate`), then classify each race with `resolveRaceCountyFips` exactly as the county function does.

**Current type — `StateElection` interface, lines 13-21:**
```typescript
export interface StateElection {
  fips: string;
  code: string;
  election_date: string;
  election_type: string;
  coverage: number;
  races_total: number;
  races_covered: number;
}
```
This is the single-number shape that must be extended to carry two numbers (see Architecture Patterns below for the proposed shape).

**10-min cache helper, lines 104-110:**
```typescript
const CACHE_TTL_MS = 10 * 60 * 1000;
const cache = new Map<string, { at: number; data: unknown }>();
function cached<T>(key: string, refresh: boolean, build: () => Promise<T>): Promise<T> {
  const hit = cache.get(key);
  if (!refresh && hit && Date.now() - hit.at < CACHE_TTL_MS) return Promise.resolve(hit.data as T);
  return build().then((data) => { cache.set(key, { at: Date.now(), data }); return data; });
}
```
Cache keys: `'elections:us'` for the state list, `` `elections:county:${code}` `` per state. Per D-04/discretion, the planner should extend the **payload shape** returned by `getElectionsStateScores` (still cached under `'elections:us'`) rather than adding a new cache key — the statewide race list for the panel is just another field per state in the same cached array.

**`racesForStateDate`, lines 45-67** — no change needed; already returns `ocd_id` per race, sufficient for classification. **`countyOcdToFips`/`placeSlugToFips`, lines 70-93** — no change needed; `getElectionsStateScores` just needs to also call these (currently it doesn't, since it never classifies).

`[VERIFIED: direct file read, backend/src/lib/electionsMapService.ts]`

### `backend/src/lib/electionsMap.test.ts` (57 lines) — existing test structure
Uses Vitest `describe`/`it`/`expect`, a `race()` factory building `RaceRow` with sane defaults, and direct assertions on pure functions (`raceCoverage`, `resolveRaceCountyFips`, `classifyCounty`, `toSlug`). No mocking needed since these are pure. New tests for a `classifyRaces`/statewide-split helper extend this file directly using the same `race()` factory pattern — no new test infra required. `[VERIFIED: direct file read]`

### `backend/src/routes/admin.ts` — `GET /coverage/map`, lines 168-200
```typescript
router.get('/coverage/map', async (req, res) => {
  try {
    const level = String(req.query.level ?? 'state');
    const metric = String(req.query.metric ?? 'completeness');
    const refresh = req.query.refresh === '1' || req.query.refresh === 'true';
    const elections = metric === 'elections';

    if (level === 'county') {
      const state = String(req.query.state ?? '').toLowerCase();
      if (!state) {
        res.status(400).json({ error: 'state query param required for level=county' });
        return;
      }
      if (elections) {
        const data = await getElectionsCountyScores(state, { refresh });
        res.json(data ?? { state, state_fips: null, election_date: null, election_type: null, counties: [] });
        return;
      }
      const data = await getCountyScores(state, { refresh });
      res.json(data ?? { state, state_fips: null, counties: [] });
      return;
    }

    if (elections) {
      res.json({ states: await getElectionsStateScores({ refresh }) });
      return;
    }
    res.json({ states: await getStateScores({ refresh }) });
  } catch (err) {
    console.error('[admin/coverage/map] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```
Import line: `import { getElectionsStateScores, getElectionsCountyScores } from '../lib/electionsMapService.js';` at **line 69** (not the CONTEXT.md's approximate "~line 168" for the route body — the route handler itself is at 168-200, matching CONTEXT.md's estimate exactly). **No route-layer change needed** — the route already forwards whatever `getElectionsStateScores` returns; extending that function's return shape flows straight through with zero route code changes. `[VERIFIED: direct file read]`

There is currently **no** `admin.test.ts` route-level integration test file (confirmed via `find`). Other routes (`people.test.ts`, `meetings.test.ts`, `search.test.ts`, `topics.test.ts`, `inform.test.ts`) demonstrate the pattern: `vi.mock` the service module, mount the router on a bare `express()` app, and hit it with `supertest`. If the planner wants an ELEC-03 contract test at the route layer, this is the template to copy — but note none currently exists for `admin.ts`, so this would be new test infrastructure, not an extension.

### `admin/src/pages/admin/coverageTypes.ts` (36 lines total) — types to extend
```typescript
// Lines 31-34 — extend for the two-number split
export interface StateElection {
  fips: string; code: string; election_date: string; election_type: string;
  coverage: number; races_total: number; races_covered: number;
}
// Line 35
export interface ElectionRace { race_id: string; position_name: string; seats: number; candidate_count: number; ocd_id: string | null; }
// Line 36
export interface CountyElection { fips: string; name: string; status: 'unknown' | 'scored'; coverage: number; races: ElectionRace[]; }
```
`[VERIFIED: direct file read]`

### `admin/src/pages/admin/CoveragePage.tsx` (183 lines total) — elections fetch + layout
- State: `elecStates` (line 20), `elecCounties` (21), `elecDate` (22), `selected`/`selectedCounty` (24-25) shared with completeness mode.
- Fetch: `useEffect` at lines 41-48 lazily loads `/admin/coverage/map?metric=elections&level=state` into `elecStates` on first toggle to elections mode.
- `loadCounties` (lines 55-73) branches on `metric`; elections branch (62-72) fetches `/admin/coverage/map?metric=elections&level=county&state=${code}` and sets `elecCounties` + `elecDate`.
- `onSelectState` (lines 75-83) is metric-agnostic — sets `selected` and calls `loadCounties(code)` regardless of mode. **This is the natural mount trigger for the new panel**: no new click-handling needed, only new render output gated on `metric === 'elections' && selected`.
- Render: `CoverageMap` mounted unconditionally at lines 156-167 (receives `elecStatesByFips`, `elecCountiesByFips`, `elecDate`, `selected`). `CoverageTable` gated `metric === 'completeness'` at line 171 — this is the **only** existing conditional render branch for mode-specific UI below the map; the new panel is a sibling to this block, gated the opposite way (`metric === 'elections' && selected`), likely inserted directly after the `</div>` closing the map wrapper at line 168 and before the completeness table block at line 170-180.
`[VERIFIED: direct file read]`

### `admin/src/pages/admin/CoverageMap.tsx` (268 lines total) — fill functions + readout
```typescript
// Lines 28-42
const RAMP_FROM = [0x8c, 0xcd, 0xd9];
const RAMP_TO = [0x00, 0x4e, 0x63];
function scoreColor(score: number | undefined): string {
  if (score == null || score <= 0) return NOT_STARTED;
  const t = Math.pow(Math.min(1, score / 100), 0.55);
  const ch = (i: number) => Math.round(RAMP_FROM[i] + (RAMP_TO[i] - RAMP_FROM[i]) * t);
  return `rgb(${ch(0)}, ${ch(1)}, ${ch(2)})`;
}
function electionStateColor(s: StateElection | undefined): string { return s ? scoreColor(s.coverage) : NOT_STARTED; }
function electionCountyColor(c: CountyElection | undefined): string {
  if (!c) return NOT_STARTED;
  if (c.status === 'unknown') return NO_RACE_DATA;
  return scoreColor(c.coverage <= 0 ? 0.01 : c.coverage);
}
```
Per **D-01**, `electionStateColor` (line 37) must read the new statewide/legislative field (currently reads `s.coverage`, which today is the buggy lumped number) — this is a one-field rename/redirect, not new logic. `electionCountyColor` (lines 38-42) already distinguishes `status === 'unknown'` (renders `NO_RACE_DATA`, a distinct gray `#3f3f46`) from real `coverage <= 0` (renders `scoreColor(0.01)`, a near-zero-but-visible color, not `NOT_STARTED`) — **this exact pattern is the model to mirror for the state-level N/A vs 0% distinction (D-03)**. The state hover-readout (lines 141-161) similarly branches `!ec || ec.status === 'unknown'` → "no race data" text vs numeric `%` — the same branch structure should drive the new "N/A — no county-level races" state-level text.

Hover readout for state (lines 143-151) currently reads `es.coverage` — same one-field swap as the fill function.
`[VERIFIED: direct file read]`

### `admin/src/pages/admin/CoverageTable.tsx` (479 lines) — styling reference only
Confirmed as a plain `<table className="w-full text-sm">` pattern (three separate tables at lines 174, 261, 404) with no exotic dependency — safe to copy this styling convention for the new statewide-races panel's race list rather than introducing a new UI library. `[VERIFIED: grep + line count]`

## Architecture Patterns

### System Architecture Diagram

```
[Admin browser: CoveragePage.tsx]
        |
        | GET /admin/coverage/map?metric=elections&level=state
        v
[admin.ts route, line 191-194] --unchanged-- --> [getElectionsStateScores()]
        |                                              |
        |                                    for each state w/ upcoming election:
        |                                    1. nextElectionDate(state)         <-- same date anchor
        |                                    2. racesForStateDate(state, date)  <-- same race set
        |                                    3. NEW: countyOcdToFips + placeSlugToFips (fetched, currently missing)
        |                                    4. NEW: partition races via resolveRaceCountyFips
        |                                    5. raceCoverage() x2 (statewide bucket, county bucket)
        |                                              |
        v                                              v
 [StateElection[] payload]  <---  { ...existing fields, statewide: {...}, countyPinnable: {...} | 'n/a', statewideRaces: RaceRow[] }
        |
        v
[CoveragePage.tsx] --sets elecStates--> [CoverageMap.tsx: electionStateColor reads statewide.coverage]
        |
        | onSelectState (existing handler, unchanged)
        v
   [selected state] --triggers--> loadCounties() --> GET /coverage/map?metric=elections&level=county&state=X
        |                                                    (unchanged: getElectionsCountyScores, already correct)
        v
  NEW: <StatewideRacesPanel races={elecStates.get(fips).statewideRaces} />   +   existing county choropleth/drill-down
  (both rendered together per D-02, in the elections+selected branch of CoveragePage.tsx)
```

### Recommended Project Structure

No new files/folders required beyond one new component:
```
backend/src/lib/
├── electionsMap.ts          # add: classifyRaces() or extend resolveRaceCountyFips call sites (no new file)
├── electionsMapService.ts   # modify: getElectionsStateScores() partitions races (lines 121-140)
├── electionsMap.test.ts     # extend: new describe block for the partition logic

admin/src/pages/admin/
├── coverageTypes.ts         # modify: StateElection extended, StatewideRace type (or reuse ElectionRace)
├── CoveragePage.tsx         # modify: render new panel in elections+selected branch
├── CoverageMap.tsx          # modify: electionStateColor reads new field; N/A text branch
├── StatewideRacesPanel.tsx  # NEW: net-new component (D-02) — list of statewide/legislative races w/ coverage
```

### Pattern 1: Partition-not-duplicate the race classification

**What:** Reuse `resolveRaceCountyFips` as a single-pass `Array.prototype.filter`/reduce to build both buckets from one race list, rather than querying twice or writing a second classifier.
**When to use:** Inside `getElectionsStateScores`, after fetching `races`, `countyMap`, `placeMap` (the same three the county function already fetches).
**Example:**
```typescript
// Source: derived from existing getElectionsCountyScores pattern (electionsMapService.ts:159-167)
const [races, countyMap, placeMap] = await Promise.all([
  racesForStateDate(code.toUpperCase(), nd.date),
  countyOcdToFips(fips),
  placeSlugToFips(fips),
]);
const statewideRaces: RaceRow[] = [];
const countyRaces: RaceRow[] = [];
for (const r of races) {
  const cf = resolveRaceCountyFips(r.ocd_id, countyMap, placeMap);
  (cf ? countyRaces : statewideRaces).push(r);
}
```
This guarantees ELEC-03: the same `races` array (from the same `nd.date`) feeds both numbers, and `getElectionsCountyScores` independently re-derives the identical `countyRaces` partition (verifiable by construction, not just convention) — the classifier is the single source of truth for the boundary per D-04.

### Pattern 2: Distinguish N/A (denominator 0) from real 0% at the type level

**What:** Mirror the existing `ClassifiedCounty` `status: 'unknown' | 'scored'` pattern (already in `electionsMap.ts:14-18`) for the new county-pinnable state-level number, instead of overloading `coverage: number` with a sentinel.
**When to use:** Any time a bucket can legitimately have zero races (D-03's Michigan case is "no county races exist for this state," which is categorically different from "county races exist, zero have candidates").
**Example:**
```typescript
// Proposed StateElection extension — mirrors ClassifiedCounty shape already proven in electionsMap.ts
export interface StateElection {
  fips: string;
  code: string;
  election_date: string;
  election_type: string;
  // Existing fields — repoint to the statewide/legislative bucket (D-01 colors the map with this):
  coverage: number;
  races_total: number;
  races_covered: number;
  // NEW — county/local-pinnable bucket, explicitly nullable-safe:
  countyCoverage: { status: 'unknown' | 'scored'; coverage: number; races_total: number; races_covered: number };
  // NEW — for the ELEC-02 panel:
  statewideRaces: RaceRow[]; // same shape already used by CountyElection.races
}
```
Using `status: 'unknown'` (denominator 0 → renders "N/A — no county-level races") vs `status: 'scored', coverage: 0` (real 0%) directly reuses the `classifyCounty` pattern already proven at `electionsMap.ts:63-67` and already consumed correctly by `electionCountyColor` in `CoverageMap.tsx:38-42`. This is the **most direct implementation of D-03** — no new sentinel values, no `-1` or `null` overloading of a numeric field.

### Anti-Patterns to Avoid
- **Encoding N/A as `coverage: 0` or `coverage: -1`:** Silently reintroduces exactly the kind of misleading-number bug this phase exists to fix. The `status` field pattern already exists in this codebase (`ClassifiedCounty`) — use it, don't invent a numeric sentinel.
- **Adding a second DB query for the statewide race list:** `racesForStateDate` already returns every race including `ocd_id`; the statewide races are already in memory after step 1 of Pattern 1. A second query would violate the "reuse in place, no new queries" spirit of D-04 and duplicate the date-anchor logic (risking ELEC-03 drift if the two queries could ever disagree).
- **New cache key per number:** The discretion note explicitly prefers extending the existing `'elections:us'` cached payload shape over adding `elections:us:statewide` / `elections:us:county` keys — two cache entries for data that must always agree is itself a Michigan-bug-shaped risk (they could go stale independently).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Race geographic-scope classification | A second/parallel classifier for the state split | `resolveRaceCountyFips` (existing, `electionsMap.ts:46-60`) | D-04 explicitly mandates this; it's already unit-tested for county/place/cd/sldu/sldl/null cases (`electionsMap.test.ts:19-38`) |
| Coverage percentage math | A new rounding/percentage formula | `raceCoverage` (existing, `electionsMap.ts:30-35`) | Already handles empty-array edge case (`length === 0 → 0`) and 1-decimal rounding consistently; reuse for both new buckets |
| N/A vs 0% state machine | A boolean flag or magic number | `status: 'unknown' | 'scored'` pattern from `ClassifiedCounty` | Already proven correct in production for the county case; extending it to state-level countyCoverage keeps the codebase's vocabulary consistent |

**Key insight:** Every piece this phase needs already exists in the 68-line `electionsMap.ts` file and is already correctly used by the county function. The entire fix is: (1) call the same helpers from `getElectionsStateScores` that `getElectionsCountyScores` already calls, (2) shape the extra data into the response, (3) build one new UI component to display it.

## Common Pitfalls

### Pitfall 1: Changing what `coverage`/`races_total`/`races_covered` mean without updating consumers
**What goes wrong:** If `coverage` is repointed to the statewide/legislative number (per D-01) but `CoverageMap.tsx`'s `electionStateColor` or hover readout aren't updated in the same change, the map could silently keep showing the old lumped semantics if a stale field name is read, or break if the field is renamed without updating both read sites (line 37 fill, line 145 hover).
**Why it happens:** Two read sites (`CoverageMap.tsx:37` and `:145`) both reference `s.coverage` / `es.coverage`; easy to update one and miss the other.
**How to avoid:** Grep `\.coverage\b` across `CoverageMap.tsx` and `CoveragePage.tsx` after the type change; both should now be reading intentionally (either the repointed field or an explicit rename).
**Warning signs:** Map fill and hover readout disagree after the change (fill shows old number, text shows new, or vice versa).

### Pitfall 2: Forgetting the `if (!fips) continue` / no-election early-return paths when adding the county-pinnable fetch
**What goes wrong:** `getElectionsStateScores` currently skips states without a known FIPS or without an upcoming election (lines 125-128) before ever calling `racesForStateDate`. If `countyOcdToFips`/`placeSlugToFips` calls are added, they must stay inside the same per-state loop guarded by these same early-returns, or the function will issue extra queries for states it's about to skip anyway.
**Why it happens:** The new fetches (`countyOcdToFips(fips)`, `placeSlugToFips(fips)`) look like they belong "at the top" but `fips` and `nd` aren't known until after the two early-return checks.
**How to avoid:** Add the two new queries via `Promise.all` immediately after the existing `racesForStateDate` call (same position `getElectionsCountyScores` uses them), inside the loop, after both early returns.
**Warning signs:** Slower `elections:us` cache rebuild than expected, or errors for states with no FIPS mapping.

### Pitfall 3: `getElectionsCountyScores`'s per-county classification silently diverging from the new state-level split
**What goes wrong:** If the state split and the county split ever call `resolveRaceCountyFips` with different `countyMap`/`placeMap` inputs (e.g., built at different times, or from a slightly different query), ELEC-03 could regress in a subtler way than the original bug — the two views would mostly agree but diverge on edge-case OCDs.
**Why it happens:** `countyOcdToFips`/`placeSlugToFips` are themselves DB queries; if the state endpoint and county endpoint cache them independently (they will, since they're separate `cached()` keys today: `elections:us` vs `elections:county:${code}`), there is a narrow window where DB changes (new geofence data) could make the two temporarily inconsistent.
**How to avoid:** This is a pre-existing property of the two-endpoint design (not introduced by this phase) — the `raceCoverage`/`resolveRaceCountyFips` functions are pure and deterministic given the same inputs, so inconsistency would only appear if `countyMap`/`placeMap` genuinely changed between the two cache windows (10 min apart at most). Acceptable per D-04's "reuse in place" scope; flag it as an Open Question below in case the planner wants a stricter guarantee (e.g., a single shared fetch).
**Warning signs:** A state's map score and its county drill-down disagree only occasionally / only right after a data import — would indicate this cache-window race condition rather than a logic bug.

### Pitfall 4: Panel race list becoming stale relative to the map's number after a `refresh=1` bust
**What goes wrong:** If `statewideRaces` is added to the `elections:us` payload (per Pattern 1, no new query) but the frontend caches `elecStates` in component state without ever refetching, a `refresh=1` cache bust on the backend won't be visible until the next full-page load in the admin UI, since `CoveragePage.tsx`'s `elecStates` fetch (lines 41-48) is guarded by `elecStates.length > 0` — it will never refetch on its own once populated.
**Why it happens:** Pre-existing behavior, not a new bug — but the panel's race list (a new piece of UI depending on this same lazily-fetched, never-auto-refreshed state) makes any staleness more visible to the admin than the plain percentage was.
**How to avoid:** No change required for phase scope (out of scope: real-time recomputation, per REQUIREMENTS.md's Out-of-Scope table) — just be aware this is existing behavior, not something to "fix" as part of ELEC-01/02/03.
**Warning signs:** N/A for this phase — documented as existing, acceptable behavior.

## Code Examples

### Proposed backend split (concrete, buildable from existing pieces)
```typescript
// Source: composed from electionsMapService.ts:121-140 (bug) + :143-167 (correct pattern) + electionsMap.ts:46-60 (classifier)
export async function getElectionsStateScores(opts: { refresh?: boolean } = {}): Promise<StateElection[]> {
  return cached('elections:us', !!opts.refresh, async () => {
    const out: StateElection[] = [];
    for (const code of await statesWithUpcomingElections()) {
      const fips = STATE_ABBR_TO_FIPS[code];
      if (!fips) continue;
      const nd = await nextElectionDate(code.toUpperCase());
      if (!nd) continue;
      const [races, countyMap, placeMap] = await Promise.all([
        racesForStateDate(code.toUpperCase(), nd.date),
        countyOcdToFips(fips),
        placeSlugToFips(fips),
      ]);
      const statewideRaces: RaceRow[] = [];
      const countyRaces: RaceRow[] = [];
      for (const r of races) {
        const cf = resolveRaceCountyFips(r.ocd_id, countyMap, placeMap);
        (cf ? countyRaces : statewideRaces).push(r);
      }
      const countyCovered = countyRaces.filter((r) => r.candidate_count > 0).length;
      const stateCovered = statewideRaces.filter((r) => r.candidate_count > 0).length;
      out.push({
        fips, code,
        election_date: nd.date, election_type: nd.type,
        coverage: raceCoverage(statewideRaces),           // D-01: map fill reads THIS
        races_total: statewideRaces.length, races_covered: stateCovered,
        countyCoverage: countyRaces.length === 0
          ? { status: 'unknown', coverage: 0, races_total: 0, races_covered: 0 }
          : { status: 'scored', coverage: raceCoverage(countyRaces), races_total: countyRaces.length, races_covered: countyCovered },
        statewideRaces,                                    // ELEC-02: panel data
      });
    }
    return out;
  });
}
```

### Proposed frontend N/A rendering (mirrors existing `electionCountyColor` branch)
```typescript
// Source: derived from CoverageMap.tsx:38-42 (existing county unknown/scored pattern)
function countyPinnableText(s: StateElection): string {
  if (s.countyCoverage.status === 'unknown') return 'N/A — no county-level races';
  return `${s.countyCoverage.coverage}%`;
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Single lumped `coverage` field for all race levels | Two separately-computed numbers (statewide/legislative vs county-pinnable) | This phase (168) | Map fill and county drill-down become internally consistent for every state, not just states with a mix of levels |
| `getElectionsCountyScores` silently drops non-county-resolvable races (`if (!cf) continue`) | Those same dropped races become the explicit statewide/legislative bucket, now visible via `statewideRaces` and the new panel | This phase | Previously "invisible" races (like Michigan's) become visible and countable |

**Deprecated/outdated:** None — this is a correctness fix to code shipped 2026-05-31 (`docs/superpowers/plans/2026-05-31-elections-mode.md`), not a library or pattern migration.

## Runtime State Inventory

**Not applicable.** This is a code-only accuracy fix with no schema change (explicitly out of scope per CONTEXT.md), no rename/rebrand, and no data migration. There is no stored data, live service config, OS-registered state, secret/env var, or build artifact that references the old buggy computation by name — the bug lives entirely in in-process JS logic (`getElectionsStateScores`) and a 10-minute in-process cache that self-expires; there is nothing to migrate, only code to fix. The `cached()` map is process-memory only (not Redis/persisted) — confirmed at `electionsMapService.ts:104-105` (`const cache = new Map<string, ...>()`), so a deploy alone clears any stale cached values.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | The proposed `StateElection.countyCoverage` nested-object shape (vs. flat sibling fields like `county_coverage`, `county_races_total`) is the best API shape — this is a design suggestion, not something CONTEXT.md locks. | Architecture Patterns, Pattern 2 | Low — purely a naming/shape choice left to Claude's discretion per CONTEXT.md; planner/implementer can flatten it without affecting correctness. |
| A2 | No new route-level (`admin.test.ts`) integration test currently exists for `/coverage/map`, so ELEC-03's "consistent denominators" guarantee will initially be verified only at the unit level (`electionsMap.test.ts`) unless the planner explicitly adds route-level coverage. | Validation Architecture, Code to Ground | Medium — a regression in the route glue code (not the pure helpers) could slip through if only unit tests are added; recommend the planner add a light route-level test given none exists. |

**All other claims in this research are `[VERIFIED]` via direct file reads of the exact files this phase touches** — this is a refactor of existing, fully-read code rather than new-library research, so the assumption surface is small.

## Open Questions

1. **Should `getElectionsStateScores` and `getElectionsCountyScores` share a single fetch of `countyMap`/`placeMap` per state to eliminate the narrow cache-window race condition described in Pitfall 3?**
   - What we know: Both currently (and will continue to) call `countyOcdToFips(fips)`/`placeSlugToFips(fips)` independently, cached under different keys (`elections:us` vs `elections:county:${code}`) with independent 10-minute TTLs.
   - What's unclear: Whether this is worth solving now or is acceptable given D-04's "isolated, low-risk fix" framing and the explicit deferral of `coverageCore.ts` (which would be the natural home for a shared fetch) to Phase 169.
   - Recommendation: Leave as-is for Phase 168 (matches D-04's scope boundary); flag for Phase 169 as a candidate motivating example for `coverageCore.ts`'s shared classifier caching.

2. **Exact API payload shape for `statewideRaces` — inline on `StateElection` (as sketched above) or a separate endpoint?**
   - What we know: CONTEXT.md's discretion note explicitly leaves "the precise shape of the new API payload" to the planner/implementer. `RaceRow`'s existing shape (`race_id`, `position_name`, `seats`, `candidate_count`, `ocd_id`) is already sufficient for the panel with no new fields.
   - What's unclear: Whether embedding the full race array in the (cached, fetched-for-all-50-states) `elections:us` payload bloats that response meaningfully — likely not, given election counts per state are small (tens, not thousands), but worth a sanity check during planning.
   - Recommendation: Inline on `StateElection` (as sketched) — avoids a second network round-trip for the panel and reuses the existing lazy-fetch-on-toggle pattern; revisit only if payload size becomes a measured problem.

## Environment Availability

Skipped — no external tool/service dependencies beyond the existing Postgres connection and Node/TypeScript toolchain already used by every other phase in this codebase. This phase touches only in-repo TypeScript/React files.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest (project-pinned), confirmed via `backend/vitest.config.ts` |
| Config file | `backend/vitest.config.ts` |
| Quick run command | `cd backend && npx vitest run src/lib/electionsMap.test.ts` |
| Full suite command | `cd backend && npm test` (runs `vitest run`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|---------------------|-------------|
| ELEC-01 | A race set with only `cd`/`sldu`/`sldl`/bare-state OCDs partitions entirely into the statewide bucket, county bucket empty | unit | `npx vitest run src/lib/electionsMap.test.ts -t "partition"` | ❌ Wave 0 — extend `electionsMap.test.ts` with new `describe` block |
| ELEC-01 | A mixed race set (some county-resolvable, some not) partitions correctly and each bucket's `raceCoverage()` is independent | unit | same file, new test case | ❌ Wave 0 |
| ELEC-02 | `getElectionsStateScores()` payload includes `statewideRaces` with the same `RaceRow` fields the panel needs (`position_name`, `candidate_count`, `seats`) | unit | `backend/src/lib/electionsMapService.test.ts` (new file) or extend an existing service-level test if one is added | ❌ Wave 0 — no `electionsMapService.test.ts` currently exists; the service function is DB-backed, so this needs either a DB-mocked unit test or an integration test against a test DB (check existing patterns in `essentialsService.test.ts` for the DB-mock convention used elsewhere in this codebase) |
| ELEC-03 | State's `countyCoverage` denominator (`races_total`) equals the sum of races counted across all counties in `getElectionsCountyScores` for the same state+date | integration/contract | New route-level test using the `people.test.ts`/`meetings.test.ts` `vi.mock` + `supertest` pattern against `admin.ts`, or a service-level test calling both functions with mocked `pool.query` and asserting the partition sums match | ❌ Wave 0 — no `admin.test.ts` exists; recommend adding one scoped to just the `/coverage/map?metric=elections` branches, mocking `electionsMapService.js` per the `people.test.ts` template (lines 1-22 of that file) |
| ELEC-03 | A state with zero county-pinnable races reports `countyCoverage.status === 'unknown'`, never `coverage: 0` | unit | `electionsMap.test.ts` or new service test | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `cd backend && npx vitest run src/lib/electionsMap.test.ts` (sub-second, pure functions)
- **Per wave merge:** `cd backend && npm test` (full backend suite)
- **Phase gate:** Full suite green before `/gsd-verify-work`; frontend has no test runner configured in this repo for `admin/` per current grep — manual verification of the panel (Michigan-case walkthrough) substitutes for automated UI tests unless the planner introduces one.

### Wave 0 Gaps
- [ ] `backend/src/lib/electionsMap.test.ts` — extend with partition/classification tests covering ELEC-01 (mixed and all-statewide race sets)
- [ ] `backend/src/lib/electionsMapService.test.ts` — new file; needs a DB-mocking approach for `getElectionsStateScores`/`getElectionsCountyScores` (check `essentialsService.test.ts` or similar for the `pool.query` mock convention already established elsewhere in `backend/src/lib/`) to cover ELEC-02 (payload shape) and ELEC-03 (denominator consistency) at the service layer without a live DB
- [ ] `backend/src/routes/admin.test.ts` — does not exist; optional but recommended given ELEC-03 is fundamentally a "the route never returns contradictory numbers" contract — a route-level test using the `people.test.ts` mock pattern would catch route-layer regressions the unit tests can't
- [ ] No frontend test framework detected for `admin/` — manual QA is the fallback for the new `StatewideRacesPanel` component and the N/A text rendering; flag this to the planner as a known gap, not something to build test infra for in this phase (out of scope)

## Security Domain

Not applicable — `workflow.security_enforcement` is absent from `.planning/config.json` (confirmed via direct read), which per the instructions means "absent = enabled," but this phase has no auth/session/access-control/crypto surface: it is a read-only admin-only reporting endpoint (already gated by `requireAuth`/`requireAdmin` middleware upstream of the `/coverage/map` route, unchanged by this phase) computing a percentage from existing public-facing election data. No new input validation surface (no new user input — the route already validates `state` query param existence at line 177-180), no new authentication/session/crypto code. Confirmed no injection risk: all DB queries in `electionsMapService.ts` use parameterized `pool.query(sql, [params])` calls (see lines 33-40, 46-59, 71-76, 81-89, 97-100) — this phase adds no new raw SQL, only new call sites of already-parameterized existing functions (`countyOcdToFips`, `placeSlugToFips`).

## Sources

### Primary (HIGH confidence)
- Direct file reads (this session): `backend/src/lib/electionsMap.ts`, `backend/src/lib/electionsMapService.ts`, `backend/src/lib/electionsMap.test.ts`, `backend/src/routes/admin.ts` (lines 1-219), `admin/src/pages/admin/CoveragePage.tsx` (full file), `admin/src/pages/admin/CoverageMap.tsx` (full file), `admin/src/pages/admin/coverageTypes.ts` (full file), `admin/src/pages/admin/CoverageTable.tsx` (grep + line count), `backend/src/routes/people.test.ts` (lines 1-50), `backend/vitest.config.ts`, `backend/package.json` (test script)
- `.planning/workstreams/coverage-map/phases/168-elections-accuracy-fix/168-CONTEXT.md` — locked decisions D-01 through D-04, canonical refs, sync note
- `.planning/workstreams/coverage-map/REQUIREMENTS.md` — ELEC-01, ELEC-02, ELEC-03 full text
- `git log -1` on all six touched files — confirms no changes since the June-29 base cited in CONTEXT.md's sync note

### Secondary (MEDIUM confidence)
- None — all findings in this research were verified by direct file inspection, not web search or training-data recall.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all existing tooling directly confirmed via config files
- Architecture: HIGH — every function/type/line cited was read directly from the current codebase in this session, not recalled from training data
- Pitfalls: HIGH — derived from direct reading of the actual control flow (early returns, cache keys, dual read-sites), not speculative

**Research date:** 2026-07-04
**Valid until:** 2026-07-18 (14 days — fast-moving repo per git log density, but this specific module was confirmed untouched for the entire 216-commit window cited in CONTEXT.md, so risk of drift before planning/execution is low)
