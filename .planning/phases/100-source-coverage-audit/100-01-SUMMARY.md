---
phase: 100-source-coverage-audit
plan: 01
subsystem: database
tags: [audit, inform, sources, data-quality, pg, pool.query]

# Dependency graph
requires:
  - phase: n/a
    provides: Live Supabase DB with inform.politician_answers, inform.politician_context, essentials.politicians/offices/districts
provides:
  - "Source coverage audit script at backend/scripts/run-source-coverage-audit.ts"
  - "100-AUDIT-REPORT.md — human-readable baseline report (SRCA-01)"
  - "100-TARGET-LIST.csv — machine-readable ranked target list (SRCA-02)"
affects: [101-federal-senate-remediation, 102-federal-house-remediation, 103-state-remediation, 104-local-remediation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Audit script pattern: dotenv + pg.Pool + async main + --dry-run flag — follows audit-112-stances.ts skeleton"
    - "COALESCE(SUM(...), 0) on aggregates — Postgres SUM returns NULL (not 0) when no rows match; always COALESCE for safety"
    - "DISTINCT ON (politician_id) in tier subquery — prevents multi-office Cartesian product inflation"
    - "CA city officials identified by external_id range (blocks 63-68), not government joins (government_id is NULL on CA city districts)"
    - "Operationalized sourced definition: context row + sources NOT NULL + array_length IS NOT NULL + at least one non-blank URL"

key-files:
  created:
    - backend/scripts/run-source-coverage-audit.ts
    - .planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md
    - .planning/phases/100-source-coverage-audit/100-TARGET-LIST.csv
  modified: []

key-decisions:
  - "CA city official cohort uses external_id ranges (blocks 63=SF, 64=SJ, 65=SD, 67=Fremont, 68=Berkeley) — government_id is NULL on all CA city districts so government-name joins return 0 rows"
  - "CA city officials appear as Local in tier breakdown, not City — the City row reflects TX cities (Plano, McKinney, etc.) which have government_id populated"
  - "Weak sources (107 rows): homepage-only URLs counted as sourced in totals but flagged separately — QUAL-01 applies during remediation phases 101-104"
  - "MD officials queried by external_id range -240005..-240001, not full_name — DB uses middle initials (Anthony G. Brown, Dereck E. Davis) while plan text uses short names"

patterns-established:
  - "Sourced definition locked for v2.7: 4-rule check (context row + sources NOT NULL + array_length IS NOT NULL + at least one non-blank URL)"
  - "Phase 100 gates all remediation: 100-TARGET-LIST.csv is the authoritative scope document for phases 101-104"

requirements-completed: [SRCA-01, SRCA-02]

# Metrics
duration: 45min
completed: 2026-06-05
---

# Phase 100 Plan 01: Source Coverage Audit Summary

**Read-only source coverage audit: 13,920 stance rows, 99.8% sourced (30 unsourced), 107 weak (homepage-only) sources, 15 politicians on remediation target list — SRCA-01 report and SRCA-02 CSV delivered.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-05T20:27Z
- **Completed:** 2026-06-05T20:49Z
- **Tasks:** 1 auto (Task 1: script build) + 1 checkpoint (Task 2: live run + deliverables)
- **Files modified:** 3 created

## Accomplishments

- `backend/scripts/run-source-coverage-audit.ts` — 6-query audit script (Queries A–F), uses pool.query() exclusively, supports --dry-run flag, writes outputs via __dirname to phase directory
- `100-AUDIT-REPORT.md` — All 6 required sections present: Executive Summary, Tier Breakdown, Milestone Cohorts, "Sourced" Definition, Weak Sources Note, MD Officials
- `100-TARGET-LIST.csv` — 15 politicians with unsourced stances, sorted tier_rank ASC then majority_unsourced DESC then unsourced_count DESC
- MD officials (Wes Moore, Aruna Miller, Anthony G. Brown, Brooke Lierman, Dereck E. Davis) confirmed zero stances
- Weak sources (homepage-only URLs): 107 rows flagged but counted as sourced per locked definition

## Key Audit Numbers

| Metric | Value |
|--------|-------|
| Total stances | 13,920 |
| Sourced | 13,890 (99.8%) |
| Unsourced | 30 |
| Weak sources (homepage-only) | 107 |
| Politicians with any unsourced | 15 |

**Tier Breakdown:**
| Federal | 3,915 total | 1 unsourced | 100.0% sourced |
| State | 6,891 total | 16 unsourced | 99.8% sourced |
| City (TX cities with gov_id) | 215 total | 5 unsourced | 97.7% sourced |
| Local | 2,195 total | 8 unsourced | 99.6% sourced |

**Top 5 on Target List:**

| Politician | Tier | Unsourced | Total | Majority? |
|-----------|------|-----------|-------|-----------|
| Deb Fischer | Federal | 1 | 20 | false |
| Gavin Newsom | State | 4 | 29 | false |
| Katy Hall | State | 3 | 28 | false |
| Tracy Miller | State | 3 | 28 | false |
| Chris Krupa Downs | City | 2 | 3 | TRUE |

## Task Commits

1. **Task 1: Build run-source-coverage-audit.ts** - `54c5b0e` (feat)
2. **Task 1 bug fix: City cohort + COALESCE** - `b7c149f` (fix)

**Plan metadata:** (pending after checkpoint approval)

## Files Created/Modified

- `backend/scripts/run-source-coverage-audit.ts` — 6-query audit script (Queries A–F): totals, tier breakdown, milestone cohorts, per-politician target list, weak sources, MD officials dedicated section
- `.planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md` — SRCA-01 deliverable: human-readable report with all 6 required sections
- `.planning/phases/100-source-coverage-audit/100-TARGET-LIST.csv` — SRCA-02 deliverable: 15 rows, exact header, sorted tier_rank ASC + majority_unsourced DESC

## Decisions Made

1. **CA city official cohort by external_id range** — CA city districts (SF, SJ, SD, Berkeley, Fremont) have NULL `government_id` on their `essentials.districts` rows, so government-name joins return 0 rows. Fixed by using external_id blocks (63=SF, 64=SJ, 65=SD, 67=Fremont, 68=Berkeley; 66=Sacramento excluded).

2. **CA city officials appear as "Local" in tier breakdown** — The tier breakdown correctly shows TX city officials (Plano, McKinney, etc.) as "City" because they have `government_id` populated. CA city officials appear as "Local" due to missing `government_id`. This is documented in the Methodology Notes section of the report. Remediation phases should be aware that "Local" in the tier table includes CA city officials.

3. **MD officials queried by external_id range -240005 to -240001** — Plan text references "Anthony Brown" and "Dereck Davis" but DB stores "Anthony G. Brown" and "Dereck E. Davis" (with middle initials). External_id range is authoritative.

4. **Weak sources counted as sourced** — 107 rows have homepage-only URLs (no path component). These pass the 4-rule sourced check and are counted as sourced in all totals, but flagged in a dedicated Weak Sources Note section. QUAL-01 applies during remediation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CA city officials cohort query returned 0 rows**
- **Found during:** Task 2 (dry-run verification)
- **Issue:** Plan's Query C v2.5 cohort used `g.name IN ('City of San Francisco', ...)` but CA city districts have NULL `government_id`, making the join impossible. SF government is also named "City and County of San Francisco" not "City of San Francisco".
- **Fix:** Replaced government join with external_id range filter: `BETWEEN -689999 AND -630000 EXCEPT -669999 TO -660000` (blocks 63=SF, 64=SJ, 65=SD, 67=Fremont, 68=Berkeley; Sacramento block 66 excluded)
- **Files modified:** backend/scripts/run-source-coverage-audit.ts
- **Verification:** Dry-run shows 893 stances for v2.5 city officials cohort (vs 0 before fix)
- **Committed in:** b7c149f

**2. [Rule 1 - Bug] NaN in unsourced_stances calculation when no rows match**
- **Found during:** Task 2 (dry-run verification)
- **Issue:** Postgres `SUM()` returns NULL (not 0) when no rows match aggregation. MD officials (0 stances) caused `parseInt(null, 10)` = NaN in the unsourced calculation.
- **Fix:** Added `COALESCE(SUM(...), 0)` on all SUM expressions in Queries A, B, C, and D
- **Files modified:** backend/scripts/run-source-coverage-audit.ts
- **Verification:** Dry-run shows "0 total, 0 unsourced" for MD cohort (vs NaN before fix)
- **Committed in:** b7c149f

---

**Total deviations:** 2 auto-fixed (Rule 1 bugs)
**Impact on plan:** Both essential for correct query results. No scope creep.

## Open Questions for Phases 101–104

1. **Weak sources (107 rows):** Homepage-only URLs counted as sourced in this audit. Remediation phases should decide: does `https://sd07.senate.ca.gov` satisfy QUAL-01 ("URL links to a primary source")? If not, treat as unsourced during re-verification.

2. **CA city officials in "Local" tier:** The tier breakdown shows CA city officials under "Local" (not "City") because their districts lack `government_id`. Phase 104 (city remediation) will need to filter by external_id ranges as done here, not by tier label.

3. **Unknown tier (704 stances, 0 unsourced):** These politicians have no office records or offices with unrecognized district types. All 704 are sourced. Low priority for remediation.

4. **Sacramento (block 66, ~120 stances):** Excluded from v2.5 cohort. Sacramento officials are real but are not in the v2.5 milestone scope. They may have unsourced stances not captured in the cohort table — check the target list CSV for "Local" politicians with unsourced stances.

## Self-Check

Files created/verified:
- [x] `backend/scripts/run-source-coverage-audit.ts` — EXISTS (committed 54c5b0e, fixed b7c149f)
- [x] `.planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md` — EXISTS (committed b7c149f)
- [x] `.planning/phases/100-source-coverage-audit/100-TARGET-LIST.csv` — EXISTS (committed b7c149f)
- [x] `.planning/phases/100-source-coverage-audit/100-01-SUMMARY.md` — THIS FILE

Commits verified:
- [x] 54c5b0e — feat(100-01): build run-source-coverage-audit.ts
- [x] b7c149f — fix(100-01): fix city cohort query and COALESCE

## Self-Check: PASSED

All created files exist and all commits are present in the worktree branch.

---
*Phase: 100-source-coverage-audit*
*Completed: 2026-06-05*
