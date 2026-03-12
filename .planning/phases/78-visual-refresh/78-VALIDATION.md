---
phase: 78
slug: visual-refresh
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-11
---

# Phase 78 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — visual/CSS phase; manual inspection via dev server |
| **Config file** | none — no test framework in EV-ReadRank |
| **Quick run command** | `cd EV-ReadRank/read-rank && npm run dev` |
| **Full suite command** | `cd EV-ReadRank/read-rank && npm run build` (verifies no compile errors) |
| **Estimated runtime** | ~5 seconds (build) |

---

## Sampling Rate

- **After every task commit:** Run `npm run build` to verify no TypeScript/Tailwind compile errors
- **After every plan wave:** `npm run dev` + visual checklist inspection
- **Before `/gsd:verify-work`:** Full visual checklist must be complete
- **Max feedback latency:** ~10 seconds (build check)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 78-01-01 | 01 | 1 | DSGN-01 | build + visual | `npm run build` | ✅ | ⬜ pending |
| 78-01-02 | 01 | 1 | DSGN-01 | build + visual | `npm run build` | ✅ | ⬜ pending |
| 78-02-01 | 02 | 2 | DSGN-02 | build + visual | `npm run build` | ✅ | ⬜ pending |
| 78-02-02 | 02 | 2 | DSGN-02 | build + visual | `npm run build` | ✅ | ⬜ pending |
| 78-03-01 | 03 | 3 | DSGN-03 | build + visual | `npm run build` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* No test framework installation needed — all DSGN requirements are visual/CSS-only and verified via manual dev server inspection and build success.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hub page shows ev-muted-blue accent, Manrope headings | DSGN-01 | Visual CSS — no automated visual regression | `npm run dev` → navigate to hub → verify color/font rendering |
| QuoteCard renders white with ev-muted-blue top border | DSGN-02 | Visual CSS | `npm run dev` → start evaluation → verify card appearance |
| Swipe feedback uses amber/cyan (not red/green) | DSGN-02 | Visual CSS | `npm run dev` → drag card left/right → verify zone colors |
| Swipe gestures function identically after redesign | DSGN-02 | Gesture behavior | `npm run dev` → swipe cards through full evaluation → verify snap-back, verdict animation, card removal |
| ResultsPhase cards match CompassV2 pattern | DSGN-03 | Visual CSS | Complete evaluation → verify results layout |
| CTA "View on Essentials" button uses ev-coral | DSGN-03 | Visual CSS | Verify results CTA button color |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
