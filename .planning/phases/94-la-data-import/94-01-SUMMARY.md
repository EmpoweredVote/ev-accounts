---
phase: 94-la-data-import
plan: 01
subsystem: treasury-importer
tags: [go, treasury, socrata, arcgis, import, testing]
dependency_graph:
  requires: []
  provides:
    - SocrataEntityConfig / SocrataDatasetConfig types
    - ArcGISEntityConfig / ArcGISDatasetConfig / ArcGISQueryResponse types
    - fetchSocrataCSV function
    - fetchArcGISFeatures paginated fetcher
    - buildSocrataCategoryTree N-level tree builder
    - buildArcGISCategoryTree N-level tree builder
    - parseFiscalYearRange helper
    - ImportSocrataBudgets orchestrator
    - ImportArcGISBudgets orchestrator
  affects:
    - EV-Backend/internal/treasury/importer.go
    - EV-Backend/treasury-import-config.json (schema extended with socrata_entities/arcgis_entities)
tech_stack:
  added: []
  patterns:
    - Socrata CSV export via simple HTTP GET (UTF-8 native, no charset conversion)
    - ArcGIS FeatureServer resultOffset pagination with ExceededTransferLimit check
    - N-level categoryNode accumulator tree shared by both Socrata and ArcGIS builders
    - Same municipality find-or-create + idempotent budget insert pattern as Gateway/Bloomington
key_files:
  created:
    - EV-Backend/internal/treasury/socrata_test.go
    - EV-Backend/internal/treasury/testdata/la_city_appropriations_sample.csv
    - EV-Backend/internal/treasury/testdata/la_county_expenditures_sample.json
  modified:
    - EV-Backend/internal/treasury/importer.go
decisions:
  - N-level categoryNode tree replaces the hardcoded 2-level (fund/dept) Gateway accumulator, enabling arbitrary depth from config
  - ArcGIS WHERE clause uses single-quoted string value for fiscal year field (esriFieldTypeString requirement)
  - Socrata uses 120s HTTP timeout (LA City CSV is ~58K rows); ArcGIS uses 60s per page
  - parseFiscalYearRange splits on '-' and takes the LAST segment to handle "2020-2021" range strings
  - FiscalYearStartMonth set from entity config (7 for all California entities per LA-03)
metrics:
  duration: 4 minutes
  completed_date: "2026-03-23"
  tasks_completed: 2
  files_modified: 4
---

# Phase 94 Plan 01: Socrata + ArcGIS Fetch Layer with Unit Tests Summary

**One-liner:** Socrata CSV and ArcGIS FeatureServer fetch strategies with N-level category tree builders and unit tests for LA City appropriations and LA County expenditure data.

## What Was Built

Added two new data source strategies to `EV-Backend/internal/treasury/importer.go`:

**Socrata (LA City):** `fetchSocrataCSV` performs a simple HTTP GET to the Socrata CSV export URL (`/api/views/{id}/rows.csv?accessType=DOWNLOAD`). `buildSocrataCategoryTree` filters rows by fiscal year (supporting both integer "2024" and range "2020-2021" formats via `parseFiscalYearRange`), then walks configurable `hierarchy_columns` to build an N-level `categoryNode` tree. `ImportSocrataBudgets` orchestrates the full pipeline: fetch → parse headers → build tree → find-or-create municipality → idempotent budget insert → `importCategories` DB insertion.

**ArcGIS (LA County):** `fetchArcGISFeatures` uses paginated `resultOffset` queries against the FeatureServer `/query` endpoint. Each page returns up to 2,000 JSON features; the loop continues while `exceededTransferLimit` is true. `buildArcGISCategoryTree` extracts hierarchy values from `feature.Attributes` map and accumulates them using the same `categoryNode` structure. Negative amounts pass through as-is (credit/adjustment rows). `ImportArcGISBudgets` orchestrates the full pipeline identically to the Socrata orchestrator.

**Shared helpers:** `categoryNode` type + `addToTree` + `convertTreeToCategories` are used by both tree builders, avoiding code duplication.

**Extended GatewayConfig** with `SocrataEntities []SocrataEntityConfig` and `ArcGISEntities []ArcGISEntityConfig` arrays — the config file now supports all three source types.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create test fixtures and unit tests | 8267bd6 | socrata_test.go, testdata/la_city_appropriations_sample.csv, testdata/la_county_expenditures_sample.json |
| 2 | Implement fetch, tree builders, and orchestrators | c2dbafd | importer.go |

## Test Results

All 6 new unit tests pass:
- `TestBuildSocrataCategoryTree` — 3 root categories for FY2024, Police=1400797289, totalBudget=2031661610
- `TestSocrataFiscalYearFilter` — 2 root categories for FY2023, totalBudget=1600000000
- `TestBuildArcGISCategoryTree` — 2 root categories, General Fund=3781537.79, Special Fund=1175000.00, totalBudget=4956537.79
- `TestArcGISNegativeAmounts` — Medical Supplies node amount=-25000.00
- `TestSocrataHeaderTrimSpace` — " Appropriation " (with spaces) trimmed and matched at index 11
- `TestParseFiscalYearRange` — "2020-2021"→2021, "2024-2025"→2025, "2024"→2024, "invalid"→error

All existing Gateway tests continue to pass (no regressions).

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None - all functions are fully implemented. The orchestrators (`ImportSocrataBudgets`, `ImportArcGISBudgets`) require a populated config file with `socrata_entities`/`arcgis_entities` arrays to perform live imports, but the functions themselves are complete. The config file extension happens in a subsequent plan.

## Self-Check: PASSED

All created files exist on disk. Both commits verified in git history.
