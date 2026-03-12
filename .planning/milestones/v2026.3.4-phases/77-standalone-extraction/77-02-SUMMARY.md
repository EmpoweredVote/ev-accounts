---
phase: 77-standalone-extraction
plan: 02
subsystem: infra
tags: [cloudflare-pages, cors, react, vite, zustand, custom-domain]

# Dependency graph
requires:
  - phase: 77-01
    provides: EmpoweredVote/read-rank standalone repo pushed to GitHub with Cloudflare Pages SPA config
provides:
  - readrank.empowered.vote live on Cloudflare Pages with custom domain
  - CORS allowlist in EV-Backend covering readrank.empowered.vote and readrank-dev.empowered.vote
  - All three Read & Rank routes verified at production domain
affects: [78-visual-polish, 79-verdict-storage, 80-ev-ui-update, 81-fragment-bridge, 82-logged-in-sync]

# Tech tracking
tech-stack:
  added: [cloudflare-pages]
  patterns:
    - "Cloudflare Pages custom domain: auto-provision DNS when domain is already on Cloudflare account"
    - "CORS allowlist: two entries per feature domain (production + dev subdomain)"

key-files:
  created: []
  modified:
    - EV-Backend/internal/middleware/middleware.go

key-decisions:
  - "CF Pages preview builds use random *.pages.dev URLs — no CORS entries needed for those; only production and dev subdomains require allowlist entries"

patterns-established:
  - "New standalone app pattern: CORS backend entry + CF Pages deployment + custom domain in one plan"

requirements-completed: [EXTR-02, EXTR-03]

# Metrics
duration: ~30min (including user-performed CF Pages setup and browser smoke test)
completed: 2026-03-12
---

# Phase 77 Plan 02: Deploy Read & Rank to readrank.empowered.vote Summary

**Backend CORS updated for readrank subdomain and EmpoweredVote/read-rank deployed to Cloudflare Pages with custom domain — all three routes and API access verified at production URL**

## Performance

- **Duration:** ~30 min (including user-performed Cloudflare Pages dashboard setup)
- **Started:** 2026-03-12
- **Completed:** 2026-03-12
- **Tasks:** 3
- **Files modified:** 1 (EV-Backend/internal/middleware/middleware.go)

## Accomplishments
- Added readrank.empowered.vote and readrank-dev.empowered.vote to EV-Backend CORS allowlist and pushed to Render for live deployment
- User configured Cloudflare Pages project (EmpoweredVote/read-rank) with NPM_TOKEN env var and build settings; CF auto-provisioned DNS for custom domain
- Browser smoke test confirmed all three routes load (/, /candidate/:id/alignment, /animation-options), CORS check returned 200, and localStorage key ev_readrank confirmed present

## Task Commits

1. **Task 1: Add readrank subdomain to backend CORS allowlist** - `e59c37e` (feat)
2. **Task 2: Configure Cloudflare Pages deployment** - user dashboard action — deployed live at readrank.empowered.vote
3. **Task 3: Verify all routes and API access at live URL** - verified by user (browser smoke test passed)

**Plan metadata:** (docs commit — see state updates)

## Files Created/Modified
- `EV-Backend/internal/middleware/middleware.go` - Added `https://readrank.empowered.vote` and `https://readrank-dev.empowered.vote` to CORS allowed map

## Decisions Made
- CF Pages preview builds (*.pages.dev) do not require CORS entries because credentials are not sent cross-origin to those random URLs; only the named subdomains need allowlist entries

## Deviations from Plan

None - plan executed exactly as written. Tasks 2 and 3 were checkpoint tasks (human-action and human-verify) that proceeded as designed.

## Issues Encountered
None - Cloudflare auto-provisioned DNS for the custom domain instantly since the empowered.vote domain is already on the account. NPM_TOKEN env var allowed CI to install ev-ui from the GitHub npm registry without errors.

## User Setup Required
None remaining for this plan — Cloudflare Pages is fully configured and live.

## Next Phase Readiness
- readrank.empowered.vote is the permanent production URL for all future phases (78 through 82)
- Phase 78 (visual polish) can begin immediately; all infrastructure is in place
- The readrank-dev.empowered.vote CORS entry is pre-registered for a future staging/preview subdomain if needed

---
*Phase: 77-standalone-extraction*
*Completed: 2026-03-12*
