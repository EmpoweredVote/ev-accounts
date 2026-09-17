import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { runPreflight, confirmEmpowerment, executeDemotion } from '../lib/empowerService.js';
import type { Request, Response } from 'express';

/**
 * Empower flow routes — preflight check, empowerment confirmation, and demotion.
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used in this file — architecture.test.ts bans it from routes/
 *   - All admin DB operations go through empowerService (in lib/)
 *   - All three routes require requireAuth + requireConnected (401 / 403)
 *
 * POST /preflight — validate all empowerment conditions, reserve slug in cache
 * POST /confirm   — validate 3-item consent, call execute_empowerment RPC via service
 * POST /demote    — call execute_demotion RPC via service with optional reason
 */

const router = Router();

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

const ConfirmSchema = z.object({
  consent: z.object({
    legal_name_public: z.literal(true),
    compass_stances_public: z.literal(true),
    platform_terms: z.literal(true),
  }),
  legal_name: z.string().min(1).max(200).optional(),
});

const DemoteSchema = z.object({
  reason: z
    .object({
      lapsed_topic_ids: z.array(z.string()).optional(),
      lapsed_at: z.string().optional(),
      triggered_by: z.enum(['cron', 'admin', 'self']).optional(),
    })
    .optional(),
});

// ---------------------------------------------------------------------------
// POST /api/empower/preflight
// Auth: requireAuth + requireConnected
//
// Validates ALL empowerment conditions in parallel and returns a structured
// result. On ineligibility: returns { eligible: false, failures: [...] } with
// 200 (preflight itself succeeded — it successfully told you you're ineligible).
// On eligibility: returns { eligible: true, summary: {...} } and reserves
// a slug in cache for 1 hour.
// ---------------------------------------------------------------------------

router.post(
  '/preflight',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    try {
      const result = await runPreflight(
        authReq.userId,
        typeof req.body?.legal_name === 'string' ? req.body.legal_name : undefined
      );
      res.status(200).json(result);
    } catch (err) {
      console.error('[POST /empower/preflight] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/empower/confirm
// Auth: requireAuth + requireConnected
//
// Requires all three consent items as z.literal(true). Calls the
// execute_empowerment RPC via empowerService using the slug reserved during
// preflight. Returns 201 with the new empowered profile on success.
//
// Errors:
//   422 CONSENT_INCOMPLETE — any consent item is missing or not literally true
//   409 PREFLIGHT_EXPIRED  — slug reservation expired (re-run preflight)
//   500 INTERNAL_ERROR     — unexpected failure
// ---------------------------------------------------------------------------

router.post(
  '/confirm',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    const parsed = ConfirmSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        code: 'CONSENT_INCOMPLETE',
        message: 'All three consent items must be explicitly accepted',
      });
      return;
    }

    try {
      const result = await confirmEmpowerment(
        authReq.userId,
        ['legal_name_public', 'compass_stances_public', 'platform_terms'],
        parsed.data.legal_name
      );
      res.status(201).json({ empowered: true, profile: result.empowered_profile });
    } catch (err) {
      const errMessage = err instanceof Error ? err.message : String(err);
      const errCode = err instanceof Error ? (err as NodeJS.ErrnoException).code : undefined;

      if (errMessage.includes('PREFLIGHT_EXPIRED') || errCode === 'PREFLIGHT_EXPIRED') {
        res.status(409).json({
          code: 'PREFLIGHT_EXPIRED',
          message: 'Preflight has expired. Please run preflight again.',
        });
        return;
      }

      console.error('[POST /empower/confirm] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Empowerment failed' });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/empower/demote
// Auth: requireAuth + requireConnected
//
// Calls the execute_demotion RPC via empowerService. The reason body is
// optional — if omitted, the RPC records NULL for demotion_reason.
//
// Body (optional):
//   { reason: { lapsed_topic_ids?: string[], lapsed_at?: string, triggered_by?: 'cron'|'admin'|'self' } }
// ---------------------------------------------------------------------------

router.post(
  '/demote',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    const parsed = DemoteSchema.safeParse(req.body ?? {});
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues[0]?.message ?? 'Invalid request body',
      });
      return;
    }

    try {
      await executeDemotion(authReq.userId, parsed.data?.reason);
      res.status(200).json({ demoted: true });
    } catch (err) {
      console.error('[POST /empower/demote] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Demotion failed' });
    }
  }
);

export default router;
