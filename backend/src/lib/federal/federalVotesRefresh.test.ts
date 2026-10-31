import { describe, expect, it, vi } from 'vitest';

// The module imports the pool and the LegiScan client; these helpers never touch them.
vi.mock('../db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('../legiscan/client.js', () => ({
  legiscanQuery: vi.fn(), legiscanDatasetZip: vi.fn(), readQueriesThisMonth: vi.fn(), MONTHLY_QUERY_CAP: 10000,
}));

import { billKeyFor, pickCongressDataset } from './federalVotesRefresh.js';

describe('billKeyFor', () => {
  it('maps LegiScan bill numbers to congress.gov keys', () => {
    expect(billKeyFor(119, 'HB1347')).toBe('119-HR-1347');
    expect(billKeyFor(119, 'HR9')).toBe('119-HRES-9');
    expect(billKeyFor(115, 'SB5')).toBe('115-S-5');
    expect(billKeyFor(115, 'SR12')).toBe('115-SRES-12');
    expect(billKeyFor(116, 'HJR3')).toBe('116-HJRES-3');
    expect(billKeyFor(116, 'SJR3')).toBe('116-SJRES-3');
    expect(billKeyFor(117, 'HCR30')).toBe('117-HCONRES-30');
    expect(billKeyFor(117, 'SCR29')).toBe('117-SCONRES-29');
  });
  it('returns null for anything that is not a bill or resolution', () => {
    expect(billKeyFor(119, 'PN123')).toBeNull();
    expect(billKeyFor(119, 'TREATYDOC4')).toBeNull();
    expect(billKeyFor(119, '')).toBeNull();
    expect(billKeyFor(119, undefined)).toBeNull();
  });
});

describe('pickCongressDataset', () => {
  const list = { datasetlist: [
    { session_id: 2199, session_name: '119th Congress', special: 0, dataset_hash: 'a', access_key: 'k1' },
    { session_id: 2041, session_name: '118th Congress', special: 0, dataset_hash: 'b', access_key: 'k2' },
  ] };
  it('finds the dataset for a Congress by name', () => {
    expect(pickCongressDataset(list, 119)?.session_id).toBe(2199);
    expect(pickCongressDataset(list, 118)?.session_id).toBe(2041);
  });
  it('returns null when the Congress has no dataset yet', () => {
    expect(pickCongressDataset(list, 120)).toBeNull();
    expect(pickCongressDataset({}, 119)).toBeNull();
  });
  it('accepts an object-shaped list', () => {
    expect(pickCongressDataset({ datasetlist: { 0: list.datasetlist[0] } }, 119)?.session_id).toBe(2199);
  });
});
