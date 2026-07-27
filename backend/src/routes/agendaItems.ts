/**
 * Agenda items routes — public read endpoint for single agenda items
 * (the citizen-facing permalink).
 *
 * Called cross-origin by the on-the-record static site (CORS_ORIGIN allowlist).
 *
 * Public reads: no auth required (optionalAuth)
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { getAgendaItemById } from '../lib/agendaItemsService.js';

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// GET /api/agenda-items/:id
router.get('/:id', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
    return;
  }

  try {
    const item = await getAgendaItemById(id);
    if (!item) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Agenda item not found' });
      return;
    }
    res.status(200).json(item);
  } catch (err) {
    console.error('[GET /agenda-items/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
