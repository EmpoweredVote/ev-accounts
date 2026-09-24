import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// A fake pool that holds one politician's candidate_committee links and answers the
// zero-state getSummary path. Every query it does not recognise returns no rows, which is
// what a politician with no confirmed contributions, no agg rows and no IE committees gets.
//
// The source-count query is answered by applying the query's OWN research_status predicate
// to the fake links, so these tests assert on the status getSummary returns, not on SQL text.
// ---------------------------------------------------------------------------

// `run` is the status of the link's latest ingestion run; absent means it has never been ingested.
let links: { research_status: string; run?: string }[] = [];
let districtType: string | null = null;
// Filed summary sheets; each belongs to links[linkIndex]. Rows carry DB shapes (numeric as string).
let reports: ({ linkIndex: number } & Record<string, unknown>)[] = [];

/**
 * Run statuses the query treats as "ingestion done" (its NOT EXISTS over ingestion_runs), or null
 * when the query does not look at runs at all. Read from the query itself, like admittedStatuses.
 */
function doneRunStatuses(sql: string): string[] | null {
  const m = sql.match(/NOT EXISTS[\s\S]*ingestion_runs[\s\S]*?\.status\s+IN\s*\(([^)]*)\)/i);
  return m ? [...m[1].matchAll(/'(\w+)'/g)].map((x) => x[1]) : null;
}

/** Statuses a WHERE clause admits: `= 'x'`, `IN ('x', 'y')`, or every status when unfiltered. */
function admittedStatuses(sql: string): string[] | null {
  const eq = sql.match(/research_status\s*=\s*'(\w+)'/);
  if (eq) return [eq[1]];
  const inList = sql.match(/research_status\s+IN\s*\(([^)]*)\)/i);
  if (inList) return [...inList[1].matchAll(/'(\w+)'/g)].map((m) => m[1]);
  return null;
}

const query = vi.fn(async (sql: string) => {
  // First: this query also joins politician_sources on candidate_committee, so the branch below would match it.
  if (sql.includes('transparent_motivations.filed_report_summaries')) {
    const admitted = admittedStatuses(sql);
    return {
      rows: reports
        .filter((r) => admitted === null || admitted.includes(links[r.linkIndex].research_status))
        .map(({ linkIndex: _linkIndex, ...row }) => row),
    };
  }
  if (/FROM transparent_motivations\.politician_sources[\s\S]*source_type = 'candidate_committee'/.test(sql)) {
    const admitted = admittedStatuses(sql);
    const done = doneRunStatuses(sql);
    const cnt = links
      .filter((l) => admitted === null || admitted.includes(l.research_status))
      .filter((l) => done === null || l.run === undefined || !done.includes(l.run)).length;
    return { rows: [{ cnt: String(cnt) }] };
  }
  if (sql.includes('essentials.office_current_holder')) {
    return { rows: districtType === null ? [] : [{ district_type: districtType }] };
  }
  return { rows: [] };
});

vi.mock('./db.js', () => ({ pool: { query: (sql: string) => query(sql) } }));

import { getSummary } from './campaignFinanceService.js';

const POLITICIAN = '00000000-0000-4000-8000-000000000001';

async function coverageStatus(): Promise<string | undefined> {
  const { summary } = await getSummary(POLITICIAN);
  return summary.coverage_status;
}

beforeEach(() => {
  links = [];
  districtType = null;
  reports = [];
  query.mockClear();
});

describe('getSummary coverage_status — which candidate_committee links count as "sourced"', () => {
  // Positive control: without it, a fake that counted nothing would pass every test below.
  it("reports 'data_pending' for a confirmed link with nothing ingested yet", async () => {
    links = [{ research_status: 'confirmed' }];
    expect(await coverageStatus()).toBe('data_pending');
  });

  // CA_0174, CA_0177 and CA_0178 disputed 1,187 wrong committee links. A wrong link is not a
  // filing on its way: the banner says "filings for this candidate have been sourced".
  it("does not report 'data_pending' when the only link is disputed", async () => {
    links = [{ research_status: 'disputed' }];
    expect(await coverageStatus()).not.toBe('data_pending');
    expect(await coverageStatus()).toBe('no_data');
  });

  it("reports 'local_unavailable' for a local office whose only link is disputed", async () => {
    links = [{ research_status: 'disputed' }];
    districtType = 'SCHOOL';
    expect(await coverageStatus()).toBe('local_unavailable');
  });

  // Migration 1792 demoted 4,540 name-mismatched links to not_applicable.
  it("does not report 'data_pending' when the only link is not_applicable", async () => {
    links = [{ research_status: 'not_applicable' }];
    expect(await coverageStatus()).toBe('no_data');
  });

  // The ingestion scheduler reads confirmed links only, so a needs_research link never becomes
  // contribution data by waiting — "check back soon" would be false for it.
  it("does not report 'data_pending' when the only link still needs research", async () => {
    links = [{ research_status: 'needs_research' }];
    expect(await coverageStatus()).toBe('no_data');
  });

  it("still reports 'data_pending' when a confirmed link sits beside disputed ones", async () => {
    links = [{ research_status: 'disputed' }, { research_status: 'confirmed' }, { research_status: 'needs_research' }];
    expect(await coverageStatus()).toBe('data_pending');
  });
});

describe('getSummary coverage_status — "data pending" only while an ingestion run is still owed', () => {
  // Corey Calaycay, 2026-09-24: both confirmed committees ran and fetched 0 records (a local
  // committee's filings are with the city clerk), yet the panel promised data "being processed".
  it("does not report 'data_pending' once the only confirmed committee has completed a run", async () => {
    links = [{ research_status: 'confirmed', run: 'completed' }];
    expect(await coverageStatus()).toBe('no_data');
  });

  it("reports 'local_unavailable' for a local office whose confirmed committee ran and loaded nothing", async () => {
    links = [{ research_status: 'confirmed', run: 'completed_with_warning' }];
    districtType = 'LOCAL';
    expect(await coverageStatus()).toBe('local_unavailable');
  });

  it("still reports 'data_pending' when the only run failed (a retry is owed)", async () => {
    links = [{ research_status: 'confirmed', run: 'failed' }];
    expect(await coverageStatus()).toBe('data_pending');
  });

  it("still reports 'data_pending' when one confirmed committee has never been ingested", async () => {
    links = [{ research_status: 'confirmed', run: 'completed' }, { research_status: 'confirmed' }];
    expect(await coverageStatus()).toBe('data_pending');
  });
});

// Dorothy Granger's CFA-4 pre-primary 2026, as the DB returns it. 15a/17c are blank on the sheet.
const GRANGER_ROW = {
  form: 'CFA-4', report_type: 'pre_primary', is_amendment: false,
  period_start: '2026-01-01', period_end: '2026-04-10', filed_on: '2026-04-15',
  filed_with: 'Monroe Circuit Court Clerk', receipts_total: '0.00', receipts_ytd: '0.00',
  receipts_itemized: null, expenditures_total: null, expenditures_ytd: null, cash_end: '0.00',
  debts_owed_by: '0.00', politician_source_id: 'internal', source_pdf: 'internal.pdf',
};

describe('getSummary coverage_status — filed report summaries', () => {
  // The Monroe importer writes no ingestion_runs, so without this rule a $0 report reads "being processed".
  it("reports 'filed_reports' for a confirmed link whose report is on file, even with no run", async () => {
    links = [{ research_status: 'confirmed' }];
    reports = [{ linkIndex: 0, ...GRANGER_ROW }];
    const { summary } = await getSummary(POLITICIAN);
    expect(summary.coverage_status).toBe('filed_reports');
    expect(summary.filed_reports).toHaveLength(1);
  });

  it('whitelists fields: numbers are numbers, blanks stay null, internal ids never leave', async () => {
    links = [{ research_status: 'confirmed' }];
    reports = [{ linkIndex: 0, ...GRANGER_ROW }];
    const { summary } = await getSummary(POLITICIAN);
    const r = summary.filed_reports![0];
    expect(r.receipts_total).toBe(0);
    expect(r.receipts_itemized).toBeNull();
    expect(r.filed_with).toBe('Monroe Circuit Court Clerk');
    expect(r).not.toHaveProperty('politician_source_id');
    expect(r).not.toHaveProperty('source_pdf');
  });

  it('ignores a report on a disputed link', async () => {
    links = [{ research_status: 'disputed' }];
    reports = [{ linkIndex: 0, ...GRANGER_ROW }];
    const { summary } = await getSummary(POLITICIAN);
    expect(summary.coverage_status).toBe('no_data');
    expect(summary.filed_reports).toBeUndefined();
  });

  it("keeps 'data_pending' for a confirmed, never-run link with no report", async () => {
    links = [{ research_status: 'confirmed' }];
    const { summary } = await getSummary(POLITICIAN);
    expect(summary.coverage_status).toBe('data_pending');
    expect(summary.filed_reports).toBeUndefined();
  });
});
