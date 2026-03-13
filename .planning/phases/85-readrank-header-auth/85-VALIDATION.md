---
phase: 85
slug: readrank-header-auth
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-12
---

# Phase 85 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None detected (TypeScript + Vite project, no test config found) |
| **Config file** | None — no Wave 0 needed |
| **Quick run command** | `cd EV-ReadRank && npm run build` |
| **Full suite command** | `cd EV-ReadRank && npm run build` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd EV-ReadRank && npm run build`
- **After every plan wave:** Run `cd EV-ReadRank && npm run build`
- **Before `/gsd:verify-work`:** Build green + human checkpoint confirming header auth state
- **Max feedback latency:** ~10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 85-01-01 | 01 | 1 | RR-01 | build | `cd EV-ReadRank && npm run build` | ✅ | ⬜ pending |
| 85-01-02 | 01 | 1 | RR-01, RR-02, RR-03 | build | `cd EV-ReadRank && npm run build` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None required for Phase 85 — no new test infrastructure needed. The phase is two targeted file edits with TypeScript compilation as the automated gate.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Logged-in user sees username + logout in header | RR-01 | No test framework installed; visual auth state requires live session | 1. Start dev server `npm run dev`. 2. Log in via compass.empowered.vote/login. 3. Return to ReadRank. 4. Verify username appears in header dropdown |
| Logged-out user sees "Sign in" link in header | RR-02 | No test framework installed; visual auth state requires live session | 1. Start dev server. 2. Ensure not logged in. 3. Verify "Sign in" link appears in header |
| Logout clears session and header switches to "Sign in" | RR-03 | Session state requires live backend | 1. Log in. 2. Click Sign out in header. 3. Verify header switches to "Sign in" state |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
