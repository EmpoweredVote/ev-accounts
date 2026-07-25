import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import type { Express } from 'express';
import crypto from 'node:crypto';

// Set ALL env vars BEFORE the dynamic app import (module-level, runs first).
// ESM hoists static imports above all module-level code — dynamic import in
// beforeAll is the only safe pattern for env-dependent modules.
const TEST_GEM_KEY = 'test-gem-key-integration';
const TEST_YELLOW_ONLY_KEY = 'test-gem-key-yellow-only';
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = process.env['SUPABASE_URL'] || 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = process.env['SUPABASE_ANON_KEY'] || 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = process.env['SUPABASE_SERVICE_ROLE_KEY'] || 'test-service-role-key';
process.env['DATABASE_URL'] = process.env['DATABASE_URL'] || 'postgresql://postgres:password@localhost:5432/postgres';
process.env['GEMS_SERVICE_KEYS'] = JSON.stringify({
  [TEST_GEM_KEY]: ['yellow', 'blue', 'red'],
  [TEST_YELLOW_ONLY_KEY]: ['yellow'],
});

// Dynamic import in beforeAll — env is fully set before module evaluation.
let app: Express;
beforeAll(async () => {
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});

// Gate on INTEGRATION_TEST_JWT, not SUPABASE_URL.
// SUPABASE_URL is always set to a fake value above (for non-live tests to pass),
// so checking it would always be true. INTEGRATION_TEST_JWT is only present
// when a real Supabase connection is available.
const hasLiveDB = !!process.env.INTEGRATION_TEST_JWT;

// ---------------------------------------------------------------------------
// POST /api/gems/award — auth and validation (no DB required)
// ---------------------------------------------------------------------------
describe('POST /api/gems/award', () => {
  it('returns 401 without X-Service-Key header', async () => {
    const res = await request(app)
      .post('/api/gems/award')
      .send({
        user_id: crypto.randomUUID(),
        gem_type: 'yellow',
        amount: 1,
        idempotency_key: crypto.randomUUID(),
      });
    expect(res.status).toBe(401);
  });

  it('returns 401 with invalid service key', async () => {
    const res = await request(app)
      .post('/api/gems/award')
      .set('X-Service-Key', 'invalid-key-xyz')
      .send({
        user_id: crypto.randomUUID(),
        gem_type: 'yellow',
        amount: 1,
        idempotency_key: crypto.randomUUID(),
      });
    expect(res.status).toBe(401);
  });

  it('returns 422 with missing required fields', async () => {
    const res = await request(app)
      .post('/api/gems/award')
      .set('X-Service-Key', TEST_GEM_KEY)
      .send({});
    expect(res.status).toBe(422);
  });

  it('returns 422 with missing idempotency_key', async () => {
    const res = await request(app)
      .post('/api/gems/award')
      .set('X-Service-Key', TEST_GEM_KEY)
      .send({ user_id: crypto.randomUUID(), gem_type: 'yellow', amount: 1 });
    expect(res.status).toBe(422);
  });
});

// ---------------------------------------------------------------------------
// POST /api/gems/award — live DB tests (GEM-06 balance-always-0 bug fix)
// Skipped when INTEGRATION_TEST_JWT is not set (CI without live Supabase).
// ---------------------------------------------------------------------------
describe.skipIf(!hasLiveDB)('POST /api/gems/award (live DB)', () => {
  const testUserJwt = process.env.INTEGRATION_TEST_JWT!;
  const testUserId = process.env.INTEGRATION_TEST_USER_ID!;

  let firstAwardBalance: number;
  const sharedIdempotencyKey = crypto.randomUUID();

  it('awards yellow gems and GET /me shows incremented balance', async () => {
    const awardRes = await request(app)
      .post('/api/gems/award')
      .set('X-Service-Key', TEST_GEM_KEY)
      .send({
        user_id: testUserId,
        gem_type: 'yellow',
        amount: 1,
        idempotency_key: sharedIdempotencyKey,
      });

    expect(awardRes.status).toBe(200);
    expect(awardRes.body.is_duplicate).toBe(false);
    expect(awardRes.body.new_balance).toBeGreaterThan(0);
    firstAwardBalance = awardRes.body.new_balance;

    // GEM-06 verification: GET /me must reflect the awarded gems (not always 0).
    // This test proves the balance-always-0 bug is fixed: gem_balance_yellow is
    // now selected from connected_profiles (not the legacy gem_balance column).
    const meRes = await request(app)
      .get('/api/account/me')
      .set('Authorization', `Bearer ${testUserJwt}`);

    expect(meRes.status).toBe(200);
    expect(meRes.body.gems).toBeDefined();
    expect(meRes.body.gems.yellow).toBeGreaterThan(0);
  });

  it('duplicate idempotency_key returns is_duplicate: true with same balance', async () => {
    const dupeRes = await request(app)
      .post('/api/gems/award')
      .set('X-Service-Key', TEST_GEM_KEY)
      .send({
        user_id: testUserId,
        gem_type: 'yellow',
        amount: 1,
        idempotency_key: sharedIdempotencyKey,
      });

    expect(dupeRes.status).toBe(200);
    expect(dupeRes.body.is_duplicate).toBe(true);
    expect(dupeRes.body.new_balance).toBe(firstAwardBalance);
  });

  it('FORBIDDEN_GEM_TYPE when key only permits yellow but awards blue', async () => {
    const forbiddenRes = await request(app)
      .post('/api/gems/award')
      .set('X-Service-Key', TEST_YELLOW_ONLY_KEY)
      .send({
        user_id: testUserId,
        gem_type: 'blue',
        amount: 1,
        idempotency_key: crypto.randomUUID(),
      });

    expect(forbiddenRes.status).toBe(422);
    expect(forbiddenRes.body.error).toBe('FORBIDDEN_GEM_TYPE');
    expect(forbiddenRes.body.permitted).toEqual(['yellow']);
  });
});
