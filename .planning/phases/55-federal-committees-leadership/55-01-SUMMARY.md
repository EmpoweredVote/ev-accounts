---
phase: 55-federal-committees-leadership
plan: "01"
subsystem: essentials
tags: [go, committees, yaml-import, cli, legislative-data]
dependency_graph:
  requires: [54-01, 54-02]
  provides: [committee-import-cli]
  affects: [essentials.legislative_committees, essentials.legislative_committee_memberships, essentials.legislative_sessions]
tech_stack:
  added: []
  patterns: [yaml-import, gorm-upsert, bridge-table-lookup, cli-subcommand]
key_files:
  created:
    - EV-Backend/internal/essentials/import_committees.go
  modified:
    - EV-Backend/main.go
decisions:
  - "Used FirstOrCreate+Assign for committee upserts instead of clause.OnConflict+Returning due to GORM UUID primary key handling with auto-generated IDs"
  - "Composed subcommittee external IDs as parent_thomas_id + sub_thomas_id (e.g. HSAG + 15 = HSAG15)"
  - "Single bulk query for bioguide bridge table entries — avoids N+1 lookups during membership upsert"
metrics:
  duration: "~3 minutes"
  completed: "2026-03-01"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 1
---

# Phase 55 Plan 01: Import Committees CLI Summary

Go CLI subcommand `import-committees` that downloads congress-legislators YAML files, parses committee structure and memberships, and upserts them into the database with full hierarchy support.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create import_committees.go with ImportCommittees function | 2b47937 | EV-Backend/internal/essentials/import_committees.go |
| 2 | Wire import-committees CLI subcommand in main.go | 785ab18 | EV-Backend/main.go |

## What Was Built

### import_committees.go (384 lines)

**YAML structs:**
- `committeeYAML` — parses committees-current.yaml top-level entries (thomas_id, name, type, subcommittees)
- `subcommitteeYAML` — nested subcommittee entries within a parent committee
- `committeeMemberYAML` — member entries; committee-membership-current.yaml is a `map[string][]committeeMemberYAML` (map, not array)

**Config/Result types:**
- `ImportCommitteesConfig` — DryRun bool, CongressNumber int (default 119)
- `ImportCommitteesResult` — SessionCreated, CommitteesUpserted, SubcommitteesUpserted, MembershipsUpserted, Skipped, Errors

**Key functions:**
- `normalizeCommitteeRole(title string) string` — maps raw YAML title strings ("Chairman", "Ranking Member", "Ex Officio", "Vice Chair") to normalized enum values: chair, vice_chair, ranking_member, ex_officio, member
- `getOrCreateSession(congressNumber int) (uuid.UUID, bool, error)` — finds or creates a LegislativeSession row for the given congress
- `fetchYAML(url string) ([]byte, error)` — HTTP GET + io.ReadAll helper following backfill_ids.go pattern
- `ImportCommittees(cfg ImportCommitteesConfig) (ImportCommitteesResult, error)` — main 8-step import flow

**Import flow:**
1. Ensure LegislativeSession exists for congress number (create if not found)
2. Download + parse committees-current.yaml as `[]committeeYAML`
3. Download + parse committee-membership-current.yaml as `map[string][]committeeMemberYAML`
4. Bulk-load all bioguide bridge rows into `map[string]uuid.UUID` cache
5. Upsert top-level committees; store thomas_id→DB UUID in committeeMap
6. Upsert subcommittees with parent_id; compose external_id as parent_thomas_id + sub_thomas_id
7. Upsert memberships via `clause.OnConflict` on (committee_id, politician_id, congress_number)
8. Log and return summary counts

### main.go (import-committees case)

- Parses `--dry-run` and `--congress=N` flags
- Calls `essentials.ImportCommittees`
- Prints: "Import complete: N committees, N subcommittees, N memberships upserted, N skipped"
- Reports session creation if new session was created
- Reports error list if any errors occurred
- Added `strconv` and `strings` to imports

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

**Note:** `import-leadership` case already existed in main.go (pre-populated from a prior session). This did not affect execution — the `import-committees` case was inserted before it as specified.

## Verification

- `go build ./...` passes with zero errors
- No `gopkg.in/yaml.v3` usage — uses `github.com/goccy/go-yaml v1.18.0`
- Membership YAML parsed as `map[string][]committeeMemberYAML` (not slice)
- Subcommittee external IDs composed as `parent_thomas_id + sub_thomas_id`
- Upserts use composite unique indexes from Phase 54 schema
- Unmatched bioguide IDs log and skip gracefully — no fatal errors

## Self-Check: PASSED

- [x] EV-Backend/internal/essentials/import_committees.go — FOUND
- [x] EV-Backend/main.go — FOUND (contains `import-committees`)
- [x] Commit 2b47937 — FOUND
- [x] Commit 785ab18 — FOUND
