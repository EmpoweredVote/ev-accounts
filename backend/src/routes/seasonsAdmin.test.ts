import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// seasonsAdmin.ts pulls in seasonCompositionService (db.js + supabase.js) and
// the auth middlewares at module scope. Without these mocks supabase.js's env
// validation process.exit(1)s in test. Mirrors readrankQuotesAdmin.test.ts.
vi.mock('../lib/db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: vi.fn() }));

vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: { userId?: string }, _res: unknown, next: () => void) => {
    req.userId = 'admin-1';
    next();
  },
}));
vi.mock('../middleware/requireCompassReviewer.js', () => ({
  requireCompassReviewer: (
    req: { reviewerCapacity?: string }, _res: unknown, next: () => void,
  ) => {
    req.reviewerCapacity = 'admin';
    next();
  },
  reviewerCapacity: () => 'admin',
}));

const { mockLogAdminAction } = vi.hoisted(() => ({ mockLogAdminAction: vi.fn() }));
vi.mock('../lib/adminService.js', () => ({ logAdminAction: mockLogAdminAction }));

const { svc } = vi.hoisted(() => ({
  svc: {
    listSeasons: vi.fn(),
    getComposition: vi.fn(),
    createDraftSeason: vi.fn(),
    updateDraftSeason: vi.fn(),
    deleteDraftSeason: vi.fn(),
    addTopicToSeason: vi.fn(),
    removeTopicFromSeason: vi.fn(),
    repinTopic: vi.fn(),
    openSeason: vi.fn(),
  },
}));
vi.mock('../lib/seasonCompositionService.js', () => svc);

import seasonsAdminRouter from './seasonsAdmin.js';

const app = express();
app.use(express.json());
app.use('/api/admin/seasons', seasonsAdminRouter);

const SEASON_ID = '11111111-1111-4111-8111-111111111111';
const TOPIC_ID = '22222222-2222-4222-8222-222222222222';

beforeEach(() => {
  mockLogAdminAction.mockReset();
  for (const fn of Object.values(svc)) fn.mockReset();
});

describe('GET /api/admin/seasons', () => {
  it('returns the seasons list', async () => {
    svc.listSeasons.mockResolvedValueOnce([{ id: SEASON_ID, number: 1 }]);
    const res = await request(app).get('/api/admin/seasons');
    expect(res.status).toBe(200);
    expect(res.body.seasons).toHaveLength(1);
  });
});

describe('GET /api/admin/seasons/composition', () => {
  it('passes the payload through', async () => {
    svc.getComposition.mockResolvedValueOnce({ open_season: null, draft_season: null, topics: [] });
    const res = await request(app).get('/api/admin/seasons/composition');
    expect(res.status).toBe(200);
    expect(res.body.topics).toEqual([]);
  });
});

describe('POST /api/admin/seasons/draft', () => {
  it('422s on a missing name without calling the service', async () => {
    const res = await request(app).post('/api/admin/seasons/draft')
      .send({ public_note: 'n' });
    expect(res.status).toBe(422);
    expect(svc.createDraftSeason).not.toHaveBeenCalled();
  });

  it('creates and logs with capacity', async () => {
    svc.createDraftSeason.mockResolvedValueOnce({ season_id: SEASON_ID, number: 2, question_count: 44 });
    const res = await request(app).post('/api/admin/seasons/draft')
      .send({ name: 'Season 2', public_note: 'the note', carry_from_open: true });
    expect(res.status).toBe(201);
    expect(res.body.question_count).toBe(44);
    expect(mockLogAdminAction).toHaveBeenCalledWith(
      'admin-1', 'compass:season:create-draft', null,
      expect.objectContaining({ capacity: 'admin', season_id: SEASON_ID }),
    );
  });

  it('maps DRAFT_EXISTS to 409 with the code', async () => {
    svc.createDraftSeason.mockRejectedValueOnce(
      new Error('DRAFT_EXISTS: a draft season already exists — edit it or delete it first'));
    const res = await request(app).post('/api/admin/seasons/draft')
      .send({ name: 'S2', public_note: 'n' });
    expect(res.status).toBe(409);
    expect(res.body.code).toBe('DRAFT_EXISTS');
    expect(mockLogAdminAction).not.toHaveBeenCalled();
  });
});

describe('POST /api/admin/seasons/draft/:id/open', () => {
  it('preserves the human message on SCAFFOLD_INDEXES_PRESENT', async () => {
    svc.openSeason.mockRejectedValueOnce(new Error(
      'SCAFFOLD_INDEXES_PRESENT: the CC_0002 scaffolding indexes still limit answers to one season. Dropping them is rollout step 3 (ADR 0005 §1.6) and an explicit operational migration — apply that first, then open the season'));
    const res = await request(app).post(`/api/admin/seasons/draft/${SEASON_ID}/open`);
    expect(res.status).toBe(409);
    expect(res.body.code).toBe('SCAFFOLD_INDEXES_PRESENT');
    expect(res.body.message).toMatch(/rollout step 3/);
  });

  it('opens and logs', async () => {
    svc.openSeason.mockResolvedValueOnce(
      { opened_season_id: SEASON_ID, closed_season_id: 'x', question_count: 44 });
    const res = await request(app).post(`/api/admin/seasons/draft/${SEASON_ID}/open`);
    expect(res.status).toBe(200);
    expect(mockLogAdminAction).toHaveBeenCalledWith(
      'admin-1', 'compass:season:open', null,
      expect.objectContaining({ opened_season_id: SEASON_ID }),
    );
  });
});

describe('topic mutations', () => {
  it('422s on an invalid topic uuid', async () => {
    const res = await request(app).post(`/api/admin/seasons/draft/${SEASON_ID}/topics`)
      .send({ topic_id: 'not-a-uuid' });
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('VALIDATION_ERROR');
  });

  it('removes a topic and logs', async () => {
    svc.removeTopicFromSeason.mockResolvedValueOnce({ removed_topic_id: TOPIC_ID });
    const res = await request(app)
      .delete(`/api/admin/seasons/draft/${SEASON_ID}/topics/${TOPIC_ID}`);
    expect(res.status).toBe(200);
    expect(mockLogAdminAction).toHaveBeenCalledWith(
      'admin-1', 'compass:season:remove-topic', null,
      expect.objectContaining({ topic_id: TOPIC_ID }),
    );
  });

  it('maps an unknown error to 500 INTERNAL_ERROR', async () => {
    svc.addTopicToSeason.mockRejectedValueOnce(new Error('connection reset'));
    const res = await request(app).post(`/api/admin/seasons/draft/${SEASON_ID}/topics`)
      .send({ topic_id: TOPIC_ID });
    expect(res.status).toBe(500);
    expect(res.body.code).toBe('INTERNAL_ERROR');
  });
});
