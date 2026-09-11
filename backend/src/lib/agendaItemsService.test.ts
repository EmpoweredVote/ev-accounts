import { describe, it, expect, beforeEach, vi } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import {
  getAgendaItemsByMeetingId,
  getAgendaItemById,
} from './agendaItemsService.js';
import {
  publicMeetingStatusClause,
  publicMeetingExistsClause,
} from './meetingVisibility.js';

const MEETING_ID = '11111111-1111-4111-8111-111111111111';
const ITEM_ID = '22222222-2222-4222-8222-222222222222';

// String-typed numerics on purpose: pg returns numeric as string.
const baseItemRow = {
  id: ITEM_ID,
  meeting_id: MEETING_ID,
  position: '6',
  item_number: '6A',
  title_raw:
    'Ordinance 2026-16 – To Amend an Ordinance Fixing the Salaries of Officers and Employees',
  kind: 'ordinance',
  legislation_ref: 'Ordinance 2026-16',
  summary_plain: 'Adjusts police and fire salaries.',
  decision_plain: 'First of two votes needed to change the salary ordinance.',
  stage: 'First reading',
  public_comment: false,
  public_comment_note: null,
  status: 'upcoming',
  outcome: null,
  segment_start_seconds: null,
  segment_end_seconds: null,
  continued_from_item_id: null,
  source_url: 'https://bloomington.in.gov/onboard/meetingFiles/17202/download',
};

beforeEach(() => {
  mockQuery.mockReset();
});

describe('getAgendaItemsByMeetingId', () => {
  it('maps rows to camelCase DTOs ordered by position', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseItemRow] });
    const items = await getAgendaItemsByMeetingId(MEETING_ID);
    expect(mockQuery).toHaveBeenCalledTimes(1);
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toContain('FROM meetings.agenda_items');
    expect(sql).toContain('ORDER BY position ASC');
    expect(params).toEqual([MEETING_ID]);
    expect(items).toHaveLength(1);
    expect(items[0]).toEqual({
      id: ITEM_ID,
      meetingId: MEETING_ID,
      position: 6,
      itemNumber: '6A',
      titleRaw: baseItemRow.title_raw,
      kind: 'ordinance',
      legislationRef: 'Ordinance 2026-16',
      summaryPlain: 'Adjusts police and fire salaries.',
      decisionPlain:
        'First of two votes needed to change the salary ordinance.',
      stage: 'First reading',
      publicComment: false,
      publicCommentNote: null,
      status: 'upcoming',
      outcome: null,
      segmentStartSeconds: null,
      segmentEndSeconds: null,
      continuedFromItemId: null,
      sourceUrl: baseItemRow.source_url,
    });
  });

  it('coerces numeric segment bounds to numbers', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [
        {
          ...baseItemRow,
          status: 'happened',
          outcome: 'passed',
          segment_start_seconds: '1234.5',
          segment_end_seconds: '2000',
        },
      ],
    });
    const items = await getAgendaItemsByMeetingId(MEETING_ID);
    expect(items[0].segmentStartSeconds).toBe(1234.5);
    expect(items[0].segmentEndSeconds).toBe(2000);
    expect(items[0].outcome).toBe('passed');
  });

  it('coerces a zero segment bound to 0, not null', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [
        {
          ...baseItemRow,
          status: 'happened',
          segment_start_seconds: '0',
          segment_end_seconds: '95',
        },
      ],
    });
    const items = await getAgendaItemsByMeetingId(MEETING_ID);
    expect(items[0].segmentStartSeconds).toBe(0);
    expect(items[0].segmentEndSeconds).toBe(95);
  });

  it('returns [] when there are no items', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    expect(await getAgendaItemsByMeetingId(MEETING_ID)).toEqual([]);
  });
});

// getAgendaItemById now issues several queries (item, votes, records,
// speakers). Dispatch on SQL text so tests don't depend on call order.
function dispatchQueries(handlers: {
  item?: unknown[];
  votes?: unknown[];
  records?: unknown[];
  speakers?: unknown[];
}) {
  mockQuery.mockImplementation(async (sql: string) => {
    if (sql.includes('FROM meetings.votes')) return { rows: handlers.votes ?? [] };
    if (sql.includes('FROM meetings.vote_records')) return { rows: handlers.records ?? [] };
    if (sql.includes('FROM meetings.segments')) return { rows: handlers.speakers ?? [] };
    return { rows: handlers.item ?? [] };
  });
}

const baseDetailRow = {
  ...baseItemRow,
  m_id: MEETING_ID,
  m_title: 'Common Council Regular Session',
  m_date: '2026-07-29',
  m_city: 'Bloomington',
  m_status: 'scheduled',
  m_starts_at: '2026-07-29T18:30:00-04:00',
  m_timezone: 'America/Indiana/Indianapolis',
  cf_id: null,
  cf_item_number: null,
  cf_meeting_date: null,
};

describe('getAgendaItemById', () => {
  it('returns the item with embedded meeting context', async () => {
    dispatchQueries({ item: [baseDetailRow] });
    const detail = await getAgendaItemById(ITEM_ID);
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toContain('FROM meetings.agenda_items');
    expect(sql).toContain('JOIN meetings.meetings');
    expect(params).toEqual([ITEM_ID]);
    expect(detail?.itemNumber).toBe('6A');
    expect(detail?.meeting).toEqual({
      id: MEETING_ID,
      title: 'Common Council Regular Session',
      date: '2026-07-29',
      city: 'Bloomington',
      status: 'scheduled',
      startsAt: '2026-07-29T18:30:00-04:00',
      timezone: 'America/Indiana/Indianapolis',
    });
  });

  it('normalizes a Date m_starts_at (pg timestamptz) to an ISO-8601 UTC string', async () => {
    // pg returns timestamptz columns as JS Date objects — no type parsers are
    // registered in db.ts. The mapper must hand back a string.
    dispatchQueries({
      item: [{ ...baseDetailRow, m_starts_at: new Date('2026-07-29T22:30:00Z') }],
    });
    const detail = await getAgendaItemById(ITEM_ID);
    expect(detail?.meeting.startsAt).toBe('2026-07-29T22:30:00.000Z');
  });

  it('returns null when not found', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    expect(await getAgendaItemById(ITEM_ID)).toBeNull();
    expect(mockQuery).toHaveBeenCalledTimes(1); // no follow-up queries
  });

  it('defaults votes/speakers to [] and continuedFrom to null', async () => {
    dispatchQueries({ item: [baseDetailRow] });
    const detail = await getAgendaItemById(ITEM_ID);
    expect(detail?.votes).toEqual([]);
    expect(detail?.speakers).toEqual([]);
    expect(detail?.continuedFrom).toBeNull();
    // No segment bounds on the item -> the segments query is never issued.
    const sqls = mockQuery.mock.calls.map((c) => c[0] as string);
    expect(sqls.some((s) => s.includes('FROM meetings.segments'))).toBe(false);
  });

  it('attaches votes with named per-member records', async () => {
    const VOTE_ID = '44444444-4444-4444-8444-444444444444';
    dispatchQueries({
      item: [baseDetailRow],
      votes: [
        {
          id: VOTE_ID,
          resolution: 'Ordinance 2026-16',
          description: 'Adoption',
          result: 'Passed · 7–0',
          vote_type: 'roll-call',
          timestamp: '5321.5', // pg numeric -> string
        },
      ],
      records: [
        {
          vote_id: VOTE_ID,
          position: 'aye',
          name: 'Isak Nti Asare',
          politician_id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        },
        { vote_id: VOTE_ID, position: 'nay', name: 'Dave Rollo', politician_id: null },
      ],
    });
    const detail = await getAgendaItemById(ITEM_ID);
    expect(detail?.votes).toEqual([
      {
        id: VOTE_ID,
        resolution: 'Ordinance 2026-16',
        description: 'Adoption',
        result: 'Passed · 7–0',
        voteType: 'roll-call',
        timestamp: 5321.5,
        records: [
          {
            position: 'aye',
            name: 'Isak Nti Asare',
            politicianId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          },
          { position: 'nay', name: 'Dave Rollo', politicianId: null },
        ],
      },
    ]);
    const votesSql = mockQuery.mock.calls
      .map((c) => c[0] as string)
      .find((s) => s.includes('FROM meetings.votes'));
    expect(votesSql).toContain('agenda_item_id = $1');
  });

  it('queries speakers within the segment span when bounds are present', async () => {
    dispatchQueries({
      item: [
        {
          ...baseDetailRow,
          status: 'happened',
          segment_start_seconds: '1200',
          segment_end_seconds: '2400',
        },
      ],
      speakers: [
        {
          name: 'Kate Rosenbarger',
          politician_id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          role: null,
          first_spoke_seconds: '1210.2',
          segment_count: '7',
        },
        {
          name: 'Buff Brown',
          politician_id: null,
          role: null,
          first_spoke_seconds: '1900',
          segment_count: '1',
        },
      ],
    });
    const detail = await getAgendaItemById(ITEM_ID);
    expect(detail?.speakers).toEqual([
      {
        name: 'Kate Rosenbarger',
        politicianId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        role: null,
        firstSpokeSeconds: 1210.2,
        segmentCount: 7,
      },
      {
        name: 'Buff Brown',
        politicianId: null,
        role: null,
        firstSpokeSeconds: 1900,
        segmentCount: 1,
      },
    ]);
    const call = mockQuery.mock.calls.find((c) =>
      (c[0] as string).includes('FROM meetings.segments')
    );
    expect(call?.[1]).toEqual([MEETING_ID, 1200, 2400]);
  });

  it('maps continued_from into a minimal prior-appearance pointer', async () => {
    const PRIOR_ID = '55555555-5555-4555-8555-555555555555';
    dispatchQueries({
      item: [
        {
          ...baseDetailRow,
          continued_from_item_id: PRIOR_ID,
          cf_id: PRIOR_ID,
          cf_item_number: '7A',
          cf_meeting_date: '2026-07-22',
        },
      ],
    });
    const detail = await getAgendaItemById(ITEM_ID);
    expect(detail?.continuedFrom).toEqual({
      id: PRIOR_ID,
      itemNumber: '7A',
      meetingDate: '2026-07-22',
    });
  });
});

// ---------------------------------------------------------------------------
// Public status gate (ev-cto decision 0017): a draft meeting's agenda items —
// and single agenda-item permalinks — must be invisible to public callers.
// (Floor drafts produce no agenda items today; this is defense in depth.)
// ---------------------------------------------------------------------------

describe('agenda-item status gate — public reads exclude drafts', () => {
  it('getAgendaItemsByMeetingId gates the list on the parent meeting', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getAgendaItemsByMeetingId(MEETING_ID);
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).toContain(publicMeetingExistsClause('$1'));
  });

  it('getAgendaItemById gates the meeting join on the allowlist', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getAgendaItemById(ITEM_ID);
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).toContain(publicMeetingStatusClause('m.status'));
  });
});
