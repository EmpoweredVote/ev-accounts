# Phase 114 — Gap Register

**Phase:** 114-ux-walkthrough
**Generated:** 2026-04-13
**Schema:** per `METHODOLOGY.md` §7 (id, app, screen, description, severity, type, evidence, baseline_ref)
**Note:** IDs are `G-114-NNN` zero-padded and MUST be monotonic across the whole phase (not per-app). Antipartisan omissions (party labels, endorsements, interest-group ratings) are intentional per METHODOLOGY.md §8 and MUST NOT appear here.

## Summary Counts
_Populated by Plan 114-07 aggregation. Left empty here._

## Gaps

<!-- Walkthrough plans (114-02 .. 114-06) append their gap entries below. Each entry follows the template: -->
<!--
### G-114-NNN — <one-line description>
- **app:** essentials | compass | read-rank | treasury | cross-app
- **screen:** <label> — <prod URL>
- **severity:** blocker | confusing | minor
- **type:** data | feature | content | ux-friction
- **evidence:** screenshots/<app>/<file>.png OR "<verbatim excerpt>"
- **baseline_ref:** <row in BALLOT-BASELINE-2026-05-05.md — REQUIRED if type=data, else "n/a">
- **notes:** <optional severity-call rationale>
-->

<!-- ========================================================================= -->
<!-- Plan 114-02: Essentials (UX-01) — 200 W Kirkwood Ave, Bloomington, IN      -->
<!-- ========================================================================= -->

### G-114-001 — Address field has no autocomplete dropdown during typing
- **app:** essentials
- **screen:** Landing — https://essentials.empowered.vote/
- **severity:** confusing
- **type:** ux-friction
- **evidence:** screenshots/essentials/02-address-typed.png
- **baseline_ref:** n/a
- **notes:** Voter types `200 W Kirkwood Ave, Bloomington, IN 47404` and gets no live confirmation the address is recognized before clicking Search. No Places autocomplete firing. Not a blocker (backend geocoder accepts the string), but the voter has no confidence check that they typed something the system understands.

### G-114-002 — Address rendered in ALL CAPS in results header regardless of input case
- **app:** essentials
- **screen:** Results — https://essentials.empowered.vote/results?q=200+W+Kirkwood+Ave%2C+Bloomington%2C+IN+47404
- **severity:** minor
- **type:** content
- **evidence:** screenshots/essentials/03-results-all.png — "Showing representatives for 200 W KIRKWOOD AVE, BLOOMINGTON, IN, 47404"
- **baseline_ref:** n/a
- **notes:** Voter entered mixed case; app echoes back uppercase. Jarring polish issue, no data or flow impact.

### G-114-003 — Default Representatives tab hides primary challengers
- **app:** essentials
- **screen:** Results (Representatives tab, default) — https://essentials.empowered.vote/results?q=200+W+Kirkwood+Ave%2C+Bloomington%2C+IN+47404
- **severity:** blocker
- **type:** ux-friction
- **evidence:** screenshots/essentials/03-results-all.png — Federal tier shows only Erin Houchin, no Graham/Meyer/Peck/Roark challengers; State tier shows only Matt Pierce, no Lilliana Young
- **baseline_ref:** n/a
- **notes:** The data IS present (Elections tab shows all 5 IN-9 candidates and Young correctly — see G-114-005). The blocker is navigational: a first-time April-2026 voter lands on Representatives, sees only incumbents, and has no signal that challengers exist on a different tab. For a pre-primary voter, this is the wrong default.

### G-114-004 — Same candidate surfaces under different offices on Representatives vs Elections tabs
- **app:** essentials
- **screen:** Results (Representatives tab and Elections tab) — https://essentials.empowered.vote/results?q=200+W+Kirkwood+Ave%2C+Bloomington%2C+IN+47404
- **severity:** confusing
- **type:** content
- **evidence:** screenshots/essentials/03-results-all.png (Representatives: Deckard/Henry under `Council At Large`) + screenshots/essentials/04-elections-tab.png (Elections: Deckard/Henry under `Monroe County Commissioner District 1`)
- **baseline_ref:** n/a
- **notes:** Both representations are correct (current seat vs sought seat), but the voter sees no linkage between the two listings. Add "(running for Commissioner District 1 — see Elections tab)" on the Representatives side.

### G-114-005 — `Representatives` is the wrong default tab in the month before a primary
- **app:** essentials
- **screen:** Results — https://essentials.empowered.vote/results?q=200+W+Kirkwood+Ave%2C+Bloomington%2C+IN+47404
- **severity:** confusing
- **type:** ux-friction
- **evidence:** screenshots/essentials/03-results-all.png (default Representatives view) + screenshots/essentials/04-elections-tab.png (Elections view with full ballot)
- **baseline_ref:** n/a
- **notes:** The Elections tab is 100% accurate against `BALLOT-BASELINE-2026-05-05.md` for Bloomington Township. The problem is it isn't the default. For a voter in April preparing to vote on May 5, Elections should lead. Related to but distinct from G-114-003: G-114-003 is about the hidden challengers; this is about the default-view policy.

### G-114-006 — Profile page header shows wrong election date "May 4, 2026"
- **app:** essentials
- **screen:** Candidate profile — https://essentials.empowered.vote/candidate/7e768cda-38f3-4511-ad7c-c8e877c5abfa (also confirmed on /cb131cec-4fb4-4619-a2f0-7cdea745a2e9 and /a9f49b8d-086d-493f-8c34-a240c427200a)
- **severity:** blocker
- **type:** content
- **evidence:** screenshots/essentials/05-pierce-profile.png, screenshots/essentials/06-young-profile.png, screenshots/essentials/07-arrington-empty-profile.png — all three profiles render "Election: May 4, 2026"
- **baseline_ref:** n/a
- **notes:** The Indiana primary is **May 5, 2026** per `BALLOT-BASELINE-2026-05-05.md` and per the results-page `on your ballot — Primary: May 5, 2026` badges (which are correct). The off-by-one is in the candidate profile template string (confirmed across 3 different profiles → app-wide). Severity=blocker because voters trust date labels and could arrive at the polls on the wrong day.

### G-114-007 — Matt Pierce profile has no personal biography paragraph
- **app:** essentials
- **screen:** Candidate profile — https://essentials.empowered.vote/candidate/7e768cda-38f3-4511-ad7c-c8e877c5abfa
- **severity:** confusing
- **type:** data
- **evidence:** screenshots/essentials/05-pierce-profile.png — body paragraph describes what a state rep does generically, no Pierce-specific bio
- **baseline_ref:** `State Legislative Races` row — Indiana State Representative, District 61 (Matt Pierce, Lilliana Young)
- **notes:** DB gap already audited — see `AUDIT-REPORT-112.md §AUDIT-06 Profile Completeness` row for Matt Pierce (`Complete=N`). This is the voter-facing confirmation of that known DB gap — the voter gets civics info about the office but zero biographical context about the person asking for their vote.

### G-114-008 — Matt Pierce profile has no visible Read & Rank section despite 10 quotes in DB
- **app:** essentials
- **screen:** Candidate profile — https://essentials.empowered.vote/candidate/7e768cda-38f3-4511-ad7c-c8e877c5abfa
- **severity:** confusing
- **type:** feature
- **evidence:** screenshots/essentials/05-pierce-profile.png — profile renders Compass section and Committee/Voting sections, but no Read & Rank / Quotes heading anywhere
- **baseline_ref:** n/a
- **notes:** `ev-ui/src/PoliticianProfile.jsx` is documented to render Read & Rank verdict badges "under StanceAccordion" per CLAUDE.md. `AUDIT-REPORT-112.md §AUDIT-04` row for Matt Pierce shows **10 quotes linked** in DB, so the data exists. Either the surface isn't being rendered for Pierce or it renders empty and was not visible in the screenshot. Requires code-side check during Phase 115 tiering.

### G-114-009 — Lilliana Young has no headshot — initials placeholder only
- **app:** essentials
- **screen:** Candidate profile — https://essentials.empowered.vote/candidate/cb131cec-4fb4-4619-a2f0-7cdea745a2e9
- **severity:** confusing
- **type:** data
- **evidence:** screenshots/essentials/06-young-profile.png — "LY" initials square where headshot should be
- **baseline_ref:** `State Legislative Races` row — Indiana State Representative, District 61 (Matt Pierce, Lilliana Young)
- **notes:** DB gap already audited — see `AUDIT-REPORT-112.md §AUDIT-05 Headshot Coverage` row for Lilliana Young (`photo_source=none`). Voter-facing effect: in a head-to-head contested D primary, Pierce has a face and Young doesn't, which biases the visual comparison. She does have 57.7% Compass stance coverage and 6 Read & Rank quotes per AUDIT-112, so the rest of her profile has substance — only the photo is missing.

### G-114-010 — 4 of the May 5 primary candidates at this address are DB stubs with empty profile pages
- **app:** essentials
- **screen:** Candidate profile (multiple) — Arrington /candidate/a9f49b8d-086d-493f-8c34-a240c427200a, Nyquist (not exercised), Joe Davis (not exercised), Tanner Dale Branham (not exercised), Julie M. Hays (not exercised)
- **severity:** blocker
- **type:** data
- **evidence:** screenshots/essentials/07-arrington-empty-profile.png — Benjamin T. Arrington profile is literally a single name card: header, office label, wrong election date, and nothing else
- **baseline_ref:** `County-Wide Races` rows — Monroe County Prosecuting Attorney (Benjamin T. Arrington, Erika Oliphant), Monroe County Assessor (Bob Nyquist, Judith A. Sharp), Monroe County Clerk (Tanner Dale Branham, Joe Davis, Tree Martin Lucas, Julie M. Hays)
- **notes:** DB gap already audited — see `AUDIT-REPORT-112.md §AUDIT-03 Stance Coverage` rows where Arrington, Nyquist, Joe Davis, Branham, Hays all appear with blank politician_id and `status=stub` (unlinked — no underlying politician record). The voter-facing consequence is that the **contested Monroe County Prosecutor primary** and the **3-way contested Monroe County Clerk primary** are unchooseable from inside the app — one side of each race has zero content. Severity=blocker because the tool fails its UX-01 goal (helping a voter decide) precisely where it matters most.


<!-- ========================================================================= -->
<!-- Plan 114-03: Compass (UX-02) — full calibration → Build → results → compare -->
<!-- ========================================================================= -->

### G-114-011 — Compare picker defaults to all-states, no location-aware prioritization
- **app:** compass
- **screen:** Results (Compare picker open) — https://compass.empowered.vote/results
- **severity:** confusing
- **type:** ux-friction
- **evidence:** screenshots/compass/06-compare-picker.png — "State" dropdown defaults to unfiltered (California + Indiana mixed); first result is Julia Brownley (CA-26), an irrelevant California rep
- **baseline_ref:** n/a
- **notes:** A Monroe County voter clicking Compare sees 52 politicians intermixing CA and IN officials with no location awareness. They must manually change the "State" dropdown to "Indiana" to find anyone relevant. No autocomplete or geo-default is applied. Distinct from G-114-012 (which is about the absence of primary challengers even after filtering); this gap is about the entry experience before any filtering.

### G-114-012 — Primary challengers absent from Compass compare picker — contested May 5 races undecidable
- **app:** compass
- **screen:** Results (Compare picker → Indiana filter) — https://compass.empowered.vote/results
- **severity:** blocker
- **type:** data
- **evidence:** screenshots/compass/07-indiana-picker-filtered.png — Indiana filter shows 9 sitting officials; zero primary challengers (Graham/Meyer/Peck/Roark for IN-9 D primary; Arrington/Oliphant for Prosecutor; Branham/Davis/Lucas/Hays for Clerk absent)
- **baseline_ref:** `Federal Races` rows — U.S. Representative IN-9 (Houchin R + Graham/Meyer/Peck/Roark D challengers); `County-Wide Races` rows — Monroe County Prosecuting Attorney, Assessor, Clerk candidates
- **notes:** Compass can compare a voter against Erin Houchin (incumbent) but not against the 4 D candidates actually contesting the May 5 IN-9 primary. Root cause: no stance data exists for the challengers (they are either DB stubs per AUDIT-REPORT-112.md §AUDIT-03 or simply have no data entered). Consequence: the compare feature is voter-useful for exactly 1 of 8 May 5 ballot races (IN HD-61 Pierce vs Young). Severity=blocker because the most contested federal race on this voter's primary ballot is completely dark inside the app.

### G-114-013 — 4-step onboarding tooltip fires on first comparison and blocks the radar view
- **app:** compass
- **screen:** Results (comparison active) — https://compass.empowered.vote/results
- **severity:** confusing
- **type:** ux-friction
- **evidence:** screenshots/compass/08-compare-pierce-overlay.png — fixed-overlay tooltip "1 of 4: Search for any politician to compare..." renders over the dual-radar, blocking interaction until advanced through all 4 steps or "Skip All" clicked
- **baseline_ref:** n/a
- **notes:** A voter who just completed a 33-question calibration and navigated the picker must click through (or skip) a 4-step tutorial before they can interact with the comparison they came for. The tooltip content is useful (antipartisan explanation, stance interpretation guidance) but the timing and fixed-overlay delivery interrupt the payoff moment. Consider surface-level inline hints rather than a blocking tour.

### G-114-014 — Matt Pierce headshot missing in Compass compare panel despite headshot existing in Essentials
- **app:** compass
- **screen:** Results (compare panel) — https://compass.empowered.vote/results
- **severity:** confusing
- **type:** feature
- **evidence:** screenshots/compass/09-compare-clean.png — Matt Pierce shows grey silhouette avatar in compare panel; screenshots/essentials/05-pierce-profile.png — Pierce has a headshot on Essentials profile
- **baseline_ref:** n/a
- **notes:** The two apps appear to source headshots independently. Compass compare panel renders a placeholder for Pierce (and visibly for Jim Banks, David G Henry in the picker) even when Essentials shows a headshot for the same politician. Requires investigation into whether Compass pulls from the same `essentials.politician_images` table or a separate source. Cross-app data inconsistency.

### G-114-015 — Religious Freedom question appears to repeat in the 33-question calibration
- **app:** compass
- **screen:** Quiz — https://compass.empowered.vote/quiz?mode=full
- **severity:** minor
- **type:** content
- **evidence:** Auto-advance JS loop observation — Religious Freedom appeared at approximately Q4 and Q20; question text appeared identical or near-identical on both occurrences
- **baseline_ref:** n/a
- **notes:** Observed during rapid JS auto-advance; not screenshot-verified (questions cycled too fast). May represent two legitimately distinct Religious Freedom sub-questions (e.g., employment vs. public accommodations), or may be a content duplication bug. Requires a human re-run of the quiz reading each question carefully to confirm. Flagged as minor until verified.


<!-- ========================================================================= -->
<!-- Plan 114-04: Read & Rank (UX-03) — https://readrank.empowered.vote/       -->
<!-- ========================================================================= -->

### G-114-016 — Both location filter mechanisms are non-functional
- **app:** read-rank
- **screen:** Topic list — https://readrank.empowered.vote/
- **severity:** blocker
- **type:** feature
- **evidence:** screenshots/read-rank/03-address-filter-no-change.png — address "200 W Kirkwood Ave, Bloomington, IN 47404" typed + Enter; topic list identical before and after. Browse Location dropdown (snap _snap-04-browse-location.md) contains only a "State" placeholder option — no actual states listed.
- **baseline_ref:** n/a
- **notes:** The voter has two mechanisms to filter quotes to their local candidates: (1) address text entry with Enter submit, and (2) "Browse Location" state dropdown. Both fail. The address filter accepts input but fires no geocode request and changes nothing. The Browse Location dropdown has a single inert "State" option. Without working filters, a Monroe County voter must complete all 26 topics (~100+ individual quote interactions) to discover which of their candidates are in the pool. Severity=blocker because the primary voter-facing navigation aid for a location-aware tool is broken end-to-end.

### G-114-017 — No candidate-level navigation — topic-centric structure buries local candidates across 26 mixed topics
- **app:** read-rank
- **screen:** Topic list — https://readrank.empowered.vote/
- **severity:** confusing
- **type:** ux-friction
- **evidence:** screenshots/read-rank/02-topic-list.png — all 26 topics shown; no "Candidates in your area" or "Filter by candidate" path visible anywhere in the UI
- **baseline_ref:** n/a
- **notes:** Even if the location filter worked, Read & Rank's organization is by topic (Deportation, Tariffs, Abortion…), not by candidate. A voter wanting to evaluate Matt Pierce specifically cannot say "show me only Pierce quotes." They discover Pierce in some topic reveals after completing the evaluation. Two of three Voting Rights quotes were California politicians (Kounalakis, Newsom); the one Monroe candidate (David Henry) was indistinguishable from the California quotes during evaluation. For a voter with limited time before May 5, the topic-centric model requires 2–3 hours of full topic completion to surface all local candidates.

### G-114-018 — IN-9 D primary challengers and contested county-race candidates have zero Read & Rank quotes
- **app:** read-rank
- **screen:** Topic list / any topic — https://readrank.empowered.vote/
- **severity:** blocker
- **type:** data
- **evidence:** Voting Rights reveal (screenshots/read-rank/06-reveal-who-said-it.png) — no Graham, Meyer, Peck, or Roark appear in the 3-quote reveal; cross-referenced with AUDIT-REPORT-112.md confirming IN-9 challengers and county candidates are stubs with no politician records
- **baseline_ref:** `Federal Races` row — U.S. Representative IN-9 (D challengers: Graham, Meyer, Peck, Roark); `County-Wide Races` rows — Monroe County Prosecuting Attorney (Arrington, Oliphant), Monroe County Assessor (Nyquist, Sharp), Monroe County Clerk (Branham, Davis, Lucas, Hays)
- **notes:** The four IN-9 D primary challengers and the candidates in the County Prosecutor, Assessor, and Clerk primaries all lack politician records in the DB (stubs per AUDIT-REPORT-112.md §AUDIT-03). Without a politician record, no sourced quote can be linked to them in Read & Rank. The consequence for a voter using Read & Rank to decide the most contested races on the May 5 Monroe County primary ballot: zero quotes available for any of those candidates. Same root cause as G-114-012 (Compass compare) and G-114-010 (Essentials stubs) — all three apps fail at the same races.

### G-114-019 — "Your verdicts appear on candidate profiles in Essentials" has no link or CTA
- **app:** read-rank
- **screen:** Topic list (post-topic-completion) — https://readrank.empowered.vote/
- **severity:** confusing
- **type:** ux-friction
- **evidence:** Accessibility snapshot _snap-11-see-who-final.md line 818 — `paragraph: Your verdicts appear on candidate profiles in Essentials.` — plain text, no hyperlink, no "Go to Essentials" button
- **baseline_ref:** n/a
- **notes:** After completing topics the voter is told their verdicts appear in Essentials, but there is no link to go there. The per-politician "View on Essentials" links in the "See Who Said It" reveal DO work (with `#compass=` fragment passthrough), but the topic list page's cross-app copy is a dead end. A voter who completes a topic and wants to see how their verdicts affect a politician's profile has no navigation path from this text.

### G-114-020 — App page title is "readrank-prototype" — prototype label visible in browser tab in production
- **app:** read-rank
- **screen:** All pages — https://readrank.empowered.vote/
- **severity:** minor
- **type:** content
- **evidence:** `<title>readrank-prototype</title>` — browser tab shows "readrank-prototype" on all pages
- **baseline_ref:** n/a
- **notes:** Minor polish gap. The page title leaks the "prototype" development label to voters, potentially eroding trust in a production app. Does not affect function.


<!-- ========================================================================= -->
<!-- Plan 114-05: Treasury (UX-04) — https://treasurytracker.empowered.vote/   -->
<!-- Relevance check: PRESENT — Bloomington $224.7M (FY2026) + Monroe Co $345.1M (FY2025) -->
<!-- ========================================================================= -->

### G-114-021 — Landing page has no geo-personalization — Indiana municipalities buried in California-heavy list
- **app:** treasury
- **screen:** Landing — https://treasurytracker.empowered.vote/
- **severity:** confusing
- **type:** ux-friction
- **evidence:** screenshots/treasury/01-landing-full.png — initial community grid shows California cities (Agoura Hills, Alhambra, Arcadia…) above the fold; Bloomington IN and Monroe County IN are only discoverable by scrolling or knowing to look
- **baseline_ref:** n/a
- **notes:** The landing page callout says "explore Bloomington to see the feature in action" but does not geo-detect the visitor or prioritize Indiana results. A Monroe County voter has no affordance telling them their municipality is available until they scroll a long alphabetically-mixed list. Severity=confusing because the voter CAN find their city, but the default view gives zero signal that Indiana data exists.

### G-114-022 — Budget-vs-actual comparison data absent from both Bloomington and Monroe County budget pages
- **app:** treasury
- **screen:** Budget overview + category drill-down — https://treasurytracker.empowered.vote/ (Bloomington and Monroe County)
- **severity:** confusing
- **type:** feature
- **evidence:** screenshots/treasury/03-bloomington-budget-overview.png — "Money In" card is blank; screenshots/treasury/04-category-drilldown.png — category pages show only approved/budgeted amounts, no actuals column or comparison toggle
- **baseline_ref:** n/a
- **notes:** The CLAUDE.md app description documents budget-vs-actual comparison as a core Treasury feature ("actual_amount stored on line items for budget-vs-actual comparison"). Neither the Bloomington nor Monroe County budget pages surface a budget-vs-actual view in production. The voter sees only the approved budget figure with no ability to check whether spending matched the plan. The "Money In" (revenue) card also appears blank on the Bloomington overview. Whether data is missing from DB or the UI toggle is broken requires code-side investigation during Phase 115 tiering.

### G-114-023 — Monroe County budget shows FY 2025 while Bloomington shows FY 2026 — inconsistent fiscal year coverage
- **app:** treasury
- **screen:** Monroe County budget overview — https://treasurytracker.empowered.vote/ (Monroe County)
- **severity:** minor
- **type:** data
- **evidence:** screenshots/treasury/07-monroe-county-budget.png — Monroe County overview header reads "In 2025, Monroe County's budgeted $345 million"; screenshots/treasury/03-bloomington-budget-overview.png — Bloomington overview reads "In 2026, Bloomington's budgeted $225 million"
- **baseline_ref:** n/a
- **notes:** Both municipalities are in the same county context yet the most recent available data year differs by one fiscal year. Monroe County shows 2025 while Bloomington shows 2026. A voter comparing City of Bloomington vs Monroe County spending is comparing different fiscal years without any warning. Minor because the data is labeled by year and the difference is one year, but the lack of a "latest available year" notice on Monroe County is a content gap.

### G-114-024 — Bloomington year selector skips 2025 — gap year in historical budget continuity
- **app:** treasury
- **screen:** Bloomington budget overview — https://treasurytracker.empowered.vote/ (Bloomington, year dropdown)
- **severity:** minor
- **type:** data
- **evidence:** screenshots/treasury/09-year-selector-open.png — Bloomington year dropdown shows: 2026, 2024, 2023, 2022, 2021, 2020 — 2025 is absent
- **baseline_ref:** n/a
- **notes:** The historical year selector for Bloomington skips 2025 entirely. A voter wanting year-over-year trend analysis would see a two-year jump from 2024 to 2026 with no explanation. Root cause is likely a missing import for FY2025 Bloomington data. Minor severity because year-over-year comparison is a secondary use case for a first-time voter using the tool before May 5.

### G-114-025 — Sunburst chart labels unreadable without hover — static view shows unlabeled color segments
- **app:** treasury
- **screen:** Bloomington budget overview (sunburst view) — https://treasurytracker.empowered.vote/ (Bloomington, sunburst toggle)
- **severity:** minor
- **type:** ux-friction
- **evidence:** screenshots/treasury/10-sunburst-view.png — radial partition chart visible with colored segments; no visible category labels on the segments themselves; only hover/tooltip state would reveal segment names
- **baseline_ref:** n/a
- **notes:** The sunburst toggle provides an interesting visual but is not independently readable without interaction. The bar chart view (default) is strictly more informative for a voter wanting to understand where money goes. Minor because the bar view is the default and sunburst is a secondary visualization.


<!-- ========================================================================= -->
<!-- Plan 114-06: Cross-App Integration Pass (D-09)                            -->
<!-- ========================================================================= -->

### G-114-026 — SiteHeader "Treasury Tracker" and "Empowered Badges" nav links point to retired Netlify prototype URL
- **app:** cross-app
- **screen:** SiteHeader (all apps) — https://essentials.empowered.vote/, https://compass.empowered.vote/, https://readrank.empowered.vote/, https://treasurytracker.empowered.vote/
- **severity:** blocker
- **type:** feature
- **evidence:** screenshots/cross-app/00-essentials-landing-baseline.png — "Treasury Tracker" href resolves to `https://ev-prototypes.netlify.app/treasury-tracker/dist`; "Empowered Badges" href resolves to `https://ev-prototypes.netlify.app/empowered-badges/dist`
- **baseline_ref:** n/a
- **notes:** The production SiteHeader nav wires "Treasury Tracker" to the old EV-prototypes Netlify URL instead of `https://treasurytracker.empowered.vote/`. A voter clicking this link from any app is routed to the stale prototype. Same bug for "Empowered Badges." Severity=blocker because the cross-app nav is the voter's primary mechanism to discover all four apps, and two of the four links are broken.

### G-114-027 — No auth state relay between apps — logged-in session lost on cross-app navigation
- **app:** cross-app
- **screen:** SiteHeader (all apps) — guest state confirmed on Essentials, Read & Rank, Treasury Tracker
- **severity:** confusing
- **type:** ux-friction
- **evidence:** screenshots/cross-app/02-siteheader-essentials-to-readrank.png — "Sign in" link visible in Read & Rank SiteHeader despite navigating from Essentials; screenshots/cross-app/03-siteheader-essentials-to-treasury.png — "Sign In" link visible in Treasury SiteHeader
- **baseline_ref:** n/a
- **notes:** Each app maintains independent auth state — there is no shared session relay between Essentials, Compass, Read & Rank, and Treasury Tracker. A voter who logs in to one app is not recognized as logged in when they navigate to another via the SiteHeader. For the pre-May-5 voter context (primarily guest), this is not a blocker; but it is confusing to see "Sign in" after already authenticating, and it breaks the perception of a unified platform.

### G-114-028 — Profile CompassCard always shows "Calibrate your compass" prompt — no result displayed for already-calibrated visitors
- **app:** cross-app
- **screen:** Politician profile CompassCard — https://essentials.empowered.vote/candidate/7e768cda-38f3-4511-ad7c-c8e877c5abfa
- **severity:** confusing
- **type:** ux-friction
- **evidence:** screenshots/cross-app/04-profile-compasscard.png — "Calibrate your compass to see how you align with Matt Pierce" with "Calibrate your compass" button; the profile body text shows "Calibrate your compass" CTA regardless of visitor state
- **baseline_ref:** n/a
- **notes:** The CompassCard in the Essentials politician profile does not check for an existing calibration result in the visitor's localStorage or account. A voter who has already completed the Compass quiz and navigated to Pierce's profile sees the same "Calibrate" CTA as a voter who has never used Compass. The return URL on the CTA link is correct (`?return=https://essentials.empowered.vote/candidate/7e768cda-...`), so the forward trip works — but the CompassCard never renders a comparison result even for returning calibrated visitors. This means the most valuable cross-app touchpoint (seeing how you align with a candidate on their profile page) only works as a one-way trip to Compass rather than an inline result. Severity=confusing because the voter who has done the work already gets no reward at the profile level.

### G-114-029 — Read & Rank verdict badges absent from politician profile despite 10 sourced quotes in DB
- **app:** cross-app
- **screen:** Politician profile — https://essentials.empowered.vote/candidate/7e768cda-38f3-4511-ad7c-c8e877c5abfa
- **severity:** blocker
- **type:** feature
- **evidence:** screenshots/cross-app/05-profile-stanceaccordion-readrank-badges.png and screenshots/cross-app/13-pierce-profile-bottom-scroll.png — full-page scroll of Pierce profile shows no Read & Rank section, no StanceAccordion, no verdict badges anywhere; "Read & Rank" text found only in SiteHeader nav link
- **baseline_ref:** n/a
- **notes:** AUDIT-REPORT-112.md §AUDIT-04 confirms 10 sourced quotes are linked to Matt Pierce in the DB. The CLAUDE.md workspace docs describe "Read & Rank verdict badges under StanceAccordion" as an implemented feature in `ev-ui/src/PoliticianProfile.jsx`. The voter-side production walk confirms this section is not rendered on the live Essentials profile page. Whether the component is disabled, behind a feature flag, or broken in production is unknown from the walkthrough alone. Severity=blocker because a voter who completed Read & Rank quote evaluations for Pierce gets no visible payoff on the Essentials profile — the cross-app loop is broken at the profile side.

### G-114-030 — Compass compare panel has no "View profile in Essentials" link — picker is a dead end for candidate exploration
- **app:** cross-app
- **screen:** Compass results (compare picker) — https://compass.empowered.vote/results
- **severity:** confusing
- **type:** feature
- **evidence:** screenshots/cross-app/06-compass-picker-to-candidate.png — Compass results page in unauthenticated uncalibrated state shows only "Get Started" / "Skip for now" onboarding prompt; screenshots/cross-app/06-compass-results-before-picker.png — zero Essentials deep-links found on the results page
- **baseline_ref:** n/a
- **notes:** When a voter discovers a candidate via the Compass picker and wants to learn more about them (their biography, legislative record, contact info), there is no path from the Compass compare panel back to that candidate's Essentials profile. The picker adds a politician to the radar overlay but does not provide any "View full profile" link or CTA. A voter who discovers Matt Pierce in Compass must manually navigate to Essentials and re-search to find the profile. Severity=confusing because the voter CAN complete the cross-app journey manually, but the lack of a deep-link creates unnecessary friction and severs the natural follow-up action.

### G-114-031 — No contextual Essentials → Treasury hand-off link in results or profile flow
- **app:** cross-app
- **screen:** Essentials results + profile — https://essentials.empowered.vote/results?q=200+W+Kirkwood+Ave%2C+Bloomington%2C+IN+47404 and https://essentials.empowered.vote/candidate/7e768cda-38f3-4511-ad7c-c8e877c5abfa
- **severity:** confusing
- **type:** feature
- **evidence:** screenshots/cross-app/07-essentials-to-treasury-handoff.png — no Treasury Tracker link on the Essentials results page other than the SiteHeader nav link (which itself points to the wrong URL per G-114-026); no Treasury link on the Pierce politician profile
- **baseline_ref:** n/a
- **notes:** Treasury Tracker has Bloomington and Monroe County budget data ($224.7M and $345.1M respectively — see 114-05 walk). Essentials shows politicians who control those budgets (city council, county commissioners). Yet there is no in-flow prompt connecting the two — a voter learning about their city councillors has no nudge to explore what budget those councillors oversee. A contextual "Explore Bloomington's $224.7M budget → Treasury Tracker" link in the local tier of Essentials results, or in a city council member's profile, would complete the civic loop. Its absence means the two most civic-context-rich apps in the suite never cross-reference each other.

