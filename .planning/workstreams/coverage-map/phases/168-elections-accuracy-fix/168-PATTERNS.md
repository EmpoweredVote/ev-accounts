# Phase 168: Elections Accuracy Fix - Pattern Map

**Mapped:** 2026-07-04
**Files analyzed:** 7 (all touched files named in CONTEXT.md canonical refs)
**Analogs found:** 7 / 7 (6 are in-file self-analogs — this is a "copy the sibling function" refactor, not a cross-module port)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `backend/src/lib/electionsMap.ts` (extend, e.g. `classifyRaces`) | utility (pure helper) | transform | `resolveRaceCountyFips` + `classifyCounty` in the same file | exact (self-analog) |
| `backend/src/lib/electionsMapService.ts` — `getElectionsStateScores` | service | CRUD (read-aggregate) | `getElectionsCountyScores` in the same file (lines 143-175) | exact (self-analog, same file) |
| `backend/src/lib/electionsMap.test.ts` (extend) | test | transform (unit) | existing `describe('classifyCounty', ...)` block, same file | exact (self-analog) |
| `backend/src/routes/admin.ts` — `GET /coverage/map` | route | request-response | no change expected (route already forwards service return value); the route's own structure is its own analog | exact (self-analog, likely zero-diff) |
| `backend/src/routes/admin.test.ts` (NEW — optional per research Wave-0 gap) | test (route/integration) | request-response | `backend/src/routes/people.test.ts` | role-match |
| `admin/src/pages/admin/coverageTypes.ts` — `StateElection` (extend) | model (frontend type) | transform | `CountyElection`/`ClassifiedCounty`-shaped `status: 'unknown'|'scored'` pattern, same file / `electionsMap.ts` | exact (self-analog) |
| `admin/src/pages/admin/CoverageMap.tsx` — `electionStateColor` + hover readout (modify) | component (pure render helpers) | transform | `electionCountyColor` in the same file (lines 38-42) and the county hover-readout branch (lines 152-160) | exact (self-analog) |
| `admin/src/pages/admin/StatewideRacesPanel.tsx` (NEW component) | component | request-response (renders already-fetched data, no own fetch) | `CoverageTable.tsx`'s `UsOverviewTable` (lines 163-216) for table styling; `CoveragePage.tsx`'s conditional-render-below-map slot (lines 170-180) for mount pattern | role-match |
| `admin/src/pages/admin/CoveragePage.tsx` (modify — mount panel) | component (page/container) | request-response | its own existing `{metric === 'completeness' && <CoverageTable .../>}` conditional block (lines 171-180) | exact (self-analog) |

## Pattern Assignments

### `backend/src/lib/electionsMap.ts` (utility, transform)

**Analog:** same file — `classifyCounty` (lines 63-67) mirrors the `status: 'unknown'|'scored'` shape that the new state-level county-pinnable bucket must reuse; `resolveRaceCountyFips` (lines 46-60) is the classifier to call, unchanged.

**Existing shape to mirror** (lines 14-18, 62-67):
```typescript
export interface ClassifiedCounty {
  status: 'unknown' | 'scored';
  coverage: number; // 0..100 (0 when unknown)
  races: RaceRow[];
}

/** Classify a county's resolved race set into the unknown / scored buckets. */
export function classifyCounty(races: RaceRow[]): ClassifiedCounty {
  if (races.length === 0) return { status: 'unknown', coverage: 0, races: [] };
  // `scored` with coverage: 0 means races exist here but none have candidates yet (distinct from `unknown` = no races resolve to this county).
  return { status: 'scored', coverage: raceCoverage(races), races };
}
```

**The classifier to reuse in place, unchanged** (lines 46-60):
```typescript
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
```

**Coverage math to reuse unchanged** (lines 30-35):
```typescript
export function raceCoverage(races: RaceRow[]): number {
  if (races.length === 0) return 0;
  const covered = races.filter((r) => r.candidate_count > 0).length;
  return Math.round((covered / races.length) * 1000) / 10;
}
```

**Guidance:** D-04/discretion allows (but does not require) a small named wrapper here (e.g. `classifyRaces(races, countyMap, placeMap): { statewide: RaceRow[]; countyPinnable: RaceRow[] }`) built as a single-pass partition over `resolveRaceCountyFips`. If added, it belongs in this file beside `classifyCounty`, follows the same "pure, no I/O" doc-comment convention at the top of the file (line 1-4), and should be covered by a new `describe` block in `electionsMap.test.ts` using the existing `race()` factory. No new file.

---

### `backend/src/lib/electionsMapService.ts` — `getElectionsStateScores` (service, CRUD)

**Analog:** `getElectionsCountyScores`, same file, lines 143-175 — this is the "already correct" sibling function; the fix is to make `getElectionsStateScores` fetch and classify the same way.

**Buggy current shape to replace** (lines 121-140):
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
        coverage: raceCoverage(races),          // BUG: lumps ALL races (any level)
        races_total: races.length, races_covered: covered,
      });
    }
    return out;
  });
}
```

**Analog pattern to copy the fetch/classify shape from** (lines 143-175, esp. 153-167):
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
      if (!cf) continue;  // races that don't resolve are DROPPED here — this is exactly the "statewide" bucket
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

**Cache pattern to preserve — extend payload, do not add a cache key** (lines 104-110):
```typescript
const CACHE_TTL_MS = 10 * 60 * 1000;
const cache = new Map<string, { at: number; data: unknown }>();
function cached<T>(key: string, refresh: boolean, build: () => Promise<T>): Promise<T> {
  const hit = cache.get(key);
  if (!refresh && hit && Date.now() - hit.at < CACHE_TTL_MS) return Promise.resolve(hit.data as T);
  return build().then((data) => { cache.set(key, { at: Date.now(), data }); return data; });
}
```
`getElectionsStateScores` stays cached under the single existing key `'elections:us'`; the payload's shape grows, the cache key does not.

**Error handling pattern:** None inside this file — pure DB read + in-memory partition, no try/catch here. Errors surface to the route handler's existing try/catch (see `admin.ts` below). No new error-handling pattern needed.

**Concrete target shape (from RESEARCH.md's Code Examples section, cross-checked against the analog above):**
```typescript
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
This is a straight copy of the `getElectionsCountyScores` loop body (lines 160-167) with the branches inverted into two arrays instead of a `Map` keyed by county.

---

### `backend/src/lib/electionsMap.test.ts` (test, transform/unit)

**Analog:** same file, `describe('classifyCounty', ...)` block (lines 48-57) and the `race()` factory (lines 4-6).

**Factory + assertion pattern to copy:**
```typescript
const race = (over: Partial<RaceRow> = {}): RaceRow => ({
  race_id: 'r', position_name: 'X', seats: 1, candidate_count: 0, ocd_id: null, ...over,
});

describe('classifyCounty', () => {
  it('is unknown when no races resolve to the county', () => {
    expect(classifyCounty([]).status).toBe('unknown');
  });
  it('is scored with coverage when races resolve', () => {
    const c = classifyCounty([race({ candidate_count: 1 }), race({ candidate_count: 0 })]);
    expect(c.status).toBe('scored');
    expect(c.coverage).toBe(50);
  });
});
```
New tests for the state-split/partition helper (if a named `classifyRaces` wrapper is added) or for `resolveRaceCountyFips`-based partition behavior should follow this exact `describe`/`it`/`race()` structure — no mocking needed since all of `electionsMap.ts` is pure. Cover: (1) all-statewide race set → county bucket empty, (2) mixed set → correct split, (3) empty race set → `status: 'unknown'` not `coverage: 0` masquerading as real zero.

---

### `backend/src/routes/admin.ts` — `GET /coverage/map` (route, request-response)

**Analog:** the route's own existing structure (lines 168-200) — this file likely needs **zero changes** since it already forwards `getElectionsStateScores()`'s return value directly.

**Current pattern (no change expected):**
```typescript
router.get('/coverage/map', async (req, res) => {
  try {
    const level = String(req.query.level ?? 'state');
    const metric = String(req.query.metric ?? 'completeness');
    const refresh = req.query.refresh === '1' || req.query.refresh === 'true';
    const elections = metric === 'elections';
    if (level === 'county') {
      const state = String(req.query.state ?? '').toLowerCase();
      if (!state) { res.status(400).json({ error: 'state query param required for level=county' }); return; }
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

**Auth pattern (shared, applies to this whole router, unchanged):** `router.use(requireAuth as any, requireAdmin as any);` at line 81 of `admin.ts` — applies to every route in the file including this one; no per-route auth code needed or to be added.

---

### `backend/src/routes/admin.test.ts` (NEW, optional per RESEARCH.md Wave-0 gap — test/route)

**Analog:** `backend/src/routes/people.test.ts` (full file, 60 lines) — the established `vi.mock` + bare-`express()` + `supertest` template for route-level tests in this codebase. No `admin.test.ts` currently exists.

**Full template to copy:**
```typescript
import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockGetPeople, mockGetPersonById, mockGetAppearancesById } = vi.hoisted(() => ({
  mockGetPeople: vi.fn(),
  mockGetPersonById: vi.fn(),
  mockGetAppearancesById: vi.fn(),
}));
vi.mock('../lib/peopleService.js', () => ({
  getPeople: mockGetPeople,
  getPersonById: mockGetPersonById,
  getAppearancesById: mockGetAppearancesById,
}));
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import peopleRouter from './people.js';

const app = express();
app.use('/api/people', peopleRouter);

beforeEach(() => {
  mockGetPeople.mockReset();
  // ...
});

describe('GET /api/people', () => {
  it('200 with the roster', async () => {
    mockGetPeople.mockResolvedValueOnce([samplePerson]);
    const res = await request(app).get('/api/people');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([samplePerson]);
  });
});
```

**Adaptation notes for `admin.ts`:**
- `admin.ts` exports `default router` (line 1297) and applies `router.use(requireAuth as any, requireAdmin as any)` at module scope (line 81) — the `vi.mock('../middleware/auth.js', ...)` and an equivalent mock for `../middleware/requireAdmin.js` must both bypass auth (pass-through `next()`), mirroring the `optionalAuth` mock above but for `requireAuth`/`requireAdmin`.
- Mock target is `vi.mock('../lib/electionsMapService.js', () => ({ getElectionsStateScores: mockFn, getElectionsCountyScores: mockFn2 }))`.
- Mount: `app.use('/api/admin', adminRouter)` then `request(app).get('/api/admin/coverage/map?metric=elections&level=state')`.
- Best test to add per RESEARCH.md's ELEC-03 gap: assert `countyCoverage.races_total` summed is internally consistent, or simply assert the route returns whatever the (now-partitioned) service mock returns unmodified — since the route does no transformation itself, this test is really validating the wiring, not the partition logic (which belongs in `electionsMap.test.ts`).

---

### `admin/src/pages/admin/coverageTypes.ts` — `StateElection` extension (model, transform)

**Analog:** `ClassifiedCounty` (`electionsMap.ts:14-18`) / `CountyElection` (same file, line 36) — the existing `status: 'unknown'|'scored'` vocabulary already used and already consumed correctly by the frontend.

**Current shape to extend** (lines 31-36):
```typescript
export interface StateElection {
  fips: string; code: string; election_date: string; election_type: string;
  coverage: number; races_total: number; races_covered: number;
}
export interface ElectionRace { race_id: string; position_name: string; seats: number; candidate_count: number; ocd_id: string | null; }
export interface CountyElection { fips: string; name: string; status: 'unknown' | 'scored'; coverage: number; races: ElectionRace[]; }
```

**Target shape (per RESEARCH.md Pattern 2, directly buildable):**
```typescript
export interface StateElection {
  fips: string;
  code: string;
  election_date: string;
  election_type: string;
  // Existing fields — repointed to the statewide/legislative bucket (D-01 colors the map with this):
  coverage: number;
  races_total: number;
  races_covered: number;
  // NEW — county/local-pinnable bucket, explicitly nullable-safe (mirrors CountyElection's status pattern):
  countyCoverage: { status: 'unknown' | 'scored'; coverage: number; races_total: number; races_covered: number };
  // NEW — for the ELEC-02 panel (reuses the existing ElectionRace shape, same fields as RaceRow backend-side):
  statewideRaces: ElectionRace[];
}
```
Do not add a new sentinel numeric value (`-1`, `0` for N/A) — the `status` field is the established codebase vocabulary for "denominator zero" (see `CountyElection.status` and its consumer in `CoverageMap.tsx`, next section).

---

### `admin/src/pages/admin/CoverageMap.tsx` — `electionStateColor` + hover readout (component, transform)

**Analog:** `electionCountyColor` (same file, lines 38-42) and the county hover-readout branch (lines 152-160) — both already implement the exact `unknown` vs `scored` visual distinction that D-03 requires at the state level.

**Existing county pattern to mirror for the new state-level N/A branch** (lines 38-42):
```typescript
function electionCountyColor(c: CountyElection | undefined): string {
  if (!c) return NOT_STARTED;
  if (c.status === 'unknown') return NO_RACE_DATA;
  return scoreColor(c.coverage <= 0 ? 0.01 : c.coverage);
}
```

**Hover-readout analog to mirror for the state-level "N/A — no county-level races" text** (lines 152-160):
```typescript
} else {
  const ec = elecCountiesByFips.get(hover.fips);
  elecReadout = (
    <>
      <span className="font-medium">{hover.name}</span>
      {!ec || ec.status === 'unknown' ? <span className="ml-2 text-gray-400">no race data</span> : <span className="ml-2 tabular-nums text-gray-500 dark:text-gray-400">{ec.coverage}%</span>}
    </>
  );
}
```

**Current state-level code to update — D-01's one-field repoint** (line 37 and lines 143-151):
```typescript
function electionStateColor(s: StateElection | undefined): string { return s ? scoreColor(s.coverage) : NOT_STARTED; }
// ...
if (hover.level === 'state') {
  const es = elecStatesByFips.get(hover.fips);
  elecReadout = (
    <>
      <span className="font-medium">{hover.name}</span>
      {es ? <span className="ml-2 tabular-nums text-gray-500 dark:text-gray-400">{es.coverage}%</span> : <span className="ml-2 text-gray-400">no upcoming election</span>}
    </>
  );
}
```
`electionStateColor` keeps reading `s.coverage` (D-01: now correctly the statewide/legislative-only number after the backend fix — this function itself does not need to change, only the meaning of the field it reads changes upstream). The state hover readout also keeps reading `es.coverage` for the map-color number; if the readout is extended to also show the county-pinnable number inline, copy the `!ec || ec.status === 'unknown'` ternary pattern verbatim, substituting `es.countyCoverage.status === 'unknown'` → `"N/A — no county-level races"`.

**Constant to reuse for any new "N/A" swatch/legend entry** (line 22): `const NO_RACE_DATA = '#3f3f46';` — already used for county `unknown`; reuse the same hex for consistency if a state-level "no county races" legend entry is added.

---

### `admin/src/pages/admin/StatewideRacesPanel.tsx` (NEW component, request-response/render-only)

**Analog A — table styling and header/count pattern:** `CoverageTable.tsx`'s `UsOverviewTable` (lines 163-216).

**Analog B — mount/conditional-render pattern:** `CoveragePage.tsx`'s existing `{metric === 'completeness' && <CoverageTable .../>}` block (lines 170-180).

**Table shell + header pattern to copy** (from `CoverageTable.tsx` lines 163-180, adapt column list):
```typescript
function UsOverviewTable({ states, loading, onPick }: { states: StateScore[]; loading: boolean; onPick: (fips: string, name: string) => void }) {
  const sorted = [...states].sort((a, b) => b.score - a.score);
  return (
    <div className="overflow-hidden rounded-lg bg-white shadow dark:bg-gray-900">
      <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3 dark:border-gray-800">
        <h2 className="text-sm font-semibold text-gray-900 dark:text-white">
          All tracked states <span className="font-normal text-gray-400">({states.length})</span>
        </h2>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800">
            <tr>{/* ...th per column, first left-aligned, rest text-right... */}</tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {/* loading skeleton rows, empty state, then mapped rows */}
          </tbody>
        </table>
      </div>
    </div>
  );
}
```

**Empty-state and loading-skeleton pattern to copy** (`CoverageTable.tsx` lines 183-190):
```typescript
{loading && states.length === 0 ? (
  Array.from({ length: 6 }).map((_, i) => (
    <tr key={i} className="animate-pulse">
      <td colSpan={US_COLS.length} className="px-3 py-2"><div className="h-4 w-full rounded bg-gray-200 dark:bg-gray-700" /></td>
    </tr>
  ))
) : states.length === 0 ? (
  <tr><td colSpan={US_COLS.length} className="px-3 py-6 text-center text-gray-400">No tracked states yet.</td></tr>
) : (
  sorted.map((s) => ( /* row */ ))
)}
```
For the panel: `races.length === 0` → an empty-state row (e.g. "No statewide/legislative races for this election"); no loading skeleton needed since `statewideRaces` arrives already-fetched as part of `elecStates` (no separate fetch per D-04/discretion — see Pitfall 4 in RESEARCH.md).

**Suggested props shape** (new, no existing analog to copy verbatim since this is genuinely net-new UI — but shape mirrors `CoverageTable`'s prop-drilling convention, e.g. `focusCounty: CountyScore | null` at line 226):
```typescript
interface StatewideRacesPanelProps {
  stateElection: StateElection | null; // null → nothing selected, render nothing (parent already gates this)
}
```

**Row content fields available with zero new fetch** (from `ElectionRace`/`RaceRow`, already defined in `coverageTypes.ts` line 35): `position_name`, `seats`, `candidate_count` — render as `{r.position_name}` / `{r.candidate_count}/{r.seats} candidates` or similar; no styling analog exists for this exact "N of M candidates" cell, but `CoverageTable.tsx`'s `Roster` component (referenced at line 277: `<Roster actual={j.roster_actual} expected={j.expected_seats} .../>`) is the closest existing "count vs expected" cell pattern if the planner wants a shared sub-component rather than inline text.

---

### `admin/src/pages/admin/CoveragePage.tsx` (modify — mount panel) (component/container, request-response)

**Analog:** its own existing metric-gated conditional render block (lines 170-180) — the new panel is a sibling to this, gated the opposite way.

**Existing pattern to mirror (mount point and gating style)** (lines 170-180):
```typescript
{/* TABLE (below) — completeness only; whole page scrolls (no inner scroll box) */}
{metric === 'completeness' && (
  <CoverageTable
    states={states}
    statesLoading={statesLoading}
    state={selected?.code ?? null}
    focusCounty={selectedCounty}
    onClearCounty={() => setSelectedCounty(null)}
    onPickState={onSelectState}
  />
)}
```

**Target pattern (new sibling block, per D-02 — panel AND county view together on state click):**
```typescript
{metric === 'elections' && selected && (
  <StatewideRacesPanel stateElection={elecStatesByFips.get(selected.fips) ?? null} />
)}
```
Insert this directly after the map wrapper `</div>` (line 168) and before the existing completeness table block (line 170) — `elecStatesByFips` is already computed via `useMemo` at line 52 (`new Map(elecStates.map((s) => [s.fips, s]))`), so no new state/fetch is needed; the panel data flows from the already-lazily-fetched `elecStates` array. `onSelectState` (lines 75-83) already sets `selected` and calls `loadCounties(code)` on any state click regardless of metric — no new click-handling wiring required, only the new render branch.

---

## Shared Patterns

### N/A vs 0% (`status: 'unknown' | 'scored'`)
**Source:** `backend/src/lib/electionsMap.ts:14-18` (`ClassifiedCounty`) and `:63-67` (`classifyCounty`); consumed at `admin/src/pages/admin/CoverageMap.tsx:38-42` (`electionCountyColor`) and `:152-160` (hover readout).
**Apply to:** `StateElection.countyCoverage` (new field), any UI that renders it (`CoverageMap.tsx` state hover readout, `StatewideRacesPanel.tsx` if it also surfaces the county number).
```typescript
// Backend: the vocabulary
export interface ClassifiedCounty { status: 'unknown' | 'scored'; coverage: number; races: RaceRow[]; }
// Frontend: the branch to copy verbatim, swapping the text string
if (c.status === 'unknown') return NO_RACE_DATA; // color fill
{!ec || ec.status === 'unknown' ? <span className="ml-2 text-gray-400">no race data</span> : <span>...</span>} // text
```

### Single shared classifier, called at both tiers (D-04)
**Source:** `resolveRaceCountyFips` at `backend/src/lib/electionsMap.ts:46-60`.
**Apply to:** both `getElectionsStateScores` (new call site) and `getElectionsCountyScores` (existing call site, line 178 in RESEARCH.md's line numbering / line 162 in the direct read above) — same function, same `countyMap`/`placeMap` inputs shape (`countyOcdToFips(fips)` + `placeSlugToFips(fips)`), so the partition boundary can never drift between the two numbers within a single phase's code (see RESEARCH.md Pitfall 3 for the cross-cache-window caveat, accepted as out of scope).

### In-process 10-minute cache, one key per payload
**Source:** `cached()` helper, `backend/src/lib/electionsMapService.ts:104-110`.
**Apply to:** `getElectionsStateScores` keeps its existing `'elections:us'` key; do not add a second key for the new fields — extend the cached value's shape instead (Anti-pattern explicitly called out in RESEARCH.md).

### Router-level auth, not per-route
**Source:** `backend/src/routes/admin.ts:81` — `router.use(requireAuth as any, requireAdmin as any);`
**Apply to:** No action needed for `/coverage/map` (already covered); relevant only if a new route is added, which this phase does not require (the existing route already forwards the extended payload with zero changes).

### Route-level test scaffold (if `admin.test.ts` is added)
**Source:** `backend/src/routes/people.test.ts` (full file) — `vi.hoisted` mock factories, `vi.mock` for both the service module and the auth middleware, bare `express()` app, `supertest` requests.
**Apply to:** New `backend/src/routes/admin.test.ts`, scoped narrowly to the `/coverage/map?metric=elections` branches per RESEARCH.md's Wave-0 gap (A2 in Assumptions Log flags this as medium-risk if skipped).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `admin/src/pages/admin/StatewideRacesPanel.tsx` | component | request-response (render) | Net-new UI per D-02 ("no existing elections table/panel to extend") — closest available analogs (`CoverageTable.tsx` styling, `CoveragePage.tsx` mount slot) are cited above and sufficient to build from, but there is no single existing "elections panel" file to copy wholesale. |
| `backend/src/routes/admin.test.ts` | test | request-response | Does not currently exist for `admin.ts` (confirmed via RESEARCH.md's `find`); `people.test.ts` is the best available cross-route template, not a same-router analog. Optional for this phase per REQUIREMENTS.md scope, but recommended (RESEARCH.md Assumption A2). |

## Metadata

**Analog search scope:** `backend/src/lib/electionsMap*.ts`, `backend/src/routes/admin.ts`, `backend/src/routes/people.test.ts`, `admin/src/pages/admin/coverageTypes.ts`, `admin/src/pages/admin/CoveragePage.tsx`, `admin/src/pages/admin/CoverageMap.tsx`, `admin/src/pages/admin/CoverageTable.tsx` (all seven files named in CONTEXT.md's canonical refs, plus one cross-route test template).
**Files scanned:** 8 (all read directly, no re-reads of overlapping ranges — all files under phase's own 2,000-line small-file threshold).
**Pattern extraction date:** 2026-07-04
