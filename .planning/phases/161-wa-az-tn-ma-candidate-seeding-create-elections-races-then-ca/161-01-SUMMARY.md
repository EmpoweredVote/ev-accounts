---
phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
plan: 01
subsystem: research
tags: [tn-redistricting, correspondence-audit, election-data, house-2026]

# Dependency graph
requires:
  - phase: 160-field-resolution-stance-gap-diagnostic (plan 02)
    provides: 160-field-table-p161.csv (37-row field table incl. TN's 9 late-primary rows), TN redistricting provenance in 160-02-SUMMARY.md
provides:
  - 161-tn-correspondence-audit.md — 9-district TN old-vs-new severity table, rubric, and the machine-readable "Severe geo_id list:" line (4704, 4705, 4706, 4708, 4709)
affects: [161-06 (TN seed — must withhold severe races per D-01b), 161-11 (verify.sql severe-race non-surfacing assertion), 166 (consolidated gate), 164.1 (polygon-refresh/dual-map design)]

# Tech tracking
tech-stack:
  added: []
  patterns: [">25%-moved OR anchor-changed severity rubric applied via named-source county-reassignment evidence + a presidential-vote-swing quantitative proxy, no GIS/shapefile dependency"]

key-files:
  created:
    - .planning/phases/161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca/161-tn-correspondence-audit.md
  modified: []

key-decisions:
  - "Severe set expanded from the RESEARCH.md working assumption (TN-9, maybe TN-8) to 5 of 9 districts (4704/4705/4706/4708/4709), driven by direct named-source confirmation that new TN-6 gained a downtown-Nashville anchor it never had, and that TN-5 lost BOTH of its old anchors (Davidson + Williamson counties) to other districts"
  - "Used a presidential-vote-swing proxy (old-map vs new-map notional 2024 result per Wikipedia's Dave's-Redistricting-sourced table) as a quantitative severity signal, since no shapefile/GIS diff was performed (qualitative county-level reporting was sufficient per 161-RESEARCH.md's Don't-Hand-Roll guidance)"
  - "Re-verified TN litigation status live (map upheld by 3-judge panel May 26; NAACP state suit dismissed; NAACP/LWV federal suit + ACLU suit pending without injunction) — confirms the map is the operative map for Aug-6 primary/Nov-3 general, satisfying the D-01 premise"

requirements-completed: [USHC3-03]

# Metrics
duration: ~55min
completed: 2026-07-03
---

# Phase 161 Plan 01: TN Old-vs-New Congressional Map Correspondence Audit Summary

**9-district TN redistricting severity audit scoring 5 districts (TN-4/5/6/8/9) severe via named-source county-reassignment evidence + a presidential-vote-swing proxy, producing the machine-readable severe-geo_id list 161-06/161-11 will consume**

## Performance

- **Duration:** ~55 min (majority spent fetching and cross-reading 8 named sources)
- **Tasks:** 2 (gather old-vs-new composition; score severity + write artifact)
- **Files modified:** 1 (161-tn-correspondence-audit.md, new)

## Accomplishments
- Fetched and read 8 named primary/secondary sources directly (TN SoS announcement page, Wikipedia's "2026 Tennessee redistricting" article, 4 Tennessee Lookout articles spanning May 7 - June 24, 2026, NPR's May 13 ground report, and the Lookout's Politics index checked through July 2, 2026) — no assumptions, every claim traceable to a fetched URL
- Applied the locked >25%-moved / anchor-changed rubric to all 9 TN districts with an explicit rationale per row; no district left unscored
- Discovered and resolved 161-RESEARCH.md's Open Question #1 (whether TN-4/5/6/7/8 individually cross the severe threshold): **TN-4, TN-5, TN-6, TN-8 all score severe**; TN-7 does not
- Re-confirmed TN-1/2/3 (East TN) as not-severe and TN-9 (Cohen, dismantled) as severe, matching the pre-audit expectation exactly
- Re-verified TN litigation status same-day as execution (well within the 161-RESEARCH.md 7-day freshness window): map upheld by a state 3-judge panel (May 26), NAACP state suit dismissed, two federal suits (NAACP/LWV consolidated + ACLU) pending without injunction as of the most recent available reporting (through July 2, 2026) — no stay or reversal found

## Task Commits

1. **Task 1+2: Gather old-vs-new TN district data, score severity, write audit artifact** - `906d0d1b` (feat)

_Note: Task 1 (data gathering) had no separately-committable deliverable per the plan's own verify step (`echo research-step-checked-in-task-2`) — both tasks land in a single artifact and a single commit, matching the plan's Task 2 acceptance criteria._

## Files Created/Modified
- `161-tn-correspondence-audit.md` - Rubric, 9-row severity table (geo_id/old_cd/incumbent/anchor_old/anchor_new/pct-proxy/severity/rationale), the "Severe geo_id list:" contract line, litigation-status recap, and 8 source URLs

## Decisions Made
- **Severity rubric evidence basis:** no shapefile/GIS diff (per 161-RESEARCH.md's explicit Don't-Hand-Roll guidance — a qualitative county-level breakdown from named reporting is sufficient). Used named-source county-reassignment statements as the primary evidence, backed by a quantitative proxy: each district's notional 2024 presidential-election result recalculated under the new boundaries vs. the old boundaries (from Wikipedia's partisan-breakdown table, itself sourced to Dave's Redistricting App).
- **Severe set is larger than RESEARCH.md's working assumption** (TN-9 certain, TN-8 "possibly"): the audit found direct evidence that TN-6 gained an entirely new anchor (downtown Nashville, confirmed by a June 24, 2026 Tennessee Lookout article quoting the new district's exact shape) and that TN-5 lost both of its prior anchors (Davidson AND Williamson counties, reassigned to CD-6 and CD-9 respectively) — both are anchor-changed calls under the rubric's second prong, independent of the more moderate presidential-swing proxy values those two districts show. TN-4 and TN-8 both scored severe primarily via the large presidential-swing proxy (-19.65 and -21.49 points respectively) plus corroborating anchor evidence (TN-4 gaining a Davidson slice; TN-8 named directly in the original three-way Memphis-split reporting).
- **TN-7 held to not-severe** despite gaining "the rest of Sumner County" — the swing proxy is near-zero (+0.19 points) and the district's suburban-Middle-TN anchor (Van Epps, Williamson/Franklin-area) is unchanged; the Sumner County gain is documented in the audit as a genuine boundary change that nonetheless falls below both rubric prongs.

## Deviations from Plan

None - plan executed exactly as written. Both tasks completed within the single artifact the plan's own Task 2 specifies; no scope creep, no DB writes, `essentials.offices` untouched.

## Issues Encountered

- **r.jina.ai returned 401 (appears to now require an API key)** for two localmemphis.com URLs listed in 161-RESEARCH.md's Sources (which were also directly 403-walled via curl). Worked around this by substituting equivalent, differently-sourced confirmation of the same facts (Shelby County three-way split, NAACP litigation) from the Wikipedia article, the two Tennessee Lookout articles that cover the same events (May 7 map-passage piece; June 10 litigation recap), and the NPR ground report — no load-bearing claim in the audit relies on a source that could not be directly fetched and read.
- No other issues. All 8 sources actually cited in the audit were fetched successfully via direct `curl`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 161-tn-correspondence-audit.md is ready for 161-06 (TN seed) to consume: the "Severe geo_id list: 4704, 4705, 4706, 4708, 4709" line gives 161-06 the exact set of TN districts that must be seeded but withheld from `/elections` per D-01b (using the Pitfall-#1 election_id-substitution mechanism from 161-RESEARCH.md), while 4701/4702/4703/4707 surface normally.
- 161-11's verify.sql will need a severe-race non-surfacing assertion scoped to these 5 geo_ids (not just TN-9) — this audit's expanded severe set (5/9, not just TN-9/TN-8) should be treated as the authoritative input for that gate, not the narrower RESEARCH.md working assumption.
- Litigation status should be spot-re-checked immediately before 161-06 executes if several days have passed, per the 7-day freshness note carried forward in this audit's Notes section.

---
*Phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca*
*Completed: 2026-07-03*

## Self-Check: PASSED

- FOUND: `.planning/phases/161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca/161-tn-correspondence-audit.md`
- FOUND: commit `906d0d1b` in `git log --oneline --all`
