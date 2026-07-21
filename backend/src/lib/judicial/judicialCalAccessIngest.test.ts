import { vi, describe, it, expect } from 'vitest';

// Mock the shared pool so importing judicialCalAccessIngest.ts (which imports
// ../db.js at module scope) doesn't trigger env.ts's startup validation /
// process.exit(1) in a test environment with no real DATABASE_URL. This test
// exercises only the pure mapping fn — writeJudicialDonations (the only export
// that touches pool.query) is never called here; the real-DB smoke test is
// Plan 30-03. Mirrors the established pattern in essentialsBrowseService.test.ts.
vi.mock('../db.js', () => ({ pool: { query: vi.fn() } }));

import { mapContributionsToJudicialDonations } from './judicialCalAccessIngest.js';
import type { ContributionInsert } from '../adapters/adapterInterface.js';

/**
 * Fixture builder mirroring electionGrouping.test.ts's `row(over)` pattern.
 * Produces a ContributionInsert with a raw_record shaped like a Cal-Access
 * RCPT_CD.TSV row (CTRIB_NAML/CTRIB_NAMF/CTRIB_EMP/CTRIB_OCC) and a
 * source_transaction_id in the exact `${filingID}_${amendID}_${lineItem}`
 * idempotency-key format produced by calAccessAdapter.ts's normalize().
 *
 * This test exercises ONLY the pure mapping fn — no DB connection is opened.
 * The real-DB smoke test for writeJudicialDonations() happens in Plan 30-03.
 */
const contribution = (over: Partial<ContributionInsert> = {}): ContributionInsert => ({
  politician_source_id: 'judge-1',
  donor_id: null,
  committee_id: null,
  amount: 500,
  contribution_date: new Date('2018-06-01'),
  election_cycle: '2018',
  confidence_level: 'HIGH',
  data_source: 'cal_access',
  source_transaction_id: '12345_0_1',
  raw_record: {
    CTRIB_NAML: 'Smith',
    CTRIB_NAMF: 'Jane',
    CTRIB_EMP: 'Acme LLP',
    CTRIB_OCC: 'Attorney',
  },
  donor_name_normalized: 'jane smith',
  ...over,
});

describe('mapContributionsToJudicialDonations', () => {
  it('reconstructs donor_name_raw from raw_record CTRIB_NAML/CTRIB_NAMF', () => {
    const [row] = mapContributionsToJudicialDonations('judge-1', [contribution()]);
    expect(row.donor_name_raw).toBe('Smith Jane');
  });

  it('trims donor_name_raw when one of CTRIB_NAML/CTRIB_NAMF is missing', () => {
    const [row] = mapContributionsToJudicialDonations(
      'judge-1',
      [contribution({ raw_record: { CTRIB_NAML: 'Doe', CTRIB_NAMF: undefined, CTRIB_EMP: null, CTRIB_OCC: null } })]
    );
    expect(row.donor_name_raw).toBe('Doe');
  });

  it('preserves source_transaction_id byte-for-byte (idempotency-key format)', () => {
    const [row] = mapContributionsToJudicialDonations(
      'judge-1',
      [contribution({ source_transaction_id: '99999_2_7' })]
    );
    expect(row.source_transaction_id).toBe('99999_2_7');
  });

  it('sets confidence_level HIGH and copies raw_record verbatim', () => {
    const rawRecord = { CTRIB_NAML: 'Smith', CTRIB_NAMF: 'Jane', CTRIB_EMP: 'Acme LLP', CTRIB_OCC: 'Attorney' };
    const [row] = mapContributionsToJudicialDonations(
      'judge-1',
      [contribution({ confidence_level: 'HIGH', raw_record: rawRecord })]
    );
    expect(row.confidence_level).toBe('HIGH');
    expect(row.raw_record).toEqual(rawRecord);
  });

  it('carries donor_employer_raw/donor_occupation_raw from CTRIB_EMP/CTRIB_OCC and leaves donor_type null', () => {
    const [row] = mapContributionsToJudicialDonations('judge-1', [contribution()]);
    expect(row.donor_employer_raw).toBe('Acme LLP');
    expect(row.donor_occupation_raw).toBe('Attorney');
    expect(row.donor_type).toBeNull();
  });

  it('nulls donor_employer_raw/donor_occupation_raw when CTRIB_EMP/CTRIB_OCC are absent', () => {
    const [row] = mapContributionsToJudicialDonations(
      'judge-1',
      [contribution({ raw_record: { CTRIB_NAML: 'Doe', CTRIB_NAMF: 'John' } })]
    );
    expect(row.donor_employer_raw).toBeNull();
    expect(row.donor_occupation_raw).toBeNull();
  });

  it('attaches the caller-supplied judgeId, not politician_source_id', () => {
    const [row] = mapContributionsToJudicialDonations(
      'judge-abc',
      [contribution({ politician_source_id: 'ignored-value' })]
    );
    expect(row.judge_id).toBe('judge-abc');
  });
});
