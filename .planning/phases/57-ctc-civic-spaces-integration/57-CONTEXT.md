# Phase 57: CTC + Civic Spaces Integration - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove that `GET /api/contributor/me` and `POST /api/roles/check` (built in Phase 53) correctly serve two external systems: CTC enforcing its `ctc_content_editor` content gate, and Civic Spaces verifying `volunteer` grants before privileged writes. No new accounts endpoints. Deliverables are integration tests, a smoke script, and a documentation update.

</domain>

<decisions>
## Implementation Decisions

### Test placement
- Integration tests go in the existing backend test suite (`backend/src/__tests__/`) alongside Phase 53 tests — same runner, same CI pipeline
- A separate standalone smoke script (`backend/scripts/smoke-phase57.ts`) for manual local validation
- CI integration tests run automatically (not opt-in/tagged)
- Smoke script targets configurable `BASE_URL` env var (defaults to localhost; override for prod)
- Smoke script is for dev/me running locally — console log pass/fail output

### Cache TTL handling
- Short TTL via `ROLE_CACHE_TTL_SECONDS` env var set in `.env.test` — no production code changes, no test-only escape hatches
- The grant → check → revoke → expire → check flow is covered in BOTH the integration test suite (using TTL=1s) and the smoke script
- Claude decides the reasonable TTL/wait duration for the smoke script

### Cross-team documentation
- Append a "Contributor Roles" section to `docs/INTEGRATION-GUIDE-v2.md` — no new file
- Depth: minimal — endpoint signature, request body shape, response shape. Just enough for a dev to integrate
- Cache behavior must be called out explicitly: results from `POST /api/roles/check` are cached; revoked grants may take up to TTL seconds to propagate

### Test fixture strategy
- Tests use setup/teardown via the existing `grant()` RPC — self-contained, no brittle seeded state
- Use a real `jurisdiction_geoid` from seeded data (not synthetic) for the `ctc_content_editor` grant test — proves full path including geoid validation
- Both jurisdiction-scoped AND NULL-scope `volunteer` grant cases covered in CI integration tests (criteria 2 and 3)
- Negative case included: user with NO volunteer grant → `POST /api/roles/check` returns `{ permitted: false }` — important security assertion

### Claude's Discretion
- Exact wait duration in smoke script for TTL expiry
- File name and structure of smoke script
- How to source the real geoid from seeded data in tests (query or hardcoded constant)

</decisions>

<specifics>
## Specific Ideas

- The grant → revoke → check flow in the smoke script should mirror what CTC/Civic Spaces devs would actually do in a real integration test — makes it useful as a reference implementation
- Cache behavior note in docs: frame it from the external dev's perspective ("your gate check may show permitted for up to X seconds after a grant is revoked")

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 57-ctc-civic-spaces-integration*
*Context gathered: 2026-04-03*
