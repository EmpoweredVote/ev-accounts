import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { searchSegments } from './searchService.js';
import { publicMeetingStatusClause } from './meetingVisibility.js';

beforeEach(() => mockQuery.mockReset());

// ---------------------------------------------------------------------------
// Public status gate (ev-cto decision 0017): transcript full-text search is the
// highest-risk leak — a draft floor meeting HAS segments, so its transcript text
// would be searchable before human review. Both the hits and count queries must
// gate on the parent meeting's status.
// ---------------------------------------------------------------------------

describe('searchSegments status gate — public reads exclude drafts', () => {
  it('gates both the hits and count queries on the meeting status', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [] }) // hits
      .mockResolvedValueOnce({ rows: [{ count: '0' }] }); // count
    await searchSegments({ q: 'rezoning', page: 1 });

    const sqls = mockQuery.mock.calls.map((c) => c[0] as string);
    expect(sqls).toHaveLength(2);
    for (const sql of sqls) {
      expect(sql).toContain(publicMeetingStatusClause('m.status'));
    }
  });

  it('keeps the gate alongside a speaker filter without disturbing bind params', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [{ count: '0' }] });
    await searchSegments({
      q: 'budget',
      speaker: '33333333-3333-4333-8333-333333333333',
      page: 1,
    });
    const [hitsSql, hitsParams] = mockQuery.mock.calls[0];
    expect(hitsSql).toContain(publicMeetingStatusClause('m.status'));
    // The gate uses literals, so the speaker id is still $2 and LIMIT/OFFSET $3/$4.
    expect(hitsParams).toContain('33333333-3333-4333-8333-333333333333');
  });
});
