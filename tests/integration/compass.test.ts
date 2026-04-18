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
