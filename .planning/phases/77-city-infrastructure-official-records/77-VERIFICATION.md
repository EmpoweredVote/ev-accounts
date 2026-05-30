---
phase: 77-city-infrastructure-official-records
verified: 2026-05-28T00:00:00Z
status: human_needed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification: false
human_verification:
  - test: "Confirm photo display attribution for Matt Mahan (CC-BY-SA 4.0)"
    expected: "Wherever Matt Mahan's headshot is rendered in any EV app, attribution to the Wikimedia Commons source is visible, or a public-domain replacement image is substituted"
    why_human: "License compliance requires visual verification of the UI rendering layer; the photo_license column value is 'cc-by-sa-4.0' but whether the UI surfaces attribution cannot be determined from the codebase alone (UI display of politician headshots is handled by CompassV2/Essentials, outside this repo)"
---

# Phase 77: City Infrastructure + Official Records Verification Report

**Phase Goal:** Seed government structure, officials, and headshots for all 4 v2.5 target cities (San Jose, San Diego, Berkeley, Fremont); verify CITY-01 through CITY-08 requirements pass; produce go/no-go for Phase 78.
**Verified:** 2026-05-28
**Status:** human_needed (automated checks all pass; one license-compliance item requires human confirmation)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | All 4 v2.5 target cities have exactly one government row each | VERIFIED | 77-02-SUMMARY.md CITY-01 query: 4 rows returned (Berkeley CA 0606000, Fremont CA 0626000, San Diego CA 0666000, San Jose CA 0668000), all type='LOCAL' |
| 2 | All 4 cities have city council district records (LOCAL per-seat + LOCAL_EXEC citywide) — 34+ total LOCAL rows | VERIFIED | 77-02-SUMMARY.md CITY-02 queries: LOCAL counts {SJ:10, SD:9, Berkeley:8, Fremont:6} = 33 total; LOCAL_EXEC counts = 4 (one per city). 33+4=37 district rows total |
| 3 | Every new city politician (39 total: SJ 11 + SD 11 + Berkeley 10 + Fremont 7) has an office row linked to a real district | VERIFIED | 77-02-SUMMARY.md CITY-07 queries: orphan_offices=0, politicians_without_office=0 across all 4 cities |
| 4 | Every new city politician has photo_origin_url populated | VERIFIED | 77-02-SUMMARY.md CITY-08 query: missing_photo=0 for all 4 cities (Berkeley 0/10, Fremont 0/7, San Diego 0/11, San Jose 0/11) |
| 5 | Every new city politician has politicians.office_id back-filled (joinable to offices.id) | VERIFIED | 77-02-SUMMARY.md CITY-07 office_id back-fill query: missing_office_id=0 for all 4 cities |
| 6 | Phase 77 is closeable: CITY-01 through CITY-08 all verified green | VERIFIED | 77-02-SUMMARY.md "Phase 78 Go/No-Go: GREEN — Phase 78 (City Stance Research) may begin." All 8 requirements explicitly passed |
| 7 | Migration 217 (SJ government structure) exists on disk and is substantive | VERIFIED | backend/migrations/217_sj_government_structure.sql exists, 99 lines, contains full BEGIN/COMMIT block seeding 1 government + 2 chambers + 10 LOCAL + 1 LOCAL_EXEC district, all with WHERE NOT EXISTS idempotency guards |
| 8 | Migration 218 (SJ officials) exists on disk, contains all 11 officials + office_id back-fill | VERIFIED | backend/migrations/218_sj_officials.sql exists, 418 lines, contains 11 WITH ins_p blocks (external_ids -640001 to -640019) + UPDATE back-fill at lines 410-415 |

**Score:** 8/8 truths verified

---

## Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| CITY-01 | Government stubs for all 4 cities in essentials.governments | SATISFIED | 4 rows confirmed in live DB via CITY-01 query in 77-02-SUMMARY.md |
| CITY-02 | City council district records for all 4 cities | SATISFIED | 33 LOCAL + 4 LOCAL_EXEC confirmed. Note: REQUIREMENTS.md text says `district_type='CITY_COUNCIL'` — this enum value does not exist in schema; actual rows correctly use LOCAL/LOCAL_EXEC per RESEARCH.md Pitfall 1. Implementation is correct; requirement text is stale documentation |
| CITY-03 | Politician records for all San Jose city officials | SATISFIED | 11 SJ politicians confirmed in live DB (external_ids -640001 to -640019): 1 Mayor + 10 Council Members |
| CITY-04 | Politician records for all San Diego city officials | SATISFIED | 11 SD politicians confirmed in live DB (external_ids -650001 to -650018); seeded in migrations 207-209 prior to Phase 77 |
| CITY-05 | Politician records for all Berkeley city officials | SATISFIED | 10 Berkeley politicians confirmed in live DB (external_ids -680001 to -680017); seeded in migrations 213-215 prior to Phase 77 |
| CITY-06 | Politician records for all Fremont city officials | SATISFIED | 7 Fremont politicians confirmed in live DB (external_ids -670001 to -670015); seeded in migrations 210-212 prior to Phase 77 |
| CITY-07 | Office records for all new officials linked to correct district | SATISFIED | orphan_offices=0, politicians_without_office=0, missing_office_id=0 across all 39 officials in all 4 cities |
| CITY-08 | photo_origin_url populated for all new officials | SATISFIED | missing_photo=0 for all 4 cities; cross-check missing_image_row=0; all 11 SJ sources documented in 219_sj_headshots.sql |

**Note on CITY-02 requirement text:** REQUIREMENTS.md defines CITY-02 as requiring `district_type='CITY_COUNCIL'`. This enum value does not exist in the essentials.districts schema — the actual valid values used are `LOCAL` (per-seat) and `LOCAL_EXEC` (citywide). The phase correctly identified and used the right enum values. REQUIREMENTS.md should be updated to reflect `LOCAL`/`LOCAL_EXEC` after Phase 77 closes. This is not an implementation defect.

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/migrations/217_sj_government_structure.sql` | SJ government + 2 chambers + 10 LOCAL districts + 1 LOCAL_EXEC district | VERIFIED | File exists, 99 lines, substantive BEGIN/COMMIT block. Committed in 5c8139e. Applied to live DB 2026-05-23 |
| `backend/migrations/218_sj_officials.sql` | 11 SJ politicians + 11 offices + office_id back-fill | VERIFIED | File exists, 418 lines, all 11 WITH ins_p blocks present + back-fill UPDATE. Committed in 5c8139e. Applied to live DB 2026-05-23 |
| `backend/migrations/219_sj_headshots.sql` | Audit-only record of 11 SJ headshot uploads following Berkeley pattern | VERIFIED | File exists, 238 lines. Contains WHERE NOT EXISTS INSERT blocks + photo_origin_url UPDATE for all 11 officials. Header explicitly states AUDIT ONLY and "No 219 in ledger". Committed in 7a02f74 |
| `.planning/phases/77-city-infrastructure-official-records/77-02-SUMMARY.md` | CITY-01–08 verification report with exact row counts per query per city | VERIFIED | File exists, contains per-requirement Pass/Fail table with exact integer row counts and Go/No-Go GREEN signal |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| essentials.offices | essentials.districts | district_id FK | WIRED | 77-02-SUMMARY.md orphan_offices=0 for all 39 officials; migration 218 joins to districts by geo_id |
| essentials.politicians.office_id | essentials.offices.id | back-fill UPDATE in migration 218 lines 410-415 | WIRED | Pattern `UPDATE essentials.politicians p SET office_id = o.id FROM essentials.offices o WHERE o.politician_id = p.id AND p.external_id BETWEEN -640019 AND -640001 AND p.office_id IS NULL` present in file; 77-02-SUMMARY.md confirms missing_office_id=0 |
| essentials.politicians.photo_origin_url | Source URLs (sanjoseca.gov, Wikimedia, Squarespace CDN) | find-headshots skill + 11 UPDATE statements in migration 219 | WIRED | 77-01-SUMMARY.md confirms 11/11 photos populated; 77-02-SUMMARY.md confirms missing_photo=0 for SJ |
| SJ external_ids (-640001 to -640019) | City identity | documented range | WIRED | Range confirmed clean at migration time (no collisions), confirmed by live DB query results in 77-02-SUMMARY.md |

---

### Data-Flow Trace (Level 4)

This phase seeds reference data only (no dynamic-rendering components introduced). Data flows from migration SQL → live DB → essentials.politicians/offices/districts tables. The write path was confirmed by re-running read queries against the live DB in Plan 77-02. No frontend components were modified in this phase, so Level 4 dynamic data-flow tracing is not applicable.

---

### Behavioral Spot-Checks

Step 7b: SKIPPED — this phase is a pure data-seeding migration phase with no runnable entry points or API endpoints introduced. Verification was conducted via direct DB queries in Plan 77-02 (read-only verification plan).

---

### Probe Execution

Step 7c: No probe scripts declared in PLAN files. No `scripts/*/tests/probe-*.sh` files exist for this phase. SKIPPED.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `backend/migrations/218_sj_officials.sql` | 395–396 | Mayor INSERT uses `district_type IN ('LOCAL', 'LOCAL_EXEC')` instead of `= 'LOCAL_EXEC'` | WARNING | Over-broad filter; safe today (only one matching row exists), but creates risk of duplicate Mayor office row if a future migration adds a LOCAL row for geo_id='0668000'. Flagged in code review WR-01. Non-blocking for Phase 77 goal |
| `backend/migrations/218_sj_officials.sql` | 407 | Stale comment: "REQUIRED: plan 64-03 queries..." (should be plan 77-01) | INFO | Copy-paste artifact from SD migration 208. No functional impact |
| `backend/migrations/219_sj_headshots.sql` | filename | Three files named `219_*.sql` in migrations directory (`219_sacramento_government_structure.sql`, `219_fremont_officials_stances.sql`, `219_sj_headshots.sql`) | WARNING | Ambiguity for environment bootstrapping from migrations directory. 219_sj_headshots.sql is documented as AUDIT ONLY in its header, but a naive migration runner that applies all 219_*.sql files could cause issues. Flagged in code review WR-02. Non-blocking for Phase 77 goal |
| `backend/migrations/219_sj_headshots.sql` | 43 | `photo_license = 'cc-by-sa-4.0'` for Matt Mahan (all others are 'public_domain') | WARNING | CC-BY-SA 4.0 requires attribution when image is displayed and derivative works (the cropped/resized version) must carry same license terms. Requires UI-layer compliance verification — routed to human verification |

**Debt marker scan:** No `TBD`, `FIXME`, or `XXX` markers found in any of the three migration files. No debt-marker blockers.

**Stub scan:** No placeholder patterns, empty return values, or unimplemented handlers. All migration files contain substantive data operations. Migration 219 is correctly designated audit-only with clear header documentation — it is not a stub.

---

### Human Verification Required

### 1. Matt Mahan Headshot Attribution (CC-BY-SA 4.0 Compliance)

**Test:** Navigate to any EV app that renders politician headshots (CompassV2 compare view, Essentials politician detail) and locate Matt Mahan's profile. Verify that either (a) attribution to the Wikimedia Commons source (`https://upload.wikimedia.org/wikipedia/commons/a/ae/Matt_Mahan_portrait_2025.jpg`) is visibly displayed near the image, or (b) the image has been replaced with a public-domain alternative.

**Expected:** Attribution is present OR the image has been swapped for a public-domain version. If neither is true, sourcing a public-domain replacement image for Matt Mahan from official San Jose city government sources is recommended.

**Why human:** License compliance requires visual inspection of the rendering layer in the CompassV2 and Essentials front-end apps. Those apps are outside this repository. The `photo_license = 'cc-by-sa-4.0'` column value is correctly recorded, but whether the UI reads that value and surfaces attribution cannot be verified by static analysis of this repo alone.

---

## Gaps Summary

No blockers. All 8 CITY-01 through CITY-08 requirements are satisfied by live DB evidence. The phase goal is achieved.

Two warnings from code review (WR-01: over-broad Mayor district filter in migration 218; WR-02: three files named 219_*.sql in migrations) are non-blocking for current phase correctness but should be addressed before the migrations directory is used to bootstrap a new environment. Recommended fix for WR-02 is to rename `219_sj_headshots.sql` to `219_sj_headshots.AUDIT-ONLY.sql`.

The only item requiring human action is the CC-BY-SA 4.0 attribution check for Matt Mahan's headshot in the rendering apps.

**Phase 78 Go/No-Go: GREEN** — all 4 cities have complete data foundations (government, districts, politicians, offices, photos). Phase 78 (City Stance Research) may begin.

---

## REQUIREMENTS.md Documentation Debt (Post-Phase Action)

CITY-02 in REQUIREMENTS.md reads: `typed as 'CITY_COUNCIL', FK'd to their government row`. The enum value `CITY_COUNCIL` does not exist in the `essentials.districts` schema; the actual values are `LOCAL` (per-seat) and `LOCAL_EXEC` (citywide at-large). The ROADMAP.md Success Criteria #2 for Phase 77 also contains the same stale `CITY_COUNCIL` reference. Both should be updated to reflect the actual schema values to prevent confusion in future phases. This is documentation debt, not an implementation failure.

---

_Verified: 2026-05-28_
_Verifier: Claude (gsd-verifier)_
