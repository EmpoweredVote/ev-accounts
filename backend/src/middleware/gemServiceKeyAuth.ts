import { Request, Response, NextFunction } from 'express';
import { env } from '../lib/env.js';

export interface GemServiceKeyRequest extends Request {
  permittedGemTypes: string[];
}

// Parse GEMS_SERVICE_KEYS at module load time.
// Shape: { "ctc-key-abc": ["yellow"], "vq-key-xyz": ["yellow", "red"] }
// If env var absent → empty map → all award requests get 401.
// If env var present but malformed JSON → process.exit(1).
let GEM_SERVICE_KEY_MAP: Record<string, string[]> = {};

if (env.GEMS_SERVICE_KEYS) {
  try {
    const parsed = JSON.parse(env.GEMS_SERVICE_KEYS);
    // Validate structure: each key must map to a non-empty string array
    for (const [key, types] of Object.entries(parsed)) {
      if (!Array.isArray(types) || types.length === 0 || !types.every(t => typeof t === 'string')) {
        console.error(`[startup] GEMS_SERVICE_KEYS: key "${key}" has invalid types — must be non-empty string array`);
        process.exit(1);
      }
      const validTypes = ['yellow', 'blue', 'red'];
      for (const t of types as string[]) {
        if (!validTypes.includes(t)) {
          console.error(`[startup] GEMS_SERVICE_KEYS: key "${key}" has invalid gem type "${t}"`);
          process.exit(1);
        }
      }
    }
    GEM_SERVICE_KEY_MAP = parsed as Record<string, string[]>;
  } catch (e) {
    console.error('[startup] GEMS_SERVICE_KEYS is malformed JSON:', e);
    process.exit(1);
  }
}

/**
 * requireGemServiceKey — validate Bearer token against GEMS_SERVICE_KEYS map.
 *
 * Returns 401 for missing or unrecognized token (uses Authorization: Bearer,
 * not X-Service-Key header — different auth model from requireServiceKey).
 *
 * After this middleware, (req as GemServiceKeyRequest).permittedGemTypes
 * contains the list of gem types this key is authorized to award.
 */
export function requireGemServiceKey(req: Request, res: Response, next: NextFunction): void {
  const token = req.headers['x-service-key'] as string | undefined;

  if (!token || !GEM_SERVICE_KEY_MAP[token]) {
    res.status(401).json({ error: 'Missing or invalid X-Service-Key' });
    return;
  }

  (req as GemServiceKeyRequest).permittedGemTypes = GEM_SERVICE_KEY_MAP[token];
  next();
}
