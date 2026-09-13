/**
 * adminMeetings.ts — /api/admin/meetings/* handlers for the Project-2 review panel.
 *
 * requireAuth + requireAdmin gate the whole router. Reads use the meetings
 * service with { includeAllStatuses: true } so drafts are visible here (and only
 * here). The status PATCH is logged via logAdminAction (ADMN-05).
 */
import { Router, type Request, type Response } from 'express';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import {
  getMeetings,
  getMeetingById,
  getTranscriptByMeetingId,
  getSummaryByMeetingId,
  getVotesByMeetingId,
  updateMeeting,
} from '../lib/meetingsService.js';
import { getSpeakerCountsByMeeting } from '../lib/adminMeetingsService.js';
import { logAdminAction } from '../lib/adminService.js';

const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const ADMIN_STATUSES = new Set(['draft', 'published', 'archived']);
const VIEW = { includeAllStatuses: true } as const;

function actorId(req: Request): string {
  return (req as AuthenticatedRequest).userId ?? 'unknown';
}

const router = Router();
router.use(requireAuth, requireAdmin);

// GET /api/admin/meetings?status=draft — the review queue.
router.get('/', async (req: Request, res: Response): Promise<void> => {
  const status = typeof req.query.status === 'string' ? req.query.status : 'draft';
  try {
    const meetings = await getMeetings({ status }, VIEW);
    const counts = await getSpeakerCountsByMeeting(meetings.map((m) => m.id));
    res.status(200).json(
      meetings.map((m) => ({
        ...m,
        named: counts[m.id]?.named ?? 0,
        linked: counts[m.id]?.linked ?? 0,
      }))
    );
  } catch (err) {
    console.error('[GET /admin/meetings] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/admin/meetings/:id/transcript?page=N — registered before /:id.
router.get('/:id/transcript', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
    return;
  }
  const page = Math.max(1, Number(req.query.page) || 1);
  try {
    res.status(200).json(await getTranscriptByMeetingId(id, page, VIEW));
  } catch (err) {
    console.error('[GET /admin/meetings/:id/transcript] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/admin/meetings/:id/summary
router.get('/:id/summary', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
    return;
  }
  try {
    const summary = await getSummaryByMeetingId(id, VIEW);
    if (!summary) { res.status(404).json({ code: 'NOT_FOUND', message: 'No summary' }); return; }
    res.status(200).json(summary);
  } catch (err) {
    console.error('[GET /admin/meetings/:id/summary] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/admin/meetings/:id/votes
router.get('/:id/votes', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
    return;
  }
  try {
    res.status(200).json(await getVotesByMeetingId(id, VIEW));
  } catch (err) {
    console.error('[GET /admin/meetings/:id/votes] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/admin/meetings/:id — meeting detail (+ speakers).
router.get('/:id', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
    return;
  }
  try {
    const meeting = await getMeetingById(id, VIEW);
    if (!meeting) { res.status(404).json({ code: 'NOT_FOUND', message: 'Meeting not found' }); return; }
    res.status(200).json(meeting);
  } catch (err) {
    console.error('[GET /admin/meetings/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// PATCH /api/admin/meetings/:id — promote (published) / archive (archived) / back to draft.
router.patch('/:id', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
    return;
  }
  const status = (req.body ?? {}).status;
  if (typeof status !== 'string' || !ADMIN_STATUSES.has(status)) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: 'status must be one of: draft, published, archived',
    });
    return;
  }
  try {
    const current = await getMeetingById(id, VIEW);
    if (!current) { res.status(404).json({ code: 'NOT_FOUND', message: 'Meeting not found' }); return; }
    const updated = await updateMeeting(id, { status });
    await logAdminAction(actorId(req), 'meeting_status_change', null, {
      meetingId: id, from: current.status, to: status,
    });
    res.status(200).json(updated);
  } catch (err) {
    console.error('[PATCH /admin/meetings/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
