import { beforeEach, describe, expect, it, vi } from 'vitest';
import express from 'express';
import request from 'supertest';

const MEETING_ID = '11111111-1111-1111-1111-111111111111';
const CHAMBER_ID = '11111111-1111-4111-8111-111111111111';
const RACE_ID = '22222222-2222-4222-8222-222222222222';

const {
  mockCreateMeeting,
  mockDeleteMeeting,
  mockGetMeetingById,
  mockGetMeetingEntityState,
  mockGetMeetings,
  mockGetSummaryByMeetingId,
  mockGetTranscriptByMeetingId,
  mockGetVotesByMeetingId,
  mockUpdateMeeting,
} = vi.hoisted(() => ({
  mockCreateMeeting: vi.fn(),
  mockDeleteMeeting: vi.fn(),
  mockGetMeetingById: vi.fn(),
  mockGetMeetingEntityState: vi.fn(),
  mockGetMeetings: vi.fn(),
  mockGetSummaryByMeetingId: vi.fn(),
  mockGetTranscriptByMeetingId: vi.fn(),
  mockGetVotesByMeetingId: vi.fn(),
  mockUpdateMeeting: vi.fn(),
}));

vi.mock('../lib/meetingsService.js', () => ({
  createMeeting: mockCreateMeeting,
  deleteMeeting: mockDeleteMeeting,
  getMeetingById: mockGetMeetingById,
  getMeetingEntityState: mockGetMeetingEntityState,
  getMeetings: mockGetMeetings,
  getSummaryByMeetingId: mockGetSummaryByMeetingId,
  getTranscriptByMeetingId: mockGetTranscriptByMeetingId,
  getVotesByMeetingId: mockGetVotesByMeetingId,
  updateMeeting: mockUpdateMeeting,
}));

vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
  requireAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import meetingsRouter from './meetings.js';

const app = express();
app.use(express.json());
app.use('/api/meetings', meetingsRouter);

beforeEach(() => {
  mockCreateMeeting.mockReset();
  mockDeleteMeeting.mockReset();
  mockGetMeetingById.mockReset();
  mockGetMeetingEntityState.mockReset();
  mockGetMeetings.mockReset();
  mockGetSummaryByMeetingId.mockReset();
  mockGetTranscriptByMeetingId.mockReset();
  mockGetVotesByMeetingId.mockReset();
  mockUpdateMeeting.mockReset();
});

describe('GET /api/meetings', () => {
  it('forwards ?raceId to getMeetings', async () => {
    mockGetMeetings.mockResolvedValueOnce([]);
    const res = await request(app).get(`/api/meetings?raceId=${RACE_ID}`);
    expect(res.status).toBe(200);
    expect(mockGetMeetings).toHaveBeenCalledWith(
      expect.objectContaining({ raceId: RACE_ID })
    );
  });
});

describe('POST /api/meetings', () => {
  it('accepts a debate with a title and null city', async () => {
    mockCreateMeeting.mockResolvedValueOnce({
      id: MEETING_ID,
      title: 'California Governor Debate',
      eventKind: 'debate',
      city: null,
    });

    const response = await request(app)
      .post('/api/meetings')
      .send({
        city: null,
        state: 'CA',
        date: '2026-06-02',
        meetingType: 'Governor Debate',
        title: 'California Governor Debate',
        eventKind: 'debate',
      });

    expect(response.status).toBe(201);
    expect(mockCreateMeeting).toHaveBeenCalledWith(
      expect.objectContaining({
        city: null,
        title: 'California Governor Debate',
        eventKind: 'debate',
      })
    );
  });

  it('rejects an unknown event kind', async () => {
    const response = await request(app)
      .post('/api/meetings')
      .send({
        city: 'Los Angeles',
        state: 'CA',
        date: '2026-06-02',
        meetingType: 'Debate',
        eventKind: 'town_hall',
      });

    expect(response.status).toBe(422);
    expect(mockCreateMeeting).not.toHaveBeenCalled();
  });

  it.each([
    ['council', null, 'chamberId is required'],
    ['school_board', null, 'chamberId is required'],
  ])(
    'rejects invalid create entity state for %s',
    async (eventKind, chamberId, message) => {
      const response = await request(app)
        .post('/api/meetings')
        .send({
          city: null,
          state: 'CA',
          date: '2026-06-02',
          meetingType: 'Event',
          eventKind,
          chamberId,
        });

      expect(response.status).toBe(422);
      expect(response.body.message).toContain(message);
      expect(mockCreateMeeting).not.toHaveBeenCalled();
    }
  );
});

describe('PATCH /api/meetings/:id', () => {
  it('accepts clearing city and title on patch', async () => {
    mockGetMeetingEntityState.mockResolvedValueOnce({
      eventKind: 'news_clip',
      chamberId: null,
      raceId: null,
    });
    mockUpdateMeeting.mockResolvedValueOnce({
      id: MEETING_ID,
      title: null,
      eventKind: 'news_clip',
      city: null,
    });

    const response = await request(app)
      .patch(`/api/meetings/${MEETING_ID}`)
      .send({ city: null, title: null, eventKind: 'news_clip' });

    expect(response.status).toBe(200);
    expect(mockUpdateMeeting).toHaveBeenCalledWith(MEETING_ID, {
      city: null,
      title: null,
      eventKind: 'news_clip',
    });
  });

  it('accepts changing a chamber event to debate', async () => {
    mockGetMeetingEntityState.mockResolvedValueOnce({
      eventKind: 'council',
      chamberId: CHAMBER_ID,
    });
    mockUpdateMeeting.mockResolvedValueOnce({
      id: MEETING_ID,
      eventKind: 'debate',
      chamberId: null,
    });

    const response = await request(app)
      .patch(`/api/meetings/${MEETING_ID}`)
      .send({ eventKind: 'debate', chamberId: null });

    expect(response.status).toBe(200);
    expect(mockUpdateMeeting).toHaveBeenCalledWith(
      MEETING_ID,
      expect.objectContaining({
        eventKind: 'debate',
        chamberId: null,
      })
    );
  });
});
