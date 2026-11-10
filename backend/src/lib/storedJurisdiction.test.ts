import { vi, describe, it, expect, beforeEach } from 'vitest';

const { poolQueryMock } = vi.hoisted(() => ({ poolQueryMock: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: poolQueryMock } }));

import {
  readStoredJurisdiction,
  toJurisdictionResponse,
  STORED_JURISDICTION_SQL,
  locationNeedsConfirmation,
} from './storedJurisdiction.js';

// Braces matter: a beforeEach that RETURNS a function has it run as teardown, and mockReset
// returns the mock — so the mock would be called once more after each test.
beforeEach(() => {
  poolQueryMock.mockReset();
});

/**
 * The SQL itself is exercised against production data in CA_0368's dry run (a basic row and
 * a Connected row, each read back through STORED_JURISDICTION_SQL). These tests pin the parts
 * a mock can: the shape of the query and what the helper does with a row.
 */
describe('readStoredJurisdiction', () => {
  it('reads BOTH tables, Connected first', () => {
    const connectedAt = STORED_JURISDICTION_SQL.indexOf('FROM connect.connected_profiles');
    const basicAt = STORED_JURISDICTION_SQL.indexOf('FROM inform.account_jurisdictions');
    expect(connectedAt).toBeGreaterThan(-1);
    expect(basicAt).toBeGreaterThan(connectedAt);
    expect(STORED_JURISDICTION_SQL).toMatch(/ORDER BY pri\s+LIMIT 1/);
  });

  it('🔴 a basic row never claims a point', () => {
    // The point-based paths in routes/essentials.ts branch on has_coords. A basic row has no
    // point to decrypt, so it must read false or those paths would call an RPC that RAISEs.
    expect(STORED_JURISDICTION_SQL).toMatch(/SELECT 2, 'basic', true, false,/);
  });

  it('returns null when neither table has a row', async () => {
    poolQueryMock.mockResolvedValue({ rows: [] });
    expect(await readStoredJurisdiction('u1')).toBeNull();
  });

  it('drops the internal ordering column', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ pri: 2, source: 'basic', location_consent: true, has_coords: false, county_geo_id: '37021' }] });
    const j = await readStoredJurisdiction('u1');
    expect(j).not.toHaveProperty('pri');
    expect(j?.source).toBe('basic');
    expect(j?.county_geo_id).toBe('37021');
  });
});

describe('toJurisdictionResponse', () => {
  it('maps every column to the public key and never spreads the row', () => {
    const out = toJurisdictionResponse({
      source: 'basic',
      location_consent: true,
      has_coords: false,
      congressional_geo_id: '3711',
      congressional_district_name: 'CD 11',
      state_senate_geo_id: null,
      state_senate_district_name: null,
      state_house_geo_id: null,
      state_house_district_name: null,
      county_geo_id: '37021',
      county_name: 'Buncombe County',
      school_district_geo_id: null,
      school_district_name: null,
      city_council_geo_id: null,
      city_council_district_name: null,
      municipality_geo_id: '3702140',
      jurisdiction_state: 'NC',
      jurisdiction_city: 'ASHEVILLE',
      city_geo_id: '3702140',
      state_geo_id: '37',
      nation_geo_id: 'US',
    });
    expect(out.congressional_district).toBe('3711');
    expect(out.county_name).toBe('Buncombe County');
    expect(out.state).toBe('NC');
    expect(out.state_geoid).toBe('37');
    expect(out).not.toHaveProperty('source');
    expect(out).not.toHaveProperty('has_coords');
  });

  it('answers all-null for no row', () => {
    expect(Object.values(toJurisdictionResponse(null)).every((v) => v === null)).toBe(true);
  });
});

describe('locationNeedsConfirmation (CA_0369)', () => {
  const basic = { source: 'basic' as const } as Parameters<typeof locationNeedsConfirmation>[1];
  const connected = { source: 'connected' as const } as Parameters<typeof locationNeedsConfirmation>[1];

  it('asks the database for a basic row', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ needs: true }] });
    expect(await locationNeedsConfirmation('u1', basic)).toBe(true);
    expect(poolQueryMock).toHaveBeenCalledWith(
      expect.stringContaining('inform.basic_location_needs_confirmation($1)'),
      ['u1'],
    );
  });

  it('passes a false answer through', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ needs: false }] });
    expect(await locationNeedsConfirmation('u1', basic)).toBe(false);
  });

  it('is false for a Connected row without asking — the weekly job re-checks those', async () => {
    expect(await locationNeedsConfirmation('u1', connected)).toBe(false);
    expect(poolQueryMock).not.toHaveBeenCalled();
  });

  it('is false with no address on file', async () => {
    expect(await locationNeedsConfirmation('u1', null)).toBe(false);
    expect(poolQueryMock).not.toHaveBeenCalled();
  });

  it('🔴 a failing check reads false instead of breaking /me (deploy before CA_0369 is applied)', async () => {
    const err = vi.spyOn(console, 'error').mockImplementation(() => {});
    poolQueryMock.mockImplementation(async () => {
      throw new Error('function inform.basic_location_needs_confirmation(uuid) does not exist');
    });
    expect(await locationNeedsConfirmation('u1', basic)).toBe(false);
    expect(err).toHaveBeenCalled();
    err.mockRestore();
  });
});
