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
