---
phase: 128
slug: empty-non-compass-variants
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-25
---

# Phase 128 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest (essentials) |
| **Config file** | `vite.config.js` (essentials) — Vitest runs via Vite |
| **Quick run command** | `cd essentials && npx vitest run src/lib/classify` |
| **Full suite command** | `cd essentials && npm test` |
| **Estimated runtime** | ~5 seconds |

> Note: ev-ui has no test infrastructure. Tests for new `computeVariant` logic live in essentials.

---

## Sampling Rate

- **After every task commit:** Run `cd essentials && npx vitest run src/lib/classify`
- **After every plan wave:** Run `cd essentials && npm test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 128-01-01 | Wave 0 | 0 | STATE-01,02,03 | — | N/A | unit | `cd essentials && npx vitest run src/lib/classify` | ❌ W0 | ⬜ pending |
| 128-02-01 | ev-ui | 1 | STATE-01 | — | N/A | visual/smoke | manual — verify CTA in prototype harness | N/A | ⬜ pending |
| 128-02-02 | ev-ui | 1 | STATE-02,03 | — | N/A | visual/smoke | manual — verify plate in prototype harness | N/A | ⬜ pending |
| 128-03-01 | Prototype | 2 | STATE-01,02,03 | — | N/A | smoke | `cd essentials && npm test` | ✅ | ⬜ pending |
| 128-04-01 | Release | 3 | All | — | N/A | integration | verify npm version bump + auto-PR in consumers | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `essentials/src/lib/classify.test.js` (append to or create) — unit tests for `computeVariant` covering STATE-01, STATE-02, STATE-03
- [ ] `computeVariant` exported from `essentials/src/lib/classify.js` so tests can import it

*Existing infrastructure: `essentials/src/lib/groupHierarchy.test.js` uses Vitest — no new framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CTA renders at `bottom: 12px`, `height: 44px`, pill shape | STATE-01 | Visual rendering — no jsdom setup in ev-ui | Open Prototype in browser; verify "Build your compass" button position + styling on an empty-variant card |
| Plate text centered in 260×260 slot | STATE-02, STATE-03 | Visual rendering | Open Prototype; verify "Compass currently unavailable for this role." centered in both admin and judicial cards |
| Retention judge dual-appearance preserved | STATE-03 | Filter-layer behavior unchanged | Verify retention judges appear in both elected and appointed filter views on representatives page |
| CTA opens CompassV2 in new tab with `?return=` param | STATE-01 | Cross-app integration | Click "Build your compass" → verify new tab opens to `compass.empowered.vote/?return=...` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
