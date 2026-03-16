---
phase: 90
slug: location-based-filtering
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 90 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest |
| **Config file** | EV-readrank/vitest.config.ts or "none — Wave 0 installs" |
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
| 90-01-01 | 01 | 1 | LOC-01 | unit | `npx vitest run` | ❌ W0 | ⬜ pending |
| 90-01-02 | 01 | 1 | LOC-02 | unit | `npx vitest run` | ❌ W0 | ⬜ pending |
| 90-01-03 | 01 | 1 | LOC-03 | unit | `npx vitest run` | ❌ W0 | ⬜ pending |
| 90-01-04 | 01 | 1 | LOC-04 | unit | `npx vitest run` | ❌ W0 | ⬜ pending |
| 90-01-05 | 01 | 1 | LOC-05 | unit | `npx vitest run` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Vitest installed and configured in EV-readrank (if not already)
- [ ] Test stubs for location filter logic (filtering, threshold, clear)
- [ ] Test stubs for useGooglePlacesAutocomplete TypeScript hook
- [ ] Test stubs for cross-app address query param parsing

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Google Maps autocomplete suggestions appear | LOC-01 | Requires Google Maps API key and browser | Type address in input, verify dropdown suggestions |
| Cross-app navigation from Essentials | LOC-04 | Requires two running apps with address state | Search address in Essentials, click Read & Rank nav link, verify hub pre-filtered |
| Filter chip UX (collapse, clear) | LOC-05 | Visual/interaction behavior | Enter address, verify chip shows, click X to clear, verify full list restored |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
