import { describe, it, expect, vi } from 'vitest';

/**
 * The 2026-09-10 compass-write outage: signInWithPassword ran on the shared
 * supabaseAdmin client, so supabase-js stored the user's session on it and every
 * later adminRpc() authenticated as that user (role `authenticated`) instead of
 * service_role -> "permission denied for function upsert_compass_answer".
 *
 * The fix is a SEPARATE `supabaseAuth` client that carries the session, keeping
 * supabaseAdmin session-free. This test pins that supabase.ts really builds a
 * distinct client (not an alias of supabaseAdmin) with the service key.
 */

vi.mock('@supabase/supabase-js', () => ({
  // Each createClient call returns a fresh, tagged object so we can tell the
  // admin and auth clients apart and read the key each was built with.
  createClient: vi.fn((url: string, key: string) => ({ __url: url, __key: key })),
}));

vi.mock('./env.js', () => ({
  env: {
    SUPABASE_URL: 'https://example.supabase.co',
    SUPABASE_SERVICE_ROLE_KEY: 'sb_secret_TESTSERVICE',
    SUPABASE_ANON_KEY: 'sb_anon_TEST',
    SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_TEST',
  },
}));

import { supabaseAdmin, supabaseAuth } from './supabase.js';

describe('supabaseAuth session isolation (2026-09-10 outage)', () => {
  it('is a distinct client instance from supabaseAdmin', () => {
    // If these were the same object, a sign-in on supabaseAuth would still
    // pollute supabaseAdmin's session — the exact bug this separation fixes.
    expect(supabaseAuth).not.toBe(supabaseAdmin);
  });

  it('authenticates with the service role key', () => {
    expect((supabaseAuth as unknown as { __key: string }).__key).toBe('sb_secret_TESTSERVICE');
    expect((supabaseAdmin as unknown as { __key: string }).__key).toBe('sb_secret_TESTSERVICE');
  });
});
