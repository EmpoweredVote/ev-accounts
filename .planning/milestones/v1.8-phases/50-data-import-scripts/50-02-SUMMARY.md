---
phase: 50-data-import-scripts
plan: 02
subsystem: database
tags: [go, gorm, postgresql, csv, cli, essentials, quotes]

# Dependency graph
requires:
  - phase: 50-01-data-import-scripts
    provides: stanceimport package and CLI subcommand switch block in main.go
  - phase: 49-quote-collection
    provides: quote_collection.csv with 61 curated politician quotes

provides:
  - essentials.quotes table (politician_id, topic_key, quote_text, source_url, source_name)
  - quoteimport Go package with ParseCSV and Run upsert logic
  - ./server import-quotes CLI subcommand

affects: [50-03-data-import-scripts, read-rank frontend]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - quoteimport follows identical structure to stanceimport (lightweight models, two-pass name detection, upsert by dedup key)

key-files:
  created:
    - EV-Backend/internal/quoteimport/csv.go
    - EV-Backend/internal/quoteimport/import.go
  modified:
    - EV-Backend/internal/essentials/models.go
    - EV-Backend/internal/essentials/setup.go
    - EV-Backend/main.go

key-decisions:
  - "Upsert dedup key is (politician_id, topic_key, source_url) — same politician can have multiple quotes per topic"
  - "No external_id fallback for quote import — quotes reference politicians by full_name only (all 11 politicians in CSV have unique names)"
  - "import-quotes case uses os.Args[2] as CSV path without the --prefix guard used in import-stances, matching plan spec"

patterns-established:
  - "Import package pattern: lightweight private model structs with TableName(), Config/ImportResult types, Run() entry point"
  - "Two-pass ambiguous name detection: count pass then map build, matching stanceimport pattern"

requirements-completed: [IMPORT-02, IMPORT-03]

# Metrics
duration: 2min
completed: 2026-02-27
---

# Phase 50 Plan 02: Quote Import CLI + Database Table Summary

**essentials.quotes table created with upsert-by-source-url semantics; ./server import-quotes CLI loads quote_collection.csv into PostgreSQL with politician name resolution and topic_key validation**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-27T00:47:35Z
- **Completed:** 2026-02-27T00:49:44Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Quote model added to essentials package with two named indexes (politician, topic_key); AutoMigrate registered
- quoteimport package (csv.go + import.go) built following identical structure to stanceimport from Plan 50-01
- import-quotes case added to existing CLI switch in main.go; full server build passes

## Task Commits

Each task was committed atomically (in EV-Backend repo):

1. **Task 50-02-01: Create essentials.quotes model and migration** - `42ed06d` (feat)
2. **Task 50-02-02: Create quote import package** - `dd54b9c` (feat)
3. **Task 50-02-03: Wire import-quotes CLI subcommand into main.go** - `14f227e` (feat)

## Files Created/Modified
- `EV-Backend/internal/essentials/models.go` - Added Quote struct and TableName()
- `EV-Backend/internal/essentials/setup.go` - Added &Quote{} to AutoMigrate call
- `EV-Backend/internal/quoteimport/csv.go` - QuoteRow struct + ParseCSV with LazyQuotes, BOM stripping, required column validation
- `EV-Backend/internal/quoteimport/import.go` - Config/ImportResult types, Run() with topic validation, two-pass ambiguous name detection, upsert by (politician_id, topic_key, source_url)
- `EV-Backend/main.go` - Added quoteimport import + import-quotes case to CLI switch

## Decisions Made
- Upsert dedup key is `(politician_id, topic_key, source_url)` — allows multiple quotes per topic for the same politician (e.g., Newsom has 2 abortion quotes from different sources), matching the plan's explicit guidance
- No external_id fallback: all 11 politicians in quote_collection.csv have unique full_names so external_id resolution is unnecessary overhead
- The import-quotes CSV path argument (os.Args[2]) does not skip `--` prefixed args the way import-stances does — this matches the plan spec and is fine since --dry-run is always a named flag

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- EV-Backend is a separate git repository nested inside the workspace root. Commits were made from within EV-Backend/ rather than the workspace root. This is the same pattern used in Plan 50-01.

## User Setup Required
None - no external service configuration required. Run `./server import-quotes` (after database is connected) to load quotes.

## Self-Check: PASSED

All created files confirmed on disk. All task commits confirmed in EV-Backend git log (42ed06d, dd54b9c, 14f227e).

## Next Phase Readiness
- essentials.quotes table will be created by AutoMigrate on next server startup
- ./server import-quotes will load all 61 rows from data/quote_collection.csv
- Plan 50-03 can now build the GET /essentials/quotes API endpoint to serve quotes to the Read & Rank frontend

---
*Phase: 50-data-import-scripts*
*Completed: 2026-02-27*
