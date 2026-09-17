import { describe, it, expect, vi, beforeEach } from 'vitest';

// auth.ts imports db/supabase/authService/etc. at module scope — mock them so env
// validation does not process.exit in test (mirrors auth.workos.test.ts / seasonsAdmin.test.ts).
vi.mock('express-rate-limit', () => ({
  default: () => (_req: unknown, _res: unknown, next: () => void) => next(),
}));
vi.mock('../lib/db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, supabaseAuth: {}, adminRpc: vi.fn() }));
vi.mock('../lib/env.js', () => ({
  env: { NODE_ENV: 'test', COOKIE_DOMAIN: '', AUTHKIT_PRIMARY: 'true', LOGIN_URL: 'https://login.empowered.vote' },
}));
vi.mock('../lib/authService.js', () => ({
  signUpWithEmail: vi.fn(), signInWithEmail: vi.fn(), signOutUser: vi.fn(), recordLogout: vi.fn(),
}));
vi.mock('../lib/emailService.js', () => ({ sendEmail: vi.fn() }));
vi.mock('../lib/enrollService.js', () => ({ completeOnboarding: vi.fn() }));
vi.mock('../lib/adminService.js', () => ({ insertAccessRequest: vi.fn() }));
vi.mock('../lib/workosProvisionService.js', () => ({ provisionWorkosUser: vi.fn(), signUpWorkosFirst: vi.fn() }));
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
  verifyWorkosAccessToken: vi.fn(),
}));
vi.mock('../lib/workosAuthService.js', () => ({
  authenticateWithPassword: vi.fn(),
  authenticateWithEmailCode: vi.fn(),
  refreshWorkosSession: vi.fn(),
  sendWorkosPasswordReset: vi.fn(),
  confirmWorkosPasswordReset: vi.fn(),
}));

const isEnabled = vi.hoisted(() => vi.fn());
const upsertSeal = vi.hoisted(() => vi.fn());
vi.mock('../lib/idVault.js', () => ({ isVaultEnabled: isEnabled, upsertSeal }));

// A tiny extracted helper keeps this unit-testable without booting Express.
import { resolveSignupLegalName } from './auth.js';

describe('signup name routing', () => {
  beforeEach(() => { isEnabled.mockReset(); upsertSeal.mockReset(); });

  it('vault ON: seals the name and passes NULL to the RPC', async () => {
    isEnabled.mockReturnValue(true);
    const rpcName = await resolveSignupLegalName('user-1', 'Ada Lovelace');
    expect(upsertSeal).toHaveBeenCalledWith('user-1', { name: 'Ada Lovelace' });
    expect(rpcName).toBeNull();
  });

  it('vault OFF: passes the real name to the RPC and seals nothing', async () => {
    isEnabled.mockReturnValue(false);
    const rpcName = await resolveSignupLegalName('user-1', 'Ada Lovelace');
    expect(upsertSeal).not.toHaveBeenCalled();
    expect(rpcName).toBe('Ada Lovelace');
  });
});
