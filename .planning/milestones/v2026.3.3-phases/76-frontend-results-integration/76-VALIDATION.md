---
phase: 76
slug: frontend-results-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-11
---

# Phase 76 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — essentials has no automated test suite |
| **Config file** | none |
| **Quick run command** | `cd essentials && npm run build` |
| **Full suite command** | Manual browser verification with Monroe County address |
| **Estimated runtime** | ~10 seconds (build) + manual verification |

---

## Sampling Rate

- **After every task commit:** Run `cd essentials && npm run build` (build green) + manual browser check for one Monroe County address
- **After every plan wave:** Full manual verification of all 5 BODY success criteria + LA County regression
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds (build)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 76-01-01 | 01 | 1 | BODY-01, BODY-02, BODY-03, BODY-04, BODY-05 | manual + build | `cd essentials && npm run build` | N/A | pending |
| 76-01-02 | 01 | 1 | Regression | manual | Manual LA County address check | N/A | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework to install — essentials uses manual browser verification as established pattern.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Section headings show specific body names | BODY-01 | UI rendering, no test suite | Search Monroe County address, verify "Monroe County Council" and "Monroe County Commissioners" appear as section headings |
| Commission and Council as separate sections | BODY-02 | UI rendering, no test suite | Verify county section splits into distinct subsections |
| Township shows specific name | BODY-03 | UI rendering, no test suite | Verify "Perry Township Trustee" (or similar) appears instead of generic label |
| Bloomington Common Council heading | BODY-04 | UI rendering, no test suite | Search Bloomington address, verify section heading |
| School board shows specific district name | BODY-05 | UI rendering, no test suite | Verify "Monroe County Community School Corporation Board" appears |
| LA County graceful fallback | Regression | UI rendering, no test suite | Search LA County address, verify generic category names still render |
| Website link icons in headers | BODY-05 | UI rendering, no test suite | Verify link icons appear for Monroe County and Bloomington bodies |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
