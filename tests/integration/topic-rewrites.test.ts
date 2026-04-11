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

describe('Topic rewrites routes — 401 enforcement (CI-safe)', () => {
  it('GET /api/admin/topic-rewrites requires auth', async () => {
    const res = await request(app).get('/api/admin/topic-rewrites');
    expect(res.status).toBe(401);
  });

  it('GET /api/admin/topic-rewrites/:id requires auth', async () => {
    const res = await request(app).get(
      '/api/admin/topic-rewrites/00000000-0000-0000-0000-000000000000',
    );
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites requires auth', async () => {
    const res = await request(app).post('/api/admin/topic-rewrites').send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/submit-framing requires auth', async () => {
    const res = await request(app)
      .post('/api/admin/topic-rewrites/x/submit-framing')
      .send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/approve-framing requires auth', async () => {
    const res = await request(app)
      .post('/api/admin/topic-rewrites/x/approve-framing')
      .send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/mark-publish-ready requires auth', async () => {
    const res = await request(app)
      .post('/api/admin/topic-rewrites/x/mark-publish-ready')
      .send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/publish requires auth', async () => {
    const res = await request(app).post('/api/admin/topic-rewrites/x/publish').send({});
    expect(res.status).toBe(401);
  });

  it('PUT /api/admin/topic-rewrites/:id/proposals/:politicianId requires auth', async () => {
    const res = await request(app)
      .put('/api/admin/topic-rewrites/x/proposals/y')
      .send({ proposed_value: 3, proposed_reasoning: '', proposed_sources: [] });
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/proposals/:politicianId/approve requires auth', async () => {
    const res = await request(app)
      .post('/api/admin/topic-rewrites/x/proposals/y/approve')
      .send({});
    expect(res.status).toBe(401);
  });

  it('POST /api/admin/topic-rewrites/:id/proposals/:politicianId/reject requires auth', async () => {
    const res = await request(app)
      .post('/api/admin/topic-rewrites/x/proposals/y/reject')
      .send({});
    expect(res.status).toBe(401);
  });
});
