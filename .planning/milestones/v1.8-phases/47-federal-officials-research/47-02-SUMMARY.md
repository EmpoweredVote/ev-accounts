---
phase: 47-federal-officials-research
plan: 02
subsystem: data
tags: [csv, stance-research, senate, indiana, federal-officials]

# Dependency graph
requires:
  - phase: 47-01
    provides: CSV with 107 rows for 6 officials, sourcing patterns for federal senators
provides:
  - Sourced stance data for IN US Senators Todd Young and Jim Banks (42 rows, all 21 topics each)
affects: [47-03, 47-04, 47-05, 47-06, 48-import]

# Tech tracking
tech-stack:
  added: []
  patterns: [senate-press-release-sourcing, congress-gov-bill-records, rsc-budget-sourcing]

key-files:
  created: []
  modified:
    - EV-Backend/data/stance_research.csv

key-decisions:
  - "Young same-sex-marriage assigned value 2 (allow nationwide with religious protections) — voted FOR Respect for Marriage Act in 2022, crossing party lines; RMA includes religious exemption provisions"
  - "Young ai-regulation assigned value 3 (require basic safety testing) — co-led CHIPS and Science Act with AI innovation provisions; positions him at balanced oversight not deregulation"
  - "Young ukraine-support assigned value 2 (continue current levels) — voted for all Ukraine aid packages but no documented calls for significantly increased support beyond current commitments"
  - "Banks ukraine-support assigned value 4 (reduce aid, focus on domestic) — voted against Ukraine supplemental funding packages; America First wing but not fully isolationist"
  - "Banks medicare and social-security assigned value 5 (privatize/private accounts) — RSC Budget under his chairmanship explicitly proposed premium support for Medicare and private investment accounts for Social Security"
  - "Banks ai-regulation assigned value 1 (allow freely without government interference) — consistent anti-regulation stance; no documented support for any AI oversight framework"
  - "Both senators BallotReady external_ids left blank — not locatable via public sources; Phase 50 import will need manual resolution"

patterns-established:
  - "RSC Budget is a valid source for Republican House members who chaired RSC — formally documents fiscal positions"
  - "House voting record (2017-2024) used for Banks pre-Senate positions alongside Senate record (2025+)"

requirements-completed: [STANCE-06]

# Metrics
duration: 3min
completed: 2026-02-26
---

# Phase 47 Plan 02: IN US Senators Stance Research Summary

**Sourced stance data for IN US Senators Todd Young (R) and Jim Banks (R) across all 21 compass topics using Senate/House press releases, congress.gov voting records, and RSC Budget documents (42 rows appended)**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-26T17:26:03Z
- **Completed:** 2026-02-26T17:29:05Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Appended 21 rows for Senator Todd Young (R-IN) covering all 21 compass topics with integer values 1-5
- Appended 21 rows for Senator Jim Banks (R-IN) covering all 21 compass topics with integer values 1-5
- CSV now has 149 data rows across 8 politicians (Newsom 21, Kounalakis 10, Braun 21, Beckwith 13, Padilla 21, Schiff 21, Young 21, Banks 21)
- All topic_keys validated against the 21 defined keys; all values are integers (range: 1-5 reflecting conservative positions for both senators); all rows have at least one source URL
- Prior rows for all 6 existing politicians remain unchanged

## Task Commits

Each task was committed atomically (in EV-Backend repo):

1. **Task 1: Research Senator Todd Young stances** - `4355112` (feat)
2. **Task 2: Research Senator Jim Banks stances** - `9be9809` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `EV-Backend/data/stance_research.csv` - Appended 42 rows for IN US Senators Young and Banks

## Decisions Made
- Young same-sex-marriage: value 2 — crossed party lines to vote for Respect for Marriage Act (2022); RMA includes religious organization exemptions matching stance 2 description
- Young ai-regulation: value 3 — CHIPS and Science Act co-lead positions him at "basic safety/innovation balance" not deregulation
- Young ukraine-support: value 2 — consistent supporter of aid packages; no documented escalation calls
- Banks ukraine-support: value 4 — voted against Ukraine supplemental funding; America First but retains some foreign engagement
- Banks medicare: value 5 — RSC Budget under Banks explicitly proposed premium support model (private insurance shift)
- Banks social-security: value 5 — RSC Budget under Banks explicitly proposed private investment account option
- Banks ai-regulation: value 1 — no documented support for any AI oversight; consistent anti-regulation across all tech
- Both senators' BallotReady external_ids left blank; no publicly findable ID via web search

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
- None — both senators have extensive documented records; 21/21 topics covered for each

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness
- IN senators complete; ready for Phase 47-03 (LA County House representatives)
- All existing rows unchanged; CSV remains valid with proper comma separation
- Pattern confirmed: federal senators with multi-term records yield full 21/21 topic coverage
- RSC Budget established as valid source type for conservative House members' fiscal positions

---
*Phase: 47-federal-officials-research*
*Completed: 2026-02-26*
