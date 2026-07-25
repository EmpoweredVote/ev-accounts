---
phase: 173-discovery-sweep-anthropic-cost-reliability-hardening
plan: 02
subsystem: infra
tags: [anthropic, claude, sdk, discovery-cron, cost-hardening, vitest, error-handling]

requires:
  - phase: 173-01
    provides: "checkAnthropicAvailability() canary helper + AnthropicAvailability union type"
provides:
  - "runDiscoverySweep aborts the sweep with exactly one operator alert and zero paid per-jurisdiction calls when Anthropic is conclusively unusable (missing key or 401/402/403 canary)"
  - "isRetryable(err) typed classifier (Anthropic.APIError .status discrimination) replacing the message-regex isTransient, exported alongside a testable withRetry"
  - "SWEEP_HORIZON_DAYS documented as a deliberate weekly-cadence/180-day cost choice (OPS-04)"
affects: [173-04]

tech-stack:
  added: []
  patterns:
    - "Sweep-level pre-flight gate: run a cheap, already-hardened canary exactly once before a batch loop of paid external-API calls, abort only on a conclusive negative signal"
    - "Typed Anthropic.APIError + .status discrimination instead of message-string regex for retry/non-retry classification"

key-files:
  created:
    - backend/src/lib/discoveryCron.test.ts
  modified:
    - backend/src/lib/discoveryCron.ts

key-decisions:
  - "isRetryable classifies other 4xx (400/404/422 etc.) as non-retryable, not just 401/402/403 — a retry on any 4xx fails identically, per RESEARCH Pattern 2"
  - "Only a returned {available:false} from checkAnthropicAvailability aborts the sweep; a thrown (inconclusive) canary error is logged and the sweep proceeds — prevents false-positive whole-sweep skips on transient 529/network blips (RESEARCH Pitfall 3)"
  - "availability.detail (already key-free by construction in 173-01) is the only thing logged or emailed on abort — env.ANTHROPIC_API_KEY is never referenced in discoveryCron.ts"

requirements-completed: [OPS-01, OPS-02, OPS-04]

coverage:
  - id: D1
    description: "runDiscoverySweep calls checkAnthropicAvailability() exactly once before the jurisdiction query; a missing key or 401/402/403 canary aborts the sweep (zero jurisdictions queried) and sends exactly one operator alert"
    requirement: OPS-01
    verification:
      - kind: unit
        ref: "backend/src/lib/discoveryCron.test.ts#missing key — sends sendEmail exactly once and never runs the jurisdiction pool.query"
        status: pass
      - kind: unit
        ref: "backend/src/lib/discoveryCron.test.ts#unusable credit — sends sendEmail exactly once, never runs the jurisdiction query, and never calls runDiscoveryForJurisdiction"
        status: pass
    human_judgment: false
  - id: D2
    description: "An inconclusive canary failure (thrown 529/network error) does NOT abort the sweep — it proceeds to the jurisdiction query and loop"
    requirement: OPS-01
    verification:
      - kind: unit
        ref: "backend/src/lib/discoveryCron.test.ts#inconclusive canary — proceeds (does run the jurisdiction pool.query)"
        status: pass
    human_judgment: false
  - id: D3
    description: "isRetryable returns false for Anthropic.APIError status 401/402/403 and other 4xx (400/404/422); true for 429 and status>=500; falls back to the network regex for non-APIError errors"
    requirement: OPS-02
    verification:
      - kind: unit
        ref: "backend/src/lib/discoveryCron.test.ts#non-retryable — isRetryable returns false for Anthropic.APIError status 401/402/403"
        status: pass
      - kind: unit
        ref: "backend/src/lib/discoveryCron.test.ts#non-retryable — isRetryable returns false for other 4xx (400/404/422)"
        status: pass
      - kind: unit
        ref: "backend/src/lib/discoveryCron.test.ts#retryable — isRetryable returns true for status 429/500/529"
        status: pass
      - kind: unit
        ref: "backend/src/lib/discoveryCron.test.ts#retryable — falls back to the network regex for non-APIError errors (ECONNRESET true, unrelated plain error false)"
        status: pass
    human_judgment: false
  - id: D4
    description: "withRetry calls its wrapped fn exactly once when the first attempt throws a 402 Anthropic.APIError — no retry multiplication"
    requirement: OPS-02
    verification:
      - kind: unit
        ref: "backend/src/lib/discoveryCron.test.ts#calls fn exactly once when the first attempt throws a 402 Anthropic.APIError, and rethrows"
        status: pass
    human_judgment: false
  - id: D5
    description: "SWEEP_HORIZON_DAYS carries a comment documenting the weekly-cadence/180-day-horizon as a deliberate cost choice"
    requirement: OPS-04
    verification: []
    human_judgment: true
    rationale: "Documentation-only deliverable (code comment); no automated test asserts comment presence/content, per 173-RESEARCH.md's Phase Requirements -> Test Map (OPS-04 is manual-only)."

duration: 2min
completed: 2026-07-23
status: complete
---

# Phase 173 Plan 2: Discovery Cron Sweep Hardening Summary

**`discoveryCron.ts`'s `runDiscoverySweep` now runs a single OPS-01 pre-flight canary before touching any jurisdiction (aborting cleanly with one alert on a conclusive missing-key/401/402/403 signal, proceeding on an inconclusive one), and its retry loop now classifies errors via a typed `isRetryable(err)` (Anthropic.APIError `.status` discrimination) instead of the old message-regex `isTransient`, guaranteeing 401/402/403 can never multiply spend through `withRetry`.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-07-23T07:30:00Z (approx.)
- **Completed:** 2026-07-23T07:32:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- New `backend/src/lib/discoveryCron.test.ts` (12 tests, all green): OPS-02 `isRetryable` classification (401/402/403 non-retryable including `it.each`, other 4xx non-retryable, 429/500/529 retryable via `it.each`, non-APIError network-regex fallback), OPS-02 `withRetry` does-not-multiply assertion on a 402 `Anthropic.APIError`, and OPS-01 sweep pre-flight (missing key aborts, unusable credit aborts, inconclusive 529 canary proceeds).
- `isTransient()` (message-regex) replaced by an exported `isRetryable(err: unknown): boolean`: `Anthropic.APIError` with `.status` 401/402/403 → `false`; `.status` 429 or `>=500` → `true`; any other 4xx → `false`; non-APIError errors fall back to the existing `ECONNRESET|ETIMEDOUT|ENOTFOUND|fetch failed` regex. `withRetry` now calls `isRetryable` and is itself exported for unit testing.
- `runDiscoverySweep` now imports `checkAnthropicAvailability` from `discoveryAgentRunner.js` (173-01) and runs it exactly once, inside the existing `try` block, before the horizon/jurisdiction query. A returned `{available:false}` logs `availability.detail` (never the raw key), sends exactly one `sendEmail` skip-alert (or a `console.warn` if `ADMIN_EMAIL` is unset), and returns — the existing `finally` still releases the run lock. A thrown (inconclusive) canary error is `console.warn`'d and the sweep proceeds normally.
- `SWEEP_HORIZON_DAYS = 180` now carries an OPS-04 comment documenting the weekly Sunday-02:00-UTC cadence + 180-day horizon as a deliberate, bounded-spend choice, cross-referencing the cron expression in `discoverySweep.ts`.

## Task Commits

Each task was committed atomically (TDD: test → feat → feat):

1. **Task 1: Author discoveryCron.test.ts (RED)** - `bbdc554e` (test)
2. **Task 2: OPS-02 — replace isTransient with typed isRetryable; export withRetry** - `c4a3c908` (feat)
3. **Task 3: OPS-01 preflight wiring + single skip-alert; OPS-04 horizon comment** - `045b8b34` (feat)

_Note: this plan's tasks were each individually `tdd="true"` (RED for Task 1, GREEN for Tasks 2 and 3) rather than one RED→GREEN pair per task — matching 173-01's precedent. No REFACTOR commit was needed._

## Files Created/Modified
- `backend/src/lib/discoveryCron.test.ts` - New Vitest suite (12 tests): OPS-02 `isRetryable` classification (6 tests incl. two `it.each` blocks) + `withRetry` does-not-multiply (1 test) + OPS-01 sweep pre-flight (3 tests: missing key, unusable credit, inconclusive canary). Mocks `@anthropic-ai/sdk` via the 173-01 `importOriginal`-spreading pattern (preserves real `APIError`), and mocks `./discoveryAgentRunner.js`, `./discoveryService.js`, `./emailService.js`, `./db.js`, `./env.js`.
- `backend/src/lib/discoveryCron.ts` - Added `import Anthropic from '@anthropic-ai/sdk'` and `import { checkAnthropicAvailability } from './discoveryAgentRunner.js'`; replaced `isTransient` with exported `isRetryable`; exported `withRetry`; wired the OPS-01 preflight gate + single skip-alert into `runDiscoverySweep`; added the OPS-04 cost-rationale comment above `SWEEP_HORIZON_DAYS`.

## Decisions Made
- `isRetryable` treats every non-{401,402,403,429,5xx} status (400/404/409/422/etc.) as non-retryable, not just the three account-level codes — matches RESEARCH Pattern 2's explicit guidance that other 4xx are "not transient — a retry will fail identically."
- Preflight abort is gated strictly on a *returned* `{available:false}` result, never on a *thrown* error from `checkAnthropicAvailability()` — a `try/catch` around the canary call distinguishes "conclusively unusable" (returned) from "inconclusive" (thrown), matching 173-01's contract and RESEARCH Pitfall 3 exactly.
- No changes to `discoveryDashboard.ts` (manual trigger route) — out of scope per RESEARCH Pitfall 4, consistent with 173-01's decision.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

Plan-level tasks were individually `tdd="true"` rather than the whole plan being a single `type: tdd` RED→GREEN→REFACTOR cycle (frontmatter is `type: execute`). For traceability: a `test(...)` commit (`bbdc554e`) precedes both `feat(...)` commits (`c4a3c908`, `045b8b34`) in git log, satisfying RED-before-GREEN ordering informally. All 12 tests in `discoveryCron.test.ts` are green as of the final commit; `npx tsc --noEmit` is clean.

## Issues Encountered

None. `discoveryCron.test.ts` ran RED as expected after Task 1 (11/12 failures — `isRetryable is not a function` / `withRetry is not a function`), went to 10/12 green after Task 2, and fully green (12/12) after Task 3. Cross-checked against the full related suite (`discoveryCron.test.ts` + `discoveryAgentRunner.test.ts` + `discoveryService.test.ts`, 22 tests) — all green, confirming no regression against 173-01's or 173-03's work.

## User Setup Required

None - no external service configuration required. (`ANTHROPIC_API_KEY` and `ADMIN_EMAIL` are existing, already-configured Render env vars this plan reads but does not manage.)

## Next Phase Readiness

- OPS-01/OPS-02/OPS-04 are fully wired and tested in `discoveryCron.ts`; the sweep orchestrator now cannot flood 144x credit-exhaustion or 45x missing-key failures, and non-retryable Anthropic errors can never multiply spend via `withRetry`.
- No blockers for 173-04 (or any subsequent phase). `discoveryDashboard.ts` (manual trigger) remains explicitly out of scope, consistent with both 173-01 and this plan's RESEARCH-cited Pitfall 4.

---
*Phase: 173-discovery-sweep-anthropic-cost-reliability-hardening*
*Completed: 2026-07-23*

## Self-Check: PASSED

All created/modified files and all recorded commit hashes were verified present on disk and in git log (see below).
