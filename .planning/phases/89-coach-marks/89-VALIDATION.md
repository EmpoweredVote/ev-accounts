---
phase: 89
slug: coach-marks
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 89 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None detected in EV-readrank — manual verification |
| **Config file** | None — no test framework installed |
| **Quick run command** | `cd EV-readrank && npx tsc --noEmit` |
| **Full suite command** | `cd EV-readrank && npx tsc --noEmit && npm run build` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd EV-readrank && npx tsc --noEmit`
- **After every plan wave:** Run `cd EV-readrank && npm run build`
- **Before `/gsd:verify-work`:** Full build must succeed + manual smoke test
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 89-01-01 | 01 | 1 | ONBD-06 | build | `cd EV-readrank && npx tsc --noEmit` | ✅ | ⬜ pending |
| 89-01-02 | 01 | 1 | ONBD-05 | build | `cd EV-readrank && npx tsc --noEmit` | ✅ | ⬜ pending |
| 89-01-03 | 01 | 1 | ONBD-05 | build | `cd EV-readrank && npx tsc --noEmit` | ✅ | ⬜ pending |
| 89-02-01 | 02 | 2 | ONBD-05 | manual | Manual browser test | ❌ | ⬜ pending |
| 89-02-02 | 02 | 2 | ONBD-05, ONBD-06 | manual | Manual browser test | ❌ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing TypeScript compiler covers type-checking for all phase requirements
- No additional test framework needed for this phase — manual verification covers interaction behavior

*Existing infrastructure covers all phase requirements that can be automated.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Coach marks appear on first real issue with correct spotlight positioning | ONBD-05 | Visual DOM positioning + SVG mask overlay requires browser | 1. Clear localStorage 2. Complete practice round 3. First real issue should show step 1 spotlight on QuoteCard after ~500ms |
| Step 1 auto-advances on swipe, step 2 appears on rank panel | ONBD-05 | Interaction sequence requires gesture input | 1. With step 1 visible, swipe right to agree 2. Step 2 should appear spotlighting rank panel 3. Click "Got it" to dismiss |
| Coach marks never reappear after dismissal | ONBD-06 | Requires page reload + localStorage persistence check | 1. Complete or skip tour 2. Reload page 3. Navigate back to evaluation — no coach marks 4. Check localStorage for `coachMarksCompleted: true` |
| Existing users skip coach marks | ONBD-06 | Requires store migration verification | 1. Set localStorage with v5 store data 2. Reload — migration should set `coachMarksCompleted: true` 3. No coach marks appear |
| Mobile step 2 targets InlineRankPanel | ONBD-05 | Requires mobile viewport + touch interaction | 1. Use mobile viewport 2. Complete step 1 3. Step 2 should spotlight InlineRankPanel/counter pill |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
