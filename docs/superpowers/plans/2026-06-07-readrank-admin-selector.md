# Read & Rank Admin Quote Selector (Plan 2 of 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an admin-only page in the ev-accounts admin panel to view all quotes for a politician (grouped by topic) and choose which one is the Read & Rank pick (`readrank_selected`), so the pick can change outside a research run.

**Architecture:** A thin service (`readrankQuotesService.ts`) holds the two operations (list grouped quotes; transactionally select one). A new admin router (`readrankQuotesAdmin.ts`) exposes `GET`/`PUT` under `/api/admin/readrank-quotes`, guarded by `requireAuth, requireAdmin`. A new admin SPA page lists quotes with radio selection, wired into the existing router + nav.

**Tech Stack:** Express + TypeScript + Zod, Vitest (services tested with a mocked `pool.query`), React + react-router + the admin `apiFetch` helper.

**Spec:** `docs/superpowers/specs/2026-06-07-research-stances-quote-path-design.md` (§6)

**Depends on:** Plan 1 Task 1 (the `readrank_selected` column must exist).

---

### Task 1: `readrankQuotesService.ts` — list + select logic

**Files:**
- Create: `backend/src/lib/readrankQuotesService.ts`
- Test: `backend/src/lib/readrankQuotesService.test.ts`

- [ ] **Step 1: Write the failing test**

Create `backend/src/lib/readrankQuotesService.test.ts`:

```ts
import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery, mockConnect, mockClientQuery, mockRelease } = vi.hoisted(() => ({
  mockQuery: vi.fn(),
  mockConnect: vi.fn(),
  mockClientQuery: vi.fn(),
  mockRelease: vi.fn(),
}));
vi.mock('./db.js', () => ({ pool: { query: mockQuery, connect: mockConnect } }));

import { listReadrankQuotes, selectReadrankQuote } from './readrankQuotesService.js';

beforeEach(() => {
  mockQuery.mockReset();
  mockClientQuery.mockReset();
  mockRelease.mockReset();
  mockConnect.mockReset();
  mockConnect.mockResolvedValue({ query: mockClientQuery, release: mockRelease });
});

describe('listReadrankQuotes', () => {
  it('groups quotes by topic_key', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [
      { id: 'q1', topic_key: 'healthcare', quote_text: 'a', deidentified_text: 'A', source_url: null, source_name: null, readrank_selected: true },
      { id: 'q2', topic_key: 'healthcare', quote_text: 'b', deidentified_text: 'B', source_url: null, source_name: null, readrank_selected: false },
      { id: 'q3', topic_key: 'housing', quote_text: 'c', deidentified_text: null, source_url: null, source_name: null, readrank_selected: false },
    ] });
    const out = await listReadrankQuotes('pol-1');
    expect(out.map((t) => t.topicKey)).toEqual(['healthcare', 'housing']);
    expect(out[0].quotes).toHaveLength(2);
    expect(out[0].quotes[0]).toMatchObject({ id: 'q1', readrankSelected: true });
  });
});

describe('selectReadrankQuote', () => {
  it('rejects selecting a quote with no de-identified text', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ politician_id: 'pol-1', topic_key: 'healthcare', deidentified_text: null }] });
    await expect(selectReadrankQuote('q3')).rejects.toThrow(/de-identified/i);
    expect(mockConnect).not.toHaveBeenCalled();
  });

  it('throws when the quote id does not exist', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await expect(selectReadrankQuote('nope')).rejects.toThrow(/not found/i);
    expect(mockConnect).not.toHaveBeenCalled();
  });

  it('clears siblings then selects the target in a transaction on one client', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ politician_id: 'pol-1', topic_key: 'Healthcare', deidentified_text: 'A' }] });
    mockClientQuery.mockResolvedValue({});
    await selectReadrankQuote('q1');
    const sql = mockClientQuery.mock.calls.map((c) => String(c[0]));
    expect(sql[0]).toBe('BEGIN');
    expect(sql[sql.length - 1]).toBe('COMMIT');
    const falseIdx = sql.findIndex((s) => /readrank_selected\s*=\s*false/i.test(s));
    const trueIdx = sql.findIndex((s) => /readrank_selected\s*=\s*true/i.test(s));
    expect(falseIdx).toBeGreaterThan(-1);
    expect(trueIdx).toBeGreaterThan(falseIdx);
    expect(mockRelease).toHaveBeenCalledTimes(1);
  });

  it('rolls back and releases the client when an update fails', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ politician_id: 'pol-1', topic_key: 'healthcare', deidentified_text: 'A' }] });
    mockClientQuery
      .mockResolvedValueOnce({})                 // BEGIN
      .mockResolvedValueOnce({})                 // clear siblings
      .mockRejectedValueOnce(new Error('boom')); // set target fails
    await expect(selectReadrankQuote('q1')).rejects.toThrow('boom');
    const sql = mockClientQuery.mock.calls.map((c) => String(c[0]));
    expect(sql).toContain('ROLLBACK');
    expect(mockRelease).toHaveBeenCalledTimes(1);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd backend && npx vitest run src/lib/readrankQuotesService.test.ts`
Expected: FAIL — cannot find module `./readrankQuotesService.js`.

- [ ] **Step 3: Implement the service**

Create `backend/src/lib/readrankQuotesService.ts`:

```ts
import { pool } from './db.js';

export interface AdminQuote {
  id: string;
  quoteText: string;
  deidentifiedText: string | null;
  sourceUrl: string | null;
  sourceName: string | null;
  readrankSelected: boolean;
}
export interface AdminTopicQuotes {
  topicKey: string;
  quotes: AdminQuote[];
}

export async function listReadrankQuotes(politicianId: string): Promise<AdminTopicQuotes[]> {
  const { rows } = await pool.query<{
    id: string; topic_key: string; quote_text: string; deidentified_text: string | null;
    source_url: string | null; source_name: string | null; readrank_selected: boolean;
  }>(
    `SELECT id, lower(topic_key) AS topic_key, quote_text, deidentified_text,
            source_url, source_name, readrank_selected
       FROM essentials.quotes
      WHERE politician_id = $1
      ORDER BY lower(topic_key) ASC, readrank_selected DESC, created_at ASC NULLS LAST, id ASC`,
    [politicianId],
  );
  const byTopic = new Map<string, AdminTopicQuotes>();
  const order: string[] = [];
  for (const r of rows) {
    if (!byTopic.has(r.topic_key)) { byTopic.set(r.topic_key, { topicKey: r.topic_key, quotes: [] }); order.push(r.topic_key); }
    byTopic.get(r.topic_key)!.quotes.push({
      id: r.id, quoteText: r.quote_text, deidentifiedText: r.deidentified_text,
      sourceUrl: r.source_url, sourceName: r.source_name, readrankSelected: r.readrank_selected,
    });
  }
  return order.map((k) => byTopic.get(k)!);
}

export async function selectReadrankQuote(quoteId: string): Promise<void> {
  const { rows } = await pool.query<{ politician_id: string; topic_key: string; deidentified_text: string | null }>(
    `SELECT politician_id, topic_key, deidentified_text FROM essentials.quotes WHERE id = $1`,
    [quoteId],
  );
  if (rows.length === 0) throw new Error('Quote not found');
  const { politician_id, topic_key, deidentified_text } = rows[0];
  if (!deidentified_text) throw new Error('Cannot select a quote with no de-identified text');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `UPDATE essentials.quotes SET readrank_selected = false
        WHERE politician_id = $1 AND lower(topic_key) = lower($2)`,
      [politician_id, topic_key],
    );
    await client.query(`UPDATE essentials.quotes SET readrank_selected = true WHERE id = $1`, [quoteId]);
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd backend && npx vitest run src/lib/readrankQuotesService.test.ts`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/readrankQuotesService.ts backend/src/lib/readrankQuotesService.test.ts
git commit -m "feat(readrank): admin service to list quotes by topic and select the RR pick"
```

---

### Task 2: Admin route `/api/admin/readrank-quotes`

**Files:**
- Create: `backend/src/routes/readrankQuotesAdmin.ts`
- Modify: `backend/src/index.ts` (mount the router)

- [ ] **Step 1: Write the router**

Create `backend/src/routes/readrankQuotesAdmin.ts`:

```ts
// /api/admin/readrank-quotes/* — admin-only Read & Rank quote selection.
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { logAdminAction } from '../lib/adminService.js';
import { listReadrankQuotes, selectReadrankQuote } from '../lib/readrankQuotesService.js';

const router = Router();
router.use(requireAuth, requireAdmin);

const listQuery = z.object({ politician_id: z.string().uuid() });

// GET /api/admin/readrank-quotes?politician_id=...
router.get('/', async (req: Request, res: Response): Promise<void> => {
  const parsed = listQuery.safeParse(req.query);
  if (!parsed.success) {
    res.status(422).json({ error: 'politician_id (uuid) is required' });
    return;
  }
  try {
    const topics = await listReadrankQuotes(parsed.data.politician_id);
    res.status(200).json({ topics });
  } catch (err) {
    console.error('[GET /admin/readrank-quotes] error:', err);
    res.status(500).json({ error: 'Failed to list quotes' });
  }
});

const selectBody = z.object({ quote_id: z.string().uuid() });

// PUT /api/admin/readrank-quotes/select
router.put('/select', async (req: Request, res: Response): Promise<void> => {
  const parsed = selectBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ error: 'quote_id (uuid) is required' });
    return;
  }
  try {
    await selectReadrankQuote(parsed.data.quote_id);
    await logAdminAction((req as AuthenticatedRequest).userId, 'readrank_quote.select', {
      quote_id: parsed.data.quote_id,
    });
    res.status(200).json({ ok: true });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to select quote';
    const code = /not found/i.test(msg) ? 404 : /de-identified/i.test(msg) ? 422 : 500;
    if (code === 500) console.error('[PUT /admin/readrank-quotes/select] error:', err);
    res.status(code).json({ error: msg });
  }
});

export default router;
```

> Confirm the `logAdminAction(userId, action, details)` signature against `backend/src/lib/adminService.ts` before finalizing; match its argument order exactly (adjust the call if it differs).

- [ ] **Step 2: Mount the router in index.ts**

In `backend/src/index.ts`, near the other `app.use('/api/admin', …)` / admin mounts, add the import and mount:

```ts
import readrankQuotesAdminRouter from './routes/readrankQuotesAdmin.js';
```
```ts
app.use('/api/admin/readrank-quotes', readrankQuotesAdminRouter);
```

- [ ] **Step 3: Typecheck**

Run: `cd backend && npm run typecheck`
Expected: no errors.

- [ ] **Step 4: Smoke-test the endpoints**

With `cd backend && npm run dev` and a valid admin bearer token in `$TOKEN`:

```bash
PID=$(curl -s "http://localhost:3000/api/readrank/races/7d3f0042-eb15-462b-bf14-df15244c5d16/quotes" >/dev/null; echo "0be7d42f-9363-40ad-bbc5-733c862f4395") # David Henry
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:3000/api/admin/readrank-quotes?politician_id=$PID" | python3 -m json.tool | head -30
```

Expected: JSON `{ "topics": [ { "topicKey": "...", "quotes": [ { "id", "quoteText", "deidentifiedText", "readrankSelected" } ] } ] }`. Unauthenticated call returns 403.

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/readrankQuotesAdmin.ts backend/src/index.ts
git commit -m "feat(admin): /api/admin/readrank-quotes list + select endpoints"
```

---

### Task 3: Admin SPA page + nav + route

**Files:**
- Create: `admin/src/pages/admin/ReadRankQuotesPage.tsx`
- Modify: `admin/src/App.tsx` (import + route)
- Modify: `admin/src/pages/admin/AdminLayout.tsx` (nav link)

- [ ] **Step 1: Add the nav link**

In `admin/src/pages/admin/AdminLayout.tsx`, add to the `links` array after the `Review Queue` entry:

```ts
  { label: 'Read & Rank Quotes', to: '/admin/readrank-quotes' },
```

- [ ] **Step 2: Add the route**

In `admin/src/App.tsx`, add the import near the other admin page imports:

```ts
import { ReadRankQuotesPage } from './pages/admin/ReadRankQuotesPage';
```

And add the route inside the `<Route path="/admin" element={<AdminLayout />}>` block (after the `review` route):

```tsx
          <Route path="readrank-quotes" element={<ReadRankQuotesPage />} />
```

- [ ] **Step 3: Create the page**

Create `admin/src/pages/admin/ReadRankQuotesPage.tsx`:

```tsx
import { useState } from 'react';
import { apiFetch } from '../../lib/api';

interface AdminQuote {
  id: string;
  quoteText: string;
  deidentifiedText: string | null;
  sourceUrl: string | null;
  sourceName: string | null;
  readrankSelected: boolean;
}
interface AdminTopicQuotes { topicKey: string; quotes: AdminQuote[]; }

export function ReadRankQuotesPage() {
  const [politicianId, setPoliticianId] = useState('');
  const [topics, setTopics] = useState<AdminTopicQuotes[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [savingId, setSavingId] = useState<string | null>(null);

  async function load(id: string) {
    setLoading(true); setError(null);
    try {
      const data = await apiFetch<{ topics: AdminTopicQuotes[] }>(
        `/admin/readrank-quotes?politician_id=${encodeURIComponent(id)}`,
      );
      setTopics(data.topics);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
      setTopics(null);
    } finally { setLoading(false); }
  }

  async function select(quoteId: string) {
    setSavingId(quoteId); setError(null);
    try {
      await apiFetch('/admin/readrank-quotes/select', {
        method: 'PUT',
        body: JSON.stringify({ quote_id: quoteId }),
      });
      await load(politicianId);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to select');
    } finally { setSavingId(null); }
  }

  return (
    <div className="p-6 max-w-4xl">
      <h1 className="text-xl font-semibold mb-4">Read &amp; Rank Quotes</h1>
      <form
        className="flex gap-2 mb-6"
        onSubmit={(e) => { e.preventDefault(); if (politicianId.trim()) load(politicianId.trim()); }}
      >
        <input
          className="border rounded px-3 py-2 flex-1"
          placeholder="Politician ID (uuid)"
          value={politicianId}
          onChange={(e) => setPoliticianId(e.target.value)}
        />
        <button className="px-4 py-2 bg-ev-muted-blue text-white rounded" type="submit">Load</button>
      </form>

      {loading && <p>Loading…</p>}
      {error && <p className="text-ev-coral mb-4">{error}</p>}

      {topics && topics.length === 0 && <p>No quotes for this politician.</p>}

      {topics?.map((t) => (
        <section key={t.topicKey} className="mb-6">
          <h2 className="font-medium mb-2">{t.topicKey}</h2>
          <ul className="space-y-2">
            {t.quotes.map((q) => (
              <li key={q.id} className="border rounded p-3 flex gap-3 items-start">
                <input
                  type="radio"
                  name={`sel-${t.topicKey}`}
                  className="mt-1"
                  checked={q.readrankSelected}
                  disabled={!q.deidentifiedText || savingId === q.id}
                  onChange={() => select(q.id)}
                  title={q.deidentifiedText ? 'Use this quote for Read & Rank' : 'No de-identified text — cannot be selected'}
                />
                <div className="flex-1">
                  <p className="text-sm">{q.deidentifiedText ?? <span className="italic text-gray-500">(no de-identified text)</span>}</p>
                  <p className="text-xs text-gray-500 mt-1">verbatim: {q.quoteText}</p>
                  {q.sourceUrl && (
                    <a className="text-xs text-ev-light-blue" href={q.sourceUrl} target="_blank" rel="noreferrer">
                      {q.sourceName ?? q.sourceUrl}
                    </a>
                  )}
                </div>
              </li>
            ))}
          </ul>
        </section>
      ))}
    </div>
  );
}
```

- [ ] **Step 4: Build the admin app**

Run: `cd admin && npm run build`
Expected: build succeeds (TypeScript + Vite), no type errors.

- [ ] **Step 5: Manual verification**

Run `cd admin && npm run dev`, log in as admin, open **Read & Rank Quotes** in the nav, paste a politician UUID (e.g. `0be7d42f-9363-40ad-bbc5-733c862f4395` = David Henry), Load. Confirm: quotes grouped by topic, the selected one's radio is checked, a radio for a quote with no de-id text is disabled, and selecting a different quote persists after reload.

- [ ] **Step 6: Commit**

```bash
git add admin/src/pages/admin/ReadRankQuotesPage.tsx admin/src/App.tsx admin/src/pages/admin/AdminLayout.tsx
git commit -m "feat(admin): Read & Rank Quotes page to choose the per-stance quote"
```

---

## Self-Review notes

- Spec §6 (admin selector) fully covered: GET grouped list (Task 1/2/3), PUT select with NULL-deid rejection (Task 1 test + Task 2 status mapping), new top-level nav (Task 3 Step 1).
- Service tested with mocked `pool.query` (matches the codebase's `researchEvidenceService.test.ts` pattern); route + page verified via typecheck/build/manual smoke test (no route-integration harness exists in the repo).
- Type names consistent across tasks: `AdminQuote`/`AdminTopicQuotes`, fields `readrankSelected`, `deidentifiedText`, `quoteText`.
- Open confirmation flagged inline: exact `logAdminAction` argument order.
