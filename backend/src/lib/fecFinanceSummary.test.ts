import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// ./db.js reads env at module scope; keep the import from touching a real database.
vi.mock('./env.js', () => ({ env: { DATABASE_URL: 'postgres://test' } }));
const poolQueryMock = vi.fn();
vi.mock('./db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));
vi.mock('./fecRateLimiter.js', () => ({ acquireFecSlot: vi.fn().mockResolvedValue(undefined) }));

import { runFecFinanceSummary, runFecFinanceSummaryJob } from './fecFinanceSummary.js';

interface Person { id: string; full_name: string; fec: string | null; is_candidate?: boolean }

/** Answers the three query shapes the writer issues: the selection, the FEC-ID lookup, the UPDATE. */
function wireDb(people: Person[]) {
  const writes: Array<{ id: string; summary: Record<string, unknown> }> = [];
  poolQueryMock.mockImplementation(async (sql: string, params: unknown[]) => {
    if (sql.includes('one_per_person')) {
      return {
        rows: people.map(p => ({
          id: p.id, bioguide_id: null, full_name: p.full_name, chamber_short: 'H', is_candidate: p.is_candidate ?? true,
        })),
      };
    }
    if (sql.includes('FROM transparent_motivations.politician_sources')) {
      const p = people.find(x => x.id === params[0]);
      return { rows: p?.fec ? [{ external_id: p.fec }] : [] };
    }
    if (sql.startsWith('UPDATE essentials.politicians SET finance_summary')) {
      writes.push({ id: params[1] as string, summary: JSON.parse(params[0] as string) });
      return { rows: [] };
    }
    throw new Error(`unexpected query: ${sql.slice(0, 80)}`);
  });
  return writes;
}

function okJson(body: unknown) {
  return { ok: true, status: 200, headers: new Headers(), json: async () => body, text: async (): Promise<string> => '' };
}

/** YAML crosswalk (empty list) + FEC: committee, totals $100, no donors. `failFec` makes every FEC call 403. */
function wireFetch({ failFec = false } = {}) {
  const fetchMock = vi.fn(async (url: string) => {
    if (url.includes('legislators-current.yaml')) return { ok: true, status: 200, text: async (): Promise<string> => '[]' };
    if (failFec) return { ok: false, status: 403, headers: new Headers(), json: async () => ({}) };
    if (url.includes('/candidates/search/')) return okJson({ results: [{ principal_committees: [{ committee_id: 'C001' }] }] });
    if (url.includes('/candidates/totals/')) return okJson({ results: [{ receipts: 100 }] });
    if (url.includes('/schedule_a/by_employer/')) return okJson({ results: [] });
    throw new Error(`unexpected fetch ${url}`);
  });
  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}

describe('fecFinanceSummary', () => {
  const saved = { key: process.env.FEC_API_KEY, max: process.env.FEC_FINANCE_SUMMARY_MAX_PEOPLE };

  beforeEach(() => {
    poolQueryMock.mockReset();
    process.env.FEC_API_KEY = 'test-key';
    delete process.env.FEC_FINANCE_SUMMARY_MAX_PEOPLE;
    vi.spyOn(console, 'log').mockImplementation(() => {});
    vi.spyOn(console, 'warn').mockImplementation(() => {});
    vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
    if (saved.key === undefined) delete process.env.FEC_API_KEY; else process.env.FEC_API_KEY = saved.key;
    if (saved.max === undefined) delete process.env.FEC_FINANCE_SUMMARY_MAX_PEOPLE;
    else process.env.FEC_FINANCE_SUMMARY_MAX_PEOPLE = saved.max;
  });

  it('stamps refreshed_at on every summary it writes', async () => {
    const writes = wireDb([{ id: 'p1', full_name: 'Ann Lee', fec: 'H6TN09449' }]);
    wireFetch();
    await runFecFinanceSummary();
    expect(writes).toHaveLength(1);
    expect(writes[0].summary).toMatchObject({ total_raised: 100, cycle: '2026', source: 'FEC' });
    expect(Date.parse(writes[0].summary.refreshed_at as string)).not.toBeNaN();
  });

  it('the cap counts only people sent to FEC — people with no FEC id do not use it up', async () => {
    const writes = wireDb([
      { id: 'n1', full_name: 'No Id One', fec: null },
      { id: 'n2', full_name: 'No Id Two', fec: null },
      { id: 'p1', full_name: 'Ann Lee', fec: 'H1' },
      { id: 'p2', full_name: 'Bo Kim', fec: 'H2' },
      { id: 'p3', full_name: 'Cy Roe', fec: 'H3' },
    ]);
    wireFetch();
    const r = await runFecFinanceSummary({ maxFecPeople: 2 });
    expect(writes.map(w => w.id)).toEqual(['p1', 'p2']);
    expect(r).toMatchObject({ processed: 4, attempted: 2, succeeded: 2, skipped_no_fec_id: 2, deferred: 1 });
  });

  it('the job asks for stalest-first order and caps at 150 by default', async () => {
    wireDb([]);
    wireFetch();
    await runFecFinanceSummaryJob();
    const selection = poolQueryMock.mock.calls.find(([sql]) => String(sql).includes('one_per_person'));
    expect(selection?.[1]).toEqual([false, [], true]);
  });

  it('the job fails the run when every FEC attempt failed', async () => {
    const writes = wireDb([
      { id: 'p1', full_name: 'Ann Lee', fec: 'H1' },
      { id: 'p2', full_name: 'Bo Kim', fec: 'H2' },
    ]);
    wireFetch({ failFec: true });
    await expect(runFecFinanceSummaryJob()).rejects.toThrow(/all 2 FEC attempts failed/);
    expect(writes).toHaveLength(0);
  });

  it('the job succeeds when only some attempts failed', async () => {
    wireDb([
      { id: 'p1', full_name: 'Ann Lee', fec: 'H1' },
      { id: 'p2', full_name: 'Bo Kim', fec: null },
    ]);
    wireFetch();
    await expect(runFecFinanceSummaryJob()).resolves.toMatchObject({ attempted: 1, succeeded: 1 });
  });

  it('the job rejects a bad FEC_FINANCE_SUMMARY_MAX_PEOPLE before any work', async () => {
    process.env.FEC_FINANCE_SUMMARY_MAX_PEOPLE = 'lots';
    wireDb([]);
    await expect(runFecFinanceSummaryJob()).rejects.toThrow(/positive integer/);
    expect(poolQueryMock).not.toHaveBeenCalled();
  });

  it('a --politician id outside the selection throws instead of silently summarising nobody', async () => {
    wireDb([]);
    wireFetch();
    await expect(runFecFinanceSummary({ onlyPoliticians: ['5d56470c-fb82-42f7-82e3-d28bf74ace47'] }))
      .rejects.toThrow(/not among the active federal politicians/);
  });
});
