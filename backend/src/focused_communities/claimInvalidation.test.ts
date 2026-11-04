import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// ── Mocks ────────────────────────────────────────────────────────────────────────────────
// middleware/claimInvalidation.ts is the one piece of the argument tree that runs AFTER a write
// has committed and BEFORE its response is sent. Everything it does is therefore on the hook
// for one rule, which its own header states: "a write that has already committed must not be
// reported as a failure because a cache could not be reached". These tests are about the ways
// of failing that are not reaching the cache.

const query = vi.fn();
vi.mock('./config/database.js', () => ({
  pool: { query: (...a: unknown[]) => query(...a) },
}));

/**
 * cacheDel, with a switch for the one failure mode the real one cannot have today.
 *
 * `cacheDel` swallows a per-key failure internally, and `invalidate` attaches a `.catch` to the
 * promise it returns — so a rejection is already covered. What is NOT covered by either is a
 * SYNCHRONOUS throw, before a promise exists to attach anything to: the `.catch` is never
 * reached and `invalidate` itself rejects. That is the shape this mock produces.
 */
let cacheDelThrows = false;
const cacheDel = vi.fn((..._keys: string[]) => {
  if (cacheDelThrows) throw new Error('cache client is not connected');
  return Promise.resolve();
});
vi.mock('./middleware/cache.js', () => ({
  cacheDel: (...keys: string[]) => cacheDel(...keys),
}));

// The key builders only. Importing the real routes/claims.ts would drag the whole read side —
// and its auth and cache dependencies — into a run that is about one middleware.
vi.mock('./routes/claims.js', () => ({
  claimCacheKey: (ns: string, id: string) => `fc:claim:${ns}:${id}:{}`,
  shapeCacheKey: (communityId: string) => `fc:claims:shape:${communityId}`,
}));

const { claimWriteInvalidation } = await import('./middleware/claimInvalidation.js');

const uuid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const CLAIM = uuid(200);
const PARENT = uuid(100);
const COMMUNITY = uuid(900);

const app = express();
app.use(express.json());
app.use(claimWriteInvalidation);
app.post('/claims/:claimId/hide', (_req, res) => {
  res.json({ data: { id: CLAIM } });
});
app.post('/claims/:claimId/fails', (_req, res) => {
  res.status(500).json({ error: { code: 'NOPE', message: 'no' } });
});

const rows = (r: unknown[]) => ({ rows: r, rowCount: r.length });

beforeEach(() => {
  query.mockReset();
  cacheDel.mockReset();
  cacheDel.mockImplementation((..._keys: string[]) => {
    if (cacheDelThrows) throw new Error('cache client is not connected');
    return Promise.resolve();
  });
  cacheDelThrows = false;
  query.mockResolvedValue(rows([{ community_id: COMMUNITY, parent_claim_id: PARENT }]));
});

describe('claimWriteInvalidation', () => {
  it('drops the shape map, the root page and the claim and its parent, then sends the body', async () => {
    const res = await request(app).post(`/claims/${CLAIM}/hide`).send({});

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ data: { id: CLAIM } });
    const keys = cacheDel.mock.calls[0] as string[];
    expect(keys).toContain(`fc:claims:shape:${COMMUNITY}`);
    expect(keys).toContain(`fc:claim:root:${COMMUNITY}:{}`);
    expect(keys).toContain(`fc:claim:id:${CLAIM}:{}`);
    expect(keys).toContain(`fc:claim:id:${PARENT}:{}`);
  });

  it('sends the body even when the invalidation itself THROWS', async () => {
    // 🔴 THE REQUEST MUST NOT HANG ON A WRITE THAT COMMITTED. `void invalidate(...).then(...)`
    // with no rejection handler meant that a throw anywhere inside invalidate skipped sendJson
    // entirely — and no error handler could pick it up, because the wrapper has already put
    // res.json back. The client then holds an open socket until its own timeout, on a request
    // whose write is in the database. invalidate() is written never to reject, but that is an
    // audit rather than a guarantee, and this is the one outcome the whole file exists to
    // prevent.
    cacheDelThrows = true;
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});

    const res = await request(app).post(`/claims/${CLAIM}/hide`).send({});

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ data: { id: CLAIM } });
    // And it leaves a trace rather than failing silently.
    expect(warn).toHaveBeenCalled();
    warn.mockRestore();
  });

  it('sends the body exactly once when the invalidation throws', async () => {
    // A rejection handler attached AFTER .then would also fire when sendJson itself threw, and
    // would then try to send the body a second time — "Cannot set headers after they are sent"
    // on a committed write. The catch goes before the then.
    cacheDelThrows = true;
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
    const err = vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await request(app).post(`/claims/${CLAIM}/hide`).send({});

    expect(res.status).toBe(200);
    expect(err).not.toHaveBeenCalled();
    warn.mockRestore();
    err.mockRestore();
  });

  it('invalidates nothing on a non-2xx, because nothing was written', async () => {
    const res = await request(app).post(`/claims/${CLAIM}/fails`).send({});

    expect(res.status).toBe(500);
    expect(query).not.toHaveBeenCalled();
    expect(cacheDel).not.toHaveBeenCalled();
  });
});
