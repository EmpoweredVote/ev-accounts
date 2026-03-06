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
