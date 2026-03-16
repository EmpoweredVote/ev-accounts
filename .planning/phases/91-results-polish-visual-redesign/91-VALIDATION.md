---
phase: 91
slug: results-polish-visual-redesign
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 91 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest (via EV-readrank) |
| **Config file** | `EV-readrank/vite.config.ts` |
| **Quick run command** | `cd EV-readrank && npx vitest run --reporter=verbose` |
| **Full suite command** | `cd EV-readrank && npx vitest run --reporter=verbose` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd EV-readrank && npx vitest run --reporter=verbose`
- **After every plan wave:** Run `cd EV-readrank && npx vitest run --reporter=verbose`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 91-01-01 | 01 | 1 | RSLT-01 | visual/manual | Browser check: identity hidden pre-reveal | N/A | ⬜ pending |
| 91-01-02 | 01 | 1 | RSLT-01 | visual/manual | Browser check: staggered reveal animation | N/A | ⬜ pending |
| 91-02-01 | 02 | 1 | RSLT-02 | grep | `grep -r "View on Essentials" EV-readrank/src/components/ResultsPhase.tsx` | ❌ W0 | ⬜ pending |
| 91-02-02 | 02 | 1 | RSLT-03 | grep | `grep -r "View Alignment" EV-readrank/src/components/ResultsPhase.tsx` (should return nothing) | ❌ W0 | ⬜ pending |
| 91-03-01 | 03 | 1 | RSLT-04 | visual/manual | Browser check: CandidateAlignmentPage typography matches | N/A | ⬜ pending |
| 91-04-01 | 04 | 2 | CHRM-04 | grep | `grep -r "Fraunces" EV-readrank/src/` (should return nothing) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers automated checks. This phase is primarily visual/animation work — most verifications are grep-based (presence/absence of strings) or manual browser checks.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Identity hidden on pre-reveal cards | RSLT-01 | Visual animation state | Load results, verify no candidate name/photo visible before clicking reveal |
| Staggered reveal animation | RSLT-01 | Animation timing | Click reveal button, verify cards animate in sequence with ~200ms gaps |
| Particle burst on reveal | RSLT-01 | Visual effect | Click reveal, verify megaBurst-style particles appear per card |
| Single CTA per card | RSLT-02 | Layout verification | After reveal, verify only "View on Essentials" button per card |
| CandidateAlignmentPage visual consistency | RSLT-04 | Typography/spacing | Navigate to alignment page, verify Manrope font, consistent spacing |
| Page transitions | CHRM-04 | Animation UX | Navigate between Hub/Eval/Results, verify smooth transitions |
| prefers-reduced-motion | RSLT-01 | Accessibility | Enable reduced motion in OS, verify no particle bursts or staggers |
| Matchup sidebar hide | CHRM-04 | Layout | During matchup phase, verify sidebar hidden and cards use full width |
| End-of-evaluation layout | CHRM-04 | Animation | After last quote, verify ranked list expands to center |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
