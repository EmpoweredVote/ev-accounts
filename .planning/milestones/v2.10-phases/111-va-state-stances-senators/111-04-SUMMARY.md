---
phase: 111-va-state-stances-senators
plan: 04
subsystem: database
tags: [stance-research, virginia, state-senate, inform-schema, psql]

requires:
  - phase: 111-03
    provides: Wave 3 stances (79 rows, 8 senators) as baseline for cumulative VAST-05 tracking

provides:
  - 30 sourced stances for 7 of 8 Wave 4 VA state senators (SD-25 through SD-31)
  - Paired politician_context rows with real source URLs for all 30 stances (VAST-05)
  - Migration 329 applied to live DB
  - Wave 4 CSV forensic artifact at backend/data/stance-research/2026-06-09-111-va-senators-wave4.csv
  - Honest-skip: Srinivasan (SD-32) — joined Senate Jan 2025, no documentable legislative record

affects: [111-va-state-stances-senators, VAST-02, VAST-05]

tech-stack:
  added: []
  patterns:
    - "Wave 4 replicates Wave 1/2/3 pattern: pre-flight JSON -> research -> CSV -> migration SQL -> psql apply -> verify"
    - "Migration 329 used — 326/327/328 applied to DB but not tracked in schema_migrations (max=325 at pre-flight)"
    - "DO $$ pc.id fixed to pc.politician_id — politician_context has no id column (composite PK on politician_id+topic_id)"

key-files:
  created:
    - backend/data/stance-research/2026-06-09-111-va-senators-wave4-preflight.json
    - backend/data/stance-research/2026-06-09-111-va-senators-wave4.csv
    - supabase/migrations/20260609000004_329_va_senators_wave4_stances.sql
  modified: []

key-decisions:
  - "Migration number 329 used — Waves 1+2+3 SQL files (326/327/328) applied but not tracked in schema_migrations (max=325). Wave 4 uses 329 to avoid filename collision."
  - "Srinivasan (SD-32) full honest-skip — joined VA Senate January 2025, only previously served in House 2024 (no recorded bills), no documentable public policy positions."
  - "DO $$ pc.id -> pc.politician_id fix applied — politician_context uses composite PK (politician_id, topic_id), not a standalone id column."
  - "Research conducted directly in executor session (same approach as Waves 1/2/3)"

requirements-completed: [VAST-02, VAST-05]

duration: ~45min
completed: 2026-06-09
---

# Phase 111 Plan 04: VA State Senators Wave 4 Summary

**30 sourced stances for 7 of 8 Wave 4 VA senators (SD-25 through SD-31), migration 329 applied, VAST-05 verified (0 unsourced)**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-09
- **Completed:** 2026-06-09
- **Tasks:** 4
- **Files created:** 3

## Per-Senator Breakdown

| Senator | SD | Party | Stances | Key Topics |
|---------|-----|-------|---------|------------|
| Richard H. Stuart | SD-25 | R | 4 | climate-change, data-centers, taxes, civil-rights |
| Ryan T. McDougle | SD-26 | R | 4 | climate-change, voting-rights, campaign-finance, immigration |
| Tara A. Durant | SD-27 | R | 3 | taxes, childcare, civil-rights |
| Bryce E. Reeves | SD-28 | R | 5 | trans-athletes, school-vouchers, ai-regulation, civil-rights, healthcare |
| Jeremy S. McPike | SD-29 | D | 4 | climate-change, housing, voting-rights, deportation |
| Danica A. Roem | SD-30 | D | 7 | data-centers, campaign-finance, same-sex-marriage, trans-athletes, civil-rights, housing, healthcare |
| Russet W. Perry | SD-31 | D | 3 | campaign-finance, civil-rights, same-sex-marriage |
| Kannan Srinivasan | SD-32 | D | 0 | HONEST-SKIP (Senate Jan 2025, no legislative record) |

**Wave 4 total:** 30 stances, 7/8 senators covered, 1 honest-skipped

## Cumulative Coverage (Waves 1 + 2 + 3 + 4)

| Metric | Value |
|--------|-------|
| Senators with stances | 27 of 32 (SD-1 through SD-32) |
| Total stances | 144 (19 W1 + 16 W2 + 79 W3 + 30 W4) |
| Unsourced stances | 0 (VAST-05 holds across all waves) |
| Honest-skipped senators | 5 (Head SD-3, Hackworth SD-5, Mulchi SD-9, Cifers SD-10, Srinivasan SD-32) |

## Key Stances by Senator

**Stuart (SD-25, R):** SB3 (2024) repealed VA ZEV standards -> climate=5; SB664 isolated data center costs from ratepayers -> data-centers=2; SB632 car-tax cut -> taxes=4; opposed redistricting reform -> civil-rights=4

**McDougle (SD-26, R):** SB53 (2024) co-patron ZEV repeal -> climate=5; SB794 photo ID for absentee voting -> voting-rights=4; SB1437 ESG restriction for public funds -> campaign-finance=4; SB1248 mandatory E-Verify -> immigration=4

**Durant (SD-27, R):** SB64 grocery tax holiday -> taxes=4; SB75/76 childcare center deregulation -> childcare=4; opposed VA ERA -> civil-rights=4

**Reeves (SD-28, R):** SB1186 trans athlete ban for K-12/college -> trans-athletes=5; SB1191 universal ESA school vouchers -> school-vouchers=5; SB164 AI disclosure requirement -> ai-regulation=2; SB1195 prohibit discrimination in credit -> civil-rights=3; opposed Medicaid expansion (2018 record) -> healthcare=4

**McPike (SD-29, D):** SB729 co-patron Clean Energy Capital Bank -> climate=2; SB597 zoning reform for affordable housing -> housing=3; SB752 automatic voter registration -> voting-rights=2; SB621 protection from deportation in VA schools -> deportation=2

**Roem (SD-30, D):** SB284/285/289 data center regulation suite (PJM study, moratorium bill, disclosure) -> data-centers=2; SB326 prohibit utility campaign contributions -> campaign-finance=2; Wikipedia identity confirms first openly trans US state senator (since 2018), co-patroned HB3337 marriage equality protection -> same-sex-marriage=1, trans-athletes=1; SB398 eviction sealing -> housing=2; SB394 paid sick leave -> healthcare=2; SB390/391 hate crimes/discrimination -> civil-rights=2

**Perry (SD-31, D):** SB692 electronic filing for independent expenditures -> campaign-finance=2; SB642 firearm restriction after domestic violence conviction -> civil-rights=2; patron HB805 marriage equality protection -> same-sex-marriage=1

**Srinivasan (SD-32, D):** Full honest-skip. Joined VA Senate January 2025. No chief-patron bills found in 2025 session via LIS. Previously served in House 2024 with no recorded bills. No documentable public policy positions via LIS, Senate member page, Ballotpedia, or VPAP. LIS member ID: S133.

## Migration Number Note

max_migration at pre-flight = 325. Waves 1+2+3 SQL files (326/327/328) are applied to the DB but NOT tracked in `supabase_migrations.schema_migrations`. Migration 329 chosen to avoid disk filename collision. The DO $$ block also required a fix: `pc.id` -> `pc.politician_id` because `inform.politician_context` has a composite primary key `(politician_id, topic_id)` with no standalone `id` column. The first apply attempt rolled back with `ERROR: column pc.id does not exist`; fix was applied before re-running successfully.

## Task Commits

Each task was committed atomically:

1. **Task 1: Wave 4 pre-flight** - `e31ff066` (chore)
2. **Task 2: Sequential research dispatch** - `0bc3377d` (feat)
3. **Task 3+4: Author + Apply migration 329** - `a07ca9f8` (feat)

## Files Created/Modified

- `backend/data/stance-research/2026-06-09-111-va-senators-wave4-preflight.json` — Pre-flight: max_migration=325, wave4_migration_number=329, 25 topics, 8 senator UUIDs
- `backend/data/stance-research/2026-06-09-111-va-senators-wave4.csv` — 30 data rows across 7 senators (forensic artifact; staged with git add -f due to gitignore)
- `supabase/migrations/20260609000004_329_va_senators_wave4_stances.sql` — Migration 329, applied 2026-06-09

## VAST-05 Verification

Post-apply DO $$ block:
- VA senators with stances (Wave 4 range -5110032 to -5110025): 7
- Unsourced VA senator stances (Wave 4): 0

Cumulative confirmation query (all 32 senators, ext_id BETWEEN -5110032 AND -5110001):
- senators_with_stances: 27
- total_stances: 144

VAST-05 invariant holds across all four waves.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed DO $$ pc.id -> pc.politician_id**
- **Found during:** Task 4 (first psql apply attempt)
- **Issue:** DO $$ verification block referenced `pc.id` which does not exist on `inform.politician_context`. Table uses composite PK `(politician_id, topic_id)`. Migration rolled back with `ERROR: column pc.id does not exist`.
- **Fix:** Changed `pc.id IS NULL` to `pc.politician_id IS NULL` to match Wave 3 migration pattern.
- **Files modified:** `supabase/migrations/20260609000004_329_va_senators_wave4_stances.sql`
- **Commit:** a07ca9f8 (fix applied before commit)

### Known False Negative (documented, not a bug)

**Task 1 verify: max_migration >= 326** — DB shows max=325 because psql-applied wave migrations (326/327/328) do not insert rows into schema_migrations. This is an expected condition documented in the Wave 3 SUMMARY and Wave 4 preflight JSON. Wave 4 used migration number 329 as planned.

## Self-Check: PASSED

- `backend/data/stance-research/2026-06-09-111-va-senators-wave4-preflight.json` — FOUND (committed e31ff066)
- `backend/data/stance-research/2026-06-09-111-va-senators-wave4.csv` — FOUND (committed 0bc3377d)
- `supabase/migrations/20260609000004_329_va_senators_wave4_stances.sql` — FOUND (committed a07ca9f8)
- Commit e31ff066 — FOUND
- Commit 0bc3377d — FOUND
- Commit a07ca9f8 — FOUND
- DB verification: 27 senators, 144 stances, 0 unsourced — CONFIRMED
