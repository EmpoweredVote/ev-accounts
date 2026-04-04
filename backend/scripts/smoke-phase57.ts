/**
 * smoke-phase57.ts — Phase 57 smoke test: CTC + Civic Spaces Integration.
 *
 * Validates the Contributor Roles lifecycle: grant -> check -> revoke -> expire -> check.
 * The grant/revoke lifecycle is gated on SMOKE_ADMIN_TOKEN. Static endpoint checks
 * always run with the provided SMOKE_TOKEN.
 *
 * Usage:
 *   SMOKE_TOKEN=<jwt> npx tsx backend/scripts/smoke-phase57.ts
 *   BASE_URL=https://api.empowered.vote SMOKE_TOKEN=<jwt> npx tsx backend/scripts/smoke-phase57.ts
 *
 *   Optional: SMOKE_ADMIN_TOKEN=<admin-jwt> to enable grant/revoke lifecycle test
 *   Note: Server must have ROLE_CACHE_TTL_SECONDS=3 for the lifecycle test to complete in ~4s
 *
 * Exits 0 if all non-skip checks pass. Exits 1 if any check fails.
 */

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface CheckResult {
  pass: boolean;
  detail: string;
  skipped?: boolean;
}

interface Grant {
  role_slug: string;
  feature_scope: string;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const BASE_URL = (process.env['BASE_URL'] ?? 'http://localhost:3000').replace(/\/$/, '');
const TIMEOUT_MS = 10_000;

const SMOKE_TOKEN = process.env['SMOKE_TOKEN'];
const SMOKE_ADMIN_TOKEN = process.env['SMOKE_ADMIN_TOKEN'];

if (!SMOKE_TOKEN) {
  console.error('Error: SMOKE_TOKEN is required.\n');
  console.error('Usage:');
  console.error('  SMOKE_TOKEN=<jwt> npx tsx backend/scripts/smoke-phase57.ts');
  console.error('  BASE_URL=https://api.empowered.vote SMOKE_TOKEN=<jwt> npx tsx backend/scripts/smoke-phase57.ts\n');
  console.error('Optional: SMOKE_ADMIN_TOKEN=<admin-jwt> to enable grant/revoke lifecycle test');
  console.error('Note: Server must have ROLE_CACHE_TTL_SECONDS=3 for the lifecycle test');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Fetch with an AbortController timeout. Throws on network error or timeout.
 */
async function fetchWithTimeout(url: string, options?: RequestInit): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Authenticated fetch — applies Bearer token and JSON content-type.
 */
async function fetchAuth(
  path: string,
  method: 'GET' | 'POST',
  body?: Record<string, unknown>,
  token: string = SMOKE_TOKEN!
): Promise<Response> {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
  return fetchWithTimeout(`${BASE_URL}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
}

/**
 * Sleep for the given number of milliseconds.
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------------------
// Checks
// ---------------------------------------------------------------------------

async function checkContributorMe(): Promise<CheckResult> {
  const res = await fetchAuth('/api/contributor/me', 'GET');

  if (res.status !== 200) {
    return { pass: false, detail: `Expected 200, got ${res.status}` };
  }

  const body: unknown = await res.json();
  if (!Array.isArray(body)) {
    return { pass: false, detail: `Expected array, got ${typeof body}` };
  }

  const grants = body as Grant[];
  console.log(`  Grants (${grants.length}):`, JSON.stringify(grants, null, 2));

  return { pass: true, detail: `GET /api/contributor/me → 200 array(${grants.length})` };
}

async function checkRolesCheckVolunteer(): Promise<CheckResult> {
  const res = await fetchAuth('/api/roles/check', 'POST', {
    feature_scope: 'volunteer',
    jurisdiction_geoid: '18105',
  });

  if (res.status !== 200) {
    return { pass: false, detail: `Expected 200, got ${res.status}` };
  }

  const body = (await res.json()) as Record<string, unknown>;
  if (typeof body['permitted'] !== 'boolean') {
    return { pass: false, detail: `Expected { permitted: boolean }, got ${JSON.stringify(body)}` };
  }

  console.log(`  Result: { permitted: ${String(body['permitted'])} }`);
  return {
    pass: true,
    detail: `POST /api/roles/check { feature_scope: "volunteer" } → { permitted: ${String(body['permitted'])} }`,
  };
}

async function checkRolesCheckNonexistent(): Promise<CheckResult> {
  const res = await fetchAuth('/api/roles/check', 'POST', {
    feature_scope: 'nonexistent_role_slug_smoke_test',
  });

  if (res.status !== 200) {
    return { pass: false, detail: `Expected 200, got ${res.status}` };
  }

  const body = (await res.json()) as Record<string, unknown>;
  if (body['permitted'] !== false) {
    return {
      pass: false,
      detail: `Expected { permitted: false } for nonexistent role, got { permitted: ${String(body['permitted'])} }`,
    };
  }

  return { pass: true, detail: `POST /api/roles/check nonexistent role → { permitted: false }` };
}

async function checkCacheTtlLifecycle(): Promise<CheckResult> {
  if (!SMOKE_ADMIN_TOKEN) {
    return {
      pass: true,
      skipped: true,
      detail: 'Cache TTL lifecycle — set SMOKE_ADMIN_TOKEN to enable',
    };
  }

  // Step 1: Grant volunteer role via admin endpoint
  console.log('  [lifecycle] Granting volunteer role via admin...');
  const grantRes = await fetchAuth(
    '/api/admin/roles/grant',
    'POST',
    { role_slug: 'volunteer' },
    SMOKE_ADMIN_TOKEN
  );
  if (grantRes.status !== 200 && grantRes.status !== 201) {
    return {
      pass: false,
      detail: `Admin grant failed: ${grantRes.status} ${await grantRes.text()}`,
    };
  }

  // Step 2: Confirm permitted: true
  console.log('  [lifecycle] Checking permitted after grant...');
  const checkAfterGrant = await fetchAuth('/api/roles/check', 'POST', {
    feature_scope: 'volunteer',
  });
  const afterGrantBody = (await checkAfterGrant.json()) as Record<string, unknown>;
  if (afterGrantBody['permitted'] !== true) {
    return {
      pass: false,
      detail: `Expected permitted: true after grant, got ${JSON.stringify(afterGrantBody)}`,
    };
  }

  // Step 3: Revoke volunteer role
  console.log('  [lifecycle] Revoking volunteer role via admin...');
  const revokeRes = await fetchAuth(
    '/api/admin/roles/revoke',
    'POST',
    { role_slug: 'volunteer' },
    SMOKE_ADMIN_TOKEN
  );
  if (revokeRes.status !== 200 && revokeRes.status !== 204) {
    return {
      pass: false,
      detail: `Admin revoke failed: ${revokeRes.status} ${await revokeRes.text()}`,
    };
  }

  // Step 4: Immediately check — may still be cached
  const checkImmediate = await fetchAuth('/api/roles/check', 'POST', {
    feature_scope: 'volunteer',
  });
  const immediateBody = (await checkImmediate.json()) as Record<string, unknown>;
  console.log(
    `  [lifecycle] Immediate check after revoke: { permitted: ${String(immediateBody['permitted'])} } (cache may still be warm)`
  );

  // Step 5: Wait for TTL expiry (ROLE_CACHE_TTL_SECONDS=3 + 1s buffer = 4s)
  console.log('  [lifecycle] Waiting 4 seconds for cache TTL expiry...');
  await sleep(4_000);

  // Step 6: Final check — must be false
  const checkAfterTtl = await fetchAuth('/api/roles/check', 'POST', {
    feature_scope: 'volunteer',
  });
  const afterTtlBody = (await checkAfterTtl.json()) as Record<string, unknown>;
  console.log(
    `  [lifecycle] Check after TTL expiry: { permitted: ${String(afterTtlBody['permitted'])} }`
  );

  if (afterTtlBody['permitted'] !== false) {
    return {
      pass: false,
      detail: `Expected permitted: false after TTL expiry, got ${JSON.stringify(afterTtlBody)}. Is ROLE_CACHE_TTL_SECONDS=3 set on the server?`,
    };
  }

  return {
    pass: true,
    detail: 'Cache TTL lifecycle: grant → permitted:true → revoke → cache warm → TTL expired → permitted:false',
  };
}

// ---------------------------------------------------------------------------
// Runner
// ---------------------------------------------------------------------------

interface NamedCheck {
  label: string;
  run: () => Promise<CheckResult>;
}

async function main(): Promise<void> {
  console.log('Phase 57 Smoke Test — CTC + Civic Spaces Integration');
  console.log('=====================================================');
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Token: ${SMOKE_TOKEN.slice(0, 20)}...`);
  if (SMOKE_ADMIN_TOKEN) {
    console.log(`Admin token: ${SMOKE_ADMIN_TOKEN.slice(0, 20)}...`);
  }
  console.log('');

  const checks: NamedCheck[] = [
    {
      label: 'GET /api/contributor/me returns grant array',
      run: checkContributorMe,
    },
    {
      label: 'POST /api/roles/check returns valid response',
      run: checkRolesCheckVolunteer,
    },
    {
      label: 'POST /api/roles/check rejects nonexistent role',
      run: checkRolesCheckNonexistent,
    },
    {
      label: 'Cache TTL lifecycle (grant → check → revoke → expire → check)',
      run: checkCacheTtlLifecycle,
    },
  ];

  let passed = 0;
  let failed = 0;
  let skipped = 0;

  for (const check of checks) {
    let result: CheckResult;

    try {
      result = await check.run();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      result = { pass: false, detail: `Network error: ${message}` };
    }

    if (result.skipped === true) {
      console.log(`[SKIP] ${result.detail}`);
      skipped++;
    } else if (result.pass) {
      console.log(`[PASS] ${check.label}: ${result.detail}`);
      passed++;
    } else {
      console.log(`[FAIL] ${check.label}: ${result.detail}`);
      failed++;
    }
  }

  const total = passed + failed;
  console.log(`\nResults: ${passed}/${total} passed, ${failed} failed, ${skipped} skipped`);

  if (failed > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}

main();
