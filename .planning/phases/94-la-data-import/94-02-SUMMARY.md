---
phase: 94-la-data-import
plan: 02
subsystem: treasury-importer
tags: [go, treasury, socrata, arcgis, config, cli]
dependency_graph:
  requires:
    - 94-01 (ImportSocrataBudgets + ImportArcGISBudgets functions in importer.go)
  provides:
    - treasury-import-config.json populated with LA City Socrata entity (datasets: 5242-pnmt operating, ih6g-qkwz revenue)
    - treasury-import-config.json populated with LA County ArcGIS entity (datasets: Open_Expenditures operating, Open_Budget_Revenue revenue, Employee Salaries salaries)
    - CLI routing: --source=socrata calls ImportSocrataBudgets, --source=arcgis calls ImportArcGISBudgets
  affects:
    - EV-Backend/treasury-import-config.json
    - EV-Backend/main.go
tech_stack:
  added: []
  patterns:
    - Config-driven source routing: socrata_entities and arcgis_entities arrays in treasury-import-config.json
    - CLI switch case expansion: bloomington, gateway, socrata, arcgis all routing to typed import functions
key_files:
  created: []
  modified:
    - EV-Backend/treasury-import-config.json
    - EV-Backend/main.go
decisions:
  - fiscal_year_start_month=7 for both LA City (Socrata) and LA County (ArcGIS) per LA-03 (California Jul-Jun fiscal year)
  - LA City salary dataset not included — confirmed not available on data.lacity.org
  - LA County revenue hierarchy_columns use best-guess field names (Revenue_Category, Revenue_Class); importer will log warnings if columns don't match
metrics:
  duration: 48 seconds
  completed_date: "2026-03-23"
  tasks_completed: 2
  files_modified: 2
---

# Phase 94 Plan 02: Wire Socrata + ArcGIS CLI and Config Summary

**One-liner:** Config file populated with LA City Socrata and LA County ArcGIS entity definitions, and CLI extended to route `--source=socrata`/`--source=arcgis` to the correct import functions built in Plan 01.

## What Was Built

**Config file extension (`treasury-import-config.json`):** Added two new top-level arrays alongside `gateway_entities`:

- `socrata_entities`: LA City (display_name="Los Angeles", state="CA", entity_type="city", base_url="https://data.lacity.org", fiscal_year_start_month=7). Two datasets: operating (`5242-pnmt`, hierarchy: Department_Name → SubDepartment_Name → Program_Name, amount_column: Appropriation, fiscal_year_column: Fiscal_Year) and revenue (`ih6g-qkwz`, hierarchy: Revenue Source, amount_column: Amount, fiscal_year_column: Fiscal_Year_Shorthand). Fiscal years 2021–2025.

- `arcgis_entities`: LA County (display_name="Los Angeles County", state="CA", entity_type="county", fiscal_year_start_month=7). Three datasets: operating (Open_Expenditures FeatureServer, fiscal_year_field: Budget_Fiscal_Year, 4-level hierarchy: Fund_Group → Department → Expenditure_Category → Expenditure_Class), revenue (Open_Budget_Revenue FeatureServer, speculative hierarchy columns), and salaries (Employee_Salaries FeatureServer, year_field: Year, hierarchy: Department, amount: Total_Compensation). Fiscal years 2021–2025.

**CLI extension (`main.go`):** In the `import-budgets` switch statement, added `case "socrata"` and `case "arcgis"` before the default case. Both cases pass the existing `configFile` and `dryRun` variables to `treasury.ImportSocrataBudgets` and `treasury.ImportArcGISBudgets` respectively. Default error message updated to list all four valid sources.

**Ready to run:**
- `./server import-budgets --source=socrata` — imports LA City appropriations and revenue
- `./server import-budgets --source=socrata --dry-run` — dry run mode
- `./server import-budgets --source=arcgis` — imports LA County operating, revenue, salaries
- `./server import-budgets --source=arcgis --dry-run` — dry run mode

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Populate treasury-import-config.json with LA entity configurations | 4304369 | treasury-import-config.json |
| 2 | Wire Socrata and ArcGIS sources into import-budgets CLI | 4e11a5a | main.go |

## Verification

- `go build -o /dev/null .` — Build OK
- `go test ./internal/treasury/... -v` — All 13 tests pass (6 Socrata/ArcGIS tests from Plan 01 + 7 Gateway tests)
- `python3 json.load(treasury-import-config.json)` — Valid JSON
- Config contains socrata_entities with fiscal_year_start_month=7
- Config contains arcgis_entities with fiscal_year_start_month=7
- main.go switch includes socrata and arcgis cases

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

- LA County revenue hierarchy_columns (`["Fund_Group", "Department", "Revenue_Category", "Revenue_Class"]`) are best-guess field names. The research phase confirmed the FeatureServer URL but did not verify the exact column schema. The importer's header validation will log a warning and skip gracefully if these columns don't match. The operating dataset (primary requirement LA-01) uses verified column names from the research phase.

## Self-Check: PASSED

Both modified files exist on disk. Both commits verified in git history.
