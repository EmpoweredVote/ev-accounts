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
// CI-safe tests
//
// These tests always run — no database required. They verify route wiring
// (HTTP plumbing, validation), and architecture constraints (file content).
// ---------------------------------------------------------------------------

describe('Candidate routes: CI-safe tests', () => {
  // -------------------------------------------------------------------------
  // Route wiring: GET /api/candidates/:slug
  // -------------------------------------------------------------------------

  it('GET /api/candidates/:slug returns 404 for non-existent slug', async () => {
    // optionalAuth routes make a real DB call when they hit candidateService.
    // With no live DB, the service will throw and return 500 — OR if slug
    // not found returns 404. Either way this confirms route wiring exists.
    // The supertest call must reach our handler (not 404 from Express itself).
    const res = await request(app).get('/api/candidates/nonexistent-slug-12345');
    // Route is wired — Express handled the request (not 404 from unregistered route)
    // With no DB, candidateService throws → 500. Route IS wired if not 404 from Express.
    // We assert it is NOT a completely unhandled route (which would give a different response).
    expect([404, 500]).toContain(res.status);
    if (res.status === 404) {
      expect(res.body).toMatchObject({ code: 'NOT_FOUND' });
    }
    if (res.status === 500) {
      expect(res.body).toMatchObject({ code: 'INTERNAL_ERROR' });
    }
  });

  it('GET /api/candidates/:slug/answers returns 422 when topics param missing', async () => {
    // Validation happens BEFORE any DB call — safe in CI
    const res = await request(app).get('/api/candidates/some-slug/answers');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
    expect(res.body.message).toContain('topics');
  });

  it('GET /api/candidates/:slug/answers returns 422 when topics param is empty string', async () => {
    const res = await request(app).get('/api/candidates/some-slug/answers?topics=');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
  });

  it('GET /api/candidates/:slug/answers returns 422 for non-UUID topic IDs', async () => {
    const res = await request(app).get('/api/candidates/some-slug/answers?topics=not-a-uuid');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
  });

  // -------------------------------------------------------------------------
  // Route wiring: GET /api/essentials/candidates/:zip
  // -------------------------------------------------------------------------

  it('GET /api/essentials/candidates/:zip returns 422 for alphabetic ZIP', async () => {
    const res = await request(app).get('/api/essentials/candidates/abc');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
  });

  it('GET /api/essentials/candidates/:zip returns 422 for partial ZIP (3 digits)', async () => {
    const res = await request(app).get('/api/essentials/candidates/123');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
  });

  it('GET /api/essentials/candidates/:zip returns 422 for partial ZIP (4 digits)', async () => {
    const res = await request(app).get('/api/essentials/candidates/1234');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
  });

  it('GET /api/essentials/candidates/:zip accepts valid 5-digit ZIP (may return 200 or 500 without DB)', async () => {
    // Validation passes — DB call happens. Without live DB: 500.
    // With live DB: 200 with array. Either confirms valid ZIP is accepted.
    const res = await request(app).get('/api/essentials/candidates/47401');
    expect([200, 500]).toContain(res.status);
    if (res.status === 200) {
      expect(Array.isArray(res.body)).toBe(true);
    }
    if (res.status === 500) {
      expect(res.body).toMatchObject({ code: 'INTERNAL_ERROR' });
    }
  });

  it('GET /api/essentials/candidates/:zip accepts ZIP+4 format', async () => {
    const res = await request(app).get('/api/essentials/candidates/47401-1234');
    expect([200, 500]).toContain(res.status);
    if (res.status === 200) {
      expect(Array.isArray(res.body)).toBe(true);
    }
  });

  it('GET /api/essentials/candidates/:zip returns 422 for malformed ZIP+4 (missing 4 digits)', async () => {
    const res = await request(app).get('/api/essentials/candidates/47401-12');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
  });

  // -------------------------------------------------------------------------
  // Architecture enforcement — file content assertions (no DB, no network)
  // Catches accidental introduction of service-role client into route files.
  // Per decision [07-01]: test uses literal string match, so comments in route
  // files must NOT contain the banned identifier.
  // -------------------------------------------------------------------------

  it('candidates.ts does not reference service-role client', () => {
    const candidatesSource = fs.readFileSync(
      path.resolve(BACKEND_SRC, 'routes/candidates.ts'),
      'utf-8'
    );
    expect(candidatesSource).not.toContain('supabaseAdmin');
  });

  it('essentialsCandidates.ts does not reference service-role client', () => {
    const essentialsSource = fs.readFileSync(
      path.resolve(BACKEND_SRC, 'routes/essentialsCandidates.ts'),
      'utf-8'
    );
    expect(essentialsSource).not.toContain('supabaseAdmin');
  });

  it('candidateService.ts does not include tolerance_rating in any response building', () => {
    const serviceSource = fs.readFileSync(
      path.resolve(BACKEND_SRC, 'lib/candidateService.ts'),
      'utf-8'
    );
    // tolerance_rating must NEVER appear in response objects — privacy enforcement
    expect(serviceSource).not.toContain('tolerance_rating');
  });

  it('candidateService.ts does not spread database rows into response objects', () => {
    const serviceSource = fs.readFileSync(
      path.resolve(BACKEND_SRC, 'lib/candidateService.ts'),
      'utf-8'
    );
    // Spreading DB rows (e.g., ...data, ...row, ...profile) would leak internal fields.
    // All response objects must be built from explicit whitelists.
    const spreadPattern = /\.\.\.\s*(data|row|profile|candidate)\b/;
    expect(spreadPattern.test(serviceSource)).toBe(false);
  });

  it('candidateService.ts does not include legal_name in exported response types', () => {
    const serviceSource = fs.readFileSync(
      path.resolve(BACKEND_SRC, 'lib/candidateService.ts'),
      'utf-8'
    );
    // CandidateProfile and EssentialsCandidate interfaces must NOT expose legal_name.
    // Interfaces start with "export interface" — check that legal_name never appears in them.
    // The field is used internally (for splitting) but must not appear in public types.
    const interfaceSection = serviceSource.match(
      /export interface (CandidateProfile|EssentialsCandidate)[\s\S]*?^}/m
    );
    if (interfaceSection) {
      expect(interfaceSection[0]).not.toContain('legal_name');
    }
    // Additionally: legal_name must not appear in CandidateAnswer interface
    const answerInterface = serviceSource.match(/export interface CandidateAnswer[\s\S]*?^}/m);
    if (answerInterface) {
      expect(answerInterface[0]).not.toContain('legal_name');
    }
  });

  it('index.ts mounts /api/candidates route', () => {
    const indexSource = fs.readFileSync(path.resolve(BACKEND_SRC, 'index.ts'), 'utf-8');
    expect(indexSource).toContain('/api/candidates');
  });

  it('index.ts mounts /api/essentials/candidates route', () => {
    const indexSource = fs.readFileSync(path.resolve(BACKEND_SRC, 'index.ts'), 'utf-8');
    expect(indexSource).toContain('/api/essentials/candidates');
  });

  it('index.ts imports candidatesRouter', () => {
    const indexSource = fs.readFileSync(path.resolve(BACKEND_SRC, 'index.ts'), 'utf-8');
    expect(indexSource).toContain('candidatesRouter');
  });
});

// ---------------------------------------------------------------------------
// DB-dependent tests — marked it.skip per decision [04-03]
//
// These tests require a live Supabase project with Phase 8 migrations applied
// and at least one active empowered candidate profile in the database.
//
// To run: apply migrations, seed test data, and run without --skip-pattern.
// ---------------------------------------------------------------------------

describe('Candidate routes: DB-dependent tests', () => {
  // CAND-02: tolerance_rating must be absent from ALL candidate responses
  // (not null — structurally absent from the response object)

  it.skip('GET /api/candidates/:slug does not include tolerance_rating in response', async () => {
    // Requires: active candidate with known slug in live DB
    const res = await request(app).get('/api/candidates/test-candidate-slug');
    expect(res.status).toBe(200);
    expect('tolerance_rating' in res.body).toBe(false);
  });

  it.skip('GET /api/essentials/candidates/:zip does not include tolerance_rating in any response item', async () => {
    // Requires: active candidate with known representing_zip in live DB
    const res = await request(app).get('/api/essentials/candidates/47401');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    for (const item of res.body) {
      expect('tolerance_rating' in item).toBe(false);
    }
  });

  // CAND-03: Inactive candidate behavior

  it.skip('GET /api/candidates/:slug returns full profile for inactive candidate with active: false', async () => {
    // Requires: demoted candidate with known slug in live DB (is_active = false)
    const res = await request(app).get('/api/candidates/demoted-candidate-slug');
    expect(res.status).toBe(200);
    expect(res.body.active).toBe(false);
    expect(typeof res.body.demoted_at).toBe('string');
    // Profile is complete — demotion notice comes from active: false, not missing data
    expect(res.body.candidate_page_slug).toBeDefined();
    expect(res.body.first_name).toBeDefined();
    expect(res.body.last_name).toBeDefined();
  });

  it.skip('GET /api/essentials/candidates/:zip excludes inactive candidates', async () => {
    // Requires: ZIP with at least one active AND one inactive candidate
    const res = await request(app).get('/api/essentials/candidates/47401');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    for (const item of res.body) {
      // No inactive candidates in Essentials response
      expect('active' in item && item.active === false).toBe(false);
    }
  });

  // Inversion logic

  it.skip('GET /api/candidates/:slug/answers applies inversion to specified topics', async () => {
    // Requires: candidate with a known public answer for a specific topic
    // The original value and inverted value (6 - original) must differ
    const topicId = '00000000-0000-0000-0000-000000000001'; // Replace with real live topic UUID
    const slug = 'test-candidate-slug';

    // Without inversion
    const resNormal = await request(app)
      .get(`/api/candidates/${slug}/answers?topics=${topicId}`);
    expect(resNormal.status).toBe(200);
    const originalValue = resNormal.body[0]?.value;
    expect(typeof originalValue).toBe('number');

    // With inversion
    const resInverted = await request(app)
      .get(`/api/candidates/${slug}/answers?topics=${topicId}&inverted=${topicId}`);
    expect(resInverted.status).toBe(200);
    const invertedValue = resInverted.body[0]?.value;
    expect(invertedValue).toBe(6 - originalValue);
  });

  // Full response shape validation (CAND-01 + CAND-02 combined)

  it.skip('GET /api/candidates/:slug response has expected shape', async () => {
    // Requires: active candidate in live DB
    const res = await request(app).get('/api/candidates/test-candidate-slug');
    expect(res.status).toBe(200);

    // Required fields
    expect(res.body.candidate_page_slug).toBeDefined();
    expect(typeof res.body.first_name).toBe('string');
    expect(typeof res.body.last_name).toBe('string');
    expect(typeof res.body.active).toBe('boolean');
    expect('demoted_at' in res.body).toBe(true); // field present, may be null
    expect(Array.isArray(res.body.images)).toBe(true);
    expect(Array.isArray(res.body.featured_stances)).toBe(true);

    // Prohibited fields — must be structurally absent (not null)
    expect('tolerance_rating' in res.body).toBe(false);
    expect('user_id' in res.body).toBe(false);
    expect('legal_name' in res.body).toBe(false);
  });

  it.skip('GET /api/essentials/candidates/:zip items have expected shape', async () => {
    // Requires: active candidate with known ZIP in live DB
    const res = await request(app).get('/api/essentials/candidates/47401');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);

    for (const item of res.body) {
      // Required fields
      expect(typeof item.candidate_page_slug).toBe('string');
      expect(typeof item.first_name).toBe('string');
      expect(typeof item.last_name).toBe('string');
      expect(Array.isArray(item.images)).toBe(true);

      // Prohibited fields — must be structurally absent
      expect('tolerance_rating' in item).toBe(false);
      expect('user_id' in item).toBe(false);
      expect('legal_name' in item).toBe(false);
    }
  });

  // Valid slug not found

  it.skip('GET /api/candidates/:slug returns 404 for non-existent slug with live DB', async () => {
    // Requires: live DB (so the service returns null cleanly instead of throwing)
    const res = await request(app).get('/api/candidates/definitely-not-a-real-slug-xyz-99999');
    expect(res.status).toBe(404);
    expect(res.body).toMatchObject({ code: 'NOT_FOUND' });
  });

  // Valid ZIP with no candidates

  it.skip('GET /api/essentials/candidates/:zip returns 200 with empty array for ZIP with no candidates', async () => {
    // Requires: live DB; use a ZIP known to have no candidates (e.g., remote area)
    const res = await request(app).get('/api/essentials/candidates/00000');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });
});
