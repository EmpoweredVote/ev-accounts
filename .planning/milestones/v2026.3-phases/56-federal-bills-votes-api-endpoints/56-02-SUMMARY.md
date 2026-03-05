---
phase: 56-federal-bills-votes-api-endpoints
plan: "02"
subsystem: api
tags: [go, congress-gov, bills, import, cli, upsert, crs-summaries]

# Dependency graph
requires:
  - phase: 56-federal-bills-votes-api-endpoints
    plan: "01"
    provides: CongressClient with GetSponsoredLegislation, GetCosponsoredLegislation, GetBillSummary
  - phase: 54-legislative-data-model
    provides: legislative_politician_id_map bridge table with bioguide entries
provides:
  - ImportFederalBills function with Config/Result structs in import_federal_bills.go
  - import-federal-bills CLI subcommand in main.go
  - upsertSponsoredBill helper (sets SponsorID, updates on conflict)
  - upsertCosponsoredBill helper (preserves existing SponsorID)
  - fetchMissingSummaries batch CRS summary updater
  - parseBillExternalID helper for "{congress}-{type}-{number}" format
affects: [56-04-api-endpoints, 56-03-votes-import]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Sponsored vs cosponsored upsert split: two separate helpers with different OnConflict DoUpdates columns — sponsored includes sponsor_id, cosponsored excludes it"
    - "Post-upsert SELECT pattern: after OnConflict Create, query back by (external_id, jurisdiction) to get the DB UUID for downstream linking"
    - "Bill external_id format: '{congress}-{type}-{number}' (e.g., '119-HR-1044') — congress number required to prevent 118/119 collisions"
    - "Consecutive error abort: counter resets on any success; aborts at MaxErrors threshold with informative error message"
    - "CRS summary phase: separate pass over bills with empty summary after all bill upserts complete — keeps main loop fast"

key-files:
  created:
    - EV-Backend/internal/essentials/import_federal_bills.go
  modified:
    - EV-Backend/main.go

key-decisions:
  - "Post-upsert SELECT to get bill DB UUID: GORM OnConflict Create does not reliably populate the struct ID field for existing rows — a follow-up SELECT by (external_id, jurisdiction) is required"
  - "Cosponsored bill upsert excludes sponsor_id from DoUpdates: the bill may already exist with the correct sponsor; overwriting with nil would corrupt sponsorship data"
  - "parseBillExternalID uses SplitN with n=3: handles bill types like 'HJRES' and numbers that may themselves contain '-' (though uncommon)"

patterns-established:
  - "ImportFederalBills follows same Config/Result struct pattern as ImportCommittees and ImportLeadership"
  - "CLI flag parsing uses switch/case with strings.HasPrefix for --key=value flags — consistent with import-committees pattern"

requirements-completed: [FED-04, FED-06]

# Metrics
duration: 3min
completed: 2026-03-02
---

# Phase 56 Plan 02: Federal Bills Import CLI Summary

**Congress.gov sponsored/cosponsored bill importer with sponsor-preserving upsert logic, consecutive-error abort, and CRS plain-text summary backfill**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-02T15:41:00Z
- **Completed:** 2026-03-02T15:43:09Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- ImportFederalBills function iterates all bioguide bridge entries for each configured congress number, fetching sponsored and cosponsored legislation
- Sponsored bill upsert sets SponsorID and updates it on conflict; cosponsored upsert explicitly excludes sponsor_id from DoUpdates to preserve existing attribution
- Cosponsorship links upserted into legislative_bill_cosponsors with DoNothing on (bill_id, politician_id)
- CRS summary fetch phase runs as a separate pass after all bills are imported — queries bills with empty summary, fetches via GetBillSummary, updates in place
- CLI subcommand supports --dry-run, --skip-summaries, --congress=N, --max-errors=N; reads CONGRESS_API_KEY from env

## Task Commits

Each task was committed atomically:

1. **Task 1: Create import_federal_bills.go with ImportFederalBills function** - `1bc7e6a` (feat)
2. **Task 2: Wire import-federal-bills CLI subcommand in main.go** - `da3b144` (feat)

**Plan metadata:** (see final commit)

## Files Created/Modified
- `EV-Backend/internal/essentials/import_federal_bills.go` - ImportFederalBills with Config/Result structs, upsertSponsoredBill, upsertCosponsoredBill, fetchMissingSummaries, parseBillExternalID helpers (413 lines)
- `EV-Backend/main.go` - Added import-federal-bills CLI case with four flags and CONGRESS_API_KEY env check

## Decisions Made
- Post-upsert SELECT is required: GORM OnConflict Create does not reliably return the struct's ID field for existing rows — a follow-up SELECT by (external_id, jurisdiction) ensures the correct UUID is returned for cosponsor linking
- Cosponsored bill upsert excludes `sponsor_id` from DoUpdates columns — the bill may already have been imported via another member's sponsored list with the correct primary sponsor set
- `parseBillExternalID` uses `strings.SplitN(id, "-", 3)` with n=3 to correctly handle edge cases where the bill number portion might contain a dash

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None — `go build ./...` passed on the first attempt.

## User Setup Required
**External service configuration required: Congress.gov API key.**

Add to `EV-Backend/.env.local`:
```
CONGRESS_API_KEY=your-congress-gov-api-key-here
```

Register for a free key at: https://api.congress.gov/sign-up/

Usage:
```bash
# Import 119th and 118th Congress bills for all bioguide-mapped politicians:
go run . import-federal-bills

# Import only 119th Congress, skip CRS summaries (faster for testing):
go run . import-federal-bills --congress=119 --skip-summaries

# Dry run to see what would be imported:
go run . import-federal-bills --dry-run
```

## Next Phase Readiness
- Plan 56-03 (votes import CLI) can now proceed using the same CongressClient from 56-01
- Plan 56-04 (bills/votes/legislative-summary API endpoints) already complete — the import CLI populates the data those endpoints serve
- Bills data ready to import once CONGRESS_API_KEY is configured in the deployment environment

## Self-Check: PASSED

- `EV-Backend/internal/essentials/import_federal_bills.go` — FOUND
- `.planning/phases/56-federal-bills-votes-api-endpoints/56-02-SUMMARY.md` — FOUND
- Commit `1bc7e6a` (feat: add ImportFederalBills) — FOUND in EV-Backend git log
- Commit `da3b144` (feat: wire CLI subcommand) — FOUND in EV-Backend git log
- `go build ./...` — PASSED

---
*Phase: 56-federal-bills-votes-api-endpoints*
*Completed: 2026-03-02*
