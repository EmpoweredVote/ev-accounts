---
phase: 104
slug: compass-first-card-prototype
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-04
---

# Phase 104 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — essentials has no test framework; this is a visual prototype phase |
| **Config file** | none |
| **Quick run command** | `cd essentials && npm run build` |
| **Full suite command** | `cd essentials && npm run build` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd essentials && npm run build`
- **After every plan wave:** Run `cd essentials && npm run build`
- **Before `/gsd:verify-work`:** Build must succeed + manual visual check
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 104-01-01 | 01 | 1 | PROTO-01 | build | `cd essentials && npm run build` | N/A | ⬜ pending |
| 104-01-02 | 01 | 1 | PROTO-02 | build | `cd essentials && npm run build` | N/A | ⬜ pending |
| 104-02-01 | 02 | 2 | PROTO-01 | visual | manual — open /prototype route | N/A | ⬜ pending |
| 104-02-02 | 02 | 2 | PROTO-02 | visual | manual — verify 4 distinct radar shapes | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework setup needed — this is a visual prototype phase where the build succeeding and manual visual verification are the appropriate checks.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Radar chart renders as visual anchor on cards | PROTO-01 | Visual/layout — cannot be automated without screenshot testing | Open /prototype, verify radar chart is dominant element above name/title |
| 4 distinct radar polygon shapes visible | PROTO-02 | Visual diversity check | Open /prototype, verify progressive/moderate/conservative/mixed profiles produce different shapes |
| Variant toggle switches between A/B/C layouts | PROTO-01 | Layout comparison — visual only | Click each variant tab, verify column count and card shape changes |
| Dashed outline placeholder for no-data politicians | PROTO-02 | Visual fallback check | Verify any politician without mock data shows dashed outline radar |
| Feature-flagged route (no nav link) | PROTO-01 | Navigation absence check | Verify no link to /prototype in header/sidebar navigation |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: build check after every commit maintains feedback
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
