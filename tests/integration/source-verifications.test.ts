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

describe('Admin source-verifications routes — 401 enforcement (CI-safe)', () => {

  it('GET /api/admin/source-verifications requires auth', async () => {
    const res = await request(app).get('/api/admin/source-verifications');
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/source-verifications/:id/approve requires auth', async () => {
    const res = await request(app).post('/api/admin/source-verifications/some-id/approve').send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/source-verifications/:id/unfixable requires auth', async () => {
    const res = await request(app).post('/api/admin/source-verifications/some-id/unfixable').send({});
    expect(res.status).toBe(401);
  });

});
