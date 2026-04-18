---
phase: 119
slug: read-rank-location-filter-repair
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-15
---

# Phase 119 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest |
| **Config file** | `read-rank/vitest.config.ts` or "none — Wave 0 installs" |
| **Quick run command** | `cd read-rank && npx vitest run --reporter=verbose` |
| **Full suite command** | `cd read-rank && npx vitest run` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd read-rank && npx vitest run --reporter=verbose`
- **After every plan wave:** Run `cd read-rank && npx vitest run`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 119-01-01 | 01 | 0 | RR-03 | — | N/A | manual | DB query + curl | N/A | ⬜ pending |
| 119-01-02 | 01 | 1 | RR-03 | — | N/A | integration | curl CORS check | N/A | ⬜ pending |
| 119-02-01 | 02 | 1 | RR-03, RR-04 | — | N/A | unit | `npx vitest run` | ❌ W0 | ⬜ pending |
| 119-03-01 | 03 | 2 | RR-04 | — | N/A | manual | Production smoke test | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] DB audit: verify Monroe County politicians have quotes with matching `candidateId` and `topic_key`
- [ ] CORS verification: confirm `readrank.empowered.vote` in `CORS_ORIGIN` env var
- [ ] API URL verification: confirm which `VITE_API_URL` is active in production

*Diagnostic wave — no code changes, only data/config verification.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Location filter scopes quotes to Monroe County | RR-03 | End-to-end browser test on production | Enter Kirkwood Ave Bloomington address, verify only local candidates shown |
| Both address and browse modes work | RR-04 | Two distinct user flows on production | Test address mode via Google Places, test browse mode via State→Area dropdowns |
| Zero-state message appears | RR-04 | UI behavior requiring visual verification | Enter address with no matching quotes, verify empty-state message and clear button |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
