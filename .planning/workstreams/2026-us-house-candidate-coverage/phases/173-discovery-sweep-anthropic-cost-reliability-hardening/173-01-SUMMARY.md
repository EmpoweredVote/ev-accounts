---
phase: 173-discovery-sweep-anthropic-cost-reliability-hardening
plan: 01
subsystem: infra
tags: [anthropic, claude, sdk, discovery-agent, cron-hardening, vitest, error-handling]

requires: []
provides:
  - "runDiscoveryAgent returns a zero-candidate DiscoveryAgentResult (never throws) on any model turn that ends without invoking report_candidates"
  - "checkAnthropicAvailability() exported one-shot canary helper + AnthropicAvailability union type for 173-02's sweep pre-flight"
affects: [173-02, 173-03]

tech-stack:
  added: []
  patterns:
    - "Typed Anthropic.APIError + .status discrimination instead of message-string regex for account-level (401/402/403) vs. transient/inconclusive canary failures"
    - "Benign no-result loop exit (console.warn + return zero-result) instead of throw, for agentic tool-use loops where 'model didn't call the reporting tool' is an expected outcome"

key-files:
  created:
    - backend/src/lib/discoveryAgentRunner.test.ts
  modified:
    - backend/src/lib/discoveryAgentRunner.ts

key-decisions:
  - "Canary uses claude-haiku-4-5 (cheapest model) per RESEARCH Open Question 2 — 401/402/403 are account-level signals, not model-level, so the cheapest model answers the same question"
  - "Only APIError status 401/402/403 classify as unusable; every other canary failure (429/5xx/network/non-APIError) is re-thrown as inconclusive so 173-02's caller can log-and-proceed rather than false-positive-skip the whole sweep"

requirements-completed: [OPS-01, OPS-03]

coverage:
  - id: D1
    description: "runDiscoveryAgent returns {candidates: [], stopReason} instead of throwing when a model turn ends (end_turn or any non-pause_turn/non-report_candidates stop_reason) without invoking report_candidates, including after a pause_turn→end_turn sequence"
    requirement: OPS-03
    verification:
      - kind: unit
        ref: "backend/src/lib/discoveryAgentRunner.test.ts#end_turn without report_candidates returns zero candidates (does not throw)"
        status: pass
      - kind: unit
        ref: "backend/src/lib/discoveryAgentRunner.test.ts#pause_turn followed by end_turn with no tool_use still returns zero candidates (does not throw)"
        status: pass
    human_judgment: false
  - id: D2
    description: "checkAnthropicAvailability() returns {available:false, reason:'missing_key'} when ANTHROPIC_API_KEY is unset, without calling the canary"
    requirement: OPS-01
    verification:
      - kind: unit
        ref: "backend/src/lib/discoveryAgentRunner.test.ts#missing key returns available:false reason:missing_key without calling the canary"
        status: pass
    human_judgment: false
  - id: D3
    description: "checkAnthropicAvailability() returns {available:false, reason:'unusable'} for canary Anthropic.APIError with status 401/402/403, and the detail string never contains the raw API key"
    requirement: OPS-01
    verification:
      - kind: unit
        ref: "backend/src/lib/discoveryAgentRunner.test.ts#unusable credit — canary throwing an Anthropic.APIError with status 401/402/403"
        status: pass
      - kind: unit
        ref: "backend/src/lib/discoveryAgentRunner.test.ts#never includes the raw API key in the unusable detail string"
        status: pass
    human_judgment: false
  - id: D4
    description: "checkAnthropicAvailability() re-throws (inconclusive) for a 529 Anthropic.APIError and for a plain non-APIError network error, rather than reporting unusable"
    requirement: OPS-01
    verification:
      - kind: unit
        ref: "backend/src/lib/discoveryAgentRunner.test.ts#inconclusive canary — a 529 Anthropic.APIError re-throws rather than reporting unusable"
        status: pass
      - kind: unit
        ref: "backend/src/lib/discoveryAgentRunner.test.ts#inconclusive canary — a plain non-APIError network error re-throws rather than reporting unusable"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-23
status: complete
---

# Phase 173 Plan 1: Discovery Agent Runner Hardening Summary

**`discoveryAgentRunner.ts` no longer throws on a benign no-report model turn (OPS-03), and now exports a typed `checkAnthropicAvailability()` canary helper (OPS-01) that classifies only account-level 401/402/403 failures as unusable, re-throwing everything else as inconclusive.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-23T07:00:00Z (approx.)
- **Completed:** 2026-07-23T07:20:58Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- `runDiscoveryAgent` treats every non-`pause_turn`, non-`report_candidates` exit (in-loop `end_turn`/other, and the post-loop `MAX_TURNS`-exhausted fallback) as a benign zero-candidate result: `console.warn` + `return {candidates: [], stopReason}` instead of throwing — eliminates the 21x "Claude did not invoke report_candidates" hard-error path.
- New exported `checkAnthropicAvailability(): Promise<AnthropicAvailability>` and `AnthropicAvailability` union type: missing key → `{available:false, reason:'missing_key'}`; one cheap canary `messages.create` call (`claude-haiku-4-5`, `max_tokens:1`, no tools) on success → `{available:true}`; `Anthropic.APIError` with status 401/402/403 → `{available:false, reason:'unusable', detail}` (detail built only from `.status`/`.type`/`.message`, never the raw key); any other error (429/5xx/network/non-APIError) → re-thrown as inconclusive.
- New `backend/src/lib/discoveryAgentRunner.test.ts` (9 tests, all green) exercising both behaviors plus a dedicated "never includes the raw API key in the unusable detail string" security assertion.

## Task Commits

Each task was committed atomically (TDD: test → feat → feat):

1. **Task 1: Author discoveryAgentRunner.test.ts (RED)** - `80b18e84` (test)
2. **Task 2: OPS-03 — replace terminal throw with zero-candidate return** - `2b9fbeb8` (feat)
3. **Task 3: OPS-01 — add and export checkAnthropicAvailability() canary helper** - `963deb75` (feat)

_Note: this plan's `tasks` were each individually `tdd="true"` (RED for Task 1, GREEN for Tasks 2 and 3 — see TDD Gate Compliance below) rather than one RED→GREEN pair per task; no REFACTOR commit was needed._

## Files Created/Modified
- `backend/src/lib/discoveryAgentRunner.test.ts` - New Vitest suite: OPS-03 no-report exit paths (2 tests) + OPS-01 canary helper (7 tests, including `it.each([401,402,403])` and the key-redaction assertion). Mocks `@anthropic-ai/sdk` via an `importOriginal`-spreading factory (preserves the real `APIError` class so both `instanceof` and `new Anthropic.APIError(...)` work) and `./env.js` via a mutable `vi.hoisted` object.
- `backend/src/lib/discoveryAgentRunner.ts` - Terminal `throw` replaced with zero-candidate `return` (both in-loop and post-loop exits); added exported `AnthropicAvailability` type and `checkAnthropicAvailability()` function.

## Decisions Made
- Canary model: `claude-haiku-4-5` (cheapest), per RESEARCH Open Question 2 — a code comment in `checkAnthropicAvailability` notes the fallback to `claude-sonnet-4-6` if the account ever rejects haiku, since 401/402/403 are account-level signals either way.
- Classification boundary: only `Anthropic.APIError` with `.status` in `{401, 402, 403}` is conclusive "unusable"; everything else (529, other 5xx, `APIConnectionError`, plain `Error`) is re-thrown so 173-02's sweep orchestrator can log-and-proceed instead of false-positive-skipping the entire week's sweep (RESEARCH Pitfall 3).
- No changes to `discoveryService.ts` — its existing zero-candidate `completed` path (and existing zero-candidate *regression* alert, which only fires when a prior run found >0) already handles the new zero-candidate return correctly; this is explicitly locked by 173-03 per the plan's `key_links`.
- No changes to `discoveryDashboard.ts` (manual trigger route) — out of scope per RESEARCH Pitfall 4 / plan prohibition; it benefits for free from OPS-03 without needing OPS-01's canary.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

Plan-level tasks were individually `tdd="true"` rather than the whole plan being a single `type: tdd` RED→GREEN→REFACTOR cycle (this plan's frontmatter is `type: execute`, not `type: tdd`), so the "Plan-Level TDD Gate Enforcement" section does not strictly apply. For traceability: a `test(...)` commit (`80b18e84`) precedes both `feat(...)` commits (`2b9fbeb8`, `963deb75`) in git log, satisfying the RED-before-GREEN ordering informally.

## Issues Encountered

None. The mock factory for `@anthropic-ai/sdk` (spreading `importOriginal()` and overriding only `default`) worked on the first attempt — `Anthropic.APIError` remained both `instanceof`-checkable and directly constructible via `new Anthropic.APIError(status, error, message, headers, type)`, matching the installed SDK's constructor signature read from `node_modules/@anthropic-ai/sdk/core/error.d.ts`.

## User Setup Required

None - no external service configuration required. (`ANTHROPIC_API_KEY` is an existing, already-configured env var; this plan adds no new env vars or dependencies.)

## Next Phase Readiness

- `checkAnthropicAvailability()` is exported and ready for 173-02 to wire into `discoveryCron.ts`'s `runDiscoverySweep()` pre-flight, per the plan's `key_links`.
- The zero-candidate return contract from `runDiscoveryAgent` is stable and ready for 173-03's regression-lock test on `discoveryService.ts`'s existing zero-candidate `completed` path.
- No blockers.

---
*Phase: 173-discovery-sweep-anthropic-cost-reliability-hardening*
*Completed: 2026-07-23*
