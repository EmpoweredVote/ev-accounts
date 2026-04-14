---
phase: 115
slug: gap-report-synthesis
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-13
---

# Phase 115 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — document synthesis phase |
| **Config file** | none |
| **Quick run command** | `ls .planning/GAP-REPORT.md .planning/BACKLOG.md 2>/dev/null` |
| **Full suite command** | `ls .planning/GAP-REPORT.md .planning/BACKLOG.md && grep -c "Tier 1\|Tier 2" .planning/GAP-REPORT.md` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `ls .planning/GAP-REPORT.md .planning/BACKLOG.md 2>/dev/null`
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 115-01-01 | 01 | 1 | GAP-01 | — | N/A | file-check | `test -f .planning/GAP-REPORT.md` | ❌ W0 | ⬜ pending |
| 115-01-02 | 01 | 1 | GAP-01 | — | N/A | content | `grep -c "Tier 1\|Tier 2" .planning/GAP-REPORT.md` | ❌ W0 | ⬜ pending |
| 115-01-03 | 01 | 1 | GAP-02 | — | N/A | content | `grep -i "intentional omissions" .planning/GAP-REPORT.md` | ❌ W0 | ⬜ pending |
| 115-01-04 | 01 | 2 | GAP-03 | — | N/A | file-check | `test -f .planning/BACKLOG.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.planning/GAP-REPORT.md` — will be created in this phase
- [ ] `.planning/BACKLOG.md` — will be created in this phase

*Files are created by execution tasks, not pre-existing.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| All 31 UX gaps assigned Tier 1 or Tier 2 with correct reasoning | GAP-01 | Tier assignment requires judgment against D-01/D-02/D-03 rules | Count entries in GAP-REPORT.md, verify each has a tier and rationale |
| Intentional omissions section covers antipartisan choices | GAP-02 | Content accuracy requires human review | Check section exists and lists: no party labels, no endorsements, no interest group ratings |
| Backlog phases are sequenced logically by dependency | GAP-03 | Sequencing requires understanding of implementation dependencies | Review BACKLOG.md phase order against PATTERN clusters from RESEARCH.md |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
