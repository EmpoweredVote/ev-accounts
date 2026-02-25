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

  // Zod validation runs after requireAuth — missing body yields 401 (not 422)
  // because requireAuth fires first. Tests below require a valid JWT.
  it.skip('returns 422 with missing code field', async () => {
    // Requires: valid JWT; Zod rejects body before DB call
  });

  it.skip('returns 409 for user who already has a Connected profile', async () => {
    // Requires: authenticated user with connected_profiles row in DB
  });

  it.skip('returns 200 and creates verification_session with valid invite code', async () => {
    // Requires: authenticated user JWT and a real unclaimed code in DB
    // Assert: session created with step_reached='profile', invite_code_id recorded
  });

  it.skip('returns 200 and resumes existing session if user already started flow', async () => {
    // Requires: user with verification_session at step 'profile' (not 'invite')
    // Assert: same session_id returned, no new code claim attempted
  });
});

describe('PATCH /api/connect/step', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app)
      .patch('/api/connect/step')
      .send({ step: 'profile', display_name: 'Test User' });
    expect(res.status).toBe(401);
  });

  it.skip('returns 422 with invalid step value (not profile or review)', async () => {
    // Requires: valid JWT; Zod enum rejects unknown step value
  });

  it.skip('returns 422 with no step field in body', async () => {
    // Requires: valid JWT; Zod rejects missing required field
  });

  it.skip('returns 404 when user has no active verification session', async () => {
    // Requires: authenticated user with no verification_sessions row
  });

  it.skip('returns 200 and updates draft fields', async () => {
    // Requires: user with session at 'profile'; sends display_name + legal_name
    // Assert: step_reached stays 'profile', drafts updated
  });

  it.skip('advances step_reached to review when all 4 required fields are present', async () => {
    // Requires: user with session; sends step='review' + all 4 fields populated
    // Assert: step_reached becomes 'review'
  });

  it.skip('does NOT advance to review when step=review but fields are incomplete', async () => {
    // Requires: user with session; sends step='review' without all 4 fields
    // Assert: step_reached stays 'profile'
  });
});

describe('POST /api/connect/complete', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app).post('/api/connect/complete').send({});
    expect(res.status).toBe(401);
  });

  it.skip('returns 404 when user has no verification session', async () => {
    // Requires: authenticated user with no session row
  });

  it.skip('returns 400 when session step_reached is not review', async () => {
    // Requires: user with session at step 'profile'
    // Assert: code 'INCOMPLETE_SESSION'
  });

  it.skip('returns 400 when required fields are missing from session', async () => {
    // Requires: user with session at 'review' step but null draft fields
    // Assert: code 'MISSING_REQUIRED_FIELDS'
  });

  it.skip('returns 201 and creates connected_profiles record', async () => {
    // Requires: user with fully-populated session at 'review' step
    // Assert: connected_profiles row inserted, response has connected:true
  });

  it.skip('sets verification_status to verified in connected_profiles', async () => {
    // Requires: complete flow; assert verification_status='verified' in DB
  });

  it.skip('sets tolerance_rating to 10.00 in connected_profiles', async () => {
    // Requires: complete flow; assert tolerance_rating=10.00 in DB
  });

  it.skip('advances verification_session step_reached to complete', async () => {
    // Requires: complete flow; assert session.step_reached='complete' in DB
  });

  it.skip('syncs display_name to public.users', async () => {
    // Requires: complete flow; assert public.users.display_name updated
  });

  it.skip('returns 409 on second attempt (idempotent — prevents double-creation)', async () => {
    // Requires: complete flow run twice
    // Assert: second POST returns 409, code 'ALREADY_CONNECTED'
  });

  it.skip('does NOT return tolerance_rating in response body', async () => {
    // Privacy enforcement: tolerance_rating must not appear in 201 response
    // Assert: response body does not have a 'tolerance_rating' key at any level
  });

  it.skip('does NOT return legal_name in response body', async () => {
    // Privacy enforcement: legal_name must not appear in 201 response
    // Assert: response body does not have a 'legal_name' key at any level
  });
});

describe('GET /api/connect/status', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app).get('/api/connect/status');
    expect(res.status).toBe(401);
  });

  it.skip('returns { status: "not_started" } for new user with no session', async () => {
    // Requires: authenticated user with no session and no connected_profiles
  });

  it.skip('returns { status: "in_progress", step_reached } for user with active session', async () => {
    // Requires: user with verification_session at some intermediate step
  });

  it.skip('returns { status: "verified" } for user who completed the flow', async () => {
    // Requires: user with connected_profiles row (verification_status='verified')
  });

  it.skip('returns { status: "pending" } for user with pending profile', async () => {
    // Requires: user with connected_profiles row (verification_status='pending')
  });

  it.skip('returns { status: "suspended" } for suspended user', async () => {
    // Requires: user with connected_profiles row (verification_status='suspended')
  });
});

describe('POST /api/connect/compass-import', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app)
      .post('/api/connect/compass-import')
      .send({ calibrations: [] });
    expect(res.status).toBe(401);
  });

  it.skip('returns 422 when calibrations field is missing', async () => {
    // Requires: valid JWT; Zod rejects missing required array
  });

  it.skip('returns 404 when user has no active verification session', async () => {
    // Requires: authenticated user with no session
  });

  it.skip('returns validation results with mismatched topics when confirmed=false', async () => {
    // Requires: user with session; seeds topics with specific versions
    // Assert: { valid, mismatched, ready_to_import } shape returned
  });

  it.skip('returns ready_to_import:true when all topic versions match', async () => {
    // Requires: user with session; calibrations all match live topic versions
  });

  it.skip('returns { imported:true, count } when confirmed=true', async () => {
    // Requires: user with session; sends confirmed:true
    // Assert: compass_import_draft stored in verification_sessions
  });

  it.skip('stores calibrations in verification_sessions.compass_import_draft (not compass_responses)', async () => {
    // This plan intentionally defers compass_responses write to Phase 4.
    // Assert: compass_import_draft updated; no row in inform.compass_responses
  });
});
