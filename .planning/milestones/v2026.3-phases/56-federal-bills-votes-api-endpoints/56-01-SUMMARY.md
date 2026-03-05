---
phase: 56-federal-bills-votes-api-endpoints
plan: "01"
subsystem: api
tags: [go, congress-gov, rate-limiting, http-client, pagination]

# Dependency graph
requires:
  - phase: 55-federal-committees-leadership
    provides: legiscan_client.go pattern for HTTP client with rate.Limiter
provides:
  - CongressClient struct with token bucket rate limiting (~4,500 req/hr)
  - fetchPaginated engine with len(items) < limit canonical stop condition
  - GetSponsoredLegislation, GetCosponsoredLegislation for member bill lists
  - GetHouseVoteList for House roll call enumeration
  - GetHouseVoteMemberVotes for per-member vote positions
  - GetBillSummary with CRS HTML stripping
  - normalizeVoteCast, normalizeVoteResult, normalizeBillStatus helpers
affects: [56-02-bills-import, 56-03-votes-import]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "fetchPaginated callback pattern: dest func([]byte) (int, error) — caller handles JSON parsing, returns item count"
    - "Token bucket rate limiting: rate.NewLimiter(rate.Every(800ms), 10) at 90% of API limit"
    - "Stop condition: n < limit (not n == 0, not pagination.next) — Congress.gov removed total field"
    - "Single-page requests for GetHouseVoteMemberVotes and GetBillSummary use limiter.Wait directly"

key-files:
  created:
    - EV-Backend/internal/essentials/congress_client.go
  modified: []

key-decisions:
  - "fetchPaginated stop condition is n < limit (not n == 0): Congress.gov silently truncates at 250 and removed the total field — round numbers do NOT mean more pages exist"
  - "GetBillSummary lowercases billType before URL path: Congress.gov requires lowercase bill type in /bill/{congress}/{type}/{number}/summaries"
  - "GetHouseVoteMemberVotes and GetBillSummary are non-paginated: member votes and summaries always fit in one response, so they use a direct limiter-throttled request"
  - "billType lowercased in GetBillSummary URL: API path requires lowercase (hr, s, hjres) not uppercase"

patterns-established:
  - "fetchPaginated callback: dest func([]byte) (int, error) returns parsed item count — pagination engine is agnostic to response shape"
  - "All client methods accept ctx context.Context for timeout and cancellation propagation"
  - "30s http.Client timeout guards against Congress.gov outages (confirmed January 2026)"

requirements-completed: [FED-03]

# Metrics
duration: 2min
completed: 2026-03-02
---

# Phase 56 Plan 01: Congress.gov HTTP Client Summary

**Token-bucket-rate-limited Congress.gov API v3 client with offset pagination engine, 5 typed methods, and vote/bill normalization helpers**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-02T15:35:47Z
- **Completed:** 2026-03-02T15:37:37Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- CongressClient struct with 800ms token bucket (burst 10, ~4,500 req/hr — 90% of the 5,000/hr limit)
- fetchPaginated engine with canonical n < limit stop condition; offset starts at 0, increments by 250
- Five typed convenience methods covering all Phase 56 data needs (sponsored bills, cosponsored bills, House vote list, member votes, bill summaries)
- normalizeVoteCast maps "Aye"/"Yea"/"Yes" variants to "yea"; handles "Not Voting"/"NV" to "not_voting"
- normalizeVoteResult maps "passed"/"agreed" and "failed"/"rejected" to canonical values
- normalizeBillStatus derives status from latest action text (Signed, Passed, Reported, In Committee, Introduced)
- stripHTMLTags cleans CRS summary HTML for plain-text storage

## Task Commits

Each task was committed atomically:

1. **Task 1: Create congress_client.go with CongressClient struct and fetchPaginated** - `1b08ccc` (feat)

**Plan metadata:** (see final commit)

## Files Created/Modified
- `EV-Backend/internal/essentials/congress_client.go` - CongressClient with rate limiting, pagination engine, 5 typed API methods, and normalization helpers (428 lines)

## Decisions Made
- `n < limit` (not `n == 0`) as stop condition — Congress.gov removed the `total` field; a round number does NOT guarantee more pages
- Non-paginated methods (GetHouseVoteMemberVotes, GetBillSummary) call `limiter.Wait` directly instead of going through fetchPaginated
- `billType` is lowercased in GetBillSummary URL path — Congress.gov API requires lowercase ("hr" not "HR")
- Sorted summaries by actionDate DESC to always return the most recent CRS text

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None — `go build ./...` passed on the first attempt.

## User Setup Required

External service configuration required: **Congress.gov API key**.

Register for a free API key at: https://api.congress.gov/sign-up/

Add to `EV-Backend/.env.local`:
```
CONGRESS_API_KEY=your-api-key-here
```

This key is consumed by the import CLIs in Plans 56-02 and 56-03. The CongressClient in this plan does not auto-read environment variables — callers (import CLIs) pass the key via `NewCongressClient(apiKey)`.

## Next Phase Readiness
- Plan 56-02 (bills import CLI) can now call `NewCongressClient(key)` and use `GetSponsoredLegislation` + `GetCosponsoredLegislation` + `GetBillSummary`
- Plan 56-03 (votes import CLI) can call `GetHouseVoteList` + `GetHouseVoteMemberVotes` + `normalizeVoteCast` + `normalizeVoteResult`
- Both plans depend on `legislative_politician_id_map` being populated (bridge table from Phase 54) — no blocker from this plan

---
*Phase: 56-federal-bills-votes-api-endpoints*
*Completed: 2026-03-02*
