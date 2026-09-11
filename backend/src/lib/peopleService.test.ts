import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { getPeople, getPersonById, getAppearancesById } from './peopleService.js';
import { publicMeetingStatusClause } from './meetingVisibility.js';

const POLITICIAN_ID = '33333333-3333-4333-8333-333333333333';

beforeEach(() => mockQuery.mockReset());

// ---------------------------------------------------------------------------
// Public status gate (ev-cto decision 0017): a draft House-floor meeting
// resolves real members to a politician_id. Roster aggregates (meetingCount,
// lastSpokeDate, cities) and speaking appearances must count only publicly
// visible meetings, or a draft's transcript text surfaces on live people pages.
// ---------------------------------------------------------------------------

describe('people status gate — public reads exclude drafts', () => {
  it('getPeople aggregates only over allowlisted meetings', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getPeople();
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).toContain(publicMeetingStatusClause('m.status'));
  });

  it('getPeople keeps the gate alongside a city filter', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getPeople({ city: 'Bloomington' });
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toContain(publicMeetingStatusClause('m.status'));
    expect(params).toContain('Bloomington');
  });

  it('getPersonById aggregates only over allowlisted meetings', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getPersonById(POLITICIAN_ID);
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toContain(publicMeetingStatusClause('m.status'));
    expect(params).toEqual([POLITICIAN_ID]);
  });

  it('getAppearancesById gates appearance segments on the meeting status', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getAppearancesById(POLITICIAN_ID);
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toContain(publicMeetingStatusClause('m.status'));
    expect(params).toEqual([POLITICIAN_ID]);
  });
});
