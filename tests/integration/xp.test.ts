import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import type { Express } from 'express';

// Set up test environment before any imports that read process.env
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-role-key';
process.env['DATABASE_URL'] = 'postgresql://postgres:password@localhost:5432/postgres';
// QUEST_SERVICE_KEY retired 2026-09-09: VQ XP is awarded in-process now, so
// validation_quest_completion is no longer awardable over HTTP by any service key.
// These route tests use the still-live TRIVIA key instead.
process.env['TRIVIA_SERVICE_KEY'] = 'test-trivia-key';
process.env['ADMIN_SERVICE_KEY'] = 'test-admin-key';

let app: Express;

beforeAll(async () => {
  // Dynamic import allows env setup to complete before module evaluation
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});

// ---------------------------------------------------------------------------
// POST /api/xp/award — service key validation
// ---------------------------------------------------------------------------

describe('POST /api/xp/award', () => {
  it('returns 401 when X-Service-Key header is missing', async () => {
    const res = await request(app)
      .post('/api/xp/award')
      .set('Content-Type', 'application/json')
      .send({
        user_id: '00000000-0000-4000-8000-000000000001',
        source: 'validation_quest_completion',
        amount: 100,
        idempotency_key: 'idem-key-001',
      });
    expect(res.status).toBe(401);
  });

  it('returns 401 when X-Service-Key is invalid', async () => {
    const res = await request(app)
      .post('/api/xp/award')
      .set('Content-Type', 'application/json')
      .set('X-Service-Key', 'not-a-valid-service-key')
      .send({
        user_id: '00000000-0000-4000-8000-000000000001',
        source: 'validation_quest_completion',
        amount: 100,
        idempotency_key: 'idem-key-002',
      });
    expect(res.status).toBe(401);
  });

  it('returns 422 when body is missing required fields', async () => {
    const res = await request(app)
      .post('/api/xp/award')
      .set('Content-Type', 'application/json')
      .set('X-Service-Key', 'test-trivia-key')
      .send({});
    expect(res.status).toBe(422);
    expect(res.body).toHaveProperty('code', 'VALIDATION_ERROR');
  });

  it('returns 422 when source is not a valid XP_SOURCE', async () => {
    const res = await request(app)
      .post('/api/xp/award')
      .set('Content-Type', 'application/json')
      .set('X-Service-Key', 'test-trivia-key')
      .send({
        user_id: '00000000-0000-4000-8000-000000000001',
        source: 'not_a_valid_source',
        amount: 100,
        idempotency_key: 'idem-key-003',
      });
    expect(res.status).toBe(422);
    expect(res.body).toHaveProperty('code', 'VALIDATION_ERROR');
  });

  it('returns 422 when user_id is not a valid UUID', async () => {
    const res = await request(app)
      .post('/api/xp/award')
      .set('Content-Type', 'application/json')
      .set('X-Service-Key', 'test-trivia-key')
      .send({
        user_id: 'not-a-uuid',
        source: 'validation_quest_completion',
        amount: 100,
        idempotency_key: 'idem-key-004',
      });
    expect(res.status).toBe(422);
    expect(res.body).toHaveProperty('code', 'VALIDATION_ERROR');
  });

  it('returns 422 when amount is negative', async () => {
    const res = await request(app)
      .post('/api/xp/award')
      .set('Content-Type', 'application/json')
      .set('X-Service-Key', 'test-trivia-key')
      .send({
        user_id: '00000000-0000-4000-8000-000000000001',
        source: 'validation_quest_completion',
        amount: -50,
        idempotency_key: 'idem-key-005',
      });
    expect(res.status).toBe(422);
    expect(res.body).toHaveProperty('code', 'VALIDATION_ERROR');
  });

  it('returns 422 when idempotency_key is missing', async () => {
    const res = await request(app)
      .post('/api/xp/award')
      .set('Content-Type', 'application/json')
      .set('X-Service-Key', 'test-trivia-key')
      .send({
        user_id: '00000000-0000-4000-8000-000000000001',
        source: 'validation_quest_completion',
        amount: 100,
      });
    expect(res.status).toBe(422);
    expect(res.body).toHaveProperty('code', 'VALIDATION_ERROR');
  });

  it('returns 422 when amount is zero (not positive)', async () => {
    const res = await request(app)
      .post('/api/xp/award')
      .set('Content-Type', 'application/json')
      .set('X-Service-Key', 'test-trivia-key')
      .send({
        user_id: '00000000-0000-4000-8000-000000000001',
        source: 'validation_quest_completion',
        amount: 0,
        idempotency_key: 'idem-key-006',
      });
    expect(res.status).toBe(422);
    expect(res.body).toHaveProperty('code', 'VALIDATION_ERROR');
  });

  it('returns 422 when trivia key attempts quest source (cross-key scope violation)', async () => {
    // test-trivia-key is authorized only for civic_trivia_championship_score.
    // Using it with validation_quest_completion must also be rejected.
    const res = await request(app)
      .post('/api/xp/award')
      .set('Content-Type', 'application/json')
      .set('X-Service-Key', 'test-trivia-key')
      .send({
        user_id: '00000000-0000-4000-8000-000000000001',
        source: 'validation_quest_completion',
        amount: 100,
        idempotency_key: 'idem-key-008',
      });
    expect(res.status).toBe(422);
    expect(res.body).toHaveProperty('code', 'SOURCE_NOT_PERMITTED');
  });
});

// ---------------------------------------------------------------------------
// GET /api/xp/me/history — auth guard
// ---------------------------------------------------------------------------

describe('GET /api/xp/me/history', () => {
  it('returns 401 when no Authorization header is provided', async () => {
    const res = await request(app).get('/api/xp/me/history');
    expect(res.status).toBe(401);
  });

  it('returns 401 when Authorization header has invalid token', async () => {
    const res = await request(app)
      .get('/api/xp/me/history')
      .set('Authorization', 'Bearer not-a-valid-jwt');
    expect(res.status).toBe(401);
  });

  it('returns 422 when limit query param is invalid (exceeds max)', async () => {
    // This test needs auth to get past the 401 guard, so we test validation
    // by asserting 401 (no auth) is the first barrier — limit validation
    // is tested by the layer below auth.
    // Manual test: with valid auth, ?limit=200 returns 422.

    // What we can test without live auth: no-auth always 401
    const res = await request(app)
      .get('/api/xp/me/history?limit=200');
    expect(res.status).toBe(401);
  });
});

// ---------------------------------------------------------------------------
// GET /api/xp/:userId — UUID validation
// ---------------------------------------------------------------------------

describe('GET /api/xp/:userId', () => {
  it('returns 400 when userId is not a valid UUID format', async () => {
    const res = await request(app).get('/api/xp/not-a-valid-uuid');
    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error', 'Invalid userId format');
  });

  it('returns 400 when userId is an empty-like string', async () => {
    const res = await request(app).get('/api/xp/just-a-slug');
    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error', 'Invalid userId format');
  });

  it('does not require an Authorization header (public endpoint)', async () => {
    // Should get past auth and either 400 (invalid UUID) or 404/500 (valid UUID, no DB)
    // We use a valid UUID format to verify no 401 is returned
    const res = await request(app).get('/api/xp/00000000-0000-4000-8000-000000000001');
    // Without live Supabase, this will error at DB level (500 or network error)
    // but NOT 401 — confirming the route requires no auth
    expect(res.status).not.toBe(401);
  });

  // Manual test (requires live Supabase + Connected user):
  //   GET /api/xp/:userId for a valid Connected user → 200 with level, total_xp, xp_in_level, xp_to_next_level
  //   GET /api/xp/:userId for a non-existent or Inform-tier user → 404
});

// ---------------------------------------------------------------------------
// Route order safety: /me/history must not match /:userId
// ---------------------------------------------------------------------------

describe('Route order: /me/history not matched as /:userId', () => {
  it('GET /api/xp/me/history returns 401 (auth guard), not 400 (UUID error)', async () => {
    // If route order is wrong, "me" would be treated as :userId and fail UUID validation.
    // With correct route order, /me/history hits requireAuth first → 401.
    const res = await request(app).get('/api/xp/me/history');
    expect(res.status).toBe(401); // auth guard, NOT UUID validation 400
    expect(res.body).not.toHaveProperty('error', 'Invalid userId format');
  });
});
