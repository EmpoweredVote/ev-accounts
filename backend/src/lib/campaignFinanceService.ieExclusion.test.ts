import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// An ie_committee link is an independent-expenditure committee that spent in the politician's
// race (migrations 190/191). Its contributions are money given TO that committee, not to the
// politician, and getOutsideSpendingForPolitician already reports them as outside spending.
// Every read of the politician's OWN fundraising must therefore leave them out; before
// 2026-09-24 those reads filtered on research_status alone and summed them in (measured on prod:
// 3 confirmed la_socrata ie_committee links, 58 rows, $2.42M — reported twice).
//
// The fake pool holds one politician's links and contributions. It answers each query by
// applying the query's OWN research_status and source_type predicates to the fake links, so
// these tests assert on the totals the service returns, not on SQL text.
// ---------------------------------------------------------------------------

interface Link { id: string; source_type: string; research_status: string }
interface Contrib {
  id: string; source: string; cycle: string; amount: number; donor: string; occupation: string;
}

let links: Link[] = [];
let contribs: Contrib[] = [];

/** research_status values a query admits, or null when it does not filter on it. */
function admittedStatuses(sql: string): string[] | null {
  const m = sql.match(/ps\.research_status\s*=\s*'(\w+)'/);
  return m ? [m[1]] : null;
}

/** source_type values a query admits, or null when it does not filter on it. */
function admittedTypes(sql: string): string[] | null {
  const m = sql.match(/ps\.source_type\s*=\s*'(\w+)'/);
  return m ? [m[1]] : null;
}

function visibleContribs(sql: string): Contrib[] {
  const statuses = admittedStatuses(sql);
  const types = admittedTypes(sql);
  const ok = new Set(
    links
      .filter((l) => statuses === null || statuses.includes(l.research_status))
      .filter((l) => types === null || types.includes(l.source_type))
      .map((l) => l.id)
  );
  return contribs.filter((c) => ok.has(c.source));
}

const sum = (cs: Contrib[]) => cs.reduce((s, c) => s + c.amount, 0);
const cyclesDesc = (cs: Contrib[]) => [...new Set(cs.map((c) => c.cycle))].sort().reverse();
const rawRecord = (c: Contrib) => ({ contributor_name: c.donor, contributor_occupation: c.occupation });

function donorGroups(cs: Contrib[]) {
  const m = new Map<string, Contrib[]>();
  for (const c of cs) m.set(c.donor, [...(m.get(c.donor) ?? []), c]);
  return [...m.entries()].map(([name, g]) => ({ name, g }));
}

const query = vi.fn(async (sql: string, params: unknown[] = []) => {
  // Outside spending is not under test here.
  if (sql.includes("'ie_committee'")) return { rows: [] };

  // ---- contribution_summary_agg (getSummary fast path). One agg row per source+cycle. ----
  if (sql.includes('contribution_summary_agg a')) {
    const vis = visibleContribs(sql);
    if (sql.includes('SELECT DISTINCT a.election_cycle')) {
      return { rows: cyclesDesc(vis).map((election_cycle) => ({ election_cycle })) };
    }
    const cycle = params[1] as string;
    const inCycle = vis.filter((c) => c.cycle === cycle);
    const bySource = new Map<string, Contrib[]>();
    for (const c of inCycle) bySource.set(c.source, [...(bySource.get(c.source) ?? []), c]);
    return {
      rows: [...bySource.values()].map((g) => ({
        election_cycle: cycle,
        data_source: 'la_socrata',
        contribution_count: String(g.length),
        total_amount: String(sum(g)),
        gross_amount: String(sum(g)), refunded_amount: '0', refund_count: '0',
        individual_total: '0',
        pac_total: '0',
        confidence_min: 1,
        sector_breakdown: [],
        top_donors: donorGroups(g).map(({ name, g: dg }) => ({
          name, donor_type: '', employer: '', occupation: '', sector: '',
          total_amount: sum(dg), contribution_count: dg.length, confidence_level: 'HIGH',
        })),
      })),
    };
  }

  // ---- searchDonors ----
  if (sql.includes('donor_matches')) {
    const vis = visibleContribs(sql).filter((c) => c.donor.toLowerCase().includes(String(params[0])));
    if (vis.length === 0) return { rows: [] };
    return {
      rows: [{
        politician_id: 'p', politician_name: 'P', office_title: null, jurisdiction: null, district: null,
        total_donated: String(sum(vis)), contribution_count: String(vis.length),
        contributions: vis.map((c) => ({ date: null, amount: c.amount, employer: '', city: '', state: '', confidence_level: 'HIGH' })),
      }],
    };
  }

  if (!sql.includes('transparent_motivations.contributions c')) return { rows: [] };
  const vis = visibleContribs(sql);

  // ---- getLegalDonorFirms ----
  if (sql.includes('firm_name')) {
    const legal = vis.filter((c) => /attorney/i.test(c.occupation));
    if (legal.length === 0) return { rows: [] };
    return { rows: [{ firm_name: 'Firm', total_donated: sum(legal), donor_count: legal.length, occupations_seen: ['ATTORNEY'] }] };
  }

  // ---- cycles ----
  if (sql.includes('SELECT DISTINCT c.election_cycle')) {
    return { rows: cyclesDesc(vis).map((election_cycle) => ({ election_cycle })) };
  }
  if (/SELECT c\.election_cycle[\s\S]*LIMIT 1/.test(sql)) {
    const cy = cyclesDesc(vis)[0];
    return { rows: cy ? [{ election_cycle: cy }] : [] };
  }

  const cycle = params[1] as string;
  const inCycle = vis.filter((c) => c.cycle === cycle);

  if (sql.includes('AS gross_total')) {
    return {
      rows: [{
        gross_total: String(sum(inCycle)), non_fec_gross: String(sum(inCycle)),
        refunded_total: '0', non_fec_refunded: '0', refund_count: '0', non_fec_refund_count: '0',
        contribution_count: String(inCycle.length), confidence_level_n: inCycle.length ? '1' : '0',
        individual_total: '0', pac_total: '0',
      }],
    };
  }
  if (sql.includes('AS occupation')) {
    return { rows: inCycle.map((c) => ({ occupation: c.occupation, amount: String(c.amount) })) };
  }
  if (sql.includes('AS contributor_name')) {
    return {
      rows: donorGroups(inCycle).map(({ name, g }) => ({
        contributor_name: name, total_amount: String(sum(g)), contribution_count: String(g.length),
        confidence_level_n: '1', raw_record: rawRecord(g[0]),
      })),
    };
  }
  if (sql.includes('SELECT c.data_source')) {
    return { rows: inCycle.length ? [{ data_source: 'la_socrata' }] : [] };
  }
  if (sql.includes('ORDER BY c.contribution_date DESC')) {
    return {
      rows: inCycle.map((c) => ({
        id: c.id, amount: String(c.amount), contribution_date: '2024-01-01', election_cycle: c.cycle,
        confidence_level: 'HIGH', data_source: 'la_socrata', raw_record: rawRecord(c),
        donor_name_normalized: c.donor,
      })),
    };
  }
  if (sql.includes('COUNT(*) AS count')) return { rows: [{ count: String(inCycle.length) }] };
  return { rows: [] };
});

vi.mock('./db.js', () => ({ pool: { query: (sql: string, params?: unknown[]) => query(sql, params) } }));

import { getSummary, getContributions, searchDonors } from './campaignFinanceService.js';
import { getLegalDonorFirms } from './essentialsProfileService.js';

const POLITICIAN = '00000000-0000-4000-8000-000000000001';

beforeEach(() => {
  // The politician's own committee raised $100 in 2024. An IE committee linked to their race
  // took $900 in 2024 and $500 in 2022. Shaped on Francis De Leon Sanchez's prod rows.
  links = [
    { id: 'own', source_type: 'candidate_committee', research_status: 'confirmed' },
    { id: 'ie', source_type: 'ie_committee', research_status: 'confirmed' },
  ];
  contribs = [
    { id: 'c1', source: 'own', cycle: '2024', amount: 100, donor: 'ALICE OWN', occupation: 'ATTORNEY' },
    { id: 'c2', source: 'ie', cycle: '2024', amount: 900, donor: 'IE GIVER', occupation: 'ATTORNEY' },
    { id: 'c3', source: 'ie', cycle: '2022', amount: 500, donor: 'IE GIVER', occupation: 'ATTORNEY' },
  ];
  query.mockClear();
});

describe('ie_committee contributions are not the politician\'s own fundraising', () => {
  // Positive control: when the second link is the politician's own committee, the fake must count
  // it. Without this, a fake that dropped the second link for any reason would pass every test.
  it('counts a second candidate_committee link (positive control for the fake)', async () => {
    links[1].source_type = 'candidate_committee';
    const { summary } = await getSummary(POLITICIAN, '2024');
    expect(summary.total_raised).toBe(1000);
  });

  it('getSummary (agg fast path) totals only the candidate committee', async () => {
    const { summary } = await getSummary(POLITICIAN, '2024');
    expect(summary.total_raised).toBe(100);
    expect(summary.contribution_count).toBe(1);
    expect(summary.top_donors.map((d) => d.name)).toEqual(['ALICE OWN']);
  });

  it('getSummary (agg fast path) does not offer a cycle that only IE money fills', async () => {
    const { summary } = await getSummary(POLITICIAN);
    expect(summary.available_cycles).toEqual(['2024']);
    expect(summary.cycle).toBe('2024');
  });

  it('getSummary (live path, confidence filter) totals only the candidate committee', async () => {
    const { summary } = await getSummary(POLITICIAN, '2024', 'HIGH');
    expect(summary.total_raised).toBe(100);
    expect(summary.contribution_count).toBe(1);
    expect(summary.available_cycles).toEqual(['2024']);
    expect(summary.top_donors.map((d) => d.name)).toEqual(['ALICE OWN']);
  });

  it('getSummary (live path) reports an IE-only cycle as empty', async () => {
    const { summary } = await getSummary(POLITICIAN, '2022', 'HIGH');
    expect(summary.total_raised).toBe(0);
    expect(summary.contribution_count).toBe(0);
  });

  it('getContributions lists only candidate-committee rows', async () => {
    const { response } = await getContributions(POLITICIAN, { cycle: '2024' });
    expect(response.results.map((r) => r.id)).toEqual(['c1']);
    expect(response.page_info.total_count).toBe(1);
  });

  it('getContributions defaults to the newest cycle of the politician\'s own money', async () => {
    // Put IE money in a newer cycle than any own money: the default must not land on it.
    contribs.push({ id: 'c4', source: 'ie', cycle: '2026', amount: 50, donor: 'IE GIVER', occupation: '' });
    const { response } = await getContributions(POLITICIAN);
    expect(response.results.map((r) => r.id)).toEqual(['c1']);
  });

  it('searchDonors does not name the politician as a recipient of IE-committee money', async () => {
    const res = await searchDonors('ie giver');
    expect(res.politicians).toEqual([]);
  });

  it('getLegalDonorFirms counts only donors to the candidate committee', async () => {
    const res = await getLegalDonorFirms(POLITICIAN);
    expect(res.firms.map((f) => f.total_donated)).toEqual([100]);
  });
});
