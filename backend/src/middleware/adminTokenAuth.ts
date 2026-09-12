/**
 * adminTokenAuth — X-Admin-Token middleware for batch ingest endpoint.
 *
 * Purpose: Authenticates requests to POST /admin/ingest/:adapter and
 * POST /internal/jobs/:name using a pre-shared token in the X-Admin-Token
 * header. This is separate from the JWT requireAuth/requireAdmin middleware —
 * it is used on the machine-callable routes (batch ingest, and the job/API
 * split Move 2 job trigger) that must be callable by SQS workers, EventBridge,
 * Supabase Cron, and curl without a user session.
 *
 * Security: If ADMIN_INGEST_TOKEN is not set in the environment, ALL requests
 * are rejected (returns 401). The endpoint is never silently open.
 *
 * Ported from: EV-Backend/internal/campaign_finance/admin_handler.go
 * (token auth logic at the top of AdminIngestHandler)
 */

import { Request, Response, NextFunction } from 'express';

/**
 * requireAdminToken middleware.
 *
 * Reads X-Admin-Token from request headers and compares against the
 * ADMIN_INGEST_TOKEN environment variable.
 *
 * Returns 401 if:
 *   - ADMIN_INGEST_TOKEN is not set (admin endpoint not configured)
 *   - X-Admin-Token header is missing
 *   - X-Admin-Token value does not match ADMIN_INGEST_TOKEN
 */
export function requireAdminToken(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const expectedToken = process.env.ADMIN_INGEST_TOKEN;

  // If the env var is not set, the endpoint is not configured — always reject.
  // Never silently pass through (would open the endpoint to unauthenticated callers).
  if (!expectedToken) {
    res.status(401).json({ error: 'admin endpoint not configured' });
    return;
  }

  const providedToken = req.headers['x-admin-token'];

  if (!providedToken || providedToken !== expectedToken) {
    res.status(401).json({ error: 'unauthorized' });
    return;
  }

  next();
}
