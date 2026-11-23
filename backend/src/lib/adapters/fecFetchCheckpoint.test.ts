import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Hoisted: imports run before plain statements, and the adapter reads this at load.
vi.hoisted(() => { process.env.FEC_PER_PAGE_SLEEP_MS = '0'; });

const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...a: unknown[]) => poolQueryMock(...a) } }));
vi.mock('./fecBulkLoader.js', () => ({
  buildCandidateCommitteeMap: async () => new Map([['CAND1', ['C001', 'C002']]]),
}));
vi.mock('../fecRateLimiter.js', () => ({ acquireFecSlot: async () => undefined }));

import { createFecAdapter } from './fecAdapter.js';
import { planFecFetch, freshMinLoadDate, type FecCheckpointRow } from './fecFetchCheckpoint.js';
import type { SourceAdapter, StreamingAdapter } from './adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';

const ps = { id: 'ps-1', external_id: 'CAND1' } as unknown as PoliticianSource;
const adapter = () => createFecAdapter('2026') as SourceAdapter & StreamingAdapter;
const headers = { get: () => null };

/** Three pages per committee; page n's cursor is {last_index: n}. */
function scheduleA(url: string) {
  const u = new URL(url);
  const at = Number(u.searchParams.get('last_index') ?? 0);
  const committee = u.searchParams.get('committee_id');
  const done = at >= 3;
  return {
    ok: true, status: 200, headers,
    json: async () => ({
      pagination: { per_page: 100, count: 300, pages: 3, last_indexes: done ? null : { last_index: at + 1 } },
      results: done ? [] : [{ sub_id: `${committee}-${at + 1}` }],
    }),
  };
}

const HISTORY = '2026-11-20T06:00:00.000Z';   // last success in ingestion_runs → cursor 2026-11-18

function db(checkpoints: Partial<FecCheckpointRow>[]) {
  poolQueryMock.mockImplementation(async (sql: string) => {
    if (sql.includes('FROM transparent_motivations.fec_fetch_checkpoints')) return { rows: checkpoints };
    if (sql.includes('max(started_at)')) return { rows: [{ started_at: HISTORY }] };
    return { rows: [] };
  });
}
const writes = () => poolQueryMock.mock.calls.filter((c) => /INTO transparent_motivations\.fec_fetch_checkpoints/.test(c[0]));
const deletes = () => poolQueryMock.mock.calls.filter((c) => /DELETE FROM transparent_motivations\.fec_fetch_checkpoints/.test(c[0]));
const savedRows = (call: unknown[]) => JSON.parse((call[1] as unknown[])[4] as string);
const scheduleAUrls = () =>
  (fetch as unknown as ReturnType<typeof vi.fn>).mock.calls.map((c) => String(c[0])).filter((u) => u.includes('schedule_a'));

beforeEach(() => {
  poolQueryMock.mockReset();
  vi.stubGlobal('fetch', vi.fn(async (url: string) =>
    url.includes('schedule_a') ? scheduleA(url) : { ok: true, status: 200, headers, json: async () => ({ pagination: { count: 0, last_indexes: null }, results: [] }) }));
});
afterEach(() => vi.unstubAllGlobals());

describe('planFecFetch', () => {
  const row = (o: Partial<FecCheckpointRow>): FecCheckpointRow => ({
    committee_id: 'C001', min_load_date: '2026-11-10', last_indexes: null, rows_saved: 0, done: false,
    chain_started_at: '2026-11-12T06:30:00.000Z', ...o,
  });
  it('no rows: a fresh attempt on the history cursor', () => {
    const p = planFecFetch([]);
    expect(p).toMatchObject({ kind: 'fresh', clearFirst: false });
    expect(freshMinLoadDate('2026-11-18', p as never)).toBe('2026-11-18');
  });
  it('an unfinished committee: resume the chain with ITS min_load_date', () => {
    const p = planFecFetch([row({ done: true }), row({ committee_id: 'C002', last_indexes: { last_index: 2 } })]);
    expect(p).toMatchObject({ kind: 'resume', minLoadDate: '2026-11-10' });
  });
  it('all done: fresh from chain start minus 2 days, never the later history cursor', () => {
    const p = planFecFetch([row({ done: true })]);
    expect(p).toMatchObject({ kind: 'fresh', clearFirst: true });
    expect(freshMinLoadDate('2026-11-18', p as never)).toBe('2026-11-10');
  });
});

describe('a cut-off FEC fetch continues where it stopped', () => {
  it('saves the cursor of the last SAVED page when the time limit fires', async () => {
    db([]);
    const controller = new AbortController();
    let n = 0;
    await adapter().fetchStream(ps, async () => { if (++n === 2) controller.abort(new Error('limit')); }, controller.signal);

    expect(writes()).toHaveLength(1);
    const [psId, cycle, minLoadDate] = writes()[0]![1] as unknown[];
    expect([psId, cycle, minLoadDate]).toEqual(['ps-1', '2026', '2026-11-18']);
    expect(savedRows(writes()[0]!)).toEqual([
      { committee_id: 'C001', done: false, last_indexes: { last_index: 2 }, rows_saved: 2 },
      { committee_id: 'C002', done: false, last_indexes: null, rows_saved: 0 },
    ]);
  });

  it('resumes from the saved cursor with the chain\'s min_load_date and skips finished committees', async () => {
    db([
      { committee_id: 'C001', min_load_date: '2026-11-10', last_indexes: null, rows_saved: 300, done: true, chain_started_at: '2026-11-12T06:30:00Z' },
      { committee_id: 'C002', min_load_date: '2026-11-10', last_indexes: { last_index: 2 }, rows_saved: 2, done: false, chain_started_at: '2026-11-12T06:30:00Z' },
    ]);
    const got: unknown[] = [];
    await adapter().fetchStream(ps, async (b) => { got.push(...b); });

    const urls = scheduleAUrls().filter((u) => !u.includes('line_number'));
    expect(urls.every((u) => u.includes('committee_id=C002'))).toBe(true);   // C001 was finished
    expect(urls[0]).toContain('last_index=2');                                // not from the top
    expect(urls.every((u) => u.includes('min_load_date=2026-11-10'))).toBe(true);   // not 2026-11-18
    expect(got).toEqual([{ sub_id: 'C002-3' }]);
    // Finished by resuming: the rows stay, all done, to set the next attempt's floor.
    expect(deletes()).toHaveLength(0);
    expect(savedRows(writes().at(-1)!).every((r: { done: boolean }) => r.done)).toBe(true);
  });

  it('after a chain finished by resuming, the next attempt reads from chain start - 2 days and clears the rows', async () => {
    db([{ committee_id: 'C001', min_load_date: '2026-11-10', last_indexes: null, rows_saved: 3, done: true, chain_started_at: '2026-11-12T06:30:00Z' },
        { committee_id: 'C002', min_load_date: '2026-11-10', last_indexes: null, rows_saved: 3, done: true, chain_started_at: '2026-11-12T06:30:00Z' }]);
    await adapter().fetchStream(ps, async () => {});
    expect(deletes()).toHaveLength(1);
    const main = scheduleAUrls().filter((u) => !u.includes('line_number'));
    expect(main.every((u) => u.includes('min_load_date=2026-11-10'))).toBe(true);
    expect(main.some((u) => u.includes('committee_id=C001'))).toBe(true);
    expect(writes()).toHaveLength(0);
  });

  it('a normal run that finishes writes no checkpoint at all', async () => {
    db([]);
    await adapter().fetchStream(ps, async () => {});
    expect(writes()).toHaveLength(0);
    expect(deletes()).toHaveLength(0);
  });
});
