# BallotReady — Spot Check

**Run date:** 2026-04-12
**Primary address:** 200 W Kirkwood Ave, Bloomington, IN 47404
**Secondary addresses:**
- 7333 W Mt Tabor Rd, Bloomington, IN 47404 (Benton Twp — State House 46/60 boundary test)
- 2700 E Covenanter Dr, Bloomington, IN 47401 (southeast Bloomington — State House 61/62 boundary test)
**Tooling:** Playwright (Chromium 1208) driven from a one-shot Node script, headless. No signup, no captcha, no paywall encountered at any step.
**Evidence directory:** `.planning/research/benchmark/screenshots/ballotready/` (27 PNGs + matching `.txt` page dumps)

---

## Access Status

**`accessible`** — BallotReady was fully reachable without any signup wall, captcha, paywall, region gate, or rate limit. Address submission on `https://www.ballotready.org/` successfully redirected to the authenticated-feeling-but-unauthenticated consumer product at `https://app.ballotready.org/civic_center/` on the first try, for all three addresses.

**Critical framing:** This is NOT a blocker case under D-02. Nothing blocked measurement. What we observed is **the measured product state**: BallotReady's consumer-facing product returns effectively zero ballot / race / candidate data for Monroe County, Indiana addresses in April 2026, one month before the May 5, 2026 Indiana Primary. This is a product gap, not an access gap.

One nuance: BallotReady's state-level marketing page at `https://www.ballotready.org/us/indiana` DOES advertise "More than 2,260 positions are up for election" for the 2026 Indiana Primary, so the data clearly exists at some aggregate level inside BallotReady — it is simply not surfaced to the personalized consumer view when fed a Monroe County address. Attempted county/city drill-down paths (`/us/indiana/counties/monroe`, `/us/indiana/bloomington`) both return "Page Not Found".

---

## Field Inventory

Scoring uses the 0–3 rubric from `METHODOLOGY.md` §2. Blockers are distinct from `0` and are not used here — none were encountered.

| # | Field (METHODOLOGY.md core dimension) | Present? | Depth (0–3) | Evidence |
|---|---------------------------------------|----------|-------------|----------|
| 1 | Race coverage vs baseline              | N        | **0**       | `primary-02-office-holders.png` + `tab-{federal,state,local}.png` — every tab renders "There is no office holder information available at this level." 0/43 baseline races surfaced. |
| 2 | Candidate photo                        | N        | **0**       | No candidates shown anywhere for the primary address → no photos to score. No placeholder silhouettes, no empty cards — just "no information." |
| 3 | Candidate bio / biography prose        | N        | **0**       | No candidate profiles reachable. |
| 4 | Candidate contact info                 | N        | **0**       | No candidate profiles reachable. |
| 5 | Stance / issue position data           | N        | **0**       | No candidate profiles reachable. |
| 6 | Candidate quotes / Q&A / statements    | N        | **0**       | No candidate profiles reachable. |
| 7 | Legislative record                     | N        | **0**       | No office holder profiles surfaced for sitting federal/state/local officials representing 200 W Kirkwood. |
| 8 | Geofence / address precision           | N        | **0**       | Three different Monroe County addresses (downtown Bloomington, rural Benton Twp, southeast Bloomington) all produce identical "no information" civic centers. Precision cannot be differentiated from zero data. See "Precinct Precision" section below. |
| 9 | Data freshness                         | N        | **0**       | No last-updated timestamps visible because no records are rendered. Copyright footer reads "© 2026 BallotReady" across all pages — a site-wide string, not a per-record freshness signal. |
| 10| Antipartisan framing (**inverted** — higher = more antipartisan) | Y | **3** | No party labels, no endorsement lists, no interest-group ratings, no donor totals, no red/blue coloring anywhere on the user-facing `civic_center` views. This is trivially "3" because there is no candidate content to partisan-label in the first place. Caveat: the `actions` page (`app-actions.png`) surfaces third-party partner CTAs one of which explicitly labels itself *"(partisan - left)"* (Oath political giving tool) — that is BallotReady choosing to feature a partisan partner, though it is in the "take action" area, not in ballot/candidate content. Score held at 3 on the ballot-data surface; noted as a nuance. |

### Derived extras (not part of core 10)

| # | Field (extra) | Present? | Depth | Evidence |
|---|---------------|----------|-------|----------|
| E1 | Voter registration check-and-update  | Y | 3 | `app-check_registration.png` — address pre-filled, next-step flow for registering, updating, or checking status. Actually works. |
| E2 | "Run for office" open-positions lookup | Y | 2 | `app-run.png` — address + year form ("2026") → "Find a Position" button. Present and interactive; output not explored. |
| E3 | Partner action directory              | Y | 2 | `app-actions.png` — curated list of third-party civic-action partners (League of Conservation Voters, United We Dream Action, Supermajority, Oath, ActiVote, etc.) with "Learn more" links. This is BallotReady's curated civic-engagement directory, not ballot data. |
| E4 | State-level voter guide marketing     | Y | 2 | `10-indiana-state.png` / `10-indiana-state.txt` — static state landing at `/us/indiana` claims "2,260 positions up for election" with important dates, but is not personalized to the user's address. |
| E5 | County / city drill-down              | N | 0 | `/us/indiana/counties/monroe` and `/us/indiana/bloomington` both return "Page Not Found" (`11-monroe-county.png`, `12-monroe-bloomington.png`). County-level public browse is not supported. |
| E6 | Polling place lookup                  | N | 0 | Civic center lists "Find your polling place" as **"Coming soon!"** for the Kirkwood address (`primary-01-civic-center.png`, `primary-01-civic-center.txt`). |
| E7 | Absentee / mail-ballot request        | N | 0 | Civic center lists "Request a ballot" as **"Coming soon!"** for the Kirkwood address (same screenshot). |
| E8 | Email capture / newsletter gate       | Y | — | Landing form at `www.ballotready.org` has a co-located `Email` input marked "Sign up to receive updates and info about upcoming elections" — the address field is paired with a marketing signup field. Signup is **not required** to proceed (we left email blank and still got redirected to the civic center). Noted as a UX nuance, not a blocker. |

---

## Race / Candidate Count vs Baseline

Denominator source: `.planning/research/BALLOT-BASELINE-2026-05-05.md`

For 200 W Kirkwood Ave, Bloomington IN (Bloomington Township, State House District 61, County Commissioner District 1), the baseline expects the following races for a Democratic OR Republican primary ballot:

| Race (from baseline) | Baseline candidate count (D+R) | BallotReady candidate count | Match? | Notes |
|----------------------|-------------------------------|----------------------------|--------|-------|
| US Representative, IN-9                                                | 5 (4 D + 1 R)                 | 0                          | N | Product returns "no office holder information" for Federal tab. |
| Indiana State Representative, District 61                              | 2 (2 D + 0 R)                 | 0                          | N | State tab returns "no office holder information." |
| Judge of the Circuit Court, Monroe, Div 6, Seat 5                      | 1 (1 D + 0 R)                 | 0                          | N | — |
| Judge of the Circuit Court, Monroe, Div 1, Seat 9                      | 1 (1 D + 0 R)                 | 0                          | N | — |
| County Prosecuting Attorney                                            | 2 (2 D + 0 R)                 | 0                          | N | — |
| County Clerk of the Circuit Court                                      | 4 (3 D + 1 R)                 | 0                          | N | — |
| County Recorder                                                        | 1 (1 D + 0 R)                 | 0                          | N | — |
| County Sheriff                                                         | 1 (1 D + 0 R)                 | 0                          | N | — |
| County Assessor                                                        | 2 (2 D + 0 R)                 | 0                          | N | — |
| County Commissioner, District 1                                        | 2 (2 D + 0 R)                 | 0                          | N | — |
| County Council, District 1 (Kirkwood precinct)                         | 1 (1 D + 0 R)                 | 0                          | N | — |
| Bloomington Township Trustee                                           | 1 (1 D + 0 R)                 | 0                          | N | — |
| Bloomington Township Board                                             | 3 (3 D + 0 R)                 | 0                          | N | — |
| **TOTAL baseline race slots for this address (both parties)**          | **14 races / ~26 candidates** | **0 races / 0 candidates** | **N** | **match-rate: 0%** |

**Match rate: 0 / 14 races (0%).**

Note on denominator: the baseline enumerates ~43 distinct race slots county-wide. An individual Bloomington-Township/HD-61/Council-District-1 voter sees roughly 14 of those on their actual ballot (the subset above). BallotReady returns 0 of the 14. Scoring Dimension 1 "race coverage vs baseline" at **0** is correct under the rubric: "absent — field/feature not present at all."

---

## Narrative Notes

1. **"Coming soon!" is the story.** The single most informative signal on the BallotReady consumer product for Monroe County right now is the phrase *"Coming soon!"* appearing next to **"Find your polling place"** and **"Request a ballot"** on the civic center page. This is 3.5 weeks before the May 5, 2026 Indiana Primary. For a product whose brand is "Where you go before you vote" — as printed on the landing-page headline — the timing is conspicuous. See `primary-01-civic-center.png`.

2. **State-level aggregate exists; personalized view does not.** The static `/us/indiana` marketing page advertises "2,260 positions up for election" in the 2026 Indiana Primary, with correct registration deadlines, absentee-request deadlines, and early-vote windows. So BallotReady's editorial team has done Indiana-level content work. But the address-fed `civic_center` → `office_holders` route returns zero records. This smells like a product where the state-level landing pages are populated for SEO / marketing but the address-to-race binding pipeline (geocode → district match → filtered race list) is not lit up for Indiana yet, or is lit up only for states BallotReady has active organizational customers in.

3. **County/city public-browse is not supported.** `/us/indiana/counties/monroe` and `/us/indiana/bloomington` both 404. This means a voter cannot get around the empty civic-center result by navigating by place name. The only personalized view is the address-in-form flow, and that view is empty for Monroe County.

4. **UX quirks on the address form.** The landing address input is co-located with an `Email` input labeled "Sign up to receive updates and info about upcoming elections." Ordering: address → email → submit. The email is optional (we left it blank and the redirect still worked). But visually, a less technical user would reasonably assume signup is required, which could depress conversions into the (currently empty) product. Also, the input's placeholder reads `1452 E 53rd St, Chicago, IL` — BallotReady's Chicago origin showing, harmless but noteworthy.

5. **Autocomplete works; redirect is good.** Two autocomplete options appeared when we typed the primary address; selecting the first one and then submitting correctly redirected to `app.ballotready.org/civic_center/`. The geocoding front-end is working fine — the back-end race resolver is what is empty.

6. **"Actions" page is where the product actually has content.** Of the four tiles on the civic center (`Get ready to vote`, `Get set to go`, `Take action`, `Talk to friends and family`), only "Take action" has substantive content (`app-actions.png`) and it is a curated list of third-party civic-engagement partners. One of them, Oath, is labeled *"(partisan - left)"* in BallotReady's own copy — relevant to Dimension 10. This is an interesting editorial choice for a product that brands itself as non-partisan on its homepage ("Sharing BallotReady, a great nonpartisan resource" per `primary-01-civic-center.txt`). The partisan label on a featured partner stays out of the ballot-data surface, so Dimension 10 is still 3 for ballot data, but it is a notable editorial nuance.

7. **Data freshness signals are absent.** No "last updated" timestamps were visible anywhere in the civic center. Freshness cannot be assessed from the product surface for Monroe County in April 2026.

8. **Comparison framing for plan 07.** Any matrix row that gives BallotReady credit for Monroe County coverage needs to be sourced to the state-level marketing claim ("2,260 positions"), not to anything actually rendered for a Monroe County address. Plan 07's synthesis should flag this explicitly: BallotReady has Indiana data somewhere, but the consumer product cannot show it to a Monroe County voter as of the run date.

9. **Not a privacy-gate product.** Unlike what we anticipated going into this plan (BallotReady being "the competitor most likely to require signup"), signup was fully optional. The `autonomous: false` precaution for this plan turned out to not be needed — but the underlying D-02 rule (distinguish product gap from access gap) was critical to apply correctly, because the obvious mis-reading would have been to log the empty civic center as a "blocker." It is not a blocker — BallotReady let us in freely and then showed us nothing.

---

## Precinct Precision Subsection

Goal per METHODOLOGY.md §1: verify whether BallotReady correctly changes its district-specific race list when the address moves across a known district boundary.

| Address | State House District expected | BallotReady office_holders output | Civic Center output | Changed correctly? |
|---------|-------------------------------|-----------------------------------|---------------------|-------------------|
| 200 W Kirkwood Ave, Bloomington 47404 (primary)        | HD 61 | "No office holder information available" (All/Federal/State/Local) | Empty — "Coming soon!" on polling / ballot | — (no data to compare) |
| 7333 W Mt Tabor Rd, Bloomington 47404 (Benton Twp)     | HD 46 or HD 60 (crosses boundary) | Identical empty state | Identical empty state | **Cannot be verified — product returns zero race data for all three addresses.** |
| 2700 E Covenanter Dr, Bloomington 47401 (SE Bloomington) | HD 62 (opposite side of 61/62 line from Kirkwood) | Identical empty state | Identical empty state | **Cannot be verified — product returns zero race data for all three addresses.** |

**Score for Dimension 8 (geofence/address precision):** **0** — not because BallotReady got precision wrong, but because there is zero race data to move. This is a strictly worse outcome than "showed the same race list for all three addresses" (which would score 1 — detectably broken precision). BallotReady showed *nothing* for all three. Precinct precision is therefore **unobservable**, which under the rubric collapses to 0 because the field is absent, not because precision is mis-implemented.

Screenshots per secondary address:
- `secondary-benton-01-civic-center.png`, `secondary-benton-02-office-holders.png`
- `secondary-d62-01-civic-center.png`, `secondary-d62-02-office-holders.png`

All four render the same "There is no office holder information available at this level" copy as the primary.

---

## Blockers

None. No signup wall, captcha, paywall, region gate, rate limit, or geo-block was encountered at any point in the Playwright session. All three addresses successfully submitted and redirected to the civic center view. All tabs rendered. All referenced app pages (office_holders, actions, run, check_registration) loaded.

**Important per D-02:** The empty civic center views documented above are **product gaps**, not access gaps. A human running the same flow manually would see the same empty state. There is therefore no human-fallback instruction required — a human session would not produce different output from the Playwright session.

If a reviewer wants to re-verify manually, the reproduction steps are:
1. Visit `https://www.ballotready.org/`.
2. Enter `200 W Kirkwood Ave, Bloomington, IN 47404` in the Address field. Leave Email blank.
3. Click "Submit".
4. Confirm redirect to `https://app.ballotready.org/civic_center/`.
5. Observe "Find your polling place" and "Request a ballot" tiles marked "Coming soon!".
6. Click "Meet your representatives" → confirm "There is no office holder information available at this level." on All/Federal/State/Local tabs.
7. Repeat for the two secondary addresses and confirm identical output.

---

*Spot-check for Phase 113 plan 02. Feeds plan 07 (MATRIX.md scoring) via the evidence above.*
