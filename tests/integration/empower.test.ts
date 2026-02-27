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

describe('Empower routes — auth enforcement (CI-safe)', () => {
  it('POST /api/empower/preflight returns 401 without auth', async () => {
    const res = await request(app).post('/api/empower/preflight');
    expect(res.status).toBe(401);
  });

  it('POST /api/empower/confirm returns 401 without auth', async () => {
    const res = await request(app)
      .post('/api/empower/confirm')
      .send({
        consent: {
          legal_name_public: true,
          compass_stances_public: true,
          platform_terms: true,
        },
      });
    expect(res.status).toBe(401);
  });

  it('POST /api/empower/demote returns 401 without auth', async () => {
    const res = await request(app).post('/api/empower/demote');
    expect(res.status).toBe(401);
  });
});

// ---------------------------------------------------------------------------
// Architecture enforcement (CI-safe)
//
// Reads source files directly — no network, no database.
// Catches accidental introduction of the service-role admin client into
// empower routes (all admin operations must go through empowerService in lib/).
// ---------------------------------------------------------------------------

describe('Empower routes — architecture enforcement (CI-safe)', () => {
  it('empower.ts does not reference supabaseAdmin', () => {
    const empowerSource = fs.readFileSync(
      path.resolve(BACKEND_SRC, 'routes/empower.ts'),
      'utf-8'
    );
    expect(empowerSource).not.toContain('supabaseAdmin');
  });
});

// ---------------------------------------------------------------------------
// Full lifecycle (requires Supabase auth + live database)
//
// These tests validate the complete empowerment and demotion flow and must
// run against a live Supabase project with real authenticated users and
// schema migrations applied.
// ---------------------------------------------------------------------------

describe('Empower routes — preflight (requires Supabase auth)', () => {
  it.skip('POST /preflight returns eligible:true for fully qualified Connected user', async () => {
    // Requires: valid JWT for a Connected user with:
    //   - verification_status = 'verified'
    //   - candidate_role set (e.g. 'city_council')
    //   - legal_name set
    //   - compass fully calibrated for their role
    // Assert: 200, body { eligible: true, summary: { legal_name, compass_completeness, slug_preview } }
    //         cache contains slug_reservation:{userId} with 1-hour TTL
  });

  it.skip('POST /preflight returns eligible:false with all failure codes when nothing is ready', async () => {
    // Requires: valid JWT for a Connected user with nothing set
    //   (verification_status = 'pending', no candidate_role, no legal_name, no compass answers)
    // Assert: 200, body { eligible: false, failures: [
    //   { code: 'NOT_VERIFIED', message: ... },
    //   { code: 'ROLE_NOT_SET', message: ... },
    //   { code: 'LEGAL_NAME_MISSING', message: ... },
    // ]}
    // Note: CALIBRATION_INCOMPLETE is only added when candidate_role is set
  });

  it.skip('POST /preflight returns demotion_context for previously demoted user', async () => {
    // Requires: valid JWT for a Connected user who was previously empowered and demoted
    //   (empower.empowered_profiles row exists with is_active=false)
    // Assert: 200, body includes demotion_context: { previously_demoted: true, demoted_at, demotion_reason }
    //         When eligible: demotion_context also includes original_slug
    //         When eligible: slug_preview === original candidate_page_slug (not a new slug)
  });
});

describe('Empower routes — confirm (requires Supabase auth)', () => {
  it.skip('POST /confirm with valid consent creates empowered profile', async () => {
    // Requires: valid JWT for an eligible Connected user who has run preflight
    // Assert: 201, body { empowered: true, profile: { ... } }
    //         empower.empowered_profiles row exists with is_active=true
    //         inform.compass_responses all set to visibility='public' for this user
    //         empower.consent_records row inserted with consented_items
  });

  it.skip('POST /confirm without prior preflight returns 409 PREFLIGHT_EXPIRED', async () => {
    // Requires: valid JWT for an eligible Connected user who has NOT run preflight
    //   (or whose slug_reservation cache key has expired)
    // Assert: 409, body { code: 'PREFLIGHT_EXPIRED', message: ... }
  });

  it.skip('POST /confirm with partial consent returns 422 CONSENT_INCOMPLETE', async () => {
    // Requires: valid JWT for any Connected user
    // Send body: { consent: { legal_name_public: true } }  (missing 2 items)
    // Assert: 422, body { code: 'CONSENT_INCOMPLETE', message: ... }
  });

  it.skip('POST /confirm rolls back entirely on RPC failure — no partial empowered_profiles row exists after failure', async () => {
    // Requires: valid JWT for an eligible user; RPC forced to fail (e.g., by using
    //   a slug that already exists, causing the slug-retry loop to exhaust 5 attempts)
    // Assert: 500 INTERNAL_ERROR
    //         No empowered_profiles row for this user_id exists in DB
    //         inform.compass_responses visibility is UNCHANGED (not set to public)
  });
});

describe('Empower routes — demote (requires Supabase auth)', () => {
  it.skip('POST /demote marks empowered user as inactive with demotion_reason', async () => {
    // Requires: valid JWT for an active Empowered user
    // Send body: { reason: { triggered_by: 'self' } }
    // Assert: 200, body { demoted: true }
    //         empower.empowered_profiles row: is_active=false, demoted_at IS NOT NULL, demotion_reason = { triggered_by: 'self' }
    //         inform.compass_responses all set to visibility='private' for this user
  });

  it.skip('POST /demote is atomic — is_active and visibility change together or not at all', async () => {
    // Requires: RPC forced to fail mid-execution (DB injection of error)
    // Assert: on failure, empowered_profiles.is_active remains true AND
    //         compass_responses visibility remains unchanged
  });
});

describe('Empower routes — re-empowerment (requires Supabase auth)', () => {
  it.skip('Re-empowerment after demotion restores original slug', async () => {
    // Requires: valid JWT for a user with is_active=false empowered_profiles row
    //   who is now eligible for re-empowerment (all conditions met)
    // Flow: POST /preflight → confirm slug_preview === original candidate_page_slug
    //       POST /confirm → empowered_profiles.candidate_page_slug unchanged
    //       GET /account/me → tier: 'empowered', empowerment_status: 'empowered'
  });
});
