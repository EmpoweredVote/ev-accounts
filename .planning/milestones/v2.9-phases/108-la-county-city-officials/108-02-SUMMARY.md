---
phase: 108-la-county-city-officials
plan: "02"
subsystem: essentials-schema
tags:
  - sql-migration
  - essentials-schema
  - la-county
  - la-city
  - beverly-hills
  - santa-monica

dependency_graph:
  requires:
    - phase: 108-01
      provides: "Wave 1 gap-fill for 14 Tier 1 LA County cities with geo_id backfill"
  provides:
    - "Beverly Hills: 6 total politicians (3 pre-existing council + Mayor + Sharona Nazarian + Howard Fisher City Treasurer) on geo_id=0606308"
    - "Santa Monica: 10 total politicians (6 pre-existing + Dan Hall, Ellis Raskin, Barry Snell, Natalya Zernitskaya) on geo_id=0670000"
    - "LA City Controller Kenneth Mejia: external_id=-700001 set, office_id backfilled"
    - "LA City Clerk Patrice Lattimore: inserted at external_id=-700002, linked to existing Clerk office with is_appointed=true"
    - "Wave 2 external_id range -700001..-700033 partially consumed (6 new records)"
  affects:
    - "GET /api/essentials/representatives/me — BH and SM residents now see fuller councils; LA City Clerk now appears"

tech_stack:
  added: []
  patterns:
    - "Pre-flight deviation: when existing politicians are already in DB, UPDATE external_id rather than INSERT new duplicate"
    - "UPDATE office fields (is_appointed_position, chamber_id) alongside politician_id link in single idempotent UPDATE"
    - "BH/SM government name lookup must use exact DB name ('City of Beverly Hills, California, US' not 'City of Beverly Hills')"

key_files:
  created:
    - backend/scripts/preflight-la-wave2.sql
    - backend/migrations/300_la_wave2_preflight.sql
    - backend/migrations/301_la_wave2_beverly_hills.sql
    - backend/migrations/302_la_wave2_santa_monica.sql
    - backend/migrations/303_la_wave2_la_city_controller_clerk.sql
  modified: []

key-decisions:
  - "Kenneth Mejia was already in DB (no external_id, no office_id) — UPDATE path used instead of INSERT; avoids duplicate row"
  - "City Attorney office left unchanged — Hydee Feldstein Soto was already linked before Wave 2; we did not insert a new one per the plan intent"
  - "City Clerk office already existed (cc009928) — linked Lattimore to it; also created City Clerk chamber and set is_appointed_position=true on the office row"
  - "BH: only Sharona Nazarian and Howard Fisher added — Corman, Mirisch, Wells, Friedman already in DB at existing external_ids"
  - "SM: only Dan Hall, Ellis Raskin, Barry Snell, Natalya Zernitskaya added — Negrete, Zwick, Torosis already in DB; Phil Brock, Parra, de la Torre are prior-term members kept per D-03"

requirements-completed:
  - LAOF-02
  - LAOF-05

duration: "~60 minutes"
completed: "2026-06-08"
---

# Phase 108 Plan 02: Wave 2 Beverly Hills + Santa Monica + LA City Citywide Offices Summary

Beverly Hills (2 new: Nazarian + Fisher), Santa Monica (4 new Dec 2024 members), and LA City Controller/Clerk linked — 6 new politician records across 4 idempotent migrations.

## Performance

- **Duration:** ~60 minutes
- **Started:** 2026-06-08T21:30:00Z
- **Completed:** 2026-06-08T22:30:00Z
- **Tasks:** 4
- **Files created:** 5

## Accomplishments

- Beverly Hills now has 6 politicians on geo_id=0606308: 3 council members + 1 Mayor (pre-existing) + Sharona R. Nazarian (5th council seat, -700010) + Howard Fisher (City Treasurer, -700011)
- Santa Monica now has 10 politicians on geo_id=0670000: 6 pre-existing + Dan Hall (-700030), Ellis Raskin (-700031), Barry Snell (-700032), Natalya Zernitskaya (-700033)
- LA City Controller confirmed: Kenneth Mejia external_id=-700001 set + office_id backfilled (he was already in DB linked to controller office)
- LA City Clerk: Patrice Lattimore (-700002, is_appointed=true) inserted and linked to existing Clerk office; City Clerk chamber created; is_appointed_position=true set on office row
- LA City Attorney office (5a873c59) left unchanged per plan — Hydee Feldstein Soto was pre-existing in DB before this wave

## Final Counts

| City | geo_id | Politicians (total) | New This Wave |
|------|--------|---------------------|---------------|
| Beverly Hills | 0606308 | 6 | 2 (Nazarian, Fisher) |
| Santa Monica | 0670000 | 10 | 4 (Hall, Raskin, Snell, Zernitskaya) |
| LA City Controller | 0644000 | 1 (Mejia) | 0 new — existing backfilled |
| LA City Clerk | 0644000 | 1 (Lattimore) | 1 new |

## LA City Controller link confirmed

Kenneth Mejia's external_id set to -700001 and office_id backfilled. He was already linked to the City Controller office (e5435b0e) from a prior migration — no duplicate insert needed.

## LA City Clerk creation path

**Path taken: linked to existing office** (city_clerk_office_exists = TRUE per pre-flight).
The City Clerk office (cc009928) existed with `politician_id=NULL` and `chamber_id=NULL`. Actions taken:
1. Created 'City Clerk' chamber for LA government (dcc0355c) — it did not exist
2. Inserted Patrice Lattimore (-700002, is_appointed=true) as politician
3. Updated office cc009928: set politician_id=Lattimore, chamber_id=new Clerk chamber, is_appointed_position=true

## LA City Attorney office explicitly not touched

**LA City Attorney office UUID 5a873c59-72ac-488f-8b2c-44dfd04d065c left unchanged per RESEARCH.md Critical Finding 1.**

Hydee Feldstein Soto was already linked to this office before Phase 108 began (inserted by a prior migration). The Wave 2 plan specified not to seed a new politician for this office due to the November 2026 runoff. No politician was inserted by migration 303. The office remains occupied by the pre-existing Feldstein Soto row.

## Task Commits

1. **Task 1: Pre-flight BH/SM office structure + LA City Clerk** - `6f7a1b9` (chore)
2. **Task 2: Beverly Hills 5 council + Treasurer + geo_id backfill** - `f5660c0` (feat)
3. **Task 3: Santa Monica 7 council + geo_id backfill** - `43c4b5d` (feat)
4. **Task 4: LA City Controller + City Clerk; skip City Attorney** - `0cc7a59` (feat)

## Files Created

- `backend/scripts/preflight-la-wave2.sql` — Re-runnable Q1–Q5 pre-flight queries
- `backend/migrations/300_la_wave2_preflight.sql` — Comment-only documentation migration (0 non-comment DDL/DML)
- `backend/migrations/301_la_wave2_beverly_hills.sql` — BH Nazarian + Fisher + geo_id/govt backfill
- `backend/migrations/302_la_wave2_santa_monica.sql` — SM Hall + Raskin + Snell + Zernitskaya + geo_id/govt backfill
- `backend/migrations/303_la_wave2_la_city_controller_clerk.sql` — Mejia external_id + Lattimore City Clerk creation

## Deviations from Plan

### Plan-Write-Time Assumption Errors (pre-flight corrections)

**1. [Rule 1 - Bug] Beverly Hills 4 of 5 council members already in DB**
- **Found during:** Task 1 (pre-flight)
- **Issue:** Plan expected Beverly Hills to have 0 politicians and specified inserting all 5 council members at external_ids -700010..-700014 plus Fisher at -700015. Pre-flight revealed Corman (-201154), Mirisch (-201153), Wells (-201155), and Friedman (-200589) already in DB with offices linked.
- **Fix:** Inserted only Sharona R. Nazarian (-700010) and Howard Fisher (-700011) — the 2 actually missing. Existing records left at their original external_ids per D-03 (do not modify existing records).
- **Acceptance criteria impact:** The plan's "returns exactly 6 rows at -700010..-700015" criterion cannot be met without re-numbering pre-existing records, which is out of scope. The functional goal (6 politicians attached to geo_id=0606308) is met.
- **Committed in:** f5660c0 (Task 2 commit)

**2. [Rule 1 - Bug] Santa Monica 3 of 7 current members already in DB; 3 prior-term members also present**
- **Found during:** Task 1 (pre-flight)
- **Issue:** Plan expected Santa Monica to have 0 politicians. Pre-flight revealed 6 office rows with: Lana Negrete, Jesse Zwick, Caroline Torosis (current members) + Phil Brock, Christine Parra, Oscar de la Torre (prior-term or superseded members). Plan specified inserting all 7 current members at -700030..-700036.
- **Fix:** Inserted only the 4 genuinely missing current members: Dan Hall (-700030), Ellis Raskin (-700031), Barry Snell (-700032), Natalya Zernitskaya (-700033). Pre-existing records retained per D-03.
- **Committed in:** 43c4b5d (Task 3 commit)

**3. [Rule 1 - Bug] Kenneth Mejia already in DB — UPDATE path instead of INSERT**
- **Found during:** Task 1 (pre-flight)
- **Issue:** Plan expected the City Controller office to have `politician_id = NULL` and called for inserting Mejia at -700001. Pre-flight showed Mejia already in DB (`590fd6ec`) and linked to the office, but with `external_id=NULL` and `office_id=NULL`.
- **Fix:** Updated Mejia's row to set `external_id=-700001` and backfilled `office_id`. No new row inserted.
- **Committed in:** 0cc7a59 (Task 4 commit)

**4. [Rule 1 - Bug] City Attorney was pre-occupied — NOT vacant as plan expected**
- **Found during:** Task 1 (pre-flight)
- **Issue:** Plan's must_have truth stated "LA City Attorney office has NO politician inserted." Pre-flight showed Hydee Feldstein Soto was already linked from a prior migration (not inserted by this wave).
- **Fix:** No action taken on the City Attorney office. Migration 303 header comment documents the intentional skip. The pre-existing linkage predates Phase 108.
- **Impact:** The plan acceptance criterion `SELECT politician_id... returns NULL` cannot be satisfied. The pre-existing condition is not a Wave 2 bug.

**5. Government name mismatch — BH/SM use long-form names**
- **Found during:** Task 2/3
- **Issue:** BH government name is 'City of Beverly Hills, California, US' (not 'City of Beverly Hills'). SM is 'City of Santa Monica, California, US'. The plan patterns used short-form names.
- **Fix:** All WHERE clauses and lookups use the actual DB government IDs directly (hard-coded UUIDs confirmed via pre-flight).
- **Committed in:** f5660c0, 43c4b5d

---

**Total deviations:** 5 plan-assumption corrections (all Rule 1 — data already in DB)
**Impact:** All corrections reflect the actual DB state vs. plan assumptions. Functional goals met. Zero regression risk.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes at trust boundaries introduced. Pure static SQL data rows. The City Attorney UUID (5a873c59) appears only in comment lines of migration 303 — verified via grep.

## Known Stubs

None. All 6 new politicians have photo_origin_url, office_id, is_incumbent=true, party=NULL.

## Self-Check

- backend/scripts/preflight-la-wave2.sql: FOUND
- backend/migrations/300_la_wave2_preflight.sql: FOUND
- backend/migrations/301_la_wave2_beverly_hills.sql: FOUND
- backend/migrations/302_la_wave2_santa_monica.sql: FOUND
- backend/migrations/303_la_wave2_la_city_controller_clerk.sql: FOUND
- Commit 6f7a1b9 (T1): FOUND
- Commit f5660c0 (T2): FOUND
- Commit 43c4b5d (T3): FOUND
- Commit 0cc7a59 (T4): FOUND

## Self-Check: PASSED
