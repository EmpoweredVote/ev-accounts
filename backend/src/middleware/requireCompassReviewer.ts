/**
 * requireCompassReviewer — admit a compass content reviewer, and record in what
 * capacity they were admitted (ADR 0004 §7, §11b).
 *
 * WHY THIS IS NOT JUST requireRole('compass_stance_editor')
 * Two separate authorisation systems exist here and neither subsumes the other:
 *
 *   - `public.user_roles` + `public.roles` — the granular role system that
 *     `requireRole` reads. `compass_stance_editor` lives here.
 *   - `public.admin_users` — a flat membership table that `requireAdmin` reads.
 *
 * An admin is NOT automatically a compass_stance_editor, so requireRole alone
 * locks admins out of a screen that already sits behind the admin-gated UI.
 *
 * 🔴 As of 2026-08-21, `compass_stance_editor` has ZERO live holders. There are
 * four grant rows and every one carries a `revoked_at` (all granted and revoked
 * on 2026-04-06/07, apparently while testing the role system). `get_user_roles`
 * filters revoked grants correctly, so requireRole('compass_stance_editor')
 * currently admits NOBODY. Without the admin branch below this router would be
 * unreachable by every account on the platform.
 *
 * Counting `public.user_roles` rows misleads twice over: rows are not people
 * (one user can hold several), and rows include revoked history. Use
 * `get_user_roles(uid)` or filter `revoked_at IS NULL`. Campaign Manager and
 * Essentials Data Editor are in the same state — worth knowing before assuming
 * any role-gated route has live users.
 *
 * WHY THE CAPACITY IS RECORDED RATHER THAN FLATTENED
 * Approving compass content is an EDITORIAL judgement, not a technical
 * privilege. Admin access is a technical privilege. Collapsing them would make
 * an admin's approval indistinguishable from an editor's in the audit record —
 * and conflating an editorial role with a technical one is precisely the mistake
 * that left migration 061 unused for four months.
 *
 * So both are admitted, and `req.reviewerCapacity` says which. Every route that
 * uses this middleware writes that into its audit `details`, so the record can
 * always answer "was this signed off by someone whose job is the wording, or by
 * someone who merely had the keys?"
 *
 * Order matters: mount AFTER requireAuth, which attaches req.userId.
 */

import type { Request, Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { supabaseAdmin } from '../lib/supabase.js';
import { getCachedUserRoles, checkRole } from '../lib/roleService.js';

/**
 * Which authority admitted this request.
 * `editor` is the intended path; `admin` is the fallback that keeps the workflow
 * usable while the role is granted to the actual reviewers.
 */
export type ReviewerCapacity = 'editor' | 'admin';

export interface ReviewerRequest extends AuthenticatedRequest {
  reviewerCapacity: ReviewerCapacity;
}

export const COMPASS_REVIEWER_ROLE = 'compass_stance_editor';

/** Read the capacity a route was admitted under. Safe to call only after this middleware. */
export function reviewerCapacity(req: Request): ReviewerCapacity {
  return (req as ReviewerRequest).reviewerCapacity ?? 'admin';
}

export async function requireCompassReviewer(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const userId = (req as AuthenticatedRequest).userId;
  if (!userId) {
    res.status(401).json({ error: 'unauthorized' });
    return;
  }

  try {
    // The role is checked FIRST so that someone who holds both is recorded as an
    // editor. Otherwise every admin-editor would be logged as a mere admin and
    // the distinction this middleware exists to preserve would be lost on the
    // people it matters most for.
    const grants = await getCachedUserRoles(userId);
    if (checkRole(grants, COMPASS_REVIEWER_ROLE)) {
      (req as ReviewerRequest).reviewerCapacity = 'editor';
      next();
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('admin_users')
      .select('user_id')
      .eq('user_id', userId)
      .maybeSingle();

    if (!error && data) {
      (req as ReviewerRequest).reviewerCapacity = 'admin';
      next();
      return;
    }

    // Deliberately opaque, matching requireRole: do not tell an unauthorised
    // caller which of the two doors they failed to open.
    res.status(403).json({ error: 'forbidden' });
  } catch (err) {
    console.error('[requireCompassReviewer] error:', err);
    res.status(500).json({ error: 'internal server error' });
  }
}
