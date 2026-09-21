import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({
  pool: { query: mockQuery },
}));

import {
  createMeeting,
  firstSentence,
  getMeetingById,
  getMeetingEntityState,
  getMeetings,
  getSummaryByMeetingId,
  getTranscriptByMeetingId,
  getUpcomingMeetings,
  getVotesByMeetingId,
  updateMeeting,
} from './meetingsService.js';
import {
  publicMeetingStatusClause,
  publicMeetingExistsClause,
} from './meetingVisibility.js';

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
  chamber_id: '11111111-1111-4111-8111-111111111111',
  race_ids: [],
  source_url: null,
  playback_kind: 'youtube',
  slug: 'm1',
  summary: fullSummary,
  processing_metadata: null,
  thumbnail_url: 'https://x.supabase.co/storage/v1/object/public/meeting-thumbnails/m1.jpg',
  starts_at: null,
  timezone: null,
};

beforeEach(() => mockQuery.mockReset());

describe('getMeetings (list payload)', () => {
  it('omits the full summary JSONB but keeps the first-sentence summaryPreview', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [
        {
          ...baseRow,
          summary: {
            ...fullSummary,
            executive_summary:
              'The council deferred the rezoning vote. A traffic study is due next month.',
          },
        },
      ],
    });

    const [item] = await getMeetings();

    expect('summary' in item).toBe(false);
    expect(item.summaryPreview).toBe('The council deferred the rezoning vote.');
  });

  it('returns the full first sentence without truncation, even when long', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });

    const [item] = await getMeetings();

    // baseRow's executive_summary is one long single sentence — returned whole.
    expect(item.summaryPreview).toBe(fullSummary.executive_summary);
    expect(item.summaryPreview!.endsWith('…')).toBe(false);
  });

  it('returns a null summaryPreview when there is no summary', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ ...baseRow, summary: null }] });

    const [item] = await getMeetings();

    expect('summary' in item).toBe(false);
    expect(item.summaryPreview).toBeNull();
  });

  it('returns the thumbnailUrl on list items', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });

    const [item] = await getMeetings();

    expect(item.thumbnailUrl).toBe(
      'https://x.supabase.co/storage/v1/object/public/meeting-thumbnails/m1.jpg',
    );
  });

  it('returns a null thumbnailUrl when the column is null', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ ...baseRow, thumbnail_url: null }] });

    const [item] = await getMeetings();

    expect(item.thumbnailUrl).toBeNull();
  });
});

describe('firstSentence', () => {
  it('returns only the first sentence of a multi-sentence summary', () => {
    expect(
      firstSentence('The council approved the rezoning. Then they recessed.'),
    ).toBe('The council approved the rezoning.');
  });

  it('returns a long single sentence whole (no cap)', () => {
    const long =
      'The League of Women Voters hosted two candidate forums on June 9, 2026—one for Indiana House District 61 and one for Monroe County Commissioner.';
    expect(firstSentence(long)).toBe(long);
  });

  it('trims surrounding whitespace', () => {
    expect(firstSentence('   Leading and trailing spaces.  Second.')).toBe(
      'Leading and trailing spaces.',
    );
  });

  it('returns the whole string when there is no terminator', () => {
    expect(firstSentence('A fragment with no terminator')).toBe(
      'A fragment with no terminator',
    );
  });

  it('handles question and exclamation marks', () => {
    expect(firstSentence('What happened next? A lot.')).toBe('What happened next?');
  });

  it('returns null for empty or missing input', () => {
    expect(firstSentence('')).toBeNull();
    expect(firstSentence(null)).toBeNull();
    expect(firstSentence(undefined)).toBeNull();
    expect(firstSentence('   ')).toBeNull();
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
    expect(meeting!.chamberId).toBe('11111111-1111-4111-8111-111111111111');
    expect(meeting!.raceIds).toEqual([]);
    expect('bodySlug' in meeting!).toBe(false);
    expect(meeting!.summary).toEqual(fullSummary);
    expect(meeting!.summaryPreview).not.toBeNull();
    // starts_at/timezone (migration 1481) map through as nulls from baseRow
    expect(meeting!.startsAt).toBeNull();
    expect(meeting!.timezone).toBeNull();
  });
});

describe('getMeetings status default', () => {
  it('filters to published when no status filter is passed', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getMeetings();
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).toContain(`status = 'published'`);
  });

  it('uses the explicit status filter when passed', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getMeetings({ status: 'scheduled' });
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).not.toContain(`status = 'published'`);
    expect(params).toContain('scheduled');
  });

  it('combines the default published literal with a parameterized raceId filter', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getMeetings({ raceId: '22222222-2222-4222-8222-222222222222' });
    const [sql, params] = mockQuery.mock.calls[0];
    // The status default is a literal, not a parameter — raceId must still be $1.
    expect(sql).toContain(`status = 'published'`);
    expect(sql).toContain('er.race_id = $1::uuid');
    expect(params).toEqual(['22222222-2222-4222-8222-222222222222']);
  });
});

describe('getUpcomingMeetings', () => {
  it('selects scheduled meetings from today forward, soonest first', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [{ ...baseRow, status: 'scheduled', starts_at: '2026-07-29T18:30:00-04:00', timezone: 'America/Indiana/Indianapolis' }],
    });
    const meetings = await getUpcomingMeetings();
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).toContain(`status = 'scheduled'`);
    expect(sql).toContain('date >= CURRENT_DATE');
    expect(sql).toContain('ORDER BY date ASC');
    expect(meetings[0].startsAt).toBe('2026-07-29T18:30:00-04:00');
    expect(meetings[0].timezone).toBe('America/Indiana/Indianapolis');
  });

  it('normalizes a Date starts_at (pg timestamptz) to an ISO-8601 UTC string', async () => {
    // pg returns timestamptz columns as JS Date objects — no type parsers are
    // registered in db.ts. The mapper must hand back a string.
    mockQuery.mockResolvedValueOnce({
      rows: [{ ...baseRow, status: 'scheduled', starts_at: new Date('2026-07-29T22:30:00Z') }],
    });
    const meetings = await getUpcomingMeetings();
    expect(meetings[0].startsAt).toBe('2026-07-29T22:30:00.000Z');
  });
});

describe('getMeetingById speakers with local_people', () => {
  // Mock speaker rows: one essentials-linked, one local-person-linked.
  const speakerRowEssentials = {
    id: 'sp1',
    meeting_id: 'm1',
    label: 'SPEAKER_00',
    display_name: 'Alice Mayor',
    confidence: '0.95',
    id_method: 'exact',
    politician_id: 'pol-uuid-1',
    politician_slug: 'alice-mayor',
    created_at: '2026-02-19T00:00:00Z',
    local_slug: null,
    local_name: null,
    local_role: null,
  };

  const speakerRowWithLocal = {
    id: 'sp2',
    meeting_id: 'm1',
    label: 'SPEAKER_01',
    display_name: 'Jane Candidate',
    confidence: '0.80',
    id_method: 'predicted',
    politician_id: null,
    politician_slug: null,
    created_at: '2026-02-19T00:00:00Z',
    local_slug: 'jane-candidate',
    local_name: 'Jane Candidate',
    local_role: 'candidate',
  };

  it('returns localSlug/localName/localRole on speakers linked to local_people', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [baseRow] })          // meeting row
      .mockResolvedValueOnce({ rows: [speakerRowEssentials, speakerRowWithLocal] }); // speakers

    const meeting = await getMeetingById('m1');

    expect(meeting).not.toBeNull();
    expect(meeting!.speakers).toHaveLength(2);

    // essentials-linked speaker: local fields must be null
    const sp0 = meeting!.speakers[0];
    expect(sp0.politicianSlug).toBe('alice-mayor');
    expect(sp0.localSlug).toBeNull();
    expect(sp0.localName).toBeNull();
    expect(sp0.localRole).toBeNull();

    // local-person speaker: local fields must be populated
    const sp1 = meeting!.speakers[1];
    expect(sp1.politicianSlug).toBeNull();
    expect(sp1.localSlug).toBe('jane-candidate');
    expect(sp1.localName).toBe('Jane Candidate');
    expect(sp1.localRole).toBe('candidate');
  });

  it('every Speaker object returned by getMeetingById includes localSlug, localName, localRole keys', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [baseRow] })
      .mockResolvedValueOnce({ rows: [speakerRowEssentials] });

    const meeting = await getMeetingById('m1');

    expect(meeting).not.toBeNull();
    const keys = Object.keys(meeting!.speakers[0]);
    expect(keys).toContain('localSlug');
    expect(keys).toContain('localName');
    expect(keys).toContain('localRole');
  });

  it('the getMeetingById speaker query contains LEFT JOIN meetings.local_people', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [baseRow] })
      .mockResolvedValueOnce({ rows: [] });

    await getMeetingById('m1');

    // Second call is the speakers query
    const calls = mockQuery.mock.calls;
    expect(calls.length).toBeGreaterThanOrEqual(2);
    const speakerQueryArg = calls[1][0] as string;
    expect(speakerQueryArg).toContain('LEFT JOIN meetings.local_people');
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
      chamberId: null,
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
        null,
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

  it('loads the current entity state for patch validation', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });

    const state = await getMeetingEntityState('m1');

    expect(state).toEqual({
      eventKind: 'council',
      chamberId: '11111111-1111-4111-8111-111111111111',
    });
  });
});

describe('raceIds (event_races)', () => {
  it('maps race_ids array onto the meeting payload', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ ...baseRow, event_kind: 'forum', race_ids: ['race-clerk', 'race-pros'] }] })
      .mockResolvedValueOnce({ rows: [] }); // getMeetingById's 2nd (speakers) query
    const m = await getMeetingById('m1');
    expect(m).not.toBeNull();
    expect(m!.raceIds).toEqual(['race-clerk', 'race-pros']);
  });

  it('defaults raceIds to [] when null', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ ...baseRow, race_ids: null }] });
    const [item] = await getMeetings();
    expect(item.raceIds).toEqual([]);
  });

  it('filters meetings by raceId via event_races', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });
    await getMeetings({ raceId: '22222222-2222-4222-8222-222222222222' });
    const sql = mockQuery.mock.calls[0][0] as string;
    const params = mockQuery.mock.calls[0][1] as unknown[];
    expect(sql).toMatch(/meetings\.event_races/);
    expect(params).toContain('22222222-2222-4222-8222-222222222222');
  });
});

describe('admin writes no longer touch race_id', () => {
  it('createMeeting INSERT omits race_id', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });
    await createMeeting({ state: 'IN', date: '2026-02-18', meetingType: 'City Council' });
    const sql = mockQuery.mock.calls[0][0] as string;
    // Only inspect the write portion (column list / VALUES), not RETURNING —
    // MEETING_COLS legitimately reads er.race_id from meetings.event_races.
    const writeClause = sql.slice(0, sql.indexOf('RETURNING'));
    expect(writeClause).not.toMatch(/\brace_id\b/);
  });

  it('updateMeeting SET omits race_id', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });
    await updateMeeting('m1', { title: 'New Title' });
    const calls = mockQuery.mock.calls.map((c) => c[0] as string);
    // Inspect the SET clause only (between UPDATE and RETURNING); the RETURNING
    // MEETING_COLS subquery reads er.race_id from meetings.event_races.
    expect(
      calls.some((s) => {
        const m = /UPDATE meetings\.meetings([\s\S]*?)RETURNING/.exec(s);
        return m !== null && /\brace_id\b/.test(m[1]);
      })
    ).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Public status gate (on-the-record ev-cto decision 0017): a draft meeting and
// anything derived from it must be invisible on every unauthenticated read.
// ---------------------------------------------------------------------------

describe('meeting status gate — public reads exclude drafts', () => {
  it('getMeetings gates the list on the public status allowlist', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getMeetings();
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).toContain(publicMeetingStatusClause());
  });

  it('getMeetings keeps the allowlist even when a status is explicitly requested (?status=draft cannot leak)', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getMeetings({ status: 'draft' });
    const [sql, params] = mockQuery.mock.calls[0];
    // The requested status is still bound, but intersected with the allowlist —
    // 'draft' ∩ {published,scheduled} = ∅, so no draft row can return.
    expect(params).toContain('draft');
    expect(sql).toContain(publicMeetingStatusClause());
  });

  it('getMeetingById gates the detail read on the allowlist', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [baseRow] })
      .mockResolvedValueOnce({ rows: [] }); // speakers
    await getMeetingById('m1');
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).toContain(publicMeetingStatusClause());
  });

  it('getMeetingById lets an authenticated admin see all statuses', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ ...baseRow, status: 'draft' }] })
      .mockResolvedValueOnce({ rows: [] });
    await getMeetingById('m1', { includeAllStatuses: true });
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).not.toContain(publicMeetingStatusClause());
  });

  it('getTranscriptByMeetingId gates both segment and count queries on the parent meeting', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [] }) // segments
      .mockResolvedValueOnce({ rows: [{ count: '0' }] }); // count
    await getTranscriptByMeetingId('m1', 1);
    const [segSql] = mockQuery.mock.calls[0];
    const [countSql] = mockQuery.mock.calls[1];
    expect(segSql).toContain(publicMeetingExistsClause('$1'));
    expect(countSql).toContain(publicMeetingExistsClause('$1'));
  });

  it('getSummaryByMeetingId gates the summary read on the allowlist', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ summary: null }] });
    await getSummaryByMeetingId('m1');
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).toContain(publicMeetingStatusClause());
  });

  it('getVotesByMeetingId gates the votes read on the parent meeting', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getVotesByMeetingId('m1');
    const [sql] = mockQuery.mock.calls[0];
    expect(sql).toContain(publicMeetingExistsClause('$1'));
  });
});
