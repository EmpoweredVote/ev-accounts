import { vi, describe, it, expect } from 'vitest';

// ---------------------------------------------------------------------------
// Donor type for the state sources. cal_access, indiana and ocpf each keep the donor type under
// their own raw key (ENTITY_CD / ContributorType / recordTypeDescription), and none of them sets
// FEC's entity_type, so before this every politician on those sources showed individual 0 / PAC 0
// and every top donor as 'unknown'. The SQL split and extractDonorType must agree row for row.
// ---------------------------------------------------------------------------

vi.mock('./db.js', () => ({ pool: { query: vi.fn(async () => ({ rows: [] })) } }));

import { extractDonorType, IS_INDIVIDUAL_SQL, IS_PAC_SQL } from './campaignFinanceService.js';

describe('extractDonorType — state sources', () => {
  it.each([
    [{ ENTITY_CD: 'IND' }, 'individual'],
    [{ ENTITY_CD: 'SCC' }, 'pac'],
    [{ ENTITY_CD: 'PTY' }, 'pac'],
    [{ ENTITY_CD: 'COM' }, 'committee'],
    [{ ENTITY_CD: 'OTH' }, 'committee'],
    [{ ContributorType: 'Individual' }, 'individual'],
    [{ ContributorType: 'Political Action Committee' }, 'pac'],
    [{ ContributorType: 'Political Action' }, 'pac'],
    [{ ContributorType: 'Corporation' }, 'committee'],
    [{ ContributorType: '' }, 'unknown'],
    [{ recordTypeDescription: 'Individual' }, 'individual'],
    [{ recordTypeDescription: 'Committee' }, 'committee'],
    [{ recordTypeDescription: 'Union/Association' }, 'committee'],
    [{ recordTypeDescription: 'Aggregated Unitemized Receipts' }, 'unknown'],
  ])('%o → %s', (raw, expected) => {
    expect(extractDonorType(raw)).toBe(expected);
  });

  it('leaves FEC, Monroe and la_socrata rows as before', () => {
    expect(extractDonorType({ entity_type: 'IND' })).toBe('individual');
    expect(extractDonorType({ entity_type: 'COM' })).toBe('committee');
    expect(extractDonorType({ type: 'pac' })).toBe('pac');
    expect(extractDonorType({ con_type: 'Monetary Contributions (Itemized)', cmt_type: 'C' })).toBe('unknown');
  });
});

describe('individual / PAC SQL predicates', () => {
  it('read each state source key with the same values extractDonorType uses', () => {
    expect(IS_INDIVIDUAL_SQL).toContain("c.raw_record->>'ENTITY_CD' = 'IND'");
    expect(IS_INDIVIDUAL_SQL).toContain("c.raw_record->>'ContributorType' = 'Individual'");
    expect(IS_INDIVIDUAL_SQL).toContain("c.raw_record->>'recordTypeDescription' = 'Individual'");
    expect(IS_PAC_SQL).toContain("c.raw_record->>'ENTITY_CD' IN ('SCC', 'PTY')");
    expect(IS_PAC_SQL).toContain("c.raw_record->>'ContributorType' IN ('Political Action Committee', 'Political Action')");
  });

  it('never counts an ambiguous committee code as a PAC', () => {
    expect(IS_PAC_SQL).not.toMatch(/'COM'/);
    expect(IS_PAC_SQL).not.toMatch(/'Committee'/);
  });
});
