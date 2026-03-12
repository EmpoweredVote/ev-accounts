---
phase: 77
slug: standalone-extraction
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-11
---

# Phase 77 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — TypeScript compilation via `tsc -b` is the only automated check |
| **Config file** | `tsconfig.app.json`, `tsconfig.node.json` |
| **Quick run command** | `npm run build` |
| **Full suite command** | `npm run build` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `npm run build`
- **After every plan wave:** Run `npm run build` + manual smoke of all three routes
- **Before `/gsd:verify-work`:** Full suite must be green + all manual checks passing
- **Max feedback latency:** 15 seconds (build) + manual smoke

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 77-01-01 | 01 | 1 | EXTR-01 | manual | `gh repo view chrisandrewsedu/EV-readrank` | N/A | ⬜ pending |
| 77-01-02 | 01 | 1 | EXTR-04 | compile | `npm run build` | ❌ Wave 0 | ⬜ pending |
| 77-01-03 | 01 | 1 | EXTR-05 | compile | `npm run build` | ❌ Wave 0 | ⬜ pending |
| 77-02-01 | 02 | 2 | EXTR-02 | smoke (manual) | Visit `https://readrank.empowered.vote` in browser | N/A | ⬜ pending |
| 77-02-02 | 02 | 2 | EXTR-03 | smoke (manual) | `curl -H "Origin: https://readrank.empowered.vote" https://api.empowered.vote/essentials/quotes -I` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extracted repo must exist with source copied before any build checks run
- [ ] `npm install` must succeed (requires `NPM_TOKEN` in Cloudflare Pages env before CI trigger)

*No test framework installation needed — TypeScript + Vite build is the validation mechanism.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| All 3 routes load at `readrank.empowered.vote` | EXTR-02 | Requires live Cloudflare Pages deployment | Visit `/`, `/candidate/:id/alignment`, `/animation-options`; confirm each renders correctly |
| API calls succeed from new domain | EXTR-03 | Requires live backend CORS + deployment | Open network tab; navigate to alignment page; confirm `api.empowered.vote` calls return 200 |
| Zustand key is `ev_readrank` | EXTR-05 | localStorage inspection | Open DevTools > Application > Local Storage; confirm key `ev_readrank` present, `readrank-storage` absent |
| Cloudflare Pages CI build passes | EXTR-02 | Requires CF Pages dashboard | Check build log in Cloudflare Pages dashboard for success including `npm install` of ev-ui |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
