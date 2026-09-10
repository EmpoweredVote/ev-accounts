import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * Regression guard for the 2026-09-10 compass-write outage.
 *
 * Session-establishing GoTrue calls MUST run on supabaseAuth, never on
 * supabaseAdmin: supabase-js stores the returned session on the calling client
 * and then sends that user's token as `Authorization` on every subsequent
 * PostgREST request. On supabaseAdmin that turned every adminRpc() after a login
 * into an `authenticated`-role call, which is denied EXECUTE on the service-role
 * write RPCs. If someone moves these back to supabaseAdmin, this test fails.
 */

const { adminAuth, authClientAuth } = vi.hoisted(() => ({
  adminAuth: { signInWithPassword: vi.fn(), signUp: vi.fn() },
  authClientAuth: { signInWithPassword: vi.fn(), signUp: vi.fn() },
}));

vi.mock('./supabase.js', () => ({
  supabaseAdmin: { auth: adminAuth },
  supabaseAuth: { auth: authClientAuth },
}));
vi.mock('./cache.js', () => ({ cache: { get: vi.fn(), set: vi.fn() } }));
vi.mock('./tokenIdentity.js', () => ({ classifyToken: vi.fn(() => 'supabase') }));

import { signInWithEmail, signUpWithEmail } from './authService.js';

describe('auth session ops run off supabaseAdmin (2026-09-10 outage)', () => {
  beforeEach(() => vi.clearAllMocks());

  it('signInWithEmail uses supabaseAuth, not supabaseAdmin', async () => {
    authClientAuth.signInWithPassword.mockResolvedValue({ data: {}, error: null });
    await signInWithEmail('user@example.com', 'password');
    expect(authClientAuth.signInWithPassword).toHaveBeenCalledTimes(1);
    expect(adminAuth.signInWithPassword).not.toHaveBeenCalled();
  });

  it('signUpWithEmail uses supabaseAuth, not supabaseAdmin', async () => {
    authClientAuth.signUp.mockResolvedValue({ data: {}, error: null });
    await signUpWithEmail('user@example.com', 'password');
    expect(authClientAuth.signUp).toHaveBeenCalledTimes(1);
    expect(adminAuth.signUp).not.toHaveBeenCalled();
  });
});
