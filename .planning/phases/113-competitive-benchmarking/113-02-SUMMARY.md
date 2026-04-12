---
phase: 113-competitive-benchmarking
plan: 02
subsystem: research/benchmark
tags: [benchmark, ballotready, playwright, competitive-analysis, monroe-county]
requires:
  - .planning/research/BALLOT-BASELINE-2026-05-05.md
  - .planning/research/benchmark/METHODOLOGY.md
  - .planning/phases/113-competitive-benchmarking/113-CONTEXT.md
provides:
  - .planning/research/benchmark/ballotready.md
  - .planning/research/benchmark/screenshots/ballotready/
affects:
  - plan 113-07 (matrix synthesis — BallotReady column)
tech-stack:
  added: []
  patterns: [playwright-mcp-fallback-to-system-playwright, page-dump-text-alongside-screenshot]
key-files:
  created:
    - .planning/research/benchmark/ballotready.md
    - .planning/research/benchmark/screenshots/ballotready/ (27 PNGs + 19 .txt page dumps)
  modified: []
decisions:
  - "BallotReady logged as `accessible` not `blocked` — product returned empty state, not a signup/captcha wall. D-02 distinction strictly enforced."
  - "Dimension 8 (geofence/address precision) scored 0 because precinct precision is unobservable when race data is absent for all three test addresses, not because precision is measurably broken."
  - "Dimension 10 (antipartisan framing) scored 3 for ballot-data surface despite editorial nuance: BallotReady's `actions` page features a partner labeled '(partisan - left)' in BallotReady's own copy. Noted in narrative, not reflected in score since no ballot content exists to partisan-label."
metrics:
  duration: ~45min
  completed: 2026-04-12
  tasks: 2
  screenshots_captured: 27
  addresses_probed: 3
  baseline_races_expected_for_primary: 14
  baseline_races_surfaced_by_competitor: 0
  match_rate_pct: 0
requirements: [BENCH-01]
---

# Phase 113 Plan 02: BallotReady Spot-Check Summary

**One-liner:** Live Playwright spot-check of BallotReady for 200 W Kirkwood Ave surfaced zero Monroe County race data across three district-boundary test addresses — measured as product gap, not access gap.

## Access Status

`accessible`. No signup wall, captcha, paywall, rate limit, or region gate encountered at any step for any of the three addresses. The landing-page address form accepted all three addresses, geocoded them via an autocomplete dropdown, and redirected to `https://app.ballotready.org/civic_center/` on first try. The `autonomous: false` safety precaution for this plan was ultimately not needed for access reasons, but the D-02 distinction it enforced (product gap vs. access gap) was critical to apply correctly in the write-up.

## Screenshot Count

**27 PNG screenshots** + 19 matching `.txt` page dumps captured under `.planning/research/benchmark/screenshots/ballotready/`. Coverage spans: landing page, address-entry form, post-submit civic center for all three addresses, office holders view, Federal/State/Local tabs, `app-actions`, `app-run`, `app-check_registration`, and the state/county/city drill-down attempts on `www.ballotready.org`.

Well over the plan's ≥3 threshold.

## Baseline Match Rate

**0 / 14 races surfaced (0%)** for the primary address (200 W Kirkwood Ave, Bloomington IN 47404).

Denominator source: `BALLOT-BASELINE-2026-05-05.md`. A Bloomington-Township / HD-61 / Council-District-1 voter should see 14 distinct races on their May 5, 2026 primary ballot (US Rep IN-9, State Rep HD-61, 2 Circuit Court seats, 6 county-wide offices, County Council D1, Bloomington Township Trustee, Bloomington Township Board). BallotReady returned the string "There is no office holder information available at this level." for every tab (All, Federal, State, Local) and the ballot-viewing tiles ("Find your polling place", "Request a ballot") are labeled "Coming soon!".

## Top 3 Observations

1. **"Coming soon!" 3.5 weeks before a state primary** — For a product branded "Where you go before you vote" and sold to voters as a ballot-lookup service, the ballot features being labeled "Coming soon!" on 2026-04-12 for a May 5, 2026 election is the most editorially significant finding of the entire spot-check. It drives BallotReady's Dimension 1 score to 0 on its own.

2. **Indiana data exists at the state marketing level but not in the personalized view** — The static `/us/indiana` page boldly advertises "More than 2,260 positions are up for election" for the 2026 Indiana Primary and lists correct registration / absentee / early-vote deadlines. So BallotReady's editorial team clearly has Indiana information. It is simply not wired to the address-fed consumer product for Monroe County. This smells like state-level SEO pages populated independently from the address→race pipeline. Plan 07 synthesis should not give BallotReady credit for "Indiana coverage" based on the state marketing page alone — the personalized product is the measurement surface.

3. **Precinct precision (Dimension 8) is strictly unobservable, not strictly broken** — All three test addresses (downtown Bloomington, rural Benton Twp, SE Bloomington) cross known State House district boundaries (HD 61 / HD 46 / HD 60 / HD 62) but render identical empty civic centers. This is a worse outcome than "showed the same race list for all three" (which would be a detectable precision failure scoring 1) because there is no race list to differentiate. Scoring collapses to 0 under the rubric's "absent" definition.

Bonus observation worth capturing: BallotReady's `actions` page features Oath, a political-giving tool, explicitly labeled *"(partisan - left)"* in BallotReady's own copy — an interesting editorial choice for a product that simultaneously describes itself as "a great nonpartisan resource" in the civic-center share-prompt language. Dimension 10 score held at 3 because this is on the actions surface, not the ballot-data surface, but the nuance is logged in the narrative.

## Blockers

**None.** No access gate of any kind. The plan's `autonomous: false` flag was a reasonable precaution that turned out not to bind. More importantly, D-02 (log product gaps and access gaps as distinct categories) was strictly applied: the empty civic center is NOT logged as a blocker, even though a careless reading would classify it as one. A human running the same manual flow would see the same empty state, so there is no human-fallback instruction to write.

## Deviations from Plan

**1. [Rule 3 - Blocker fix] Playwright MCP tools unavailable in session — used system Playwright instead**
- **Found during:** Task 1 setup
- **Issue:** The plan specified `mcp__plugin_playwright_playwright__*` MCP tools, but those tools were not registered in this agent session. Attempting the task as specified would have failed immediately.
- **Fix:** Installed `playwright` into a temp workspace (`/tmp/pw-work`), pointed at the existing Chromium 1208 install under `~/Library/Caches/ms-playwright/chromium-1208/` (newer versions' headless shell was missing), and drove the browser via headless Node scripts (`/tmp/ballotready-scrape.mjs`, `/tmp/ballotready-indiana.mjs`, `/tmp/ballotready-deep.mjs`, `/tmp/ballotready-tabs.mjs`). Captured full-page screenshots and page-text dumps identical in content to what the MCP tools would have produced.
- **Files modified:** None in the repo (tooling lives under `/tmp/`). Evidence output is identical to the plan's spec.
- **Commit:** 524e165

**2. [Rule 2 - Missing critical evidence] Added per-screenshot `.txt` page dumps**
- **Found during:** Task 1 — realized that downstream synthesis in plan 07 would need grep-able text of what was on each screen, not just binary PNGs.
- **Fix:** Wrote a `.txt` file alongside each PNG containing `URL:`, `TITLE:`, first 8–12K of `document.body.innerText`, and up to 200 captured `<a>` link text/href pairs. Gives future agents a text-based audit trail without re-driving Playwright.
- **Files modified:** Added 19 `.txt` files to `screenshots/ballotready/`
- **Commit:** 524e165

**3. [Rule 2 - Missing coverage] Explored additional BallotReady app pages beyond the plan's list**
- **Found during:** Task 1 — after discovering the primary address produced an empty civic center, I explored `app-actions`, `app-run`, `app-check_registration`, and the three office-holders tabs (Federal/State/Local) to confirm the "empty" finding was product-wide and not limited to one specific view.
- **Fix:** Added 10+ screenshots of these additional pages. Confirmed BallotReady's product has substantive content in the civic-action / voter-registration / run-for-office areas but zero content in the ballot-data area for Monroe County. This strengthens the narrative and prevents a plan-07 reviewer from asking "did you check if the data was hidden on a different page?"
- **Commit:** 524e165

## Deferred Issues

None. No out-of-scope discoveries. No pre-existing lint / typecheck concerns (this is a research phase, no code touched).

## Commits

| Task | Description | Hash |
|------|-------------|------|
| 1 | Playwright spot-check + 27 screenshots + text dumps | `524e165` |
| 2 | `ballotready.md` evidence file with all 6 required sections | `19d6315` |

## Self-Check: PASSED

- `.planning/research/benchmark/ballotready.md` exists: **FOUND**
- `.planning/research/benchmark/screenshots/ballotready/` has 27 PNGs (≥3 required): **FOUND**
- All 6 required sections (`Access Status`, `Field Inventory`, `Race / Candidate Count vs Baseline`, `Narrative Notes`, `Precinct Precision`, `Blockers`) grep-present: **FOUND**
- `200 W Kirkwood` appears in ballotready.md: **FOUND**
- Commit `524e165` exists in git log: **FOUND**
- Commit `19d6315` exists in git log: **FOUND**
- `STATE.md` and `ROADMAP.md` untouched by this executor: **CONFIRMED** (orchestrator owns those writes)
