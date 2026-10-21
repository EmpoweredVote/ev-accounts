import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// LA City Ethics (la_socrata) files loans (Schedule B) and "Misc. Increases to Cash" (Schedule I: city matching
// funds, vendor refunds, voided checks) beside its contribution schedules A and C. None of B or I is a donation,
// so they must stay out of raised, refunds, the split, sectors and top donors, and matching funds get their own
// line. The fake pool records each query so these tests pin the predicates every gross figure uses.
// ---------------------------------------------------------------------------

const calls: string[] = [];
const query = vi.fn(async (sql: string) => {
  calls.push(sql);
  return { rows: [] };
});
vi.mock('./db.js', () => ({ pool: { query: (sql: string, params?: unknown[]) => query(sql, params) } }));

import {
  NON_CONTRIBUTION_SQL,
  DONATION_SQL,
  REFUND_SQL,
  PUBLIC_MATCHING_FUNDS_SQL,
  refreshSummaryAgg,
} from './campaignFinanceService.js';

beforeEach(() => {
  calls.length = 0;
  query.mockClear();
});

describe('LA non-contribution schedules', () => {
  it('only la_socrata Schedule B and I are non-contributions, and a missing schedule is not one', () => {
    expect(NON_CONTRIBUTION_SQL).toContain("COALESCE(c.data_source, '') = 'la_socrata'");
    expect(NON_CONTRIBUTION_SQL).toContain("COALESCE(c.raw_record->>'schedule', '') IN ('B', 'I')");
  });

  it('donations and refunds both leave them out', () => {
    expect(DONATION_SQL).toBe(`(c.amount >= 0 AND NOT ${NON_CONTRIBUTION_SQL})`);
    expect(REFUND_SQL).toBe(`(c.amount < 0 AND NOT ${NON_CONTRIBUTION_SQL})`);
  });

  it('matching funds are la_socrata Schedule I paid by a City body or described as matching / public financing', () => {
    expect(PUBLIC_MATCHING_FUNDS_SQL).toContain("c.raw_record->>'schedule' = 'I'");
    expect(PUBLIC_MATCHING_FUNDS_SQL).toContain("'(matching|public financ)'");
    expect(PUBLIC_MATCHING_FUNDS_SQL).toContain("'(city of los a|los angeles city)'");
  });

  it('every agg figure uses the shared predicates, never a bare amount test', async () => {
    await refreshSummaryAgg('00000000-0000-4000-8000-000000000001', '2026');
    const reads = calls.filter((sql) => sql.includes('FROM transparent_motivations.contributions c'));
    expect(reads.length).toBeGreaterThan(0);
    for (const sql of reads) {
      expect(sql).toContain(NON_CONTRIBUTION_SQL);
      expect(sql.replaceAll(DONATION_SQL, '').replaceAll(REFUND_SQL, '')).not.toMatch(/c\.amount [<>]=? 0/);
    }
  });
});
