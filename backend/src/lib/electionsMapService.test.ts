// src/lib/electionsMapService.test.ts
//
// This is the ONLY automated coverage of the SQL-row -> tier translation layer:
// admin.test.ts mocks getElectionsStateScores wholesale, so it never exercises the
// real racesForStateDate -> classifyRaceTier -> weightedDepthScore pipeline against
// representative raw-DB row shapes. pool.query is mocked here (no live DB).
import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { racesForStateDate, getElectionsStateScores } from './electionsMapService.js';

beforeEach(() => {
  mockQuery.mockReset();
});

/** Compact partial-override factory for a raw (string-typed) DB row from racesForStateDate. */
const raceRow = (over: Partial<{
  race_id: string; position_name: string; seats: string; candidate_count: string; ocd_id: string | null;
  active_count: string; stanced_count: string; motivated_count: string;
}> = {}) => ({
  race_id: 'r', position_name: 'X', seats: '1', candidate_count: '0', ocd_id: null,
  active_count: '0', stanced_count: '0', motivated_count: '0',
  ...over,
});

describe('racesForStateDate — per-race aggregate translation', () => {
  it('coerces string aggregate columns to numbers and preserves raw candidate_count', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [
        raceRow({
          race_id: 'r-gov', position_name: 'Governor', seats: '1', candidate_count: '4',
          active_count: '3', stanced_count: '2', motivated_count: '1',
          ocd_id: 'ocd-division/country:us/state:mi',
        }),
      ],
    });

    const [race] = await racesForStateDate('MI', '2026-11-03');

    expect(race.active_count).toBe(3);
    expect(race.stanced_count).toBe(2);
    expect(race.motivated_count).toBe(1);
    expect(race.candidate_count).toBe(4);
    expect(mockQuery.mock.calls[0][1]).toEqual(['MI', '2026-11-03']);
  });
});

describe('getElectionsStateScores — tier + depthScore from a representative candidate mix', () => {
  it('derives per-race tier, tierCounts, and depthScore from withdrawn / null-politician_id / stanced-only / fully-covered candidates', async () => {
    // Query order inside getElectionsStateScores:
    // 1. statesWithUpcomingElections
    // 2. nextElectionDate
    // 3. Promise.all([racesForStateDate, countyOcdToFips, placeSlugToFips])
    mockQuery.mockResolvedValueOnce({ rows: [{ state: 'mi' }] }); // statesWithUpcomingElections
    mockQuery.mockResolvedValueOnce({ rows: [{ election_date: '2026-11-03', election_type: 'general' }] }); // nextElectionDate
    mockQuery.mockResolvedValueOnce({
      rows: [
        // Tier 3: all active candidates stanced AND motivated.
        raceRow({
          race_id: 'r-t3', position_name: 'Fully covered', candidate_count: '2',
          active_count: '2', stanced_count: '2', motivated_count: '2',
          ocd_id: 'ocd-division/country:us/state:mi',
        }),
        // Tier 2: stance-only (D-06) — motivation doesn't reach ALL active.
        raceRow({
          race_id: 'r-t2', position_name: 'Stanced only', candidate_count: '2',
          active_count: '2', stanced_count: '2', motivated_count: '0',
          ocd_id: 'ocd-division/country:us/state:mi',
        }),
        // Tier 1: names-only / null-politician_id case (D-03) — active but no signals.
        raceRow({
          race_id: 'r-t1', position_name: 'Names only', candidate_count: '2',
          active_count: '2', stanced_count: '0', motivated_count: '0',
          ocd_id: 'ocd-division/country:us/state:mi',
        }),
        // Tier 0: everyone withdrawn (D-02) — active_count is 0.
        raceRow({
          race_id: 'r-t0', position_name: 'All withdrawn', candidate_count: '2',
          active_count: '0', stanced_count: '0', motivated_count: '0',
          ocd_id: 'ocd-division/country:us/state:mi',
        }),
      ],
    }); // racesForStateDate
    mockQuery.mockResolvedValueOnce({ rows: [] }); // countyOcdToFips
    mockQuery.mockResolvedValueOnce({ rows: [] }); // placeSlugToFips

    const [mi] = await getElectionsStateScores({ refresh: true });

    expect(mi.tierCounts).toEqual({ t0: 1, t1: 1, t2: 1, t3: 1 });
    expect(mi.statewideRaces.map((r) => r.tier)).toEqual([3, 2, 1, 0]);
    // (1 + 2/3 + 1/3 + 0) / 4 * 100 = 50
    expect(mi.depthScore).toBe(50);
  });
});
