/**
 * Live-database detection for integration tests.
 *
 * vitest does not load `.env` — only `backend/src/index.ts` does, via
 * `import 'dotenv/config'`, as a side effect of importing the app. So a plain
 * `npm test` run has no DATABASE_URL, and tests that talk to a real database
 * either hang up on a nonexistent local server or fall back to whatever
 * placeholder the test set for itself.
 *
 * Tests that genuinely need a database gate on `hasLiveDb` and skip otherwise,
 * so the suite is green on a laptop with no database and still exercises the
 * real thing in CI:
 *
 *     DATABASE_URL=postgres://... npm test
 *
 * IMPORTANT — why this is a module and not an inline check. Several test files
 * assign a placeholder DATABASE_URL at module top-level, before importing the
 * app. ESM evaluates a module's static imports before the importing module's
 * body, so importing this file captures the pristine value from the real
 * environment, ahead of any placeholder the test installs for itself.
 */

const raw = process.env['DATABASE_URL'];

/** A real DATABASE_URL was supplied by the environment (not a test placeholder). */
export const hasLiveDb = !!raw && !raw.includes('postgres:password@localhost');

/** The pristine DATABASE_URL, captured before any test overwrote it. */
export const liveDbUrl = hasLiveDb ? raw : undefined;
