---
phase: quick-12
plan: 1
subsystem: infra
tags: [vite, react, netlify, github, monorepo, treasury-tracker, empowered-badges, fallacy-finders]

requires: []
provides:
  - "Standalone treasury-tracker repo on GitHub (chrisandrewsedu)"
  - "Standalone empowered-badges repo on GitHub (chrisandrewsedu)"
  - "Standalone fallacy-finders repo on GitHub (chrisandrewsedu)"
  - "EV-prototypes cleaned to only build read-rank and data-entry"
affects: [ev-prototypes, netlify-deploys]

tech-stack:
  added: []
  patterns:
    - "Standalone repo pattern: git init -> gh repo create --private --source=. --push"
    - "Netlify SPA routing with netlify.toml at repo root"
    - "Vite base path '/' for standalone vs nested deployment"

key-files:
  created:
    - /Users/chrisandrews/Documents/GitHub/treasury-tracker/netlify.toml
    - /Users/chrisandrews/Documents/GitHub/treasury-tracker/vite.config.ts
    - /Users/chrisandrews/Documents/GitHub/empowered-badges/netlify.toml
    - /Users/chrisandrews/Documents/GitHub/empowered-badges/vite.config.ts
    - /Users/chrisandrews/Documents/GitHub/fallacy-finders/netlify.toml
    - /Users/chrisandrews/Documents/GitHub/fallacy-finders/vite.config.js
  modified:
    - /Users/chrisandrews/Documents/GitHub/EV-prototypes/package.json
    - /Users/chrisandrews/Documents/GitHub/EV-prototypes/netlify.toml
    - /Users/chrisandrews/Documents/GitHub/EV-prototypes/index.html

key-decisions:
  - "Original directories preserved in EV-prototypes until standalone Netlify deploys are verified"
  - "Treasury-tracker netlify.toml includes API proxy redirect to ev-backend-h3n8.onrender.com"
  - "All three repos created as private under chrisandrewsedu"

patterns-established:
  - "Standalone extract pattern: copy, clean node_modules/dist, update vite base, add netlify.toml, git init, gh repo create"

requirements-completed: []

duration: 15min
completed: 2026-03-13
---

# Quick Task 12: Extract Treasury Tracker, Empowered Badges, Fallacy Finders

**Three EV-prototypes sub-projects extracted to standalone GitHub repos with root-level Vite base paths and Netlify SPA routing, EV-prototypes build:all reduced to read-rank and data-entry only**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-03-13
- **Tasks:** 2 of 2 (checkpoint awaiting human verification)
- **Files modified:** 6 modified, 6 created across 4 repos

## Accomplishments

- Created 3 standalone private GitHub repos under chrisandrewsedu: treasury-tracker, empowered-badges, fallacy-finders
- Updated vite base paths from nested (`/{project}/dist/`) to root-level (`/`) in all three
- Added netlify.toml to each (treasury-tracker includes API proxy redirect)
- Verified all three build successfully with `npm run build`
- EV-prototypes package.json build:all now only runs build:read-rank and build:data-entry
- Removed treasury-tracker and empowered-badges feature cards from EV-prototypes index.html
- Removed treasury-tracker, empowered-badges, fallacy-finders Netlify redirects from EV-prototypes netlify.toml

## Task Commits

1. **Task 1: Create standalone repos** - Committed to each new repo (ca987ca / 3f685c0 / a71f1f5) (chore)
2. **Task 2: Clean up EV-prototypes** - `aa5202c` (chore)

## Files Created/Modified

### New standalone repos (each committed and pushed to GitHub)

- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/` - Standalone repo at https://github.com/chrisandrewsedu/treasury-tracker
  - `vite.config.ts` - base changed to '/'
  - `netlify.toml` - SPA routing + API proxy to ev-backend-h3n8.onrender.com
- `/Users/chrisandrews/Documents/GitHub/empowered-badges/` - Standalone repo at https://github.com/chrisandrewsedu/empowered-badges
  - `vite.config.ts` - base changed to '/'
  - `netlify.toml` - SPA routing
- `/Users/chrisandrews/Documents/GitHub/fallacy-finders/` - Standalone repo at https://github.com/chrisandrewsedu/fallacy-finders
  - `vite.config.js` - base changed to '/'
  - `netlify.toml` - SPA routing

### EV-prototypes (modified)

- `package.json` - Removed build:treasury, build:badges, build:fallacy-finders; build:all now only builds read-rank and data-entry
- `netlify.toml` - Removed redirects for /treasury-tracker/*, /empowered-badges/*, /fallacy-finders/*
- `index.html` - Removed Treasury Tracker and Empowered Badges feature cards (fallacy-finders was not in index.html)

## Decisions Made

- Original sub-project directories remain in EV-prototypes until standalone Netlify deploys are verified working — safe to delete after that
- All repos created as private (can be made public later if desired)
- Treasury-tracker's API proxy preserved in its standalone netlify.toml so EV-Backend connectivity works immediately

## Deviations from Plan

None - plan executed exactly as written.

Note: fallacy-finders was not present as a card in EV-prototypes/index.html (only in package.json scripts and netlify.toml redirects), so only treasury-tracker and empowered-badges cards were removed from index.html.

## Issues Encountered

None — all three projects built cleanly on first attempt.

## Next Steps

- Connect each standalone repo to Netlify for independent deployment
- Once standalone deploys are verified, delete the original sub-directories from EV-prototypes: `rm -rf EV-prototypes/treasury-tracker EV-prototypes/empowered-badges EV-prototypes/fallacy-finders`

---
*Quick Task: 12*
*Completed: 2026-03-13*
