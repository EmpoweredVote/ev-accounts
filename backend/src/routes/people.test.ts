import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockGetPeople, mockGetPersonById, mockGetAppearancesById } = vi.hoisted(() => ({
  mockGetPeople: vi.fn(),
  mockGetPersonById: vi.fn(),
  mockGetAppearancesById: vi.fn(),
}));
vi.mock('../lib/peopleService.js', () => ({
  getPeople: mockGetPeople,
  getPersonById: mockGetPersonById,
  getAppearancesById: mockGetAppearancesById,
}));
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import peopleRouter from './people.js';

const app = express();
app.use('/api/people', peopleRouter);

const POL_ID = '11111111-1111-1111-1111-111111111111';

const samplePerson = {
  politicianId: POL_ID,
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
  mockGetPersonById.mockReset();
  mockGetAppearancesById.mockReset();
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

describe('GET /api/people/:id', () => {
  it('422 on a non-UUID id, service not called', async () => {
    const res = await request(app).get('/api/people/not-a-uuid');
    expect(res.status).toBe(422);
    expect(mockGetPersonById).not.toHaveBeenCalled();
  });

  it('404 when the person is unknown', async () => {
    mockGetPersonById.mockResolvedValueOnce(null);
    const res = await request(app).get(`/api/people/${POL_ID}`);
    expect(res.status).toBe(404);
  });

  it('200 with the person detail', async () => {
    mockGetPersonById.mockResolvedValueOnce({ ...samplePerson, bioText: 'Mayor since 2016.' });
    const res = await request(app).get(`/api/people/${POL_ID}`);
    expect(res.status).toBe(200);
    expect(res.body.bioText).toBe('Mayor since 2016.');
    expect(mockGetPersonById).toHaveBeenCalledWith(POL_ID);
  });
});

describe('GET /api/people/:id/appearances', () => {
  it('422 on a non-UUID id, service not called', async () => {
    const res = await request(app).get('/api/people/not-a-uuid/appearances');
    expect(res.status).toBe(422);
    expect(mockGetAppearancesById).not.toHaveBeenCalled();
  });

  it('200 with id and appearances', async () => {
    const appearance = {
      meetingId: '22222222-2222-2222-2222-222222222222',
      city: 'Bloomington',
      meetingType: 'City Council',
      date: '2026-02-18',
      playbackKind: 'youtube',
      segments: [{ segmentIndex: 4, startTime: 120.5, endTime: 150, text: 'Thank you.' }],
    };
    mockGetAppearancesById.mockResolvedValueOnce([appearance]);
    const res = await request(app).get(`/api/people/${POL_ID}/appearances`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ id: POL_ID, appearances: [appearance] });
    expect(mockGetAppearancesById).toHaveBeenCalledWith(POL_ID);
  });
});
