import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { getBoundary, getBoundaryBatch, getCountyUnionFrames, getDistrictCountyGeoIds, getStateCountyGeoIds, getCountyNames } from './informBoundaryService.js';

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

describe('getBoundaryBatch', () => {
  it('returns an empty map immediately when refs is empty (no DB query)', async () => {
    const result = await getBoundaryBatch([]);
    expect(result).toEqual(new Map());
    expect(mockQuery).not.toHaveBeenCalled();
  });

  it('deduplicates refs and fires one query', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getBoundaryBatch([
      { layer: 'G4110', geoid: '1805860' },
      { layer: 'G4110', geoid: '1805860' }, // duplicate
    ]);
    expect(mockQuery).toHaveBeenCalledTimes(1);
  });

  it('returns a map keyed by "layer:geoid" for matching rows', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [
      {
        geo_id: '1805860', mtfcc: 'G4110', name: 'Bloomington city',
        minx: -86.6, miny: 39.1, maxx: -86.4, maxy: 39.3,
        geojson: '{"type":"Polygon","coordinates":[[[-86.6,39.1],[-86.4,39.1],[-86.4,39.3],[-86.6,39.1]]]}',
      },
    ] });
    const result = await getBoundaryBatch([{ layer: 'G4110', geoid: '1805860' }]);
    expect(result.size).toBe(1);
    expect(result.get('G4110:1805860')).toMatchObject({
      hasBoundary: true,
      layer: 'G4110',
      geoid: '1805860',
      name: 'Bloomington city',
      bbox: [-86.6, 39.1, -86.4, 39.3],
      geojson: { type: 'Polygon' },
    });
  });

  it('omits rows where geojson or bbox is null', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [
      { geo_id: '9999', mtfcc: 'G4110', name: 'Unknown', minx: null, miny: null, maxx: null, maxy: null, geojson: null },
    ] });
    const result = await getBoundaryBatch([{ layer: 'G4110', geoid: '9999' }]);
    expect(result.size).toBe(0);
  });

  it('passes user data as params — never interpolated into SQL', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getBoundaryBatch([
      { layer: 'G4110', geoid: '1805860' },
      { layer: 'G4020', geoid: '18105' },
    ]);
    const [, params] = mockQuery.mock.calls[0];
    expect(params).toEqual(['G4110', '1805860', 'G4020', '18105']);
  });
});

describe('getCountyUnionFrames', () => {
  it('returns an empty map and fires no query when refs is empty', async () => {
    const out = await getCountyUnionFrames([]);
    expect(out.size).toBe(0);
    expect(mockQuery).not.toHaveBeenCalled();
  });

  it('exposes member county geoids alongside the union frame', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      layer: 'G5220', geoid: '49021',
      minx: -112.5, miny: 40.0, maxx: -111.5, maxy: 40.9,
      geojson: '{"type":"MultiPolygon","coordinates":[]}',
      county_geoids: ['49035', '49045'],
    }] });

    const out = await getCountyUnionFrames([{ layer: 'G5220', geoid: '49021' }]);

    expect(out.get('G5220:49021')).toMatchObject({
      bbox: [-112.5, 40.0, -111.5, 40.9],
      countyGeoIds: ['49035', '49045'],
    });
  });

  it('defaults countyGeoIds to [] when the column is null', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      layer: 'G5220', geoid: '49021',
      minx: -112.5, miny: 40.0, maxx: -111.5, maxy: 40.9,
      geojson: '{"type":"MultiPolygon","coordinates":[]}',
      county_geoids: null,
    }] });

    const out = await getCountyUnionFrames([{ layer: 'G5220', geoid: '49021' }]);

    expect(out.get('G5220:49021')?.countyGeoIds).toEqual([]);
  });
});

describe('getDistrictCountyGeoIds', () => {
  it('returns an empty map and fires no query when refs is empty', async () => {
    const out = await getDistrictCountyGeoIds([]);
    expect(out.size).toBe(0);
    expect(mockQuery).not.toHaveBeenCalled();
  });

  it('returns the overlapping county geoids keyed by layer:geoid via an indexed table lookup', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [
      { layer: 'G5220', geoid: '49021', county_geoids: ['49035', '49045'] },
    ] });

    const out = await getDistrictCountyGeoIds([{ layer: 'G5220', geoid: '49021' }]);

    expect(out.get('G5220:49021')).toEqual(['49035', '49045']);
    // Reads the precomputed table — no live geometry computation.
    const [sql] = mockQuery.mock.calls[0];
    expect(String(sql)).toMatch(/district_county_overlap/i);
    expect(String(sql)).not.toMatch(/ST_Intersects|ST_Union|ST_AsGeoJSON|ST_Area/i);
  });

  it('defaults to [] when the county_geoids column is null', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ layer: 'G5220', geoid: '49021', county_geoids: null }] });
    const out = await getDistrictCountyGeoIds([{ layer: 'G5220', geoid: '49021' }]);
    expect(out.get('G5220:49021')).toEqual([]);
  });

  it('deduplicates repeated refs before querying', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getDistrictCountyGeoIds([
      { layer: 'G5220', geoid: '49021' },
      { layer: 'G5220', geoid: '49021' },
    ]);
    const [, params] = mockQuery.mock.calls[0];
    expect(params).toEqual(['G5220', '49021']);
  });
});

describe('getStateCountyGeoIds', () => {
  it('maps USPS input to FIPS for the query, but returns a Map keyed by USPS', async () => {
    // essentials.geofence_boundaries.state holds 2-digit FIPS, not USPS — the query
    // must be issued with FIPS codes even though callers pass/receive USPS.
    mockQuery.mockResolvedValueOnce({ rows: [
      { state: '06', geo_id: '06037' },
      { state: '06', geo_id: '06059' },
    ] });
    const out = await getStateCountyGeoIds(['CA']);
    expect(out.get('CA')).toEqual(['06037', '06059']);
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toMatch(/mtfcc = 'G4020'/);
    expect(params).toEqual([['06']]); // FIPS, not USPS
  });

  it('groups county GEOIDs by USPS state, deduping input states', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [
      { state: '06', geo_id: '06037' },
      { state: '06', geo_id: '06059' },
      { state: '49', geo_id: '49035' },
    ] });
    const out = await getStateCountyGeoIds(['CA', 'UT', 'CA']);
    expect(out.get('CA')).toEqual(['06037', '06059']);
    expect(out.get('UT')).toEqual(['49035']);
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toMatch(/mtfcc = 'G4020'/);
    expect(params).toEqual([['06', '49']]);
  });

  it('returns an empty map and runs no query for no states', async () => {
    const out = await getStateCountyGeoIds([]);
    expect(out.size).toBe(0);
    expect(mockQuery).not.toHaveBeenCalled();
  });
});

describe('getCountyNames', () => {
  it('maps county GEOIDs to names, deduping input', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [
      { geo_id: '06037', name: 'Los Angeles County' },
      { geo_id: '49035', name: 'Salt Lake County' },
    ] });
    const out = await getCountyNames(['06037', '49035', '06037']);
    expect(out).toEqual({ '06037': 'Los Angeles County', '49035': 'Salt Lake County' });
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toMatch(/mtfcc = 'G4020'/);
    expect(params).toEqual([['06037', '49035']]);
  });

  it('returns {} and runs no query for no ids', async () => {
    expect(await getCountyNames([])).toEqual({});
    expect(mockQuery).not.toHaveBeenCalled();
  });
});
