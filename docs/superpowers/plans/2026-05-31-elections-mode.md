# Elections Mode for the Coverage Map — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an "Elections" toggle to `/admin/coverage/map` that recolors the US→county choropleth by race-candidate coverage for each state's nearest upcoming election, with a race-list drill-down and graceful "no race data" handling.

**Architecture:** A new backend module `electionsMapService.ts` computes per-state and per-county "race coverage" (races with ≥1 candidate ÷ total races) for the soonest upcoming election date, reusing the existing largest-overlap place→county mapping. The map endpoint gains a `metric=elections` param. The frontend `CoverageMapPage` gains a metric toggle that swaps the color basis, hover, legend, and drill-down panel. Pure rollup/resolution logic is split into testable functions; SQL lives in thin query functions.

**Tech Stack:** Node 20 + TypeScript + Express + `pg` (Postgres/PostGIS), Vitest; React 18 + react-simple-maps.

**Spec:** `docs/superpowers/specs/2026-05-31-elections-mode-design.md`

---

## File Structure

- **Create** `backend/src/lib/electionsMap.ts` — pure helpers: `toSlug`, `raceCoverage`, `resolveRaceCountyFips`, `classifyCounty`, types. No DB. Fully unit-tested.
- **Create** `backend/src/lib/electionsMap.test.ts` — Vitest unit tests for the pure helpers.
- **Create** `backend/src/lib/electionsMapService.ts` — DB query functions + `getElectionsStateScores` / `getElectionsCountyScores` (compose + 10-min cache).
- **Modify** `backend/src/routes/admin.ts` — add `metric` param to `GET /coverage/map`.
- **Modify** `admin/src/pages/admin/CoverageMapPage.tsx` — metric toggle, elections coloring/hover/legend, race-list drill-down.

---

## Task 1: Pure helpers + types (no DB)

**Files:**
- Create: `backend/src/lib/electionsMap.ts`
- Test: `backend/src/lib/electionsMap.test.ts`

- [ ] **Step 1: Write the failing tests**

```ts
// backend/src/lib/electionsMap.test.ts
import { describe, it, expect } from 'vitest';
import { raceCoverage, resolveRaceCountyFips, classifyCounty, type RaceRow } from './electionsMap.js';

const race = (over: Partial<RaceRow> = {}): RaceRow => ({
  race_id: 'r', position_name: 'X', seats: 1, candidate_count: 0, ocd_id: null, ...over,
});

describe('raceCoverage', () => {
  it('is covered ÷ total, rounded to 1 decimal, 0..100', () => {
    expect(raceCoverage([race({ candidate_count: 1 }), race({ candidate_count: 0 })])).toBe(50);
    expect(raceCoverage([race({ candidate_count: 2 }), race({ candidate_count: 3 })])).toBe(100);
    expect(raceCoverage([race(), race()])).toBe(0);
  });
  it('returns 0 for an empty set', () => {
    expect(raceCoverage([])).toBe(0);
  });
});

describe('resolveRaceCountyFips', () => {
  const countyOcdToFips = new Map([['ocd-division/country:us/state:ut/county:salt_lake', '49035']]);
  const placeSlugToFips = new Map([['provo', '49049']]);
  it('resolves a county-level race directly', () => {
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut/county:salt_lake', countyOcdToFips, placeSlugToFips)).toBe('49035');
  });
  it('resolves a place-level race via its slug', () => {
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut/place:provo', countyOcdToFips, placeSlugToFips)).toBe('49049');
  });
  it('returns null for state/federal/legislative races', () => {
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut', countyOcdToFips, placeSlugToFips)).toBeNull();
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut/cd:1', countyOcdToFips, placeSlugToFips)).toBeNull();
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut/sldu:5', countyOcdToFips, placeSlugToFips)).toBeNull();
    expect(resolveRaceCountyFips(null, countyOcdToFips, placeSlugToFips)).toBeNull();
  });
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

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd backend && npx vitest run src/lib/electionsMap.test.ts`
Expected: FAIL — `Cannot find module './electionsMap.js'`.

- [ ] **Step 3: Implement the pure module**

```ts
// backend/src/lib/electionsMap.ts
/**
 * Pure helpers for elections mode (no DB). The "metric" is RACE COVERAGE:
 * the fraction of races that have at least one candidate loaded.
 */

export interface RaceRow {
  race_id: string;
  position_name: string;
  seats: number;
  candidate_count: number;
  ocd_id: string | null; // race's district OCD (via office → district), if any
}

export interface CountyElection {
  status: 'unknown' | 'scored';
  coverage: number; // 0..100 (0 when unknown)
  races: RaceRow[];
}

/** TIGER name → OCD-style slug. Mirrors coverageMapService.toSlug — keep in sync. */
export function toSlug(name: string, strip: RegExp): string {
  return name
    .replace(strip, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}
export const PLACE_STRIP = / (city|town)$/i;

/** Coverage % = races with ≥1 candidate ÷ total, one decimal. */
export function raceCoverage(races: RaceRow[]): number {
  if (races.length === 0) return 0;
  const covered = races.filter((r) => r.candidate_count > 0).length;
  return Math.round((covered / races.length) * 1000) / 10;
}

/**
 * Which county (5-digit FIPS) a race belongs to, or null if it can't be pinned to
 * one (federal / state / legislative-district / statewide races).
 *   - .../county:X  → direct lookup
 *   - .../place:Y   → the county that place sits in (largest-overlap map)
 */
export function resolveRaceCountyFips(
  ocdId: string | null,
  countyOcdToFips: Map<string, string>,
  placeSlugToFips: Map<string, string>,
): string | null {
  if (!ocdId) return null;
  const county = ocdId.match(/\/county:[^/]+$/);
  if (county) return countyOcdToFips.get(ocdId) ?? null;
  const place = ocdId.match(/\/place:([^/]+)$/);
  if (place) return placeSlugToFips.get(place[1]) ?? null;
  return null; // cd / sldu / sldl / bare state → state-level only
}

/** Classify a county's resolved race set into the unknown / scored buckets. */
export function classifyCounty(races: RaceRow[]): CountyElection {
  if (races.length === 0) return { status: 'unknown', coverage: 0, races: [] };
  return { status: 'scored', coverage: raceCoverage(races), races };
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd backend && npx vitest run src/lib/electionsMap.test.ts`
Expected: PASS (all 8 assertions).

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/electionsMap.ts backend/src/lib/electionsMap.test.ts
git commit -m "feat(elections-map): pure race-coverage + county-resolution helpers"
```

---

## Task 2: DB query functions

**Files:**
- Create: `backend/src/lib/electionsMapService.ts`

Reuses `STATE_ABBR_TO_FIPS` from `treasuryService.ts` (already exported) and the largest-overlap place→county pattern from `coverageMapService.ts`.

- [ ] **Step 1: Implement the query functions**

```ts
// backend/src/lib/electionsMapService.ts
/**
 * electionsMapService.ts — "elections mode" for the coverage map.
 *
 * Recolors geographies by RACE COVERAGE (races with ≥1 candidate ÷ total) for each
 * state's NEAREST upcoming election DATE. State % composites every race at that date
 * (all levels); county % counts only races that resolve to the county. See
 * docs/superpowers/specs/2026-05-31-elections-mode-design.md.
 */
import { pool } from './db.js';
import { STATE_ABBR_TO_FIPS } from './treasuryService.js';
import { toSlug, PLACE_STRIP, raceCoverage, resolveRaceCountyFips, classifyCounty, type RaceRow } from './electionsMap.js';

export interface StateElection {
  fips: string;
  code: string;
  election_date: string;
  election_type: string;
  coverage: number;
  races_total: number;
  races_covered: number;
}

export interface CountyElection {
  fips: string;
  name: string;
  status: 'unknown' | 'scored';
  coverage: number;
  races: RaceRow[];
}

/** Nearest upcoming election date for a state (2-letter), or null. */
export async function nextElectionDate(stateAbbr: string): Promise<{ date: string; type: string } | null> {
  const { rows } = await pool.query<{ election_date: string; election_type: string }>(
    `SELECT to_char(election_date,'YYYY-MM-DD') AS election_date, election_type
       FROM essentials.elections
      WHERE state = $1 AND election_date >= CURRENT_DATE
      ORDER BY election_date, election_type
      LIMIT 1`,
    [stateAbbr],
  );
  return rows[0] ? { date: rows[0].election_date, type: rows[0].election_type } : null;
}

/** All races (any level) across every elections row on a given date for a state. */
export async function racesForStateDate(stateAbbr: string, date: string): Promise<RaceRow[]> {
  const { rows } = await pool.query<{
    race_id: string; position_name: string; seats: number; candidate_count: string; ocd_id: string | null;
  }>(
    `SELECT r.id AS race_id, r.position_name, r.seats,
            COUNT(rc.id) AS candidate_count, d.ocd_id
       FROM essentials.elections e
       JOIN essentials.races r ON r.election_id = e.id
       LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
       LEFT JOIN essentials.offices o ON o.id = r.office_id
       LEFT JOIN essentials.districts d ON d.id = o.district_id
      WHERE e.state = $1 AND e.election_date = $2
      GROUP BY r.id, r.position_name, r.seats, d.ocd_id`,
    [stateAbbr, date],
  );
  return rows.map((r) => ({
    race_id: r.race_id,
    position_name: r.position_name,
    seats: Number(r.seats),
    candidate_count: Number(r.candidate_count),
    ocd_id: r.ocd_id,
  }));
}

/** county OCD → 5-digit FIPS for a state (FIPS string). */
export async function countyOcdToFips(stateFips: string): Promise<Map<string, string>> {
  const { rows } = await pool.query<{ ocd_id: string; geo_id: string }>(
    `SELECT ocd_id, geo_id FROM essentials.geofence_boundaries
      WHERE state = $1 AND mtfcc = 'G4020' AND ocd_id IS NOT NULL`,
    [stateFips],
  );
  return new Map(rows.map((r) => [r.ocd_id, r.geo_id]));
}

/** place slug → county FIPS (largest boundary overlap). Places lack ocd_id, so slug from name. */
export async function placeSlugToFips(stateFips: string): Promise<Map<string, string>> {
  const { rows } = await pool.query<{ name: string; county_fips: string | null }>(
    `SELECT p.name,
       (SELECT c.geo_id FROM essentials.geofence_boundaries c
         WHERE c.state = $1 AND c.mtfcc = 'G4020' AND ST_Intersects(c.geometry, p.geometry)
         ORDER BY ST_Area(ST_Intersection(c.geometry, p.geometry)) DESC LIMIT 1) AS county_fips
       FROM essentials.geofence_boundaries p
      WHERE p.state = $1 AND p.mtfcc = 'G4110'`,
    [stateFips],
  );
  const m = new Map<string, string>();
  for (const r of rows) if (r.county_fips) m.set(toSlug(r.name, PLACE_STRIP), r.county_fips);
  return m;
}

/** county FIPS → TIGER county name (for labels). */
export async function countyNames(stateFips: string): Promise<Map<string, string>> {
  const { rows } = await pool.query<{ geo_id: string; name: string }>(
    `SELECT geo_id, name FROM essentials.geofence_boundaries WHERE state = $1 AND mtfcc = 'G4020'`,
    [stateFips],
  );
  return new Map(rows.map((r) => [r.geo_id, r.name]));
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd backend && npm run typecheck`
Expected: no errors. (`raceCoverage`, `resolveRaceCountyFips`, `classifyCounty`, `STATE_ABBR_TO_FIPS` are unused for now — that's fine, they're used in Task 3. If `noUnusedLocals` complains, leave them; Task 3 adds usage in the same module.)

> NOTE: if the typecheck errors on unused imports, proceed directly to Task 3 (same file) before running typecheck again, or temporarily remove the unused names from the import and re-add in Task 3.

- [ ] **Step 3: Manually verify the queries against live data**

Create `backend/scripts/_probe_em.ts`:

```ts
import { nextElectionDate, racesForStateDate, countyOcdToFips, placeSlugToFips } from '../src/lib/electionsMapService.js';
import { pool } from '../src/lib/db.js';
async function main() {
  for (const st of ['UT', 'TX', 'CA']) {
    const nd = await nextElectionDate(st);
    const races = nd ? await racesForStateDate(st, nd.date) : [];
    console.log(`${st}: next=${JSON.stringify(nd)} races=${races.length} withOcd=${races.filter(r=>r.ocd_id).length}`);
  }
  console.log('UT county ocd→fips size:', (await countyOcdToFips('49')).size);
  console.log('UT place slug→fips size:', (await placeSlugToFips('49')).size);
  await pool.end();
}
main().catch((e) => { console.error(e); process.exit(1); });
```

Run: `cd backend && node --env-file=.env --import tsx scripts/_probe_em.ts`
Expected: UT next ~`{date:2026-06-23,type:primary}` races≈138; TX next `{...special...}` races≈1; CA races≈72. county/place maps non-empty for UT. Then delete the probe: `rm backend/scripts/_probe_em.ts`.

- [ ] **Step 4: Commit**

```bash
git add backend/src/lib/electionsMapService.ts
git commit -m "feat(elections-map): DB queries — next election, races, county resolution maps"
```

---

## Task 3: Compose state + county scores (with cache)

**Files:**
- Modify: `backend/src/lib/electionsMapService.ts` (append)

- [ ] **Step 1: Append the compose functions + cache**

```ts
// ── append to backend/src/lib/electionsMapService.ts ──

const CACHE_TTL_MS = 10 * 60 * 1000;
const cache = new Map<string, { at: number; data: unknown }>();
function cached<T>(key: string, refresh: boolean, build: () => Promise<T>): Promise<T> {
  const hit = cache.get(key);
  if (!refresh && hit && Date.now() - hit.at < CACHE_TTL_MS) return Promise.resolve(hit.data as T);
  return build().then((data) => { cache.set(key, { at: Date.now(), data }); return data; });
}

/** Lowercase 2-letter codes of states that have ≥1 upcoming election. */
async function statesWithUpcomingElections(): Promise<string[]> {
  const { rows } = await pool.query<{ state: string }>(
    `SELECT DISTINCT state FROM essentials.elections WHERE election_date >= CURRENT_DATE`,
  );
  return rows.map((r) => r.state.toLowerCase());
}

/** US choropleth: race coverage for each state's nearest upcoming election. */
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
        coverage: raceCoverage(races),
        races_total: races.length, races_covered: covered,
      });
    }
    return out;
  });
}

/** County choropleth + race drill-down for one state's nearest upcoming election. */
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
    // bucket county-resolvable races by county fips
    const byCounty = new Map<string, RaceRow[]>();
    for (const r of races) {
      const cf = resolveRaceCountyFips(r.ocd_id, countyMap, placeMap);
      if (!cf) continue;
      (byCounty.get(cf) ?? byCounty.set(cf, []).get(cf)!).push(r);
    }
    // every county in the state, classified (unknown if no resolvable races)
    const counties: CountyElection[] = [...names.entries()].map(([cf, name]) => {
      const c = classifyCounty(byCounty.get(cf) ?? []);
      return { fips: cf, name, status: c.status, coverage: c.coverage, races: c.races };
    }).sort((a, b) => a.name.localeCompare(b.name));
    return { state: code, state_fips: fips, election_date: nd.date, election_type: nd.type, counties };
  });
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd backend && npm run typecheck`
Expected: no errors.

- [ ] **Step 3: Manually verify the rollup**

Create `backend/scripts/_probe_es.ts`:

```ts
import { getElectionsStateScores, getElectionsCountyScores } from '../src/lib/electionsMapService.js';
import { pool } from '../src/lib/db.js';
async function main() {
  const states = await getElectionsStateScores();
  console.log('States:', states.map(s => `${s.code} ${s.election_type}/${s.election_date} cov=${s.coverage}% (${s.races_covered}/${s.races_total})`));
  const ut = await getElectionsCountyScores('ut');
  const scored = ut?.counties.filter(c => c.status === 'scored') ?? [];
  console.log(`UT date=${ut?.election_date} counties=${ut?.counties.length} scored=${scored.length} unknown=${(ut?.counties.length ?? 0) - scored.length}`);
  console.log('UT scored sample:', scored.slice(0, 3).map(c => `${c.name}=${c.coverage}% (${c.races.length} races)`));
  const tx = await getElectionsCountyScores('tx');
  console.log(`TX scored=${tx?.counties.filter(c=>c.status==='scored').length} (expect 0; all unknown)`);
  await pool.end();
}
main().catch((e) => { console.error(e); process.exit(1); });
```

Run: `cd backend && node --env-file=.env --import tsx scripts/_probe_es.ts`
Expected: states list with coverage %; UT has some scored counties + many unknown; TX scored = 0 (all unknown). Then `rm backend/scripts/_probe_es.ts`.

- [ ] **Step 4: Commit**

```bash
git add backend/src/lib/electionsMapService.ts
git commit -m "feat(elections-map): compose state + county race-coverage with cache"
```

---

## Task 4: Wire the `metric` param into the route

**Files:**
- Modify: `backend/src/routes/admin.ts`

- [ ] **Step 1: Add the import**

Add next to the existing coverage-map import (near `import { getStateScores, getCountyScores } from '../lib/coverageMapService.js';`):

```ts
import { getElectionsStateScores, getElectionsCountyScores } from '../lib/electionsMapService.js';
```

- [ ] **Step 2: Branch on `metric` inside the existing handler**

Replace the body of `router.get('/coverage/map', …)` with:

```ts
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

- [ ] **Step 3: Verify it compiles + responds (gated)**

Run: `cd backend && npm run typecheck`
Expected: no errors.

Run (dev server must be running on :3000): `curl -s -o /dev/null -w "%{http_code}\n" "http://localhost:3000/api/admin/coverage/map?metric=elections&level=state"`
Expected: `401` (admin-gated — confirms the route exists and is protected).

- [ ] **Step 4: Commit**

```bash
git add backend/src/routes/admin.ts
git commit -m "feat(elections-map): add metric=elections to /coverage/map route"
```

---

## Task 5: Frontend — metric toggle + elections coloring

**Files:**
- Modify: `admin/src/pages/admin/CoverageMapPage.tsx`

- [ ] **Step 1: Add elections types + a metric state**

Near the other interfaces at the top of the component module, add:

```tsx
type Metric = 'completeness' | 'elections';

interface StateElection { fips: string; code: string; election_date: string; election_type: string; coverage: number; races_total: number; races_covered: number; }
interface ElectionRace { race_id: string; position_name: string; seats: number; candidate_count: number; ocd_id: string | null; }
interface CountyElection { fips: string; name: string; status: 'unknown' | 'scored'; coverage: number; races: ElectionRace[]; }
```

Inside the component, add state (near the existing `useState` calls):

```tsx
const [metric, setMetric] = useState<Metric>('completeness');
const [elecStates, setElecStates] = useState<StateElection[]>([]);
const [elecCounties, setElecCounties] = useState<CountyElection[]>([]);
const [elecDate, setElecDate] = useState<{ date: string; type: string } | null>(null);
```

- [ ] **Step 2: Add the "unknown" color + an elections color lookup**

Add below the existing `scoreColor` helper:

```tsx
const NO_RACE_DATA = '#3f3f46'; // zinc-700 hatch-ish neutral — distinct from NOT_STARTED grey

// Elections fill: reuse the teal ramp for coverage, but "unknown" gets its own neutral.
function electionStateColor(s: StateElection | undefined): string {
  if (!s) return NOT_STARTED; // no upcoming election
  return scoreColor(s.coverage);
}
function electionCountyColor(c: CountyElection | undefined): string {
  if (!c) return NOT_STARTED;
  if (c.status === 'unknown') return NO_RACE_DATA;
  return scoreColor(c.coverage <= 0 ? 0.01 : c.coverage); // ensure 0%-covered still reads as teal floor, not grey
}
```

- [ ] **Step 3: Fetch elections data when in elections mode**

Add an effect (after the existing US-states effect):

```tsx
// Elections US scores — fetched lazily when the toggle is first flipped on
useEffect(() => {
  if (metric !== 'elections' || elecStates.length > 0) return;
  setStatesLoading(true);
  apiFetch<{ states: StateElection[] }>(`/admin/coverage/map?metric=elections&level=state`)
    .then((res) => setElecStates(res.states))
    .catch((err) => setError(err.message))
    .finally(() => setStatesLoading(false));
}, [metric, elecStates.length]);
```

Update `enterState` to also fetch elections counties when a state is entered in elections mode. Inside `enterState`, after the existing completeness county fetch block, add (guarded by metric):

```tsx
if (metric === 'elections' && code) {
  setLoading(true);
  apiFetch<{ election_date: string | null; election_type: string | null; counties: CountyElection[] }>(
    `/admin/coverage/map?metric=elections&level=county&state=${code}`,
  )
    .then((res) => {
      setElecCounties(res.counties);
      setElecDate(res.election_date ? { date: res.election_date, type: res.election_type ?? '' } : null);
    })
    .catch((err) => setError(err.message))
    .finally(() => setLoading(false));
}
```

> Implementation note: keep the existing completeness fetch in `enterState` behind `if (metric === 'completeness')` so only one runs. `enterState`'s dependency array must include `metric`.

- [ ] **Step 4: Add the toggle control + use the right fill**

Add a toggle next to the "Table view" link in the header:

```tsx
<div className="inline-flex overflow-hidden rounded-md border border-gray-300 text-xs dark:border-gray-600">
  {(['completeness', 'elections'] as Metric[]).map((m) => (
    <button
      key={m}
      onClick={() => { setMetric(m); setSelectedCounty(null); }}
      className={`px-2.5 py-1 font-medium capitalize ${metric === m ? 'bg-ev-teal text-white dark:bg-ev-teal-light dark:text-gray-900' : 'text-gray-600 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'}`}
    >
      {m}
    </button>
  ))}
</div>
```

In the US `<Geographies>` render, choose fill by metric:

```tsx
const sc = stateByFips.get(geo.id as string);
const es = elecStatesByFips.get(geo.id as string);
const fill = metric === 'elections' ? electionStateColor(es) : scoreColor(sc?.score);
```

(Add `const elecStatesByFips = useMemo(() => new Map(elecStates.map(s => [s.fips, s])), [elecStates]);` near the other `useMemo`s, and use `fill` in the `style.default/hover/pressed.fill`. Do the analogous swap in the county `<Geographies>` using `elecCountiesByFips` + `electionCountyColor`.)

- [ ] **Step 5: Verify build**

Run: `cd admin && npx tsc --noEmit && npm run build`
Expected: typecheck clean, build succeeds.

- [ ] **Step 6: Commit**

```bash
git add admin/src/pages/admin/CoverageMapPage.tsx
git commit -m "feat(elections-map): metric toggle + elections choropleth fill"
```

---

## Task 6: Frontend — elections hover, legend, and race-list drill-down

**Files:**
- Modify: `admin/src/pages/admin/CoverageMapPage.tsx`

- [ ] **Step 1: Hover readout shows election date + coverage / "no race data"**

In the hover state-setting handlers (elections mode), set hover to include coverage or unknown. Update the hover readout block so that in elections mode it shows e.g. `San Juan County — no race data` or `Salt Lake County — 42% · Primary Jun 23, 2026`. Use `elecDate` for the date context and the county's `status`/`coverage`.

```tsx
// in elections mode, onMouseEnter for a county:
onMouseEnter={() => setHover({ name: geo.properties.name, score: cs?.status === 'unknown' ? undefined : cs?.coverage })}
```

(Reuse the existing `hover.score == null ? 'not started' : '<n>%'` readout; for elections, `undefined` score renders the neutral text — acceptable for v1. Optionally append `elecDate` type+date next to the legend.)

- [ ] **Step 2: Legend swaps in elections mode**

Render an elections legend when `metric === 'elections'`: a "no race data" swatch (using `NO_RACE_DATA`) + the same low→high teal ramp, and the election date/type text (`elecDate`) if a state is selected.

```tsx
{metric === 'elections' ? (
  <div className="flex items-center gap-3 text-xs text-gray-500 dark:text-gray-400">
    {elecDate && <span className="font-medium text-gray-600 dark:text-gray-300 capitalize">{elecDate.type} · {elecDate.date}</span>}
    <span className="inline-flex items-center gap-1.5"><span className="inline-block h-2.5 w-2.5 rounded-sm" style={{ background: NO_RACE_DATA }} /> no race data</span>
    <span className="inline-flex items-center gap-1.5"><span>low</span><div className="h-2 w-24 rounded-full" style={{ background: `linear-gradient(to right, ${scoreColor(5)}, ${scoreColor(45)}, ${scoreColor(100)})` }} /><span>high</span></span>
  </div>
) : ( /* existing completeness legend */ )}
```

- [ ] **Step 3: Race-list drill-down panel**

When `metric === 'elections'` and a county is selected, render a race list instead of the completeness breakdown. The selected county comes from `elecCounties` (track a `selectedElecCounty` or reuse `selectedCounty` keyed by fips). Panel rows: position name, seats, candidate count, covered ✓/✗.

```tsx
{metric === 'elections' && selectedElecCounty && (
  <div className="rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
    <div className="border-b border-gray-100 p-4 dark:border-gray-800">
      <h2 className="text-sm font-semibold text-gray-900 dark:text-white">{selectedElecCounty.name}</h2>
      <p className="text-xs text-gray-500 dark:text-gray-400">
        {selectedElecCounty.status === 'unknown'
          ? 'No races resolve to this county yet'
          : `${selectedElecCounty.coverage}% of races have candidates · ${selectedElecCounty.races.length} races`}
      </p>
    </div>
    {selectedElecCounty.races.length > 0 && (
      <div className="max-h-[26rem] overflow-auto">
        <table className="w-full text-sm">
          <thead className="sticky top-0 border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800">
            <tr>{['Race', 'Seats', 'Candidates', ''].map((h) => <th key={h} className="px-3 py-2 text-left font-medium text-gray-500 dark:text-gray-400">{h}</th>)}</tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {selectedElecCounty.races.map((r) => (
              <tr key={r.race_id} className="hover:bg-gray-50 dark:hover:bg-gray-800/40">
                <td className="px-3 py-2 text-gray-900 dark:text-white">{r.position_name}</td>
                <td className="px-3 py-2 tabular-nums text-gray-600 dark:text-gray-400">{r.seats}</td>
                <td className="px-3 py-2 tabular-nums text-gray-600 dark:text-gray-400">{r.candidate_count}</td>
                <td className="px-3 py-2">{r.candidate_count > 0
                  ? <span className="text-emerald-600 dark:text-emerald-400">✓</span>
                  : <span className="text-gray-300 dark:text-gray-600">✕</span>}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    )}
  </div>
)}
```

Wire county clicks in elections mode to `setSelectedElecCounty(cs)` (add `const [selectedElecCounty, setSelectedElecCounty] = useState<CountyElection | null>(null);`). Clear it in `backToUS` and when toggling metric.

- [ ] **Step 4: Verify build**

Run: `cd admin && npx tsc --noEmit && npm run build`
Expected: typecheck clean, build succeeds.

- [ ] **Step 5: Commit**

```bash
git add admin/src/pages/admin/CoverageMapPage.tsx
git commit -m "feat(elections-map): elections hover, legend, and race-list drill-down"
```

---

## Task 7: Final verification + docs

**Files:**
- Modify: `backend/data/coverage/COVERAGE-MAP.md` (replace the "Planned: Elections mode" section with a short "Elections mode" usage note)

- [ ] **Step 1: Full typecheck + build + unit tests**

```bash
cd backend && npm run typecheck && npx vitest run src/lib/electionsMap.test.ts
cd ../admin && npx tsc --noEmit && npm run build
```
Expected: all clean.

- [ ] **Step 2: Manual end-to-end (dev servers running, logged in as admin)**

- Open `/admin/coverage/map`, flip the toggle to **Elections**. The US map recolors; tracked states show coverage, others gray.
- Click **Utah** → counties color; some scored, many "no race data" (zinc); the date reads `Primary · 2026-06-23`. Click a scored county → race list with candidate counts.
- Click **Texas** → all counties "no race data" (expected — 0 races resolve), state still colored.

- [ ] **Step 3: Update the doc**

Replace the `## Planned: "Elections mode" (not built yet)` section of `backend/data/coverage/COVERAGE-MAP.md` with:

```markdown
## Elections mode

Toggle the map to **Elections** to recolor by **race coverage** — `races with ≥1
candidate ÷ total races` — for each state's **nearest upcoming election date** (all
`elections` rows on that date, every level). State % composites all races; county %
counts only races resolving to that county (`…/county:X` or `…/place:Y`). Counties
where no races resolve show **"no race data"** (a distinct neutral fill, not 0%).
Backend: `electionsMapService.ts`; endpoint `?metric=elections`.
```

- [ ] **Step 4: Commit**

```bash
git add backend/data/coverage/COVERAGE-MAP.md
git commit -m "docs(elections-map): document elections mode in COVERAGE-MAP.md"
```

---

## Notes for the implementer

- **OCD level detection** is purely string-based on `district.ocd_id` (`/county:`, `/place:`, else state-level). This matches how `coverageMapService.ts` already works.
- **Don't force state-level races into counties** — `resolveRaceCountyFips` returns `null` for `cd`/`sldu`/`sldl`/bare-state OCDs by design; those count only toward the state %.
- **Cache**: elections results use their own 10-min cache keyed `elections:*`. `?refresh=1` busts it; a redeploy clears it.
- **Deploy**: this is the established flow — feature branch → PR → squash-merge to `master` → Render auto-deploys. Don't commit to `master` directly.
