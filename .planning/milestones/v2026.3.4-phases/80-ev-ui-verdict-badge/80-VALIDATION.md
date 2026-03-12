---
phase: 80
slug: ev-ui-verdict-badge
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-12
---

# Phase 80 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — ev-ui has no automated test infrastructure |
| **Config file** | none |
| **Quick run command** | `npm view @chrisandrewsedu/ev-ui version` (verify publish) |
| **Full suite command** | Manual visual verification in browser |
| **Estimated runtime** | ~2 minutes (manual) |

---

## Sampling Rate

- **After every task commit:** Manual visual inspection of component in browser
- **After every plan wave:** Run `npm view @chrisandrewsedu/ev-ui version` to confirm publish
- **Before `/gsd:verify-work`:** Verify published package resolves in essentials `npm install`
- **Max feedback latency:** ~5 minutes (manual verification)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 80-01-01 | 01 | 1 | PROF-03 | manual | Inspect `ev-ui/src/StanceAccordion.jsx` exists with `verdictsByTopic` prop | ❌ W0 | ⬜ pending |
| 80-01-02 | 01 | 1 | PROF-03 | manual | Inspect `ev-ui/src/Favicon.jsx` exists | ❌ W0 | ⬜ pending |
| 80-01-03 | 01 | 1 | PROF-03 | manual | `grep -r 'StanceAccordion' ev-ui/src/index.js` returns export | ❌ W0 | ⬜ pending |
| 80-01-04 | 01 | 2 | PROF-03 | automated | `cd ev-ui && npm run build` exits 0 | ❌ W0 | ⬜ pending |
| 80-01-05 | 01 | 2 | PROF-03 | automated | `npm view @chrisandrewsedu/ev-ui version` returns `0.1.42` | ❌ W0 | ⬜ pending |
| 80-01-06 | 01 | 3 | PROF-03 | manual | Load essentials Profile page — badge renders for agreed/disagreed topics | ❌ W0 | ⬜ pending |
| 80-01-07 | 01 | 3 | PROF-03 | manual | Load essentials Profile page without verdictsByTopic — identical to previous render | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — no automated test infrastructure exists or is expected for this component library. Manual verification is the established pattern for ev-ui releases (consistent with Phases 67-76).

*Existing infrastructure covers all phase requirements (manual verification only).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Badge renders inline (agreed = cyan pill, disagreed = amber pill) | PROF-03 | No test framework in ev-ui; browser visual check only | Load `/profile/:slug` in essentials dev server with `verdictsByTopic={{ [topicId]: 'agreed' }}` passed to StanceAccordion; confirm cyan pill appears on correct topic row |
| No prop = no badge | PROF-03 | Visual regression; no test framework | Load profile page without passing `verdictsByTopic`; confirm topic rows are identical to current behavior |
| v0.1.42 published and installable | PROF-03 | npm registry verification | Run `npm view @chrisandrewsedu/ev-ui version` in terminal; then `cd essentials && npm install && npm run dev` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5 minutes
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
