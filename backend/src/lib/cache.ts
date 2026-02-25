import { Redis } from '@upstash/redis';
import { env } from './env.js';

interface CacheClient {
  get<T>(key: string): Promise<T | null>;
  set(key: string, value: unknown, ttlSeconds?: number): Promise<void>;
  del(key: string): Promise<void>;
}

class InMemoryFallback implements CacheClient {
  private store = new Map<string, { value: unknown; expiresAt: number | null }>();

  async get<T>(key: string): Promise<T | null> {
    const entry = this.store.get(key);
    if (!entry) return null;
    if (entry.expiresAt && Date.now() > entry.expiresAt) {
      this.store.delete(key);
      return null;
    }
    return entry.value as T;
  }

  async set(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
    this.store.set(key, {
      value,
      expiresAt: ttlSeconds ? Date.now() + ttlSeconds * 1000 : null,
    });
  }

  async del(key: string): Promise<void> {
    this.store.delete(key);
  }
}

function createCache(): CacheClient {
  if (!env.REDIS_URL) {
    console.warn('[cache] REDIS_URL not set — using in-memory fallback');
    return new InMemoryFallback();
  }
  try {
    const redis = new Redis({ url: env.REDIS_URL });
    return {
      async get<T>(key: string): Promise<T | null> {
        return redis.get<T>(key);
      },
      async set(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
        if (ttlSeconds) {
          await redis.set(key, value, { ex: ttlSeconds });
        } else {
          await redis.set(key, value);
        }
      },
      async del(key: string): Promise<void> {
        await redis.del(key);
      },
    };
  } catch {
    console.warn('[cache] Redis init failed — using in-memory fallback');
    return new InMemoryFallback();
  }
}

export const cache = createCache();
