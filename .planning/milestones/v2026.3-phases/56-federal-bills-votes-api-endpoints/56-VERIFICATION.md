---
phase: 56-federal-bills-votes-api-endpoints
verified: 2026-03-02T00:00:00Z
status: passed
score: 12/12 must-haves verified
re_verification: false
---

# Phase 56: Federal Bills, Votes & API Endpoints Verification Report

**Phase Goal:** Federal politicians' voting records and sponsored legislation are pre-imported via batch CLI and all 5 legislative API endpoints are live
**Verified:** 2026-03-02
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | CongressClient struct wraps net/http.Client with rate.Limiter enforcing ~4,500 req/hr (token every 800ms, burst 10) | VERIFIED | `congress_client.go:39` — `rate.NewLimiter(rate.Every(800*time.Millisecond), 10)` with `http.Client{Timeout: 30*time.Second}` |
| 2  | fetchPaginated method pages through Congress.gov API responses using `n < limit` as the stop condition | VERIFIED | `congress_client.go:114` — `if n < limit { break }` with comment: "Never use pagination.next or assume a round number means there are more pages." |
| 3  | Convenience methods GetSponsoredLegislation, GetCosponsoredLegislation, GetHouseVoteList, GetHouseVoteMemberVotes, and GetBillSummary exist and return typed responses | VERIFIED | `congress_client.go` lines 174, 199, 224, 248, 306 — all 5 methods confirmed, typed responses |
| 4  | `go run . import-federal-bills` fetches sponsored and cosponsored legislation for all politicians with bioguide bridge rows | VERIFIED | `import_federal_bills.go` + `main.go:232` — CLI case with CONGRESS_API_KEY env check, bioguide map loaded from bridge table |
| 5  | Bills for 119th and 118th Congress are imported by default | VERIFIED | `import_federal_bills.go:64` — default `[]int{119, 118}` if CongressNumbers empty |
| 6  | Bill external_id includes Congress number (e.g., '119-HR-1044') | VERIFIED | `import_federal_bills.go:228` — `fmt.Sprintf("%d-%s-%s", congressNum, bill.Type, bill.Number)` |
| 7  | CRS plain-language summaries fetched and stored with HTML stripped | VERIFIED | `fetchMissingSummaries` function in `import_federal_bills.go:347` calls `GetBillSummary` which strips HTML via `stripHTMLTags` |
| 8  | `go run . import-federal-votes` imports House roll call votes (Congress.gov) and Senate votes (LegiScan) | VERIFIED | `import_federal_votes.go` — `ImportFederalVotes` function; `main.go:280` — CLI case with dual-source import |
| 9  | Senate votes matched via LegiScan people_id bridge with id_type='legiscan' | VERIFIED | `import_federal_votes.go:355` — `buildLegiScanSenatorBridge` with getSessionPeople name matching; `bridge.IDType = "legiscan"` at line 454 |
| 10 | GET /politician/{id}/bills returns sponsored and cosponsored legislation with is_sponsor flag, status, and introduction date | VERIFIED | `handlers.go:3111` — `GetPoliticianBills` with `?all=true` filter, `?limit=N`, JOIN on cosponsors table, `is_sponsor` CASE expression |
| 11 | GET /politician/{id}/votes returns voting record with bill title, position, vote date, and outcome | VERIFIED | `handlers.go:3203` — `GetPoliticianVotes` with LEFT JOIN on legislative_bills for bill context, `?limit=N` (max 250) |
| 12 | GET /politician/{id}/legislative-summary returns 5 recent bills + 10 recent votes in single response | VERIFIED | `handlers.go:3277` — `GetPoliticianLegislativeSummary` with LIMIT 5 and LIMIT 10 subqueries, returns `LegislativeSummaryOut` |

**Score:** 12/12 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `EV-Backend/internal/essentials/congress_client.go` | CongressClient struct with rate limiting, fetchPaginated, typed API methods | VERIFIED | 428 lines; CongressClient, fetchPaginated, 5 typed methods, normalizeVoteCast, normalizeVoteResult, normalizeBillStatus, stripHTMLTags all present |
| `EV-Backend/internal/essentials/import_federal_bills.go` | ImportFederalBills function with Config/Result structs | VERIFIED | 413 lines (exceeds min_lines:200); ImportFederalBills, ImportFederalBillsConfig, ImportFederalBillsResult, upsertSponsoredBill, upsertCosponsoredBill, fetchMissingSummaries, parseBillExternalID |
| `EV-Backend/main.go` (import-federal-bills case) | import-federal-bills CLI subcommand | VERIFIED | Lines 232-279: case with --dry-run, --skip-summaries, --congress=N, --max-errors=N, CONGRESS_API_KEY env guard |
| `EV-Backend/internal/essentials/import_federal_votes.go` | ImportFederalVotes function with House and Senate import workflows | VERIFIED | 688 lines (exceeds min_lines:300); dual-source import, buildLegiScanSenatorBridge, importSenateVotes, houseVoteUpsert |
| `EV-Backend/main.go` (import-federal-votes case) | import-federal-votes CLI subcommand | VERIFIED | Lines 280-331: case with --dry-run, --house-only, --senate-only, --congress=N, --max-errors=N, dual env var guards |
| `EV-Backend/internal/essentials/handlers.go` | GetPoliticianBills, GetPoliticianVotes, GetPoliticianLegislativeSummary handlers; LegislativeBillOut and LegislativeVoteOut DTOs | VERIFIED | Lines 133-158 (DTOs), 3111-3390 (handlers); all present with correct query params and SQL |
| `EV-Backend/internal/essentials/routes.go` | Three new route registrations under /politician/{id}/ | VERIFIED | Lines 31-33: bills, votes, legislative-summary all registered as public routes after Phase 55 block |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `congress_client.go` | golang.org/x/time/rate | `rate.NewLimiter(rate.Every(800*time.Millisecond), 10)` | WIRED | Line 39 confirmed |
| `congress_client.go fetchPaginated` | Congress.gov API | HTTP GET with offset pagination, stop on `n < limit` | WIRED | Lines 56-122; `if n < limit { break }` at line 114 |
| `import_federal_bills.go` | `congress_client.go` | `GetSponsoredLegislation`, `GetCosponsoredLegislation`, `GetBillSummary` | WIRED | Lines 120, 150, 372 confirmed calls |
| `import_federal_bills.go` | `essentials.legislative_bills` | GORM `clause.OnConflict` upsert on `external_id + jurisdiction` | WIRED | Lines 260-268 (sponsored), 320-328 (cosponsored) — `Columns: [{external_id}, {jurisdiction}]` |
| `import_federal_bills.go` | `essentials.legislative_bill_cosponsors` | GORM `clause.OnConflict{DoNothing: true}` | WIRED | Lines 181-184 — `Clauses(clause.OnConflict{DoNothing: true}).Create(&cosponsor)` |
| `import_federal_bills.go` | `essentials.legislative_politician_id_map` | Bridge table lookup with `id_type = "bioguide"` | WIRED | Lines 85-94 — `Where("id_type = ?", "bioguide")` |
| `import_federal_votes.go` | `congress_client.go` | `GetHouseVoteList`, `GetHouseVoteMemberVotes` | WIRED | Lines 103, 145 confirmed calls |
| `import_federal_votes.go` | `legiscan_client.go` | `Query` for getSessionList, getMasterList, getBill, getRollCall, getSessionPeople | WIRED | Lines 326, 363, 485, 541, 596 confirmed |
| `import_federal_votes.go` | `essentials.legislative_votes` | GORM `clause.OnConflict` upsert on `politician_id + bill_id + session_id + external_vote_id` | WIRED | Lines 278-286 (House), 663-671 (Senate) |
| `import_federal_votes.go` | `essentials.legislative_politician_id_map` (legiscan) | Bridge insert for id_type='legiscan' via name matching | WIRED | Lines 392 (load existing), 453-460 (insert new) — `IDType: "legiscan"` |
| `handlers.go GetPoliticianBills` | `essentials.legislative_bills + essentials.legislative_bill_cosponsors` | Raw SQL JOIN with sponsor_id check and cosponsor subquery | WIRED | Lines 3157-3174 — subquery `SELECT bill_id FROM essentials.legislative_bill_cosponsors` |
| `handlers.go GetPoliticianVotes` | `essentials.legislative_votes LEFT JOIN essentials.legislative_bills` | Raw SQL with LEFT JOIN for bill context | WIRED | Lines 3240-3255 — `LEFT JOIN essentials.legislative_bills b ON b.id = v.bill_id` |
| `routes.go` | `handlers.go` | Chi route registration for bills, votes, legislative-summary | WIRED | Lines 31-33 confirmed; all 3 routes call correct handlers |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| FED-03 | 56-01 | Congress.gov API client with rate limiting (5K req/hr) and exhaustive pagination (250-item page cap handling) | SATISFIED | `congress_client.go`: `rate.NewLimiter(rate.Every(800ms), 10)` at 90% of limit; fetchPaginated with `n < limit` stop; builds without errors |
| FED-04 | 56-02 | Sponsored and cosponsored legislation imported for federal politicians via Congress.gov API (current + previous Congress) | SATISFIED | `import_federal_bills.go`: Congress 119+118 default; `GetSponsoredLegislation` + `GetCosponsoredLegislation`; `import-federal-bills` CLI live in main.go |
| FED-05 | 56-03 | Voting records batch-imported for federal politicians — House via Congress.gov API, Senate via LegiScan (current + previous Congress) | SATISFIED | `import_federal_votes.go`: House via CongressClient, Senate via LegiScanClient; dual-source, dual-congress; `import-federal-votes` CLI live |
| FED-06 | 56-02 | CRS plain-language bill summaries fetched from Congress.gov and stored alongside bill records | SATISFIED | `fetchMissingSummaries` in `import_federal_bills.go:347`: queries bills with empty summary, calls `GetBillSummary`, strips HTML, updates DB |
| API-01 | 56-04 | GET /politician/{id}/committees returns committee assignments with roles for any government level | SATISFIED | Route registered in `routes.go:27`; handler `GetPoliticianCommittees` in handlers.go (Phase 55, confirmed present) |
| API-02 | 56-04 | GET /politician/{id}/leadership returns leadership positions with date ranges | SATISFIED | Route registered in `routes.go:28`; handler `GetPoliticianLeadership` in handlers.go (Phase 55, confirmed present) |
| API-03 | 56-04 | GET /politician/{id}/bills returns sponsored and cosponsored legislation with status | SATISFIED | Route `routes.go:31`; `GetPoliticianBills` handler with `?all=true` filter and `?limit=N`; returns `LegislativeBillOut[]` |
| API-04 | 56-04 | GET /politician/{id}/votes returns voting record with bill info and position | SATISFIED | Route `routes.go:32`; `GetPoliticianVotes` handler with LEFT JOIN for bill title/number/URL; returns `LegislativeVoteOut[]` |
| API-05 | 56-04 | GET /politician/{id}/legislative-summary returns bounded overview for initial profile render | SATISFIED | Route `routes.go:33`; `GetPoliticianLegislativeSummary` returns `LegislativeSummaryOut{RecentBills(5), RecentVotes(10)}` |

**Orphaned requirements check:** REQUIREMENTS.md maps FED-03, FED-04, FED-05, FED-06, API-01 through API-05 to Phase 56. All 9 are claimed in plan frontmatter and verified. No orphaned requirements.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `import_federal_votes.go` | 159 | `result := houseVoteUpsert(...)` then `_ = result` — local variable shadows outer `result`, returned value immediately discarded. The actual mutation is via pointer `&result` so `HouseVotesUpserted` still updates correctly. | Warning | No runtime impact — pointer mutation works correctly. Cosmetic dead-assignment. |

No blocker anti-patterns. The shadowing is cosmetic — `houseVoteUpsert` receives `&result` (pointer to the function-scoped `ImportFederalVotesResult`) and mutates it directly; the locally-assigned return value is correctly ignored with `_ = result`.

---

## Build Verification

`cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build ./...` — **PASSED** (no output = no errors)

---

## Human Verification Required

### 1. Congress.gov API Key Available in Deployment Environment

**Test:** Set `CONGRESS_API_KEY` env var and run `go run . import-federal-bills --skip-summaries --congress=119`
**Expected:** CLI logs bioguide bridge entries, fetches sponsored legislation, upserts bills into `essentials.legislative_bills`
**Why human:** Requires external API key and live database connection — cannot verify programmatically

### 2. LegiScan API Key and Budget for Senate Import

**Test:** Set `LEGISCAN_API_KEY` and run `go run . import-federal-votes --senate-only --congress=119`
**Expected:** Budget logged, senator bridge built via getSessionPeople, Senate votes upserted into `essentials.legislative_votes`
**Why human:** Requires live LegiScan API key with budget remaining, and populated `legislative_politician_id_map`

### 3. API Endpoints Return Correct Data After Import

**Test:** After at least one bill/vote import run, call `GET /essentials/politician/{id}/bills` and `GET /essentials/politician/{id}/votes` with a known federal politician UUID
**Expected:** Bills array with `external_id` in `119-HR-NNNN` format, `is_sponsor` boolean, `status_label` one of (Signed/Passed/Reported/In Committee/Introduced); votes array with `position` one of (yea/nay/not_voting/present/absent)
**Why human:** Requires live database with imported data to validate response shape beyond empty arrays

### 4. Bills Significance Filter Behavior

**Test:** Call `GET /essentials/politician/{id}/bills` (default) and `GET /essentials/politician/{id}/bills?all=true` for a prolific House member
**Expected:** Default call omits "Introduced" bills; `?all=true` includes them (delta visible in response)
**Why human:** Cannot assess filter correctness without imported bill data in the database

### 5. Votes Limit Parameter

**Test:** Call `GET /essentials/politician/{id}/votes?limit=5` and `GET /essentials/politician/{id}/votes?limit=300`
**Expected:** First returns at most 5 votes; second returns at most 250 (capped by `if pageLimit > 250`)
**Why human:** Requires live imported data to see limit behavior in action

---

## Gaps Summary

No gaps found. All artifacts exist and are substantive (well above minimum line counts), all key links are wired, all requirement IDs are satisfied, and the build compiles clean. The one anti-pattern noted (shadowed `result` variable in `import_federal_votes.go:159`) is cosmetic — pointer mutation means `HouseVotesUpserted` is correctly tracked.

The phase goal is fully achieved at the code level: all 4 CLIs exist (`import-federal-bills`, `import-federal-votes`, plus the Phase 55 `import-committees`/`import-leadership` that are confirmed in routes.go), all 5 legislative API endpoints are registered and return correct data structures, and the build passes without errors. Runtime verification (actual API calls and database population) requires human testing with live API keys.

---

_Verified: 2026-03-02_
_Verifier: Claude (gsd-verifier)_
