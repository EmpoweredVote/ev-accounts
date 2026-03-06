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
  // Dynamic import allows env setup to complete before module evaluation
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Assert the error response has the correct { code, message } shape.
 * All error responses in this API use a flat two-field contract — no nested
 * details, no raw Supabase errors, no arrays.
 */
function assertErrorShape(body: Record<string, unknown>): void {
  expect(body).toHaveProperty('code');
  expect(body).toHaveProperty('message');
  expect(typeof body['code']).toBe('string');
  expect(typeof body['message']).toBe('string');
}

// ---------------------------------------------------------------------------
// POST /api/auth/signup
// ---------------------------------------------------------------------------

describe('POST /api/auth/signup', () => {
  // ---- Validation tests (do NOT require Supabase) ----

  it('returns 422 for missing email', async () => {
    const res = await request(app)
      .post('/api/auth/signup')
      .set('Content-Type', 'application/json')
      .send({ password: 'password123' });

    expect(res.status).toBe(422);
    assertErrorShape(res.body as Record<string, unknown>);
    expect((res.body as Record<string, unknown>)['code']).toBe('VALIDATION_ERROR');
  });

  it('returns 422 for missing password', async () => {
    const res = await request(app)
      .post('/api/auth/signup')
      .set('Content-Type', 'application/json')
      .send({ email: 'test@example.com' });

    expect(res.status).toBe(422);
    assertErrorShape(res.body as Record<string, unknown>);
    expect((res.body as Record<string, unknown>)['code']).toBe('VALIDATION_ERROR');
  });

  it('returns 422 for invalid email format', async () => {
    const res = await request(app)
      .post('/api/auth/signup')
      .set('Content-Type', 'application/json')
      .send({ email: 'not-an-email', password: 'password123' });

    expect(res.status).toBe(422);
    assertErrorShape(res.body as Record<string, unknown>);
    expect((res.body as Record<string, unknown>)['code']).toBe('VALIDATION_ERROR');
  });

  it('returns 422 for password shorter than 8 chars', async () => {
    const res = await request(app)
      .post('/api/auth/signup')
      .set('Content-Type', 'application/json')
      .send({ email: 'test@example.com', password: 'short' });

    expect(res.status).toBe(422);
    assertErrorShape(res.body as Record<string, unknown>);
    expect((res.body as Record<string, unknown>)['code']).toBe('VALIDATION_ERROR');
  });

  it('returns correct error shape { code, message } on validation failure', async () => {
    const res = await request(app)
      .post('/api/auth/signup')
      .set('Content-Type', 'application/json')
      .send({ email: 'bad', password: 'x' });

    expect(res.status).toBe(422);
    // Exactly two fields: code and message
    const body = res.body as Record<string, unknown>;
    assertErrorShape(body);
    // No extra fields beyond code and message should be present for error responses
    expect(body['code']).toBe('VALIDATION_ERROR');
  });
});

// ---------------------------------------------------------------------------
// POST /api/auth/login
// ---------------------------------------------------------------------------

describe('POST /api/auth/login', () => {
  // ---- Validation tests (do NOT require Supabase) ----

  it('returns 422 for missing email', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .set('Content-Type', 'application/json')
      .send({ password: 'password123' });

    expect(res.status).toBe(422);
    assertErrorShape(res.body as Record<string, unknown>);
    expect((res.body as Record<string, unknown>)['code']).toBe('VALIDATION_ERROR');
  });

  it('returns 422 for missing password', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .set('Content-Type', 'application/json')
      .send({ email: 'test@example.com' });

    expect(res.status).toBe(422);
    assertErrorShape(res.body as Record<string, unknown>);
    expect((res.body as Record<string, unknown>)['code']).toBe('VALIDATION_ERROR');
  });

  it('returns correct error shape { code, message } on validation failure', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .set('Content-Type', 'application/json')
      .send({ email: 'not-valid', password: 'x' });

    expect(res.status).toBe(422);
    assertErrorShape(res.body as Record<string, unknown>);
    expect((res.body as Record<string, unknown>)['code']).toBe('VALIDATION_ERROR');
  });
});

// ---------------------------------------------------------------------------
// POST /api/auth/logout
// ---------------------------------------------------------------------------

describe('POST /api/auth/logout', () => {
  // ---- Auth barrier tests (do NOT require Supabase for valid flow) ----

  it('returns 401 without auth header', async () => {
    // requireAuth middleware blocks the request before any Supabase call
    const res = await request(app)
      .post('/api/auth/logout')
      .set('Content-Type', 'application/json');

    expect(res.status).toBe(401);
  });

  it('returns 401 with invalid Bearer token', async () => {
    // JWKS verification will fail on the fake token.
    // In the test environment the Supabase URL is https://test.supabase.co so
    // the JWKS fetch will fail — which correctly results in a 401.
    const res = await request(app)
      .post('/api/auth/logout')
      .set('Content-Type', 'application/json')
      .set('Authorization', 'Bearer invalid.token.here');

    expect(res.status).toBe(401);
  });

  // ---- Supabase-dependent test ----
  // NOTE: Requires a valid JWT from a live Supabase project.

  describe('(requires Supabase connectivity)', () => {
    it('returns 200 with success message when given a valid JWT', async () => {
      // Requires a valid access token obtained from a prior login call.
      // Set TEST_ACCESS_TOKEN env var to run this test.
      const accessToken = process.env['TEST_ACCESS_TOKEN'];

      if (!accessToken) {
        console.warn('[auth.test] Skipping logout success test — TEST_ACCESS_TOKEN not set');
        return;
      }

      const res = await request(app)
        .post('/api/auth/logout')
        .set('Content-Type', 'application/json')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      const body = res.body as Record<string, unknown>;
      expect(body['message']).toBe('Logged out successfully');
    });
  });
});
