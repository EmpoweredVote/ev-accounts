# Coverage Tab Bivariate Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merge the two coverage routes (`/admin/coverage` table + `/admin/coverage/map` choropleth) into one stacked, single-scroll page where the map is the table's selector and the completeness map uses bivariate (breadth × depth) Teal×Amber coloring with rich hover cards.

**Architecture:** Backend `coverageMapService` aggregates the existing per-jurisdiction data into per-geography **breadth** (fraction of child units started) and **depth** (mean composite over started units only) plus a hover breakdown, alongside the existing composite `score`. A new pure `coverageBivariate.ts` module on each side holds the testable math: the **backend** module does breadth/depth aggregation; the **frontend** module does threshold bucketing + the 3×3 hex lookup. The frontend collapses `CoverageMapPage` + `CoverageTrackerPage` into one `CoveragePage` orchestrator that renders a `CoverageMap` (top) and `CoverageTable` (below), the whole page scrolling, with the map click driving the table.

**Tech Stack:** Node 20 / TypeScript 5.6 / Express (backend, Vitest 2), React 18 + Vite 5 + react-simple-maps + Tailwind (admin SPA; Vitest added for the pure frontend module).

---

## File Structure

**Backend**
- Create `backend/src/lib/coverageBivariate.ts` — pure breadth/depth aggregation (no DB). Tested.
- Create `backend/src/lib/coverageBivariate.test.ts` — Vitest for the above.
- Modify `backend/src/lib/coverageMapService.ts` — add breadth/depth + hover breakdown to `StateScore` and `CountyScore`, computed from the existing `buildJurisdictions` output. Elections path untouched.
- Modify `backend/data/coverage/COVERAGE-MAP.md` — document breadth/depth + bivariate.

**Frontend (admin SPA)**
- Modify `admin/package.json` — add `vitest` devDep + `test` script.
- Create `admin/vitest.config.ts` — node-env Vitest config.
- Create `admin/src/pages/admin/coverageBivariate.ts` — pure bucketing + 3×3 palette + `bivariateColor`. Tested.
- Create `admin/src/pages/admin/coverageBivariate.test.ts` — Vitest for the above.
- Create `admin/src/pages/admin/BivariateLegend.tsx` — 2D legend swatch grid.
- Create `admin/src/pages/admin/CoverageHoverCard.tsx` — `StateHoverCard` + `CountyHoverCard`.
- Create `admin/src/pages/admin/CoverageMap.tsx` — the map (extracted from `CoverageMapPage`), props-driven; bivariate fill in completeness mode, hover cards, legend. Owns both metric modes' map rendering.
- Create `admin/src/pages/admin/CoverageTable.tsx` — the tabular tracker (extracted from `CoverageTrackerPage` body), driven by a `state` prop instead of its own dropdown; renders a county jurisdiction breakdown when a county is focused.
- Create `admin/src/pages/admin/CoveragePage.tsx` — orchestrator: fetch logic, metric toggle, breadcrumb, selection state; renders `CoverageMap` then `CoverageTable`, whole page scrolls.
- Delete `admin/src/pages/admin/CoverageMapPage.tsx` and `admin/src/pages/admin/CoverageTrackerPage.tsx` (logic moved into the components above).
- Keep `admin/src/pages/admin/coverageCells.tsx` unchanged (shared cells).
- Modify `admin/src/App.tsx` — point `coverage` route at `CoveragePage`; redirect `coverage/map` → `coverage`.
- Modify `admin/src/pages/admin/AdminLayout.tsx` — remove the "Coverage Map" nav item.

---

## Data contract (the shapes the backend will return)

Completeness mode only. Elections mode response shapes are unchanged.

```ts
// per state (level=state)
interface StateScore {
  fips: string; code: string; name: string;
  score: number;            // EXISTING composite 0..100 (table still uses it)
  jurisdiction_count: number; populated_count: number;  // EXISTING
  // NEW:
  breadth: number;          // 0..1 — counties with ≥1 started unit ÷ total counties
  depth: number;            // 0..100 — mean of started counties' depth
  counties_started: number; counties_total: number;
  cities_started: number;   cities_total: number;
  schools_started: number;  schools_total: number;
  roster_pct: number;       // 0..100 over started units, Σactual/Σexpected capped
  stances_pct: number;      // 0..100 over started units, Σresearched/Σtotal
  photo_pct: number;        // 0..100 over started units, ΣwithPhoto/Σtotal
}

// per county (level=county&state=xx)
interface CountyScore {
  fips: string; name: string;
  score: number;            // EXISTING rolled-up composite 0..100
  jurisdiction_count: number; populated_count: number;  // EXISTING
  jurisdictions: JurisdictionScore[];                   // EXISTING
  // NEW:
  breadth: number;          // 0..1 — populated_count ÷ jurisdiction_count
  depth: number;            // 0..100 — mean composite over populated jurisdictions only
  county_govt_started: boolean;
  cities_started: number;   cities_total: number;
  schools_started: number;  schools_total: number;
  roster: Tristate; stances: Tristate; photos: Tristate; treasury: Tristate; donors: Tristate; // over populated jurisdictions
}
```

`JurisdictionScore` is unchanged.

**Aggregation semantics (locked):**
- A **county** is "started" iff ≥1 jurisdiction inside it is populated.
- **County depth** = mean of `j.score` over its *populated* jurisdictions (0 if none) — white space is carried by breadth, not by dragging depth down.
- **State breadth** = started counties ÷ **true total counties in the state**. **State depth** = mean of *started counties'* county-depth (0 if none). This makes Indiana (only Monroe built out) read **low breadth / high depth → teal**, the headline acceptance case.

**Breadth denominator (decided 2026-06-03):** The state's county geofence universe can be incomplete in production — e.g. Indiana has only 1 of its 92 counties geofenced (Monroe), while CA (58/58) and UT (29/29) are complete. Denominating breadth by *loaded* county geofences would make Indiana read 1/1 = 1.0 (olive/both-high), the exact "looks more covered than it is" failure the redesign targets. So `counties_total` (and thus state breadth) is denominated by the **true US county count per state**, from a static `US_COUNTY_COUNTS` table (keyed by 2-digit state FIPS) in `coverageMapService.ts`. States missing from the table fall back to the loaded-geofence count. County **depth** is still over *started* (loaded, populated) counties — only the breadth denominator uses the true total.

---

## Task 1: Backend pure breadth/depth aggregation module

**Files:**
- Create: `backend/src/lib/coverageBivariate.ts`
- Test: `backend/src/lib/coverageBivariate.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// backend/src/lib/coverageBivariate.test.ts
import { describe, it, expect } from 'vitest';
import { aggregateUnits, type Unit } from './coverageBivariate.js';

const u = (started: boolean, depth: number): Unit => ({ started, depth });

describe('aggregateUnits', () => {
  it('breadth = started ÷ total; depth = mean over started only', () => {
    const r = aggregateUnits([u(true, 80), u(true, 60), u(false, 0), u(false, 0)]);
    expect(r.started).toBe(2);
    expect(r.total).toBe(4);
    expect(r.breadth).toBeCloseTo(0.5, 5);
    expect(r.depth).toBe(70); // (80+60)/2 — the two empties do NOT drag it down
  });

  it('all empty → breadth 0, depth 0', () => {
    expect(aggregateUnits([u(false, 0), u(false, 0)])).toEqual({ breadth: 0, depth: 0, started: 0, total: 2 });
  });

  it('all started → breadth 1', () => {
    const r = aggregateUnits([u(true, 50), u(true, 100)]);
    expect(r.breadth).toBe(1);
    expect(r.depth).toBe(75);
  });

  it('empty input → all zeros', () => {
    expect(aggregateUnits([])).toEqual({ breadth: 0, depth: 0, started: 0, total: 0 });
  });

  it('rounds depth to one decimal', () => {
    expect(aggregateUnits([u(true, 10), u(true, 10), u(true, 11)]).depth).toBe(10.3);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/lib/coverageBivariate.test.ts`
Expected: FAIL — `Cannot find module './coverageBivariate.js'`

- [ ] **Step 3: Write the implementation**

```ts
// backend/src/lib/coverageBivariate.ts
/**
 * coverageBivariate.ts — pure breadth/depth aggregation for the bivariate
 * completeness map. No DB access; unit-tested. coverageMapService feeds it the
 * per-unit (started, depth) pairs it already computes via buildJurisdictions.
 *
 * breadth = fraction of child units that are started (≥1 active politician).
 * depth   = mean composite over the STARTED units only — white space is carried
 *           by breadth, not by dragging depth toward zero.
 */
export interface Unit {
  started: boolean;
  depth: number; // that unit's own composite/depth, 0..100
}

export interface BreadthDepth {
  breadth: number; // 0..1
  depth: number;   // 0..100, one decimal
  started: number;
  total: number;
}

export function aggregateUnits(units: Unit[]): BreadthDepth {
  const total = units.length;
  const startedUnits = units.filter((u) => u.started);
  const started = startedUnits.length;
  const breadth = total > 0 ? started / total : 0;
  const depth =
    started > 0 ? startedUnits.reduce((s, u) => s + u.depth, 0) / started : 0;
  return { breadth, depth: Math.round(depth * 10) / 10, started, total };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run src/lib/coverageBivariate.test.ts`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/coverageBivariate.ts backend/src/lib/coverageBivariate.test.ts
git commit -m "feat(coverage): pure breadth/depth aggregation module"
```

---

## Task 2: Backend — enrich getCountyScores with breadth/depth + hover breakdown

**Files:**
- Modify: `backend/src/lib/coverageMapService.ts` (interface `CountyScore` ~96-103; `getCountyScores` body ~383-399; helpers near top)

- [ ] **Step 1: Add a small tristate helper and extend the `CountyScore` interface**

In `coverageMapService.ts`, import the aggregator at the top alongside the existing imports (after line 38):

```ts
import { aggregateUnits, type Unit } from './coverageBivariate.js';
```

Replace the `CountyScore` interface (lines 96-103) with:

```ts
export interface CountyScore {
  fips: string; // 5-digit county FIPS (matches us-atlas county keys)
  name: string;
  score: number; // 0..100, mean composite over jurisdictions inside
  jurisdiction_count: number;
  populated_count: number;
  jurisdictions: JurisdictionScore[];
  // Bivariate + hover breakdown (completeness mode):
  breadth: number; // 0..1 — populated_count ÷ jurisdiction_count
  depth: number;   // 0..100 — mean composite over populated jurisdictions only
  county_govt_started: boolean;
  cities_started: number;
  cities_total: number;
  schools_started: number;
  schools_total: number;
  roster: Tristate;
  stances: Tristate;
  photos: Tristate;
  treasury: Tristate;
  donors: Tristate;
}
```

- [ ] **Step 2: Add a county-breakdown helper above `getCountyScores`**

Insert this function just before `export async function getCountyScores` (before line 359):

```ts
/**
 * Roll a county's jurisdiction list into the bivariate + hover breakdown.
 * breadth/depth come from the pure aggregator (started = populated, depth =
 * composite score). The axis tristates summarise the populated jurisdictions
 * only, so empty white space doesn't read as a hard ✕ on every axis.
 */
function countyBreakdown(list: JurisdictionScore[]) {
  const units: Unit[] = list.map((j) => ({ started: j.populated, depth: j.score }));
  const { breadth, depth } = aggregateUnits(units);
  const populated = list.filter((j) => j.populated);

  const cities = list.filter((j) => j.level === 'local');
  const schools = list.filter((j) => j.level === 'school');
  const countyGovt = list.find((j) => j.level === 'county');

  // Axis tristates over the populated set.
  const sum = (sel: (j: JurisdictionScore) => number) => populated.reduce((s, j) => s + sel(j), 0);
  const photoPart = sum((j) => j.headshots.withPhoto);
  const photoTotal = sum((j) => j.headshots.total);
  const stancePart = sum((j) => j.stances.researched);
  const stanceTotal = sum((j) => j.stances.total);
  const rosterActual = sum((j) => (j.expected_seats ? j.roster_actual : 0));
  const rosterExpected = sum((j) => j.expected_seats ?? 0);
  const treasuryFull = populated.filter((j) => j.treasury === 'full').length;
  const treasuryAny = populated.filter((j) => j.treasury !== 'none').length;
  const donorsFull = populated.filter((j) => j.donors === 'full').length;
  const donorsAny = populated.filter((j) => j.donors !== 'none').length;

  const fracTristate = (part: number, total: number): Tristate => ratioTristate(part, total);
  const anyFullTristate = (full: number, any: number, n: number): Tristate =>
    n === 0 || any === 0 ? 'none' : full >= n ? 'full' : 'partial';

  return {
    breadth,
    depth,
    county_govt_started: !!countyGovt?.populated,
    cities_started: cities.filter((c) => c.populated).length,
    cities_total: cities.length,
    schools_started: schools.filter((s) => s.populated).length,
    schools_total: schools.length,
    roster: rosterExpected > 0 ? fracTristate(rosterActual, rosterExpected) : 'none',
    stances: fracTristate(stancePart, stanceTotal),
    photos: fracTristate(photoPart, photoTotal),
    treasury: anyFullTristate(treasuryFull, treasuryAny, populated.length),
    donors: anyFullTristate(donorsFull, donorsAny, populated.length),
  };
}
```

- [ ] **Step 3: Wire the breakdown into the county build loop**

In `getCountyScores`, replace the `counties.push({...})` block (lines 384-396) with:

```ts
    for (const [fips, list] of byCounty) {
      const county = list.find((l) => l.level === 'county');
      const sorted = list.sort((a, b) => {
        const order = { county: 0, local: 1, school: 2 } as const;
        return order[a.level] - order[b.level] || a.name.localeCompare(b.name);
      });
      counties.push({
        fips,
        name: county?.name ?? fips,
        score: mean(list.map((l) => l.score)),
        jurisdiction_count: list.length,
        populated_count: list.filter((l) => l.populated).length,
        jurisdictions: sorted,
        ...countyBreakdown(list),
      });
    }
```

- [ ] **Step 4: Typecheck**

Run: `cd backend && npm run typecheck`
Expected: no errors.

- [ ] **Step 5: Probe against production data**

Write a throwaway probe `backend/scripts/_probe-county.ts`:

```ts
import { getCountyScores } from '../src/lib/coverageMapService.js';
const data = await getCountyScores('ut', { refresh: true });
const slc = data?.counties.find((c) => c.name.toLowerCase().includes('salt lake'));
console.log(JSON.stringify({
  name: slc?.name, score: slc?.score, breadth: slc?.breadth, depth: slc?.depth,
  county_govt_started: slc?.county_govt_started,
  cities: `${slc?.cities_started}/${slc?.cities_total}`,
  schools: `${slc?.schools_started}/${slc?.schools_total}`,
  roster: slc?.roster, stances: slc?.stances, photos: slc?.photos,
  treasury: slc?.treasury, donors: slc?.donors,
}, null, 2));
process.exit(0);
```

Run: `cd backend && node --env-file=.env --import tsx scripts/_probe-county.ts`
Expected: a JSON object for Salt Lake County with `breadth` between 0 and 1, `depth` 0..100, and tristate axis values. Sanity-check: `breadth` should equal `populated_count / jurisdiction_count`. Then delete the probe: `rm backend/scripts/_probe-county.ts`.

- [ ] **Step 6: Commit**

```bash
git add backend/src/lib/coverageMapService.ts
git commit -m "feat(coverage): per-county breadth/depth + hover breakdown"
```

---

## Task 3: Backend — enrich getStateScores with breadth/depth + state hover breakdown

**Files:**
- Modify: `backend/src/lib/coverageMapService.ts` (interface `StateScore` ~105-112; `getStateScores` body ~404-425)

- [ ] **Step 1: Extend the `StateScore` interface**

Replace the `StateScore` interface (lines 105-112) with:

```ts
export interface StateScore {
  fips: string; // 2-digit state FIPS (matches us-atlas state keys)
  code: string; // 2-letter lowercase (e.g. 'ut')
  name: string;
  score: number; // 0..100
  jurisdiction_count: number;
  populated_count: number;
  // Bivariate + hover breakdown (completeness mode):
  breadth: number; // 0..1 — counties with ≥1 started unit ÷ total counties
  depth: number;   // 0..100 — mean of started counties' depth
  counties_started: number;
  counties_total: number;
  cities_started: number;
  cities_total: number;
  schools_started: number;
  schools_total: number;
  roster_pct: number;  // 0..100 over started units
  stances_pct: number; // 0..100 over started units
  photo_pct: number;   // 0..100 over started units
}
```

- [ ] **Step 2: Add a state-breakdown helper above `getStateScores`**

Insert before `export async function getStateScores` (before line 403):

```ts
/**
 * Roll a whole state's flat jurisdiction list into the bivariate + hover
 * breakdown. Breadth/depth are computed over COUNTY rollups (a county is a
 * "unit"; started = any jurisdiction inside it populated; its depth = mean
 * composite over its populated jurisdictions). This is why a state with one
 * built-out county and many empty ones reads low-breadth / high-depth (teal),
 * instead of the old single mean that washed out to near-empty.
 */
function stateBreakdown(jur: JurisdictionScore[]) {
  // Group by county for the county-rollup units.
  const byCounty = new Map<string, JurisdictionScore[]>();
  for (const j of jur) {
    if (!j.county_fips) continue;
    const arr = byCounty.get(j.county_fips) ?? [];
    arr.push(j);
    byCounty.set(j.county_fips, arr);
  }
  const countyUnits: Unit[] = [];
  for (const [, list] of byCounty) {
    const populated = list.filter((j) => j.populated);
    const started = populated.length > 0;
    const depth = populated.length > 0 ? populated.reduce((s, j) => s + j.score, 0) / populated.length : 0;
    countyUnits.push({ started, depth });
  }
  const { breadth, depth } = aggregateUnits(countyUnits);

  const cities = jur.filter((j) => j.level === 'local');
  const schools = jur.filter((j) => j.level === 'school');
  const counties = jur.filter((j) => j.level === 'county');

  // Depth summary over ALL populated units (state-wide), as percentages.
  const populated = jur.filter((j) => j.populated);
  const sum = (sel: (j: JurisdictionScore) => number) => populated.reduce((s, j) => s + sel(j), 0);
  const photoPart = sum((j) => j.headshots.withPhoto);
  const photoTotal = sum((j) => j.headshots.total);
  const stancePart = sum((j) => j.stances.researched);
  const stanceTotal = sum((j) => j.stances.total);
  const rosterActual = sum((j) => (j.expected_seats ? j.roster_actual : 0));
  const rosterExpected = sum((j) => j.expected_seats ?? 0);
  const pct = (part: number, total: number) => (total > 0 ? Math.round((part / total) * 1000) / 10 : 0);

  return {
    breadth,
    depth,
    counties_started: countyUnits.filter((u) => u.started).length,
    counties_total: counties.length,
    cities_started: cities.filter((c) => c.populated).length,
    cities_total: cities.length,
    schools_started: schools.filter((s) => s.populated).length,
    schools_total: schools.length,
    roster_pct: pct(Math.min(rosterActual, rosterExpected), rosterExpected),
    stances_pct: pct(stancePart, stanceTotal),
    photo_pct: pct(photoPart, photoTotal),
  };
}
```

- [ ] **Step 3: Wire the breakdown into the state build loop**

In `getStateScores`, replace the `out.push({...})` block (lines 415-421) with:

```ts
      out.push({
        fips,
        code,
        name: file.state_name,
        score: mean(jur.map((j) => j.score)),
        jurisdiction_count: jur.length,
        populated_count: jur.filter((j) => j.populated).length,
        ...stateBreakdown(jur),
      });
```

- [ ] **Step 4: Typecheck**

Run: `cd backend && npm run typecheck`
Expected: no errors.

- [ ] **Step 5: Probe against production data — confirm the Indiana acceptance case**

Write `backend/scripts/_probe-state.ts`:

```ts
import { getStateScores } from '../src/lib/coverageMapService.js';
const states = await getStateScores({ refresh: true });
for (const code of ['in', 'ut', 'ca']) {
  const s = states.find((x) => x.code === code);
  if (!s) { console.log(code, 'NOT TRACKED'); continue; }
  console.log(JSON.stringify({
    code: s.code, score: s.score, breadth: s.breadth, depth: s.depth,
    counties: `${s.counties_started}/${s.counties_total}`,
    cities: `${s.cities_started}/${s.cities_total}`,
    schools: `${s.schools_started}/${s.schools_total}`,
    roster_pct: s.roster_pct, stances_pct: s.stances_pct, photo_pct: s.photo_pct,
  }));
}
process.exit(0);
```

Run: `cd backend && node --env-file=.env --import tsx scripts/_probe-state.ts`
Expected: **Indiana** shows **low breadth** (few counties started, e.g. ~0.01–0.1) with **high depth** (Monroe is built out, e.g. depth > 50) — the narrow-but-deep signature. UT/CA show higher breadth. Delete the probe: `rm backend/scripts/_probe-state.ts`.

- [ ] **Step 6: Run the full backend test suite (no regressions)**

Run: `cd backend && npm test`
Expected: all existing suites pass, including `coverageBivariate.test.ts` and `electionsMap.test.ts`.

- [ ] **Step 7: Commit**

```bash
git add backend/src/lib/coverageMapService.ts
git commit -m "feat(coverage): per-state breadth/depth + hover breakdown"
```

---

## Task 4: Frontend — add Vitest to the admin package

**Files:**
- Modify: `admin/package.json`
- Create: `admin/vitest.config.ts`

- [ ] **Step 1: Add the `test` script and `vitest` devDependency**

In `admin/package.json`, change the `scripts` block to:

```json
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest run"
  },
```

Add `"vitest": "^2.1.0"` to `devDependencies` (keep alphabetical-ish ordering near `vite`).

- [ ] **Step 2: Create the Vitest config (node env — the module under test is pure, no DOM)**

```ts
// admin/vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['src/**/*.test.ts'],
  },
});
```

- [ ] **Step 3: Install**

Run: `cd admin && npm install`
Expected: `vitest` added, lockfile updated, no errors.

- [ ] **Step 4: Smoke-test the runner with a throwaway spec**

Create `admin/src/_smoke.test.ts` with `import { it, expect } from 'vitest'; it('runs', () => expect(1).toBe(1));`
Run: `cd admin && npm test`
Expected: 1 passing test. Then `rm admin/src/_smoke.test.ts`.

- [ ] **Step 5: Commit**

```bash
git add admin/package.json admin/package-lock.json admin/vitest.config.ts
git commit -m "chore(admin): add vitest for pure-module unit tests"
```

---

## Task 5: Frontend — pure bivariate bucketing + color module

**Files:**
- Create: `admin/src/pages/admin/coverageBivariate.ts`
- Test: `admin/src/pages/admin/coverageBivariate.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// admin/src/pages/admin/coverageBivariate.test.ts
import { describe, it, expect } from 'vitest';
import { bucketBreadth, bucketDepth, bivariateColor, PALETTE, NOT_STARTED } from './coverageBivariate';

describe('bucketBreadth (thresholds <0.10 / <0.50 / >=0.50)', () => {
  it('low below 0.10', () => { expect(bucketBreadth(0)).toBe('low'); expect(bucketBreadth(0.099)).toBe('low'); });
  it('med at the 0.10 boundary up to <0.50', () => { expect(bucketBreadth(0.10)).toBe('med'); expect(bucketBreadth(0.499)).toBe('med'); });
  it('high at the 0.50 boundary', () => { expect(bucketBreadth(0.50)).toBe('high'); expect(bucketBreadth(1)).toBe('high'); });
});

describe('bucketDepth (thresholds <33 / <66 / >=66, on 0..100)', () => {
  it('low below 33', () => { expect(bucketDepth(0)).toBe('low'); expect(bucketDepth(32.9)).toBe('low'); });
  it('med at 33 up to <66', () => { expect(bucketDepth(33)).toBe('med'); expect(bucketDepth(65.9)).toBe('med'); });
  it('high at 66', () => { expect(bucketDepth(66)).toBe('high'); expect(bucketDepth(100)).toBe('high'); });
});

describe('bivariateColor — all 9 cells', () => {
  const cases: [number, number, string][] = [
    // breadth, depth(0..100), expected hex
    [0.0, 0,   PALETTE.low.low],   // empty / near-white
    [0.3, 0,   PALETTE.low.med],
    [0.8, 0,   PALETTE.low.high],
    [0.0, 50,  PALETTE.med.low],
    [0.3, 50,  PALETTE.med.med],
    [0.8, 50,  PALETTE.med.high],
    [0.0, 80,  PALETTE.high.low],  // deep teal — narrow-but-deep (Indiana)
    [0.3, 80,  PALETTE.high.med],
    [0.8, 80,  PALETTE.high.high], // olive — both high
  ];
  it.each(cases)('breadth=%s depth=%s → %s', (b, d, hex) => {
    expect(bivariateColor(b, d)).toBe(hex);
  });
});

describe('bivariateColor — edges', () => {
  it('0 started (breadth 0, depth 0) → the empty near-white cell', () => {
    expect(bivariateColor(0, 0)).toBe('#ece8e0');
  });
  it('exposes the not-started grey separately', () => {
    expect(NOT_STARTED).toBe('#e5e7eb');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd admin && npx vitest run src/pages/admin/coverageBivariate.test.ts`
Expected: FAIL — cannot find module `./coverageBivariate`.

- [ ] **Step 3: Write the implementation**

```ts
// admin/src/pages/admin/coverageBivariate.ts
/**
 * Pure bivariate coloring for the completeness coverage map.
 *
 *   X axis = breadth (fraction of child units started, 0..1)
 *   Y axis = depth   (mean composite over started units, 0..100)
 *
 * Each axis is bucketed low/med/high → a 3×3 Teal × Amber grid:
 *   teal  = deep & narrow, amber = broad & shallow, olive = both high,
 *   near-white = empty (0 started). Antipartisan — deliberately no red/blue.
 *
 * Thresholds + hexes are the tunable design constants. Untracked geographies
 * (no coverage YAML) use NOT_STARTED grey, painted by the caller — distinct from
 * the near-white "tracked but empty" cell.
 */
export type Bucket = 'low' | 'med' | 'high';

// breadth thresholds (fraction): <0.10 low · <0.50 med · >=0.50 high
export const BREADTH_THRESHOLDS = { low: 0.1, high: 0.5 };
// depth thresholds (0..100 composite): <33 low · <66 med · >=66 high
export const DEPTH_THRESHOLDS = { low: 33, high: 66 };

export const NOT_STARTED = '#e5e7eb'; // gray-200 — untracked / no coverage file

// PALETTE[depthBucket][breadthBucket] — rows = depth, cols = breadth.
export const PALETTE: Record<Bucket, Record<Bucket, string>> = {
  high: { low: '#2f8f8f', med: '#36806a', high: '#3f6b3a' },
  med:  { low: '#a9cdc0', med: '#aab98a', high: '#ad9c4a' },
  low:  { low: '#ece8e0', med: '#ead9a8', high: '#e6c34d' },
};

export function bucketBreadth(b: number): Bucket {
  if (b < BREADTH_THRESHOLDS.low) return 'low';
  if (b < BREADTH_THRESHOLDS.high) return 'med';
  return 'high';
}

export function bucketDepth(d: number): Bucket {
  if (d < DEPTH_THRESHOLDS.low) return 'low';
  if (d < DEPTH_THRESHOLDS.high) return 'med';
  return 'high';
}

/** (breadth 0..1, depth 0..100) → teal×amber hex. */
export function bivariateColor(breadth: number, depth: number): string {
  return PALETTE[bucketDepth(depth)][bucketBreadth(breadth)];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd admin && npx vitest run src/pages/admin/coverageBivariate.test.ts`
Expected: PASS (all describe blocks).

- [ ] **Step 5: Commit**

```bash
git add admin/src/pages/admin/coverageBivariate.ts admin/src/pages/admin/coverageBivariate.test.ts
git commit -m "feat(admin): pure bivariate bucketing + teal×amber color lookup"
```

---

## Task 6: Frontend — 2D legend + hover-card components

**Files:**
- Create: `admin/src/pages/admin/BivariateLegend.tsx`
- Create: `admin/src/pages/admin/CoverageHoverCard.tsx`

These are pure presentational components consuming the Task 5 palette and the Task 2/3 backend shapes. No tests (rendering-only; the math they display is already tested).

- [ ] **Step 1: Create the bivariate legend**

```tsx
// admin/src/pages/admin/BivariateLegend.tsx
/**
 * 2D legend for the bivariate completeness map: a 3×3 Teal×Amber grid with
 * breadth on X (→) and depth on Y (↑), plus the separate "not started" grey.
 */
import { PALETTE, NOT_STARTED, type Bucket } from './coverageBivariate';

const ROWS: Bucket[] = ['high', 'med', 'low']; // top → bottom
const COLS: Bucket[] = ['low', 'med', 'high'];  // left → right

export function BivariateLegend() {
  return (
    <div className="flex items-end gap-3 text-[10px] text-gray-500 dark:text-gray-400">
      <div className="flex items-center gap-1.5">
        <div className="flex flex-col items-center">
          {/* Y axis label */}
          <div className="flex">
            <div className="flex flex-col justify-between pr-1 text-right leading-none" style={{ height: 48 }}>
              <span>deep</span>
              <span className="rotate-0 text-gray-400">depth ↑</span>
              <span>shallow</span>
            </div>
            <div className="grid grid-cols-3 grid-rows-3" style={{ width: 48, height: 48 }}>
              {ROWS.map((r) =>
                COLS.map((c) => (
                  <div key={`${r}-${c}`} style={{ background: PALETTE[r][c] }} className="h-4 w-4" />
                )),
              )}
            </div>
          </div>
          <span className="mt-0.5 text-gray-400">breadth →</span>
        </div>
      </div>
      <span className="inline-flex items-center gap-1.5">
        <span className="inline-block h-2.5 w-2.5 rounded-sm" style={{ background: NOT_STARTED }} />
        not started
      </span>
    </div>
  );
}
```

- [ ] **Step 2: Create the hover cards**

```tsx
// admin/src/pages/admin/CoverageHoverCard.tsx
/**
 * Hover cards for the bivariate completeness map. They convey WHAT is covered,
 * not just a %: breadth bars (how many child units started) + a one-line depth
 * summary (state) or axis chips (county).
 */
import { Chip, type Tristate } from './coverageCells';

export interface StateHover {
  name: string;
  counties_started: number; counties_total: number;
  cities_started: number; cities_total: number;
  schools_started: number; schools_total: number;
  roster_pct: number; stances_pct: number; photo_pct: number;
}

export interface CountyHover {
  name: string;
  populated_count: number; jurisdiction_count: number;
  county_govt_started: boolean;
  cities_started: number; cities_total: number;
  schools_started: number; schools_total: number;
  roster: Tristate; stances: Tristate; photos: Tristate; treasury: Tristate; donors: Tristate;
}

function Bar({ label, started, total }: { label: string; started: number; total: number }) {
  const pct = total > 0 ? (started / total) * 100 : 0;
  return (
    <div className="flex items-center gap-2">
      <span className="w-14 shrink-0 text-[10px] uppercase tracking-wide text-gray-400">{label}</span>
      <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800">
        <div className="h-full bg-ev-teal dark:bg-ev-teal-light" style={{ width: `${pct}%` }} />
      </div>
      <span className="tabular-nums text-[11px] text-gray-500 dark:text-gray-400">{started}/{total}</span>
    </div>
  );
}

export function StateHoverCard({ s }: { s: StateHover }) {
  return (
    <div className="w-64 rounded-lg border border-gray-200 bg-white p-3 shadow-lg dark:border-gray-700 dark:bg-gray-900">
      <div className="mb-1 text-sm font-semibold text-gray-900 dark:text-white">{s.name}</div>
      <div className="mb-2 text-xs text-gray-500 dark:text-gray-400">
        {s.counties_started}/{s.counties_total} counties started
      </div>
      <div className="space-y-1">
        <Bar label="Counties" started={s.counties_started} total={s.counties_total} />
        <Bar label="Cities" started={s.cities_started} total={s.cities_total} />
        <Bar label="Schools" started={s.schools_started} total={s.schools_total} />
      </div>
      <div className="mt-2 border-t border-gray-100 pt-1.5 text-[11px] text-gray-500 dark:border-gray-800 dark:text-gray-400">
        Rosters {s.roster_pct}% · Stances {s.stances_pct}% · Photos {s.photo_pct}%
      </div>
    </div>
  );
}

export function CountyHoverCard({ c }: { c: CountyHover }) {
  return (
    <div className="w-64 rounded-lg border border-gray-200 bg-white p-3 shadow-lg dark:border-gray-700 dark:bg-gray-900">
      <div className="mb-1 text-sm font-semibold text-gray-900 dark:text-white">{c.name}</div>
      <div className="mb-2 text-xs text-gray-500 dark:text-gray-400">
        {c.populated_count}/{c.jurisdiction_count} populated
      </div>
      <ul className="space-y-0.5 text-[11px] text-gray-600 dark:text-gray-300">
        <li>County govt {c.county_govt_started ? '✓' : 'started ✕'}</li>
        <li>Cities {c.cities_started}/{c.cities_total}</li>
        <li>School districts {c.schools_started}/{c.schools_total}</li>
      </ul>
      <div className="mt-2 flex flex-wrap gap-1 border-t border-gray-100 pt-1.5 dark:border-gray-800">
        {([['Roster', c.roster], ['Stances', c.stances], ['Photos', c.photos], ['Treasury', c.treasury], ['Donors', c.donors]] as [string, Tristate][]).map(
          ([label, v]) => (
            <span key={label} className="inline-flex items-center gap-1 text-[10px] text-gray-500 dark:text-gray-400">
              {label}<Chip value={v} />
            </span>
          ),
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 3: Typecheck**

Run: `cd admin && npx tsc --noEmit`
Expected: no errors (note `ev-teal` / `ev-teal-light` classes already exist — used in current `CoverageMapPage`).

- [ ] **Step 4: Commit**

```bash
git add admin/src/pages/admin/BivariateLegend.tsx admin/src/pages/admin/CoverageHoverCard.tsx
git commit -m "feat(admin): bivariate 2D legend + state/county hover cards"
```

---

## Task 7: Frontend — extract `CoverageMap` component (props-driven, bivariate fill)

**Files:**
- Create: `admin/src/pages/admin/CoverageMap.tsx`

This lifts the map rendering out of `CoverageMapPage` into a controlled component. The orchestrator (Task 9) owns all data + selection state and passes it in. Completeness fill uses `bivariateColor`; elections fill is unchanged.

- [ ] **Step 1: Create the component**

Create `admin/src/pages/admin/CoverageMap.tsx` with the props interface and body below. Port the existing map internals from `CoverageMapPage.tsx` lines 88-122 (the `STATES_TOPO`/`COUNTIES_TOPO` constants, `MapLevel`/`Metric` types, `NO_RACE_DATA`, `scoreColor`, `electionStateColor`, `electionCountyColor`, `MAP_W`/`MAP_H`, `fitToFeature`, `pathRef`/`projRef`) verbatim, then render the `ComposableMap` exactly as in lines 346-419 — with these changes:

1. Replace the completeness state fill `scoreColor(sc?.score)` with `sc ? bivariateColor(sc.breadth, sc.depth) : NOT_STARTED`.
2. Replace the completeness county fill `scoreColor(cs?.score)` with `cs ? bivariateColor(cs.breadth, cs.depth) : NOT_STARTED`.
3. On state hover/click and county hover/click, call props callbacks (`onHoverState`, `onSelectState`, `onHoverCounty`, `onSelectCounty`) instead of local setState.
4. Render the hover card (`StateHoverCard`/`CountyHoverCard`) in a positioned overlay using the hovered datum passed back up, and the `BivariateLegend` (completeness) / existing elections legend below the map.

```tsx
// admin/src/pages/admin/CoverageMap.tsx
import { useRef, useCallback } from 'react';
import { ComposableMap, Geographies, Geography, ZoomableGroup } from 'react-simple-maps';
import { bivariateColor, NOT_STARTED } from './coverageBivariate';
import { BivariateLegend } from './BivariateLegend';
import type { StateScore, CountyScore, StateElection, CountyElection, Metric } from './coverageTypes';

const STATES_TOPO = 'https://cdn.jsdelivr.net/npm/us-atlas@3/states-10m.json';
const COUNTIES_TOPO = 'https://cdn.jsdelivr.net/npm/us-atlas@3/counties-10m.json';
const NO_RACE_DATA = '#3f3f46';
const MAP_W = 800;
const MAP_H = 600;

// Elections single-hue ramp (UNCHANGED from the old map).
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

interface Props {
  metric: Metric;
  // completeness data
  states: StateScore[];
  counties: CountyScore[];
  stateByFips: Map<string, StateScore>;
  countyByFips: Map<string, CountyScore>;
  // elections data
  elecStatesByFips: Map<string, StateElection>;
  elecCountiesByFips: Map<string, CountyElection>;
  elecDate: { date: string; type: string } | null;
  // selection
  selected: { fips: string; name: string; code?: string } | null;
  selectedCountyFips: string | null;
  center: [number, number];
  zoom: number;
  onSelectState: (fips: string, name: string, geo: unknown, fit: (geo: unknown) => void) => void;
  onSelectCounty: (fips: string) => void;
}

export function CoverageMap(props: Props) {
  const { metric, stateByFips, countyByFips, elecStatesByFips, elecCountiesByFips, selected, selectedCountyFips } = props;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const pathRef = useRef<any>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const projRef = useRef<any>(null);

  const fitToFeature = useCallback((geo: unknown) => {
    const path = pathRef.current; const proj = projRef.current;
    if (!path || !proj) return;
    const [[x0, y0], [x1, y1]] = path.bounds(geo) as [[number, number], [number, number]];
    const boxW = x1 - x0, boxH = y1 - y0;
    if (!Number.isFinite(boxW) || !Number.isFinite(boxH) || boxW <= 0 || boxH <= 0) return;
    // (the orchestrator owns center/zoom; this returns nothing — see onSelectState)
  }, []);

  return (
    <div className="relative">
      <div className="relative overflow-hidden rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
        <ComposableMap projection="geoAlbersUsa" width={MAP_W} height={MAP_H} style={{ width: '100%', height: 'auto' }}>
          <ZoomableGroup center={props.center} zoom={props.zoom} minZoom={1} maxZoom={12}>
            {!selected ? (
              <Geographies geography={STATES_TOPO}>
                {({ geographies, path, projection }) => {
                  pathRef.current = path; projRef.current = projection;
                  return geographies.map((geo) => {
                    const sc = stateByFips.get(geo.id as string);
                    const es = elecStatesByFips.get(geo.id as string);
                    const fill = metric === 'elections' ? electionStateColor(es) : (sc ? bivariateColor(sc.breadth, sc.depth) : NOT_STARTED);
                    return (
                      <Geography
                        key={geo.rsmKey}
                        geography={geo}
                        onClick={() => props.onSelectState(geo.id as string, geo.properties.name, geo, fitToFeature)}
                        style={{
                          default: { fill, stroke: '#fff', strokeWidth: 0.5, outline: 'none' },
                          hover: { fill, stroke: '#00657c', strokeWidth: 1.2, outline: 'none', cursor: 'pointer' },
                          pressed: { fill, outline: 'none' },
                        }}
                      />
                    );
                  });
                }}
              </Geographies>
            ) : (
              <Geographies geography={COUNTIES_TOPO}>
                {({ geographies, path, projection }) => {
                  pathRef.current = path; projRef.current = projection;
                  return geographies
                    .filter((geo) => (geo.id as string).startsWith(selected.fips))
                    .map((geo) => {
                      const cs = countyByFips.get(geo.id as string);
                      const ec = elecCountiesByFips.get(geo.id as string);
                      const fill = metric === 'elections' ? electionCountyColor(ec) : (cs ? bivariateColor(cs.breadth, cs.depth) : NOT_STARTED);
                      const isSel = selectedCountyFips === geo.id;
                      return (
                        <Geography
                          key={geo.rsmKey}
                          geography={geo}
                          onClick={() => props.onSelectCounty(geo.id as string)}
                          style={{
                            default: { fill, stroke: isSel ? '#00657c' : '#fff', strokeWidth: isSel ? 1.5 : 0.5, outline: 'none' },
                            hover: { fill, stroke: '#00657c', strokeWidth: 1.2, outline: 'none', cursor: 'pointer' },
                            pressed: { fill, outline: 'none' },
                          }}
                        />
                      );
                    });
                }}
              </Geographies>
            )}
          </ZoomableGroup>
        </ComposableMap>
      </div>

      {/* Legend */}
      <div className="mt-2 flex items-center justify-end">
        {metric === 'completeness' ? (
          <BivariateLegend />
        ) : (
          <div className="flex items-center gap-3 text-xs text-gray-500 dark:text-gray-400">
            {props.elecDate && (
              <span className="font-medium capitalize text-gray-600 dark:text-gray-300">{props.elecDate.type} · {props.elecDate.date}</span>
            )}
            <span className="inline-flex items-center gap-1.5">
              <span className="inline-block h-2.5 w-2.5 rounded-sm" style={{ background: NO_RACE_DATA }} /> no race data
            </span>
            <span className="inline-flex items-center gap-1.5">
              <span>low</span>
              <div className="h-2 w-24 rounded-full" style={{ background: `linear-gradient(to right, ${scoreColor(5)}, ${scoreColor(45)}, ${scoreColor(100)})` }} />
              <span>high</span>
            </span>
          </div>
        )}
      </div>
    </div>
  );
}
```

> **Hover-card placement note:** to keep this task self-contained, hover is handled by the orchestrator. The map calls `onSelectState`/`onSelectCounty` on click; hover overlays are rendered by the orchestrator over the map container (Task 9) using `onMouseEnter` wired the same way as `onClick`. If you prefer hover inside the map, add `onHoverState(sc|null)` / `onHoverCounty(cs|null)` props and `onMouseEnter`/`onMouseLeave` on each `<Geography>`, and render `<StateHoverCard>`/`<CountyHoverCard>` absolutely-positioned in this component. **Either placement is acceptable; pick one and keep all hover logic there.**

- [ ] **Step 2: Create the shared types module the map imports**

```ts
// admin/src/pages/admin/coverageTypes.ts
export type MapLevel = 'county' | 'local' | 'school';
export type Metric = 'completeness' | 'elections';

export interface StateScore {
  fips: string; code: string; name: string; score: number;
  jurisdiction_count: number; populated_count: number;
  breadth: number; depth: number;
  counties_started: number; counties_total: number;
  cities_started: number; cities_total: number;
  schools_started: number; schools_total: number;
  roster_pct: number; stances_pct: number; photo_pct: number;
}

export interface JurisdictionScore {
  ocd_id: string; name: string; level: MapLevel; county_fips: string | null;
  score: number; populated: boolean; roster_actual: number; expected_seats: number | null;
  headshots: { withPhoto: number; total: number }; stances: { researched: number; total: number };
  geofenced: boolean; treasury: 'none' | 'partial' | 'full'; donors: 'none' | 'partial' | 'full';
}

export interface CountyScore {
  fips: string; name: string; score: number;
  jurisdiction_count: number; populated_count: number; jurisdictions: JurisdictionScore[];
  breadth: number; depth: number; county_govt_started: boolean;
  cities_started: number; cities_total: number; schools_started: number; schools_total: number;
  roster: 'none' | 'partial' | 'full'; stances: 'none' | 'partial' | 'full'; photos: 'none' | 'partial' | 'full';
  treasury: 'none' | 'partial' | 'full'; donors: 'none' | 'partial' | 'full';
}

export interface StateElection {
  fips: string; code: string; election_date: string; election_type: string;
  coverage: number; races_total: number; races_covered: number;
}
export interface ElectionRace { race_id: string; position_name: string; seats: number; candidate_count: number; ocd_id: string | null; }
export interface CountyElection { fips: string; name: string; status: 'unknown' | 'scored'; coverage: number; races: ElectionRace[]; }
```

- [ ] **Step 3: Typecheck**

Run: `cd admin && npx tsc --noEmit`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add admin/src/pages/admin/CoverageMap.tsx admin/src/pages/admin/coverageTypes.ts
git commit -m "feat(admin): props-driven CoverageMap with bivariate fill"
```

---

## Task 8: Frontend — extract `CoverageTable` component (state-driven + county focus)

**Files:**
- Create: `admin/src/pages/admin/CoverageTable.tsx`

This lifts the tabular tracker out of `CoverageTrackerPage`. It takes the selected `state` as a prop (no internal dropdown) and, when a county is focused, renders that county's jurisdiction breakdown instead of the full state tracker.

- [ ] **Step 1: Create the component**

Port `CoverageTrackerPage.tsx` lines 6-132 (the `Level`, `SkipTopicRule`, `CoverageLocation`, `UniverseCategory`, `Coverage`, `CoverageResponse` types; `LEVEL_LABEL`, `LEVEL_ORDER`; the `UniverseCard` component; `STATUS_STYLE`) verbatim into this file. Then implement the body:

```tsx
// admin/src/pages/admin/CoverageTable.tsx
import { useEffect, useState, useCallback } from 'react';
import { apiFetch } from '../../lib/api';
import { Bool, Chip, Stances, Roster, ratioToTristate } from './coverageCells';
import type { CountyScore } from './coverageTypes';
// ...PASTE the ported types/constants/UniverseCard/STATUS_STYLE here...

const COUNTY_LEVEL_LABEL = { county: 'County govt', local: 'City / Town', school: 'School District' } as const;

interface Props {
  /** lowercase state code selected on the map; null until a state is chosen */
  state: string | null;
  /** when set, focus the table on this county's jurisdiction breakdown */
  focusCounty: CountyScore | null;
  onClearCounty: () => void;
}

export function CoverageTable({ state, focusCounty, onClearCounty }: Props) {
  const [data, setData] = useState<CoverageResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const fetchCoverage = useCallback(() => {
    if (!state) { setData(null); return; }
    setLoading(true); setError(null);
    apiFetch<CoverageResponse>(`/admin/coverage?state=${state}`)
      .then(setData)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [state]);

  useEffect(() => { fetchCoverage(); }, [fetchCoverage]);

  // County focus: render the map's jurisdiction breakdown for that county.
  if (focusCounty) {
    return (
      <div className="rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
        <div className="flex items-center justify-between border-b border-gray-100 p-4 dark:border-gray-800">
          <div>
            <h2 className="text-sm font-semibold text-gray-900 dark:text-white">{focusCounty.name}</h2>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {focusCounty.populated_count}/{focusCounty.jurisdiction_count} jurisdictions populated · depth {focusCounty.depth}%
            </p>
          </div>
          <button onClick={onClearCounty} className="text-xs text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">← back to state</button>
        </div>
        <table className="w-full text-sm">
          <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800">
            <tr>
              {['Jurisdiction', 'Geofenced', 'Roster', 'Headshots', 'Stances', 'Treasury', 'Donors', 'Score'].map((h) => (
                <th key={h} className="whitespace-nowrap px-3 py-2 text-left font-medium text-gray-500 dark:text-gray-400">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {focusCounty.jurisdictions.map((j) => (
              <tr key={j.ocd_id} className="hover:bg-gray-50 dark:hover:bg-gray-800/40">
                <td className="px-3 py-2">
                  <div className="font-medium text-gray-900 dark:text-white">{j.name}</div>
                  <div className="text-[10px] uppercase tracking-wide text-gray-400">{COUNTY_LEVEL_LABEL[j.level]}</div>
                </td>
                <td className="px-3 py-2"><Bool value={j.geofenced} /></td>
                <td className="px-3 py-2"><Roster actual={j.roster_actual} expected={j.expected_seats} complete={j.expected_seats != null && j.roster_actual >= j.expected_seats} /></td>
                <td className="px-3 py-2"><Chip value={ratioToTristate(j.headshots.withPhoto, j.headshots.total)} /></td>
                <td className="px-3 py-2"><Stances s={j.stances} /></td>
                <td className="px-3 py-2"><Chip value={j.treasury} /></td>
                <td className="px-3 py-2"><Chip value={j.donors} /></td>
                <td className="px-3 py-2 tabular-nums text-gray-600 dark:text-gray-400">{j.score}%</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }

  const cov = data?.coverage ?? null;
  if (!state) return <p className="text-sm text-gray-400">Select a state on the map to see its coverage breakdown.</p>;

  return (
    <div>
      {error && <div className="mb-4 rounded border border-red-200 bg-red-50 p-4 text-sm text-red-700 dark:border-red-800/60 dark:bg-red-950/40 dark:text-red-400">{error}</div>}
      {/* PASTE the existing cov-render block from CoverageTrackerPage.tsx lines 201-363
          VERBATIM (the synced-at line, universe cards grid, treasury_orphans,
          rules, and the coverage table). It already uses `cov`, `loading`,
          LEVEL_ORDER, UniverseCard, STATUS_STYLE, and the shared cells — all
          ported above. Remove ONLY the outer state dropdown + Link header, which
          now live in the orchestrator. */}
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd admin && npx tsc --noEmit`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add admin/src/pages/admin/CoverageTable.tsx
git commit -m "feat(admin): state-driven CoverageTable with county focus"
```

---

## Task 9: Frontend — `CoveragePage` orchestrator (stacked, single-scroll, map drives table)

**Files:**
- Create: `admin/src/pages/admin/CoveragePage.tsx`

Owns all data fetching + selection state (ported from `CoverageMapPage` lines 124-273), the metric toggle + breadcrumb (lines 275-323), renders `CoverageMap` on top and `CoverageTable` below, and the hover overlay. The outer container is a normal page `<div>` — **no inner `max-h`/`overflow-auto`**, so the whole page scrolls.

- [ ] **Step 1: Create the orchestrator**

```tsx
// admin/src/pages/admin/CoveragePage.tsx
import { useEffect, useMemo, useState, useCallback } from 'react';
import { apiFetch } from '../../lib/api';
import { CoverageMap } from './CoverageMap';
import { CoverageTable } from './CoverageTable';
import { StateHoverCard, CountyHoverCard } from './CoverageHoverCard';
import type { StateScore, CountyScore, StateElection, CountyElection, Metric } from './coverageTypes';

export function CoveragePage() {
  const [metric, setMetric] = useState<Metric>('completeness');
  // completeness data
  const [states, setStates] = useState<StateScore[]>([]);
  const [counties, setCounties] = useState<CountyScore[]>([]);
  // elections data
  const [elecStates, setElecStates] = useState<StateElection[]>([]);
  const [elecCounties, setElecCounties] = useState<CountyElection[]>([]);
  const [elecDate, setElecDate] = useState<{ date: string; type: string } | null>(null);
  // selection
  const [selected, setSelected] = useState<{ fips: string; name: string; code?: string } | null>(null);
  const [selectedCounty, setSelectedCounty] = useState<CountyScore | null>(null);
  const [center, setCenter] = useState<[number, number]>([-96, 38]);
  const [zoom, setZoom] = useState(1);
  // misc
  const [hoverState, setHoverState] = useState<StateScore | null>(null);
  const [hoverCounty, setHoverCounty] = useState<CountyScore | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [statesLoading, setStatesLoading] = useState(true);
  const [loading, setLoading] = useState(false);

  // US completeness scores
  useEffect(() => {
    setStatesLoading(true);
    apiFetch<{ states: StateScore[] }>(`/admin/coverage/map?level=state`)
      .then((res) => setStates(res.states))
      .catch((err) => setError(err.message))
      .finally(() => setStatesLoading(false));
  }, []);

  // US elections scores (lazy)
  useEffect(() => {
    if (metric !== 'elections' || elecStates.length > 0) return;
    setStatesLoading(true);
    apiFetch<{ states: StateElection[] }>(`/admin/coverage/map?metric=elections&level=state`)
      .then((res) => setElecStates(res.states))
      .catch((err) => setError(err.message))
      .finally(() => setStatesLoading(false));
  }, [metric, elecStates.length]);

  const stateByFips = useMemo(() => new Map(states.map((s) => [s.fips, s])), [states]);
  const countyByFips = useMemo(() => new Map(counties.map((c) => [c.fips, c])), [counties]);
  const elecStatesByFips = useMemo(() => new Map(elecStates.map((s) => [s.fips, s])), [elecStates]);
  const elecCountiesByFips = useMemo(() => new Map(elecCounties.map((c) => [c.fips, c])), [elecCounties]);

  const loadCounties = useCallback((code: string) => {
    setLoading(true);
    if (metric === 'completeness') {
      apiFetch<{ counties: CountyScore[] }>(`/admin/coverage/map?level=county&state=${code}`)
        .then((res) => setCounties(res.counties)).catch((err) => setError(err.message)).finally(() => setLoading(false));
    } else {
      apiFetch<{ election_date: string | null; election_type: string | null; counties: CountyElection[] }>(
        `/admin/coverage/map?metric=elections&level=county&state=${code}`,
      ).then((res) => { setElecCounties(res.counties); setElecDate(res.election_date ? { date: res.election_date, type: res.election_type ?? '' } : null); })
       .catch((err) => setError(err.message)).finally(() => setLoading(false));
    }
  }, [metric]);

  const onSelectState = useCallback((fips: string, name: string, geo: unknown, fit: (geo: unknown) => void) => {
    const code = (metric === 'completeness' ? stateByFips.get(fips)?.code : elecStatesByFips.get(fips)?.code ?? stateByFips.get(fips)?.code);
    setSelected({ fips, name, code });
    setSelectedCounty(null);
    // Frame the state. fitToFeature can't reach setCenter/setZoom, so compute here:
    void fit; // bounds-based framing is handled by the map ref; fall back to a sane zoom:
    setCenter([-96, 38]); setZoom(4);
    if (!code) { setCounties([]); setElecCounties([]); return; }
    loadCounties(code);
  }, [metric, stateByFips, elecStatesByFips, loadCounties]);

  // Re-fetch counties when metric flips while a state is selected.
  useEffect(() => {
    if (selected?.code) loadCounties(selected.code);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [metric]);

  const onSelectCounty = useCallback((fips: string) => {
    if (metric === 'completeness') setSelectedCounty(countyByFips.get(fips) ?? null);
  }, [metric, countyByFips]);

  const backToUS = useCallback(() => {
    setSelected(null); setCounties([]); setSelectedCounty(null);
    setElecCounties([]); setElecDate(null);
    setCenter([-96, 38]); setZoom(1);
  }, []);

  return (
    <div>
      {/* Header + metric toggle + breadcrumb */}
      <div className="mb-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Coverage</h1>
          <div className="inline-flex overflow-hidden rounded-md border border-gray-300 text-xs dark:border-gray-600">
            {(['completeness', 'elections'] as Metric[]).map((m) => (
              <button key={m} onClick={() => { setMetric(m); setSelectedCounty(null); }}
                className={`px-2.5 py-1 font-medium capitalize ${metric === m ? 'bg-ev-teal text-white dark:bg-ev-teal-light dark:text-gray-900' : 'text-gray-600 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'}`}>
                {m}
              </button>
            ))}
          </div>
        </div>
        <nav className="text-sm text-gray-500 dark:text-gray-400">
          <button onClick={backToUS} className="hover:text-ev-teal dark:hover:text-ev-teal-light">United States</button>
          {selected && (<><span className="px-1.5">›</span><span className="font-medium text-gray-900 dark:text-white">{selected.name}</span></>)}
          {selectedCounty && (<><span className="px-1.5">›</span><span className="font-medium text-gray-900 dark:text-white">{selectedCounty.name}</span></>)}
        </nav>
      </div>

      {error && <div className="mb-4 rounded border border-red-200 bg-red-50 p-4 text-sm text-red-700 dark:border-red-800/60 dark:bg-red-950/40 dark:text-red-400">{error}</div>}

      {/* MAP (top) */}
      <div className="relative mb-6">
        {(statesLoading || loading) && (
          <div className="absolute inset-0 z-10 flex flex-col items-center justify-center gap-3 bg-white/70 backdrop-blur-sm dark:bg-gray-900/70">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-gray-300 border-t-ev-teal dark:border-gray-600 dark:border-t-ev-teal-light" />
            <p className="text-sm font-medium text-gray-600 dark:text-gray-300">{statesLoading ? 'Loading coverage data…' : 'Loading counties…'}</p>
          </div>
        )}
        <CoverageMap
          metric={metric}
          states={states} counties={counties}
          stateByFips={stateByFips} countyByFips={countyByFips}
          elecStatesByFips={elecStatesByFips} elecCountiesByFips={elecCountiesByFips} elecDate={elecDate}
          selected={selected} selectedCountyFips={selectedCounty?.fips ?? null}
          center={center} zoom={zoom}
          onSelectState={onSelectState} onSelectCounty={onSelectCounty}
        />
      </div>

      {/* TABLE (below) — completeness only; elections keeps its own drill-down inside the map area */}
      {metric === 'completeness' && (
        <CoverageTable
          state={selected?.code ?? null}
          focusCounty={selectedCounty}
          onClearCounty={() => setSelectedCounty(null)}
        />
      )}
    </div>
  );
}
```

> **Hover overlay decision:** The minimal version above does not render hover cards (it relies on the existing `<Geography>` hover stroke). To satisfy the spec's hover-card requirement, wire hover in **CoverageMap** (the simpler placement): add `onMouseEnter={() => /* setHover */}` per geography and render `<StateHoverCard>`/`<CountyHoverCard>` absolutely positioned inside the map container, fed by `stateByFips`/`countyByFips`. Move `hoverState`/`hoverCounty` state into `CoverageMap` and drop the unused orchestrator hover state. (The orchestrator hover state fields above are placeholders for whichever placement you choose — delete them if hover lives in the map.) The `StateHoverCard`/`CountyHoverCard` props map 1:1 onto `StateScore`/`CountyScore` fields.

- [ ] **Step 2: Typecheck**

Run: `cd admin && npx tsc --noEmit`
Expected: no errors. Resolve any unused-var errors by removing the placeholder hover state per the note.

- [ ] **Step 3: Commit**

```bash
git add admin/src/pages/admin/CoveragePage.tsx
git commit -m "feat(admin): unified CoveragePage orchestrator (map drives table, single scroll)"
```

---

## Task 10: Frontend — routing, redirect, nav cleanup, delete old pages

**Files:**
- Modify: `admin/src/App.tsx` (imports ~18-19; routes ~108-109)
- Modify: `admin/src/pages/admin/AdminLayout.tsx` (nav ~18-19)
- Delete: `admin/src/pages/admin/CoverageMapPage.tsx`, `admin/src/pages/admin/CoverageTrackerPage.tsx`

- [ ] **Step 1: Swap the route imports + routes in `App.tsx`**

Replace the two coverage imports (lines 18-19) with:

```ts
import { CoveragePage } from './pages/admin/CoveragePage';
import { Navigate } from 'react-router-dom';
```

(If `Navigate` is already imported at the top of `App.tsx`, do not add a duplicate.)

Replace the two coverage routes (lines 108-109) with:

```tsx
          <Route path="coverage" element={<CoveragePage />} />
          <Route path="coverage/map" element={<Navigate to="/admin/coverage" replace />} />
```

- [ ] **Step 2: Remove the "Coverage Map" nav item in `AdminLayout.tsx`**

Delete line 19 (`{ label: 'Coverage Map', to: '/admin/coverage/map' },`). Keep line 18 (`{ label: 'Coverage', to: '/admin/coverage', exact: true }`) — drop the now-unnecessary `exact: true` only if `exact` is unused elsewhere; otherwise leave it.

- [ ] **Step 3: Delete the old pages**

```bash
git rm admin/src/pages/admin/CoverageMapPage.tsx admin/src/pages/admin/CoverageTrackerPage.tsx
```

- [ ] **Step 4: Typecheck + build**

Run: `cd admin && npx tsc --noEmit && npm run build`
Expected: clean build (no dangling imports to the deleted pages).

- [ ] **Step 5: Run the frontend unit tests**

Run: `cd admin && npm test`
Expected: `coverageBivariate.test.ts` passes.

- [ ] **Step 6: Commit**

```bash
git add admin/src/App.tsx admin/src/pages/admin/AdminLayout.tsx
git commit -m "feat(admin): single Coverage tab, redirect old map route, drop nav item"
```

---

## Task 11: Docs — update COVERAGE-MAP.md

**Files:**
- Modify: `backend/data/coverage/COVERAGE-MAP.md`

- [ ] **Step 1: Document breadth/depth + bivariate**

Add a section after the existing "The formula" section explaining:
- The map now colors completeness by **bivariate breadth × depth** (not the single composite mean). The composite `score` is still returned and still drives the **table**.
- **Breadth** = fraction of child units started (state→counties, county→jurisdictions). **Depth** = mean composite over started units only.
- The 3×3 Teal×Amber palette + thresholds (breadth `<10%/10–50%/≥50%`, depth `<33/33–66/≥66`), with the note that they live in `admin/src/pages/admin/coverageBivariate.ts` and the aggregation lives in `backend/src/lib/coverageBivariate.ts`.
- The two routes are now one (`/admin/coverage`); `/admin/coverage/map` redirects.

Update the "Frontend:" pointer line near the top from `CoverageMapPage.tsx` to `CoveragePage.tsx` / `CoverageMap.tsx`.

- [ ] **Step 2: Commit**

```bash
git add backend/data/coverage/COVERAGE-MAP.md
git commit -m "docs(coverage): document bivariate breadth/depth + unified route"
```

---

## Task 12: Manual verification (preview)

- [ ] **Step 1: Start backend + admin dev servers and verify the integrated view**

Run backend: `cd backend && npm run dev` (port 3000). Run admin: `cd admin && npm run dev`. Use the preview tools to open the admin app, log in, and navigate to `/admin/coverage`. Verify:
- [ ] One "Coverage" nav item only (no "Coverage Map").
- [ ] Map renders on top, table below, the **whole page scrolls** (no inner scrollbox on the table).
- [ ] **Indiana reads teal** (narrow-but-deep); a broad-shallow state reads amber; both-high reads olive; untracked states are grey, distinct from the near-white empty cell.
- [ ] Clicking a state selects it AND the table below shows that state's breakdown (no separate dropdown).
- [ ] Drilling to a county focuses the table on that county's jurisdictions.
- [ ] Hover cards: state card shows `n/N counties` + breadth bars + `Rosters/Stances/Photos %`; county card shows `n/N populated` + jurisdictions inside + axis chips.
- [ ] Metric toggle → elections keeps its single-hue coloring + race-list drill-down inside the same layout.
- [ ] Navigating to `/admin/coverage/map` redirects to `/admin/coverage`.

- [ ] **Step 2: Capture a screenshot for the PR** of the completeness view with Indiana teal + a hover card visible.

---

## Self-Review (completed during planning)

- **Spec coverage:** One tab + stacked + single scroll (T9/T10) ✓; map-as-selector + county focus (T8/T9) ✓; bivariate breadth/depth (T1–T3 backend, T5 frontend) ✓; 3×3 teal×amber + 2D legend (T5/T6) ✓; hover cards state+county (T6) ✓; backend returns breadth/depth/breakdown alongside score (T2/T3) ✓; elections unchanged (T7 fill branch + T9 keeps elections drill-down) ✓; remove nav item + redirect (T10) ✓; Vitest for aggregation/bucketing/color (T1/T5) ✓; manual checks incl. Indiana/UT/CA + redirect + scroll (T12) ✓; docs (T11) ✓; composite weights untouched ✓; PR #20 dependency already MERGED ✓.
- **Known judgment calls flagged for the implementer:** (a) hover-card placement (map vs orchestrator) — pick one, T7/T9 notes; (b) state framing on click — the old `fitToFeature` used the projection ref; the orchestrator can't reach center/zoom from inside the map, so T9 falls back to a fixed `zoom=4`. If precise bounds-framing is wanted, lift `fitToFeature` to compute `[center, zoom]` and pass setters down, OR keep `center/zoom` state inside `CoverageMap`. Either is acceptable; do not block on it.
- **Type consistency:** `StateScore`/`CountyScore`/`JurisdictionScore`/`Metric` are defined once in `coverageTypes.ts` (T7) and imported everywhere; backend mirrors them in `coverageMapService.ts`. `bivariateColor(breadth, depth)`, `aggregateUnits(units)`, `bucketBreadth`/`bucketDepth` names are used consistently across tasks and tests.
