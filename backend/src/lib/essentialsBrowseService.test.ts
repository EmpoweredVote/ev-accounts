import { vi, describe, it, expect, beforeEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';

// Mock DB and cache so module-level side effects don't crash the test runner
// and so getOverlappingGeoIdsForArea's two pool.query calls (the
// resolveOverlappingGeoPairs intersection query, then the area's own state
// lookup) are fully controllable per test.
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('./cache.js', () => ({
  cache: {
    get: vi.fn().mockResolvedValue(null),
    set: vi.fn().mockResolvedValue(undefined),
    del: vi.fn().mockResolvedValue(undefined),
  },
}));

import { pool } from './db.js';
import { getCongressionalOverlapNote } from './essentialsBrowseService.js';

const read = (rel: string) => fs.readFileSync(path.resolve(__dirname, rel), 'utf-8');
const SOURCE = read('./essentialsBrowseService.ts');

describe('getCongressionalOverlapNote', () => {
  beforeEach(() => {
    vi.mocked(pool.query).mockReset();
  });

  it('returns needsExactAddress:true with ALL overlapping CD geo_ids when >1 G5200 pair overlaps', async () => {
    vi.mocked(pool.query)
      // resolveOverlappingGeoPairs' intersection query (Branch 1-3 UNION ALL)
      .mockResolvedValueOnce({
        rows: [
          { geo_id: '0601', mtfcc: 'G5200' },
          { geo_id: '0602', mtfcc: 'G5200' },
          { geo_id: '06075', mtfcc: 'G4020' }, // non-CD row — must be filtered out
        ],
      } as never)
      // getOverlappingGeoIdsForArea's own state-lookup query
      .mockResolvedValueOnce({ rows: [{ state: '06' }] } as never);

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result.needsExactAddress).toBe(true);
    expect([...result.cdGeoIds].sort()).toEqual(['0601', '0602']);
  });

  it('returns needsExactAddress:false with the single CD geo_id when exactly 1 overlaps', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never)
      .mockResolvedValueOnce({ rows: [{ state: '06' }] } as never);

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result.needsExactAddress).toBe(false);
    expect(result.cdGeoIds).toEqual(['0601']);
  });

  it('returns needsExactAddress:false and an empty array when zero CDs overlap AND the Gazetteer centroid fallback also finds no centroid (honest omission, never fabricate a rep)', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // resolveOverlappingGeoPairs
      .mockResolvedValueOnce({ rows: [] } as never) // getOverlappingGeoIdsForArea's state lookup
      .mockResolvedValueOnce({ rows: [] } as never) // 212-07 fallback: gazetteer_places centroid lookup
      .mockResolvedValueOnce({ rows: [] } as never); // 212-07 fallback: gazetteer_counties centroid lookup

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result.needsExactAddress).toBe(false);
    expect(result.cdGeoIds).toEqual([]);
  });

  it('dedupes duplicate G5200 geo_ids in the overlap result', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({
        rows: [
          { geo_id: '0601', mtfcc: 'G5200' },
          { geo_id: '0601', mtfcc: 'G5200' },
        ],
      } as never)
      .mockResolvedValueOnce({ rows: [{ state: '06' }] } as never);

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result.needsExactAddress).toBe(false);
    expect(result.cdGeoIds).toEqual(['0601']);
  });

  it('does not call any new PostGIS/ST_Intersects query when the Gazetteer centroid fallback also finds nothing (reuses getOverlappingGeoIdsForArea + the honest fallback path only)', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // resolveOverlappingGeoPairs
      .mockResolvedValueOnce({ rows: [] } as never) // getOverlappingGeoIdsForArea's state lookup
      .mockResolvedValueOnce({ rows: [] } as never) // gazetteer_places centroid lookup
      .mockResolvedValueOnce({ rows: [] } as never); // gazetteer_counties centroid lookup

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result).toEqual({ cdGeoIds: [], needsExactAddress: false });
    expect(vi.mocked(pool.query).mock.calls.length).toBe(4);
  });
});

describe('getCongressionalOverlapNote — 212-07 Gazetteer centroid fallback (RSLV-05/06 blocker)', () => {
  beforeEach(() => {
    vi.mocked(pool.query).mockReset();
  });

  it('falls back to the containing CD found via the gazetteer_places centroid + ST_Contains when the primary geometry overlap is empty', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // resolveOverlappingGeoPairs: 0 G5200 pairs (no polygon for this Gazetteer-only place)
      .mockResolvedValueOnce({ rows: [] } as never) // getOverlappingGeoIdsForArea's state lookup
      .mockResolvedValueOnce({ rows: [{ lon: -121.6219, lat: 39.7596 }] } as never) // gazetteer_places centroid (Paradise CDP CA)
      .mockResolvedValueOnce({ rows: [{ geo_id: '0603' }] } as never); // ST_Contains CD lookup (CD 3, Kevin Kiley)

    const result = await getCongressionalOverlapNote('0655528', 'G4110');

    expect(result).toEqual({ cdGeoIds: ['0603'], needsExactAddress: false });
  });

  it('falls back to essentials.gazetteer_counties when the geo_id has no gazetteer_places row', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // resolveOverlappingGeoPairs
      .mockResolvedValueOnce({ rows: [] } as never) // state lookup
      .mockResolvedValueOnce({ rows: [] } as never) // gazetteer_places: no row
      .mockResolvedValueOnce({ rows: [{ lon: -120.0, lat: 38.6 }] } as never) // gazetteer_counties centroid
      .mockResolvedValueOnce({ rows: [{ geo_id: '0603' }] } as never); // ST_Contains CD lookup

    const result = await getCongressionalOverlapNote('06003', 'G4020');

    expect(result).toEqual({ cdGeoIds: ['0603'], needsExactAddress: false });
  });

  it('returns cdGeoIds:[] with needsExactAddress:false (honest omission) when a centroid exists but falls inside no CD polygon', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // resolveOverlappingGeoPairs
      .mockResolvedValueOnce({ rows: [] } as never) // state lookup
      .mockResolvedValueOnce({ rows: [{ lon: -66.5901, lat: 18.2208 }] } as never) // centroid (e.g. a territory)
      .mockResolvedValueOnce({ rows: [] } as never); // ST_Contains finds no CD

    const result = await getCongressionalOverlapNote('7200000', 'G4110');

    expect(result).toEqual({ cdGeoIds: [], needsExactAddress: false });
  });

  it('returns cdGeoIds:[] with needsExactAddress:false (never fabricated) when no centroid exists in either Gazetteer table', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // resolveOverlappingGeoPairs
      .mockResolvedValueOnce({ rows: [] } as never) // state lookup
      .mockResolvedValueOnce({ rows: [] } as never) // gazetteer_places: no row
      .mockResolvedValueOnce({ rows: [] } as never); // gazetteer_counties: no row either

    const result = await getCongressionalOverlapNote('17', 'G4000');

    expect(result).toEqual({ cdGeoIds: [], needsExactAddress: false });
  });

  it('never fires the fallback when the primary geometry overlap already found CD(s) — does not override a real multi-CD result', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({
        rows: [
          { geo_id: '0601', mtfcc: 'G5200' },
          { geo_id: '0602', mtfcc: 'G5200' },
        ],
      } as never) // resolveOverlappingGeoPairs: 2 real CDs found via geometry
      .mockResolvedValueOnce({ rows: [{ state: '06' }] } as never); // state lookup

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result.needsExactAddress).toBe(true);
    expect([...result.cdGeoIds].sort()).toEqual(['0601', '0602']);
    // Only the 2 calls getOverlappingGeoIdsForArea makes — the centroid
    // fallback must never fire when cdGeoIds is already non-empty.
    expect(vi.mocked(pool.query).mock.calls.length).toBe(2);
  });
});

describe('getCongressionalOverlapNote source guards', () => {
  const helperSource = (() => {
    const start = SOURCE.indexOf('export async function getCongressionalOverlapNote');
    expect(start).toBeGreaterThan(-1);
    return SOURCE.slice(start);
  })();

  it('filters strictly on G5200, never the G5200V26 redistricting-vintage boundary set', () => {
    expect(helperSource).toMatch(/mtfcc\s*===\s*'G5200'/);
    // The literal token 'G5200V26' must not appear inside this helper's body.
    const bodyEnd = helperSource.indexOf('\n}');
    const body = helperSource.slice(0, bodyEnd === -1 ? undefined : bodyEnd);
    expect(body).not.toMatch(/G5200V26/);
  });

  it('does not author a new PostGIS/ST_Intersects query (reuse-only)', () => {
    const bodyEnd = helperSource.indexOf('\n}');
    const body = helperSource.slice(0, bodyEnd === -1 ? undefined : bodyEnd);
    expect(body).not.toMatch(/ST_Intersects|ST_Contains|pool\.query/);
    expect(body).toMatch(/getOverlappingGeoIdsForArea\(/);
  });
});
