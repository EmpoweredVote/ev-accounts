/**
 * People routes — people who speak in published meetings.
 *
 * Serves the on-the-record web app's /people pages, and (being the
 * essentials backend) lets essentials render appearance cards from the
 * same endpoints.
 *
 * Public reads only: no auth required (optionalAuth). No write routes —
 * roster is derived from meetings.speakers, written by the pipeline.
 *
 * Keyed on essentials.politicians.id (UUID): politician_slug is NULL for
 * ~99.4% of rows (incl. all candidates), so id is the only viable key.
 *
 * Architecture rules enforced here (same as meetings.ts):
 *   - All DB access via peopleService (pool.query)
 *   - UUID validated before any DB lookup
 *   - Subpath route (/:id/appearances) defined BEFORE /:id
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import {
  getPeople,
  getPersonById,
  getAppearancesById,
} from '../lib/peopleService.js';

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// GET /api/people
// Optional query: ?city=Bloomington
router.get('/', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const filters: { city?: string } = {};
  if (typeof req.query.city === 'string') filters.city = req.query.city;

  try {
    const people = await getPeople(Object.keys(filters).length > 0 ? filters : undefined);
    res.status(200).json(people);
  } catch (err) {
    console.error('[GET /people] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/people/:id/appearances — MUST be before /:id
router.get(
  '/:id/appearances',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    try {
      const appearances = await getAppearancesById(id);
      res.status(200).json({ id, appearances });
    } catch (err) {
      console.error('[GET /people/:id/appearances] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// GET /api/people/:id
router.get('/:id', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_REGEX.test(id)) {
    res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
    return;
  }

  try {
    const person = await getPersonById(id);
    if (!person) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Person not found' });
      return;
    }
    res.status(200).json(person);
  } catch (err) {
    console.error('[GET /people/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
