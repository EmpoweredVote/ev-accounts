---
phase: 92-schema-foundation-bloomington-migration
plan: "02"
subsystem: treasury
tags: [import, cli, go-backend, budget-migration, bloomington, gorm]
dependency_graph:
  requires: [treasury-municipality-model, three-column-budget-index]
  provides: [import-budgets-cli, bloomington-data-migration]
  affects: [treasury-tracker-frontend, treasury-api-endpoints]
tech_stack:
  added: []
  patterns: [cli-subcommand-dispatch, find-or-create-pattern, idempotent-upsert, recursive-category-import]
key_files:
  created:
    - EV-Backend/internal/treasury/importer.go
  modified:
    - EV-Backend/main.go
decisions:
  - "Dry-run flag skips DB writes but still requires DB connection (consistent with all other import commands in codebase)"
  - "Idempotent import: budget existence checked by (municipality_id, fiscal_year, dataset_type) before insert — matches the three-column unique index from Plan 01"
  - "totalBudget resolution priority: totalBudget > totalCompensation > totalRevenue — salary files have both totalBudget and totalCompensation set to the same value, so either field works"
  - "FiscalYearStartMonth hardcoded to 1 (January) for all Bloomington records — Indiana fiscal year runs January to December"
metrics:
  duration: "2 minutes"
  completed_date: "2026-03-22"
  tasks_completed: 2
  files_changed: 2
---

# Phase 92 Plan 02: Budget Import CLI Summary

**One-liner:** `import-budgets` CLI subcommand reads all 15 Bloomington JSON files (operating/revenue/salaries for 2021-2025), finds-or-creates the Municipality record, and upserts Budget + recursive category tree via GORM transactions.

## What Was Built

### Task 1: importer.go with ImportBudgets function (commit `b648662`)

Created `EV-Backend/internal/treasury/importer.go` with:

**Types:**
- `ImportBudgetsConfig` — `DataDir string` (default: `treasury-tracker/public/data`) and `DryRun bool`
- `ImportBudgetsResult` — `FilesProcessed`, `Inserted`, `Skipped`, `Errors []string`
- `budgetJSON` — internal struct mirroring the JSON file format with all three total fields (`totalBudget`, `totalCompensation`, `totalRevenue`)

**`ImportBudgets` function logic:**
1. Iterates 3 dataset prefixes × 5 years = 15 files total
2. Constructs filename as `{prefix}-{year}.json` — linked files (`budget-YYYY-linked.json`) are excluded by construction
3. Reads and unmarshals each file
4. Resolves `totalBudget`: uses `metadata.totalBudget` first, falls back to `totalCompensation` (salary files), then `totalRevenue` (revenue files)
5. In a GORM transaction: finds-or-creates `Municipality{Name:"Bloomington", State:"IN", EntityType:"city"}`
6. Checks if budget exists for `(municipality_id, fiscal_year, dataset_type)` — skips if found (idempotent)
7. Creates `Budget` with `FiscalYearStartMonth: 1` (Indiana = January)
8. Calls `importCategories(tx, budget.ID, nil, data.Categories, 0)` from handlers.go for recursive category tree
9. Commits transaction, increments `Inserted`

### Task 2: import-budgets CLI case in main.go (commit `4a84b3e`)

Added `case "import-budgets":` block to the CLI subcommand switch in `main.go` (placed after `import-quotes`):
- Default `jsonDir = "treasury-tracker/public/data"` (relative to EV-Backend repo root)
- Supports `--dry-run` flag to preview without DB writes
- Supports `--data-dir=` override for custom data directory paths
- Calls `treasury.ImportBudgets(treasury.ImportBudgetsConfig{...})`
- Prints summary: `Import complete: N files processed, N budgets inserted, N skipped`
- Prints per-error details if any errors occurred
- Exits with `os.Exit(0)`

## Verification Results

- `go build -o server .` — PASS
- `grep -c "func ImportBudgets" internal/treasury/importer.go` → 1
- `grep -c "ImportBudgetsConfig" internal/treasury/importer.go` → 3
- `grep -c "importCategories" internal/treasury/importer.go` → 2
- `grep -c "totalCompensation" internal/treasury/importer.go` → 2
- `grep -c "FiscalYearStartMonth" internal/treasury/importer.go` → 1
- `grep -c 'case "import-budgets"' main.go` → 1
- `grep -c "treasury.ImportBudgets" main.go` → 1

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Worktree branch missing Plan 01 commits**
- **Found during:** Task 1 verification (`go build` failed with undefined `Municipality`)
- **Issue:** Worktree branch `worktree-agent-a30dd0e5` was created from an older commit before Plan 01's Municipality rename commits (`43cf756`, `48fb9d5`) were merged to `main`
- **Fix:** `git merge main` fast-forwarded the worktree branch to include both Plan 01 commits; `importer.go` (untracked) survived the merge
- **Files modified:** All Plan 01 files (models.go, handlers.go, routes.go, setup.go, rename.sql) merged in from main
- **Impact:** None on deliverables — all Plan 02 code was written against the correct post-rename types

## Decisions Made

1. **Dry-run requires DB connection** — consistent with every other import command in the codebase; the `db.Connect()` and `Init()` calls happen before the CLI switch. The `DryRun` flag correctly prevents DB writes inside `ImportBudgets`.

2. **totalBudget resolution priority** — salary files have both `totalBudget` and `totalCompensation` set to identical values. The resolver checks `totalBudget` first, so salary files naturally use that field. The `totalCompensation` fallback is only needed if `totalBudget` is absent or zero.

3. **No linked file exclusion needed** — linked files are excluded by construction: the file list only generates `budget-YYYY.json`, not `budget-YYYY-linked.json`. No special filtering required.

## Known Stubs

None — all logic uses real GORM DB operations. DryRun mode logs what would happen without executing any DB writes.

## Pre-Deployment Note

Before running `./server import-budgets` in production:
1. Run `EV-Backend/internal/treasury/rename.sql` in Supabase SQL editor (renames `treasury.cities` → `treasury.municipalities`)
2. Deploy the updated Go binary
3. Run `./server import-budgets` from the EV-Backend repo root (treasury-tracker must be a sibling directory, or use `--data-dir=` to specify the path)

## Self-Check: PASSED

Files created:
- `EV-Backend/internal/treasury/importer.go` — exists
- `.planning/phases/92-schema-foundation-bloomington-migration/92-02-SUMMARY.md` — this file

Commits:
- `b648662` — feat(92-02): create ImportBudgets function in importer.go
- `4a84b3e` — feat(92-02): wire import-budgets CLI subcommand into main.go
