import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { getSpeakerCountsByMeeting } from './adminMeetingsService.js';

describe('getSpeakerCountsByMeeting', () => {
  beforeEach(() => mockQuery.mockReset());

  it('returns {} and does not query when given no ids', async () => {
    expect(await getSpeakerCountsByMeeting([])).toEqual({});
    expect(mockQuery).not.toHaveBeenCalled();
  });

  it('maps named/linked counts to numbers keyed by meeting id', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [{ meeting_id: 'm1', named: '33', linked: '32' }],
    });
    const out = await getSpeakerCountsByMeeting(['m1']);
    expect(out).toEqual({ m1: { named: 33, linked: 32 } });
    const [, params] = mockQuery.mock.calls[0];
    expect(params).toEqual([['m1']]);
  });
});
