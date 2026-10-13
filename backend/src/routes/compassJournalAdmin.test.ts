import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const h = vi.hoisted(() => ({
  create: vi.fn(), update: vi.fn(), publish: vi.fn(), del: vi.fn(), season: vi.fn(),
  assertOpen: vi.fn(),
}));
vi.mock('../lib/compassJournalService.js', () => ({
  createEntry: h.create, updateEntry: h.update, publishEntry: h.publish,
  deleteDraft: h.del, resolveDefaultSeasonId: h.season,
  assertSeasonWritable: h.assertOpen,
}));
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: Record<string, unknown>, _res: unknown, next: () => void) => {
    req.userId = 'u-admin';
    next();
  },
}));
vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import adminRouter from './compassJournalAdmin.js';

const app = express();
app.use(express.json());
app.use('/api/admin/compass', adminRouter);

beforeEach(() => {
  Object.values(h).forEach((m) => m.mockReset());
  h.season.mockResolvedValue('s-open');
});

describe('POST /topics/:topicId/journal', () => {
  it('creates a draft and takes the author from the session, not the body', async () => {
    h.create.mockResolvedValue({ id: 'j1' });
    const res = await request(app)
      .post('/api/admin/compass/topics/33333333-3333-4333-8333-333333333333/journal')
      .send({ kind: 'watching', body: 'We are watching childcare.', authorId: 'u-someone-else' });

    expect(res.status).toBe(201);
    expect(h.create).toHaveBeenCalledWith(expect.anything(), 'u-admin');
    expect(h.create.mock.calls[0][0]).not.toHaveProperty('authorId');
  });

  it('rejects a watching entry that carries a revision', async () => {
    const res = await request(app)
      .post('/api/admin/compass/topics/33333333-3333-4333-8333-333333333333/journal')
      .send({ kind: 'watching', body: 'x', revisionId: '11111111-1111-4111-8111-111111111111' });

    expect(res.status).toBe(422);
    expect(h.create).not.toHaveBeenCalled();
  });

  it('rejects a blank body', async () => {
    const res = await request(app)
      .post('/api/admin/compass/topics/33333333-3333-4333-8333-333333333333/journal')
      .send({ kind: 'changed', body: '   ' });
    expect(res.status).toBe(400);
  });

  it('defaults the season when none is given', async () => {
    h.create.mockResolvedValue({ id: 'j1' });
    await request(app).post('/api/admin/compass/topics/33333333-3333-4333-8333-333333333333/journal')
      .send({ kind: 'changed', body: 'shipped' });
    expect(h.create.mock.calls[0][0].seasonId).toBe('s-open');
  });

  // 🔴 A write that guesses a season is worse than one that fails. There is no
  // correct fallback: stamping a closed season backdates the entry.
  it('fails loudly when no open or draft season exists', async () => {
    h.season.mockRejectedValue(new Error('NO_SEASON: nothing to attach to'));
    const res = await request(app).post('/api/admin/compass/topics/33333333-3333-4333-8333-333333333333/journal')
      .send({ kind: 'changed', body: 'shipped' });
    expect(res.status).toBe(409);
    expect(h.create).not.toHaveBeenCalled();
  });
});

describe('POST /journal/:id/publish', () => {
  it('publishes and answers 200', async () => {
    h.publish.mockResolvedValue(true);
    expect((await request(app).post('/api/admin/compass/journal/11111111-1111-4111-8111-111111111111/publish')).status).toBe(200);
  });

  it('answers 404 for an unknown id', async () => {
    h.publish.mockResolvedValue(false);
    expect((await request(app).post('/api/admin/compass/journal/22222222-2222-4222-8222-222222222222/publish')).status).toBe(404);
  });
});

describe('DELETE /journal/:id', () => {
  it('answers 409 when the entry is published, because published entries are edited', async () => {
    h.del.mockResolvedValue(false);
    const res = await request(app).delete('/api/admin/compass/journal/11111111-1111-4111-8111-111111111111');
    expect(res.status).toBe(409);
    expect(res.body.code).toBe('NOT_A_DRAFT');
  });
});

// ── Review fixes ────────────────────────────────────────────────────────────

/**
 * I7. The NO_SEASON guard protected only the IMPLICIT path. An explicit
 * seasonId was validated as a uuid and nothing more, so it could name a CLOSED
 * season — backdating the entry into a season it was not written for, which is
 * the exact harm resolveDefaultSeasonId refuses to commit for the default.
 */
describe('an explicit seasonId may not name a closed season', () => {
  it('refuses a closed season with 409', async () => {
    h.assertOpen.mockRejectedValue(new Error('SEASON_CLOSED: that season is closed'));
    const res = await request(app).post('/api/admin/compass/topics/33333333-3333-4333-8333-333333333333/journal')
      .send({ kind: 'changed', body: 'x', seasonId: '22222222-2222-4222-8222-222222222222' });
    expect(res.status).toBe(409);
    expect(h.create).not.toHaveBeenCalled();
  });

  it('accepts an open or draft season', async () => {
    h.assertOpen.mockResolvedValue(undefined);
    h.create.mockResolvedValue({ id: 'j1' });
    const res = await request(app).post('/api/admin/compass/topics/33333333-3333-4333-8333-333333333333/journal')
      .send({ kind: 'changed', body: 'x', seasonId: '22222222-2222-4222-8222-222222222222' });
    expect(res.status).toBe(201);
    expect(h.season).not.toHaveBeenCalled();
  });
});

/**
 * I6. A non-uuid id reached Postgres and raised 22P02, which the catch turned
 * into a 500. On the PUBLIC route that is a crawlable 500 for any bot following
 * a slug-shaped URL; here it is the wrong status for an ordinary typo.
 */
describe('a non-uuid path param is a 400, not a 500', () => {
  it('refuses a slug where an entry id belongs', async () => {
    const res = await request(app).post('/api/admin/compass/journal/not-a-uuid/publish');
    expect(res.status).toBe(400);
    expect(h.publish).not.toHaveBeenCalled();
  });
});

/**
 * I5. PATCH {"title": null} answered 200 {ok:true} and changed nothing, because
 * COALESCE($2, title) cannot tell "clear it" from "leave it". The API reported
 * success for work it did not do.
 */
describe('PATCH can clear a title, and says so honestly', () => {
  it('passes an explicit null through as a clear', async () => {
    h.update.mockResolvedValue(true);
    await request(app).patch('/api/admin/compass/journal/33333333-3333-4333-8333-333333333333')
      .send({ title: null });
    expect(h.update.mock.calls[0][1]).toEqual({ title: null });
  });

  it('sends no fields at all when the body is empty', async () => {
    h.update.mockResolvedValue(true);
    await request(app).patch('/api/admin/compass/journal/33333333-3333-4333-8333-333333333333')
      .send({});
    expect(h.update.mock.calls[0][1]).toEqual({});
  });
});
