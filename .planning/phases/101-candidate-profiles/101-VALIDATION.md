---
phase: 101
slug: candidate-profiles
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-30
---

# Phase 101 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest (ev-accounts), manual browser (essentials frontend) |
| **Config file** | `ev-accounts/backend/vitest.config.ts` |
| **Quick run command** | `cd ev-accounts/backend && npm test -- --run` |
| **Full suite command** | `cd ev-accounts/backend && npm test -- --run` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd ev-accounts/backend && npm test -- --run`
- **After every plan wave:** Run full suite + manual browser verification
- **Before `/gsd:verify-work`:** Full suite must be green + manual profile navigation test
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 101-01-01 | 01 | 1 | PROF-01 | integration | `cd ev-accounts/backend && npm test -- --run` | ❌ W0 | ⬜ pending |
| 101-01-02 | 01 | 1 | PROF-02 | manual | Browser: navigate to incumbent candidate profile | N/A | ⬜ pending |
| 101-01-03 | 01 | 1 | PROF-03 | manual | Browser: navigate to challenger candidate profile | N/A | ⬜ pending |
| 101-02-01 | 02 | 2 | PROF-04 | manual | Browser: verify compass card renders on candidate profile | N/A | ⬜ pending |
| 101-02-02 | 02 | 2 | PROF-05 | manual | Browser: verify verdict badge renders on candidate profile | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `ev-accounts/backend/src/__tests__/raceCandidates.test.ts` — stubs for PROF-01 (race candidate endpoint)

*Existing infrastructure covers most phase requirements — frontend verification is manual.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Candidate card navigation from Election Central | PROF-01 | UI routing/navigation behavior | Click candidate card → verify `/candidate/:id` loads with name, photo, position |
| Incumbent compass card display | PROF-02 | Requires live compass data + UI rendering | Navigate to incumbent candidate → verify compass radar overlay appears |
| Challenger minimal profile | PROF-03 | Requires visual verification of absent sections | Navigate to challenger candidate → verify no loading spinners, no empty sections |
| Compass stances on profiles | PROF-04 | Data import + UI rendering | Verify compass card appears for candidates with imported stances |
| Read & Rank verdict badges | PROF-05 | Data import + UI rendering | Verify verdict badge appears for candidates with imported quotes |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
