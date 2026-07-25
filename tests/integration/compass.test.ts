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
// Two contracts live here, and the difference is deliberate:
//
//   - requireAuth routes reject anonymous callers with 401.
//   - The five answer routes use optionalAuth (18-02: "convert five answer
//     routes to optionalAuth with anonymous short-circuit guards"). Anonymous
//     callers get 200 with an empty body — `[]` for the collection routes and
//     `null` for the single-answer upsert. The guard short-circuits before any
//     createUserClient call, so no other user's data can ever be reached.
//
// The property worth guarding on the optionalAuth routes is therefore not the
// status code but the empty body: anonymous callers must never receive rows.
// These tests reject before any DB call — no database needed.
// ---------------------------------------------------------------------------

describe('Compass routes — auth enforcement (CI-safe)', () => {
  it('GET /api/compass/progress returns 401 without auth (requireAuth)', async () => {
    const res = await request(app).get('/api/compass/progress');
    expect(res.status).toBe(401);
  });
});

describe('Compass routes — anonymous short-circuit (CI-safe)', () => {
  it('GET /api/compass/answers returns 200 [] without auth', async () => {
    const res = await request(app).get('/api/compass/answers');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it('POST /api/compass/answers/batch returns 200 [] without auth', async () => {
    const res = await request(app)
      .post('/api/compass/answers/batch')
      .send({ ids: [] });
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it('GET /api/compass/selected-topics returns 200 [] without auth', async () => {
    const res = await request(app).get('/api/compass/selected-topics');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  // This one short-circuits to `null` rather than `[]` — it upserts a single
  // answer, so there is no collection to return. Same guard, different shape.
  it('POST /api/compass/answers returns 200 null without auth', async () => {
    const res = await request(app)
      .post('/api/compass/answers')
      .send({ topic_id: '00000000-0000-0000-0000-000000000001', value: 3 });
    expect(res.status).toBe(200);
    expect(res.body).toBeNull();
  });

  it('PUT /api/compass/selected-topics returns 200 [] without auth', async () => {
    const res = await request(app)
      .put('/api/compass/selected-topics')
      .send({ topic_ids: [] });
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
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

  it('compassService.ts wraps photo_custom_url and photo_origin_url with NULLIF to prevent empty-string short-circuit (G-114-014)', () => {
    // Source-level check: verify the NULLIF fix is present in the SQL template string.
    // Full DB-level regression (insert politician with photo_origin_url='', verify fallthrough
    // to politician_images.url) requires a live Supabase connection and is not feasible in CI.
    // See G-114-014 in RESEARCH.md for root cause and manual verification steps.
    const serviceSource = fs.readFileSync(
      path.resolve(BACKEND_SRC, 'lib/compassService.ts'),
      'utf-8'
    );
    expect(serviceSource).toContain("NULLIF(p.photo_custom_url, '')");
    expect(serviceSource).toContain("NULLIF(p.photo_origin_url, '')");
  });
});
