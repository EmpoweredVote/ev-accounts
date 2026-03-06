import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { getPoliticiansGrouped } from '../lib/essentialsService.js';
import type { Request, Response } from 'express';

/**
 * Essentials politicians routes — grouped politician data for CompassV2 frontend.
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used — all DB access via essentialsService (supabaseAnon)
 *   - optionalAuth — no authentication required for public politician discovery
 *   - Active politicians only. is_candidate filtering via ?include_candidates query param.
 */

const router = Router();

// ---------------------------------------------------------------------------
// GET /api/essentials/politicians
// Auth: optional — works unauthenticated (public data)
// Returns active politicians grouped by office_title.
// ?include_candidates=true — include candidates alongside incumbents.
// Without the flag: returns incumbents only (is_candidate = false).
// On DB error: returns 500 with error body (NOT silent empty array).
// ---------------------------------------------------------------------------

router.get('/', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const includeCandidates = req.query.include_candidates === 'true';
    const data = await getPoliticiansGrouped(includeCandidates);
    res.status(200).json(data);
  } catch (err) {
    console.error('[GET /essentials/politicians] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
