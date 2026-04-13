# Benchmark Matrix — EV vs BallotReady / Vote411 / VoteSmart / Ballotpedia

**Run date:** 2026-04-12
**Primary address:** 200 W Kirkwood Ave, Bloomington, IN 47404
**Rubric:** see `METHODOLOGY.md` (0–3 depth + `blocked`). Dimension 10 is inverted (higher = more antipartisan).
**Source files:** `ballotready.md`, `vote411.md`, `votesmart.md`, `ballotpedia.md`, `ev.md` (each file's `## Field Inventory` section is the authoritative per-cell evidence).
**Baseline denominator (Dim 1):** `BALLOT-BASELINE-2026-05-05.md` (Phase 112 output — ~14 on-ballot race slots for the Kirkwood voter).

---

## Core 10 Scoring Table

| #  | Dimension                    | EV       | BallotReady | Vote411  | VoteSmart | Ballotpedia |
| -- | ---------------------------- | -------- | ----------- | -------- | --------- | ----------- |
| 1  | Race coverage vs baseline    | 2¹       | 0²          | 2³       | 1⁴        | 2⁵          |
| 2  | Candidate photo              | 1⁶       | 0²          | 0⁷       | 1⁸        | 2⁹          |
| 3  | Candidate bio                | 0¹⁰      | 0²          | 1¹¹      | 3¹²       | 3¹³         |
| 4  | Candidate contact info       | 2¹⁴      | 0²          | 1¹⁵      | 3¹⁶       | 2¹⁷         |
| 5  | Stance / issue data          | 1¹⁸      | 0²          | 1¹⁹      | 3²⁰       | 1²¹         |
| 6  | Candidate quotes / Q&A       | 1²²      | 0²          | 2²³      | 2²⁴       | 2²⁵         |
| 7  | Legislative record           | 2²⁶      | 0²          | 0²⁷      | 3²⁸       | 1²⁹         |
| 8  | Geofence / address precision | 1³⁰      | 0²          | 1³¹      | 1³²       | 2³³         |
| 9  | Data freshness               | 2³⁴      | 0²          | 1³⁵      | 2³⁶       | 3³⁷         |
| 10 | Antipartisan framing †       | 3³⁸      | 3³⁹         | 1⁴⁰      | 0⁴¹       | 0⁴²         |
|    | **Core-10 total (max 30)**   | **15**   | **3**       | **9**    | **19**    | **16**      |

† Dimension 10 is inverted per METHODOLOGY §3/§6: higher score = more antipartisan. EV's 3 is the rubric's intended outcome for a product that intentionally omits party labels, endorsements, interest-group ratings, and partisan color associations.

### Evidence footnotes (per cell)

1. `ev.md` §Field Inventory row 1 — Elections tab surfaces 13/14 baseline races for Kirkwood (~93%), with a concrete County Council D1→D4 binding miss capping the score at 2.
2. `ballotready.md` §Field Inventory — every core dimension scored 0. BallotReady's civic-center returns "no office holder information" across Federal/State/Local tabs for all three addresses; 0/14 baseline races. Not blocked (no signup/captcha/paywall encountered) — this is a measured product gap.
3. `vote411.md` §Field Inventory row 1 — 16 races returned for Kirkwood (superset, ≥13/14 on-ballot; candidate count verified at 5/5 for US House IN-9 only; other races not drilled).
4. `votesmart.md` §Field Inventory row 1 — product-scope mismatch: VoteSmart is a sitting-officeholder + fed/state-candidate tracker, not a ballot tool. 3/14 baseline races surfaced as candidate cards (US House IN-9, HD 61, County Council D1). ~21% coverage.
5. `ballotpedia.md` §Field Inventory row 1 — sblv3 tool returns 16 "candidate races" for Kirkwood; 11–13/14 baseline races verified (~79–93%). Superset on 4 county council districts.
6. `ev.md` row 2 — AUDIT-REPORT-112: 19 cdn / 0 local / 62 none across 81 candidates (~23%). Sitting officials get real headshots; challengers get two-letter initials placeholders.
7. `vote411.md` row 2 — US House IN-9 race detail renders 5 candidate cards with party labels only, no headshots visible in DOM.
8. `votesmart.md` row 2 — ZIP results list shows silhouette/avatar tiles; detailed profiles render text-only bios; most legislative challengers show initials placeholders.
9. `ballotpedia.md` row 2 — Houchin infobox renders formal portrait; coverage is uneven (federal incumbents strong, local challengers sparse).
10. `ev.md` row 3 — AUDIT-REPORT-112: 0/51 linked candidates have bios. Profiles render a generic **chamber** description ("The U.S. House of Representatives is one of two chambers...") in the bio slot. Hard 0 per D-10.5 same-harshness rule.
11. `vote411.md` row 3 — LWV questionnaire model includes candidate bio intro, but the View-Answers modal did not serialize into captured DOM; capped at 1 (minimal/verified).
12. `votesmart.md` row 3 — Houchin BIO tab captured: full name, family, birth date, home city, religion, expandable education/political experience/committees/caucuses/professional experience. Personal-data-rich.
13. `ballotpedia.md` row 3 — Houchin wiki renders encyclopedic career prose (birthplace, IU BA + GW MA, Contend Communications, Dan Coats regional director, State Senate D47 2014–22, committee structure, predecessor/successor, $174k salary, certified election history).
14. `ev.md` row 4 — Structured contact-type taxonomy (primary/office/campaign/central); Houchin profile: office address + office phone + central phone + primary email + campaign email + website + wiki + 5 social links. DB avg 1.2 contacts/candidate per AUDIT-REPORT-112 caps the score at 2.
15. `vote411.md` row 4 — LWV data model includes candidate-supplied contact; View-Answers modal not captured; capped at 1.
16. `votesmart.md` row 4 — Houchin BIO tab: Campaign (email, website, "More Campaign Contacts") + Office (Washington DC address, Webmail, Website, "More Office Contacts") — multi-tier contact.
17. `ballotpedia.md` row 4 — Houchin wiki lists 11 channels organized by Official / Campaign / Personal tier (website, Facebook, X, Instagram, YouTube, LinkedIn, etc.) but no email/phone/mailing address.
18. `ev.md` row 5 — Houchin STANCE BREAKDOWN with 21 topics, Pierce with 19. AUDIT-REPORT-112: only 5/51 linked candidates have any stances (~10%). Feature works for big profiles, empty for the rest.
19. `vote411.md` row 5 — Vote411's candidate-Q&A model is stance-adjacent. Presence of issue questions confirmed by "Select candidates to compare their responses on issues that matter to you" copy; answers not captured.
20. `votesmart.md` row 5 — Houchin POSITIONS tab: 40+ issue questions across Abortion, Budget, Campaign Finance, Crime, Defense, Economy, Education, Elections, Energy, etc., each marked Official/Inferred/Unknown with sourced evidence (tweets, roll-call votes, interest-group ratings). "Political Courage Test" — the core VoteSmart product.
21. `ballotpedia.md` row 5 — Issue positions present only for candidates who complete the opt-in Candidate Connection survey; absent from incumbent profiles (Houchin page has none). Sparse-by-opt-in.
22. `ev.md` row 6 — AUDIT-REPORT-112: 4/51 linked candidates have quotes (~8%). Stance text on profiles is paraphrased, not sourced verbatim. Read & Rank integration exists but no Q&A card rendered in captures.
23. `vote411.md` row 6 — Every candidate has a "View Answers" button; LWV footer disclaimer ("All responses come directly from the candidates and are unedited by the League") confirms Q&A is the core feature. Capped at 2 because the modal did not serialize into DOM and LWV response rates are uneven.
24. `votesmart.md` row 6 — Tweet quotations + policy statements embedded inline in POSITIONS as evidence for inferred positions (with Twitter source citations). Standalone public-statements page returns 404 — rolled into POSITIONS.
25. `ballotpedia.md` row 6 — Candidate Connection Q&A present for candidates who opt in (questions include "Why are you running?" / "What areas of public policy are you passionate about?" / "Who do you look up to?"); Houchin did not opt in, so absent on his profile. Sparse-by-opt-in.
26. `ev.md` row 7 — Pierce profile: 5 committees, "Voted in 100% of roll calls", example vote ("Voted Nay on Shooting ranges. — passed"), "Authored 5 bills." Houchin profile: 6 visible committees + "Show all 7" + bill authorship + HR 1628 In Committee. Federal + state wired via Congress.gov + LegiScan; local-tier has zero data (Bolden profile empty). Capped at 2 because local is empty and per-vote drill-down not rendered.
27. `vote411.md` row 7 — No bills / votes / committee memberships surfaced. Vote411 is not a legislative-record product (deliberate product scope).
28. `votesmart.md` row 7 — Houchin VOTES tab: 31 pages of roll-call votes with bill number, title, outcome, vote position, date (current through 03/27/2026). Filters for sponsorships-only and issue type. Strongest in benchmark set.
29. `ballotpedia.md` row 7 — Committee assignments listed + election-history vote totals, but no roll-call votes, no bill sponsorships, no voting record page. Encyclopedic-narrative scope, not legislative-tracking scope.
30. `ev.md` row 8 — PostGIS ST_Covers against TIGER 2024 + ArcGIS. Primary: Kirkwood → Bloomington Twp + HD 61 ✓. Covenanter: township flips to Perry ✓ but HD stays 61 (expected HD 62) ✗. Mt Tabor: doesn't geocode at all. Council District D1→D4 binding bug. Same 1 as Vote411.
31. `vote411.md` row 8 — Township binding correct (Bloomington ↔ Kirkwood, Perry ↔ Covenanter), but Covenanter returns HD 61 (wrong — should be HD 62), council districts returned as superset (all 4), Mt Tabor doesn't resolve.
32. `votesmart.md` row 8 — ZIP-level match returning superset of all districts touching ZIP 47404. Product itself discloses: "47404 has multiple legislative districts. To refine, enter your home address or 9-digit ZIP." Address-level precision not exercised in captures.
33. `ballotpedia.md` row 8 — State House district flips correctly across Kirkwood (HD 61) → Mt Tabor (HD 46). Townships change correctly (Bloomington → Richland → Perry). Covenanter returns HD 61 (same edge case as Vote411/EV; internally consistent Perry+HD 61 pairing). County council still superset. Best state-level precision in the set.
34. `ev.md` row 9 — 23-day countdown to May 5 primary; Houchin FEC "Updated Apr 12, 2026" (same-day); Pierce FEC "Updated Apr 2, 2026"; structured term date ranges. Capped at 2 because freshness is per-FEC-record only, no last-updated on stances/quotes/bios.
35. `vote411.md` row 9 — Aggregate counters ("13345 candidates / 6298 races") and upcoming-debate dates (14 Apr 2026 IN-9 debate). No per-record freshness signal.
36. `votesmart.md` row 9 — VOTES current through 03/27/2026 (2 weeks pre-run) but site footer frozen at "© 1992-2021" and interest-group ratings cite 2023–24 cycles. Bifurcated freshness.
37. `ballotpedia.md` row 9 — Live 23-day countdown; explicit "we will update your sample ballot accordingly as we get closer to election day" commitment copy; 2024 certified election results; "© 2026 Ballotpedia" footer. Freshest product in the set.
38. `ev.md` row 10 — No party labels on representative cards, no endorsements, no interest-group ratings, no partisan color associations, FEC raw total as neutral transparency signal only. Party labels appear only on Elections tab as race-group headers (closed-primary structural necessity, analogous to Vote411's filter modal).
39. `ballotready.md` row 10 — No party labels / endorsements / ratings / donor totals / partisan color on the civic-center ballot-data surface (score held at 3 because there is no candidate content to partisan-label in the first place). Nuance: Oath partner in the "Take Action" area is labeled "(partisan - left)" by BallotReady itself — editorial nuance that does not land on the ballot-data surface.
40. `vote411.md` row 10 — Party labels prominent on every candidate card (DEMOCRATIC / REPUBLICAN in all-caps); party-filter modal defaults to filter closed-primary races by chosen party. No endorsements / ratings / donor totals / red-blue color. Middle score: party labels yes, deeper partisan features no.
41. `votesmart.md` row 10 — Party labels on every tile (R-IN / D-IN), INCUMBENT/CHALLENGER framing, interest-group scorecards (NRL 100%, Planned Parenthood 0%, SBA 100%, AIPAC 2026 endorsement), ideological topic scorecards (Conservative, Liberal, Fiscally Liberal). By-design partisan — VoteSmart's mission is partisan-disclosure, not partisan-suppression.
42. `ballotpedia.md` row 10 — Pervasive party tags on every race; "Democratic primary" / "Republican primary" as organizing headings; explicit endorsement sections (Trump endorsement shown on Houchin); third-party partisan race ratings (Cook / DDHQ / Inside Elections / Sabato's Crystal Ball) surfaced in a dedicated "Race ratings" infobox. Note: Ballotpedia claims "firmly committed to neutrality" in its mission statement — editorial asymmetry vs VoteSmart's transparent partisanship.

---

## Race / Candidate Count vs Baseline

Denominator: `BALLOT-BASELINE-2026-05-05.md` — the Kirkwood voter's actual May 5 2026 primary ballot has 14 on-ballot race slots across Bloomington Township / State House District 61 / County Commissioner D1 / County Council D1.

| Race (from baseline)                                   | Baseline candidates (D+R) | EV  | BallotReady | Vote411         | VoteSmart | Ballotpedia |
| ------------------------------------------------------ | ------------------------- | --- | ----------- | --------------- | --------- | ----------- |
| US Representative, IN-9                                | 5 (4 D + 1 R)             | 5 ✓ | 0           | 5 ✓             | 5 ✓       | 5 ✓         |
| Indiana State Representative, District 61              | 2 (2 D)                   | 2 ✓ | 0           | surfaced        | 2 ✓       | surfaced    |
| County Prosecuting Attorney                            | 2 (2 D)                   | 2 ✓ | 0           | surfaced        | 0         | surfaced    |
| County Clerk of the Circuit Court                      | 4 (3 D + 1 R)             | 4 ✓ | 0           | surfaced        | 0         | surfaced    |
| County Recorder                                        | 1 (1 D)                   | 1 ✓ | 0           | surfaced        | 0         | surfaced    |
| County Sheriff                                         | 1 (1 D)                   | 1 ✓ | 0           | surfaced        | 0         | surfaced    |
| County Assessor                                        | 2 (2 D)                   | 2 ✓ | 0           | surfaced        | 0         | surfaced    |
| County Commissioner, District 1                        | 2 (2 D)                   | 2 ✓ | 0           | surfaced        | 0         | surfaced    |
| Judge, Circuit Court Division 6 (Seat 5 / Krothe)      | 1 (1 D)                   | 1 ✓ | 0           | surfaced        | 0         | surfaced    |
| Judge, Circuit Court Division 1 (Seat 9 / Bradley)     | 1 (1 D)                   | 1 ✓ | 0           | surfaced        | 0         | surfaced    |
| **County Council, District 1** (voter's district)      | 1 (1 D)                   | **✗ (wrong district — shows D4)** | 0           | surfaced (as superset w/ D2–D4)  | 1 ✓       | surfaced (as superset w/ D2–D4) |
| Bloomington Township Trustee                           | 1 (1 D)                   | 1 ✓ | 0           | surfaced        | 0         | surfaced    |
| Bloomington Township Board (3 seats)                   | 3 (3 D)                   | 3 ✓ | 0           | surfaced        | 0         | surfaced    |
| **TOTAL on-ballot race slots**                         | **14 / ~26 candidates**   | **13 / 14** | **0 / 14** | **13+ / 14**   | **3 / 14**       | **11–13 / 14**   |
| **MATCH %**                                            | —                         | **~93%**    | **0%**    | **~93%**        | **~21%**  | **~79–93%** |

**Interpretation:**
- **Vote411 (~93%)**, **EV (~93%)**, and **Ballotpedia (~79–93%)** cluster at the top for on-ballot race coverage. They behave as ballot-lookup products and deliver the Kirkwood voter's races.
- **EV's one detectable miss is structurally different** from the other two: not a failure to include the race, but a failure to bind the voter to the correct County Council district (shows CC D4 when the voter is in CC D1). This is a concrete, falsifiable geofence-to-subdistrict bug, not a data-coverage hole. Logged for Phase 115.
- **VoteSmart (~21%)** fails by product scope, not by execution — it does not track county-level primary races anywhere in the country. Its 3 surfaced races (US House IN-9, HD 61, Council D1) are all fully populated; the other 11 are simply not in VoteSmart's product model.
- **BallotReady (0%)** is the outlier: zero ballot races surfaced despite no access blockers. BallotReady's Indiana data exists at the marketing-page level ("2,260 positions up for election") but the address-to-race binding pipeline is not lit up for Monroe County on 2026-04-12, 23 days before the May 5 primary.

---

## Derived-Extra Dimensions

Features surfaced by one or more competitors that are NOT in the core 10. Per METHODOLOGY §3, up to 5 allowed — 5 kept below, ordered by cross-subject significance. Per METHODOLOGY §6/§7, EV's `intentional omission` entries on E1–E4 are NOT scored as gaps (they are deliberate antipartisan-principle product decisions). EV's E1–E4 scores therefore read as `— (intentional)`.

| #  | Derived dimension                              | EV               | BallotReady | Vote411 | VoteSmart | Ballotpedia | Notes |
| -- | ---------------------------------------------- | ---------------- | ----------- | ------- | --------- | ----------- | ----- |
| E1 | Interest-group ratings / scorecards            | — (intentional)  | 0           | 0       | **3**     | 0           | VoteSmart's signature feature (`votesmart.md` E1): 40+ issue scorecards (NRL, PPAF, SBA, AIPAC, etc.) with 0–100% ratings. Intentionally omitted by EV per METHODOLOGY §6. |
| E2 | Explicit endorsements aggregation              | — (intentional)  | 0           | 0       | **2**     | **3**       | Ballotpedia shows "Houchin received the following endorsements: President Donald Trump (R) 2024" as a dedicated section (`ballotpedia.md` row 10); VoteSmart surfaces 2026 Endorsements list starting with AIPAC PAC (`votesmart.md` E3). Intentionally omitted by EV. |
| E3 | Third-party partisan race ratings (Cook, Sabato, DDHQ, Inside Elections) | — (intentional) | 0 | 0 | 0 | **3** | Ballotpedia-unique: dedicated "Race ratings" infobox on every federal race (`ballotpedia.md` E3). Intentionally omitted by EV. |
| E4 | Candidate-response Q&A product (LWV questionnaire / Candidate Connection / Political Courage Test) | 0 | 0 | **2** | **3** | **3** | Vote411's LWV questionnaire (`vote411.md` row 6), Ballotpedia's opt-in Candidate Connection survey (`ballotpedia.md` E1), and VoteSmart's Political Courage Test (`votesmart.md` E5) are three editorially different Q&A products. EV scores 0 here — this is a **non-intentional gap** per `ev.md` §Narrative Note #2. |
| E5 | Withdrawn / disqualified candidate tracking    | 0                | 0           | 0       | 0         | **3**       | Ballotpedia-unique (`ballotpedia.md` E4): IN-9 race page lists "Withdrawn or disqualified candidates: James Davidson (D), Cody Voyles (D), Emilee McCartney (D)." Non-intentional gap for EV; relevant to `project_candidates_vs_politicians.md` data model work. |

**Extras NOT included** (each subject file lists 6–10 derived extras in its Field Inventory — the above 5 are the ones with cross-subject scoring significance):

- BallotReady E1/E2/E3 (voter registration lookup, "run for office" search, partner action directory) — **E6** below is a noted standalone for BallotReady.
- Vote411 E1/E2 (election-date + registration-deadline block, debates & forums with venue+time) — see E7 / E8 below.
- VoteSmart E2/E4/E5/E6/E7 (voting record with filters, incumbent/challenger tag, Political Courage Test, Track Politician button, Civic Sage AI chat) — see E9 below.
- Ballotpedia E2/E5/E6/E7/E8 (encyclopedic race wiki pages, campaign finance / compensation, predecessor-successor chain, "estimated time to complete" microcopy, printable ballot output) — see E10 below.
- EV E1/E3/E6/E7/E9 (Compass cross-link, chamber-official-website links, term dates + years-in-office, tier filter, Elections tab) — see E11 below.

### Secondary derived extras (single-subject highlights, not cross-compared)

| #   | Feature                                                                 | Owner        | Score | Notes |
| --- | ----------------------------------------------------------------------- | ------------ | ----- | ----- |
| E6  | Voter registration check-and-update (inline, address-bound)            | BallotReady  | 3     | `ballotready.md` E1 — the one Monroe-County-working feature BallotReady ships. |
| E7  | Debates & forums with venue + time + recording links                    | Vote411      | 3     | `vote411.md` E2 — 14 Apr 2026 IN-9 debate at UU Church Bloomington + YouTube recordings. Unique. |
| E8  | Multilingual support (English/Español + 4 hotlines)                     | Vote411      | 2     | `vote411.md` E7. |
| E9  | Roll-call-vote surface with bill filters                                | VoteSmart    | 3     | `votesmart.md` E2 — 31-page paginated roll-call list. EV has the DB data (`essentials.votes`) but does not surface this depth in the profile UI — **non-intentional EV gap**, highest-priority for Phase 115 alongside bios. |
| E10 | Encyclopedic race / district wiki pages                                 | Ballotpedia  | 3     | `ballotpedia.md` E2 — every race has a dedicated Wikipedia-style article with filing deadlines, prior elections, withdrawn candidates. |
| E11 | Compass cross-link from profile (issue alignment tool)                  | EV           | 2     | `ev.md` E1 — unique in the set; no competitor cross-links to an issue-alignment product. |
| E12 | Tier-level classification + group filter (Local/State/Federal toggle)   | EV           | 3     | `ev.md` E7 — unique in the set; no competitor lets the voter filter representatives by tier or elected/appointed. |

---

## Score Summary

| Subject     | Core-10 total | One-line interpretation |
| ----------- | ------------- | ----------------------- |
| **VoteSmart**   | **19 / 30** | Deepest candidate-level data in the set (bio 3, contact 3, stances 3, legislative record 3) but narrow product scope (~21% ballot coverage) and maximally partisan-framed (Dim 10 = 0). Strongest single-candidate drill, weakest ballot-tool. |
| **Ballotpedia** | **16 / 30** | Best-balanced ballot product + encyclopedic depth. Freshest data in the set (Dim 9 = 3), deepest bio prose (Dim 3 = 3), but partisan-framed (Dim 10 = 0) despite neutrality claim. |
| **EV**          | **15 / 30** | Ballot-race coverage tied at top cluster (~93%), strong on legislative record (federal/state only) and contact info, uniquely antipartisan (Dim 10 = 3). Non-intentional gaps on bio (0), photo (1), stance coverage (1), quotes (1) — these are EV's Phase 115 priorities. |
| **Vote411**     | **9 / 30**  | The "ballot product that works" for Monroe County on 2026-04-12 — ~93% race coverage, real debate listings, working LWV Q&A — but thin on candidate-level depth (bio 1, contact 1, stances 1, no legislative record). The most usable for the voter, the least data-rich. |
| **BallotReady** | **3 / 30**  | Measured product gap, not an access gap. Despite a polished brand and state-level aggregate claims ("2,260 positions up for election"), the address-to-race binding pipeline returns zero Monroe County data 23 days before the primary. Only Dim 10 = 3 because there is no candidate content to partisan-label. |

---

## Editorial Asymmetries & Narrative Notes (for Phase 115 synthesis)

1. **"Nonpartisan" means different things to different products.** VoteSmart scores 0 on Dim 10 and openly embraces partisan disclosure as its product mission (interest-group ratings are the feature). Ballotpedia also scores 0 on Dim 10 but claims in its own mission statement to be "firmly committed to neutrality" — yet ships party tags, endorsement sections, and third-party partisan race ratings (Cook / Sabato / Inside Elections / DDHQ) as first-class features. **VoteSmart is partisan-by-mission and honest about it; Ballotpedia is partisan-by-feature while claiming neutrality.** EV's Dim 10 = 3 is a genuinely different editorial posture, not just a difference in degree.

2. **Vote411's and EV's Dim 10 = 1 / 3 are close in practice.** Vote411 shows party labels on candidate cards because Indiana has closed primaries and the LWV product is helping voters see their actual ballot; EV shows party labels only on Elections-tab race-group headers for the same structural reason. The difference in score (1 vs 3) reflects that Vote411 labels individual **candidates** with party while EV labels only the **race group**. Per METHODOLOGY §6 operational definition, EV's approach scores higher, but the editorial intent is similar (both are trying to help the voter, not valorize partisanship).

3. **BallotReady's "Coming soon!" tiles are the story, not the data.** The single most informative observation from the entire benchmark is that BallotReady's Monroe County civic center renders "Coming soon!" for "Find your polling place" and "Request a ballot" 23 days before the May 5 primary. A product whose brand is "Where you go before you vote" is not usable for the voter being benchmarked. This is not an access gap (no blockers), it is a product gap.

4. **Vote411 is the only product that surfaced a real debate listing** (14 Apr 2026 IN-9 candidates debate at UU Church Bloomington, with venue and time). This is the single most concretely useful content item in the entire benchmark for a Bloomington voter actively trying to decide between IN-9 primary candidates. Logged as derived E7 for Phase 115.

5. **Candidate-Q&A is a three-way competition with editorially different models.** Vote411's LWV questionnaire (verbatim candidate responses, unedited), Ballotpedia's Candidate Connection (opt-in survey, slot left empty when declined), and VoteSmart's Political Courage Test (fills refusals with inferred positions from tweets + roll-call votes + interest-group ratings) are three honest editorial positions on the same underlying problem. EV has none of them. This is the biggest non-intentional product feature gap in the core + derived set, alongside bios and roll-call surfacing.

---

## EV Gap Classification for Phase 115

Per the plan's mandate to distinguish **intentional omissions** from **non-intentional coverage gaps** so Phase 115 has a clean gap report:

### Intentional omissions (NOT gaps — documented per METHODOLOGY §6)

These features are deliberately absent from EV per the antipartisan principle in `PROJECT.md`. They should NOT appear in the Phase 115 gap report as deficiencies:

- **E1 — Interest-group ratings / scorecards** (VoteSmart=3): Deliberately omitted. No NRL / PPAF / SBA / AIPAC / ACU scorecards.
- **E2 — Explicit endorsements aggregation** (Ballotpedia=3, VoteSmart=2): Deliberately omitted. No endorsement lists, no labor/newspaper/advocacy endorsements.
- **E3 — Third-party partisan race ratings** (Ballotpedia=3): Deliberately omitted. No Cook / Sabato / Inside Elections / DDHQ ratings.
- **Donor / fundraising breakdowns** (implied by Ballotpedia E5, VoteSmart general): Deliberately omitted. EV ships a raw FEC total only, no donor breakdown, no top-contributors list.
- **Party labels on sitting-official cards** (Vote411, VoteSmart, Ballotpedia all have these): Deliberately omitted. Dim 10's rubric operationalizes this as the 3 score.

### Non-intentional gaps (REAL gaps — candidates for Phase 115 gap report)

These are dimensions where EV scores below competitors and the shortfall is a coverage failure, not an editorial decision. Ordered by Phase 115 priority:

1. **Dim 3 — Candidate bio (EV=0, Ballotpedia=3, VoteSmart=3).** EV has 0/51 linked candidates with a bio per AUDIT-REPORT-112. Profiles render a generic chamber description in the bio slot. **Highest priority** — this is the biggest non-intentional gap in the entire benchmark and scores a hard 0 against competitors who score 3. Phase 115 should treat this as gap #1.
2. **Dim 7 — Legislative record surfacing (EV=2, VoteSmart=3).** EV has `essentials.bills` + `essentials.votes` + Congress.gov / LegiScan pipelines wired, but the profile UI surfaces only summary counts + a single example vote, not the full roll-call drill-down VoteSmart captures (31 pages for Houchin). **Data-model complete, UI surface incomplete** — this is a surface-area gap, not a data gap, and the highest-ROI fix. Also: local-tier has zero legislative data (Bolden profile empty); needs municipal + county + court pipelines.
3. **Dim 2 — Candidate photos (EV=1, Ballotpedia=2).** 19 cdn / 0 local / 62 none across 81 candidates (~23% coverage) per AUDIT-REPORT-112. Needs challenger photo scraping + Supabase CDN re-hosting for 2026 primary slate.
4. **Dim 5 — Stance / issue coverage (EV=1, VoteSmart=3).** Feature works (Houchin=21 topics, Pierce=19) but only 5/51 linked candidates have any stance data. Coverage expansion via staging workflow (`/api/staging/*`) needed for the 2026 primary field.
5. **Dim 6 — Candidate quotes / Q&A (EV=1, Vote411=2, VoteSmart=2, Ballotpedia=2).** 4/51 linked candidates have any quotes; paraphrased stance text rendered instead of sourced verbatim quotes. Read & Rank pipeline needs expansion to the primary candidate set.
6. **E4 — Candidate-response Q&A product (EV=0, Vote411=2, VoteSmart=3, Ballotpedia=3).** EV has no direct equivalent of LWV questionnaire / Political Courage Test / Candidate Connection. This is a **product-feature gap**, not just a coverage gap — Phase 115 should consider whether EV's staging workflow could host a similar candidate-response surface.
7. **E5 — Withdrawn candidate tracking (EV=0, Ballotpedia=3).** Ballotpedia-unique; connects to existing candidates-vs-politicians data model work (`project_candidates_vs_politicians.md`).
8. **County Council D1→D4 geofence binding bug** (Dim 1 evidence). Concrete, falsifiable miss on the voter's ballot-relevant council district. File as a bug for Phase 115.
9. **Rural address geocoding (Mt Tabor Rd fails to resolve).** Shared failure mode with Vote411. PostGIS infrastructure is sound; Google Places geocoding upstream is brittle on rural-number addresses. File as Dim 8 hardening task.

---

*Synthesized by Phase 113 plan 07 from the five per-subject spot-check files. Feeds Phase 115 (gap report + synthesis). All cell scores trace to an evidence note referencing the corresponding `.md` source file's `## Field Inventory` section.*
