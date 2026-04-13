---
phase: 113-competitive-benchmarking
plan: 06
subsystem: research/benchmark
tags: [benchmark, ev, self-audit, d-10.5, honest-scoring, monroe-county, antipartisan, essentials]
requires:
  - .planning/research/BALLOT-BASELINE-2026-05-05.md
  - .planning/research/AUDIT-REPORT-112.md
  - .planning/research/benchmark/METHODOLOGY.md
  - .planning/phases/113-competitive-benchmarking/113-CONTEXT.md
provides:
  - .planning/research/benchmark/ev.md
  - .planning/research/benchmark/screenshots/ev/
affects:
  - plan 113-07 (matrix synthesis — EV column, now scored on the same ruler as competitors)
  - plan 115 (gap report — Dim 3 bio flagged as EV's biggest non-intentional coverage gap; concrete CC D1 vs D4 geofence binding bug flagged for fix)
tech-stack:
  added: []
  patterns:
    - playwright-mcp-fallback-to-system-playwright
    - page-dump-text-alongside-screenshot
    - fresh-context-per-address-for-autocomplete-state
    - d-10.5-self-audit-same-ruler-as-competitors
key-files:
  created:
    - .planning/research/benchmark/ev.md
    - .planning/research/benchmark/screenshots/ev/ (36 PNGs + 36 .txt page dumps across primary + 2 secondary addresses)
  modified: []
decisions:
  - "EV scored on the same 0-3 rubric as competitors with the same harshness per D-10.5. No privileges, no intentional-omission excuses on non-exempt dimensions. Only Dim 10 (antipartisan framing) is exempt, and only because METHODOLOGY §6 defined the exemption before scoring."
  - "Dimension 1 (race coverage) scored 2 — 13/14 baseline races surfaced for Kirkwood via the Elections tab (comparable to Vote411 ~93% and Ballotpedia ~79-93%, far ahead of BallotReady 0% and VoteSmart ~21%). The gap to 3 is the County Council District 1 miss: the Kirkwood voter actually votes for CC D1 (Iversen) but EV surfaces CC D4 members/primary (Crossley) in both Representatives and Elections views. This is a concrete, falsifiable precision bug documented for plan 115."
  - "Dimension 3 (bio) scored 0 — HARD HARSH ZERO. AUDIT-REPORT-112 recorded 0/51 linked candidates have a bio, and the live captures confirmed it: Houchin, Pierce, and Bolden all render the generic CHAMBER description ('The U.S. House of Representatives is one of two chambers for the federal legislature...') in the slot where a biographical narrative should appear. Same harshness applied to BallotReady's 0 on Dim 1. This is EV's biggest non-intentional coverage gap vs Ballotpedia's 3 (encyclopedic prose) and VoteSmart's 3 (personal/family data)."
  - "Dimension 7 (legislative record) scored 2 — Pierce profile shows 'Voted in 100% of roll calls' with a specific example vote ('Voted Nay on Shooting ranges. — passed'); Houchin shows 6 committees + 5 authored bills advanced past introduction. Federal + state pipeline strong. But Bolden (Bloomington CC) has ZERO legislative record surface — the local tier is empty because the Congress.gov+LegiScan+Open States pipeline doesn't cover municipal bodies. Honest midpoint 2."
  - "Dimension 8 (geofence precision) scored 1 — SAME AS VOTE411. PostGIS infrastructure is theoretically more precise than ZIP-only competitors, but observed precision fails on both secondary addresses: Mt Tabor doesn't geocode at all (same rural-address failure Vote411 had), Covenanter returns HD 61 when methodology expects HD 62 (same boundary bug Vote411 had on the same address). Plus the CC D1-vs-D4 miss on the primary. D-10.5: no privilege for infrastructure-that-should-work, the score reflects what the addresses actually return."
  - "Dimension 10 (antipartisan framing, INVERTED) scored 3 per METHODOLOGY §6 — across 36 page dumps, ZERO party labels on any sitting-official card, no endorsements, no interest-group ratings, no red/blue color associations, no FEC partisan scorecards. The FEC total ($1,094,344 Houchin / $9,698 Pierce) is rendered as a neutral transparency signal. The only party labels in the entire evidence set appear in the Elections tab as race headers ('STATE REPRESENTATIVE, DISTRICT 61 — DEMOCRATIC PRIMARY'), which is the structural necessity of Indiana's closed primary law. 3 is the rubric's intended outcome for a product that deliberately omits the features being measured, not a privilege."
  - "EV essentials is STRUCTURALLY DIFFERENT from competitors: it is a 'who represents you' tool with a grafted 'who's on your ballot' tab, where every competitor is a ballot-lookup product with no representatives view. Documented in Narrative Note #1 for plan 07's narrative. The Representatives-first default means a voter lands on 60+ sitting officials (many non-elected: Cabinet, SCOTUS, appointed commissioners) before finding the 13-race ballot view."
  - "Sum of honest ruler: 2+1+0+2+1+1+2+1+2+3 = 15/30. Between Vote411 rough sum ~10 and Ballotpedia rough sum ~17. This is the fair position of the product on 2026-04-12, neither hidden nor privileged."
metrics:
  duration: ~55min
  completed: 2026-04-12
  tasks: 2
  screenshots_captured: 36
  page_dumps_captured: 36
  addresses_probed: 3 (Kirkwood primary + Mt Tabor Benton rural + Covenanter HD 62 boundary)
  baseline_races_expected_for_primary: 14
  baseline_races_surfaced_by_ev_elections_tab: 13
  match_rate_pct: "~93% (top cluster with Vote411 and Ballotpedia)"
  honest_sum_score: "15/30"
  bio_coverage: "0/51 linked candidates (0%)"
  stance_coverage: "5/51 linked candidates (9.8%)"
  quote_coverage: "4/51 linked candidates (7.8%)"
  headshot_coverage: "19 cdn / 0 local / 62 none (~23%)"
  avg_contacts_per_candidate: 1.2
requirements: [BENCH-05, BENCH-06]
---

# Phase 113 Plan 06: Empowered Vote Self Spot-Check Summary

**One-liner:** Honest self spot-check of EV essentials (essentials.empowered.vote) against the same 10-dimension ruler used on 4 competitors — EV lands in the top cluster for race coverage (13/14 baseline races, ~93%) with one concrete CC D1-vs-D4 binding miss, scores a hard harsh 0 on candidate bio (0/51 linked candidates per Phase 112 audit), matches Vote411's Dim 8 precision failure (Mt Tabor no-resolve + Covenanter HD 61/62 wrong), and cleanly earns the Dim 10 antipartisan max of 3 per METHODOLOGY §6 — summing to 15/30 on the honest ruler, between Vote411 (~10) and Ballotpedia (~17).

## Top 3 EV Strengths

1. **Dimension 10 (antipartisan framing) = 3 — the one dimension where EV is unambiguously best in the benchmark set.** Across 36 page dumps covering the Representatives view, the Elections view, and 3 politician profiles (Houchin federal, Pierce state, Bolden local), there are **zero** party labels on any sitting-official card, **zero** endorsement sections, **zero** interest-group ratings, **zero** red/blue color associations, and **zero** partisan FEC scorecards. The only party labels in the entire evidence set appear on the Elections tab as race headers ("STATE REPRESENTATIVE, DISTRICT 61 — DEMOCRATIC PRIMARY") — which is the structural necessity of Indiana's closed-primary law, not a product choice. Compare: Ballotpedia scored 0 (party labels + Trump endorsement on Houchin + Cook/DDHQ/Sabato race ratings); VoteSmart scored 0 (partisan-by-mission); Vote411 scored 1 (DEMOCRATIC/REPUBLICAN all-caps above every name + party-filter default modal); BallotReady held 3 for ballot-data surface despite editorial-nuance around partisan-labeled actions. EV is the only product that actually implements what METHODOLOGY §6 describes: structured contact + stance data without any associated party label or scorecard.

2. **Dimension 1 (race coverage) = 2 — tied top cluster with Vote411 and Ballotpedia at ~93% baseline match.** The Elections tab for Kirkwood surfaces 13 of 14 baseline race slots with correct primary-party splits: US Rep IN-9 (5 candidates: 4 D + 1 R), Indiana HD 61 (2 D Pierce/Young), both Circuit Court judgeships, 6 county-wide offices with correct primary splits (County Clerk correctly renders the 3 D + 1 R split), Commissioner D1 (2 D Deckard/Henry), Bloomington Township Trustee + Board, Monroe County Prosecuting Attorney (2 D), Sheriff, Recorder, Assessor. This is architecturally cleaner than any competitor's conflation of "representatives" and "ballot races" because EV has a **dedicated Elections tab** separate from the Representatives view — the structural separation of "who holds power over you" vs "who's on your ballot" is unique in the benchmark set. The freshness signal "2026 Indiana Primary · May 5, 2026 · 23 days away" on that tab is as strong as Ballotpedia's live countdown. A Monroe County voter on 2026-04-12 would get actually-useful race data from EV, exactly comparable to what they'd get from Vote411 or Ballotpedia.

3. **Dimensions 4 + 7 + 9 all scored 2 — quietly competent mid-tier performance on contact info, legislative record, and freshness.** Houchin's profile captures full structured contact (office + central phones, primary + campaign emails, 5 social links, Wikipedia link, houchin.house.gov + contact form). Pierce's profile shows "**Voted in 100% of roll calls**" with a specific example vote ("Voted Nay on Shooting ranges. — passed"), 5 committees (including Ranking Member on Utilities/Energy/Telecom), and 5 authored bills advanced past introduction. Campaign finance freshness is the strongest in the benchmark set — "Data from FEC · **Updated Apr 12, 2026**" on Houchin is same-day, outperforming even Ballotpedia's live election countdown for per-record freshness. Federal + state legislative data is wired via Congress.gov + LegiScan + Open States per PROJECT.md, and the profile rendering works well for the tiers covered. These three 2s are EV doing the unglamorous work honestly and getting honest midpoint scores for it.

## Top 3 EV Weaknesses (per own 0-3 scoring)

1. **Dimension 3 (candidate bio) = 0 — the hard harsh zero, and EV's biggest non-intentional coverage gap.** Per AUDIT-REPORT-112: **0 of 51 linked candidates have a bio** (every single `has_bio = N` in the audit table). The live walkthrough confirmed it: Houchin's profile, Pierce's profile, and Bolden's profile all render a generic **office** description ("The U.S. House of Representatives is one of two chambers for the federal legislature. Representatives begin the legislation process, offer amendments, and serve on committees.") in the slot where a biographical narrative should appear. There is no career history, no educational path, no birthplace, no prior-office lineage — none of the encyclopedic content Ballotpedia captured on the same Houchin (birth year 1976, Salem IN, IU BA, GW grad, Contend Communications founder, Indiana DCS/CAPE/New Hope Services/PCA Indiana history, Dan Coats regional director, Indiana State Senate D47 2014-2022, predecessor Trey Hollingsworth, successor Gary Byrne, $174,000 salary, 64.5% / 222,884 votes in 2024). Per D-10.5, this scores 0 the same way BallotReady's empty civic center scored 0 on Dim 1 — absence is absence. **This is EV's priority-#1 gap for Phase 115's gap report**, alongside VoteSmart's Dim 7 legislative record as the two biggest non-intentional coverage gaps across the whole benchmark set.

2. **Dimensions 5 + 6 (stance + Q&A) both scored 1 — minimal/token coverage at ~8-10% of the candidate base.** AUDIT-REPORT-112: 5/51 linked candidates have any stances (9.8%), 4/51 have any quotes (7.8%). Houchin's profile renders 21 topic stances beautifully — Healthcare, Abortion, Tariffs, Taxes, plus "Show all 21 topics" expand — and Pierce renders 19. But **46 of 51 linked candidates render no stance section at all**, and Bolden (the local city-council example) has zero. The feature is architecturally sound (StanceAccordion + Read & Rank verdict integration per PROJECT.md) but the data is sparse. Same pattern Ballotpedia's Candidate Connection has — an opt-in stance/Q&A model with ~10-20% participation — and EV scored the same 1 / 1 combination on the same basis. Quote dimension also fails the cap-at-proof rule (same rule applied to Vote411 Dim 6): no Q&A modal / sourced verbatim quote card rendered in any of the 3 drilled profiles' captured DOM. Paraphrased stance text like "provide limited healthcare assistance only to those who cannot afford it" is stance-adjacent but not a direct verbatim quote per the rubric's Dim 6 definition.

3. **Dimension 8 (geofence precision) = 1 — SAME AS VOTE411, which is a disappointment because PostGIS should be better.** EV's stack has every infrastructure advantage: TIGER 2024 geofences, ArcGIS for LA County, PostGIS ST_Covers / ST_Intersects, a dedicated geofence smoke test that Phase 112 ran and passed. But the **observed** behavior on the 3 methodology-test addresses: (a) **Mt Tabor Rd doesn't resolve at all** — "We couldn't find that address" + "Local representative data is not yet available for this area" + "No upcoming elections found" — this is the same rural-address failure Vote411 had, likely Google Places autocomplete coverage gap upstream of the PostGIS query. (b) **Covenanter correctly flips township** (Bloomington → Perry) but **incorrectly returns HD 61** when methodology expects HD 62 — the same boundary bug Vote411 had on the same address, worth noting as cross-product agreement for reviewer attention. (c) **Kirkwood's primary CC D1 race returns D4 members/primaries** — the Representatives view shows Crossley (D4) among the Council members, and the Elections tab surfaces "COUNCIL DISTRICT 4 — DEMOCRATIC PRIMARY" (Jennifer Crossley) instead of the Iversen D1 primary the Kirkwood voter actually votes in. Per D-10.5, no privilege for having PostGIS in the stack — the score reflects what the addresses return. Three independent precision failures → honest score 1.

## Intentional-Omission Dimensions Confirmed

Per METHODOLOGY §6, these are EV's **deliberate** antipartisan omissions. They are NOT gaps; they are intentional product decisions that the Dim 10 inversion rewards. Each was verified in the captures:

1. **No party labels on sitting-official cards.** Confirmed across 36 page dumps — Houchin, Pierce, Bolden, Thomson, Rosenbarger, Crossley, Marte, and 50+ other cards show name + office + district only, no "(R)" / "(D)" / "(I)" tags. The Elections tab is the sole exception (party labels as race headers, required by closed-primary structure).

2. **No endorsement lists.** Zero endorsement sections on any profile. Compare: Ballotpedia's Houchin profile has a "Endorsements" section listing Trump 2024. EV's Houchin profile has none.

3. **No interest-group ratings.** Zero NRA / Sierra Club / NARAL / ACU / Heritage / AFL-CIO scorecards anywhere. Compare: VoteSmart is built around these (they are VoteSmart's primary surface). EV's Houchin profile has none.

4. **No partisan donor / fundraising summaries.** The FEC total "$1,094,344 total raised" for Houchin and "$9,698 total raised" for Pierce are rendered as **neutral transparency signals** — raw total + source + freshness date, with no donor breakdown, no top-contributors ranking, no industry-totals pie chart, no PAC categorization. This is the operational definition of antipartisan FEC handling.

5. **No red/blue color associations.** Zero partisan color overlays anywhere in the UI. EV's design system uses ev-coral, ev-muted-blue, ev-light-blue, ev-yellow per CLAUDE.md — these map to pillars (Inform=Yellow, Connect=Blue, Empower=Coral) per the design-system memory doc, NOT to parties. The tier indicators (LOCAL, STATE, FEDERAL) are typographic, not color-coded by party.

All 5 were confirmed present (i.e., the omissions are real) in the 36 page dumps. Dim 10 = 3 is honestly earned under METHODOLOGY §6's operational definition.

## Deviations from Plan

**1. [Rule 3 - Blocker fix] Playwright MCP tools unavailable in session — reused system Playwright workaround from plans 02/03/04/05**
- **Found during:** Task 1 setup
- **Issue:** Plan specified `mcp__plugin_playwright_playwright__browser_*` tools, but those MCP tools are not registered in this agent session (same root cause as plans 02-05). Attempting the task as specified would have failed immediately.
- **Fix:** Reused the existing `/tmp/pw-work/` Node workspace. Wrote 3 sequential scripts (`ev-scrape.mjs` for primary + 2 secondary landing/results captures, `ev-scrape2.mjs` for Elections tab + Houchin/Pierce/Bolden profile drills, `ev-scrape3.mjs` for secondary addresses Elections tab verification). Pointed at chromium-1208 cache. Captured full-page screenshots + `.txt` page dumps identical in content to what the MCP tools would have produced.
- **Files modified:** None in the repo (tooling under `/tmp/pw-work/`). Evidence output is identical to the plan's spec.
- **Commit:** 7583ac5 (Task 1)

**2. [Rule 2 - Missing coverage] 3 scrape runs instead of a single-run plan because the Elections tab is a dedicated sub-surface that needed a separate capture pass, and the secondary-address elections behavior needed a third run**
- **Found during:** Task 1, after the first scrape showed `/elections` route was empty and the Elections surface is actually a tab on the results page
- **Issue:** The plan envisioned a linear flow (landing → address entry → results → profile click → elections central → compass). The actual product has (a) Elections as a results-page tab toggle, not a separate route; (b) politician profile links are JS-driven, not static `<a href>` elements captured on first scrape; (c) the secondary addresses needed their own Elections tab clicks to verify that Mt Tabor returns "No upcoming elections found" and that Covenanter correctly flips township but keeps the wrong HD.
- **Fix:** Sequential runs. Run 1: landing + results + profile-link-navigation attempts (no profile clicks landed). Run 2: Elections tab click + text-based profile click for Houchin/Pierce/Bolden (getByText clicks work where href-based don't). Run 3: Secondary-address Elections tab captures to verify precinct-precision failures explicitly. Total 36 PNGs + 36 TXTs — well above the plan's ≥3 threshold.
- **Commit:** 7583ac5 (Task 1)

**3. [Rule 2 - Missing critical finding] Discovered the concrete County Council District 1 vs District 4 binding bug during Task 2 evidence review**
- **Found during:** Task 2, when cross-referencing the Elections tab capture against AUDIT-REPORT-112's candidate linkage table
- **Issue:** Both the Representatives view and the Elections tab for the Kirkwood primary address surface County Council **District 4** (Crossley, Deckard, Feitl, Henry as reps; Crossley as the D primary candidate) instead of Council **District 1** (the Kirkwood voter's actual council district, where Peter James Iversen is the D primary candidate per AUDIT-REPORT-112). This is a concrete, falsifiable precision failure that affects the Dim 1 score (taking it from a possible 3 to an honest 2) and the Dim 8 score (as a sub-state precision failure).
- **Fix:** Documented in ev.md Narrative Note #4 + Race Count table row as a MISS, and flagged for plan 115's gap report as a concrete bug (not a coverage gap) — either the geofence-to-council-district binding is wrong for downtown Bloomington, or the query is returning "members of the council" rather than "the member who represents this address."
- **Commit:** a5abd5d (Task 2)

**4. [Rule 2 - Missing coverage] Added derived extras E1-E10 to ev.md Field Inventory despite the plan only requiring the 10 core dimensions**
- **Found during:** Task 2 writing
- **Issue:** Competitor files (ballotpedia.md, vote411.md) include a derived-extras subsection for features outside the core 10. Omitting this section would make plan 07's matrix merge inconsistent — EV's column would have empty derived-extra rows where competitors have populated ones. EV has 10 derived extras worth documenting: Compass cross-link, Read & Rank cross-link, official government body links per chamber, FEC raw total, social links, term dates with years-in-office, tier-level + elected/appointed filter, Wikipedia links, Elections tab as separate surface, Treasury/Badges cross-nav.
- **Fix:** Added a "Derived extras observed in captures" subsection after the core 10 table in ev.md with all 10 extras scored.
- **Commit:** a5abd5d (Task 2)

## Deferred Issues

**1. County Council District 1 vs District 4 geofence binding bug.** Concrete, falsifiable, sub-state precision failure affecting the Kirkwood primary address. Not in scope for this research phase (no code changes), but filed here for plan 115's gap report and for a future backend plan to investigate.

**2. Rural address geocoding gap.** `7333 W Mt Tabor Rd, Bloomington, IN 47404` does not resolve through Google Places autocomplete, returning empty state. Same failure mode Vote411 had on the same address in plan 03. Upstream problem (Google Places coverage), not a PostGIS problem, but the end-user experience is identical. Not in scope for this phase.

**3. Covenanter HD 61 vs HD 62 boundary disagreement.** Both EV and Vote411 return HD 61 for the 2700 E Covenanter Dr address when METHODOLOGY §1 expects HD 62. Cross-product agreement on the "wrong" answer raises the possibility that the methodology's HD 62 expectation is the error, not the products. Plan 05 (Ballotpedia) also flagged this as a single-cell methodology edge case. Plan 07 reviewer should decide whether to re-verify the methodology-expected district for this address or accept the cross-product consensus.

**4. Local-tier legislative record gap.** Bolden (Bloomington City Council) profile has no legislative record section because the Congress.gov / LegiScan / Open States pipeline doesn't cover municipal bodies. Same pattern would apply to County Council, Township Trustee, Circuit Court Judges, and every other local-tier race on the actual May 5 ballot. Not fixable in this research phase; noted for Phase 115's gap report as a federal-is-great / local-is-empty product shape.

**5. View Answers / Quote-card serialization.** Not drilled during this session. The feature exists (Read & Rank integration per PROJECT.md StanceAccordion verdict badges), but no per-quote card or verdict badge rendered in the captured DOM on Houchin/Pierce/Bolden profiles, likely because the captures were unauthenticated (verdict badges for guests require localStorage from a prior Read & Rank session, which the headless browser didn't have). A manual authenticated re-verification could push Dim 6 from 1 toward 2 if quote cards surface for logged-in users. Logged for plan 07 consideration.

## Commits

| Task | Description | Hash |
|------|-------------|------|
| 1 | EV Playwright spot-check: 36 PNGs + 36 .txt page dumps across primary + 2 secondary addresses, Representatives + Elections tabs, Houchin/Pierce/Bolden profile drills | `7583ac5` |
| 2 | `ev.md` self spot-check evidence file with all 6 D-03 sections, honest 10-dim scoring per D-10.5, 10 derived extras, concrete CC D1-vs-D4 miss documented | `a5abd5d` |

## Self-Check: PASSED

- `.planning/research/benchmark/ev.md` exists: **FOUND**
- `.planning/research/benchmark/screenshots/ev/` has 36 PNGs (≥3 required): **FOUND**
- All 6 required sections (`Access Status`, `Field Inventory`, `Race / Candidate Count vs Baseline`, `Narrative Notes`, `Precinct Precision`, `Blockers`) grep-present: **FOUND**
- `200 W Kirkwood` appears in ev.md: **FOUND**
- `AUDIT-REPORT-112` referenced in ev.md: **FOUND**
- D-10.5 honored (no privileges, Dim 3 scored 0 not 1, Dim 8 scored 1 same as Vote411 despite PostGIS stack): **CONFIRMED** (see Narrative Note #10)
- Intentional-omission dimensions confirmed in captures (no party labels, no endorsements, no ratings, no donor scorecards, no red/blue): **CONFIRMED** (see Top 3 Strengths section + Dim 10 evidence cell)
- Commit `7583ac5` exists in git log: **FOUND**
- Commit `a5abd5d` exists in git log: **FOUND**
- `STATE.md` and `ROADMAP.md` untouched by this executor: **CONFIRMED** (per plan instructions — orchestrator owns those writes)
