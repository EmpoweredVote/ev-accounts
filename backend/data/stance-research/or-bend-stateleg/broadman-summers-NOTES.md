# Research notes — Broadman (SD 27) + Summers (HD 53 challenger)

Research date 2026-07-25. Scope: the 25 topics in `_TOPIC_SCALE_STATELEG.txt`.
Output: `broadman-summers.json` — 18 rows (Broadman 14, Summers 4).

---

## Remediation check (the reason this job exists)

The 6 retired Broadman stances attributed votes on **HB 2002 (2023R1)** and **SB 1537 (2024R1)**.
Confirmed impossible: Broadman's Senate `term_start` is **2025-01-13** (Wikipedia infobox `term_start`,
corroborated by his Ballotpedia/OLIS presence only from 2025R1). His January-2021 Wikipedia infobox
entry is `office1 = Member of the Bend City Council, Position 2`, term 2021-01 → 2025-01 — the city
council trap the brief warned about.

**Every bill cited in the new JSON was session-checked programmatically.** I pulled his complete
sponsorship and roll-call record from the OLIS OData API and confirmed the session distribution:

| Source | Rows | Sessions present |
|---|---|---|
| `MeasureSponsors` where `LegislatoreCode eq 'Sen Broadman'` | 98 | 2025R1 (75), 2026R1 (23) |
| `MeasureVotes` where `VoteName eq 'Sen Broadman'` | 976 | 2025R1 (790), 2025S1 (4), 2026R1 (182) |

Zero rows before 2025R1. No pre-2025 Senate act is attributable to him, and none is cited.

---

## Fetch-layer findings (reusable)

- **OLIS has a working OData API**: `https://api.oregonlegislature.gov/odata/odataservice.svc/`.
  Collections: `Measures`, `MeasureSponsors`, `MeasureVotes`, `MeasureHistoryActions`,
  `MeasureAnalysisDocuments`, `Legislators`, `CommitteeVotes`, … This is *far* better than scraping
  the JS-heavy OLIS UI. **Schema gotcha: the sponsor field is misspelled `LegislatoreCode`** (not
  `LegislatorCode`) — filtering on the correct spelling returns HTTP 400. Legislator codes look like
  `Sen Broadman`.
- `Measures?$filter=SessionKey eq '2025R1'` returns 5.3 MB / ~3,300 measures with `CatchLine`,
  `MeasureSummary`, `CurrentLocation`, `ChapterNumber` — one call gives you the whole session index.
- **`https://olis.oregonlegislature.gov/liz/<SESSION>/Measures/Overview/<PREFIX><NUM>` resolves 200**
  for every measure I cited (36/36 URL check passed). Safe as the human-readable citation.
- Staff Measure Summary PDFs extract cleanly: get `DocumentUrl` from `MeasureAnalysisDocuments`, then
  `curl | pdftotext`. Used for SB 1129.
- **`bendbulletin.com` works with plain `curl` + a browser UA** — including `?s=<query>` search and
  full article bodies (no paywall interception on the article HTML). **`r.jina.ai` TIMED OUT (422)
  on bendbulletin** even with `x-no-cache: true`. Direct curl is the better tool here; prior intel to
  route Bend media through jina is wrong for this domain.
- `sos.oregon.gov/elections/Pages/candidate-filings.aspx` → **404**. Ballotpedia was the working
  route to the 2026 candidate field.
- Ballotpedia responded 200 to plain curl this session (no 403, no Playwright needed).
- 2024 Deschutes County voters' pamphlet: landing page `digitalcollections.library.oregon.gov/nodes/view/281745`;
  the **`/nodes/download/281745` path returns HTML**, the real PDF is at
  **`/assets/displaypdf/281745`** (5.4 MB). `pdftotext` throws a harmless
  `Unknown character collection 'Adobe-Korea1'` warning but extracts fine. Ran both with and without
  `-layout`; the **non-`-layout` output was the usable one** (layout mode interleaved the two
  candidate columns worse). Attribution confirmed against the `(This information furnished by X.)`
  delimiters, not mere page co-location — Broadman's block ends `(This information furnished by Team
  Broadman.)` and Summers' ends `(This information furnished by Summers for Oregon, PAC ID 21352.)`.
- `bendoregon.gov` was never needed — the council-vote question was answered by Bulletin reporting
  that named the vote count and Broadman's position.

## Quote handling

All 9 candidate quotes were **string-matched against the fetched bytes** with a normalizer before
being written (`verify.mjs`); 9/9 OK. **Apostrophes in the Bulletin and Wix sources are U+2019
(`’`), delivered as `&#8217;` in raw HTML** — if you re-verify, normalize entities first or match
against rendered text, otherwise a correct quote will look like a mismatch.

Quotes were only taken where the text is **first-person or first-person-plural**. Third-person
campaign copy ("Summers will cut the Salem Tax", "Anthony will fight to…") was deliberately NOT
used as `quote_text` even though it is verbatim and candidate-authored, because presenting it as
speech would read as indirect speech. Those topics carry `quote_text: ""` with the platform text
paraphrased in `quote_deidentified` and quoted-with-attribution inside `reasoning` only where the
source is unambiguous.

---

## Broadman — evidence confirmed vs. not confirmed

### Individually confirmed (bill + session + his own vote/sponsorship)

| Measure | Session | His act | Chapter |
|---|---|---|---|
| SB 1129 | 2025R1 | Chief sponsor; **carried on Senate floor** 4/17/25 | ch. 188 |
| SB 1011 | 2025R1 | Chief sponsor; **carried on floor** 3/31/25 | ch. 142 |
| SB 1137 | 2025R1 | Chief sponsor; **carried on floor** 6/16/25 | ch. 545 |
| SB 974 | 2025R1 | Chief sponsor; Aye 4/28/25 + concurrence 6/5/25 | ch. 330 |
| SB 599 | 2025R1 | Regular sponsor; Aye 3/24/25 | ch. 226 |
| HB 3054 | 2025R1 | Aye 6/12/25 | ch. 387 |
| SB 690 | 2025R1 | Aye 6/17/25 + concurrence 6/27/25 | ch. 598 |
| HB 3546 | 2025R1 | Aye 6/3/25 | ch. 323 |
| HB 2081 | 2025R1 | Aye 6/16/25 | ch. 433 |
| SB 1570 | 2026R1 | Chief sponsor; Aye 2/24/26 + concurrence 3/4/26 | ch. 93 |
| SB 1567 | 2026R1 | Regular sponsor; Aye 2/27/26 | ch. 91 |
| HB 4088 | 2026R1 | Aye on passage 3/5/26 | ch. 52 |
| HB 4127 | 2026R1 | Aye 3/6/26 | ch. 63 |
| HB 4031 | 2026R1 | Aye 2/25/26 | ch. 12 |
| Bend camping code | — | **Voted in the 4-3 majority, 11/16/2022**, as mayor pro tem | — |
| Protected bike-lane proposal | — | Co-launched with Ariel Mendez, taken to Transportation Bond Oversight Cmte, May–June 2021 | — |

**Procedural-vote trap logged:** on HB 4088 he shows a **Nay** and an **Aye** on the same day
(2026-03-05). The Nay is *"Motion to substitute Minority Report for Committee Report failed"* — i.e.
voting against the minority report, which is *support* for the bill. Of his 976 votes only 37 are
non-Aye and **most of those are minority-report / withdraw-from-committee motions, not opposition**.
Do not read a bare Nay as opposition without reading `ActionText`.

### Chief-sponsored but never reached a floor vote (sponsorship is the act cited, not a vote)

SB 20, SB 1097, SB 1103, SB 957, HB 3085, HB 3079, HB 3529, HB 3530, HB 4117 — all still
"In Senate/House Committee". Cited as sponsorship only; no vote is claimed for any of them.
HB 3011, HB 4150, SB 969 likewise (regular sponsor, no floor vote).

### Could NOT individually confirm

- **The Bend council roll call by name.** The Bulletin reports the code "passed by a 4-3 vote" and
  says "the code he voted in favor of Wednesday is better than existing policy" — that sentence is
  what establishes his Aye. I did not retrieve the city's own tally sheet naming all seven
  councilors. If a hard primary record is required, pull the 11/16/2022 Bend City Council minutes.
- **His 2024 pamphlet claim that he "helped lead the effort to reduce homelessness and regulate
  camping"** — third-person campaign copy about his own record. I did not rely on it for the value;
  the camping-code vote and the guest column carry `homelessness` / `homelessness-response`.
- **SB 1586 / HB 4104 direction.** I could not determine from the catchline/digest whether the
  semiconductor and enterprise-zone changes *expand* or *tighten* the incentives, nor whether any
  community-benefit or job-quality conditions attach — which is precisely what separates
  `economic-development` chairs 3 and 4. Hence the skip. **Unlocking it:** read the SB 1586 -A
  engrossed text and Staff Measure Summary.

### Broadman skips (11)

| topic_key | why |
|---|---|
| `taxes` | **Closest call in the set — flagged for human review.** As Senate revenue chair he and Rep. Nathanson proposed (amendment to SB 1507, 2026R1) the largest EITC expansion in Oregon history *plus* a net-new-jobs employer credit, paid for by removing three deductions (auto-loan interest, corporate equity-sale profits, bonus depreciation). That straddles chair 2 (raise on large companies) and chair 3 (keep rates, close loopholes): it raises **no rates** and funds **no new services**, and he described the package to the Bulletin as ideas to start a debate, none guaranteed. Adjacent chairs both fit → skipped per the scale rule. Source: bendbulletin.com/2026/02/03/bends-broadman-pushes-tax-boost-for-families/ |
| `economic-development` | Off/undetermined axis — see above. |
| `fossil-fuels` | Axis is drilling and extraction permits. No Oregon act of his touches it. His only public-lands bill, SB 1590 (2026R1, ch., chief sponsor — bars public bodies from helping the federal government privatize federal land), is a land-disposal question, not an extraction-permitting one. |
| `residential-zoning` | Nothing on the density/neighbourhood-character axis. SB 75 (Aye, ch. 589) eases ADU development on rural residential land but does it through *wildfire hazard code*, not zoning density. |
| `local-environment` | No act on the local development-vs-green-space axis. SJR 28 (regular sponsor — constitutional right to a clean environment) is far broader than the chair scale. |
| `jail-capacity` | Only SB 559 (regular sponsor, a *study* of early medical release from state prison). Prison ≠ jail capacity, and a study is not a chair. |
| `trans-athletes` | No athletics-eligibility measure in 2025R1/2026R1. HB 4088 covers gender-affirming *treatment*, a different axis. |
| `school-vouchers` | Nothing. HB 4124 (chief sponsor) is a higher-education system study. |
| `voting-rights` | Nothing on the voter-access/security axis. SJR 30 (chief sponsor) *raises* initiative-petition signature thresholds — ballot-measure access, not voter access. Deliberately not scored here. |
| `redistricting` | No measure matched; no statement found. |
| `campaign-finance` | No measure, no statement. |

---

## Summers — what was searched, what was found

### Identity verification (done first, before any evidence was used)

Required a Deschutes/HD-53 link. Got three independent ones:
1. **Ballotpedia `Michael_Summers_(Oregon)` is a single page spanning both races** — categories
   include *"Oregon State Senate candidate, 2024"* and *"Oregon House of Representatives candidate,
   2026"*, and the infobox lists **Redmond School District 2J, Position 2, tenure 2021–present, term
   ends 2029**. He advanced from the R primary for HD 53 on **2026-05-19 with 5,678 votes (98.4%)**
   and faces incumbent Emerson Levy on 2026-11-03.
2. **Broadman's Wikipedia article** names his 2024 general-election opponent as "Republican small-business
   owner and Redmond School Board chair Michael Summers".
3. **electsummers.com** — the URL printed in his own 2024 pamphlet statement — now titles its
   homepage *"Summers for Oregon State Representative"* and its bio page states he is *"running for
   Oregon House District 53"* and *"Chair of the Redmond School Board since 2021"*.

Same person. Note the DB has **no party recorded**; Ballotpedia and the 2024 pamphlet both list him
as Republican. I did **not** use party for any value — every Summers row rests on his own published
words.

### Sources fetched for Summers

| Source | Result |
|---|---|
| `electsummers.com` (home, `/issues`, `/meet-michael`) | **LIVE and current 2026.** `/issues` has 5 planks: cost-of-living/taxes, housing, jobs & small business, homelessness, water. Wix site; content extracts from `>text<` nodes after stripping script/style. |
| `electsummers.com/sitemap.xml` → `pages-sitemap.xml`, `blog-posts-sitemap.xml` | 12 pages + 19 blog posts enumerated. Best single move on this site. |
| Blog posts fetched | `affordable-housing-in-central-oregon` (**richest — ends in a first-person policy paragraph**), `keeping-costs-low`, `measure-110-press-release`, `what-s-really-going-on-at-our-border`, `solving-homelessness-one-local-veteran-at-a-time`, `op-ed-article`, `a-seat-for-every-voice`, `water-conservation-conversations` |
| 2024 Deschutes County voters' pamphlet | His full candidate statement, delimiter-verified |
| `ballotpedia.org/Michael_Summers_(Oregon)` + `.../Oregon_House_of_Representatives_District_53` | Identity + 2026 field. **No stance content** — and he has completed **neither** the 2024 nor the 2026 Ballotpedia Candidate Connection survey. |
| `bendbulletin.com/?s=Michael+Summers` (pages 1–2) | Only 2 hits, both 2024: his Senate-run announcement and a letters column. **No 2026 HD-53 coverage yet.** |
| `sos.oregon.gov` candidate filings | 404 |
| `summersfororegon.com`, `michaelsummersoregon.com` | Not attempted — prior intel says dead. **`electsummers.com` is the live domain.** |

### Confirmed stance-bearing text (4 topics scored)

- `housing` = 4 and `growth-and-development` = 4 — the housing blog post is unusually explicit: it
  names *"tax credits, bond measures, and statewide rent control"* as approaches that *"have often
  failed to tackle the underlying problems"*, blames *"aggressive land-use policies"* and
  *"artificial scarcity of land"*, and prescribes UGB expansion + lower builder fees + regulatory
  cost screening. His rejecting the chair-3 toolkit *in his own words* is what makes 4 defensible
  rather than a party prior.
- `taxes` = 4 — current 2026 issues page.
- `public-safety-approach` = 4 — 2024 pamphlet, *"We need to increase police staffing…"*.

### Summers skips (and exactly what would unlock each)

| topic_key | why skipped | unlock |
|---|---|---|
| `rent-regulation` | He lists statewide rent control among failed approaches, but that is an **efficacy critique, not a repeal position** — chairs 4 and 5 both fit and neither is stated. | A direct statement on repealing/limiting SB 608, or a Nov-2026 pamphlet answer. |
| `residential-zoning` | Says he'd promote *"a variety of housing options, including multi-family units"* but with no by-right upzoning, parking or corridor language; his lever is outward (UGB) not inward (density). Chairs 3 and 4 both fit. | A statement on middle housing / HB 2001 implementation. |
| `local-environment` | *"strike a better balance between conservation and development"* — chairs 3 and 4 both fit; no fee-in-lieu or deregulation mechanism named. | — |
| `homelessness`, `homelessness-response` | 2026 plank is a **spending critique plus devolution** (*"stop writing blank checks to Salem and give Bend, Redmond, and Sisters the tools"*); 2024 statement says *"a balanced approach"*. Neither picks a point on the housing-first ↔ enforcement axis. | A statement on camping bans / Grants Pass, or a shelter-vs-permanent-housing preference. |
| `economic-development` | **Off-axis.** The topic asks about incentives (abatements, community benefit agreements); his jobs plank answers on regulation and tax increases. | A statement on enterprise zones, SDC waivers, or recruiting a major employer. |
| `school-vouchers` | *"education should empower parents with choices"* names **no voucher, ESA, or funds-follow-the-student mechanism**, and he is a sitting public-school board chair whose own bio touts Science of Reading curriculum and public-school outcomes. Too vague to place between chairs 3, 4 and 5. | A statement on Oregon voucher/ESA legislation. **Also: his Redmond School Board 2J votes 2021–2026 are an untapped primary source** — worth a pass for `school-vouchers`, `childcare`, `trans-athletes`, `local-immigration`. |
| `jail-capacity` | Measure 110 post wants misdemeanor reclassification + treatment pathways, but **never addresses capacity** — the actual axis. | A statement on the Deschutes County jail expansion. |
| `local-immigration` | The border post is a **travelogue of a Yuma trip with no policy position**. Nothing on ICE cooperation. | — |
| all remaining 12 topics | No evidence found at all. | — |

### Biggest single unlock for Summers

The **November 2026 general-election Deschutes County voters' pamphlet**, not yet published as of
2026-07-25 (the 2024 edition is State Library node `281745`; expect a sibling node in Sept–Oct 2026).
That is a candidate-authored, delimiter-attributable, current-office statement — it would likely
resolve `rent-regulation`, `homelessness-response`, `school-vouchers` and confirm `taxes`. Second
best: a KTVZ or Bend Chamber **Levy–Summers debate**, on the 2024 precedent (KTVZ ran a two-part
Broadman–Summers debate on 2024-09-15).

## Deliberate non-uses

- The `keeping-costs-low` post is **opposition research on Broadman** that cites five Bulletin /
  Central Oregon Daily stories about his council votes (fire levy 3/22/24, transportation fees
  5/17/23, home-seller fees 12/9/22, utility rates 6/19/21, property taxes 10/2020). **None of it
  was used as evidence of Broadman's stance** — an opponent's characterisation of a vote is not the
  vote. Those five citations are, however, real leads if someone wants to score Broadman's council
  fiscal record from the underlying articles.
- The `solving-homelessness-one-local-veteran-at-a-time` post is philanthropy (donated flooring for
  a veterans' shelter village) described by the Bend Heroes Foundation president — **charity by a
  third party's account, not a policy stance.** Not scored.
- The 2026-07-08 transportation-funding article has Broadman only as indirect speech ("said he sees
  2027 as a clean slate") — no stance, not used.
- The 2026-01-15 immigration article looks like a Broadman immigration source but **his own bill in
  that package is the public-lands bill (SB 1590)**; the immigration bills belong to other members.
  Not used for `local-immigration`.
