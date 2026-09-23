import { describe, it, expect, vi, beforeEach } from 'vitest';

// connect.ts pulls supabase.js, db.js, connectService.js and the auth middleware at module
// scope. Without these, supabase.js's/db.js's env validation calls process.exit(1) under
// vitest. Mirrors connect.setLocation.test.ts / auth.idVault.test.ts.
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: vi.fn() }));
vi.mock('../lib/db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('../lib/geocodingService.js', () => ({
  geocodeAddress: vi.fn(),
  GeocodingError: class GeocodingError extends Error {
    code: string;
    constructor(code: string, message: string) {
      super(message);
      this.code = code;
    }
  },
}));
vi.mock('../lib/inviteService.js', () => ({ claimInviteCode: vi.fn() }));
const getEnrollmentDrafts = vi.hoisted(() => vi.fn());
vi.mock('../lib/connectService.js', () => ({
  getLocationConsent: vi.fn(),
  getEnrollmentDrafts,
  getConnectedProfile: vi.fn(),
  upsertConnectedProfile: vi.fn(),
  setLocationConsent: vi.fn(),
  getDistrictAssignments: vi.fn(),
  completeConnectFlow: vi.fn(),
  getPeerRequests: vi.fn(),
  createPeerRequest: vi.fn(),
  respondToPeerRequest: vi.fn(),
  getConnections: vi.fn(),
  hasConnectedProfile: vi.fn(),
  getConnectedProfileVerificationStatus: vi.fn(),
  getVerificationSession: vi.fn(),
  getVerificationSessionStep: vi.fn(),
  upsertVerificationSession: vi.fn(),
  updateVerificationSession: vi.fn(),
  importCompassCalibrations: vi.fn(),
}));
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));
vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
}));
vi.mock('../middleware/tierGuards.js', () => ({
  requireConnected: (_req: unknown, _res: unknown, next: () => void) => next(),
  requireEmpowered: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

const isEnabled = vi.hoisted(() => vi.fn());
const upsertSeal = vi.hoisted(() => vi.fn());
vi.mock('../lib/idVault.js', () => ({ isVaultEnabled: isEnabled, upsertSeal }));

import { sealAddressIfEnabled, resolveCompleteConnectSeal } from './connect.js';

describe('set-location address sealing', () => {
  beforeEach(() => { isEnabled.mockReset(); upsertSeal.mockReset(); });

  it('vault ON: seals the raw address', async () => {
    isEnabled.mockReturnValue(true);
    await sealAddressIfEnabled('user-1', '742 Evergreen Terrace');
    expect(upsertSeal).toHaveBeenCalledWith('user-1', { address: '742 Evergreen Terrace' });
  });

  it('vault OFF: seals nothing', async () => {
    isEnabled.mockReturnValue(false);
    await sealAddressIfEnabled('user-1', '742 Evergreen Terrace');
    expect(upsertSeal).not.toHaveBeenCalled();
  });
});

// POST /complete seal parity (CA_0120, spec §4.4): before this fix, /complete
// called complete_connect_flow with only p_user_id, and the RPC wrote the
// plaintext legal_name_draft (and left home_address_draft plaintext) in
// connect.verification_sessions regardless of the vault. resolveCompleteConnectSeal
// is the extracted seal-first-then-flag decision the route now calls before the
// RPC — mirrors resolveSignupLegalName in auth.ts, broadened to seal both drafts.
describe('POST /complete draft sealing (resolveCompleteConnectSeal)', () => {
  beforeEach(() => {
    isEnabled.mockReset();
    upsertSeal.mockReset();
    getEnrollmentDrafts.mockReset();
  });

  it('vault ON with both drafts: reads them once, seals name+address in a single upsert, flags the RPC', async () => {
    isEnabled.mockReturnValue(true);
    getEnrollmentDrafts.mockResolvedValue({ legalName: 'Ada Lovelace', homeAddress: '742 Evergreen Terrace' });

    const sealName = await resolveCompleteConnectSeal('user-1');

    expect(getEnrollmentDrafts).toHaveBeenCalledWith('user-1');
    expect(upsertSeal).toHaveBeenCalledTimes(1);
    expect(upsertSeal).toHaveBeenCalledWith('user-1', { name: 'Ada Lovelace', address: '742 Evergreen Terrace' });
    expect(sealName).toBe(true);
  });

  it('vault ON with only an address draft: seals the address alone, still flags the RPC', async () => {
    isEnabled.mockReturnValue(true);
    getEnrollmentDrafts.mockResolvedValue({ legalName: null, homeAddress: '742 Evergreen Terrace' });

    const sealName = await resolveCompleteConnectSeal('user-1');

    expect(upsertSeal).toHaveBeenCalledWith('user-1', { address: '742 Evergreen Terrace' });
    expect(sealName).toBe(true);
  });

  it('vault ON with no drafts (edge case): does not call upsertSeal, still flags the RPC', async () => {
    isEnabled.mockReturnValue(true);
    getEnrollmentDrafts.mockResolvedValue({ legalName: null, homeAddress: null });

    const sealName = await resolveCompleteConnectSeal('user-1');

    expect(getEnrollmentDrafts).toHaveBeenCalledWith('user-1');
    expect(upsertSeal).not.toHaveBeenCalled();
    expect(sealName).toBe(true);
  });

  it('vault OFF: never reads drafts or seals, and tells the RPC not to null the column', async () => {
    isEnabled.mockReturnValue(false);

    const sealName = await resolveCompleteConnectSeal('user-1');

    expect(getEnrollmentDrafts).not.toHaveBeenCalled();
    expect(upsertSeal).not.toHaveBeenCalled();
    expect(sealName).toBe(false);
  });

  it('vault ON, seal fails: the error propagates (fatal — the RPC never runs, drafts survive)', async () => {
    isEnabled.mockReturnValue(true);
    getEnrollmentDrafts.mockResolvedValue({ legalName: 'Ada Lovelace', homeAddress: '742 Evergreen Terrace' });
    upsertSeal.mockRejectedValue(new Error('seal boom'));

    await expect(resolveCompleteConnectSeal('user-1')).rejects.toThrow('seal boom');
  });
});
