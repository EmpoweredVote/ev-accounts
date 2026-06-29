import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockSearchSegments } = vi.hoisted(() => ({ mockSearchSegments: vi.fn() }));
vi.mock('../lib/searchService.js', () => ({
  searchSegments: mockSearchSegments,
  SEARCH_PAGE_SIZE: 25,
}));
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import searchRouter from './search.js';

const app = express();
app.use('/api/search', searchRouter);

const sampleResponse = {
  query: 'housing',
  page: 1,
  totalCount: 1,
  results: [
    {
      meetingId: '22222222-2222-2222-2222-222222222222',
      title: null,
      eventKind: 'council',
      eventOrgs: [],
      sourceTitle: null,
      city: 'Bloomington',
      meetingType: 'City Council',
      date: '2026-02-18',
      segmentIndex: 42,
      startTime: 1843.2,
      endTime: 1851,
      speakerName: 'John Hamilton',
      politicianId: '11111111-1111-1111-1111-111111111111',
      snippet: 'we have to talk about [[[housing]]] before the',
    },
  ],
};

beforeEach(() => mockSearchSegments.mockReset());

describe('GET /api/search validation', () => {
  it('422 when q is missing', async () => {
    const res = await request(app).get('/api/search');
    expect(res.status).toBe(422);
    expect(mockSearchSegments).not.toHaveBeenCalled();
  });

  it('422 when q is only whitespace', async () => {
    const res = await request(app).get('/api/search?q=%20%20');
    expect(res.status).toBe(422);
    expect(mockSearchSegments).not.toHaveBeenCalled();
  });

  it('422 when q exceeds 200 characters', async () => {
    const res = await request(app).get(`/api/search?q=${'a'.repeat(201)}`);
    expect(res.status).toBe(422);
    expect(mockSearchSegments).not.toHaveBeenCalled();
  });

  it('422 when page is not a positive integer', async () => {
    const res = await request(app).get('/api/search?q=housing&page=0');
    expect(res.status).toBe(422);
    expect(mockSearchSegments).not.toHaveBeenCalled();
  });

  it('422 when speaker is not a valid politician id', async () => {
    const res = await request(app).get('/api/search?q=housing&speaker=Bad!Slug');
    expect(res.status).toBe(422);
    expect(mockSearchSegments).not.toHaveBeenCalled();
  });

  it('422 when speaker is a valid slug but not a UUID', async () => {
    const res = await request(app).get('/api/search?q=housing&speaker=john-hamilton');
    expect(res.status).toBe(422);
    expect(mockSearchSegments).not.toHaveBeenCalled();
  });

  it('422 when page exceeds the cap', async () => {
    const res = await request(app).get('/api/search?q=housing&page=401');
    expect(res.status).toBe(422);
    expect(mockSearchSegments).not.toHaveBeenCalled();
  });
});

describe('GET /api/search results', () => {
  it('200 with the search response, defaults applied', async () => {
    mockSearchSegments.mockResolvedValueOnce(sampleResponse);
    const res = await request(app).get('/api/search?q=housing');
    expect(res.status).toBe(200);
    expect(res.body).toEqual(sampleResponse);
    expect(mockSearchSegments).toHaveBeenCalledWith({
      q: 'housing',
      city: undefined,
      speaker: undefined,
      page: 1,
    });
  });

  it('passes city, speaker, and page through', async () => {
    mockSearchSegments.mockResolvedValueOnce({ ...sampleResponse, page: 3 });
    const res = await request(app).get(
      '/api/search?q=housing&city=Bloomington&speaker=33333333-3333-3333-3333-333333333333&page=3'
    );
    expect(res.status).toBe(200);
    expect(mockSearchSegments).toHaveBeenCalledWith({
      q: 'housing',
      city: 'Bloomington',
      speaker: '33333333-3333-3333-3333-333333333333',
      page: 3,
    });
  });

  it('200 with zero results is not an error', async () => {
    mockSearchSegments.mockResolvedValueOnce({
      query: 'zzzz',
      page: 1,
      totalCount: 0,
      results: [],
    });
    const res = await request(app).get('/api/search?q=zzzz');
    expect(res.status).toBe(200);
    expect(res.body.totalCount).toBe(0);
    expect(res.body.results).toEqual([]);
  });

  it('500 with INTERNAL_ERROR when the service throws', async () => {
    mockSearchSegments.mockRejectedValueOnce(new Error('db down'));
    const res = await request(app).get('/api/search?q=housing');
    expect(res.status).toBe(500);
    expect(res.body.code).toBe('INTERNAL_ERROR');
  });
});
