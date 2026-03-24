/**
 * Campaign Finance routes — public API for transparent_motivations data.
 *
 * Purpose: Public-facing campaign finance endpoints for the Essentials frontend
 * (useCampaignFinance.js). All routes are public (optionalAuth — no credentials required).
 *
 * Architecture rules enforced here:
 *   - All DB access via campaignFinanceService (pool.query only — schema not PostgREST-exposed)
 *   - UUID validation before any DB lookup
 *   - politician_source_id NEVER exposed in any response
 *   - X-Data-Updated-At header set on all data responses
 */

import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import type { Request, Response } from 'express';
import {
  getSummary,
  getContributions,
  validateConfidence,
} from '../lib/campaignFinanceService.js';

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// GET /api/campaign-finance/health
// ---------------------------------------------------------------------------

router.get('/health', (_req: Request, res: Response): void => {
  res.status(200).json({ status: 'ok', service: 'campaign-finance' });
});

// ---------------------------------------------------------------------------
// GET /api/campaign-finance/politician/:id/summary
// Query params: ?cycle=2024 ?confidence=high|medium|estimated
// ---------------------------------------------------------------------------

router.get(
  '/politician/:id/summary',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    // Validate ?cycle — must be a 4-digit year string if provided
    const cycleRaw = req.query.cycle as string | undefined;
    if (cycleRaw !== undefined && !/^\d{4}$/.test(cycleRaw)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'cycle must be a 4-digit year' });
      return;
    }

    // Validate ?confidence
    const confidenceRaw = req.query.confidence as string | undefined;
    let confidence: string | null = null;
    try {
      confidence = validateConfidence(confidenceRaw);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Invalid confidence value';
      res.status(422).json({ code: 'VALIDATION_ERROR', message });
      return;
    }

    try {
      const { summary, updatedAt } = await getSummary(id, cycleRaw, confidence);
      if (updatedAt) {
        res.setHeader('X-Data-Updated-At', updatedAt);
      }
      res.status(200).json(summary);
    } catch (err) {
      console.error('[GET /campaign-finance/politician/:id/summary] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/campaign-finance/politician/:id/contributions
// Query params: ?cursor=... ?limit=50 ?cycle=2024 ?confidence=high|medium|estimated
// ---------------------------------------------------------------------------

router.get(
  '/politician/:id/contributions',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'INVALID_ID', message: 'Invalid UUID format' });
      return;
    }

    // Validate ?cycle — must be a 4-digit year string if provided
    const cycleRaw = req.query.cycle as string | undefined;
    if (cycleRaw !== undefined && !/^\d{4}$/.test(cycleRaw)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'cycle must be a 4-digit year' });
      return;
    }

    // Validate ?limit — must be integer 1–100 if provided
    const limitRaw = req.query.limit as string | undefined;
    let limit: number | undefined;
    if (limitRaw !== undefined) {
      const parsed = Number(limitRaw);
      if (!Number.isInteger(parsed) || parsed < 1 || parsed > 100) {
        res.status(422).json({ code: 'VALIDATION_ERROR', message: 'limit must be an integer between 1 and 100' });
        return;
      }
      limit = parsed;
    }

    // Validate ?confidence
    const confidenceRaw = req.query.confidence as string | undefined;
    let confidence: string | null = null;
    try {
      confidence = validateConfidence(confidenceRaw);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Invalid confidence value';
      res.status(422).json({ code: 'VALIDATION_ERROR', message });
      return;
    }

    const cursor = req.query.cursor as string | undefined;

    try {
      const { response, updatedAt } = await getContributions(id, {
        cursor,
        limit,
        cycle: cycleRaw,
        confidence,
      });
      if (updatedAt) {
        res.setHeader('X-Data-Updated-At', updatedAt);
      }
      res.status(200).json(response);
    } catch (err) {
      console.error('[GET /campaign-finance/politician/:id/contributions] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

export default router;
