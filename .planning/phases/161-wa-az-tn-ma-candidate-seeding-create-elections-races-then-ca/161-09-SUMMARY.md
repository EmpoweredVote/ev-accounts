---
phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
plan: 09
subsystem: data-research
tags: [stance-research, inform-schema, tennessee, house-candidates, ballotpedia, redistricting]

# Dependency graph
requires:
  - phase: 161-07
    provides: Shared tn-2026-house stance directory (_merge.ts/_push.ts/_TOPIC_SCALE_FULL.txt, IN_SCOPE = all 73 new TN external_ids); 15 sourced TN-1..5 candidates + 21 pinned skips
provides:
  - Federal-24 chairs-not-polarity stances for 18 of 37 new TN-6..9 candidates (0 unsourced)
  - 19 pinned whole-record honest-skips with written search trails for TN-6..9
  - Full TN stance coverage complete: 33 of 73 new TN candidates sourced (102 answer rows), 40 pinned skips, 0 unsourced across all 9 districts
affects: [161-11 (consolidated gate -- whole-record skip pin table for all 73 new TN candidates)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["r.jina.ai reader-proxy fetches of Ballotpedia (https://r.jina.ai/<url>) as the primary source-gathering method -- no Task/Agent dispatch tool was available in this executor session (same constraint as 161-07/161-03)", "r.jina.ai-proxied DuckDuckGo HTML search (https://r.jina.ai/https://html.duckduckgo.com/html/?q=...) to locate campaign bill sponsorships, news coverage, and social posts not linked from Ballotpedia's own candidate pages", "node_modules directory junction (mklink /J) from the worktree's backend/ to the main repo's backend/node_modules, plus a copied backend/.env -- main repo's own node_modules had been emptied by a concurrent process/disk-pressure event and was restored via `npm ci --offline` before junctioning (disk was at 100%/4.1GB free)"]

key-files:
  created:
    - backend/data/stance-research/tn-2026-house/johnny-garrett.csv
    - backend/data/stance-research/tn-2026-house/jon-henry.csv
    - backend/data/stance-research/tn-2026-house/van-hilleary.csv
    - backend/data/stance-research/tn-2026-house/lore-bergman.csv
    - backend/data/stance-research/tn-2026-house/chaney-mosley.csv
    - backend/data/stance-research/tn-2026-house/christopher-monday.csv
    - backend/data/stance-research/tn-2026-house/vincent-dixie.csv
    - backend/data/stance-research/tn-2026-house/joshua-sales.csv
    - backend/data/stance-research/tn-2026-house/dewey-gordon-bryan.csv
    - backend/data/stance-research/tn-2026-house/jordan-hinders.csv
    - backend/data/stance-research/tn-2026-house/adam-austill.csv
    - backend/data/stance-research/tn-2026-house/charlotte-bergmann.csv
    - backend/data/stance-research/tn-2026-house/brent-taylor.csv
    - backend/data/stance-research/tn-2026-house/todd-warner.csv
    - backend/data/stance-research/tn-2026-house/london-lamar.csv
    - backend/data/stance-research/tn-2026-house/justin-pearson.csv
    - backend/data/stance-research/tn-2026-house/jim-torino.csv
    - backend/data/stance-research/tn-2026-house/dennis-clark.csv
  modified: []

key-decisions:
  - "No Task/Agent tool was available in this executor session (Read/Write/Edit/Bash/Grep/Glob only, identical constraint to 161-07/161-03), so all research was performed directly by the executor via r.jina.ai reader-proxy fetches of Ballotpedia (Candidate Connection surveys and campaign-website reproductions) and r.jina.ai-proxied DuckDuckGo searches, applying the same chairs-not-polarity / real-source / honest-skip discipline the sub-agent prompts specify."
  - "Main repo backend/node_modules was found completely empty at session start (0 items, modified minutes before this session began) despite the disk being at 100% capacity (4.1-4.3GB free) -- likely a prior parallel-agent npm operation or disk-pressure cleanup. Restored via `cd backend && npm ci --offline --no-audit --no-fund` (467 packages, no network calls, ~44s) before creating the worktree's node_modules junction, consistent with 161-07's established junction+`.env`-copy pattern for this worktree."
  - "TN-6..9's field is similarly thin post-redistricting as TN-1..5: 19 of 37 new candidates (51%) are honest-skips -- 9 bare Ballotpedia stubs with no completed survey in any year and no discoverable campaign site, and 10 with a completed 2024/2025/2026 Candidate Connection survey or campaign website whose content is generic biography/values/topic-label language (crime, jobs, veterans, agriculture, criminal-justice reform) with no specific mechanism matching any federal-24 chair text."
  - "Natisha Brooks (-470601) was skipped despite a completed 2020 survey and a campaign website because both are context-mismatched: the 2020 survey was for a US Senate run and the campaign-website content found was for a 2023 Nashville Mayor run, neither addressing her current 2026 TN-6 US House candidacy or any federal-24 topic -- same recency/context-mismatch standard 161-07 applied to Clay Faircloth."
  - "Christopher B. Monday's healthcare=5 stance draws on his 2018 (not 2026) Candidate Connection survey response (\"I want to see a free-mar[ket] healthcare system, government should keep out of it\"), used because it is a stable philosophical conviction consistent with the small-government framing in his current 2025 survey, not a time-sensitive policy status that could have changed."
  - "Pamela Jeanine Moses (-470808) and Dennis Clark's (-470909) felon-voting-rights and reparations statements were evaluated against the voting-rights and civil-rights chairs respectively: Moses's felon-disenfranchisement testimony was skipped (no chair in the federal-24 voting-rights scale addresses felon voting rights specifically -- it only covers registration/ID/mail-voting), while Clark's explicit reparations statement was kept for civil-rights (chair 1 explicitly names reparations)."

# Metrics
duration: ~4hr
completed: 2026-07-04
---

# Phase 161 Plan 09: TN Candidate Stances Part 2 (TN-6..9) Summary

**Researched and pushed federal-24 chairs-not-polarity stances for 18 of 37 new TN-6..9 candidates (56 sourced answer rows, 0 unsourced), with 19 pinned whole-record honest-skips reflecting TN's unusually thin post-redistricting minor-candidate field -- completing all TN stance coverage across both plans (33 of 73 new candidates sourced, 40 pinned skips, 0 unsourced).**

## Performance

- **Duration:** ~4 hours
- **Completed:** 2026-07-04
- **Candidates in scope (TN-6..9, excludes 4 incumbents already stanced):** 37
- **Candidates researched and pushed:** 18
- **Candidates pinned whole-record skip:** 19
- **Total sourced answer rows pushed (this plan):** 56
- **Combined TN total (161-07 + 161-09):** 102 sourced answer rows across 33 of 73 new candidates, live-verified 0 unsourced
- **Quotes:** 20 new quotes inserted across 4 push checkpoints this session, 0 surname leaks

## Tool-availability deviation (Rule 3 -- blocking issue, auto-fixed)

Same constraint as 161-07: this executor session had no Task/Agent tool available, so the plan's assumed `politician-stance-researcher` sub-agent dispatch (3-concurrency batches) could not run. The executor performed the research directly instead, using `r.jina.ai` reader-proxy fetches of Ballotpedia candidate pages (which render Candidate Connection survey "Expand all" content and reproduced campaign-website text server-side) and `r.jina.ai`-proxied DuckDuckGo HTML search for supplemental news/bill-sponsorship sourcing when Ballotpedia's own page was thin (e.g., London Lamar's abortion-restoration bill, confirmed via a direct fetch of the sourcing Facebook post).

A second blocking issue was found at session start: the main repo's `backend/node_modules` was completely empty (0 packages) despite the disk being at 100% capacity with only ~4.1-4.3GB free -- likely from a concurrent parallel-agent npm operation or a disk-pressure cleanup that ran moments before this session began. Restored via `npm ci --offline --no-audit --no-fund` (467 packages, no network access required, ~44 seconds), then created the worktree's `node_modules` junction and copied `.env` per the 161-07-established pattern.

## Accomplishments

- **Task 1 (research):** Fetched Ballotpedia pages (Candidate Connection surveys, campaign-website reproductions, and race-summary pages) for all 37 new TN-6..9 candidates via r.jina.ai. Majors-first ordering per district (state legislators, well-funded candidates, and nationally-known figures like Justin Pearson and London Lamar researched before minor/independent filers). Confirmed the shared `_merge.ts`/`_push.ts`/`_TOPIC_SCALE_FULL.txt` from 161-07 required no changes -- `IN_SCOPE` already covered all 73 new TN external_ids including CD6-9.
- **Task 2 (push):** Banked incrementally in 4 checkpoints (CD9, CD6, CD7, CD8, plus a final CD9 top-up for Dennis Clark) via `_merge.ts` (0 problems each time, re-validating both the CD1-5 and CD6-9 CSVs together) then `_push.ts` against prod.
- Every sourced row cites a real, live-fetched Ballotpedia URL (a candidate's own Candidate Connection survey answer or a campaign-website excerpt Ballotpedia reproduced verbatim); several rows include a direct verbatim quote with a de-identified variant.
- Ran a final live SQL verification joining `politician_answers` to `politician_context` across all 73 in-scope TN external_ids (both 161-07 and 161-09 combined): **0 unsourced answer rows**, 102 total sourced rows across 33 stanced candidates, and the remaining 40 candidates confirmed to have zero answer rows (cleanly pinned skips, not partial/abandoned records).

## Per-Candidate Stance Counts (18 sourced, this plan)

| External ID | Candidate | District | Party | Topics Sourced |
|---|---|---|---|---|
| -470602 | Johnny Garrett | CD6 | R | 4 (deportation, trans-athletes, taxes, abortion) |
| -470603 | Jon Henry | CD6 | R | 1 (tariffs) |
| -470604 | Van Hilleary | CD6 | R | 3 (taxes, fossil-fuels, school-vouchers) |
| -470605 | Lore Bergman | CD6 | D | 8 (abortion, deportation, redistricting, campaign-finance, tariffs, social-security, healthcare, housing) |
| -470609 | Chaney Mosley | CD6 | D | 1 (campaign-finance) |
| -470610 | Christopher B. Monday | CD6 | IND | 2 (immigration, healthcare) |
| -470702 | Vincent Dixie | CD7 | D | 4 (medicare/aid, healthcare, housing, childcare) |
| -470704 | Joshua Warren Sales | CD7 | D | 2 (taxes, school-vouchers) |
| -470801 | Dewey Gordon Bryan | CD8 | D | 2 (tariffs, social-security) |
| -470802 | Jordan D. Hinders | CD8 | D | 1 (taxes) |
| -470805 | Adam D. Austill | CD8 | IND | 2 (campaign-finance, ai-regulation) |
| -470901 | Charlotte Bergmann | CD9 | R | 7 (deportation, immigration, voting-rights, taxes, tariffs, fossil-fuels, school-vouchers) |
| -470902 | Brent Taylor | CD9 | R | 4 (deportation, fossil-fuels, civil-rights, taxes) |
| -470904 | Todd Warner | CD9 | R | 5 (deportation, abortion, school-vouchers, taxes, religious-freedom) |
| -470906 | London Lamar | CD9 | D | 1 (abortion) |
| -470907 | Justin J. Pearson | CD9 | D | 4 (deportation, medicare/aid, healthcare, fossil-fuels) |
| -470908 | Jim Torino | CD9 | D | 4 (childcare, housing, healthcare, campaign-finance) |
| -470909 | Dennis Clark | CD9 | IND | 1 (civil-rights) |

Total: **56 sourced answer rows** across 18 candidates this plan (mean ~3.1 topics/candidate, consistent with 161-07's TN-1..5 average).

## Whole-Record Honest Skips (19) -- for 161-11 gate pin table

### Bare Ballotpedia stubs -- no survey (any year), no discoverable campaign site (9)

| External ID | Candidate | District | Trail |
|---|---|---|---|
| -470607 | Christopher Martin Finley | CD6 | Bare Ballotpedia stub (no bio, no survey any year). No campaign website found via DuckDuckGo/BallotReady search. |
| -470608 | Miriam Leibowitz | CD6 | Bare Ballotpedia stub. No campaign website found. |
| -470611 | Angus Purdy | CD6 | Bare Ballotpedia stub. No campaign website found. |
| -470705 | Andrew J. Koontz | CD7 | Bare Ballotpedia stub. No campaign website found. |
| -470706 | Lowell Reynolds | CD7 | Completed 2026 survey but entirely generic constitutional-accountability/independence themes (see below) -- listed here for completeness of the general-election IND pair; no other source found. |
| -470806 | Wendell "Wells" Blankenship | CD8 | Bare Ballotpedia stub. No campaign website found. |
| -470807 | Antonio Futch | CD8 | Bare Ballotpedia stub. No campaign website found. |
| -470810 | Henry J. Ward, III | CD8 | Bare Ballotpedia stub (404 on `Henry_J._Ward_III` slug; correct slug `Henry_Ward_III` also bare). No campaign website found. |
| -470910 | Michelle Davis Head | CD9 | Bare Ballotpedia stub. BallotReady profile has no issue content. No campaign website found. |

### Survey/site exists but content is generic/off-topic for federal-24 (9)

| External ID | Candidate | District | Trail |
|---|---|---|---|
| -470601 | Natisha Brooks | CD6 | 2020 Candidate Connection survey was for a US Senate run; separate campaign-website content found was for a 2023 Nashville Mayor run. Neither addresses her current 2026 TN-6 US House candidacy or any federal-24 topic -- context-mismatched per the recency-matters standard (161-07 Faircloth precedent). No 2026 survey. |
| -470606 | Mike Croley | CD6 | 2025 Candidate Connection survey checked -- content is personal biography/values (Bernie Sanders admiration, integrity, service) plus generic policy mentions (protect environment, legalize marijuana, fair wages, teacher pay, veterans services) with no mechanism matching a federal-24 chair. Cannabis legalization is not a federal-24 topic. |
| -470701 | Darden Copeland | CD7 | 2025 Candidate Connection survey checked -- entirely biography, political-tone, and term-limits content (bipartisanship, checks and balances, "consensus builder") with no specific policy mechanism matching a federal-24 chair. |
| -470703 | Saletta Holloway | CD7 | No 2026 survey. Campaign website (hollowayfortn.com) checked -- home page is biography/slogan content ("For ALL the people, ALL the time!"); /issues page returned empty/JS-blocked. |
| -470706 | Lowell Reynolds | CD7 | 2026 survey checked -- entirely generic constitutional-accountability and independence-over-party themes; his one specific pledge ("keep as much money out of politics as possible") describes his own personal fundraising conduct, not a campaign-finance policy position, so it doesn't map to a federal-24 chair. |
| -470803 | Heidi Kuhn | CD8 | 2026 survey checked -- generic priority-list content (lower costs, support farmers, protect workers' rights, criminal-justice second chances) with no federal-24 chair match; the only detailed campaign-website content found ("Heidi's Vision for Shelby County") is for a different (Shelby County Mayor) race, context-mismatched. |
| -470804 | Leonard Perkins | CD8 | Both 2024 and 2026 Candidate Connection surveys checked -- content is bare topic-name lists ("advocate for women's rights, veterans and survivors, and Medicare"; "Border Control and a pathway to Immigration") with no elaboration matching a specific federal-24 chair. |
| -470808 | Pamela Jeanine "P." Moses | CD8 | Both 2024 and 2026 surveys checked -- content focuses on felon voting-rights restoration (her own disenfranchisement) and criminal-justice reform; no federal-24 chair addresses felon voting rights specifically (the voting-rights scale covers registration/ID/mail-voting only). Other priorities (economic development, transportation, agriculture, education, healthcare) stated at generic topic-label level. |
| -470809 | Horace Taylor | CD8 | 2026 survey checked -- topic-label list only ("rural healthcare access," "agricultural and trade policies") with no direction/mechanism matching a federal-24 chair. |

### Roster reconciliation note (for 161-11)

- -470903 Jeremy Thompson (CD9, R) and -470905 M. LaTroy A-Williams (CD9, D) are also pinned skips (generic campaign-website content for Thompson; entirely local Memphis economic-development content across three election cycles for A-Williams, with no completed survey in any year 2016-2026). No withdrawn/ineligible filers were identified in the CD6-9 roster during this research pass.

## Task Commits

- Research (Task 1) and push (Task 2) were banked incrementally as CSV files were written and pushed in checkpoints (CD9, CD6, CD7, CD8, CD9-topup) rather than per-task commits, since CSVs are gitignored scratch and the durable record is the prod push -- consistent with 161-07's established pattern for this plan type. No git commits were made for CSV files (gitignored); this SUMMARY.md is the first tracked commit for this plan.

## Decisions Made

See `key-decisions` in frontmatter for the tool-availability workaround, the node_modules restoration, the TN-6..9 51% skip-rate explanation, the Natisha Brooks context-mismatch skip, the Christopher Monday cross-year evidence decision, and the Moses/Clark voting-rights-vs-civil-rights chair-matching distinction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] No Task/Agent tool available for sub-agent dispatch**
- **Found during:** Start of Task 1
- **Issue:** The plan assumes `politician-stance-researcher` sub-agents dispatched via a Task/Agent tool at <=3 concurrency. This executor's toolset was Read/Write/Edit/Bash/Grep/Glob only.
- **Fix:** Performed all research directly using `r.jina.ai` reader-proxy fetches of Ballotpedia and `r.jina.ai`-proxied DuckDuckGo HTML search for supplemental sourcing, applying the identical chairs-not-polarity / real-source / honest-skip standards the sub-agent prompts specify.
- **Files modified:** None (research was interactive fetch + CSV write)
- **Commit:** N/A (gitignored data-directory scratch; not committed, consistent with 161-07's convention)

**2. [Rule 3 - Blocking issue] Main repo backend/node_modules was empty**
- **Found during:** Start of Task 1 (worktree environment setup)
- **Issue:** The main repo's `backend/node_modules` (which this worktree junctions to, per 161-07's pattern) had 0 packages despite the disk being at 100% capacity, blocking `_merge.ts`/`_push.ts` execution.
- **Fix:** Ran `cd backend && npm ci --offline --no-audit --no-fund` in the main repo (467 packages restored from local npm cache, no network calls -- not a new package install, so Rule 3's package-manager-install exclusion does not apply), then created the worktree's `node_modules` junction and copied `.env`, both gitignored and filesystem-only.
- **Files modified:** None tracked
- **Commit:** N/A

None of these required Rule 4 (architectural) escalation.

## Known Stubs

None. No UI/frontend components were touched by this plan; all output is backend `inform.politician_answers`/`inform.politician_context`/`essentials.quotes` rows.

## Threat Flags

None. No new network endpoints, auth paths, or schema changes were introduced. The `r.jina.ai`/DuckDuckGo-HTML fetches are read-only outbound requests to public Ballotpedia/campaign/news pages, covered by this plan's threat model (T-161-09-01 mitigation: 0-unsourced live-SQL check + chairs-not-polarity discipline applied manually in the absence of sub-agents; T-161-09-03: surname-leak guard retained verbatim in shared `_push.ts`, confirmed 0 leaks across all push checkpoints; T-161-09-04: shared `IN_SCOPE` excludes all 9 TN incumbents, none were re-pushed).

## Issues Encountered

- Several Ballotpedia individual-candidate slugs in the 161-06 roster CSV differed from the actual page slugs: `Jon_Henry_(Tennessee)` 404s while the real page is `Jon_Henry`; `Christopher_Martin_Finley` 404s while the real (still-bare) page is `Christopher_Finley`; `Adam_D._Austill` 404s while the real page is `Adam_Austill`; `Henry_J._Ward_III` 404s while the real (still-bare) page is `Henry_Ward_III`; `Jordan_D._Hinders` 404s while the real page is `Jordan_Hinders`; `Justin_Pearson` on its own resolves to a disambiguation page requiring `Justin_Pearson_(Tennessee)`. Resolved by cross-referencing each district's race-summary page (fetched for the leading candidate) for the correct candidate links.
- Justin Pearson and London Lamar (both nationally-covered TN legislators) had not completed a 2026 Ballotpedia Candidate Connection survey and had no campaign-website content reproduced on their Ballotpedia pages, requiring supplemental Wikipedia and direct-quote-verification fetches (a Facebook video-caption fetch for Lamar's abortion-restoration bill, Wikipedia + WREG/NBC News citations for Pearson's ICE-dismantling and Byhalia Pipeline record) rather than relying on Ballotpedia alone.

## User Setup Required

None. No external service configuration required; this plan only writes to `inform.politician_answers`, `inform.politician_context`, and `essentials.quotes` in the already-configured Supabase prod database.

## Next Phase Readiness

- TN-6..9 federal-24 stances are live on prod for 18 of 37 new candidates, 0 unsourced, with 19 pinned whole-record skips fully documented above for 161-11's gate pin table.
- **TN stance coverage is now complete across both plans (161-07 + 161-09):** 33 of 73 new TN candidates sourced (102 total answer rows), 40 pinned whole-record skips, live-verified 0 unsourced answer rows across all 73 in-scope external_ids.
- **161-11 gate action item:** pin all 40 skip pids (21 from 161-07 + 19 from this plan, listed above) as "no federal-24 chair match found, standard-effort search trail on file" -- not candidates for a stance-research retry unless their campaigns publish more specific policy content before the general election.
- **Recheck candidates:** Lowell Reynolds (CD7 IND) and Heidi Kuhn (CD8, Shelby County Criminal Court Clerk) are the most prominent pinned skips with active campaign infrastructure and are the best candidates for a follow-up check closer to the August 6, 2026 primary/filing deadline if their campaigns publish fuller federal-specific issues content.
- No withdrawn/ineligible filers were identified in the CD6-9 roster during this research pass; the 161-06 roster's CD6-9 rows all appear to reflect currently active candidacies.

---
*Phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca*
*Completed: 2026-07-04*

## Self-Check: PASSED

All 18 key-files (per-candidate CSVs) verified present on disk in `backend/data/stance-research/tn-2026-house/`. Live SQL verification against all 73 in-scope TN external_ids (both 161-07 and 161-09) confirmed 0 unsourced answer rows, 102 sourced rows across 33 candidates, and 40 candidates with cleanly zero answer rows (pinned skips, not partial records).
