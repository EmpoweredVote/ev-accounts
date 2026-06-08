/**
 * smoke-la-representatives-me.ts
 * Phase 108: LA County City Officials — Integration Smoke Test
 *
 * Exercises GET /api/essentials/representatives/me for a known LA-area test user
 * and confirms that newly-seeded Phase 108 officials (external_id BETWEEN -700699 AND -700001)
 * appear in the response.
 *
 * Usage:
 *   API_BASE_URL=https://api.empowered.vote \
 *   SMOKE_TEST_BEARER_TOKEN=<connected-tier-jwt> \
 *   npx tsx backend/scripts/smoke-la-representatives-me.ts
 *
 * Environment variables:
 *   API_BASE_URL           — API base URL (default: http://localhost:3001)
 *   SMOKE_TEST_BEARER_TOKEN — JWT for a Connected-tier test user at an LA-area address
 *                             (Chris's UUID 4e6dde8f-2bd0-4054-824f-4164744165ea or any
 *                             LA-area Connected user with district data cached)
 *
 * This script is READ-ONLY. It makes only GET requests and performs no DB writes.
 *
 * Exit codes:
 *   0 — smoke test passed (Phase 108 politicians found in response)
 *   1 — smoke test failed (see error output for details)
 */

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const API_BASE_URL = (process.env['API_BASE_URL'] ?? 'http://localhost:3001').replace(/\/$/, '');
const SMOKE_TEST_BEARER_TOKEN = process.env['SMOKE_TEST_BEARER_TOKEN'] ?? '';

// Phase 108 external_id range for LA County city officials
const PHASE108_MIN = -700699;
const PHASE108_MAX = -700001;

const TIMEOUT_MS = 15_000;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface Politician {
  id?: string;
  full_name?: string;
  first_name?: string;
  last_name?: string;
  external_id?: number;
  office_title?: string;
  photo_origin_url?: string;
  [key: string]: unknown;
}

interface CheckResult {
  pass: boolean;
  detail: string;
  skipped?: boolean;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Fetch with AbortController timeout. Throws on network error or timeout.
 * Note: Bearer token is read from env only; never logged.
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
 * Determine if an external_id falls in the Phase 108 range.
 * Range: -700699 <= external_id <= -700001
 */
function isPhase108Politician(extId: unknown): boolean {
  if (typeof extId !== 'number') return false;
  return extId >= PHASE108_MIN && extId <= PHASE108_MAX;
}

/**
 * Redact authorization header for safe logging.
 */
function redactToken(token: string): string {
  if (token.length <= 10) return '***';
  return token.slice(0, 8) + '...' + token.slice(-4);
}

// ---------------------------------------------------------------------------
// Checks
// ---------------------------------------------------------------------------

/**
 * Step A-D: call GET /api/essentials/representatives/me and parse response.
 */
async function checkRepresentativesMe(): Promise<CheckResult> {
  if (!SMOKE_TEST_BEARER_TOKEN) {
    return {
      pass: false,
      detail: 'SMOKE_TEST_BEARER_TOKEN is not set. Cannot call authenticated endpoint.',
    };
  }

  const url = `${API_BASE_URL}/api/essentials/representatives/me`;
  let res: Response;

  try {
    res = await fetchWithTimeout(url, {
      method: 'GET',
      headers: {
        // Token is sent in Authorization header but never logged
        Authorization: `Bearer ${SMOKE_TEST_BEARER_TOKEN}`,
        'Content-Type': 'application/json',
      },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return {
      pass: false,
      detail: `Network error calling ${url}: ${message}`,
    };
  }

  // Step C: Assert 200
  if (res.status !== 200) {
    let body = '';
    try {
      body = await res.text();
    } catch {
      // ignore
    }
    return {
      pass: false,
      detail: `Expected 200, got ${res.status}. Body: ${body.slice(0, 200)}`,
    };
  }

  let data: unknown;
  try {
    data = await res.json();
  } catch {
    return {
      pass: false,
      detail: 'Response is not valid JSON',
    };
  }

  // Normalize: response may be array or object with politicians array
  let politicians: Politician[] = [];
  if (Array.isArray(data)) {
    politicians = data as Politician[];
  } else if (
    data !== null &&
    typeof data === 'object' &&
    'politicians' in data &&
    Array.isArray((data as Record<string, unknown>)['politicians'])
  ) {
    politicians = (data as Record<string, unknown>)['politicians'] as Politician[];
  } else if (
    data !== null &&
    typeof data === 'object' &&
    'data' in data &&
    Array.isArray((data as Record<string, unknown>)['data'])
  ) {
    politicians = (data as Record<string, unknown>)['data'] as Politician[];
  } else {
    return {
      pass: false,
      detail: `Unexpected response shape: ${JSON.stringify(data).slice(0, 200)}`,
    };
  }

  const totalCount = politicians.length;

  // Step D: Assert at least one Phase 108 politician
  const phase108Politicians = politicians.filter((p) => isPhase108Politician(p.external_id));
  const phase108Count = phase108Politicians.length;

  // Step E: Print summary table
  console.log(`\n  --- Response Summary ---`);
  console.log(`  Total politicians returned: ${totalCount}`);
  console.log(`  Phase 108 politicians (external_id -700699..-700001): ${phase108Count}`);

  if (phase108Count > 0) {
    console.log(`\n  Phase 108 politicians found:`);
    for (const p of phase108Politicians) {
      const name = p.full_name ?? `${p.first_name ?? ''} ${p.last_name ?? ''}`.trim();
      const title = p.office_title ?? '(no title)';
      console.log(`    - ${name} [external_id=${p.external_id}] — ${title}`);
    }
  }

  if (totalCount > 0 && phase108Count === 0) {
    // Non-zero politicians returned but none from Phase 108
    console.log(`\n  All ${totalCount} politicians returned (external_ids):`);
    for (const p of politicians) {
      const name = p.full_name ?? `${p.first_name ?? ''} ${p.last_name ?? ''}`.trim();
      console.log(`    - ${name} [external_id=${p.external_id ?? 'null'}]`);
    }
    return {
      pass: false,
      detail:
        `${totalCount} politicians returned but NONE have external_id between ${PHASE108_MIN} and ${PHASE108_MAX}. ` +
        `The test user's district may not intersect any Phase 108 city. ` +
        `Verify the test user has an LA-area address cached in user_districts (e.g., a Long Beach or West Hollywood address). ` +
        `This is NOT a Phase 108 data error if the user is not in an LA County city covered by Phase 108.`,
    };
  }

  if (totalCount === 0) {
    return {
      pass: false,
      detail:
        `representatives/me returned 0 politicians. ` +
        `The test user may not have district data cached (run cache_user_districts first), ` +
        `or the server may be unreachable at ${API_BASE_URL}.`,
    };
  }

  return {
    pass: true,
    detail: `${phase108Count} Phase 108 politician(s) returned out of ${totalCount} total.`,
  };
}

// ---------------------------------------------------------------------------
// Runner
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log('Phase 108 Smoke Test — LA County Representatives-Me Integration');
  console.log('================================================================');
  console.log(`API base URL: ${API_BASE_URL}`);

  if (SMOKE_TEST_BEARER_TOKEN) {
    console.log(`Bearer token: ${redactToken(SMOKE_TEST_BEARER_TOKEN)}`);
  } else {
    console.error('\nError: SMOKE_TEST_BEARER_TOKEN is not set.\n');
    console.error('Usage:');
    console.error('  API_BASE_URL=https://api.empowered.vote \\');
    console.error('  SMOKE_TEST_BEARER_TOKEN=<connected-tier-jwt> \\');
    console.error('  npx tsx backend/scripts/smoke-la-representatives-me.ts\n');
    console.error('The token must be for a Connected-tier user with an LA-area address cached.');
    process.exit(1);
  }

  console.log(`\nPhase 108 range: external_id BETWEEN ${PHASE108_MIN} AND ${PHASE108_MAX}`);
  console.log(`Endpoint: GET ${API_BASE_URL}/api/essentials/representatives/me\n`);

  let result: CheckResult;
  try {
    result = await checkRepresentativesMe();
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`\nUnhandled error: ${message}`);
    process.exit(1);
  }

  console.log('');
  if (result.pass) {
    console.log(`[PASS] ${result.detail}`);
    console.log('\nSmoke test PASSED. Phase 108 officials are surfacing for this LA-area user.');
    process.exit(0);
  } else {
    console.log(`[FAIL] ${result.detail}`);
    console.log('\nSmoke test FAILED. See detail above.');
    process.exit(1);
  }
}

main();
