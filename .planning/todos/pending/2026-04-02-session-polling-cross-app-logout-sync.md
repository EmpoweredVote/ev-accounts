---
created: 2026-04-02T00:00
title: Add session polling for cross-app logout sync
area: api
files:
  - backend/src/routes/auth.ts
---

## Problem

Logout clears the `ev_session` cookie but does not invalidate active in-memory sessions in apps already loaded in the browser. Apps visited *before* logout stay authenticated until refreshed; only apps visited *after* logout correctly show unauthenticated state. Cross-subdomain localStorage/BroadcastChannel don't work across `*.empowered.vote` subdomains.

## Solution

Add periodic polling of `GET /api/auth/session` (every 30–60 seconds) in each app. When a 401 is returned, the app clears local auth state and shows unauthenticated UI. ~20 lines per app, no browser API edge cases.

Apps to update:
- app.empowered.vote (Profile Hub)
- essentials.empowered.vote
- compass.empowered.vote
- ctc.empowered.vote
- quests.empowered.vote
- civicspaces.empowered.vote
- treasurytracker.empowered.vote (once it joins the accounts system)

**Why:** Treasury Tracker not yet on accounts system — add it to the polling implementation when it integrates.
**How to apply:** Implement as a shared hook or utility if apps share a component library; otherwise add per-app. Polling should only run when user appears authenticated (skip for unauthenticated sessions to avoid unnecessary API load).
