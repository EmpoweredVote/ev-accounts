/**
 * smokeTest.ts — Production smoke test suite for Empowered Accounts API.
 *
 * Exercises 5 critical checks to confirm the live environment is functional.
 * Run this as the go/no-go gate before announcing Alpha access.
 *
 * Usage:
 *   npx tsx backend/scripts/smokeTest.ts
 *   SMOKE_TEST_URL=https://<domain> npx tsx backend/scripts/smokeTest.ts
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

interface Check {
  name: string;
  run: () => Promise<CheckResult>;
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const BASE_URL = (process.env['SMOKE_TEST_URL'] ?? 'http://localhost:3000').replace(/\/$/, '');
const TIMEOUT_MS = 10_000;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Fetch with a 10-second AbortController timeout. Throws on network error.
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

// ---------------------------------------------------------------------------
// Checks
// ---------------------------------------------------------------------------

const checks: Check[] = [
  // -------------------------------------------------------------------------
  // Check 1: Health
  // -------------------------------------------------------------------------
  {
    name: 'Health',
    async run(): Promise<CheckResult> {
      const url = `${BASE_URL}/api/health`;
      const res = await fetchWithTimeout(url);

      if (res.status !== 200) {
        return { pass: false, detail: `Expected 200 with {status:'ok'}, got ${res.status}` };
      }

      const body = (await res.json()) as Record<string, unknown>;
      if (body['status'] !== 'ok') {
        return { pass: false, detail: `Expected {status:'ok'}, got status:'${String(body['status'])}'` };
      }

      return { pass: true, detail: `GET /api/health → 200 {status:'ok'}` };
    },
  },

  // -------------------------------------------------------------------------
  // Check 2: Auth reachability
  // Passes on 401 (Supabase correctly rejected bad credentials).
  // 500 means auth is unreachable. 200 would be catastrophic.
  // -------------------------------------------------------------------------
  {
    name: 'Auth reachability',
    async run(): Promise<CheckResult> {
      const url = `${BASE_URL}/api/auth/login`;
      const res = await fetchWithTimeout(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'smoke-test@invalid.example',
          password: 'not-a-real-password',
        }),
      });

      if (res.status !== 401) {
        const note = res.status === 500 ? ' (500 means auth is unreachable)' : res.status === 200 ? ' (200 would be catastrophic)' : '';
        return { pass: false, detail: `Expected 401 (auth reachable), got ${res.status}${note}` };
      }

      return { pass: true, detail: `POST /api/auth/login → 401 (Supabase auth reachable)` };
    },
  },

  // -------------------------------------------------------------------------
  // Check 3: Compass topics
  // -------------------------------------------------------------------------
  {
    name: 'Compass topics',
    async run(): Promise<CheckResult> {
      const url = `${BASE_URL}/api/compass/topics`;
      const res = await fetchWithTimeout(url);

      if (res.status !== 200) {
        return { pass: false, detail: `Expected 200 with JSON array, got ${res.status}` };
      }

      const body: unknown = await res.json();
      if (!Array.isArray(body)) {
        return { pass: false, detail: `Expected array, got ${typeof body}` };
      }

      return { pass: true, detail: `GET /api/compass/topics → 200 array(${body.length})` };
    },
  },

  // -------------------------------------------------------------------------
  // Check 4: Essentials politicians
  // A successful response proves migration 026 was applied — the endpoint
  // queries the `is_candidate` column added in 026_inform_schema_repair_and_candidates.sql.
  // If migration 026 is missing, this endpoint returns 500 (column not found).
  // -------------------------------------------------------------------------
  {
    name: 'Essentials politicians',
    async run(): Promise<CheckResult> {
      const url = `${BASE_URL}/api/essentials/politicians`;
      const res = await fetchWithTimeout(url);

      if (res.status !== 200) {
        return { pass: false, detail: `Expected 200 with JSON array, got ${res.status}` };
      }

      const body: unknown = await res.json();
      if (!Array.isArray(body)) {
        return { pass: false, detail: `Expected array, got ${typeof body}` };
      }

      return { pass: true, detail: `GET /api/essentials/politicians → 200 array(${body.length})` };
    },
  },

  // -------------------------------------------------------------------------
  // Check 5: Admin UI — skipped in programmatic run, human-only verification
  // -------------------------------------------------------------------------
  {
    name: 'Admin UI',
    async run(): Promise<CheckResult> {
      return {
        pass: true,
        skipped: true,
        detail: `Verify manually: admin UI loads at ${BASE_URL.replace('/api', '')} with no JS errors`,
      };
    },
  },
];

// ---------------------------------------------------------------------------
// Runner
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log(`Smoke testing: ${BASE_URL}\n`);

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
      console.log(`[SKIP] ${check.name}: ${result.detail}`);
      skipped++;
    } else if (result.pass) {
      console.log(`[PASS] ${check.name}: ${result.detail}`);
      passed++;
    } else {
      console.log(`[FAIL] ${check.name}: ${result.detail}`);
      failed++;
    }
  }

  const total = passed + failed;
  console.log(`\nResults: ${passed}/${total} passed (${skipped} skipped)`);

  if (failed > 0) {
    console.log('SMOKE TEST FAILED');
    process.exit(1);
  } else {
    console.log('SMOKE TEST PASSED');
    process.exit(0);
  }
}

main();
