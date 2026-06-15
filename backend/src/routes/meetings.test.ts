import { beforeEach, describe, expect, it, vi } from 'vitest';
import express from 'express';
import request from 'supertest';

const MEETING_ID = '11111111-1111-1111-1111-111111111111';

const {
  mockCreateMeeting,
  mockDeleteMeeting,
  mockGetMeetingById,
  mockGetMeetings,
  mockGetSummaryByMeetingId,
  mockGetTranscriptByMeetingId,
  mockGetVotesByMeetingId,
  mockUpdateMeeting,
} = vi.hoisted(() => ({
  mockCreateMeeting: vi.fn(),
  mockDeleteMeeting: vi.fn(),
  mockGetMeetingById: vi.fn(),
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
  mockGetMeetings.mockReset();
  mockGetSummaryByMeetingId.mockReset();
  mockGetTranscriptByMeetingId.mockReset();
  mockGetVotesByMeetingId.mockReset();
  mockUpdateMeeting.mockReset();
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
});

describe('PATCH /api/meetings/:id', () => {
  it('accepts clearing city and title on patch', async () => {
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
});
