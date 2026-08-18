import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Mock the shared pool so importing fecAdapter.ts (which imports ../db.js at module
// scope) doesn't trigger env.ts's startup validation / process.exit(1) in a test
// environment with no real DATABASE_URL. Mirrors the established pattern in
// judicialCalAccessIngest.test.ts / essentialsBrowseService.test.ts.
const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));

// Mock the bulk loader so FEC-01 committee-resolution tests control the bulk map
// deterministically without streaming a real ccl{YY}.zip file.
const buildCandidateCommitteeMapMock = vi.fn();
vi.mock('./fecBulkLoader.js', () => ({
  buildCandidateCommitteeMap: (...args: unknown[]) => buildCandidateCommitteeMapMock(...args),
}));

// Mock the shared FEC rate limiter (FEC-03, 174-01) so these tests can assert the
// limiter is acquired before every outbound fetch without exercising real Redis/
// in-process pacing logic (that module has its own dedicated test file).
const acquireFecSlotMock = vi.fn().mockResolvedValue(undefined);
vi.mock('../fecRateLimiter.js', () => ({
  acquireFecSlot: (...args: unknown[]) => acquireFecSlotMock(...args),
}));

import { createFecAdapter } from './fecAdapter.js';
import type { PoliticianSource } from '../campaignFinanceService.js';
import type { SourceAdapter, StreamingAdapter } from './adapterInterface.js';

/** createFecAdapter's declared return type is the base SourceAdapter interface; the
 *  concrete FECAdapter also implements StreamingAdapter.fetchStream (asserted at
 *  runtime by runIngestion.ts's isStreamingAdapter duck-type check). Cast here so
 *  tests can call fetchStream directly against the same public factory. */
function asStreaming(adapter: SourceAdapter): SourceAdapter & StreamingAdapter {
  return adapter as SourceAdapter & StreamingAdapter;
}

const ps: PoliticianSource = {
  id: 'ps-1',
  essentials_politician_id: 'pol-1',
  source_system: 'fec',
  external_id: 'CAND123',
  research_status: 'confirmed',
  notes: '',
  created_at: '',
  updated_at: '',
};

/** Default headers stub — every response now flows through readRemaining(response)
 *  (FEC-03), so all mock responses need a `.headers.get`. Defaults to "no header
 *  present"; individual tests override via the `headers` param below. */
function headersStub(values: Record<string, string> = {}) {
  return { get: (name: string) => values[name.toLowerCase()] ?? null };
}

/** Empty first-page Schedule A response — terminates streamPagesForWindow's loop
 *  immediately (page.results.length === 0 -> break), so each test can assert exactly
 *  how many/which requests were made without needing to model real pagination. */
function emptyScheduleAResponse() {
  return {
    ok: true,
    status: 200,
    headers: headersStub(),
    json: async () => ({ pagination: { per_page: 100, count: 0, pages: 0, last_indexes: null }, results: [] }),
  };
}

function candidateSearchResponse(committeeIds: string[]) {
  return {
    ok: true,
    status: 200,
    headers: headersStub(),
    json: async () => ({
      results: [{ candidate_id: ps.external_id, principal_committees: committeeIds.map((id) => ({ committee_id: id })) }],
    }),
  };
}

/** A 429 response, optionally carrying a `retry-after` header (numeric seconds or
 *  HTTP-date string). Omitting `retryAfter` models the "no header present" case
 *  that must fall back to the existing exponential backoff (FEC-03/Pitfall 1). */
function rateLimitedResponse(retryAfter?: string) {
  return {
    ok: false,
    status: 429,
    headers: headersStub(retryAfter !== undefined ? { 'retry-after': retryAfter } : {}),
    json: async () => ({}),
  };
}

describe('fecAdapter committee resolution (FEC-01)', () => {
  beforeEach(() => {
    poolQueryMock.mockReset();
    buildCandidateCommitteeMapMock.mockReset();
    acquireFecSlotMock.mockClear();
    // getFecLoadCursor's default: no prior successful run -> null cursor -> whole-cycle path.
    poolQueryMock.mockResolvedValue({ rows: [{ started_at: null }] });
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('committee bulk-map hit returns mapped committees with zero FEC API calls for candidate lookup', async () => {
    buildCandidateCommitteeMapMock.mockResolvedValue(new Map([[ps.external_id, ['C00111111']]]));
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock.mockResolvedValue(emptyScheduleAResponse());

    const adapter = asStreaming(createFecAdapter('2026'));
    await adapter.fetchStream(ps, async () => {});

    expect(buildCandidateCommitteeMapMock).toHaveBeenCalledWith('2026');
    // Every fetch call must be the schedule_a endpoint — never candidates/search.
    for (const call of fetchMock.mock.calls) {
      expect(String(call[0])).not.toContain('candidates/search');
      expect(String(call[0])).toContain('schedule_a');
    }
    expect(fetchMock.mock.calls.length).toBeGreaterThan(0);
  });

  it('committee bulk-map miss falls through to the candidate-search fetch fallback', async () => {
    buildCandidateCommitteeMapMock.mockResolvedValue(new Map()); // miss: empty map, no entry for this candidate
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock.mockImplementation(async (url: string) => {
      if (String(url).includes('candidates/search')) return candidateSearchResponse(['C00222222']);
      return emptyScheduleAResponse();
    });

    const adapter = asStreaming(createFecAdapter('2026'));
    await adapter.fetchStream(ps, async () => {});

    const searchCalls = fetchMock.mock.calls.filter((c: unknown[]) => String(c[0]).includes('candidates/search'));
    expect(searchCalls.length).toBe(1);
  });
});

describe('fecAdapter incremental min_load_date cursor (FEC-02)', () => {
  beforeEach(() => {
    poolQueryMock.mockReset();
    buildCandidateCommitteeMapMock.mockReset();
    acquireFecSlotMock.mockClear();
    buildCandidateCommitteeMapMock.mockResolvedValue(new Map([[ps.external_id, ['C00333333']]]));
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('load_date: a prior successful run sets min_load_date to the watermark minus 2 days', async () => {
    // getFecLoadCursor's query — max(started_at) of prior completed runs.
    poolQueryMock.mockImplementation(async (sql: string) => {
      if (String(sql).includes('max(started_at)')) {
        return { rows: [{ started_at: '2026-07-20T03:05:00.000Z' }] };
      }
      return { rows: [] }; // getCompletedWindows / anything else
    });
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock.mockResolvedValue(emptyScheduleAResponse());

    const adapter = asStreaming(createFecAdapter('2026'));
    await adapter.fetchStream(ps, async () => {});

    const scheduleACalls = fetchMock.mock.calls.filter((c: unknown[]) => String(c[0]).includes('schedule_a'));
    expect(scheduleACalls.length).toBeGreaterThan(0);
    for (const call of scheduleACalls) {
      const url = String(call[0]);
      // 2026-07-20 minus 2 days = 2026-07-18; date-only, never a timestamp.
      expect(url).toContain('min_load_date=2026-07-18');
      expect(url).not.toMatch(/min_load_date=[^&]*T/);
    }
  });

  it('load_date: no prior successful run omits min_load_date (whole-cycle initial backfill)', async () => {
    poolQueryMock.mockImplementation(async (sql: string) => {
      if (String(sql).includes('max(started_at)')) {
        return { rows: [{ started_at: null }] };
      }
      return { rows: [] };
    });
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock.mockResolvedValue(emptyScheduleAResponse());

    const adapter = asStreaming(createFecAdapter('2026'));
    await adapter.fetchStream(ps, async () => {});

    const scheduleACalls = fetchMock.mock.calls.filter((c: unknown[]) => String(c[0]).includes('schedule_a'));
    expect(scheduleACalls.length).toBeGreaterThan(0);
    for (const call of scheduleACalls) {
      expect(String(call[0])).not.toContain('min_load_date');
    }
  });
});

describe('fecAdapter FEC-03 — shared limiter gate + Retry-After/X-RateLimit-Remaining backoff', () => {
  beforeEach(() => {
    poolQueryMock.mockReset();
    buildCandidateCommitteeMapMock.mockReset();
    acquireFecSlotMock.mockClear();
    poolQueryMock.mockResolvedValue({ rows: [{ started_at: null }] });
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.useRealTimers();
  });

  it('acquires the shared limiter before every schedule_a fetch (limiter gate)', async () => {
    buildCandidateCommitteeMapMock.mockResolvedValue(new Map([[ps.external_id, ['C00888888']]]));
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock.mockResolvedValue(emptyScheduleAResponse());

    const adapter = asStreaming(createFecAdapter('2026'));
    await adapter.fetchStream(ps, async () => {});

    expect(acquireFecSlotMock).toHaveBeenCalled();
    expect(fetchMock).toHaveBeenCalled();
    const firstAcquireOrder = acquireFecSlotMock.mock.invocationCallOrder[0]!;
    const firstFetchOrder = fetchMock.mock.invocationCallOrder[0]!;
    expect(firstAcquireOrder).toBeLessThan(firstFetchOrder);
  });

  it('acquires the shared limiter before the resolveCommitteeIds candidate-search fallback fetch (limiter gate)', async () => {
    buildCandidateCommitteeMapMock.mockResolvedValue(new Map()); // bulk-map miss -> API fallback
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock.mockImplementation(async (url: string) => {
      if (String(url).includes('candidates/search')) return candidateSearchResponse(['C00777777']);
      return emptyScheduleAResponse();
    });

    const adapter = asStreaming(createFecAdapter('2026'));
    await adapter.fetchStream(ps, async () => {});

    const searchCallIdx = fetchMock.mock.calls.findIndex((c: unknown[]) => String(c[0]).includes('candidates/search'));
    expect(searchCallIdx).toBeGreaterThanOrEqual(0);
    const searchCallOrder = fetchMock.mock.invocationCallOrder[searchCallIdx]!;
    const priorAcquireCalls = acquireFecSlotMock.mock.invocationCallOrder.filter((o) => o < searchCallOrder);
    expect(priorAcquireCalls.length).toBeGreaterThan(0);
  });

  it('a 429 with a numeric Retry-After header sleeps the clamped parsed value, not the raw exponential delay (rate limit / retry-after)', async () => {
    vi.useFakeTimers();
    buildCandidateCommitteeMapMock.mockResolvedValue(new Map([[ps.external_id, ['C00999999']]]));
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock
      .mockResolvedValueOnce(rateLimitedResponse('5')) // 5s Retry-After — bigger than the 2s exponential start
      .mockResolvedValueOnce(emptyScheduleAResponse());
    const setTimeoutSpy = vi.spyOn(global, 'setTimeout');

    const adapter = asStreaming(createFecAdapter('2026'));
    const streamPromise = adapter.fetchStream(ps, async () => {});
    await vi.runAllTimersAsync();
    await streamPromise;

    // sleep(ms) delays only — exclude the unrelated 60_000ms AbortSignal.timeout() calls.
    const sleepDelays = setTimeoutSpy.mock.calls.map((c) => c[1]).filter((ms) => typeof ms === 'number' && ms < 60_000);
    expect(sleepDelays).toContain(5000);
    expect(sleepDelays).not.toContain(2000);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('a 429 with a Retry-After header exceeding 120s clamps the sleep to the 120000ms ceiling (rate limit / retry-after)', async () => {
    vi.useFakeTimers();
    buildCandidateCommitteeMapMock.mockResolvedValue(new Map([[ps.external_id, ['C00999998']]]));
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock
      .mockResolvedValueOnce(rateLimitedResponse('600')) // 600s — must clamp to 120s, never sleep unclamped (V5/DoS)
      .mockResolvedValueOnce(emptyScheduleAResponse());
    const setTimeoutSpy = vi.spyOn(global, 'setTimeout');

    const adapter = asStreaming(createFecAdapter('2026'));
    const streamPromise = adapter.fetchStream(ps, async () => {});
    await vi.runAllTimersAsync();
    await streamPromise;

    const sleepDelays = setTimeoutSpy.mock.calls.map((c) => c[1]).filter((ms) => typeof ms === 'number' && ms < 600_000);
    expect(sleepDelays).toContain(120_000);
    expect(sleepDelays).not.toContain(600_000);
  });

  it('a 429 with no Retry-After header falls back to the existing exponential delay (rate limit / retry-after)', async () => {
    vi.useFakeTimers();
    buildCandidateCommitteeMapMock.mockResolvedValue(new Map([[ps.external_id, ['C00999997']]]));
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    fetchMock
      .mockResolvedValueOnce(rateLimitedResponse()) // no retry-after header at all
      .mockResolvedValueOnce(emptyScheduleAResponse());
    const setTimeoutSpy = vi.spyOn(global, 'setTimeout');

    const adapter = asStreaming(createFecAdapter('2026'));
    const streamPromise = adapter.fetchStream(ps, async () => {});
    await vi.runAllTimersAsync();
    await streamPromise;

    const sleepDelays = setTimeoutSpy.mock.calls.map((c) => c[1]).filter((ms) => typeof ms === 'number' && ms < 60_000);
    expect(sleepDelays).toContain(2000); // the existing initial exponential delay, unchanged
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
});

describe('fecAdapter FEC-04 — amendment supersession (original_sub_id retirement) + dead skip removal', () => {
  beforeEach(() => {
    poolQueryMock.mockReset();
  });

  /** Minimal raw Schedule A record — only the fields normalize()/shouldSkipRecord() read. */
  function scheduleARecord(overrides: Record<string, unknown> = {}): Record<string, unknown> {
    return {
      sub_id: 'SUB-NEW-1',
      contributor_name: 'Jane Doe',
      contribution_receipt_amount: 100,
      contribution_receipt_date: '2026-06-01',
      two_year_transaction_period: 2026,
      memo_code: null,
      original_sub_id: null,
      ...overrides,
    };
  }

  it('shouldSkipRecord (via normalize) still EXCLUDES memo_code="X" but no longer skips a plain amended row lacking the absent is_amended flag', async () => {
    const adapter = createFecAdapter('2026');
    const memoRecord = scheduleARecord({ sub_id: 'SUB-MEMO-1', memo_code: 'X' });
    // A plain amended row: no is_amended field at all (confirmed absent from the live
    // schema), amendment_indicator="A", original_sub_id null (not yet caught populated
    // live) — this must NOT be skipped; only memo_code='X' skips.
    const amendedRecord = scheduleARecord({ sub_id: 'SUB-AMENDED-1', amendment_indicator: 'A' });

    const result = await adapter.normalize(
      { records: [memoRecord, amendedRecord], totalExpected: 2, totalFetched: 2 },
      ps
    );

    // The memo row is reported as EXCLUDED (a deliberate business rule), not as
    // `skipped` (which means a normalize DEFECT and drives runIngestion's 1% alarm).
    // Asserting skipped === 0 is the point: it is what keeps that alarm meaningful
    // for FEC instead of firing on every run with memo traffic.
    expect(result.excluded).toBe(1);
    expect(result.skipped).toBe(0);
    expect(result.totalParsed).toBe(2);
    expect(result.contributions).toHaveLength(1);
    expect(result.contributions[0]!.source_transaction_id).toBe('SUB-AMENDED-1');
  });

  it('normalizeRecords collects non-null original_sub_id into NormalizeResult.supersededSubIds and still inserts the amended row itself', async () => {
    const adapter = createFecAdapter('2026');
    const amendedRecord = scheduleARecord({ sub_id: 'SUB-NEW-2', original_sub_id: 'SUB-OLD-2' });

    const result = await adapter.normalize(
      { records: [amendedRecord], totalExpected: 1, totalFetched: 1 },
      ps
    );

    expect(result.supersededSubIds).toEqual(['SUB-OLD-2']);
    expect(result.contributions).toHaveLength(1);
    expect(result.contributions[0]!.source_transaction_id).toBe('SUB-NEW-2');
    expect(result.contributions[0]!.raw_record['original_sub_id']).toBe('SUB-OLD-2');
  });

  it('normalizeRecords omits supersededSubIds entirely when no record carries a non-null original_sub_id', async () => {
    const adapter = createFecAdapter('2026');
    const plainRecord = scheduleARecord();

    const result = await adapter.normalize(
      { records: [plainRecord], totalExpected: 1, totalFetched: 1 },
      ps
    );

    expect(result.supersededSubIds).toBeUndefined();
  });

  it('upsertContributions issues a retirement DELETE parameterized with data_source=\'fec\' and the original_sub_id values, after inserting the batch, and never targets the new amended row', async () => {
    const insertCalls: unknown[][] = [];
    const deleteCalls: unknown[][] = [];
    poolQueryMock.mockImplementation((sql: string, params: unknown[]) => {
      if (/^\s*INSERT INTO/i.test(sql)) {
        insertCalls.push(params);
        return Promise.resolve({ rows: [{ is_insert: true }] });
      }
      if (/^\s*DELETE FROM/i.test(sql)) {
        deleteCalls.push(params);
        expect(sql).toContain("data_source = 'fec'");
        expect(sql).toContain('source_transaction_id = ANY($1');
        return Promise.resolve({ rows: [] });
      }
      throw new Error(`unexpected query: ${sql}`);
    });

    const adapter = createFecAdapter('2026');
    const amendedRecord = scheduleARecord({ sub_id: 'SUB-NEW-3', original_sub_id: 'SUB-OLD-3' });
    const normalized = await adapter.normalize(
      { records: [amendedRecord], totalExpected: 1, totalFetched: 1 },
      ps
    );

    const result = await adapter.upsert(normalized);

    expect(insertCalls).toHaveLength(1);
    // The DELETE's parameter is exactly the OLD sub_id (original_sub_id), never the new
    // row's own sub_id — the new row's own sub_id must never appear in the retirement params.
    expect(deleteCalls).toHaveLength(1);
    expect(deleteCalls[0]![0]).toEqual(['SUB-OLD-3']);
    expect(deleteCalls[0]![0]).not.toContain('SUB-NEW-3');
    // Retirement runs after the insert batch (insert call recorded before delete call).
    const insertCallIdx = poolQueryMock.mock.calls.findIndex((c) => /^\s*INSERT INTO/i.test(c[0] as string));
    const deleteCallIdx = poolQueryMock.mock.calls.findIndex((c) => /^\s*DELETE FROM/i.test(c[0] as string));
    expect(insertCallIdx).toBeLessThan(deleteCallIdx);
    expect(result.inserted).toBe(1);
    expect(result.errors).toBe(0);
  });

  it('upsertContributions issues no DELETE when supersededSubIds is absent (the common case — most transactions are never amended)', async () => {
    poolQueryMock.mockImplementation((sql: string) => {
      if (/^\s*INSERT INTO/i.test(sql)) return Promise.resolve({ rows: [{ is_insert: true }] });
      throw new Error(`unexpected query: ${sql}`);
    });

    const adapter = createFecAdapter('2026');
    const plainRecord = scheduleARecord();
    const normalized = await adapter.normalize(
      { records: [plainRecord], totalExpected: 1, totalFetched: 1 },
      ps
    );

    await adapter.upsert(normalized);

    const deleteCallCount = poolQueryMock.mock.calls.filter((c) => /^\s*DELETE FROM/i.test(c[0] as string)).length;
    expect(deleteCallCount).toBe(0);
  });
});

describe('fecAdapter FEC-04b — filing-level supersession (real prod double-count)', () => {
  beforeEach(() => {
    poolQueryMock.mockReset();
  });

  /**
   * Modelled on the actual double-count reproduced in prod 2026-07-25: committee C00256925,
   * report 12P/2020. The same $250 2020-05-07 contribution was stored twice — once from
   * file 1409022 (loaded 2020-05-30) and again from file 1484476 (the December amendment).
   * Note the two versions carry DIFFERENT transaction_ids, which is why transaction_id
   * cannot be the dedup key.
   */
  function filingRecord(overrides: Record<string, unknown> = {}): Record<string, unknown> {
    return {
      sub_id: '4123020201986704254',
      contributor_name: 'Denise Chamblee',
      contribution_receipt_amount: 250,
      contribution_receipt_date: '2020-05-07',
      two_year_transaction_period: 2020,
      memo_code: null,
      original_sub_id: null,
      committee_id: 'C00256925',
      report_year: 2020,
      report_type: '12P',
      file_number: 1484476,
      transaction_id: '2208859',
      load_date: '2020-12-30T00:00:00',
      ...overrides,
    };
  }

  it('collects the HIGHEST file_number per (committee, report_year, report_type)', async () => {
    const adapter = createFecAdapter('2020');
    const result = await adapter.normalize(
      {
        records: [
          filingRecord({ sub_id: 'A', file_number: 1409022, transaction_id: 'VSHCSM0N319' }),
          filingRecord({ sub_id: 'B', file_number: 1484476 }),
          // a DIFFERENT report of the same committee must be tracked separately
          filingRecord({ sub_id: 'C', report_type: 'Q3', file_number: 1484480 }),
        ],
        totalExpected: 3,
        totalFetched: 3,
      },
      ps
    );

    expect(result.supersededFilings).toHaveLength(2);
    const p12 = result.supersededFilings!.find((f) => f.reportType === '12P')!;
    expect(p12.maxFileNumber).toBe(1484476);
    expect(p12.committeeId).toBe('C00256925');
    expect(p12.reportYear).toBe(2020);
    const q3 = result.supersededFilings!.find((f) => f.reportType === 'Q3')!;
    expect(q3.maxFileNumber).toBe(1484480);
  });

  it('omits supersededFilings when the identifying fields are absent (pre-fix / bulk rows)', async () => {
    const adapter = createFecAdapter('2020');
    const result = await adapter.normalize(
      {
        records: [{
          sub_id: 'NO-FILING-FIELDS',
          contributor_name: 'Jane Doe',
          contribution_receipt_amount: 10,
          contribution_receipt_date: '2020-05-07',
          two_year_transaction_period: 2020,
          memo_code: null,
        }],
        totalExpected: 1,
        totalFetched: 1,
      },
      ps
    );
    expect(result.supersededFilings).toBeUndefined();
  });

  it('retires EARLIER filings scoped by politician_source_id, guarded on file_number presence, and never deletes the just-inserted max', async () => {
    const deleteCalls: { sql: string; params: unknown[] }[] = [];
    poolQueryMock.mockImplementation((sql: string, params: unknown[]) => {
      // NOT anchored: the per-line retirement is a WITH ... DELETE, so the statement does
      // not begin with DELETE.
      if (/\bDELETE FROM/i.test(sql)) {
        deleteCalls.push({ sql, params });
        return Promise.resolve({ rows: [], rowCount: 3 });
      }
      return Promise.resolve({ rows: [], rowCount: 0 });
    });

    const adapter = createFecAdapter('2020');
    const normalized = await adapter.normalize(
      { records: [filingRecord()], totalExpected: 1, totalFetched: 1 },
      ps
    );
    await adapter.upsert(normalized);

    const filingDelete = deleteCalls.find((c) => /file_number/i.test(c.sql));
    expect(filingDelete).toBeDefined();
    // scoped by politician_source_id FIRST so the DELETE rides idx_contrib_src_cycle
    expect(filingDelete!.sql).toMatch(/politician_source_id\s*=\s*\$1/);
    expect(filingDelete!.sql).toMatch(/data_source\s*=\s*'fec'/);
    // pre-fix rows (no file_number stored) must never be matched
    expect(filingDelete!.sql).toMatch(/raw_record\s*\?\s*'file_number'/);
    // strictly-less-than the batch max, so the rows just inserted (which ARE the max) survive
    expect(filingDelete!.sql).toMatch(/r\.fn\s*<\s*\$5/);
    expect(filingDelete!.params).toEqual([ps.id, 'C00256925', 2020, '12P', 1484476]);
  });

  /**
   * Regression guard for the DELTA-AMENDMENT data loss (found 2026-07-25).
   *
   * The original FEC-04b rule deleted every row of a report below the report's highest
   * file_number, on the assumption that an amendment re-reports the whole report. Live data
   * falsifies that: of 24 superseded filings sampled, ZERO were supersets of their successor.
   * Committee C00574889 report Q1/2016 on 2016-03-11 has 114 lines in original file 1066886 and
   * only 2 in amendment 1081569 — the old rule would have destroyed 112 real contributions.
   *
   * So the DELETE must require per-LINE evidence: a matching (donor, amount, date) row under a
   * higher file_number in the same report. These assertions pin that self-join in place.
   */
  it('requires per-LINE evidence so a delta amendment cannot destroy the original filing', async () => {
    const deleteCalls: { sql: string; params: unknown[] }[] = [];
    poolQueryMock.mockImplementation((sql: string, params: unknown[]) => {
      if (/\bDELETE FROM/i.test(sql)) {
        deleteCalls.push({ sql, params });
        return Promise.resolve({ rows: [], rowCount: 0 });
      }
      return Promise.resolve({ rows: [], rowCount: 0 });
    });

    const adapter = createFecAdapter('2020');
    const normalized = await adapter.normalize(
      { records: [filingRecord()], totalExpected: 1, totalFetched: 1 },
      ps
    );
    await adapter.upsert(normalized);

    const filingDelete = deleteCalls.find((c) => /file_number/i.test(c.sql))!;
    // The surviving version of a LINE is a window MAX partitioned by the line's identity —
    // so a row is only ever deleted when the SAME line exists under a higher file_number.
    expect(filingDelete.sql).toMatch(
      /max\(fn\)\s*OVER\s*\(\s*PARTITION BY donor_name_normalized,\s*amount,\s*contribution_date\s*\)/i
    );
    expect(filingDelete.sql).toMatch(/r\.fn\s*<\s*r\.survivor_fn/);
    // NOT a self-join: that plans as a quadratic nested loop with JSONB extraction in the join
    // filter and does not complete on real data.
    expect(filingDelete.sql).not.toMatch(/USING\s+transparent_motivations\.contributions\s+newer/i);
    // the partition stays inside ONE report of ONE committee, so a contribution legitimately
    // reported in two different reports is never collapsed
    expect(filingDelete.sql).toMatch(/raw_record->>'committee_id'\s*=\s*\$2/);
    expect(filingDelete.sql).toMatch(/raw_record->>'report_year'\)::int\s*=\s*\$3/);
    expect(filingDelete.sql).toMatch(/raw_record->>'report_type'\s*=\s*\$4/);
    // and never below the batch max, so the rows just inserted survive
    expect(filingDelete.sql).toMatch(/r\.fn\s*<\s*\$5/);
  });
});
