// src/lib/readrankService.test.ts
import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
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

import { getPlayableRaces, deriveTierScope } from './readrankService.js';

beforeEach(() => mockQuery.mockReset());

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
      race_id: 'r1', position_name: 'Mayor',
      election_id: 'e1', election_name: 'LA 2026', election_date: new Date('2026-11-03T00:00:00Z'),
      jurisdiction_level: 'county', state: 'CA',
      boundary_layer: 'G4110', boundary_geoid: '0644000',
      candidate_count: '3', topic_count: '5', quote_count: '24', rankable_topic_count: '4',
      politician_ids: ['p1', 'p2', 'p3'],
    }] });

    const [race] = await getPlayableRaces();
    expect(race).toMatchObject({
      raceId: 'r1', positionName: 'Mayor', state: 'CA',
      candidateCount: 3, topicCount: 5, quoteCount: 24, rankableTopicCount: 4,
      tier: 'local', scope: 'citywide',
      boundaryRef: { layer: 'G4110', geoid: '0644000' },
    });
  });

  it('emits boundaryRef:null when the race has no resolvable district', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      race_id: 'r2', position_name: 'Governor',
      election_id: 'e2', election_name: 'IN 2026', election_date: null,
      jurisdiction_level: 'state', state: 'IN',
      boundary_layer: null, boundary_geoid: null,
      candidate_count: '2', topic_count: '3', quote_count: '8', rankable_topic_count: '3',
      politician_ids: ['p1', 'p2'],
    }] });
    const [race] = await getPlayableRaces();
    expect(race.boundaryRef).toBeNull();
    expect(race).toMatchObject({ tier: 'state', scope: 'statewide' });
  });
});
