# Phase 173 — Deferred Items (out-of-scope test failures)

Recorded during 173-04 Task 1 (full-suite gate), 2026-07-23.

`cd backend && npm test` reports **21 failed / 862 passed / 4 skipped** across 9 test files.
None of the 21 failures are in files touched by Phase 173
(`discoveryCron.ts`, `discoveryAgentRunner.ts`, `discoverySweep.ts`, or their new
`*.test.ts` files — all 3 new/updated discovery test files are 100% green, 22/22 tests).

Diff scope confirms Phase 173 only modified:
- `backend/src/cron/discoverySweep.ts`
- `backend/src/lib/discoveryAgentRunner.ts` (+ `discoveryAgentRunner.test.ts`)
- `backend/src/lib/discoveryCron.ts` (+ `discoveryCron.test.ts`)
- `backend/src/lib/discoveryService.test.ts` (new, no source change)

The 21 failures are pre-existing and environmental — this sandbox has no live
Supabase/Postgres connection and is missing some env vars, which is the root
cause visible directly in the failure output:

| File | Root cause (from failure output) |
|------|-----------------------------------|
| `tests/architecture/coordinateLeakage.test.ts` (4 failures) | Static source-grep architecture test, unrelated to discovery code |
| `tests/integration/architecture.test.ts` (2 failures) | Static source-grep dual-client architecture test, unrelated to discovery code |
| `tests/integration/compass.test.ts` (5 failures) | Expects 401 without auth; environment/auth wiring difference in this sandbox |
| `tests/integration/ctcCivicSpaces.test.ts` (1 failure) | CTC grant fixture/env dependency |
| `tests/integration/env-validation.test.ts` (2 failures) | `process.exit` called — env var validation depends on vars not set in this shell |
| `tests/integration/gems.test.ts` (2 failures) | Expected 422, got 401 — auth/env wiring difference in this sandbox |
| `tests/integration/treasury-cities.test.ts` (3 failures) | 500 instead of 200 — requires live DB |
| `test/arcgis-sources-coverage.test.ts` (1 failure) | **`error: password authentication failed for user "Chris"`** — requires a live Postgres connection not available in this sandbox |
| `test/essentialsService-tribal-land.test.ts` (1 failure) | `process.exit` called — env var validation dependency, same root cause as env-validation.test.ts |

**Disposition:** Out of scope per the executor's Scope Boundary rule (only auto-fix issues
directly caused by the current task's changes). Not fixed. `npx tsc --noEmit` is clean
(0 errors). All three OPS-01/02/03 test files plus the 8 named VALIDATION `-t` behaviors
pass. Operator should re-run `npm test` in an environment with a live DB connection and
full env vars configured to confirm these are indeed pre-existing (not introduced by this
phase) before further action.
