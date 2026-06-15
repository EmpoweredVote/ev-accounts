import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({
  pool: { query: mockQuery },
}));

import { getMeetings, getMeetingById } from './meetingsService.js';

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
  city: 'Bloomington',
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
    expect(meeting!.summary).toEqual(fullSummary);
    expect(meeting!.summaryPreview).not.toBeNull();
  });
});
