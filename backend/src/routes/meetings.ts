/**
 * Meetings routes — city council meeting data for the EV-Accounts API.
 *
 * Purpose: Satisfies CONS-09 — Meetings endpoints served by ev-accounts.
 * The Go server is no longer the authoritative source for meetings data.
 *
 * Public reads: no auth required (optionalAuth)
 * Admin writes: requireAuth + requireAdmin
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used — all DB access via meetingsService (pool.query)
 *   - Meetings schema is NOT PostgREST-exposed; direct pool.query() only
 *   - Explicit UUID validation before any DB lookup
 *   - Zod validation on all write request bodies
 *   - Subpath routes (/upcoming, /:id/transcript, /:id/summary, /:id/votes,
 *     /:id/agenda-items) defined BEFORE /:id
 */

import { Router } from 'express';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import type { Request, Response } from 'express';
import { z } from 'zod';
import {
  getMeetings,
  getMeetingById,
  getMeetingEntityState,
  getTranscriptByMeetingId,
  getSummaryByMeetingId,
  getUpcomingMeetings,
  getVotesByMeetingId,
  createMeeting,
  updateMeeting,
  deleteMeeting,
} from '../lib/meetingsService.js';
import { getAgendaItemsByMeetingId } from '../lib/agendaItemsService.js';
import { EVENT_KINDS } from '../lib/eventKinds.js';
import { validateEventEntities } from '../lib/eventEntityRules.js';

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// Public read routes (optionalAuth — works unauthenticated)
// ---------------------------------------------------------------------------

// GET /api/meetings
// Optional query: ?city=Indianapolis&state=IN&status=scheduled
// Public status gate (ev-cto decision 0017): the service intersects any status
// filter with the public allowlist (published, scheduled), so ?status=draft (or
// any internal status) returns nothing — a draft meeting cannot leak here.
router.get('/', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const filters: { city?: string; state?: string; status?: string; raceId?: string } = {};

  if (typeof req.query.city === 'string') filters.city = req.query.city;
  if (typeof req.query.state === 'string') filters.state = req.query.state;
  if (typeof req.query.status === 'string') filters.status = req.query.status;
  if (typeof req.query.raceId === 'string') filters.raceId = req.query.raceId;

  try {
    const meetings = await getMeetings(Object.keys(filters).length > 0 ? filters : undefined);
    res.status(200).json(meetings);
  } catch (err) {
    console.error('[GET /meetings] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/meetings/upcoming — MUST be registered before ANY /:id... route so
// Express doesn't capture "upcoming" as an id.
router.get('/upcoming', optionalAuth, async (_req: Request, res: Response): Promise<void> => {
  try {
    res.status(200).json(await getUpcomingMeetings());
  } catch (err) {
    console.error('[GET /meetings/upcoming] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/meetings/:id/transcript — MUST be before /:id
// Optional query: ?page=1
router.get(
  '/:id/transcript',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    const pageRaw = req.query.page as string | undefined;
    let page = 1;
    if (pageRaw !== undefined) {
      const parsed = Number(pageRaw);
      if (!Number.isInteger(parsed) || parsed < 1) {
        res.status(422).json({ code: 'VALIDATION_ERROR', message: 'page must be a positive integer' });
        return;
      }
      page = parsed;
    }

    try {
      const result = await getTranscriptByMeetingId(id, page);
      res.status(200).json(result);
    } catch (err) {
      console.error('[GET /meetings/:id/transcript] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// GET /api/meetings/:id/summary — MUST be before /:id
router.get(
  '/:id/summary',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    try {
      const summary = await getSummaryByMeetingId(id);
      if (!summary) {
        res.status(404).json({ code: 'NOT_FOUND', message: 'Summary not found' });
        return;
      }
      res.status(200).json(summary);
    } catch (err) {
      console.error('[GET /meetings/:id/summary] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// GET /api/meetings/:id/votes — MUST be before /:id
router.get(
  '/:id/votes',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    try {
      const votes = await getVotesByMeetingId(id);
      res.status(200).json(votes);
    } catch (err) {
      console.error('[GET /meetings/:id/votes] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// GET /api/meetings/:id/agenda-items — MUST be before /:id
router.get(
  '/:id/agenda-items',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    try {
      const items = await getAgendaItemsByMeetingId(id);
      res.status(200).json(items);
    } catch (err) {
      console.error('[GET /meetings/:id/agenda-items] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// GET /api/meetings/:id
router.get('/:id', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
    return;
  }

  try {
    const meeting = await getMeetingById(id);
    if (!meeting) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Meeting not found' });
      return;
    }
    res.status(200).json(meeting);
  } catch (err) {
    console.error('[GET /meetings/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// Admin write routes (requireAuth + requireAdmin)
// ---------------------------------------------------------------------------

// POST /api/meetings
const createMeetingSchema = z.object({
  city: z.string().min(1).optional().nullable(),
  state: z.string().min(1),
  date: z.string().min(1),
  meetingType: z.string().min(1),
  title: z.string().trim().min(1).optional().nullable(),
  eventKind: z.enum(EVENT_KINDS).default('council'),
  chamberId: z.string().uuid().optional().nullable(),
  durationSeconds: z.number().int().positive().optional().nullable(),
  videoUrl: z.string().url().optional().nullable(),
  audioSource: z.string().optional().nullable(),
  status: z.string().optional(),
});

router.post(
  '/',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const parsed = createMeetingSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.message });
      return;
    }

    try {
      const entityError = validateEventEntities({
        eventKind: parsed.data.eventKind,
        chamberId: parsed.data.chamberId ?? null,
      });
      if (entityError) {
        res.status(422).json({
          code: 'VALIDATION_ERROR',
          message: entityError,
        });
        return;
      }

      const meeting = await createMeeting(parsed.data);
      res.status(201).json(meeting);
    } catch (err) {
      console.error('[POST /meetings] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// PATCH /api/meetings/:id
const updateMeetingSchema = z.object({
  city: z.string().min(1).optional().nullable(),
  state: z.string().min(1).optional(),
  date: z.string().min(1).optional(),
  meetingType: z.string().min(1).optional(),
  title: z.string().trim().min(1).optional().nullable(),
  eventKind: z.enum(EVENT_KINDS).optional(),
  chamberId: z.string().uuid().optional().nullable(),
  durationSeconds: z.number().int().positive().optional().nullable(),
  videoUrl: z.string().url().optional().nullable(),
  audioSource: z.string().optional().nullable(),
  status: z.string().optional(),
});

router.patch(
  '/:id',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    const parsed = updateMeetingSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.message });
      return;
    }

    try {
      const current = await getMeetingEntityState(id);
      if (!current) {
        res.status(404).json({
          code: 'NOT_FOUND',
          message: 'Meeting not found',
        });
        return;
      }

      const nextState = {
        eventKind: parsed.data.eventKind ?? current.eventKind,
        chamberId:
          parsed.data.chamberId !== undefined
            ? parsed.data.chamberId
            : current.chamberId,
      };

      const entityError = validateEventEntities(nextState);
      if (entityError) {
        res.status(422).json({
          code: 'VALIDATION_ERROR',
          message: entityError,
        });
        return;
      }

      const meeting = await updateMeeting(id, parsed.data);
      if (!meeting) {
        res.status(404).json({ code: 'NOT_FOUND', message: 'Meeting not found' });
        return;
      }
      res.status(200).json(meeting);
    } catch (err) {
      console.error('[PATCH /meetings/:id] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// DELETE /api/meetings/:id
router.delete(
  '/:id',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    try {
      const deleted = await deleteMeeting(id);
      if (!deleted) {
        res.status(404).json({ code: 'NOT_FOUND', message: 'Meeting not found' });
        return;
      }
      res.status(204).send();
    } catch (err) {
      console.error('[DELETE /meetings/:id] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

export default router;
