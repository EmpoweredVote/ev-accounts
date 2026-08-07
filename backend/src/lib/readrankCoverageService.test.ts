import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));
vi.mock('./readrankQuestionsService.js', () => ({
  listRaceQuestions: vi.fn(async () => [
    { questionId: 'q1', topicKey: 'campaign-finance', questionText: 'Q1?', origin: 'emergent', status: 'confirmed', answeringCandidates: 2, rankable: true, surfaced: true },
  ]),
}));

import { cellState, listRaceCandidates, getCoverageGrid, searchRaces } from './readrankCoverageService.js';

describe('cellState', () => {
  it('live when a live quote exists', () => expect(cellState(true, 3)).toBe('live'));
  it('draft when quotes exist but none live', () => expect(cellState(false, 2)).toBe('draft'));
  it('none when no quotes', () => expect(cellState(false, 0)).toBe('none'));
});

describe('listRaceCandidates', () => {
  beforeEach(() => mockQuery.mockReset());
  it('queries still-standing candidates with a politician_id and maps to camelCase', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ politician_id: 'p1', full_name: 'Ada' }, { politician_id: 'p2', full_name: 'Ben' }] });
    const out = await listRaceCandidates('race-1');
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toContain('essentials.race_candidates');
    // Liveness is the shared predicate from migration 1582, not an inline status test — it excludes
    // withdrawals AND `not_nominated` (people who ran and did not become the nominee). Asserting on
    // the function call is what stops this query quietly reverting to a status-only check.
    expect(sql).toContain('essentials.is_live_candidate(rc.candidate_status, rc.result)');
    expect(sql).not.toContain("<> 'withdrawn'");
    expect(sql).toContain('rc.politician_id IS NOT NULL');
    expect(params).toEqual(['race-1']);
    expect(out).toEqual([{ politicianId: 'p1', fullName: 'Ada' }, { politicianId: 'p2', fullName: 'Ben' }]);
  });
});

describe('getCoverageGrid', () => {
  beforeEach(() => mockQuery.mockReset());
  it('composes questions + candidates + cells with derived cell state', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ politician_id: 'p1', full_name: 'Ada' }] })
      .mockResolvedValueOnce({ rows: [{ question_id: 'q1', politician_id: 'p1', has_live: true, quote_count: '2' }] });
    const grid = await getCoverageGrid('race-1');
    expect(grid.questions.map((q) => q.questionId)).toEqual(['q1']);
    expect(grid.candidates).toEqual([{ politicianId: 'p1', fullName: 'Ada' }]);
    expect(grid.cells).toEqual([{ questionId: 'q1', politicianId: 'p1', state: 'live' }]);
  });
});

describe('searchRaces', () => {
  beforeEach(() => mockQuery.mockReset());
  it('ILIKE-searches races by position_name', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ race_id: 'r1', position_name: 'U.S. Senate Texas' }] });
    const out = await searchRaces('senate');
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toContain('essentials.races');
    expect(sql.toLowerCase()).toContain('ilike');
    expect(params).toEqual(['%senate%']);
    expect(out).toEqual([{ raceId: 'r1', positionName: 'U.S. Senate Texas' }]);
  });
});
