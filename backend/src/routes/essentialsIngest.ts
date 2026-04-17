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
 * IDEMPOTENCY:
 * consensus_record_id has a UNIQUE constraint. Duplicate POSTs return 200 with
 * is_duplicate: true rather than 409, matching the xp/award pattern.
 *
 * ALL writes use pool.query() — essentials schema is NOT in PostgREST.
 */

import { Router } from 'express';
import { z } from 'zod';
import { requireServiceKey, type ServiceKeyRequest } from '../middleware/serviceKeyAuth.js';
import { pool } from '../lib/db.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// Validation schema
// ---------------------------------------------------------------------------

const QuestVerifiedFactSchema = z.object({
  consensus_record_id: z.string().min(1).max(255),
  quest_id:            z.string().min(1).max(255),
  question_text:       z.string().min(1).max(2000),
  verified_answer:     z.string().min(1).max(2000),
  confidence_level:    z.number().min(0).max(1),
  total_submissions:   z.number().int().positive(),
  jurisdiction_name:   z.string().min(1).max(500),
  politician_id:       z.string().uuid().optional(), // VQ passes if known; null = needs manual match
});

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

    // 2. Validate body
    const parsed = QuestVerifiedFactSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues[0]?.message ?? 'Invalid request body',
        fields: parsed.error.flatten().fieldErrors,
      });
      return;
    }

    const {
      consensus_record_id,
      quest_id,
      question_text,
      verified_answer,
      confidence_level,
      total_submissions,
      jurisdiction_name,
      politician_id,
    } = parsed.data;

    // 3. Idempotency check — fast path before any lock
    try {
      const existing = await pool.query<{ id: string }>(
        `SELECT id FROM essentials.quest_verified_facts
         WHERE consensus_record_id = $1
         LIMIT 1`,
        [consensus_record_id]
      );

      if (existing.rows.length > 0) {
        res.status(200).json({ is_duplicate: true, id: existing.rows[0]!.id });
        return;
      }
    } catch (err) {
      console.error('[POST /api/essentials/ingest/quest-verified] idempotency check error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to check idempotency' });
      return;
    }

    // 4. Insert
    try {
      const result = await pool.query<{ id: string }>(
        `INSERT INTO essentials.quest_verified_facts
           (consensus_record_id, quest_id, question_text, verified_answer,
            confidence_level, total_submissions, jurisdiction_name, politician_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (consensus_record_id) DO NOTHING
         RETURNING id`,
        [
          consensus_record_id,
          quest_id,
          question_text,
          verified_answer,
          confidence_level,
          total_submissions,
          jurisdiction_name,
          politician_id ?? null,
        ]
      );

      // ON CONFLICT DO NOTHING returns no rows — another process beat us to it
      if (result.rows.length === 0) {
        const existing = await pool.query<{ id: string }>(
          `SELECT id FROM essentials.quest_verified_facts WHERE consensus_record_id = $1`,
          [consensus_record_id]
        );
        res.status(200).json({ is_duplicate: true, id: existing.rows[0]?.id ?? null });
        return;
      }

      res.status(201).json({ is_duplicate: false, id: result.rows[0]!.id });
    } catch (err) {
      console.error('[POST /api/essentials/ingest/quest-verified] insert error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to store verified fact' });
    }
  }
);

export default router;
