import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { getTopics, getTopicByKey } from './topicsService.js';
import {
  publicMeetingStatusClause,
  publicMeetingExistsClause,
} from './meetingVisibility.js';
import { topicAskedByPublishedSeason } from './seasonService.js';

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

// 🔴 The topic match used to gate on `ct.is_live = true`. Seventeen Season 2
// topics are is_live = false (created staged; opening a season flips no
// boolean), so a meeting tagged with one lost its title here. The gate is now
// seasonService.topicAskedByPublishedSeason, still on `ct` — `ctc` is the
// content view and must keep supplying only the wording.
describe('topic titles follow the published seasons, not is_live', () => {
  const code = (sql: string) => sql.replace(/--[^\n]*/g, '');

  it('getTopics titles a tag whose topic a published season asks', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getTopics();
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).toContain(`ON ct.topic_key = mt.topic_key AND ${topicAskedByPublishedSeason('ct.id')}`);
    expect(code(sql)).not.toMatch(/is_live/);
  });

  it('getTopicByKey resolves the title under the same gate', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [] }) // title lookup
      .mockResolvedValueOnce({ rows: [] }); // items
    await getTopicByKey('gun-policy');
    const [titleSql, params] = mockQuery.mock.calls[0];
    expect(titleSql).toContain(`WHERE ct.topic_key = $1 AND ${topicAskedByPublishedSeason('ct.id')}`);
    expect(code(titleSql)).not.toMatch(/is_live/);
    expect(params).toEqual(['gun-policy']);
  });
});
