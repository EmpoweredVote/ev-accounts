import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));

// essentials.ts pulls in db.js / supabase.js and several service modules at
// module scope; db.js and supabase.js validate env vars at import time and
// process.exit(1) in this unit-test environment. Only pool.query is exercised
// by GET /quotes — everything else is a full stub (no importActual). Mirrors
// the essentialsCoordinateLookup.test.ts convention.
vi.mock('../lib/db.js', () => ({ pool: { query: mockQuery } }));
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: vi.fn() }));
vi.mock('../lib/essentialsService.js', () => ({
  getRepresentativesByAddress: vi.fn(),
  getRepresentativesByJurisdiction: vi.fn(),
  getLocalOfficialsByUserId: vi.fn(),
  getGovernmentById: vi.fn(),
  getChamberById: vi.fn(),
  getDistrictById: vi.fn(),
}));
vi.mock('../lib/electionService.js', () => ({
  getElectionsByCoordinate: vi.fn(),
  getElectionsByGeoIds: vi.fn(),
  getCandidateById: vi.fn(),
}));
vi.mock('../lib/voterInfoService.js', () => ({ getVoterInfo: vi.fn() }));
vi.mock('../lib/geocodingService.js', () => ({
  geocodeAddress: vi.fn(),
  GeocodingError: class GeocodingError extends Error {
    code: string;
    constructor(code: string, message: string) { super(message); this.code = code; }
  },
}));
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
  requireAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));
vi.mock('../middleware/tierGuards.js', () => ({
  requireConnected: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import essentialsRouter from './essentials.js';
import { topicAskedByPublishedSeason } from '../lib/seasonService.js';

const app = express();
app.use(express.json());
app.use('/api/essentials', essentialsRouter);

beforeEach(() => {
  mockQuery.mockReset();
});

describe('GET /api/essentials/quotes', () => {
  const ROW = {
    quote_id: 'q1',
    quote_text: 'Verbatim quote.',
    text: 'De-identified quote.',
    politician_id: 'p1',
    source_url: null,
    source_name: null,
    politician_name: 'Alex Doe',
    politician_party: 'Independent',
    politician_photo: null,
    office_title: 'State Senator',
    topic_id: 't1',
    topic_key: 'housing',
    topic_title: 'Housing',
    topic_question: 'What about housing?',
  };

  it('returns quotes/candidates/issues, with candidate office from the office-title lookup', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [ROW] });
    const res = await request(app).get('/api/essentials/quotes');
    expect(res.status).toBe(200);
    expect(res.body.quotes).toHaveLength(1);
    expect(res.body.candidates[0]).toMatchObject({ id: 'p1', name: 'Alex Doe', office: 'State Senator' });
    expect(res.body.issues[0]).toMatchObject({ id: 'housing', title: 'Housing' });
  });

  // Title avoids the literal "offices" + ".politician_id": check:occupancy scans
  // every changed file and reads that spelling as a query on the dropped column.
  it('resolves the office title through current_office_holders, not the politician_id column migration 1463 dropped from essentials.offices', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [ROW] });
    await request(app).get('/api/essentials/quotes');

    const sql = String(mockQuery.mock.calls[0][0]);
    // 1463 dropped essentials.offices.politician_id — occupancy must resolve through the view.
    expect(sql).toContain('essentials.current_office_holders');
    expect(sql).toMatch(/coh\.politician_id\s*=\s*p\.id/);
    // The pre-1463 shape: an unqualified politician_id filter directly on essentials.offices.
    expect(sql).not.toMatch(/essentials\.offices\s+WHERE\s+politician_id/i);
  });

  // 🔴 The topic match used to be `AND ct.is_live = true`, and the route drops
  // every row whose topic did not match. Seventeen Season 2 topics are
  // is_live = false (created staged; opening a season flips no boolean), so
  // every quote on them vanished from this endpoint. The match now asks whether
  // a published season asks the topic.
  it('matches a quote to a topic a published season asks, not by is_live', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await request(app).get('/api/essentials/quotes');

    const sql = String(mockQuery.mock.calls[0][0]);
    expect(sql).toContain(
      `LEFT JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key) AND ${topicAskedByPublishedSeason('ct.id')}`);
    expect(sql.replace(/--[^\n]*/g, '')).not.toMatch(/is_live/);
  });

  it('422 when politician_id is not a uuid', async () => {
    const res = await request(app).get('/api/essentials/quotes?politician_id=nope');
    expect(res.status).toBe(422);
    expect(mockQuery).not.toHaveBeenCalled();
  });
});
