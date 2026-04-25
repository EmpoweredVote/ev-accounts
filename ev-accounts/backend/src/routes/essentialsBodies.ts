import { Router } from 'express';
import type { Request, Response } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { searchBodies, getRosterBySlug } from '../lib/essentialsBodiesService.js';

const router = Router();

router.get('/', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const q = typeof req.query.q === 'string' ? req.query.q.trim() : '';
  if (q.length < 2) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: 'q must be at least 2 characters',
    });
    return;
  }
  const stateRaw = typeof req.query.state === 'string' ? req.query.state.trim() : '';
  let state: string | null = null;
  if (stateRaw) {
    if (!/^[A-Za-z]{2}$/.test(stateRaw)) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: 'state must be a 2-letter abbreviation',
      });
      return;
    }
    state = stateRaw.toUpperCase();
  }
  try {
    const bodies = await searchBodies(q, state);
    res.status(200).json(bodies);
  } catch (err) {
    console.error('[GET /essentials/bodies] error:', err);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    });
  }
});

router.get('/:slug/roster', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const slug = (req.params.slug as string | undefined) ?? '';
  if (!/^[a-z0-9-]+$/.test(slug)) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: 'slug must be kebab-case [a-z0-9-]',
    });
    return;
  }
  try {
    const roster = await getRosterBySlug(slug);
    if (roster === null) {
      res.status(404).json({
        code: 'BODY_NOT_FOUND',
        message: 'No governing body matched that slug',
      });
      return;
    }
    res.status(200).json(roster);
  } catch (err) {
    console.error('[GET /essentials/bodies/:slug/roster] error:', err);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    });
  }
});

export default router;
