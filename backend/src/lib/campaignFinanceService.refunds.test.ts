import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// "Raised" is GROSS receipts; returned contributions are reported on their own line (CA_0255,
// operator decision 2026-09-24). A refund is a NEGATIVE itemized row, and before CA_0255 every
// figure was SUM(amount), so refunds counted against "raised": Gavin Newsom's 2024 cycle (two
// returned contributions on Cal-Access filing 2834446, -$104.40 and -$234.36, nothing else) opened
// the summary as "raised -$338.76".
//
// The fake pool holds contribution rows and answers each query from them. Row-level reads (sectors,
// top donors) drop refund rows ONLY when the query's own SQL says `AND c.amount >= 0`, so these
// tests fail if a query stops filtering, not merely if a helper changes.
// ---------------------------------------------------------------------------

interface Contrib { source: string; cycle: string; amount: number; donor: string; occupation: string }
interface AggFixture {
  source: string; cycle: string; data_source: string; contribution_count: number; total_amount: number;
  gross_amount: number; refunded_amount: number; refund_count: number;
  top_donors?: { name: string; total_amount: number; contribution_count: number }[];
}

let contribs: Contrib[] = [];
let agg: AggFixture[] = [];
let fecReceipts: number | null = null;
let inserted: unknown[] | null = null;

const refundFiltered = (sql: string) => /AND c\.amount >= 0/.test(sql);
const rowsFor = (sql: string, params: unknown[]) => {
  const cycle = params[1] as string;
  // refreshSummaryAgg keys by politician_source_id; getSummary by politician (one here).
  const bySource = sql.includes('c.politician_source_id = $1');
  return contribs.filter(
    (c) => c.cycle === cycle && (!bySource || c.source === params[0]) && (!refundFiltered(sql) || c.amount >= 0)
  );
};
const sum = (cs: Contrib[]) => cs.reduce((s, c) => s + c.amount, 0);

const query = vi.fn(async (sql: string, params: unknown[] = []) => {
  if (sql.includes('fec_candidate_totals')) {
    return { rows: sql.includes('AS receipts') ? [{ receipts: fecReceipts == null ? null : String(fecReceipts) }] : [] };
  }
  if (sql.includes('INSERT INTO transparent_motivations.contribution_summary_agg')) {
    inserted = params;
    return { rows: [] };
  }
  if (sql.includes('contribution_summary_agg a')) {
    if (sql.includes('SELECT DISTINCT a.election_cycle')) {
      return { rows: [...new Set(agg.map((a) => a.cycle))].sort().reverse().map((election_cycle) => ({ election_cycle })) };
    }
    return {
      rows: agg.filter((a) => a.cycle === params[1]).map((a) => ({
        election_cycle: a.cycle, data_source: a.data_source,
        contribution_count: String(a.contribution_count), total_amount: String(a.total_amount),
        gross_amount: String(a.gross_amount), refunded_amount: String(a.refunded_amount),
        refund_count: String(a.refund_count),
        individual_total: '0', pac_total: '0', confidence_min: 1, sector_breakdown: [],
        top_donors: (a.top_donors ?? []).map((d) => ({
          ...d, donor_type: '', employer: '', occupation: '', sector: '', confidence_level: 'HIGH',
        })),
      })),
    };
  }
  if (!sql.includes('transparent_motivations.contributions c')) return { rows: [] };

  if (sql.includes('SELECT DISTINCT c.election_cycle')) {
    return { rows: [...new Set(contribs.map((c) => c.cycle))].sort().reverse().map((election_cycle) => ({ election_cycle })) };
  }
  const all = rowsFor(sql.replace(/AND c\.amount >= 0/g, ''), params); // totals see every row
  const gross = all.filter((c) => c.amount >= 0);
  const refunds = all.filter((c) => c.amount < 0);
  if (sql.includes('AS row_count')) {
    return {
      rows: [{
        row_count: String(all.length), contribution_count: String(gross.length), total_amount: String(sum(all)),
        gross_amount: String(sum(gross)), refunded_amount: String(-sum(refunds)), refund_count: String(refunds.length),
        confidence_min: '1', individual_total: '0', pac_total: '0', data_source: 'cal_access',
      }],
    };
  }
  if (sql.includes('AS gross_total')) {
    return {
      rows: [{
        gross_total: String(sum(gross)), non_fec_gross: String(sum(gross)),
        refunded_total: String(-sum(refunds)), non_fec_refunded: String(-sum(refunds)),
        refund_count: String(refunds.length), non_fec_refund_count: String(refunds.length),
        contribution_count: String(gross.length), confidence_level_n: all.length ? '1' : '0',
        individual_total: '0', pac_total: '0',
      }],
    };
  }
  const rows = rowsFor(sql, params);
  if (sql.includes('AS occupation')) {
    return { rows: rows.map((c) => ({ occupation: c.occupation, amount: String(c.amount), total: String(c.amount), count: '1' })) };
  }
  if (sql.includes('AS contributor_name')) {
    const g = new Map<string, Contrib[]>();
    for (const c of rows) g.set(c.donor, [...(g.get(c.donor) ?? []), c]);
    return {
      rows: [...g.entries()].map(([name, cs]) => ({
        contributor_name: name, total_amount: String(sum(cs)), contribution_count: String(cs.length),
        confidence_level_n: '1', raw_record: { contributor_name: name, contributor_occupation: cs[0].occupation },
      })),
    };
  }
  if (sql.includes('SELECT c.data_source')) return { rows: rows.length ? [{ data_source: 'cal_access' }] : [] };
  return { rows: [] };
});

vi.mock('./db.js', () => ({ pool: { query: (sql: string, params?: unknown[]) => query(sql, params) } }));

import { getSummary, refreshSummaryAgg, headlineTotals } from './campaignFinanceService.js';

const POLITICIAN = '00000000-0000-4000-8000-000000000001';
const NEWSOM_2024: Contrib[] = [
  { source: 's1', cycle: '2024', amount: -104.4, donor: 'DONOR A', occupation: 'ATTORNEY' },
  { source: 's1', cycle: '2024', amount: -234.36, donor: 'DONOR B', occupation: 'ATTORNEY' },
];
const MIXED_2022: Contrib[] = [
  { source: 's1', cycle: '2022', amount: 1000, donor: 'GIVER', occupation: 'ATTORNEY' },
  { source: 's1', cycle: '2022', amount: 500, donor: 'KEEPER', occupation: 'ENGINEER' },
  { source: 's1', cycle: '2022', amount: -200, donor: 'GIVER', occupation: 'ATTORNEY' },
  { source: 's1', cycle: '2022', amount: -50, donor: 'REFUNDED ONLY', occupation: 'ENGINEER' },
];

beforeEach(() => {
  contribs = [...NEWSOM_2024, ...MIXED_2022];
  agg = [];
  fecReceipts = null;
  inserted = null;
  query.mockClear();
});

describe('refreshSummaryAgg stores gross, refunds and a net total separately', () => {
  it('a refunds-only cycle keeps its row: gross 0, refunded 338.76, 2 refunds, no donors', async () => {
    await refreshSummaryAgg('s1', '2024');
    // $4 count, $5 net, $10 top_donors json, $11 gross, $12 refunded, $13 refund_count
    expect(inserted).not.toBeNull();
    const p = inserted!;
    expect(p[3]).toBe(0);
    expect(p[4]).toBeCloseTo(-338.76);
    expect(p[10]).toBe(0);
    expect(p[11]).toBeCloseTo(338.76);
    expect(p[12]).toBe(2);
    expect(JSON.parse(p[9] as string)).toEqual([]);
  });

  it('a mixed cycle: gross from positive rows, donors and sectors gross, refunds apart', async () => {
    await refreshSummaryAgg('s1', '2022');
    const p = inserted!;
    expect(p[3]).toBe(2);
    expect(p[4]).toBe(1250);
    expect(p[10]).toBe(1500);
    expect(p[11]).toBe(250);
    expect(p[12]).toBe(2);
    const donors = JSON.parse(p[9] as string) as { name: string; total_amount: number }[];
    expect(donors.map((d) => [d.name, d.total_amount])).toEqual([['GIVER', 1000], ['KEEPER', 500]]);
    const sectors = JSON.parse(p[8] as string) as { total: number }[];
    expect(sectors.reduce((s, x) => s + x.total, 0)).toBe(1500);
  });
});

describe('getSummary (agg fast path) reports raised as gross and refunds on their own line', () => {
  it('refunds-only cycle: raised 0, refunded 338.76', async () => {
    agg = [{ source: 's1', cycle: '2024', data_source: 'cal_access', contribution_count: 0, total_amount: -338.76,
      gross_amount: 0, refunded_amount: 338.76, refund_count: 2 }];
    const { summary } = await getSummary(POLITICIAN, '2024');
    expect(summary.total_raised).toBe(0);
    expect(summary.total_refunded).toBeCloseTo(338.76);
    expect(summary.refund_count).toBe(2);
    expect(summary.contribution_count).toBe(0);
  });

  it('mixed cycle: raised is gross, not net', async () => {
    agg = [{ source: 's1', cycle: '2022', data_source: 'cal_access', contribution_count: 2, total_amount: 1250,
      gross_amount: 1500, refunded_amount: 250, refund_count: 2 }];
    const { summary } = await getSummary(POLITICIAN, '2022');
    expect(summary.total_raised).toBe(1500);
    expect(summary.total_refunded).toBe(250);
  });

  it('FEC cycle: authoritative receipts carry the headline; FEC itemized refunds are not added', async () => {
    fecReceipts = 9000;
    agg = [
      { source: 'f1', cycle: '2024', data_source: 'fec', contribution_count: 10, total_amount: 4700,
        gross_amount: 5000, refunded_amount: 300, refund_count: 3 },
      { source: 's1', cycle: '2024', data_source: 'cal_access', contribution_count: 1, total_amount: 80,
        gross_amount: 100, refunded_amount: 20, refund_count: 1 },
    ];
    const { summary } = await getSummary(POLITICIAN, '2024');
    expect(summary.total_raised).toBe(9100); // FEC receipts + non-FEC gross
    expect(summary.total_refunded).toBe(20); // non-FEC refunds only
    expect(summary.refund_count).toBe(1);
  });
});

describe('getSummary (live path, confidence filter) applies the same split', () => {
  it('refunds-only cycle: raised 0, refunded 338.76, and refunds are not "donors"', async () => {
    const { summary } = await getSummary(POLITICIAN, '2024', 'HIGH');
    expect(summary.total_raised).toBe(0);
    expect(summary.total_refunded).toBeCloseTo(338.76);
    expect(summary.refund_count).toBe(2);
    expect(summary.top_donors).toEqual([]);
    expect(summary.sector_breakdown).toEqual([]);
  });

  it('mixed cycle: donors and sectors are gross; a refund-only donor does not appear', async () => {
    const { summary } = await getSummary(POLITICIAN, '2022', 'HIGH');
    expect(summary.total_raised).toBe(1500);
    expect(summary.total_refunded).toBe(250);
    expect(summary.top_donors.map((d) => [d.name, d.total_amount]).sort()).toEqual([['GIVER', 1000], ['KEEPER', 500]]);
    expect(summary.sector_breakdown.reduce((s, x) => s + x.total, 0)).toBe(1500);
  });
});

describe('headlineTotals', () => {
  const itemized = { gross: 5100, refunded: 320, refundCount: 4 };
  const nonFec = { gross: 100, refunded: 20, refundCount: 1 };
  it('uses FEC receipts + non-FEC gross, and non-FEC refunds only, when FEC is authoritative', () => {
    expect(headlineTotals(9000, itemized, nonFec)).toEqual({ total_raised: 9100, total_refunded: 20, refund_count: 1 });
  });
  it('uses the itemized figures of every source otherwise', () => {
    expect(headlineTotals(null, itemized, nonFec)).toEqual({ total_raised: 5100, total_refunded: 320, refund_count: 4 });
  });
});
