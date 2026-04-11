import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';

process.env.JWT_SECRET = process.env.JWT_SECRET ?? 'test-secret-at-least-32-characters-long!!';
process.env.SUPABASE_URL = process.env.SUPABASE_URL ?? 'https://test.supabase.co';
process.env.SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY ?? 'test-anon-key';
process.env.SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY ?? 'test-service-role';
process.env.DATABASE_URL = process.env.DATABASE_URL ?? 'postgresql://postgres:password@localhost:5432/postgres';
process.env.NODE_ENV = 'test';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
let app: any;

beforeAll(async () => {
  const mod = await import('@backend/index.js');
  app = mod.default ?? mod.app ?? mod;
});

describe('GET /api/essentials/bodies — validation (no DB required)', () => {
  it('rejects missing q with 422 VALIDATION_ERROR', async () => {
    const res = await request(app).get('/api/essentials/bodies');
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('VALIDATION_ERROR');
    expect(res.headers['content-type']).toMatch(/application\/json/);
  });

  it('rejects q shorter than 2 chars with 422', async () => {
    const res = await request(app).get('/api/essentials/bodies').query({ q: 'a' });
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('VALIDATION_ERROR');
  });

  it('rejects malformed state with 422', async () => {
    const res = await request(app)
      .get('/api/essentials/bodies')
      .query({ q: 'bloom', state: 'IND' });
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('VALIDATION_ERROR');
  });
});

describe('GET /api/essentials/bodies — search happy path (DB-optional)', () => {
  it('accepts valid q and returns array shape on 200', async () => {
    const res = await request(app).get('/api/essentials/bodies').query({ q: 'bloom' });
    expect([200, 500]).toContain(res.status);
    if (res.status === 200) {
      expect(Array.isArray(res.body)).toBe(true);
      for (const row of res.body) {
        expect(row).toHaveProperty('slug');
        expect(row).toHaveProperty('name_formal');
        expect(row).toHaveProperty('state');
        expect(row).toHaveProperty('member_count');
        expect(typeof row.slug).toBe('string');
        expect(typeof row.name_formal).toBe('string');
        expect(typeof row.state).toBe('string');
        expect(typeof row.member_count).toBe('number');
        for (const key of Object.keys(row)) {
          expect(key).not.toMatch(/party|affiliation/i);
        }
      }
    }
  });

  it('accepts valid state filter and returns array shape on 200', async () => {
    const res = await request(app)
      .get('/api/essentials/bodies')
      .query({ q: 'bloom', state: 'in' });
    expect([200, 500]).toContain(res.status);
    if (res.status === 200) expect(Array.isArray(res.body)).toBe(true);
  });
});

describe('GET /api/essentials/bodies/:slug/roster — validation & errors', () => {
  it('rejects malformed slug with 422', async () => {
    const res = await request(app).get('/api/essentials/bodies/BAD_SLUG/roster');
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('VALIDATION_ERROR');
  });

  it('returns 404 BODY_NOT_FOUND (or tolerant 500) for unknown slug', async () => {
    const res = await request(app).get('/api/essentials/bodies/totally-fake-body-does-not-exist/roster');
    expect([404, 500]).toContain(res.status);
    if (res.status === 404) {
      expect(res.body.code).toBe('BODY_NOT_FOUND');
      expect(res.headers['content-type']).toMatch(/application\/json/);
    }
  });
});

describe('GET /api/essentials/bodies/:slug/roster — Bloomington happy path (DB-optional)', () => {
  it('returns D-16 shape for bloomington-common-council with no party keys and under 500ms', async () => {
    const start = Date.now();
    const res = await request(app).get('/api/essentials/bodies/bloomington-common-council/roster');
    const elapsed = Date.now() - start;

    expect([200, 404, 500]).toContain(res.status);

    if (res.status === 200) {
      expect(elapsed).toBeLessThan(500);

      expect(res.body).toHaveProperty('slug', 'bloomington-common-council');
      expect(res.body).toHaveProperty('name_formal');
      expect(res.body).toHaveProperty('state');
      expect(res.body).toHaveProperty('fetched_at');
      expect(typeof res.body.fetched_at).toBe('string');
      expect(() => new Date(res.body.fetched_at)).not.toThrow();

      expect(Array.isArray(res.body.members)).toBe(true);

      for (const key of Object.keys(res.body)) {
        expect(key).not.toMatch(/party|affiliation/i);
      }

      for (const m of res.body.members) {
        expect(m).toHaveProperty('politician_slug');
        expect(m).toHaveProperty('politician_id');
        expect(typeof m.politician_id).toBe('string');
        expect(m).toHaveProperty('full_name');
        expect(m).toHaveProperty('preferred_name');
        expect(m).toHaveProperty('title');
        expect(m).toHaveProperty('chamber_name');
        expect(m).toHaveProperty('district_label');
        expect(typeof m.district_label).toBe('string');
        expect(m).toHaveProperty('photo_url');
        expect(m.photo_url === null || typeof m.photo_url === 'string').toBe(true);

        for (const key of Object.keys(m)) {
          expect(key).not.toMatch(/party|affiliation/i);
        }
      }
    }
  });
});
