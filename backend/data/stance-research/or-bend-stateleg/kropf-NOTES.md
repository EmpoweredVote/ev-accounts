# Jason Kropf (OR HD-54, D-Bend) — research notes

external_id `-4120054` · assumed office 2021-01-11 · eligible sessions **2021R1 onward only**.
Remediation job: the 6 retired DB rows cited HB 2001 (2019), HB 3427 (2019) and HB 2020 (2019-20),
all of which predate his seating. **Nothing in this output cites a pre-2021 measure** — verified
programmatically (see "Integrity checks" below).

Result: **14 stances, 4 verbatim quotes, 11 topics skipped.**

---

## The single most valuable source: the OLIS OData API

`https://api.oregonlegislature.gov/odata/ODataService.svc/` is a public, unauthenticated, fully
queryable OData v3 endpoint. It has no rate limit, needs no proxy, and returns clean JSON with
`&$format=json`. **This is far better than scraping the JS-heavy OLIS web UI or PDFs** and should be
the default for any future Oregon legislator.

Collections used:

| Collection | Query | Yield |
|---|---|---|
| `Legislators` | `$filter=LastName eq 'Kropf'` | Confirms `LegislatorCode` = **`Rep Kropf`** and enumerates his sessions. Earliest = `2021R1`. This is the cheap, authoritative seating-date guard. |
| `MeasureVotes` | `$filter=VoteName eq 'Rep Kropf'` | **2,927 individual recorded votes**, each with `Vote`, `ActionText`, `ActionDate`. Page with `$top=1000&$skip=N`. |
| `MeasureSponsors` | `$filter=LegislatoreCode eq 'Rep Kropf'` | 301 sponsorships (57 `Chief`, 244 `Regular`). Note the **misspelled field name `LegislatoreCode`** — that is the real column name. |
| `Measures` | `$filter=SessionKey eq '2023R1'` | `CatchLine`, `RelatingTo`, `MeasureSummary`, `ChapterNumber`, `Vetoed`. Fetched all 10 eligible sessions (9,839 measures) to join against the votes. |

Session-key distribution of his 2,927 votes — **zero pre-2021**:
`2021R1:822, 2021S1:3, 2021S2:5, 2022R1:150, 2023R1:775, 2024R1:161, 2024S1:2, 2025R1:823, 2025S1:3, 2026R1:183`

Vote types: `Aye:2703, Nay:148, Excused for Business:58, Excused:18`.

### METHODOLOGICAL TRAP — "Motion to withdraw from committee" votes are NOT content stances

This is the most important finding for future Oregon work, and it nearly produced two wrong scores.

Oregon minority members routinely move to withdraw a bill from committee to force a floor vote.
Majority members vote Nay on these **as a bloc, to defend committee process, regardless of whether
they support the underlying bill.** Proof from Kropf's own record: he voted **Nay** on the motion to
withdraw **HB 4147 (2022R1)**, a bill letting incarcerated people register and vote — a bill he would
plainly favour on the merits. Same pattern on HB 2107 (2023R1) and HB 3115 (2021R1), where he voted
Nay on the procedural motion and **Aye on final passage of the very same bill**.

**Therefore all 148 Nay votes were screened, and only `Third reading` / `Passed` / `concurred in
Senate amendments` votes were used as evidence.** Motions to withdraw, to refer/re-refer, to
postpone, and to substitute a Minority Report were excluded from scoring. (Where he voted Nay on
seven successive delay motions against HB 2002 in one day, that is mentioned only as corroboration
alongside his actual Aye on final passage.)

### Strongest evidence tier: bills he personally FLOOR-CARRIED

`MeasureVotes.ActionText` contains `Carried by Kropf`, which identifies the 79 measures he carried on
the floor. A floor carrier speaks for the bill — this is his own act, stronger than a sponsorship and
much stronger than a caucus vote. Key ones used: SB 48, SB 819, HB 2172, HB 3318 (2021R1);
HB 4123, HB 4075 (2022R1); **HB 4002 (2024R1, the Measure 110 rewrite)**; HB 2935, HB 2492, HB 2005,
HB 3069 (2025R1); SB 1516 (2026R1).

---

## Sources fetched

**Primary (OLIS OData API)** — as above. Individual measure pages cited in output use the canonical
human-facing pattern `https://olis.oregonlegislature.gov/liz/<SESSION>/Measures/Overview/<BILL>`.
Caveat: OLIS is a single-page app and returns **HTTP 200 even for a nonexistent measure**
(`2021R1/ZZ9999` → 200), so the status code proves nothing. Verified instead via the embedded
`<title>` (e.g. `HB4002 2024 Regular Session`). Every cited measure exists in the OData API.

**His own words**
- `https://jasonkropfforbend.com/` — campaign site, first-person platform. Found via the contact
  address `info@jasonkropfforbend.com` buried in his **Ballotpedia** page. `jasonkropf.com` and
  `kropfforOregon.com` do not resolve (NXDOMAIN). `/issues`, `/priorities`, `/about` are 404;
  everything lives on `/` — `sitemap.xml` confirms only `meet-jason-kropf`, `endorsements`, `home`,
  `staging`, `shop`.
- `https://bendbulletin.com/2024/01/25/editorial-kropf-kotek-and-knopp-on-changes-to-measure-110/`
- `https://oregoncapitalchronicle.com/2022/02/23/lawmakers-poised-to-spend-400-million-on-housing-projects/`
- `https://oregoncapitalchronicle.com/2023/10/13/oregon-lawmakers-prep-to-tackle-drug-addiction-in-2024-session/`
- `https://oregoncapitalchronicle.com/2024/02/14/oregon-judges-including-chief-justice-concerned-about-legislative-addiction-proposal-letter-says/`
- Bend Bulletin `?s=Jason+Kropf` site search, plus the 2023-08-01 leadership profile and the
  2026-02-23 primary-challenger story.

**Fetch-layer notes for next time**
- `bendbulletin.com/?s=<query>` works with a plain browser UA and no proxy — no `r.jina.ai` needed.
  Result links are in `href="https://bendbulletin.com/YYYY/MM/DD/slug/"` form (note: no `www.`).
- `oregoncapitalchronicle.com/?s=<query>` likewise.
- `html.duckduckgo.com` returned a 14 KB blocked stub — **not needed at all** for this jurisdiction;
  the two site searches plus Ballotpedia covered everything.
- `WebFetch` was **not used for any quote.** All four quotes came from `curl` + string match.
- Ballotpedia fetched fine over plain curl (200, 200 KB) — no Playwright required this session.

---

## Quotes: verified

All four `quote_text` values were re-fetched fresh at the end of the session and confirmed as exact
substrings of the tag-stripped page text. One note: the healthcare quote spans a `</strong>` tag
between its two sentences, so it matches the rendered text but not the raw HTML — the rendered-text
match is the correct standard.

| Topic | Source | Note |
|---|---|---|
| `public-safety-approach`, `jail-capacity` | Bend Bulletin 2024-01-25 | Same quote used on both rows; it documents both the police/public-health operating model and treatment-instead-of-jail. Em-dashes are U+2014. |
| `homelessness-response` | Oregon Capital Chronicle 2022-02-23 | Contains a mid-quote `…` (U+2026) **present in the source**, not an edit of mine. No trailing ellipsis. |
| `healthcare` | campaign site | Verbatim, no edits. |

No `quote_deidentified` required edits: none of the four contains a party label, office claim,
self-identification, or named third party. "Oregonian" is a bare state demonym and was kept.

**Indirect speech deliberately NOT quoted.** Several tempting lines are the reporter's words, not his,
and were left out of `quote_text` entirely — e.g. the Bulletin's "Kropf wants to see that approach for
state's funding for victims of crime" and "He would make funding for these sorts of organizations more
akin to the way schools are funded." Also excluded: the Capital Chronicle line "This committee is
really going to serve as a legislative hub to address the urgent public health and public safety
response – because you have to have both" — **that is Sen. Kate Lieber speaking, not Kropf.** Easy
misattribution trap, since the two are quoted alternately as committee co-chairs throughout.

---

## Topics scored (14)

| topic | value | anchor |
|---|---|---|
| abortion | 1 | HB 2002 (2023R1) co-sponsor + Aye; HB 4127, HB 4088 (2026R1) |
| healthcare | 2 | HB 3352 (2021R1) Cover All People co-sponsor + Aye; insurance mandates; campaign quote |
| housing | 3 | HB 2705, HB 2671 (2023R1) chief; SB 8 (2021R1), HB 2001 (2023R1) Aye |
| rent-regulation | 2 | HB 3054 (2025R1) Aye; SB 278/SB 282 (2021R1) |
| residential-zoning | 4 | HB 2138 (2025R1) Aye; SB 458, SB 391 (2021R1) |
| climate-change | 3 | HB 2021 (2021R1) co-sponsor + Aye; HB 3409 (2023R1) |
| civil-rights | 2 | HB 3294, HB 3307 (2023R1); HB 2505 (2021R1); SB 1579 (2022R1); HB 2936 (2021R1) Aye |
| childcare | 3 | HB 2683 (2023R1) chief; HB 3005 (2023R1), HB 4098 (2024R1) |
| homelessness-response | 3 | HB 4123 (2022R1) chief + carried; HB 3644 (2025R1); HB 3115 (2021R1) Aye |
| public-safety-approach | 3 | HB 4002 (2024R1) carried; HB 2005, HB 3069 (2025R1) |
| jail-capacity | 2 | SB 48, SB 819, HB 2172 (2021R1) carried; HB 4001 (2024R1); HB 3067 (2025R1) |
| local-immigration | 1 | HB 3265 (2021R1) Sanctuary Promise Act co-sponsor + Aye; HB 4114, HB 4138 (2026R1) |
| campaign-finance | 2 | HB 4024 (2024R1) Aye; SB 1571 (2024R1) carried |
| data-centers | 2 | HB 3546 (2025R1) co-sponsor + Aye |

### Chair calls worth re-reading

- **climate-change = 3, not 2.** HB 2021 is aggressive but chair 2 specifies phase-out of fossil fuels
  **by 2030**; HB 2021's 2030 milestone is an 80% cut confined to the **electricity sector**, with
  100% not due until 2040. The specific date in the chair text is what decides it.
- **data-centers = 2, with a stated caveat.** HB 3546 nails chair 2's cost-shifting bar (allocate
  costs to the facilities, mitigate risk to other retail classes) but does **not** require dedicated
  generation, chair 2's other clause. Chair 3 was rejected because HB 3546 is a ratemaking statute,
  not a siting/approval statute — none of chair 3's pre-approval assessments or community benefit
  requirements appear in it.
- **campaign-finance = 2 by elimination.** HB 4024 imposes real contribution limits plus
  original-source reporting, which is strictly more than chair 3's disclosure-only ceiling, and far
  less than chair 1's ban-and-publicly-fund. So 2.
- **public-safety-approach = 3, not 2.** HB 4002's deflection model keeps **police as the first
  responder** and then hands off; chair 2 requires shifting non-violent calls *away* from police to
  unarmed co-responders. Not the same thing.
- **jail-capacity = 2 despite HB 4002 recriminalizing possession** as a Class C misdemeanor. Flagged
  in the reasoning for honesty, but the surrounding record (standing pretrial release orders ×2,
  pretrial release study, sentence reconsideration, earned supervision reduction, specialty courts,
  Justice Reinvestment, courthouse-colocated treatment, set-aside reform) is unambiguously
  alternatives-over-capacity, and he has never advocated building jail capacity.

---

## Topics skipped (11) — with reasons

| topic | why skipped |
|---|---|
| **homelessness** | Neither chair 2 nor 3 actually fits. HB 3115 (2021R1) does **not** decriminalize public sleeping (chair 2) and does **not** condition enforcement on shelter-bed availability or divert citations to services (chair 3) — it requires local camping laws be "objectively reasonable as to time, place and manner." His position is captured cleanly at `homelessness-response`; scoring it twice would double-count the same evidence at false precision. |
| **taxes** | Genuinely mixed and no chair is safe. He voted **Nay on final passage of SB 139 (2021R1)**, which narrowed the reduced pass-through income tax rate — i.e. a Democrat voting against a tax increase on pass-through business income. His opposition to CAT/estate-tax repeal exists only as withdrawal-motion votes, which are procedurally unreliable (see trap above). No chair earned. |
| **voting-rights** | Only real evidence is Aye on final passage of HB 2107 (2023R1) extending automatic voter registration to OHA. That sits between chair 1 and chair 2, and chair 1's conjunctive "**and allow online voting**" has no support anywhere in his record. |
| **school-vouchers** | Oregon has no voucher program, so the voucher axis is untestable. He voted **Nay on final passage of HB 3204 (2023R1)** (virtual public charter enrollment timelines) and his campaign platform is squarely public-school funding, but that cannot distinguish chair 1 (eliminate vouchers) from chair 2 (restrict vouchers to low-income). |
| **economic-development** | Contradictory. He floor-carried HB 2037 (2021R1) small-business loan expansion, consistent with chair 2 — but he voted **Aye on SB 4 (2023R1)**, Oregon's large semiconductor/CHIPS incentive package, which directly contradicts chair 2's "avoid large corporate subsidies." Leaves 3 vs 4 unresolved with only floor votes and no statement. |
| **growth-and-development** | His own HB 3318 (2021R1), which he chief-sponsored and carried, fast-tracked a **Bend-specific UGB expansion** — but I could not evidence chair 3's "invest in infrastructure ahead of growth" or chair 4's "reduce fees / actively recruit development." Streamlining alone is common to both. |
| **redistricting** | No usable evidence. His Nay on HJR 204 (2022R1, Citizens Redistricting Commission) is a withdrawal-motion vote — excluded by the trap above. His Aye on SB 881 (2021S1) enacting legislature-drawn maps is not an endorsement of legislature-drawing as the right *method*. |
| **trans-athletes** | Only touchpoint is HB 2037 (2025R1), and his vote there was on a **motion to withdraw**, not passage. His LGBTQ-related co-sponsorships (HB 3020, HB 3041, SB 704 in 2021R1) concern the "trans panic" defence and statutory definitions — a different axis from athletic eligibility. |
| **fossil-fuels** | Oregon has effectively no oil/gas drilling; nothing in his record addresses the drilling-permit axis the chairs are written on. |
| **local-environment** | No evidence on the development-vs-preservation trade-off axis. Wildlife-corridor co-sponsorships (HB 4130 2022R1, HB 2999 2023R1) do not speak to it. |
| **transportation-priorities** | HB 3055 (2021R1) is an omnibus; HB 4139 (2022R1) and HB 3014 (2023R1) co-sponsorships are GHG and student-transport reimbursement. Nothing establishes a modal-priority chair. |

---

## OLIS votes I could and could NOT individually confirm

**Confirmed at the individual-vote level** (his name in `MeasureVotes.VoteName`, with action text and
date) for every measure cited as a vote: HB 3265, HB 3115, HB 3124, SB 48, SB 819, HB 2172, SB 8,
SB 458, SB 391, SB 278, SB 282, HB 2021, HB 2936, HB 3352, HB 2163 (2021R1); SB 891 (2021S2);
HB 4123 (2022R1); HB 2002, HB 2107, HB 2001, HB 3294, HB 3409, HB 2683, HB 3005, HB 3204, SB 4
(2023R1); HB 4002, HB 4024, HB 4098, HB 4001, SB 1571 (2024R1); HB 2138, HB 3054, HB 3546, HB 3644,
HB 2005, HB 3069, HB 2935, HB 2492 (2025R1); HB 4114, HB 4138, SB 1516 (2026R1).

**Could NOT confirm a personal vote — cited as sponsorship only, never as a vote:**
- **HB 2705 (2023R1)** — chief sponsor, *no floor vote recorded*; died before reaching the floor.
- **HB 2670 (2023R1)** — chief sponsor, *no floor vote recorded*.
- **HB 3067 (2025R1)** — chief sponsor, *no floor vote recorded*.
- **HB 2671, HB 2972, HB 2974 (2023R1)** — chief sponsor; used as sponsorship evidence only.
- **HB 3307, HB 2505, SB 1579, HB 2504, HB 3109, HB 3560** — `Regular` (co-)sponsorships used as
  sponsorship evidence only; where a floor vote also exists it is named separately.

The reasoning strings say "chief-sponsored" or "co-sponsored" (never "voted for") for all of the
above. No vote is attributed to him that is not in `MeasureVotes`.

## Integrity checks run

- Schema: 14 rows, exact key set and order, `external_id` = `-4120054` on every row, all `value` in
  1–5, every row has ≥1 source, no quote without a `quote_deidentified`. **PASS**
- Session guard: regex over every `reasoning` string for `\b(19|20)\d\d(R1|S1|S2|I1)\b` — **no session
  earlier than 2021R1 cited anywhere. PASS**
- Quote audit: all 4 quotes re-fetched fresh and confirmed verbatim; no trailing ellipsis; no party
  label, office claim, or executive-act phrasing in any `quote_deidentified`. **PASS**

## Nothing blocked me

No paywall, proxy, or rate-limit problem this session. The OData API removed the need for PDF
extraction entirely, so `pdftotext` and the letter-spacing pitfall never came up, and the voters'
pamphlet was not needed.

## Incidental facts (not scored)

- He **won** the 2026 Democratic primary 88.8%–11.1% over Andrew Caruana (Ballotpedia), and is
  unopposed in the general — consistent with the brief.
- He chairs House Judiciary and was deputy majority whip of the House Democratic Caucus from 2023.
- He co-chaired the Joint Committee on Addiction and Community Safety Response with Sen. Kate Lieber.
- Feb 2026: a conduct complaint was filed over his conduct as Judiciary chair toward Rep. Thuy Tran
  during a gun-bill vote. Not a policy stance; recorded here only so a future pass does not mistake
  the coverage for issue content.
