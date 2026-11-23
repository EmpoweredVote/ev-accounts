import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// ---------------------------------------------------------------------------
// WHY THIS FILE EXISTS.
//
// PUT /my-lenses used to read a short payload as "delete everything I did not
// mention" (measured against production 2026-11-22: three lenses in, one
// survivor, HTTP 200). A deletion must now be NAMED in delete_keys. This is the
// last structural guard: one PUT may delete at most one lens, so "delete
// everything in one shot" is impossible rather than merely guarded.
// ---------------------------------------------------------------------------

const USER = '11111111-1111-4111-8111-111111111111';
const ACCESS_TOKEN = 'test-access-token';
const LENS = { key: 'u_7f3a91', name: 'Mine', topic_ids: [] as string[] };

const replaceUserLensesMock = vi.hoisted(() => vi.fn());
const findUnknownTopicIdsMock = vi.hoisted(() => vi.fn());

vi.mock('../lib/supabase.js', () => ({
  adminRpc: vi.fn(),
  supabaseAdmin: {},
  supabaseAnon: { schema: () => ({ from: () => ({ select: () => ({}) }) }) },
  createUserClient: vi.fn(),
  requestDb: vi.fn(),
}));

vi.mock('../lib/compassService.js', () => ({
  getCompassCompleteness: vi.fn(),
  getCompassTopics: vi.fn(),
  getTopicAnswerStats: vi.fn(),
  getCompassCategories: vi.fn(),
  getCompassLenses: vi.fn(),
  getCompassPoliticians: vi.fn(),
  getCompassPoliticianIds: vi.fn(),
  getCandidates: vi.fn(),
  getCandidateAnswers: vi.fn(),
  getPoliticianAnswers: vi.fn(),
  getResearchStates: vi.fn(),
  getCandidateResearchStates: vi.fn(),
  getPoliticianContext: vi.fn(),
  getPoliticianContextAll: vi.fn(),
  validateTopicIds: vi.fn(),
  isNoPromotedTopicsError: vi.fn(),
  saveSelectedTopics: vi.fn(),
  getSelectedTopics: vi.fn(),
  compareWithPoliticians: vi.fn(),
  getUserVerdicts: vi.fn(),
  getBatchPoliticianAnswers: vi.fn(),
  getPoliticianCitations: vi.fn(),
}));

vi.mock('../lib/compassUserLensService.js', () => ({
  getUserLenses: vi.fn(),
  replaceUserLenses: replaceUserLensesMock,
  findUnknownTopicIds: findUnknownTopicIdsMock,
  getRecalibrationFlags: vi.fn(),
  getAllRecalibrationFlags: vi.fn(),
  isLensKeyConflictError: vi.fn(),
}));

vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (req: express.Request, _res: express.Response, next: express.NextFunction) => {
    (req as express.Request & { userId: string; accessToken: string }).userId = USER;
    (req as express.Request & { userId: string; accessToken: string }).accessToken = ACCESS_TOKEN;
    next();
  },
  requireAuth: (req: express.Request, _res: express.Response, next: express.NextFunction) => {
    (req as express.Request & { userId: string; accessToken: string }).userId = USER;
    (req as express.Request & { userId: string; accessToken: string }).accessToken = ACCESS_TOKEN;
    next();
  },
}));

import compassRouter from './compass.js';

const app = express();
app.use(express.json());
app.use('/api/compass', compassRouter);

const put = (body: unknown) => request(app).put('/api/compass/my-lenses').send(body as object);

beforeEach(() => {
  vi.clearAllMocks();
  findUnknownTopicIdsMock.mockResolvedValue([]);
});

describe('PUT /api/compass/my-lenses — one deletion per request', () => {
  it('refuses a request that would delete two lenses', async () => {
    const res = await put({ lenses: [LENS], delete_keys: ['u_aaa001', 'u_bbb002'] });

    expect(res.status).toBe(422);
    expect(res.body.code).toBe('TOO_MANY_LENS_DELETIONS');
    expect(res.body.delete_keys).toEqual(['u_aaa001', 'u_bbb002']);
    // Refused whole: the service is never reached, so neither deletion happens.
    expect(replaceUserLensesMock).not.toHaveBeenCalled();
  });

  it('allows a request that deletes exactly one', async () => {
    replaceUserLensesMock.mockResolvedValue([]);

    const res = await put({ lenses: [LENS], delete_keys: ['u_aaa001'] });

    expect(res.status).toBe(200);
    expect(replaceUserLensesMock).toHaveBeenCalledWith(USER, [LENS], ['u_aaa001']);
  });

  it('counts a key named twice as one deletion', async () => {
    // 🔴 Review Focus 1. Array length is 2 and the lens count is 1. A cap counted
    // on length refuses a single legitimate deletion with a 422 the client cannot
    // act on, because nothing about its request was actually too big.
    replaceUserLensesMock.mockResolvedValue([]);

    const res = await put({ lenses: [LENS], delete_keys: ['u_aaa001', 'u_aaa001'] });

    expect(res.status).toBe(200);
  });
});
