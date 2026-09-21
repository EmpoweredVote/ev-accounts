import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
// connect.ts pulls supabase.js, db.js, connectService.js and the auth middleware at module
// scope. Without these, supabase.js's env validation calls process.exit(1) under vitest.
// Follows the admin.test.ts convention.

const { adminRpcMock, poolQueryMock, geocodeMock, getLocationConsentMock } = vi.hoisted(() => ({
  adminRpcMock: vi.fn(),
  poolQueryMock: vi.fn(),
  geocodeMock: vi.fn(),
  getLocationConsentMock: vi.fn(),
}));

vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: adminRpcMock }));
vi.mock('../lib/db.js', () => ({ pool: { query: poolQueryMock } }));
vi.mock('../lib/geocodingService.js', () => ({
  geocodeAddress: geocodeMock,
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
  getLocationConsent: getLocationConsentMock,
  getConnectedProfile: vi.fn(),
  upsertConnectedProfile: vi.fn(),
  setLocationConsent: vi.fn(),
  getDistrictAssignments: vi.fn(),
  completeConnectFlow: vi.fn(),
  getPeerRequests: vi.fn(),
  createPeerRequest: vi.fn(),
  respondToPeerRequest: vi.fn(),
  getConnections: vi.fn(),
}));
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: { userId?: string }, _res: unknown, next: () => void) => {
    req.userId = 'user-1';
    next();
  },
}));
vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
}));
vi.mock('../middleware/tierGuards.js', () => ({
  requireConnected: (_req: unknown, _res: unknown, next: () => void) => next(),
  requireEmpowered: (_req: unknown, _res: unknown, next: () => void) => next(),
}));
// idVault.js pulls env.js/db.js at module scope too (see connect.idVault.test.ts). Default
// OFF here — this file exercises set-location's geocoding/district behaviour, not sealing.
vi.mock('../lib/idVault.js', () => ({ isVaultEnabled: () => false, upsertSeal: vi.fn() }));

import connectRouter from './connect.js';

const app = express();
app.use(express.json());
app.use('/api/connect', connectRouter);

/** Every district key the RPC returns, all NULL — what an unresolved point produces. */
const RESOLVED_NOTHING = {
  congressional: null,
  congressional_name: null,
  state_senate: null,
  state_senate_name: null,
  state_house: null,
  state_house_name: null,
  county: null,
  county_name: null,
  school_district: null,
  school_district_name: null,
  city_council: null,
  city_council_name: null,
  municipality: null,
};

let warnSpy: ReturnType<typeof vi.spyOn>;

beforeEach(() => {
  adminRpcMock.mockReset();
  poolQueryMock.mockReset();
  geocodeMock.mockReset();
  getLocationConsentMock.mockReset();

  geocodeMock.mockResolvedValue({ lat: 44.05, lng: -121.31, state: 'OR', city: 'Bend' });
  getLocationConsentMock.mockResolvedValue(false);
  poolQueryMock.mockResolvedValue({ rows: [], rowCount: 0 });
  warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
});

afterEach(() => {
  warnSpy.mockRestore();
});

/** upsert_user_location succeeds; resolve_user_jurisdiction returns `payload`. */
function withJurisdiction(payload: unknown) {
  adminRpcMock.mockImplementation((fn: string) => {
    if (fn === 'upsert_user_location') return Promise.resolve({ data: null, error: null });
    if (fn === 'resolve_user_jurisdiction') return Promise.resolve({ data: payload, error: null });
    return Promise.resolve({ data: null, error: null });
  });
}

function post() {
  return request(app)
    .post('/api/connect/set-location')
    .send({ address: '123 Main St, Bend, OR 97701', force: true });
}

// ---------------------------------------------------------------------------

describe('set-location — an unresolved address must not pass silently', () => {
  // The address CHANGED, so the stored districts belong to the old point and writing the
  // new nulls is correct. What was missing is any signal: the error branch only fires on a
  // real error, and resolve_user_jurisdiction raises none when it resolves nothing. So a
  // broken geo_id/mtfcc join gave every new user empty districts with nothing logged.

  it('warns when the RPC resolves no district at all', async () => {
    withJurisdiction(RESOLVED_NOTHING);

    const res = await post();

    expect(res.status).toBe(200);
    expect(warnSpy.mock.calls.flat().join(' ')).toContain('UNRESOLVED');
  });

  it('still writes the new jurisdiction, nulls included', async () => {
    // Not a wipe: the old districts are for the old address. This must keep happening.
    withJurisdiction(RESOLVED_NOTHING);

    await post();

    const updates = poolQueryMock.mock.calls
      .map((c) => (typeof c[0] === 'string' ? c[0] : ''))
      .filter((sql) => sql.includes('UPDATE connect.connected_profiles'));
    expect(updates).toHaveLength(1);
  });

  it('does not warn when the address resolves normally', async () => {
    withJurisdiction({
      ...RESOLVED_NOTHING,
      congressional: 'cd-5',
      congressional_name: 'Oregon 5th',
      county: 'county-deschutes',
    });

    const res = await post();

    expect(res.status).toBe(200);
    expect(warnSpy.mock.calls.flat().join(' ')).not.toContain('UNRESOLVED');
  });
});
