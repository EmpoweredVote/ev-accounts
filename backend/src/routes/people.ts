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
 * Architecture rules enforced here (same as meetings.ts):
 *   - All DB access via peopleService (pool.query)
 *   - Slug validated before any DB lookup
 *   - Subpath route (/:slug/appearances) defined BEFORE /:slug
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import {
  getPeople,
  getPersonBySlug,
  getAppearancesBySlug,
} from '../lib/peopleService.js';

const router = Router();

// Pipeline slugs are kebab-case; cap length defensively.
const SLUG_REGEX = /^[a-z0-9][a-z0-9_-]{0,99}$/;

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

// GET /api/people/:slug/appearances — MUST be before /:slug
router.get(
  '/:slug/appearances',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const slug = req.params.slug as string;
    if (!SLUG_REGEX.test(slug)) {
      res.status(422).json({ code: 'INVALID_SLUG', message: 'Invalid slug format' });
      return;
    }

    try {
      const appearances = await getAppearancesBySlug(slug);
      res.status(200).json({ slug, appearances });
    } catch (err) {
      console.error('[GET /people/:slug/appearances] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// GET /api/people/:slug
router.get('/:slug', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const slug = req.params.slug as string;
  if (!SLUG_REGEX.test(slug)) {
    res.status(422).json({ code: 'INVALID_SLUG', message: 'Invalid slug format' });
    return;
  }

  try {
    const person = await getPersonBySlug(slug);
    if (!person) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Person not found' });
      return;
    }
    res.status(200).json(person);
  } catch (err) {
    console.error('[GET /people/:slug] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
