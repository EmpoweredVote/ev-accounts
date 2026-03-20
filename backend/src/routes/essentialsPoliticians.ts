import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { getPoliticiansFlatList, getPoliticianById, politicianExists } from '../lib/essentialsService.js';
import {
  getLegislativeByPolitician,
  getCommitteesByPolitician,
  getBillsByPolitician,
  getVotesByPolitician,
} from '../lib/essentialsLegislativeService.js';
import type { Request, Response } from 'express';
import type { AuthenticatedRequest } from '../middleware/auth.js';

/**
 * Essentials politicians routes — Go-parity flat politician list and
 * politician depth routes (legislative, committees, bills, votes).
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used — all DB access via essentialsService /
 *     essentialsLegislativeService
 *   - optionalAuth — no authentication required for public politician discovery
 *   - Active politicians only. is_incumbent filtering via ?include_candidates query param.
 *   - data_level: 'inform' for unauthenticated, 'connected' for authenticated
 *
 * CRITICAL ROUTE ORDERING:
 *   /:id/legislative, /:id/committees, /:id/bills, /:id/votes MUST be defined
 *   BEFORE /:id. If /:id is first, Express matches it for paths like
 *   /:id/legislative and the subroute handler never fires.
 *
 * Response shape matches Go server /api/essentials/politicians exactly.
 * Each item includes district_id, district_type, data_level per Go parity contract.
 */

const router = Router();

// UUID regex — shared by all routes that accept politician ID param
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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
// GET /api/essentials/politicians/:id/legislative
// Auth: optional — public data, data_level varies
// Returns legislative sessions for a politician (sessions reachable via
// sponsored/cosponsored bills and vote records).
// 422 for invalid UUID. 404 for non-existent politician.
// Returns { data: LegislativeSession[], data_level }.
// ---------------------------------------------------------------------------

router.get('/:id/legislative', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID format' });
      return;
    }
    const userId = (req as AuthenticatedRequest).userId;
    const exists = await politicianExists(id);
    if (!exists) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Politician not found' });
      return;
    }
    const data = await getLegislativeByPolitician(id);
    const data_level = userId ? 'connected' : 'inform';
    res.status(200).json({ data, data_level });
  } catch (err) {
    console.error('[GET /essentials/politicians/:id/legislative] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/politicians/:id/committees
// Auth: optional — public data, data_level varies
// Returns committee memberships for a politician.
// 422 for invalid UUID. 404 for non-existent politician.
// Returns { data: CommitteeMembership[], data_level }.
// ---------------------------------------------------------------------------

router.get('/:id/committees', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID format' });
      return;
    }
    const userId = (req as AuthenticatedRequest).userId;
    const exists = await politicianExists(id);
    if (!exists) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Politician not found' });
      return;
    }
    const data = await getCommitteesByPolitician(id);
    const data_level = userId ? 'connected' : 'inform';
    res.status(200).json({ data, data_level });
  } catch (err) {
    console.error('[GET /essentials/politicians/:id/committees] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/politicians/:id/bills
// Auth: optional — public data, data_level varies
// Returns bills sponsored or cosponsored by a politician.
// ?limit=N — max 100, default 50. Ordered by introduced_at DESC.
// 422 for invalid UUID. 404 for non-existent politician.
// Returns { data: Bill[], data_level }.
// ---------------------------------------------------------------------------

router.get('/:id/bills', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID format' });
      return;
    }
    const userId = (req as AuthenticatedRequest).userId;
    const exists = await politicianExists(id);
    if (!exists) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Politician not found' });
      return;
    }
    const rawLimit = typeof req.query.limit === 'string' ? parseInt(req.query.limit, 10) : NaN;
    const limit = isNaN(rawLimit) ? 50 : Math.min(100, Math.max(1, rawLimit));
    const data = await getBillsByPolitician(id, limit);
    const data_level = userId ? 'connected' : 'inform';
    res.status(200).json({ data, data_level });
  } catch (err) {
    console.error('[GET /essentials/politicians/:id/bills] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/politicians/:id/votes
// Auth: optional — public data, data_level varies
// Returns voting record for a politician.
// ?limit=N — max 100, default 50. Ordered by vote_date DESC.
// 422 for invalid UUID. 404 for non-existent politician.
// Returns { data: Vote[], data_level }.
// ---------------------------------------------------------------------------

router.get('/:id/votes', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID format' });
      return;
    }
    const userId = (req as AuthenticatedRequest).userId;
    const exists = await politicianExists(id);
    if (!exists) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Politician not found' });
      return;
    }
    const rawLimit = typeof req.query.limit === 'string' ? parseInt(req.query.limit, 10) : NaN;
    const limit = isNaN(rawLimit) ? 50 : Math.min(100, Math.max(1, rawLimit));
    const data = await getVotesByPolitician(id, limit);
    const data_level = userId ? 'connected' : 'inform';
    res.status(200).json({ data, data_level });
  } catch (err) {
    console.error('[GET /essentials/politicians/:id/votes] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/politicians/:id
// Auth: optional — works unauthenticated (public data)
// Returns full politician profile with nested contacts, images, degrees, experiences.
// data_level: 'connected' if authenticated, 'inform' if not.
// 404 if politician not found. 422 if ID is not a valid UUID.
// MUST be LAST — Express matches /:id before /:id/subroutes if defined first.
// ---------------------------------------------------------------------------

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
