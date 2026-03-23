---
phase: 40-frontend-auth-updates
plan: 05
status: complete
completed: 2026-03-23
---

# 40-05 Summary: Cutover Runbook

**One-liner:** CUTOVER-RUNBOOK.md created — 10-section runbook covering CORS setup, Netlify env vars, staging verification, production cutover, rollback, and party responsibilities.

## What Was Built

A complete cutover runbook at `.planning/phases/40-frontend-auth-updates/CUTOVER-RUNBOOK.md` (396 lines) documenting the coordinated switchover from Go server cookie auth to ev-accounts Bearer token auth across all four frontend apps.

## Tasks Completed

1. **Create CUTOVER-RUNBOOK.md** — commit `888834a`

## Files Created

- `.planning/phases/40-frontend-auth-updates/CUTOVER-RUNBOOK.md` — 10 sections: CORS_ORIGIN config, Netlify env vars (Chris Andrews), staging checklist per app, production cutover order, rollback plan, known behavior changes, user communication draft, post-cutover monitoring, party responsibility matrix

## Human Verification

Runbook approved and acted on: Chris Andrews completed Section 3.1 (Read & Rank VITE_API_URL in Netlify dashboard) on 2026-03-22. Runbook confirmed accurate and actionable.

## Key Notes

- Read & Rank uses direct API calls — requires VITE_API_URL env var in Netlify dashboard (done by Chris Andrews)
- CompassV2, Essentials, Treasury Tracker use Netlify proxy — no env var change needed, proxy in netlify.toml takes effect on PR merge
- CORS_ORIGIN on Render must include all four frontend domains before cutover
- Rollback: revert netlify.toml proxy target to Go server (~5-10 min)
