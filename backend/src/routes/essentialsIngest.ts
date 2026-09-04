/**
 * essentialsIngest — machine-to-machine ingest endpoint for Validation Quests.
 *
 * WHY THIS FILE EXISTS:
 * Validation Quests (VQ) finalizes crowd-verified officeholder answers and needs
 * to push them into the Essentials data store. Rather than writing directly to
 * production politician tables (which require FK mappings we can't guarantee at
 * ingest time), VQ data lands in essentials.quest_verified_facts with
 * status = 'pending_review'. Accounts admins review and promote from there.
 *
 * AUTH:
 * X-Service-Key header — must match VQ_SERVICE_KEY env var.
 * requireServiceKey sets req.permittedSources = ['vq_ingest'].
 * Handler verifies the source matches before writing.
 *
 * STORAGE:
 * The validation + idempotent insert live in lib/essentialsIngestService.ts so the
 * folded VQ consensus job can call them in-process (no HTTP, no service key). This
 * route is the external HTTP surface; it authenticates, then delegates.
 */

import { Router } from 'express';
import { requireServiceKey, type ServiceKeyRequest } from '../middleware/serviceKeyAuth.js';
import {
  ingestQuestVerifiedFact,
  EssentialsIngestValidationError,
} from '../lib/essentialsIngestService.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// POST /api/essentials/ingest/quest-verified
// Auth: requireServiceKey (X-Service-Key: <VQ_SERVICE_KEY>)
//
// Ingests a single crowd-verified officeholder fact from VQ at quest finalization.
// Idempotent: duplicate consensus_record_id returns 200 { is_duplicate: true }.
// ---------------------------------------------------------------------------

router.post(
  '/quest-verified',
  requireServiceKey,
  async (req: Request, res: Response): Promise<void> => {
    const serviceReq = req as ServiceKeyRequest;

    // 1. Verify source authorization
    if (!serviceReq.permittedSources.includes('vq_ingest')) {
      res.status(422).json({
        code: 'SOURCE_NOT_PERMITTED',
        message: "This service key is not authorized to use source 'vq_ingest'",
      });
      return;
    }

    // 2. Validate + store (shared with the in-process VQ consensus path)
    try {
      const result = await ingestQuestVerifiedFact(req.body);
      res
        .status(result.is_duplicate ? 200 : 201)
        .json({ is_duplicate: result.is_duplicate, id: result.id });
    } catch (err) {
      if (err instanceof EssentialsIngestValidationError) {
        res.status(422).json({
          code: 'VALIDATION_ERROR',
          message: err.message,
          fields: err.fields,
        });
        return;
      }
      console.error('[POST /api/essentials/ingest/quest-verified] ingest error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to store verified fact' });
    }
  }
);

export default router;
