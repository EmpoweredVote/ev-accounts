---
phase: 93-indiana-data-import
plan: "01"
subsystem: treasury
tags: [go, csv, indiana-gateway, importer, windows-1252, pipe-delimiter]
dependency_graph:
  requires: [92-02]
  provides: [gateway-import-pipeline]
  affects: [treasury-api, import-budgets-cli]
tech_stack:
  added: []
  patterns:
    - Config-driven Gateway fetch with treasury-import-config.json
    - Windows-1252 → UTF-8 transparent re-encoding via golang.org/x/text/transform
    - Fail-fast header validation before processing rows
    - Flat CSV → fund/dept/line-item hierarchy tree accumulation
key_files:
  created:
    - EV-Backend/treasury-import-config.json
    - EV-Backend/internal/treasury/gateway_test.go
    - EV-Backend/internal/treasury/testdata/ellettsville_sample.csv
  modified:
    - EV-Backend/internal/treasury/importer.go
    - EV-Backend/main.go
decisions:
  - POST-based Gateway fetch with configurable form params; HTML Content-Type response triggers descriptive error (not silent failure)
  - buildGatewayCategoryTree exposed as testable function to allow unit tests without DB or HTTP dependencies
  - sortStrings implemented inline (insertion sort) to avoid importing sort package for one use
  - Funds accumulated in insertion order to preserve CSV ordering in output
metrics:
  duration: "~4 minutes"
  completed: "2026-03-22"
  tasks_completed: 4
  files_changed: 5
---

# Phase 93 Plan 01: Indiana Gateway Import Pipeline Summary

Config-driven Go import pipeline for Indiana Gateway pipe-delimited CSV budget data with Windows-1252 re-encoding, fail-fast header validation, and recursive category tree insertion via existing importCategories helper.

## What Was Built

A new `ImportGatewayBudgets` function and supporting infrastructure that extends the existing treasury import CLI to fetch, decode, parse, and insert Indiana Gateway budget data for Ellettsville and Monroe County across fiscal years 2021-2025 for both operating and revenue dataset types.

### Files Created

**EV-Backend/treasury-import-config.json** — Entity metadata for Gateway sources. Defines Ellettsville (city, unit_code=5304) and Monroe County (county, unit_code=5500) with pipe delimiter, windows-1252 encoding, hierarchy columns, and both operating/revenue dataset types for 2021-2025.

**EV-Backend/internal/treasury/gateway_test.go** — 7 test functions covering CSV parsing, amount formatting, header validation, pipe delimiter, UTF-8 re-encoding, and end-to-end parse for Ellettsville and Monroe County. All tests pass GREEN.

**EV-Backend/internal/treasury/testdata/ellettsville_sample.csv** — 10-row pipe-delimited fixture with realistic fund/dept/line-item structure, including comma-formatted amounts ("1,234,567.00") and parenthesized negatives ("(500.00)").

### Files Modified

**EV-Backend/internal/treasury/importer.go** — Added:
- `GatewayEntityConfig` and `GatewayConfig` types for JSON config unmarshaling
- `newGatewayCSVReader`: wraps io.Reader with Windows-1252 decoder, sets pipe delimiter, LazyQuotes=true
- `parseAmount`: strips commas, converts parenthesized negatives, treats blank as 0.0
- `validateHeaders`: builds header→index map, returns descriptive error naming missing columns
- `buildGatewayCategoryTree`: accumulates flat CSV rows into fund/dept hierarchy, computes percentages, populates LineItems
- `ImportGatewayBudgets`: top-level function iterating entity/datasetType/year, fetching CSV, validating, parsing, inserting via importCategories with idempotent check
- `fetchGatewayCSV`: HTTP POST to Gateway with Content-Type check (HTML response = form returned, not file)

**EV-Backend/main.go** — Extended `import-budgets` case with `--source=` (bloomington/gateway) and `--config=` flags. Dispatches to `ImportGatewayBudgets` for gateway source.

## Verification Results

1. `go test ./internal/treasury/... -count=1` — PASS (all 7 gateway tests green)
2. `go build -o /tmp/ev-server-test .` — compiles without errors
3. `grep -c "func ImportGatewayBudgets"` — returns 1
4. `grep -c "charmap.Windows1252"` — returns 1
5. `grep -c "validateHeaders"` — returns 3 (definition + 2 call sites)
6. Monroe County and Ellettsville both in treasury-import-config.json
7. Both `"revenue"` dataset_types in config
8. `--source=gateway` dispatched correctly in main.go

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written with one implementation decision:

**1. [Discretion] buildGatewayCategoryTree named to avoid collision**
- **Context:** handlers.go already exports `buildCategoryTree([]BudgetCategory)`. The new function operates on `[][]string` raw CSV records.
- **Resolution:** Named `buildGatewayCategoryTree` to distinguish from the existing DB-to-tree function in handlers.go.

## Known Limitations / Post-Implementation Notes

**Gateway POST parameters require runtime confirmation.** The `fetchGatewayCSV` function uses `UnitID`, `rptYear`, and `rptType` form parameters based on the ASP.NET WebForms pattern documented in research. The exact parameter names must be confirmed by:
1. Loading https://gateway.ifionline.org/public/download.aspx in a browser
2. Selecting Ellettsville (or Monroe County), a year, and dataset type
3. Capturing the POST request in DevTools Network tab
4. Updating `fetchGatewayCSV` if parameter names differ

If the POST returns HTML instead of CSV, `fetchGatewayCSV` returns a descriptive error: "gateway returned HTML page instead of CSV — POST parameters may need updating". This prevents silent failure.

**Column headers require first-run confirmation.** The config uses `["fund_name", "department_name", "account_description"]` and `"amount"` as column names (medium confidence from research). Header validation (D-03) will produce a clear error on first run if the actual column names differ — update `hierarchy_columns` and `amount_column` in treasury-import-config.json accordingly.

## Self-Check: PASSED

- [x] treasury-import-config.json exists at EV-Backend/treasury-import-config.json
- [x] gateway_test.go exists at EV-Backend/internal/treasury/gateway_test.go
- [x] ellettsville_sample.csv exists at EV-Backend/internal/treasury/testdata/ellettsville_sample.csv
- [x] Commit 436757b: test(93-01): add failing gateway tests and CSV fixture
- [x] Commit 7164f7a: feat(93-01): add Gateway types, helpers, and config file
- [x] Commit 0c4160d: feat(93-01): implement ImportGatewayBudgets with fetch, parse, tree-build
- [x] Commit 476eddd: feat(93-01): wire --source=gateway and --config= flags into import-budgets CLI
