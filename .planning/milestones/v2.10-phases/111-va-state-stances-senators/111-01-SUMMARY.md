---
phase: 111-va-state-stances-senators
plan: 01
subsystem: database
tags: [stance-research, virginia, state-senate, inform-schema, psql]

requires:
  - phase: 110-va-official-records-geofencing
    provides: VA senator politician records (migration 318) as FK targets in inform.politician_answers

provides:
  - 19 sourced stances for 6 of 8 Wave 1 VA state senators (SD-1 through SD-8)
  - Paired politician_context rows with real source URLs for all 19 stances (VAST-05)
  - Migration 326 applied to live DB
  - Wave 1 CSV forensic artifact at backend/data/stance-research/2026-06-09-111-va-senators-wave1.csv

affects: [111-va-state-stances-senators, VAST-02, VAST-05]

tech-stack:
  added: []
  patterns:
    - "Stance research via WebFetch + direct Node.js HTTPS module for Ballotpedia/Wikipedia"
    - "Migration DO $$ verification using pc.politician_id IS NULL (not pc.id — no id column on politician_context)"
    - "Migration number shifted from planned 324 to 326 after pre-flight revealed max_migration=325"

key-files:
  created:
    - backend/data/stance-research/2026-06-09-111-va-senators-wave1-preflight.json
    - backend/data/stance-research/2026-06-09-111-va-senators-wave1.csv
    - supabase/migrations/20260609000001_326_va_senators_wave1_stances.sql
  modified: []

key-decisions:
  - "Migration number 326 used (not 324 as planned) — max_migration was 325, not 323 as expected from STATE.md; migrations 324/325 exist in backend/migrations/ (VA elections 2026, not in supabase/migrations/)"
  - "Christopher T. Head (SD-3) honest-skipped — no Ballotpedia campaign themes or accessible senate.virginia.gov page found"
  - "T. Travis Hackworth (SD-5) honest-skipped — no survey responses or issue positions in Ballotpedia (neither 2021 nor 2023 surveys completed)"
  - "politician_context has no id column — verification DO $$ block uses pc.politician_id IS NULL (composite PK table)"

patterns-established:
  - "Wave migration pattern: pre-flight JSON -> sequential research -> CSV -> migration SQL -> psql apply -> verify"
  - "Honest-skip for senators with no accessible policy text: 5-10 stances typical for new/rural senators; 0 stances acceptable if no URLs found"
  - "Migration DO $$ uses pc.politician_id IS NULL not pc.id IS NULL for politician_context joins"

requirements-completed: [VAST-02, VAST-05]

duration: 90min
completed: 2026-06-09
---

# Phase 111 Plan 01: VA State Senators Wave 1 Summary

**19 sourced stances for 6 of 8 Wave 1 VA senators (SD-1 through SD-8) across abortion, taxes, fossil-fuels, healthcare, immigration, religious-freedom, and same-sex-marriage topics, with migration 326 applied and VAST-05 verified (0 unsourced)**

## Performance

- **Duration:** ~90 min
- **Started:** 2026-06-09T17:40:00Z
- **Completed:** 2026-06-09
- **Tasks:** 4
- **Files modified:** 3 created

## Accomplishments
- Pre-flight confirmed max_migration=325 (not 323 as planned), shifted migration to 326; all 8 Wave 1 senator UUIDs verified against live DB
- Research via direct WebFetch (Ballotpedia, Wikipedia) produced 19 sourced stances across 6 senators; Head and Hackworth honestly skipped (no documentable policy positions found)
- Migration 326 authored with proper SQL single-quote escaping, paired INSERT pattern, and DO $$ verification block
- Migration applied via psql: DO $$ printed "VA senators with stances: 6" and "Unsourced VA senator stances: 0" — COMMIT successful

## Per-Senator Breakdown

| Senator | SD | Stances | Topics |
|---------|-----|---------|--------|
| Timmy French | SD-1 | 3 | abortion=4, taxes=4, religious-freedom=4 |
| Mark D. Obenshain | SD-2 | 4 | abortion=4, taxes=4, fossil-fuels=4, religious-freedom=5 |
| Christopher T. Head | SD-3 | 0 | Honest skip — no campaign themes found on Ballotpedia |
| David R. Suetterlein | SD-4 | 2 | abortion=4, healthcare=4 |
| T. Travis Hackworth | SD-5 | 0 | Honest skip — no survey responses or issue text found |
| Todd E. Pillion | SD-6 | 4 | fossil-fuels=5, healthcare=4, taxes=4, religious-freedom=4 |
| William M. Stanley, Jr. | SD-7 | 3 | taxes=5, immigration=4, abortion=4 |
| Mark J. Peake | SD-8 | 3 | taxes=4, same-sex-marriage=5, abortion=4 |

**Total:** 19 stances, 6/8 senators covered, 2 honest-skipped

## Task Commits

Each task was committed atomically:

1. **Task 1: Wave 1 pre-flight** - `22d74c3` (chore)
2. **Task 2: Sequential research dispatch** - `025addf` (feat)
3. **Task 3: Author migration 326 SQL** - `85ef970` (feat)
4. **Task 4: Apply migration 326** - `bdfd6c4` (feat)

## Files Created/Modified
- `backend/data/stance-research/2026-06-09-111-va-senators-wave1-preflight.json` - Pre-flight: max_migration=325, 44 topics, 8 senator UUIDs
- `backend/data/stance-research/2026-06-09-111-va-senators-wave1.csv` - 19 data rows across 6 senators (forensic artifact)
- `supabase/migrations/20260609000001_326_va_senators_wave1_stances.sql` - Migration 326, applied 2026-06-09

## Decisions Made
- Migration number shifted 324→326 because pre-flight showed max_migration=325 (STATE.md showed 323 but migrations 324/325 existed in backend/migrations/ for VA 2026 elections)
- Conducted research in this executor session directly via Node.js HTTPS module (Ballotpedia, Wikipedia) rather than spawning subagents (claude CLI was out of credits)
- Head and Hackworth honestly skipped — zero documentable policy positions found after checking Ballotpedia (no campaign themes, no survey responses)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed pc.id IS NULL → pc.politician_id IS NULL in DO $$ verification block**
- **Found during:** Task 4 (Apply migration 326)
- **Issue:** The migration's DO $$ block used `pc.id IS NULL` but `inform.politician_context` has no `id` column — it uses a composite primary key (politician_id, topic_id). This caused an ERROR and migration ROLLBACK on first apply attempt.
- **Fix:** Changed `pc.id IS NULL` to `pc.politician_id IS NULL` in the DO $$ unsourced-count query. Same fix needed in RESEARCH.md Pattern 4 template (noted but not modified — that template is documentation, not production code).
- **Files modified:** supabase/migrations/20260609000001_326_va_senators_wave1_stances.sql
- **Verification:** Migration re-applied successfully; DO $$ printed "Unsourced VA senator stances: 0" and COMMIT succeeded.
- **Committed in:** bdfd6c4 (Task 4 commit)

**2. [Rule 1 - Deviation] Migration number shifted from 324 to 326**
- **Found during:** Task 1 (pre-flight)
- **Issue:** STATE.md stated max_migration=323 but actual DB max was 325. Migrations 324/325 exist in backend/migrations/ (VA 2026 election race data), not in supabase/migrations/.
- **Fix:** Updated migration filename to 20260609000001_326_va_senators_wave1_stances.sql. Plan 111-02 and subsequent waves must use 327+ accordingly.
- **Files modified:** supabase/migrations/20260609000001_326_va_senators_wave1_stances.sql
- **Committed in:** 85ef970 (Task 3 commit), bdfd6c4 (Task 4 commit)

---

**Total deviations:** 2 auto-fixed (1 schema bug, 1 migration numbering correction)
**Impact on plan:** Both fixes necessary for correctness. No scope creep.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. All data written to existing `inform.politician_answers` and `inform.politician_context` tables (public-read, admin-write via existing RLS). No new trust boundaries.

## Known Stubs

None - all 19 stances are sourced from real fetched URLs. Head and Hackworth are formally honest-skipped (not stubs).

## VAST-05 Verification

Post-apply SQL confirmation:
- senators_with_stances: 6 (of 8; 2 honest-skipped)
- total_stances: 19
- unsourced_count: 0

VAST-05 invariant holds for Wave 1.

## Issues Encountered
- Claude CLI (for spawning subagents) was out of API credits. Research was conducted directly in this executor session using Node.js HTTPS module to fetch Ballotpedia and Wikipedia pages. Research quality is equivalent — same Five-Chairs methodology, same source URL requirement, same honest-skip rule applied.
- `senate.virginia.gov/senators/[district]/` returned 404 for all tested districts. LIS Virginia (lis.virginia.gov) also returned query interpretation errors for member lookup by district. Ballotpedia was the primary successful source for all senators.

## Next Phase Readiness
- Plan 111-02 (Wave 2, SD-9 through SD-16) is unblocked
- Next free migration number: 327
- Wave 2 will cover: Tammy Brankley Mulchi (SD-9), Luther H. Cifers III (SD-10), R. Creigh Deeds (SD-11), Glen H. Sturtevant Jr. (SD-12), Lashrecse D. Aird (SD-13), Lamont Bagby (SD-14), Michael J. Jones (SD-15), Schuyler T. VanValkenburg (SD-16)

---
*Phase: 111-va-state-stances-senators*
*Completed: 2026-06-09*
