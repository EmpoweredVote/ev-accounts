import { Router, type Request, type Response } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { getStanceBreakdown } from '../lib/compassStatsService.js';

const router = Router();
router.use(requireAuth, requireAdmin);

// GET /api/admin/compass-stats — per-topic stance response distribution
router.get('/', async (_req: Request, res: Response): Promise<void> => {
  try {
    const report = await getStanceBreakdown();
    res.status(200).json(report);
  } catch (err) {
    console.error('[GET /admin/compass-stats] error:', err);
    res.status(500).json({ error: 'Failed to load stance breakdown' });
  }
});

export default router;
