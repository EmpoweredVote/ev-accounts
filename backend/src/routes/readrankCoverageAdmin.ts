import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { getCoverageGrid, searchRaces } from '../lib/readrankCoverageService.js';

const router = Router();
router.use(requireAuth, requireAdmin);

const gridQuery = z.object({ race_id: z.string().uuid() });
// GET /api/admin/readrank-coverage?race_id=<uuid>
router.get('/', async (req: Request, res: Response): Promise<void> => {
  const parsed = gridQuery.safeParse(req.query);
  if (!parsed.success) {
    res.status(422).json({ error: 'race_id (uuid) is required' });
    return;
  }
  try {
    const grid = await getCoverageGrid(parsed.data.race_id);
    res.status(200).json(grid);
  } catch (err) {
    console.error('[GET /admin/readrank-coverage] error:', err);
    res.status(500).json({ error: 'Failed to load coverage grid' });
  }
});

const racesQuery = z.object({ q: z.string().min(1) });
// GET /api/admin/readrank-coverage/races?q=<text>
router.get('/races', async (req: Request, res: Response): Promise<void> => {
  const parsed = racesQuery.safeParse(req.query);
  if (!parsed.success) {
    res.status(422).json({ error: 'q is required' });
    return;
  }
  try {
    const races = await searchRaces(parsed.data.q);
    res.status(200).json({ races });
  } catch (err) {
    console.error('[GET /admin/readrank-coverage/races] error:', err);
    res.status(500).json({ error: 'Failed to search races' });
  }
});

export default router;
