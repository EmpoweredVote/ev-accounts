# Read & Rank: Coverage Grid (Plan 3) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An admin "coverage grid" at `/admin/readrank-coverage` — rows = a race's Read & Rank questions, columns = its candidates, cells colored by quote state (live / draft / none) — so a curator can see at a glance which questions are rankable, which are one candidate away, and which candidates are under-covered.

**Architecture:** Backend adds a `readrankCoverageService` that composes the existing `listRaceQuestions` (rows + rankable/surfaced) with a new `listRaceCandidates` (columns) and a per-(question×candidate) cell query, plus a small race search for the picker; exposed via a new admin router `/api/admin/readrank-coverage`. Frontend adds a React page that picks a race and renders the grid, with cell coloring + per-question row status computed in a **pure, unit-tested** helper (the component itself follows the repo's "render vs. logic split" so it needs no jsdom/RTL). All read-only — no mutations, no schema changes.

**Tech Stack:** Backend TS/ESM, node-postgres (`import { pool } from './db.js'`), Express + Zod, Vitest (pool mocked, `npm test` from `backend/`). Frontend React 18 + Vite + `react-router-dom` v6 + Tailwind v4 + `zustand`; shared `apiFetch<T>()` client; Vitest `environment: 'node'`, `include: ['src/**/*.test.ts']` (**`.ts` only**, no component rendering), `npm test` from `admin/`.

**Source spec:** `on-the-record` `docs/superpowers/specs/2026-07-21-readrank-question-as-unit-design.md` §"Coverage grid". Builds on Plan 1 (`readrankQuestionsService.listRaceQuestions`, already shipped) and Plans 2/2b (publish attaches quotes to questions; audit is question-aware). **Scope calls:** cell states = `live | draft | none` (the spec's `not-addressed` vs `empty` needs a per-(candidate,question) "searched" marker that isn't stored — deferred); this plan is read-only triage/visibility (click-to-curate mutations are a follow-on that can reuse the existing `/admin/readrank-quotes` select/deselect routes).

**Cell mapping (from real schema — `essentials.quotes`):** for a (question, candidate) pair — a quote with `readrank_selected = true AND deidentified_text IS NOT NULL` → **live**; any other quote present → **draft**; no quote → **none**. Columns key on `politician_id` (challenger `race_candidates` rows with `politician_id IS NULL` can't own a selected quote and are excluded). Roster filter everywhere: `COALESCE(rc.candidate_status,'active') <> 'withdrawn'`.

---

## Backend

### Task 1: `readrankCoverageService` (TDD)

**Files:**
- Create: `backend/src/lib/readrankCoverageService.ts`
- Test: `backend/src/lib/readrankCoverageService.test.ts`

- [ ] **Step 1: Write the failing test** (mirrors `readrankQuestionsService.test.ts`: mock `./db.js`, feed rows, assert SQL + mapping; `cellState` is pure)

Create `backend/src/lib/readrankCoverageService.test.ts`:

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));
// getCoverageGrid composes listRaceQuestions; stub it so this test targets cells+candidates.
vi.mock('./readrankQuestionsService.js', () => ({
  listRaceQuestions: vi.fn(async () => [
    { questionId: 'q1', topicKey: 'campaign-finance', questionText: 'Q1?', origin: 'emergent', status: 'confirmed', answeringCandidates: 2, rankable: true, surfaced: true },
  ]),
}));

import { cellState, listRaceCandidates, getCoverageGrid, searchRaces } from './readrankCoverageService.js';

describe('cellState', () => {
  it('live when a live quote exists', () => expect(cellState(true, 3)).toBe('live'));
  it('draft when quotes exist but none live', () => expect(cellState(false, 2)).toBe('draft'));
  it('none when no quotes', () => expect(cellState(false, 0)).toBe('none'));
});

describe('listRaceCandidates', () => {
  beforeEach(() => mockQuery.mockReset());
  it('queries non-withdrawn candidates with a politician_id and maps to camelCase', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ politician_id: 'p1', full_name: 'Ada' }, { politician_id: 'p2', full_name: 'Ben' }] });
    const out = await listRaceCandidates('race-1');
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toContain('essentials.race_candidates');
    expect(sql).toContain("COALESCE(rc.candidate_status, 'active') <> 'withdrawn'");
    expect(sql).toContain('rc.politician_id IS NOT NULL');
    expect(params).toEqual(['race-1']);
    expect(out).toEqual([{ politicianId: 'p1', fullName: 'Ada' }, { politicianId: 'p2', fullName: 'Ben' }]);
  });
});

describe('getCoverageGrid', () => {
  beforeEach(() => mockQuery.mockReset());
  it('composes questions + candidates + cells with derived cell state', async () => {
    // 1st pool.query = candidates; 2nd = cells (listRaceQuestions is mocked, no pool.query)
    mockQuery
      .mockResolvedValueOnce({ rows: [{ politician_id: 'p1', full_name: 'Ada' }] })
      .mockResolvedValueOnce({ rows: [{ question_id: 'q1', politician_id: 'p1', has_live: true, quote_count: '2' }] });
    const grid = await getCoverageGrid('race-1');
    expect(grid.questions.map((q) => q.questionId)).toEqual(['q1']);
    expect(grid.candidates).toEqual([{ politicianId: 'p1', fullName: 'Ada' }]);
    expect(grid.cells).toEqual([{ questionId: 'q1', politicianId: 'p1', state: 'live' }]);
  });
});

describe('searchRaces', () => {
  beforeEach(() => mockQuery.mockReset());
  it('ILIKE-searches races by position_name', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ race_id: 'r1', position_name: 'U.S. Senate Texas' }] });
    const out = await searchRaces('senate');
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toContain('essentials.races');
    expect(sql.toLowerCase()).toContain('ilike');
    expect(params).toEqual(['%senate%']);
    expect(out).toEqual([{ raceId: 'r1', positionName: 'U.S. Senate Texas' }]);
  });
});
```

- [ ] **Step 2: Run — confirm failure**

From `backend/`: `npm test -- readrankCoverageService`
Expected: FAIL — cannot resolve `./readrankCoverageService.js`.

- [ ] **Step 3: Implement the service**

Create `backend/src/lib/readrankCoverageService.ts`:

```ts
import { pool } from './db.js';
import { listRaceQuestions, type RaceQuestion } from './readrankQuestionsService.js';

export type CellState = 'live' | 'draft' | 'none';

export interface RaceCandidate { politicianId: string; fullName: string; }
export interface CoverageCell { questionId: string; politicianId: string; state: CellState; }
export interface RaceOption { raceId: string; positionName: string; }
export interface CoverageGrid {
  questions: RaceQuestion[];   // rows (carry rankable/surfaced)
  candidates: RaceCandidate[]; // columns
  cells: CoverageCell[];       // (question×candidate) pairs that have >=1 quote; missing pair renders 'none'
}

interface CandidateRow { politician_id: string; full_name: string; }
interface CellRow { question_id: string; politician_id: string; has_live: boolean; quote_count: string; }
interface RaceRow { race_id: string; position_name: string; }

// Pure: derive a cell's state from its quote aggregate.
export function cellState(hasLive: boolean, quoteCount: number): CellState {
  if (hasLive) return 'live';
  if (quoteCount > 0) return 'draft';
  return 'none';
}

const LIST_CANDIDATES_SQL = `
  SELECT DISTINCT rc.politician_id::text AS politician_id,
         COALESCE(p.full_name, rc.full_name) AS full_name
  FROM essentials.race_candidates rc
  LEFT JOIN essentials.politicians p ON p.id = rc.politician_id
  WHERE rc.race_id = $1
    AND rc.politician_id IS NOT NULL
    AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
  ORDER BY full_name
`;

export async function listRaceCandidates(raceId: string): Promise<RaceCandidate[]> {
  const { rows } = await pool.query<CandidateRow>(LIST_CANDIDATES_SQL, [raceId]);
  return rows.map((r) => ({ politicianId: r.politician_id, fullName: r.full_name }));
}

// Per (confirmed question × non-withdrawn candidate) quote aggregate. Only pairs with >=1 quote
// are returned; the grid renders any missing pair as 'none'. has_live = a live quote exists.
const CELLS_SQL = `
  SELECT rq.id::text            AS question_id,
         q.politician_id::text  AS politician_id,
         bool_or(q.readrank_selected AND q.deidentified_text IS NOT NULL) AS has_live,
         count(*)::text         AS quote_count
  FROM essentials.readrank_questions rq
  JOIN essentials.quotes q ON q.question_id = rq.id
  JOIN essentials.race_candidates rc
    ON rc.race_id = rq.race_id
   AND rc.politician_id = q.politician_id
   AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
  WHERE rq.race_id = $1 AND rq.status = 'confirmed'
  GROUP BY rq.id, q.politician_id
`;

export async function getCoverageGrid(raceId: string): Promise<CoverageGrid> {
  const questions = await listRaceQuestions(raceId);
  const candidates = await listRaceCandidates(raceId);
  const { rows } = await pool.query<CellRow>(CELLS_SQL, [raceId]);
  const cells = rows.map((r) => ({
    questionId: r.question_id,
    politicianId: r.politician_id,
    state: cellState(r.has_live, Number(r.quote_count)),
  }));
  return { questions, candidates, cells };
}

const SEARCH_RACES_SQL = `
  SELECT r.id::text AS race_id, r.position_name
  FROM essentials.races r
  WHERE r.position_name ILIKE $1
  ORDER BY r.position_name
  LIMIT 25
`;

export async function searchRaces(query: string): Promise<RaceOption[]> {
  const { rows } = await pool.query<RaceRow>(SEARCH_RACES_SQL, [`%${query}%`]);
  return rows.map((r) => ({ raceId: r.race_id, positionName: r.position_name }));
}
```

- [ ] **Step 4: Run — confirm pass**

From `backend/`: `npm test -- readrankCoverageService` → Expected: all green (3 `cellState` + 1 candidates + 1 grid + 1 searchRaces = 6).

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/readrankCoverageService.ts backend/src/lib/readrankCoverageService.test.ts
git commit -m "feat(readrank): coverage-grid service (candidates + per-cell state + race search)"
```

---

### Task 2: admin route `/api/admin/readrank-coverage` (TDD)

**Files:**
- Create: `backend/src/routes/readrankCoverageAdmin.ts`
- Modify: `backend/src/index.ts`
- Test: `backend/src/routes/readrankCoverageAdmin.test.ts`

- [ ] **Step 1: Write the failing route test** (mirrors `readrankQuotesAdmin.test.ts`: mock auth/admin/supabase + the service)

Create `backend/src/routes/readrankCoverageAdmin.test.ts`:

```ts
import { vi, describe, it, expect } from 'vitest';
import express from 'express';
import request from 'supertest';

vi.mock('../lib/db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: vi.fn() }));
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: { userId?: string }, _res: unknown, next: () => void) => { req.userId = 'admin-1'; next(); },
}));
vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
}));
const { mockGrid, mockSearch } = vi.hoisted(() => ({ mockGrid: vi.fn(), mockSearch: vi.fn() }));
vi.mock('../lib/readrankCoverageService.js', () => ({ getCoverageGrid: mockGrid, searchRaces: mockSearch }));

import router from './readrankCoverageAdmin.js';
const app = express();
app.use(express.json());
app.use('/api/admin/readrank-coverage', router);

const UUID = '216ead27-9e86-49f2-b21c-af659d114faf';

describe('GET /api/admin/readrank-coverage', () => {
  it('422 without a valid race_id', async () => {
    const res = await request(app).get('/api/admin/readrank-coverage?race_id=nope');
    expect(res.status).toBe(422);
  });
  it('returns the grid for a valid race_id', async () => {
    mockGrid.mockResolvedValueOnce({ questions: [], candidates: [], cells: [] });
    const res = await request(app).get(`/api/admin/readrank-coverage?race_id=${UUID}`);
    expect(res.status).toBe(200);
    expect(mockGrid).toHaveBeenCalledWith(UUID);
    expect(res.body).toEqual({ questions: [], candidates: [], cells: [] });
  });
});

describe('GET /api/admin/readrank-coverage/races', () => {
  it('422 without q', async () => {
    const res = await request(app).get('/api/admin/readrank-coverage/races');
    expect(res.status).toBe(422);
  });
  it('returns matches', async () => {
    mockSearch.mockResolvedValueOnce([{ raceId: 'r1', positionName: 'U.S. Senate Texas' }]);
    const res = await request(app).get('/api/admin/readrank-coverage/races?q=senate');
    expect(res.status).toBe(200);
    expect(mockSearch).toHaveBeenCalledWith('senate');
    expect(res.body).toEqual({ races: [{ raceId: 'r1', positionName: 'U.S. Senate Texas' }] });
  });
});
```

- [ ] **Step 2: Run — confirm failure**

From `backend/`: `npm test -- readrankCoverageAdmin` → FAIL (cannot resolve `./readrankCoverageAdmin.js`).

- [ ] **Step 3: Implement the router**

Create `backend/src/routes/readrankCoverageAdmin.ts`:

```ts
import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { getCoverageGrid, searchRaces } from '../lib/readrankCoverageService.js';

const router = Router();
router.use(requireAuth, requireAdmin);

const gridQuery = z.object({ race_id: z.string().uuid() });
// GET /api/admin/readrank-coverage?race_id=<uuid>
router.get('/', async (req: Request, res: Response): Promise<void> => {
  const parsed = gridQuery.safeParse(req.query);
  if (!parsed.success) {
    res.status(422).json({ error: 'race_id (uuid) is required' });
    return;
  }
  try {
    const grid = await getCoverageGrid(parsed.data.race_id);
    res.status(200).json(grid);
  } catch (err) {
    console.error('[GET /admin/readrank-coverage] error:', err);
    res.status(500).json({ error: 'Failed to load coverage grid' });
  }
});

const racesQuery = z.object({ q: z.string().min(1) });
// GET /api/admin/readrank-coverage/races?q=<text>
router.get('/races', async (req: Request, res: Response): Promise<void> => {
  const parsed = racesQuery.safeParse(req.query);
  if (!parsed.success) {
    res.status(422).json({ error: 'q is required' });
    return;
  }
  try {
    const races = await searchRaces(parsed.data.q);
    res.status(200).json({ races });
  } catch (err) {
    console.error('[GET /admin/readrank-coverage/races] error:', err);
    res.status(500).json({ error: 'Failed to search races' });
  }
});

export default router;
```

- [ ] **Step 4: Mount the router in `backend/src/index.ts`**

Near the other admin router imports (~line 37) add:
```ts
import readrankCoverageAdminRouter from './routes/readrankCoverageAdmin.js';
```
Near the other admin `app.use(...)` mounts (~line 130, next to the `readrank-quotes` mount) add:
```ts
app.use('/api/admin/readrank-coverage', readrankCoverageAdminRouter);
```

- [ ] **Step 5: Run — confirm pass**

From `backend/`: `npm test -- readrankCoverageAdmin` → Expected: 4 passed. Then `npm run test:unit` → whole `src` suite still green.

- [ ] **Step 6: Commit**

```bash
git add backend/src/routes/readrankCoverageAdmin.ts backend/src/routes/readrankCoverageAdmin.test.ts backend/src/index.ts
git commit -m "feat(readrank): admin coverage-grid + race-search endpoints"
```

---

## Frontend

### Task 3: pure cell/row logic helper (TDD)

**Files:**
- Create: `admin/src/pages/admin/coverageGridCell.ts`
- Test: `admin/src/pages/admin/coverageGridCell.test.ts`

- [ ] **Step 1: Write the failing test** (pure `.ts`, fits the `include: ['src/**/*.test.ts']` runner — no jsdom)

Create `admin/src/pages/admin/coverageGridCell.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { cellClass, rowStatus, type CellState } from './coverageGridCell';

describe('rowStatus', () => {
  it('rankable with >= 2 live', () => expect(rowStatus(['live', 'live', 'none'])).toBe('rankable'));
  it('near-rankable with 1 live + a draft', () => expect(rowStatus(['live', 'draft'])).toBe('near-rankable'));
  it('solo with a single live and no drafts', () => expect(rowStatus(['live', 'none'])).toBe('solo'));
  it('solo with only drafts', () => expect(rowStatus(['draft', 'none'])).toBe('solo'));
  it('none when nothing present', () => expect(rowStatus(['none', 'none'])).toBe('none'));
});

describe('cellClass', () => {
  it('distinct class per state', () => {
    const states: CellState[] = ['live', 'draft', 'none'];
    const classes = states.map(cellClass);
    expect(new Set(classes).size).toBe(3);
    expect(cellClass('live')).toContain('green');
    expect(cellClass('draft')).toContain('amber');
  });
});
```

- [ ] **Step 2: Run — confirm failure**

From `admin/`: `npm test -- coverageGridCell` → FAIL (module missing).

- [ ] **Step 3: Implement the helper**

Create `admin/src/pages/admin/coverageGridCell.ts`:

```ts
export type CellState = 'live' | 'draft' | 'none';
export type RowStatus = 'rankable' | 'near-rankable' | 'solo' | 'none';

const CELL_CLASS: Record<CellState, string> = {
  live: 'bg-green-500',
  draft: 'bg-amber-400',
  none: 'bg-gray-200 dark:bg-gray-700',
};

export function cellClass(state: CellState): string {
  return CELL_CLASS[state];
}

// A question's row status, derived from its candidates' cell states.
// rankable = >=2 live (a real head-to-head); near-rankable = 1 live + >=1 draft (one confirm away);
// solo = at least one live/draft but not rankable/near; none = nothing.
export function rowStatus(states: CellState[]): RowStatus {
  const live = states.filter((s) => s === 'live').length;
  const draft = states.filter((s) => s === 'draft').length;
  if (live >= 2) return 'rankable';
  if (live === 1 && draft >= 1) return 'near-rankable';
  if (live + draft >= 1) return 'solo';
  return 'none';
}
```

- [ ] **Step 4: Run — confirm pass**

From `admin/`: `npm test -- coverageGridCell` → Expected: all green (5 rowStatus + 1 cellClass).

- [ ] **Step 5: Commit**

```bash
git add admin/src/pages/admin/coverageGridCell.ts admin/src/pages/admin/coverageGridCell.test.ts
git commit -m "feat(admin): coverage-grid cell/row status helper"
```

---

### Task 4: the coverage grid page + routing/nav

**Files:**
- Create: `admin/src/pages/admin/ReadRankCoveragePage.tsx`
- Modify: `admin/src/App.tsx`
- Modify: `admin/src/pages/admin/AdminLayout.tsx`

- [ ] **Step 1: Create the page component**

Create `admin/src/pages/admin/ReadRankCoveragePage.tsx`:

```tsx
import { useState } from 'react';
import { apiFetch } from '../../lib/api';
import { cellClass, rowStatus, type CellState } from './coverageGridCell';

interface RaceOption { raceId: string; positionName: string; }
interface Question {
  questionId: string; topicKey: string; questionText: string;
  origin: string; status: string; answeringCandidates: number;
  rankable: boolean; surfaced: boolean;
}
interface Candidate { politicianId: string; fullName: string; }
interface Cell { questionId: string; politicianId: string; state: CellState; }
interface Grid { questions: Question[]; candidates: Candidate[]; cells: Cell[]; }

const ROW_BADGE: Record<string, string> = {
  rankable: 'bg-green-600 text-white',
  'near-rankable': 'bg-amber-500 text-white',
  solo: 'bg-gray-400 text-white',
  none: 'bg-gray-200 text-gray-600 dark:bg-gray-700 dark:text-gray-300',
};

export function ReadRankCoveragePage() {
  const [query, setQuery] = useState('');
  const [races, setRaces] = useState<RaceOption[]>([]);
  const [grid, setGrid] = useState<Grid | null>(null);
  const [raceName, setRaceName] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function search(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    try {
      const d = await apiFetch<{ races: RaceOption[] }>(
        `/admin/readrank-coverage/races?q=${encodeURIComponent(query)}`);
      setRaces(d.races);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Search failed');
    }
  }

  async function loadRace(r: RaceOption) {
    setLoading(true); setError(''); setRaceName(r.positionName);
    try {
      setGrid(await apiFetch<Grid>(`/admin/readrank-coverage?race_id=${encodeURIComponent(r.raceId)}`));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load grid');
      setGrid(null);
    } finally {
      setLoading(false);
    }
  }

  // (questionId, politicianId) -> state, defaulting to 'none' for absent pairs.
  const stateOf = (g: Grid, qId: string, pId: string): CellState =>
    g.cells.find((c) => c.questionId === qId && c.politicianId === pId)?.state ?? 'none';

  return (
    <div className="p-6">
      <h1 className="text-2xl font-semibold mb-4">Read &amp; Rank — Coverage Grid</h1>

      <form onSubmit={search} className="flex gap-2 mb-6">
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search races (e.g. Senate Texas)"
          className="border rounded px-3 py-2 flex-1 dark:bg-gray-800 dark:border-gray-600"
        />
        <button type="submit" className="px-4 py-2 rounded bg-ev-blue text-white">Search</button>
      </form>

      {races.length > 0 && !grid && (
        <ul className="mb-6 space-y-1">
          {races.map((r) => (
            <li key={r.raceId}>
              <button onClick={() => loadRace(r)} className="text-ev-blue hover:underline">
                {r.positionName}
              </button>
            </li>
          ))}
        </ul>
      )}

      {error && <p className="text-ev-red mb-4">{error}</p>}
      {loading && <p>Loading…</p>}

      {grid && (
        <>
          <div className="flex items-center gap-4 mb-3">
            <h2 className="text-lg font-medium">{raceName}</h2>
            <button onClick={() => { setGrid(null); }} className="text-sm text-ev-blue hover:underline">
              ← pick another race
            </button>
          </div>
          <div className="flex gap-4 mb-3 text-sm">
            <span><span className="inline-block w-3 h-3 rounded-sm bg-green-500 mr-1" />live</span>
            <span><span className="inline-block w-3 h-3 rounded-sm bg-amber-400 mr-1" />draft</span>
            <span><span className="inline-block w-3 h-3 rounded-sm bg-gray-200 dark:bg-gray-700 mr-1" />none</span>
          </div>

          {grid.questions.length === 0 ? (
            <p className="text-gray-500">No confirmed questions for this race yet.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="border-collapse text-sm">
                <thead>
                  <tr>
                    <th className="text-left p-2 sticky left-0 bg-white dark:bg-gray-900">Question</th>
                    <th className="p-2">Status</th>
                    {grid.candidates.map((c) => (
                      <th key={c.politicianId} className="p-2 whitespace-nowrap">{c.fullName}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {grid.questions.map((q) => {
                    const states = grid.candidates.map((c) => stateOf(grid, q.questionId, c.politicianId));
                    const rs = rowStatus(states);
                    return (
                      <tr key={q.questionId} className="border-t dark:border-gray-700">
                        <td className="p-2 max-w-md sticky left-0 bg-white dark:bg-gray-900">
                          <span className="text-xs text-gray-500 mr-1">[{q.topicKey}]</span>{q.questionText}
                        </td>
                        <td className="p-2">
                          <span className={`px-2 py-0.5 rounded text-xs ${ROW_BADGE[rs]}`}>{rs}</span>
                        </td>
                        {grid.candidates.map((c, i) => (
                          <td key={c.politicianId} className="p-2 text-center">
                            <span
                              title={states[i]}
                              className={`inline-block w-5 h-5 rounded-sm ${cellClass(states[i])}`}
                            />
                          </td>
                        ))}
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Register the route in `admin/src/App.tsx`**

Add the import near the other admin-page imports (~line 25):
```tsx
import { ReadRankCoveragePage } from './pages/admin/ReadRankCoveragePage';
```
Add the child route inside the `<Route path="/admin" element={<AdminLayout />}>` block (next to the existing `readrank-quotes` route, ~line 118):
```tsx
<Route path="readrank-coverage" element={<ReadRankCoveragePage />} />
```

- [ ] **Step 3: Add the nav link in `admin/src/pages/admin/AdminLayout.tsx`**

Append to the `navItems` array (~lines 4-21):
```ts
{ label: 'Read & Rank Coverage', to: '/admin/readrank-coverage' },
```

- [ ] **Step 4: Verify — unit tests, typecheck, build**

From `admin/`:
- `npm test` → all green (the pure helper test; the `.tsx` is not unit-tested by design — the runner is node-only).
- `npx tsc --noEmit` → no type errors in the new page/imports.
- `npm run build` → succeeds (Vite compiles the new page).

- [ ] **Step 5: Commit**

```bash
git add admin/src/pages/admin/ReadRankCoveragePage.tsx admin/src/App.tsx admin/src/pages/admin/AdminLayout.tsx
git commit -m "feat(admin): Read & Rank coverage-grid page + route + nav"
```

---

## Self-review

- **Spec coverage (§Coverage grid):** rows = questions, columns = candidates, colored cells → Task 4 table using Task 1's `getCoverageGrid` + Task 3's `cellClass`. Row status rankable/near-rankable/solo/none → `rowStatus` (Task 3), rendered as a badge. Triage (near-rankable visible) + inclusion (every non-withdrawn candidate is a column, sparse columns visible) + a race picker → Tasks 1/2/4. The `not-addressed` vs `empty` split and click-to-curate mutations are explicitly deferred (stated in header) — no silent drop.
- **Placeholder scan:** none — full SQL/TS/TSX/commands in every step. Line numbers for `index.ts`/`App.tsx`/`AdminLayout.tsx` edits are approximate anchors ("near line N, next to X"), with the neighboring code named so the exact spot is unambiguous.
- **Consistency:** `CellState` (`'live'|'draft'|'none'`) is identical in the backend service (Task 1), the frontend helper (Task 3), and the page (Task 4). `getCoverageGrid` returns `{questions, candidates, cells}`; the page's `Grid` interface + `stateOf` match that shape and the `RaceQuestion`/`RaceCandidate`/`CoverageCell` field names (`questionId`, `politicianId`, `topicKey`, `questionText`, `fullName`, `state`). The route test mocks `getCoverageGrid`/`searchRaces` — the exact names the service exports and the router imports. `searchRaces` returns `{raceId, positionName}`; the page's `RaceOption` matches.
- **Read-only:** no mutations, no schema changes, all `SELECT`; safe to point at prod. Cell query only counts quotes already attached to questions — until curation populates `question_id`, the grid shows questions with all-`none` rows (correct, and itself a useful "nothing sourced yet" signal).
