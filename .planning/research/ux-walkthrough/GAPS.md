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

