import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockTopic, mockSeason } = vi.hoisted(() => ({
  mockTopic: vi.fn(), mockSeason: vi.fn(),
}));
vi.mock('../lib/compassJournalService.js', () => ({
  listTopicJournal: mockTopic, listSeasonJournal: mockSeason,
}));
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import journalRouter from './compassJournal.js';

const app = express();
app.use('/api/compass', journalRouter);

beforeEach(() => { mockTopic.mockReset(); mockSeason.mockReset(); });

describe('GET /compass/topics/:topicId/journal', () => {
  it('returns the entries for that topic', async () => {
    mockTopic.mockResolvedValue([{ id: 'j1', topicId: 't1' }]);
    const res = await request(app).get('/api/compass/topics/33333333-3333-4333-8333-333333333333/journal');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([{ id: 'j1', topicId: 't1' }]);
    expect(mockTopic).toHaveBeenCalledWith('33333333-3333-4333-8333-333333333333');
  });

  it('answers 200 with an empty array for a topic with no entries', async () => {
    mockTopic.mockResolvedValue([]);
    const res = await request(app).get('/api/compass/topics/44444444-4444-4444-8444-444444444444/journal');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it('answers 500 with the house error shape when the service throws', async () => {
    mockTopic.mockRejectedValue(new Error('boom'));
    const res = await request(app).get('/api/compass/topics/33333333-3333-4333-8333-333333333333/journal');
    expect(res.status).toBe(500);
    expect(res.body.code).toBe('INTERNAL_ERROR');
  });
});

describe('GET /compass/journal', () => {
  it('passes the season number through as a number', async () => {
    mockSeason.mockResolvedValue([]);
    const res = await request(app).get('/api/compass/journal?season=3');
    expect(res.status).toBe(200);
    expect(mockSeason).toHaveBeenCalledWith(3);
  });

  it('rejects a non-numeric season with 400 rather than querying', async () => {
    const res = await request(app).get('/api/compass/journal?season=three');
    expect(res.status).toBe(400);
    expect(mockSeason).not.toHaveBeenCalled();
  });

  it('requires the season parameter', async () => {
    const res = await request(app).get('/api/compass/journal');
    expect(res.status).toBe(400);
    expect(mockSeason).not.toHaveBeenCalled();
  });
});

/**
 * I6 (public half). This route is anonymous and crawlable, so a slug-shaped URL
 * from any bot — /topics/childcare/journal — used to reach Postgres, raise
 * 22P02 and come back as a 500 with a log line.
 */
describe('a non-uuid topic id is a 400, not a crawlable 500', () => {
  it('refuses a slug without querying', async () => {
    const res = await request(app).get('/api/compass/topics/childcare/journal');
    expect(res.status).toBe(400);
    expect(mockTopic).not.toHaveBeenCalled();
  });
});

// `Number('')` is 0 and Number.isInteger(0) is true, so an empty ?season=
// queried for season zero instead of being refused.
describe('an empty season parameter is refused', () => {
  it('does not read it as season 0', async () => {
    const res = await request(app).get('/api/compass/journal?season=');
    expect(res.status).toBe(400);
    expect(mockSeason).not.toHaveBeenCalled();
  });
});
