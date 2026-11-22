import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// ---------------------------------------------------------------------------
// WHY THIS FILE EXISTS.
//
// Every other write to compass_responses carries a value, because every other
// write is an answer. Abandoning a write-in is not one: the user discards what
// they typed and the question goes back to unanswered, so there is no value to
// post — and `postAnswerSchema` answers a null value with a 422, correctly,
// because no number means "not answered".
//
// So there was nothing the client could call. It cleared its own state, the
// server kept the row, and the next hydration handed the cancelled write-in
// back: a question the user had explicitly abandoned, in their own words,
// returning on the next page load. DELETE /answers/:topicId is the missing
// verb.
//
// The route-ordering test below is the one worth keeping honest. It is not
// hypothetical bookkeeping — see its own comment.
// ---------------------------------------------------------------------------

const USER = '11111111-1111-4111-8111-111111111111';
const OTHER_USER = '99999999-9999-4999-8999-999999999999';
const TOPIC = '22222222-2222-4222-8222-222222222222';
const ACCESS_TOKEN = 'test-access-token';

const clearCompassAnswerMock = vi.hoisted(() => vi.fn());
const resetCompassAnswersMock = vi.hoisted(() => vi.fn());

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
  resetCompassAnswers: resetCompassAnswersMock,
  clearCompassAnswer: clearCompassAnswerMock,
  compareWithPoliticians: vi.fn(),
  getUserVerdicts: vi.fn(),
  getBatchPoliticianAnswers: vi.fn(),
  getPoliticianCitations: vi.fn(),
}));

vi.mock('../lib/compassUserLensService.js', () => ({
  getUserLenses: vi.fn(),
  replaceUserLenses: vi.fn(),
  findUnknownTopicIds: vi.fn(),
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

beforeEach(() => {
  vi.clearAllMocks();
  clearCompassAnswerMock.mockResolvedValue(1);
  resetCompassAnswersMock.mockResolvedValue(undefined);
});

describe('DELETE /api/compass/answers/:topicId', () => {
  it('clears the caller’s answer to that topic', async () => {
    const res = await request(app).delete(`/api/compass/answers/${TOPIC}`);

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ cleared: 1 });
    expect(clearCompassAnswerMock).toHaveBeenCalledWith(USER, TOPIC);
  });

  it('is idempotent — cancelling twice is not an error', async () => {
    // The client fires this on a gesture, and the gesture is repeatable: the ×
    // on an already-cleared card, a retry after a dropped response. A 404 here
    // would make the client decide whether its own cancel had "worked", which
    // is a question with no useful answer.
    clearCompassAnswerMock.mockResolvedValue(0);

    const res = await request(app).delete(`/api/compass/answers/${TOPIC}`);

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ cleared: 0 });
  });

  it('takes the owner from the session, never from the request', async () => {
    // There is no route by which a caller names whose answer to clear. Pinned
    // because the obvious "improvement" — accepting a user_id for an admin
    // tool — would turn this into a way to delete other people's answers.
    const res = await request(app)
      .delete(`/api/compass/answers/${TOPIC}`)
      .send({ user_id: OTHER_USER });

    expect(res.status).toBe(200);
    expect(clearCompassAnswerMock).toHaveBeenCalledWith(USER, TOPIC);
    expect(clearCompassAnswerMock).not.toHaveBeenCalledWith(OTHER_USER, expect.anything());
  });

  it('rejects a topic id that is not a UUID', async () => {
    const res = await request(app).delete('/api/compass/answers/not-a-uuid');

    expect(res.status).toBe(422);
    expect(res.body.code).toBe('VALIDATION_ERROR');
    expect(clearCompassAnswerMock).not.toHaveBeenCalled();
  });

  it('answers 500 rather than leaking the error when the clear throws', async () => {
    clearCompassAnswerMock.mockRejectedValue(new Error('connection terminated unexpectedly'));

    const res = await request(app).delete(`/api/compass/answers/${TOPIC}`);

    expect(res.status).toBe(500);
    expect(res.body.code).toBe('INTERNAL_ERROR');
    expect(JSON.stringify(res.body)).not.toContain('connection terminated');
  });
});

describe('DELETE /api/compass/answers/me — still the full reset', () => {
  // 🔴 THIS IS THE TRAP, NOT A FORMALITY. Express matches routes in
  // registration order. `/answers/me` is declared well above
  // `/answers/:topicId`, and it has to stay that way: move the new route up and
  // `me` binds to `:topicId`, fails the UUID check, and Reset Compass starts
  // answering 422 — a silent loss of a destructive-but-wanted feature, with
  // nothing in the logs to say why. The UUID check is the second line of
  // defence here, not the first.
  it('resets everything and does not reach the single-topic clear', async () => {
    const res = await request(app).delete('/api/compass/answers/me');

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ reset: true });
    expect(resetCompassAnswersMock).toHaveBeenCalledWith(USER, false);
    expect(clearCompassAnswerMock).not.toHaveBeenCalled();
  });
});
