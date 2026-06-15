import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockGetTopics, mockGetTopicByKey } = vi.hoisted(() => ({
  mockGetTopics: vi.fn(),
  mockGetTopicByKey: vi.fn(),
}));
vi.mock('../lib/topicsService.js', () => ({
  getTopics: mockGetTopics,
  getTopicByKey: mockGetTopicByKey,
}));
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import topicsRouter from './topics.js';

const app = express();
app.use('/api/topics', topicsRouter);

beforeEach(() => {
  mockGetTopics.mockReset();
  mockGetTopicByKey.mockReset();
});

describe('GET /api/topics', () => {
  it('200 with topic list', async () => {
    mockGetTopics.mockResolvedValueOnce({
      topics: [{ topicKey: 'housing', title: 'Housing', itemCount: 14, meetingCount: 9 }],
      uncategorizedCount: 0,
    });
    const res = await request(app).get('/api/topics');
    expect(res.status).toBe(200);
    expect(res.body.topics[0].topicKey).toBe('housing');
  });
});

describe('GET /api/topics/:key', () => {
  it('422 on a malformed key', async () => {
    const res = await request(app).get('/api/topics/Bad!Key');
    expect(res.status).toBe(422);
    expect(mockGetTopicByKey).not.toHaveBeenCalled();
  });

  it('404 when unknown', async () => {
    mockGetTopicByKey.mockResolvedValueOnce(null);
    const res = await request(app).get('/api/topics/nope');
    expect(res.status).toBe(404);
  });

  it('200 with topic detail', async () => {
    mockGetTopicByKey.mockResolvedValueOnce({
      topicKey: 'housing', title: 'Housing',
      items: [{ meetingId: 'm1', city: 'Bloomington', meetingType: 'City Council',
                date: '2026-02-18', playbackKind: 'youtube', sectionIndex: 2,
                sectionTitle: 'Ordinance 26-04', sectionType: 'discussion',
                startTime: 1843, status: 'predicted' }],
    });
    const res = await request(app).get('/api/topics/housing');
    expect(res.status).toBe(200);
    expect(res.body.items).toHaveLength(1);
    expect(mockGetTopicByKey).toHaveBeenCalledWith('housing');
  });
});
