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
