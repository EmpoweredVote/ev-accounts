---
phase: "05"
plan: "02"
name: "empower-service-and-routes"
subsystem: "empower"
tags: ["empower", "preflight", "slug-reservation", "consent", "rpc", "demotion", "integration-tests"]

dependency-graph:
  requires:
    - "05-01: empower schema (consent_records, demoted_at, demotion_reason, candidate_role, updated RPCs)"
    - "04-02: getCompassCompleteness in compassService"
    - "01-02: architecture constraint (supabaseAdmin banned from routes/)"
    - "03-01: tierGuards.requireConnected middleware"
  provides:
    - "empowerService.ts: preflight, slug reservation, consent recording, RPC wrappers"
    - "routes/empower.ts: POST /preflight, POST /confirm, POST /demote"
    - "empowerRouter mounted at /api/empower"
    - "empower.test.ts: CI-safe 401 enforcement + architecture constraint test"
  affects:
    - "05-03: verification of full lifecycle (if applicable)"
    - "06: any feature requiring empowered tier"
    - "07: admin demotion trigger, cron demotion via executeDemotion"

tech-stack:
  added: []
  patterns:
    - "Service layer (empowerService.ts) wraps all admin RPC calls — routes stay clean"
    - "Cache-backed slug reservation: 1-hour TTL, cleared on confirm"
    - "All-failures-before-return preflight pattern (no early return on first failure)"
    - "PREFLIGHT_EXPIRED as typed Error with .code property for catch-block discrimination"

key-files:
  created:
    - "backend/src/lib/empowerService.ts"
    - "backend/src/routes/empower.ts"
    - "tests/integration/empower.test.ts"
  modified:
    - "backend/src/index.ts"

decisions:
  - id: "05-02-01"
    decision: "Preflight returns 200 for ineligible users (not 4xx) — preflight itself succeeded in reporting failures"
    rationale: "Client needs to distinguish 'preflight ran and found failures' from 'preflight couldn't run at all'"
  - id: "05-02-02"
    decision: "PREFLIGHT_EXPIRED thrown as Error with .code = 'PREFLIGHT_EXPIRED' on err object"
    rationale: "Allows catch block to discriminate by checking err.message OR (err as ErrnoException).code without creating a custom error class"
  - id: "05-02-03"
    decision: "DemoteSchema uses .optional() on reason object — empty body {} parses cleanly"
    rationale: "Demotion can be triggered by cron (no user body) or admin (structured reason); both paths must work"
  - id: "05-02-04"
    decision: "compassCompleteness checked only when candidate_role is not null — avoids false CALIBRATION_INCOMPLETE when role is unset"
    rationale: "ROLE_NOT_SET already in failures; reporting CALIBRATION_INCOMPLETE with undefined role scope would be misleading"

metrics:
  duration: "~4 minutes"
  completed: "2026-02-27"
  tasks: 2
  commits: 2
---

# Phase 5 Plan 02: Empower Service and Routes Summary

**Empower service layer (preflight, slug reservation, consent, RPC wrappers) and three empower endpoints behind requireAuth + requireConnected, with CI-safe integration tests**

## Accomplishments

- Created `backend/src/lib/empowerService.ts` with 6 exported functions:
  - `runPreflight`: collects ALL empowerment failures (NOT_VERIFIED, ROLE_NOT_SET, LEGAL_NAME_MISSING, CALIBRATION_INCOMPLETE) before returning — no early exit on first failure; includes demotion context for demoted users; preserves original slug for re-empowerment
  - `reserveSlug`: generates slug from legal name (lowercase + alphanumeric hyphenation + 4-char UUID suffix) and caches with 1-hour TTL
  - `getReservedSlug`: retrieves cached slug or null if expired
  - `recordConsent`: inserts into `empower.consent_records` via pg pool
  - `confirmEmpowerment`: validates slug reservation exists (throws PREFLIGHT_EXPIRED), calls `execute_empowerment` RPC, records consent, clears cache
  - `executeDemotion`: calls `execute_demotion` RPC with optional demotion reason

- Created `backend/src/routes/empower.ts` with three endpoints:
  - `POST /api/empower/preflight` — returns 200 with either `{ eligible: false, failures }` or `{ eligible: true, summary }` (never 4xx for ineligible)
  - `POST /api/empower/confirm` — validates z.literal(true) for all 3 consent items (422 on partial), calls confirmEmpowerment (409 PREFLIGHT_EXPIRED if slug expired, 201 on success)
  - `POST /api/empower/demote` — optional reason body (DemoteSchema), calls executeDemotion, returns 200

- Updated `backend/src/index.ts` to mount `empowerRouter` at `/api/empower` after compassRouter

- Created `tests/integration/empower.test.ts` with:
  - 4 CI-safe tests: 3x 401 auth enforcement + 1x architecture check (routes/empower.ts contains no `supabaseAdmin`)
  - 10 skipped Supabase-dependent tests covering full lifecycle, demotion atomicity, re-empowerment slug restore, and consent rollback

## Key Decisions Made

- Preflight returns 200 for ineligible users — not 4xx — because the endpoint itself succeeded in evaluating all conditions (see 05-02-01)
- PREFLIGHT_EXPIRED uses `.code` on the Error object rather than a custom class, keeping discrimination simple in the catch block (see 05-02-02)
- DemoteSchema reason is fully optional so cron-triggered demotion (no body) and admin-triggered demotion (structured body) both work without separate schemas (see 05-02-03)
- CALIBRATION_INCOMPLETE only checked when candidate_role is not null to avoid misleading error when ROLE_NOT_SET is already reported (see 05-02-04)

## Files Created/Modified

| File | Action | Purpose |
|------|--------|---------|
| `backend/src/lib/empowerService.ts` | Created | Service layer: preflight, slug, consent, RPCs |
| `backend/src/routes/empower.ts` | Created | POST /preflight, /confirm, /demote routes |
| `backend/src/index.ts` | Modified | Mount empowerRouter at /api/empower |
| `tests/integration/empower.test.ts` | Created | CI-safe + skipped integration tests |

## Verification Results

- `npx vitest run --run empower`: 4 passed, 10 skipped
- `npx vitest run --run architecture`: 2 passed (empowerService.ts in allowedFiles, routes/empower.ts clean)
- `routes/empower.ts` contains no `supabaseAdmin` string
- `backend/src/index.ts` mounts `empowerRouter` at `/api/empower`

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

- Phase 5 is now complete (both plans done)
- Phase 6 (Gems, Roles, and Social Graph) can begin
- Phase 7 reminder: add compass admin routes deferred from Phase 4 (topics/create, topics/update, stances/update, compass/politicians/context, PUT /compass/politicians/:id/answers, GET /essentials/politicians)
