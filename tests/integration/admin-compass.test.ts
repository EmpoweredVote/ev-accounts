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

describe('Admin compass routes — 401 enforcement (CI-safe)', () => {

  // Topics
  it('GET /api/admin/compass/topics requires auth', async () => {
    const res = await request(app).get('/api/admin/compass/topics');
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/compass/topics requires auth', async () => {
    const res = await request(app).post('/api/admin/compass/topics').send({});
    expect(res.status).toBe(401);
  });

  it('PATCH /api/admin/compass/topics/:id requires auth', async () => {
    const res = await request(app).patch('/api/admin/compass/topics/some-id').send({});
    expect(res.status).toBe(401);
  });

  it('PATCH /api/admin/compass/stances/:id requires auth', async () => {
    const res = await request(app).patch('/api/admin/compass/stances/some-id').send({});
    expect(res.status).toBe(401);
  });

  // Categories
  it('GET /api/admin/compass/categories requires auth', async () => {
    const res = await request(app).get('/api/admin/compass/categories');
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/compass/categories requires auth', async () => {
    const res = await request(app).post('/api/admin/compass/categories').send({});
    expect(res.status).toBe(401);
  });

  it('PUT /api/admin/compass/topics/:id/categories requires auth', async () => {
    const res = await request(app).put('/api/admin/compass/topics/some-id/categories').send({});
    expect(res.status).toBe(401);
  });

  // Politicians
  it('GET /api/admin/compass/politicians requires auth', async () => {
    const res = await request(app).get('/api/admin/compass/politicians');
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/compass/politicians requires auth', async () => {
    const res = await request(app).post('/api/admin/compass/politicians').send({});
    expect(res.status).toBe(401);
  });

  it('PATCH /api/admin/compass/politicians/:id requires auth', async () => {
    const res = await request(app).patch('/api/admin/compass/politicians/some-id').send({});
    expect(res.status).toBe(401);
  });

  it('PUT /api/admin/compass/politicians/:id/answers requires auth', async () => {
    const res = await request(app).put('/api/admin/compass/politicians/some-id/answers').send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/compass/politicians/:id/context requires auth', async () => {
    const res = await request(app).post('/api/admin/compass/politicians/some-id/context').send({});
    expect(res.status).toBe(401);
  });

});
