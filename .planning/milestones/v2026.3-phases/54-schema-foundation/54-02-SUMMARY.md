---
phase: 54-schema-foundation
plan: "02"
subsystem: EV-Backend/essentials
tags: [go, yaml, cli, backfill, congress-legislators, legislative, database]

dependency_graph:
  requires:
    - phase: 54-01
      provides: essentials.legislative_politician_id_map table and LegislativePoliticianIDMap GORM model
  provides:
    - BackfillLegislativeIDs CLI function (backfill_ids.go)
    - backfill-legislative-ids CLI subcommand in main.go
    - data inventory matrix document (data-model.md)
  affects:
    - Phase 55 (federal session import — uses bridge table populated by this backfill)
    - Phase 56 (committee import — uses bridge table for politician linking)
    - Phase 57 (LegiScan import — bridge table pattern established here)
    - Phase 58 (local/Legistar import — bridge table pattern established here)

tech-stack:
  added: []
  patterns:
    - CLI backfill subcommand pattern (DryRun flag, BackfillConfig/BackfillResult structs)
    - Tiered matching for cross-source ID reconciliation (exact ID > name+state > skip ambiguous)
    - Bridge row existence check before insert (query then insert, not ON CONFLICT)
    - goccy/go-yaml for YAML struct unmarshaling

key-files:
  created:
    - EV-Backend/internal/essentials/backfill_ids.go
    - .planning/phases/54-schema-foundation/data-model.md
  modified:
    - EV-Backend/main.go

key-decisions:
  - "Tiered matching: Tier 1 exact bioguide_id (if politician already has it), Tier 2 last_name+state (single match only), skip ambiguous/unmatched — no medium-confidence inserts"
  - "Existence check before insert rather than ON CONFLICT clause — GORM Create does not expose upsert semantics cleanly for UUID primary keys"
  - "NATIONAL_EXEC politicians excluded from backfill — they have no bioguide_id and are not in congress-legislators YAML"
  - "data-model.md confirmed no schema changes needed for empty jurisdictions — all 5 jurisdictions fit existing 8-table schema"

requirements-completed: [SCHEMA-09]

duration: 2min
completed: "2026-03-02"
---

# Phase 54 Plan 02: Schema Foundation Summary

**CLI backfill subcommand populates legislative_politician_id_map with bioguide IDs from congress-legislators YAML, using tiered matching (exact ID > name+state > skip ambiguous), plus data inventory matrix confirming all 5 jurisdictions fit the 8-table schema.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-02T01:43:37Z
- **Completed:** 2026-03-02T01:45:43Z
- **Tasks:** 2 completed
- **Files modified:** 3

## Accomplishments

- Created `backfill_ids.go` with full tiered-matching logic: downloads congress-legislators YAML via HTTP, builds bioguide and name+state lookup maps, matches NATIONAL_UPPER/NATIONAL_LOWER politicians, inserts bridge rows with dry-run support
- Wired `backfill-legislative-ids` CLI subcommand into `main.go` alongside existing import subcommands
- Created `data-model.md` with 5-jurisdiction x 8-data-type availability matrix, confirming no schema changes needed for empty jurisdictions

## Task Commits

Each task was committed atomically (in EV-Backend repo):

1. **Task 1: Create backfill_ids.go** - `66b43b9` (feat)
2. **Task 2: Wire CLI + data-model.md** - `bdd6a54` (feat)

## Files Created/Modified

- `EV-Backend/internal/essentials/backfill_ids.go` — BackfillLegislativeIDs function: HTTP download, YAML parse, tiered matching, bridge table inserts
- `EV-Backend/main.go` — Added `backfill-legislative-ids` case to CLI switch block
- `.planning/phases/54-schema-foundation/data-model.md` — Jurisdiction x data type availability matrix for Federal, Indiana, California, Bloomington IN, LA County CA

## Decisions Made

- **Tiered matching approach:** Tier 1 uses existing `bioguide_id` on the politician record (most federal politicians already have this from BallotReady). Tier 2 uses `last_name + representing_state` and only matches if exactly one result exists. Ambiguous (multiple matches) are logged as errors and skipped — no medium-confidence inserts that could create bad data.
- **Existence check before insert:** Used `db.DB.Where(...).First(&existing)` check rather than relying on ON CONFLICT clause, because GORM Create does not expose clean upsert semantics for UUID primary keys. The composite unique index in the schema still prevents actual duplicates at the database level.
- **NATIONAL_EXEC exclusion:** President, VP, and Cabinet members have no `bioguide_id` and do not appear in congress-legislators YAML. The query explicitly filters to `NATIONAL_UPPER` and `NATIONAL_LOWER` only.
- **goccy/go-yaml confirmed:** Already in go.mod as v1.18.0 (indirect, added in 54-01). Promoted to direct usage in backfill_ids.go import.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Bridge table is ready for backfill. Run `go run . backfill-legislative-ids --dry-run` to preview matches, then without `--dry-run` to populate the table.
- `data-model.md` confirms Phase 55 (federal bills + sessions via Congress.gov API) is the correct next step — data sources confirmed available.
- Phase 57 (LegiScan for IN/CA) and Phase 58 (Legistar for LA County) are confirmed feasible from the inventory matrix.
- Bloomington local vote data confirmed infeasible from any structured source — `legislative_votes` table will remain empty for Bloomington.

---
*Phase: 54-schema-foundation*
*Completed: 2026-03-02*

## Self-Check: PASSED

- [x] `EV-Backend/internal/essentials/backfill_ids.go` — found, contains BackfillLegislativeIDs function
- [x] `EV-Backend/main.go` — found, contains backfill-legislative-ids case
- [x] `.planning/phases/54-schema-foundation/data-model.md` — found, all 5 jurisdictions documented
- [x] Commit 66b43b9 — exists in EV-Backend git log
- [x] Commit bdd6a54 — exists in EV-Backend git log
