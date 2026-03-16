---
phase: 86
slug: chrome-cleanup-store-migration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 86 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — TypeScript build check only |
| **Config file** | `EV-readrank/tsconfig.json` |
| **Quick run command** | `cd EV-readrank && npm run build` |
| **Full suite command** | `cd EV-readrank && npm run build` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd EV-readrank && npm run build`
- **After every plan wave:** Run `cd EV-readrank && npm run build`
- **Before `/gsd:verify-work`:** Full build must be green + manual browser checks
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | 01 | 1 | FLOW-06 | build | `cd EV-readrank && npm run build` | ✅ | ⬜ pending |
| TBD | 01 | 1 | CHRM-01 | build | `cd EV-readrank && npm run build` | ✅ | ⬜ pending |
| TBD | 01 | 1 | CHRM-02 | build | `cd EV-readrank && npm run build` | ✅ | ⬜ pending |
| TBD | 01 | 1 | CHRM-03 | build | `cd EV-readrank && npm run build` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework install needed — verification is TypeScript build + manual browser testing.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ProgressHeader not visible anywhere in app | CHRM-01 | Visual DOM check | Navigate all routes, confirm no progress bar |
| /animation-options returns 404 | CHRM-02 | Route check | Navigate to `/animation-options`, confirm 404 |
| "Clear Read & Rank" in profile menu with confirm dialog | CHRM-03 | Interactive UI flow | Click profile → "Clear Read & Rank" → confirm dialog appears → localStorage cleared |
| Returning user with old localStorage (phase:'ranking') lands on hub | FLOW-06 | Requires localStorage manipulation | Set `ev_readrank` in localStorage to `{"state":{"phase":"ranking"},"version":1}`, reload, confirm hub |
| No references to deleted components or old Phase union | FLOW-06 | Build verification | `cd EV-readrank && npm run build` passes cleanly |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
