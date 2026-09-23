import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// connect.ts pulls supabase.js, db.js, connectService.js and the auth middleware at module
// scope; their env validation calls process.exit(1) under vitest. Mirrors
// connect.idVault.test.ts.
const { adminRpc, poolQuery, importCompassCalibrations } = vi.hoisted(() => ({
  adminRpc: vi.fn(),
  poolQuery: vi.fn(),
  importCompassCalibrations: vi.fn(),
}));
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc }));
vi.mock('../lib/db.js', () => ({ pool: { query: poolQuery } }));
vi.mock('../lib/geocodingService.js', () => ({
  geocodeAddress: vi.fn(),
  GeocodingError: class GeocodingError extends Error {},
}));
vi.mock('../lib/inviteService.js', () => ({ claimInviteCode: vi.fn() }));
vi.mock('../lib/connectService.js', () => ({
  getLocationConsent: vi.fn(),
  getEnrollmentDrafts: vi.fn(),
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
  importCompassCalibrations,
}));
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: { userId?: string; accessToken?: string }, _res: unknown, next: () => void) => {
    req.userId = 'user-1';
    req.accessToken = 'token-1';
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
vi.mock('../lib/idVault.js', () => ({ isVaultEnabled: vi.fn(), upsertSeal: vi.fn() }));

import connectRouter from './connect.js';

const app = express();
app.use(express.json());
app.use('/api/connect', connectRouter);

const TOPIC = '11111111-1111-4111-8111-111111111111';
const STANCE = '22222222-2222-4222-8222-222222222222';

beforeEach(() => {
  adminRpc.mockReset();
  poolQuery.mockReset();
  importCompassCalibrations.mockReset();
});

// 🔴 THE LEGACY stance_id IMPORT IS GONE. It validated against
// compass_topics.is_live and the frozen compass_topics.version — wrong on the 17
// Season 2 topics that are is_live = false and on 25 of the 60 the season asks —
// and parked the calibration as a draft for GET /compass/answers to promote later.
// No client called it: 0 requests in the 14 days of Render logs retained on
// 2026-09-23, 0 verification sessions and 0 drafts on prod.
describe('POST /api/connect/compass-import — value-bearing calibrations only', () => {
  it('refuses a stance_id-only calibration instead of parking a draft', async () => {
    const res = await request(app).post('/api/connect/compass-import').send({
      calibrations: [{ topic_id: TOPIC, topic_version: 1, stance_id: STANCE }],
      confirmed: true,
    });

    expect(res.status).toBe(422);
    expect(res.body.code).toBe('VALIDATION_ERROR');
    expect(importCompassCalibrations).not.toHaveBeenCalled();
    expect(poolQuery).not.toHaveBeenCalled();
  });

  it('refuses an empty import, which used to fall through to the draft path', async () => {
    const res = await request(app).post('/api/connect/compass-import').send({
      calibrations: [], confirmed: true,
    });

    expect(res.status).toBe(422);
    expect(importCompassCalibrations).not.toHaveBeenCalled();
  });

  // Phase 1 only ever validated legacy rows. For value-bearing rows it always
  // answered "nothing to check, ready" — and must keep answering exactly that,
  // without reading anything.
  it('confirmed:false keeps its old answer for value-bearing rows and reads nothing', async () => {
    const res = await request(app).post('/api/connect/compass-import').send({
      calibrations: [{ topic_id: TOPIC, topic_version: 1, value: 3 }],
    });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ valid: [], mismatched: [], ready_to_import: true });
    expect(poolQuery).not.toHaveBeenCalled();
    expect(adminRpc).not.toHaveBeenCalled();
    expect(importCompassCalibrations).not.toHaveBeenCalled();
  });

  it('confirmed:true imports the values directly', async () => {
    importCompassCalibrations.mockResolvedValue({ imported: 1, onboarding_complete: false });

    const res = await request(app).post('/api/connect/compass-import').send({
      calibrations: [{ topic_id: TOPIC, topic_version: 1, value: 4, inverted: true }],
      confirmed: true,
    });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ imported: true, count: 1, onboarding_complete: false });
    expect(importCompassCalibrations).toHaveBeenCalledWith({
      userId: 'user-1',
      accessToken: 'token-1',
      calibrations: [{ topic_id: TOPIC, value: 4, inverted: true }],
      selectedTopics: undefined,
    });
  });
});
