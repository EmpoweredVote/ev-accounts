---
phase: 95-entity-switcher
plan: "01"
subsystem: treasury
tags: [backend, frontend, api, types, cache]
dependency_graph:
  requires: []
  provides: [municipality-api-contract, available-datasets-metadata, state-aware-cache-key]
  affects: [treasury-tracker, EV-Backend]
tech_stack:
  added: []
  patterns: [two-query-aggregation-in-go, state-aware-cache-key]
key_files:
  created: []
  modified:
    - EV-Backend/internal/treasury/models.go
    - EV-Backend/internal/treasury/handlers.go
    - treasury-tracker/src/types/budget.ts
    - treasury-tracker/src/data/dataLoader.ts
decisions:
  - "Two-query approach for ListMunicipalities: fetch all municipalities, fetch all budget summaries separately, group in Go — avoids complex JOIN and handles empty datasets gracefully"
  - "Municipality interface uses literal union types for entity_type and dataset_type for frontend type safety"
metrics:
  duration: "~5 minutes"
  completed: "2026-03-23"
  tasks_completed: 2
  files_modified: 4
---

# Phase 95 Plan 01: Data Contracts for Entity Switcher Summary

**One-liner:** ListMunicipalities API extended with per-municipality available_datasets array and hero_image_url, frontend Municipality interface defined, cache key updated to include state for cross-entity collision prevention.

## What Was Built

Extended the Go treasury backend to return dataset availability metadata alongside each municipality in the `ListMunicipalities` endpoint. Added `hero_image_url` nullable field to the Municipality model (GORM AutoMigrate will add the column on next deploy). Created a typed `Municipality` interface in the frontend that mirrors the new API shape. Updated `loadBudgetData` cache key to include `municipalityState` so that cities with the same name in different states cannot collide in the in-memory cache (UI-04).

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Backend: Add hero_image_url to Municipality and extend ListMunicipalities with available_datasets | 6cc37a8 (EV-Backend) | models.go, handlers.go |
| 2 | Frontend: Add Municipality type to budget.ts and update dataLoader.ts cache key | fa6ce50 (treasury-tracker) | budget.ts, dataLoader.ts |

## Key Changes

### EV-Backend/internal/treasury/models.go
- Added `HeroImageURL *string` (nullable pointer, `json:"hero_image_url,omitempty"`) after Population field
- GORM AutoMigrate will run `ADD COLUMN hero_image_url TEXT` on next server startup

### EV-Backend/internal/treasury/handlers.go
- Added `DatasetSummary` struct (`fiscal_year int`, `dataset_type string`)
- Added `MunicipalityResponse` struct with `AvailableDatasets []DatasetSummary` and `HeroImageURL *string`
- Rewrote `ListMunicipalities` using two-query pattern: fetch all municipalities, fetch all budget summaries, group by municipality_id in Go, build and return `[]MunicipalityResponse`
- Empty datasets array (`[]DatasetSummary{}`) returned for municipalities with no budgets

### treasury-tracker/src/types/budget.ts
- Added `Municipality` interface with `id`, `name`, `state`, `entity_type`, `population`, `hero_image_url?`, `available_datasets`
- Typed union for `entity_type: 'city' | 'county' | 'township'`
- Typed union for `dataset_type: 'operating' | 'revenue' | 'salaries'` in available_datasets

### treasury-tracker/src/data/dataLoader.ts
- Updated import to include `Municipality` from types/budget
- Added `municipalityState: string = 'IN'` parameter to `loadBudgetData` (after municipalityName, before dataset)
- Cache key updated from `${municipalityName}-${year}-${dataset}` to `${municipalityName}-${municipalityState}-${year}-${dataset}`
- `listMunicipalities` return type updated from anonymous inline type to `Promise<Municipality[]>`

## Deviations from Plan

None — plan executed exactly as written.

## Verification

- `go build ./...` in EV-Backend: exits 0
- `npx tsc --noEmit` in treasury-tracker: exits 0 (no errors)
- Municipality interface in budget.ts matches MunicipalityResponse Go struct shape
- Cache key includes state parameter (UI-04 satisfied)

## Known Stubs

None — no UI changes in this plan. The API contract and types are complete data structures.

## Self-Check: PASSED
