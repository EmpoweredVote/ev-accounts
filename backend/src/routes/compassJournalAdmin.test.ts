import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const h = vi.hoisted(() => ({
  create: vi.fn(), update: vi.fn(), publish: vi.fn(), del: vi.fn(), season: vi.fn(),
}));
vi.mock('../lib/compassJournalService.js', () => ({
  createEntry: h.create, updateEntry: h.update, publishEntry: h.publish,
  deleteDraft: h.del, resolveDefaultSeasonId: h.season,
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
      .post('/api/admin/compass/topics/t1/journal')
      .send({ kind: 'watching', body: 'We are watching childcare.', authorId: 'u-someone-else' });

    expect(res.status).toBe(201);
    expect(h.create).toHaveBeenCalledWith(expect.anything(), 'u-admin');
    expect(h.create.mock.calls[0][0]).not.toHaveProperty('authorId');
  });

  it('rejects a watching entry that carries a revision', async () => {
    const res = await request(app)
      .post('/api/admin/compass/topics/t1/journal')
      .send({ kind: 'watching', body: 'x', revisionId: '11111111-1111-4111-8111-111111111111' });

    expect(res.status).toBe(422);
    expect(h.create).not.toHaveBeenCalled();
  });

  it('rejects a blank body', async () => {
    const res = await request(app)
      .post('/api/admin/compass/topics/t1/journal')
      .send({ kind: 'changed', body: '   ' });
    expect(res.status).toBe(400);
  });

  it('defaults the season when none is given', async () => {
    h.create.mockResolvedValue({ id: 'j1' });
    await request(app).post('/api/admin/compass/topics/t1/journal')
      .send({ kind: 'changed', body: 'shipped' });
    expect(h.create.mock.calls[0][0].seasonId).toBe('s-open');
  });

  // 🔴 A write that guesses a season is worse than one that fails. There is no
  // correct fallback: stamping a closed season backdates the entry.
  it('fails loudly when no open or draft season exists', async () => {
    h.season.mockRejectedValue(new Error('NO_SEASON: nothing to attach to'));
    const res = await request(app).post('/api/admin/compass/topics/t1/journal')
      .send({ kind: 'changed', body: 'shipped' });
    expect(res.status).toBe(409);
    expect(h.create).not.toHaveBeenCalled();
  });
});

describe('POST /journal/:id/publish', () => {
  it('publishes and answers 200', async () => {
    h.publish.mockResolvedValue(true);
    expect((await request(app).post('/api/admin/compass/journal/j1/publish')).status).toBe(200);
  });

  it('answers 404 for an unknown id', async () => {
    h.publish.mockResolvedValue(false);
    expect((await request(app).post('/api/admin/compass/journal/nope/publish')).status).toBe(404);
  });
});

describe('DELETE /journal/:id', () => {
  it('answers 409 when the entry is published, because published entries are edited', async () => {
    h.del.mockResolvedValue(false);
    const res = await request(app).delete('/api/admin/compass/journal/j1');
    expect(res.status).toBe(409);
    expect(res.body.code).toBe('NOT_A_DRAFT');
  });
});
