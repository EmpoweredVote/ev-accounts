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
// Architecture enforcement — CI-safe (reads file content, no network)
// ---------------------------------------------------------------------------

describe('Architecture enforcement: connect routes', () => {
  it('connect route file does not reference service-role client', () => {
    const content = fs.readFileSync(
      path.resolve(BACKEND_SRC, 'routes/connect.ts'),
      'utf-8'
    );
    expect(content).not.toContain('supabaseAdmin');
  });
});

// ---------------------------------------------------------------------------
// Connect flow endpoints — 401 without auth (CI-safe)
// requireAuth is the first middleware on every connect route.
// Requests without a Bearer token are rejected before any DB operation.
// ---------------------------------------------------------------------------

describe('POST /api/connect/start', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app)
      .post('/api/connect/start')
      .send({ code: 'ABCD-1234' });
    expect(res.status).toBe(401);
  });
});

describe('PATCH /api/connect/step', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app)
      .patch('/api/connect/step')
      .send({ step: 'profile', display_name: 'Test User' });
    expect(res.status).toBe(401);
  });
});

describe('POST /api/connect/complete', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app).post('/api/connect/complete').send({});
    expect(res.status).toBe(401);
  });
});

describe('GET /api/connect/status', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app).get('/api/connect/status');
    expect(res.status).toBe(401);
  });
});

describe('POST /api/connect/compass-import', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app)
      .post('/api/connect/compass-import')
      .send({ calibrations: [] });
    expect(res.status).toBe(401);
  });
});
