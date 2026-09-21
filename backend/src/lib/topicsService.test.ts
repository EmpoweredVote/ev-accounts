import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { getTopics, getTopicByKey } from './topicsService.js';
import {
  publicMeetingStatusClause,
  publicMeetingExistsClause,
} from './meetingVisibility.js';

beforeEach(() => mockQuery.mockReset());

// ---------------------------------------------------------------------------
// Public status gate (ev-cto decision 0017): topic tags on a draft meeting must
// not surface publicly. (Floor drafts run with summaries off and produce no
// meeting_topics rows today; this is defense in depth.)
// ---------------------------------------------------------------------------

describe('topics status gate — public reads exclude drafts', () => {
  it('getTopics counts topic tags only on publicly-visible meetings', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getTopics();
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).toContain(publicMeetingExistsClause('mt.meeting_id'));
  });

  it('getTopicByKey gates the item list on the meeting status', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [] }) // title lookup
      .mockResolvedValueOnce({ rows: [] }); // items
    await getTopicByKey('housing');
    const [itemsSql] = mockQuery.mock.calls[1];
    expect(itemsSql).toContain(publicMeetingStatusClause('m.status'));
  });
});
