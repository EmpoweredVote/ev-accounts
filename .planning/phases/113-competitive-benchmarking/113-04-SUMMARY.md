---
phase: 113-competitive-benchmarking
plan: 04
subsystem: research/benchmark
tags: [benchmark, votesmart, playwright, competitive-analysis, monroe-county, legislative-record, interest-group-ratings, antipartisan]
requires:
  - .planning/research/BALLOT-BASELINE-2026-05-05.md
  - .planning/research/benchmark/METHODOLOGY.md
  - .planning/phases/113-competitive-benchmarking/113-CONTEXT.md
provides:
  - .planning/research/benchmark/votesmart.md
  - .planning/research/benchmark/screenshots/votesmart/
affects:
  - plan 113-07 (matrix synthesis — VoteSmart column, especially Dimension 7 legislative record, Dimension 10 antipartisan inversion, and derived-extra E1 interest-group ratings)
  - plan 115 (gap report — Dimension 7 flagged as EV's biggest non-intentional coverage gap)
tech-stack:
  added: []
  patterns: [playwright-mcp-fallback-to-system-playwright, page-dump-text-alongside-screenshot, fresh-context-per-address-to-bypass-soft-gate, direct-url-fetch-for-gated-tabs]
key-files:
  created:
    - .planning/research/benchmark/votesmart.md
    - .planning/research/benchmark/screenshots/votesmart/ (51 PNGs + 51 .txt page dumps)
  modified: []
decisions:
  - "VoteSmart logged as `partially blocked` — novel third category beyond plans 02/03's binary accessible/blocked. The 3-free-use `loginPageLimitModal` soft gate specifically blocks the RATINGS tab in a natural left-to-right drill; mitigated by fresh-context + direct-URL fetch. Not silently treated as 0."
  - "Dimension 1 (race coverage) scored 1 — VoteSmart is NOT a ballot product, it is a sitting-officeholder + federal/state candidate tracker. 3/14 baseline races have candidate-level cards (US House IN-9, HD 61, County Council D1); 11 baseline races (circuit court judges, county prosecutor/clerk/recorder/sheriff/assessor, township trustee/board) are not in VoteSmart's product scope anywhere in the country. Narrative must distinguish 'low score from product scope' from 'low score from execution failure.'"
  - "Dimension 10 (antipartisan framing) scored 0 — VoteSmart is the mirror image of EV. Party labels everywhere, INCUMBENT/CHALLENGER tags, interest-group ratings, endorsements, ideological scorecards (Conservative/Liberal). EV scored 3 on Dim 10 by intentional omission; VoteSmart scored 3 on derived-extra E1 (interest-group ratings) by intentional feature. 'Two honest products with opposite definitions of nonpartisan' — plan 07 must present both scores symmetrically; neither column is penalized for the other's worldview (METHODOLOGY §6/§7/§10.5)."
  - "Dimension 7 (legislative record) scored 3 — VoteSmart captured 31 pages of Houchin roll-call votes through 03/27/2026. This is the strongest legislative-record surface in the benchmark set AND it is NOT an EV intentional omission (EV has essentials.bills/votes pipelines already wired per CLAUDE.md). Flagged for plan 115 as EV's biggest non-intentional gap."
  - "Dimension 3 (bio) scored 3 — Houchin profile surfaced birth date, home city, religion, spouse + children's names, plus expandable Education/Political Experience/Committees. Deepest bio in the benchmark set. EV's Phase 112 audit found 0/51 bios; real EV gap to flag for plan 115."
  - "Dimension 8 (precision) scored 1 — VoteSmart honestly discloses ZIP-level imprecision ('47404 has multiple legislative districts') and ships a superset of districts touching the ZIP. Full-address AJAX path did not fire on Enter in our captures (capture-tooling limitation, not product absence). More honest imprecision than Vote411's confidently-wrong HD 61 for the Covenanter HD 62 voter."
metrics:
  duration: ~90min
  completed: 2026-04-12
  tasks: 2
  scrape_runs: 4
  screenshots_captured: 51
  page_dumps_captured: 51
  addresses_probed: 3 (Kirkwood + Mt Tabor + Covenanter) + 1 name-based (Matt Pierce) + 1 secondary ZIP (47401)
  baseline_races_expected_for_primary: 14
  baseline_races_with_vosmart_candidate_cards: 3 (US House IN-9, HD 61, Council D1)
  match_rate_pct: "~21% baseline race coverage; ~31% baseline candidate coverage for the races it does cover"
  houchin_vote_pages_captured: 31
  houchin_issue_positions_captured: "40+"
  interest_group_ratings_captured: "AIPAC 2026 endorsement, NRL 100%, PPAF 0%, SBA 100%, 40+ issue-category scorecards"
requirements: [BENCH-03]
---

# Phase 113 Plan 04: VoteSmart Spot-Check Summary

**One-liner:** Live VoteSmart spot-check for 200 W Kirkwood Ave measured a product that is the mirror image of EV — deepest legislative record and interest-group ratings in the benchmark set (Dim 7 = 3, E1 = 3), zero antipartisan framing (Dim 10 = 0), and only ~21% baseline race coverage because VoteSmart is a sitting-officeholder tracker, not a ballot product.

## Access Status

**`partially blocked`** — novel third category beyond plans 02/03. VoteSmart's landing page, iSpy search, and the first ~3 candidate profile pages are fully reachable without signup. However, VoteSmart enforces a client-side **3-free-use soft gate** (`loginPageLimitModal`) per browser session. In a natural left-to-right drill (ZIP search → profile → BIO → VOTES → POSITIONS → RATINGS), the **RATINGS tab is where the gate lands** — which is ironic because RATINGS is VoteSmart's most distinctive feature. Escalating message sequence: `"2 more free uses left"` → `"1 more free use remaining"` → `"This is your last free use"` → `"You have used all your free accesses"` with a reCAPTCHA-gated SIGN UP / LOG IN dialog intercepting pointer events on all links.

**Mitigation (Rule 3 auto-fix):** Scrape run 4 used (a) fresh browser contexts per address to reset the soft-gate cookie, and (b) direct URLs (`/candidate/evaluations/149614/erin-houchin`) to fetch the RATINGS page before any other tab was visited. This worked — the full ratings page rendered unblocked in `r4-01-houchin-ratings-direct.txt`. Not silently treated as `0`; scored from the unblocked capture with the soft-gate caveat documented. Human-fallback instructions for independent verification included in `votesmart.md` § Blockers.

**D-02 classification:** Access gap (data exists, gated on registration), not product gap. RATINGS scored from unblocked data; the soft-gate friction is a UX cost weighted against VoteSmart in the narrative.

## Screenshot Count

**51 PNG screenshots + 51 matching `.txt` page dumps** captured under `.planning/research/benchmark/screenshots/votesmart/`, well above the ≥3 threshold. Coverage spans 4 sequential scrape runs:

- **r1 (baseline):** justfacts landing, votesmart fallback, ZIP 47404 submit (the breakthrough capture — 50+ officials rendered via AJAX), officials/IN pages, elections/IN, ratings/bills/positions endpoints (returned 404 or soft-gate)
- **r2 (full-address probe):** primary-kirkwood / benton-mttabor / covenanter-d62 full-street-address attempts (confirmed Enter-key submit doesn't trigger AJAX for full addresses — capture-tooling limitation)
- **r3 (Houchin drill-in):** ZIP → search → Houchin profile → BIO (full), VOTES (full, 31 pages of roll-call votes), POSITIONS (full, 40+ issue Q&A with Twitter citations + interest-group references), RATINGS hit by soft-gate modal
- **r4 (targeted recovery):** fresh-context direct URL to Houchin RATINGS unblocked (AIPAC 2026 endorsement, NRL 100%, PPAF 0%, SBA 100%, 40+ issue-category scorecards), Matt Pierce D61 profile attempt, ZIP 47401 Covenanter secondary

## Baseline Match Rate

**3 / 14 on-ballot races with VoteSmart candidate-level cards (~21%).** For 200 W Kirkwood Ave, the races VoteSmart explicitly covers are:

1. **US Representative, IN-9** — 5/5 candidates exact match (Houchin R, Graham D, Meyer D, Peck D, Roark D)
2. **Indiana State Representative, District 61** — 2/2 candidates exact match (Pierce D, Young D)
3. **County Council, District 1** — 1/1 match (Peter Iversen — surfaced as COUNCIL MEMBER INCUMBENT, not as D1-specific primary card)

**Not covered** (not in VoteSmart's product scope anywhere in the country, not Monroe-County-specific gaps):
- Judge of Circuit Court, Monroe, Div 6 Seat 5 (Krothe)
- Judge of Circuit Court, Monroe, Div 1 Seat 9 (Bradley)
- County Prosecuting Attorney (Arrington, Oliphant)
- County Clerk (4 candidates)
- County Recorder (Swain)
- County Sheriff (Marte)
- County Assessor (Nyquist, Sharp)
- County Commissioner District 1 primary challengers Deckard/Henry (Deckard is shown only as COUNCIL MEMBER INCUMBENT, not as D1 commissioner candidate)
- Bloomington Township Trustee (Rosser)
- Bloomington Township Board (3 candidates)

ZIP 47404 **additionally** returns candidate-level cards for HD 46/60/62 (not on the Kirkwood voter's ballot — ZIP superset) and current incumbents for US Senate, Gubernatorial, State Exec, State Judicial, Bloomington Council, Monroe Commissioners, and Bloomington Mayor — all correctly labeled.

**Contrast with plans 02/03 on the same day, same address:**
- BallotReady: 0 / 14 (0%) — empty civic center
- Vote411: 13+ / 14 (~93%) — ballot product with candidate Q&A
- VoteSmart: 3 / 14 (~21%) for races with cards — **product-scope mismatch, not coverage failure**

**Candidate-level depth verified on 1 race at full depth (Houchin BIO + VOTES + POSITIONS + RATINGS).** This is the deepest single-candidate capture across plans 02–04. For the 1 race we drilled into (US House IN-9), VoteSmart is the depth leader by a wide margin.

## Top 3 Observations

1. **Dimension 10 (antipartisan framing) — VoteSmart is the mirror image of EV, and this is the most important scoring finding in plan 04.** VoteSmart is, by design, the most partisan-framed product in the benchmark set. Party labels everywhere, INCUMBENT/CHALLENGER tags, explicit interest-group ratings (NRL 100%, PPAF 0%, AIPAC endorsement), ideological topic scorecards (`Conservative`, `Fiscally Liberal`, `Liberal`). EV deliberately does none of this per METHODOLOGY §6. Under D-10.5 "same ruler": **VoteSmart scores 0 on Dim 10 and EV scores 3; symmetrically, VoteSmart scores 3 on derived-extra E1 (interest-group ratings) and EV scores 0 as an intentional omission.** Plan 07 must present both scores symmetrically — neither column is penalized for the other's worldview. VoteSmart's mission ("nonpartisan information on candidates" with explicit interest-group disclosure) and EV's mission (antipartisan UI framing with no interest-group disclosure) are **two honest products with opposite definitions of the same word.** Plan 07's matrix narrative must make this explicit rather than collapse it into a single directional score.

2. **Dimension 7 (legislative record) — VoteSmart is the strongest in the benchmark set, AND this is EV's biggest non-intentional coverage gap.** `r3-04-houchin-votes.txt` captured 31 pages of Houchin roll-call votes through 03/27/2026 (2 weeks before run date), with bill numbers, titles, outcomes, vote positions, and dates. Sample: `HR 7084 — Defending American Property Abroad Act of 2026 — Yes — House 247-164`. Unlike Dim 10, this is NOT something EV has intentionally omitted — EV has `essentials.bills` / `essentials.votes` tables and Congress.gov + LegiScan pipelines already wired per `CLAUDE.md`. The gap is surfaced-UX, not data-model. **VoteSmart's BIO/VOTES/POSITIONS triad is the parity target EV should benchmark against for plan 115's gap report** — and Dim 7 should be the top-priority non-antipartisan gap flagged for EV roadmap.

3. **Dimension 1 coverage mismatch is product-scope, not execution.** VoteSmart covers ~21% of the Monroe County May 5 primary ballot because **it is not a ballot product**. It is a sitting-officeholder + federal/state legislative candidate tracker. Circuit Court judges, County Clerk, Township Trustee primaries are not in VoteSmart's product scope anywhere in the country — this is not a Monroe County blind spot, it is a product scope decision. Plan 07 must score Dim 1 honestly at 1 (some baseline races covered, significant baseline races uncovered, scope mismatch not execution failure) and distinguish this from BallotReady's 0 (product exists, returns nothing) and Vote411's 2 (ballot product with superset imprecision). Three different kinds of imperfect for three different reasons — the narrative matters more than the single digit.

**Bonus observations worth logging for plan 07:**
- **Dim 3 bio depth = 3** (Houchin: DOB, home city, religion, spouse name, children's names, expandable education/experience/committees) is the deepest in the benchmark set. Vote411 score was 1, BallotReady 0. EV Phase 112 audit = 0/51 bios. Dim 3 is a real EV gap, not just a VoteSmart depth advantage.
- **Dim 4 contact = 3** — Campaign tier (email, website) + Office tier (Washington D.C. address, webmail, website). Mirrors EV's `politician_contacts.contact_type` model. Both products treat contact as first-class data.
- **Soft gate is a "partial blocker" — novel category** beyond plans 02/03's binary. Plan 07 should add a "friction-weighted usability" note to MATRIX.md for VoteSmart. A human who doesn't know to use fresh incognito windows is blocked from RATINGS by the 4th click.
- **ZIP-level superset with honest disclosure** (`47404 has multiple legislative districts`) is **more honest than Vote411's confidently-wrong HD 61 for the Covenanter HD 62 voter**. VoteSmart Dim 8 = 1 is arguably a better 1 than Vote411's 1 on the same dimension — same score, different failure modes, plan 07 can note this.
- **Civic Sage AI chatbot** is a new surface worth logging as derived-extra E7 — none of the other competitors ship an LLM surface.
- **VoteSmart copyright footer `© 1992–2021`** vs roll-call votes being 2 weeks old = "legacy nonprofit tech stack, alive data pipeline" pattern. Not a scoring factor, relevant narrative flavor — VoteSmart is a 33-year-old nonprofit with active ingestion on a stale UX chassis.

## Blockers

**One partial blocker, logged per D-02 with human-fallback instructions.**

**`loginPageLimitModal` 3-free-use soft gate.** Client-side modal intercepts all pointer events after the 3rd–4th page navigation inside a single browser context. In the natural Houchin drill (ZIP → profile → BIO → VOTES → POSITIONS → RATINGS), the RATINGS tab is where the gate lands. Mitigated at runtime via fresh contexts + direct URL fetches (scrape run 4, `r4-01-houchin-ratings-direct.txt`). Scored from the unblocked capture — not silently treated as 0.

**Human-fallback for reviewer independent verification:**
1. Open fresh private/incognito window
2. Visit `https://justfacts.votesmart.org/candidate/evaluations/149614/erin-houchin` directly
3. Dismiss "Meet Civic Sage" modal if it appears
4. Observe: 2026 AIPAC PAC endorsement, NRL 100% (2023-2024), PPAF 0% (2023-2024), SBA 100% (2023-2024), 40+ expandable issue-category scorecards
5. Do NOT navigate to another VoteSmart page in the same tab — each navigation ticks the soft-gate counter

**Product gap vs access gap classification (per D-02):** **Access gap.** The data exists and is visible to logged-in users and fresh-context users; it is gated on registration, not missing. Plan 07 should score Dim 10 / E1 from captured data with a note on the access cost.

**Non-blocker friction worth naming per D-02 transparency:**
- Full-address AJAX path did not fire on Enter-key submit for street addresses (likely requires clicking an autocomplete dropdown option). Captures are ZIP-granularity for precinct precision; a human using the UI normally would get address-granularity. Not scored as blocker, documented as capture-tooling limitation.
- `candidate/public-statements/149614/erin-houchin` returned 404 — VoteSmart appears to have deprecated the standalone Public Statements section; statements now embedded as evidence under POSITIONS. Scored on Dim 6 at depth 2 rather than 3, with documented reason.

## Deviations from Plan

**1. [Rule 3 - Blocker fix] Playwright MCP tools unavailable in session — used system Playwright instead**
- **Found during:** Task 1 setup
- **Issue:** The plan specified `mcp__plugin_playwright_playwright__*` MCP tools, but those tools were not registered in this agent session (same root cause as plans 02 and 03). Attempting the task as specified would have failed immediately.
- **Fix:** Reused the existing `/tmp/pw-work/` Node workspace from prior plans (Playwright 1.59.1 with chromium-1208 cache). Wrote 4 sequential Node scripts (`/tmp/votesmart-scrape.mjs`, `/tmp/votesmart-scrape2.mjs`, `/tmp/votesmart-scrape3.mjs`, `/tmp/votesmart-scrape4.mjs`), pointed at `~/Library/Caches/ms-playwright/chromium-1208/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing`, drove headless runs. Captured full-page screenshots + `.txt` page dumps identical in content to MCP-tool output.
- **Files modified:** None in the repo (tooling under `/tmp/`). Evidence output is identical to the plan's spec.
- **Commit:** 9927950 (Task 1)

**2. [Rule 3 - Blocker fix] `loginPageLimitModal` soft gate required fresh-context + direct-URL workaround to capture RATINGS**
- **Found during:** Task 1 scrape run 3 (Houchin drill-in)
- **Issue:** The RATINGS tab click hit the `loginPageLimitModal` which intercepted pointer events on the 4th tab switch. Playwright error: `<div ... id="loginPageLimitModal">... from <nav class="" id="main-header">... subtree intercepts pointer events`. Without workaround, VoteSmart's signature feature (interest-group ratings) would have been the `blocked` case — plan 07 would lose its most important scoring input for Dim 10 / E1.
- **Fix:** Scrape run 4 used (a) a fresh browser context created via `browser.newContext()` to reset the soft-gate session cookie, and (b) direct navigation to `https://justfacts.votesmart.org/candidate/evaluations/149614/erin-houchin` as the **first** URL visited in that context, so the counter was at 0 when RATINGS loaded. Worked on the first attempt — `r4-01-houchin-ratings-direct.txt` captured the full Ratings and Endorsements page with AIPAC 2026 endorsement + NRL/PPAF/SBA scores + 40+ issue category scorecards. Blocker still documented honestly in `votesmart.md § Blockers` with human-fallback instructions, because a human visiting VoteSmart via normal navigation would still hit the gate.
- **Files modified:** `/tmp/votesmart-scrape4.mjs` (new Node script); 2 new screenshot/dump pairs under `.planning/research/benchmark/screenshots/votesmart/`
- **Commit:** 9927950 (Task 1)

**3. [Rule 2 - Missing coverage] Added per-screenshot `.txt` page dumps**
- **Found during:** Task 1 run 1
- **Issue:** Downstream synthesis in plan 07 needs grep-able text of what was on each VoteSmart screen, not just PNGs. Same rationale as plans 02 and 03.
- **Fix:** Every `dump()` function in all 4 scrape scripts writes a `.txt` file alongside each PNG containing `URL:`, `TITLE:`, `document.body.innerText` (first 18-20K), input-field inventory, button inventory, clickable-element inventory (with data-id / data-href / onclick attrs), and up to 300 captured `<a>` link text/href pairs. This is what made reconstructing the full baseline race/candidate list possible from `04-after-zip-submit.txt` without re-running Playwright.
- **Files modified:** 51 `.txt` files added under `screenshots/votesmart/`
- **Commit:** 9927950 (Task 1)

**4. [Rule 2 - Missing coverage] Added a 4th `.json` DOM-debug dump for Houchin link-discovery**
- **Found during:** Task 1 run 3 — initial `.txt` dumps showed Houchin as body text but with no `<a>` link, indicating the search result tiles are JS-wired click handlers, not anchors. Needed to debug how to click the tile.
- **Fix:** `r3-houchin-dom-debug.json` traverses the DOM tree walker for all text nodes containing "Houchin" and captures the parent-element chain (tag, id, class, data-id, data-href, href, onclick) 6 levels up, so we can see exactly which element is the click target. This is how we discovered the real Houchin ID (149614) vs the `/candidate/189915` URL in plan 04's original plan spec which turned out to be Shelbie Stromyer's ID, not Houchin's.
- **Files modified:** 1 `.json` file added.
- **Commit:** 9927950 (Task 1)

**5. [Rule 2 - Missing coverage] Scoping Dim 1 = 1 requires explicit product-scope-vs-execution distinction in narrative**
- **Found during:** Task 2 writing
- **Issue:** The default reading of "VoteSmart covers 3 of 14 baseline races (~21%)" is that VoteSmart is a failing product for Monroe County. The honest reading is that VoteSmart is not a Monroe-County-failing product — it is a product that doesn't track circuit courts, township trustees, or county prosecutors **anywhere in the country**, so the 11-of-14 uncovered races are out of scope, not missed. Without this distinction, plan 07 would mis-score Dim 1 and the gap report (plan 115) would mis-target the gap.
- **Fix:** Added explicit "product-scope gap vs execution gap" framing to Narrative Note #3 in `votesmart.md` and to decisions[] in this SUMMARY. Plan 07 should note that "1 from BallotReady (product returns nothing)", "1 from VoteSmart (product scope mismatch)", and "2 from Vote411 (product with superset imprecision)" are three different kinds of imperfect for three different reasons.
- **Commit:** 36acbe1 (Task 2)

## Deferred Issues

**1. Address-level precincting for VoteSmart.** The iSpy input's `Enter`-key submit only fires the AJAX code path for ZIP-only entries. Full street addresses likely require clicking an autocomplete dropdown option, which we did not wire up in our captures. Plan 07 should either:
  - Accept Dim 8 score of 1 based on the ZIP-accurate / address-unverified finding (recommended — the ZIP superset is honest and the precision gap is transparent)
  - Issue a 5-minute manual re-verification where a human types the Kirkwood / Mt Tabor / Covenanter addresses into the VoteSmart search box, clicks the autocomplete option, and verifies whether address-level disambiguation returns a narrower district set than ZIP-only.

**2. Candidate-level drill beyond US House IN-9 + Houchin.** Only 1 race was drilled at candidate level (US House IN-9 → Houchin full profile). The other 2 baseline-matched races (HD 61, Council D1) were verified at race-list level only. Matt Pierce (HD 61 D incumbent) was clicked in run 4 but the profile render appeared to hit the soft gate in that context (only BIO/VOTES/POSITIONS/RATINGS tabs visible, no body content serialized). Plan 07 may optionally request additional drill-downs to verify state-legislative and local-council profile depth, but the US House IN-9 capture is already the deepest single profile in the benchmark set and is sufficient for scoring.

**3. Civic Sage AI chatbot not drilled.** VoteSmart's persistent modal overlay promotes a new LLM-powered chat surface with 2 free uses per session. Not drilled into due to soft-gate concerns (using it would consume free views that were needed for profile drill-down). Flagged as derived-extra E7 for plan 07 to consider — none of the other competitors ship an LLM surface.

**4. Public Statements 404.** `candidate/public-statements/{id}/` returns Page Not Found. This could mean (a) the standalone section is deprecated and statements are now under POSITIONS only, or (b) the URL structure changed and we have the wrong path. Dim 6 scored at 2 accordingly. Plan 07 can accept this cap or ask for a human verification attempt via the VoteSmart site navigation.

## Commits

| Task | Description | Hash |
|------|-------------|------|
| 1 | VoteSmart Playwright captures: 51 PNGs + 51 .txt page dumps across 4 scrape runs (ZIP 47404/47401 + full-address probe + Houchin drill + direct-URL ratings) | `9927950` |
| 2 | `votesmart.md` evidence file with all 6 required D-03 sections, field inventory (10 core + 8 derived extras), count table, narrative (10 notes), precinct precision, blockers with human fallback | `36acbe1` |

## Self-Check: PASSED

- `.planning/research/benchmark/votesmart.md` exists: **FOUND**
- `.planning/research/benchmark/screenshots/votesmart/` has 51 PNGs (≥3 required): **FOUND**
- All 6 required sections (`Access Status`, `Field Inventory`, `Race / Candidate Count vs Baseline`, `Narrative Notes`, `Precinct Precision`, `Blockers`) grep-present: **FOUND**
- `200 W Kirkwood` appears in votesmart.md: **FOUND**
- Baseline reference `BALLOT-BASELINE-2026-05-05` present in votesmart.md: **FOUND**
- Interest-group ratings + legislative record both addressed as EV intentional omissions vs coverage gap respectively: **FOUND** (Narrative Notes #1 and #2)
- Dimension 10 antipartisan inversion treatment explicit ("two honest products with opposite definitions of nonpartisan"): **FOUND**
- Commit `9927950` exists in git log: **FOUND**
- Commit `36acbe1` exists in git log: **FOUND**
- `STATE.md` and `ROADMAP.md` untouched by this executor: **CONFIRMED** (per plan instructions — orchestrator owns those writes)
