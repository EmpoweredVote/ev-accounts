# Emerson Levy (D) — Oregon House District 53 — research notes

- external_id `-4120053`; OLIS `LegislatorCode` / `VoteName` = **`Rep Levy E`**
- Sworn in **2023-01-09** (confirmed on Wikipedia). Eligible sessions used: **2023R1, 2024R1,
  2024S1, 2025R1, 2025S1, 2026R1**. No pre-2023 measure is cited anywhere in `levy.json`.
- District confirmed in her own op-ed byline block: "State Rep. Emerson Levy is a Democrat
  representing House District 53, which includes Bend, south Redmond, Tumalo and Sisters."
  (Bend Bulletin, 2023-03-10.) **Deschutes County, not Clackamas/Lake Oswego.**

## Result

**14 stances written**, 6 with a verbatim quote. All 33 distinct source URLs HTTP-200 verified
after the file was written. Every quote was re-fetched with `curl` from a clean session and
string-matched (whitespace-normalised) against the page body — see "Quote provenance" below.

| topic_key | value | primary evidence |
|---|---|---|
| abortion | 1 | HB 2002 2023R1 Aye (concurrence 6/21/23) + HB 4127 2026R1 Aye + campaign quote |
| healthcare | 2 | HB 4113 2024R1 chief sponsor + floor carrier; HB 2010 2025R1 Aye |
| housing | 2 | SB 611 2023R1 Aye; HB 2001 2023R1 Aye + member sponsor; own op-ed |
| rent-regulation | 2 | SB 611 2023R1 Aye; HB 3054 2025R1 Aye |
| residential-zoning | 4 | HB 2138 2025R1 Aye ×2; HB 3197 2023R1 Aye |
| climate-change | 3 | HB 3409 2023R1 sponsor+Aye; HB 4102 2024R1 sponsor+Aye; 4 chief-sponsored 2025R1 energy bills |
| childcare | 3 | HB 3005 / HB 3235 2023R1 Aye; HB 2727 2023R1 + HB 3560 2025R1 sponsor+Aye |
| homelessness-response | 2 | own op-ed; HB 3644 2025R1 Aye; HB 3970 2025R1 + HB 4149 2026R1 chief sponsor & floor carrier |
| data-centers | 2 | HB 3546 2025R1 (POWER Act) Aye ×2; HB 3792 2025R1 Aye |
| campaign-finance | 2 | HB 4024 2024R1 Aye; HB 4018 2026R1 **Nay** on final passage |
| voting-rights | 1 | HB 2107 2023R1 Aye (automatic voter registration extension) |
| local-immigration | 1 | HB 4114 / HB 4111 / HB 4079 all 2026R1 Aye |
| growth-and-development | 3 | HB 3620 + HB 3628 2023R1 chief sponsor; campaign infrastructure plank |
| transportation-priorities | 3 | campaign quote; HB 4103 2024R1 chief sponsor; HB 4007 2026R1 Aye |

## Sources fetched

**Primary / authoritative (individual votes and sponsorships)**

- **OLIS OData API** — `https://api.oregonlegislature.gov/odata/odataservice.svc/` (live, no auth,
  `$format=json`). This is the single most valuable Oregon source and it is fully `curl`-able:
  - `Legislators?$filter=FirstName eq 'Emerson'` → confirmed `LegislatorCode` = `Rep Levy E`,
    HD 53, Democrat, sessions 2023I1 → 2026R1.
  - `MeasureVotes?$filter=SessionKey eq '<S>' and VoteName eq 'Rep Levy E'` → **1,947 individual
    vote records** across her six voting sessions (1,739 Aye, 93 Nay, 82 Excused, 33 Excused for
    Business). One row per legislator per roll call, with `ActionText` and `ActionDate`.
  - `MeasureSponsors?$filter=LegislatoreCode eq 'Rep Levy E'` (note the API's misspelling of
    `Legislatore`) → **235 sponsorships**, `SponsorLevel` = Chief or Regular.
  - `Measures?$filter=SessionKey eq '<S>'` with `$select=...,RelatingTo,ChapterNumber,MeasureSummary`
    → full catch-line + summary + chaptered-law number for every measure, used to join subjects
    onto her votes.
- OLIS measure overview pages (`olis.oregonlegislature.gov/liz/<session>/Measures/Overview/<M>`) —
  all cited ones return 200; used as the human-readable citation alongside the API vote URL.

**Her own words**

- `https://emersonvotes.com/priorities/` — campaign platform. Sections *Reproductive Rights*,
  *Environment + Energy*, *A Thriving Economy for all*, *Health + Public Safety*, and
  *Transportation Safety* are **first person**; the *Housing* section is written in the **third
  person** and was therefore not used as a quote.
- Bend Bulletin guest column **by Emerson Levy**, 2023-03-10, "Legislature's affordable housing and
  houseless response package is a big step toward stability". The live URL now **302s to the
  Opinion section landing page** (article body gone), so the cited source is the Wayback capture
  `web.archive.org/web/20230327134004/...`, which contains the full body.
- KTVZ, 2024-02-10/13, "'Not a political issue. It's a human issue': Rep. Emerson Levy introduces
  bill to lower prescription drug costs" — contains two direct quotes from her committee testimony.
- `https://en.wikipedia.org/wiki/Emerson_Levy` — term start, biography, election results only.

**Fetched but not usable / dead ends**

- `oregonlegislature.gov/LevyE` and its `Pages/{biography,news,legislative-accomplishments}.aspx`
  render as SharePoint chrome with **no body content** over `curl` — contact block only.
  `Pages/newsletters.aspx` and `Pages/Newsroom.aspx` 404.
- `oregonlegislature.gov/levy` (no `E`) is **Bobby Levy (R, HD 58)** — a different legislator. Her
  OLIS code was `Rep Levy` through 2022R1 and became `Rep Levy B` in 2023 when Emerson arrived.
  Any name-only match on "Levy" in Oregon data is a wrong-person trap.
- `emersonlevy.com`, `emersonforOregon.com`, `levyfororegon.com` — do not resolve. Correct campaign
  domain is **`emersonvotes.com`** (found via Mojeek).
- `html.duckduckgo.com` served a **CAPTCHA**. `mojeek.com/search?q=` worked first try and is the
  better search tool for this jurisdiction.
- `emersonvotes.com` is behind **mod_security**: a bare or short `User-Agent` gets
  `406 Not Acceptable` on `*-sitemap.xml` while returning 200 on HTML pages. Send a full desktop
  Chrome UA for everything on that host.
- `bendbulletin.com/search/?q=` → 404; the working form is `bendbulletin.com/?s=Emerson+Levy`, but
  it surfaced nothing newer than Dec 2024, so no 2025–26 local coverage was located.

## OLIS votes I could and could NOT individually confirm

**Confirmed as her own recorded vote** (each has a per-legislator `MeasureVotes` row; the API URL
in `levy.json` re-runs the exact query): HB 2002, HB 2107, HB 2001, SB 611, HB 3409, HB 3179,
HB 3005, HB 3235, HB 2727, HB 3197 (all 2023R1); HB 4024, HB 4113, HB 4102, HB 4103 (2024R1);
HB 2138, HB 3054, HB 3546, HB 3792, HB 2010, HB 3644, HB 3970, HB 3560, SB 688 (2025R1);
HB 4018, HB 4114, HB 4111, HB 4079, HB 4127, HB 4149, HB 4007 (2026R1). Also HB 3991 and HB 3992
(2025S1 transportation/budget special session), Aye on both.

**Could NOT confirm individually:**

- **HB 2002, 2023R1 initial House third reading (2023-05-01).** The API holds her Nay on all seven
  referral/postponement motions that day but **no third-reading roll-call row for her**; the only
  third-reading row set for that measure is a 30-member (Senate) tally dated 2023-06-15. What is
  confirmed is her **Aye on the House concurrence-and-repassage vote of 2023-06-21**, which is the
  final House action on the bill, and that is what the reasoning cites.
- **HB 3986, 2025R1** (renewable-energy siting on farmland) — she is the **chief sponsor**, but
  there is **no floor vote record for her** on it; cited as sponsorship only, never as a vote.
- **HB 3620 / HB 3628, 2023R1** — chief sponsorships that never reached a floor vote (no chapter
  number). Cited as sponsorship only.

**Vote-reading trap noted:** many of her Nay votes are on *procedural* motions ("Motion to refer to
Rules failed", "Motion to substitute Minority Report failed"), where a Nay means she was **defending**
the bill. On HB 3054 and HB 2107 she is recorded Nay on the referral motion and Aye on passage of the
same measure the same day. Do not read a bare Nay as opposition without reading `ActionText`.

## Topics deliberately skipped (11 of 25)

| topic_key | why skipped |
|---|---|
| taxes | Every revenue bill she voted on is technical (erroneous-material fixes, sunset extensions, estate-tax natural-resource treatment, credit alignment). Nothing on the raise-vs-cut axis. |
| fossil-fuels | Axis is drilling/extraction permits. Oregon has effectively none; her energy work is generation-side. HB 3520 (pipeline setback notification) is not a permitting stance. |
| local-environment | Axis is green space / tree preservation as a condition of development approval. Her only adjacent evidence is the tree-canopy and green-infrastructure grant components inside HB 3409 — not a development-review position. Campaign language ("manage our resources well") is too vague. |
| civil-rights | Votes are narrow and administrative (school civil-rights coordinators, removing discriminatory deed language, tribal consultation). Nothing on the equity-mandate-to-colorblind axis. |
| trans-athletes | No evidence at all. HB 4119 (2024R1) and HB 3694 (2025R1) are name/image/likeness compensation bills, not gender-eligibility bills — an easy false positive on the phrase "student athletes". |
| school-vouchers | Assigning chair 1 would require the "eliminating voucher programs" half; Oregon has no voucher program and she has never spoken to one. Her public-school-funding and special-education-cap positions do not answer the voucher question. Her charter-school votes (HB 3204, SB 767, HB 3953) are not a voucher stance. |
| homelessness (criminalization) | No vote or statement on camping bans, citations, or enforcement conditioned on shelter availability. Her homelessness record is all shelter/services, which is scored under `homelessness-response` instead. |
| public-safety-approach | Axis is police funding/operations. Her material (mental-health capacity in Deschutes County, HB 2757 9-8-8 crisis funding) is on behavioral-health capacity, not on the police budget — using it would violate the same-axis rule. |
| jail-capacity | No evidence. |
| economic-development | Chairs 3 and 4 both fit and neither dominates: she was a member sponsor of the semiconductor package (HB 4154, 2024R1 — targeted industry incentive, chair 3) while also touting the $1B Hydrogen Hub and active recruitment of new-energy employers (chair 4). Adjacent chairs → skip. |
| redistricting | No evidence. |

## Ambiguity flags carried in `reasoning`

Two rows name their own weak spot in the reasoning text so a reviewer can down-rank them:

- **voting-rights = 1** — HB 2107's automatic voter registration is the defining chair-1 mechanism,
  and chair 2's markers (no-excuse mail, expanded early voting) are already universal in Oregon so
  she has nothing to expand there. But chair 1 also says "allow online voting", on which she has
  **no record**. Flagged in the reasoning.
- **local-immigration = 1** — her three 2026R1 votes clearly push past Oregon's baseline
  non-cooperation statute (chair 3), but **none of them addresses ICE detainers**, which is chair 1's
  first clause. The detainer element is read from direction of travel, not documented. Flagged.

`data-centers = 2` is a half-match by construction: HB 3546 does exactly chair 2's second clause
(barring cost pass-through to other ratepayers) and none of its first clause (dedicated generation).
Chair 3's approval-stage conditions are not what she voted for, so 2 is the closest chair.

## Quote provenance (why each quote, and what was edited)

All six are **verbatim, contiguous plain text in the raw HTML with no intervening markup** — checked
by `grep -o` on the raw byte stream, then re-checked after `levy.json` was written by re-fetching
each source in a fresh session and substring-matching. No `quote_deidentified` needed edits: none
contains a speaker name, office claim, party tell, or named third party, so each is identical to its
`quote_text` (nothing was cut, so no `…` and no `[brackets]`).

- **abortion** — two consecutive sentences from the *Reproductive Rights* plank. Forward-looking
  ("I will always protect"), directly on the legal-framework axis, no personal attack. The
  preceding sentence ("I am the only pro-choice candidate in this race") was **deliberately
  excluded**: it is a comparative claim about opponents, not a position.
- **healthcare** — from her Feb 2024 testimony to the House Committee on Behavioral Health and
  Health Care as quoted by KTVZ. Chosen because it states the *mechanism* (make purchased private
  insurance actually usable) that distinguishes chair 2 from chair 1.
- **housing** — from her own op-ed. Chosen over the adjacent "I'm proud to support HB 2001 and 5019"
  sentence, which is a record claim rather than a forward position.
- **climate-change** — one sentence only. The sentence before it ("I have been a champion of…") is
  self-touting record and the sentence after it names her committee vice-chairmanship — both would
  fail the forward-not-record and self-ID tests, so the quote was cut to the single forward clause.
  Thin on its own; the reasoning carries the specificity.
- **homelessness-response** — from her own op-ed; names shelter capacity + rehousing + prevention as
  the strategy, which is exactly what separates chair 2 from chair 1.
- **transportation-priorities** — three consecutive sentences from the *Transportation Safety* plank.
  "Deschutes County" is a bare place name and is retained per the de-identification rules.

**No quote for the other 8 rows.** For `rent-regulation`, `residential-zoning`, `data-centers`,
`campaign-finance`, `voting-rights` and `local-immigration` the stance rests entirely on roll-call
votes and she has no quotable sentence on those axes. For `childcare` and `growth-and-development`
the only candidate text fails a gate — the childcare line is a record claim ("I am proud to have
worked to secure funding…") and the growth/infrastructure line is written in the **third person**
on the campaign site, which is the campaign's copy rather than her speech. In both cases the
paraphrase is carried in `reasoning` and `quote_text` is left blank, per the rule that a blank
quote with a real source beats a manufactured one.

## Things that blocked me

- No 2025 or 2026 local press coverage of her was reachable: Bend Bulletin's own site search
  returned nothing after Dec 2024, and her campaign site's news index stops at Aug 2024. Her
  campaign platform therefore reflects the **2024 cycle**, not the 2026 race against Michael
  Summers. Anything on the 2026 race (voters' pamphlet statement, debates with Summers) is still
  un-mined and would be the highest-value next fetch.
- Her official legislative page yields no content over `curl`, so **legislative newsletters, floor
  speeches, and committee testimony were not mined** beyond what KTVZ quoted. Committee testimony
  is available via the OData `CommitteePublicTestimonies` / `CommitteeMeetingDocuments` collections
  and via OLIS meeting audio/video — not attempted here, and the likeliest route to quotes for the
  six vote-only rows above.
- `WebFetch` was not used for any quote. Every quote came from `curl` + string match, per the
  standing warning that WebFetch (including via `r.jina.ai`) returns a paraphrase.
