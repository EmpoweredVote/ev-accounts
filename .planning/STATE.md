---
gsd_state_version: 1.0
milestone: v2026.3.7
milestone_name: Treasury Tracker Expansion
status: Ready to plan
stopped_at: Completed 92-03-PLAN.md
last_updated: "2026-03-22T22:14:00.946Z"
progress:
  total_phases: 5
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-22)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 92 — schema-foundation-bloomington-migration

## Current Position

Phase: 93
Plan: Not started

## Performance Metrics

**Velocity (v2026.3.6):** 7 phases, 15 plans, 3 days
**Velocity (v2026.3.5):** 3 phases, 5 plans, 1 day
**Velocity (v2026.3.4):** 6 phases, 13 plans, 1 day

*Updated after each plan completion*

## Accumulated Context

### Decisions

- Schema gate: Three-column unique index on treasury.budgets (city_id, fiscal_year, dataset_type) must deploy before any import — missing dataset_type causes silent duplicates or constraint violations
- Schema gate: fiscal_year_start_month added to treasury.budgets before CA data; Indiana = 1 (Jan), California = 7 (Jul)
- Go backend kept for this milestone; Express port deferred to separate future milestone
- Visual refresh: EV tokens apply to UI chrome only; chart segment fills use separate --data-* namespace to preserve 30-color perceptual distinctiveness
- LA data source: Use data.lacounty.gov expenditure transactions — not CEO PDF (PDF parsing produces 10-40% amount errors from merged cells)
- Checkbook transactions (282K rows) deferred to v2+; not imported this milestone
- [Phase 92]: Backward compat: city_id query param in ListBudgets maps to municipality_id column so existing frontend calls keep working
- [Phase 92]: Three-column index declared both in GORM struct tags and explicit CREATE UNIQUE INDEX in setup.go for safety
- [Phase 92]: rename.sql provided as pre-deployment manual step — GORM AutoMigrate cannot rename tables/columns
- [Phase 92]: API-only data loading: dataLoader.ts throws on failure, App.tsx catch sets setBudgetData(null), listCities renamed to listMunicipalities calling /treasury/municipalities
- [Phase 92]: Idempotent budget import: existence checked by (municipality_id, fiscal_year, dataset_type) before insert
- [Phase 92]: totalBudget resolution: totalBudget > totalCompensation > totalRevenue (salary files have both totalBudget and totalCompensation set to same value)
- [Phase 92]: Loading guard fix: if (loading || !operatingBudgetData) was blocking error state — removed operatingBudgetData dependency and added null-setting in totals catch block

### Pending Todos

- 12 politicians have no Read & Rank quotes (carried from v1.8)

### Blockers/Concerns

- Phase 93 start: Download and inspect Indiana Gateway sample files for Ellettsville and Monroe County before writing transforms — column schema confirmed at medium confidence only
- Phase 94 start: Verify data.lacounty.gov Socrata dataset IDs for department-level expenditures (30-minute investigation) before writing LA County import script

## Session Continuity

Last session: 2026-03-22T21:57:56.826Z
Stopped at: Completed 92-03-PLAN.md
Resume file: None
