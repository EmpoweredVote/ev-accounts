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
import { cache } from './cache.js';
import {
  getCongressionalOverlapNote,
  resolveOverlappingGeoPairs,
  OVERLAP_QUERY_FINGERPRINT,
} from './essentialsBrowseService.js';

const read = (rel: string) => fs.readFileSync(path.resolve(__dirname, rel), 'utf-8');
const SOURCE = read('./essentialsBrowseService.ts');

/**
 * Queue the TWO calls resolveOverlappingGeoPairs now makes before anything else:
 * the geofence version read, then the store lookup. A HIT is modelled here
 * because a warm store is what production has — and because these chains are
 * ORDERED, so they must describe the real call order rather than be loosened
 * into not caring about it. The store's own misses, writes and degrade paths are
 * tested in "resolveOverlappingGeoPairs — durable store" at the bottom of this
 * file; here the store is a warm fixture, not the subject.
 */
const warmStore = (
  seedGeoId: string,
  seedMtfcc: string,
  pairs: Array<{ geo_id: string; mtfcc: string }>
) => {
  vi.mocked(pool.query)
    .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
    .mockResolvedValueOnce({
      rows: [{ seed_geo_id: seedGeoId, seed_mtfcc: seedMtfcc, pairs }],
    } as never);
};

describe('getCongressionalOverlapNote', () => {
  beforeEach(() => {
    vi.mocked(pool.query).mockReset();
  });

  it('returns needsExactAddress:true with ALL overlapping CD geo_ids when >1 G5200 pair overlaps', async () => {
    warmStore('0666000', 'G4110', [
      { geo_id: '0601', mtfcc: 'G5200' },
      { geo_id: '0602', mtfcc: 'G5200' },
      { geo_id: '06075', mtfcc: 'G4020' }, // non-CD row — must be filtered out
    ]);
    // getOverlappingGeoIdsForArea's own state-lookup query
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [{ state: '06' }] } as never);

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result.needsExactAddress).toBe(true);
    expect([...result.cdGeoIds].sort()).toEqual(['0601', '0602']);
  });

  it('returns needsExactAddress:false with the single CD geo_id when exactly 1 overlaps', async () => {
    warmStore('0666000', 'G4110', [{ geo_id: '0601', mtfcc: 'G5200' }]);
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [{ state: '06' }] } as never);

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result.needsExactAddress).toBe(false);
    expect(result.cdGeoIds).toEqual(['0601']);
  });

  it('returns needsExactAddress:false and an empty array when zero CDs overlap AND the Gazetteer centroid fallback also finds no centroid (honest omission, never fabricate a rep)', async () => {
    warmStore('0666000', 'G4110', []); // stored, and the answer is "none"
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // getOverlappingGeoIdsForArea's state lookup
      .mockResolvedValueOnce({ rows: [] } as never) // 212-07 fallback: gazetteer_places centroid lookup
      .mockResolvedValueOnce({ rows: [] } as never); // 212-07 fallback: gazetteer_counties centroid lookup

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result.needsExactAddress).toBe(false);
    expect(result.cdGeoIds).toEqual([]);
  });

  it('dedupes duplicate G5200 geo_ids in the overlap result', async () => {
    warmStore('0666000', 'G4110', [
      { geo_id: '0601', mtfcc: 'G5200' },
      { geo_id: '0601', mtfcc: 'G5200' },
    ]);
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [{ state: '06' }] } as never);

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result.needsExactAddress).toBe(false);
    expect(result.cdGeoIds).toEqual(['0601']);
  });

  it('does not call any new PostGIS/ST_Intersects query when the Gazetteer centroid fallback also finds nothing (reuses getOverlappingGeoIdsForArea + the honest fallback path only)', async () => {
    warmStore('0666000', 'G4110', []);
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // getOverlappingGeoIdsForArea's state lookup
      .mockResolvedValueOnce({ rows: [] } as never) // gazetteer_places centroid lookup
      .mockResolvedValueOnce({ rows: [] } as never); // gazetteer_counties centroid lookup

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result).toEqual({ cdGeoIds: [], needsExactAddress: false });
    // 2 for the version + store read, then the 3 this helper's own path makes.
    expect(vi.mocked(pool.query).mock.calls.length).toBe(5);
    expect(
      vi.mocked(pool.query).mock.calls.every((c) => !String(c[0]).includes('ST_Intersection'))
    ).toBe(true);
  });
});

describe('getCongressionalOverlapNote — 212-07 Gazetteer centroid fallback (RSLV-05/06 blocker)', () => {
  beforeEach(() => {
    vi.mocked(pool.query).mockReset();
  });

  it('falls back to the containing CD found via the gazetteer_places centroid + ST_Contains when the primary geometry overlap is empty', async () => {
    warmStore('0655528', 'G4110', []); // 0 G5200 pairs — a Gazetteer-only place with no polygon
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // getOverlappingGeoIdsForArea's state lookup
      .mockResolvedValueOnce({ rows: [{ lon: -121.6219, lat: 39.7596 }] } as never) // gazetteer_places centroid (Paradise CDP CA)
      .mockResolvedValueOnce({ rows: [{ geo_id: '0603' }] } as never); // ST_Contains CD lookup (CD 3, Kevin Kiley)

    const result = await getCongressionalOverlapNote('0655528', 'G4110');

    expect(result).toEqual({ cdGeoIds: ['0603'], needsExactAddress: false });
  });

  it('falls back to essentials.gazetteer_counties when the geo_id has no gazetteer_places row', async () => {
    warmStore('06003', 'G4020', []);
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // state lookup
      .mockResolvedValueOnce({ rows: [] } as never) // gazetteer_places: no row
      .mockResolvedValueOnce({ rows: [{ lon: -120.0, lat: 38.6 }] } as never) // gazetteer_counties centroid
      .mockResolvedValueOnce({ rows: [{ geo_id: '0603' }] } as never); // ST_Contains CD lookup

    const result = await getCongressionalOverlapNote('06003', 'G4020');

    expect(result).toEqual({ cdGeoIds: ['0603'], needsExactAddress: false });
  });

  it('returns cdGeoIds:[] with needsExactAddress:false (honest omission) when a centroid exists but falls inside no CD polygon', async () => {
    warmStore('7200000', 'G4110', []);
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // state lookup
      .mockResolvedValueOnce({ rows: [{ lon: -66.5901, lat: 18.2208 }] } as never) // centroid (e.g. a territory)
      .mockResolvedValueOnce({ rows: [] } as never); // ST_Contains finds no CD

    const result = await getCongressionalOverlapNote('7200000', 'G4110');

    expect(result).toEqual({ cdGeoIds: [], needsExactAddress: false });
  });

  it('returns cdGeoIds:[] with needsExactAddress:false (never fabricated) when no centroid exists in either Gazetteer table', async () => {
    warmStore('17', 'G4000', []);
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never) // state lookup
      .mockResolvedValueOnce({ rows: [] } as never) // gazetteer_places: no row
      .mockResolvedValueOnce({ rows: [] } as never); // gazetteer_counties: no row either

    const result = await getCongressionalOverlapNote('17', 'G4000');

    expect(result).toEqual({ cdGeoIds: [], needsExactAddress: false });
  });

  it('never fires the fallback when the primary geometry overlap already found CD(s) — does not override a real multi-CD result', async () => {
    warmStore('0666000', 'G4110', [
      { geo_id: '0601', mtfcc: 'G5200' },
      { geo_id: '0602', mtfcc: 'G5200' },
    ]);
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [{ state: '06' }] } as never); // state lookup

    const result = await getCongressionalOverlapNote('0666000', 'G4110');

    expect(result.needsExactAddress).toBe(true);
    expect([...result.cdGeoIds].sort()).toEqual(['0601', '0602']);
    // The version read, the store read and the state lookup — and nothing else.
    // The centroid fallback must never fire when cdGeoIds is already non-empty.
    expect(vi.mocked(pool.query).mock.calls.length).toBe(3);
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

// ---------------------------------------------------------------------------
// resolveOverlappingGeoPairs — the durable store (CC_0511)
// ---------------------------------------------------------------------------
// The ORDER inside the resolver is what is under test, so these drive pool.query
// with ordered chains and assert on the SQL TEXT of each call. A mocked pool
// cannot see SQL; asserting only on return values tests the mock.

const VERSION_SQL = 'essentials.geofence_version';
const STORE_SQL = 'essentials.geo_overlap_pairs';
const BOUNDARIES_SQL = 'essentials.geofence_boundaries gb';
const callSql = (n: number) => String(vi.mocked(pool.query).mock.calls[n]![0]);
const callParams = (n: number) => vi.mocked(pool.query).mock.calls[n]![1] as unknown[];
const everySql = () => vi.mocked(pool.query).mock.calls.map((c) => String(c[0]));

describe('resolveOverlappingGeoPairs — durable store', () => {
  beforeEach(() => {
    vi.mocked(pool.query).mockReset();
    vi.mocked(cache.get).mockReset().mockResolvedValue(null);
    vi.mocked(cache.set).mockReset().mockResolvedValue(undefined);
  });

  it('returns stored pairs without running the intersection query on a full hit', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({
        rows: [
          { seed_geo_id: '06', seed_mtfcc: 'G4000', pairs: [{ geo_id: '0601', mtfcc: 'G5200' }] },
        ],
      } as never);

    const got = await resolveOverlappingGeoPairs([{ geo_id: '06', mtfcc: 'G4000' }]);

    expect(got).toEqual([{ geo_id: '0601', mtfcc: 'G5200' }]);
    expect(vi.mocked(pool.query)).toHaveBeenCalledTimes(2);
    expect(everySql().some((s) => s.includes('ST_Intersection'))).toBe(false);
  });

  it('computes only the seeds that missed, and unions the two', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({
        rows: [
          { seed_geo_id: '06', seed_mtfcc: 'G4000', pairs: [{ geo_id: '0601', mtfcc: 'G5200' }] },
        ],
      } as never)
      .mockResolvedValueOnce({ rows: [{ geo_id: '4801', mtfcc: 'G5200' }] } as never)
      .mockResolvedValueOnce({ rows: [{ geo_id: '48', mtfcc: 'G4000' }] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 1 } as never);

    const got = await resolveOverlappingGeoPairs([
      { geo_id: '06', mtfcc: 'G4000' },
      { geo_id: '48', mtfcc: 'G4000' },
    ]);

    expect(got).toEqual([
      { geo_id: '0601', mtfcc: 'G5200' },
      { geo_id: '4801', mtfcc: 'G5200' },
    ]);
    // Exactly ONE intersection query, and it carried only the seed that missed.
    expect(everySql().filter((s) => s.includes('ST_Intersection'))).toHaveLength(1);
    expect(callParams(2)).toEqual([['48'], ['G4000']]);
  });

  it('stores the version read before the compute, not after', async () => {
    // An ingest landing mid-compute moves the version. The row must carry the
    // version the answer was computed AGAINST, so it is born superseded and
    // unreadable. Writing the CURRENT version publishes an answer computed from
    // half-ingested geometry at a version readers trust.
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never)
      .mockResolvedValueOnce({ rows: [{ geo_id: '06', mtfcc: 'G4000' }] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 1 } as never);

    await resolveOverlappingGeoPairs([{ geo_id: '06', mtfcc: 'G4000' }]);

    expect(callSql(4)).toContain('ON CONFLICT');
    expect(callParams(4)).toContain('7');
    expect(callParams(4)).not.toContain('9');
  });

  it('does not store a seed that is not in geofence_boundaries', async () => {
    // /by-area takes geo_id and mtfcc from an unauthenticated body, validated
    // only as non-empty strings. Without this the primary key of a permanent
    // essentials table is caller-controlled free text anyone can add to at will.
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [] } as never);

    const got = await resolveOverlappingGeoPairs([{ geo_id: 'nope', mtfcc: 'alsonope' }]);

    expect(got).toEqual([]);
    expect(vi.mocked(pool.query)).toHaveBeenCalledTimes(4);
    expect(everySql().some((s) => s.includes('ON CONFLICT'))).toBe(false);
  });

  it('falls back to computing when the version row cannot be read', async () => {
    // A deploy that lands before the migration is applied, or a half-applied
    // one. It must compute, and it must not 500.
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never);

    const got = await resolveOverlappingGeoPairs([{ geo_id: '06', mtfcc: 'G4000' }]);

    expect(got).toEqual([{ geo_id: '0601', mtfcc: 'G5200' }]);
    expect(vi.mocked(pool.query)).toHaveBeenCalledTimes(2);
    expect(callSql(1)).toContain('ST_Intersection');
    expect(everySql().some((s) => s.includes(STORE_SQL))).toBe(false);
  });

  it('ignores a cached value that is not an array of pairs', async () => {
    // cache.get is typed <T> and validates nothing, so a v2-era or truncated
    // entry would otherwise reach a caller as pairs.
    vi.mocked(cache.get).mockResolvedValueOnce({ old: 'shape' } as never);
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never);

    const got = await resolveOverlappingGeoPairs([{ geo_id: '06', mtfcc: 'G4000' }]);

    expect(got).toEqual([{ geo_id: '0601', mtfcc: 'G5200' }]);
  });

  it('honours a cached empty array — that is an answer, not a miss', async () => {
    vi.mocked(cache.get).mockResolvedValueOnce([] as never);
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [{ version: '7' }] } as never);

    const got = await resolveOverlappingGeoPairs([{ geo_id: '06', mtfcc: 'G4000' }]);

    expect(got).toEqual([]);
    expect(vi.mocked(pool.query)).toHaveBeenCalledTimes(1); // the version read, nothing more
  });

  it('puts the version and the fingerprint in the Redis key', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({
        rows: [{ seed_geo_id: '06', seed_mtfcc: 'G4000', pairs: [] }],
      } as never);

    await resolveOverlappingGeoPairs([{ geo_id: '06', mtfcc: 'G4000' }]);

    const key = String(vi.mocked(cache.get).mock.calls[0]![0]);
    expect(key).toContain(':7:');
    expect(key).toContain(OVERLAP_QUERY_FINGERPRINT);
    expect(key).toContain('06::G4000');
    // v2 entries were written under a different answer shape; never read them.
    expect(key).not.toContain('overlap:v2:');
  });

  it('reads the version before anything else, the cache included', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({
        rows: [{ seed_geo_id: '06', seed_mtfcc: 'G4000', pairs: [] }],
      } as never);

    await resolveOverlappingGeoPairs([{ geo_id: '06', mtfcc: 'G4000' }]);

    expect(callSql(0)).toContain(VERSION_SQL);
    expect(callSql(1)).toContain(STORE_SQL);
    expect(vi.mocked(cache.get).mock.invocationCallOrder[0]!).toBeGreaterThan(
      vi.mocked(pool.query).mock.invocationCallOrder[0]!
    );
  });

  it('looks a seed up in geofence_boundaries by its (geo_id, mtfcc) key', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [{ geo_id: '06', mtfcc: 'G4000' }] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 1 } as never);

    await resolveOverlappingGeoPairs([{ geo_id: '06', mtfcc: 'G4000' }]);

    expect(callSql(3)).toContain(BOUNDARIES_SQL);
  });
});

describe('resolveOverlappingGeoPairs — the kill switch', () => {
  it('does not read or write the store when GEO_OVERLAP_STORE_ENABLED=0', async () => {
    process.env.GEO_OVERLAP_STORE_ENABLED = '0';
    vi.resetModules();
    try {
      const { pool: p } = await import('./db.js');
      const { cache: c } = await import('./cache.js');
      const svc = await import('./essentialsBrowseService.js');
      vi.mocked(p.query).mockReset();
      vi.mocked(c.get).mockReset().mockResolvedValue(null);
      vi.mocked(c.set).mockReset().mockResolvedValue(undefined);
      vi.mocked(p.query)
        .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
        .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never);

      const got = await svc.resolveOverlappingGeoPairs([{ geo_id: '06', mtfcc: 'G4000' }]);

      expect(got).toEqual([{ geo_id: '0601', mtfcc: 'G5200' }]);
      expect(vi.mocked(p.query)).toHaveBeenCalledTimes(2);
      const sqls = vi.mocked(p.query).mock.calls.map((x) => String(x[0]));
      expect(sqls.some((s) => s.includes('essentials.geo_overlap_pairs'))).toBe(false);
    } finally {
      delete process.env.GEO_OVERLAP_STORE_ENABLED;
      vi.resetModules();
    }
  });
});
