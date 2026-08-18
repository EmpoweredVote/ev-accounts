import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';
import type { PoliticianFlatRecord } from '../lib/essentialsService.js';

const {
  mockSearchPlaceNames,
  mockGetStatewideOfficials,
  mockGetFederalOfficials,
  mockGetCongressionalOverlapNote,
  mockGetPoliticiansByArea,
  mockGetPoliticiansByGovernmentList,
} = vi.hoisted(() => ({
  mockSearchPlaceNames: vi.fn(),
  mockGetStatewideOfficials: vi.fn(),
  mockGetFederalOfficials: vi.fn(),
  mockGetCongressionalOverlapNote: vi.fn(),
  mockGetPoliticiansByArea: vi.fn(),
  mockGetPoliticiansByGovernmentList: vi.fn(),
}));

// Full mock (no importActual) — the real module pulls in ./db.js, which
// validates DATABASE_URL/SUPABASE_* env vars at import time and process.exits
// when they're absent (as they are in this unit-test environment). Only the
// two symbols the route actually imports are needed here. The class is
// declared INSIDE the factory (not as an outer top-level const) because
// vi.mock factories are hoisted above the file's other top-level statements —
// referencing an outer const here would throw ("no top level variables
// inside" per vitest's vi.mock hoisting rules).
vi.mock('../lib/locationSearchService.js', () => {
  class LocationSearchQueryTooShortError extends Error {
    constructor(message = 'Query must be at least 2 characters') {
      super(message);
      this.name = 'LocationSearchQueryTooShortError';
    }
  }
  return {
    searchPlaceNames: mockSearchPlaceNames,
    LocationSearchQueryTooShortError,
  };
});

vi.mock('../lib/essentialsBrowseService.js', () => ({
  getStatewideOfficials: mockGetStatewideOfficials,
  getFederalOfficials: mockGetFederalOfficials,
  getCongressionalOverlapNote: mockGetCongressionalOverlapNote,
  getPoliticiansByArea: mockGetPoliticiansByArea,
  getPoliticiansByGovernmentList: mockGetPoliticiansByGovernmentList,
}));

vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import locationSearchRouter, { pickHouseRep } from './essentialsLocationSearch.js';

const app = express();
app.use('/api/essentials/location-search', locationSearchRouter);

beforeEach(() => {
  mockSearchPlaceNames.mockReset();
  mockGetStatewideOfficials.mockReset();
  mockGetFederalOfficials.mockReset();
  mockGetCongressionalOverlapNote.mockReset();
  mockGetPoliticiansByArea.mockReset();
  mockGetPoliticiansByGovernmentList.mockReset();
});

// ---------------------------------------------------------------------------
// Minimal PoliticianFlatRecord fixture builder — only district_type/geo_id
// vary across the 212-06 test cases; every other field is a harmless default.
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

describe('pickHouseRep (212-06 gap-closure fix, D-01 defect)', () => {
  it('picks the record whose district_type is NATIONAL_LOWER and geo_id matches the CD, ignoring earlier local/state records', () => {
    const records = [
      makeRep({ id: 'local-councilor', district_type: 'LOCAL', geo_id: '0406', full_name: 'A Marana City Councilor' }),
      makeRep({ id: 'state-rep', district_type: 'STATE_LOWER', geo_id: '0406', full_name: 'A State House Rep' }),
      makeRep({ id: 'house-rep', district_type: 'NATIONAL_LOWER', geo_id: '0406', full_name: 'Juan Ciscomani' }),
    ];

    const result = pickHouseRep(records, '0406');

    expect(result?.id).toBe('house-rep');
    expect(result?.full_name).toBe('Juan Ciscomani');
  });

  it('returns null when no NATIONAL_LOWER record matches the CD geo_id (honest omission, never fabricate)', () => {
    const records = [
      makeRep({ id: 'local-councilor', district_type: 'LOCAL', geo_id: '0406' }),
      makeRep({ id: 'wrong-cd-house-rep', district_type: 'NATIONAL_LOWER', geo_id: '9999' }),
    ];

    expect(pickHouseRep(records, '0406')).toBeNull();
  });

  it('returns null for an empty records array', () => {
    expect(pickHouseRep([], '0406')).toBeNull();
  });

  it('does NOT simply return records[0] when records[0] is not the NATIONAL_LOWER/matching-geo_id record (regression vs the [0] bug)', () => {
    const records = [
      makeRep({ id: 'first-but-wrong', district_type: 'LOCAL', geo_id: '2501' }),
      makeRep({ id: 'actual-house-rep', district_type: 'NATIONAL_LOWER', geo_id: '2501' }),
    ];

    const result = pickHouseRep(records, '2501');
    expect(result?.id).toBe('actual-house-rep');
    expect(result?.id).not.toBe(records[0].id);
  });
});

describe('GET /api/essentials/location-search/resolve — validation', () => {
  it('422 when geo_id is missing', async () => {
    const res = await request(app).get('/api/essentials/location-search/resolve?mtfcc=G5200&state=AZ');
    expect(res.status).toBe(422);
    expect(mockGetStatewideOfficials).not.toHaveBeenCalled();
  });

  it('422 when mtfcc is not a known value', async () => {
    const res = await request(app).get(
      '/api/essentials/location-search/resolve?geo_id=0406&mtfcc=BOGUS&state=AZ'
    );
    expect(res.status).toBe(422);
  });

  it('422 when state is not a 2-letter uppercase abbreviation', async () => {
    const res = await request(app).get(
      '/api/essentials/location-search/resolve?geo_id=0406&mtfcc=G5200&state=arizona'
    );
    expect(res.status).toBe(422);
  });

  // 212-07 gap-closure (RSLV-05 blocker): GET / emits mtfcc:"G4000" for every
  // State-tier candidate (e.g. "Illinois", "IL") — before this fix, KNOWN_MTFCCS
  // omitted 'G4000' so passing that exact candidate straight into /resolve
  // (the documented round-trip) always 422'd. Verified live for IL/AZ pre-fix.
  it('does NOT 422 for a State-tier candidate (mtfcc=G4000) — the documented GET / -> GET /resolve round-trip', async () => {
    mockGetStatewideOfficials.mockResolvedValueOnce([]);
    mockGetFederalOfficials.mockResolvedValueOnce([]);
    mockGetCongressionalOverlapNote.mockResolvedValueOnce({
      cdGeoIds: [],
      needsExactAddress: false,
    });
    mockGetPoliticiansByGovernmentList.mockResolvedValueOnce([]);

    const res = await request(app).get(
      '/api/essentials/location-search/resolve?geo_id=17&mtfcc=G4000&state=IL'
    );

    expect(res.status).toBe(200);
    expect(mockGetCongressionalOverlapNote).toHaveBeenCalledWith('17', 'G4000');
  });
});

describe('GET /api/essentials/location-search/resolve — D-01 US House selection (212-06)', () => {
  it('returns the actual NATIONAL_LOWER House member as congressional.representative, not the first overlapping local/state official', async () => {
    mockGetStatewideOfficials.mockResolvedValueOnce([]);
    mockGetFederalOfficials.mockResolvedValueOnce([]);
    mockGetCongressionalOverlapNote.mockResolvedValueOnce({
      cdGeoIds: ['0406'],
      needsExactAddress: false,
    });
    mockGetPoliticiansByGovernmentList.mockResolvedValueOnce([]);
    mockGetPoliticiansByArea.mockResolvedValueOnce([
      makeRep({ id: 'marana-councilor', district_type: 'LOCAL', geo_id: '0406', full_name: 'A Marana City Councilor' }),
      makeRep({ id: 'ciscomani', district_type: 'NATIONAL_LOWER', geo_id: '0406', full_name: 'Juan Ciscomani' }),
    ]);

    const res = await request(app).get(
      '/api/essentials/location-search/resolve?geo_id=0406&mtfcc=G4110&state=AZ'
    );

    expect(res.status).toBe(200);
    expect(res.body.congressional.representative?.full_name).toBe('Juan Ciscomani');
    expect(res.body.congressional.representative?.id).toBe('ciscomani');
    expect(mockGetPoliticiansByArea).toHaveBeenCalledWith('0406', 'G5200');
  });

  it('representative is null (never auto-picked) when needsExactAddress is true (>1 CD overlaps)', async () => {
    mockGetStatewideOfficials.mockResolvedValueOnce([]);
    mockGetFederalOfficials.mockResolvedValueOnce([]);
    mockGetCongressionalOverlapNote.mockResolvedValueOnce({
      cdGeoIds: ['0601', '0602'],
      needsExactAddress: true,
    });
    mockGetPoliticiansByGovernmentList.mockResolvedValueOnce([]);

    const res = await request(app).get(
      '/api/essentials/location-search/resolve?geo_id=0666000&mtfcc=G4110&state=CA'
    );

    expect(res.status).toBe(200);
    expect(res.body.congressional.representative).toBeNull();
    expect(res.body.congressional.cdGeoIds).toEqual(['0601', '0602']);
    expect(mockGetPoliticiansByArea).not.toHaveBeenCalled();
  });

  it('representative is null (honest omission) when no NATIONAL_LOWER record is found in the overlap set', async () => {
    mockGetStatewideOfficials.mockResolvedValueOnce([]);
    mockGetFederalOfficials.mockResolvedValueOnce([]);
    mockGetCongressionalOverlapNote.mockResolvedValueOnce({
      cdGeoIds: ['0406'],
      needsExactAddress: false,
    });
    mockGetPoliticiansByGovernmentList.mockResolvedValueOnce([]);
    mockGetPoliticiansByArea.mockResolvedValueOnce([
      makeRep({ id: 'marana-councilor', district_type: 'LOCAL', geo_id: '0406' }),
    ]);

    const res = await request(app).get(
      '/api/essentials/location-search/resolve?geo_id=0406&mtfcc=G4110&state=AZ'
    );

    expect(res.status).toBe(200);
    expect(res.body.congressional.representative).toBeNull();
  });
});
