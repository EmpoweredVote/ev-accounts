import { Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { supabaseAdmin } from '../lib/supabase.js';

/**
 * Blocks unverified-email users from write endpoints.
 * Must be used AFTER requireAuth middleware.
 *
 * Uses supabaseAdmin.auth.admin.getUserById — a trusted server-side check,
 * not a data read for the response body. Same pattern as middleware/auth.ts.
 *
 * Architecture note: supabaseAdmin is permitted in src/middleware/ by design.
 * The architecture enforcement test allowlist includes this file.
 */
export async function requireVerified(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const {
      data: { user },
      error,
    } = await supabaseAdmin.auth.admin.getUserById(req.userId);

    if (error || !user?.email_confirmed_at) {
      res.status(403).json({
        code: 'EMAIL_NOT_VERIFIED',
        message: 'Email verification required for this action',
      });
      return;
    }

    next();
  } catch {
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    });
  }
}
