# Hyper-local County Membership (school + township) Implementation Plan

> **For agentic workers:** implement task-by-task with TDD. Steps use checkbox (`- [ ]`) syntax.

**Goal:** School-district (`G5400/G5410/G5420`) and township (`G4040`) races should land in the read-rank "In {County}" tier instead of the state tier, by resolving the counties their boundary overlaps.

**Background:** A prior change ([read-rank PR #49](https://github.com/EmpoweredVote/read-rank/pull/49) / [ev-accounts PR #55](https://github.com/EmpoweredVote/ev-accounts/pull/55)) added a county relevance tier driven by per-race `countyGeoIds`. State-legislative districts got their county set from `getCountyUnionFrames` (county polygons overlapping the district). School/township races were left out (`countyGeoIds = []`) and fall to the state tier — a documented v1 boundary we're now closing.

**Approach:** Reuse the existing `getCountyUnionFrames` overlap query for these layers too. Introduce a `COUNTY_OVERLAP_LAYERS` set so ref-collection and the `countyGeoIds` derivation stay DRY. **The visual `frameRef` (map motif) is intentionally NOT changed** — school/township keep their state outline; only tiering changes. **No frontend change** — `groupRaces` already tiers on whatever `countyGeoIds` it receives.

**Tradeoff accepted:** `getCountyUnionFrames` also computes union geometry we discard for these layers. The set of school/township races is small, so this is acceptable; a membership-only query is a possible future optimization.

**Tech stack:** TypeScript, PostGIS, Vitest (mocked `pool.query` / `getCountyUnionFrames`).

---

## Task 1: Extend county membership to school + township layers

**Files:**
- Modify: `backend/src/lib/readrankService.ts`
- Modify: `backend/src/lib/informBoundaryService.ts` (doc comment only)
- Test: `backend/src/lib/readrankService.test.ts`

Run all commands from `/Users/chrisandrews/Documents/GitHub/ev-accounts/backend`.

- [ ] **Step 1: Update the failing tests**

In `backend/src/lib/readrankService.test.ts`, find the existing test (in `describe('getPlayableRaces — countyGeoIds', ...)`):
```ts
  it('is [] for a school district race (v1 boundary)', async () => {
```
REPLACE that single `it(...)` block with these three:
```ts
  it('uses the union member counties for a school district', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'School Board',
      jurisdiction_level: 'local',
      boundary_layer: 'G5400', boundary_geoid: '1800001',
      frame_layer: null, frame_geoid: null,
    }] });
    mockGetCountyUnionFrames.mockResolvedValueOnce(new Map([
      ['G5400:1800001', { bbox: [0, 0, 1, 1], geojson: { type: 'MultiPolygon', coordinates: [] }, countyGeoIds: ['18105'] }],
    ]));
    const [race] = await getPlayableRaces();
    expect(race.countyGeoIds).toEqual(['18105']);
  });

  it('uses the union member counties for a township', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'Township Trustee',
      jurisdiction_level: 'local',
      boundary_layer: 'G4040', boundary_geoid: '1899999',
      frame_layer: null, frame_geoid: null,
    }] });
    mockGetCountyUnionFrames.mockResolvedValueOnce(new Map([
      ['G4040:1899999', { bbox: [0, 0, 1, 1], geojson: { type: 'MultiPolygon', coordinates: [] }, countyGeoIds: ['18105', '18021'] }],
    ]));
    const [race] = await getPlayableRaces();
    expect(race.countyGeoIds).toEqual(['18105', '18021']);
  });

  it('is [] for a school district with no resolved county overlap', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'School Board',
      jurisdiction_level: 'local',
      boundary_layer: 'G5400', boundary_geoid: '1800001',
      frame_layer: null, frame_geoid: null,
    }] });
    // getCountyUnionFrames returns no entry for this ref → graceful []
    const [race] = await getPlayableRaces();
    expect(race.countyGeoIds).toEqual([]);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `npx vitest run src/lib/readrankService.test.ts`
Expected: the two "uses the union member counties" tests FAIL (school/township currently derive `[]` because the derivation branch only matches `G5210`/`G5220`). The "no resolved overlap" test passes already.

- [ ] **Step 3: Add the `COUNTY_OVERLAP_LAYERS` set**

In `backend/src/lib/readrankService.ts`, just below the `MTFCC_SCOPE` constant (near line 121), add:
```ts
/** Sub-state layers whose county membership is resolved by polygon overlap (ST_Intersects)
 *  for the read-rank county relevance tier: state-leg districts, school districts, townships.
 *  Their visual frame is unchanged — this only populates countyGeoIds. */
const COUNTY_OVERLAP_LAYERS = new Set(['G5210', 'G5220', 'G5400', 'G5410', 'G5420', 'G4040']);
```

- [ ] **Step 4: Broaden the ref collection**

Find this block (~lines 352–356):
```ts
  const slegRefs: Array<{ layer: string; geoid: string }> = [];
  for (const r of rows) {
    if ((r.boundary_layer === 'G5210' || r.boundary_layer === 'G5220') && r.boundary_geoid) {
      slegRefs.push({ layer: r.boundary_layer, geoid: r.boundary_geoid });
    }
  }
```
Replace with:
```ts
  const overlapRefs: Array<{ layer: string; geoid: string }> = [];
  for (const r of rows) {
    if (r.boundary_layer && COUNTY_OVERLAP_LAYERS.has(r.boundary_layer) && r.boundary_geoid) {
      overlapRefs.push({ layer: r.boundary_layer, geoid: r.boundary_geoid });
    }
  }
```
Then update the call that uses it (~line 360) from `await getCountyUnionFrames(slegRefs)` to `await getCountyUnionFrames(overlapRefs)`. Leave the surrounding `let unionFrameMap` declaration and the `try/catch` exactly as-is.

- [ ] **Step 5: Broaden the `countyGeoIds` derivation branch**

Find the third branch of the `countyGeoIds` derivation (~lines 428–431):
```ts
    } else if (childLayer === 'G5210' || childLayer === 'G5220') {
      const uf = r.boundary_geoid ? unionFrameMap.get(`${childLayer}:${r.boundary_geoid}`) : undefined;
      countyGeoIds = uf?.countyGeoIds ?? [];
    }
```
Replace the condition with the set check:
```ts
    } else if (COUNTY_OVERLAP_LAYERS.has(childLayer)) {
      const uf = r.boundary_geoid ? unionFrameMap.get(`${childLayer}:${r.boundary_geoid}`) : undefined;
      countyGeoIds = uf?.countyGeoIds ?? [];
    }
```
Also update the derivation comment just above the `let countyGeoIds` line so it reads (replace the existing comment text):
```ts
    // County set for the relevance tier. county/city/ward-council come from the
    // single G4020 boundary or frame already computed; state-leg, school, and
    // township districts use the overlapping-county set; everything else → [].
```

**IMPORTANT — do NOT change the `frameRef` logic.** The state-leg visual-frame branch (`} else if (childLayer === 'G5210' || childLayer === 'G5220') {` around line 399, which builds the `G4020U` frame) MUST stay literal `G5210/G5220`. School/township must keep `frameRef = stateRef` (the `else` branch). Only the `countyGeoIds` branch (Step 5) and the ref collection (Step 4) change.

- [ ] **Step 6: Update the `getCountyUnionFrames` doc comment**

In `backend/src/lib/informBoundaryService.ts`, the JSDoc above `getCountyUnionFrames` begins "Frame geometry for state-legislative districts:". Update the first sentence to note the broader use, e.g.:
```ts
/**
 * Frame geometry + member county GEOIDs for sub-state districts (state-legislative,
 * school, township): the union of the counties (G4020) each district actually overlaps.
 * The union geometry is used as the visual frame for state-leg districts; the member
 * GEOIDs (countyGeoIds) drive read-rank's county relevance tier for all of them.
 * Keyed by "layer:geoid" of the district (the child), matching the refs passed in.
 ...
```
Keep the rest of the existing comment (the ST_Intersects / area-overlap / simplification notes) intact.

- [ ] **Step 7: Run the tests to verify they pass**

Run: `npx vitest run src/lib/readrankService.test.ts`
Expected: PASS — the two new union-member tests, the no-overlap `[]` test, the pre-existing state-leg test, and all others.

- [ ] **Step 8: Verify types**

Run: `npx tsc -b --noEmit`
Expected: clean.

- [ ] **Step 9: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add backend/src/lib/readrankService.ts backend/src/lib/informBoundaryService.ts backend/src/lib/readrankService.test.ts docs/superpowers/plans/2026-06-19-hyperlocal-county-membership.md
git commit -m "feat(readrank): county-tier school + township races via overlap

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Out of scope
- Visual map frame for school/township (stays the state outline).
- Any frontend change (read-rank already tiers on `countyGeoIds`).
- A membership-only query optimization (we reuse `getCountyUnionFrames` and discard its geometry for these layers).
