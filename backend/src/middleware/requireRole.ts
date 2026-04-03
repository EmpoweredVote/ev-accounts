/**
 * requireRole — middleware factory for role-based access control.
 *
 * Returns an Express middleware that checks whether the authenticated user
 * holds the specified role (with optional scope constraints) before allowing
 * the request to proceed.
 *
 * Usage:
 *   router.post('/sensitive', requireRole('editor'), handler);
 *   router.post('/local', requireRole('volunteer', { geoid: (req) => req.params.geoid }), handler);
 *
 * Error responses are intentionally opaque:
 *   401 { error: 'unauthorized' } — no user session attached
 *   403 { error: 'forbidden' }   — session present but role check failed
 *   500 { error: 'internal server error' } — unexpected error
 *
 * This middleware is safe to stack without requireAuth — it performs its own
 * auth check on `req.userId`. However, requireAuth is recommended in front of
 * this middleware to provide consistent 401 handling with more descriptive
 * messages (e.g., "Missing authorization header").
 */

import type { Request, Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { getCachedUserRoles, checkRole } from '../lib/roleService.js';

export function requireRole(
  roleSlug: string | string[],
  opts?: {
    geoid?: string | ((req: Request) => string | undefined);
    resourceId?: string | ((req: Request) => string | undefined);
  }
): (req: Request, res: Response, next: NextFunction) => Promise<void> {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = (req as AuthenticatedRequest).userId;
      if (!userId) {
        res.status(401).json({ error: 'unauthorized' });
        return;
      }

      // Resolve geoid — may be a static string, a request-derived function, or undefined
      const resolvedGeoid =
        typeof opts?.geoid === 'function'
          ? opts.geoid(req)
          : opts?.geoid;

      // Resolve resourceId — same pattern
      const resolvedResourceId =
        typeof opts?.resourceId === 'function'
          ? opts.resourceId(req)
          : opts?.resourceId;

      // Build scope — only include defined values
      const scope: { geoid?: string; resourceId?: string } = {};
      if (resolvedGeoid !== undefined) scope.geoid = resolvedGeoid;
      if (resolvedResourceId !== undefined) scope.resourceId = resolvedResourceId;

      const grants = await getCachedUserRoles(userId);

      const permitted = checkRole(
        grants,
        roleSlug,
        Object.keys(scope).length > 0 ? scope : undefined
      );

      if (!permitted) {
        res.status(403).json({ error: 'forbidden' });
        return;
      }

      next();
    } catch (err) {
      console.error('[requireRole] error:', err);
      res.status(500).json({ error: 'internal server error' });
    }
  };
}
