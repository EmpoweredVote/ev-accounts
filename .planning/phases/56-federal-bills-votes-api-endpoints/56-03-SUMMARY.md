---
phase: 56-federal-bills-votes-api-endpoints
plan: "03"
subsystem: api
tags: [go, legiscan, congress-api, legislative-votes, batch-import, cli]

requires:
  - phase: 56-01
    provides: CongressClient with GetHouseVoteList, GetHouseVoteMemberVotes; normalizeVoteCast, normalizeVoteResult helpers; LegiScanClient with Query, GetBudgetStatus, RemainingBudget; LegislativeVote and LegislativePoliticianIDMap models
  - phase: 55-01
    provides: getOrCreateSession function in import_committees.go for legislative session lookup/creation

provides:
  - ImportFederalVotes function: batch imports House votes from Congress.gov and Senate votes from LegiScan
  - buildLegiScanSenatorBridge: name-matching senators to bridge table with id_type='legiscan'
  - import-federal-votes CLI subcommand with --house-only, --senate-only, --congress=N, --max-errors=N, --dry-run flags
  - House external_vote_id format: house-{congress}-{session}-{rollCallNumber}
  - Senate external_vote_id format: legiscan-{roll_call_id}

affects:
  - 56-04 (votes API endpoints consume legislative_votes data populated by this importer)
  - future-56-phases (any phase serving vote history needs this import to have run first)

tech-stack:
  added: []
  patterns:
    - "getMasterList parsed as map[string]json.RawMessage (not array) — key '0' is session metadata, skip it"
    - "LegiScan budget check before Senate import; periodic budget check every 100 bills during import"
    - "Senator bridge via getSessionPeople name matching: single match only, ambiguous matches skipped"
    - "goto label used to break out of nested session loop on MaxErrors threshold"
    - "Dual-source vote import: Congress.gov for House, LegiScan for Senate — never mix sources"

key-files:
  created:
    - EV-Backend/internal/essentials/import_federal_votes.go
  modified:
    - EV-Backend/main.go

key-decisions:
  - "House = Congress.gov ONLY; Senate = LegiScan ONLY — Congress.gov API v3 does not include Senate roll calls"
  - "getMasterList response is a MAP not an array — key '0' is session metadata; iterate all other keys"
  - "Senator bridge built via getSessionPeople name matching before any vote import — single match only (no ambiguous inserts)"
  - "LegiScan budget checked before Senate import begins; warned if < 1000 queries remain; halted if < 100 during import"
  - "Individual vote failures are logged and skipped — import continues to maximize coverage per run"

requirements-completed: [FED-05]

duration: 3min
completed: 2026-03-02
---

# Phase 56 Plan 03: Federal Votes Import Summary

**Batch import of House roll call votes from Congress.gov and Senate roll call votes from LegiScan, with senator-to-politician name-matching bridge, into legislative_votes table via CLI import-federal-votes**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-02T15:41:02Z
- **Completed:** 2026-03-02T15:44:15Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `import_federal_votes.go` (688 lines) with dual-source import: House via Congress.gov, Senate via LegiScan
- Implemented `buildLegiScanSenatorBridge` with getSessionPeople name matching and id_type='legiscan' bridge inserts
- getMasterList correctly parsed as `map[string]json.RawMessage` (not array), key "0" session metadata skipped
- LegiScan budget checked before Senate import; periodic budget check every 100 bills halts import if < 100 queries remain
- Wired `import-federal-votes` CLI case in main.go with all required flags and env var guards

## Task Commits

Each task was committed atomically:

1. **Task 1: Create import_federal_votes.go with House and Senate import workflows** - `367770e` (feat)
2. **Task 2: Wire import-federal-votes CLI subcommand in main.go** - `9f709f2` (feat)

## Files Created/Modified

- `EV-Backend/internal/essentials/import_federal_votes.go` - ImportFederalVotes function with House/Senate workflows, LegiScan bridge building, and all helper functions
- `EV-Backend/main.go` - import-federal-votes case with --dry-run, --house-only, --senate-only, --congress=N, --max-errors=N flags

## Decisions Made

- getMasterList must be parsed as a map, not an array — the JSON structure is `{"masterlist": {"0": {metadata}, "1": {bill}, ...}}`. Parsing as `[]json.RawMessage` would silently fail.
- Senator bridge uses single-match name lookup only. Multiple matches on the same name are skipped rather than guessing — data correctness prioritized over coverage.
- House and Senate import are cleanly separated into different code paths. No cross-contamination: House roll calls in LegiScan getBill responses are skipped (`Chamber != "S"`), LegiScan is never called for House.
- `goto houseDone` used to break out of nested congress/session/rollcall loop when MaxErrors threshold is reached — cleaner than passing error signals through multiple levels.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The EV-Backend directory has its own git repository. File staging required `git -C /path/to/EV-Backend add ...` rather than the workspace-level git.
- main.go had been modified since initially read (56-02 had already added import-federal-bills case). Re-read before editing resolved the conflict.

## User Setup Required

None - no external service configuration required at build time. CONGRESS_API_KEY and LEGISCAN_API_KEY are runtime env vars, not build-time.

## Next Phase Readiness

- `import-federal-votes` is ready to run once API keys are configured and the legislative_politician_id_map has been populated by `backfill-legislative-ids` (from Phase 54)
- Plan 56-04 API endpoints (GetPoliticianVotes, GetPoliticianBills, GetPoliticianLegislativeSummary) consume the legislative_votes data this importer writes — those endpoints are complete per STATE.md
- Phase 56 is fully complete (all 4 plans done per STATE.md)

---
*Phase: 56-federal-bills-votes-api-endpoints*
*Completed: 2026-03-02*
