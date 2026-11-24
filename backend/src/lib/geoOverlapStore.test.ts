import { vi, describe, it, expect } from 'vitest';

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

import { fingerprintOf } from './geoOverlapStore.js';
import { OVERLAP_QUERY_SQL, OVERLAP_QUERY_FINGERPRINT } from './essentialsBrowseService.js';
import { UNRESOLVABLE_PAIR_MTFCC_SQL_LIST } from './geoIdGuard.js';

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
