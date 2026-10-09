import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockGetPlayableRaces, mockFindLocalities } = vi.hoisted(() => ({ mockGetPlayableRaces: vi.fn(), mockFindLocalities: vi.fn() }));
vi.mock('../lib/db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('../lib/readrankLocalities.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../lib/readrankLocalities.js')>()),
  findLocalities: mockFindLocalities,
}));
vi.mock('../lib/readrankService.js', () => ({
  getPlayableRaces: mockGetPlayableRaces,
  getRaceBlindQuotes: vi.fn(),
  computeRaceMatch: vi.fn(),
}));

import readrankRouter from './readrank.js';

const app = express();
app.use(express.json());
app.use('/api/readrank', readrankRouter);

const uuid = (i: number) => `00000000-0000-4000-8000-${String(i).padStart(12, '0')}`;
const JURISDICTION = {
  congressional: '0634',
  state_senate: null,
  state_house: null,
  county: '06037',
  school_district: null,
};

beforeEach(() => {
  mockGetPlayableRaces.mockReset();
  mockFindLocalities.mockReset();
  mockGetPlayableRaces.mockResolvedValue({ races: [{ raceId: 'r1' }], counties: { '06037': 'Los Angeles' } });
});

describe('GET /api/readrank/races', () => {
  it('parses query params as before', async () => {
    const res = await request(app)
      .get('/api/readrank/races')
      .query({ politician_ids: `${uuid(1)},bogus,${uuid(2)}`, cd: '0634', county: '06037', embed: uuid(9), embed_local: '1' });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ races: [{ raceId: 'r1' }], counties: { '06037': 'Los Angeles' } });
    expect(mockGetPlayableRaces).toHaveBeenCalledWith([uuid(1), uuid(2)], JURISDICTION, [uuid(9)], true);
  });

  it('passes undefined for absent inputs', async () => {
    await request(app).get('/api/readrank/races');
    expect(mockGetPlayableRaces).toHaveBeenCalledWith(undefined, undefined, undefined, false);
  });
});

describe('POST /api/readrank/races', () => {
  it('accepts a large roster in the body (the LA case, ~500 ids)', async () => {
    const ids = Array.from({ length: 500 }, (_, i) => uuid(i));
    const res = await request(app)
      .post('/api/readrank/races')
      .send({ politician_ids: ids, cd: '0634', county: '06037', embed_local: true });
    expect(res.status).toBe(200);
    expect(res.body.races).toEqual([{ raceId: 'r1' }]);
    expect(mockGetPlayableRaces).toHaveBeenCalledWith(ids, JURISDICTION, undefined, true);
  });

  it('matches GET for the same inputs', async () => {
    const query = { politician_ids: `${uuid(1)},${uuid(2)}`, cd: '0634', county: '06037', embed: uuid(9), embed_local: '1' };
    await request(app).get('/api/readrank/races').query(query);
    await request(app).post('/api/readrank/races').send({
      politician_ids: [uuid(1), uuid(2)], cd: '0634', county: '06037', embed: [uuid(9)], embed_local: true,
    });
    expect(mockGetPlayableRaces.mock.calls[1]).toEqual(mockGetPlayableRaces.mock.calls[0]);
  });

  it('drops invalid ids, like GET', async () => {
    await request(app).post('/api/readrank/races').send({ politician_ids: [uuid(1), 'nope', 42] });
    expect(mockGetPlayableRaces).toHaveBeenCalledWith([uuid(1)], undefined, undefined, false);
  });

  it('treats an empty body as no filters', async () => {
    const res = await request(app).post('/api/readrank/races');
    expect(res.status).toBe(200);
    expect(mockGetPlayableRaces).toHaveBeenCalledWith(undefined, undefined, undefined, false);
  });

  it('422 when politician_ids is not an array', async () => {
    const res = await request(app).post('/api/readrank/races').send({ politician_ids: { a: 1 } });
    expect(res.status).toBe(422);
    expect(mockGetPlayableRaces).not.toHaveBeenCalled();
  });

  it('422 when the roster exceeds the cap', async () => {
    const ids = Array.from({ length: 2001 }, (_, i) => uuid(i));
    const res = await request(app).post('/api/readrank/races').send({ politician_ids: ids });
    expect(res.status).toBe(422);
    expect(mockGetPlayableRaces).not.toHaveBeenCalled();
  });

  it('500 without leaking details when the service throws', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    mockGetPlayableRaces.mockRejectedValue(new Error('db down'));
    const res = await request(app).post('/api/readrank/races').send({ politician_ids: [uuid(1)] });
    expect(res.status).toBe(500);
    expect(res.body).toEqual({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  });
});

describe('GET /api/readrank/localities', () => {
  it('422 on missing q', async () => {
    const res = await request(app).get('/api/readrank/localities');
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('VALIDATION_ERROR');
    expect(mockFindLocalities).not.toHaveBeenCalled();
  });
  it('422 on too-short q, bad chars, bad state', async () => {
    for (const query of [{ q: 'a' }, { q: 'Irv<ine' }, { q: 'x'.repeat(61) }, { q: 'Irvine', state: 'CAL' }, { q: 'Irvine', state: '1' }]) {
      const res = await request(app).get('/api/readrank/localities').query(query);
      expect(res.status).toBe(422);
      expect(res.body.code).toBe('VALIDATION_ERROR');
    }
  });
  it('uppercases state and returns localities', async () => {
    const rows = [{ name: 'Irvine', state: 'CA', placeGeoid: '0636770', countyGeoid: '06059' }];
    mockFindLocalities.mockResolvedValue(rows);
    const res = await request(app).get('/api/readrank/localities').query({ q: ' Irvine ', state: 'ca' });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ localities: rows });
    expect(mockFindLocalities).toHaveBeenCalledWith('Irvine', 'CA');
  });
  it('passes null state when omitted; empty result is 200 []', async () => {
    mockFindLocalities.mockResolvedValue([]);
    const res = await request(app).get('/api/readrank/localities').query({ q: 'Nowhere' });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ localities: [] });
    expect(mockFindLocalities).toHaveBeenCalledWith('Nowhere', null);
  });
  it('500 INTERNAL_ERROR on DB error', async () => {
    mockFindLocalities.mockRejectedValue(new Error('db down'));
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {});
    const res = await request(app).get('/api/readrank/localities').query({ q: 'Irvine' });
    expect(res.status).toBe(500);
    expect(res.body.code).toBe('INTERNAL_ERROR');
    spy.mockRestore();
  });
});
