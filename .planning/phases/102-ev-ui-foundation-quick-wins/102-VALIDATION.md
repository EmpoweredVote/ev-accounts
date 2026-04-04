---
phase: 102
slug: ev-ui-foundation-quick-wins
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-03
---

# Phase 102 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest (ev-accounts/backend), manual verification (ev-ui, essentials) |
| **Config file** | `ev-accounts/backend/vitest.config.ts` |
| **Quick run command** | `cd ev-accounts/backend && npm test` |
| **Full suite command** | `cd ev-accounts/backend && npm test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd ev-accounts/backend && npm test`
- **After every plan wave:** Run full suite + manual visual checks
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 102-01-01 | 01 | 1 | VIS-03 | grep | `grep -q "BallotIcon" ev-ui/src/icons.js` | ❌ W0 | ⬜ pending |
| 102-01-02 | 01 | 1 | VIS-03 | grep | `grep -q "tierColors" ev-ui/src/tokens.js` | ❌ W0 | ⬜ pending |
| 102-01-03 | 01 | 1 | DATA-03 | grep | `grep -q "imageFocalPoint" ev-ui/src/PoliticianCard.jsx` | ❌ W0 | ⬜ pending |
| 102-02-01 | 02 | 1 | DATA-01 | grep | `grep -L "Incumbent" essentials/src/components/ElectionsView.jsx` | ✅ | ⬜ pending |
| 102-02-02 | 02 | 1 | DATA-02 | sql | Migration file exists in `ev-accounts/backend/migrations/` | ❌ W0 | ⬜ pending |
| 102-03-01 | 03 | 2 | VIS-03 | grep | `grep -q "0.1.55" ev-ui/package.json` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.
- ev-ui has no test framework — verification is grep-based and visual
- ev-accounts backend tests validate migration syntax

*No new test files needed for this phase.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Headshot cropping shows faces | DATA-03 | Visual rendering check | View politician cards in browser, verify faces visible |
| Icons render correctly | VIS-03 | SVG visual check | Import icons in test page, verify shapes match Lucide originals |
| tierColors contrast meets WCAG | VIS-03 | Visual/computed style check | Inspect computed colors on section headers |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
