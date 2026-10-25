import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// getContributions ?donor= — the Top Donors list opens a donor's own transactions.
//
// A top_donors `name` is the DONOR_NAME_SQL grouping key (raw contributor name), while
// donor_name_normalized is a different, lowercased form. The filter must match the exact
// grouping key AND stay on the indexed column, including the '' legacy rows (la_socrata) that
// were never normalized. The fake pool records each query so these tests pin both predicates.
// ---------------------------------------------------------------------------

const calls: { sql: string; params: unknown[] }[] = [];

const query = vi.fn(async (sql: string, params: unknown[] = []) => {
  calls.push({ sql, params });
  if (sql.includes('COUNT(*) AS count')) return { rows: [{ count: '1' }] };
  if (sql.includes('ORDER BY c.contribution_date DESC')) {
    return {
      rows: [
        {
          id: 'c1', amount: '500', contribution_date: '2025-07-14', election_cycle: '2026',
          confidence_level: 'HIGH', data_source: 'la_socrata', donor_name_normalized: '',
          raw_record: { con_name: 'Victor Syng' },
        },
      ],
    };
  }
  return { rows: [] };
});

vi.mock('./db.js', () => ({ pool: { query: (sql: string, params?: unknown[]) => query(sql, params) } }));

import { getContributions, encodeCursor } from './campaignFinanceService.js';

const POLITICIAN = '00000000-0000-4000-8000-000000000001';
const pageCall = () => calls.find((c) => c.sql.includes('ORDER BY c.contribution_date DESC'))!;
const countCall = () => calls.find((c) => c.sql.includes('COUNT(*) AS count'))!;

beforeEach(() => {
  calls.length = 0;
  query.mockClear();
});

describe('getContributions donor filter', () => {
  it('matches the indexed normalized key (and legacy blanks) plus the exact top-donor name', async () => {
    await getContributions(POLITICIAN, { cycle: '2026', donor: 'SIMON, DEBORAH' });

    for (const call of [pageCall(), countCall()]) {
      expect(call.sql).toMatch(/c\.donor_name_normalized IN \(\$3, ''\)/);
      expect(call.sql).toMatch(/COALESCE\(c\.raw_record->>'contributor_name'[\s\S]*\) = \$4/);
      expect(call.params.slice(0, 4)).toEqual([POLITICIAN, '2026', 'deborah simon', 'SIMON, DEBORAH']);
    }
  });

  it('numbers the donor params after ?confidence= and before the cursor', async () => {
    const cursor = encodeCursor(new Date('2025-07-14T00:00:00.000Z'), '00000000-0000-4000-8000-0000000000c9');
    await getContributions(POLITICIAN, { cycle: '2026', confidence: 'HIGH', donor: 'Victor Syng', cursor });
    const call = pageCall();
    expect(call.sql).toMatch(/c\.confidence_level = \$3/);
    expect(call.sql).toMatch(/IN \(\$4, ''\)/);
    expect(call.sql).toMatch(/< \(\$6, \$7\)/);
    expect(call.params.slice(2)).toEqual(['HIGH', 'victor syng', 'Victor Syng', '2025-07-14T00:00:00.000Z', '00000000-0000-4000-8000-0000000000c9']);
  });

  it('echoes the donor so a client can tell this API from one that ignores ?donor=', async () => {
    const { response } = await getContributions(POLITICIAN, { cycle: '2026', donor: 'Victor Syng' });
    expect(response.filter).toEqual({ donor: 'Victor Syng' });
    expect(response.page_info.total_count).toBe(1);
  });

  it('leaves the unfiltered list unchanged: no donor predicate, no filter echo', async () => {
    const { response } = await getContributions(POLITICIAN, { cycle: '2026' });
    expect(pageCall().sql).not.toContain('donor_name_normalized IN');
    expect(countCall().sql).not.toContain('donor_name_normalized IN');
    expect(pageCall().params).toEqual([POLITICIAN, '2026']);
    expect(response).not.toHaveProperty('filter');
  });
});
