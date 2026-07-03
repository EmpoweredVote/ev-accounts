---
phase: 161
slug: wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-03
---

# Phase 161 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | psql read-only gate scripts (`-v ON_ERROR_STOP=1`) + `node` diag/validator scripts in `backend/scripts/` (per Validation Architecture in 161-RESEARCH.md) |
| **Config file** | none — scripts run against production Supabase (ref `kxsdzaojfaibhuzmclfq`) via `backend/src/lib/db.js` pool |
| **Quick run command** | per-state read-only SQL assertion block (counts + invariants) after each seed/stance push |
| **Full suite command** | `161-verify.sql` 37-district mini-gate (authored in the closing plan) |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task's read-only SQL assertion (row counts, 0-unsourced, non-null politician_id)
- **After every plan wave:** Run the per-state assertion block for the state just completed
- **Before `/gsd:verify-work`:** `161-verify.sql` must pass (psql exit 0)
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (filled by planner) | | | | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements — read-only SQL gates and diag scripts are the established validation stack (no test framework install needed).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| /elections surfaces each district's field for an in-district coordinate | USHC3-03 | Coordinate smoke exercises the live feed path | Run the coordinate-smoke script (152/158 pattern) against representative in-district coordinates per state |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
