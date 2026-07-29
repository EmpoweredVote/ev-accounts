import { vi, describe, it, expect, beforeEach } from 'vitest';

// Mock the shared pool so importing fecBulkLoader.ts (which imports ../db.js via
// fecAdapter.js at module scope) doesn't trigger env.ts's startup validation /
// process.exit(1) in a test environment with no real DATABASE_URL. Mirrors the
// established pattern in fecAdapter.test.ts / essentialsBrowseService.test.ts.
const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));

// cache.ts also imports env.js at module scope (via fecBulkLoader's own import of
// cache.ts for the ccl->committee map TTL cache) — same reason, same mock shape.
vi.mock('../cache.js', () => ({ cache: { get: vi.fn().mockResolvedValue(null), set: vi.fn() } }));

// campaignFinanceService.js is imported by fecBulkLoader.ts for
// refreshSummaryAggForSource/getConfirmedFecSources — not exercised by these
// pure-function tests (mapBulkRow only), but it also transitively touches db.js,
// so stub it out rather than let the real module resolve.
vi.mock('../campaignFinanceService.js', () => ({
  refreshSummaryAggForSource: vi.fn(),
  getConfirmedFecSources: vi.fn().mockResolvedValue([]),
}));

import { mapBulkRow } from './fecBulkLoader.js';

/**
 * Build a 21-element pipe-split indiv bulk row so column positions are asserted, not
 * assumed. Column order per the FEC data dictionary (indiv_header_file.csv), matching
 * fecBulkLoader.ts's I_* constants:
 *   0 cmte_id, 1 amndt_ind, 2 rpt_tp, 3 transaction_pgi, 4 image_num, 5 transaction_tp,
 *   6 entity_tp, 7 name, 8 city, 9 state, 10 zip_code, 11 employer, 12 occupation,
 *   13 transaction_dt, 14 transaction_amt, 15 other_id, 16 tran_id, 17 file_num,
 *   18 memo_cd, 19 memo_text, 20 sub_id
 */
function indivRow(overrides: Partial<{
  cmteId: string; amndtInd: string; rptTp: string; transactionPgi: string; imageNum: string;
  transactionTp: string; entityTp: string; name: string; city: string; state: string;
  zipCode: string; employer: string; occupation: string; transactionDt: string;
  transactionAmt: string; otherId: string; tranId: string; fileNum: string; memoCd: string;
  memoText: string; subId: string;
}> = {}): string[] {
  const defaults = {
    cmteId: 'C00736876', amndtInd: 'N', rptTp: 'Q2', transactionPgi: 'P2022', imageNum: '202210169999999999',
    transactionTp: '15', entityTp: 'IND', name: 'TAFT, NANCY', city: 'ATLANTA', state: 'GA',
    zipCode: '30301', employer: 'RETIRED', occupation: 'RETIRED', transactionDt: '06152022',
    transactionAmt: '2900.00', otherId: '', tranId: 'SA11AI.1234', fileNum: '1197695', memoCd: '',
    memoText: '', subId: '4041920221234567890',
  };
  const r = { ...defaults, ...overrides };
  return [
    r.cmteId, r.amndtInd, r.rptTp, r.transactionPgi, r.imageNum, r.transactionTp, r.entityTp,
    r.name, r.city, r.state, r.zipCode, r.employer, r.occupation, r.transactionDt, r.transactionAmt,
    r.otherId, r.tranId, r.fileNum, r.memoCd, r.memoText, r.subId,
  ];
}

describe('mapBulkRow (quick-260729-0jn — amendment + election fields)', () => {
  beforeEach(() => {
    poolQueryMock.mockReset();
  });

  it('carries the five new amendment/election fields in raw_record', () => {
    const row = indivRow();
    const mapped = mapBulkRow(row, 'ps-1', '2022');
    expect(mapped.raw_record['file_number']).toBe('1197695');
    expect(mapped.raw_record['report_type']).toBe('Q2');
    expect(mapped.raw_record['amendment_indicator']).toBe('N');
    expect(mapped.raw_record['transaction_id']).toBe('SA11AI.1234');
    expect(mapped.raw_record['election_type']).toBe('P2022');
  });

  it('still produces every pre-existing raw_record key unchanged', () => {
    const row = indivRow();
    const mapped = mapBulkRow(row, 'ps-1', '2022');
    expect(mapped.raw_record['sub_id']).toBe('4041920221234567890');
    expect(mapped.raw_record['memo_code']).toBe('');
    expect(mapped.raw_record['entity_type']).toBe('IND');
    expect(mapped.raw_record['committee_id']).toBe('C00736876');
    expect(mapped.raw_record['contributor_city']).toBe('ATLANTA');
    expect(mapped.raw_record['contributor_name']).toBe('TAFT, NANCY');
    expect(mapped.raw_record['contributor_state']).toBe('GA');
    expect(mapped.raw_record['contributor_employer']).toBe('RETIRED');
    expect(mapped.raw_record['contributor_occupation']).toBe('RETIRED');
    expect(mapped.raw_record['contribution_receipt_date']).toBe('2022-06-15');
    expect(mapped.raw_record['contribution_receipt_amount']).toBe(2900);
    expect(mapped.raw_record['two_year_transaction_period']).toBe(2022);
  });

  it('keeps source_transaction_id equal to SUB_ID and data_source unchanged (CON-06 dedup key)', () => {
    const row = indivRow({ subId: '4041920229999999999' });
    const mapped = mapBulkRow(row, 'ps-1', '2022');
    expect(mapped.source_transaction_id).toBe('4041920229999999999');
    expect(mapped.data_source).toBe('fec');
  });

  it('does NOT carry a report-year key — deliberate safety property (FEC-04b guard)', () => {
    const row = indivRow();
    const mapped = mapBulkRow(row, 'ps-1', '2022');
    expect(mapped.raw_record['report_year']).toBeUndefined();
    expect(Object.prototype.hasOwnProperty.call(mapped.raw_record, 'report_year')).toBe(false);
  });

  it('maps a row with blank new-column values without throwing, yielding empty strings', () => {
    const row = indivRow({ amndtInd: '', rptTp: '', transactionPgi: '', tranId: '', fileNum: '' });
    expect(() => mapBulkRow(row, 'ps-1', '2022')).not.toThrow();
    const mapped = mapBulkRow(row, 'ps-1', '2022');
    expect(mapped.raw_record['amendment_indicator']).toBe('');
    expect(mapped.raw_record['report_type']).toBe('');
    expect(mapped.raw_record['election_type']).toBe('');
    expect(mapped.raw_record['transaction_id']).toBe('');
    expect(mapped.raw_record['file_number']).toBe('');
  });
});
