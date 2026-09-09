import { Request, Response, NextFunction } from 'express';
import { env } from '../lib/env.js';

export interface ServiceKeyRequest extends Request {
  permittedSources: string[];
}

// Built at module load time — env vars resolved once at startup.
// Keys are env var values; values are arrays of permitted source types.
// If an env var is undefined/empty, it is not added to the map.
const SERVICE_KEY_MAP: Record<string, string[]> = {};
if (env.TRIVIA_SERVICE_KEY) {
  SERVICE_KEY_MAP[env.TRIVIA_SERVICE_KEY] = ['civic_trivia_championship_score'];
}
if (env.ADMIN_SERVICE_KEY) {
  SERVICE_KEY_MAP[env.ADMIN_SERVICE_KEY] = ['admin_gift'];
}
if (env.LISTENING_XP_KEY) {
  SERVICE_KEY_MAP[env.LISTENING_XP_KEY] = ['empowered_listening_session'];
  }
if (env.ESSENTIALS_SERVICE_KEY) {
  SERVICE_KEY_MAP[env.ESSENTIALS_SERVICE_KEY] = ['essentials-rep-lookup'];
}

/**
 * requireServiceKey — validate X-Service-Key header and attach permitted sources.
 * Returns 401 for missing or unrecognized key (matches requireAuth pattern).
 * After this middleware, (req as ServiceKeyRequest).permittedSources contains
 * the list of source types this key is authorized to use.
 */
export function requireServiceKey(req: Request, res: Response, next: NextFunction): void {
  const key = req.headers['x-service-key'] as string | undefined;
  if (!key || !SERVICE_KEY_MAP[key]) {
    res.status(401).json({ error: 'Missing or invalid X-Service-Key' });
    return;
  }
  (req as ServiceKeyRequest).permittedSources = SERVICE_KEY_MAP[key];
  next();
}
