import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import type { Express } from 'express';

// Set up test environment before any imports that read process.env
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-role-key';
process.env['DATABASE_URL'] = 'postgresql://postgres:password@localhost:5432/postgres';

let app: Express;

beforeAll(async () => {
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});

// ---------------------------------------------------------------------------
// CI-safe tests for GET /api/essentials/elections-by-address
//
// These tests verify route wiring and validation — no live database required.
// Integration tests requiring a real DB can be added with a db-check guard.
// ---------------------------------------------------------------------------

describe('GET /api/essentials/elections-by-address', () => {
  it('returns 422 when address param is missing', async () => {
    const res = await request(app).get('/api/essentials/elections-by-address');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
  });

  it('returns 422 when address param is empty string', async () => {
    const res = await request(app).get('/api/essentials/elections-by-address?address=');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
  });

  it('returns elections array shape for a valid address (with DB or empty graceful fallback)', async () => {
    // With no live DB, geocoding may fail or succeed — the route must be wired correctly.
    // Acceptable responses: 200 (elections array), 503 (geocoder unavailable in CI), or 500 (no DB).
    const res = await request(app).get(
      '/api/essentials/elections-by-address?address=' +
      encodeURIComponent('401 N Morton St, Bloomington, IN 47404')
    );
    // Route must be wired — not a 404 from Express itself
    expect([200, 503, 500]).toContain(res.status);
    if (res.status === 200) {
      expect(res.body).toHaveProperty('elections');
      expect(Array.isArray(res.body.elections)).toBe(true);
      // Each election should have expected shape
      if (res.body.elections.length > 0) {
        const election = res.body.elections[0];
        expect(election).toHaveProperty('election_id');
        expect(election).toHaveProperty('election_name');
        expect(election).toHaveProperty('election_date');
        expect(election).toHaveProperty('races');
        // Each race should have district_type
        if (election.races.length > 0) {
          expect(election.races[0]).toHaveProperty('district_type');
        }
      }
    }
  });

  it('every race has a candidates array (may be empty for 0-candidate races)', async () => {
    const res = await request(app).get(
      '/api/essentials/elections-by-address?address=' +
      encodeURIComponent('401 N Morton St, Bloomington, IN 47404')
    );
    // Route must be wired — not a 404
    expect([200, 503, 500]).toContain(res.status);
    if (res.status === 200 && res.body.elections?.length > 0) {
      for (const election of res.body.elections) {
        for (const race of election.races) {
          expect(race).toHaveProperty('candidates');
          expect(Array.isArray(race.candidates)).toBe(true);
          // Each candidate (if present) must have required fields
          for (const candidate of race.candidates) {
            expect(candidate).toHaveProperty('candidate_id');
            expect(candidate).toHaveProperty('full_name');
            expect(typeof candidate.is_incumbent).toBe('boolean');
          }
        }
      }
    }
  });

  it('returns empty elections or graceful error for non-geocodable address', async () => {
    const res = await request(app).get(
      '/api/essentials/elections-by-address?address=' +
      encodeURIComponent('zzz not a real address 99999')
    );
    // Should return 200 with empty elections, or 503 if geocoder unavailable in CI
    expect([200, 503]).toContain(res.status);
    if (res.status === 200) {
      expect(res.body).toHaveProperty('elections');
      expect(res.body.elections).toEqual([]);
    }
  });
});

// ---------------------------------------------------------------------------
// CI-safe tests for GET /api/essentials/race-candidates/:id
//
// These tests verify route wiring and validation — no live database required.
// ---------------------------------------------------------------------------

describe('GET /api/essentials/race-candidates/:id', () => {
  it('returns 422 for invalid UUID format', async () => {
    const res = await request(app).get('/api/essentials/race-candidates/not-a-uuid');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
  });

  it('returns 422 for numeric ID (not UUID)', async () => {
    const res = await request(app).get('/api/essentials/race-candidates/12345');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
  });

  it('returns 404 or 500 for valid UUID that does not exist (no live DB)', async () => {
    const res = await request(app).get(
      '/api/essentials/race-candidates/00000000-0000-0000-0000-000000000000'
    );
    // With no DB: 500 on connection error; with DB: 404 for non-existent
    expect([404, 500]).toContain(res.status);
  });

  it('route is wired — does not return 404 from Express itself', async () => {
    // Any valid-format UUID should NOT get Express's default 404 HTML response
    const res = await request(app).get(
      '/api/essentials/race-candidates/11111111-1111-1111-1111-111111111111'
    );
    // Should be 404 (our JSON) or 500 (DB), never Express's default HTML 404
    expect(res.headers['content-type']).toMatch(/json/);
  });
});
