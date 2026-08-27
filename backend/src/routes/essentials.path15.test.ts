import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// ---------------------------------------------------------------------------
// Mocks — essentials.ts pulls db/supabase and four services at module scope.
// ---------------------------------------------------------------------------

const { poolQueryMock, adminRpcMock, repsByJurisdictionMock, localOfficialsMock } = vi.hoisted(
  () => ({
    poolQueryMock: vi.fn(),
    adminRpcMock: vi.fn(),
    repsByJurisdictionMock: vi.fn(),
    localOfficialsMock: vi.fn(),
  })
);

vi.mock('../lib/db.js', () => ({ pool: { query: poolQueryMock } }));
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: adminRpcMock }));
vi.mock('../lib/essentialsService.js', () => ({
  getRepresentativesByAddress: vi.fn(),
  getRepresentativesByJurisdiction: repsByJurisdictionMock,
  getLocalOfficialsByUserId: localOfficialsMock,
  getGovernmentById: vi.fn(),
  getChamberById: vi.fn(),
  getDistrictById: vi.fn(),
}));
vi.mock('../lib/electionService.js', () => ({
  getElectionsByCoordinate: vi.fn(),
  getElectionsByGeoIds: vi.fn().mockResolvedValue([]),
  getCandidateById: vi.fn(),
}));
vi.mock('../lib/voterInfoService.js', () => ({ getVoterInfo: vi.fn() }));
vi.mock('../lib/geocodingService.js', () => ({
  geocodeAddress: vi.fn(),
  GeocodingError: class GeocodingError extends Error {},
}));
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: { userId?: string }, _res: unknown, next: () => void) => {
    req.userId = 'user-1';
    next();
  },
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));
vi.mock('../middleware/tierGuards.js', () => ({
  requireConnected: (_req: unknown, _res: unknown, next: () => void) => next(),
  requireEmpowered: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import essentialsRouter from './essentials.js';

const app = express();
app.use(express.json());
app.use('/api/essentials', essentialsRouter);

/**
 * A profile that lands on Path 1.5: coords on file, congressional/senate/county empty —
 * but a SCHOOL DISTRICT already stored. That last part is the point: the Path 1.5 guard
 * checked only the columns it saw, while the UPDATE wrote all five.
 */
const PROFILE_ON_PATH_15 = {
  congressional_geo_id: null,
  state_senate_geo_id: null,
  state_house_geo_id: null,
  county_geo_id: null,
  school_district_geo_id: 'geo-school-bend',
  municipality_geo_id: 'geo-muni-bend',
  jurisdiction_state: 'OR',
  jurisdiction_city: 'Bend',
  has_coords: true,
};

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
  municipality: null,
};

/** Dispatch on SQL text, not call order — the handler's path count varies by branch. */
function routePoolQueries() {
  poolQueryMock.mockImplementation((sql: string) => {
    if (typeof sql === 'string' && sql.includes('FROM connect.connected_profiles')) {
      return Promise.resolve({ rows: [PROFILE_ON_PATH_15], rowCount: 1 });
    }
    if (typeof sql === 'string' && sql.includes('FROM connect.user_districts')) {
      return Promise.resolve({ rows: [], rowCount: 0 }); // no TIGER cache -> skip Path 0
    }
    return Promise.resolve({ rows: [], rowCount: 0 });
  });
}

function profileUpdates(): string[] {
  return poolQueryMock.mock.calls
    .map((c) => (typeof c[0] === 'string' ? c[0] : ''))
    .filter((sql) => sql.includes('UPDATE connect.connected_profiles'));
}

beforeEach(() => {
  poolQueryMock.mockReset();
  adminRpcMock.mockReset();
  repsByJurisdictionMock.mockReset();
  localOfficialsMock.mockReset();

  repsByJurisdictionMock.mockResolvedValue([]);
  localOfficialsMock.mockResolvedValue([]);
  vi.spyOn(console, 'warn').mockImplementation(() => {});
  routePoolQueries();
});

// ---------------------------------------------------------------------------

describe('essentials Path 1.5 — an unresolved back-fill must not write', () => {
  // The back-fill exists to FILL empty geo_id columns. When the RPC resolves nothing there
  // is nothing to contribute, so the UPDATE is pure cost — and its guard checked fewer
  // columns than it wrote, so it could null a stored school_district or municipality on a
  // profile whose congressional/senate columns happened to be empty.

  it('issues no write-back on /representatives/me when nothing resolves', async () => {
    adminRpcMock.mockResolvedValue({ data: RESOLVED_NOTHING, error: null });

    await request(app).get('/api/essentials/representatives/me');

    expect(profileUpdates()).toEqual([]);
  });

  it('issues no write-back on /elections/me when nothing resolves', async () => {
    adminRpcMock.mockResolvedValue({ data: RESOLVED_NOTHING, error: null });

    await request(app).get('/api/essentials/elections/me');

    expect(profileUpdates()).toEqual([]);
  });

  it('still writes the back-fill when the RPC does resolve something', async () => {
    // Positive control: the whole point of Path 1.5 must keep working.
    adminRpcMock.mockResolvedValue({
      data: { ...RESOLVED_NOTHING, congressional: 'cd-5', congressional_name: 'Oregon 5th' },
      error: null,
    });

    await request(app).get('/api/essentials/representatives/me');

    expect(profileUpdates()).toHaveLength(1);
  });
});
