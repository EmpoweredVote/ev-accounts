import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockGetPeople, mockGetPersonBySlug, mockGetAppearancesBySlug } = vi.hoisted(() => ({
  mockGetPeople: vi.fn(),
  mockGetPersonBySlug: vi.fn(),
  mockGetAppearancesBySlug: vi.fn(),
}));
vi.mock('../lib/peopleService.js', () => ({
  getPeople: mockGetPeople,
  getPersonBySlug: mockGetPersonBySlug,
  getAppearancesBySlug: mockGetAppearancesBySlug,
}));
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import peopleRouter from './people.js';

const app = express();
app.use('/api/people', peopleRouter);

const samplePerson = {
  slug: 'john-hamilton',
  politicianId: '11111111-1111-1111-1111-111111111111',
  name: 'John Hamilton',
  headshotUrl: null,
  party: 'Democratic',
  officeTitle: 'Mayor',
  district: null,
  jurisdiction: 'Bloomington',
  meetingCount: 3,
  cities: ['Bloomington'],
  lastSpokeDate: '2026-02-18',
};

beforeEach(() => {
  mockGetPeople.mockReset();
  mockGetPersonBySlug.mockReset();
  mockGetAppearancesBySlug.mockReset();
});

describe('GET /api/people', () => {
  it('200 with the roster', async () => {
    mockGetPeople.mockResolvedValueOnce([samplePerson]);
    const res = await request(app).get('/api/people');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([samplePerson]);
    expect(mockGetPeople).toHaveBeenCalledWith(undefined);
  });

  it('passes the city filter through', async () => {
    mockGetPeople.mockResolvedValueOnce([]);
    const res = await request(app).get('/api/people?city=Bloomington');
    expect(res.status).toBe(200);
    expect(mockGetPeople).toHaveBeenCalledWith({ city: 'Bloomington' });
  });
});

describe('GET /api/people/:slug', () => {
  it('422 on an invalid slug, service not called', async () => {
    const res = await request(app).get('/api/people/Bad!Slug');
    expect(res.status).toBe(422);
    expect(mockGetPersonBySlug).not.toHaveBeenCalled();
  });

  it('404 when the person is unknown', async () => {
    mockGetPersonBySlug.mockResolvedValueOnce(null);
    const res = await request(app).get('/api/people/nobody-here');
    expect(res.status).toBe(404);
  });

  it('200 with the person detail', async () => {
    mockGetPersonBySlug.mockResolvedValueOnce({ ...samplePerson, bioText: 'Mayor since 2016.' });
    const res = await request(app).get('/api/people/john-hamilton');
    expect(res.status).toBe(200);
    expect(res.body.bioText).toBe('Mayor since 2016.');
    expect(mockGetPersonBySlug).toHaveBeenCalledWith('john-hamilton');
  });
});

describe('GET /api/people/:slug/appearances', () => {
  it('422 on an invalid slug, service not called', async () => {
    const res = await request(app).get('/api/people/Bad!Slug/appearances');
    expect(res.status).toBe(422);
    expect(mockGetAppearancesBySlug).not.toHaveBeenCalled();
  });

  it('200 with slug and appearances', async () => {
    const appearance = {
      meetingId: '22222222-2222-2222-2222-222222222222',
      city: 'Bloomington',
      meetingType: 'City Council',
      date: '2026-02-18',
      playbackKind: 'youtube',
      segments: [{ segmentIndex: 4, startTime: 120.5, endTime: 150, text: 'Thank you.' }],
    };
    mockGetAppearancesBySlug.mockResolvedValueOnce([appearance]);
    const res = await request(app).get('/api/people/john-hamilton/appearances');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ slug: 'john-hamilton', appearances: [appearance] });
  });
});
