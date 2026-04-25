---
phase: 120
slug: contested-race-bio-photo-authoring
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-16
---

# Phase 120 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest |
| **Config file** | `ev-accounts/backend/vitest.config.ts` |
| **Quick run command** | `cd ev-accounts/backend && npm test` |
| **Full suite command** | `cd ev-accounts/backend && npm test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd ev-accounts/backend && npm test`
- **After every plan wave:** Run `cd ev-accounts/backend && npm test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 120-01-01 | 01 | 1 | CONT-01 | — | N/A | integration | `cd ev-accounts/backend && npm test` | ⬜ W0 | ⬜ pending |
| 120-01-02 | 01 | 1 | CONT-02 | — | N/A | manual | DB query + visual check | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. This is primarily a content authoring phase — validation is via DB queries and visual profile page checks.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Bios render on profile pages | CONT-01 | Requires visual check of PoliticianProfile component | Load essentials profile page for a contested-race candidate, verify bio_text displays |
| Photos render on profile pages | CONT-02 | Requires visual check of headshot rendering | Load essentials profile page, verify headshot image loads from Supabase CDN |
| Bio tone is neutral/factual | CONT-01 | Subjective review | Read each bio in REVIEW-DATA.md before import, verify neutral tone |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
