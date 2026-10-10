import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// getOutsideSpendingForPolitician reports independent-expenditure committees that spent in a
// politician's race. It was written for `la_socrata` and hardcoded that source system into the
// CTE that gathers a committee's rows, while the CTE that LISTS the committees carried no such
// filter — so a confirmed `ie_committee` link from any other system rendered as a committee card
// with an empty name and $0. Measured on prod 2026-10-09 while adjudicating the CAL-ACCESS
// surname buckets: two real IE committees (Melissa Hurtado's business coalition, John Erickson's
// UNITE HERE Local 11 committee) had to be parked at `not_applicable` for exactly this reason.
//
// ⚠ THE NAIVE FIX IS WRONG. The gathering CTE joins on `external_id` alone, so simply deleting
// the source_system filter merges a CAL-ACCESS filer id with an la_socrata committee id that
// happens to be the same string. Both are bare numbers. `should not merge two committees` below
// is the control for that, and it must fail against the naive fix.
//
// The fake pool models the two tables and INTERPRETS each query's own predicates — which
// source_system values it admits, and which `notes` keys it reads, in order — so these tests
// assert on what the service returns rather than on SQL text, and stay honest across a rewrite.
// ---------------------------------------------------------------------------

interface Source {
  id: string;
  politician: string;
  source_system: string;
  external_id: string;
  source_type: string;
  research_status: string;
  notes: Record<string, string>;
}
interface Contrib { id: string; source: string; amount: number; donor: string }

let sources: Source[] = [];
let contribs: Contrib[] = [];

const POL = 'pol-1';

/** Which source_system values the query's gathering CTE admits for a given declaring row. */
function admitsSystem(sql: string, declaring: Source): (s: Source) => boolean {
  const literal = sql.match(/ps\.source_system\s*=\s*'([a-z_]+)'/);
  if (literal) return (s) => s.source_system === literal[1];
  if (/ps\.source_system\s*=\s*\w+\.source_system/.test(sql)) {
    return (s) => s.source_system === declaring.source_system;
  }
  return () => true;
}

/** The `notes` keys the query reads, in the order it reads them. */
function notesKeys(sql: string): string[] {
  return [...sql.matchAll(/notes::jsonb\s*->>\s*'(\w+)'/g)].map((m) => m[1]);
}

function declaredIeLinks(politicianId: string): Source[] {
  return sources.filter(
    (s) => s.politician === politicianId && s.source_type === 'ie_committee' && s.research_status === 'confirmed'
  );
}

/** Every source row the query would gather for each declared committee. */
function gathered(sql: string, politicianId: string) {
  return declaredIeLinks(politicianId).map((declaring) => {
    const admits = admitsSystem(sql, declaring);
    const rows = sources.filter((s) => s.external_id === declaring.external_id && admits(s));
    const keys = notesKeys(sql);
    const label = keys.map((k) => declaring.notes[k]).find((v) => v != null) ?? null;
    return { declaring, rows, label };
  });
}

const query = vi.fn(async (sql: string, params: unknown[] = []) => {
  const politicianId = params[0] as string;

  if (sql.includes("'ie_committee'")) {
    const groups = gathered(sql, politicianId);

    // the top-donors query
    if (/donor_name_normalized\s+AS\s+donor_name/i.test(sql)) {
      const rows: Array<{ cmt_id: string; donor_name: string; amount: string }> = [];
      for (const g of groups) {
        const byDonor = new Map<string, number>();
        for (const c of contribs.filter((c) => g.rows.some((r) => r.id === c.source))) {
          byDonor.set(c.donor, (byDonor.get(c.donor) ?? 0) + c.amount);
        }
        for (const [donor_name, amount] of [...byDonor].sort((a, b) => b[1] - a[1])) {
          rows.push({ cmt_id: g.declaring.external_id, donor_name, amount: String(amount) });
        }
      }
      return { rows };
    }

    // the totals query
    return {
      rows: groups.map((g) => {
        const cs = contribs.filter((c) => g.rows.some((r) => r.id === c.source));
        return {
          cmt_id: g.declaring.external_id,
          cmt_nm: g.label,
          total_amount: String(cs.reduce((s, c) => s + c.amount, 0)),
          contribution_count: String(cs.length),
        };
      }),
    };
  }

  // Everything else answers empty, which drives getSummary down its zero-state path —
  // the shortest route to the outside-spending block.
  return { rows: [] };
});

vi.mock('./db.js', () => ({ pool: { query: (sql: string, params?: unknown[]) => query(sql, params) } }));

import { getSummary } from './campaignFinanceService.js';

beforeEach(() => {
  sources = [];
  contribs = [];
  query.mockClear();
});

function ieLink(over: Partial<Source> & { id: string; external_id: string }): Source {
  return {
    politician: POL,
    source_system: 'la_socrata',
    source_type: 'ie_committee',
    research_status: 'confirmed',
    notes: {},
    ...over,
  };
}

describe('outside spending', () => {
  it('publishes an la_socrata IE committee', async () => {
    sources = [ieLink({ id: 's1', external_id: 'C1', notes: { cmt_nm: 'FRIENDS OF SOMEONE' } })];
    contribs = [
      { id: 'c1', source: 's1', amount: 1000, donor: 'acme corp' },
      { id: 'c2', source: 's1', amount: 500, donor: 'beta llc' },
    ];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([
      expect.objectContaining({
        cmt_id: 'C1',
        cmt_nm: 'FRIENDS OF SOMEONE',
        total_amount: 1500,
        contribution_count: 2,
      }),
    ]);
  });

  it('publishes a CAL-ACCESS IE committee, with the name from committee_name', async () => {
    sources = [
      ieLink({
        id: 's1',
        source_system: 'cal_access',
        external_id: '1447993',
        notes: { committee_name: 'COALITION OF BUSINESS ORGANIZATIONS SUPPORTING SENATOR MELISSA' },
      }),
    ];
    contribs = [{ id: 'c1', source: 's1', amount: 344843.8, donor: 'a trade association' }];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([
      expect.objectContaining({
        cmt_id: '1447993',
        cmt_nm: 'COALITION OF BUSINESS ORGANIZATIONS SUPPORTING SENATOR MELISSA',
        total_amount: 344843.8,
        contribution_count: 1,
      }),
    ]);
  });

  it('reports top donors for a CAL-ACCESS IE committee', async () => {
    sources = [
      ieLink({ id: 's1', source_system: 'cal_access', external_id: '1489255', notes: { committee_name: 'WORKING FAMILIES FOR JOHN' } }),
    ];
    contribs = [
      { id: 'c1', source: 's1', amount: 25000, donor: 'unite here local 11' },
      { id: 'c2', source: 's1', amount: 100, donor: 'a small donor' },
    ];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees[0]?.top_donors).toEqual([
      { donor_name: 'unite here local 11', amount: 25000 },
      { donor_name: 'a small donor', amount: 100 },
    ]);
  });

  it('should not merge two committees whose ids collide across source systems', async () => {
    // A CAL-ACCESS filer id and an la_socrata committee id are both bare numbers, so they can
    // be the same string while naming two unrelated committees. Dropping the source_system
    // filter instead of correlating it would sum them together.
    sources = [
      ieLink({ id: 's-cal', source_system: 'cal_access', external_id: '1447993', notes: { committee_name: 'THE CAL-ACCESS ONE' } }),
      ieLink({
        id: 's-la',
        politician: 'pol-other',
        source_system: 'la_socrata',
        external_id: '1447993',
        notes: { cmt_nm: 'AN UNRELATED LA COMMITTEE' },
      }),
    ];
    contribs = [
      { id: 'c1', source: 's-cal', amount: 100, donor: 'cal donor' },
      { id: 'c2', source: 's-la', amount: 999999, donor: 'la donor' },
    ];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([
      expect.objectContaining({ cmt_id: '1447993', cmt_nm: 'THE CAL-ACCESS ONE', total_amount: 100, contribution_count: 1 }),
    ]);
  });

  it('leaves a non-confirmed IE link out entirely', async () => {
    sources = [
      ieLink({ id: 's1', source_system: 'cal_access', external_id: '1447993', research_status: 'not_applicable', notes: { committee_name: 'PARKED' } }),
    ];
    contribs = [{ id: 'c1', source: 's1', amount: 500, donor: 'someone' }];

    const { summary } = await getSummary(POL);

    expect(summary.outside_spending.committees).toEqual([]);
  });
});
