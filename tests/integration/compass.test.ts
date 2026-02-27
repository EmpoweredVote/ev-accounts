import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import type { Express } from 'express';

// Set up test environment before any imports that read process.env
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-role-key';
process.env['DATABASE_URL'] = 'postgresql://postgres:password@localhost:5432/postgres';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BACKEND_SRC = path.resolve(__dirname, '../../backend/src');

let app: Express;

beforeAll(async () => {
  // Dynamic import allows env setup to complete before module evaluation
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});

// ---------------------------------------------------------------------------
// Auth enforcement (CI-safe)
//
// All requireAuth routes reject before any DB call when no Authorization
// header is provided. These tests always pass — no database needed.
// ---------------------------------------------------------------------------

describe('Compass routes — auth enforcement (CI-safe)', () => {
  it('GET /api/compass/answers returns 401 without auth', async () => {
    const res = await request(app).get('/api/compass/answers');
    expect(res.status).toBe(401);
  });

  it('POST /api/compass/answers/batch returns 401 without auth', async () => {
    const res = await request(app)
      .post('/api/compass/answers/batch')
      .send({ ids: [] });
    expect(res.status).toBe(401);
  });

  it('GET /api/compass/selected-topics returns 401 without auth', async () => {
    const res = await request(app).get('/api/compass/selected-topics');
    expect(res.status).toBe(401);
  });

  it('GET /api/compass/progress returns 401 without auth', async () => {
    const res = await request(app).get('/api/compass/progress');
    expect(res.status).toBe(401);
  });

  it('POST /api/compass/answers returns 401 without auth', async () => {
    const res = await request(app)
      .post('/api/compass/answers')
      .send({ topic_id: '00000000-0000-0000-0000-000000000001', value: 3 });
    expect(res.status).toBe(401);
  });

  it('PUT /api/compass/selected-topics returns 401 without auth', async () => {
    const res = await request(app)
      .put('/api/compass/selected-topics')
      .send({ topic_ids: [] });
    expect(res.status).toBe(401);
  });
});

// ---------------------------------------------------------------------------
// Architecture enforcement (CI-safe)
//
// Reads source files directly — no network, no database.
// Catches accidental introduction of the service-role admin client into
// compass routes or the compassService library.
// ---------------------------------------------------------------------------

describe('Compass routes — architecture enforcement (CI-safe)', () => {
  it('compass.ts does not reference supabaseAdmin', () => {
    const compassSource = fs.readFileSync(
      path.resolve(BACKEND_SRC, 'routes/compass.ts'),
      'utf-8'
    );
    expect(compassSource).not.toContain('supabaseAdmin');
  });

  it('compassService.ts does not reference supabaseAdmin', () => {
    const serviceSource = fs.readFileSync(
      path.resolve(BACKEND_SRC, 'lib/compassService.ts'),
      'utf-8'
    );
    expect(serviceSource).not.toContain('supabaseAdmin');
  });
});

// ---------------------------------------------------------------------------
// Public access (requires live database)
//
// optionalAuth routes make real pg pool queries. They will return 500 if the
// DATABASE_URL in the test environment points to an unavailable database.
// These tests are skipped unless a live database is explicitly available.
// Run against a real database to verify public-access behaviour.
// ---------------------------------------------------------------------------

describe('Compass routes — public access (requires live database)', () => {
  it.skip('GET /api/compass/topics returns 200 without auth', async () => {
    // Requires: live database with inform schema and compass_topics table
    const res = await request(app).get('/api/compass/topics');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it.skip('GET /api/compass/categories returns 200 without auth', async () => {
    // Requires: live database with inform schema and compass_categories table
    const res = await request(app).get('/api/compass/categories');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it.skip('GET /api/compass/politicians returns 200 without auth', async () => {
    // Requires: live database with inform schema and politicians table
    const res = await request(app).get('/api/compass/politicians');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// Calibration round-trip (requires Supabase auth + live database)
//
// These tests validate the full write→read cycle and must run against
// a live Supabase project with a real authenticated user.
// ---------------------------------------------------------------------------

describe('Compass routes — calibration (requires Supabase auth)', () => {
  it.skip('POST /answers with valid body returns 200 and upserted response', async () => {
    // Requires: valid Bearer JWT for a Connected user, and a live topic in DB
    // Assert: 200, body has { topic_id, value, write_in_text, inverted, visibility, created_at, updated_at }
  });

  it.skip('GET /answers returns the calibrated topic after POST /answers', async () => {
    // Requires: user with at least one compass_responses row
    // Assert: GET /answers array includes the topic_id just calibrated
  });

  it.skip('POST /answers re-calibration appends new change_history row with old_value', async () => {
    // Requires: user who has already calibrated a topic (first POST /answers done)
    // Assert: second POST /answers returns 200; DB has 2 rows in compass_change_history
    //         for this (user_id, topic_id) pair; second row has correct old_value
  });

  it.skip('POST /answers with non-existent topic_id returns 404 TOPIC_NOT_FOUND', async () => {
    // Requires: valid JWT; topic_id not in inform.compass_topics
  });

  it.skip('POST /answers with non-live topic returns 404 TOPIC_NOT_FOUND', async () => {
    // Requires: valid JWT; topic_id exists but is_live=false
  });

  it.skip('GET /progress returns { required, answered, percent, complete }', async () => {
    // Requires: valid JWT and live topics in DB
    // Assert: response shape matches { required: number, answered: number, percent: number, complete: boolean }
  });

  it.skip('GET /progress?role=city_council returns role-filtered completeness', async () => {
    // Requires: valid JWT and topics with compass_topic_roles rows for city_council
    // Assert: required count matches only topics required for city_council
  });

  it.skip('GET /progress returns 422 for unknown role param', async () => {
    // Requires: valid JWT
    // Assert: GET /progress?role=invalid_role returns 422 VALIDATION_ERROR
  });

  it.skip('PUT /selected-topics with invalid topic IDs returns 422 with invalid_ids', async () => {
    // Requires: valid JWT for Connected user
    // Assert: 422, body has { code: "INVALID_TOPIC_IDS", invalid_ids: [...] }
  });

  it.skip('PUT /selected-topics with valid topic IDs returns 200 and stores them', async () => {
    // Requires: valid JWT for Connected user; topic IDs exist and are live
    // Assert: 200, body { topic_ids: [...] }; GET /selected-topics returns same IDs
  });

  it.skip('PUT /selected-topics returns 403 NOT_CONNECTED for non-Connected user', async () => {
    // Requires: valid JWT for user with no connected_profiles row
  });

  it.skip('PUT /selected-topics with empty array clears selection', async () => {
    // Requires: Connected user who already has selected_topic_ids
    // Assert: PUT with { topic_ids: [] } returns 200; GET /selected-topics returns []
  });

  it.skip('GET /politicians/:id/answers returns stances for a politician', async () => {
    // Requires: politician with politician_answers rows in DB
    // Assert: array of { topic_id, value } objects
  });

  it.skip('GET /politicians/:id/:topicId/context returns reasoning and sources', async () => {
    // Requires: politician_context row exists for the (politician_id, topic_id) pair
    // Assert: body has { reasoning: string, sources: string[] }
  });

  it.skip('GET /politicians/:id/:topicId/context returns 404 when no context exists', async () => {
    // Requires: valid politician_id and topic_id but no politician_context row
    // Assert: 404, code 'NOT_FOUND'
  });
});
