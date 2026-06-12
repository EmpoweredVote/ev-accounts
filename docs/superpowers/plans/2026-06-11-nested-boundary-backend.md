# Nested-Boundary Motif (Backend) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** The Read & Rank races API emits a `frameRef` (the parent boundary to nest each race's constituency inside), and overrides federal races to render their home state on the US frame.

**Architecture:** `getPlayableRaces` gains a `frameRef` field. Deterministic parents (state via FIPS, nation `US`, or none) are computed in TS; sub-county parents (city→county, ward→city) are resolved by a PostGIS `ST_Contains` LATERAL that returns `frame_layer`/`frame_geoid`. The `/api/inform/boundary` endpoint is unchanged — the frame is just another ref the frontend fetches. Tested with a mocked `pg` pool (repo convention); the SQL containment is verified by a live read-only smoke.

**Tech Stack:** Node + TypeScript, Express, `pg` (raw SQL), Vitest (mocked pool), PostGIS. Repo: `ev-accounts`, branch `feat/nested-boundary-backend`. Paths below are relative to `backend/`.

**Spec:** read-rank repo, `docs/superpowers/specs/2026-06-11-nested-boundary-motif-design.md`.

---

## Grounding facts (verified)

- `getPlayableRaces` (`src/lib/readrankService.ts`) already LEFT JOINs `essentials.offices o` → `essentials.districts d` for the child boundary (`d.mtfcc`, `COALESCE(d.geo_id, d.tiger_geoid)`), and emits `boundaryRef`/`tier`/`scope`/counts. `USPS_TO_FIPS` and `deriveTierScope` already exist in the file.
- Frame parents: federal → US (`{G4000,'US'}`, child overridden to home state); statewide state → none; county/state-leg/school → state (`{G4000, FIPS}`); city `G4110` → county `G4020` (spatial); ward `X…` → city `G4110` (spatial).
- `essentials.geofence_boundaries` holds all these geometries keyed by `(mtfcc, geo_id)`. State outlines (`G4000`) + the `US` row are present (shipped). Tests mock `./db.js` + `./env.js` (see `src/lib/readrankService.test.ts`).
- The baseline full test suite has pre-existing integration failures — gate on the specific test file + `npm run typecheck`, not `npm test`.

---

## Task 1: `frameRef` resolution in `getPlayableRaces`

**Files:**
- Modify: `src/lib/readrankService.ts` (`RaceSummary` interface; the `getPlayableRaces` query + mapping)
- Test: `src/lib/readrankService.test.ts` (add `frameRef` cases)

- [ ] **Step 1: Add the test cases**

Append these tests inside the existing `describe('getPlayableRaces', ...)` block in `src/lib/readrankService.test.ts` (the file already mocks `./db.js` and `./env.js`):

```ts
  it('federal: child = home state, frame = US (model B)', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rf', position_name: 'U.S. House',
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'federal', state: 'IN',
      boundary_layer: 'G5200', boundary_geoid: '1807',
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.tier).toBe('federal');
    expect(race.boundaryRef).toEqual({ layer: 'G4000', geoid: '18' }); // home state
    expect(race.frameRef).toEqual({ layer: 'G4000', geoid: 'US' });
  });

  it('statewide state (Governor): frame = null (state alone)', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rg', position_name: 'Governor',
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: null, boundary_geoid: null, frame_layer: null, frame_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.boundaryRef).toEqual({ layer: 'G4000', geoid: '18' });
    expect(race.frameRef).toBeNull();
  });

  it('county: frame = state', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rc', position_name: 'County Commission',
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'county', state: 'IN',
      boundary_layer: 'G4020', boundary_geoid: '18105', frame_layer: null, frame_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.boundaryRef).toEqual({ layer: 'G4020', geoid: '18105' });
    expect(race.frameRef).toEqual({ layer: 'G4000', geoid: '18' });
  });

  it('city: frame = the SQL-resolved container county', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rcity', position_name: 'Mayor',
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'city', state: 'IN',
      boundary_layer: 'G4110', boundary_geoid: '1805860',
      frame_layer: 'G4020', frame_geoid: '18105',
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.boundaryRef).toEqual({ layer: 'G4110', geoid: '1805860' });
    expect(race.frameRef).toEqual({ layer: 'G4020', geoid: '18105' });
  });

  it('ward: frame = the SQL-resolved container city', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rw', position_name: 'City Common Council',
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'city', state: 'IN',
      boundary_layer: 'X0001', boundary_geoid: '180586000001',
      frame_layer: 'G4110', frame_geoid: '1805860',
      candidate_count: '2', topic_count: '2', quote_count: '6', rankable_topic_count: '2',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.frameRef).toEqual({ layer: 'G4110', geoid: '1805860' });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run src/lib/readrankService.test.ts`
Expected: FAIL — `frameRef` is undefined on the results.

- [ ] **Step 3: Add `frameRef` to the `RaceSummary` interface**

In `src/lib/readrankService.ts`, inside `RaceSummary`, after `boundaryRef: { layer: string; geoid: string } | null;`:

```ts
  frameRef: { layer: string; geoid: string } | null;
```

- [ ] **Step 4: Update the query (child-geom join + container LATERAL)**

In the `getPlayableRaces` SQL: add `frame_layer`/`frame_geoid` to the row type and the SELECT, add the two joins before `GROUP BY`, and extend `GROUP BY`.

Add to the `pool.query<{...}>` row type (next to `boundary_geoid`):
```ts
    frame_layer: string | null; frame_geoid: string | null;
```

In the SELECT list, after the `COALESCE(d.geo_id, d.tiger_geoid) AS boundary_geoid,` line:
```sql
           frame.frame_layer, frame.frame_geoid,
```

After the existing `LEFT JOIN essentials.districts d ON d.id = o.district_id` line, add:
```sql
    LEFT JOIN essentials.geofence_boundaries cb
      ON cb.mtfcc = d.mtfcc AND cb.geo_id = COALESCE(d.geo_id, d.tiger_geoid)
    LEFT JOIN LATERAL (
      SELECT fp.mtfcc AS frame_layer, fp.geo_id AS frame_geoid
      FROM essentials.geofence_boundaries fp
      WHERE fp.mtfcc = CASE WHEN d.mtfcc = 'G4110' THEN 'G4020'
                            WHEN d.mtfcc LIKE 'X%'  THEN 'G4110' END
        AND ST_Contains(fp.geometry, ST_PointOnSurface(cb.geometry))
      ORDER BY ST_Area(fp.geometry) ASC
      LIMIT 1
    ) frame ON (d.mtfcc = 'G4110' OR d.mtfcc LIKE 'X%')
```

Extend the `GROUP BY` line to include the frame columns:
```sql
    GROUP BY r.id, r.position_name, e.id, e.name, e.election_date, e.jurisdiction_level, e.state,
             d.mtfcc, COALESCE(d.geo_id, d.tiger_geoid), frame.frame_layer, frame.frame_geoid
```

- [ ] **Step 5: Update the mapping**

Replace the `return rows.map((r) => { ... })` body's computation of `boundaryRef` (and add `frameRef`). Replace from `const { tier, scope } = deriveTierScope({...})` through the returned object with:

```ts
  const localSet = new Set(politicianIds ?? []);
  return rows.map((r) => {
    const { tier, scope } = deriveTierScope({
      jurisdiction_level: r.jurisdiction_level,
      position_name: r.position_name,
      mtfcc: r.boundary_layer,
    });
    const fips = r.state ? USPS_TO_FIPS[r.state] : undefined;
    const stateRef = fips ? { layer: 'G4000', geoid: fips } : null;
    const childLayer = r.boundary_layer ?? '';

    // Child boundary: the office's specific district, or the whole-state outline
    // for statewide offices. Federal offices are overridden below to the state.
    let boundaryRef = r.boundary_layer && r.boundary_geoid
      ? { layer: r.boundary_layer, geoid: r.boundary_geoid }
      : (scope === 'statewide' ? stateRef : null);

    // Frame (parent to nest the child inside).
    let frameRef: { layer: string; geoid: string } | null;
    if (tier === 'federal') {
      boundaryRef = stateRef;                          // model B: federal child = home state
      frameRef = { layer: 'G4000', geoid: 'US' };
    } else if (scope === 'statewide') {
      frameRef = null;                                 // Governor: state alone
    } else if (childLayer === 'G4110' || childLayer.startsWith('X')) {
      frameRef = r.frame_layer && r.frame_geoid        // city→county / ward→city (SQL containment)
        ? { layer: r.frame_layer, geoid: r.frame_geoid }
        : null;
    } else {
      frameRef = stateRef;                             // county / state-leg / school → state
    }

    return {
      raceId: r.race_id,
      positionName: r.position_name,
      electionName: r.election_name,
      electionDate: r.election_date ? new Date(r.election_date).toISOString().slice(0, 10) : null,
      state: r.state,
      jurisdictionLevel: r.jurisdiction_level,
      candidateCount: Number(r.candidate_count),
      topicCount: Number(r.topic_count),
      quoteCount: Number(r.quote_count),
      rankableTopicCount: Number(r.rankable_topic_count),
      tier,
      scope,
      boundaryRef,
      frameRef,
      isLocal: localSet.size > 0 && (r.politician_ids ?? []).some((id) => localSet.has(id)),
    };
  });
```

- [ ] **Step 6: Run test to verify it passes**

Run: `npx vitest run src/lib/readrankService.test.ts`
Expected: PASS (all existing + 5 new `frameRef` cases).

- [ ] **Step 7: Typecheck + commit**

Run: `npm run typecheck`
Expected: clean.

```bash
git add src/lib/readrankService.ts src/lib/readrankService.test.ts
git commit -m "feat(readrank): emit frameRef (parent boundary) + federal home-state override"
```

---

## Task 2: Verification + live smoke

**Files:** none.

- [ ] **Step 1: Targeted tests + typecheck**

Run: `npx vitest run src/lib/readrankService.test.ts && npm run typecheck`
Expected: pass / clean. (Do not gate on `npm test`; baseline integration tests fail pre-existing.)

- [ ] **Step 2: Document a live read-only smoke (do NOT mutate)**

Record in the PR. Confirms the LATERAL resolves real containers on prod:

```sql
-- City → county containment (Bloomington city should resolve Monroe County):
SELECT child.name AS city,
       (SELECT p.name FROM essentials.geofence_boundaries p
        WHERE p.mtfcc='G4020' AND ST_Contains(p.geometry, ST_PointOnSurface(child.geometry))
        ORDER BY ST_Area(p.geometry) ASC LIMIT 1) AS county
FROM essentials.geofence_boundaries child
WHERE child.mtfcc='G4110' AND child.geo_id='1805860';

-- Ward → city containment (a Bloomington council district should resolve Bloomington city):
SELECT child.name AS ward,
       (SELECT p.name FROM essentials.geofence_boundaries p
        WHERE p.mtfcc='G4110' AND ST_Contains(p.geometry, ST_PointOnSurface(child.geometry))
        ORDER BY ST_Area(p.geometry) ASC LIMIT 1) AS city
FROM essentials.geofence_boundaries child
WHERE child.mtfcc LIKE 'X%' AND child.name ILIKE '%bloomington%' LIMIT 1;
```

- [ ] **Step 3: Commit any fixes**

```bash
git add -A && git commit -m "chore(readrank): verification fixes for frameRef" || echo "nothing to commit"
```

---

## Self-Review notes
- **Spec coverage:** `frameRef` field (T1, spec §3.1), per-tier resolution incl. federal child override (T1 mapping), spatial containment for city/ward (T1 SQL LATERAL), endpoint unchanged (no endpoint task).
- **Frontend contract:** `frameRef` is `{ layer, geoid } | null` — matches the read-rank `RaceSummary.frameRef` added in the frontend plan.
- **Safety:** all executed steps are pure code (mocked pool); no prod writes. The live smoke is read-only.
- **Cardinality:** `cb` (child geom) and `frame` (LATERAL) are 1:1 with the race's single office/district, so the GROUP BY aggregates are unaffected; `frame_layer`/`frame_geoid` are added to GROUP BY as required.
