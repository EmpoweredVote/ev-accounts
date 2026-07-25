---
phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
plan: 10
subsystem: data-research
tags: [stance-research, inform-schema, massachusetts, house-candidates, progressive-mass, ballotpedia]

# Dependency graph
requires:
  - phase: 161-08
    provides: MA candidate reconciliation roster (18 new external_ids across CD1/3/4/5/6/8/9, 6 incumbents skipped, Moulton open seat)
provides:
  - Federal-24 chairs-not-polarity stances for the final 4 of 18 new MA candidates (0 unsourced)
  - 1 pinned whole-record honest-skip with written search trail (R. Tyler MacAllister, MA-9)
  - Full MA stance coverage complete: 17 of 18 new MA candidates sourced (130 answer rows), 1 pinned skip, 0 unsourced across all 9 districts -- completes USHC3-05 for the phase
affects: [161-11 (consolidated gate -- whole-record skip pin table across WA/AZ/TN/MA)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["No Task/Agent tool was available in this executor session (Read/Write/Edit/Bash/Grep/Glob only, same constraint as 161-07/161-09) -- research performed directly via curl (DuckDuckGo HTML search + campaign-site fetches) and r.jina.ai reader-proxy for JS-walled/paywalled sources (Ballotpedia, MassLive)", "pdftotext -layout used to extract full text from a Progressive Mass PAC candidate-endorsement questionnaire PDF (36 pages, Craig Swallow) -- a rich structured Y/N + free-text policy source not previously used in this phase", "backend/node_modules was found completely empty (0 packages) at session start on the main working tree (not a worktree) -- restored via `npm ci` (lockfile-exact, no new/unpinned packages, no network resolution of new versions) rather than treating it as an unfixable package-install blocker"]

key-files:
  created:
    - backend/data/stance-research/ma-2026-house/robert-burke.csv
    - backend/data/stance-research/ma-2026-house/craig-swallow.csv
  modified: []

key-decisions:
  - "backend/node_modules was completely empty (0 packages, confirmed via `find node_modules -maxdepth 1 -type d` returning only the directory itself) despite the non_negotiables assuming it was 'just restored.' Restored via `npm ci` -- lockfile-exact restoration of already-vetted, pre-existing dependencies is materially different from installing a new/unfamiliar package (the Rule-3 exclusion's slopsquatting concern), so this was treated as a Rule-3 auto-fixable blocking issue rather than escalated to a package-legitimacy checkpoint."
  - "Patrick Roath (-250801) already had a complete, high-quality 11-topic research CSV sitting on disk from a prior session (unpushed) -- verified via live prod query (0 answer rows) that it had genuinely never been pushed, then merged + pushed it as-is rather than re-researching."
  - "R. Tyler MacAllister (-250902, MA-9 R) is a pinned whole-record honest-skip: checked 4 pages of his own campaign site (home/about/policies/solutions), Ballotpedia (no completed Candidate Connection survey), a local Sippican Week announcement article, and attempted MassLive (captcha-walled) and smarter.vote (thin) -- every source is pure biography ('lifelong Cape Codder,' '5 terms on the Mattapoisett Select Board') or single-word issue-area labels ('Cost of Living,' 'Public & Child Safety,' 'Veterans & Seniors') with no specific mechanism matching any federal-24 chair text. No stance rows written for him; IN_SCOPE in _merge.ts already included his external_id so the 0-problems merge count correctly reflects 17 (not 18) candidates with rows."
  - "Craig Swallow's (-250901) 17-topic coverage came from a single high-density source -- a 36-page Progressive Mass PAC candidate-endorsement questionnaire PDF with direct Y/N answers and free-text elaboration on nearly every federal-24 topic -- extracted via `pdftotext -layout` after the plain PDF read tool reported it exceeded the 20-page-per-request limit. This is the richest single-source yield in the MA slice; two topics (ai-regulation, ukraine-support, redistricting, religious-freedom, misinformation, tariffs, trans-athletes) were still skipped because the questionnaire's coverage of those areas was either absent or too indirect to match an exact chair (e.g., 'oppose Big Tech's state-AI-preemption efforts' does not specify an AI regulation stance)."
  - "Robert Gerald Burke's (-250802) healthcare=5 stance ('personal catastrophic insurance you buy yourself') and deportation=5 stance ('remove every invader...not just the bad ones') were sourced from his own campaign site's Priorities and Meet Rob pages -- both are unambiguous, unhedged statements that map cleanly to the most extreme chair on each scale without inference."

# Metrics
duration: ~2.5hr
completed: 2026-07-04
---

# Phase 161 Plan 10: MA Candidate Stances (final 4) Summary

**Researched and pushed federal-24 chairs-not-polarity stances for the last 4 of 18 new MA candidates (34 sourced answer rows: Roath 11, Burke 6, Swallow 17), with 1 pinned whole-record honest-skip (MacAllister, MA-9) -- completing full MA stance coverage and closing out USHC3-05 for the phase.**

## Performance

- **Duration:** ~2.5 hours
- **Completed:** 2026-07-04
- **Candidates in scope (new MA, excludes 6 incumbents + 2 already-wired incumbents):** 18
- **Candidates researched and pushed this plan:** 4 (Roath, Burke, Swallow sourced; MacAllister pinned skip)
- **Candidates pinned whole-record skip:** 1 (MacAllister)
- **Total sourced answer rows pushed this plan:** 34 (Roath 11, Burke 6, Swallow 17)
- **Combined MA total (this plan + prior 14 already-pushed):** 130 sourced answer rows across 17 of 18 new candidates, live-verified 0 unsourced
- **Quotes:** 30 new quotes inserted this push (7 Roath, 6 Burke, 17 Swallow), 36 already-present duplicates re-confirmed idempotently, 0 surname leaks

## Environment deviation (Rule 3 -- blocking issue, auto-fixed)

`backend/node_modules` was completely empty (0 packages) at session start on the main working tree, despite project memory noting it had "just been restored." This blocked every subsequent step -- `tsx`, `pg`, and `csv-parse` were all unavailable, so nothing (not even a prod read query) could run. Restored via `npm ci` (467 packages, lockfile-exact, no new or unpinned packages resolved) rather than treating this as the excluded "package fails to install" scenario -- `npm ci` restores dependencies already vetted and used throughout this codebase, which is materially different from installing an unfamiliar/new package where slopsquatting is a concern.

## Accomplishments

- **Verified prod state first:** queried `essentials.politicians` joined to `inform.politician_answers` for all 18 in-scope external_ids, confirming exactly 4 had zero answer rows (Roath, Burke, Swallow, MacAllister) and the other 14 were already fully pushed from a prior session -- avoiding any redundant re-research.
- **Patrick Roath (-250801, MA-8 D):** found a complete, high-quality 11-topic CSV already on disk (abortion, immigration, deportation, housing, childcare, healthcare, medicare/aid, ukraine-support, climate-change, fossil-fuels, campaign-finance) sourced entirely from his own campaign issues pages (patrickroath.com/plan/*). Verified it had never actually been pushed, then included it in this plan's merge+push as-is.
- **Robert Gerald Burke (-250802, MA-8 R):** researched via his campaign site (burke4congress.us/priorities, /meet-rob) -- 6 topics (immigration, deportation, voting-rights, healthcare, taxes, tariffs), each an unhedged direct statement matching an extreme chair (e.g., "remove every invader...not just the bad ones" = deportation value 5; "personal catastrophic insurance you buy yourself" = healthcare value 5).
- **Craig Swallow (-250901, MA-9 D):** researched primarily via a 36-page Progressive Mass PAC candidate-endorsement questionnaire PDF (extracted with `pdftotext -layout`) containing direct Y/N + free-text answers -- yielded 17 topics, the richest single-candidate coverage in the entire MA slice.
- **R. Tyler MacAllister (-250902, MA-9 R):** exhausted available sources (own campaign site x4 pages, Ballotpedia, local news announcement, MassLive attempt, smarter.vote attempt) and found only generic biography and single-word issue labels with zero chair-matchable specifics -- pinned as a whole-record honest-skip with the trail documented below.
- Ran `_merge.ts` (0 problems, 130 total rows, 17 of 18 in-scope candidates with rows) then `_push.ts` against prod -- idempotent re-push of the full directory (including the 14 already-done CSVs) confirmed no duplicate-row errors and 0 surname leaks.
- Final live SQL verification joining `politician_answers` to `politician_context` across all 18 in-scope MA external_ids: **0 unsourced answer rows**.

## Per-Candidate Stance Counts (this plan's 4)

| External ID | Candidate | District | Party | Topics Sourced |
|---|---|---|---|---|
| -250801 | Patrick Roath | MA-8 | D | 11 (abortion, immigration, deportation, housing, childcare, healthcare, medicare/aid, ukraine-support, climate-change, fossil-fuels, campaign-finance) |
| -250802 | Robert Gerald Burke | MA-8 | R | 6 (immigration, deportation, voting-rights, healthcare, taxes, tariffs) |
| -250901 | Craig Swallow | MA-9 | D | 17 (abortion, childcare, civil-rights, climate-change, deportation, fossil-fuels, healthcare, homelessness, housing, immigration, medicare/aid, same-sex-marriage, school-vouchers, social-security, taxes, campaign-finance, voting-rights) |
| -250902 | R. Tyler MacAllister | MA-9 | R | 0 -- pinned whole-record skip (see below) |

Total: **34 sourced answer rows** across 3 candidates this plan.

## Full MA Slice Coverage (all 18 new candidates, combined)

| District | Candidate | External ID | Topics | Status |
|---|---|---|---|---|
| MA-1 | Jeromie Whalen | -250101 | 7 | Sourced (prior session) |
| MA-1 | Nadia Milleron | -250102 | 3 | Sourced (prior session) |
| MA-3 | Gary J. Grossi | -250301 | 2 | Sourced (prior session) |
| MA-4 | Jason Poulos | -250401 | 5 | Sourced (prior session) |
| MA-4 | Thomas Stalcup | -250402 | 1 | Sourced (prior session) |
| MA-5 | Tarik Samman | -250501 | 5 | Sourced (prior session) |
| MA-5 | Jonathan Paz | -250502 | 4 | Sourced (prior session) |
| MA-6 | Bethany Andres-Beck | -250601 | 16 | Sourced (prior session) |
| MA-6 | John A. Beccia III | -250602 | 5 | Sourced (prior session) |
| MA-6 | Jamie Belsito | -250603 | 17 | Sourced (prior session) |
| MA-6 | Dan Koh | -250604 | 7 | Sourced (prior session) |
| MA-6 | Mariah Lancaster | -250605 | 16 | Sourced (prior session) |
| MA-6 | Tram Nguyen | -250606 | 7 | Sourced (prior session) |
| MA-6 | Micah Quinney Jones | -250607 | 1 | Sourced (prior session) |
| MA-8 | Patrick Roath | -250801 | 11 | **Sourced (this plan)** |
| MA-8 | Robert Gerald Burke | -250802 | 6 | **Sourced (this plan)** |
| MA-9 | Craig Swallow | -250901 | 17 | **Sourced (this plan)** |
| MA-9 | R. Tyler MacAllister | -250902 | 0 | **Pinned skip (this plan)** |

**Total: 130 sourced answer rows across 17 of 18 new MA candidates. 0 unsourced. 1 pinned whole-record skip.**

## Whole-Record Honest Skip (1) -- for 161-11 gate pin table

| External ID | Candidate | District | Trail |
|---|---|---|---|
| -250902 | R. Tyler MacAllister | MA-9 (R) | Checked 4 pages of his own campaign site (macallister4congress.com: home, /about, /policies, /solutions) -- /policies is a legal/FEC-disclaimer page with no issue content; /solutions lists 6 bare issue-area headers ("Sustainable Fishing & the Working Waterfront," "Cost of Living," "Public & Child Safety," "Accountable Government," "Veterans & Seniors," "Our Coastal Way of Life") each with one boilerplate sentence and no specific mechanism. Ballotpedia confirmed he has not completed the 2026 Candidate Connection survey. A local Sippican Week article (Apr 30, 2026) covering his campaign launch is purely biographical (20 years on the Mattapoisett Select Board). MassLive's profile piece is captcha-walled (DataDome, unreachable via curl or r.jina.ai proxy); smarter.vote's page is a 1.5KB stub with no content. No source found ties him to a specific position matching any federal-24 chair text. |

## Task Commits

- Research (research directly by the executor -- no Task/Agent tool available this session) and push were banked in a single merge+push cycle for this plan's 3 sourced candidates (Roath, Burke, Swallow), consistent with 161-07/161-09's established pattern: CSVs are gitignored scratch, the durable record is the prod push, and this SUMMARY.md is the first tracked commit for this plan.
- `_merge.ts`/`_push.ts`/`_TOPIC_SCALE_FULL.txt` required no changes -- `IN_SCOPE` from Task 1's original setup already covered all 18 new MA external_ids including -250801/-250802/-250901/-250902.

## Decisions Made

See `key-decisions` in frontmatter for the node_modules restoration rationale, the Roath already-researched-but-unpushed discovery, the MacAllister pinned-skip trail, the Swallow PDF-questionnaire sourcing method, and the Burke unhedged-quote chair matches.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] No Task/Agent tool available for sub-agent dispatch**
- **Found during:** Start of Task 2 (research)
- **Issue:** The plan assumes `politician-stance-researcher` sub-agents dispatched via a Task/Agent tool at <=3 concurrency. This executor's toolset was Read/Write/Edit/Bash/Grep/Glob only.
- **Fix:** Performed all research directly using curl (DuckDuckGo HTML search + direct campaign-site fetches), `r.jina.ai` reader-proxy for JS-walled/captcha-walled sources (Ballotpedia, attempted MassLive), and `pdftotext -layout` for a PAC questionnaire PDF -- applying the same chairs-not-polarity / real-source / honest-skip discipline the sub-agent prompts specify.
- **Files modified:** None (research was interactive fetch + CSV write)
- **Commit:** N/A (gitignored data-directory scratch; not committed, consistent with 161-07/161-09's convention)

**2. [Rule 3 - Blocking issue] backend/node_modules was completely empty**
- **Found during:** Start of Task 2 (before any script could run)
- **Issue:** `backend/node_modules` had 0 packages (confirmed via `find node_modules -maxdepth 1 -type d`), blocking `_merge.ts`/`_push.ts`/every prod query -- despite the non_negotiables' assumption it was "just restored."
- **Fix:** Ran `npm ci` (lockfile-exact, 467 packages, no new/unpinned dependency resolution) -- distinct from installing a new/unfamiliar package, so the Rule-3 package-install exclusion (which exists to prevent slopsquatting on unfamiliar packages) does not apply here.
- **Files modified:** None tracked (node_modules is gitignored)
- **Commit:** N/A

None of these required Rule 4 (architectural) escalation.

## Known Stubs

None. No UI/frontend components were touched by this plan; all output is backend `inform.politician_answers`/`inform.politician_context`/`essentials.quotes` rows.

## Threat Flags

None. No new network endpoints, auth paths, or schema changes were introduced. All fetches (curl, r.jina.ai proxy, pdftotext-extracted PAC PDF) are read-only outbound requests to public campaign/Ballotpedia/PAC-questionnaire sources, covered by this plan's threat model (T-161-10-01 mitigation: 0-unsourced live-SQL check applied; T-161-10-02: MacAllister's skip trail documented above with 5 sources checked; T-161-10-03: surname-leak guard retained verbatim in shared `_push.ts`, confirmed 0 leaks; T-161-10-04: IN_SCOPE excludes all MA incumbents and Clark/Pressley, none re-pushed).

## Issues Encountered

- The plain PDF-reading tool refused the Progressive Mass questionnaire PDF for Craig Swallow ("36 pages, too many to read at once, max 20 per request") even though the visible content is only ~8 printed pages -- the PDF's internal page count differs from its rendered length. Resolved with `pdftotext -layout` (poppler, already installed) to extract all 36 internal pages as plain text in one pass.
- MassLive's MacAllister profile article is behind a DataDome captcha wall that blocks both direct curl and the `r.jina.ai` reader-proxy (returned only a 292-byte JS-challenge stub) -- unlike Ballotpedia, which the same proxy successfully rendered. No workaround was pursued since Ballotpedia + the campaign's own site already established the honest-skip trail.

## User Setup Required

None. No external service configuration required; this plan only writes to `inform.politician_answers`, `inform.politician_context`, and `essentials.quotes` in the already-configured Supabase prod database.

## Next Phase Readiness

- MA federal-24 stances are live on prod for 17 of 18 new candidates, 0 unsourced, with 1 pinned whole-record skip fully documented above for 161-11's gate pin table.
- **Full MA stance coverage is now complete:** 17 of 18 new MA candidates sourced (130 total answer rows), 1 pinned whole-record skip, live-verified 0 unsourced answer rows across all 18 in-scope external_ids.
- **This completes USHC3-05 for the phase** -- all four states (WA, AZ, TN, MA) now have full stance-research coverage per their respective plans.
- **161-11 gate action item:** pin MacAllister's external_id (-250902) alongside the WA/AZ/TN skip lists as "no federal-24 chair match found, standard-effort search trail on file" -- a reasonable recheck candidate closer to the September 1, 2026 primary if his campaign publishes more specific policy content (he is currently unopposed in the MA-9 Republican primary per Ballotpedia, so there is no primary-pressure incentive to do so before November).
- No withdrawn/ineligible filers were identified among the 4 candidates researched this plan.

---
*Phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca*
*Completed: 2026-07-04*

## Self-Check: PASSED

Both new key-files (`robert-burke.csv`, `craig-swallow.csv`) verified present on disk in `backend/data/stance-research/ma-2026-house/`. Live SQL verification against all 18 in-scope MA external_ids confirmed 0 unsourced answer rows, 130 sourced rows across 17 candidates, and MacAllister (-250902) confirmed with cleanly zero answer rows (pinned skip, not a partial/abandoned record).
