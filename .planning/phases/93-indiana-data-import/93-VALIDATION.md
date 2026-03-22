---
phase: 93
slug: indiana-data-import
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-22
---

# Phase 93 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | go test |
| **Config file** | none — uses standard Go test tooling |
| **Quick run command** | `cd EV-Backend && go test ./internal/treasury/...` |
| **Full suite command** | `cd EV-Backend && go test ./internal/treasury/... -v` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd EV-Backend && go test ./internal/treasury/...`
- **After every plan wave:** Run `cd EV-Backend && go test ./internal/treasury/... -v`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 93-01-01 | 01 | 1 | IND-01 | unit | `go test ./internal/treasury/... -run TestGatewayCSVParse` | ❌ W0 | ⬜ pending |
| 93-01-02 | 01 | 1 | IND-03 | unit | `go test ./internal/treasury/... -run TestPipeDelimiter` | ❌ W0 | ⬜ pending |
| 93-01-03 | 01 | 1 | IND-03 | unit | `go test ./internal/treasury/... -run TestUTF8Reencode` | ❌ W0 | ⬜ pending |
| 93-02-01 | 02 | 1 | IND-01 | integration | `go test ./internal/treasury/... -run TestImportEllettsville` | ❌ W0 | ⬜ pending |
| 93-02-02 | 02 | 1 | IND-02 | integration | `go test ./internal/treasury/... -run TestImportMonroeCounty` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `internal/treasury/gateway_test.go` — stubs for IND-01, IND-02, IND-03
- [ ] Test fixtures: sample pipe-delimited CSV data for Ellettsville and Monroe County

*Existing go test infrastructure covers framework needs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Treasury Tracker UI displays imported data | IND-01, IND-02 | Requires browser + running frontend | Load treasurytracker.empowered.vote, select Ellettsville/Monroe County, verify budget data renders |
| Gateway POST download works | IND-01 | Requires live Gateway server | Run import CLI against live Gateway URL, verify CSV downloads |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
