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
    const res = await request(app).get('/api/compass/topics/t1/journal');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([{ id: 'j1', topicId: 't1' }]);
    expect(mockTopic).toHaveBeenCalledWith('t1');
  });

  it('answers 200 with an empty array for a topic with no entries', async () => {
    mockTopic.mockResolvedValue([]);
    const res = await request(app).get('/api/compass/topics/t-none/journal');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it('answers 500 with the house error shape when the service throws', async () => {
    mockTopic.mockRejectedValue(new Error('boom'));
    const res = await request(app).get('/api/compass/topics/t1/journal');
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
