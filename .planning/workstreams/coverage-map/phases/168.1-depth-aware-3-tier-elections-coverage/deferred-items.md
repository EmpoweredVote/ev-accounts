# Deferred Items — Phase 168.1

Out-of-scope pre-existing failures observed while running the full backend suite (`cd backend && npm test`) during plan 168.1-02 execution. None touch files modified by this plan (`electionsMapService.ts`, `electionsMap.ts`) — logged per the executor scope-boundary rule, not fixed.

- `tests/integration/architecture.test.ts` — pre-existing `supabaseAdmin` usage violations in `routes/admin.ts`, `routes/auth.ts`, `routes/campaignFinanceAdmin.ts`, `lib/essentialsLegislativeService.ts`.
- `tests/architecture/coordinateLeakage.test.ts` — pre-existing encrypted_lat column-reference matches in `connect.ts`/`essentials.ts`.
- `tests/integration/compass.test.ts` — 401-auth-enforcement assertions failing (unrelated to elections).
- `tests/integration/ctcCivicSpaces.test.ts`, `tests/integration/env-validation.test.ts`, `tests/integration/gems.test.ts`, `tests/integration/treasury-cities.test.ts` — pre-existing integration failures, unrelated domains.
- `src/lib/browseResolution.test.ts`, `test/arcgis-sources-coverage.test.ts`, `test/essentialsService-tribal-land.test.ts` — pre-existing failures, unrelated domains.
- Two TIGER-boundary integration test files (`state-city-assertions.test.ts`, `state-run-makevalid.test.ts`) trigger `process.exit(1)` from `scripts/load-state-tiger-boundaries.ts`, producing unhandled rejections in the suite run — pre-existing, unrelated to elections coverage.

All elections/admin-relevant suites pass: `electionsMap.test.ts` (28), `electionsMapService.test.ts` (2, new), `admin.test.ts` (4), `essentials-elections.test.ts` (9), `admin-compass.test.ts` (12).
