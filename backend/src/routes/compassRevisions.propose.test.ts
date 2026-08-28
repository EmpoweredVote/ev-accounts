import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// compassRevisions.ts pulls in supabase.js/db.js transitively; without these
// mocks supabase.js's env validation process.exit(1)s in test. Mirrors
// readrankQuotesAdmin.test.ts.
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
    req.reviewerCapacity = 'editor';
    next();
  },
  reviewerCapacity: () => 'editor',
}));

const { mockLogAdminAction } = vi.hoisted(() => ({ mockLogAdminAction: vi.fn() }));
vi.mock('../lib/adminService.js', () => ({ logAdminAction: mockLogAdminAction }));

const { svc } = vi.hoisted(() => ({
  svc: {
    listOpenRevisions: vi.fn(),
    getRevisionForReview: vi.fn(),
    getTopicRevisionHistory: vi.fn(),
    getCurrentTopicContent: vi.fn(),
    proposeRevision: vi.fn(),
    approveRevision: vi.fn(),
    rejectRevision: vi.fn(),
    publishRevision: vi.fn(),
  },
}));
vi.mock('../lib/compassRevisionService.js', () => svc);

import compassRevisionsRouter from './compassRevisions.js';

const app = express();
app.use(express.json());
app.use('/api/compass/revisions', compassRevisionsRouter);

const LADDER = [1, 2, 3, 4, 5].map((v) => ({ value: v, text: `rung ${v}` }));
const BODY = {
  topic_key: 'taxes',
  change_class: 'substantive',
  title: 'Taxation and Public Spending',
  short_title: 'Taxes',
  question_text: 'How should government balance taxes and spending?',
  stances: LADDER,
  rationale: 'why',
  public_note: 'what changed, for readers',
  review_ref: null,
  rung_map: { 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 },
};

beforeEach(() => {
  mockLogAdminAction.mockReset();
  for (const fn of Object.values(svc)) fn.mockReset();
});

describe('GET /api/compass/revisions/current/:topicKey', () => {
  it('returns the current content', async () => {
    svc.getCurrentTopicContent.mockResolvedValueOnce({ topicKey: 'taxes', ladder: LADDER });
    const res = await request(app).get('/api/compass/revisions/current/taxes');
    expect(res.status).toBe(200);
    expect(res.body.topicKey).toBe('taxes');
  });

  it('maps NO_SUCH_TOPIC to 404', async () => {
    svc.getCurrentTopicContent.mockRejectedValueOnce(new Error('NO_SUCH_TOPIC: nope'));
    const res = await request(app).get('/api/compass/revisions/current/nope');
    expect(res.status).toBe(404);
    expect(res.body.code).toBe('NO_SUCH_TOPIC');
  });

  it('422s an invalid topic key without calling the service', async () => {
    const res = await request(app).get('/api/compass/revisions/current/NOT%20OK');
    expect(res.status).toBe(422);
    expect(svc.getCurrentTopicContent).not.toHaveBeenCalled();
  });
});

describe('POST /api/compass/revisions', () => {
  it('files a proposal and logs with capacity', async () => {
    svc.proposeRevision.mockResolvedValueOnce({ revision_id: 'rev-1' });
    const res = await request(app).post('/api/compass/revisions').send(BODY);
    expect(res.status).toBe(201);
    expect(res.body.revision_id).toBe('rev-1');
    expect(svc.proposeRevision).toHaveBeenCalledWith(
      expect.objectContaining({ topicKey: 'taxes', changeClass: 'substantive' }),
      'admin-1',
    );
    expect(mockLogAdminAction).toHaveBeenCalledWith(
      'admin-1', 'compass:revision:propose', null,
      expect.objectContaining({ capacity: 'editor', ladder_changed: true }),
    );
  });

  it('422s a ladder that is not exactly five rungs', async () => {
    const res = await request(app).post('/api/compass/revisions')
      .send({ ...BODY, stances: LADDER.slice(0, 4) });
    expect(res.status).toBe(422);
    expect(svc.proposeRevision).not.toHaveBeenCalled();
  });

  it('passes the RPC BAD_LADDER message through as 422', async () => {
    svc.proposeRevision.mockRejectedValueOnce(
      new Error('BAD_LADDER: rung values must be 1..5 with no duplicates'));
    const res = await request(app).post('/api/compass/revisions').send(BODY);
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('BAD_LADDER');
    expect(res.body.message).toMatch(/no duplicates/);
  });

  it('still returns 201 when only the audit log fails', async () => {
    svc.proposeRevision.mockResolvedValueOnce({ revision_id: 'rev-2' });
    mockLogAdminAction.mockRejectedValueOnce(new Error('audit down'));
    const res = await request(app).post('/api/compass/revisions').send(BODY);
    expect(res.status).toBe(201);
  });
});
