---
phase: 45-legacy-cleanup
plan: 01
subsystem: api
tags: [go, compass, seeds, cleanup]

# Dependency graph
requires: []
provides:
  - "Deleted internal/seeds/ package (topics.go, categories.go, seeds.go)"
  - "Deleted internal/compass/data/topics.json (50-topic deprecated data)"
  - "Deleted cmd/seed/main.go (commented-out stub)"
  - "cmd/seed/compass_csv_seeder.go is the sole seeder going forward"
affects: [46-compass-research, 47-compass-research, 48-compass-research, 50-compass-import]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CSV-based seeder (compass_csv_seeder.go) is the sole seeder for compass data"

key-files:
  created: []
  modified:
    - "EV-Backend/cmd/seed/compass_csv_seeder.go (preserved, unchanged)"
    - "EV-Backend/Empowered Compass Issues and Stances Top 20.csv (preserved, unchanged)"

key-decisions:
  - "Deleted cmd/seed/main.go stub entirely rather than emptying it — compass_csv_seeder.go already owns func main() in the same package, so the stub was both dead code and a potential build conflict"

patterns-established:
  - "Single seeder pattern: compass_csv_seeder.go with --csv, --confirm, --dry-run flags is the canonical way to seed compass data"

requirements-completed: [CLEAN-01, CLEAN-02, CLEAN-03, CLEAN-04]

# Metrics
duration: 2min
completed: 2026-02-26
---

# Phase 45 Plan 01: Legacy Cleanup Summary

**Removed 5 deprecated files (2584 lines) — internal/seeds/ package and 50-topic topics.json — leaving compass_csv_seeder.go as the sole seeder**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-26T15:43:48Z
- **Completed:** 2026-02-26T15:45:41Z
- **Tasks:** 2
- **Files modified:** 5 deleted, 0 modified

## Accomplishments
- Deleted the entire `internal/seeds/` package (topics.go, categories.go, seeds.go) — 233 lines of dead Go code
- Deleted `internal/compass/data/topics.json` — the 2351-line 50-topic deprecated JSON data file
- Deleted `cmd/seed/main.go` — the fully commented-out stub that referenced the old seeds package
- Verified `go build ./...` compiles cleanly with zero errors after all deletions
- Confirmed zero remaining references to `internal/seeds`, `topics.json`, or any seed function names across all `.go` files

## Task Commits

Each task was committed atomically (in EV-Backend git repo):

1. **Task 1: Delete deprecated seed files and old topics.json** - `5f3498c` (chore)
2. **Task 2: Verify no remaining references to deleted code** - (no files changed, verification only)

## Files Deleted
- `EV-Backend/internal/seeds/topics.go` - Old SeedTopics() that read the 50-topic JSON
- `EV-Backend/internal/seeds/categories.go` - Hardcoded 50-topic category map and SeedCategories()/SeedTopicCategories()
- `EV-Backend/internal/seeds/seeds.go` - SeedAll() orchestrator
- `EV-Backend/internal/compass/data/topics.json` - 2351-line 50-topic JSON data file
- `EV-Backend/cmd/seed/main.go` - Fully commented-out stub referencing internal/seeds

## Files Preserved (Unchanged)
- `EV-Backend/cmd/seed/compass_csv_seeder.go` - CSV-based seeder with main(), sole seeder going forward
- `EV-Backend/Empowered Compass Issues and Stances Top 20.csv` - 21-topic/5-stance source of truth (21 lines: 1 header + 20 rows)

## Decisions Made
- Deleted `cmd/seed/main.go` stub entirely rather than leaving it empty: `compass_csv_seeder.go` in the same package already defines `func main()`, making the stub a potential build conflict. The plan called for deletion and this was confirmed correct.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- EV-Backend has its own nested git repository (separate from the workspace root repo). Commits were made to the EV-Backend repo directly. This is expected per the project's isolation strategy documented in CLAUDE.md.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Repository is clean: only the CSV seeder path exists for compass data
- Phases 46-48 (compass research) can proceed without confusion about which seeder to use
- Phase 50 (compass import) will use `compass_csv_seeder.go` with the updated CSV from research phases
- Before starting Phase 46, verify 21 topic_keys from DB as noted in STATE.md blockers

---
*Phase: 45-legacy-cleanup*
*Completed: 2026-02-26*
