---
phase: 88
slug: practice-round
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 88 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest |
| **Config file** | `EV-readrank/vitest.config.ts` or needs creation |
| **Quick run command** | `cd EV-readrank && npx vitest run --reporter=verbose` |
| **Full suite command** | `cd EV-readrank && npx vitest run` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd EV-readrank && npx vitest run --reporter=verbose`
- **After every plan wave:** Run `cd EV-readrank && npx vitest run`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | 01 | 1 | ONBD-01 | unit | `vitest run` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | ONBD-02 | unit | `vitest run` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | ONBD-03 | unit | `vitest run` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | ONBD-04 | unit | `vitest run` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Vitest installed and configured in EV-readrank (if not already)
- [ ] Test stubs for practice store state (practiceCompleted flag, practice progress isolation)
- [ ] Test stubs for practice data isolation (verdictSync must not read practice data)
- [ ] Test stubs for skip-practice flow (clears state, sets practiceCompleted)

*Will be refined by planner when task IDs are assigned.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Swipe gesture feel | ONBD-02 | Touch/mouse interaction UX | Swipe 5 practice quotes on mobile + desktop, verify smooth animation |
| Head-to-head matchup flow | ONBD-02 | Multi-step UI interaction | Complete practice, verify matchup prompts appear after agrees |
| Practice banner visibility | ONBD-01 | Visual design verification | Verify "Practice Round" banner visible throughout practice |
| Results screen character reveals | ONBD-01 | Animation/visual quality | Complete practice, verify pizza ranking results with character reveals |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
