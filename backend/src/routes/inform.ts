import { Router } from 'express';
import type { Request, Response } from 'express';
import { z } from 'zod';
import { getBoundary } from '../lib/informBoundaryService.js';

/**
 * Inform pillar — geographic boundary geometry for the Read & Rank motif.
 * Mounted at /api/inform in index.ts. Public (the app uses plain fetch).
 */
const router = Router();

const querySchema = z.object({
  layer: z.string().min(1).max(32),
  geoid: z.string().min(1).max(32),
});

// GET /api/inform/boundary?layer=<mtfcc>&geoid=<geo_id>
router.get('/boundary', async (req: Request, res: Response): Promise<void> => {
  const parsed = querySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'layer and geoid are required' });
    return;
  }
  try {
    const result = await getBoundary(parsed.data.layer, parsed.data.geoid);
    res.status(200).json(result);
  } catch (err) {
    console.error('[GET /inform/boundary] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
