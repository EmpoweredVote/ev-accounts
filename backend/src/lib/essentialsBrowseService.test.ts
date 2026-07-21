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

  it('returns needsExactAddress:false and an empty array when zero CDs overlap (honest omission, never fabricate a rep)', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [] } as never);

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

  it('does not call any new PostGIS/ST_Intersects query (reuses getOverlappingGeoIdsForArea only)', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [] } as never);

    await getCongressionalOverlapNote('0666000', 'G4110');

    // Exactly the 2 calls getOverlappingGeoIdsForArea itself makes — no 3rd
    // call, i.e. no extra query authored by getCongressionalOverlapNote.
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
