---
phase: 90-campaign-finance-schema-ingestion-api
verified: 2026-06-04T11:30:00Z
status: gaps_found
score: 3/4 roadmap success criteria verified
overrides_applied: 0
gaps:
  - truth: "All target federal politicians (senators + 2026 candidates) have finance_summary populated — SELECT COUNT WHERE finance_summary IS NULL returns 0 for target set"
    status: failed
    reason: "57 of 258 enumerated federal politicians have NULL finance_summary: 44 skipped (no FEC ID found in either crosswalk path) + 13 errored (FEC API timeouts during the run). ROADMAP SC2 requires 0 NULL for the target set. Q1 count of 203 non-null met the PLAN's weaker acceptance criterion (>= 100) but not the ROADMAP bar."
    artifacts:
      - path: "backend/scripts/run-fec-finance-summary.ts"
        issue: "Script correctly logs and skips politicians with no FEC ID (intended design), but ROADMAP SC2 requires all target politicians to be populated. 13 timeout errors are recoverable by re-run. 44 skipped politicians need FEC IDs added to transparent_motivations.politician_sources."
    missing:
      - "Re-run script to recover 13 FEC API timeout errors (idempotent — safe to re-run)"
      - "Add politician_sources rows for 44 skipped politicians (FEC IDs not in either crosswalk): list in 90-02-SUMMARY.md"
  - truth: "getRepresentativesByAddress, getRepresentativesByJurisdiction, and getLocalOfficialsByUserId SELECT clauses include p.finance_summary"
    status: failed
    reason: "Code review CR-01 and CR-02 (confirmed by reading essentialsService.ts lines 588-696 and 1506-1528 and 1676-1698): four query paths that return PoliticianFlatRecord[] omit p.finance_summary from their SELECT lists. Row mappers correctly include finance_summary: row.finance_summary ?? null, so result is always null instead of actual FEC data for federal politicians returned via these endpoints. FINA-03 explicitly scopes to GET /api/essentials/politicians and single-politician endpoints (getPoliticiansFlatList + getPoliticianById), which ARE correctly wired. But this issue means federal senators and House members returned via address lookup and jurisdiction lookup will never surface finance data."
    artifacts:
      - path: "backend/src/lib/essentialsService.ts"
        issue: "districtQueryText (line 588) and statewideQueryText (line 652) in getRepresentativesByAddress missing p.finance_summary in SELECT. SELECT_FIELDS constant in getRepresentativesByJurisdiction (line 1506) and getLocalOfficialsByUserId (line 1676) missing p.finance_summary."
    missing:
      - "Add p.finance_summary to districtQueryText in getRepresentativesByAddress (after p.is_incumbent)"
      - "Add p.finance_summary to statewideQueryText in getRepresentativesByAddress (after p.is_incumbent)"
      - "Add p.finance_summary to SELECT_FIELDS in getRepresentativesByJurisdiction (line ~1511)"
      - "Add p.finance_summary to SELECT_FIELDS in getLocalOfficialsByUserId (line ~1681)"
---

# Phase 90: Campaign Finance Schema + Ingestion + API Verification Report

**Phase Goal:** Campaign Finance Schema + FEC Ingestion + API Surface — add finance_summary JSONB to essentials.politicians, populate via FEC API for federal politicians, surface on GET /api/essentials/politicians endpoints
**Verified:** 2026-06-04T11:30:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | finance_summary column exists on essentials.politicians (verified via information_schema query) | VERIFIED | migration 268 file exists at backend/migrations/268_finance_summary_column.sql; SUMMARY Task 2 shows `information_schema.columns` returned 1 row with data_type=jsonb, is_nullable=YES |
| SC2 | All target federal politicians (senators + 2026 candidates) have finance_summary populated — SELECT COUNT WHERE finance_summary IS NULL returns 0 for target set | FAILED | Script run: 201 succeeded, 44 skipped (no FEC ID), 13 errors (API timeouts) = 57 with NULL. Q1 count = 203 non-null (meets plan's >= 100 bar, not roadmap's = 0 bar) |
| SC3 | Spot-check: one senator has total_raised (positive integer), top_donors 3+ entries, source="FEC" | VERIFIED | SUMMARY Q2: Jon Ossoff $81,146,109 / 10 donors / cycle=2026 / source=FEC |
| SC4 | GET /api/essentials/politicians response includes finance_summary field — null for non-federal, populated for federal | VERIFIED | SUMMARY smoke tests: LIST OK (191 with data), DETAIL OK (Jon Ossoff), NULL OK (William Ellis, LOCAL); vitest 5/5 passing |

**Score:** 3/4 roadmap success criteria verified

### Plan Must-Have Truths (across all three plans)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| P01-T1 | essentials.politicians has a new nullable JSONB column named finance_summary | VERIFIED | `268_finance_summary_column.sql` exists; `ADD COLUMN IF NOT EXISTS finance_summary JSONB`; COMMENT present with all 4 key names |
| P01-T2 | Migration applied to remote Supabase DB before ingestion | VERIFIED | SUMMARY Task 2: information_schema query returned 1 row, data_type=jsonb, is_nullable=YES |
| P01-T3 | Wave-0 test scaffold exists and was RED before Plan 03 | VERIFIED | SUMMARY confirms 5 failed tests; vitest run confirmed 5/5 passing after Plan 03 |
| P02-T1 | Federal politicians have finance_summary populated with FEC-sourced data | PARTIAL | 201/258 succeeded (78%); 57 NULL — but all 100 sitting senators claimed covered (see UNCERTAIN note below) |
| P02-T2 | Every populated finance_summary has the four canonical keys: total_raised, top_donors, cycle, source | VERIFIED | Q2 spot-check confirms shape; migration COMMENT documents all 4 keys; script builds explicit object (no raw FEC spread) |
| P02-T3 | Crosswalk uses politician_sources (Path 2) and congress-legislators YAML (Path 1) | VERIFIED | Script contains both: `transparent_motivations.politician_sources` query at line 193; YAML URL at line 43 |
| P02-T4 | Script is idempotent | VERIFIED | Parameterized UPDATE (not INSERT); SUMMARY confirms re-run recovers timeouts |
| P02-T5 | Politicians with no matched FEC ID are logged as skipped and left with NULL | VERIFIED | 44 skipped documented by name in SUMMARY; `skipped_no_fec_id: 44` in JSON summary |
| P03-T1 | GET /api/essentials/politicians response objects include a finance_summary field | VERIFIED | `getPoliticiansFlatList` SELECT at line 440: `p.finance_summary`; row mapper at line 534; smoke test LIST OK |
| P03-T2 | GET /api/essentials/politicians/:id response includes a finance_summary field | VERIFIED | `getPoliticianById` SELECT at line 976: `p.finance_summary`; row mapper at line 1200; smoke test DETAIL OK |
| P03-T3 | finance_summary is null for politicians with no FEC data | VERIFIED | smoke test NULL OK (William Ellis, LOCAL district) |
| P03-T4 | finance_summary is a JSON object (not a string) in API responses | VERIFIED | SUMMARY: "Pitfall 6 did not manifest — JSONB returned as object by default"; no JSON.parse wrapper needed |
| P03-T5 | No existing PoliticianFlatRecord or PoliticianDetail field changes | VERIFIED | TSC clean; diff adds only finance_summary at end of both interfaces |
| P03-T6 | All five Wave-0 tests are GREEN | VERIFIED | `npx vitest run test/essentialsService-finance-summary.test.ts`: 5 passed, 0 failed (verified by running) |

**UNCERTAIN finding on senator coverage:** SUMMARY claims "senator-only count: 100 (all 100 sitting senators have finance_summary)" but the errored list includes 7 sitting senators (Angus King, Raphael Warnock, Ron Johnson, Shelley Moore Capito, Ted Budd, Ted Cruz, Tim Kaine) where "DB was not written." These 7 may be senator re-election candidate records separate from their senator records (possible if each senator has two DB records: one for their current term, one for their 2026 campaign). Cannot verify without running remote DB query. The Q1 count of 203 is plausible either way.

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/migrations/268_finance_summary_column.sql` | DDL adding finance_summary JSONB to essentials.politicians | VERIFIED | Exists; contains `ALTER TABLE essentials.politicians ADD COLUMN IF NOT EXISTS finance_summary JSONB`; COMMENT with all 4 key names; no inform.politicians reference; no index |
| `backend/scripts/run-fec-finance-summary.ts` | FEC ingestion script — two-path crosswalk, 3 FEC API calls/politician, pool.query UPDATE | VERIFIED | Exists; contains all required endpoint URLs, transparent_motivations.politician_sources, legislators-current YAML, SLEEP constant = 1500, explicit FinanceSummary object construction; no raw FEC response spread |
| `backend/test/essentialsService-finance-summary.test.ts` | 5-test source-scan vitest file | VERIFIED | Exists; imports vitest + node:fs + node:path; fs.readFileSync; stripComments helper; 5 it() tests; no runtime import from essentialsService; vitest confirms 5/5 passing |
| `backend/src/lib/essentialsService.ts` | FinanceSummary interface + 2 interface fields + 2 SELECTs + 2 row mappers | VERIFIED (FINA-03 scope) | FinanceSummary exported at line 88; PoliticianFlatRecord field at line 150; PoliticianDetail field at line 928; SELECT in getPoliticiansFlatList at line 440; SELECT in getPoliticianById at line 976; mappers at lines 534 and 1200 |
| `backend/src/lib/essentialsService.ts` (other query paths) | p.finance_summary in getRepresentativesByAddress, getRepresentativesByJurisdiction, getLocalOfficialsByUserId SELECT | FAILED | districtQueryText (line 588), statewideQueryText (line 652), getRepresentativesByJurisdiction SELECT_FIELDS (line 1506), getLocalOfficialsByUserId SELECT_FIELDS (line 1676) — all MISSING p.finance_summary. Row mappers at lines 782, 1642, 1773 exist but receive undefined -> null due to missing SELECT |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| migration 268 | essentials.politicians.finance_summary | `ALTER TABLE essentials.politicians ADD COLUMN IF NOT EXISTS finance_summary JSONB` | VERIFIED (claimed) | SUMMARY confirms information_schema verification passed; cannot re-run remote DB query |
| run-fec-finance-summary.ts | FEC API (3 endpoints) | native fetch with 1500ms sleep | VERIFIED | File contains `api.open.fec.gov/v1/candidates/search/`, `candidates/totals/`, `schedules/schedule_a/by_employer/` and `SLEEP_BETWEEN_FEC_CALLS_MS = 1500` |
| run-fec-finance-summary.ts | essentials.politicians SET finance_summary | pool.query parameterized UPDATE | VERIFIED | Line 325: `pool.query('UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2', ...)` |
| run-fec-finance-summary.ts | transparent_motivations.politician_sources (Path 2 crosswalk) | pool.query SELECT WHERE source_system LIKE 'fec%' AND research_status='confirmed' | VERIFIED | Lines 187-195: Path 2 query with correct filters |
| GET /api/essentials/politicians | essentials.politicians.finance_summary | getPoliticiansFlatList SELECT p.finance_summary -> PoliticianFlatRecord | VERIFIED | Line 440 (SELECT), line 534 (mapper), smoke test LIST OK |
| GET /api/essentials/politicians/:id | essentials.politicians.finance_summary | getPoliticianById SELECT p.finance_summary -> PoliticianDetail | VERIFIED | Line 976 (SELECT), line 1200 (mapper), smoke test DETAIL OK |
| GET /api/essentials/representatives/me (address/jurisdiction) | essentials.politicians.finance_summary | getRepresentativesByAddress / getRepresentativesByJurisdiction SELECT | NOT_WIRED | p.finance_summary missing from 4 SELECT clauses; always returns null for finance_summary even for federal politicians |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| essentialsService.ts getPoliticiansFlatList | finance_summary | pg row from essentials.politicians.finance_summary column (line 440 SELECT) | YES — populated by FEC ingestion script for 201/258 federal politicians | VERIFIED (for FINA-03 target endpoint) |
| essentialsService.ts getPoliticianById | finance_summary | pg row from essentials.politicians.finance_summary column (line 976 SELECT) | YES | VERIFIED |
| essentialsService.ts getRepresentativesByAddress | finance_summary | NOT in SELECT clause — row.finance_summary = undefined -> null | NO — always null regardless of DB value | HOLLOW (missing SELECT) |
| essentialsService.ts getRepresentativesByJurisdiction | finance_summary | SELECT_FIELDS missing p.finance_summary — row.finance_summary = undefined -> null | NO | HOLLOW (missing SELECT) |
| essentialsService.ts getLocalOfficialsByUserId | finance_summary | SELECT_FIELDS missing p.finance_summary | NO | HOLLOW (missing SELECT) |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 5 Wave-0 source-scan tests pass GREEN | `cd backend && npx vitest run test/essentialsService-finance-summary.test.ts` | 5 passed, 0 failed | PASS |
| TSC compiles clean for essentialsService.ts | `cd backend && npx tsc --noEmit` | 0 errors on essentialsService.ts/finance_summary (2 pre-existing unrelated errors in coverageService.ts and stanceResearchCsv.ts) | PASS |
| No inform.politicians reference in migration 268 | `grep inform.politicians backend/migrations/268_finance_summary_column.sql` | No output | PASS |
| No inform.politicians reference in ingestion script | `grep inform.politicians backend/scripts/run-fec-finance-summary.ts` | No output | PASS |
| Live API smoke tests (from SUMMARY, not re-run) | curl against running backend | LIST OK: 191 politicians; DETAIL OK: $81M, 10 donors; NULL OK: non-federal null | PASS (per SUMMARY) |

---

### Probe Execution

Step 7c not applicable — no `scripts/*/tests/probe-*.sh` probes declared for this phase.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| FINA-01 | 90-01 | finance_summary JSONB column added to politicians table; migration applied | SATISFIED (with note) | Column exists on essentials.politicians (not inform.politicians as REQUIREMENTS.md states — inform.politicians was dropped in Phase 35; ROADMAP explicitly acknowledges this). All 4 JSONB keys documented. |
| FINA-02 | 90-02 | FEC ingestion script built and run; data loaded for federal politicians | PARTIALLY SATISFIED | Script built and run; 201/258 succeeded. ROADMAP SC2 "returns 0 for target set" not met (57 NULL). PLAN acceptance criteria (>= 100 sitting senators) met per SUMMARY claim. 13 timeouts recoverable by re-run. 44 skipped need FEC IDs added to politician_sources. |
| FINA-03 | 90-03 | GET /api/essentials/politicians and single-politician endpoints return finance_summary | SATISFIED (scoped) | The two named endpoints (getPoliticiansFlatList and getPoliticianById) return finance_summary. Three other PoliticianFlatRecord-returning query paths (address lookup, jurisdiction lookup, local officials) are missing p.finance_summary in their SELECT clauses — these are outside FINA-03's explicit scope but represent an incomplete implementation of the phase goal's broader intent. |

**Orphaned requirements check:** No additional requirements mapped to Phase 90 in REQUIREMENTS.md beyond FINA-01, FINA-02, FINA-03.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| backend/src/lib/essentialsService.ts | 588-696 | getRepresentativesByAddress SELECT missing p.finance_summary (2 query texts) | BLOCKER (code review CR-01) | Federal senators/House members from address lookup always return finance_summary: null; FEC data invisible on /api/essentials/representatives/me when location-based |
| backend/src/lib/essentialsService.ts | 1506-1528 | getRepresentativesByJurisdiction SELECT_FIELDS missing p.finance_summary | BLOCKER (code review CR-02) | Finance data invisible for jurisdiction-based representative lookup |
| backend/src/lib/essentialsService.ts | 1676-1698 | getLocalOfficialsByUserId SELECT_FIELDS missing p.finance_summary | BLOCKER (code review CR-02) | Finance data invisible for local officials lookup |
| backend/src/lib/essentialsBrowseService.ts | 310, 616 | finance_summary: null hardcoded in two browse mappers (getPoliticiansByArea, getPoliticiansByGovernmentList) | WARNING (code review WR-01) | Browse endpoints always return null for federal politicians; deliberate or missing SELECT |
| backend/scripts/run-fec-finance-summary.ts | 457-461 | void pool.end() not awaited before process.exit(1) in fatal error handler | WARNING (code review WR-02) | Pool may not drain before exit; partial write possible on fatal error path |

No unresolved TBD/FIXME/XXX debt markers found in phase-modified files.

---

### Human Verification Required

#### 1. Senator Coverage Spot-Check

**Test:** Run `SELECT full_name, finance_summary IS NOT NULL AS has_data FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON d.id = o.district_id WHERE d.district_type = 'NATIONAL_UPPER' AND p.is_active = true AND p.full_name IN ('Angus S. King, Jr.', 'Raphael Warnock', 'Ron Johnson', 'Ted Cruz', 'Tim Kaine', 'Shelley Moore Capito', 'Ted Budd')` against the remote DB.
**Expected:** Determine whether these 7 senators have finance_summary = true (meaning the SUMMARY "senator-only count = 100" claim is correct) or false (meaning actual senator coverage is ~93, and re-run is needed).
**Why human:** Cannot run remote DB queries programmatically from this context.

#### 2. FINA-02 Exact Senator Count Confirmation

**Test:** Run `SELECT COUNT(*) FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON d.id = o.district_id WHERE d.district_type = 'NATIONAL_UPPER' AND p.is_active = true AND p.finance_summary IS NOT NULL` against remote DB.
**Expected:** 100 (all sitting senators have data) per SUMMARY claim, but SUMMARY is internally contradictory (7 senators listed as errored = DB not written).
**Why human:** SUMMARY has an internal contradiction (7 senators listed as errored/not-written, but claim is 100 senators covered). Only a DB query resolves this.

---

### Gaps Summary

**Gap 1 (BLOCKER): ROADMAP SC2 not met — 57 federal politicians have NULL finance_summary**

ROADMAP Success Criteria 2 requires "returns 0 for target set" (all federal politicians populated). The ingestion run yielded 201/258 succeeded. The 57 with NULL split into two categories:

- **13 FEC API timeouts** — these politicians have FEC IDs (not skipped), just experienced API latency. The script is idempotent; re-running will recover these 13. All are named in 90-02-SUMMARY.md.

- **44 skipped (no FEC ID)** — these politicians have no FEC ID in either crosswalk path (politician_sources or congress-legislators YAML). Predominantly 2026 non-incumbent candidates who are not yet in the authoritative sources. Each needs a row added to `transparent_motivations.politician_sources` with `source_system = 'fec%'` and `research_status = 'confirmed'` before a re-run will pick them up.

The PLAN's acceptance criteria used a weaker bar (">= 100") which was met. The ROADMAP's bar ("returns 0") was not. This is a scope discrepancy introduced when the plan was written — the plan explicitly accepts NULL for no-FEC-ID politicians as correct behavior, but ROADMAP SC2 does not allow it.

**Gap 2 (BLOCKER): finance_summary missing from 4 SELECT clauses in essentialsService.ts**

The phase goal says "surface on GET /api/essentials/politicians endpoints." FINA-03 explicitly names only the list and single-politician endpoints, which are correctly wired. However, three additional PoliticianFlatRecord-returning query paths that serve federal politicians via `/api/essentials/representatives/me` always return `finance_summary: null` even for politicians with ingested data, because p.finance_summary is missing from their SELECT clauses. The mappers correctly write `row.finance_summary ?? null` but the value is always undefined (silently coerced to null). This is Code Review finding CR-01 and CR-02, confirmed by reading essentialsService.ts lines 588-696, 1506-1528, and 1676-1698.

The fix is 4 targeted edits (add `p.finance_summary,` to each SELECT or SELECT_FIELDS). This does not require a migration or test changes — the existing test only covers getPoliticiansFlatList and getPoliticianById.

---

_Verified: 2026-06-04T11:30:00Z_
_Verifier: Claude (gsd-verifier)_
