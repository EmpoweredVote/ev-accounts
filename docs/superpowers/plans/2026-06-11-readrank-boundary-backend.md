# Read & Rank Boundary API (Backend) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Serve constituency boundary geometry to the Read & Rank `RaceCard` motif, and enrich the races API with the fields it needs (`boundaryRef`, `quoteCount`, `rankableTopicCount`, `tier`, `scope`), so the frontend's dot-fields become real maps for every race whose boundary already exists in the database.

**Architecture:** A new `GET /api/inform/boundary` endpoint backed by `informBoundaryService.getBoundary(layer, geoid)`, which runs a PostGIS `ST_SimplifyPreserveTopology` + `ST_AsGeoJSON` query against `essentials.geofence_boundaries` (keyed by `mtfcc` + `geo_id`). `getPlayableRaces` gains a `LEFT JOIN essentials.offices → essentials.districts` to emit a `boundaryRef`, plus quote/rankable-topic counts and derived tier/scope. All logic is unit-tested with a mocked `pg` pool (the repo's established pattern). State + nation outlines are a separate, user-applied data migration (writes to prod — NOT run by automation).

**Tech Stack:** Node + TypeScript, Express, `pg` (raw SQL via `pool`), Zod, Vitest (mocked pool). PostGIS in prod (`essentials.geofence_boundaries`, SRID 4326).

**Workspace:** `/Users/chrisandrews/Documents/GitHub/ev-accounts-plan2` (git worktree, branch `feat/readrank-boundary-api`, off clean `origin/master`). All paths below are relative to the `backend/` subdir of that worktree.

**Design spec:** `read-rank` repo, `docs/superpowers/specs/2026-06-11-landing-race-card-redesign-design.md`.

---

## Grounding facts (verified against prod DB)

- Geometry table: `essentials.geofence_boundaries(geo_id, ocd_id, name, state, mtfcc, geometry, ...)`, PostGIS `geometry` SRID 4326. Keyed by `(mtfcc, geo_id)`. Covers cities (`G4110`), counties (`G4020`), townships (`G4040`), congressional (`G5200`), state-leg (`G5210`/`G5220`), school (`G54xx`), custom council/supervisorial (`X0001`/`X-MCC-DIST`). State outlines (`G4000`) = California only today; no US/nation outline.
- Race → boundary join: `essentials.races.office_id` → `essentials.offices.district_id` → `essentials.districts(mtfcc, geo_id, tiger_geoid)` → matches `geofence_boundaries(mtfcc, geo_id)`. Verified end-to-end for "Los Angeles Mayor" (`geo_id 0644000`, `mtfcc G4110`). `office_id` / `district_id` may be null → no boundaryRef → frontend dot-field.
- Service pattern: raw `pool.query` in `src/lib/*Service.ts`; tests `vi.mock('./db.js', () => ({ pool: { query: mockQuery } }))` and assert mapping from mocked rows.
- Routers: `src/routes/*.ts` (Express `Router`), mounted in `src/index.ts`. `readrank` is at `index.ts:148` (`app.use('/api/readrank', readrankRouter)`).

---

## File Structure

- Create `src/lib/informBoundaryService.ts` — `getBoundary(layer, geoid)` PostGIS query + shaping.
- Create `src/lib/informBoundaryService.test.ts` — mocked-pool unit tests.
- Create `src/routes/inform.ts` — `GET /boundary` route (Zod-validated query).
- Modify `src/index.ts` — import + mount `informRouter` at `/api/inform` next to readrank.
- Modify `src/lib/readrankService.ts` — extend `RaceSummary` + `getPlayableRaces` (boundaryRef, quoteCount, rankableTopicCount, tier, scope) + add a pure `deriveTierScope` helper.
- Create/Modify `src/lib/readrankService.test.ts` — mocked-pool test for the new mapping (create if absent).
- Docs-only (user-applied, NOT executed here): `../supabase/migrations/<ts>_289_readrank_state_nation_outlines.sql` + `scripts/_apply-migration-289.ts`.

Commands (run from `backend/`): tests `npx vitest run <path>`; full `npm test`; `npm run typecheck`; `npm run lint`.

---

## Task 0: Worktree setup

**Files:** none (environment).

- [ ] **Step 1: Install dependencies in the worktree**

The worktree has no `node_modules`. From `/Users/chrisandrews/Documents/GitHub/ev-accounts-plan2/backend`:

Run: `npm install`
Expected: completes; `npx vitest --version` prints a version.

- [ ] **Step 2: Confirm the baseline suite runs**

Run: `npm test`
Expected: the existing suite passes (record the count). If env validation blocks import, note it — existing service tests mock `./db.js` and pass, so the pattern is known-good.

---

## Task 1: `getBoundary` service

**Files:**
- Create: `src/lib/informBoundaryService.ts`
- Test: `src/lib/informBoundaryService.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// src/lib/informBoundaryService.test.ts
import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { getBoundary } from './informBoundaryService.js';

beforeEach(() => mockQuery.mockReset());

describe('getBoundary', () => {
  it('returns hasBoundary:false when no row matches', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    const out = await getBoundary('G4110', '9999999');
    expect(out).toEqual({ hasBoundary: false });
  });

  it('shapes a simplified boundary row into the API contract', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      geo_id: '0644000', mtfcc: 'G4110', name: 'Los Angeles city',
      minx: -118.6, miny: 33.7, maxx: -118.1, maxy: 34.3,
      geojson: '{"type":"MultiPolygon","coordinates":[[[[-118.2,34.0],[-118.1,34.0],[-118.1,34.1],[-118.2,34.0]]]]}',
    }] });
    const out = await getBoundary('G4110', '0644000');
    expect(out).toEqual({
      hasBoundary: true,
      layer: 'G4110',
      geoid: '0644000',
      name: 'Los Angeles city',
      bbox: [-118.6, 33.7, -118.1, 34.3],
      geojson: { type: 'MultiPolygon', coordinates: [[[[-118.2, 34.0], [-118.1, 34.0], [-118.1, 34.1], [-118.2, 34.0]]]] },
    });
    // Parameterized query: mtfcc + geo_id passed as params, never interpolated.
    const [, params] = mockQuery.mock.calls[0];
    expect(params).toEqual(['G4110', '0644000']);
  });

  it('returns hasBoundary:false when the geometry is null', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      geo_id: '0644000', mtfcc: 'G4110', name: 'x',
      minx: null, miny: null, maxx: null, maxy: null, geojson: null,
    }] });
    expect(await getBoundary('G4110', '0644000')).toEqual({ hasBoundary: false });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run src/lib/informBoundaryService.test.ts`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement**

```ts
// src/lib/informBoundaryService.ts
import { pool } from './db.js';

export interface BoundaryResult {
  hasBoundary: true;
  layer: string;
  geoid: string;
  name: string;
  bbox: [number, number, number, number];
  geojson: { type: 'Polygon' | 'MultiPolygon'; coordinates: unknown };
}
export type BoundaryResponse = BoundaryResult | { hasBoundary: false };

/**
 * Simplified constituency geometry for the Read & Rank motif, keyed by TIGER
 * MTFCC + geo_id. Returns { hasBoundary: false } when absent so the frontend
 * falls back to the dot-field. Tolerance ~0.001 deg suits a ~64px render.
 */
export async function getBoundary(layer: string, geoid: string): Promise<BoundaryResponse> {
  const { rows } = await pool.query<{
    geo_id: string; mtfcc: string; name: string | null;
    minx: number | null; miny: number | null; maxx: number | null; maxy: number | null;
    geojson: string | null;
  }>(
    `SELECT geo_id, mtfcc, name,
            ST_XMin(ST_Envelope(geometry)) AS minx, ST_YMin(ST_Envelope(geometry)) AS miny,
            ST_XMax(ST_Envelope(geometry)) AS maxx, ST_YMax(ST_Envelope(geometry)) AS maxy,
            ST_AsGeoJSON(ST_SimplifyPreserveTopology(geometry, 0.001)) AS geojson
     FROM essentials.geofence_boundaries
     WHERE mtfcc = $1 AND geo_id = $2
     LIMIT 1`,
    [layer, geoid],
  );

  const row = rows[0];
  if (!row || !row.geojson || row.minx == null) return { hasBoundary: false };

  return {
    hasBoundary: true,
    layer: row.mtfcc,
    geoid: row.geo_id,
    name: row.name ?? '',
    bbox: [Number(row.minx), Number(row.miny), Number(row.maxx), Number(row.maxy)],
    geojson: JSON.parse(row.geojson),
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run src/lib/informBoundaryService.test.ts`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add src/lib/informBoundaryService.ts src/lib/informBoundaryService.test.ts
git commit -m "feat(inform): getBoundary service — simplified geofence geometry by mtfcc+geo_id"
```

---

## Task 2: `GET /api/inform/boundary` route

**Files:**
- Create: `src/routes/inform.ts`
- Test: `src/routes/inform.test.ts`
- Modify: `src/index.ts` (import + mount)

- [ ] **Step 1: Write the failing test**

```ts
// src/routes/inform.test.ts
import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockGetBoundary } = vi.hoisted(() => ({ mockGetBoundary: vi.fn() }));
vi.mock('../lib/informBoundaryService.js', () => ({ getBoundary: mockGetBoundary }));

import informRouter from './inform.js';

const app = express();
app.use('/api/inform', informRouter);

beforeEach(() => mockGetBoundary.mockReset());

describe('GET /api/inform/boundary', () => {
  it('422 when layer or geoid is missing', async () => {
    const res = await request(app).get('/api/inform/boundary?layer=G4110');
    expect(res.status).toBe(422);
    expect(mockGetBoundary).not.toHaveBeenCalled();
  });

  it('200 with the boundary payload', async () => {
    mockGetBoundary.mockResolvedValueOnce({ hasBoundary: true, layer: 'G4110', geoid: '0644000', name: 'Los Angeles city', bbox: [0, 0, 1, 1], geojson: { type: 'Polygon', coordinates: [] } });
    const res = await request(app).get('/api/inform/boundary?layer=G4110&geoid=0644000');
    expect(res.status).toBe(200);
    expect(res.body.name).toBe('Los Angeles city');
    expect(mockGetBoundary).toHaveBeenCalledWith('G4110', '0644000');
  });

  it('200 with hasBoundary:false when absent (not an error)', async () => {
    mockGetBoundary.mockResolvedValueOnce({ hasBoundary: false });
    const res = await request(app).get('/api/inform/boundary?layer=G4110&geoid=zzz');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ hasBoundary: false });
  });
});
```

If `supertest` is not already a dev dependency, install it: `npm install -D supertest @types/supertest` (check `package.json` first; many Express repos already have it).

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run src/routes/inform.test.ts`
Expected: FAIL — `./inform.js` not found.

- [ ] **Step 3: Implement the route**

```ts
// src/routes/inform.ts
import { Router } from 'express';
import type { Request, Response } from 'express';
import { z } from 'zod';
import { getBoundary } from '../lib/informBoundaryService.js';

/**
 * Inform pillar — geographic boundary geometry for the Read & Rank motif.
 * Mounted at /api/inform in index.ts. Public (the app uses plain fetch).
 */
const router = Router();

const querySchema = z.object({
  layer: z.string().min(1).max(32),
  geoid: z.string().min(1).max(32),
});

// GET /api/inform/boundary?layer=<mtfcc>&geoid=<geo_id>
router.get('/boundary', async (req: Request, res: Response): Promise<void> => {
  const parsed = querySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'layer and geoid are required' });
    return;
  }
  try {
    const result = await getBoundary(parsed.data.layer, parsed.data.geoid);
    res.status(200).json(result);
  } catch (err) {
    console.error('[GET /inform/boundary] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run src/routes/inform.test.ts`
Expected: PASS (3 tests).

- [ ] **Step 5: Mount the router**

In `src/index.ts`, add the import alongside the other route imports (near line 35, by `readrankRouter`):

```ts
import informRouter from './routes/inform.js';
```

And mount it next to readrank (near line 148):

```ts
app.use('/api/inform', informRouter);
```

- [ ] **Step 6: Verify it compiles and the suite is green**

Run: `npm run typecheck`
Expected: no errors.
Run: `npx vitest run src/routes/inform.test.ts src/lib/informBoundaryService.test.ts`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/routes/inform.ts src/routes/inform.test.ts src/index.ts
git commit -m "feat(inform): GET /api/inform/boundary route + mount"
```

---

## Task 3: Enrich `getPlayableRaces` (boundaryRef, counts, tier/scope)

**Files:**
- Modify: `src/lib/readrankService.ts` (the `RaceSummary` interface + `getPlayableRaces` + a new `deriveTierScope` helper)
- Test: `src/lib/readrankService.test.ts` (create)

- [ ] **Step 1: Write the failing test**

```ts
// src/lib/readrankService.test.ts
import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { getPlayableRaces, deriveTierScope } from './readrankService.js';

beforeEach(() => mockQuery.mockReset());

describe('deriveTierScope', () => {
  it('uses mtfcc when present: G4110 -> local/citywide', () => {
    expect(deriveTierScope({ jurisdiction_level: 'county', position_name: 'Mayor', mtfcc: 'G4110' }))
      .toEqual({ tier: 'local', scope: 'citywide' });
  });
  it('G5200 -> federal/district', () => {
    expect(deriveTierScope({ jurisdiction_level: 'federal', position_name: 'U.S. House', mtfcc: 'G5200' }))
      .toEqual({ tier: 'federal', scope: 'district' });
  });
  it('G4020 -> local/county', () => {
    expect(deriveTierScope({ jurisdiction_level: 'county', position_name: 'County Commission', mtfcc: 'G4020' }))
      .toEqual({ tier: 'local', scope: 'county' });
  });
  it('falls back to jurisdiction_level + name when mtfcc absent: Governor -> state/statewide', () => {
    expect(deriveTierScope({ jurisdiction_level: 'state', position_name: 'Governor', mtfcc: null }))
      .toEqual({ tier: 'state', scope: 'statewide' });
  });
});

describe('getPlayableRaces', () => {
  it('maps boundaryRef, counts and tier/scope from a joined row', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r1', position_name: 'Mayor',
      election_id: 'e1', election_name: 'LA 2026', election_date: new Date('2026-11-03T00:00:00Z'),
      jurisdiction_level: 'county', state: 'CA',
      boundary_layer: 'G4110', boundary_geoid: '0644000',
      candidate_count: '3', topic_count: '5', quote_count: '24', rankable_topic_count: '4',
      politician_ids: ['p1', 'p2', 'p3'],
    }] });

    const [race] = await getPlayableRaces();
    expect(race).toMatchObject({
      raceId: 'r1', positionName: 'Mayor', state: 'CA',
      candidateCount: 3, topicCount: 5, quoteCount: 24, rankableTopicCount: 4,
      tier: 'local', scope: 'citywide',
      boundaryRef: { layer: 'G4110', geoid: '0644000' },
    });
  });

  it('emits boundaryRef:null when the race has no resolvable district', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r2', position_name: 'Governor',
      election_id: 'e2', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: null, boundary_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.boundaryRef).toBeNull();
    expect(race).toMatchObject({ tier: 'state', scope: 'statewide' });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run src/lib/readrankService.test.ts`
Expected: FAIL — `deriveTierScope` not exported / new fields absent.

- [ ] **Step 3: Implement**

In `src/lib/readrankService.ts`, extend the `RaceSummary` interface (add after `isLocal: boolean;`):

```ts
  quoteCount: number;
  rankableTopicCount: number;
  tier: 'federal' | 'state' | 'local';
  scope: 'statewide' | 'district' | 'county' | 'citywide';
  boundaryRef: { layer: string; geoid: string } | null;
```

Add this exported pure helper (above `getPlayableRaces`):

```ts
type Tier = 'federal' | 'state' | 'local';
type Scope = 'statewide' | 'district' | 'county' | 'citywide';

const MTFCC_SCOPE: Record<string, Scope> = {
  G4000: 'statewide', // whole state
  G4020: 'county',
  G4040: 'district',  // county subdivision / township
  G4110: 'citywide',  // incorporated place
  G5200: 'district',  // congressional
  G5210: 'district',  // state senate
  G5220: 'district',  // state house / assembly / ward
};

/** Tier from jurisdiction_level; scope prefers the mtfcc geometry class, else position name. */
export function deriveTierScope(input: {
  jurisdiction_level: string | null;
  position_name: string;
  mtfcc: string | null;
}): { tier: Tier; scope: Scope } {
  const jl = (input.jurisdiction_level ?? '').toLowerCase();
  const tier: Tier = /fed|congress|national/.test(jl)
    ? 'federal'
    : jl === 'state'
      ? 'state'
      : 'local';

  let scope: Scope | undefined = input.mtfcc ? MTFCC_SCOPE[input.mtfcc] : undefined;
  if (input.mtfcc && input.mtfcc.startsWith('X')) scope = 'district'; // custom council/ward layers
  if (!scope) {
    const n = input.position_name.toLowerCase();
    if (/county commission|board of supervisors|county council|sheriff|\bcounty\b/.test(n)) scope = 'county';
    else if (/mayor|city of /.test(n)) scope = 'citywide';
    else if (/council|ward|\bdistrict\b|house|assembly|representative|senate district/.test(n)) scope = 'district';
    else scope = tier === 'local' ? 'citywide' : 'statewide';
  }
  return { tier, scope };
}
```

Replace the `getPlayableRaces` query + mapping. New SQL adds the office/district join, quote count, rankable-topic subquery, and boundary columns:

```ts
export async function getPlayableRaces(politicianIds?: string[]): Promise<RaceSummary[]> {
  const { rows } = await pool.query<{
    race_id: string; position_name: string; election_id: string; election_name: string;
    election_date: Date | null; jurisdiction_level: string | null; state: string | null;
    boundary_layer: string | null; boundary_geoid: string | null;
    candidate_count: string; topic_count: string; quote_count: string; rankable_topic_count: string;
    politician_ids: string[];
  }>(`
    SELECT r.id AS race_id, r.position_name,
           e.id AS election_id, e.name AS election_name, e.election_date,
           e.jurisdiction_level, e.state,
           d.mtfcc AS boundary_layer,
           COALESCE(d.geo_id, d.tiger_geoid) AS boundary_geoid,
           COUNT(DISTINCT rc.politician_id)   AS candidate_count,
           COUNT(DISTINCT lower(q.topic_key)) AS topic_count,
           COUNT(q.id)                        AS quote_count,
           (
             SELECT COUNT(*) FROM (
               SELECT lower(q2.topic_key) AS tk
               FROM essentials.race_candidates rc2
               JOIN essentials.quotes q2
                 ON q2.politician_id = rc2.politician_id
                AND q2.deidentified_text IS NOT NULL AND q2.readrank_selected = true
               JOIN inform.compass_topics ct2
                 ON ct2.topic_key = lower(q2.topic_key) AND ct2.is_live = true
               WHERE rc2.race_id = r.id
                 AND COALESCE(rc2.candidate_status, 'active') <> 'withdrawn'
               GROUP BY lower(q2.topic_key)
               HAVING COUNT(DISTINCT rc2.politician_id) >= 2
             ) rankable
           )                                  AS rankable_topic_count,
           array_agg(DISTINCT rc.politician_id) AS politician_ids
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.race_candidates rc
      ON rc.race_id = r.id
     AND rc.politician_id IS NOT NULL
     AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
    JOIN essentials.quotes q
      ON q.politician_id = rc.politician_id
     AND q.deidentified_text IS NOT NULL
     AND q.readrank_selected = true
    JOIN inform.compass_topics ct
      ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
    LEFT JOIN essentials.offices o ON o.id = r.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    GROUP BY r.id, r.position_name, e.id, e.name, e.election_date, e.jurisdiction_level, e.state,
             d.mtfcc, COALESCE(d.geo_id, d.tiger_geoid)
    HAVING COUNT(DISTINCT rc.politician_id) >= 2
    ORDER BY e.election_date ASC NULLS LAST
  `);

  const localSet = new Set(politicianIds ?? []);
  return rows.map((r) => {
    const { tier, scope } = deriveTierScope({
      jurisdiction_level: r.jurisdiction_level,
      position_name: r.position_name,
      mtfcc: r.boundary_layer,
    });
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
      boundaryRef: r.boundary_layer && r.boundary_geoid
        ? { layer: r.boundary_layer, geoid: r.boundary_geoid }
        : null,
      isLocal: localSet.size > 0 && (r.politician_ids ?? []).some((id) => localSet.has(id)),
    };
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run src/lib/readrankService.test.ts`
Expected: PASS (6 tests).

- [ ] **Step 5: Run the full suite + typecheck**

Run: `npm test` then `npm run typecheck`
Expected: all green (the reveal/quotes services are untouched).

- [ ] **Step 6: Commit**

```bash
git add src/lib/readrankService.ts src/lib/readrankService.test.ts
git commit -m "feat(readrank): races API emits boundaryRef, quote/rankable-topic counts, tier/scope"
```

---

## Task 4: Verification + live smoke (read-only)

**Files:** none.

- [ ] **Step 1: Full suite, typecheck, lint, build**

Run: `npm test && npm run typecheck && npm run lint && npm run build`
Expected: all succeed. Fix only issues this branch introduced.

- [ ] **Step 2: Document a manual live smoke (do NOT run automatically)**

These are read-only checks the maintainer can run against prod to confirm the SQL behaves (the unit tests only cover mapping, since the pool is mocked). Record them in the PR description:

```sql
-- Playable races now carry a boundaryRef where the office resolves a district:
SELECT r.id, r.position_name, d.mtfcc, COALESCE(d.geo_id, d.tiger_geoid) AS geoid
FROM essentials.races r
LEFT JOIN essentials.offices o ON o.id = r.office_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE r.office_id IS NOT NULL
LIMIT 10;

-- The endpoint's underlying query returns geometry for a known place (LA city):
SELECT geo_id, mtfcc, name, ST_NPoints(ST_SimplifyPreserveTopology(geometry, 0.001)) AS pts
FROM essentials.geofence_boundaries
WHERE mtfcc = 'G4110' AND geo_id = '0644000';
```

- [ ] **Step 3: Commit any verification fixes**

```bash
git add -A && git commit -m "chore(inform): verification fixes" || echo "nothing to commit"
```

---

## Task 5 (USER-APPLIED, NOT executed by automation): state + nation outline ingest

**This task writes to the production database and requires sourcing external geometry. Do NOT run it via a subagent or unattended. It is written here so the maintainer can apply it deliberately.**

Goal: add the ~49 missing `G4000` state outlines (keyed by state FIPS) + one US/nation outline to `essentials.geofence_boundaries`, so statewide (Governor) and federal-statewide (U.S. Senate) races resolve a boundary. After it lands, extend the boundaryRef resolution so statewide races without a district fall back to the state-FIPS / nation row.

- [ ] **Step 1: Source simplified geometry**

Obtain a simplified US states + nation GeoJSON (Census TIGER `cb_2023_us_state_500k` + `cb_2018_us_nation_5m`, or Natural Earth admin-1/0), in EPSG:4326, with each feature carrying `STATEFP` (FIPS) and `NAME`. Save to `backend/data/geo/us_states.geojson` and `backend/data/geo/us_nation.geojson` in the worktree.

- [ ] **Step 2: Write the ingest script** (`backend/scripts/_apply-migration-289.ts`, mirroring the existing `_apply-migration-*.ts` shape)

For each state feature, upsert into `essentials.geofence_boundaries` with `mtfcc='G4000'`, `geo_id=STATEFP`, `name=NAME`, `state=<2-letter>`, `geometry=ST_SetSRID(ST_GeomFromGeoJSON($geom),4326)`, `source='tiger_cb_2023'`. For the nation, use `mtfcc='G4000'`, `geo_id='US'`, `name='United States'`. Use `INSERT ... ON CONFLICT` guarded by a uniqueness check on `(mtfcc, geo_id)` (add the constraint/index in the migration if absent). Include a smoke check: `SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE mtfcc='G4000'` (expect ~51).

- [ ] **Step 3: Extend statewide boundaryRef resolution** (`readrankService.ts`)

After the ingest exists, add a fallback in the `getPlayableRaces` mapping: when `boundaryRef` is null and `scope === 'statewide'`, set `boundaryRef = { layer: 'G4000', geoid: tier === 'federal' ? 'US' : fipsForState(r.state) }`, using a 2-letter→FIPS map. Add a unit test for this branch. (Kept out of Task 3 so the no-prod-write code can ship first.)

- [ ] **Step 4: Apply to prod deliberately** — run the script against `DATABASE_URL`, verify the smoke count, and confirm a statewide race now returns geometry via `GET /api/inform/boundary?layer=G4000&geoid=<fips>`.

---

## Self-Review notes
- **Spec coverage:** boundary endpoint (T1/T2), races-API `boundaryRef`/`quoteCount`/`rankableTopicCount`/`tier`/`scope` (T3), graceful `hasBoundary:false` → frontend dot-field (T1), MTFCC-driven scope + jurisdiction-driven tier (T3), state/nation ingest as a deliberate user-applied step (T5).
- **Frontend contract match:** `fetchBoundary` (read-rank) expects `{ geoid, layer, name, bbox, geojson, hasBoundary }` or `hasBoundary:false`; T1 returns exactly that. `RaceSummary.boundaryRef` is `{ layer, geoid } | null`; T3 emits exactly that. `tier`/`scope` string unions match the frontend's `RaceTier`/`RaceScope`.
- **Safety:** all executed tasks (0-4) are pure code with a mocked pool — no DB writes. The only prod mutation (T5) is explicitly user-applied. Queries are parameterized (no SQL injection via `layer`/`geoid`).
- **Deferred:** statewide boundaryRef fallback depends on T5's ingest, so it ships with T5, not T3.
