import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';
import type { AddressSearchResult, PoliticianFlatRecord } from '../lib/essentialsService.js';

const { mockGetRepresentativesByCoordinate } = vi.hoisted(() => ({
  mockGetRepresentativesByCoordinate: vi.fn(),
}));

// Full mock (no importActual) — the real essentialsService.ts module pulls in
// ./db.js, which validates DATABASE_URL/SUPABASE_* env vars at import time
// and process.exits when they're absent (as they are in this unit-test
// environment). Only the one symbol the route actually imports is needed
// here. classifyCoordinate is left UNMOCKED — it's a pure, DB-free function
// (Phase 213-01) and exercising the real implementation through the HTTP
// layer is exactly what proves the 422 taxonomy round-trips correctly.
vi.mock('../lib/essentialsService.js', () => ({
  getRepresentativesByCoordinate: mockGetRepresentativesByCoordinate,
}));

vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import coordinateLookupRouter from './essentialsCoordinateLookup.js';

const app = express();
app.use(express.json());
app.use('/api/essentials/coordinate-lookup', coordinateLookupRouter);

beforeEach(() => {
  mockGetRepresentativesByCoordinate.mockReset();
});

// ---------------------------------------------------------------------------
// Minimal PoliticianFlatRecord fixture builder — only the fields relevant to
// the BLOCKER 1 regression guard (district_type) vary; every other field is
// a harmless default satisfying the interface.
// ---------------------------------------------------------------------------
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

function makeAddressSearchResult(politicians: PoliticianFlatRecord[]): AddressSearchResult {
  return {
    politicians,
    jurisdiction: null,
    matchedAddress: '',
    tribal_land: { on_reservation: false },
    county: null,
    jurisdictionGeoIds: {
      congressional: null,
      state_senate: null,
      state_house: null,
      county: null,
      school_district: null,
    },
    locality: { incorporated: null, place_name: null, county_name: null },
  };
}

describe('POST /api/essentials/coordinate-lookup — 200 path (Bloomington, IN)', () => {
  it('returns 200 with a non-empty politicians array, exactly one NATIONAL_LOWER rep, empty matchedAddress, and no coordinate echo', async () => {
    const fixture = makeAddressSearchResult([
      makeRep({ id: 'house-rep', district_type: 'NATIONAL_LOWER', full_name: 'A US House Rep' }),
      makeRep({ id: 'state-sen', district_type: 'STATE_UPPER', full_name: 'A State Senator' }),
      makeRep({ id: 'local-council', district_type: 'LOCAL', full_name: 'A City Councilor' }),
    ]);
    mockGetRepresentativesByCoordinate.mockResolvedValueOnce(fixture);

    const res = await request(app)
      .post('/api/essentials/coordinate-lookup')
      .send({ lat: 39.17, lng: -86.52 });

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.politicians)).toBe(true);
    expect(res.body.politicians.length).toBeGreaterThan(0);

    // BLOCKER 1 regression guard: EXACTLY ONE NATIONAL_LOWER record — never
    // the ~435-member nationwide House roster.
    const houseReps = res.body.politicians.filter(
      (p: { district_type: string }) => p.district_type === 'NATIONAL_LOWER',
    );
    expect(houseReps).toHaveLength(1);

    expect(res.body.matchedAddress).toBe('');

    // Privacy no-echo (Criterion 3): the serialized body must not contain
    // either submitted coordinate value.
    const serialized = JSON.stringify(res.body);
    expect(serialized).not.toContain('39.17');
    expect(serialized).not.toContain('-86.52');

    expect(mockGetRepresentativesByCoordinate).toHaveBeenCalledWith(39.17, -86.52);
  });
});

describe('POST /api/essentials/coordinate-lookup — 422 validation taxonomy (D-07)', () => {
  it('SWAPPED_COORDINATES when lat/lng are transposed (Bloomington swapped)', async () => {
    const res = await request(app)
      .post('/api/essentials/coordinate-lookup')
      .send({ lat: -86.52, lng: 39.17 });

    expect(res.status).toBe(422);
    expect(res.body.code).toBe('SWAPPED_COORDINATES');
    expect(mockGetRepresentativesByCoordinate).not.toHaveBeenCalled();
  });

  it('OUTSIDE_US_BOUNDS for a non-US point (London)', async () => {
    const res = await request(app)
      .post('/api/essentials/coordinate-lookup')
      .send({ lat: 51.5, lng: -0.12 });

    expect(res.status).toBe(422);
    expect(res.body.code).toBe('OUTSIDE_US_BOUNDS');
    expect(mockGetRepresentativesByCoordinate).not.toHaveBeenCalled();
  });

  it('INVALID_COORDINATES for non-numeric malformed input', async () => {
    const res = await request(app)
      .post('/api/essentials/coordinate-lookup')
      .send({ lat: 'abc', lng: null });

    expect(res.status).toBe(422);
    expect(res.body.code).toBe('INVALID_COORDINATES');
    expect(mockGetRepresentativesByCoordinate).not.toHaveBeenCalled();
  });

  it('INVALID_COORDINATES when both lat and lng are missing', async () => {
    const res = await request(app).post('/api/essentials/coordinate-lookup').send({});

    expect(res.status).toBe(422);
    expect(res.body.code).toBe('INVALID_COORDINATES');
    expect(mockGetRepresentativesByCoordinate).not.toHaveBeenCalled();
  });
});
