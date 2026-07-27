import { describe, it, expect, beforeEach, vi } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import {
  getAgendaItemsByMeetingId,
  getAgendaItemById,
} from './agendaItemsService.js';

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

  it('returns [] when there are no items', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    expect(await getAgendaItemsByMeetingId(MEETING_ID)).toEqual([]);
  });
});

describe('getAgendaItemById', () => {
  it('returns the item with embedded meeting context', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [
        {
          ...baseItemRow,
          m_id: MEETING_ID,
          m_title: 'Common Council Regular Session',
          m_date: '2026-07-29',
          m_city: 'Bloomington',
          m_status: 'scheduled',
          m_starts_at: '2026-07-29T18:30:00-04:00',
        },
      ],
    });
    const detail = await getAgendaItemById(ITEM_ID);
    expect(detail?.itemNumber).toBe('6A');
    expect(detail?.meeting).toEqual({
      id: MEETING_ID,
      title: 'Common Council Regular Session',
      date: '2026-07-29',
      city: 'Bloomington',
      status: 'scheduled',
      startsAt: '2026-07-29T18:30:00-04:00',
    });
  });

  it('returns null when not found', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    expect(await getAgendaItemById(ITEM_ID)).toBeNull();
  });
});
