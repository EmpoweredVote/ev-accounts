---
phase: 77-standalone-extraction
plan: 01
subsystem: infra
tags: [react, vite, zustand, cloudflare-pages, ev-ui, typescript]

# Dependency graph
requires: []
provides:
  - EV-readrank standalone repo on GitHub (EmpoweredVote/read-rank)
  - Vite config with base '/' and local ev-ui alias
  - BrowserRouter basename="/" for domain root deploy
  - Zustand persist key renamed to ev_readrank (version 1, migrate passthrough)
  - Cloudflare Pages SPA routing via public/_redirects
  - .npmrc with NPM_TOKEN for GitHub npm registry
affects: [78-visual-polish, 79-verdict-storage, 80-ev-ui-update, 81-fragment-bridge, 82-logged-in-sync]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cloudflare Pages SPA routing: public/_redirects with /* /index.html 200"
    - "Local ev-ui alias in vite.config.ts: fs.existsSync check against ../ev-ui/dist"
    - "Zustand persist versioning: version+migrate for storage key renames"

key-files:
  created:
    - EV-readrank/vite.config.ts
    - EV-readrank/public/_redirects
    - EV-readrank/.npmrc
  modified:
    - EV-readrank/package.json
    - EV-readrank/src/App.tsx
    - EV-readrank/src/store/useReadRankStore.ts

key-decisions:
  - "Keep src/types/ev-ui.d.ts manual shim — ev-ui 0.1.41 ships no .d.ts files in its dist/"
  - "migrate function uses ReadRankState cast (not ReturnType<typeof useReadRankStore.getState>) to avoid circular init reference"

patterns-established:
  - "Cloudflare Pages SPA: _redirects in public/ copied verbatim to dist/"
  - "Local ev-ui dev alias: conditional on fs.existsSync, no config flag needed"

requirements-completed: [EXTR-01, EXTR-04, EXTR-05]

# Metrics
duration: 3min
completed: 2026-03-12
---

# Phase 77 Plan 01: Standalone Extraction Summary

**Read & Rank extracted from EV-prototypes monorepo into EmpoweredVote/read-rank with four targeted config fixes for Cloudflare Pages domain-root deployment**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-12T01:57:04Z
- **Completed:** 2026-03-12T01:59:55Z
- **Tasks:** 2
- **Files modified:** 6 (plus 56 files created in new repo)

## Accomplishments
- Created EmpoweredVote/read-rank public GitHub repo and populated it with full Read & Rank source
- Applied all four targeted config changes (vite base, basename, persist key, ev-ui version) with zero behavior changes
- Build passes cleanly: TypeScript clean, Vite succeeds, dist/ contains _redirects for Cloudflare Pages SPA routing
- Commit pushed to EmpoweredVote/read-rank main branch

## Task Commits

Each task was committed atomically in the EV-readrank repo:

1. **Task 1 + Task 2: Extract Read & Rank as standalone app** - `64af700` (feat)

**Plan metadata:** (docs commit — see state updates)

## Files Created/Modified
- `EV-readrank/package.json` - Name changed to ev-readrank, ev-ui bumped to ^0.1.41
- `EV-readrank/vite.config.ts` - base: '/', local ev-ui alias, dedupe config
- `EV-readrank/src/App.tsx` - BrowserRouter basename changed from /read-rank/dist to /
- `EV-readrank/src/store/useReadRankStore.ts` - persist name: ev_readrank, version: 1, migrate passthrough
- `EV-readrank/public/_redirects` - Cloudflare Pages SPA fallback: /* /index.html 200
- `EV-readrank/.npmrc` - GitHub npm registry auth for @chrisandrewsedu/ev-ui

## Decisions Made
- Kept `src/types/ev-ui.d.ts` manual shim — ev-ui 0.1.41 package ships only JS bundles, no `.d.ts` files
- Used `ReadRankState` cast in migrate function instead of `ReturnType<typeof useReadRankStore.getState>` to avoid TypeScript circular initializer error

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed circular type reference in Zustand persist migrate function**
- **Found during:** Task 1 (build verification)
- **Issue:** Plan's migrate template used `ReturnType<typeof useReadRankStore.getState>` which caused `TS7022: 'useReadRankStore' implicitly has type 'any'` — circular reference at store initialization
- **Fix:** Changed cast to `ReadRankState` (already in scope), which resolves identically at runtime
- **Files modified:** EV-readrank/src/store/useReadRankStore.ts
- **Verification:** Build exits 0, no TypeScript errors
- **Committed in:** 64af700 (Task 1+2 combined commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 bug)
**Impact on plan:** Required for TypeScript build to pass. One-line fix, no behavior change.

## Issues Encountered
- SSH key not configured for EmpoweredVote org — used HTTPS clone instead. Push succeeded via HTTPS.

## User Setup Required
- `NPM_TOKEN` environment variable must be added to Cloudflare Pages project settings before first CI build (already documented in STATE.md blockers)

## Next Phase Readiness
- EV-readrank repo is ready for Phase 78 (visual polish)
- Cloudflare Pages project connection to EmpoweredVote/read-rank can be configured now
- NPM_TOKEN must be set in Cloudflare Pages env before CI builds will succeed

---
*Phase: 77-standalone-extraction*
*Completed: 2026-03-12*
