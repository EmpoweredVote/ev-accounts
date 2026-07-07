---
phase: 168
slug: elections-accuracy-fix
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-04
---

# Phase 168 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest (project-pinned) — confirmed via `backend/vitest.config.ts` and `backend/package.json` (`"test": "vitest run"`) |
| **Config file** | `backend/vitest.config.ts` |
| **Quick run command** | `cd backend && npx vitest run src/lib/electionsMap.test.ts` |
| **Full suite command** | `cd backend && npm test` |
| **Estimated runtime** | ~1s (pure-helper quick run); full backend suite ~tens of seconds |

**Frontend note:** No test runner is configured for `admin/` (confirmed via RESEARCH.md). Frontend verification is `npx tsc --noEmit` (typecheck) + the Plan-03 Task-3 manual Michigan-case walkthrough. This is a known, accepted gap for this phase (out of scope to stand up a frontend test harness).

---

## Sampling Rate

- **After every task commit:** Run `cd backend && npx vitest run src/lib/electionsMap.test.ts` (backend), or `cd admin && npx tsc --noEmit` (frontend tasks)
- **After every plan wave:** Run `cd backend && npm test`
- **Before `/gsd-verify-work`:** Full backend suite green + admin typecheck clean + manual walkthrough approved
- **Max feedback latency:** < 5s (pure-helper quick run is sub-second)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 168-01-01 | 01 | 1 | ELEC-01 | T-168-02 | Pure partition, no new SQL | unit | `cd backend && npx vitest run src/lib/electionsMap.test.ts -t "classifyRaces"` | ❌ W0 (extends existing file) | ⬜ pending |
| 168-01-02 | 01 | 1 | ELEC-01, ELEC-03 | T-168-01 / T-168-02 | Payload behind existing admin guard; parameterized queries only | unit + typecheck | `cd backend && npx vitest run src/lib/electionsMap.test.ts && npx tsc --noEmit` | ✅ (pure tests) / service typecheck | ⬜ pending |
| 168-02-01 | 02 | 2 | ELEC-03 | T-168-03 | Auth mocked test-only; real guard unchanged | integration (route) | `cd backend && npx vitest run src/routes/admin.test.ts` | ❌ W0 (NEW file) | ⬜ pending |
| 168-03-01 | 03 | 2 | ELEC-01, ELEC-02, ELEC-03 | T-168-04 | Renders admin-only data on admin-gated page | typecheck | `cd admin && npx tsc --noEmit` | ✅ (tsc) | ⬜ pending |
| 168-03-02 | 03 | 2 | ELEC-02 | T-168-04 | Panel mount, no new fetch | typecheck | `cd admin && npx tsc --noEmit` | ✅ (tsc) | ⬜ pending |
| 168-03-03 | 03 | 2 | ELEC-01, ELEC-02, ELEC-03 | T-168-04 | Manual verify of admin-gated UI | manual (human-verify) | Michigan-case walkthrough (Plan 03 Task 3) | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `backend/src/lib/electionsMap.test.ts` — extend with a `describe('classifyRaces')` block (all-statewide, mixed, empty sets) — ELEC-01. **Handled in Plan 01 Task 1** (test written before/with the helper; `tdd="true"`).
- [ ] `backend/src/routes/admin.test.ts` — NEW file: route-level cross-endpoint denominator consistency (ELEC-03). **Handled in Plan 02 Task 1** (`tdd="true"`).

**Note:** No standalone `backend/src/lib/electionsMapService.test.ts` is created. Per the established codebase convention (`essentialsService.test.ts` extracts pure logic into a helper — `pickCountyFromDistrictRows` — and unit-tests that rather than DB-mocking the whole service), the ELEC-01/ELEC-03 partition logic is verified at the pure-helper level via `classifyRaces` in `electionsMap.test.ts`, and the service-layer wiring + denominator consistency is verified at the route level via `admin.test.ts`. This avoids brittle DB-mocking of `getElectionsStateScores` while keeping every requirement automated-sampled.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Elections map fill = statewide number; statewide-races panel renders alongside county view; N/A distinct from 0%; state view does not contradict county drill-down | ELEC-01, ELEC-02, ELEC-03 | No frontend test runner configured for `admin/` (RESEARCH.md); UI/visual verification | Plan 03 Task 3 checkpoint — Michigan-case walkthrough steps 1-5 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (frontend UI verified by tsc + manual walkthrough per accepted no-frontend-runner gap)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every backend task has a vitest command; every frontend code task has a tsc gate)
- [x] Wave 0 covers all MISSING references (`classifyRaces` tests in Plan 01, new `admin.test.ts` in Plan 02)
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-04
