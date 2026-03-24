/**
 * campaignFinanceAdmin — admin routes for campaign finance management.
 *
 * Purpose: Lets operators manage politician source IDs, trigger adapter
 * runs manually (single-source JWT-auth and batch X-Admin-Token), and
 * run FEC historical backfills.
 *
 * Ported from:
 *   EV-Backend/internal/campaign_finance/handlers.go (sources CRUD, FEC handler)
 *   EV-Backend/internal/campaign_finance/admin_handler.go (batch ingest dispatch)
 *   EV-Backend/internal/campaign_finance/routes.go (route mounting)
 *
 * Auth model:
 *   - Sources CRUD, per-adapter ingest, backfill, ingestion-runs:
 *       requireAuth + requireAdmin (JWT)
 *   - Batch ingest trigger (/admin/ingest/:adapter):
 *       requireAdminToken (X-Admin-Token header) — registered directly on app in index.ts
 *
 * Route mounting: campaignFinanceAdminRouter mounts at /api/campaign-finance in index.ts.
 *
 * Architecture rules enforced here:
 *   - All DB access via campaignFinanceService (pool.query — NOT PostgREST/supabaseAdmin)
 *   - Explicit UUID validation before any DB lookup
 *   - politician_source_id never exposed in public JSON responses
 *   - Zod validation on all write request bodies
 */

import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import type { Request, Response } from 'express';
import type { AuthenticatedRequest } from '../middleware/auth.js';
import { z } from 'zod';
import {
  getSourcesByPolitician,
  createSource,
  getSourceById,
  updateSource,
  deleteSource,
  logSourceAudit,
  getIngestionRuns,
  getIngestionRunAfter,
  getConfirmedFecSources,
  getMostRecentIngestionRun,
} from '../lib/campaignFinanceService.js';
import { runIngestion } from '../lib/adapters/runIngestion.js';
import { createFecAdapter } from '../lib/adapters/fecAdapter.js';

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// Helper: get username from authenticated request (best-effort, non-fatal)
// ---------------------------------------------------------------------------

/**
 * resolveUsername does a best-effort lookup of username from app_auth.users
 * for audit logging purposes. Falls back to userId on any error.
 */
async function resolveUsername(userId: string): Promise<string> {
  // Import pool directly for the username lookup — this is an admin-layer
  // concern, not exposed via service layer.
  const { pool } = await import('../lib/db.js');
  try {
    const result = await pool.query<{ username: string }>(
      `SELECT username FROM app_auth.users WHERE user_id = $1 LIMIT 1`,
      [userId]
    );
    return result.rows[0]?.username ?? userId;
  } catch {
    return userId;
  }
}

// ---------------------------------------------------------------------------
// Sources CRUD routes — requireAuth + requireAdmin
// ---------------------------------------------------------------------------

// GET /api/campaign-finance/sources/:politicianId
// List all politician_sources for a politician by essentials_politician_id
router.get(
  '/sources/:politicianId',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const politicianId = req.params.politicianId as string;
    if (!UUID_REGEX.test(politicianId)) {
      res.status(422).json({ error: 'Invalid politician UUID' });
      return;
    }

    try {
      const sources = await getSourcesByPolitician(politicianId);
      res.status(200).json(sources);
    } catch (err) {
      console.error('[GET /campaign-finance/sources/:politicianId] error:', err);
      res.status(500).json({ error: 'Failed to query sources' });
    }
  }
);

// POST /api/campaign-finance/sources
// Create a new politician_source row
const createSourceSchema = z.object({
  essentials_politician_id: z.string().uuid(),
  source_system: z.string().min(1).max(32),
  external_id: z.string().max(128).optional().default(''),
  research_status: z
    .enum(['needs_research', 'confirmed', 'not_applicable', 'disputed'])
    .optional()
    .default('needs_research'),
  notes: z.string().optional().default(''),
});

router.post(
  '/sources',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const parsed = createSourceSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ error: parsed.error.message });
      return;
    }

    try {
      const newSource = await createSource(parsed.data);

      // Audit log — best-effort, non-fatal on error
      const authReq = req as AuthenticatedRequest;
      const username = await resolveUsername(authReq.userId).catch(() => authReq.userId);
      await logSourceAudit(newSource.id, authReq.userId, username, 'CREATE', null, newSource).catch(
        (err) => console.warn('[sources CRUD] audit log failed (non-fatal):', err)
      );

      res.status(201).json(newSource);
    } catch (err) {
      console.error('[POST /campaign-finance/sources] error:', err);
      res.status(500).json({ error: 'Failed to create source' });
    }
  }
);

// PUT /api/campaign-finance/sources/:id
// Update an existing politician_source row
const updateSourceSchema = z.object({
  essentials_politician_id: z.string().uuid().optional(),
  source_system: z.string().min(1).max(32).optional(),
  external_id: z.string().max(128).optional(),
  research_status: z
    .enum(['needs_research', 'confirmed', 'not_applicable', 'disputed'])
    .optional(),
  notes: z.string().optional(),
});

router.put(
  '/sources/:id',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ error: 'Invalid source UUID' });
      return;
    }

    const parsed = updateSourceSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ error: parsed.error.message });
      return;
    }

    try {
      // Fetch existing row for audit log (before state)
      const existing = await getSourceById(id);
      if (!existing) {
        res.status(404).json({ error: 'Source not found' });
        return;
      }

      const updated = await updateSource(id, parsed.data);
      if (!updated) {
        res.status(404).json({ error: 'Source not found' });
        return;
      }

      // Audit log — best-effort, non-fatal on error
      const authReq = req as AuthenticatedRequest;
      const username = await resolveUsername(authReq.userId).catch(() => authReq.userId);
      await logSourceAudit(id, authReq.userId, username, 'UPDATE', existing, updated).catch(
        (err) => console.warn('[sources CRUD] audit log failed (non-fatal):', err)
      );

      res.status(200).json(updated);
    } catch (err) {
      console.error('[PUT /campaign-finance/sources/:id] error:', err);
      res.status(500).json({ error: 'Failed to update source' });
    }
  }
);

// DELETE /api/campaign-finance/sources/:id
// Delete a politician_source row
router.delete(
  '/sources/:id',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_REGEX.test(id)) {
      res.status(422).json({ error: 'Invalid source UUID' });
      return;
    }

    try {
      // Fetch existing row for audit log (before state)
      const existing = await getSourceById(id);
      if (!existing) {
        res.status(404).json({ error: 'Source not found' });
        return;
      }

      const deleted = await deleteSource(id);
      if (!deleted) {
        res.status(404).json({ error: 'Source not found' });
        return;
      }

      // Audit log — best-effort, non-fatal on error
      const authReq = req as AuthenticatedRequest;
      const username = await resolveUsername(authReq.userId).catch(() => authReq.userId);
      await logSourceAudit(id, authReq.userId, username, 'DELETE', existing, null).catch(
        (err) => console.warn('[sources CRUD] audit log failed (non-fatal):', err)
      );

      res.status(200).json({ deleted: true });
    } catch (err) {
      console.error('[DELETE /campaign-finance/sources/:id] error:', err);
      res.status(500).json({ error: 'Failed to delete source' });
    }
  }
);

// ---------------------------------------------------------------------------
// Per-adapter JWT-authenticated ingest routes — requireAuth + requireAdmin
// These are single-source, targeted runs (not batch).
// ---------------------------------------------------------------------------

// POST /api/campaign-finance/admin/ingest/fec
// Trigger a synchronous FEC ingest for one confirmed politician_source + one cycle.
const ingestFecSchema = z.object({
  politician_source_id: z.string().uuid(),
  cycle: z.string().min(4).max(4),
});

router.post(
  '/admin/ingest/fec',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const parsed = ingestFecSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'politician_source_id and cycle are required' });
      return;
    }

    const { politician_source_id, cycle } = parsed.data;

    try {
      // Validate that the source exists and is FEC + confirmed
      const ps = await getSourceById(politician_source_id);
      if (!ps) {
        res.status(404).json({ error: 'politician_source not found' });
        return;
      }
      if (ps.source_system !== 'fec' || ps.research_status !== 'confirmed') {
        res.status(400).json({
          error: 'politician_source must be source_system=fec and research_status=confirmed',
        });
        return;
      }

      const startedAfter = new Date();
      const adapter = createFecAdapter(cycle);
      await runIngestion(adapter, ps, cycle);

      // Retrieve the run record created during this ingestion
      const run = await getIngestionRunAfter(politician_source_id, cycle, startedAfter);
      if (!run) {
        res.status(500).json({ error: 'ingestion completed but could not retrieve run ID' });
        return;
      }

      res.status(200).json({
        status: 'ok',
        ingestion_run_id: run.id,
        message: 'ingestion complete',
      });
    } catch (err) {
      console.error('[POST /campaign-finance/admin/ingest/fec] error:', err);
      res.status(500).json({ error: err instanceof Error ? err.message : String(err) });
    }
  }
);

// POST /api/campaign-finance/admin/ingest/cal-access
// Cal-Access adapter not yet ported (Plan 07 work) — return 501.
router.post(
  '/admin/ingest/cal-access',
  requireAuth,
  requireAdmin,
  (_req: Request, res: Response): void => {
    res.status(501).json({ error: 'Cal-Access ingest not yet implemented in Express port' });
  }
);

// POST /api/campaign-finance/admin/ingest/socrata
// Socrata adapter not yet ported — return 501.
router.post(
  '/admin/ingest/socrata',
  requireAuth,
  requireAdmin,
  (_req: Request, res: Response): void => {
    res.status(501).json({ error: 'Socrata ingest not yet implemented in Express port' });
  }
);

// POST /api/campaign-finance/admin/ingest/indiana
// Indiana adapter not yet ported — return 501.
router.post(
  '/admin/ingest/indiana',
  requireAuth,
  requireAdmin,
  (_req: Request, res: Response): void => {
    res.status(501).json({ error: 'Indiana ingest not yet implemented in Express port' });
  }
);

// ---------------------------------------------------------------------------
// FEC historical backfill route — requireAuth + requireAdmin
// Iterates cycles from current back to 2010, runs FEC per source per cycle.
// Non-aborting: per-politician errors logged, continues to next.
// Idempotent via ON CONFLICT upsert in fecAdapter.
// ---------------------------------------------------------------------------

// POST /api/campaign-finance/admin/backfill/fec
router.post(
  '/admin/backfill/fec',
  requireAuth,
  requireAdmin,
  async (_req: Request, res: Response): Promise<void> => {
    try {
      const sources = await getConfirmedFecSources();

      if (sources.length === 0) {
        res.status(200).json({
          status: 'completed_with_warning',
          message: 'No confirmed FEC sources found',
          results: [],
        });
        return;
      }

      // Determine current FEC cycle: round up to next even year
      const now = new Date();
      const currentYear = now.getFullYear();
      const currentCycle = currentYear % 2 !== 0 ? currentYear + 1 : currentYear;

      // Iterate from current cycle back to 2010 (inclusive)
      const cycles: string[] = [];
      for (let year = currentCycle; year >= 2010; year -= 2) {
        cycles.push(String(year));
      }

      type BackfillResult = {
        politician_source_id: string;
        cycle: string;
        status: string;
        error?: string;
      };

      const results: BackfillResult[] = [];

      for (const ps of sources) {
        for (const cycle of cycles) {
          try {
            const adapter = createFecAdapter(cycle);
            await runIngestion(adapter, ps, cycle);
            results.push({ politician_source_id: ps.id, cycle, status: 'completed' });
          } catch (err) {
            // Non-aborting: log error, continue to next source/cycle
            const errMsg = err instanceof Error ? err.message : String(err);
            console.error(
              `[FEC backfill] source=${ps.id} cycle=${cycle} error: ${errMsg}`
            );
            results.push({
              politician_source_id: ps.id,
              cycle,
              status: 'failed',
              error: errMsg,
            });
          }
        }
      }

      const failedCount = results.filter((r) => r.status === 'failed').length;
      res.status(200).json({
        status: failedCount > 0 ? 'completed_with_errors' : 'ok',
        message: `FEC backfill complete: ${results.length} runs, ${failedCount} errors`,
        results,
      });
    } catch (err) {
      console.error('[POST /campaign-finance/admin/backfill/fec] error:', err);
      res.status(500).json({ error: err instanceof Error ? err.message : String(err) });
    }
  }
);

// ---------------------------------------------------------------------------
// Ingestion runs list — requireAuth + requireAdmin
// ---------------------------------------------------------------------------

// GET /api/campaign-finance/admin/ingestion-runs
// List recent ingestion_runs with optional ?adapter filter.
router.get(
  '/admin/ingestion-runs',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response): Promise<void> => {
    const adapterFilter = req.query.adapter as string | undefined;
    const limitRaw = req.query.limit as string | undefined;
    const limit = limitRaw ? Math.min(Number(limitRaw) || 50, 500) : 50;

    try {
      const runs = await getIngestionRuns(adapterFilter, limit);
      res.status(200).json(runs);
    } catch (err) {
      console.error('[GET /campaign-finance/admin/ingestion-runs] error:', err);
      res.status(500).json({ error: 'Failed to query ingestion runs' });
    }
  }
);

export default router;

// ---------------------------------------------------------------------------
// Batch ingest handler — exported for direct registration on app in index.ts
//
// Route: POST /admin/ingest/:adapter
// Auth: requireAdminToken (X-Admin-Token header) — NOT JWT
//
// This handler is registered DIRECTLY on app (not on this router) in index.ts
// so its path is /admin/ingest/:adapter (no /api/campaign-finance prefix).
//
// Three-shape response contract — ALL non-400 outcomes return HTTP 200:
//   Success:         { status: "ok",      adapter, ingestion_run_id }
//   Lock contention: { status: "skipped", adapter, reason: "lock held by another instance" }
//   Other failure:   { status: "failed",  adapter, error }
// Unknown adapter returns HTTP 400: { error: "unknown adapter: X" }
//
// Ported from: EV-Backend/internal/campaign_finance/admin_handler.go
// ---------------------------------------------------------------------------

// adapterDBNames maps URL-friendly adapter name to ingestion_runs.adapter_name column value
const adapterDBNames: Record<string, string> = {
  fec: 'fec',
  'cal-access': 'cal_access',
  indiana: 'indiana',
  socrata: 'la_socrata',
};

/**
 * batchIngestHandler handles POST /admin/ingest/:adapter.
 *
 * Dispatches to the appropriate adapter's ingest-all function.
 * Returns three-shape response (ok/skipped/failed) — all HTTP 200.
 * Unknown adapter returns HTTP 400.
 */
export async function batchIngestHandler(req: Request, res: Response): Promise<void> {
  const adapterName = req.params.adapter as string;

  // Validate adapter name
  if (!Object.keys(adapterDBNames).includes(adapterName)) {
    res.status(400).json({ error: `unknown adapter: ${adapterName}` });
    return;
  }

  try {
    // Dispatch to adapter
    await dispatchAdapter(adapterName);

    // Fetch most recent ingestion_run for this adapter
    const dbName = adapterDBNames[adapterName]!;
    const run = await getMostRecentIngestionRun(dbName);

    res.status(200).json({
      status: 'ok',
      adapter: adapterName,
      ingestion_run_id: run?.id ?? null,
    });
  } catch (err) {
    const errMsg = err instanceof Error ? err.message : String(err);

    // Lock contention → HTTP 200 skipped (prevents retry floods from EventBridge)
    if (errMsg.toLowerCase().includes('lock')) {
      res.status(200).json({
        status: 'skipped',
        adapter: adapterName,
        reason: 'lock held by another instance',
      });
      return;
    }

    // Other failure → HTTP 200 failed (prevents retry floods)
    res.status(200).json({
      status: 'failed',
      adapter: adapterName,
      error: errMsg,
    });
  }
}

/**
 * dispatchAdapter runs the named adapter's ingest-all function.
 * Returns a promise that resolves on success, rejects on failure.
 * Callers test for "lock" in the error message to detect Redis lock contention.
 *
 * Ported from DispatchAdapter() in admin_handler.go.
 */
async function dispatchAdapter(name: string): Promise<void> {
  switch (name) {
    case 'fec': {
      // FEC batch: query all confirmed FEC sources, run runIngestion for each
      const sources = await getConfirmedFecSources();
      if (sources.length === 0) {
        console.warn('[batchIngest/fec] no confirmed FEC sources found');
        return;
      }
      const now = new Date();
      const currentYear = now.getFullYear();
      const cycle = String(currentYear % 2 !== 0 ? currentYear + 1 : currentYear);

      for (const ps of sources) {
        try {
          const adapter = createFecAdapter(cycle);
          await runIngestion(adapter, ps, cycle);
        } catch (err) {
          // Non-aborting: log per-source error, continue to next
          console.error(
            `[batchIngest/fec] source=${ps.id} error: ${err instanceof Error ? err.message : String(err)}`
          );
        }
      }
      break;
    }

    case 'cal-access':
      // Cal-Access adapter not yet ported in Express
      throw new Error('cal-access ingestion not yet implemented in Express port');

    case 'indiana':
      // Indiana adapter not yet ported in Express
      throw new Error('indiana ingestion not yet implemented in Express port');

    case 'socrata':
      // Socrata adapter not yet ported in Express
      throw new Error('socrata ingestion not yet implemented in Express port');

    default:
      throw new Error(`unknown adapter: ${name}`);
  }
}
