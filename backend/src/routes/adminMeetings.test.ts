import { beforeEach, describe, expect, it, vi } from 'vitest';
import express from 'express';
import request from 'supertest';

const MEETING_ID = '11111111-1111-1111-1111-111111111111';

const {
  mockGetMeetings,
  mockGetMeetingById,
  mockGetTranscriptByMeetingId,
  mockGetSummaryByMeetingId,
  mockGetVotesByMeetingId,
  mockUpdateMeeting,
  mockGetSpeakerCountsByMeeting,
  mockLogAdminAction,
} = vi.hoisted(() => ({
  mockGetMeetings: vi.fn(),
  mockGetMeetingById: vi.fn(),
  mockGetTranscriptByMeetingId: vi.fn(),
  mockGetSummaryByMeetingId: vi.fn(),
  mockGetVotesByMeetingId: vi.fn(),
  mockUpdateMeeting: vi.fn(),
  mockGetSpeakerCountsByMeeting: vi.fn(),
  mockLogAdminAction: vi.fn(),
}));

vi.mock('../lib/meetingsService.js', () => ({
  getMeetings: mockGetMeetings,
  getMeetingById: mockGetMeetingById,
  getTranscriptByMeetingId: mockGetTranscriptByMeetingId,
  getSummaryByMeetingId: mockGetSummaryByMeetingId,
  getVotesByMeetingId: mockGetVotesByMeetingId,
  updateMeeting: mockUpdateMeeting,
}));
vi.mock('../lib/adminMeetingsService.js', () => ({
  getSpeakerCountsByMeeting: mockGetSpeakerCountsByMeeting,
}));
vi.mock('../lib/adminService.js', () => ({ logAdminAction: mockLogAdminAction }));

// Mutable middleware impls so a test can simulate 401/403.
let authImpl = (req: any, _res: any, next: any) => { req.userId = 'admin-1'; next(); };
let adminImpl = (_req: any, _res: any, next: any) => next();
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: any, res: any, next: any) => authImpl(req, res, next),
}));
vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: (req: any, res: any, next: any) => adminImpl(req, res, next),
}));

import adminMeetingsRouter from './adminMeetings.js';

const app = express();
app.use(express.json());
app.use('/api/admin/meetings', adminMeetingsRouter);

beforeEach(() => {
  vi.clearAllMocks();
  authImpl = (req: any, _res: any, next: any) => { req.userId = 'admin-1'; next(); };
  adminImpl = (_req: any, _res: any, next: any) => next();
});

describe('GET /api/admin/meetings', () => {
  it('lists drafts with includeAllStatuses and merged named/linked counts', async () => {
    mockGetMeetings.mockResolvedValueOnce([
      { id: MEETING_ID, title: 'US House Floor', status: 'draft', speakerCount: 48 },
    ]);
    mockGetSpeakerCountsByMeeting.mockResolvedValueOnce({ [MEETING_ID]: { named: 33, linked: 32 } });

    const res = await request(app).get('/api/admin/meetings?status=draft');

    expect(res.status).toBe(200);
    expect(mockGetMeetings).toHaveBeenCalledWith({ status: 'draft' }, { includeAllStatuses: true });
    expect(res.body).toEqual([
      { id: MEETING_ID, title: 'US House Floor', status: 'draft', speakerCount: 48, named: 33, linked: 32 },
    ]);
  });

  it('defaults to status=draft when no status query is given', async () => {
    mockGetMeetings.mockResolvedValueOnce([]);
    mockGetSpeakerCountsByMeeting.mockResolvedValueOnce({});
    await request(app).get('/api/admin/meetings');
    expect(mockGetMeetings).toHaveBeenCalledWith({ status: 'draft' }, { includeAllStatuses: true });
  });

  it('returns 401 when not authenticated', async () => {
    authImpl = (_req: any, res: any) => res.status(401).json({ code: 'UNAUTHENTICATED' });
    const res = await request(app).get('/api/admin/meetings');
    expect(res.status).toBe(401);
    expect(mockGetMeetings).not.toHaveBeenCalled();
  });

  it('returns 403 when authenticated but not an admin', async () => {
    adminImpl = (_req: any, res: any) => res.status(403).json({ error: 'Admin access required' });
    const res = await request(app).get('/api/admin/meetings');
    expect(res.status).toBe(403);
    expect(mockGetMeetings).not.toHaveBeenCalled();
  });
});

describe('GET /api/admin/meetings/:id', () => {
  it('returns a draft meeting with includeAllStatuses', async () => {
    mockGetMeetingById.mockResolvedValueOnce({ id: MEETING_ID, status: 'draft', speakers: [] });
    const res = await request(app).get(`/api/admin/meetings/${MEETING_ID}`);
    expect(res.status).toBe(200);
    expect(mockGetMeetingById).toHaveBeenCalledWith(MEETING_ID, { includeAllStatuses: true });
  });

  it('404s a missing meeting', async () => {
    mockGetMeetingById.mockResolvedValueOnce(null);
    const res = await request(app).get(`/api/admin/meetings/${MEETING_ID}`);
    expect(res.status).toBe(404);
  });

  it('422s a malformed id', async () => {
    const res = await request(app).get('/api/admin/meetings/not-a-uuid');
    expect(res.status).toBe(422);
    expect(mockGetMeetingById).not.toHaveBeenCalled();
  });
});

describe('GET /api/admin/meetings/:id/transcript', () => {
  it('passes page and includeAllStatuses', async () => {
    mockGetTranscriptByMeetingId.mockResolvedValueOnce({ segments: [], page: 2, totalCount: 0 });
    const res = await request(app).get(`/api/admin/meetings/${MEETING_ID}/transcript?page=2`);
    expect(res.status).toBe(200);
    expect(mockGetTranscriptByMeetingId).toHaveBeenCalledWith(MEETING_ID, 2, { includeAllStatuses: true });
  });
});
