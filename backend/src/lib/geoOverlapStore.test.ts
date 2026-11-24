import { vi, describe, it, expect, beforeEach } from 'vitest';

// Mock DB and cache so importing essentialsBrowseService.js for its SQL text
// does not open a pool or a Redis client at module scope.
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('./cache.js', () => ({
  cache: {
    get: vi.fn().mockResolvedValue(null),
    set: vi.fn().mockResolvedValue(undefined),
    del: vi.fn().mockResolvedValue(undefined),
  },
}));

import { pool } from './db.js';
import {
  fingerprintOf,
  seedKey,
  readGeofenceVersion,
  readStoredPairs,
  writeStoredPairs,
  filterSeedsPresent,
  sweepSupersededPairs,
} from './geoOverlapStore.js';
import { OVERLAP_QUERY_SQL, OVERLAP_QUERY_FINGERPRINT } from './essentialsBrowseService.js';
import { UNRESOLVABLE_PAIR_MTFCC_SQL_LIST } from './geoIdGuard.js';

const q = () => vi.mocked(pool.query);
/** The SQL text of the n-th call. A mocked pool cannot see SQL; guard the TEXT. */
const sqlOf = (n = 0) => String(q().mock.calls[n]![0]);
const paramsOf = (n = 0) => q().mock.calls[n]![1] as unknown[];

const squash = (s: string) => s.replace(/\s/g, '');

describe('OVERLAP_QUERY_FINGERPRINT', () => {
  it('hashes a text that contains all four answer-changing constants', () => {
    const sql = squash(OVERLAP_QUERY_SQL);
    expect(sql).toContain(squash(UNRESOLVABLE_PAIR_MTFCC_SQL_LIST));
    expect(sql).toContain('0.03');
    expect(sql).toContain(squash("'G4110', 'G4120'"));
    expect(sql).toContain(squash("'G5200', 'G5210', 'G5220', 'G4020', 'G5400', 'G5410', 'G5420'"));
  });

  it('changes when any one of them changes', () => {
    const base = fingerprintOf(OVERLAP_QUERY_SQL);
    expect(fingerprintOf(OVERLAP_QUERY_SQL.replace('0.03', '0.04'))).not.toBe(base);
    expect(fingerprintOf(OVERLAP_QUERY_SQL.replace("'G6350'", "'G6351'"))).not.toBe(base);
    expect(fingerprintOf(OVERLAP_QUERY_SQL.replace("'G4110'", "'G4115'"))).not.toBe(base);
  });

  it('is 16 lowercase hex characters', () => {
    expect(OVERLAP_QUERY_FINGERPRINT).toMatch(/^[0-9a-f]{16}$/);
  });
});

describe('seedKey', () => {
  it('is the composite key every Map in this feature uses', () => {
    expect(seedKey({ geo_id: '06', mtfcc: 'G4000' })).toBe('06::G4000');
  });
});

describe('readGeofenceVersion', () => {
  beforeEach(() => q().mockReset());

  it('returns the bigint as a string, never a number', async () => {
    q().mockResolvedValueOnce({ rows: [{ version: '9007199254740993' }] } as never);
    const v = await readGeofenceVersion();
    // 9007199254740993 is Number.MAX_SAFE_INTEGER + 2. Parsed to a JS number it
    // would come back 9007199254740992 — silently, with no error anywhere.
    expect(v).toBe('9007199254740993');
    expect(typeof v).toBe('string');
    // The cast is what guarantees it, and the cast lives in SQL, not here.
    expect(sqlOf()).toContain('::text');
  });

  it('returns null when the query throws', async () => {
    q().mockRejectedValueOnce(new Error('relation "essentials.geofence_version" does not exist'));
    expect(await readGeofenceVersion()).toBeNull();
  });

  it('returns null when the table is there but holds no row', async () => {
    q().mockResolvedValueOnce({ rows: [] } as never);
    expect(await readGeofenceVersion()).toBeNull();
  });
});

describe('readStoredPairs', () => {
  beforeEach(() => q().mockReset());

  it('omits a seed that missed and keeps one that returned []', async () => {
    // A seed can legitimately overlap nothing. An absent key means "not stored";
    // an empty array means "stored, and the answer is none". Collapsing the two
    // would recompute every zero-pair seed on every request, forever.
    q().mockResolvedValueOnce({
      rows: [{ seed_geo_id: '06', seed_mtfcc: 'G4000', pairs: [] }],
    } as never);
    const got = await readStoredPairs(
      [
        { geo_id: '06', mtfcc: 'G4000' },
        { geo_id: '48', mtfcc: 'G4000' },
      ],
      '7',
      'abc123'
    );
    expect(got.get('06::G4000')).toEqual([]);
    expect(got.has('48::G4000')).toBe(false);
    expect(got.size).toBe(1);
  });

  it('binds BOTH the version and the fingerprint', async () => {
    q().mockResolvedValueOnce({ rows: [] } as never);
    await readStoredPairs([{ geo_id: '06', mtfcc: 'G4000' }], '7', 'abc123');
    expect(paramsOf()).toContain('7');
    expect(paramsOf()).toContain('abc123');
    expect(sqlOf()).toContain('geofence_version');
    expect(sqlOf()).toContain('query_fingerprint');
  });

  it('issues no query for an empty seed list', async () => {
    const got = await readStoredPairs([], '7', 'abc123');
    expect(got.size).toBe(0);
    expect(q()).not.toHaveBeenCalled();
  });
});

describe('writeStoredPairs', () => {
  beforeEach(() => q().mockReset());

  const entries = [
    {
      seed: { geo_id: '06', mtfcc: 'G4000' },
      pairs: [
        { geo_id: '0601', mtfcc: 'G5200' },
        { geo_id: '0602', mtfcc: 'G5200' },
      ],
    },
    { seed: { geo_id: '48', mtfcc: 'G4000' }, pairs: [] },
  ];

  it('is idempotent for the same key', async () => {
    // The warming job and a live request WILL collide on (seed, version,
    // fingerprint). A plain INSERT would surface that as a unique violation and
    // a 500 on a request that was about to answer correctly.
    q().mockResolvedValue({ rows: [], rowCount: 2 } as never);
    await writeStoredPairs(entries, '7', 'abc123');
    await writeStoredPairs(entries, '7', 'abc123');
    expect(q()).toHaveBeenCalledTimes(2);
    expect(sqlOf(0)).toContain('ON CONFLICT');
    expect(sqlOf(0)).toContain('DO UPDATE');
    expect(sqlOf(0)).toBe(sqlOf(1));
  });

  it('writes pair_count equal to pairs.length', async () => {
    q().mockResolvedValueOnce({ rows: [], rowCount: 2 } as never);
    await writeStoredPairs(entries, '7', 'abc123');
    expect(paramsOf()).toContainEqual([2, 0]);
  });

  it('collapses a duplicate seed instead of raising "cannot affect row a second time"', async () => {
    // ON CONFLICT DO UPDATE refuses a statement that proposes the same key twice.
    // Two callers racing is the documented hazard; the same seed appearing twice
    // in ONE call is the undocumented one, and it is a 500 on a request that was
    // about to answer correctly.
    q().mockResolvedValueOnce({ rows: [], rowCount: 1 } as never);
    await writeStoredPairs(
      [
        { seed: { geo_id: '06', mtfcc: 'G4000' }, pairs: [] },
        { seed: { geo_id: '06', mtfcc: 'G4000' }, pairs: [{ geo_id: '0601', mtfcc: 'G5200' }] },
      ],
      '7',
      'abc123'
    );
    expect(paramsOf()[0]).toEqual(['06']);
    // The LAST entry wins — it is the one the caller computed most recently.
    expect(paramsOf()).toContainEqual([1]);
  });

  it('issues no query for an empty entries array', async () => {
    await writeStoredPairs([], '7', 'abc123');
    expect(q()).not.toHaveBeenCalled();
  });
});

describe('filterSeedsPresent', () => {
  beforeEach(() => q().mockReset());

  it('returns only the seeds the query matched', async () => {
    // /by-area takes geo_id and mtfcc from an unauthenticated body, validated
    // only as non-empty strings. Without this, the primary key of a permanent
    // essentials table is caller-controlled free text.
    q().mockResolvedValueOnce({ rows: [{ geo_id: '06', mtfcc: 'G4000' }] } as never);
    const got = await filterSeedsPresent([
      { geo_id: '06', mtfcc: 'G4000' },
      { geo_id: 'DROP TABLE', mtfcc: 'NOPE' },
    ]);
    expect(got).toEqual([{ geo_id: '06', mtfcc: 'G4000' }]);
  });

  it('issues no query for an empty seed list', async () => {
    expect(await filterSeedsPresent([])).toEqual([]);
    expect(q()).not.toHaveBeenCalled();
  });
});

describe('sweepSupersededPairs', () => {
  beforeEach(() => q().mockReset());

  it('deletes on a version OR a fingerprint mismatch, and returns the count', async () => {
    q().mockResolvedValueOnce({ rows: [], rowCount: 41 } as never);
    expect(await sweepSupersededPairs('7', 'abc123')).toBe(41);
    const sql = sqlOf();
    expect(sql).toContain('DELETE');
    // Sweeping on the version alone would leave every row computed under a
    // superseded RESOLVER on disk at the current version — readable, and wrong.
    expect(sql).toContain('geofence_version');
    expect(sql).toContain('query_fingerprint');
    expect(sql.slice(sql.indexOf('WHERE'))).toContain(' OR ');
  });
});

describe('OVERLAP_STORE_ENABLED', () => {
  const load = async (value: string | undefined) => {
    if (value === undefined) delete process.env.GEO_OVERLAP_STORE_ENABLED;
    else process.env.GEO_OVERLAP_STORE_ENABLED = value;
    vi.resetModules();
    return (await import('./geoOverlapStore.js')).OVERLAP_STORE_ENABLED;
  };

  it('is false for "0" and "false", true otherwise', async () => {
    expect(await load('0')).toBe(false);
    expect(await load('false')).toBe(false);
    expect(await load('FALSE')).toBe(false);
    expect(await load(undefined)).toBe(true);
    expect(await load('1')).toBe(true);
    expect(await load('true')).toBe(true);
  });
});
