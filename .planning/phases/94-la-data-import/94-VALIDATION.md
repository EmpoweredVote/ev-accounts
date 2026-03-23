---
phase: 94
slug: la-data-import
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-22
---

# Phase 94 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | go test |
| **Config file** | none — Wave 0 installs |
| **Quick run command** | `cd EV-Backend && go test ./internal/treasury/...` |
| **Full suite command** | `cd EV-Backend && go test ./...` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd EV-Backend && go test ./internal/treasury/...`
- **After every plan wave:** Run `cd EV-Backend && go test ./...`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 94-01-01 | 01 | 1 | LA-01 | integration | `go test ./internal/treasury/... -run TestLACountyImport` | ❌ W0 | ⬜ pending |
| 94-01-02 | 01 | 1 | LA-02 | integration | `go test ./internal/treasury/... -run TestLACityImport` | ❌ W0 | ⬜ pending |
| 94-01-03 | 01 | 1 | LA-03 | unit | `go test ./internal/treasury/... -run TestFiscalYearStartMonth` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `internal/treasury/import_test.go` — stubs for LA-01, LA-02, LA-03
- [ ] Test fixtures for ArcGIS and Socrata response mocking

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Budget data visible in Treasury Tracker UI | LA-01, LA-02 | Requires browser rendering | Navigate to treasurytracker.empowered.vote, select LA County/LA City, verify data displays |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
