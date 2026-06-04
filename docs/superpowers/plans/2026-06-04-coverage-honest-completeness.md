# Coverage Honest-Completeness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the bivariate map fill with an honest single completeness gradient (compass sage→purple→yellow), count all school-district types, and show donor/headshot data as `X / Y` counts instead of Full/Partial/None.

**Architecture:** Backend keeps the composite `score` (unchanged weights) but widens the school universe and surfaces per-jurisdiction donor counts + county-level percentages. Frontend swaps the pure `bivariateColor` for a pure, unit-tested `completenessColor(score)`, replaces the 2D legend with a gradient bar, and renders counts in the table + hover card.

**Tech Stack:** Node 20 / TypeScript / Express / Postgres / Vitest (backend); React 18 / Vite / Tailwind / Vitest (admin SPA).

**Spec:** `docs/superpowers/specs/2026-06-04-coverage-honest-completeness-design.md`

---

## File Structure

**Backend**
- Modify `backend/src/lib/coverageMapService.ts` — widen school universe (G5400/G5410), add `donors_n` to `JurisdictionScore`, replace `CountyScore` rollup tristates with `*_pct` numbers.

**Frontend (admin SPA)**
- Create `admin/src/pages/admin/completenessColor.ts` (+ `.test.ts`) — pure score→color.
- Delete `admin/src/pages/admin/coverageBivariate.ts` (+ `.test.ts`) — bivariate fill retired.
- Create `admin/src/pages/admin/CompletenessLegend.tsx` — gradient legend bar.
- Delete `admin/src/pages/admin/BivariateLegend.tsx` — replaced.
- Modify `admin/src/pages/admin/coverageTypes.ts` — `JurisdictionScore.donors_n`; `CountyScore` tristates → `*_pct`.
- Modify `admin/src/pages/admin/CoverageMap.tsx` — fill via `completenessColor`; legend swap.
- Modify `admin/src/pages/admin/coverageCells.tsx` — add `CountBar` (colored `X/Y`).
- Modify `admin/src/pages/admin/CoverageTable.tsx` — drill-down headshots/donors as counts; US chip recolor.
- Modify `admin/src/pages/admin/CoverageHoverCard.tsx` — county card numeric pct line.

**Docs**
- Modify `backend/data/coverage/COVERAGE-MAP.md`.

---

## Task 1: Backend — widen the school-district universe

**Files:**
- Modify: `backend/src/lib/coverageMapService.ts` (the `children` query in `buildJurisdictions`, ~324-333)

- [ ] **Step 1: Add elementary + secondary school districts to the children query**

In `buildJurisdictions`, the children query currently filters `child.mtfcc IN ('G4110', 'G5420')`. Change that one line to include elementary (`G5400`) and secondary (`G5410`):

```ts
        WHERE child.state = $1 AND child.mtfcc IN ('G4110', 'G5420', 'G5400', 'G5410')`,
```

- [ ] **Step 2: Map the new school types to the `school` level in the push loop**

The push loop (~388-394) currently treats `G4110` as `local` and everything else as a `school_district`. That `else` branch already covers `G5420`; it now also covers `G5400`/`G5410`. No change is needed to the branch logic — verify it reads:

```ts
  for (const ch of children.rows) {
    if (ch.mtfcc === 'G4110') {
      push(`ocd-division/country:us/state:${stateCode}/place:${toSlug(ch.name, PLACE_STRIP)}`, ch.name, 'local', ch.county_fips, ch.geo_id);
    } else {
      push(`ocd-division/country:us/state:${stateCode}/school_district:${toSlug(ch.name, SCHOOL_STRIP)}`, ch.name, 'school', ch.county_fips, ch.geo_id);
    }
  }
```

The `SCHOOL_STRIP` regex (`/ school district$/i`) still produces a unique slug per district (e.g. "Foo Elementary School District" → `foo_elementary`); elementary/secondary districts have no loaded politicians, so they land as empty `school` units that correctly enlarge the denominator. No slug change is required.

- [ ] **Step 3: Typecheck**

Run: `cd backend && npm run typecheck`
Expected: no errors.

- [ ] **Step 4: Probe production — confirm the school universe grew**

Create `backend/scripts/_probe-schools.ts`:

```ts
import { getStateScores } from '../src/lib/coverageMapService.js';
const states = await getStateScores({ refresh: true });
for (const code of ['ca', 'ut', 'in']) {
  const s = states.find((x) => x.code === code);
  if (!s) { console.log(code, 'NOT TRACKED'); continue; }
  console.log(JSON.stringify({ code: s.code, score: s.score, schools: `${s.schools_started}/${s.schools_total}` }));
}
process.exit(0);
```

Run: `cd backend && node --env-file=.env --import tsx scripts/_probe-schools.ts`
Expected: CA `schools_total` jumps to ~982 (was 353); CA `score` drops a little (more empty units). Paste the output, then `rm backend/scripts/_probe-schools.ts`.

- [ ] **Step 5: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add backend/src/lib/coverageMapService.ts
git commit -m "feat(coverage): count all school-district types (unified+elementary+secondary)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Backend — per-jurisdiction donor counts + county-level percentages

**Files:**
- Modify: `backend/src/lib/coverageMapService.ts` (`JurisdictionScore` ~99-113; `push` ~341-382; `CountyScore` ~115-135; `countyBreakdown` ~409-450)

- [ ] **Step 1: Add `donors_n` to the `JurisdictionScore` interface**

Replace the `JurisdictionScore` interface (lines ~99-113) with (adds `donors_n`, keeps everything else):

```ts
export interface JurisdictionScore {
  ocd_id: string;
  name: string;
  level: MapLevel;
  county_fips: string | null;
  score: number; // composite 0..100
  populated: boolean;
  roster_actual: number;
  expected_seats: number | null;
  headshots: { withPhoto: number; total: number };
  stances: { researched: number; total: number };
  donors_n: { withDonors: number; total: number };
  geofenced: boolean;
  treasury: Tristate;
  donors: Tristate;
}
```

- [ ] **Step 2: Populate `donors_n` in the `push` helper**

In `push`, the `out.push({...})` object currently has `stances: { researched: s.researched, total: s.total },`. Add the donor count right after it:

```ts
      stances: { researched: s.researched, total: s.total },
      donors_n: { withDonors: s.withDonors, total: s.total },
```

(`s.withDonors` is already on the `JurisStats` object from `statsByJurisdiction`.)

- [ ] **Step 3: Replace the `CountyScore` rollup tristates with percentages**

Replace the `CountyScore` interface (lines ~115-135) with (swaps `roster`/`stances`/`photos`/`donors` Tristates for `*_pct` numbers; keeps `treasury` Tristate):

```ts
export interface CountyScore {
  fips: string; // 5-digit county FIPS (matches us-atlas county keys)
  name: string;
  score: number; // 0..100, mean composite over jurisdictions inside
  jurisdiction_count: number;
  populated_count: number;
  jurisdictions: JurisdictionScore[];
  breadth: number; // 0..1 — populated_count ÷ jurisdiction_count
  depth: number;   // 0..100 — mean composite over populated jurisdictions only
  county_govt_started: boolean;
  cities_started: number;
  cities_total: number;
  schools_started: number;
  schools_total: number;
  roster_pct: number;   // 0..100 over populated jurisdictions
  stances_pct: number;  // 0..100
  photo_pct: number;    // 0..100
  donors_pct: number;   // 0..100 — politicians with ≥1 contribution ÷ total
  treasury: Tristate;   // categorical: any/all populated jurisdictions with a budget
}
```

- [ ] **Step 4: Rewrite `countyBreakdown` to return percentages**

Replace the entire `countyBreakdown` function (lines ~403-450) with:

```ts
/**
 * Roll a county's jurisdiction list into the bivariate + hover breakdown.
 * breadth/depth come from the pure aggregator (started = populated, depth =
 * composite score). Per-axis values are percentages over the POPULATED
 * jurisdictions, so empty white space doesn't drag them to zero. Treasury stays
 * categorical (a budget is loaded per jurisdiction, not a per-politician ratio).
 */
function countyBreakdown(list: JurisdictionScore[]) {
  const units: Unit[] = list.map((j) => ({ started: j.populated, depth: j.score }));
  const { breadth, depth } = aggregateUnits(units);
  const populated = list.filter((j) => j.populated);

  const cities = list.filter((j) => j.level === 'local');
  const schools = list.filter((j) => j.level === 'school');
  const countyGovt = list.find((j) => j.level === 'county');

  const sum = (sel: (j: JurisdictionScore) => number) => populated.reduce((s, j) => s + sel(j), 0);
  const photoPart = sum((j) => j.headshots.withPhoto);
  const photoTotal = sum((j) => j.headshots.total);
  const stancePart = sum((j) => j.stances.researched);
  const stanceTotal = sum((j) => j.stances.total);
  const donorPart = sum((j) => j.donors_n.withDonors);
  const donorTotal = sum((j) => j.donors_n.total);
  const rosterActual = sum((j) => (j.expected_seats != null ? j.roster_actual : 0));
  const rosterExpected = sum((j) => j.expected_seats ?? 0);
  const pct = (part: number, total: number) => (total > 0 ? Math.round((part / total) * 1000) / 10 : 0);

  const treasuryFull = populated.filter((j) => j.treasury === 'full').length;
  const treasuryAny = populated.filter((j) => j.treasury !== 'none').length;
  // 'full' only when every populated jurisdiction has a budget, 'partial' when some do.
  const treasury: Tristate =
    populated.length === 0 || treasuryAny === 0 ? 'none' : treasuryFull >= populated.length ? 'full' : 'partial';

  return {
    breadth,
    depth,
    county_govt_started: !!countyGovt?.populated,
    cities_started: cities.filter((c) => c.populated).length,
    cities_total: cities.length,
    schools_started: schools.filter((s) => s.populated).length,
    schools_total: schools.length,
    roster_pct: pct(Math.min(rosterActual, rosterExpected), rosterExpected),
    stances_pct: pct(stancePart, stanceTotal),
    photo_pct: pct(photoPart, photoTotal),
    donors_pct: pct(donorPart, donorTotal),
    treasury,
  };
}
```

- [ ] **Step 5: Typecheck**

Run: `cd backend && npm run typecheck`
Expected: no errors. (`getCountyScores` spreads `...countyBreakdown(list)`, so the new shape flows through automatically.)

- [ ] **Step 6: Probe production**

Create `backend/scripts/_probe-county2.ts`:

```ts
import { getCountyScores } from '../src/lib/coverageMapService.js';
const data = await getCountyScores('ut', { refresh: true });
const slc = data?.counties.find((c) => c.name.toLowerCase().includes('salt lake'));
console.log(JSON.stringify({
  name: slc?.name, roster_pct: slc?.roster_pct, stances_pct: slc?.stances_pct,
  photo_pct: slc?.photo_pct, donors_pct: slc?.donors_pct, treasury: slc?.treasury,
}, null, 2));
const j = slc?.jurisdictions.find((x) => x.populated);
console.log('sample jurisdiction donors_n:', JSON.stringify(j?.donors_n), 'headshots:', JSON.stringify(j?.headshots));
process.exit(0);
```

Run: `cd backend && node --env-file=.env --import tsx scripts/_probe-county2.ts`
Expected: Salt Lake County shows `roster_pct/stances_pct/photo_pct/donors_pct` numbers (0..100) and `treasury` tristate; the sample jurisdiction shows `donors_n: {withDonors, total}` and `headshots: {withPhoto, total}`. Paste it, then `rm backend/scripts/_probe-county2.ts`.

- [ ] **Step 7: Run the backend suite**

Run: `cd backend && npm test`
Expected: `coverageBivariate.test.ts` (5) passes; pre-existing architecture/integration failures are unrelated. Confirm you touched no test files.

- [ ] **Step 8: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add backend/src/lib/coverageMapService.ts
git commit -m "feat(coverage): per-jurisdiction donor counts + county-level percentages

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Frontend — pure `completenessColor` module (TDD)

**Files:**
- Create: `admin/src/pages/admin/completenessColor.ts`
- Test: `admin/src/pages/admin/completenessColor.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// admin/src/pages/admin/completenessColor.test.ts
import { describe, it, expect } from 'vitest';
import { completenessColor, NOT_STARTED, GAMMA, KNEE } from './completenessColor';

describe('completenessColor', () => {
  it('untracked (null) → not-started grey', () => {
    expect(completenessColor(null)).toBe(NOT_STARTED);
    expect(NOT_STARTED).toBe('#e5e7eb');
  });

  it('0% → pale sage (ramp floor, distinct from grey)', () => {
    expect(completenessColor(0)).toBe('rgb(207, 227, 196)');
  });

  it('100% → yellow (only at fully complete)', () => {
    expect(completenessColor(100)).toBe('rgb(254, 209, 46)');
  });

  it('the gamma knee lands exactly on purple', () => {
    const kneeScore = 100 * Math.pow(KNEE, 1 / GAMMA);
    expect(completenessColor(kneeScore)).toBe('rgb(125, 91, 166)');
  });

  it('distinguishes low scores (gamma expands the low end)', () => {
    expect(completenessColor(4)).not.toBe(completenessColor(30));
    expect(completenessColor(4)).not.toBe(NOT_STARTED);
  });

  it('clamps above 100 to yellow', () => {
    expect(completenessColor(150)).toBe('rgb(254, 209, 46)');
  });
});
```

- [ ] **Step 2: Run it, verify it FAILS**

Run: `cd admin && npx vitest run src/pages/admin/completenessColor.test.ts`
Expected: FAIL — cannot find module `./completenessColor`.

- [ ] **Step 3: Implement the module**

```ts
// admin/src/pages/admin/completenessColor.ts
/**
 * Honest single-gradient color for the completeness coverage map.
 *
 * Input is the composite completeness score (0..100) for a state or county —
 * empty units already drag it down, so the color reflects how complete the WHOLE
 * jurisdiction is. A gamma curve expands the low end so 4% vs 13% vs 30% are
 * distinguishable sage shades; only ~100% reaches yellow. Untracked geographies
 * (no coverage YAML → null score) render neutral grey, painted by the caller.
 *
 * Antipartisan — sage → purple → yellow, deliberately no red/blue. Tunable.
 */
export const NOT_STARTED = '#e5e7eb'; // gray-200 — untracked / no coverage file
export const GAMMA = 0.55;            // expands the crowded low end
export const KNEE = 0.6;              // t at which the ramp reaches purple

const SAGE = [0xcf, 0xe3, 0xc4];   // low
const PURPLE = [0x7d, 0x5b, 0xa6]; // mid-high (at the knee)
const YELLOW = [0xfe, 0xd1, 0x2e]; // 100% (EV Inform token)

const lerp = (a: number, b: number, t: number) => Math.round(a + (b - a) * t);
const rgb = (c: number[]) => `rgb(${c[0]}, ${c[1]}, ${c[2]})`;

/** score 0..100 → sage→purple→yellow hex; null/undefined → not-started grey. */
export function completenessColor(score: number | null | undefined): string {
  if (score == null) return NOT_STARTED;
  const t = Math.pow(Math.min(1, Math.max(0, score) / 100), GAMMA);
  if (t <= KNEE) {
    const u = t / KNEE;
    return rgb([lerp(SAGE[0], PURPLE[0], u), lerp(SAGE[1], PURPLE[1], u), lerp(SAGE[2], PURPLE[2], u)]);
  }
  const u = (t - KNEE) / (1 - KNEE);
  return rgb([lerp(PURPLE[0], YELLOW[0], u), lerp(PURPLE[1], YELLOW[1], u), lerp(PURPLE[2], YELLOW[2], u)]);
}
```

- [ ] **Step 4: Run it, verify it PASSES**

Run: `cd admin && npx vitest run src/pages/admin/completenessColor.test.ts`
Expected: PASS (6 tests).

- [ ] **Step 5: Delete the retired bivariate module + its test**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git rm admin/src/pages/admin/coverageBivariate.ts admin/src/pages/admin/coverageBivariate.test.ts
```

(Note: the backend's own `backend/src/lib/coverageBivariate.ts` aggregation module is a different file — do NOT touch it.)

- [ ] **Step 6: Commit**

```bash
git add admin/src/pages/admin/completenessColor.ts admin/src/pages/admin/completenessColor.test.ts
git commit -m "feat(admin): pure completenessColor gradient; retire bivariate fill

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Frontend — `CompletenessLegend` (replaces `BivariateLegend`)

**Files:**
- Create: `admin/src/pages/admin/CompletenessLegend.tsx`
- Delete: `admin/src/pages/admin/BivariateLegend.tsx`

- [ ] **Step 1: Create the gradient legend**

```tsx
// admin/src/pages/admin/CompletenessLegend.tsx
/**
 * Legend for the honest completeness gradient: a sage → purple → yellow bar
 * (less complete → 100%) plus the separate grey "not started" chip. Rendered as
 * an overlay inside the map area.
 */
import { completenessColor, NOT_STARTED } from './completenessColor';

// Sample the same gamma'd ramp at a few scores so the bar matches the map exactly.
const STOPS = [0, 10, 25, 45, 70, 100].map((s) => completenessColor(s));

export function CompletenessLegend() {
  return (
    <div className="flex items-center gap-3 text-[11px] leading-none text-gray-500 dark:text-gray-400">
      <div className="flex flex-col gap-1">
        <div className="flex items-center gap-2">
          <span>less complete</span>
          <div className="h-3 w-40 rounded-full" style={{ background: `linear-gradient(to right, ${STOPS.join(', ')})` }} />
          <span className="font-medium text-gray-600 dark:text-gray-300">100%</span>
        </div>
      </div>
      <span className="inline-flex items-center gap-1.5">
        <span className="inline-block h-3 w-3 rounded-sm" style={{ background: NOT_STARTED }} />
        not started
      </span>
    </div>
  );
}
```

- [ ] **Step 2: Delete the old legend**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git rm admin/src/pages/admin/BivariateLegend.tsx
```

- [ ] **Step 3: Typecheck** (will still error until CoverageMap is updated in Task 6 — that's expected; just confirm THIS file has no errors of its own by checking the message references only CoverageMap's import).

Run: `cd admin && npx tsc --noEmit`
Expected: the only errors are `CoverageMap.tsx` still importing `./BivariateLegend` — fixed in Task 6. (If `CompletenessLegend.tsx` itself errors, fix it.)

- [ ] **Step 4: Commit**

```bash
git add admin/src/pages/admin/CompletenessLegend.tsx
git commit -m "feat(admin): completeness gradient legend (replaces bivariate 2D legend)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Frontend — update `coverageTypes.ts`

**Files:**
- Modify: `admin/src/pages/admin/coverageTypes.ts`

- [ ] **Step 1: Add `donors_n` to `JurisdictionScore`**

In `coverageTypes.ts`, the `JurisdictionScore` interface has:
```ts
  headshots: { withPhoto: number; total: number }; stances: { researched: number; total: number };
```
Add `donors_n` alongside:
```ts
  headshots: { withPhoto: number; total: number }; stances: { researched: number; total: number };
  donors_n: { withDonors: number; total: number };
```

- [ ] **Step 2: Swap the `CountyScore` rollup tristates for percentages**

The `CountyScore` interface currently ends with:
```ts
  roster: 'none' | 'partial' | 'full'; stances: 'none' | 'partial' | 'full'; photos: 'none' | 'partial' | 'full';
  treasury: 'none' | 'partial' | 'full'; donors: 'none' | 'partial' | 'full';
```
Replace those two lines with:
```ts
  roster_pct: number; stances_pct: number; photo_pct: number; donors_pct: number;
  treasury: 'none' | 'partial' | 'full';
```

- [ ] **Step 3: Typecheck**

Run: `cd admin && npx tsc --noEmit`
Expected: errors now in `CoverageMap.tsx` (BivariateLegend import), `CoverageHoverCard.tsx` (county tristates gone), `CoverageTable.tsx` (county tristates / bivariate import) — all fixed in Tasks 6-8. Confirm `coverageTypes.ts` itself has no error.

- [ ] **Step 4: Commit**

```bash
git add admin/src/pages/admin/coverageTypes.ts
git commit -m "feat(admin): coverageTypes — donors_n + county percentages

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Frontend — `CoverageMap` fill + legend swap

**Files:**
- Modify: `admin/src/pages/admin/CoverageMap.tsx`

- [ ] **Step 1: Swap the imports**

Replace:
```ts
import { bivariateColor, NOT_STARTED } from './coverageBivariate';
import { BivariateLegend } from './BivariateLegend';
```
with:
```ts
import { completenessColor, NOT_STARTED } from './completenessColor';
import { CompletenessLegend } from './CompletenessLegend';
```

- [ ] **Step 2: Use `completenessColor` for the state fill**

Find the state fill line:
```ts
                    const fill = metric === 'elections' ? electionStateColor(es) : (sc ? bivariateColor(sc.breadth, sc.depth) : NOT_STARTED);
```
Replace with:
```ts
                    const fill = metric === 'elections' ? electionStateColor(es) : completenessColor(sc?.score ?? null);
```

- [ ] **Step 3: Use `completenessColor` for the county fill**

Find the county fill line:
```ts
                      const fill = metric === 'elections' ? electionCountyColor(ec) : (cs ? bivariateColor(cs.breadth, cs.depth) : NOT_STARTED);
```
Replace with:
```ts
                      const fill = metric === 'elections' ? electionCountyColor(ec) : completenessColor(cs?.score ?? null);
```

- [ ] **Step 4: Swap the in-map legend overlay**

Find:
```tsx
        {metric === 'completeness' && (
          <div className="absolute bottom-3 left-3 z-20 rounded-md border border-gray-200/70 bg-white/85 px-3 py-2 shadow-sm backdrop-blur-sm dark:border-gray-700/70 dark:bg-gray-900/85">
            <BivariateLegend />
          </div>
        )}
```
Replace `<BivariateLegend />` with `<CompletenessLegend />` (keep the wrapper div).

- [ ] **Step 5: Typecheck**

Run: `cd admin && npx tsc --noEmit`
Expected: `CoverageMap.tsx` errors resolved; remaining errors only in `CoverageHoverCard.tsx` / `CoverageTable.tsx`. (`NOT_STARTED` is still imported and still used by the elections color helpers — confirm no unused-import error.)

- [ ] **Step 6: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add admin/src/pages/admin/CoverageMap.tsx
git commit -m "feat(admin): CoverageMap fill uses completenessColor + gradient legend

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Frontend — `CountBar` cell + drill-down counts + US chip recolor

**Files:**
- Modify: `admin/src/pages/admin/coverageCells.tsx`
- Modify: `admin/src/pages/admin/CoverageTable.tsx`

- [ ] **Step 1: Add a `CountBar` cell to `coverageCells.tsx`**

Append to `admin/src/pages/admin/coverageCells.tsx` (it already exports `ratioToTristate` and the `Tristate` type):

```tsx
/** A colored "have/total" count — green=full, amber=partial, grey=none. */
export function CountBar({ have, total }: { have: number; total: number }) {
  const t = ratioToTristate(have, total);
  const cls =
    t === 'full' ? 'text-emerald-700 dark:text-emerald-400'
    : t === 'partial' ? 'text-amber-700 dark:text-amber-400'
    : 'text-gray-400 dark:text-gray-600';
  return (
    <span className={`tabular-nums text-xs font-medium ${cls}`}>
      {have}<span className="text-gray-400">/{total}</span>
    </span>
  );
}
```

- [ ] **Step 2: Use counts for Headshots + Donors in the county drill-down table**

In `CoverageTable.tsx`, update the imports from `./coverageCells` to add `CountBar` and from `./completenessColor`:
```ts
import { Bool, Chip, Stances, Roster, ratioToTristate, CountBar, type Tristate } from './coverageCells';
```
And replace the bivariate import:
```ts
import { bivariateColor } from './coverageBivariate';
```
with:
```ts
import { completenessColor } from './completenessColor';
```

In the county-focus table body, the Headshots and Donors cells currently read:
```tsx
                  <td className="px-3 py-2"><Chip value={ratioToTristate(j.headshots.withPhoto, j.headshots.total)} /></td>
                  <td className="px-3 py-2"><Stances s={j.stances} /></td>
                  <td className="px-3 py-2"><Chip value={j.treasury} /></td>
                  <td className="px-3 py-2"><Chip value={j.donors} /></td>
```
Replace the Headshots cell and the Donors cell (leave Stances and Treasury as-is):
```tsx
                  <td className="px-3 py-2"><CountBar have={j.headshots.withPhoto} total={j.headshots.total} /></td>
                  <td className="px-3 py-2"><Stances s={j.stances} /></td>
                  <td className="px-3 py-2"><Chip value={j.treasury} /></td>
                  <td className="px-3 py-2"><CountBar have={j.donors_n.withDonors} total={j.donors_n.total} /></td>
```

- [ ] **Step 3: Recolor the US-overview leading chip with `completenessColor`**

In the `UsOverviewTable` row, the leading chip currently reads:
```tsx
                      <span className="inline-block h-3.5 w-3.5 shrink-0 rounded-sm" style={{ background: bivariateColor(s.breadth, s.depth) }} title="bivariate breadth × depth" />
```
Replace with:
```tsx
                      <span className="inline-block h-3.5 w-3.5 shrink-0 rounded-sm" style={{ background: completenessColor(s.score) }} title="completeness" />
```

(The Breadth / Depth columns stay — they're honest numbers. `ratioToTristate` is still imported but may now be unused in `CoverageTable`; if tsc/lint flags it as unused, remove it from the import.)

- [ ] **Step 4: Typecheck**

Run: `cd admin && npx tsc --noEmit`
Expected: `CoverageTable.tsx` errors resolved; only `CoverageHoverCard.tsx` remains (Task 8). If `ratioToTristate` is reported unused in CoverageTable, drop it from the import line.

- [ ] **Step 5: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add admin/src/pages/admin/coverageCells.tsx admin/src/pages/admin/CoverageTable.tsx
git commit -m "feat(admin): count cells for headshots/donors; US chip uses completenessColor

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Frontend — county hover card numeric line

**Files:**
- Modify: `admin/src/pages/admin/CoverageHoverCard.tsx`

- [ ] **Step 1: Update the `CountyHover` interface**

In `CoverageHoverCard.tsx`, the `CountyHover` interface ends with:
```ts
  roster: Tristate; stances: Tristate; photos: Tristate; treasury: Tristate; donors: Tristate;
```
Replace that line with:
```ts
  roster_pct: number; stances_pct: number; photo_pct: number; donors_pct: number; treasury: Tristate;
```

- [ ] **Step 2: Replace the tristate chips with a numeric summary line**

In `CountyHoverCard`, the axis-chips block currently reads:
```tsx
      <div className="mt-2 flex flex-wrap items-center gap-x-2 gap-y-1 border-t border-gray-100 pt-1.5 dark:border-gray-800">
        {([['Roster', c.roster], ['Stances', c.stances], ['Photos', c.photos], ['Treasury', c.treasury], ['Donors', c.donors]] as [string, Tristate][]).map(
          ([label, v]) => (
            <span key={label} className="inline-flex items-center gap-1 text-[10px] text-gray-500 dark:text-gray-400">
              {label}<Chip value={v} />
            </span>
          ),
        )}
      </div>
```
Replace the whole block with a numeric line plus a small treasury indicator:
```tsx
      <div className="mt-2 border-t border-gray-100 pt-1.5 text-[11px] text-gray-500 dark:border-gray-800 dark:text-gray-400">
        Rosters {c.roster_pct}% · Stances {c.stances_pct}% · Photos {c.photo_pct}% · Donors {c.donors_pct}%
      </div>
      <div className="mt-1 flex items-center gap-1 text-[10px] text-gray-500 dark:text-gray-400">
        Treasury<Chip value={c.treasury} />
      </div>
```

(`Chip` and `Tristate` are still imported and still used by the Treasury indicator — leave the import line as-is.)

- [ ] **Step 3: Typecheck + build**

Run: `cd admin && npx tsc --noEmit && npm run build`
Expected: clean build (the whole admin app compiles).

- [ ] **Step 4: Run the admin unit tests**

Run: `cd admin && npm test`
Expected: `completenessColor.test.ts` passes (6); no other test files.

- [ ] **Step 5: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add admin/src/pages/admin/CoverageHoverCard.tsx
git commit -m "feat(admin): county hover card shows percentages, not Full/Partial/None

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Docs + final verification

**Files:**
- Modify: `backend/data/coverage/COVERAGE-MAP.md`

- [ ] **Step 1: Update the bivariate section of the doc**

In `backend/data/coverage/COVERAGE-MAP.md`, the "Bivariate coloring (completeness map fill)" section describes the retired 3×3 encoding. Replace that section's body so it documents the new model:
- The completeness map fill is now a **single honest gradient** over the composite `score` (empty units count), gamma-expanded `sage → purple → yellow(100%)`, antipartisan, untracked = grey. Pure function: `admin/src/pages/admin/completenessColor.ts`.
- Breadth/depth are still computed (`backend/src/lib/coverageBivariate.ts` aggregation) and surfaced as **numbers** in the hover cards + US overview table, but no longer drive the color.
- The school-district universe now counts unified + elementary + secondary (`G5420`+`G5400`+`G5410`).
- Headshots and donors are shown as `have/total` counts (politicians with a photo / with ≥1 contribution), not Full/Partial/None.

Keep the surrounding "Geography rollup", "not started vs low", elections, and freshness sections accurate (update any sentence that still claims the fill is bivariate or that schools are unified-only).

- [ ] **Step 2: Commit the docs**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add backend/data/coverage/COVERAGE-MAP.md
git commit -m "docs(coverage): honest completeness gradient + school universe + count cells

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

- [ ] **Step 3: Full verification gate**

Run each and confirm green:
- `cd backend && npm run typecheck` → clean
- `cd backend && npx vitest run src/lib/coverageBivariate.test.ts` → 5 pass
- `cd admin && npx tsc --noEmit` → clean
- `cd admin && npm test` → completenessColor 6 pass
- `cd admin && npm run build` → clean

- [ ] **Step 4: Confirm the color mapping on real data**

Create `admin/_colorcheck.mts`:
```ts
import { completenessColor } from './src/pages/admin/completenessColor.ts';
// CA≈13 (after school-universe change it drops a little), IN≈4, a complete county≈97
for (const [label, score] of [['CA-ish', 11], ['IN-ish', 3], ['UT-ish', 9], ['done county', 97], ['untracked', null]] as const) {
  console.log(label, score, '→', completenessColor(score as number | null));
}
EOF_MARKER
```
(Write the file without the `EOF_MARKER` line.) Run: `cd admin && npx tsx _colorcheck.mts; rm admin/_colorcheck.mts`
Expected: low scores are pale-sage rgb values (distinct from each other), the "done county" is near-yellow, untracked is `#e5e7eb`. This is a sanity check, not committed.

- [ ] **Step 5: Push + open PR**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git push -u origin feat/coverage-honest-completeness
```
Then open a PR (base `master`) summarizing: honest completeness gradient (sage→purple→yellow), all school-district types counted, headshots/donors as counts, county hover/ table de-tristated. Note the manual UI checks (CA reads early sage, a complete county reads yellow, drill-down shows counts, gradient legend) need a pass in the running admin app.

---

## Self-Review

- **Spec coverage:** honest gradient color (T3 module + T6 fill) ✓; sage→purple→yellow gamma + yellow@100% (T3) ✓; bivariate retired, breadth/depth kept as numbers (T3 delete + US table/hover unchanged columns) ✓; school universe all types (T1) ✓; donor/headshot counts (T2 backend + T7 cells) ✓; county hover de-tristated to % (T2 backend + T8) ✓; composite weights / Indiana denominator / elections untouched (no task changes them) ✓; legend → gradient bar (T4) ✓; docs (T9) ✓; tests for completenessColor (T3) ✓.
- **Placeholder scan:** none — every code step has full code or exact old→new snippets.
- **Type consistency:** `donors_n: {withDonors,total}` defined in backend (T2) + frontend `coverageTypes` (T5) and consumed in T7/T8. `CountyScore` `roster_pct/stances_pct/photo_pct/donors_pct` + `treasury` defined in T2/T5 and consumed in T8. `CountBar({have,total})` defined T7 and used T7. `completenessColor(score|null)` defined T3, used T6/T7. Legend names `CompletenessLegend` consistent T4/T6.
- **Sequencing note:** Tasks 4-5 intentionally leave the app non-compiling between commits (interfaces change before consumers); the app is green again after Task 8. Each commit is still atomic/coherent. The executor should not treat the interim tsc errors called out in T4/T5/T6 as failures.
