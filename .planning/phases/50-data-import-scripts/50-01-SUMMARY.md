---
phase: 50-data-import-scripts
plan: 01
subsystem: api
tags: [go, gorm, postgres, csv, cli, compass, essentials]

# Dependency graph
requires:
  - phase: 49-quote-collection
    provides: validated stance_research.csv with 455 data rows ready for DB import
  - phase: 48-local-officials-research
    provides: complete politician roster in essentials.politicians table
provides:
  - CLI subcommand ./server import-stances that loads stance CSV into compass.answers and compass.contexts
  - stanceimport Go package with ParseCSV and Run functions
  - Upsert semantics for idempotent re-runs of stance data import
affects: [phase-50-02, phase-50-03, compass-data-availability]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - CLI subcommand pattern in main.go: check os.Args after Init() calls, before HTTP router setup
    - Standalone import package uses db.DB global rather than opening new connection
    - Ambiguous name detection via two-pass politician map build

key-files:
  created:
    - EV-Backend/internal/stanceimport/csv.go
    - EV-Backend/internal/stanceimport/import.go
  modified:
    - EV-Backend/main.go

key-decisions:
  - "CLI subcommand placed after all Init() calls so tables are migrated and DB is ready before import runs"
  - "stanceimport package uses db.DB global connection — no separate DB open needed"
  - "Two-pass ambiguous name detection: count first, then build maps; ambiguousNames set catches duplicates the map would silently overwrite"
  - "DryRun mode validates all rows and resolves IDs but skips DB writes entirely"
  - "Context upsert failure after answer upsert does not skip the row — answer row is preserved"

patterns-established:
  - "CLI subcommand pattern: os.Args check after Init() calls in main.go, os.Exit(0) on success"
  - "Stance import package: load reference data (topics, politicians) into maps, then iterate CSV rows with row-level error accumulation"

requirements-completed: [IMPORT-01, IMPORT-03]

# Metrics
duration: 2min
completed: 2026-02-27
---

# Phase 50 Plan 1: Stance Import CLI Summary

**`./server import-stances` CLI subcommand upserts 455 stance rows from CSV into compass.answers and compass.contexts with politician/topic ID resolution, ambiguous name detection, and dry-run support**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-27T00:43:00Z
- **Completed:** 2026-02-27T00:45:01Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Created `internal/stanceimport` package with `ParseCSV` (LazyQuotes, column-index map) and `Run` (full upsert pipeline)
- Implemented two-pass ambiguous politician name detection to safely skip rows where full_name matches multiple DB records
- Wired `import-stances` CLI subcommand into `main.go` after all `Init()` calls; server behavior unchanged when no subcommand provided

## Task Commits

Each task was committed atomically in the EV-Backend repo:

1. **Task 1: Create stance import package** - `bda2aa2` (feat)
2. **Task 2: Wire CLI subcommand into main.go** - `1ae7837` (feat)

## Files Created/Modified
- `EV-Backend/internal/stanceimport/csv.go` - StanceRow struct and ParseCSV function with LazyQuotes
- `EV-Backend/internal/stanceimport/import.go` - Config, ImportResult, Run() with full validation/upsert pipeline
- `EV-Backend/main.go` - Added stanceimport import and CLI subcommand dispatch block

## Decisions Made
- CLI subcommand check placed after all `Init()` calls so schema migrations have run and `db.DB` is ready before any import logic executes
- The `stanceimport` package uses the global `db.DB` rather than opening its own connection — consistent with all other internal packages
- Ambiguous name detection uses two passes: first build `nameCount map[string]int`, then mark any name with count > 1 as ambiguous. This is the safety net for the `byName` map which silently overwrites on duplicates
- Context upsert failure logs an error but does not skip/undo the answer row — partial data is better than no data
- `--dry-run` flag validates all rows (including DB lookups for topics/politicians) but performs zero writes, allowing safe pre-flight checks

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
- EV-Backend directory has its own nested git repo (not tracked by the workspace root repo), so all commits were made via `cd EV-Backend && git commit`. This is the expected project structure.

## User Setup Required
None — no external service configuration required. To run the import:

```bash
cd EV-Backend
go build -o server .
./server import-stances --dry-run   # dry-run validation
./server import-stances             # full import
```

## Next Phase Readiness
- Phase 50-02 (Quote Import CLI) can proceed: same stanceimport package pattern applies to quote_collection.csv
- Phase 50-03 (Budget Import CLI) can proceed: same CLI subcommand pattern applies
- compass.answers and compass.contexts ready to receive stance data once server is run with DB credentials

## Self-Check: PASSED

- EV-Backend/internal/stanceimport/csv.go — FOUND
- EV-Backend/internal/stanceimport/import.go — FOUND
- .planning/phases/50-data-import-scripts/50-01-SUMMARY.md — FOUND
- EV-Backend commit bda2aa2 (stanceimport package) — FOUND
- EV-Backend commit 1ae7837 (main.go CLI wiring) — FOUND

---
*Phase: 50-data-import-scripts*
*Completed: 2026-02-27*
