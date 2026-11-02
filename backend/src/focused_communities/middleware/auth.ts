import type { Request, Response, NextFunction } from 'express';
import { requireAuth as engineRequireAuth, type AuthenticatedRequest } from '../../middleware/auth.js';
import { getAccountMe } from '../../lib/accountMeService.js';

// Auth for the folded Focused Communities routes.
//
// The standalone verified the token itself (its own dual-issuer copy) and then called
// GET /api/account/me over HTTP. Here the engine's single verifier, requireAuth, does the
// first half — and also enforces revocation, deletion and suspension, which the standalone
// did not — and getAccountMe (the builder that route calls) does the second half in-process.
// Same pattern as src/civic_spaces/services/accountsApi.ts. The standalone's verifier is
// deliberately NOT vendored: one dual-issuer verifier per process.

export interface AccountUser {
  id: string;
  tier: 'inform' | 'connected' | 'empowered';
  account_standing: 'active' | 'suspended';
  completed_onboarding: boolean;
  display_name: string;
  /**
   * When the public.users row was created. getAccountMe already returns it and loadUser
   * spreads the whole composite onto req.user, so this is a field that was always there
   * and merely undeclared — not a new query.
   *
   * It is here for ONE reason: routes/claimWrites.ts snapshots the rater's account age
   * onto connect.claim_ratings at rating time. That is a property of the rater AT THE
   * MOMENT OF RATING and cannot be recovered afterwards, so it has to be written then or
   * never. Optional, because this interface is a narrowing of a composite assembled from
   * several tables and a caller must not assume any of it is present.
   */
  created_at?: string | null;
  /**
   * The connected-tier child record, when there is one. Present only for connected and
   * empowered accounts — an Inform-tier caller has no row and no verification status.
   * Here for the same reason as created_at: the rating snapshot.
   */
  connected_profile?: { verification_status?: string | null } | null;
}

export type FcRequest = Request & { user?: AccountUser };

/**
 * requireAuth, plus one compatibility shim: the engine answers a suspended account with
 * 403 { error: 'Account suspended' }, and the Focused Communities frontend shows its
 * "suspended" notice only when the body also carries reason: 'suspended' (which the
 * standalone's requireConnected sent). Add the reason so that notice still appears.
 */
function requireEngineAuth(req: Request, res: Response, next: NextFunction): Promise<void> {
  const originalJson = res.json.bind(res);
  res.json = ((body: unknown) => {
    if (
      res.statusCode === 403 &&
      body !== null &&
      typeof body === 'object' &&
      (body as { error?: unknown }).error === 'Account suspended'
    ) {
      return originalJson({ ...(body as object), reason: 'suspended' });
    }
    return originalJson(body);
  }) as Response['json'];
  return engineRequireAuth(req, res, () => {
    res.json = originalJson;
    next();
  });
}

async function loadUser(req: Request, res: Response, next: NextFunction): Promise<void> {
  const { userId, accessToken } = req as AuthenticatedRequest;
  try {
    const me = (await getAccountMe(accessToken, userId)) as unknown as AccountUser;
    (req as FcRequest).user = { ...me, id: userId };
  } catch (err) {
    // AUTH_ERROR = the identity behind the token cannot be confirmed: the same 401 the
    // standalone sent when /api/account/me answered 401. Anything else is our failure.
    console.error('[focused_communities] getAccountMe failed:', (err as Error).message);
    if ((err as { code?: string }).code === 'AUTH_ERROR') {
      res.status(401).json({ error: 'Session expired or revoked' });
    } else {
      res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' } });
    }
    return;
  }
  res.setHeader('Cache-Control', 'private, no-store');
  next();
}

/** Valid token + live account, with the account composite on req.user. */
export const requireAuth = [requireEngineAuth, loadUser];
