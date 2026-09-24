import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// admin.ts imports adminService.js (which imports supabase.js + db.js) at module scope,
// plus requireAdmin.js (which also imports supabase.js). Neither is exercised by the
// elections coverage-map branches under test here, but importing admin.ts pulls them
// in transitively and — without these mocks — supabase.js's env.js validation calls
// process.exit(1) in a test environment with no real Supabase/DB env vars configured.
// Mocking db.js/supabase.js here follows the essentialsService.test.ts convention.
vi.mock('../lib/db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: vi.fn() }));

vi.mock('../middleware/auth.js', () => ({
  requireAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));
vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

const { mockGetElectionsStateScores, mockGetElectionsCountyScores, mockGetFederalDelegation } = vi.hoisted(() => ({
  mockGetElectionsStateScores: vi.fn(),
  mockGetElectionsCountyScores: vi.fn(),
  mockGetFederalDelegation: vi.fn(),
}));
vi.mock('../lib/electionsMapService.js', () => ({
  getElectionsStateScores: mockGetElectionsStateScores,
  getElectionsCountyScores: mockGetElectionsCountyScores,
}));
vi.mock('../lib/federalCoverage.js', () => ({
  getFederalDelegation: mockGetFederalDelegation,
}));

// Only resolveResearchReview is exercised below (task 13, R1 — approval input validation); the
// other three are mocked only because admin.ts imports them from the same module.
const { mockResolveResearchReview } = vi.hoisted(() => ({
  mockResolveResearchReview: vi.fn().mockResolvedValue({ ladderRevisionUnknown: false }),
}));
vi.mock('../lib/researchEvidenceService.js', () => ({
  listPendingResearchReview: vi.fn(),
  getResearchReviewById: vi.fn(),
  resolveResearchReview: mockResolveResearchReview,
  rejectResearchReview: vi.fn(),
}));

import adminRouter from './admin.js';

const app = express();
app.use(express.json());
app.use('/api/admin', adminRouter);

beforeEach(() => {
  mockGetElectionsStateScores.mockReset();
  mockGetElectionsCountyScores.mockReset();
  mockGetFederalDelegation.mockReset();
  mockResolveResearchReview.mockClear();
});

// Shared fixture race set — one statewide race (bare-state ocd_id, no county-pinnable
// path) and two county-pinnable races, so the state payload's countyCoverage.races_total
// (2) is internally consistent with what the county drill-down for the same state would
// report (races summed across counties == 2). This encodes the ELEC-03 contract: the
// state's county-pinnable denominator must never contradict the county endpoint's total
// for the same underlying race set.
const STATEWIDE_RACE = {
  race_id: 'r-gov', position_name: 'Governor', seats: 1, candidate_count: 2, ocd_id: 'ocd-division/country:us/state:mi',
};
const COUNTY_RACE_A = {
  race_id: 'r-a', position_name: 'County Clerk A', seats: 1, candidate_count: 1, ocd_id: 'ocd-division/country:us/state:mi/county:washtenaw',
};
const COUNTY_RACE_B = {
  race_id: 'r-b', position_name: 'County Clerk B', seats: 1, candidate_count: 0, ocd_id: 'ocd-division/country:us/state:mi/county:wayne',
};

const stateElection = {
  fips: '26',
  code: 'mi',
  election_date: '2026-11-03',
  election_type: 'general',
  coverage: 100,
  races_total: 1,
  races_covered: 1,
  countyCoverage: { status: 'scored' as const, coverage: 50, races_total: 2, races_covered: 1 },
  statewideRaces: [STATEWIDE_RACE],
};

const countyPayload = {
  state: 'mi',
  state_fips: '26',
  election_date: '2026-11-03',
  election_type: 'general',
  counties: [
    { fips: '26161', name: 'Washtenaw', status: 'scored' as const, coverage: 100, races: [COUNTY_RACE_A] },
    { fips: '26163', name: 'Wayne', status: 'scored' as const, coverage: 0, races: [COUNTY_RACE_B] },
  ],
};

describe('GET /api/admin/coverage/map?metric=elections&level=state', () => {
  it('200 with the exact partitioned StateElection payload, unmodified', async () => {
    mockGetElectionsStateScores.mockResolvedValueOnce([stateElection]);
    const res = await request(app).get('/api/admin/coverage/map?metric=elections&level=state');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ states: [stateElection] });
    expect(mockGetElectionsStateScores).toHaveBeenCalledWith({ refresh: false });
  });
});

describe('GET /api/admin/coverage/map?metric=elections&level=county', () => {
  it('200 with the mocked county drill-down payload, unmodified', async () => {
    mockGetElectionsCountyScores.mockResolvedValueOnce(countyPayload);
    const res = await request(app).get('/api/admin/coverage/map?metric=elections&level=county&state=mi');
    expect(res.status).toBe(200);
    expect(res.body).toEqual(countyPayload);
    expect(mockGetElectionsCountyScores).toHaveBeenCalledWith('mi', { refresh: false });
  });

  it('400 when state param is missing (existing route guard, unchanged)', async () => {
    const res = await request(app).get('/api/admin/coverage/map?metric=elections&level=county');
    expect(res.status).toBe(400);
    expect(mockGetElectionsCountyScores).not.toHaveBeenCalled();
  });
});

describe('GET /api/admin/coverage/federal', () => {
  const member = {
    politician_id: 'p-1',
    full_name: 'Ashley Moody',
    title: 'Senator',
    tier: 'senate',
    district_ocd: 'ocd-division/country:us/state:fl',
    has_photo: true,
    researched: true,
    has_donors: false,
    voting_powers: 'full',
    representation_note: null,
  };

  it('200 with the delegation payload, unmodified, lowercasing the state code', async () => {
    mockGetFederalDelegation.mockResolvedValueOnce([member]);
    const res = await request(app).get('/api/admin/coverage/federal?state=FL');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ state: 'fl', members: [member] });
    expect(mockGetFederalDelegation).toHaveBeenCalledWith('fl');
  });

  it('400 when state param is missing or not a 2-letter code', async () => {
    for (const qs of ['', '?state=', '?state=flx', '?state=f1']) {
      const res = await request(app).get(`/api/admin/coverage/federal${qs}`);
      expect(res.status).toBe(400);
    }
    expect(mockGetFederalDelegation).not.toHaveBeenCalled();
  });
});

describe('ELEC-03: state/county denominator consistency', () => {
  it('the state countyCoverage.races_total matches the sum of the county drill-down races for the same state', async () => {
    mockGetElectionsStateScores.mockResolvedValueOnce([stateElection]);
    mockGetElectionsCountyScores.mockResolvedValueOnce(countyPayload);

    const stateRes = await request(app).get('/api/admin/coverage/map?metric=elections&level=state');
    const countyRes = await request(app).get('/api/admin/coverage/map?metric=elections&level=county&state=mi');

    const mi = stateRes.body.states.find((s: { code: string }) => s.code === 'mi');
    const countyDrilldownTotal = countyRes.body.counties.reduce(
      (sum: number, c: { races: unknown[] }) => sum + c.races.length,
      0,
    );

    // The route performs no aggregation of its own — this assertion proves the two
    // mocked service responses are internally consistent BY CONSTRUCTION (both derived
    // from the same fixture race set), and that the route forwards each number without
    // alteration. A regression in route glue that dropped/duplicated data would break
    // this equality even though each branch's own mock would still report success.
    expect(mi.countyCoverage.races_total).toBe(countyDrilldownTotal);
  });
});

// Task 13, R1: the route rejects a malformed body with 400 before resolveResearchReview ever
// runs — a bad shape must never reach the service (or the DB).
describe('POST /api/admin/research-review/:id/resolve — approval input validation', () => {
  it('400 when humanVerifiedUrls is not an array', async () => {
    const res = await request(app)
      .post('/api/admin/research-review/rev-1/resolve')
      .send({ humanVerifiedUrls: 'https://a.example' });
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/humanVerifiedUrls/);
    expect(mockResolveResearchReview).not.toHaveBeenCalled();
  });

  it('400 when humanVerifiedUrls contains a non-string entry', async () => {
    const res = await request(app)
      .post('/api/admin/research-review/rev-1/resolve')
      .send({ humanVerifiedUrls: ['https://a.example', 5] });
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/humanVerifiedUrls/);
    expect(mockResolveResearchReview).not.toHaveBeenCalled();
  });

  it.each([7, 2.5, 0, -1, '3'])('400 when valueOverride is %j (not absent, null, or an integer 1-5)', async (bad) => {
    const res = await request(app)
      .post('/api/admin/research-review/rev-1/resolve')
      .send({ valueOverride: bad });
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/valueOverride/);
    expect(mockResolveResearchReview).not.toHaveBeenCalled();
  });

  it('400 when reasoningOverride is not a string', async () => {
    const res = await request(app)
      .post('/api/admin/research-review/rev-1/resolve')
      .send({ reasoningOverride: 42 });
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/reasoningOverride/);
    expect(mockResolveResearchReview).not.toHaveBeenCalled();
  });

  it('reaches the service when humanVerifiedUrls is absent and valueOverride is null (both allowed)', async () => {
    const res = await request(app)
      .post('/api/admin/research-review/rev-1/resolve')
      .send({ valueOverride: null });
    expect(res.status).toBe(200);
    expect(mockResolveResearchReview).toHaveBeenCalledTimes(1);
    const call = mockResolveResearchReview.mock.calls[0];
    expect(call[0]).toBe('rev-1');
    expect(call[2]).toEqual([]);
    expect(call[3]).toBe(null);
    expect(call[4]).toBeUndefined();
  });

  it('reaches the service with a valid integer valueOverride 1-5 and a string array', async () => {
    const res = await request(app)
      .post('/api/admin/research-review/rev-1/resolve')
      .send({ humanVerifiedUrls: ['https://a.example'], valueOverride: 3, reasoningOverride: 'why' });
    expect(res.status).toBe(200);
    const call = mockResolveResearchReview.mock.calls[0];
    expect(call[0]).toBe('rev-1');
    expect(call[2]).toEqual(['https://a.example']);
    expect(call[3]).toBe(3);
    expect(call[4]).toBe('why');
  });

  // CA_0264: the ladder check's two outcomes, as the page receives them.
  it('returns ladderRevisionUnknown so the page can flag a legacy row', async () => {
    mockResolveResearchReview.mockResolvedValueOnce({ ladderRevisionUnknown: true });
    const res = await request(app).post('/api/admin/research-review/rev-1/resolve').send({});
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true, ladderRevisionUnknown: true });
  });
  it('409 with the service message when the ladder changed since the row was researched', async () => {
    mockResolveResearchReview.mockRejectedValueOnce(Object.assign(
      new Error('the ladder changed since this row was researched — re-research it'), { code: 'CONFLICT' }));
    const res = await request(app).post('/api/admin/research-review/rev-1/resolve').send({});
    expect(res.status).toBe(409);
    expect(res.body.error).toBe('the ladder changed since this row was researched — re-research it');
  });
});
