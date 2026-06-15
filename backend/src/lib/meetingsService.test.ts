import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({
  pool: { query: mockQuery },
}));

import {
  createMeeting,
  getMeetingById,
  getMeetings,
  updateMeeting,
} from './meetingsService.js';

// A representative meetings.meetings row with a full summary JSONB.
const fullSummary = {
  executive_summary:
    'The council debated a rezoning ordinance at length, hearing public ' +
    'comment from two dozen residents before deferring the vote to next month ' +
    'pending a traffic study and revised affordable-housing set-aside terms.',
  key_decisions: ['Deferred rezoning vote', 'Approved budget amendment'],
  sections: [{ section_type: 'discussion', title: 'Rezoning', content: 'long content...' }],
  model: 'claude',
  generated_at: '2026-02-18T00:00:00Z',
};

const baseRow = {
  id: 'm1',
  title: 'Bloomington Council Budget Hearing',
  event_kind: 'council',
  city: null,
  state: 'IN',
  date: '2026-02-18',
  meeting_type: 'City Council',
  duration_seconds: '3600',
  video_url: null,
  audio_source: null,
  status: 'published',
  segment_count: '120',
  speaker_count: '9',
  created_at: '2026-02-19T00:00:00Z',
  updated_at: '2026-02-19T00:00:00Z',
  body_slug: 'bloomington-cc',
  source_url: null,
  playback_kind: 'youtube',
  slug: 'm1',
  summary: fullSummary,
  processing_metadata: null,
};

beforeEach(() => mockQuery.mockReset());

describe('getMeetings (list payload)', () => {
  it('omits the full summary JSONB but keeps a truncated summaryPreview', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });

    const [item] = await getMeetings();

    expect('summary' in item).toBe(false);
    expect(item.summaryPreview).not.toBeNull();
    expect(item.summaryPreview!.length).toBeLessThanOrEqual(160);
    expect(item.summaryPreview!.endsWith('…')).toBe(true);
  });

  it('returns a null summaryPreview when there is no summary', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ ...baseRow, summary: null }] });

    const [item] = await getMeetings();

    expect('summary' in item).toBe(false);
    expect(item.summaryPreview).toBeNull();
  });
});

describe('getMeetingById (detail payload)', () => {
  it('keeps the full summary JSONB', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [baseRow] }) // meeting row
      .mockResolvedValueOnce({ rows: [] }); // speakers

    const meeting = await getMeetingById('m1');

    expect(meeting).not.toBeNull();
    expect(meeting!.title).toBe('Bloomington Council Budget Hearing');
    expect(meeting!.eventKind).toBe('council');
    expect(meeting!.city).toBeNull();
    expect(meeting!.summary).toEqual(fullSummary);
    expect(meeting!.summaryPreview).not.toBeNull();
  });
});

describe('meeting writes', () => {
  it('writes title, eventKind, and a null city on create', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });

    await createMeeting({
      city: null,
      state: 'CA',
      date: '2026-06-02',
      meetingType: 'Governor Debate',
      title: 'California Governor Debate',
      eventKind: 'debate',
    });

    expect(mockQuery).toHaveBeenCalledWith(
      expect.stringContaining('title, event_kind'),
      [
        null,
        'CA',
        '2026-06-02',
        'Governor Debate',
        null,
        null,
        null,
        'processing',
        'California Governor Debate',
        'debate',
      ]
    );
  });

  it('updates title and eventKind independently', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });

    await updateMeeting('m1', {
      title: 'Updated title',
      eventKind: 'forum',
    });

    expect(mockQuery).toHaveBeenCalledWith(
      expect.stringContaining('title = $1, event_kind = $2'),
      ['Updated title', 'forum', 'm1']
    );
  });
});
