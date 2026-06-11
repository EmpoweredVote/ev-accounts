import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { getBoundary } from './informBoundaryService.js';

beforeEach(() => mockQuery.mockReset());

describe('getBoundary', () => {
  it('returns hasBoundary:false when no row matches', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    const out = await getBoundary('G4110', '9999999');
    expect(out).toEqual({ hasBoundary: false });
  });

  it('shapes a simplified boundary row into the API contract', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      geo_id: '0644000', mtfcc: 'G4110', name: 'Los Angeles city',
      minx: -118.6, miny: 33.7, maxx: -118.1, maxy: 34.3,
      geojson: '{"type":"MultiPolygon","coordinates":[[[[-118.2,34.0],[-118.1,34.0],[-118.1,34.1],[-118.2,34.0]]]]}',
    }] });
    const out = await getBoundary('G4110', '0644000');
    expect(out).toEqual({
      hasBoundary: true,
      layer: 'G4110',
      geoid: '0644000',
      name: 'Los Angeles city',
      bbox: [-118.6, 33.7, -118.1, 34.3],
      geojson: { type: 'MultiPolygon', coordinates: [[[[-118.2, 34.0], [-118.1, 34.0], [-118.1, 34.1], [-118.2, 34.0]]]] },
    });
    // Parameterized query: mtfcc + geo_id passed as params, never interpolated.
    const [, params] = mockQuery.mock.calls[0];
    expect(params).toEqual(['G4110', '0644000']);
  });

  it('returns hasBoundary:false when the geometry is null', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      geo_id: '0644000', mtfcc: 'G4110', name: 'x',
      minx: null, miny: null, maxx: null, maxy: null, geojson: null,
    }] });
    expect(await getBoundary('G4110', '0644000')).toEqual({ hasBoundary: false });
  });
});
