# Hyper-local County Visual Frame (school + township) Implementation Plan

> TDD, single task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** School-district (`G5400/G5410/G5420`) and township (`G4040`) races should render their map motif framed by the **county union outline** (multi-county where applicable), instead of the whole-state outline — matching how state-legislative districts already render.

**Background:** A prior change ([ev-accounts PR #56](https://github.com/EmpoweredVote/ev-accounts/pull/56)) put these races in the read-rank county *tier* by running them through `getCountyUnionFrames` (which returns the union outline geometry + member county GEOIDs). At that time we used only the GEOIDs and left the visual `frameRef = stateRef`, discarding the geometry. This change uses that already-computed union geometry as the frame, eliminating the earlier tradeoff.

**Approach:** Broaden the `frameRef` state-leg branch to the existing `COUNTY_OVERLAP_LAYERS` set so school/township also get the `G4020U` union frame, falling back to the state outline when no county union resolves. `boundaryRef` (the child district polygon) is unchanged.

**No frontend change:** read-rank's motif already renders `G4020U` frames (with inline `bbox`/`geojson`) for state-leg districts; school/township will render through the identical path.

**Tech stack:** TypeScript, PostGIS, Vitest (mocked `pool.query` / `getCountyUnionFrames`).

---

## Task 1: Frame school + township to the county union

**Files:**
- Modify: `backend/src/lib/readrankService.ts`
- Test: `backend/src/lib/readrankService.test.ts`

Run from `/Users/chrisandrews/Documents/GitHub/ev-accounts/backend`.

- [ ] **Step 1: Write the failing tests**

In `backend/src/lib/readrankService.test.ts`, in the same `describe` block that holds the existing state-leg frame tests (search for `'state-leg district: frame = the county-union'`), add these two tests right after the state-leg fallback test:
```ts
  it('school district: frame = the county-union (computed geometry, embedded inline)', async () => {
    const unionGeom = { type: 'MultiPolygon' as const, coordinates: [[[[-86.6, 39.0], [-86.3, 39.0], [-86.3, 39.5], [-86.6, 39.0]]]] };
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'School Board', jurisdiction_level: 'local',
      boundary_layer: 'G5400', boundary_geoid: '1800001', frame_layer: null, frame_geoid: null,
    }] });
    mockGetCountyUnionFrames.mockResolvedValueOnce(new Map([
      ['G5400:1800001', { bbox: [-86.6, 39.0, -86.3, 39.5], geojson: unionGeom, countyGeoIds: ['18105'] }],
    ]));
    const [race] = await getPlayableRaces();
    expect(race.boundaryRef).toMatchObject({ layer: 'G5400', geoid: '1800001' });
    expect(race.frameRef).toEqual({
      layer: 'G4020U', geoid: '1800001', bbox: [-86.6, 39.0, -86.3, 39.5], geojson: unionGeom,
    });
  });

  it('township: falls back to the state frame when no county union is found', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'Township Trustee', jurisdiction_level: 'local',
      boundary_layer: 'G4040', boundary_geoid: '1899999', frame_layer: null, frame_geoid: null,
    }] });
    mockGetCountyUnionFrames.mockResolvedValueOnce(new Map()); // empty — no union
    const [race] = await getPlayableRaces();
    expect(race.frameRef).toEqual({ layer: 'G4000', geoid: '18' }); // IN state outline (BASE_ROW state)
  });
```

- [ ] **Step 2: Run the tests — expect FAIL**

Run: `npx vitest run src/lib/readrankService.test.ts`
Expected: the "school district: frame = the county-union" test FAILS (school currently frames to `stateRef`, i.e. `{ layer: 'G4000', geoid: '18' }`, not `G4020U`). The township fallback test passes already.

- [ ] **Step 3: Broaden the frameRef branch**

In `backend/src/lib/readrankService.ts`, find this branch:
```ts
    } else if (childLayer === 'G5210' || childLayer === 'G5220') {
      // State-leg district → union of overlapping counties (computed geometry,
      // embedded inline). Falls back to the state outline if the union is empty.
      const uf = r.boundary_geoid ? unionFrameMap.get(`${childLayer}:${r.boundary_geoid}`) : undefined;
      frameRef = uf
        ? { layer: 'G4020U', geoid: r.boundary_geoid as string, bbox: uf.bbox, geojson: uf.geojson }
        : stateRef;
    } else {
      frameRef = stateRef;                             // county / school → state
    }
```
Change the condition and the comments:
```ts
    } else if (COUNTY_OVERLAP_LAYERS.has(childLayer)) {
      // Sub-state district (state-leg / school / township) → union of overlapping
      // counties (computed geometry, embedded inline). Falls back to the state
      // outline if the union is empty.
      const uf = r.boundary_geoid ? unionFrameMap.get(`${childLayer}:${r.boundary_geoid}`) : undefined;
      frameRef = uf
        ? { layer: 'G4020U', geoid: r.boundary_geoid as string, bbox: uf.bbox, geojson: uf.geojson }
        : stateRef;
    } else {
      frameRef = stateRef;                             // county → state
    }
```
Do not change `boundaryRef` or any other branch. `COUNTY_OVERLAP_LAYERS` already exists in this file (added in the prior change) and already contains exactly `G5210/G5220/G5400/G5410/G5420/G4040`.

- [ ] **Step 4: Run the tests — expect PASS**

Run: `npx vitest run src/lib/readrankService.test.ts`
Expected: all pass, including both new tests and the two pre-existing state-leg frame tests (G5210/G5220 are still in the set, so their behavior is identical).

- [ ] **Step 5: Verify types**

Run: `npx tsc -b --noEmit` — clean.

- [ ] **Step 6: Commit**
```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git add backend/src/lib/readrankService.ts backend/src/lib/readrankService.test.ts docs/superpowers/plans/2026-06-19-hyperlocal-county-frame.md
git commit -m "feat(readrank): frame school + township races to the county union

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Out of scope
- Any frontend change (the motif already renders `G4020U` frames).
- County races (`G4020`) keep the state outline as their frame (unchanged).
