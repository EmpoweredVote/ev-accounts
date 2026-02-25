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

describe('Architecture enforcement: invite routes', () => {
  it('invite route file does not reference service-role client', () => {
    const content = fs.readFileSync(
      path.resolve(BACKEND_SRC, 'routes/invites.ts'),
      'utf-8'
    );
    expect(content).not.toContain('supabaseAdmin');
  });
});

// ---------------------------------------------------------------------------
// Invite endpoints — 401 without auth (CI-safe)
// requireAuth is the first middleware on all invite routes.
// Requests without a Bearer token are rejected before any DB operation.
// ---------------------------------------------------------------------------

describe('POST /api/invites/send', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app).post('/api/invites/send').send({});
    expect(res.status).toBe(401);
  });

  // Supabase-dependent: requireConnected needs a real connected_profiles row
  it.skip('returns 403 for non-Connected (Inform-tier) user', async () => {
    // Requires: authenticated user JWT without connected_profiles row
  });

  it.skip('returns 201 with generated invite code for Connected user', async () => {
    // Requires: authenticated Connected-tier user JWT
  });

  it.skip('returns 409 when user already has 5 pending (unclaimed) codes', async () => {
    // Requires: Connected user with 5 unclaimed codes seeded
  });
});

describe('POST /api/invites/claim', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app)
      .post('/api/invites/claim')
      .send({ code: 'ABCD-1234' });
    expect(res.status).toBe(401);
  });

  // Zod validation runs after requireAuth, so missing body → 401 (no auth header).
  // Validation-only tests that need no DB require a valid JWT (Supabase-dependent).
  it.skip('returns 422 with missing code field', async () => {
    // Requires: valid JWT; Zod rejects body before DB call
  });

  it.skip('returns 422 with code too short (e.g. "AB-123")', async () => {
    // Requires: valid JWT; Zod min(9) rejects short code
  });

  it.skip('returns 422 with code too long (e.g. "ABCD-12345")', async () => {
    // Requires: valid JWT; Zod max(9) rejects long code
  });

  it.skip('returns 404 for non-existent invite code', async () => {
    // Requires: authenticated user JWT; claimInviteCode returns INVALID_CODE
  });

  it.skip('returns 200 with claimed:true for valid unclaimed code', async () => {
    // Requires: authenticated user JWT and a real unclaimed code in DB
  });

  it.skip('returns 409 for already-claimed code', async () => {
    // Requires: code with is_claimed=true in DB
  });

  it.skip('returns 410 for expired code', async () => {
    // Requires: code with expires_at in the past
  });

  it.skip('returns 403 for self-invite (claimant is code creator)', async () => {
    // Requires: code created by the same user attempting to claim
  });

  it.skip('creates invite_chains record when code has a real inviter', async () => {
    // Requires: code with non-null created_by; asserts invite_chains row inserted
  });
});

describe('GET /api/invites/mine', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app).get('/api/invites/mine');
    expect(res.status).toBe(401);
  });

  it.skip('returns only codes created by the authenticated user', async () => {
    // Requires: Connected user JWT; seeds codes for two users, asserts isolation
  });

  it.skip('response does not include created_by or claimed_by fields', async () => {
    // Requires: Connected user JWT; whitelist serialization check
    // Assert: response body items do NOT have created_by or claimed_by keys
  });
});
