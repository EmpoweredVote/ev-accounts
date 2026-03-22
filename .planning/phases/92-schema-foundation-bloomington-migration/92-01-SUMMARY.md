---
phase: 92-schema-foundation-bloomington-migration
plan: "01"
subsystem: treasury
tags: [schema, go-backend, models, migration, municipality, budget]
dependency_graph:
  requires: []
  provides: [treasury-municipality-model, three-column-budget-index, municipality-api-routes]
  affects: [treasury-tracker-frontend, budget-import-scripts]
tech_stack:
  added: []
  patterns: [gorm-composite-index, entity-type-enum-validation, backward-compat-query-params]
key_files:
  created:
    - EV-Backend/internal/treasury/rename.sql
  modified:
    - EV-Backend/internal/treasury/models.go
    - EV-Backend/internal/treasury/handlers.go
    - EV-Backend/internal/treasury/routes.go
    - EV-Backend/internal/treasury/setup.go
decisions:
  - "Backward compat: city_id query param in ListBudgets maps to municipality_id column so existing frontend calls keep working"
  - "entity_type validated server-side (city/county/township) with default 'city' for both CreateMunicipality and ImportBudget"
  - "Three-column index declared both in GORM struct tags and explicit CREATE UNIQUE INDEX in setup.go for safety"
  - "rename.sql provided as pre-deployment manual step — GORM AutoMigrate cannot rename tables/columns"
metrics:
  duration: "3 minutes"
  completed_date: "2026-03-22"
  tasks_completed: 2
  files_changed: 5
---

# Phase 92 Plan 01: Municipality Schema Foundation Summary

**One-liner:** City model renamed to Municipality with entity_type, FiscalYearStartMonth added to Budget, three-column unique index (municipality_id+fiscal_year+dataset_type) fixing the SCHM-01 silent-duplicate bug, and all handlers/routes/setup updated.

## What Was Built

### Task 1: SQL rename script and Go models (commit `43cf756`)

Created `EV-Backend/internal/treasury/rename.sql` — a pre-deployment script to be run manually in Supabase SQL editor before the new Go code deploys. It renames `treasury.cities` to `treasury.municipalities`, renames the `city_id` column to `municipality_id` on the budgets table, and drops the old two-column unique index.

Rewrote `EV-Backend/internal/treasury/models.go`:
- `City` struct renamed to `Municipality` with `TableName()` returning `treasury.municipalities`
- Added `EntityType string` field with `gorm:"not null;default:'city'"` — supports city, county, township
- Removed the single-column `uniqueIndex` from `Name` (replaced by composite index in setup.go)
- `Budget.CityID` renamed to `Budget.MunicipalityID` with three-column composite unique index tag `idx_budget_municipality_year_type` including `MunicipalityID`, `FiscalYear`, and `DatasetType` — fixes SCHM-01
- Added `Budget.FiscalYearStartMonth int` with `gorm:"not null;default:1"` — Indiana=1 (January), California=7 (July)
- Updated `Budget` relationship from `City City` to `Municipality Municipality`
- `BudgetCategory` and `BudgetLineItem` unchanged

### Task 2: Handlers, routes, setup (commit `48fb9d5`)

Updated `EV-Backend/internal/treasury/handlers.go`:
- All five City handlers renamed: `ListMunicipalities`, `GetMunicipality`, `CreateMunicipality`, `UpdateMunicipality`, `DeleteMunicipality`
- `CreateMunicipality` validates `entity_type` (must be city/county/township), defaults to "city"
- `UpdateMunicipality` supports `entity_type` as an updateable field with validation
- `ListBudgets` uses `Preload("Municipality")`, supports `municipality_id` and `city_id` query params (backward compat with existing frontend)
- `GetBudget` uses `Preload("Municipality")`
- `CreateBudget` validates `MunicipalityID` (not `CityID`), error message updated
- `ImportBudget` accepts optional `entity_type` (defaults "city") and `fiscal_year_start_month` (defaults 1); creates `Municipality{}` not `City{}`; response JSON uses `municipality_id` key

Updated `EV-Backend/internal/treasury/routes.go`:
- `/cities` routes replaced with `/municipalities` and `/municipalities/{municipality_id}`
- Budget routes unchanged (no city in path)

Updated `EV-Backend/internal/treasury/setup.go`:
- `AutoMigrate` list uses `&Municipality{}` instead of `&City{}`
- Drops `idx_budget_city_year` and `idx_cities_name` (old indexes from City era)
- Creates `idx_municipality_name_state_type` unique index on `(name, state, entity_type)` — SCHM-02
- Creates `idx_budget_municipality_year_type` unique index on `(municipality_id, fiscal_year, dataset_type)` — SCHM-01

## Verification Results

- `go build -o server .` — PASS
- No `City{}` references in `internal/treasury/` — PASS
- No `city_id` in `models.go` — PASS
- `idx_budget_municipality_year_type` in setup.go — PASS
- `idx_municipality_name_state_type` in setup.go — PASS
- `rename.sql` exists with correct ALTER TABLE statements — PASS

## Deviations from Plan

None — plan executed exactly as written.

## Decisions Made

1. **Backward compat query param** — `ListBudgets` accepts both `municipality_id` and `city_id` as query params, both mapping to the `municipality_id` column. This avoids breaking the treasury-tracker frontend before it is updated in a later plan.

2. **Explicit index creation** — Both GORM struct tags and explicit `CREATE UNIQUE INDEX` in setup.go declare the three-column index. The struct tags ensure GORM tracks it; the explicit SQL is the safety net if GORM's index naming logic drifts.

3. **entity_type server-side validation** — `CreateMunicipality` and `UpdateMunicipality` validate against the fixed enum `{city, county, township}`. `ImportBudget` silently defaults to "city" for backward compat with existing JSON imports that don't include the field.

## Known Stubs

None — all data flows through real DB queries. No placeholder values.

## Pre-Deployment Note

Before deploying the updated Go binary, `EV-Backend/internal/treasury/rename.sql` must be executed in the Supabase SQL editor. This renames the DB table and column; the Go code will fail to connect to the old names otherwise.

## Self-Check: PASSED

Files created:
- `EV-Backend/internal/treasury/rename.sql` — exists
- `.planning/phases/92-schema-foundation-bloomington-migration/92-01-SUMMARY.md` — this file

Commits:
- `43cf756` — feat(92-01): rename City to Municipality, add entity_type and fiscal_year_start_month, fix three-column budget unique index
- `48fb9d5` — feat(92-01): update handlers/routes/setup to use Municipality, add composite indexes
