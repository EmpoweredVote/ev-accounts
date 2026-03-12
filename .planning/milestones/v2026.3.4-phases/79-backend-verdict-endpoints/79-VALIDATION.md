---
phase: 79
slug: backend-verdict-endpoints
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-12
---

# Phase 79 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — EV-Backend has no test files |
| **Config file** | none |
| **Quick run command** | `go build ./...` |
| **Full suite command** | `go vet ./...` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `go build ./...`
- **After every plan wave:** Run `go vet ./...`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 79-01-01 | 01 | 1 | VERD-01 | manual | `go build ./...` | ❌ W0 | ⬜ pending |
| 79-01-02 | 01 | 1 | VERD-02 | manual | `go build ./...` | ❌ W0 | ⬜ pending |
| 79-01-03 | 01 | 1 | VERD-03 | manual | `go build ./...` | ❌ W0 | ⬜ pending |
| 79-01-04 | 01 | 1 | VERD-04 | manual | `go build ./...` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

No test infrastructure exists in EV-Backend. All validation is manual via curl/Postman against a running server.

*Existing infrastructure covers all phase requirements (go build + go vet as compilation gate).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `compass.quote_verdicts` table created with unique constraint | VERD-01 | No test framework; DB inspection required | Run server, inspect DB schema: `\d compass.quote_verdicts` |
| POST `/compass/verdicts` bulk-upserts and returns updated set | VERD-02 | No test framework; HTTP test required | `curl -X POST /compass/verdicts` with session cookie + verdict payload |
| GET `/compass/verdicts` returns current user verdicts | VERD-03 | No test framework; HTTP test required | `curl /compass/verdicts` with session cookie, verify response |
| GET `/essentials/quotes?politician_id=X` filters correctly | VERD-04 | No test framework; HTTP test required | `curl /essentials/quotes?politician_id=1`, verify only quotes for politician 1 returned |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
