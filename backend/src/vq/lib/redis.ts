import { Redis } from '@upstash/redis';

const upstash = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});

// In-memory fallback when Upstash is unavailable
const memCache = new Map<string, { data: string; expires: number }>();
let redisAvailable = true;

// Periodic probe: attempt reconnect every 60 seconds if degraded
setInterval(async () => {
  if (!redisAvailable) {
    try {
      await upstash.ping();
      redisAvailable = true;
    } catch {
      // Still unavailable — remain in fallback mode
    }
  }
}, 60_000);

export const redis = {
  async get(key: string): Promise<string | null> {
    if (redisAvailable) {
      try {
        return await upstash.get<string>(key);
      } catch {
        redisAvailable = false;
        // Fall through to memCache
      }
    }
    const entry = memCache.get(key);
    if (!entry || entry.expires < Date.now()) return null;
    return entry.data;
  },

  async set(key: string, value: string, ex?: number): Promise<void> {
    if (redisAvailable) {
      try {
        if (ex) {
          await upstash.set(key, value, { ex });
        } else {
          await upstash.set(key, value);
        }
        return;
      } catch {
        redisAvailable = false;
        // Fall through to memCache
      }
    }
    const expires = ex ? Date.now() + ex * 1000 : Infinity;
    memCache.set(key, { data: value, expires });
  },

  async del(key: string): Promise<void> {
    if (redisAvailable) {
      try {
        await upstash.del(key);
        return;
      } catch {
        redisAvailable = false;
        // Fall through to memCache
      }
    }
    memCache.delete(key);
  },

  async scanDel(pattern: string): Promise<number> {
    if (redisAvailable) {
      try {
        let cursor = '0';
        let deleted = 0;
        do {
          const [nextCursor, keys] = await upstash.scan(cursor, { match: pattern });
          if (keys.length > 0) {
            await upstash.del(...(keys as [string, ...string[]]));
            deleted += keys.length;
          }
          cursor = String(nextCursor);
        } while (cursor !== '0');
        return deleted;
      } catch {
        redisAvailable = false;
        // Fall through to memCache
      }
    }
    // memCache fallback: delete keys that start with the non-glob prefix
    const prefix = pattern.endsWith('*') ? pattern.slice(0, -1) : pattern;
    let deleted = 0;
    for (const key of memCache.keys()) {
      if (key.startsWith(prefix)) {
        memCache.delete(key);
        deleted++;
      }
    }
    return deleted;
  },

  isAvailable(): boolean {
    return redisAvailable;
  },
};
