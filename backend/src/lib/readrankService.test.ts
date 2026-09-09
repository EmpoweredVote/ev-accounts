// src/lib/readrankService.test.ts
import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery, mockGetBoundaryBatch, mockGetDistrictCountyGeoIds, mockGetStateCountyGeoIds, mockGetCountyNames } = vi.hoisted(() => ({
  mockQuery: vi.fn(),
  mockGetBoundaryBatch: vi.fn(),
  mockGetDistrictCountyGeoIds: vi.fn(),
  mockGetStateCountyGeoIds: vi.fn(),
  mockGetCountyNames: vi.fn(),
}));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));
vi.mock('./env.js', () => ({
  env: {
    SUPABASE_SERVICE_ROLE_KEY: 'test-secret',
    READRANK_TOKEN_SECRET: 'test-readrank-secret',
    SUPABASE_URL: 'https://test.supabase.co',
    SUPABASE_ANON_KEY: 'test-anon',
    DATABASE_URL: 'postgres://test',
    ADMIN_INGEST_TOKEN: 'test-token',
  },
}));
vi.mock('./informBoundaryService.js', () => ({
  getBoundaryBatch: mockGetBoundaryBatch,
  getDistrictCountyGeoIds: mockGetDistrictCountyGeoIds,
  getStateCountyGeoIds: mockGetStateCountyGeoIds,
  getCountyNames: mockGetCountyNames,
}));

import { getPlayableRaces, deriveTierScope, deriveOfficeSeat, getRaceBlindQuotes, computeRaceMatch, topicTitleFromKey } from './readrankService.js';
import type { JurisdictionGeoIds } from './essentialsService.js';

// getPlayableRaces now returns { races, counties }. Existing array-style assertions
// migrate to this helper.
async function getPlayableRacesResult(ids?: string[], jurisdiction?: JurisdictionGeoIds) {
  return getPlayableRaces(ids, jurisdiction);
}

beforeEach(() => {
  mockQuery.mockReset();
  mockGetBoundaryBatch.mockReset();
  mockGetDistrictCountyGeoIds.mockReset();
  mockGetStateCountyGeoIds.mockReset();
  mockGetCountyNames.mockReset();
  // Default: empty maps (no county overlap / no embedded geometry) so existing tests are unaffected.
  mockGetBoundaryBatch.mockResolvedValue(new Map());
  mockGetDistrictCountyGeoIds.mockResolvedValue(new Map());
  mockGetStateCountyGeoIds.mockResolvedValue(new Map());
  mockGetCountyNames.mockResolvedValue({});
});

describe('deriveTierScope', () => {
  it('uses mtfcc when present: G4110 -> local/citywide', () => {
    expect(deriveTierScope({ jurisdiction_level: 'county', position_name: 'Mayor', mtfcc: 'G4110' }))
      .toEqual({ tier: 'local', scope: 'citywide' });
  });
  it('G5200 -> federal/district', () => {
    expect(deriveTierScope({ jurisdiction_level: 'federal', position_name: 'U.S. House', mtfcc: 'G5200' }))
      .toEqual({ tier: 'federal', scope: 'district' });
  });
  it('G5420 school district -> local/district', () => {
    expect(deriveTierScope({ jurisdiction_level: 'local', position_name: 'School Board', mtfcc: 'G5420' }))
      .toEqual({ tier: 'local', scope: 'district' });
  });
  it('G4020 -> local/county', () => {
    expect(deriveTierScope({ jurisdiction_level: 'county', position_name: 'County Commission', mtfcc: 'G4020' }))
      .toEqual({ tier: 'local', scope: 'county' });
  });
  it('falls back to jurisdiction_level + name when mtfcc absent: Governor -> state/statewide', () => {
    expect(deriveTierScope({ jurisdiction_level: 'state', position_name: 'Governor', mtfcc: null }))
      .toEqual({ tier: 'state', scope: 'statewide' });
  });
});

describe('getPlayableRaces', () => {
  it('maps boundaryRef, counts and tier/scope from a joined row', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r1', position_name: 'Mayor', district_label: null, district_type: 'LOCAL_EXEC',
      election_id: 'e1', election_name: 'LA 2026', election_date: new Date('2026-11-03T00:00:00Z'),
      jurisdiction_level: 'county', state: 'CA',
      boundary_layer: 'G4110', boundary_geoid: '0644000',
      candidate_count: '3', question_count: '5', quote_count: '24', rankable_question_count: '4',
      politician_ids: ['p1', 'p2', 'p3'],
    }] });

    const { races: [race] } = await getPlayableRacesResult();
    expect(race).toMatchObject({
      raceId: 'r1', office: 'Mayor', seat: null, state: 'CA',
      candidateCount: 3, topicCount: 5, quoteCount: 24, rankableTopicCount: 4,
      tier: 'local', scope: 'citywide',
      boundaryRef: { layer: 'G4110', geoid: '0644000' },
    });
  });

  it('falls back to the whole-state outline for a statewide race with no district', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r2', position_name: 'Governor', district_label: null, district_type: null,
      election_id: 'e2', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: null, boundary_geoid: null,
      candidate_count: '2', question_count: '3', quote_count: '8', rankable_question_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race).toMatchObject({ tier: 'state', scope: 'statewide' });
    expect(race.boundaryRef).toEqual({ layer: 'G4000', geoid: '18' }); // IN
  });

  it('emits boundaryRef:null when there is no district and the scope is not statewide', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r3', position_name: 'City Council', district_label: null, district_type: null,
      election_id: 'e3', election_name: 'Somewhere 2026', election_date: null,
      jurisdiction_level: 'city', state: 'IN',
      boundary_layer: null, boundary_geoid: null,
      candidate_count: '2', question_count: '2', quote_count: '6', rankable_question_count: '2',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.scope).toBe('district');
    expect(race.boundaryRef).toBeNull();
  });

  it('federal: child = home state, frame = US (model B)', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rf', position_name: 'U.S. House', district_label: null, district_type: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'federal', state: 'IN',
      boundary_layer: 'G5200', boundary_geoid: '1807',
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '3', quote_count: '8', rankable_question_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.tier).toBe('federal');
    expect(race.boundaryRef).toEqual({ layer: 'G4000', geoid: '18' }); // home state
    expect(race.frameRef).toEqual({ layer: 'G4000', geoid: 'US' });
  });

  it('statewide state (Governor): frame = null (state alone)', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rg', position_name: 'Governor', district_label: null, district_type: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: null, boundary_geoid: null, frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '3', quote_count: '8', rankable_question_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.boundaryRef).toEqual({ layer: 'G4000', geoid: '18' });
    expect(race.frameRef).toBeNull();
  });

  it('county: frame = state', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rc', position_name: 'County Commission', district_label: null, district_type: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'county', state: 'IN',
      boundary_layer: 'G4020', boundary_geoid: '18105', frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '3', quote_count: '8', rankable_question_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.boundaryRef).toEqual({ layer: 'G4020', geoid: '18105' });
    expect(race.frameRef).toEqual({ layer: 'G4000', geoid: '18' });
  });

  it('city: frame = the SQL-resolved container county', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rcity', position_name: 'Mayor', district_label: null, district_type: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'city', state: 'IN',
      boundary_layer: 'G4110', boundary_geoid: '1805860',
      frame_layer: 'G4020', frame_geoid: '18105',
      candidate_count: '2', question_count: '3', quote_count: '8', rankable_question_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.boundaryRef).toEqual({ layer: 'G4110', geoid: '1805860' });
    expect(race.frameRef).toEqual({ layer: 'G4020', geoid: '18105' });
  });

  it('ward: frame = the SQL-resolved container city', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rw', position_name: 'City Common Council', district_label: null, district_type: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'city', state: 'IN',
      boundary_layer: 'X0001', boundary_geoid: '180586000001',
      frame_layer: 'G4110', frame_geoid: '1805860',
      candidate_count: '2', question_count: '2', quote_count: '6', rankable_question_count: '2',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.frameRef).toEqual({ layer: 'G4110', geoid: '1805860' });
  });

  it('county-council district (X% / district_type COUNTY): frame = the SQL-resolved county', async () => {
    // #3b: the SQL routes X% COUNTY layers to a G4020 container; the mapping
    // passes that frame_layer/frame_geoid straight through.
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rcc', position_name: 'Salt Lake County Council District 5', district_label: 'District 5',
      district_type: 'COUNTY',
      election_id: 'e', election_name: 'UT 2026', election_date: null,
      jurisdiction_level: 'county', state: 'UT',
      boundary_layer: 'X0001', boundary_geoid: 'ocd-division/country:us/state:ut/county:salt_lake/council_district:5',
      frame_layer: 'G4020', frame_geoid: '49035',
      candidate_count: '2', question_count: '1', quote_count: '6', rankable_question_count: '1',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.boundaryRef).toEqual({ layer: 'X0001', geoid: 'ocd-division/country:us/state:ut/county:salt_lake/council_district:5' });
    expect(race.frameRef).toEqual({ layer: 'G4020', geoid: '49035' });
  });

  it('state-leg district: frames against the state outline (frame geometry lazy-loaded)', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rsl', position_name: 'Utah State Senate District 13', district_label: 'District 13',
      district_type: 'STATE_UPPER',
      election_id: 'e', election_name: 'UT 2026', election_date: null,
      jurisdiction_level: 'state', state: 'UT',
      boundary_layer: 'G5210', boundary_geoid: '49013', frame_layer: null, frame_geoid: null,
      candidate_count: '3', question_count: '3', quote_count: '12', rankable_question_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    mockGetDistrictCountyGeoIds.mockResolvedValueOnce(new Map([['G5210:49013', ['49013']]]));
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.boundaryRef).toEqual({ layer: 'G5210', geoid: '49013' }); // no embedded geometry
    expect(race.frameRef).toEqual({ layer: 'G4000', geoid: '49' });       // UT state outline
    expect(race.countyGeoIds).toEqual(['49013']);
  });

  it('school district: frames against the state outline', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'School Board', jurisdiction_level: 'local',
      boundary_layer: 'G5400', boundary_geoid: '1800001', frame_layer: null, frame_geoid: null,
    }] });
    mockGetDistrictCountyGeoIds.mockResolvedValueOnce(new Map([['G5400:1800001', ['18105']]]));
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.boundaryRef).toEqual({ layer: 'G5400', geoid: '1800001' });
    expect(race.frameRef).toEqual({ layer: 'G4000', geoid: '18' }); // IN state outline (BASE_ROW state)
  });

  it('township: frames against the state outline', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'Township Trustee', jurisdiction_level: 'local',
      boundary_layer: 'G4040', boundary_geoid: '1899999', frame_layer: null, frame_geoid: null,
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.frameRef).toEqual({ layer: 'G4000', geoid: '18' }); // IN state outline (BASE_ROW state)
  });

  it('derives office/seat from raw position_name + district_label via deriveOfficeSeat', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rd', position_name: 'Monroe County Commissioner - District 1', district_label: 'District 1',
      district_type: 'COUNTY',
      election_id: 'e', election_name: 'IN 2025', election_date: null,
      jurisdiction_level: 'county', state: 'IN',
      boundary_layer: 'G4020', boundary_geoid: '18105', frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '3', quote_count: '6', rankable_question_count: '2',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.office).toBe('Monroe County Commissioner');
    expect(race.seat).toBe('District 1');
  });

  it('derives seat from positionName for a legislative race when districtLabel equals positionName', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rm', position_name: 'Indiana House of Representatives - District 61', district_label: null,
      district_type: 'STATE_LOWER',
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: 'G5220', boundary_geoid: '18061', frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '3', quote_count: '6', rankable_question_count: '2',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.office).toBe('State Representative');
    expect(race.seat).toBe('District 61');
  });

  it('emits seat:null for a statewide race with no district record', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rg2', position_name: 'Governor', district_label: null, district_type: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: null, boundary_geoid: null, frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '3', quote_count: '8', rankable_question_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.seat).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// Geometry attachment tests
// ---------------------------------------------------------------------------

const BASE_ROW = {
  race_id: 'race-1',
  position_name: 'City Council',
  district_label: null,
  district_type: null,
  election_id: 'election-1',
  election_name: 'Bloomington 2026',
  election_date: null,
  jurisdiction_level: 'local',
  state: 'IN',
  boundary_layer: 'G4110',
  boundary_geoid: '1805860',
  frame_layer: 'G4020',
  frame_geoid: '18105',
  candidate_count: '2',
  question_count: '3',
  quote_count: '6',
  rankable_question_count: '2',
  politician_ids: ['pol-1', 'pol-2'],
};

describe('getPlayableRaces — refs carry no geometry (lazy-loaded client-side)', () => {
  it('returns boundaryRef/frameRef as {layer, geoid} only — no bbox or geojson', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [BASE_ROW] });

    const { races } = await getPlayableRacesResult();

    expect(races).toHaveLength(1);
    // Exact-equality (not toMatchObject) proves no bbox/geojson keys leak into the list.
    expect(races[0].boundaryRef).toEqual({ layer: 'G4110', geoid: '1805860' });
    expect(races[0].frameRef).toEqual({ layer: 'G4020', geoid: '18105' });
  });
});

describe('getPlayableRaces — embed geometry', () => {
  const GEOM_A = { type: 'Polygon' as const, coordinates: [] };
  const GEOM_B = { type: 'Polygon' as const, coordinates: [] };

  it('embeds boundary + frame geometry only for the requested race ids', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [
      { ...BASE_ROW, race_id: 'featured' },
      { ...BASE_ROW, race_id: 'other' },
    ] });
    mockGetBoundaryBatch.mockResolvedValueOnce(new Map([
      ['G4110:1805860', { layer: 'G4110', geoid: '1805860', name: '', bbox: [0, 0, 1, 1], geojson: GEOM_A, hasBoundary: true }],
      ['G4020:18105', { layer: 'G4020', geoid: '18105', name: '', bbox: [0, 0, 2, 2], geojson: GEOM_B, hasBoundary: true }],
    ]));

    const { races } = await getPlayableRaces([], undefined, ['featured']);
    const featured = races.find((r) => r.raceId === 'featured')!;
    const other = races.find((r) => r.raceId === 'other')!;

    expect(featured.boundaryRef).toMatchObject({ layer: 'G4110', geoid: '1805860', bbox: [0, 0, 1, 1], geojson: GEOM_A });
    expect(featured.frameRef).toMatchObject({ layer: 'G4020', geoid: '18105', bbox: [0, 0, 2, 2], geojson: GEOM_B });
    // Non-embedded race stays geometry-free (still lazy-loaded client-side).
    expect(other.boundaryRef).toEqual({ layer: 'G4110', geoid: '1805860' });
    expect(other.frameRef).toEqual({ layer: 'G4020', geoid: '18105' });
  });

  it('does not resolve geometry when no embed ids are given', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [BASE_ROW] });
    await getPlayableRaces();
    expect(mockGetBoundaryBatch).not.toHaveBeenCalled();
  });

  it('embedLocal inlines geometry for the user\'s isLocal races only', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [
      { ...BASE_ROW, race_id: 'mine', politician_ids: ['pol-1'] },  // isLocal via roster match
      { ...BASE_ROW, race_id: 'other', politician_ids: ['pol-9'] }, // not the user's
    ] });
    mockGetBoundaryBatch.mockResolvedValueOnce(new Map([
      ['G4110:1805860', { layer: 'G4110', geoid: '1805860', name: '', bbox: [0, 0, 1, 1], geojson: GEOM_A, hasBoundary: true }],
      ['G4020:18105', { layer: 'G4020', geoid: '18105', name: '', bbox: [0, 0, 2, 2], geojson: GEOM_B, hasBoundary: true }],
    ]));

    const { races } = await getPlayableRaces(['pol-1'], undefined, undefined, true);
    const mine = races.find((r) => r.raceId === 'mine')!;
    const other = races.find((r) => r.raceId === 'other')!;

    expect(mine.isLocal).toBe(true);
    expect(mine.boundaryRef).toMatchObject({ layer: 'G4110', geoid: '1805860', geojson: GEOM_A });
    expect(other.isLocal).toBe(false);
    expect(other.boundaryRef).toEqual({ layer: 'G4110', geoid: '1805860' }); // not embedded
  });
});

describe('getPlayableRaces — countyGeoIds', () => {
  it('populates countyGeoIds for a congressional (G5200) district from the overlapping-county set', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r-cd', position_name: 'U.S. House', district_label: 'District 3', district_type: 'NATIONAL_LOWER',
      election_id: 'e1', election_name: 'General', election_date: null,
      jurisdiction_level: 'federal', state: 'UT',
      boundary_layer: 'G5200', boundary_geoid: '4903',
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '3', quote_count: '9', rankable_question_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    mockGetDistrictCountyGeoIds.mockResolvedValue(new Map([['G5200:4903', ['49035', '49049']]]));
    const { races } = await getPlayableRacesResult();
    expect(races[0].countyGeoIds).toEqual(['49035', '49049']);
  });

  it('leaves a federal race boundary/frame as state-in-US after adding G5200', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r-cd2', position_name: 'U.S. House', district_label: 'District 1', district_type: 'NATIONAL_LOWER',
      election_id: 'e1', election_name: 'General', election_date: null,
      jurisdiction_level: 'federal', state: 'UT',
      boundary_layer: 'G5200', boundary_geoid: '4901',
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '1', quote_count: '3', rankable_question_count: '1',
      politician_ids: ['p1', 'p2'],
    }] });
    mockGetDistrictCountyGeoIds.mockResolvedValue(new Map());
    const { races } = await getPlayableRacesResult();
    expect(races[0].boundaryRef).toEqual({ layer: 'G4000', geoid: '49' });
    expect(races[0].frameRef).toEqual({ layer: 'G4000', geoid: 'US' });
  });

  it('congressional (G5200) district with tier=state (per source data) frames to the state outline but still gets its overlapping-county set', async () => {
    // Some source rows carry jurisdiction_level:'state' for congressional districts, so
    // they miss the tier==='federal' branch. They still frame against the state outline
    // (all sub-state districts do) while their county set comes from the overlap lookup.
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r-cd3', position_name: 'U.S. House', district_label: 'District 9', district_type: 'NATIONAL_LOWER',
      election_id: 'e1', election_name: 'General', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: 'G5200', boundary_geoid: '1809',
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '1', quote_count: '3', rankable_question_count: '1',
      politician_ids: ['p1', 'p2'],
    }] });
    mockGetDistrictCountyGeoIds.mockResolvedValueOnce(new Map([['G5200:1809', ['18001', '18003']]]));
    const { races } = await getPlayableRacesResult();
    expect(races[0].frameRef).toEqual({ layer: 'G4000', geoid: '18' }); // IN state outline
    expect(races[0].countyGeoIds).toEqual(['18001', '18003']);
  });

  it('uses the G4020 frame geoid for a city race', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [BASE_ROW] }); // G4110 framed to G4020 18105
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.countyGeoIds).toEqual(['18105']);
  });

  it('uses the boundary geoid for a county race', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'County Commission',
      jurisdiction_level: 'county',
      boundary_layer: 'G4020', boundary_geoid: '18105',
      frame_layer: null, frame_geoid: null,
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.countyGeoIds).toEqual(['18105']);
  });

  it('uses the union member counties for a state-legislative district', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'State Senate District 21',
      jurisdiction_level: 'state',
      boundary_layer: 'G5210', boundary_geoid: '49021',
      frame_layer: null, frame_geoid: null,
    }] });
    mockGetDistrictCountyGeoIds.mockResolvedValueOnce(new Map([['G5210:49021', ['49035', '49045']]]));
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.countyGeoIds).toEqual(['49035', '49045']);
  });

  it('is [] for a statewide race', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'Governor',
      jurisdiction_level: 'state',
      boundary_layer: null, boundary_geoid: null,
      frame_layer: null, frame_geoid: null,
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.countyGeoIds).toEqual([]);
  });

  it('uses the union member counties for a school district', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'School Board',
      jurisdiction_level: 'local',
      boundary_layer: 'G5400', boundary_geoid: '1800001',
      frame_layer: null, frame_geoid: null,
    }] });
    mockGetDistrictCountyGeoIds.mockResolvedValueOnce(new Map([['G5400:1800001', ['18105']]]));
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.countyGeoIds).toEqual(['18105']);
  });

  it('uses the union member counties for a township', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'Township Trustee',
      jurisdiction_level: 'local',
      boundary_layer: 'G4040', boundary_geoid: '1899999',
      frame_layer: null, frame_geoid: null,
    }] });
    mockGetDistrictCountyGeoIds.mockResolvedValueOnce(new Map([['G4040:1899999', ['18105', '18021']]]));
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.countyGeoIds).toEqual(['18105', '18021']);
  });

  it('is [] for a school district with no resolved county overlap', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'School Board',
      jurisdiction_level: 'local',
      boundary_layer: 'G5400', boundary_geoid: '1800001',
      frame_layer: null, frame_geoid: null,
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.countyGeoIds).toEqual([]);
  });

  it('is [] for a city ward framed to a city, not a county', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      ...BASE_ROW,
      position_name: 'City Council Ward 3',
      boundary_layer: 'X0001', boundary_geoid: 'WARD3',
      frame_layer: 'G4110', frame_geoid: '1805860',
    }] });
    const { races: [race] } = await getPlayableRacesResult();
    expect(race.countyGeoIds).toEqual([]);
  });

  it('assigns every county in the state to a statewide race', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r-gov', position_name: 'Governor', district_label: null, district_type: null,
      election_id: 'e1', election_name: 'General', election_date: null,
      jurisdiction_level: 'state', state: 'UT',
      boundary_layer: 'G4000', boundary_geoid: '49',
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '4', quote_count: '8', rankable_question_count: '4',
      politician_ids: ['p1', 'p2'],
    }] });
    mockGetStateCountyGeoIds.mockResolvedValue(new Map([['UT', ['49035', '49049', '49011']]]));
    const { races } = await getPlayableRacesResult();
    expect(races[0].scope).toBe('statewide');
    expect(races[0].countyGeoIds).toEqual(['49035', '49049', '49011']);
    expect(mockGetStateCountyGeoIds).toHaveBeenCalledWith(['UT']);
  });
});

describe('getPlayableRaces — counties name index', () => {
  it('returns a counties name index covering every referenced GEOID', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r-gov', position_name: 'Governor', district_label: null, district_type: null,
      election_id: 'e1', election_name: 'General', election_date: null,
      jurisdiction_level: 'state', state: 'UT',
      boundary_layer: 'G4000', boundary_geoid: '49',
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '4', quote_count: '8', rankable_question_count: '4',
      politician_ids: ['p1', 'p2'],
    }] });
    mockGetStateCountyGeoIds.mockResolvedValue(new Map([['UT', ['49035']]]));
    mockGetCountyNames.mockResolvedValue({ '49035': 'Salt Lake County' });
    const { races, counties } = await getPlayableRacesResult();
    expect(races[0].countyGeoIds).toEqual(['49035']);
    expect(counties).toEqual({ '49035': 'Salt Lake County' });
    expect(mockGetCountyNames).toHaveBeenCalledWith(['49035']);
  });
});

describe('getPlayableRaces — geographic isLocal', () => {
  function congressionalRow(overrides: Partial<Record<string, unknown>> = {}) {
    return {
      race_id: 'r-cd', position_name: 'US Representative', district_label: 'District 9', district_type: 'NATIONAL_LOWER',
      election_id: 'e1', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'federal', state: 'IN',
      boundary_layer: 'G5200', boundary_geoid: '1809',
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '3', quote_count: '6', rankable_question_count: '3',
      politician_ids: ['p1', 'p2'],
      ...overrides,
    };
  }

  it('is isLocal when the user jurisdiction congressional GEOID matches the race boundary_geoid, even with no roster overlap', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [congressionalRow()] });
    const jurisdiction: JurisdictionGeoIds = {
      congressional: '1809', state_senate: null, state_house: null, county: null, school_district: null,
    };
    const { races: [race] } = await getPlayableRacesResult([], jurisdiction);
    expect(race.isLocal).toBe(true);
  });

  it('is NOT isLocal when the user jurisdiction congressional GEOID does not match the race boundary_geoid', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [congressionalRow()] });
    const jurisdiction: JurisdictionGeoIds = {
      congressional: '1801', state_senate: null, state_house: null, county: null, school_district: null,
    };
    const { races: [race] } = await getPlayableRacesResult([], jurisdiction);
    expect(race.isLocal).toBe(false);
  });

  it('falls back to roster match when geography does not resolve (no jurisdiction)', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [congressionalRow()] });
    const { races: [race] } = await getPlayableRacesResult(['p2']);
    expect(race.isLocal).toBe(true);
  });

  it('a statewide race (no district boundary_geoid) is not geo-matched and relies on roster', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r-gov', position_name: 'Governor', district_label: null, district_type: null,
      election_id: 'e2', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: null, boundary_geoid: null,
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '3', quote_count: '8', rankable_question_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const jurisdiction: JurisdictionGeoIds = {
      congressional: '1809', state_senate: null, state_house: null, county: null, school_district: null,
    };
    // No roster overlap -> not local even though a jurisdiction is present (statewide has no district geoid to match).
    const { races: [race] } = await getPlayableRacesResult([], jurisdiction);
    expect(race.isLocal).toBe(false);

    // Roster overlap -> local via fallback.
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r-gov', position_name: 'Governor', district_label: null, district_type: null,
      election_id: 'e2', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: null, boundary_geoid: null,
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '3', quote_count: '8', rankable_question_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const { races: [race2] } = await getPlayableRacesResult(['p1'], jurisdiction);
    expect(race2.isLocal).toBe(true);
  });
});

describe('deriveOfficeSeat', () => {
  it('legislative STATE_LOWER: office from district_type, seat extracted from chamber label', () => {
    expect(deriveOfficeSeat({
      positionName: 'Utah State House District 21', districtLabel: 'State House District 21',
      districtType: 'STATE_LOWER', state: 'UT',
    })).toEqual({ office: 'State Representative', seat: 'District 21' });
  });

  it('legislative STATE_UPPER -> State Senator', () => {
    expect(deriveOfficeSeat({
      positionName: 'Utah State Senate District 13', districtLabel: 'State Senate District 13',
      districtType: 'STATE_UPPER', state: 'UT',
    })).toEqual({ office: 'State Senator', seat: 'District 13' });
  });

  it('legislative NATIONAL_LOWER: word-ordinal + federal abbreviation', () => {
    expect(deriveOfficeSeat({
      positionName: 'United States Representative, Ninth District', districtLabel: 'Ninth District',
      districtType: 'NATIONAL_LOWER', state: 'IN',
    })).toEqual({ office: 'US Representative', seat: 'District 9' });
  });

  it('legislative: strips leading zeros from the seat', () => {
    expect(deriveOfficeSeat({
      positionName: 'State Representative, District 061', districtLabel: 'District 061',
      districtType: 'STATE_LOWER', state: 'IN',
    })).toEqual({ office: 'State Representative', seat: 'District 61' });
  });

  it('legislative: recovers seat from positionName when districtLabel is null', () => {
    expect(deriveOfficeSeat({
      positionName: 'Utah State House District 44', districtLabel: null,
      districtType: 'STATE_LOWER', state: 'UT',
    })).toEqual({ office: 'State Representative', seat: 'District 44' });
  });

  it('county executive: keeps place-qualified office, takes seat from label', () => {
    expect(deriveOfficeSeat({
      positionName: 'Monroe County Commissioner', districtLabel: 'District 1',
      districtType: 'COUNTY', state: 'IN',
    })).toEqual({ office: 'Monroe County Commissioner', seat: 'District 1' });
  });

  it('city executive: keeps the place in the office, no seat', () => {
    expect(deriveOfficeSeat({
      positionName: 'Los Angeles Mayor', districtLabel: null,
      districtType: 'LOCAL_EXEC', state: 'CA',
    })).toEqual({ office: 'Los Angeles Mayor', seat: null });
  });

  it('statewide exec: drops a redundant state abbreviation prefix', () => {
    expect(deriveOfficeSeat({
      positionName: 'CA Governor', districtLabel: null, districtType: null, state: 'CA',
    })).toEqual({ office: 'Governor', seat: null });
  });

  it('statewide exec: drops a redundant full-state-name prefix', () => {
    expect(deriveOfficeSeat({
      positionName: 'California Governor', districtLabel: null, districtType: null, state: 'CA',
    })).toEqual({ office: 'Governor', seat: null });
  });

  it('at-large seat normalizes spelling', () => {
    expect(deriveOfficeSeat({
      positionName: 'City Council', districtLabel: 'At Large', districtType: 'LOCAL', state: 'IN',
    })).toEqual({ office: 'City Council', seat: 'At-Large' });
  });

  it('exec: splits seat on a hyphen separator', () => {
    expect(deriveOfficeSeat({
      positionName: 'Monroe County Commissioner - District 1', districtLabel: null,
      districtType: 'COUNTY', state: 'IN',
    })).toEqual({ office: 'Monroe County Commissioner', seat: 'District 1' });
  });

  it('exec: splits seat on an en-dash separator', () => {
    expect(deriveOfficeSeat({
      positionName: 'Monroe County Commissioner – District 2', districtLabel: null,
      districtType: 'COUNTY', state: 'IN',
    })).toEqual({ office: 'Monroe County Commissioner', seat: 'District 2' });
  });
});

describe('computeRaceMatch — office title via current_office_holders (migration 1463)', () => {
  // Title deliberately avoids spelling the dropped column as <alias>.politician_id:
  // check-office-occupancy.mjs scans whole changed files and strips comments but not
  // string literals, so the literal form in a test name reads as a live violation.
  it('resolves the office title through the current_office_holders view, not the politician_id column dropped from essentials.offices', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [{
        quote_id: 'q1', politician_id: 'p1', topic_key: 'housing', deidentified_text: 'Build more homes.',
        source_name: null, source_url: null, full_name: 'Alex Doe', photo: null,
        office_title: 'State Senator', topic_title: 'Housing', position_name: 'Governor',
      }],
    });

    const result = await computeRaceMatch('race-1', [{ quote_id: 'q1', supported: true, rank: 1 }]);

    expect(result).not.toBeNull();
    expect(result!.positionName).toBe('Governor');
    expect(result!.ballot[0]).toMatchObject({ candidateId: 'p1', name: 'Alex Doe', office: 'State Senator' });

    const sql = mockQuery.mock.calls[0][0] as string;
    // 1463 dropped essentials.offices.politician_id — occupancy must resolve through the view.
    expect(sql).toContain('essentials.current_office_holders');
    expect(sql).toMatch(/coh\.politician_id\s*=\s*p\.id/);
    // The pre-1463 shape: an unqualified politician_id filter directly on essentials.offices
    // (42702 ambiguous / 42703 undefined against the live schema).
    expect(sql).not.toMatch(/essentials\.offices\s+WHERE\s+politician_id/i);
  });
});

describe('getRaceBlindQuotes — resolved ranking question (override ?? compass)', () => {
  it('maps the resolved topic_question into the payload and LEFT JOINs the override table', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [
        { quote_id: 'q1', deidentified_text: 'Answer one.', topic_key: 'fossil-fuels', politician_id: 'p1', topic_title: 'Fossil fuels', topic_question: 'RESOLVED QUESTION', position_name: 'Governor' },
        { quote_id: 'q2', deidentified_text: 'Answer two.', topic_key: 'fossil-fuels', politician_id: 'p2', topic_title: 'Fossil fuels', topic_question: 'RESOLVED QUESTION', position_name: 'Governor' },
      ],
    });

    const payload = await getRaceBlindQuotes('race-1');

    expect(payload).not.toBeNull();
    expect(payload!.topics).toHaveLength(1);
    expect(payload!.topics[0].question).toBe('RESOLVED QUESTION');
    expect(payload!.topics[0].quotes).toHaveLength(2);

    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toContain('essentials.readrank_race_topic_questions');
    // The COALESCE gained a third, higher-priority source (rq = the quote's own
    // readrank_question), because a topic with no Compass row has no Compass
    // question_text to fall back to. The override-beats-compass ordering asserted
    // here is unchanged.
    // The Compass arm reads `ctc` (compass_topics_current), not `ct`: ADR 0004's
    // content repoint moved question text onto the current revision, because
    // CA_0012 froze compass_topics' own text columns. `ct` still matches the row
    // and still carries the is_live kill switch — see the service.
    expect(sql).toMatch(/COALESCE\(\s*rq\.question_text\s*,\s*rtq\.question_text\s*,\s*ctc\.question_text\s*\)/);
  });
});

describe('computeRaceMatch — candidates you judged but never agreed with', () => {
  // Two candidates on one topic. The SQL only returns quotes whose ids were
  // submitted, so which of these the user judged is controlled by the verdicts.
  const rows = [
    {
      quote_id: 'q1', politician_id: 'p1', topic_key: 'housing', deidentified_text: 'Build more homes.',
      source_name: 'Debate', source_url: 'https://example.com/debate', full_name: 'Alex Doe', photo: null,
      office_title: 'State Senator', topic_title: 'Housing', position_name: 'Governor',
    },
    {
      quote_id: 'q2', politician_id: 'p2', topic_key: 'housing', deidentified_text: 'Build fewer homes.',
      source_name: 'Townhall', source_url: 'https://example.com/townhall', full_name: 'Blair Roe', photo: null,
      office_title: 'Council Member', topic_title: 'Housing', position_name: 'Governor',
    },
  ];

  it('puts a candidate you only disagreed with on the ballot, unranked, after the ranked ones', async () => {
    mockQuery.mockResolvedValueOnce({ rows });

    const result = await computeRaceMatch('race-1', [
      { quote_id: 'q1', supported: true, rank: 1 },
      { quote_id: 'q2', supported: false, rank: null },
    ]);

    expect(result!.ballot).toHaveLength(2);
    expect(result!.ballot[0]).toMatchObject({ candidateId: 'p1', rank: 1 });
    expect(result!.ballot[1]).toMatchObject({ candidateId: 'p2', rank: null });
    expect(result!.ballot[1].evidence).toEqual({
      agreementCount: 0, firstPlaceCount: 0, topicsWithAgreement: 0,
    });
  });

  it('still carries the unranked candidate\'s quotes and provenance', async () => {
    mockQuery.mockResolvedValueOnce({ rows });

    const result = await computeRaceMatch('race-1', [
      { quote_id: 'q1', supported: true, rank: 1 },
      { quote_id: 'q2', supported: false, rank: null },
    ]);

    const unranked = result!.ballot.find((e) => e.rank === null)!;
    expect(unranked.perTopic).toHaveLength(1);
    expect(unranked.perTopic[0].quotes).toEqual([
      expect.objectContaining({
        quoteId: 'q2', supported: false, rank: null,
        sourceName: 'Townhall', sourceUrl: 'https://example.com/townhall',
      }),
    ]);
    // Nobody won a topic the user agreed with nothing on for this candidate.
    expect(unranked.perTopic[0].userTopWinner).toBe(false);
  });

  it('returns every judged candidate unranked when nothing was agreed', async () => {
    mockQuery.mockResolvedValueOnce({ rows });

    const result = await computeRaceMatch('race-1', [
      { quote_id: 'q1', supported: false, rank: null },
      { quote_id: 'q2', supported: false, rank: null },
    ]);

    expect(result!.ballot).toHaveLength(2);
    expect(result!.ballot.every((e) => e.rank === null)).toBe(true);
    expect(result!.ballot.every((e) => e.evidence.agreementCount === 0)).toBe(true);
  });

  it('leaves out candidates the user never judged', async () => {
    mockQuery.mockResolvedValueOnce({ rows });

    const result = await computeRaceMatch('race-1', [{ quote_id: 'q1', supported: true, rank: 1 }]);

    expect(result!.ballot).toHaveLength(1);
    expect(result!.ballot[0].candidateId).toBe('p1');
  });

  it('orders the unranked tail deterministically, not by row order', async () => {
    // The reveal SQL has no ORDER BY, so row order is not guaranteed stable
    // across identical requests. Reversing it must not reshuffle the ballot.
    mockQuery.mockResolvedValueOnce({ rows: [...rows].reverse() });

    const result = await computeRaceMatch('race-1', [
      { quote_id: 'q1', supported: false, rank: null },
      { quote_id: 'q2', supported: false, rank: null },
    ]);

    expect(result!.ballot.map((e) => e.name)).toEqual(['Alex Doe', 'Blair Roe']);
  });
});

// ---------------------------------------------------------------------------
// A question can ship without a live Compass topic.
//
// The four inner joins on inform.compass_topics became LEFT JOINs, so a quote
// whose topic_key has no Compass row now reaches the payload — and arrives with
// topic_title NULL. The readable heading is derived in TypeScript (here, where
// it is testable) rather than in SQL, because pool.query is mocked in this file
// and no SQL behaviour is exercised by these tests at all.
// ---------------------------------------------------------------------------

describe('topicTitleFromKey', () => {
  it('title-cases a hyphenated key: israel-aid -> Israel Aid', () => {
    expect(topicTitleFromKey('israel-aid')).toBe('Israel Aid');
  });

  it('title-cases a single-word key: housing -> Housing', () => {
    expect(topicTitleFromKey('housing')).toBe('Housing');
  });

  it('title-cases a multi-hyphen key: public-safety-approach -> Public Safety Approach', () => {
    expect(topicTitleFromKey('public-safety-approach')).toBe('Public Safety Approach');
  });

  it('handles underscores the same way as hyphens', () => {
    expect(topicTitleFromKey('gun_policy')).toBe('Gun Policy');
  });

  it('normalises an already-cased or spaced key rather than doubling separators', () => {
    expect(topicTitleFromKey('ISRAEL--AID')).toBe('Israel Aid');
    expect(topicTitleFromKey('  israel aid  ')).toBe('Israel Aid');
  });

  it('returns an empty string for an empty, whitespace-only, or missing key', () => {
    // A heading is a user-facing string; there is nothing honest to invent from
    // no key at all, so the caller falls back to '' exactly as it did before.
    expect(topicTitleFromKey('')).toBe('');
    expect(topicTitleFromKey('   ')).toBe('');
    expect(topicTitleFromKey('---')).toBe('');
    expect(topicTitleFromKey(null)).toBe('');
    expect(topicTitleFromKey(undefined)).toBe('');
  });
});

describe('getRaceBlindQuotes — topic with no live Compass topic', () => {
  it('derives the heading from topic_key when topic_title is NULL', async () => {
    // What a non-Compass topic looks like coming back from the LEFT JOIN:
    // ct.short_title and ct.question_text are both NULL; the question is
    // supplied by essentials.readrank_questions instead.
    mockQuery.mockResolvedValueOnce({
      rows: [
        { quote_id: 'q1', deidentified_text: 'Conditions on aid.', topic_key: 'israel-aid', politician_id: 'p1', topic_title: null, topic_question: 'Should US aid to Israel carry conditions?', position_name: 'U.S. Senate' },
        { quote_id: 'q2', deidentified_text: 'No conditions.', topic_key: 'israel-aid', politician_id: 'p2', topic_title: null, topic_question: 'Should US aid to Israel carry conditions?', position_name: 'U.S. Senate' },
      ],
    });

    const payload = await getRaceBlindQuotes('race-mi-senate');

    expect(payload).not.toBeNull();
    expect(payload!.topics).toHaveLength(1);
    expect(payload!.topics[0].title).toBe('Israel Aid');
    expect(payload!.topics[0].question).toBe('Should US aid to Israel carry conditions?');
    expect(payload!.topics[0].quotes).toHaveLength(2);
    // Blindness invariant: no attribution leaks onto the blind card. `cardKey` was
    // added when cards became per-question — it names the QUESTION, not the speaker,
    // so it widens the shape without weakening the premise.
    for (const q of payload!.topics[0].quotes) {
      expect(Object.keys(q).sort()).toEqual(['candidateToken', 'cardKey', 'id', 'text', 'topicKey']);
    }
  });

  it('prefers a real Compass short_title over the derived one', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [
        { quote_id: 'q1', deidentified_text: 'Build more homes.', topic_key: 'housing', politician_id: 'p1', topic_title: 'Housing', topic_question: 'Q?', position_name: 'Mayor' },
      ],
    });

    const payload = await getRaceBlindQuotes('race-1');

    expect(payload!.topics[0].title).toBe('Housing');
  });

  it('keeps a Compass short_title that differs from the key title-cased', async () => {
    // Guards against a fallback that silently overwrites curated wording:
    // 'fossil-fuels' would derive as 'Fossil Fuels', but Compass says otherwise.
    mockQuery.mockResolvedValueOnce({
      rows: [
        { quote_id: 'q1', deidentified_text: 'Phase them out.', topic_key: 'fossil-fuels', politician_id: 'p1', topic_title: 'Fossil fuels', topic_question: 'Q?', position_name: 'Governor' },
      ],
    });

    const payload = await getRaceBlindQuotes('race-1');

    expect(payload!.topics[0].title).toBe('Fossil fuels');
  });

  it('resolves the question across question -> race override -> compass', async () => {
    // Weak structural guard: pool.query is mocked, so the COALESCE is never
    // executed. This only asserts the three sources appear in the right order
    // in the SQL text — it does NOT prove the database resolves them correctly.
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getRaceBlindQuotes('race-1');

    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toMatch(/COALESCE\(\s*rq\.question_text\s*,\s*rtq\.question_text\s*,\s*ctc\.question_text\s*\)/);
    expect(sql).toContain('essentials.readrank_questions rq');
  });
});

describe('computeRaceMatch — topic with no live Compass topic', () => {
  it('derives the per-topic heading from topic_key when topic_title is NULL', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [{
        quote_id: 'q1', politician_id: 'p1', topic_key: 'israel-aid', deidentified_text: 'Conditions on aid.',
        source_name: 'Debate', source_url: 'https://example.com/debate', full_name: 'Alex Doe', photo: null,
        office_title: 'State Senator', topic_title: null, position_name: 'U.S. Senate',
      }],
    });

    const result = await computeRaceMatch('race-mi-senate', [{ quote_id: 'q1', supported: true, rank: 1 }]);

    expect(result!.ballot).toHaveLength(1);
    expect(result!.ballot[0].perTopic[0]).toMatchObject({ topicKey: 'israel-aid', title: 'Israel Aid' });
  });

  it('prefers a real Compass short_title at the reveal too', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [{
        quote_id: 'q1', politician_id: 'p1', topic_key: 'housing', deidentified_text: 'Build more homes.',
        source_name: null, source_url: null, full_name: 'Alex Doe', photo: null,
        office_title: 'State Senator', topic_title: 'Housing', position_name: 'Governor',
      }],
    });

    const result = await computeRaceMatch('race-1', [{ quote_id: 'q1', supported: true, rank: 1 }]);

    expect(result!.ballot[0].perTopic[0].title).toBe('Housing');
  });
});

// ---------------------------------------------------------------------------
// The QUESTION is the unit of comparison, not the topic.
//
// 1377 made essentials.readrank_questions first-class: one topic can host several
// questions (LA Mayor's economic-development topic hosts a film/TV question and a
// downtown question). The player path used to bucket by lower(topic_key), so two
// questions in one topic merged into a single card that paired answers to DIFFERENT
// questions under whichever question text happened to arrive first.
//
// Cards are keyed by question_id, falling back to 'topic:<topic_key>' — compass-era
// quotes predate question_id and must still group by topic.
// ---------------------------------------------------------------------------

describe('getRaceBlindQuotes — one card per question', () => {
  /** Two econ-dev questions in one topic: the film pair and the downtown pair. */
  const splitTopicRows = [
    {
      quote_id: 'bass-film', deidentified_text: 'Keep film production here.', topic_key: 'economic-development',
      politician_id: 'bass', question_id: 'q-film', topic_title: 'Economic Development',
      topic_question: 'How would you keep film and TV production in the city?', position_name: 'Los Angeles Mayor',
    },
    {
      quote_id: 'raman-film', deidentified_text: 'Subsidies are the wrong tool.', topic_key: 'economic-development',
      politician_id: 'raman', question_id: 'q-film', topic_title: 'Economic Development',
      topic_question: 'How would you keep film and TV production in the city?', position_name: 'Los Angeles Mayor',
    },
    {
      quote_id: 'bass-downtown', deidentified_text: 'Convert offices to housing.', topic_key: 'economic-development',
      politician_id: 'bass', question_id: 'q-downtown', topic_title: 'Economic Development',
      topic_question: 'What is your plan for downtown?', position_name: 'Los Angeles Mayor',
    },
    {
      quote_id: 'raman-downtown', deidentified_text: 'Invest in transit first.', topic_key: 'economic-development',
      politician_id: 'raman', question_id: 'q-downtown', topic_title: 'Economic Development',
      topic_question: 'What is your plan for downtown?', position_name: 'Los Angeles Mayor',
    },
  ];

  it('splits two questions in one topic into two cards, each with its own question text', async () => {
    mockQuery.mockResolvedValueOnce({ rows: splitTopicRows });

    const payload = await getRaceBlindQuotes('race-la-mayor');

    expect(payload!.topics).toHaveLength(2);
    const byQuestionId = new Map(payload!.topics.map((t) => [t.questionId, t]));
    expect([...byQuestionId.keys()].sort()).toEqual(['q-downtown', 'q-film']);

    const film = byQuestionId.get('q-film')!;
    expect(film.question).toBe('How would you keep film and TV production in the city?');
    expect(film.quotes.map((q) => q.id).sort()).toEqual(['bass-film', 'raman-film']);

    const downtown = byQuestionId.get('q-downtown')!;
    expect(downtown.question).toBe('What is your plan for downtown?');
    expect(downtown.quotes.map((q) => q.id).sort()).toEqual(['bass-downtown', 'raman-downtown']);
  });

  it('never pairs answers to different questions on one card', async () => {
    mockQuery.mockResolvedValueOnce({ rows: splitTopicRows });

    const payload = await getRaceBlindQuotes('race-la-mayor');

    // The corruption this fix exists to prevent: a card whose quotes answer more
    // than one question, displayed under a single question heading.
    const quoteQuestion: Record<string, string> = {
      'bass-film': 'q-film', 'raman-film': 'q-film',
      'bass-downtown': 'q-downtown', 'raman-downtown': 'q-downtown',
    };
    for (const card of payload!.topics) {
      const answered = new Set(card.quotes.map((q) => quoteQuestion[q.id]));
      expect([...answered]).toEqual([card.questionId]);
    }
  });

  it('stamps each quote with its own card key', async () => {
    // The game client routes a verdict by looking the card up from the QUOTE
    // (`race.topics[quote.topicKey]`). With two cards sharing a topicKey the quote
    // has to carry the card key itself, or an agree/disagree lands on the wrong card.
    mockQuery.mockResolvedValueOnce({ rows: splitTopicRows });

    const payload = await getRaceBlindQuotes('race-la-mayor');

    for (const card of payload!.topics) {
      for (const quote of card.quotes) expect(quote.cardKey).toBe(card.key);
    }
    const film = payload!.topics.find((t) => t.questionId === 'q-film')!;
    expect(film.quotes.map((q) => q.cardKey)).toEqual(['q-film', 'q-film']);
  });

  it('keeps the blind payload free of attribution after adding cardKey', async () => {
    // cardKey names the QUESTION, never the speaker, so it cannot de-anonymise a
    // card. This restates the blindness invariant over the widened quote shape.
    mockQuery.mockResolvedValueOnce({ rows: splitTopicRows });

    const payload = await getRaceBlindQuotes('race-la-mayor');

    for (const card of payload!.topics) {
      for (const quote of card.quotes) {
        expect(Object.keys(quote).sort()).toEqual(['cardKey', 'candidateToken', 'id', 'text', 'topicKey'].sort());
      }
    }
  });

  it('gives each card a distinct key while both keep the real topicKey', async () => {
    mockQuery.mockResolvedValueOnce({ rows: splitTopicRows });

    const payload = await getRaceBlindQuotes('race-la-mayor');

    // topicKey stays truthful (both cards ARE economic-development) — `key` is what
    // consumers must group by. A consumer keying a map by topicKey drops a card.
    expect(payload!.topics.map((t) => t.topicKey)).toEqual(['economic-development', 'economic-development']);
    expect(new Set(payload!.topics.map((t) => t.key)).size).toBe(2);
  });

  it('still groups compass-era quotes (question_id NULL) by topic', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [
        { quote_id: 'q1', deidentified_text: 'Build more homes.', topic_key: 'housing', politician_id: 'p1', question_id: null, topic_title: 'Housing', topic_question: 'Q?', position_name: 'Governor' },
        { quote_id: 'q2', deidentified_text: 'Build fewer homes.', topic_key: 'housing', politician_id: 'p2', question_id: null, topic_title: 'Housing', topic_question: 'Q?', position_name: 'Governor' },
      ],
    });

    const payload = await getRaceBlindQuotes('race-1');

    expect(payload!.topics).toHaveLength(1);
    expect(payload!.topics[0]).toMatchObject({ key: 'topic:housing', topicKey: 'housing', questionId: null });
    expect(payload!.topics[0].quotes).toHaveLength(2);
  });

  it('separates a question-bearing card from a compass-era card in the same topic', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [
        { quote_id: 'q1', deidentified_text: 'Legacy answer.', topic_key: 'housing', politician_id: 'p1', question_id: null, topic_title: 'Housing', topic_question: 'Compass question?', position_name: 'Governor' },
        { quote_id: 'q2', deidentified_text: 'Question answer.', topic_key: 'housing', politician_id: 'p2', question_id: 'q-zoning', topic_title: 'Housing', topic_question: 'Would you upzone?', position_name: 'Governor' },
      ],
    });

    const payload = await getRaceBlindQuotes('race-1');

    expect(payload!.topics).toHaveLength(2);
    expect(payload!.topics.map((t) => t.key).sort()).toEqual(['q-zoning', 'topic:housing']);
  });

  it('selects question_id and orders cards deterministically within a topic', async () => {
    // Structural guard: pool.query is mocked, so the grouping key can only be
    // trusted if the SQL actually returns question_id, and card order within a
    // topic is only stable if the ORDER BY reaches past the topic title.
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getRaceBlindQuotes('race-1');

    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toMatch(/q\.question_id/);
    expect(sql).toMatch(/ORDER BY[\s\S]*COALESCE\(ctc\.short_title, lower\(q\.topic_key\)\)[\s\S]*q\.question_id/);
  });
});

describe('getPlayableRaces — playability is measured in questions', () => {
  it('counts questions, not topics, for playability', async () => {
    // A split topic advertises TWO playable cards. Counting topics reported one,
    // understating the race and disagreeing with the admin coverage grid.
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r-la', position_name: 'Los Angeles Mayor', district_label: null, district_type: 'LOCAL_EXEC',
      election_id: 'e1', election_name: 'LA 2026', election_date: null,
      jurisdiction_level: 'county', state: 'CA',
      boundary_layer: 'G4110', boundary_geoid: '0644000',
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', question_count: '2', quote_count: '4', rankable_question_count: '2',
      politician_ids: ['bass', 'raman'],
    }] });

    const { races: [race] } = await getPlayableRacesResult();

    expect(race.questionCount).toBe(2);
    expect(race.rankableQuestionCount).toBe(2);
    // The pre-question wire names stay, carrying the same numbers, because the
    // game client reads `rankableTopicCount ?? topicCount`. Renaming them without
    // a coordinated client release would zero out every race card's progress.
    expect(race.topicCount).toBe(2);
    expect(race.rankableTopicCount).toBe(2);
  });

  it('keys both playability counts on the question, with the topic fallback', async () => {
    // Structural guard: the counting happens in SQL and pool.query is mocked, so
    // this asserts the grouping key rather than the arithmetic. A GROUP BY on bare
    // lower(topic_key) is the defect — it merges two questions into one rankable
    // unit and passes a 2-candidate check that no single question satisfies.
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getPlayableRacesResult();

    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toContain("COUNT(DISTINCT COALESCE(q.question_id::text, 'topic:' || lower(q.topic_key)))");
    expect(sql).toContain("GROUP BY COALESCE(q2.question_id::text, 'topic:' || lower(q2.topic_key))");
    expect(sql).not.toMatch(/GROUP BY lower\(q2\.topic_key\)/);
  });
});

// ---------------------------------------------------------------------------
// The reveal must not merge two questions' rankings.
//
// computeRaceMatch grouped perTopic (and the userTopWinner tie-break) by
// lower(topic_key). With two questions in one topic that silently pooled both
// questions' quotes into a single reveal section and awarded ONE winner across
// answers to two different questions.
// ---------------------------------------------------------------------------

describe('computeRaceMatch — the reveal is keyed by question', () => {
  const splitTopicRows = [
    {
      quote_id: 'bass-film', politician_id: 'bass', topic_key: 'economic-development', question_id: 'q-film',
      deidentified_text: 'Keep film production here.', source_name: 'Debate', source_url: 'https://example.com/d',
      full_name: 'Karen Bass', photo: null, office_title: 'Mayor', topic_title: 'Economic Development',
      topic_question: 'How would you keep film and TV production in the city?', position_name: 'Los Angeles Mayor',
    },
    {
      quote_id: 'raman-film', politician_id: 'raman', topic_key: 'economic-development', question_id: 'q-film',
      deidentified_text: 'Subsidies are the wrong tool.', source_name: 'Forum', source_url: 'https://example.com/f',
      full_name: 'Nithya Raman', photo: null, office_title: 'Council Member', topic_title: 'Economic Development',
      topic_question: 'How would you keep film and TV production in the city?', position_name: 'Los Angeles Mayor',
    },
    {
      quote_id: 'bass-downtown', politician_id: 'bass', topic_key: 'economic-development', question_id: 'q-downtown',
      deidentified_text: 'Convert offices to housing.', source_name: 'Debate', source_url: 'https://example.com/d',
      full_name: 'Karen Bass', photo: null, office_title: 'Mayor', topic_title: 'Economic Development',
      topic_question: 'What is your plan for downtown?', position_name: 'Los Angeles Mayor',
    },
    {
      quote_id: 'raman-downtown', politician_id: 'raman', topic_key: 'economic-development', question_id: 'q-downtown',
      deidentified_text: 'Invest in transit first.', source_name: 'Forum', source_url: 'https://example.com/f',
      full_name: 'Nithya Raman', photo: null, office_title: 'Council Member', topic_title: 'Economic Development',
      topic_question: 'What is your plan for downtown?', position_name: 'Los Angeles Mayor',
    },
  ];

  it('gives a candidate one reveal section per question, not one per topic', async () => {
    mockQuery.mockResolvedValueOnce({ rows: splitTopicRows });

    const result = await computeRaceMatch('race-la-mayor', [
      { quote_id: 'bass-film', supported: true, rank: 1 },
      { quote_id: 'bass-downtown', supported: true, rank: 2 },
    ]);

    const bass = result!.ballot.find((b) => b.candidateId === 'bass')!;
    expect(bass.perTopic).toHaveLength(2);
    expect(bass.perTopic.map((t) => t.questionId).sort()).toEqual(['q-downtown', 'q-film']);
    for (const section of bass.perTopic) {
      expect(section.quotes).toHaveLength(1);
      expect(section.topicKey).toBe('economic-development');
    }
  });

  it('carries the question text so two sections of one topic are distinguishable', async () => {
    // Both sections share the topic short_title, so without the question text the
    // reveal shows the same heading twice with no way to tell them apart.
    mockQuery.mockResolvedValueOnce({ rows: splitTopicRows });

    const result = await computeRaceMatch('race-la-mayor', [
      { quote_id: 'bass-film', supported: true, rank: 1 },
      { quote_id: 'bass-downtown', supported: true, rank: 2 },
    ]);

    const bass = result!.ballot.find((b) => b.candidateId === 'bass')!;
    const byQuestion = new Map(bass.perTopic.map((t) => [t.questionId, t.question]));
    expect(byQuestion.get('q-film')).toBe('How would you keep film and TV production in the city?');
    expect(byQuestion.get('q-downtown')).toBe('What is your plan for downtown?');
  });

  it('decides userTopWinner per question, so each candidate can win their own', async () => {
    mockQuery.mockResolvedValueOnce({ rows: splitTopicRows });

    const result = await computeRaceMatch('race-la-mayor', [
      { quote_id: 'bass-film', supported: true, rank: 1 },
      { quote_id: 'raman-film', supported: true, rank: 2 },
      { quote_id: 'bass-downtown', supported: true, rank: 2 },
      { quote_id: 'raman-downtown', supported: true, rank: 1 },
    ]);

    const winner = (candidateId: string, questionId: string) =>
      result!.ballot.find((b) => b.candidateId === candidateId)!
        .perTopic.find((t) => t.questionId === questionId)!.userTopWinner;

    // Topic-keyed, the single rank-1 for the whole topic went to whoever was seen
    // first (bass), and raman won nothing despite topping the downtown question.
    expect(winner('bass', 'q-film')).toBe(true);
    expect(winner('bass', 'q-downtown')).toBe(false);
    expect(winner('raman', 'q-downtown')).toBe(true);
    expect(winner('raman', 'q-film')).toBe(false);
  });

  it('counts agreement in questions, not topics', async () => {
    mockQuery.mockResolvedValueOnce({ rows: splitTopicRows });

    const result = await computeRaceMatch('race-la-mayor', [
      { quote_id: 'bass-film', supported: true, rank: 1 },
      { quote_id: 'bass-downtown', supported: true, rank: 2 },
    ]);

    const bass = result!.ballot.find((b) => b.candidateId === 'bass')!;
    // Two agreements on two distinct questions. Topic-keyed this reported 1,
    // understating breadth of agreement against a question-keyed denominator.
    expect(bass.evidence.agreementCount).toBe(2);
    expect(bass.evidence.topicsWithAgreement).toBe(2);
  });

  it('still keys compass-era quotes (question_id NULL) by topic', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [{
        quote_id: 'q1', politician_id: 'p1', topic_key: 'housing', question_id: null,
        deidentified_text: 'Build more homes.', source_name: null, source_url: null,
        full_name: 'Alex Doe', photo: null, office_title: 'State Senator',
        topic_title: 'Housing', topic_question: 'Q?', position_name: 'Governor',
      }],
    });

    const result = await computeRaceMatch('race-1', [{ quote_id: 'q1', supported: true, rank: 1 }]);

    expect(result!.ballot[0].perTopic).toHaveLength(1);
    expect(result!.ballot[0].perTopic[0]).toMatchObject({
      key: 'topic:housing', topicKey: 'housing', questionId: null, userTopWinner: true,
    });
  });

  it('selects question_id and resolves the question text in SQL', async () => {
    // Structural guard: pool.query is mocked, so the grouping key is only real if
    // the reveal query returns question_id, and the heading is only disambiguated
    // if it resolves question text through the same three sources as the payload.
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await computeRaceMatch('race-1', [{ quote_id: 'q1', supported: true, rank: 1 }]);

    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toMatch(/q\.question_id/);
    expect(sql).toMatch(/COALESCE\(\s*rq\.question_text\s*,\s*rtq\.question_text\s*,\s*ctc\.question_text\s*\)/);
  });
});

// ---------------------------------------------------------------------------
// The content repoint split one alias into two: `ct` (inform.compass_topics)
// still matches the row and carries `is_live`; `ctc`
// (inform.compass_topics_current) carries the wording. That split is only safe
// while the kill switch keeps reading `ct`.
//
// 🔴 THE FAILURE THESE GUARD AGAINST. compass_topics_current has NO is_live
// column, so moving the kill switch onto `ctc` does not error — it silently
// deletes the condition, and every retired Compass topic comes back into a
// voter-facing surface. Nothing else in the suite would notice.
// ---------------------------------------------------------------------------
describe('content repoint — the is_live kill switch must stay on ct', () => {
  const killSwitch = /\(\s*ct2?\.topic_key IS NULL OR ct2?\.is_live = true\s*\)/;

  it('keeps the kill switch reading ct in the playable-races query', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getPlayableRacesResult();

    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toMatch(killSwitch);
    expect(sql).not.toMatch(/ctc\.is_live/);
  });

  it('keeps the kill switch on ct while taking text from ctc in the blind payload', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getRaceBlindQuotes('race-1');

    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toMatch(killSwitch);
    expect(sql).toContain('inform.compass_topics_current ctc');
    expect(sql).not.toMatch(/ctc\.is_live/);
  });

  // The reveal and the blind payload must gate identically. If only one of them
  // kept the kill switch, a retired topic would be hidden while a voter ranked
  // and then reappear when the answers were shown.
  it('keeps the kill switch on ct while taking text from ctc in the reveal', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await computeRaceMatch('race-1', [{ quote_id: 'q1', supported: true, rank: 1 }]);

    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toMatch(killSwitch);
    expect(sql).toContain('inform.compass_topics_current ctc');
    expect(sql).not.toMatch(/ctc\.is_live/);
  });
});
