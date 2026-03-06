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
});

describe('POST /api/invites/claim', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app)
      .post('/api/invites/claim')
      .send({ code: 'ABCD-1234' });
    expect(res.status).toBe(401);
  });
});

describe('GET /api/invites/mine', () => {
  it('returns 401 without auth', async () => {
    const res = await request(app).get('/api/invites/mine');
    expect(res.status).toBe(401);
  });
});
