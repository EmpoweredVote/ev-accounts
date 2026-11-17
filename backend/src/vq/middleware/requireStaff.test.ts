import { describe, it, expect, vi, beforeEach, beforeAll } from 'vitest';
import { generateKeyPair, exportJWK, SignJWT, createLocalJWKSet } from 'jose';
import type { JWK } from 'jose';

// requireStaff decides staff from public.admin_users, never from the token (ev-cto 0041).
// These tests run the REAL requireAuth in front of it, so the WorkOS case proves the whole
// chain: a WorkOS-signed token with no app_metadata resolves to the internal user id and is
// admitted when that id is in admin_users.

const WORKOS_CLIENT_ID = 'client_test';
const WORKOS_ISSUER = `https://api.workos.com/user_management/${WORKOS_CLIENT_ID}`;
process.env.WORKOS_CLIENT_ID = WORKOS_CLIENT_ID;
process.env.SUPABASE_URL = process.env.SUPABASE_URL ?? 'https://example.supabase.co';

const STAFF_ID = '11111111-1111-4111-8111-111111111111';
const NON_STAFF_ID = '22222222-2222-4222-8222-222222222222';

let publicJwk: JWK;
let privateKey: CryptoKey;

// Swap the remote JWKS for a local one holding the test key, so tokens signed here verify.
vi.mock('jose', async (orig) => {
  const actual = await orig<typeof import('jose')>();
  return {
    ...actual,
    createRemoteJWKSet: () => (protectedHeader: unknown, token: unknown) =>
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (actual.createLocalJWKSet({ keys: [publicJwk] }) as any)(protectedHeader, token),
  };
});

// admin_users lookup: the id asked for, and what the table answers.
let lookedUp: string | null = null;
let lookupError: { message: string } | null = null;
vi.mock('../lib/supabase.js', () => ({
  supabaseService: {
    from: (table: string) => ({
      select: () => ({
        eq: (_col: string, id: string) => ({
          maybeSingle: async () => {
            lookedUp = id;
            if (table !== 'admin_users') throw new Error(`unexpected table ${table}`);
            if (lookupError) return { data: null, error: lookupError };
            return { data: id === STAFF_ID ? { user_id: id } : null, error: null };
          },
        }),
      }),
    }),
  },
}));

const { requireAuth } = await import('./auth.js');
const { requireStaff } = await import('./tierGuards.js');

beforeAll(async () => {
  const kp = await generateKeyPair('RS256');
  privateKey = kp.privateKey as CryptoKey;
  publicJwk = { ...(await exportJWK(kp.publicKey)), kid: 'k1', alg: 'RS256' };
  // sanity: the local set accepts the key
  createLocalJWKSet({ keys: [publicJwk] });
});

beforeEach(() => {
  lookedUp = null;
  lookupError = null;
});

function workosToken(claims: Record<string, unknown>) {
  return new SignJWT(claims)
    .setProtectedHeader({ alg: 'RS256', kid: 'k1' })
    .setIssuer(WORKOS_ISSUER)
    .setSubject('user_01WORKOSSUBJECT')
    .setIssuedAt()
    .setExpirationTime('5m')
    .sign(privateKey);
}

async function run(authorization?: string) {
  const req: any = { headers: authorization ? { authorization } : {} };
  let status: number | null = null;
  let body: unknown = null;
  let admitted = false;
  const res: any = {
    status: (c: number) => {
      status = c;
      return res;
    },
    json: (b: unknown) => {
      body = b;
      return res;
    },
  };
  let authed = false;
  await requireAuth(req, res, () => {
    authed = true;
  });
  if (authed) {
    await requireStaff(req, res, () => {
      admitted = true;
    });
  }
  return { status, body, admitted, req };
}

describe('VQ requireStaff (database, not token)', () => {
  it('admits a WorkOS-signed staff user whose token has no app_metadata', async () => {
    const token = await workosToken({ role: 'authenticated', external_id: STAFF_ID });
    const out = await run(`Bearer ${token}`);
    expect(out.req.jwtPayload.app_metadata).toBeUndefined();
    expect(out.req.userId).toBe(STAFF_ID); // internal UUID, not the WorkOS sub
    expect(lookedUp).toBe(STAFF_ID);
    expect(out.admitted).toBe(true);
    expect(out.status).toBeNull();
  });

  it('403s a signed-in user who is not in admin_users', async () => {
    const token = await workosToken({ role: 'authenticated', external_id: NON_STAFF_ID });
    const out = await run(`Bearer ${token}`);
    expect(out.admitted).toBe(false);
    expect(out.status).toBe(403);
    expect(out.body).toEqual({ error: 'Staff access required' });
  });

  it('ignores a token that claims app_metadata.role=admin for a non-staff user', async () => {
    const token = await workosToken({
      role: 'authenticated',
      external_id: NON_STAFF_ID,
      app_metadata: { role: 'admin' },
    });
    const out = await run(`Bearer ${token}`);
    expect(out.admitted).toBe(false);
    expect(out.status).toBe(403);
  });

  it('401s a request with no token and never asks the database', async () => {
    const out = await run();
    expect(out.status).toBe(401);
    expect(out.admitted).toBe(false);
    expect(lookedUp).toBeNull();
  });

  it('503s (not 403) when the admin_users lookup fails', async () => {
    lookupError = { message: 'connection refused' };
    const token = await workosToken({ role: 'authenticated', external_id: STAFF_ID });
    const out = await run(`Bearer ${token}`);
    expect(out.admitted).toBe(false);
    expect(out.status).toBe(503);
  });

  it('admits a staff user called directly with a userId (Supabase path sets the same field)', async () => {
    const req: any = { userId: STAFF_ID, jwtPayload: { sub: STAFF_ID } };
    let admitted = false;
    const res: any = { status: () => res, json: () => res };
    await requireStaff(req, res, () => {
      admitted = true;
    });
    expect(admitted).toBe(true);
  });
});
