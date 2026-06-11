import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockGetBoundary } = vi.hoisted(() => ({ mockGetBoundary: vi.fn() }));
vi.mock('../lib/informBoundaryService.js', () => ({ getBoundary: mockGetBoundary }));

import informRouter from './inform.js';

const app = express();
app.use('/api/inform', informRouter);

beforeEach(() => mockGetBoundary.mockReset());

describe('GET /api/inform/boundary', () => {
  it('422 when layer or geoid is missing', async () => {
    const res = await request(app).get('/api/inform/boundary?layer=G4110');
    expect(res.status).toBe(422);
    expect(mockGetBoundary).not.toHaveBeenCalled();
  });

  it('200 with the boundary payload', async () => {
    mockGetBoundary.mockResolvedValueOnce({ hasBoundary: true, layer: 'G4110', geoid: '0644000', name: 'Los Angeles city', bbox: [0, 0, 1, 1], geojson: { type: 'Polygon', coordinates: [] } });
    const res = await request(app).get('/api/inform/boundary?layer=G4110&geoid=0644000');
    expect(res.status).toBe(200);
    expect(res.body.name).toBe('Los Angeles city');
    expect(mockGetBoundary).toHaveBeenCalledWith('G4110', '0644000');
  });

  it('200 with hasBoundary:false when absent (not an error)', async () => {
    mockGetBoundary.mockResolvedValueOnce({ hasBoundary: false });
    const res = await request(app).get('/api/inform/boundary?layer=G4110&geoid=zzz');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ hasBoundary: false });
  });
});
