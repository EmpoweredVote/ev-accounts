// src/lib/readrankService.test.ts
import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery, mockGetBoundaryBatch } = vi.hoisted(() => ({
  mockQuery: vi.fn(),
  mockGetBoundaryBatch: vi.fn(),
}));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));
vi.mock('./env.js', () => ({
  env: {
    SUPABASE_SERVICE_ROLE_KEY: 'test-secret',
    SUPABASE_URL: 'https://test.supabase.co',
    SUPABASE_ANON_KEY: 'test-anon',
    DATABASE_URL: 'postgres://test',
    ADMIN_INGEST_TOKEN: 'test-token',
  },
}));
vi.mock('./informBoundaryService.js', () => ({ getBoundaryBatch: mockGetBoundaryBatch }));

import { getPlayableRaces, deriveTierScope } from './readrankService.js';

beforeEach(() => {
  mockQuery.mockReset();
  mockGetBoundaryBatch.mockReset();
  // Default: return an empty map (no geometry) so existing tests are unaffected.
  mockGetBoundaryBatch.mockResolvedValue(new Map());
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
      race_id: 'r1', clean_position_name: 'Mayor', district_label: null,
      election_id: 'e1', election_name: 'LA 2026', election_date: new Date('2026-11-03T00:00:00Z'),
      jurisdiction_level: 'county', state: 'CA',
      boundary_layer: 'G4110', boundary_geoid: '0644000',
      candidate_count: '3', topic_count: '5', quote_count: '24', rankable_topic_count: '4',
      politician_ids: ['p1', 'p2', 'p3'],
    }] });

    const [race] = await getPlayableRaces();
    expect(race).toMatchObject({
      raceId: 'r1', positionName: 'Mayor', districtLabel: null, state: 'CA',
      candidateCount: 3, topicCount: 5, quoteCount: 24, rankableTopicCount: 4,
      tier: 'local', scope: 'citywide',
      boundaryRef: { layer: 'G4110', geoid: '0644000' },
    });
  });

  it('falls back to the whole-state outline for a statewide race with no district', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r2', clean_position_name: 'Governor', district_label: null,
      election_id: 'e2', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: null, boundary_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race).toMatchObject({ tier: 'state', scope: 'statewide' });
    expect(race.boundaryRef).toEqual({ layer: 'G4000', geoid: '18' }); // IN
  });

  it('emits boundaryRef:null when there is no district and the scope is not statewide', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r3', clean_position_name: 'City Council', district_label: null,
      election_id: 'e3', election_name: 'Somewhere 2026', election_date: null,
      jurisdiction_level: 'city', state: 'IN',
      boundary_layer: null, boundary_geoid: null,
      candidate_count: '2', topic_count: '2', quote_count: '6', rankable_topic_count: '2',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.scope).toBe('district');
    expect(race.boundaryRef).toBeNull();
  });

  it('federal: child = home state, frame = US (model B)', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rf', clean_position_name: 'U.S. House', district_label: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'federal', state: 'IN',
      boundary_layer: 'G5200', boundary_geoid: '1807',
      frame_layer: null, frame_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.tier).toBe('federal');
    expect(race.boundaryRef).toEqual({ layer: 'G4000', geoid: '18' }); // home state
    expect(race.frameRef).toEqual({ layer: 'G4000', geoid: 'US' });
  });

  it('statewide state (Governor): frame = null (state alone)', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rg', clean_position_name: 'Governor', district_label: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: null, boundary_geoid: null, frame_layer: null, frame_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.boundaryRef).toEqual({ layer: 'G4000', geoid: '18' });
    expect(race.frameRef).toBeNull();
  });

  it('county: frame = state', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rc', clean_position_name: 'County Commission', district_label: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'county', state: 'IN',
      boundary_layer: 'G4020', boundary_geoid: '18105', frame_layer: null, frame_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.boundaryRef).toEqual({ layer: 'G4020', geoid: '18105' });
    expect(race.frameRef).toEqual({ layer: 'G4000', geoid: '18' });
  });

  it('city: frame = the SQL-resolved container county', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rcity', clean_position_name: 'Mayor', district_label: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'city', state: 'IN',
      boundary_layer: 'G4110', boundary_geoid: '1805860',
      frame_layer: 'G4020', frame_geoid: '18105',
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.boundaryRef).toEqual({ layer: 'G4110', geoid: '1805860' });
    expect(race.frameRef).toEqual({ layer: 'G4020', geoid: '18105' });
  });

  it('ward: frame = the SQL-resolved container city', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rw', clean_position_name: 'City Common Council', district_label: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'city', state: 'IN',
      boundary_layer: 'X0001', boundary_geoid: '180586000001',
      frame_layer: 'G4110', frame_geoid: '1805860',
      candidate_count: '2', topic_count: '2', quote_count: '6', rankable_topic_count: '2',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.frameRef).toEqual({ layer: 'G4110', geoid: '1805860' });
  });

  it('strips district label suffix from positionName and emits districtLabel separately', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      // SQL strips "District 1" from "Monroe County Commissioner - District 1"
      race_id: 'rd', clean_position_name: 'Monroe County Commissioner', district_label: 'District 1',
      election_id: 'e', election_name: 'IN 2025', election_date: null,
      jurisdiction_level: 'county', state: 'IN',
      boundary_layer: 'G4020', boundary_geoid: '18105', frame_layer: null, frame_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '6', rankable_topic_count: '2',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.positionName).toBe('Monroe County Commissioner');
    expect(race.districtLabel).toBe('District 1');
  });

  it('emits districtLabel:null when district label equals the full position name (messy data guard)', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      // SQL: d.label = position_name → strip skipped, clean_position_name = full name, district_label = null
      race_id: 'rm', clean_position_name: 'Indiana House of Representatives - District 61', district_label: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: 'G5220', boundary_geoid: '18061', frame_layer: null, frame_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '6', rankable_topic_count: '2',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.positionName).toBe('Indiana House of Representatives - District 61');
    expect(race.districtLabel).toBeNull();
  });

  it('emits districtLabel:null for a statewide race with no district record', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'rg2', clean_position_name: 'Governor', district_label: null,
      election_id: 'e', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: null, boundary_geoid: null, frame_layer: null, frame_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.districtLabel).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// Geometry attachment tests
// ---------------------------------------------------------------------------

const BASE_ROW = {
  race_id: 'race-1',
  clean_position_name: 'City Council',
  district_label: null,
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
  topic_count: '3',
  quote_count: '6',
  rankable_topic_count: '2',
  politician_ids: ['pol-1', 'pol-2'],
};

const BLOOMINGTON_GEOM = { type: 'Polygon' as const, coordinates: [[[-86.6, 39.1], [-86.4, 39.1], [-86.4, 39.3], [-86.6, 39.1]]] };
const MONROE_GEOM = { type: 'Polygon' as const, coordinates: [[[-87.0, 39.0], [-86.3, 39.0], [-86.3, 39.5], [-87.0, 39.0]]] };

describe('getPlayableRaces — geometry attachment', () => {
  it('attaches bbox and geojson to boundaryRef and frameRef when batch finds them', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [BASE_ROW] });
    mockGetBoundaryBatch.mockResolvedValueOnce(new Map([
      ['G4110:1805860', { layer: 'G4110', geoid: '1805860', name: 'Bloomington city', bbox: [-86.6, 39.1, -86.4, 39.3], geojson: BLOOMINGTON_GEOM, hasBoundary: true }],
      ['G4020:18105', { layer: 'G4020', geoid: '18105', name: 'Monroe County', bbox: [-87.0, 39.0, -86.3, 39.5], geojson: MONROE_GEOM, hasBoundary: true }],
    ]));

    const races = await getPlayableRaces();

    expect(races).toHaveLength(1);
    expect(races[0].boundaryRef).toMatchObject({
      layer: 'G4110',
      geoid: '1805860',
      bbox: [-86.6, 39.1, -86.4, 39.3],
      geojson: BLOOMINGTON_GEOM,
    });
    expect(races[0].frameRef).toMatchObject({
      layer: 'G4020',
      geoid: '18105',
      bbox: [-87.0, 39.0, -86.3, 39.5],
      geojson: MONROE_GEOM,
    });
  });

  it('returns races without geometry when getBoundaryBatch throws', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [BASE_ROW] });
    mockGetBoundaryBatch.mockRejectedValueOnce(new Error('DB down'));

    const races = await getPlayableRaces();

    expect(races).toHaveLength(1);
    expect(races[0].boundaryRef).toEqual({ layer: 'G4110', geoid: '1805860' });
    expect(races[0].frameRef).toEqual({ layer: 'G4020', geoid: '18105' });
  });

  it('returns races without geometry when a ref is absent from the batch result', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [BASE_ROW] });
    mockGetBoundaryBatch.mockResolvedValueOnce(new Map()); // empty — nothing found

    const races = await getPlayableRaces();

    expect(races[0].boundaryRef).toEqual({ layer: 'G4110', geoid: '1805860' });
    expect(races[0].frameRef).toEqual({ layer: 'G4020', geoid: '18105' });
  });
});
