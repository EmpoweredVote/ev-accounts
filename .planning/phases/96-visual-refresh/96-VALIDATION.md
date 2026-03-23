---
phase: 96
slug: visual-refresh
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-23
---

# Phase 96 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None (visual/CSS phase — build serves as smoke test) |
| **Config file** | none |
| **Quick run command** | `cd treasury-tracker && npm run build` |
| **Full suite command** | `cd treasury-tracker && npm run build` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd treasury-tracker && npm run build`
- **After every plan wave:** Run `cd treasury-tracker && npm run build`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 96-01-01 | 01 | 1 | VIS-01 | smoke | `cd treasury-tracker && npm run build` | N/A | ⬜ pending |
| 96-01-02 | 01 | 1 | VIS-02 | smoke | `cd treasury-tracker && npm run build` | N/A | ⬜ pending |
| 96-01-03 | 01 | 1 | VIS-05 | smoke | `cd treasury-tracker && npm run build` | N/A | ⬜ pending |
| 96-02-01 | 02 | 2 | VIS-03 | manual-only | `grep -r "var(--coral)\|var(--muted-blue)" treasury-tracker/src/` | N/A | ⬜ pending |
| 96-02-02 | 02 | 2 | VIS-04 | manual-only | `grep -rn "category\.color\|\.data\.color" treasury-tracker/src/components/` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No unit test framework is needed — this is a visual/CSS migration phase. The build command serves as the automated gate.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| UI chrome uses EV design tokens visually | VIS-03 | CSS class application is visual — build can't verify visual output | Open app in browser, inspect header/cards/tabs/buttons for ev-* token usage |
| Chart fills use data viz palette, not brand colors | VIS-04 | D3 renders SVG at runtime — can't verify fill colors at build time | Open sunburst/icicle charts, verify segment colors match `--color-data-*` palette |
| Manrope typography renders correctly | VIS-05 | Font loading is runtime — build can't verify rendered font | Open app, inspect body font-family in DevTools |
| Full visual redesign quality | VIS-03 | Design quality is subjective | Compare components against 96-UI-SPEC.md mockups |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
