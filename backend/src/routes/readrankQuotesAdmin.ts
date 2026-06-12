// /api/admin/readrank-quotes/* — admin-only Read & Rank quote selection.
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { logAdminAction } from '../lib/adminService.js';
import { listReadrankPoliticians, listReadrankQuotes, selectReadrankQuote } from '../lib/readrankQuotesService.js';

const router = Router();
router.use(requireAuth, requireAdmin);

// GET /api/admin/readrank-quotes/politicians — all politicians who have at least one quote
router.get('/politicians', async (_req: Request, res: Response): Promise<void> => {
  try {
    const politicians = await listReadrankPoliticians();
    res.status(200).json({ politicians });
  } catch (err) {
    console.error('[GET /admin/readrank-quotes/politicians] error:', err);
    res.status(500).json({ error: 'Failed to list politicians' });
  }
});

const listQuery = z.object({ politician_id: z.string().uuid() });

// GET /api/admin/readrank-quotes?politician_id=...
router.get('/', async (req: Request, res: Response): Promise<void> => {
  const parsed = listQuery.safeParse(req.query);
  if (!parsed.success) {
    res.status(422).json({ error: 'politician_id (uuid) is required' });
    return;
  }
  try {
    const topics = await listReadrankQuotes(parsed.data.politician_id);
    res.status(200).json({ topics });
  } catch (err) {
    console.error('[GET /admin/readrank-quotes] error:', err);
    res.status(500).json({ error: 'Failed to list quotes' });
  }
});

const selectBody = z.object({ quote_id: z.string().uuid() });

// PUT /api/admin/readrank-quotes/select
router.put('/select', async (req: Request, res: Response): Promise<void> => {
  const parsed = selectBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ error: 'quote_id (uuid) is required' });
    return;
  }
  try {
    await selectReadrankQuote(parsed.data.quote_id);
    await logAdminAction(
      (req as AuthenticatedRequest).userId,
      'readrank_quote.select',
      null,
      { quote_id: parsed.data.quote_id },
    );
    res.status(200).json({ ok: true });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to select quote';
    const code = /not found/i.test(msg) ? 404 : /de-identified/i.test(msg) ? 422 : 500;
    if (code === 500) console.error('[PUT /admin/readrank-quotes/select] error:', err);
    res.status(code).json({ error: msg });
  }
});

export default router;
