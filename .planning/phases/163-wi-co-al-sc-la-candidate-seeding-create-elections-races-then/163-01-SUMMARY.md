---
phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then
plan: 01
subsystem: database
tags: [redistricting, correspondence-audit, alabama, louisiana, research]

# Dependency graph
requires:
  - phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
    provides: D-01/D-01a/D-01b redistricting-handling pattern (audit-first, severity-routed withholding), TN audit structure/rubric to clone
  - phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
    provides: MO audit as second concrete example of the same artifact shape
provides:
  - AL correspondence audit (163-al-correspondence-audit.md): all 7 AL districts scored, severe set = {0102}
  - LA correspondence audit (163-la-correspondence-audit.md): all 6 LA districts scored, severe set = {2202, 2206}
  - Enrolled-statute parish-by-parish comparison method (SB8 2024 vs SB121 2026) as a stronger-than-precedent evidentiary technique for future redistricting audits
affects: [163-04, 163-06, 163-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Enrolled-legislative-text diff for redistricting audits: fetch both the OLD and NEW enrolled bill text directly from the state legislature's document server and compare parish/precinct assignments line-by-line, rather than relying only on secondary news reporting or a presidential-margin proxy"
    - "Distinguish 'special/redo primary required' (procedural: any line move triggers a re-vote) from 'severity-rubric-crossing boundary shift' (substantive: >25% population moved OR anchor changed) — these are NOT the same signal and pre-audit hypotheses should not conflate them"

key-files:
  created:
    - .planning/phases/163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then/163-al-correspondence-audit.md
    - .planning/phases/163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then/163-la-correspondence-audit.md
    - .planning/phases/163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then/163-01-SUMMARY.md
  modified: []

key-decisions:
  - "AL severe geo_id set = {0102} only — of the four Aug-11 special-primary districts (0101/0102/0106/0107), only AL-2 crosses the severity rubric (loses its entire majority-Black Mobile-area constituency, BVAP drops 48.7%->39.9%); AL-1/6/7 needed special primaries for procedural reasons (any line move triggers a redo) but their boundary shifts sit below the rubric threshold on the evidence"
  - "LA severe geo_id set = {2202, 2206} — LA-6 (dissolved Fields corridor) confirms the pre-audit hypothesis; LA-2 (gains a new Baton Rouge metro anchor + loses Assumption Parish) overturns the RESEARCH.md prediction that LA-2 was 'likely not-severe'; LA-1/4/5 (three of RESEARCH's four 'likely severe' predictions) score NOT-SEVERE because their core anchors (Gulf/Bayou corridor, Shreveport-Bossier, Monroe) are preserved or strengthened despite real, evidence-based boundary shifts"
  - "LA-4 flagged as a genuine borderline case (~20-22% population-moved estimate) for downstream spot-check during 163-11 or Phase 164.1, though scored NOT-SEVERE on anchor-preservation evidence"
  - "Used the actual enrolled SB8 (2024, old LA map) and SB121 (2026, new LA map) legislative texts — fetched directly from legis.la.gov — for a parish-by-parish diff, which is stronger evidence than the presidential-margin-proxy method used in the TN/MO precedent audits"

patterns-established:
  - "Pattern: for any future correspondence audit, fetch the actual enrolled old-map and new-map statutory text when both exist and are retrievable, rather than relying solely on secondary reporting"

requirements-completed: [USHC3-03]

# Metrics
duration: 55min
completed: 2026-07-05
---

# Phase 163 Plan 01: AL + LA Correspondence Audits Summary

**Enrolled-statute parish/precinct diff (SB8-2024 vs SB121-2026) finds AL severe={AL-2 only, 1/7} and LA severe={LA-2, LA-6, 2/6} — overturning half of RESEARCH.md's pre-audit severity predictions in both directions**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-07-05T18:27:00Z (approx.)
- **Completed:** 2026-07-05T19:22:38Z
- **Tasks:** 2
- **Files modified:** 2 created (audits) + this SUMMARY.md

## Accomplishments

- Scored all 7 AL districts (geo_id 0101-0107) against the TN/MO-cloned severity rubric using Wikipedia's sourced county-by-county old-vs-new breakdown, Alabama Reflector's BVAP data, and two independent litigation trackers (Loyola Law School's All About Redistricting, Democracy Docket) re-verified current as of execution date.
- Scored all 6 LA districts (geo_id 2201-2206) using a stronger evidentiary method than any prior redistricting audit in this project: fetched and diffed the **actual enrolled legislative text** of both the old (SB8, 2024) and new (SB121, 2026) maps directly from `legis.la.gov`, comparing parish/precinct assignments statute-to-statute rather than relying on secondary reporting.
- Both severe geo_id lists are enumerated as machine-consumable lines ready for 163-04/163-06 (seed withholding) and 163-11 (gate assertions).
- Surfaced and documented a genuinely counter-intuitive, evidence-driven finding for AL: three of the four Aug-11 special-primary districts (AL-1/6/7) do NOT cross the severity threshold — the special primary is a procedural trigger (Alabama law requires re-running any district whose lines moved at all), not evidence of severity itself. This directly tests and partially refutes 163-RESEARCH.md's "AL-1/2/6/7 all severe" hypothesis with named-source, county-level evidence.
- Surfaced the mirror-image finding for LA: the pre-audit "likely severe" set (LA-1/4/5/6) and "likely not-severe" set (LA-2/3) both had a wrong district — LA-2 (predicted not-severe) is actually severe (gains a new Baton Rouge anchor), while LA-1/4/5 (predicted severe) are not-severe (anchors preserved/strengthened).

## Task Commits

Each task was committed atomically:

1. **Task 1: Gather + score AL old-vs-new district composition; write 163-al-correspondence-audit.md** - `29bea932` (docs)
2. **Task 2: Gather + score LA old-vs-new district composition (parish-level); write 163-la-correspondence-audit.md** - `e1c178ec` (docs)

**Plan metadata:** (this commit, following SUMMARY.md write)

## Files Created/Modified

- `.planning/phases/163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then/163-al-correspondence-audit.md` - 7-row AL severity table, rubric, sources, severe geo_id list = `0102`
- `.planning/phases/163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then/163-la-correspondence-audit.md` - 6-row LA severity table (parish-level, enrolled-statute-sourced), rubric, sources, severe geo_id list = `2202, 2206`

## Decisions Made

See `key-decisions` in frontmatter above. Summary: AL severe = `{0102}` (1 of 7); LA severe = `{2202, 2206}` (2 of 6). Both sets deviate from RESEARCH.md's pre-audit hypotheses in evidence-driven ways (AL: smaller severe set than predicted, all four special-primary districts individually adjudicated; LA: same severe-set SIZE as predicted but with the WRONG two districts swapped in the original hypothesis — LA-2 in, LA-1/4/5 out).

## Deviations from Plan

None — plan executed exactly as written. Both tasks produced the required artifacts with the required structure (verbatim-cloned TN rubric, per-district table, "Severe geo_id list:" line, source URLs, "Notes for downstream consumers" section). No DB writes occurred; `essentials.offices` was not touched, consistent with the plan's threat-model disposition (T-163-01-01/02/03, all `mitigate`/`accept-with-check`, satisfied by the rubric application, source citation, and litigation re-verification respectively).

One methodological enhancement beyond the plan's minimum bar (not a deviation from required scope, but worth noting): for LA, the plan's `<action>` block suggested fetching "Louisiana's official 2026 redistricting site (redist.legis.la.gov/2026_Files/2026CONGRESSACT2) and/or Wikipedia's LA 2026 congressional district tables." The official redist.legis.la.gov site returned 403 Forbidden. Rather than falling back only to secondary reporting, the enrolled bill text (SB121 Act 2 and its repealed predecessor SB8 Act 2) was located and fetched directly from `legis.la.gov`'s document server, which gave parish-and-precinct-level statutory ground truth for both the old and new maps — a stronger source than either the blocked official redistricting site or Wikipedia's tables would have provided.

## Issues Encountered

- `redist.legis.la.gov` (LA's official 2026 redistricting file server, suggested in RESEARCH.md and the plan) returned HTTP 403 Forbidden on direct fetch. Resolved by locating the enrolled bill text (SB121/Act 2 and SB8/Act 2) via `legis.la.gov`'s `BillInfo.aspx`/`ViewDocument.aspx` document links instead, which are the authoritative source for the same statutory boundary descriptions.
- Several news sources (Alabama Reflector, law.justia.com, NOLA.com, Ballotpedia, al.com) were Cloudflare/paywall/JS-walled to direct `curl` fetches; resolved via the `r.jina.ai` proxy per the project's standing fetch-wall playbook, consistent with memory note "Ballotpedia hard-walled to curl/jina but Playwright renders it" (Ballotpedia specifically could not be recovered even via jina in this session — no Playwright/browser tool was available — but sufficient alternative sourcing existed).
- Wikipedia's LA 2026 House-elections article was found to carry stale (pre-SB121) candidate-filing text in its District 6 subsection (still listing Cleo Fields as "presumptive nominee" for a district described with old-map geography). This was explicitly identified via a corroborating DuckDuckGo search and documented as a source-reliability caveat in the LA audit rather than used uncritically.

## User Setup Required

None - no external service configuration required. Pure research artifacts, no DB writes, no code changes.

## Next Phase Readiness

- 163-04 (AL seed) can proceed with the AL severe geo_id set `{0102}`: wire AL-2's race to a withheld "Polygon Pending"-style election; wire AL-1/3/4/5/6/7 to the normal `'AL 2026 Statewide General'` election.
- 163-06 (LA seed) can proceed with the LA severe geo_id set `{2202, 2206}`: wire LA-2 and LA-6's races to a withheld election; wire LA-1/3/4/5 to the normal `'LA 2026 Statewide General'` election (jungle-primary modeling, `primary_party=NULL`, per Critical Question 2 — unaffected by this audit).
- 163-11 (consolidated verify + coordinate-smoke) can add AL-SEVERE (assert 0102's race parent election is the withheld one) and LA-SEVERE (assert 2202/2206) assertion blocks, plus negative coordinate-smoke samples for those three geo_ids, analogous to 162's MO-SEVERE block.
- No blockers. Both audits re-verified litigation currency same-day as execution (2026-07-05); if 163-04/163-06 execute more than a few days later, both audits' "Notes for downstream consumers" sections flag the need to re-check litigation status before seeding.

---
*Phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then*
*Completed: 2026-07-05*

## Self-Check: PASSED

- FOUND: `.planning/phases/163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then/163-al-correspondence-audit.md`
- FOUND: `.planning/phases/163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then/163-la-correspondence-audit.md`
- FOUND: `.planning/phases/163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then/163-01-SUMMARY.md`
- FOUND commit: `29bea932` (AL audit)
- FOUND commit: `e1c178ec` (LA audit)
