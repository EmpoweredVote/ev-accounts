import { vi, describe, it, expect, beforeEach } from 'vitest';

vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('./cache.js', () => ({
  cache: {
    get: vi.fn().mockResolvedValue(null),
    set: vi.fn().mockResolvedValue(undefined),
    del: vi.fn().mockResolvedValue(undefined),
  },
}));

import { pool } from './db.js';
import { warmGeoOverlapPairs } from './geoOverlapWarm.js';

const q = () => vi.mocked(pool.query);
const sqlOf = (n: number) => String(q().mock.calls[n]![0]);
const paramsOf = (n: number) => q().mock.calls[n]![1] as unknown[];
const everySql = () => q().mock.calls.map((c) => String(c[0]));
const indexOfSql = (needle: string) => everySql().findIndex((s) => s.includes(needle));

/** The three seeds the listing returns in these tests. */
const SEEDS = [
  { geo_id: '06', mtfcc: 'G4000' },
  { geo_id: '48', mtfcc: 'G4000' },
  { geo_id: '36', mtfcc: 'G4000' },
];

describe('warmGeoOverlapPairs', () => {
  beforeEach(() => {
    q().mockReset();
    vi.spyOn(console, 'log').mockImplementation(() => {});
  });

  it('computes nothing and still sweeps when every seed is already stored at this version', async () => {
    // The near-no-op case, and it is the common one: GEO_OVERLAP_WARM_ON_BOOT
    // means every API instance runs this on every deploy. A bounded stampede on
    // a cold store is the trade the design accepts; one on every restart is not.
    q()
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: SEEDS } as never)
      .mockResolvedValueOnce({
        rows: SEEDS.map((s) => ({ seed_geo_id: s.geo_id, seed_mtfcc: s.mtfcc, pairs: [] })),
      } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 4 } as never); // the sweep

    const got = await warmGeoOverlapPairs();

    expect(got).toEqual({
      version: '7',
      fingerprint: expect.stringMatching(/^[0-9a-f]{16}$/),
      computed: 0,
      alreadyCurrent: 3,
      swept: 4,
    });
    expect(everySql().some((s) => s.includes('ST_Intersection'))).toBe(false);
    expect(everySql().some((s) => s.includes('DELETE'))).toBe(true);
  });

  it('sweeps AFTER the last store write', async () => {
    // Sweeping first leaves a window with no warm state at all — the 7-second
    // cold call this work exists to remove, manufactured by the job that exists
    // to prevent it.
    q()
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [SEEDS[0]] } as never)
      .mockResolvedValueOnce({ rows: [] } as never) // nothing stored yet
      .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never) // compute
      .mockResolvedValueOnce({ rows: [], rowCount: 1 } as never) // the upsert
      .mockResolvedValueOnce({ rows: [], rowCount: 9 } as never); // the sweep

    const got = await warmGeoOverlapPairs();

    expect(got.computed).toBe(1);
    expect(got.swept).toBe(9);
    const write = indexOfSql('ON CONFLICT');
    const sweep = indexOfSql('DELETE');
    expect(write).toBeGreaterThan(-1);
    expect(sweep).toBeGreaterThan(write);
  });

  it('returns version:null and computes nothing when the version cannot be read', async () => {
    // A deploy ahead of the migration. The job reports and stops; it must not
    // compute 53 states' worth of PostGIS against a store it cannot key.
    q().mockResolvedValueOnce({ rows: [] } as never);

    const got = await warmGeoOverlapPairs();

    expect(got.version).toBeNull();
    expect(got.computed).toBe(0);
    expect(got.alreadyCurrent).toBe(0);
    expect(got.swept).toBe(0);
    expect(q()).toHaveBeenCalledTimes(1);
  });

  it('warms G4000 by default', async () => {
    q()
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 0 } as never);

    await warmGeoOverlapPairs();

    expect(paramsOf(1)).toEqual(['G4000']);
    // geo_id and mtfcc ONLY. Selecting geometry here would detoast every polygon
    // in a 158 MB table to list 53 state outlines.
    expect(sqlOf(1)).not.toContain('geometry');
  });

  it('takes a different seed layer when asked', async () => {
    q()
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 0 } as never);

    await warmGeoOverlapPairs({ seedMtfcc: 'G4020' });

    expect(paramsOf(1)).toEqual(['G4020']);
  });

  it('dryRun computes and reports but issues no write or delete', async () => {
    q()
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [SEEDS[0]] } as never)
      .mockResolvedValueOnce({ rows: [] } as never) // nothing stored
      .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never); // compute

    const got = await warmGeoOverlapPairs({ dryRun: true });

    expect(got.computed).toBe(1);
    expect(got.swept).toBe(0);
    expect(everySql().some((s) => s.includes('ST_Intersection'))).toBe(true);
    expect(everySql().some((s) => s.includes('ON CONFLICT'))).toBe(false);
    expect(everySql().some((s) => s.includes('DELETE'))).toBe(false);
  });

  it('writes every computed seed in ONE upsert, at the version read first', async () => {
    q()
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: SEEDS } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never)
      .mockResolvedValueOnce({ rows: [{ geo_id: '4801', mtfcc: 'G5200' }] } as never)
      .mockResolvedValueOnce({ rows: [{ geo_id: '3601', mtfcc: 'G5200' }] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 3 } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 0 } as never);

    const got = await warmGeoOverlapPairs();

    expect(got.computed).toBe(3);
    expect(everySql().filter((s) => s.includes('ON CONFLICT'))).toHaveLength(1);
    expect(paramsOf(indexOfSql('ON CONFLICT'))).toContain('7');
    expect(paramsOf(indexOfSql('ON CONFLICT'))[0]).toEqual(['06', '48', '36']);
  });
});
