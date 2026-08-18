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
const { mockGetRepresentativesByAddress } = vi.hoisted(() => ({
  mockGetRepresentativesByAddress: vi.fn(),
}));

vi.mock('../lib/essentialsService.js', () => ({
  getRepresentativesByAddress: mockGetRepresentativesByAddress,
  getPoliticiansFlatList: vi.fn(),
}));

vi.mock('../lib/candidateService.js', () => ({
  getCandidatesByZip: vi.fn(),
}));

vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import candidatesRouter from './essentialsCandidates.js';

const app = express();
app.use(express.json());
app.use('/api/essentials/candidates', candidatesRouter);

beforeEach(() => {
  mockGetRepresentativesByAddress.mockReset();
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
