---
phase: 87
slug: unified-evaluatephase-inlinerankpanel
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 87 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — TypeScript build as automated proxy |
| **Config file** | tsconfig.app.json |
| **Quick run command** | `cd EV-readrank && npx tsc --project tsconfig.app.json --noEmit` |
| **Full suite command** | `cd EV-readrank && npm run build` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd EV-readrank && npx tsc --project tsconfig.app.json --noEmit`
- **After every plan wave:** Run `cd EV-readrank && npm run build`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 87-01-01 | 01 | 1 | FLOW-05 | TypeScript build | `cd EV-readrank && npx tsc --project tsconfig.app.json --noEmit` | ✅ | ⬜ pending |
| 87-01-02 | 01 | 1 | FLOW-01 | manual | N/A | N/A | ⬜ pending |
| 87-02-01 | 02 | 2 | FLOW-02 | manual | N/A | N/A | ⬜ pending |
| 87-02-02 | 02 | 2 | FLOW-03 | manual | N/A | N/A | ⬜ pending |
| 87-02-03 | 02 | 2 | FLOW-04 | manual | N/A | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. TypeScript build serves as the automated proxy for structural correctness. No unit test framework exists and none is required for this phase.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Evaluation phase never transitions to separate ranking screen | FLOW-01 | UI navigation flow — requires browser | Complete an issue, verify no intermediate ranking screen appears |
| InlineRankPanel appears only after 2nd agree | FLOW-02 | DOM interaction timing — requires browser | Agree with 2 quotes, verify panel appears after second |
| Desktop sidebar shows ranked list during evaluation | FLOW-03 | Layout verification — requires browser | On desktop viewport, verify sidebar visible while evaluating |
| Mobile inline panel slides in between quotes | FLOW-04 | Touch interaction + animation — requires device | On mobile viewport, verify panel appears inline after 2nd agree |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
