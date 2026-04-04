# Phase 57: CTC + Civic Spaces Integration - Research

**Researched:** 2026-04-03
**Domain:** Integration testing, smoke scripting, documentation — for existing endpoints GET /api/contributor/me and POST /api/roles/check
**Confidence:** HIGH

## Summary

Phase 57 is a verification and documentation phase, not a feature phase. Both endpoints (`GET /api/contributor/me` and `POST /api/roles/check`) are live and correct per Phase 53. The work is: (1) write integration tests in `tests/integration/` that exercise the two endpoints against mocked roleService behavior, (2) write a standalone smoke script at `backend/scripts/smoke-phase57.ts` that proves the grant → check → revoke → expire → check lifecycle, and (3) append a "Contributor Roles" section to `docs/INTEGRATION-GUIDE-v2.md`.

The test pattern is fully established by Phases 53, 55, 56, and revocation.test.ts. Pure-function tests use dynamic import in `beforeAll`. HTTP-level tests use `supertest` against the imported `app`, with `process.env` set at the top of the file before any imports, and a `SUPABASE_JWT_SECRET` env var to activate the HS256 test path (avoiding JWKS network calls). The smoke script follows the pattern of `backend/scripts/smokeTest.ts`: `fetchWithTimeout`, console `[PASS]/[FAIL]` output, `process.exit(0|1)`.

The critical implementation detail: `getCachedUserRoles` currently hardcodes TTL=90s. The CONTEXT requires `ROLE_CACHE_TTL_SECONDS` env var support so tests can set TTL=1s and observe cache expiry without sleeping 90 seconds. This requires a one-line change to `roleService.ts` — reading `parseInt(process.env['ROLE_CACHE_TTL_SECONDS'] ?? '90', 10)` in place of the literal `90`. This is the only production code change in Phase 57.

**Primary recommendation:** Make `ROLE_CACHE_TTL_SECONDS` env var control TTL in `roleService.ts`, set it to `1` in test env setup, then test the full revoke → wait → check flow with a 1.5s sleep in the integration test (and a similar wait in the smoke script).

## Standard Stack

No new libraries. All tools are already in the project.

### Core (already in place)
| Tool | Version | Purpose | Why Used |
|------|---------|---------|----------|
| `vitest` | ^2.1.0 | Test runner | Project standard — `npm test` in backend/ |
| `supertest` | ^7.0.0 | HTTP integration tests against Express app | Project standard |
| `jose` | ^5.9.0 | Sign test JWTs for HS256 auth path | Established in revocation.test.ts |
| TypeScript strict | ^5.6.0 | Smoke script and test typing | Project standard |
| `tsx` | (dev dep) | Run smoke script: `npx tsx backend/scripts/smoke-phase57.ts` | Project standard for scripts |

**No new npm installs required.**

## Architecture Patterns

### Recommended File Structure
```
tests/integration/
└── ctcCivicSpaces.test.ts     # NEW — integration tests for Phase 57

backend/src/lib/
└── roleService.ts              # MODIFIED — ROLE_CACHE_TTL_SECONDS env var for TTL

backend/scripts/
└── smoke-phase57.ts            # NEW — standalone smoke script

docs/
└── INTEGRATION-GUIDE-v2.md    # MODIFIED — append "Contributor Roles" section
```

### Pattern 1: HTTP Integration Test with HS256 JWT

Established in `tests/integration/revocation.test.ts`. Required because `POST /api/roles/check` and `GET /api/contributor/me` both call `requireAuth`, which uses JWKS by default. Setting `SUPABASE_JWT_SECRET` before import activates the HS256 code path, making auth work in tests without network.

```typescript
// Source: tests/integration/revocation.test.ts
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-role-key';
process.env['DATABASE_URL'] = 'postgresql://postgres:password@localhost:5432/postgres';
process.env['SUPABASE_JWT_SECRET'] = 'test-secret-32-chars-minimum-for-hs256';
process.env['ROLE_CACHE_TTL_SECONDS'] = '1';  // Phase 57 addition
process.env['ADMIN_INGEST_TOKEN'] = 'test-ingest-token';

import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { SignJWT } from 'jose';
import type { Express } from 'express';

let app: Express;
beforeAll(async () => {
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});
```

### Pattern 2: Signing Test JWT

```typescript
// Source: tests/integration/revocation.test.ts
const TEST_JWT_SECRET = 'test-secret-32-chars-minimum-for-hs256';
const TEST_USER_ID = '00000000-0000-0000-0000-000000000001';

async function signTestJwt(): Promise<string> {
  const secretKey = new TextEncoder().encode(TEST_JWT_SECRET);
  return new SignJWT({ sub: TEST_USER_ID, role: 'authenticated' })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt(Math.floor(Date.now() / 1000) - 1)
    .setIssuer('https://test.supabase.co/auth/v1')
    .setAudience('authenticated')
    .setExpirationTime('1h')
    .sign(secretKey);
}
```

### Pattern 3: Smoke Script Structure

```typescript
// Source: backend/scripts/smokeTest.ts
const BASE_URL = (process.env['BASE_URL'] ?? 'http://localhost:3000').replace(/\/$/, '');

interface CheckResult { pass: boolean; detail: string; skipped?: boolean; }
interface Check { name: string; run: () => Promise<CheckResult>; }

async function fetchWithTimeout(url: string, options?: RequestInit): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 10_000);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}
```

The existing `smokeTest.ts` uses `SMOKE_TEST_URL`. Phase 57's smoke script uses `BASE_URL` (per CONTEXT). Keep the naming distinct so both scripts can coexist without confusion.

### Pattern 4: ROLE_CACHE_TTL_SECONDS in roleService.ts

The only production code change. Replace the hardcoded `90` with an env-driven value:

```typescript
// In getCachedUserRoles(), replace:
await cache.set(key, grants, 90);

// With:
const ttl = parseInt(process.env['ROLE_CACHE_TTL_SECONDS'] ?? '90', 10);
await cache.set(key, grants, ttl);
```

This is safe — `parseInt` with a default of `'90'` is identical to current behavior when the env var is absent. Tests set it to `'1'` via `process.env` before import.

### Pattern 5: Mocking getCachedUserRoles in Integration Tests

The two endpoints under test both call `getCachedUserRoles(userId)`. In tests, this call hits `getUserRoles` (the DB function via `adminRpc`), which will fail against the test Supabase URL. The approach: use `vi.mock` to mock `roleService` at the module level, or configure `getCachedUserRoles` to return controlled grants.

The established pattern in this codebase is NOT to use `vi.mock` — instead, tests intercept at the behavior level (e.g., revocation.test.ts lets `signOutUser` fail silently and tests the side effect). For the role endpoints, the cleanest approach is to mock `getCachedUserRoles` via `vi.mock('../../backend/src/lib/roleService.js', ...)` so the test controls what grants the endpoint sees.

Alternatively (and simpler): since tests run with the in-memory cache, the test can directly populate the cache by calling `cache.set('roles:uid:{TEST_USER_ID}', [...grants], 10)` before making the HTTP request. This bypasses the mock pattern entirely and respects the real code path.

**Recommendation: Use cache pre-population** (`cache.set` with the known cache key) rather than `vi.mock`. This tests the real endpoint code path, including the cache hit logic. The cache key is `roles:uid:{userId}` — visible in `roleService.ts` line 106.

```typescript
// Source: backend/src/lib/roleService.ts (line 106)
const key = `roles:uid:${userId}`;

// In test setup:
import { cache } from '../../backend/src/lib/cache.js';
const TEST_GRANTS = [{ id: 'g1', role_id: 'r1', slug: 'ctc_content_editor', ... }];
await cache.set(`roles:uid:${TEST_USER_ID}`, TEST_GRANTS, 5);
```

This works in tests because there are no Upstash env vars set, so `cache` is the `InMemoryFallback`. After TTL expiry, `cache.get` returns `null`, then `getUserRoles` (DB) is called and fails — which is fine for the negative/expiry case if the test expects the endpoint to return `{ permitted: false }` after revocation (the revoked state should be an empty grants array in cache, not an error).

**Revised approach for the revoke → expire → check flow:**
1. Pre-populate cache with `[volunteer grant]` → check returns `{ permitted: true }` (cache hit)
2. Overwrite cache with `[]` (empty array, TTL=1s) to simulate revocation + cache invalidation
3. Sleep 1.5s
4. Make check request → cache is expired, `getUserRoles` is called → fails against test DB → endpoint returns 500 OR we need to ensure `getUserRoles` returns `[]` in the revoked state

This is the key complexity: after the in-memory cache expires, the test endpoint calls `getUserRoles` which calls `adminRpc('get_user_roles', ...)` against `https://test.supabase.co` — this will fail with a network/auth error, causing a 500 response, not `{ permitted: false }`.

**Resolution:** The correct approach is `vi.mock` for `roleService` to control `getCachedUserRoles` return values deterministically. This is the right pattern for HTTP-level integration tests when the underlying DB is unavailable.

```typescript
// vi.mock approach — controls what getCachedUserRoles returns per test
import { vi } from 'vitest';

vi.mock('../../backend/src/lib/roleService.js', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../../backend/src/lib/roleService.js')>();
  return {
    ...actual,
    getCachedUserRoles: vi.fn(),
  };
});
```

Then in each test: `vi.mocked(getCachedUserRoles).mockResolvedValueOnce([...grants])`.

For the **cache TTL / revoke → expire flow** specifically: this is better validated in the smoke script (which runs against a real server with real DB and Redis) than in the integration test suite. The integration test proves the endpoint logic; the smoke script proves the cache lifecycle.

### Anti-Patterns to Avoid
- **Don't sleep 90 seconds in integration tests** — TTL must be configurable, and 1s is enough.
- **Don't use `adminRpc` or `pool.query` in test files** — production code only. Tests control behavior via mock or cache pre-population.
- **Don't import `cache` from `roleService.ts`** — `cache` is not exported from `roleService`. Import it directly from `cache.ts` if pre-populating.
- **Don't call `grantRole`/`revokeRole` RPCs in integration tests** — these hit production Supabase. Use `vi.mock` to control `getCachedUserRoles` return values.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP integration test JWT | Custom JWT library | `SignJWT` from `jose` (already in project) | Established pattern |
| HTTP assertions | Raw fetch | `supertest` request(app) chain | Established pattern |
| Cache expiry simulation | Sleep 90s | Set `ROLE_CACHE_TTL_SECONDS=1` env var + sleep 1.5s | Only works if roleService reads env var |
| Mock role grants | Real DB grant/revoke | `vi.mock` + `mockResolvedValueOnce` | No test Supabase available |

## Common Pitfalls

### Pitfall 1: JWKS Network Call in Tests
**What goes wrong:** Tests fail with 401 because `requireAuth` tries to fetch JWKS from `https://test.supabase.co/auth/v1/.well-known/jwks.json`.
**Why it happens:** `SUPABASE_JWT_SECRET` must be set BEFORE any import of the app. The auth middleware reads it at module evaluation time.
**How to avoid:** Set `process.env['SUPABASE_JWT_SECRET']` at the top of the test file, before any `import` statements. Use dynamic `await import('../../backend/src/index.js')` in `beforeAll`.
**Warning signs:** Tests return 401 with no body or network timeout, not the expected response.

### Pitfall 2: Cache Pre-Population Race with DB Fallback
**What goes wrong:** After cache expiry, `getCachedUserRoles` falls back to `getUserRoles` which calls `adminRpc` against the test Supabase URL, returning 500 instead of the expected `{ permitted: false }`.
**Why it happens:** The in-memory cache expires and the DB fallback is unavailable in test environment.
**How to avoid:** Use `vi.mock` to control `getCachedUserRoles` return values directly. Don't rely on cache expiry in integration tests — use the mock to return `[]` for the "after revocation" case.
**Warning signs:** Tests that worked when cache was warm suddenly fail with 500 after a sleep.

### Pitfall 3: vi.mock Hoisting
**What goes wrong:** `vi.mock` hoisting moves the mock declaration above `process.env` assignments, so env setup hasn't run when the mocked module initializes.
**Why it happens:** Vitest hoists `vi.mock` calls to the top of the file (like Jest).
**How to avoid:** The env vars (`SUPABASE_URL`, etc.) must still be set before the mock runs. Use `vi.mock` with a factory function that uses `importOriginal` (async). Keep the `process.env` assignments at the absolute top of the file.

### Pitfall 4: Hardcoded TTL in roleService.ts
**What goes wrong:** Integration test sets `ROLE_CACHE_TTL_SECONDS=1` but the cache still uses 90s TTL because `roleService.ts` doesn't read the env var.
**Why it happens:** Current code hardcodes `await cache.set(key, grants, 90)`.
**How to avoid:** This is the planned code change for Phase 57 — modify `roleService.ts` to read `parseInt(process.env['ROLE_CACHE_TTL_SECONDS'] ?? '90', 10)`.
**Warning signs:** TTL test cases always time out or the sleep doesn't cause cache miss.

### Pitfall 5: Smoke Script Using Wrong Env Var Name
**What goes wrong:** Smoke script uses `SMOKE_TEST_URL` (matching existing `smokeTest.ts`) instead of `BASE_URL` (per CONTEXT decision).
**Why it happens:** Copying from existing smoke script without adjusting.
**How to avoid:** CONTEXT specifies `BASE_URL`. Keep the two scripts' env vars distinct.

### Pitfall 6: Real geoid for ctc_content_editor grant
**What goes wrong:** The `ctc_content_editor` grant test uses a synthetic geoid that doesn't exist in seeded data, so the grant fails validation in the RPC.
**Why it happens:** `grant_role` RPC may or may not validate that `jurisdiction_geoid` exists in the locations table.
**How to avoid:** Per CONTEXT, use a real `jurisdiction_geoid` from seeded data. Since the test uses `vi.mock` for `getCachedUserRoles` (no actual grant RPC call), the geoid only needs to be real in the smoke script. In the smoke script, query `SELECT geo_id FROM essentials.districts LIMIT 1` to get a real geoid, or use a known-good value from the existing test suite (`'06037'` is used extensively in compassContributor tests — confirms it's in seeded data).

## Code Examples

### GET /api/contributor/me — Test Structure
```typescript
// Source: backend/src/routes/contributor.ts
// Response shape: [{ role_slug, feature_scope, jurisdiction_geoid, resource_id }]

it('returns ctc_content_editor grant with jurisdiction_geoid', async () => {
  vi.mocked(getCachedUserRoles).mockResolvedValueOnce([{
    id: 'g1',
    role_id: 'r1',
    slug: 'ctc_content_editor',
    name: 'CTC Content Editor',
    granted_at: '2026-01-01',
    feature_scope: 'platform',
    jurisdiction_geoid: '06037',
    resource_id: null,
  }]);

  const token = await signTestJwt();
  const res = await request(app)
    .get('/api/contributor/me')
    .set('Authorization', `Bearer ${token}`);

  expect(res.status).toBe(200);
  expect(Array.isArray(res.body)).toBe(true);
  const grant = res.body[0];
  expect(grant.role_slug).toBe('ctc_content_editor');
  expect(grant.jurisdiction_geoid).toBe('06037');
});
```

### POST /api/roles/check — Test Structure
```typescript
// Source: backend/src/routes/roles.ts
// Request: { feature_scope: string, jurisdiction_geoid?: string }
// Response: { permitted: boolean }

it('returns permitted:true for user with matching volunteer grant', async () => {
  vi.mocked(getCachedUserRoles).mockResolvedValueOnce([{
    id: 'g2', role_id: 'r2', slug: 'volunteer',
    name: 'Volunteer', granted_at: '2026-01-01',
    feature_scope: 'platform', jurisdiction_geoid: '18105', resource_id: null,
  }]);

  const token = await signTestJwt();
  const res = await request(app)
    .post('/api/roles/check')
    .set('Authorization', `Bearer ${token}`)
    .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });

  expect(res.status).toBe(200);
  expect(res.body.permitted).toBe(true);
});

it('returns permitted:false for user with volunteer grant for different jurisdiction', async () => {
  vi.mocked(getCachedUserRoles).mockResolvedValueOnce([{
    id: 'g3', role_id: 'r2', slug: 'volunteer',
    name: 'Volunteer', granted_at: '2026-01-01',
    feature_scope: 'platform', jurisdiction_geoid: '06037', resource_id: null,
  }]);

  const token = await signTestJwt();
  const res = await request(app)
    .post('/api/roles/check')
    .set('Authorization', `Bearer ${token}`)
    .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });

  expect(res.status).toBe(200);
  expect(res.body.permitted).toBe(false);
});

it('returns permitted:true for NULL-scope volunteer grant (unrestricted)', async () => {
  vi.mocked(getCachedUserRoles).mockResolvedValueOnce([{
    id: 'g4', role_id: 'r2', slug: 'volunteer',
    name: 'Volunteer', granted_at: '2026-01-01',
    feature_scope: 'platform', jurisdiction_geoid: null, resource_id: null,
  }]);

  const res = await request(app)
    .post('/api/roles/check')
    .set('Authorization', `Bearer ${await signTestJwt()}`)
    .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });

  expect(res.status).toBe(200);
  expect(res.body.permitted).toBe(true);
});

it('returns permitted:false for user with NO volunteer grant (negative security case)', async () => {
  vi.mocked(getCachedUserRoles).mockResolvedValueOnce([]);  // No grants

  const res = await request(app)
    .post('/api/roles/check')
    .set('Authorization', `Bearer ${await signTestJwt()}`)
    .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });

  expect(res.status).toBe(200);
  expect(res.body.permitted).toBe(false);
});
```

### Cache TTL Flow — Mock Approach for Integration Tests
```typescript
// This tests the logic without relying on actual cache TTL expiry.
// Cache TTL behavior is validated in the smoke script instead.

it('reflects revoked state when cache returns empty grants', async () => {
  const token = await signTestJwt();

  // Before revocation: grants present → permitted
  vi.mocked(getCachedUserRoles).mockResolvedValueOnce([
    { id: 'g5', role_id: 'r2', slug: 'volunteer', ..., jurisdiction_geoid: null }
  ]);
  const beforeRes = await request(app)
    .post('/api/roles/check')
    .set('Authorization', `Bearer ${token}`)
    .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });
  expect(beforeRes.body.permitted).toBe(true);

  // After revocation: empty grants → not permitted
  vi.mocked(getCachedUserRoles).mockResolvedValueOnce([]);
  const afterRes = await request(app)
    .post('/api/roles/check')
    .set('Authorization', `Bearer ${token}`)
    .send({ feature_scope: 'volunteer', jurisdiction_geoid: '18105' });
  expect(afterRes.body.permitted).toBe(false);
});
```

### Smoke Script — Recommended TTL Wait Duration
The smoke script runs against a real server. The decision: use 3 seconds wait after revocation + cache invalidation, with production cache TTL at 90s. The smoke script should call `POST /api/admin/roles/revoke` (or equivalent) and then wait for `ROLE_CACHE_TTL_SECONDS` + buffer. Since the smoke script is for local dev use with a configurable `BASE_URL`, the developer sets a short TTL or the smoke script documents that it requires the server to be running with `ROLE_CACHE_TTL_SECONDS=3`. The smoke script should log this precondition clearly.

**Recommended approach:** Set a 3s TTL and wait 4s in the smoke script. Document in the script header that the server must be started with `ROLE_CACHE_TTL_SECONDS=3` for the TTL test to complete in reasonable time. If the env var is not set, the script skips the TTL check with a `[SKIP]` note.

### INTEGRATION-GUIDE-v2.md — "Contributor Roles" Section

Append after section 8.13 (or as 8.13a / 8.14, renumbering if needed). Content:

```markdown
### 8.14 Contributor Roles (`/api/contributor`, `/api/roles/check`)

Used by CTC and Civic Spaces to verify feature access without accounts writing to external systems.

| Method | Path | Auth | Body | Description |
|--------|------|------|------|-------------|
| `GET` | `/api/contributor/me` | Auth | — | Returns caller's active role grants as array. |
| `POST` | `/api/roles/check` | Auth | `{ feature_scope, jurisdiction_geoid? }` | Returns `{ permitted: boolean }`. |

**GET /api/contributor/me response shape:**
```json
[
  {
    "role_slug": "ctc_content_editor",
    "feature_scope": "platform",
    "jurisdiction_geoid": "06037",
    "resource_id": null
  }
]
```

**POST /api/roles/check request/response:**
```json
// Request
{ "feature_scope": "volunteer", "jurisdiction_geoid": "18105" }

// Response
{ "permitted": true }
```

**Cache behavior:** Results from `POST /api/roles/check` are cached. A grant that has been revoked may still return `{ "permitted": true }` for up to 90 seconds after revocation. Design your gate accordingly — for low-stakes gates this is acceptable; for high-stakes operations, call the endpoint close to the time of the privileged action rather than caching the result on your side.

**NULL-scope grants:** A grant with `jurisdiction_geoid: null` is unrestricted — it passes any jurisdiction check. If your system grants a user a NULL-scope `volunteer` role, `POST /api/roles/check` returns `{ "permitted": true }` for any `jurisdiction_geoid` value.
```

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Hardcoded TTL=90 in roleService.ts | `ROLE_CACHE_TTL_SECONDS` env var (Phase 57 change) | Allows TTL=1 in tests |
| No CTC/Civic Spaces integration documented | "Contributor Roles" section in INTEGRATION-GUIDE-v2.md | External teams can self-serve |

## Open Questions

1. **Real geoid in smoke script**
   - What we know: `'06037'` (LA County FIPS) is used in multiple existing tests, likely seeded
   - What's unclear: Whether `grant_role` RPC validates that `jurisdiction_geoid` exists in a locations table, or accepts any string
   - Recommendation: In the smoke script, use `'06037'` or query `SELECT geo_id FROM essentials.districts LIMIT 1`. In integration tests (using `vi.mock`), the geoid value is arbitrary since no RPC is called.

2. **Admin route for grant/revoke in smoke script**
   - What we know: `POST /api/admin/roles/grant` and `POST /api/admin/roles/revoke` exist (seen in INTEGRATION-GUIDE-v2.md lines 702-703). The smoke script needs admin credentials.
   - What's unclear: Whether the smoke script should require admin credentials or call the grant/revoke RPCs directly via a service key pattern.
   - Recommendation: The smoke script is for dev/me use locally. Use `supabaseAdmin`-level calls directly (via `tsx` running with service role key env vars set), not through the HTTP API. This avoids requiring admin session management in the script. Alternatively, call `POST /api/admin/roles/grant` with admin Bearer token if that's simpler.

3. **Section numbering in INTEGRATION-GUIDE-v2.md**
   - What we know: Current section 8.14 is "Referral", 8.13 is "Roles". The new section covers contributor + roles/check.
   - What's unclear: Whether to renumber sections or insert as 8.13a or add after existing 8.13.
   - Recommendation: Insert as a new section after 8.13 (Roles), renumber downstream sections (8.14 Referral becomes 8.15, etc.). The guide is a living document — renumbering is cleaner than gaps.

## Sources

### Primary (HIGH confidence)
- `backend/src/routes/contributor.ts` — exact endpoint implementation, response shape
- `backend/src/routes/roles.ts` — exact POST /api/roles/check implementation
- `backend/src/lib/roleService.ts` — getCachedUserRoles, checkRole, TTL hardcode at line 118
- `backend/src/lib/cache.ts` — InMemoryFallback TTL expiry behavior
- `tests/integration/revocation.test.ts` — canonical HTTP test pattern with HS256 JWT
- `tests/integration/requireRole.test.ts` — pure function test pattern, UserRoleGrant type
- `backend/scripts/smokeTest.ts` — canonical smoke script structure

### Secondary (MEDIUM confidence)
- `backend/migrations/047_role_scope_migration.sql` — confirms `ctc_content_editor` and `volunteer` slugs seeded
- `tests/integration/compassContributor.test.ts` — confirms `'06037'` geoid is used in established tests

### Tertiary (LOW confidence)
- Whether `grant_role` RPC validates `jurisdiction_geoid` against a reference table — not confirmed from migrations read

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries, all patterns are established
- Architecture (test patterns): HIGH — direct code inspection of working test files
- Smoke script structure: HIGH — direct code inspection of existing smokeTest.ts
- Pitfalls: HIGH — identified from actual code paths (JWKS, DB fallback, vi.mock hoisting)
- Real geoid validation behavior: LOW — not confirmed from RPC implementation

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (stable domain — no external libraries changing)
