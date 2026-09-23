import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// ---------------------------------------------------------------------------
// WHY THIS FILE EXISTS.
//
// GET /compass/answers and POST /compass/answers/batch read
// inform.compass_responses_effective through requestDb(). On the WorkOS-token
// path requestDb() returns the service-role client, which BYPASSES RLS — so the
// route, not the database, is what confines the read to the caller. The routes
// used to omit the owner predicate and lean on RLS alone. That was two bugs at
// once:
//
//   1. Data exposure — the service-role client returned every user's answers.
//   2. Latency — with no user filter the disposition LEFT JOIN in the view runs
//      O(rows²) over the whole table (measured ~3.7s for ~200 rows; ~350ms once
//      scoped to a single user).
//
// These tests pin that both routes send .eq('user_id', <caller>) to the client.
// ---------------------------------------------------------------------------

const USER = '11111111-1111-4111-8111-111111111111';
const ACCESS_TOKEN = 'test-access-token';

// Records every builder call so the test can assert the query was scoped.
const eqMock = vi.hoisted(() => vi.fn());
const requestDbMock = vi.hoisted(() => vi.fn());

// A chainable stub matching the supabase-js query builder surface the routes
// use: .schema().from().eq().select().in().is() and a terminal await → {data}.
function makeBuilder() {
  const builder: Record<string, unknown> = {};
  const passthrough = () => builder;
  builder.schema = passthrough;
  builder.from = passthrough;
  builder.select = passthrough;
  builder.in = passthrough;
  builder.eq = (col: string, val: unknown) => { eqMock(col, val); return builder; };
  // `.is('deleted_at', null)` is the terminal call the routes await.
  builder.is = () => Promise.resolve({ data: [], error: null });
  return builder;
}

vi.mock('../lib/supabase.js', () => ({
  adminRpc: vi.fn(),
  supabaseAdmin: {},
  supabaseAnon: { schema: () => ({ from: () => ({ select: () => ({}) }) }) },
  createUserClient: vi.fn(),
  requestDb: requestDbMock,
}));

// No promoteCompassImportDraft stub, on purpose: GET /answers no longer runs the
// lazy draft promotion (the legacy import that wrote drafts is gone), and vitest
// throws if the route reaches for an export this mock does not define.
vi.mock('../lib/compassService.js', () => ({
  getCompassCompleteness: vi.fn(),
  getCompassTopics: vi.fn(),
  getCompassCategories: vi.fn(),
  getCompassLenses: vi.fn(),
  getCompassPoliticians: vi.fn(),
  getCandidates: vi.fn(),
  getCandidateAnswers: vi.fn(),
  getPoliticianAnswers: vi.fn(),
  getPoliticianContext: vi.fn(),
  getPoliticianContextAll: vi.fn(),
  validateTopicIds: vi.fn(),
  isNoPromotedTopicsError: vi.fn(),
  saveSelectedTopics: vi.fn(),
  getSelectedTopics: vi.fn(),
  resetCompassAnswers: vi.fn(),
  compareWithPoliticians: vi.fn(),
  getUserVerdicts: vi.fn(),
  getBatchPoliticianAnswers: vi.fn(),
  getPoliticianCitations: vi.fn(),
}));

// User-lens service is imported by the router at load time; stub the surface.
vi.mock('../lib/compassUserLensService.js', () => ({
  getUserLenses: vi.fn(),
  replaceUserLenses: vi.fn(),
}));

// optionalAuth resolves the caller. Inject a fixed authenticated identity so
// the route reaches the query builder we are asserting on.
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

beforeEach(() => {
  vi.clearAllMocks();
  requestDbMock.mockImplementation(() => makeBuilder());
});

describe('GET /api/compass/answers — owner scoping', () => {
  it('scopes the read to the caller (.eq user_id)', async () => {
    const res = await request(app).get('/api/compass/answers');

    expect(res.status).toBe(200);
    expect(requestDbMock).toHaveBeenCalledWith(ACCESS_TOKEN);
    expect(eqMock).toHaveBeenCalledWith('user_id', USER);
  });
});

describe('POST /api/compass/answers/batch — owner scoping', () => {
  it('scopes the read to the caller (.eq user_id) alongside the topic filter', async () => {
    const res = await request(app)
      .post('/api/compass/answers/batch')
      .send({ ids: ['22222222-2222-4222-8222-222222222222'] });

    expect(res.status).toBe(200);
    expect(eqMock).toHaveBeenCalledWith('user_id', USER);
  });
});
