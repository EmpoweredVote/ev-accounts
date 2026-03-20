import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { getPoliticiansFlatList, getPoliticianById } from '../lib/essentialsService.js';
import type { Request, Response } from 'express';
import type { AuthenticatedRequest } from '../middleware/auth.js';

/**
 * Essentials politicians routes — Go-parity flat politician list.
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used — all DB access via essentialsService
 *   - optionalAuth — no authentication required for public politician discovery
 *   - Active politicians only. is_incumbent filtering via ?include_candidates query param.
 *   - data_level: 'inform' for unauthenticated, 'connected' for authenticated
 *
 * Response shape matches Go server /api/essentials/politicians exactly.
 * Each item includes district_id, district_type, data_level per Go parity contract.
 */

const router = Router();

// ---------------------------------------------------------------------------
// GET /api/essentials/politicians
// Auth: optional — works unauthenticated (public data)
// Returns active politicians as flat list (Go-parity response shape).
// ?include_candidates=true — include non-incumbents alongside incumbents.
// Without the flag: returns incumbents only (is_incumbent = true).
// On DB error: returns 500 with error body (NOT silent empty array).
// ---------------------------------------------------------------------------

router.get('/', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const includeCandidates = req.query.include_candidates === 'true';
    const userId = (req as AuthenticatedRequest).userId;
    const data_level = userId ? 'connected' : 'inform';
    const politicians = await getPoliticiansFlatList(includeCandidates);
    res.status(200).json(politicians.map((p) => ({ ...p, data_level })));
  } catch (err) {
    console.error('[GET /essentials/politicians] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/politicians/:id
// Auth: optional — works unauthenticated (public data)
// Returns full politician profile with nested contacts, images, degrees, experiences.
// data_level: 'connected' if authenticated, 'inform' if not.
// 404 if politician not found. 422 if ID is not a valid UUID.
// ---------------------------------------------------------------------------

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

router.get('/:id', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;

    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID format' });
      return;
    }

    const userId = (req as AuthenticatedRequest).userId;
    const politician = await getPoliticianById(id);

    if (politician === null) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Politician not found' });
      return;
    }

    const data_level = userId ? 'connected' : 'inform';
    res.status(200).json({ ...politician, data_level });
  } catch (err) {
    console.error('[GET /essentials/politicians/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
