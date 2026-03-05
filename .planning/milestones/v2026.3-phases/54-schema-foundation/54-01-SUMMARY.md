---
phase: 54-schema-foundation
plan: "01"
subsystem: EV-Backend/essentials
tags: [schema, gorm, legislative, database, go]
dependency_graph:
  requires: []
  provides:
    - essentials.legislative_sessions table
    - essentials.legislative_committees table
    - essentials.legislative_committee_memberships table
    - essentials.legislative_leadership_roles table
    - essentials.legislative_bills table
    - essentials.legislative_bill_cosponsors table
    - essentials.legislative_votes table
    - essentials.legislative_politician_id_map table
    - essentials.politicians.leg_data_fetched_at column
  affects:
    - EV-Backend/internal/essentials/models.go
    - EV-Backend/internal/essentials/setup.go
tech_stack:
  added:
    - github.com/goccy/go-yaml v1.18.0
  patterns:
    - GORM AutoMigrate for schema creation
    - Composite unique indexes via gorm:"uniqueIndex:name" tags
    - Bare UUID foreign key fields (no GORM association tags, cross-schema FK unreliable on Supabase)
    - *time.Time pointer for optional timestamps (non-pointer for required)
key_files:
  created: []
  modified:
    - EV-Backend/internal/essentials/models.go
    - EV-Backend/internal/essentials/setup.go
    - EV-Backend/go.mod
    - EV-Backend/go.sum
decisions:
  - "Used bare UUID fields for cross-table references (no GORM foreignKey association tags) because GORM cross-schema FK support is unreliable on Supabase"
  - "Used github.com/goccy/go-yaml v1.18.0; gopkg.in/yaml.v3 is archived and must not be used"
  - "LegDataFetchedAt uses *time.Time (pointer) so existing rows get NULL on migration, not zero-time"
  - "LegislativeVote composite unique index includes BillID as nullable UUID to handle non-bill votes"
metrics:
  duration: "1m 48s"
  completed: "2026-03-02"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 54 Plan 01: Schema Foundation — Legislative Tables Summary

**One-liner:** 8 legislative GORM models + LegDataFetchedAt column added to essentials schema, database-ready for all subsequent import phases.

## What Was Built

Added the complete database foundation for legislative data to the EV-Backend `internal/essentials` package. This is a pure schema change — no import logic, no API endpoints, no frontend changes.

### New Tables (8)

| Table | Purpose |
|-------|---------|
| `essentials.legislative_sessions` | Congressional/legislative session tracking (119th Congress, 2025 IN Regular Session) |
| `essentials.legislative_committees` | Committees and subcommittees with (external_id, jurisdiction) unique index |
| `essentials.legislative_committee_memberships` | Politician-committee links with role (chair, member, etc.) |
| `essentials.legislative_leadership_roles` | Floor leadership positions (Speaker, Majority Leader, etc.) |
| `essentials.legislative_bills` | Bills, resolutions, ordinances with topic_tags text[] array |
| `essentials.legislative_bill_cosponsors` | Politician-bill cosponsor bridge table |
| `essentials.legislative_votes` | Individual member roll call votes with composite unique index |
| `essentials.legislative_politician_id_map` | Cross-source ID bridge (bioguide, OCD, LegiScan, Legistar, OpenStates) |

### Modified Columns (1)

- `essentials.politicians.leg_data_fetched_at` — `*time.Time` nullable timestamp with `gorm:"index"` for lazy-fetch tracking; existing rows get NULL on migration

### Dependency Added

- `github.com/goccy/go-yaml v1.18.0` — needed by Plan 54-02 for congress-legislators YAML parsing

## Verification Results

1. `go build ./...` — PASS (no errors)
2. `grep -c "func (Legislative" internal/essentials/models.go` — 8 (correct)
3. `grep "LegDataFetchedAt" internal/essentials/models.go` — found with `*time.Time` (correct)
4. `grep "goccy/go-yaml" go.mod` — found v1.18.0 (correct)
5. `grep -c "Legislative" internal/essentials/setup.go` — 9 (8 struct refs + 1 comment line, correct)

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | cc4199d | feat(54-01): add 8 legislative GORM models and LegDataFetchedAt to models.go |
| Task 2 | 28dea84 | feat(54-01): wire 8 legislative models into AutoMigrate and add go-yaml dependency |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- [x] `EV-Backend/internal/essentials/models.go` — found, contains all 8 new Legislative* structs
- [x] `EV-Backend/internal/essentials/setup.go` — found, contains 8 new models in AutoMigrate
- [x] `EV-Backend/go.mod` — found, contains github.com/goccy/go-yaml v1.18.0
- [x] Commit cc4199d — exists in EV-Backend git log
- [x] Commit 28dea84 — exists in EV-Backend git log
