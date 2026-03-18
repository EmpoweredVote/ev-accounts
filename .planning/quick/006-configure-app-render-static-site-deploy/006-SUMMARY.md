---
phase: quick-006
plan: "006"
subsystem: infra
tags: [render, vite, static-site, deploy, react]

# Dependency graph
requires: []
provides:
  - render.yaml static site service config for empowered-vote-app
  - app/.env.production VITE_API_URL fallback for manual builds
affects: [render-deploy, profile.empowered.vote, app-frontend]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "render.yaml: static site with SPA rewrite rule for React Router client-side routing"
    - "VITE_API_URL injected at build time via Render envVars + .env.production fallback"

key-files:
  created:
    - render.yaml
    - app/.env.production
  modified: []

key-decisions:
  - "runtime: static (not node web service) — Render serves pre-built dist/ directly"
  - "SPA rewrite rule /* -> /index.html required for React Router to work on direct URL access"
  - "NODE_VERSION: 20 pinned to ensure consistent build environment"
  - "Do NOT include admin app or backend API in render.yaml — those are managed via Render dashboard separately"

patterns-established:
  - "Static site deploy: buildCommand runs from repo root, staticPublishPath is relative to repo root"

# Metrics
duration: 1min
completed: 2026-03-18
---

# Quick Task 006: Configure App Render Static Site Deploy

**render.yaml with empowered-vote-app static site service pointing at ev-accounts-api.onrender.com, with SPA rewrite rule for React Router**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-18T23:27:19Z
- **Completed:** 2026-03-18T23:28:12Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments
- Created render.yaml at repo root with static site service entry for the /app frontend
- Set VITE_API_URL and NODE_VERSION env vars in render.yaml for Render builds
- Created app/.env.production as fallback for local production builds
- Added SPA rewrite rule (/* -> /index.html) so React Router works on direct URL access
- Verified production build completes successfully with the new config

## Task Commits

1. **Task 1: Create render.yaml and app/.env.production** - `df0a9b7` (chore)

## Files Created/Modified
- `render.yaml` - Render static site service config for empowered-vote-app; builds /app and serves dist/ with SPA rewrite
- `app/.env.production` - VITE_API_URL fallback for non-Render local production builds

## Decisions Made
- `runtime: static` chosen (not a node web service) — Render serves the pre-built Vite dist/ directory directly
- SPA rewrite rule `/* -> /index.html` required for React Router — without it, direct URL access to any route other than `/` returns 404
- Only the /app frontend is in render.yaml; admin UI and backend API remain in their existing Render dashboard services

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

**To deploy on Render:**
1. Connect the GitHub repo to Render
2. "New Static Site" -> select existing service or "From render.yaml"
3. Render will detect render.yaml and configure empowered-vote-app automatically
4. Set custom domain `profile.empowered.vote` in the Render dashboard after deploy

No env vars need manual entry — VITE_API_URL is defined in render.yaml.

## Next Phase Readiness
- render.yaml is ready to connect to Render dashboard for auto-deploy of profile.empowered.vote
- app/.env.production ensures `npm run build` works locally without needing Render
- No source code changes required — api.ts already reads VITE_API_URL correctly

---
*Phase: quick-006*
*Completed: 2026-03-18*
