import { vi, describe, it, expect } from 'vitest';
import express from 'express';
import request from 'supertest';

vi.mock('../lib/db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: vi.fn() }));
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: { userId?: string }, _res: unknown, next: () => void) => { req.userId = 'admin-1'; next(); },
}));
vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
}));
const { mockGrid, mockSearch } = vi.hoisted(() => ({ mockGrid: vi.fn(), mockSearch: vi.fn() }));
vi.mock('../lib/readrankCoverageService.js', () => ({ getCoverageGrid: mockGrid, searchRaces: mockSearch }));

import router from './readrankCoverageAdmin.js';
const app = express();
app.use(express.json());
app.use('/api/admin/readrank-coverage', router);

const UUID = '216ead27-9e86-49f2-b21c-af659d114faf';

describe('GET /api/admin/readrank-coverage', () => {
  it('422 without a valid race_id', async () => {
    const res = await request(app).get('/api/admin/readrank-coverage?race_id=nope');
    expect(res.status).toBe(422);
  });
  it('returns the grid for a valid race_id', async () => {
    mockGrid.mockResolvedValueOnce({ questions: [], candidates: [], cells: [] });
    const res = await request(app).get(`/api/admin/readrank-coverage?race_id=${UUID}`);
    expect(res.status).toBe(200);
    expect(mockGrid).toHaveBeenCalledWith(UUID);
    expect(res.body).toEqual({ questions: [], candidates: [], cells: [] });
  });
});

describe('GET /api/admin/readrank-coverage/races', () => {
  it('422 without q', async () => {
    const res = await request(app).get('/api/admin/readrank-coverage/races');
    expect(res.status).toBe(422);
  });
  it('returns matches', async () => {
    mockSearch.mockResolvedValueOnce([{ raceId: 'r1', positionName: 'U.S. Senate Texas' }]);
    const res = await request(app).get('/api/admin/readrank-coverage/races?q=senate');
    expect(res.status).toBe(200);
    expect(mockSearch).toHaveBeenCalledWith('senate');
    expect(res.body).toEqual({ races: [{ raceId: 'r1', positionName: 'U.S. Senate Texas' }] });
  });
});
