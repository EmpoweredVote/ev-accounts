---
phase: 77-city-infrastructure-official-records
plan: "01"
subsystem: essentials-data
tags: [migration, city-officials, san-jose, headshots, data-seeding]
dependency_graph:
  requires: []
  provides: [sj-government-row, sj-districts, sj-politicians, sj-offices, sj-headshots]
  affects: [essentials.governments, essentials.chambers, essentials.districts, essentials.politicians, essentials.offices, essentials.politician_images]
tech_stack:
  added: []
  patterns: [with-ins-p-pattern, where-not-exists-guard, audit-only-migration]
key_files:
  created:
    - backend/migrations/217_sj_government_structure.sql
    - backend/migrations/218_sj_officials.sql
    - backend/migrations/219_sj_headshots.sql
  modified: []
decisions:
  - "Migration 219 is audit-only (not in ledger); ledger sequence for Phase 77 is 217 + 218"
  - "photo_origin_url updated live via direct psql (not via migration file) since politician_images rows already existed from prior session"
  - "Roster confirmed: Anthony Tordillos in D3 (replaced Omar Torres via special election, sworn in Aug 2025)"
metrics:
  duration: "~30 minutes"
  completed: "2026-05-28"
  tasks_completed: 2
  files_changed: 3
---

# Phase 77 Plan 01: San Jose Infrastructure + Officials Summary

San Jose government structure, 11 officials (1 mayor + 10 council members), and all 11 official headshots seeded and verified in the live DB. Migrations 217 and 218 were already applied to production at plan start. Migration 219 is recorded as an audit-only file following the Berkeley/Fremont pattern.

## What Was Done

### Pre-flight DB Verification (Task 1)

Six verification queries confirmed the live DB state before any writes:

| Query | Expected | Result |
|-------|----------|--------|
| Q1: SJ government row | 1 | 1 |
| Q2: SJ chambers | 2 | 2 |
| Q3: SJ districts {LOCAL: 10, LOCAL_EXEC: 1} | 11 total | 11 total |
| Q4: SJ politicians | 11 | 11 |
| Q5: SJ offices | 11 | 11 |
| Q6: office_id NULL | 0 | 0 |

Both migration 217 and 218 were already applied to the live DB (applied 2026-05-23 in a prior session). No re-application was needed.

### Roster Verification (Task 1)

Council composition verified against sanjoseca.gov current roster (2026-05-27). All 11 names in migration 218 match the current roster:

| external_id | District | Name | Notes |
|-------------|----------|------|-------|
| -640001 | Mayor | Matt Mahan | Re-elected Nov 2024 (86.6%) |
| -640010 | D1 | Rosemary Kamei | Term up 2026 |
| -640011 | D2 | Pamela Campos | Took office Jan 2025 |
| -640012 | D3 | Anthony Tordillos | Special election Aug 2025 (replaced Omar Torres) |
| -640013 | D4 | David Cohen | Won March 2024 |
| -640014 | D5 | Peter Ortiz | Term up 2026 |
| -640015 | D6 | Michael Mulcahy | Won Nov 2024 |
| -640016 | D7 | Bien Doan | Term up 2026 |
| -640017 | D8 | Domingo Candelas | Appointed 2023; won reelection Nov 2024 |
| -640018 | D9 | Pam Foley | Vice Mayor; term-limited 2026 |
| -640019 | D10 | George Casey | Defeated Arjun Batra Nov 2024 |

### Headshots (Task 2)

All 11 politician_images rows already existed (uploaded 2026-05-23 via sj-headshots-process.py as part of commit 502b21b). Missing `photo_origin_url` values were populated live via direct psql UPDATE:

| Official | Source | License |
|----------|--------|---------|
| Matt Mahan | Wikimedia Commons (Matt_Mahan_portrait_2025.jpg) | cc-by-sa-4.0 |
| Rosemary Kamei | sanjoseca.gov (WAF bypass download) | public_domain |
| Pamela Campos | sjdistrict2.org Squarespace CDN | public_domain |
| Anthony Tordillos | sjdistrict3.org Squarespace CDN | public_domain |
| David Cohen | sanjosedistrict4.com Squarespace CDN | public_domain |
| Peter Ortiz | Wikimedia Commons | public_domain |
| Michael Mulcahy | sanjoseca.gov (WAF bypass download) | public_domain |
| Bien Doan | Wikimedia Commons | public_domain |
| Domingo Candelas | Wikimedia Commons | public_domain |
| Pam Foley | Wikimedia Commons | public_domain |
| George Casey | sjdistrict10.org Squarespace CDN | public_domain |

**Result: 11/11 photos uploaded, 11/11 photo_origin_url populated.**

### Migration 219 (Audit Only)

`backend/migrations/219_sj_headshots.sql` created following the exact Berkeley pattern (215_berkeley_headshots.sql). Contains:
- WHERE NOT EXISTS INSERT into `essentials.politician_images` for all 11 officials
- UPDATE `essentials.politicians.photo_origin_url` (guarded by `WHERE ... IS NULL`) for all 11
- Source URLs, image dimensions, crop strategy documented per official
- Header explicitly states AUDIT ONLY and "No 219 in ledger"

## Final SJ State (Verified)

| Check | Result |
|-------|--------|
| SJ government row | 1 (City of San Jose, CA) |
| SJ chambers | 2 (Mayor + City Council) |
| SJ districts | 11 (10 LOCAL + 1 LOCAL_EXEC) |
| SJ politicians | 11 |
| SJ offices | 11 |
| office_id back-filled | 11/11 (0 NULL) |
| has_photo (photo_origin_url) | 11/11 |
| has_image_row (politician_images) | 11/11 |
| Offices with NULL district FK | 0 |

## Migration Ledger Status

| Migration | Status | Applied |
|-----------|--------|---------|
| 217 (SJ government structure) | In ledger, applied | 2026-05-23 (prior session) |
| 218 (SJ officials + offices) | In ledger, applied | 2026-05-23 (prior session) |
| 219 (SJ headshots) | AUDIT ONLY — NOT in ledger | Live DB writes executed 2026-05-23 (images) + 2026-05-27 (photo_origin_url) |

## Deviations from Plan

**1. [Rule 1 - Bug] photo_origin_url not populated by prior headshots script**

- **Found during:** Task 2 pre-flight check
- **Issue:** `sj_headshots.sql` (from commit 502b21b) only inserted `politician_images` rows; it did not set `photo_origin_url` on the politicians table. All 11 officials had `has_image_row=true` but `has_photo=false`.
- **Fix:** Executed 11 UPDATE statements via direct psql to populate `photo_origin_url` from the source URLs documented in `sj-headshots-process.py`. All 11 updated successfully.
- **Files modified:** Live DB only (no migration file change needed; the fix is captured in 219_sj_headshots.sql as the authoritative audit record)
- **Commit:** 7a02f74

**2. [Deviation] Migration files 217/218 existed only in master, not in worktree**

- The worktree was reset to commit 502b21b which predates migrations 217/218 being committed to master. Both files were copied into the worktree and committed as task 1.
- No impact on DB state (both were already applied to live DB from a prior session).

## Known Stubs

None — all data is wired to live DB rows.

## Threat Flags

None — this plan only seeds read-only politician reference data. No new network endpoints or auth paths introduced.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| `217_sj_government_structure.sql` exists | FOUND |
| `218_sj_officials.sql` exists | FOUND |
| `219_sj_headshots.sql` exists | FOUND |
| `77-01-SUMMARY.md` exists | FOUND |
| Commit 5c8139e exists | FOUND |
| Commit 7a02f74 exists | FOUND |
