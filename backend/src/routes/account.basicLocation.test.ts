import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// ---------------------------------------------------------------------------
// POST /api/account/set-location — a BASIC account adds an address (CA_0368).
//
// The rule under test is "districts only": the address and the point are used to resolve
// districts and then dropped. So these tests read every SQL call the route makes and check
// what each one was handed — the only call allowed to receive the point is the TIGER cache
// (essentials.cache_user_districts takes a point and stores districts). Nothing receives the
// address at all.
// ---------------------------------------------------------------------------

const { adminRpcMock, poolQueryMock, geocodeMock } = vi.hoisted(() => ({
  adminRpcMock: vi.fn(),
  poolQueryMock: vi.fn(),
  geocodeMock: vi.fn(),
}));

vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, requestDb: vi.fn(), adminRpc: adminRpcMock }));
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
vi.mock('../lib/connectService.js', () => ({ getLocationConsent: vi.fn() }));
vi.mock('../lib/authService.js', () => ({ getRequestAuthUser: vi.fn() }));
vi.mock('../lib/adminService.js', () => ({ isUserAdmin: vi.fn() }));
vi.mock('../lib/accountMeService.js', () => ({ getAccountMe: vi.fn() }));
vi.mock('../middleware/requireVerified.js', () => ({
  requireVerified: (_req: unknown, _res: unknown, next: () => void) => next(),
}));
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: { userId?: string }, _res: unknown, next: () => void) => {
    req.userId = 'user-1';
    next();
  },
}));
vi.mock('../middleware/tierGuards.js', () => ({
  requireConnected: (_req: unknown, _res: unknown, next: () => void) => next(),
  requireInform: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import accountRouter from './account.js';

const app = express();
app.use(express.json());
app.use('/api/account', accountRouter);

const ADDRESS = '17 Lexington Ave, Asheville, NC 28801';
const POINT = { lat: 35.5951234, lng: -82.5515678 };

const ASHEVILLE = {
  congressional: '3711',
  congressional_name: 'Congressional District 11',
  state_senate: '37049',
  state_senate_name: 'State Senate District 49',
  state_house: '37114',
  state_house_name: 'State House District 114',
  county: '37021',
  county_name: 'Buncombe County',
  school_district: '3700420',
  school_district_name: 'Asheville City Schools',
  city_council: null,
  city_council_name: null,
  municipality: '3702140',
  city: '3702140',
  state: '37',
  nation: 'US',
};

function withResolvers(payload: unknown, cd2026: string | null = null) {
  adminRpcMock.mockImplementation((fn: string) => {
    if (fn === 'resolve_jurisdiction_at_point') return Promise.resolve({ data: payload, error: null });
    if (fn === 'resolve_congressional_2026_at_point') return Promise.resolve({ data: cd2026, error: null });
    return Promise.resolve({ data: null, error: null });
  });
}

/** Every SQL call: its text and its parameters. */
function sqlCalls(): Array<{ sql: string; params: unknown[] }> {
  return poolQueryMock.mock.calls.map(([sql, params]) => ({ sql: String(sql), params: (params ?? []) as unknown[] }));
}

let warnSpy: ReturnType<typeof vi.spyOn>;
let errorSpy: ReturnType<typeof vi.spyOn>;

beforeEach(() => {
  adminRpcMock.mockReset();
  poolQueryMock.mockReset();
  geocodeMock.mockReset();
  geocodeMock.mockResolvedValue({ ...POINT, state: 'NC', city: 'ASHEVILLE', matchedAddress: '17 LEXINGTON AVE, ASHEVILLE, NC, 28801' });
  poolQueryMock.mockImplementation((sql: string) => {
    if (sql.includes('INSERT INTO inform.account_jurisdictions')) return Promise.resolve({ rows: [{ inserted: true }] });
    if (sql.includes('FROM essentials.districts')) return Promise.resolve({ rows: [{ label: 'Congressional District 1 (2026)' }] });
    return Promise.resolve({ rows: [] });
  });
  warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
  errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
});

afterEach(() => {
  warnSpy.mockRestore();
  errorSpy.mockRestore();
});

describe('POST /api/account/set-location — districts only', () => {
  it('stores the districts in inform.account_jurisdictions', async () => {
    withResolvers(ASHEVILLE);
    const res = await request(app).post('/api/account/set-location').send({ address: ADDRESS });

    expect(res.status).toBe(200);
    const insert = sqlCalls().find((c) => c.sql.includes('INSERT INTO inform.account_jurisdictions'));
    expect(insert).toBeDefined();
    expect(insert!.params).toContain('3711');
    expect(insert!.params).toContain('Buncombe County');
    expect(insert!.params).toContain('3702140');
  });

  it('🔴 hands the point to NO call except the TIGER district cache, and the address to none', async () => {
    withResolvers(ASHEVILLE);
    await request(app).post('/api/account/set-location').send({ address: ADDRESS });

    const calls = sqlCalls();
    expect(calls.length).toBeGreaterThan(0); // a check over zero calls proves nothing

    for (const c of calls) {
      const flat = JSON.stringify(c.params);
      expect(flat).not.toContain('Lexington');
      expect(flat).not.toContain('LEXINGTON');
      if (!c.sql.includes('essentials.cache_user_districts')) {
        expect(c.params).not.toContain(POINT.lat);
        expect(c.params).not.toContain(POINT.lng);
        expect(flat).not.toContain(String(POINT.lat));
      }
    }
    // And the old plain-JSON store is gone.
    expect(calls.some((c) => c.sql.includes('inform_profiles'))).toBe(false);
  });

  it('never echoes the address or the point', async () => {
    withResolvers(ASHEVILLE);
    const res = await request(app).post('/api/account/set-location').send({ address: ADDRESS });

    const body = JSON.stringify(res.body);
    expect(body).not.toContain('Lexington');
    expect(body).not.toContain('LEXINGTON');
    expect(body).not.toContain(String(POINT.lat));
    expect(body).not.toContain(String(POINT.lng));
    expect(res.body.jurisdiction.county_name).toBe('Buncombe County');
    expect(res.body.first_location).toBe(true);
  });

  it('stores the 2026 congressional district, with its own label, when the map moved it', async () => {
    withResolvers(ASHEVILLE, '3701');
    const res = await request(app).post('/api/account/set-location').send({ address: ADDRESS });

    const insert = sqlCalls().find((c) => c.sql.includes('INSERT INTO inform.account_jurisdictions'))!;
    expect(insert.params[1]).toBe('3701');
    expect(insert.params[2]).toBe('Congressional District 1 (2026)');
    expect(insert.params).not.toContain('3711');
    expect(res.body.jurisdiction.congressional_district).toBe('3701');
  });

  it('keeps the old id and label when the 2026 map does not cover the point', async () => {
    withResolvers(ASHEVILLE, null);
    await request(app).post('/api/account/set-location').send({ address: ADDRESS });

    const insert = sqlCalls().find((c) => c.sql.includes('INSERT INTO inform.account_jurisdictions'))!;
    expect(insert.params[1]).toBe('3711');
    expect(insert.params[2]).toBe('Congressional District 11');
    expect(sqlCalls().some((c) => c.sql.includes('FROM essentials.districts'))).toBe(false);
  });

  it('answers the same error codes as the Connected route', async () => {
    const { GeocodingError } = await import('../lib/geocodingService.js');
    geocodeMock.mockRejectedValueOnce(new (GeocodingError as any)('ADDRESS_NOT_FOUND', 'not found'));
    const res = await request(app).post('/api/account/set-location').send({ address: ADDRESS });
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('ADDRESS_NOT_FOUND');
    expect(poolQueryMock).not.toHaveBeenCalled();
  });

  it('500s, and writes nothing, when the resolver fails', async () => {
    adminRpcMock.mockResolvedValue({ data: null, error: { message: 'boom' } });
    const res = await request(app).post('/api/account/set-location').send({ address: ADDRESS });
    expect(res.status).toBe(500);
    expect(sqlCalls().some((c) => c.sql.includes('INSERT'))).toBe(false);
  });
});

describe('PATCH /api/account/location-hint — districts only', () => {
  it('🔴 caches districts at the point and stores nothing else', async () => {
    const res = await request(app)
      .patch('/api/account/location-hint')
      .send({ location: { ...POINT, label: ADDRESS } });

    expect(res.status).toBe(200);
    const calls = sqlCalls();
    expect(calls).toHaveLength(1);
    expect(calls[0].sql).toContain('essentials.cache_user_districts');
    expect(calls.some((c) => c.sql.includes('inform_profiles'))).toBe(false);
  });
});

describe('GET /api/account/me/jurisdiction — location_needs_confirmation (CA_0369)', () => {
  function storedRow(source: 'basic' | 'connected', needs: boolean) {
    poolQueryMock.mockImplementation((sql: string) => {
      if (sql.includes('FROM inform.account_jurisdictions') && sql.includes('connect.connected_profiles')) {
        return Promise.resolve({
          rows: [{ pri: source === 'basic' ? 2 : 1, source, location_consent: true, has_coords: source === 'connected', county_geo_id: '37021', congressional_geo_id: '3711' }],
        });
      }
      if (sql.includes('basic_location_needs_confirmation')) return Promise.resolve({ rows: [{ needs }] });
      return Promise.resolve({ rows: [] });
    });
  }

  it('is true for a basic account the maps changed under, and sits BESIDE jurisdiction', async () => {
    storedRow('basic', true);
    const res = await request(app).get('/api/account/me/jurisdiction');
    expect(res.status).toBe(200);
    expect(res.body.location_needs_confirmation).toBe(true);
    expect(res.body.jurisdiction).not.toHaveProperty('location_needs_confirmation');
    expect(res.body.jurisdiction.county).toBe('37021');
  });

  it('is false for a basic account whose maps did not change', async () => {
    storedRow('basic', false);
    const res = await request(app).get('/api/account/me/jurisdiction');
    expect(res.body.location_needs_confirmation).toBe(false);
  });

  it('is false for a Connected account, without asking the database', async () => {
    storedRow('connected', true);
    const res = await request(app).get('/api/account/me/jurisdiction');
    expect(res.body.location_needs_confirmation).toBe(false);
    expect(sqlCalls().some((c) => c.sql.includes('basic_location_needs_confirmation'))).toBe(false);
  });

  it('still answers 200 with false when the check fails', async () => {
    poolQueryMock.mockImplementation((sql: string) => {
      if (sql.includes('basic_location_needs_confirmation')) return Promise.reject(new Error('does not exist'));
      return Promise.resolve({ rows: [{ pri: 2, source: 'basic', location_consent: true, has_coords: false }] });
    });
    const res = await request(app).get('/api/account/me/jurisdiction');
    expect(res.status).toBe(200);
    expect(res.body.location_needs_confirmation).toBe(false);
  });
});
