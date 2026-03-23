---
phase: 42-decommission-and-dns-cutover
plan: 01
status: complete
commit: 72b0970
date: 2026-03-23
---

# Phase 42 Plan 01 Summary — Runbook + URL Cleanup

## What Was Done

**Task 1: Stale URL Cleanup**

Replaced all `https://ev-accounts-api.onrender.com` references with `https://accounts.empowered.vote` in:
- `app/.env.production` — `VITE_API_URL` now canonical domain
- `render.yaml` — static site env var updated
- `docs/SMOKE-TEST-INTEG.md` — all curl examples updated
- `docs/ONBOARDING-VQ.md` — header URL and fetch examples updated
- `docs/ONBOARDING-CTC.md` — header URL and all env var table rows updated

Remaining occurrences of the old URL:
- `backend/.env` — untracked local file; not a source/doc file (expected)
- `docs/DECOMMISSION-RUNBOOK.md` — mentions URL only as context ("look for this in CTC/VQ service env vars"), not as an application endpoint

**Task 2: Decommission Runbook**

Created `docs/DECOMMISSION-RUNBOOK.md` (284 lines) — a standalone operational document covering:

1. Prerequisites (Phase 40 + 41 complete, accounts.empowered.vote serving traffic)
2. Pre-Flight Checklist (T-48h) — Route 53 access, Render custom domain, all 4 Netlify frontends, health check
3. Lower DNS TTL to 300s (T-24h) — step-by-step Route 53 instructions
4. Traffic Gate Verification (T-0) — Render logs procedure, accept/defer criteria
5. DNS Flip — Route 53 steps, curl health + CORS verification commands
6. Post-Flip Monitoring (T-0 to T+4h) — rollback triggers (any new 5xx)
7. Scale Go Server to Zero (T+4h) — Render suspension steps
8. Raise DNS TTL to 3600 (T+24h)
9. Archive Go Repo (T+1 week) — GitHub archive procedure
10. Post-Cutover Cleanup — VQ/CTC stale URL updates, trivia_service Supavisor fix

## Requirements Coverage

- **CONS-20** — DNS cutover plan documented (hard flip via Route 53)
- **CONS-21** — Go server scale-to-zero procedure documented (Section 6)
- **CONS-22** — Post-cutover cleanup items documented (Section 9); stale internal URLs removed from tracked files

## What Remains

Plan 02 is a human-action checkpoint — Chris must execute the runbook (multi-day operation):
- Day 0: Pre-flight + lower TTL
- Day 1: Traffic gate + DNS flip + monitoring
- Day 1 T+4h: Scale Go server to zero
- Day 2 T+24h: Raise TTL
- Day 8: Archive Go repo
