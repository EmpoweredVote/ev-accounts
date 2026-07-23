---
phase: 173
slug: discovery-sweep-anthropic-cost-reliability-hardening
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-22
---

# Phase 173 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest `^2.1.0` (installed) |
| **Config file** | `backend/vitest.config.ts` |
| **Quick run command** | `cd backend && npx vitest run src/lib/discoveryCron.test.ts src/lib/discoveryAgentRunner.test.ts` |
| **Full suite command** | `cd backend && npm test` (runs `vitest run`, `src/**/*.{test,spec}.{ts,js}`) |
| **Estimated runtime** | ~5–15 seconds (quick); full suite longer |

---

## Sampling Rate

- **After every task commit:** Run `cd backend && npx vitest run src/lib/discoveryCron.test.ts src/lib/discoveryAgentRunner.test.ts` (add `src/lib/discoveryService.test.ts` once created)
- **After every plan wave:** Run `cd backend && npm test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~15 seconds

---

## Per-Task Verification Map

| Task ID | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| OPS-01a | — | OPS-01 | Missing `ANTHROPIC_API_KEY` aborts sweep, 0 jurisdictions processed, exactly one alert email; key never logged | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "missing key"` | ❌ W0 | ⬜ pending |
| OPS-01b | — | OPS-01 | Canary 401/402/403 `Anthropic.APIError` aborts sweep, 0 jurisdictions, one alert | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "unusable credit"` | ❌ W0 | ⬜ pending |
| OPS-01c | — | OPS-01 | Inconclusive canary (529/network) does NOT abort — jurisdictions still process | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "inconclusive canary"` | ❌ W0 | ⬜ pending |
| OPS-02a | — | OPS-02 | `isRetryable` false for `Anthropic.APIError` status 401/402/403 | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "non-retryable"` | ❌ W0 | ⬜ pending |
| OPS-02b | — | OPS-02 | `isRetryable` true for 429 and a representative 5xx (500/529) | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "retryable"` | ❌ W0 | ⬜ pending |
| OPS-02c | — | OPS-02 | `withRetry` calls fn exactly once on a 402 `Anthropic.APIError` (no multiply) | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "withRetry does not multiply"` | ❌ W0 | ⬜ pending |
| OPS-03a | — | OPS-03 | `runDiscoveryAgent` returns `{candidates:[],stopReason}` (no throw) on `end_turn` w/o `report_candidates` | unit | `npx vitest run src/lib/discoveryAgentRunner.test.ts -t "end_turn without report_candidates"` | ❌ W0 | ⬜ pending |
| OPS-03b | — | OPS-03 | `runDiscoveryForJurisdiction` → `status: completed`, `candidatesFound: 0` (not `failed`) on zero candidates | integration | `npx vitest run src/lib/discoveryService.test.ts -t "zero candidates is not a failure"` | ❌ W0 | ⬜ pending |
| OPS-04 | — | OPS-04 | Cadence/horizon documented in code + STATE/roadmap note | manual-only | N/A | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `backend/src/lib/discoveryCron.test.ts` — NEW; OPS-01 (canary gating) + OPS-02 (retry classification). Mock `@anthropic-ai/sdk`, `./discoveryService.js`, `./emailService.js`, `./env.js` (control `ANTHROPIC_API_KEY` presence). Follow the codebase `vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }))` convention (see `essentialsBrowseService.test.ts`, `electionsMapService.test.ts`).
- [ ] `backend/src/lib/discoveryAgentRunner.test.ts` — NEW; OPS-03 zero-candidate return path. Mock `@anthropic-ai/sdk` to return controlled `stop_reason` sequences (`pause_turn` → `end_turn` with no tool_use block); mock `./env.js`.
- [ ] `backend/src/lib/discoveryService.test.ts` — NEW; regression lock on the existing zero-candidate handling in `runDiscoveryForJurisdiction`. Mock `./discoveryAgentRunner.js`, `./db.js`, `./emailService.js`, `./fetchPageContent.js`.
- [ ] Framework install: none — Vitest already installed + configured.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cadence + horizon are a deliberate, documented cost choice | OPS-04 | Documentation/confirmation deliverable — no runtime behavior to assert | Confirm live `discovery_jurisdictions`-in-horizon count with operator; verify code comment on the cron expr + `SWEEP_HORIZON_DAYS` states the cost rationale; roadmap/STATE note records the decision |
| Real Render deploy of the change | OPS-01..04 | Deploy verification is out-of-process | After merge, trigger Render deploy hook; confirm next sweep fire behaves (or a manual dashboard trigger with a deliberately-bad key produces the skip+alert, not a flood) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (OPS-04 is documented manual-only)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (3 new test files)
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
