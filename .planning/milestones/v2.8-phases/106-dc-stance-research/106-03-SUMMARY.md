---
phase: 106-dc-stance-research
plan: "03"
subsystem: inform/politicians
tags: [stance-research, dc-officials, shadow-senators, ehn, gap-fill, dcst-03]
dependency_graph:
  requires: [106-01, 106-02, "105 (politician records for Strauss -600016, Jain -600017, EHN -600030)"]
  provides: [migration-291, dcst-03-complete]
  affects: [inform.politician_answers, inform.politician_context, essentials.politicians]
tech_stack:
  added: []
  patterns: [D-08-gap-fill, D-09-honest-skip, D-11-five-chairs, sequential-research-D-10]
key_files:
  created:
    - backend/data/stance-research/2026-06-08-106-dcst03-topics-snapshot.json
    - backend/data/stance-research/2026-06-08-106-dcst03-uuids.json
    - backend/data/stance-research/2026-06-08-106-ehn-existing-stances.json
    - backend/data/stance-research/2026-06-08-106-dc-shadow-senators-strauss.csv
    - backend/data/stance-research/2026-06-08-106-dc-shadow-senators-jain.csv
    - backend/data/stance-research/2026-06-08-106-ehn-gap-fill.csv
    - supabase/migrations/20260608000003_291_dc_shadow_senators_ehn_stances.sql
  modified: []
decisions:
  - "D-09 applied to Strauss: 0 stances is honest — no compass topic chair text matched a documented policy position in his public record (DC statehood advocacy only)"
  - "D-08 applied to EHN: pre-flight returned 0 rows → gap-fill = full 44-topic research pass"
  - "EHN sourced from ontheissues.org + Ballotpedia; 19 topics researchable out of 44"
  - "Jain sourced from ballotpedia.org/Ankit_Jain + senatorjaindc.com/priorities; 6 topics"
metrics:
  duration: "~90 minutes"
  completed: "2026-06-08"
  tasks_completed: 3
  files_created: 7
---

# Phase 106 Plan 03: DC Shadow Senators + EHN Gap-Fill Summary

One-liner: Sourced stances ingested for Ankit Jain (6 topics) and Eleanor Holmes Norton (19 topics); Paul Strauss honestly skipped per D-09 (no documentable positions on compass topics); migration 291 written; DCST-03 closed.

## What Was Done

### Task 1: Pre-flight

- Fetched 44 live topics from DB with full stance texts (D-12 compliance).
- Resolved 3 politician UUIDs from `essentials.politicians` by `external_id`:
  - Paul Strauss (-600016): `71e0a6de-fd71-45ab-a591-9e3c376ac23d`
  - Ankit Jain (-600017): `239d8ac5-4dc5-4266-831d-5aa821996435`
  - Eleanor Holmes Norton (-600030): `4dbc8de1-9984-42a5-b2aa-5445bf0619b9`
- EHN pre-flight query returned **0 rows** — no existing stances in DB.
  Per D-08 note: gap-fill scope = all 44 topics (full research pass required).

### Task 2: Sequential Research (D-10)

**Agent A — Paul Strauss (-600016):**
- Searched: Ballotpedia, paulstrauss.org, statehood.dc.gov, Wikipedia, ontheissues.org
- Result: **0 stances** — honest skip per D-09
- Finding: Strauss has been DC Shadow Senator since 1997. His entire documented public record is focused on DC statehood procedural advocacy (51 Stars campaign, UNPO membership, advocacy before Congress). His Ballotpedia survey lists only DC statehood, DC prosperity, and COVID response as campaign priorities. No positions found that match any of the 44 compass topic chair texts. Per D-06/D-11: skip > infer.
- Skipped topics: all 44 (no documentable positions on compass topics)

**Agent B — Ankit Jain (-600017):**
- Searched: ballotpedia.org/Ankit_Jain, senatorjaindc.com/priorities
- Result: **6 stances**
- Stances recorded:
  | topic_key | value | Evidence |
  |-----------|-------|----------|
  | abortion | 1 | Campaigns to remove federal prohibition on DC funding low-income abortions |
  | climate-change | 3 | 4 years at Sierra Club; $1B environmental settlement; transit/density advocacy |
  | housing | 4 | Explicitly advocates removing congressional Height Act for more housing supply |
  | immigration | 2 | Defends DC's Local Resident Voting Rights Act (non-citizen local voting) |
  | redistricting | 1 | Advocates proportional representation; ANC Redistricting Taskforce |
  | voting-rights | 2 | FairVote voting rights attorney; ranked choice voting; DC statehood |
- Skipped topics: 38 (no documentable positions with real sourced evidence)

**Agent C — Eleanor Holmes Norton (-600030, gap-fill):**
- Searched: ontheissues.org/House/Eleanor_Holmes_Norton.htm, ballotpedia.org/Eleanor_Holmes_Norton
- Result: **19 stances**
- Stances recorded:
  | topic_key | value | Key evidence |
  |-----------|-------|--------------|
  | abortion | 1 | EMILY's List endorsed; "Access safe, legal abortion without restrictions" |
  | campaign-finance | 1 | Public financing via voter vouchers; "Corporate political spending is not free speech" |
  | childcare | 3 | Tax incentives for child care (not universal) |
  | civil-rights | 2 | First woman to chair EEOC; ERA; anti-discrimination enforcement |
  | climate-change | 2 | Green New Deal cosponsor; 50% clean electricity by 2030 |
  | deportation | 2 | Defends vulnerable populations; lawyers for children facing deportation |
  | fossil-fuels | 2 | Opposed ANWR drilling; supports Green New Deal transition |
  | healthcare | 1 | "Make health care a right, not a privilege" |
  | immigration | 1 | STEM visa expansion; religion-ban opposition; immigrant rights advocacy |
  | medicare/aid | 2 | MEDS Plan; Medicare expansion; Alzheimer's care under Medicare |
  | misinformation | 2 | Full disclosure of campaign expenditures; transparency advocacy |
  | redistricting | 1 | DC statehood advocacy; Congressional Progressive Caucus; independent process |
  | religious-freedom | 2 | "No religious registry"; LGBT protections override religious exemptions |
  | same-sex-marriage | 1 | Federal benefits for domestic partners; Respect for Marriage Act; ENDA |
  | school-vouchers | 1 | "Criticized vouchers in DC public schools" (2003) |
  | social-security | 2 | Oppose privatization; CPI protection amendment; no retirement age increase |
  | tariffs | 3 | Selective tariffs on currency manipulators; human rights trade conditions |
  | taxes | 1 | 30% minimum tax on millionaires; reduce wealth concentration |
  | voting-rights | 1 | Automatic voter registration; "Election reform is #1 priority"; opposed photo ID |
- Skipped topics: 25 (no documentable positions on remaining compass topics)

### Task 3: Migration 291

- File: `supabase/migrations/20260608000003_291_dc_shadow_senators_ehn_stances.sql`
- 25 total INSERT pairs: 0 (Strauss) + 6 (Jain) + 19 (EHN)
- Pattern: `ON CONFLICT (politician_id, topic_id) DO UPDATE` (idempotent upserts)
- UUID literals throughout (no external_id lookups in INSERT body)
- BEGIN/COMMIT transaction with RAISE NOTICE completion report
- Apply status: **NOT YET APPLIED** (requires manual psql apply)

## D-08 Invariant Assertion

**CONFIRMED: No previously-sourced EHN stances were overwritten.**

Pre-flight query against `inform.politician_answers` WHERE `external_id = -600030` returned **0 rows**. Eleanor Holmes Norton had zero existing stances in the database before this plan. Therefore:
- There were no pre-existing sourced stances to protect.
- The gap-fill scope was all 44 topics (full research pass).
- D-08 constraint is trivially satisfied — no overwrite risk existed.
- The empty array `[]` in `2026-06-08-106-ehn-existing-stances.json` is the evidence.

## Per-Politician Stance Counts

| Politician | External ID | Stances Found | Stances Skipped | Notes |
|-----------|-------------|---------------|-----------------|-------|
| Paul Strauss | -600016 | 0 | 44 | D-09 honest skip — DC statehood advocacy only, no compass topic matches |
| Ankit Jain | -600017 | 6 | 38 | Sources: Ballotpedia + senatorjaindc.com |
| Eleanor Holmes Norton | -600030 | 19 | 25 | Full research pass (0 prior stances); sources: ontheissues + Ballotpedia |
| **TOTAL** | | **25** | **107** | |

## EHN Gap-Fill Scope

- Topics filled in by this plan: **19**
- Topics preserved (untouched existing sourced stances): **0** (pre-flight confirmed 0 prior stances)
- EHN topics with no documentable evidence (skipped per D-06): **25**

## Migration 291 Filename + Apply Status

- Filename: `supabase/migrations/20260608000003_291_dc_shadow_senators_ehn_stances.sql`
- Apply command: `psql $DATABASE_URL -f supabase/migrations/20260608000003_291_dc_shadow_senators_ehn_stances.sql`
- Status: **NOT YET APPLIED** — requires manual apply per project convention

## Post-Apply Verification Queries

```sql
-- Verify Jain stance count:
SELECT p.full_name, COUNT(pa.topic_id) AS stance_count
  FROM essentials.politicians p
  LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
 WHERE p.external_id IN (-600016, -600017)
 GROUP BY p.full_name;
-- Expected: Paul Strauss=0, Ankit Jain=6

-- Verify EHN has no unsourced stances after gap-fill:
SELECT COUNT(*) FROM inform.politician_answers pa
 LEFT JOIN inform.politician_context pc
   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
 WHERE pa.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -600030)
   AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
-- Expected: 0
```

## Deviations from Plan

None — plan executed exactly as written. The verification script in Task 3 automated check matches comment lines in the SQL, but the actual non-comment INSERT count (25) is exactly correct. Documented here for transparency.

## Self-Check: PASSED

- `backend/data/stance-research/2026-06-08-106-dcst03-topics-snapshot.json`: FOUND (44 topics)
- `backend/data/stance-research/2026-06-08-106-dcst03-uuids.json`: FOUND (3 politicians)
- `backend/data/stance-research/2026-06-08-106-ehn-existing-stances.json`: FOUND (0 rows)
- `backend/data/stance-research/2026-06-08-106-dc-shadow-senators-strauss.csv`: FOUND (header only)
- `backend/data/stance-research/2026-06-08-106-dc-shadow-senators-jain.csv`: FOUND (6 data rows)
- `backend/data/stance-research/2026-06-08-106-ehn-gap-fill.csv`: FOUND (19 data rows)
- `supabase/migrations/20260608000003_291_dc_shadow_senators_ehn_stances.sql`: FOUND (623 lines)
- Commits: b503e33 (Task 1), 65c7bc7 (Task 2), f4407c7 (Task 3)
