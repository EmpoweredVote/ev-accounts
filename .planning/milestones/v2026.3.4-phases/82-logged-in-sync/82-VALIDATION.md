---
phase: 82
slug: logged-in-sync
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-12
---

# Phase 82 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — no automated test suite in EV-readrank, essentials, or EV-Backend |
| **Config file** | none |
| **Quick run command** | `cd /Users/chrisandrews/Documents/GitHub/EV-readrank && npm run build` |
| **Full suite command** | `cd /Users/chrisandrews/Documents/GitHub/EV-readrank && npm run build && cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build ./...` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `npm run build` in the relevant repo (TypeScript compile verifies no type errors)
- **After every plan wave:** Run full suite command (both repos build clean)
- **Before `/gsd:verify-work`:** Full suite must be green + manual smoke test complete
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 82-01-01 | 01 | 1 | SYNC-01 | build | `cd /Users/chrisandrews/Documents/GitHub/EV-readrank && npm run build` | ❌ W0 | ⬜ pending |
| 82-01-02 | 01 | 1 | SYNC-01 | build | `cd /Users/chrisandrews/Documents/GitHub/EV-readrank && npm run build` | ❌ W0 | ⬜ pending |
| 82-01-03 | 01 | 1 | SYNC-01 | manual smoke | See manual procedure below | N/A | ⬜ pending |
| 82-02-01 | 02 | 1 | SYNC-02 | build | `cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build` | ❌ W0 | ⬜ pending |
| 82-02-02 | 02 | 1 | SYNC-02 | manual smoke | See manual procedure below | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `EV-readrank/src/hooks/useAuthState.ts` — new file, covers SYNC-01 auth detection
- [ ] `EV-readrank/src/utils/verdictSync.ts` — new file, covers SYNC-01 POST logic
- [ ] `essentials/src/lib/compass.js` — add `fetchUserVerdicts()` export, covers SYNC-02

*No new test framework needed — build compilation is the automated gate.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Verdicts POSTed when logged-in user completes issue | SYNC-01 | No test framework; requires live auth session | Log in via CompassV2; open Read & Rank; complete rating an issue; check Network tab for POST /compass/verdicts with 2xx response |
| Verdict badges appear on Essentials direct profile visit | SYNC-02 | Requires live auth session and real data | After step above, navigate directly to an Essentials politician profile (no #compass= fragment); expand StanceAccordion topic; verify verdict badges visible |
| Cross-device verdict consistency | SYNC-01 + SYNC-02 | Requires two devices/browsers | Repeat smoke on a different browser/device with same account; verify same badges appear |

### Full Manual Smoke Test Procedure
1. Log in on CompassV2 or any EV app sharing the `api.empowered.vote` cookie domain
2. Open `readrank.empowered.vote` (session cookie should be present)
3. Complete rating an issue (reach results phase)
4. Navigate directly to an Essentials politician profile — **no** `#compass=` fragment in URL
5. Expand a StanceAccordion topic row for a politician with rated quotes
6. Verdict badges should appear (served from API, not fragment)
7. Repeat on a different device/browser with same account to verify cross-device sync

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
