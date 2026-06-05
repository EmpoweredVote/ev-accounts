---
phase: 100
slug: source-coverage-audit
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-05
---

# Phase 100 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — data-audit phase (same pattern as Phases 87, 89) |
| **Config file** | N/A |
| **Quick run command** | `cd backend && npx tsx scripts/run-source-coverage-audit.ts` |
| **Full suite command** | `cd backend && npx tsx scripts/run-source-coverage-audit.ts` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** N/A — single-script phase
- **After plan completion:** Run the audit script; inspect output files
- **Before `/gsd-verify-work`:** Both `100-AUDIT-REPORT.md` and `100-TARGET-LIST.csv` must exist in phase directory

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 100-01-01 | 01 | 1 | SRCA-01 | — | N/A | manual | `cd backend && npx tsx scripts/run-source-coverage-audit.ts` | ❌ W0 | ⬜ pending |
| 100-01-02 | 01 | 1 | SRCA-02 | — | N/A | manual | inspect `.planning/phases/100-source-coverage-audit/100-TARGET-LIST.csv` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `backend/scripts/run-source-coverage-audit.ts` — the audit script (produced by this phase)

*No test stubs required — deliverable IS the script output.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Audit report shows correct tier breakdown | SRCA-01 | Output is a live DB snapshot; automating would require mocking DB state, defeating the audit purpose | Run script, verify 100-AUDIT-REPORT.md exists with Federal/State/Local/City rows and non-zero totals |
| Target list CSV has majority_unsourced flag | SRCA-02 | Same as above | Open 100-TARGET-LIST.csv, verify columns present, spot-check known unsourced politicians |
| MD officials (Wes Moore et al.) appear with 0 stances | SRCA-01 | DB query required | Verify MD officials section in audit report shows 5 politicians, all with 0 stances |

---

## Validation Sign-Off

- [ ] Audit script executes without error (`exit 0`)
- [ ] `100-AUDIT-REPORT.md` written to phase directory with all required sections
- [ ] `100-TARGET-LIST.csv` written to phase directory with correct columns
- [ ] MD officials section present in report (confirms Pitfall 5 handled)
- [ ] Sourced definition documented in report
- [ ] `nyquist_compliant: false` — data-audit phase, same rationale as Phases 87/89

**Approval:** pending
