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
vi.mock('../lib/connectService.js', () => ({
  getLocationConsent: vi.fn(),
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
  getVerificationSessionId: vi.fn(),
  upsertVerificationSession: vi.fn(),
  updateVerificationSession: vi.fn(),
  validateCompassVersions: vi.fn(),
  saveCompassImportDraft: vi.fn(),
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

import { sealAddressIfEnabled } from './connect.js';

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
