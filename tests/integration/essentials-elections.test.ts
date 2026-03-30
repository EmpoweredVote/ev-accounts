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
