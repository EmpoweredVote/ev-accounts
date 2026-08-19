import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';
import type { AddressSearchResult, PoliticianFlatRecord } from '../lib/essentialsService.js';

/**
 * Route-level smoke test for POST /api/essentials/candidates/search
 * (Phase 216, LOC-03) — mirrors essentialsCoordinateLookup.test.ts's
 * supertest+mock pattern. No test existed for this route prior to this
 * phase (RESEARCH Wave 0 gap).
 *
 * Fully mocks both service dependencies (essentialsService.js and
 * candidateService.js) rather than importing the real modules — the real
 * essentialsService.ts pulls in ./db.js, which validates env vars at
 * import time and process.exits when absent (as in this unit-test
 * environment). Only the symbols the route actually imports are needed.
 */
const { mockGetRepresentativesByAddress, mockGetOfficialsByZip } = vi.hoisted(() => ({
  mockGetRepresentativesByAddress: vi.fn(),
  mockGetOfficialsByZip: vi.fn(),
}));

vi.mock('../lib/essentialsService.js', () => ({
  getRepresentativesByAddress: mockGetRepresentativesByAddress,
  getPoliticiansFlatList: vi.fn(),
  getOfficialsByZip: mockGetOfficialsByZip,
}));

// NOTE: no candidateService mock — the route no longer imports it. Its
// getCandidatesByZip stub ignored the ZIP and returned every active
// empowered_profile; it was deleted rather than left one import away.

vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import candidatesRouter from './essentialsCandidates.js';

const app = express();
app.use(express.json());
app.use('/api/essentials/candidates', candidatesRouter);

beforeEach(() => {
  mockGetRepresentativesByAddress.mockReset();
  mockGetOfficialsByZip.mockReset();
});

function makeRep(overrides: Partial<PoliticianFlatRecord>): PoliticianFlatRecord {
  return {
    id: 'p-default',
    external_id: null,
    first_name: '',
    middle_initial: '',
    last_name: '',
    preferred_name: '',
    name_suffix: '',
    full_name: 'Default Person',
    party: '',
    photo_origin_url: '',
    web_form_url: '',
    urls: null,
    email_addresses: null,
    office_title: '',
    representing_state: '',
    representing_city: '',
    district_type: '',
    district_label: '',
    district_id: '',
    geo_id: '',
    mtfcc: '',
    chamber_name: '',
    chamber_name_formal: '',
    government_name: '',
    government_body_name: '',
    government_body_url: '',
    chamber_url: '',
    government_type: '',
    is_elected: true,
    voting_powers: 'full',
    representation_note: null,
    is_appointed: false,
    faces_retention_vote: false,
    election_frequency: '',
    policy_engagement_level: 'full',
    committees: [],
    bio_text: null,
    slug: null,
    is_incumbent: true,
    term_start: '',
    term_end: '',
    term_date_precision: '',
    appointment_date: '',
    office_description: '',
    is_vacant: false,
    vacant_since: null,
    next_primary_date: '',
    next_general_date: '',
    images: [],
    finance_summary: null,
    ...overrides,
  };
}

function makeAddressSearchResult(
  politicians: PoliticianFlatRecord[],
  locality: AddressSearchResult['locality'],
): AddressSearchResult {
  return {
    politicians,
    jurisdiction: null,
    matchedAddress: '123 Test St',
    tribal_land: { on_reservation: false },
    county: { geoid: '04019', name: 'Pima County' },
    jurisdictionGeoIds: {
      congressional: null,
      state_senate: null,
      state_house: null,
      county: null,
      school_district: null,
    },
    locality,
  };
}

describe('POST /api/essentials/candidates/search — subset-key smoke test (LOC-03)', () => {
  it('response body includes all five subset keys: politicians, tribal_land, locality, county, jurisdiction', async () => {
    const fixture = makeAddressSearchResult(
      [makeRep({ id: 'local-council', district_type: 'LOCAL', full_name: 'A City Councilor' })],
      { incorporated: false, place_name: null, county_name: 'Pima County' },
    );
    mockGetRepresentativesByAddress.mockResolvedValueOnce(fixture);

    const res = await request(app)
      .post('/api/essentials/candidates/search')
      .send({ query: 'somewhere in Pima County, AZ' });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('politicians');
    expect(res.body).toHaveProperty('tribal_land');
    expect(res.body).toHaveProperty('locality');
    expect(res.body).toHaveProperty('county');
    expect(res.body).toHaveProperty('jurisdiction');

    expect(res.body.locality).toEqual({ incorporated: false, place_name: null, county_name: 'Pima County' });
  });

  it('defaults locality to the null-incorporated shape when the service returns no locality field', async () => {
    const fixture = makeAddressSearchResult([], { incorporated: null, place_name: null, county_name: null });
    // Simulate an older/partial service result missing `locality` entirely.
    delete (fixture as Partial<AddressSearchResult>).locality;
    mockGetRepresentativesByAddress.mockResolvedValueOnce(fixture);

    const res = await request(app)
      .post('/api/essentials/candidates/search')
      .send({ query: 'somewhere' });

    expect(res.status).toBe(200);
    expect(res.body.locality).toEqual({ incorporated: null, place_name: null, county_name: null });
  });
});

// ---------------------------------------------------------------------------
// GET /api/essentials/candidates/:zip
//
// This route previously called a stub that IGNORED its zip argument and
// returned every active empowered_profiles row. These tests pin the real
// contract: a ZIP is an AREA, so several holders of one office is a valid
// answer, each carrying the share of the ZIP their district covers.
// ---------------------------------------------------------------------------

describe('GET /api/essentials/candidates/:zip', () => {
  it('returns 422 for a malformed ZIP without touching the service', async () => {
    const res = await request(app).get('/api/essentials/candidates/4622');
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('VALIDATION_ERROR');
    expect(mockGetOfficialsByZip).not.toHaveBeenCalled();
  });

  it('normalizes ZIP+4 to five digits before lookup', async () => {
    mockGetOfficialsByZip.mockResolvedValue({
      zip: '46220', states: ['IN'], county: null, politicians: [], ambiguity: [],
    });
    const res = await request(app).get('/api/essentials/candidates/46220-1234');
    expect(res.status).toBe(200);
    expect(mockGetOfficialsByZip).toHaveBeenCalledWith('46220');
  });

  it('returns 404 ZIP_NOT_FOUND when no ZCTA polygon exists', async () => {
    // Distinguishes "not a real ZIP" from "real ZIP, no offices covered" — a
    // distinction the old stub could not make, because it never read the ZIP.
    mockGetOfficialsByZip.mockResolvedValue(null);
    const res = await request(app).get('/api/essentials/candidates/00000');
    expect(res.status).toBe(404);
    expect(res.body.code).toBe('ZIP_NOT_FOUND');
  });

  it('passes share, ambiguity, states and county through to the response', async () => {
    mockGetOfficialsByZip.mockResolvedValue({
      zip: '46220',
      states: ['IN'],
      county: { geoid: '18097', name: 'Marion County' },
      politicians: [
        { ...makeRep({ id: 'a', district_type: 'STATE_LOWER' }), share: 0.38 },
        { ...makeRep({ id: 'b', district_type: 'STATE_LOWER' }), share: 0.01 },
      ],
      ambiguity: [{ district_type: 'STATE_LOWER', count: 2 }],
    });
    const res = await request(app).get('/api/essentials/candidates/46220');
    expect(res.status).toBe(200);
    expect(res.body.zip).toBe('46220');
    expect(res.body.states).toEqual(['IN']);
    expect(res.body.county.name).toBe('Marion County');
    expect(res.body.politicians.map((p: { share: number }) => p.share)).toEqual([0.38, 0.01]);
    expect(res.body.ambiguity).toEqual([{ district_type: 'STATE_LOWER', count: 2 }]);
  });

  it('does NOT drop a sliver server-side — collapsing is the client\'s job', async () => {
    // A >=10% server cutoff would have removed Bloomington from 47401.
    mockGetOfficialsByZip.mockResolvedValue({
      zip: '46360', states: ['IN'], county: null,
      politicians: [
        { ...makeRep({ id: 'real' }), share: 0.61 },
        { ...makeRep({ id: 'sliver' }), share: 0.0004 },
      ],
      ambiguity: [],
    });
    const res = await request(app).get('/api/essentials/candidates/46360');
    expect(res.status).toBe(200);
    expect(res.body.politicians).toHaveLength(2);
    expect(res.body.politicians[1].share).toBeCloseTo(0.0004);
  });

  it('returns 200 with an empty politicians array for a real ZIP we cover no offices in', async () => {
    mockGetOfficialsByZip.mockResolvedValue({
      zip: '99999', states: [], county: null, politicians: [], ambiguity: [],
    });
    const res = await request(app).get('/api/essentials/candidates/99999');
    expect(res.status).toBe(200);
    expect(res.body.politicians).toEqual([]);
    expect(res.headers['x-data-status']).toBe('no-geofence-data');
  });

  it('marks a populated result fresh', async () => {
    mockGetOfficialsByZip.mockResolvedValue({
      zip: '46220', states: ['IN'], county: null,
      politicians: [{ ...makeRep({ id: 'a' }), share: 1 }], ambiguity: [],
    });
    const res = await request(app).get('/api/essentials/candidates/46220');
    expect(res.headers['x-data-status']).toBe('fresh');
  });

  it('returns 500 when the service throws', async () => {
    mockGetOfficialsByZip.mockRejectedValue(new Error('boom'));
    const res = await request(app).get('/api/essentials/candidates/46220');
    expect(res.status).toBe(500);
    expect(res.body.code).toBe('INTERNAL_ERROR');
  });
});
