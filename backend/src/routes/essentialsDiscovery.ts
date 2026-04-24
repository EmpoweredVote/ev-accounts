/**
 * essentialsDiscovery — v2.1 Claude candidate discovery admin API.
 *
 * Three endpoints, all gated by requireAdminToken (X-Admin-Token header):
 *
 *   POST /discover/jurisdiction/:id
 *     Triggers a background discovery run for a registered jurisdiction.
 *     Returns 202 immediately; run continues asynchronously.
 *     The discovery_runs row tracks outcome (status, counts, raw_output).
 *
 *   POST /discovery/staging/:id/approve
 *     Marks a pending staging row as approved (status='approved').
 *     Does NOT auto-promote to race_candidates — auto-upsert deferred to Phase 7.
 *     If race_id is NULL, approval succeeds with a warning in the response.
 *
 *   POST /discovery/staging/:id/dismiss
 *     Marks a pending staging row as dismissed (status='dismissed').
 *     Requires a non-empty `reason` string in the request body.
 *
 * Auth: requireAdminToken is applied at mount time in index.ts (NOT in this file).
 * This mirrors the batchIngestHandler pattern — keeps the router auth-agnostic.
 *
 * IMPORTANT: The essentials schema is NOT in PostgREST. All DB writes use
 * pool.query() directly — never the supabase client.
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import { z } from 'zod';
import { pool } from '../lib/db.js';
import { runDiscoveryForJurisdiction } from '../lib/discoveryService.js';

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// POST /discover/jurisdiction/:id
// Auth: requireAdminToken (applied at mount in index.ts)
// Triggers a discovery run for the given discovery_jurisdictions.id.
// Returns 202 immediately; run continues in background.
// ---------------------------------------------------------------------------
router.post('/discover/jurisdiction/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;

    if (!id || !UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid jurisdiction id (expected UUID)' });
      return;
    }

    // Confirm existence BEFORE returning 202 — don't lie about acceptance
    const existsResult = await pool.query(
      'SELECT 1 FROM essentials.discovery_jurisdictions WHERE id = $1',
      [id]
    );
    if (existsResult.rows.length === 0) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'discovery_jurisdictions row not found' });
      return;
    }

    // Fire-and-forget. The run row persists status='running' immediately, so callers can poll.
    // The .catch handler prevents unhandled promise rejection from crashing the process.
    runDiscoveryForJurisdiction(id, { triggeredBy: 'on_demand' }).catch((err) => {
      console.error('[discoverJurisdiction] background run failed for id=' + id + ':', err);
    });

    res.status(202).json({ status: 'accepted', jurisdictionId: id });
  } catch (err) {
    console.error('[POST /discover/jurisdiction/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /discover/race/:id
// Auth: requireAdminToken (applied at mount in index.ts)
// Resolves the discovery_jurisdictions row that covers this race by JOINing
// races → elections → discovery_jurisdictions on (election_date, state), then
// delegates to runDiscoveryForJurisdiction. There is no race_id column on
// discovery_jurisdictions — discovery is jurisdiction-scoped at the agent level.
// Returns 202 immediately; run continues in background.
// ---------------------------------------------------------------------------
router.post('/discover/race/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const raceId = req.params.id as string;

    if (!raceId || !UUID_REGEX.test(raceId)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid race id (expected UUID)' });
      return;
    }

    // Resolve the covering discovery_jurisdictions row.
    // Assumes at most one discovery_jurisdictions row covers a given (election_date, state).
    // If multiple rows match (e.g. overlapping county + city jurisdictions), the first is used.
    const resolveResult = await pool.query<{
      race_exists: boolean;
      jurisdiction_id: string | null;
      jurisdiction_name: string | null;
    }>(
      `WITH race_row AS (
         SELECT r.id AS race_id, r.election_id, e.election_date, e.state
           FROM essentials.races r
           JOIN essentials.elections e ON e.id = r.election_id
          WHERE r.id = $1
       )
       SELECT
         (SELECT true FROM race_row) AS race_exists,
         dj.id   AS jurisdiction_id,
         dj.jurisdiction_name
         FROM race_row rr
         LEFT JOIN essentials.discovery_jurisdictions dj
           ON dj.election_date = rr.election_date AND dj.state = rr.state`,
      [raceId]
    );

    if (resolveResult.rows.length === 0) {
      // The CTE returned no rows → the race itself doesn't exist
      res.status(404).json({ code: 'RACE_NOT_FOUND', message: 'Race not found' });
      return;
    }

    const row = resolveResult.rows[0];
    if (!row.jurisdiction_id) {
      res.status(404).json({
        code: 'NO_DISCOVERY_JURISDICTION',
        message: 'No discovery_jurisdictions row covers this race. Register a jurisdiction with matching election_date + state first.',
      });
      return;
    }

    const jurisdictionId = row.jurisdiction_id;
    const jurisdictionName = row.jurisdiction_name;

    // Fire-and-forget; run row persists status='running' immediately, so callers can poll.
    runDiscoveryForJurisdiction(jurisdictionId, { triggeredBy: 'on_demand' }).catch((err) => {
      console.error('[discoverRace] background run failed for raceId=' + raceId + ' jurisdictionId=' + jurisdictionId + ':', err);
    });

    res.status(202).json({
      status: 'accepted',
      raceId,
      jurisdictionId,
      jurisdictionName,
    });
  } catch (err) {
    console.error('[POST /discover/race/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /discovery/staging/:id/approve
// Auth: requireAdminToken
// Body (optional): { reviewerName?: string }
// Marks a pending staging row as approved (status='approved').
// Does NOT auto-promote to race_candidates (STAG-02 deferred to Phase 7).
// ---------------------------------------------------------------------------
router.post('/discovery/staging/:id/approve', async (req: Request, res: Response): Promise<void> => {
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
    const warning = row.race_id === null
      ? 'Staging row approved, but race_id is NULL. Auto-promotion to race_candidates is deferred to Phase 7. A matching essentials.races row must exist before any promotion.'
      : null;

    res.status(200).json({
      id: row.id,
      fullName: row.full_name,
      status: 'approved',
      confidence: row.confidence,
      action: row.action,
      warning,
    });
  } catch (err) {
    console.error('[POST /discovery/staging/:id/approve] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /discovery/staging/:id/dismiss
// Auth: requireAdminToken
// Body: { reason: string } — required; stored on dismissed_reason
// ---------------------------------------------------------------------------
router.post('/discovery/staging/:id/dismiss', async (req: Request, res: Response): Promise<void> => {
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
