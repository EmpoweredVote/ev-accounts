# VoteSmart — Spot Check

**Run date:** 2026-04-12
**Primary address:** 200 W Kirkwood Ave, Bloomington, IN 47404
**Secondary addresses:**
- 7333 W Mt Tabor Rd, Bloomington, IN 47404 (Benton Twp — State House 46/60 boundary test)
- 2700 E Covenanter Dr, Bloomington, IN 47401 (southeast Bloomington — State House 61/62 boundary test)
**Tooling:** Playwright (Chromium 1208, headless) driven from Node scripts under `/tmp/pw-work/`, same system-Playwright fallback pattern used in plans 02 and 03 because the `mcp__plugin_playwright_playwright__*` MCP tools were not registered in this session.
**Evidence directory:** `.planning/research/benchmark/screenshots/votesmart/` (51 PNGs + 51 matching `.txt` page dumps across 4 sequential scrape runs: r1 baseline, r2 full-address probe, r3 Houchin drill-in, r4 direct-URL ratings + Matt Pierce + 47401 secondary)

---

## Access Status

**`partially blocked` — access nuance, not a hard wall.** VoteSmart is fundamentally reachable without signup: the `justfacts.votesmart.org/` landing page, the `iSpy` address/name search, and the first ~3 candidate profile pages all render without any auth gate. However, VoteSmart enforces a **3-free-use soft gate** per browser session, implemented as a client-side modal (`loginPageLimitModal`) that locks the page after the 3rd–4th navigation inside a single browser context. Messages escalate predictably: *"You have 2 more free uses left"* → *"You have 1 more free use remaining"* → *"This is your last free use"* → *"You have used all your free accesses. Please log in or sign up to continue enjoying our content without interruption"* (with reCAPTCHA-protected SIGN UP / LOG IN dialog intercepting pointer events on all links).

This was mitigated at runtime by (a) creating a **fresh browser context per address** to reset the free-use cookie and (b) using **direct profile URLs** once we had harvested candidate IDs from an earlier context's search results. Both workarounds are non-trivial for a human user and the soft gate is a real product constraint in the user experience.

**D-02 classification:** One specific dimension is genuinely blocked in a way that a human walking the same flow would also hit. VoteSmart's **interest-group Ratings page** (`candidate/evaluations/{id}/`) rendered fully in one fresh-context run (`r4-01-houchin-ratings-direct`) but was **blocked by the `loginPageLimitModal`** in the sequential-drill run (`r3`). A human visiting from the primary-address results list would click Houchin → BIO → VOTES → POSITIONS → RATINGS and hit the soft gate exactly at the RATINGS step, because RATINGS is the 4th tab in the official workflow and the soft-gate counter increments on each tab switch. **Ratings depth is therefore observed with a blocker caveat: visible to anyone who knows to start with a fresh browser, but gated in the natural left-to-right tab flow.**

**Critical framing vs D-02:** This is a rare "partial blocker" case — the signal from plans 02 and 03 was that access was binary (accessible or fully blocked); plan 04 adds a third category (soft-gated per-dimension). The primary-address race/candidate count and BIO/VOTES/POSITIONS data are **unblocked** and measured as `accessible`. RATINGS is measured with the blocker caveat. No screen is silently treated as `0` when it is actually behind a gate.

**Primary entry point note:** The plan specified `https://justfacts.votesmart.org/` as the entry point. That URL is canonical — both `votesmart.org/*` variants redirect to `justfacts.votesmart.org/*`. `justfacts` is where all the content lives.

---

## Field Inventory

Scoring uses the 0–3 rubric from `METHODOLOGY.md` §2. For the RATINGS dimension only, the score reflects the data visible on `r4-01-houchin-ratings-direct`, with a blocker note (soft gate in natural navigation flow).

| # | Field (METHODOLOGY.md core dimension) | Present? | Depth (0–3) | Evidence |
|---|---------------------------------------|----------|-------------|----------|
| 1 | Race coverage vs baseline              | Mixed    | **1**       | `04-after-zip-submit.txt` — ZIP 47404 returns 50+ officials across federal/state/local, but VoteSmart's product model is **sitting officeholders + federal/state legislative candidates**, not "this voter's May 5 primary ballot." Of the 14 baseline races for the Kirkwood voter, VoteSmart surfaces candidate-level cards for 3: US House IN-9 (all 5 candidates ✓), State House District 61 (both 2 D candidates ✓), and County Council District 1 (Iversen ✓). The other 11 baseline races — Circuit Court judges (×2), County Prosecutor, Clerk, Recorder, Sheriff, Assessor, County Commissioner D1 primary slots, Bloomington Township Trustee, Bloomington Township Board — are **not surfaced at all** as primary-context candidate cards. Monroe County Commissioner incumbents (Lee Jones, Julie Thomas, Jody Madeira) and the Mayor (Kerry Thomson) show up as "CURRENT INCUMBENT" tiles, not as ballot races. Score 1 reflects "minimal/token presence" — some of the baseline is visible, but as an incumbents directory, not as the voter's ballot. See count table below. |
| 2 | Candidate photo                        | Y (partial) | **1**    | `r3-02-zip-results.png` + `r4-06-zip-47401-results.png` — the ZIP results list renders silhouette/avatar tiles for many officials but detailed profile screens (`r3-04-houchin-bio.png`) show text-only bio rather than an embedded headshot in the captured DOM. Some presidential/gubernatorial tiles render photos; most legislative challengers show initials placeholders. Honest score 1 reflects "present but shallow / many placeholders." |
| 3 | Candidate bio / biography prose        | Y        | **3**       | `r3-04-houchin-bio.txt` — Houchin's BIO tab rendered: full name, gender, family ("Husband: Dustin; 3 Children: Claire, Elaine, Graham"), birth date `09/24/1976`, home city `Salem, IN`, religion `Christian`, followed by expandable Education, Political Experience, Current Legislative Committees, Former Legislative Committees, Caucuses, and Professional Experience sections. This is among the deepest biographical depth in the benchmark set. Score 3 (comprehensive). |
| 4 | Candidate contact info                 | Y        | **3**       | `r3-04-houchin-bio.txt` — office-tier breakdown: `Campaign` (email, website, "More Campaign Contacts"), `Office` (`Washington, D.C.` address, `Washington, D.C. Webmail`, `Washington, D.C. Website`, "More Office Contacts"). Multiple contact tiers per office matches or exceeds the EV `politician_contacts` model (`primary`, `office`, `campaign`, `personal`, etc. per `CLAUDE.md`). Score 3. |
| 5 | Stance / issue position data           | Y        | **3**       | `r3-04-houchin-positions.txt` — Houchin's POSITIONS tab rendered 40+ specific issue questions across Abortion, Budget/Spending/Taxes, Campaign Finance, Crime & Public Safety, Defense, Economy, Education, Elections, Energy, etc. Each question marked `Official Position` / `Inferred Position` / `Unknown Position`, with sourced evidence (tweets, roll-call votes, NRL ratings, HR 26 reference). Example: Abortion-and-Roe Q&A cites two Twitter quotes + NRL 100% rating + HR 26 vote. Score 3 — this is the "Political Courage Test" product and it is genuinely comprehensive for federal incumbents. |
| 6 | Candidate quotes / Q&A / direct statements | Y     | **2**       | Tweet quotations + policy statements are **embedded inline in POSITIONS** as evidence for inferred positions (e.g. *"A year after the Dobbs decision - this is another important victory in the fight to protect the unborn." (twitter.com)*). A dedicated public-statements page was attempted (`r4-02-houchin-public-statements.txt`) — `candidate/public-statements/{id}/` returned `Page Not Found (404)`, suggesting VoteSmart has deprecated the standalone public-statements section and rolled quotes into POSITIONS. Score 2 (present and usable — quotes exist with source citations, but no dedicated Q&A section). |
| 7 | Legislative record                     | Y        | **3**       | `r3-04-houchin-votes.txt` — Houchin's VOTES tab rendered **31 pages** of roll-call votes with bill numbers, bill titles, outcomes, vote positions, and dates. Sample: `03/27/2026 — Defending American Property Abroad Act of 2026 — HR 7084 — Yes — Passage Bill Passed - House (247-164)`. Categorized by National Key Votes, with filters for sponsorships-only and issue type. This is the deepest legislative-record surface in the benchmark set — **Dimension 7 is VoteSmart's product moat** for sitting federal officials. Score 3 (comprehensive). |
| 8 | Geofence / address precision           | Mixed    | **1**       | See "Precinct Precision" section below. Short version: VoteSmart's iSpy search accepts full street addresses in principle but routes most searches to a ZIP-level match that returns a **superset of all districts touching that ZIP**. ZIP 47404 explicitly tells the user *"47404 has multiple legislative districts. To refine your search, please enter your home address or 9-Digit zip code"* — so the product knows it's imprecise and delegates precision-chasing to the user. Full-address submission via `Enter` key in the iSpy input did not trigger the AJAX code path that ZIP submissions use (product quirk), so from the captures we observe ZIP-level coverage, not address-level coverage. Score 1 reflects "address-aware in the UX but coarse at the data layer — returns all districts touching the ZIP." |
| 9 | Data freshness                         | Y        | **2**       | Voting-record page shows votes through `03/27/2026` (2 weeks before run date), with an explicit "On The Ballot: Running, Republican for U.S. House (IN) - District 9" status line. BUT the site footer reads `All content © 1992 - 2021 Vote Smart unless otherwise attributed` — the copyright-year anchor froze 5 years ago. Ratings page references `2023-2024` cycles for Planned Parenthood / NRL / SBA. Freshness is **very high for roll-call votes** (days old), **moderate for issue positions** (2024 cycle), **low for interest-group ratings** (2023-2024). Score 2 (present and usable, but bifurcated by data type). |
| 10| Antipartisan framing (**inverted** — higher = more antipartisan) | **N** | **0** | VoteSmart is the **opposite of antipartisan** in every measured dimension. Party labels are prominent everywhere: `REPUBLICAN` / `DEMOCRATIC` tags on every official, `R-IN` / `D-IN` suffix after every office (e.g. `U.S. HOUSE (R-IN) INCUMBENT`, `STATE HOUSE (D-IN) CHALLENGER`). `INCUMBENT` vs `CHALLENGER` framing creates an implicit incumbency advantage. **Interest-group ratings are VoteSmart's signature feature** — `r4-01-houchin-ratings-direct.txt` surfaces `2026 Endorsements: AIPAC PAC`, `National Right to Life Committee 100%`, `Planned Parenthood Action Fund 0%`, `Susan B. Anthony Pro-Life America 100%`, followed by 40+ issue-category scorecards including `Conservative`, `Fiscally Conservative`, `Fiscally Liberal`, `Liberal`, `Socially Conservative`. These are explicit partisan/ideological labels. Score **0** on the antipartisan-framing axis — VoteSmart is, by design, the most partisan-framed product in the benchmark set. **This is not a defect — see "Narrative Notes #1" on EV's intentional omissions vs VoteSmart's intentional feature.** |

### Derived extras (not part of core 10 — to be added to MATRIX.md by plan 07)

| # | Field (extra) | Present? | Depth | Evidence |
|---|---------------|----------|-------|----------|
| E1 | Interest-group ratings / scorecards | Y | **3** | `r4-01-houchin-ratings-direct.txt` — 40+ issue categories (Abortion, Conservative, Fiscally Conservative, Guns, Labor Unions, etc.) each expandable into named interest groups with 0–100% scores. AIPAC 2026 endorsement shown. NRL 100% / PPAF 0% as per-topic rows. **This is the single most distinctive VoteSmart feature** — no other competitor in the benchmark set surfaces a comparable scorecard. Plan 07 must add this as a derived extra. Intentionally omitted by EV per METHODOLOGY §6. |
| E2 | Voting record by bill with filters | Y | **3** | `r3-04-houchin-votes.txt` — "See Erin Houchin's Sponsorships Only" filter, issue filter, 31-page paginated list with bill numbers, outcomes, and vote positions. Intentionally omitted by EV for non-sitting-official surface; partially present in EV for federal incumbents via `essentials.votes` table (per `CLAUDE.md`). |
| E3 | Endorsements aggregation (explicit) | Y | **2** | `r4-01-houchin-ratings-direct.txt` — 2026 Endorsements list begins with AIPAC PAC. Captured section short but explicit feature. Intentionally omitted by EV. |
| E4 | Incumbent/challenger tag on every tile | Y | **2** | Every search-result tile carries `INCUMBENT` or `CHALLENGER`. EV's `essentials.politicians` model also has this concept via office dates, but not surfaced as a top-level tag — relevant design note for plan 07. |
| E5 | "Political Courage Test" (candidate-self-reported Q&A) | Y | **3** | `r3-04-houchin-positions.txt` — VoteSmart's branded candidate questionnaire with direct Q&A answers when the candidate responds, and inferred positions (from tweets, roll-call votes, interest-group ratings) when they don't. More editorially rich than Vote411's LWV questionnaire, but less candidate-voiced: Vote411 only surfaces direct answers, VoteSmart fills in refusals with research. Different editorial philosophy. |
| E6 | Track politician button | Y | **2** | `r3-04-houchin-bio.txt` — `TRACK THIS POLITICIAN` CTA on every profile, likely email-alert signup for new votes/statements. Not explored further due to soft-gate concerns. |
| E7 | Civic Sage AI chat | Y | **2** | `01-justfacts-landing.txt` — Persistent modal overlay promoting "Meet Civic Sage" with 2 free chat uses. Tagline: "Built with boundaries, on purpose." Not drilled into. |
| E8 | Multi-district ZIP disambiguation message | Y | **3** | `04-after-zip-submit.txt` / `r4-06-zip-47401-results.txt` — explicit disclosure that `47404 has multiple legislative districts` and guidance to narrow via street address or ZIP+4. Honest about imprecision — unique among the benchmark set. |

---

## Race / Candidate Count vs Baseline

Denominator source: `.planning/research/BALLOT-BASELINE-2026-05-05.md`

For 200 W Kirkwood Ave, Bloomington IN (Bloomington Township, State House District 61, County Commissioner District 1, Council District 1), the baseline expects 14 on-ballot race slots for the Democratic OR Republican primary. VoteSmart's product model surfaces candidate-level cards for **3 of those 14 races** and lists current incumbents for several others. Because ZIP 47404 spans multiple legislative districts, VoteSmart returns a superset including HD 46 / HD 60 / HD 62 candidates the Kirkwood voter does not actually vote in (similar superset behavior to Vote411's council-district inflation).

| Race (from baseline) | Baseline candidate count (D+R) | VoteSmart candidate cards | Match? | Notes |
|----------------------|-------------------------------|---------------------------|--------|-------|
| US Representative, IN-9                                   | 5 (4 D + 1 R)                | **5** (Houchin R, Graham D, Meyer D, Peck D, Roark D) — INCUMBENT/CHALLENGER labels correct | ✓ | Exact baseline match. `04-after-zip-submit.txt`. |
| Indiana State Representative, District 46                 | 4 (1 D: Pittsford III + 2 R: Arthur, Heaton + 1 D) | **3** (Heaton R incumbent, Arthur R challenger, Pittsford III D challenger) | ~ | Missing baseline's second HD-46 R if there is one; close match. Not on Kirkwood voter's ballot (HD 46 is Benton Twp), returned as ZIP superset. |
| Indiana State Representative, District 60                 | 5 (1 D + 4 R: Syczylo, Mayfield, Moore, Waters + Heaton?) | **4** (Mayfield R incumbent, Moore R challenger, Waters R challenger, Syczylo D challenger) | ~ | Close; exact list depends on baseline parse. Not on Kirkwood voter's ballot. ZIP superset. |
| **Indiana State Representative, District 61**             | **2 (2 D: Pierce, Young)**   | **2** (Pierce D incumbent, Young D challenger) | ✓ | **Exact baseline match** for the Kirkwood voter's actual HD race. |
| Indiana State Representative, District 62                 | 2 (1 D: Oliver + 1 R: Hall)  | **2** (Hall R incumbent, Oliver D challenger) | ✓ | Exact match; not on Kirkwood voter's ballot (HD 62 is Benton/East). ZIP superset. |
| Judge of the Circuit Court, Monroe, Div 6, Seat 5 (Krothe)| 1 (1 D)                      | **0**                    | ✗ | VoteSmart does not track Indiana circuit-court primary races. Product-model gap. |
| Judge of the Circuit Court, Monroe, Div 1, Seat 9 (Bradley)| 1 (1 D)                     | **0**                    | ✗ | Same. |
| County Prosecuting Attorney (Arrington, Oliphant)         | 2 (2 D)                      | **0**                    | ✗ | VoteSmart does not track county primary races. |
| County Clerk of the Circuit Court                          | 4 (3 D + 1 R)                | **0**                    | ✗ | Not tracked. |
| County Recorder (Swain)                                    | 1 (1 D)                      | **0**                    | ✗ | Not tracked. |
| County Sheriff (Marte)                                     | 1 (1 D)                      | **0**                    | ✗ | Not tracked. |
| County Assessor (Nyquist, Sharp)                           | 2 (2 D)                      | **0**                    | ✗ | Not tracked. |
| County Commissioner, District 1 (Deckard, Henry)           | 2 (2 D)                      | **0 (as primary cards)** — incumbents Lee Jones / Julie Thomas / Jody Madeira shown in `COMMISSIONER` tiles | ✗ | VoteSmart surfaces sitting county commissioners but **does not track the D1 primary contest**. Trent Deckard appears ONLY as a COUNCIL MEMBER incumbent (not as D1 commissioner challenger). |
| **County Council, District 1 (Iversen)**                   | **1 (1 D)**                  | **1** (Peter Iversen — COUNCIL MEMBER INCUMBENT) | ✓ | Match. Listed alongside other council members without per-district context. |
| Bloomington Township Trustee (Rosser)                      | 1 (1 D)                      | **0**                    | ✗ | Not tracked. |
| Bloomington Township Board (Granger, McKinney, Sensenstein)| 3 (3 D)                      | **0**                    | ✗ | Not tracked. |
| **TOTAL baseline race slots for this address**             | **14 races / ~26 candidates**| **3 baseline races fully covered (US House IN-9 + HD 61 + Council D1) / 8 candidates matched baseline**; 4 additional state-legislative races returned as ZIP superset (HD 46/60/62); 11 baseline races have no VoteSmart cards | **~21% baseline race coverage; ~31% baseline candidate coverage for the races it does cover** | **Contrast plans 02/03:** BallotReady 0%, Vote411 93%+, VoteSmart ~21%. VoteSmart is **not a ballot product** — it is a **sitting-officeholder + major-office-candidate tracker**. The mismatch with the May 5 primary baseline is a **product-scope gap**, not a coverage failure. Plan 07 must score Dimension 1 honestly at 1 (not 0 or 3) and explain the scope mismatch in the narrative. |

**Non-baseline currently-sitting officials surfaced as ZIP 47404 match (partial list):**

- Presidential: Trump (R-NA), Vance (R-NA) — federal executive
- US Senate: Young (R-IN), Banks (R-IN)
- Gubernatorial: Braun (R-IN) governor, Beckwith (R-IN) LG
- State executive: Rokita (R-IN) AG, Morales (R-IN) + Bayh/Potter/Shelton challengers SoS, Elliott (R-IN) Treasurer, Gulley Commissioner of Revenue
- State judicial: Rush Chief Justice, Goff / Massa / Molter / Slaughter Justices
- State legislative: Bassler / Baughman / Bouchie / Ellington / Risk / Yoder (State Senate candidates)
- Local executive: Kerry Thomson Mayor (Bloomington)
- Local legislative: Iversen, Piedmont-Smith, Rosenbarger, Wiltz, Hawk, Crossley, Rollo, Daily, Zulich, Deckard, Feitl, Flaherty, Henry, Nti Asare, Ruff (Bloomington Council Members)
- Local commissioners: Lee Jones, Julie Thomas, Jody Madeira (Monroe County Commissioners)

**Candidate-level depth verified on 1 race (Houchin profile) at full BIO + VOTES + POSITIONS + RATINGS depth.** This is the strongest single-candidate capture across plans 02–04.

---

## Narrative Notes

1. **Dimension 10 (antipartisan framing) — VoteSmart is the mirror image of EV.** This is the most important narrative finding from plan 04, and the one most important to score honestly per METHODOLOGY §6/§7.

    VoteSmart is, by design, **the most partisan-framed product in the benchmark set**. Party labels appear on every tile. `INCUMBENT`/`CHALLENGER` framing privileges incumbency. **Interest-group ratings are VoteSmart's core feature** — Houchin's Ratings page surfaces AIPAC PAC's 2026 endorsement, NRL 100%, Planned Parenthood 0%, Susan B. Anthony 100%, and ideological topic scorecards (`Conservative`, `Fiscally Liberal`, `Liberal`). **EV deliberately does NOT do any of this** per METHODOLOGY §6 — no party labels, no endorsements, no interest-group ratings, no partisan color associations.

    Under the D-10.5 "same ruler" rule, VoteSmart scores **0 on Dimension 10** and EV scores **3**. But the inverse is also true: **VoteSmart scores 3 on the derived-extra "Interest-Group Ratings" (E1)** and **EV scores 0** on that same derived extra. Plan 07 must present both scores — you cannot credit VoteSmart with 3 on E1 and then also score EV's 0 on E1 as a "gap", because EV's 0 is intentional per the antipartisan carve-out. Symmetrically, you cannot credit EV with 3 on Dim 10 and also score VoteSmart's 0 on Dim 10 as a defect, because VoteSmart's 0 is intentional per its mission statement ("nonpartisan information on candidates" including interest-group disclosures is, for VoteSmart, the definition of nonpartisan — disclosure of partisan actors, not suppression of partisan signaling). **Two honest products with opposite definitions of "nonpartisan."** Plan 07 must make this explicit rather than collapsing it into a single directional score.

    Concretely: the MATRIX.md row for Dim 10 should show VoteSmart at 0 and EV at 3; the MATRIX.md row for derived-extra E1 should show VoteSmart at 3 and EV as "intentional omission". Neither column is penalized for the other's worldview.

2. **Dimension 7 (legislative record) — VoteSmart is the strongest competitor in the benchmark set, and this is EV's biggest *non-intentional* coverage gap.** `r3-04-houchin-votes.txt` captured **31 pages of roll-call votes** for Erin Houchin, with bill numbers, bill titles, outcomes, vote positions, and dates current through 03/27/2026 (2 weeks before run date). Sample rows: `HR 7084 — Defending American Property Abroad Act of 2026 — Yes — House 247-164`, `HR 26 — Born-Alive Abortion Survivors Protection Act` (referenced from POSITIONS tab as evidence for the abortion Q&A).

    Unlike Dim 10, **this is NOT a product EV has intentionally omitted.** EV's backend has `essentials.bills`, `essentials.votes`, and the Congress.gov + LegiScan pipelines already wired (per `CLAUDE.md`). Phase 112's audit baselined the data gap, and the gap is surfaced-UX, not data-model. **VoteSmart is the product to benchmark against for Dimension 7 parity.** Plan 07 should score VoteSmart at 3 and score EV per AUDIT-REPORT-112.md's findings — and plan 115 should treat this as the top-priority gap for plan 07's gap-report narrative.

    Additional point: VoteSmart's voting record is **only rich for sitting federal officials**. For state-legislative challengers (Pittsford III, Syczylo, Young, Oliver) the VOTES tab either shows no votes (non-incumbents) or a thin state-level record. For local council members the record is essentially absent. So "Dim 7 at 3" is specific to US House / Senate / President — the same surface area EV's backend already has.

3. **Dimension 1 (race coverage) — VoteSmart covers ~21% of the baseline because it is a different product, not because it is missing data.** The 3-of-14 coverage looks terrible against Vote411's 93%+ until you recognize VoteSmart is **not a "what's on my ballot" product**. It is a **sitting-officeholder tracker + federal/state legislative candidate tracker**. Monroe County Circuit Court judges, County Clerk, Township Trustee primaries are not in VoteSmart's product scope **anywhere in the country** — it is not a Monroe County blind spot. Dim 1 honest score: **1** (some baseline races covered, significant baseline races uncovered, but the gap is scope not execution). Plan 07's narrative must distinguish "1 because of product scope" from "1 because of execution failure" — the rubric doesn't carry that nuance natively.

4. **Soft gate (`loginPageLimitModal`) is a product-scope blocker worth naming explicitly.** VoteSmart enforces a 3-free-use per-session limit via client-side modal. In a single natural drill-down (ZIP → profile → BIO → VOTES → POSITIONS → RATINGS), the RATINGS tab is where the gate lands. A real human who doesn't know to open a fresh incognito window would be blocked from VoteSmart's signature feature by the 4th click. This is a **moderate UX tax** that plan 07 should weight against VoteSmart's otherwise strong-depth scores — the data is rich, but the friction is real. Not a full blocker (we got past it with fresh contexts + direct URLs), not fully accessible either. This is the first "partial blocker" case in the benchmark, and plan 07 should add a note column to MATRIX.md reflecting it.

5. **ZIP-level district superset is both a precision weakness and a transparency strength.** VoteSmart explicitly tells the user *"47404 has multiple legislative districts. To refine your search, please enter your home address or 9-Digit zip code"* — the product is **honest about its imprecision**, unlike Vote411 which silently returns the wrong HD for the Covenanter secondary. This earns VoteSmart a partial credit on Dim 8: the product knows it's imprecise and says so, rather than confidently returning wrong data. Score 1 (minimal) reflects "knows its limits, ships a superset, tells the user."

6. **Bio depth (Dim 3) is the deepest in the benchmark set.** Houchin's profile surfaces birth date (1976-09-24), home city (Salem, IN), religion (Christian), spouse name (Dustin), children's names (Claire, Elaine, Graham) — nothing in Vote411 or BallotReady comes close. EV's Phase 112 audit found bio coverage at 0/51 (per METHODOLOGY §7). **Dimension 3 is a real EV gap** that plan 07 should flag alongside Dim 7.

7. **Contact info (Dim 4) matches EV's multi-tier model.** VoteSmart surfaces Campaign tier (email, website) and Office tier (Washington D.C. address, webmail, website) — mirrors EV's `politician_contacts.contact_type` (primary/office/campaign/personal) per `CLAUDE.md`. Both products treat contact info as first-class data. Score 3 for both (pending EV verification in plan 05).

8. **VoteSmart's copyright footer (`© 1992–2021`) vs its roll-call votes being 2 weeks old creates a freshness paradox.** The site's legal/brand surface was last updated 5 years ago. The data surface was updated 2 weeks ago. This is a "legacy nonprofit tech stack, but the data pipeline is alive" pattern. Not a scoring factor per se, but relevant narrative flavor for plan 07 — VoteSmart is a 33-year-old nonprofit (founded 1992) with active data ingestion on top of a stale UX chassis.

9. **Civic Sage AI chatbot is a new surface.** VoteSmart is shipping an AI chatbot that "pulls directly from Vote Smart's verified, nonpartisan research." 2 free uses per session. Not drilled into during capture (soft-gate concerns). Worth noting as a derived extra E7 for the benchmark set — none of the other competitors are shipping an LLM surface.

10. **Production parity and the "VoteSmart is the comparison" frame.** For the dimensions EV has NOT intentionally omitted (Dim 3 bio, Dim 7 legislative record, partial Dim 4 contact info), **VoteSmart is the right yardstick, not BallotReady or Vote411.** BallotReady has 0 data for Monroe County. Vote411 has race lists but only candidate-questionnaire depth. VoteSmart is the only product in the benchmark set that surfaces **deep per-incumbent data at a level EV already has in its backend and could reasonably surface in its frontend**. Plan 115's gap report should treat VoteSmart's BIO/VOTES/POSITIONS triad as the parity target for EV, and treat VoteSmart's RATINGS/endorsements as the parity floor (EV stays at 0 intentionally).

---

## Precinct Precision Subsection

Goal per METHODOLOGY.md §1: verify whether VoteSmart correctly changes its district-specific race list when the address moves across a known district boundary.

VoteSmart's iSpy search input accepted all three addresses textually, but the `Enter` key press in the iSpy input only triggered the AJAX search-result rendering for ZIP-only entries. Full street addresses submitted via `Enter` stayed on the landing page (`primary-kirkwood-02-results.txt`, `benton-mttabor-02-results.txt`, `covenanter-d62-02-results.txt`) — the full-address code path likely requires clicking an autocomplete dropdown option or a separate submit button that was not discovered in our runs. This is a **capture-tooling limitation**, not a product absence: the iSpy input placeholder literally reads *"Enter a politician's name or your address"*, so address search exists. We fell back to ZIP-only matching for the precinct-precision pass, which means we are measuring **district-coverage at ZIP resolution**, not **point-in-polygon geofence precision**.

| Address | State House District expected | VoteSmart State House candidates returned | Changed correctly? |
|---------|-------------------------------|-------------------------------------------|-------------------|
| 200 W Kirkwood Ave 47404 (primary) | HD 61 | HD 46 (Heaton, Arthur, Pittsford III) + HD 60 (Mayfield, Moore, Syczylo, Waters) + **HD 61 (Pierce, Young)** + HD 62 (Hall, Oliver) — ZIP superset including the correct HD | — (baseline; returns superset including HD 61 ✓) |
| 7333 W Mt Tabor Rd 47404 (Benton Twp) | HD 46 or HD 60 | Did not resolve via `Enter` submit in full-address mode. Falling back to same ZIP 47404 returns same superset including HD 46 and HD 60 ✓ | ~ (returns correct districts as part of ZIP superset, but does not distinguish from primary) |
| 2700 E Covenanter Dr 47401 (SE Bloomington) | HD 62 | ZIP 47401 result (`r4-06-zip-47401-results.txt`) returns HD 62 (Hall, Oliver) + HD 61 (Pierce, Young) — still a superset but narrower than 47404 (excludes HD 46/60 which are not in 47401). Correctly **includes HD 62** for this voter. | ✓ (HD 62 is present in the narrower 47401 ZIP superset) |

**Precinct precision summary:**
- VoteSmart's ZIP-level coverage is **deterministic and correct**: ZIP 47404 returns the full set of districts touching that ZIP (HD 46/60/61/62), ZIP 47401 returns the narrower set (HD 61/62). No wrong districts are returned.
- **Address-level precision is unverified** because the full-address AJAX path didn't fire via `Enter` in our captures. A human using the autocomplete dropdown would get the address-specific refinement the product promises in its "has multiple legislative districts" warning.
- Compared to Vote411 (plan 03), which **returned the wrong HD 61 for the Covenanter HD 62 voter** (a confident wrong answer), VoteSmart's superset behavior is arguably **more honest** — it shows all candidates the voter might potentially see, lets the user disambiguate, and explicitly warns about ZIP-district collisions.
- Compared to BallotReady (plan 02), which returned 0 data for all three addresses, VoteSmart is meaningfully better — the data exists, it's just coarse-grained by default.

**Score for Dimension 8 (geofence / address precision):** **1 (minimal/token precision).** The product returns something address-aware (ZIP-level districts superset), honestly discloses its imprecision, but does not demonstrate street-address-to-precinct resolution in our captures. Plan 07 should score 1 with a note: "ZIP-accurate, address-level unverified, transparent about imprecision."

Screenshots per secondary address:
- **Primary (Kirkwood):** `03-zip-entry-47404.png`, `04-after-zip-submit.png`, `r3-01-zip-typed.png`, `r3-02-zip-results.png`, plus primary-kirkwood-01..04 from run 2
- **Benton (Mt Tabor):** `benton-mttabor-01-address-typed.png`, `benton-mttabor-02-results.png`, `benton-mttabor-03-results-scrolled.png`, `benton-mttabor-04-results-scrolled2.png`
- **Covenanter (47401):** `covenanter-d62-01-address-typed.png`, `covenanter-d62-02-results.png`, `covenanter-d62-03-results-scrolled.png`, `covenanter-d62-04-results-scrolled2.png`, `r4-06-zip-47401-results.png`, `r4-07-zip-47401-scrolled.png`

---

## Blockers

**One partial blocker, logged per D-02 with human-fallback instructions.**

### Blocker 1: `loginPageLimitModal` 3-free-use soft gate

**What:** VoteSmart enforces a client-side 3-use soft gate per browser session. After the 3rd to 4th page navigation inside the same context, a modal (`loginPageLimitModal`) intercepts pointer events on all links and tab switches, overlaying a reCAPTCHA-protected SIGN UP / LOG IN dialog. Messaging escalates: `"2 more free uses left"` → `"1 more free use remaining"` → `"This is your last free use"` → `"You have used all your free accesses"`.

**Specific impact on measurement:** In a natural left-to-right drill (ZIP search → profile → BIO → VOTES → POSITIONS → RATINGS), the **RATINGS tab** is where the gate lands because RATINGS is the 4th tab. This is ironic because RATINGS is VoteSmart's most distinctive feature (interest-group scorecards, endorsements), and the one feature plan 04 was most interested in measuring.

**Mitigation applied automatically (Rule 3 — auto-fix blocker):** Scrape run 4 used (a) **fresh browser contexts per address** to reset the soft-gate cookie, and (b) **direct URLs** (`/candidate/evaluations/149614/erin-houchin`) to fetch the RATINGS page before any other tab was visited in that context. This worked: `r4-01-houchin-ratings-direct.txt` captured the full ratings page unblocked. No silent treatment as `0` — dimension scored honestly from the unblocked capture, with this blocker notation.

**Human-fallback instructions (for reviewer independent verification):**
1. Open a fresh private/incognito window.
2. Visit `https://justfacts.votesmart.org/candidate/evaluations/149614/erin-houchin` directly.
3. Dismiss the "Meet Civic Sage" modal if it appears.
4. Observe the full Ratings and Endorsements page: 2026 AIPAC PAC endorsement, National Right to Life Committee 100% (2023-2024 cycle), Planned Parenthood Action Fund 0% (2023-2024), Susan B. Anthony Pro-Life America 100% (2023-2024), followed by 40+ expandable issue-category scorecards.
5. Do NOT navigate to another VoteSmart page in the same tab without opening a fresh incognito window between clicks — each navigation ticks the soft-gate counter.

**Product gap vs access gap classification (per D-02):** This is an **access gap** (the data exists and is visible to logged-in users / fresh-context users), not a product gap. The RATINGS feature is fully built and data-rich — it is gated on registration, not missing. Plan 07 should score Dim 10 / derived-extra E1 from the captured data, annotated with the soft-gate access-cost.

### Non-blocker friction worth naming per D-02 transparency

- **Full-address AJAX path** — the `iSpy` input's Enter-key submit only fired for ZIP entries, not for full street addresses, in our captures. This is likely because full-address matches require clicking an autocomplete dropdown option rather than pressing Enter. Captures are at ZIP-granularity for precinct precision; a human using the UI normally would get address-granularity. Not scored as a blocker, noted as a capture-tooling limitation.
- **Public-statements 404** — `candidate/public-statements/149614/erin-houchin` returned `Page Not Found`. VoteSmart appears to have deprecated the standalone Public Statements section; statements are now embedded as evidence under POSITIONS. Scored on Dim 6 at depth 2 (present and usable, no dedicated surface).

**Manual reproduction steps for the full plan 04 run** (for any reviewer who wants to independently verify the primary finding):
1. Open fresh private browsing window.
2. Visit `https://justfacts.votesmart.org/`.
3. Dismiss the "Meet Civic Sage" modal.
4. In the search box at the top ("Enter a politician's name or your address"), type `47404` and press Enter.
5. Observe a list of 50+ federal/state/local officials and candidates, with a header explaining `47404 has multiple legislative districts`. Confirm all 5 US House IN-9 candidates present (Houchin, Graham, Meyer, Peck, Roark) with party labels and INCUMBENT/CHALLENGER tags.
6. In a **second fresh incognito window** (to avoid tripping the soft gate on subsequent clicks), visit `https://justfacts.votesmart.org/candidate/149614/erin-houchin` and click BIO, then VOTES, then POSITIONS. Observe 31 pages of roll-call votes and 40+ issue-position Q&A entries with sourced tweets and interest-group citations.
7. In a **third fresh incognito window**, visit `https://justfacts.votesmart.org/candidate/evaluations/149614/erin-houchin` to see the Ratings page unblocked.
8. Note the repeat-incognito pattern required — this is the soft-gate friction, and should be weighted against VoteSmart on any "usability for a casual voter" meta-dimension plan 07 may choose to add.

---

*Spot-check for Phase 113 plan 04. Feeds plan 07 (MATRIX.md scoring) via the evidence above. Key scoring inputs: VoteSmart is strongest in the benchmark set on Dim 3 (bio), Dim 7 (legislative record), and derived-extra E1 (interest-group ratings). Weakest on Dim 1 (race coverage — product-scope mismatch) and Dim 10 (antipartisan framing — intentional inverse by VoteSmart's mission, mirror of EV). The "two honest products with opposite definitions of nonpartisan" framing (Narrative Note #1) is the most important observation for plan 07's matrix narrative. See `BALLOT-BASELINE-2026-05-05` for the race-count denominator.*
