import type { Request, Response, NextFunction } from 'express';
import { cache } from '../../lib/cache.js';

// Read-through response cache, unchanged from the standalone except for the store: the
// standalone had its own Upstash client + in-memory fallback (src/lib/redis.ts); the engine's
// shared `cache` (src/lib/cache.ts) already is exactly that, with a bounded fallback. Keys keep
// the `fc:` prefix and the same shape — req.path is relative to the mount point here just as
// it was under the standalone's '/api' mount — so the invalidation keys in the routes match.

export const TTL = {
  COMMUNITIES: 5 * 60,    // 5 minutes
  STANCES: 30 * 60,       // 30 minutes
  THREAD_LIST: 30,        // 30 seconds
  THREAD_DETAIL: 30,      // 30 seconds
} as const;

export function cacheMiddleware(ttlSeconds: number) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const key = `fc:${req.path}:${JSON.stringify(req.query)}`;
    const cached = await cache.get<unknown>(key);
    if (cached !== null) {
      res.json(cached);
      return;
    }
    const originalJson = res.json.bind(res);
    res.json = ((body: unknown) => {
      if (!res.headersSent && res.statusCode >= 200 && res.statusCode < 300) {
        cache.set(key, body, ttlSeconds).catch(() => {});
      }
      return originalJson(body);
    }) as Response['json'];
    next();
  };
}

/** Best-effort multi-key delete (the engine cache deletes one key at a time). */
export async function cacheDel(...keys: string[]): Promise<void> {
  await Promise.all(keys.map((k) => cache.del(k).catch(() => {})));
}
