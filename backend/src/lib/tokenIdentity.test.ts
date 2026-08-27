import { describe, it, expect, vi, beforeEach } from 'vitest';

const SUPABASE_URL = 'https://test-project.supabase.co';
const CLIENT_ID = 'client_01TESTTESTTESTTESTTESTTEST';

let mockEnv: Record<string, string | undefined> = {};
vi.mock('./env.js', () => ({
  get env() {
    return mockEnv;
  },
}));

/** Fresh module instance per test — issuer constants are module-scoped. */
async function freshModule() {
  vi.resetModules();
  return import('./tokenIdentity.js');
}

/** Unsigned three-part JWT — classifyToken reads claims without verifying. */
function fakeJwt(payload: Record<string, unknown>): string {
  const b64 = (obj: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(obj)).toString('base64url');
  return `${b64({ alg: 'RS256', typ: 'JWT' })}.${b64(payload)}.sig`;
}

beforeEach(() => {
  mockEnv = { SUPABASE_URL, WORKOS_CLIENT_ID: CLIENT_ID };
});

describe('issuer constants', () => {
  it('derives WorkOS issuer and JWKS URL from the client id', async () => {
    const m = await freshModule();
    expect(m.SUPABASE_ISSUER).toBe(`${SUPABASE_URL}/auth/v1`);
    expect(m.WORKOS_ISSUER).toBe(`https://api.workos.com/user_management/${CLIENT_ID}`);
    expect(m.WORKOS_JWKS_URL).toBe(`https://api.workos.com/sso/jwks/${CLIENT_ID}`);
  });

  it('is Supabase-only when WORKOS_CLIENT_ID is absent', async () => {
    mockEnv = { SUPABASE_URL };
    const m = await freshModule();
    expect(m.WORKOS_ISSUER).toBeNull();
    expect(m.WORKOS_JWKS_URL).toBeNull();
  });

  it('honors custom-domain overrides', async () => {
    mockEnv = {
      SUPABASE_URL,
      WORKOS_CLIENT_ID: CLIENT_ID,
      WORKOS_ISSUER: 'https://auth.empowered.vote',
      WORKOS_JWKS_URL: 'https://auth.empowered.vote/sso/jwks',
    };
    const m = await freshModule();
    expect(m.WORKOS_ISSUER).toBe('https://auth.empowered.vote');
    expect(m.WORKOS_JWKS_URL).toBe('https://auth.empowered.vote/sso/jwks');
  });
});

describe('classifyToken', () => {
  it('classifies a Supabase-issued token', async () => {
    const m = await freshModule();
    expect(m.classifyToken(fakeJwt({ iss: `${SUPABASE_URL}/auth/v1` }))).toBe('supabase');
  });

  it('classifies a WorkOS-issued token', async () => {
    const m = await freshModule();
    const iss = `https://api.workos.com/user_management/${CLIENT_ID}`;
    expect(m.classifyToken(fakeJwt({ iss }))).toBe('workos');
  });

  it('rejects a WorkOS token when WORKOS_CLIENT_ID is not configured', async () => {
    mockEnv = { SUPABASE_URL };
    const m = await freshModule();
    const iss = `https://api.workos.com/user_management/${CLIENT_ID}`;
    expect(m.classifyToken(fakeJwt({ iss }))).toBeNull();
  });

  it('rejects unknown issuers and malformed tokens', async () => {
    const m = await freshModule();
    expect(m.classifyToken(fakeJwt({ iss: 'https://evil.example.com' }))).toBeNull();
    expect(m.classifyToken(fakeJwt({}))).toBeNull();
    expect(m.classifyToken('not-a-jwt')).toBeNull();
  });
});

describe('resolveInternalUserId', () => {
  const UUID = '4f9c1a2e-0000-4000-8000-000000000000';

  it('Supabase: internal id is the sub claim', async () => {
    const m = await freshModule();
    expect(m.resolveInternalUserId('supabase', { sub: UUID })).toBe(UUID);
  });

  it('Supabase: missing or empty sub does not resolve', async () => {
    const m = await freshModule();
    expect(m.resolveInternalUserId('supabase', {})).toBeNull();
    expect(m.resolveInternalUserId('supabase', { sub: '' })).toBeNull();
  });

  it('WorkOS: internal id is external_id, never the WorkOS sub', async () => {
    const m = await freshModule();
    const payload = { sub: 'user_01HXYZ', external_id: UUID };
    expect(m.resolveInternalUserId('workos', payload)).toBe(UUID);
  });

  it('WorkOS: an unlinked account (no external_id) does not resolve', async () => {
    const m = await freshModule();
    expect(m.resolveInternalUserId('workos', { sub: 'user_01HXYZ' })).toBeNull();
    expect(m.resolveInternalUserId('workos', { sub: 'user_01HXYZ', external_id: '' })).toBeNull();
    expect(m.resolveInternalUserId('workos', { sub: 'user_01HXYZ', external_id: 42 })).toBeNull();
  });
});
