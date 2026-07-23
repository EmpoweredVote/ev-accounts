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

/** Empty first-page Schedule A response — terminates streamPagesForWindow's loop
 *  immediately (page.results.length === 0 -> break), so each test can assert exactly
 *  how many/which requests were made without needing to model real pagination. */
function emptyScheduleAResponse() {
  return {
    ok: true,
    status: 200,
    json: async () => ({ pagination: { per_page: 100, count: 0, pages: 0, last_indexes: null }, results: [] }),
  };
}

function candidateSearchResponse(committeeIds: string[]) {
  return {
    ok: true,
    status: 200,
    json: async () => ({
      results: [{ candidate_id: ps.external_id, principal_committees: committeeIds.map((id) => ({ committee_id: id })) }],
    }),
  };
}

describe('fecAdapter committee resolution (FEC-01)', () => {
  beforeEach(() => {
    poolQueryMock.mockReset();
    buildCandidateCommitteeMapMock.mockReset();
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
