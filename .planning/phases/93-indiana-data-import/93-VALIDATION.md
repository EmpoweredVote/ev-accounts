---
phase: 93
slug: indiana-data-import
status: draft
nyquist_compliant: true
wave_0_complete: true
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
| 93-01-00 | 01 | 0 | IND-01, IND-03 | scaffold | `go test ./internal/treasury/... -run TestGatewayCSVParse` | Wave 0 creates | ⬜ pending |
| 93-01-01 | 01 | 1 | IND-01, IND-03 | unit | `go test ./internal/treasury/... -run "TestParseAmount\|TestValidateHeaders\|TestPipeDelimiter\|TestUTF8Reencode\|TestGatewayCSVParse"` | ✅ W0 | ⬜ pending |
| 93-01-02 | 01 | 1 | IND-01, IND-02 | unit | `go test ./internal/treasury/... -run "TestImportEllettsville\|TestImportMonroeCounty"` | ✅ W0 | ⬜ pending |
| 93-01-03 | 01 | 1 | IND-01 | build | `go build -o /tmp/ev-server-test . && grep -c 'case "gateway"' main.go` | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `internal/treasury/gateway_test.go` — test functions for IND-01, IND-02, IND-03 (created by Task 0)
- [x] `internal/treasury/testdata/ellettsville_sample.csv` — pipe-delimited test fixture (created by Task 0)

*Existing go test infrastructure covers framework needs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Treasury Tracker UI displays imported data | IND-01, IND-02 | Requires browser + running frontend | Load treasurytracker.empowered.vote, select Ellettsville/Monroe County, verify budget data renders |
| Gateway POST download works against live site | IND-01 | Requires live Gateway server + network | Run `./server import-budgets --source=gateway --dry-run` and verify CSV downloads |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready
