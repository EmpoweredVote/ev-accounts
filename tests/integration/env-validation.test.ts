import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('env validation', () => {
  beforeEach(() => {
    vi.resetModules();
  });

  it('accepts valid env vars', async () => {
    vi.stubEnv('NODE_ENV', 'test');
    vi.stubEnv('SUPABASE_URL', 'https://test.supabase.co');
    vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key');
    vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', 'test-service-role-key');
    vi.stubEnv('DATABASE_URL', 'postgresql://postgres:password@localhost:5432/postgres');

    const { env } = await import('../../backend/src/lib/env.js');
    expect(env.SUPABASE_URL).toBe('https://test.supabase.co');
  });

  it('exits on missing SUPABASE_URL', async () => {
    vi.stubEnv('SUPABASE_URL', '');
    vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key');
    vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', 'test-service-role-key');
    vi.stubEnv('DATABASE_URL', 'postgresql://postgres:password@localhost:5432/postgres');

    const exitSpy = vi
      .spyOn(process, 'exit')
      .mockImplementation((_code?: number | string | null | undefined): never => {
        throw new Error('process.exit called');
      });

    await expect(import('../../backend/src/lib/env.js')).rejects.toThrow();
    expect(exitSpy).toHaveBeenCalledWith(1);
    exitSpy.mockRestore();
  });

  it('tolerates missing optional REDIS_URL', async () => {
    vi.stubEnv('NODE_ENV', 'test');
    vi.stubEnv('SUPABASE_URL', 'https://test.supabase.co');
    vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key');
    vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', 'test-service-role-key');
    vi.stubEnv('DATABASE_URL', 'postgresql://postgres:password@localhost:5432/postgres');
    // REDIS_URL intentionally not set

    const { env } = await import('../../backend/src/lib/env.js');
    expect(env.REDIS_URL).toBeUndefined();
  });
});
