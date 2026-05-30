/**
 * discoveryDashboard — JWT-gated read-side API for the Phase 8 admin discovery dashboard.
 *
 * Three endpoints, all gated by requireAuth + requireAdmin (JWT Bearer):
 *
 *   GET /discovery/jurisdictions
 *     Returns one row per discovery_jurisdictions row with last-run summary
 *     and active candidate count.
 *
 *   GET /discovery/runs
 *     Returns paginated run history joined with jurisdiction name.
 *     Query params: limit (default 25, max 100), offset (default 0),
 *     jurisdiction_id (optional UUID filter on discovery_jurisdiction_id).
 *
 *   GET /discovery/coverage
 *     Returns per-jurisdiction race/candidate health stats.
 *
 * Auth: requireAuth + requireAdmin are applied per-route (not at mount time).
 * This is the dual-router pattern: this router serves browser JWT requests while
 * the existing essentialsDiscoveryRouter continues to serve server-to-server
 * X-Admin-Token requests on the same /api/admin mount point.
 *
 * IMPORTANT: The essentials schema is NOT in PostgREST. All DB reads use
 * pool.query() directly — never the supabase client.
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import { pool } from '../lib/db.js';
import { requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { runDiscoveryForJurisdiction } from '../lib/discoveryService.js';
import { acquireRunLock, releaseRunLock } from '../lib/discoveryCron.js';

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// GET /discovery/jurisdictions
// Auth: requireAuth + requireAdmin (per-route)
// Returns one row per discovery_jurisdictions row with last-run summary and
// active (approved) candidate count.
// ---------------------------------------------------------------------------
router.get('/discovery/jurisdictions', requireAuth as any, requireAdmin as any, async (req: Request, res: Response): Promise<void> => {
  try {
    const result = await pool.query(`
      SELECT
        dj.id,
        dj.jurisdiction_name                          AS name,
        dj.election_date,
        dj.source_url,
        lr.id                                         AS last_run_id,
        lr.status                                     AS last_run_status,
        lr.started_at                                 AS last_run_started_at,
        lr.completed_at                               AS last_run_completed_at,
        COALESCE(lr.candidates_new, 0)                AS last_run_candidates_found,
        COALESCE(lr.candidates_auto_upserted, 0)      AS last_run_candidates_auto_upserted,
        COALESCE(active.count, 0)::int                AS active_candidates
      FROM essentials.discovery_jurisdictions dj
      LEFT JOIN LATERAL (
        SELECT id, status, started_at, completed_at, candidates_new, candidates_auto_upserted
        FROM essentials.discovery_runs
        WHERE discovery_jurisdiction_id = dj.id
        ORDER BY started_at DESC
        LIMIT 1
      ) lr ON true
      LEFT JOIN LATERAL (
        SELECT COUNT(*)::int AS count
        FROM essentials.candidate_staging cs
        WHERE cs.discovery_jurisdiction_id = dj.id
          AND cs.status = 'approved'
      ) active ON true
      ORDER BY dj.jurisdiction_name
    `);
    res.json(result.rows);
  } catch (err) {
    console.error('[GET /discovery/jurisdictions] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /discovery/runs
// Auth: requireAuth + requireAdmin (per-route)
// Returns paginated run history joined with jurisdiction name.
// Query params:
//   limit          — number of rows (default 25, max 100)
//   offset         — row offset for pagination (default 0)
//   jurisdiction_id — optional UUID to filter by discovery_jurisdiction_id
// ---------------------------------------------------------------------------
router.get('/discovery/runs', requireAuth as any, requireAdmin as any, async (req: Request, res: Response): Promise<void> => {
  try {
    const limit = Math.min(parseInt(req.query.limit as string) || 25, 100);
    const offset = parseInt(req.query.offset as string) || 0;
    const jurisdictionId = req.query.jurisdiction_id
      ? (req.query.jurisdiction_id as string)
      : null;

    if (jurisdictionId && !UUID_REGEX.test(jurisdictionId)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid jurisdiction_id' });
      return;
    }

    const params: any[] = [limit, offset];
    let where = '';
    if (jurisdictionId) {
      params.push(jurisdictionId);
      where = `WHERE dr.discovery_jurisdiction_id = $${params.length}`;
    }

    const result = await pool.query(`
      SELECT
        dr.id,
        dr.discovery_jurisdiction_id                  AS jurisdiction_id,
        dj.jurisdiction_name                          AS jurisdiction_name,
        dr.status,
        dr.started_at,
        dr.completed_at,
        COALESCE(dr.candidates_new, 0)                AS candidates_found,
        COALESCE(dr.candidates_withdrawn, 0)          AS candidates_staged,
        COALESCE(dr.candidates_auto_upserted, 0)      AS candidates_auto_upserted,
        dr.triggered_by,
        dr.error_message
      FROM essentials.discovery_runs dr
      JOIN essentials.discovery_jurisdictions dj ON dj.id = dr.discovery_jurisdiction_id
      ${where}
      ORDER BY dr.started_at DESC
      LIMIT $1 OFFSET $2
    `, params);

    const countParams = jurisdictionId ? [jurisdictionId] : [];
    const countWhere = jurisdictionId ? `WHERE dr.discovery_jurisdiction_id = $1` : '';
    const countResult = await pool.query(
      `SELECT COUNT(*)::int AS total FROM essentials.discovery_runs dr ${countWhere}`,
      countParams
    );

    res.json({
      runs: result.rows,
      total: countResult.rows[0].total,
      limit,
      offset,
    });
  } catch (err) {
    console.error('[GET /discovery/runs] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /discovery/coverage
// Auth: requireAuth + requireAdmin (per-route)
// Returns per-jurisdiction race/candidate health stats.
// ---------------------------------------------------------------------------
router.get('/discovery/coverage', requireAuth as any, requireAdmin as any, async (req: Request, res: Response): Promise<void> => {
  try {
    const result = await pool.query(`
      SELECT
        dj.id,
        dj.jurisdiction_name                                          AS name,
        COUNT(r.id)::int                                              AS total_races,
        COUNT(CASE WHEN EXISTS(
          SELECT 1 FROM essentials.race_candidates rca WHERE rca.race_id = r.id
        ) THEN 1 END)::int                                           AS races_with_candidates,
        COUNT(CASE WHEN r.id IS NOT NULL AND NOT EXISTS(
          SELECT 1 FROM essentials.race_candidates rca WHERE rca.race_id = r.id
        ) THEN 1 END)::int                                           AS zero_candidate_races
      FROM essentials.discovery_jurisdictions dj
      LEFT JOIN essentials.elections e
        ON e.election_date = dj.election_date AND e.state = dj.state
      LEFT JOIN essentials.races r ON r.election_id = e.id
      GROUP BY dj.id, dj.jurisdiction_name
      ORDER BY dj.jurisdiction_name
    `);
    res.json(result.rows);
  } catch (err) {
    console.error('[GET /discovery/coverage] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /discovery/trigger/:id
// Auth: requireAuth + requireAdmin (per-route, JWT Bearer)
// JWT-gated equivalent of POST /discover/jurisdiction/:id (X-Admin-Token route).
// Triggers a background discovery run for the given discovery_jurisdictions UUID.
// Returns 202 immediately; run continues asynchronously.
// ---------------------------------------------------------------------------
router.post('/discovery/trigger/:id', requireAuth as any, requireAdmin as any, async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;

    if (!id || !UUID_REGEX.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid jurisdiction id (expected UUID)' });
      return;
    }

    const existsResult = await pool.query(
      'SELECT 1 FROM essentials.discovery_jurisdictions WHERE id = $1',
      [id]
    );
    if (existsResult.rows.length === 0) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'discovery_jurisdictions row not found' });
      return;
    }

    if (!acquireRunLock()) {
      res.status(409).json({
        code: 'ALREADY_RUNNING',
        message: 'A discovery run is already in progress. Try again after it completes.',
      });
      return;
    }

    runDiscoveryForJurisdiction(id, { triggeredBy: 'on_demand', autoUpsert: true })
      .catch((err) => {
        console.error('[POST /discovery/trigger/:id] background run failed for id=' + id + ':', err);
      })
      .finally(() => {
        releaseRunLock();
      });

    res.status(202).json({ status: 'accepted', jurisdictionId: id });
  } catch (err) {
    console.error('[POST /discovery/trigger/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
