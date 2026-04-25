/**
 * stagingQueueAdmin — JWT-gated staging queue API for the browser admin UI (STAG-06).
 *
 * Three endpoints, all gated by requireAuth + requireAdmin (JWT Bearer):
 *
 *   GET /discovery/staging
 *     Returns all pending staged candidates with race, election, and jurisdiction
 *     context. Uses LEFT JOIN so rows with race_id = NULL are still returned.
 *     Sorted by election_date ASC (soonest first), then confidence ASC, then created_at ASC.
 *
 *   POST /discovery/staging/:id/approve
 *     Marks a pending staging row as approved and upserts the candidate to
 *     race_candidates (source='discovery_admin') when race_id is not null and
 *     action != 'withdrawal'. Returns upsertResult: inserted|already_present|skipped_*.
 *
 *   POST /discovery/staging/:id/dismiss
 *     Marks a pending staging row as dismissed (status='dismissed').
 *     Requires a non-empty `reason` string in the request body.
 *
 * Auth: requireAuth + requireAdmin are applied per-route inside this file (NOT at mount time).
 * This is the dual-router pattern: this router serves browser JWT requests while the existing
 * essentialsDiscoveryRouter continues to serve server-to-server X-Admin-Token requests.
 *
 * IMPORTANT: The essentials schema is NOT in PostgREST. All DB reads/writes use
 * pool.query() directly — never the supabase client.
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import { z } from 'zod';
import { pool } from '../lib/db.js';
import { autoUpsertToRaceCandidates } from '../lib/discoveryService.js';
import { requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// GET /discovery/staging
// Auth: requireAuth + requireAdmin (per-route)
// Returns all pending staged candidates grouped/ordered by election date.
// Uses LEFT JOIN so rows with race_id = NULL are still included.
// ---------------------------------------------------------------------------
router.get('/discovery/staging', requireAuth as any, requireAdmin as any, async (req: Request, res: Response): Promise<void> => {
  try {
    const result = await pool.query(`
      SELECT
        cs.id, cs.full_name, cs.confidence, cs.action, cs.flagged, cs.flag_reason,
        cs.citation_url, cs.race_hint, cs.run_id, cs.created_at, cs.race_id,
        r.position_name AS race_name,
        e.id AS election_id, e.election_date, e.name AS election_name, e.state, e.jurisdiction_level,
        dj.id AS discovery_jurisdiction_id, dj.jurisdiction_name
      FROM essentials.candidate_staging cs
      LEFT JOIN essentials.races r ON r.id = cs.race_id
      LEFT JOIN essentials.elections e ON e.id = r.election_id
      LEFT JOIN essentials.discovery_jurisdictions dj ON dj.id = cs.discovery_jurisdiction_id
      WHERE cs.status = 'pending'
      ORDER BY e.election_date ASC NULLS LAST, cs.confidence ASC, cs.created_at ASC
    `);

    res.status(200).json(result.rows);
  } catch (err) {
    console.error('[GET /discovery/staging] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /discovery/staging/:id/approve
// Auth: requireAuth + requireAdmin (per-route)
// Body (optional): { reviewerName?: string }
// Marks pending staging row approved and upserts to race_candidates when race_id is not null
// and action != 'withdrawal'. Returns upsertResult in the response body.
// ---------------------------------------------------------------------------
router.post('/discovery/staging/:id/approve', requireAuth as any, requireAdmin as any, async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    if (!id || !UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid staging id' });
      return;
    }

    const bodySchema = z.object({ reviewerName: z.string().trim().min(1).max(200).optional() });
    const body = bodySchema.safeParse(req.body ?? {});
    if (!body.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid body', issues: body.error.flatten() });
      return;
    }
    const reviewedBy = body.data.reviewerName ?? 'admin';

    const result = await pool.query(
      `UPDATE essentials.candidate_staging
          SET status = 'approved',
              reviewed_at = now(),
              reviewed_by = $2
        WHERE id = $1 AND status = 'pending'
        RETURNING id, full_name, confidence, action, race_id, flagged, flag_reason`,
      [id, reviewedBy]
    );

    if (result.rows.length === 0) {
      const statusResult = await pool.query(
        'SELECT status FROM essentials.candidate_staging WHERE id = $1',
        [id]
      );
      if (statusResult.rows.length === 0) {
        res.status(404).json({ code: 'NOT_FOUND', message: 'Staging row not found' });
      } else {
        res.status(409).json({
          code: 'ALREADY_REVIEWED',
          message: `Staging row is already ${statusResult.rows[0].status}`,
        });
      }
      return;
    }

    const row = result.rows[0];

    let upsertResult: 'inserted' | 'already_present' | 'skipped_no_race' | 'skipped_withdrawal' = 'skipped_no_race';
    if (row.race_id !== null && row.action !== 'withdrawal') {
      upsertResult = await autoUpsertToRaceCandidates({
        raceId: row.race_id,
        fullName: row.full_name,
        source: 'discovery_admin',
      });
    } else if (row.action === 'withdrawal') {
      upsertResult = 'skipped_withdrawal';
    }

    res.status(200).json({
      id: row.id,
      fullName: row.full_name,
      status: 'approved',
      confidence: row.confidence,
      action: row.action,
      upsertResult,
    });
  } catch (err) {
    console.error('[POST /discovery/staging/:id/approve] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /discovery/staging/:id/dismiss
// Auth: requireAuth + requireAdmin (per-route)
// Body: { reason: string } — required; stored on dismissed_reason
// ---------------------------------------------------------------------------
router.post('/discovery/staging/:id/dismiss', requireAuth as any, requireAdmin as any, async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    if (!id || !UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid staging id' });
      return;
    }

    const bodySchema = z.object({
      reason: z.string().trim().min(1).max(500),
      reviewerName: z.string().trim().min(1).max(200).optional(),
    });
    const body = bodySchema.safeParse(req.body ?? {});
    if (!body.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: 'Body requires a non-empty `reason` string',
        issues: body.error.flatten(),
      });
      return;
    }
    const reviewedBy = body.data.reviewerName ?? 'admin';

    const result = await pool.query(
      `UPDATE essentials.candidate_staging
          SET status = 'dismissed',
              dismissed_reason = $2,
              reviewed_at = now(),
              reviewed_by = $3
        WHERE id = $1 AND status = 'pending'
        RETURNING id, full_name, confidence, action`,
      [id, body.data.reason, reviewedBy]
    );

    if (result.rows.length === 0) {
      const statusResult = await pool.query(
        'SELECT status FROM essentials.candidate_staging WHERE id = $1',
        [id]
      );
      if (statusResult.rows.length === 0) {
        res.status(404).json({ code: 'NOT_FOUND', message: 'Staging row not found' });
      } else {
        res.status(409).json({
          code: 'ALREADY_REVIEWED',
          message: `Staging row is already ${statusResult.rows[0].status}`,
        });
      }
      return;
    }

    const row = result.rows[0];
    res.status(200).json({
      id: row.id,
      fullName: row.full_name,
      status: 'dismissed',
      dismissedReason: body.data.reason,
      confidence: row.confidence,
      action: row.action,
    });
  } catch (err) {
    console.error('[POST /discovery/staging/:id/dismiss] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
