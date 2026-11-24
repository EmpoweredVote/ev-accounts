import { vi, describe, it, expect, beforeEach } from 'vitest';

// The warm job takes its OWN connection so it can raise statement_timeout on it,
// so the mock has to offer one. Its query is the same spy, which keeps every
// assertion below reading one ordered list of calls.
vi.mock('./db.js', () => {
  const query = vi.fn();
  const release = vi.fn();
  return { pool: { query, release, connect: vi.fn(async () => ({ query, release })) } };
});
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
/** Calls are found by their SQL, not by a hard-coded index, so adding a query
 *  ahead of them does not silently repoint an assertion at the wrong one. */
const SEED_LISTING = 'WHERE mtfcc = $1';

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
      .mockResolvedValueOnce({ rows: [] } as never) // SET statement_timeout
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: SEEDS } as never)
      .mockResolvedValueOnce({
        rows: SEEDS.map((s) => ({ seed_geo_id: s.geo_id, seed_mtfcc: s.mtfcc, pairs: [] })),
      } as never)
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never) // the sweep re-reads the version
      .mockResolvedValueOnce({ rows: [], rowCount: 4 } as never) // the sweep
      .mockResolvedValue({ rows: [] } as never); // RESET statement_timeout

    const got = await warmGeoOverlapPairs();

    expect(got).toEqual({
      version: '7',
      fingerprint: expect.stringMatching(/^[0-9a-f]{16}$/),
      computed: 0,
      alreadyCurrent: 3,
      swept: 4,
      failed: 0,
    });
    expect(everySql().some((s) => s.includes('ST_Intersection'))).toBe(false);
    expect(everySql().some((s) => s.includes('DELETE'))).toBe(true);
  });

  it('sweeps AFTER the last store write', async () => {
    // Sweeping first leaves a window with no warm state at all — the 7-second
    // cold call this work exists to remove, manufactured by the job that exists
    // to prevent it.
    q()
      .mockResolvedValueOnce({ rows: [] } as never) // SET statement_timeout
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [SEEDS[0]] } as never)
      .mockResolvedValueOnce({ rows: [] } as never) // nothing stored yet
      .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never) // compute
      .mockResolvedValueOnce({ rows: [], rowCount: 1 } as never) // the upsert
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never) // the sweep re-reads the version
      .mockResolvedValueOnce({ rows: [], rowCount: 9 } as never) // the sweep
      .mockResolvedValue({ rows: [] } as never); // RESET statement_timeout

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
    q()
      .mockResolvedValueOnce({ rows: [] } as never) // SET statement_timeout
      .mockResolvedValueOnce({ rows: [] } as never);

    const got = await warmGeoOverlapPairs();

    expect(got.version).toBeNull();
    expect(got.computed).toBe(0);
    expect(got.alreadyCurrent).toBe(0);
    expect(got.swept).toBe(0);
    // the timeout SET, the version read, and the RESET the finally always runs
    expect(q()).toHaveBeenCalledTimes(3);
    expect(everySql()[2]).toContain('RESET statement_timeout');
  });

  it('warms G4000 by default', async () => {
    q()
      .mockResolvedValueOnce({ rows: [] } as never) // SET statement_timeout
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 0 } as never);

    await warmGeoOverlapPairs();

    expect(paramsOf(indexOfSql(SEED_LISTING))).toEqual(['G4000']);
    // geo_id and mtfcc ONLY. Selecting geometry here would detoast every polygon
    // in a 158 MB table to list 53 state outlines.
    expect(sqlOf(indexOfSql(SEED_LISTING))).not.toContain('geometry');
  });

  it('takes a different seed layer when asked', async () => {
    q()
      .mockResolvedValueOnce({ rows: [] } as never) // SET statement_timeout
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 0 } as never);

    await warmGeoOverlapPairs({ seedMtfcc: 'G4020' });

    expect(paramsOf(indexOfSql(SEED_LISTING))).toEqual(['G4020']);
  });

  it('dryRun computes and reports but issues no write or delete', async () => {
    q()
      .mockResolvedValueOnce({ rows: [] } as never) // SET statement_timeout
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
      .mockResolvedValueOnce({ rows: [] } as never) // SET statement_timeout
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

describe('warmGeoOverlapPairs — surviving the 30-second wall', () => {
  beforeEach(() => {
    q().mockReset();
    vi.spyOn(console, 'log').mockImplementation(() => {});
    vi.spyOn(console, 'warn').mockImplementation(() => {});
  });

  it('raises statement_timeout on its own connection before it computes anything', async () => {
    // MEASURED ON PROD 2026-11-24: the G4000 listing is not 53 states — one of
    // its rows is `US`, the whole country, which resolves 40,899 pairs in 83
    // SECONDS. ev_api carries statement_timeout = 30s, so without this the job
    // dies on that seed every single run.
    q()
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 0 } as never);

    await warmGeoOverlapPairs();

    expect(sqlOf(0)).toContain('statement_timeout');
    expect(indexOfSql('statement_timeout')).toBe(0);
  });

  it('a seed that fails to compute does not stop the rest, and is reported', async () => {
    // One pathological seed must not cost the other 52 their warm state.
    q()
      .mockResolvedValueOnce({ rows: [] } as never) // SET statement_timeout
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({
        rows: [
          { geo_id: 'US', mtfcc: 'G4000' },
          { geo_id: '06', mtfcc: 'G4000' },
        ],
      } as never)
      .mockResolvedValueOnce({ rows: [] } as never) // nothing stored
      .mockRejectedValueOnce(new Error('canceling statement due to statement timeout'))
      .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 1 } as never) // the upsert
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never) // the sweep re-reads the version
      .mockResolvedValueOnce({ rows: [], rowCount: 0 } as never) // the sweep
      .mockResolvedValue({ rows: [] } as never); // RESET statement_timeout

    const got = await warmGeoOverlapPairs();

    expect(got.computed).toBe(1);
    expect(got.failed).toBe(1);
    // The survivor was still written, and the sweep still ran.
    expect(indexOfSql('ON CONFLICT')).toBeGreaterThan(-1);
    expect(paramsOf(indexOfSql('ON CONFLICT'))[0]).toEqual(['06']);
    expect(indexOfSql('DELETE')).toBeGreaterThan(indexOfSql('ON CONFLICT'));
  });

  it('releases its connection even when the run throws', async () => {
    // readGeofenceVersion swallows its own errors by design, so the throw has to
    // come from the seed listing, which does not.
    q()
      .mockResolvedValueOnce({ rows: [] } as never) // SET statement_timeout
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockRejectedValueOnce(new Error('connection lost'));

    await expect(warmGeoOverlapPairs()).rejects.toThrow('connection lost');
    expect(vi.mocked((pool as unknown as { release: () => void }).release)).toHaveBeenCalled();
  });
});

describe('warmGeoOverlapPairs — fixes from the whole-branch review', () => {
  beforeEach(() => {
    q().mockReset();
    vi.spyOn(console, 'log').mockImplementation(() => {});
    vi.spyOn(console, 'warn').mockImplementation(() => {});
  });

  it('resets statement_timeout before giving the connection back to the pool', async () => {
    // 🔴 `SET statement_timeout` outside a transaction is a SESSION setting, and
    // release() returns the connection to the idle pool carrying it. With
    // GEO_OVERLAP_WARM_ON_BOOT set, one connection per boot would then serve
    // ordinary requests with no 30-second guard at all — silently, and the repo
    // relies on that guard to stop a runaway query pinning a connection.
    q()
      .mockResolvedValueOnce({ rows: [] } as never) // SET
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [] } as never) // seed listing
      .mockResolvedValueOnce({ rows: [], rowCount: 0 } as never) // sweep: version re-read
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 0 } as never)
      .mockResolvedValue({ rows: [] } as never);

    await warmGeoOverlapPairs();

    expect(everySql().some((s) => s.includes('RESET statement_timeout'))).toBe(true);
    const reset = everySql().findIndex((s) => s.includes('RESET statement_timeout'));
    expect(reset).toBe(everySql().length - 1); // the very last thing it does
  });

  it('resets statement_timeout even when the run throws', async () => {
    q()
      .mockResolvedValueOnce({ rows: [] } as never) // SET
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockRejectedValueOnce(new Error('connection lost'))
      .mockResolvedValue({ rows: [] } as never);

    await expect(warmGeoOverlapPairs()).rejects.toThrow('connection lost');
    expect(everySql().some((s) => s.includes('RESET statement_timeout'))).toBe(true);
  });

  it('skips the sweep when the version moved during the run', async () => {
    // The warm reads the version once and may sweep 124 seconds later. If an
    // ingest bumps the version in between, live requests are writing CORRECT
    // rows at V+1 — and a sweep holding V would delete every one of them, while
    // this run's own rows at V are already unreadable. An empty store and a cold
    // window for every state, caused by the job that exists to prevent exactly
    // that.
    q()
      .mockResolvedValueOnce({ rows: [] } as never) // SET
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [SEEDS[0]] } as never)
      .mockResolvedValueOnce({ rows: [] } as never) // nothing stored
      .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never) // compute
      .mockResolvedValueOnce({ rows: [], rowCount: 1 } as never) // the upsert
      .mockResolvedValueOnce({ rows: [{ version: '9' }] } as never) // the version MOVED
      .mockResolvedValue({ rows: [] } as never);

    const got = await warmGeoOverlapPairs();

    expect(got.computed).toBe(1);
    expect(got.swept).toBe(0);
    expect(everySql().some((s) => s.includes('DELETE'))).toBe(false);
  });

  it('sweeps when the version held still', async () => {
    q()
      .mockResolvedValueOnce({ rows: [] } as never) // SET
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never)
      .mockResolvedValueOnce({ rows: [SEEDS[0]] } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({ rows: [{ geo_id: '0601', mtfcc: 'G5200' }] } as never)
      .mockResolvedValueOnce({ rows: [], rowCount: 1 } as never)
      .mockResolvedValueOnce({ rows: [{ version: '7' }] } as never) // unchanged
      .mockResolvedValueOnce({ rows: [], rowCount: 11 } as never) // the sweep
      .mockResolvedValue({ rows: [] } as never);

    const got = await warmGeoOverlapPairs();

    expect(got.swept).toBe(11);
  });
});
