---
phase: 27-cache-only-candidates-warmer-cleanup
verified: 2026-02-22T22:30:00Z
status: passed
score: 9/9 must-haves verified
re_verification: false
---

# Phase 27: Cache-Only Candidates & Warmer Cleanup — Verification Report

**Phase Goal:** All remaining BallotReady live API call sites are replaced — candidates come from the database, warmers are fully removed, and the BallotReady provider is de-registered at startup
**Verified:** 2026-02-22T22:30:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Candidate toggle on Essentials dashboard shows candidates sourced from essentials.election_records with no live BallotReady fetch | VERIFIED | `GetCandidatesByZip` at handlers.go:2451 queries `essentials.election_records er ... WHERE er.is_active = true AND er.withdrawn = false` via raw SQL; frontend `Results.jsx` calls `fetchCandidates(activeQuery)` which hits `/essentials/candidates/${zip}` |
| 2 | Politician profile page loads candidacy data from database without triggering a background goroutine to BallotReady | VERIFIED | `ensureCandidacyData` deleted (zero grep matches); `GetPoliticianByID` has no goroutine call; `GetPoliticianEndorsements`, `GetPoliticianStances`, `GetPoliticianElections` still present reading DB only |
| 3 | Backend starts without initializing or logging any BallotReady provider connection | VERIFIED | `ballotready` blank import removed from `setup.go`; `var Provider` and `provider.NewProvider()` initialization block deleted; `go build ./...` compiles cleanly |
| 4 | ZIP-based cache warmers (warmFederal, warmState, warmLocal) fully deleted — no stubs, no dead code | VERIFIED | Zero grep matches for `warmFederal\|warmState\|warmLocal\|warmZip` in `handlers.go`; lock infrastructure (`tryAcquireLock`, `releaseLock`, `isWarmingInProgress`, `tryAcquireZipWarmLock`, `releaseZipWarmLock`, `waitForDataMin`) also zero matches |
| 5 | GetCacheStatus endpoint and /cache-status/{zip} route are removed | VERIFIED | Zero matches for `GetCacheStatus\|getCacheStatus\|CacheStatusResponse` in `handlers.go`; zero matches for `cache-status` in `routes.go` |
| 6 | handleZipLookup returns DB-only results without cache freshness checks or warmer goroutines | VERIFIED | `handleZipLookup` at handlers.go:163-172 is 9 lines: derive state, call `fetchOfficialsFromDB`, set `X-Data-Status: fresh`, return JSON — no cache checks, no goroutines |
| 7 | FederalCache, StateCache, ZipCache GORM models removed; DROP TABLE statements added | VERIFIED | Zero grep matches in `models.go` and `setup.go` for those structs; `setup.go` lines 32-34 contain `DROP TABLE IF EXISTS essentials.federal_cache/state_caches/zip_caches` |
| 8 | Backend compiles without errors | VERIFIED | `go build ./...` passes with no output in EV-Backend |
| 9 | DB fetch functions (fetchOfficialsFromDB, fetchFederalAndStateFromDB, fetchStatewideFromDB) preserved | VERIFIED | All three functions present in `handlers.go` at lines 1057, 1338, 1330 respectively |

**Score:** 9/9 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `EV-Backend/internal/essentials/models.go` | `IsActive bool` field on `ElectionRecord`; no `FederalCache`/`StateCache`/`ZipCache` structs | VERIFIED | Line 244: `IsActive bool \`json:"is_active" gorm:"default:false"\``. Zero matches for cache structs. |
| `EV-Backend/internal/essentials/handlers.go` | DB-only `GetCandidatesByZip`, simplified `handleZipLookup`, no warmer functions, no `ensureCandidacyData`, no `ballotready` import | VERIFIED | All confirmed via grep. `GetCandidatesByZip` at line 2451 uses raw SQL on `election_records`. `handleZipLookup` at line 163 is 9 lines. |
| `EV-Backend/internal/essentials/routes.go` | No `/cache-status/{zip}` route; `/candidates/{zip}` route present | VERIFIED | Line 19: `r.Get("/candidates/{zip}", GetCandidatesByZip)`. Zero matches for `cache-status`. |
| `EV-Backend/internal/essentials/setup.go` | No ballotready blank import, no `Provider` var, DROP TABLE statements, no cache models in AutoMigrate | VERIFIED | Imports: only `log`, `db`, `geocoding`, and `_ cicero`. Lines 32-34: three DROP TABLE statements. AutoMigrate list contains only active models. |
| `EV-Backend/internal/essentials/admin.go` | No `WarmZip`/`WarmZipWith` exports; `runBulkImport` is a stub that marks job failed | VERIFIED | `runBulkImport` at line 139 logs deprecation message and marks job `failed` immediately. No warmer references. |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `handlers.go (GetCandidatesByZip)` | `essentials.election_records table` | Raw SQL join through politicians/offices/districts/chambers | WIRED | Query at handlers.go:2497-2516 selects from `essentials.election_records er` with `WHERE er.is_active = true AND er.withdrawn = false` |
| `handlers.go (handleZipLookup)` | `fetchOfficialsFromDB` | Direct call (no cache checks) | WIRED | handlers.go:165: `officials, err := fetchOfficialsFromDB(zip, state)` — single call, no freshness check, no goroutine |
| `setup.go (Init)` | `DROP TABLE statements` | Exec before AutoMigrate | WIRED | Lines 32-34 confirmed in setup.go; cache structs absent from AutoMigrate list at lines 36-59 |
| `GetPoliticianByID` | `database read only` | No `ensureCandidacyData` call | WIRED | Zero matches for `ensureCandidacyData` in handlers.go; `ExternalGlobalID` removed from profile query |
| `Results.jsx (toggle)` | `GET /essentials/candidates/{zip}` | `fetchCandidates()` in `useEffect` when `showCandidates=true` | WIRED | `api.jsx:153`: fetch to `/essentials/candidates/${zip}`; `Results.jsx:174`: `fetchCandidates(activeQuery)` inside `useEffect` gated on `showCandidates` |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BR-03 | 27-01, 27-02 | Background cache warmers (warmFederal, warmState, warmLocal) no longer call BallotReady API | SATISFIED | All three warmer functions deleted (zero grep matches); commit `791b6c2` confirms deletion of 1,294 lines |
| BR-04 | 27-02 | BallotReady provider is de-registered from setup (no initialization at startup) | SATISFIED | `ballotready` blank import removed from `setup.go`; `var Provider` and initialization block deleted; commit `9a1de3c` |
| CAND-01 | 27-01 | User can view cached candidate/race data from election_records table (no live BallotReady fetch) | SATISFIED | `GetCandidatesByZip` reads `essentials.election_records` with `is_active=true` filter; frontend toggle wired to endpoint; commit `5aeb4ee` |

All three requirement IDs declared in plan frontmatter are accounted for. No orphaned requirements found — REQUIREMENTS.md maps BR-03, BR-04, CAND-01 exclusively to Phase 27.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `admin.go` | 137-153 | `runBulkImport` is a placeholder that marks all jobs as immediately failed | INFO | Intentional — documented in SUMMARY as "deprecated in place"; not a stub blocking the phase goal; bulk import requires a future data pipeline |
| `cmd/bulk-import/main.go` | — | CLI tool deprecated in place (prints message and exits) | INFO | Intentional — documented decision to preserve git history; does not affect server behavior |

No BLOCKER or WARNING severity anti-patterns found. Both INFO items are intentional architectural decisions documented in the summaries.

---

### Human Verification Required

#### 1. Candidate Toggle — End-to-End

**Test:** On the Essentials dashboard, enter a ZIP code for an area with active candidates in the database (requires at least one `election_records` row with `is_active=true`), then toggle "Show Candidates".
**Expected:** The toggle triggers a fetch to `/essentials/candidates/{zip}`. If no active candidates exist in the DB for that ZIP, an empty state appears (not an error). If active candidates exist, cards render with election date.
**Why human:** Requires populated `election_records` data with `is_active=true` to confirm the render path works end-to-end. Automated checks confirm the API returns from DB, but cannot confirm the UI renders correctly without real data.

#### 2. Profile Page — No Goroutine on Load

**Test:** Open any politician profile page and observe backend logs.
**Expected:** No log line containing `ensureCandidacyData`, `FetchCandidacyData`, or any BallotReady-related output. Endorsements, stances, and elections sections appear (empty arrays if no data) without any background fetch delay.
**Why human:** Log observation requires running the server. Automated checks confirm the function is deleted, but cannot simulate a live profile page load.

#### 3. Server Startup — No BallotReady Connection Log

**Test:** Start the EV-Backend server and observe startup logs.
**Expected:** No log line referencing BallotReady initialization, provider registration, or API key validation. DROP TABLE lines for `federal_cache`, `state_caches`, `zip_caches` may appear (idempotent, harmless after first run).
**Why human:** Requires running the server to observe actual startup log output.

---

### Gaps Summary

No gaps found. All phase must-haves verified against actual codebase:

- GetCandidatesByZip is a genuine DB-only implementation (full SQL query, not a stub)
- All four warmer functions are completely absent — not stubbed, not commented out
- handleZipLookup is genuinely simplified to 9 lines with a direct DB call
- The BallotReady provider blank import is absent from setup.go; the Provider variable and initialization are gone
- All three cache table structs are deleted from models.go and setup.go AutoMigrate
- DROP TABLE IF EXISTS statements are present for all three cache tables
- The backend compiles cleanly
- Three commits in EV-Backend git history (5aeb4ee, 791b6c2, 9a1de3c) confirm the work is committed

The phase goal is achieved: BallotReady is fully disconnected from the running server.

---

_Verified: 2026-02-22T22:30:00Z_
_Verifier: Claude (gsd-verifier)_
