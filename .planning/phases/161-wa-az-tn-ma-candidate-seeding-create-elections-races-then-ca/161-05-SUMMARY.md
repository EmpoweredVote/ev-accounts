---
phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
plan: 05
subsystem: data
tags: [stance-research, compass, wa-2026-house, inform.politician_answers, inform.politician_context, essentials.quotes]

# Dependency graph
requires:
  - phase: 161-04
    provides: 60 new WA challenger politician rows (external_id band -(53*10000+cd*100+seq)) seeded via race_candidates reconciliation
provides:
  - Federal-24 chairs-not-polarity stances for 46 of 60 new WA challengers (0 unsourced), pushed to prod
  - 14 documented whole-record honest-skips with written search trails for the 161-11 gate pin table
  - WA stance directory (wa-2026-house/) fully processed and closed out
affects: [161-11, USHC3-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Direct curl research (no Task/Agent tool available this session): Ballotpedia fetched directly with Accept-Language header (bypasses the anonymous-bot wall that blocks r.jina.ai's shared IP pool); r.jina.ai used for campaign-site JS-rendered pages; web.archive.org CDX API + direct wayback fetch for dead/archived campaign pages"
    - "Ballotpedia 'Campaign themes' section location varies per page (TOC anchor vs real content div) — must grep for 'has not yet completed' / 'completed Ballotpedia's Candidate Connection survey in' markers, not just the first id=\"Campaign_themes\" match, or real survey answers get missed"
    - "Cross-state homonym risk on common names (John Roco) — do not attribute another state's Ballotpedia-merged content to the target candidate without corroboration"

key-files:
  created:
    - backend/data/stance-research/wa-2026-house/jerrod-sessler.csv
    - backend/data/stance-research/wa-2026-house/andres-valleza.csv
    - backend/data/stance-research/wa-2026-house/keith-arnold.csv
    - backend/data/stance-research/wa-2026-house/kurtis-engle.csv
    - backend/data/stance-research/wa-2026-house/antony-barran.csv
    - backend/data/stance-research/wa-2026-house/catherine-hildebrand.csv
    - backend/data/stance-research/wa-2026-house/john-saulie-rohman.csv
    - backend/data/stance-research/wa-2026-house/brian-ogorman.csv
    - backend/data/stance-research/wa-2026-house/matthew-hayes.csv
  modified: []

key-decisions:
  - "No Task/Agent tool available this session (same constraint as 161-03/AZ) — researched all 23 remaining WA challengers directly via curl/wayback/Wikipedia fetches instead of dispatching politician-stance-researcher sub-agents, applying identical chairs-not-polarity/0-unsourced/honest-skip standards"
  - "14 of the 23 remaining challengers are pinned whole-record honest-skips: either no completed 2026 Ballotpedia Candidate Connection survey + no accessible campaign website (Chung, Derek Maynes, Jacob Perasso, Gwen Kirkland, Elpidia Saavedra, John Hughs, Austin Braswell), a completed survey/website with content too generic or off-scale to defensibly match any federal-24 chair (Spencer Meline, Jacek Kobiesa, Favian Valencia, Mary Silva, James Etzkorn), incoherent/disqualifying rhetoric with no usable policy position (David Blomstrom), or a cross-state-homonym identity risk (John Roco — Ballotpedia's page is dominated by an apparent 2016 Hawaii Senate candidacy under the same name)"
  - "Reused prior-cycle campaign material (2024 statements) for repeat candidates Keith Arnold and John Saulie-Rohman where no fresher 2026 material exists and no retraction was found, consistent with the pattern already used for incumbents elsewhere in this milestone"

requirements-completed: [USHC3-05]

# Metrics
duration: 165min
completed: 2026-07-04
---

# Phase 161 Plan 05: WA Candidate Stances Summary

**Closed out the WA federal-24 stance slice: pushed sourced chairs-not-polarity stances for the final 9 of 23 remaining challengers (46/60 total new WA candidates now stanced), with 14 remaining challengers pinned as documented whole-record honest-skips — 0 unsourced rows across all 60 in-scope WA candidates.**

## Performance

- **Duration:** ~165 min (this session; continues incremental work from prior sessions that researched 37 of 60 candidates)
- **Completed:** 2026-07-04
- **Candidates researched this session:** 23 (9 sourced + 14 honest-skip)
- **Files modified:** 9 new CSVs (gitignored scratch) + 1 SUMMARY.md (tracked)

## Accomplishments

- Researched and pushed sourced federal-24 stances for 9 more WA challengers: Jerrod Sessler (taxes/FAIRtax), Andres Valleza (trans-athletes, voting-rights), Keith Arnold (abortion, healthcare, taxes, deportation, tariffs, climate-change), Kurtis Engle (redistricting), Antony Barran (immigration, medicare/aid, social-security, taxes, housing, school-vouchers), Catherine Hildebrand (taxes, fossil-fuels), John Saulie-Rohman (abortion, campaign-finance, taxes), Brian O'Gorman (campaign-finance), Matthew Hayes (misinformation)
- Ran `_merge.ts` across all 46 candidate CSVs in the directory: 0 problems, 141 total rows
- Pushed to prod via `_push.ts`: 141 answers, 141 contexts, 23 new quotes inserted, 114 pre-existing quotes matched (idempotent re-push of earlier batches), 136 quotes selected for Read & Rank, 0 surname leaks
- Verified against prod: all 60 in-scope WA external_ids resolved to politician rows; 0 unsourced `politician_answers` rows (every answer has a paired `politician_context.sources` entry); exactly 14 candidates confirmed with 0 answers, matching the documented honest-skip list below
- Documented 14 whole-record honest-skips with written search trails for the 161-11 gate

## Per-Candidate Stance Counts (this session's 9)

| Candidate | External ID | District | Topics Covered | Values |
|---|---|---|---|---|
| Jerrod Sessler | -530406 | CD4 | taxes | 5 |
| Andres Valleza | -530804 | CD8 | trans-athletes, voting-rights | 4, 5 |
| Keith Arnold | -530803 | CD8 | abortion, healthcare, taxes, deportation, tariffs, climate-change | 4, 2, 2, 2, 2, 3 |
| Kurtis Engle | -531002 | CD10 | redistricting | 1 |
| Antony Barran | -530306 | CD3 | immigration, medicare/aid, social-security, taxes, housing, school-vouchers | 4, 3, 3, 4, 4, 4 |
| Catherine Hildebrand | -530106 | CD1 | taxes, fossil-fuels | 1, 2 |
| John Saulie-Rohman | -530303 | CD3 | abortion, campaign-finance, taxes | 2, 2, 2 |
| Brian O'Gorman | -530601 | CD6 | campaign-finance | 2 |
| Matthew Hayes | -530503 | CD5 | misinformation | 4 |

All rows carry >=1 real fetched http(s) source (Ballotpedia direct-fetch, campaign website, or web.archive.org). No party-inferred values.

## Roster Reconciliation — Whole-Record Honest-Skips (14) for the 161-11 gate

| Candidate | External ID | District | Trail |
|---|---|---|---|
| Chris D. Chung | -531005 | CD10 | Ballotpedia: no completed 2026 Candidate Connection; 2024 statement is for an unrelated race (WA Insurance Commissioner), no federal-24 content. Campaign website (chungforcongress.com) is a parked GoDaddy "Launching Soon" placeholder with no real content. OpenFEC search for "Chris Chung Washington" returned 0 results. |
| Derek Maynes | -531004 | CD10 | Ballotpedia's only Candidate Connection content is a 2015 statement for Puyallup School Board (unrelated office); no 2026 survey or campaign website found. |
| Jacob Perasso | -530901 | CD9 | Ballotpedia's 2026 Candidate Connection section exists but has no submitted answers (Socialist Workers Party perennial candidate); no campaign website found. |
| Spencer Meline | -530802 | CD8 | Completed 2026 Ballotpedia Candidate Connection survey read in full; entirely generic family/faith/small-business biography with no text matching any federal-24 topic's exact scale language. |
| Gwen Kirkland | -530703 | CD7 | No completed 2026 Ballotpedia survey; only a LinkedIn profile link found, no accessible policy content. |
| David W. Blomstrom | -530701 | CD7 | Extensive but incoherent record (2015/2020 school-board and gubernatorial survey responses containing conspiratorial and bigoted rhetoric); no coherent, defensible position on any federal-24 topic. Flagged as disqualifying content, not usable stance material. |
| Elpidia Saavedra | -530410 | CD4 | No completed 2026 Ballotpedia survey; only a Facebook page link found (walled, no accessible text). |
| Favian Valencia | -530405 | CD4 | Campaign website (valenciaforcongress.com) home + about pages reviewed directly; only marketing-level issue headlines ("Healthcare That Works," "Secure Borders and Common Sense Immigration System") with no elaborating text defensible against exact scale language. |
| John C. Hughs | -530404 | CD4 | No completed 2026 Ballotpedia survey; only a Facebook page link found (walled, no accessible text). |
| Jacek "Jack" Kobiesa | -530401 | CD4 | Completed 2026 Ballotpedia Candidate Connection survey read in full; extensive populist anti-establishment rhetoric (anti-corruption, anti-lobbying, English-as-national-language) with no text matching any federal-24 topic's exact scale language. |
| Austin Braswell | -530307 | CD3 | No completed 2026 Ballotpedia survey; no campaign website found. |
| John P. Roco | -530302 | CD3 | IDENTITY RISK FLAG: Ballotpedia's "John Roco" page content is dominated by an apparent 2016 Hawaii state Senate candidacy (johnroco.wix.com/hawaii, "Peace in the Pacific Rim" platform) — a likely cross-state homonym data merge, not reliably attributable to the WA-3 2026 candidate. No 2026 survey completed. Recommend the 161-11 gate confirm candidate identity via VoteWA filing before any future stance attempt. |
| Mary Silva | -530105 | CD1 | Completed 2026 Ballotpedia Candidate Connection survey read in full plus 2024 campaign-website statement; extensive but entirely conspiratorial/national-security-narrative content (banking cabals, foundation networks, COVID-mandate grievances) with no text matching any federal-24 topic's exact scale language. |
| James Etzkorn | -530103 | CD1 | Completed 2026 Ballotpedia Candidate Connection survey read in full; detailed platform (bureaucracy reduction, tech-sector competency, national debt via growth) genuinely does not intersect any of the 24 federal-24 topic scales despite full read. |

## Final Verification (all 60 in-scope WA new challengers)

- `_merge.ts`: 46 CSVs, 141 rows, **0 problems**
- `_push.ts`: 141 answers, 141 contexts, 23 quotesIns, 114 quotesDup, 136 selected, **0 leaks**
- Live prod query: 60/60 in-scope external_ids resolved; **0 unsourced `politician_answers` rows** (every answer paired to a non-empty `politician_context.sources`); exactly 14 candidates with 0 answers, matching the honest-skip table above exactly

## Task Commits

Per-task commits were made incrementally across sessions for the earlier 37 candidates (Task 1 setup + Task 2/3 batches, prior to this session). This session's work (9 new CSVs + push) is scratch/gitignored data with no source-controlled task commits required; only this SUMMARY.md is committed, per the plan's sequential-mode instructions.

**Plan metadata:** committed with this SUMMARY.md, STATE.md, and ROADMAP.md updates.

## Files Created/Modified
- `backend/data/stance-research/wa-2026-house/jerrod-sessler.csv` - 1 sourced stance (taxes)
- `backend/data/stance-research/wa-2026-house/andres-valleza.csv` - 2 sourced stances
- `backend/data/stance-research/wa-2026-house/keith-arnold.csv` - 6 sourced stances
- `backend/data/stance-research/wa-2026-house/kurtis-engle.csv` - 1 sourced stance
- `backend/data/stance-research/wa-2026-house/antony-barran.csv` - 6 sourced stances
- `backend/data/stance-research/wa-2026-house/catherine-hildebrand.csv` - 2 sourced stances
- `backend/data/stance-research/wa-2026-house/john-saulie-rohman.csv` - 3 sourced stances
- `backend/data/stance-research/wa-2026-house/brian-ogorman.csv` - 1 sourced stance
- `backend/data/stance-research/wa-2026-house/matthew-hayes.csv` - 1 sourced stance

## Decisions Made
- No Task/Agent tool was available in this session (same as 161-03/AZ) — all research was performed directly via curl (Ballotpedia with Accept-Language header, r.jina.ai for JS-rendered campaign sites, web.archive.org CDX/wayback for archived pages, Wikipedia raw export), applying the same chairs-not-polarity, 0-unsourced, and honest-skip-with-trail standards a dispatched sub-agent would have followed.
- Chose to flag John Roco as an identity-risk skip rather than use the Hawaii-attributed Ballotpedia content, consistent with the project's standing cross-state-homonym caution (Bouchard/Hancock/Barringer precedent).
- Reused 2024 campaign-website material for Keith Arnold and John Saulie-Rohman (repeat candidates with no fresher 2026 statement and no retraction found) rather than treating them as honest-skips, since their most recent public position is still their most recent public position.

## Deviations from Plan

None - plan executed exactly as written. The only environmental deviation (no Task/Agent tool available) mirrors the precedent already set and documented in 161-03 (AZ), so it is not treated as a new deviation requiring a rule citation.

## Issues Encountered

- `node_modules` was not installed in `backend/` at session start (`npx tsx` failed with `ERR_MODULE_NOT_FOUND` for `csv-parse`); ran `npm install` in `backend/` to restore dependencies before `_merge.ts`/`_push.ts` could run. This is routine environment setup, not a plan deviation.
- Ballotpedia's per-page "Campaign themes" section appears at two different `id="Campaign_themes"` anchor points on some pages (an early TOC-adjacent blurb and the real content div further down); naive fixed-offset extraction from the first match missed real survey answers for several candidates (Catherine Hildebrand, James Etzkorn) until content was re-extracted from the correct offset.
- DuckDuckGo Lite and Bing web search both began returning empty/bot-challenge responses after a handful of queries; abandoned general web search in favor of direct Ballotpedia fetches (which reliably return 200 with the correct `Accept-Language` header) plus targeted campaign-website domain guesses and `web.archive.org`'s CDX API for archived pages.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- WA federal-24 stance slice is fully closed: 46/60 new challengers sourced, 14/60 pinned honest-skips with trails, 0 unsourced rows verified live against prod.
- The 14-row honest-skip table above is ready to be copied into the 161-11 gate's pin table without further research.
- The John Roco identity-risk flag should be resolved (via VoteWA filing lookup) before any future attempt to research his stances, to avoid attributing a different person's record to the WA-3 candidate.

---
*Phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca*
*Completed: 2026-07-04*

## Self-Check: PASSED

All 9 newly created CSV files verified present on disk; SUMMARY.md verified present. Prod verification query (0 unsourced rows, 60/60 in-scope resolved, 14 zero-answer candidates matching the documented honest-skip table) re-confirmed above in "Final Verification."
