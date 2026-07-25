// IMPORTANT: Env vars must be set before any imports that read process.env.
// The auth middleware reads SUPABASE_JWT_SECRET at module evaluation time to
// decide between HS256 and JWKS. If set after import, the middleware will have
// already chosen the JWKS path and the test JWT will not verify.
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-role-key';
process.env['DATABASE_URL'] = 'postgresql://postgres:password@localhost:5432/postgres';
process.env['ADMIN_INGEST_TOKEN'] = 'test-ingest-token';
// Activates the HS256 path in auth.ts — without this, requireAuth uses JWKS
// (network call to test.supabase.co which fails and returns 401 for wrong reason).
process.env['SUPABASE_JWT_SECRET'] = 'test-secret-32-chars-minimum-for-hs256';
// Short TTL so cache lifecycle tests can observe expiry quickly.
process.env['ROLE_CACHE_TTL_SECONDS'] = '1';

import { describe, it, expect, beforeAll, beforeEach } from 'vitest';
import request from 'supertest';
import { SignJWT } from 'jose';
import type { Express } from 'express';
import type { UserRoleGrant } from '../../backend/src/lib/roleService.js';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const TEST_JWT_SECRET = 'test-secret-32-chars-minimum-for-hs256';
const TEST_USER_ID = '00000000-0000-0000-0000-000000000001';
const CACHE_KEY = `roles:uid:${TEST_USER_ID}`;

// ---------------------------------------------------------------------------
// JWT helper
// ---------------------------------------------------------------------------

async function signTestJwt(): Promise<string> {
  const secretKey = new TextEncoder().encode(TEST_JWT_SECRET);
  return new SignJWT({
    sub: TEST_USER_ID,
    role: 'authenticated',
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt(Math.floor(Date.now() / 1000) - 1)
    .setIssuer('https://test.supabase.co/auth/v1')
    .setAudience('authenticated')
    .setExpirationTime('1h')
    .sign(secretKey);
}

// ---------------------------------------------------------------------------
// Grant factory — builds UserRoleGrant test objects
// ---------------------------------------------------------------------------

function grant(
  slug: string,
  geoid: string | null = null,
  resourceId: string | null = null
): UserRoleGrant {
  return {
    id: 'test-grant-id',
    role_id: 'r1',
    slug,
    name: slug,
    granted_at: '2026-01-01',
    feature_scope: 'platform',
    jurisdiction_geoid: geoid,
    resource_id: resourceId,
  };
}

// ---------------------------------------------------------------------------
// App and cache — dynamic imports so env vars above are set before evaluation
// ---------------------------------------------------------------------------

let app: Express;
let cache: import('../../backend/src/lib/cache.js').CacheClient;

beforeAll(async () => {
  const [appMod, cacheMod] = await Promise.all([
    import('../../backend/src/index.js'),
    import('../../backend/src/lib/cache.js'),
  ]);
  app = appMod.app;
  cache = cacheMod.cache;
});

// Clear the role cache entry before each test so one test's grants don't bleed
// into the next. The in-memory cache (InMemoryFallback) is used in tests since
// no REDIS_URL is set.
beforeEach(async () => {
  await cache.del(CACHE_KEY);
});

// ---------------------------------------------------------------------------
// describe: GET /api/contributor/me — CTC integration
//
// CTC calls this endpoint to learn which roles (and jurisdictions) the
// authenticated user holds. ctc_content_editor with a jurisdiction_geoid
// tells CTC which district's content the user may edit.
//
// We pre-populate the in-memory cache with controlled grants so the endpoint
// returns a predictable response without a live DB connection.
// ---------------------------------------------------------------------------

describe('GET /api/contributor/me — contributor dashboard feed', () => {
  // GET /api/contributor/me is the Contributor *dashboard* feed. d9a4a55c
  // ("filter contributor dashboard to 3 role types only") narrowed it to
  // compass_stance_editor / campaign_manager / essentials_data_editor, so it is
  // not a general "which roles do I hold" endpoint. GET /api/roles/me is — it
  // returns every active grant unfiltered, and that is where a consumer needing
  // ctc_content_editor should read from.
  //
  // These two tests pin both halves of that filter so neither side drifts silently.
  it('returns a contributor-dashboard grant with its jurisdiction_geoid', async () => {
    await cache.set(CACHE_KEY, [grant('compass_stance_editor', '06037')], 10);

    const token = await signTestJwt();
    const res = await request(app)
      .get('/api/contributor/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          role_slug: 'compass_stance_editor',
          jurisdiction_geoid: '06037',
        }),
      ])
    );
  });

  it('filters out non-contributor grants such as ctc_content_editor', async () => {
    await cache.set(
      CACHE_KEY,
      [grant('ctc_content_editor', '06037'), grant('campaign_manager', '06037')],
      10
    );

    const token = await signTestJwt();
    const res = await request(app)
      .get('/api/contributor/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.map((g: { role_slug: string }) => g.role_slug)).toEqual(['campaign_manager']);
  });

  it('returns empty array when user has no grants', async () => {
    await cache.set(CACHE_KEY, [], 10);

    const token = await signTestJwt();
    const res = await request(app)
      .get('/api/contributor/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it('returns 401 without auth token', async () => {
    const res = await request(app).get('/api/contributor/me');
    expect(res.status).toBe(401);
  });
});

// ---------------------------------------------------------------------------
// describe: POST /api/roles/check — Civic Spaces integration
//
// Civic Spaces calls this endpoint to gate access to jurisdiction-scoped
// features (e.g. volunteer coordination). NULL-scope grants are unrestricted
// and must pass any jurisdiction check.
// ---------------------------------------------------------------------------

describe('POST /api/roles/check — Civic Spaces integration', () => {
  it('returns permitted:true for exact volunteer jurisdiction match', async () => {
    await cache.set(CACHE_KEY, [grant('volunteer', '18105')], 10);

    const token = await signTestJwt();
    const res = await request(app)
      .post('/api/roles/check')
      .set('Authorization', `Bearer ${token}`)
      .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ permitted: true });
  });

  it('returns permitted:false for wrong jurisdiction', async () => {
    await cache.set(CACHE_KEY, [grant('volunteer', '06037')], 10);

    const token = await signTestJwt();
    const res = await request(app)
      .post('/api/roles/check')
      .set('Authorization', `Bearer ${token}`)
      .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ permitted: false });
  });

  it('returns permitted:true for NULL-scope volunteer (unrestricted)', async () => {
    // NULL jurisdiction_geoid on a grant means unrestricted — passes any
    // jurisdiction check per checkRole NULL-safe semantics.
    await cache.set(CACHE_KEY, [grant('volunteer', null)], 10);

    const token = await signTestJwt();
    const res = await request(app)
      .post('/api/roles/check')
      .set('Authorization', `Bearer ${token}`)
      .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ permitted: true });
  });

  it('returns permitted:false when user has no volunteer grant', async () => {
    await cache.set(CACHE_KEY, [], 10);

    const token = await signTestJwt();
    const res = await request(app)
      .post('/api/roles/check')
      .set('Authorization', `Bearer ${token}`)
      .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ permitted: false });
  });

  it('returns 400 when feature_scope missing', async () => {
    const token = await signTestJwt();
    const res = await request(app)
      .post('/api/roles/check')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(400);
  });

  it('returns 401 without auth token', async () => {
    const res = await request(app)
      .post('/api/roles/check')
      .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });

    expect(res.status).toBe(401);
  });
});

// ---------------------------------------------------------------------------
// describe: Cache TTL lifecycle — revocation reflected after expiry
//
// Proves that /api/roles/check correctly surfaces the underlying grant state
// across successive calls. In production, after a grant is revoked and the
// cache TTL expires, the next call refreshes from DB — returning no grant.
//
// We model that lifecycle using the in-memory cache:
// 1. Populate cache with active grant → permitted:true
// 2. Overwrite cache with [] to simulate revocation + cache invalidation
// 3. permitted:false on next check
//
// ROLE_CACHE_TTL_SECONDS=1 means the cache expires in 1 second if not
// overwritten, but we overwrite it directly here to avoid any sleep.
// ---------------------------------------------------------------------------

describe('Cache TTL lifecycle — revocation reflected after expiry', () => {
  it('endpoint reflects post-revocation state when cache returns empty', async () => {
    const token = await signTestJwt();

    // Step 1: User has an active grant — cache warm with volunteer grant.
    await cache.set(CACHE_KEY, [grant('volunteer', null)], 10);

    const firstRes = await request(app)
      .post('/api/roles/check')
      .set('Authorization', `Bearer ${token}`)
      .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });

    expect(firstRes.status).toBe(200);
    expect(firstRes.body).toEqual({ permitted: true });

    // Step 2: Grant was revoked. In production, invalidateRoleCache() clears the
    // cache entry after revocation, then the next cache set uses the DB result
    // (no grant). We simulate this by overwriting the cache with an empty array.
    // No sleep needed because we're controlling the cache state directly.
    // In production, this is what happens when a grant is revoked and the cache
    // TTL expires — the cache refreshes from the DB and finds no grant.
    await cache.set(CACHE_KEY, [], 10);

    const secondRes = await request(app)
      .post('/api/roles/check')
      .set('Authorization', `Bearer ${token}`)
      .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });

    expect(secondRes.status).toBe(200);
    expect(secondRes.body).toEqual({ permitted: false });
  });
});
