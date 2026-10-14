# EGI — do roster people run Google political ads? (2026-10-13)

Follow-on to the source-yield study (PR #1010), which found that paid ads were the largest
own-words source never read. Question: before anyone sets up the Meta Ad Library API, how many
roster people advertise at all, using a $0 source?

Data: `backend/data/stance-research/2026-10-13-egi-google-ads/`.

## Source

- **Google Political Ads transparency bundle** —
  `https://storage.googleapis.com/political-csv/google-political-ads-transparency-bundle.zip`.
  Public, no credentials, $0. 310 MB zipped / 3.2 GB unzipped. Refreshed daily (this copy:
  2026-10-13 18:03 UTC). Verified-election advertisers only (US federal/state candidates,
  officeholders, parties, and any advertiser running ads that feature them).
  - ⚠ The older URL under `storage.googleapis.com/transparencyreport/` still answers 200 but is
    a 2.5 KB stub last modified 2022-06-02. Use the `political-csv` bucket.
- BigQuery `bigquery-public-data.google_political_ads` holds the same tables but needs a Google
  Cloud project and credentials. Not used.

## Rosters

- 3-county roster from PR #950 (`roster.csv`, Monroe IN / Racine WI / Utah County UT).
- LA County roster: `roster-la.sql` from PR #1010, run read-only against prod
  (`SET default_transaction_read_only = on`) → `roster-la.csv`, 1,188 rows.
- 1,496 distinct people after de-duplication by (county, politician id). A person who holds a
  seat is counted as **incumbent**; a person who appears only as a November candidate is a
  **challenger** (this includes open-seat candidates).

## Method

1. Keep US advertisers in `advertiser-geo-spend` (17,352). Add declared names and scopes from
   `advertiser-declared-stats` (California advertisers declare the candidate they feature).
2. Candidate match: the person's surname is a whole word in the advertiser name/scope **and**
   the advertiser spent in the person's state. 7,283 pairs.
3. Strength: first name (or its first three letters, for Dave/David) also present → 194 pairs.
   Surname-only pairs whose advertiser text has a committee shape (`Smith for …`,
   `Friends of Smith`) and whose top spend state is home → ~130 more pairs.
4. **Every accepted pair was judged by hand** (`decisions.txt`). Rejected: same-name strangers
   (Andy Kim NJ vs Judge Andrew C. Kim; Mark Kelly vs Judge Mary E. Kelly; Assembly Robert
   Garcia vs Rep. Robert Garcia), and multi-candidate slates that merely contain a matching
   token. Classes:
   - `own` — the person's own committee or official office (e.g. `REP. BRAD SHERMAN - U.S. HOUSE`).
   - `own_ctrl` — a ballot-measure committee the person controls (Gabriel, Irwin, Gonzalez).
   - `third` — another sponsor (IE, PAC, union, voter guide) that names the person. **Not own
     words.**

## Result 1 — who advertised

| Level | Status | People | Own ads, ever | Own ads since 2025-07 | Named only by a third party |
|---|---|---:|---:|---:|---:|
| federal | incumbent | 30 | 23 | 11 | 0 |
| federal | challenger | 30 | 6 | 6 | 0 |
| state | incumbent | 77 | 24 | 7 | 4 |
| state | challenger | 33 | 4 | 4 | 1 |
| county | incumbent | 55 | 2 | 1 | 0 |
| county | challenger | 15 | 0 | 0 | 1 |
| city | incumbent | 616 | 15 | 8 | 4 |
| city | challenger | 12 | 2 | 2 | 0 |
| school | incumbent | 197 | 7 | 2 | 4 |
| school | challenger | 3 | 0 | 0 | 0 |
| judicial | incumbent | 428 | 0 | 0 | 0 |
| **total** | | **1,496** | **83 (5.5%)** | **41 (2.7%)** | **14** |

By county: LA 63 of 1,000 · Monroe 8 of 114 · Racine 6 of 167 · Utah County 6 of 215.

Reading:

- Google ads are a **federal and state** source. 77% of federal incumbents have advertised; 31%
  of state incumbents. Below state level the rate is 2–4%, and judges are 0.
- Most local hits are **not about the local seat**. Of the 24 city/school/county people with own
  ads, at least 8 advertised for a *higher* office (Taj, Pulido, Deen, Seo, Klein Lopez for
  Assembly; Erickson, Alegria for State Senate; Pimentel for Board of Equalization). Their ads
  speak to a state race, not to the seat on the roster.
- Challengers: 12 of 93 (13%) advertised; all 12 within the current cycle. Ads reach some
  challengers that have no official record — but few, and almost all at federal/state level.
- The three non-LA counties together: 20 people with own ads, 11 below federal level — all
  state legislators or legislative candidates (Hall, Mayfield, Pierce, Huffman Oliver; Vos,
  Schutt; Shallenberger, Shepherd, Boyd, Fiefia) except one city councillor (Andy Ruff,
  Bloomington, 2020).

**Recall limits** (undercount, not overcount): a committee named without the person's surname
(`Neighbors for a Better Westside`) cannot be matched; city and school candidates often advertise
below Google's verification threshold or not on Google at all; local-only issue ads by
unverified advertisers are not in this file.

## Result 2 — is the ad text in the file? No.

- `creative-stats` gives per ad: `Ad_ID`, `Ad_URL`, `Ad_Type` (TEXT / IMAGE / VIDEO), dates,
  impression bucket, spend range, targeting. **No headline, body or transcript.**
- The 83 people's own advertisers ran **2,231 ads: 1,473 video, 625 text, 133 image.** Since
  2025-07: 409 video, 59 text, 0 image. 53 people have at least one TEXT ad; **26 people have
  video only.**
- Getting the words needs the ad pages. Tested one TEXT ad (John Boyd for Utah, 2026-10-12):
  the page at `adstransparency.google.com` renders no ad text in the DOM — a "text" ad is served
  as a **rendered image** (`tpc.googlesyndication.com/archive/simgad/<id>`, 696×1004). The image
  is legible (vision or OCR works) and needs no sign-in. Video ads need the YouTube video and a
  transcript.
- Content of that one sample: biography and a general pitch ("fact-based policy and real
  transparency"); no policy rule. One sample proves only that the words are reachable, not that
  ads carry EGI positions.

## Result 3 — pricing the Meta Ad Library API route

Not set up (no yes from Chris). From Meta's API page, checked 2026-10-13:

| Item | Cost |
|---|---|
| Money | $0 |
| Facebook account | required (a real person's account) |
| Identity confirmation | `facebook.com/ID` — the same process required to run political ads; government ID; "can take a few days" |
| Meta for Developers account + app | required; agree to the Platform Policy |
| Access token | user token from the app; short-lived by default, must be refreshed |
| Coverage | ads about social issues, elections or politics, delivered anywhere in the past 7 years |
| What it returns | ad body text, link titles/captions, page name, spend and impression ranges, dates — text is a field, no OCR needed |

Alternative with no API: Meta's **Ad Library Report** (CSV by advertiser/page, spend totals) —
gives the count, not the words.

## What this means for EGI

- For the A1 v2 counties (Monroe, Racine, Utah County), Google ads cannot fill the challenger gap:
  11 below-federal people there have ever advertised on Google, and only one of them below state level.
- For LA County it adds a little, mostly at state level and mostly in video.
- Before setting up Meta, the cheap next check is the same count on Meta via the Ad Library
  Report CSV (no API, no ID). Local candidates spend far more on Facebook/Instagram than on
  Google, so Meta's count may differ a lot from this one.
- If words are wanted from Google: ~59 current-cycle TEXT ad images can be read by vision at low
  cost; the 409 current-cycle videos need transcripts.

## Reproduce

Scripts in `scripts/` take paths as arguments. Download the bundle to an empty directory, then
`match.py` → `enrich_all.py` → hand decisions → `tally.py`. `runla.cjs` runs `roster-la.sql`
read-only. Python is run with `-I`.

---

# Part 2 — Meta Ad Library Report count (2026-10-13)

Data: `backend/data/stance-research/2026-10-13-egi-google-ads/meta/`.

## Source

- **Meta Ad Library Report**, United States, time range *All dates* (2019-10-10 → 2026-10-09).
  Public page `facebook.com/ads/library/report`, button "Download report". No login, no ID, $0.
  - Direct download URLs return **403** to scripts; the file must be fetched by clicking in a
    browser. 304 MB zipped / 925 MB unzipped.
  - Contents: `advertisers.csv` (523,659 rows: Page ID, Page name, Disclaimer, lifetime spend,
    number of ads) and one `regions/<State>.csv` per state (spend in that state by Page +
    disclaimer). **No ad text, no dates per ad.** 340,484 advertisers show spend as `≤100`
    (counted as $50 here).
  - Lifetime file only: it cannot say *when* an advertiser ran. A recency count needs a second
    download with *Last 90 days*.

## Method

1. For each roster person, scan their state's region file. Candidate pair: surname as a whole word
   in Page name or disclaimer, and either the first name (or a prefix of it, Dan/Daniel) present
   or a committee shape (`Smith for …`, `Friends of Smith`). 5,332 pairs.
2. Keep pairs whose home-state spend is ≥ 50% of the advertiser's US spend (local and state
   campaigns spend almost all at home). 2,755 pairs.
3. **Own page (strict rule):** the Page name *or* the disclaimer contains the person's first and
   last name and nothing else except office / campaign filler words (`for`, `elect`, `council`,
   `assembly`, `mayor`, `friends of`, years, state names …). Pages with no disclaimer and ≤ $100
   lifetime are set aside. → **259 people.**
4. **Precision check by hand** on a seeded random sample (`random.seed(20261013)`):
   - Strict rule: **40 of 40** sampled people are correct (their own page or committee).
   - Surname-only committee shape (159 more people): **2–3 of 30** correct (`Pope for Register of
     Deeds`, `Eich For Council`); the rest are same-surname strangers (`Newman for State Senate`
     vs Judge Tara Newman). **Excluded** — adds about 13 people, recorded as undercount.
5. Unlike the Google count, rows were **not** all judged by hand; the sample is the evidence.

## Result

| Level | Status | People | Meta own page | Meta ≥ $1k lifetime | Google own (Part 1) | Either | Meta, not Google |
|---|---|---:|---:|---:|---:|---:|---:|
| federal | incumbent | 30 | 26 | 26 | 23 | 28 | 5 |
| federal | challenger | 30 | 15 | 10 | 6 | 16 | 10 |
| state | incumbent | 77 | 52 | 44 | 24 | 54 | 30 |
| state | challenger | 33 | 8 | 4 | 4 | 8 | 4 |
| county | incumbent | 55 | 10 | 3 | 2 | 11 | 9 |
| county | challenger | 15 | 3 | 2 | 0 | 3 | 3 |
| city | incumbent | 616 | 109 | 55 | 15 | 112 | 97 |
| city | challenger | 12 | 3 | 2 | 2 | 3 | 1 |
| school | incumbent | 197 | 16 | 9 | 7 | 18 | 11 |
| school | challenger | 3 | 0 | 0 | 0 | 0 | 0 |
| judicial | incumbent | 428 | 17 | 8 | 0 | 17 | 17 |
| **total** | | **1,496** | **259 (17%)** | **163** | **83** | **270 (18%)** | **187** |

By county (Meta): LA 175 of 1,000 · Utah County 56 of 215 · Racine 15 of 167 · Monroe 13 of 114.

The three A1 v2 counties, below federal level: incumbents 63 of 419; **challengers 9 of 55**
(Google: 4).

Reading:

- **Meta is the larger source: 3× Google** (259 vs 83 people), and nearly all of the gain is
  local: city incumbents 109 vs 15, judges 17 vs 0. Google adds only 11 people Meta does not.
- Many local pages are small: of the 259, 96 spent under $1,000 lifetime. A few dozen ads.
- Utah County is the outlier among the A1 v2 counties (56 of 215, 26%); Monroe and Racine are
  under 10%.
- Challengers stay thin: 29 of 93 overall, 9 of 55 in the A1 v2 counties. Ads do not close the
  challenger gap; they mainly add incumbents who already have an official record.
- As in Part 1, some local hits advertised for another office (Erickson, Alegria, Taj for state
  seats; judges who ran for DA or sheriff). The office in the ad is not always the roster seat.

## What this means for the API decision

- The report gives the **count** only. Words need the Meta Ad Library API (ID confirmation,
  developer app, token — see Part 1) or reading ads in the public Ad Library web page one Page at a
  time.
- The API is now justified only if ad words are wanted for **about 260 people, mostly
  incumbents**. For challengers it would add text for about 29 people across all four counties.
- Cheap next checks, if wanted: (a) download *Last 90 days* to count who is advertising **now**;
  (b) read the ads of a sample of 10–15 local Pages in the public Ad Library (browser, no login)
  to see whether local ads state any EGI rule before paying the setup cost of the API.

---

# Part 3 — who advertises now, and what local Meta ads say (2026-10-13)

Data: `meta/meta_page_matches_90d.csv`, `meta/local_page_reads.csv`.

## Last 90 days (Meta Ad Library Report, 2026-07-12 → 2026-10-09)

Same download route (browser click, no login), 18 MB. Each own Page + disclaimer from Part 2 was
looked up in the 90-day advertiser file.

| Level | Status | People | Meta own ads, last 90 days | Meta own ads, ever (Part 2) |
|---|---|---:|---:|---:|
| federal | incumbent | 30 | 17 | 26 |
| federal | challenger | 30 | 14 | 15 |
| state | incumbent | 77 | 15 | 52 |
| state | challenger | 33 | 6 | 8 |
| county | incumbent | 55 | 0 | 10 |
| county | challenger | 15 | 0 | 3 |
| city | incumbent | 616 | 12 | 109 |
| city | challenger | 12 | 3 | 3 |
| school | incumbent | 197 | 2 | 16 |
| school | challenger | 3 | 0 | 0 |
| judicial | incumbent | 428 | 1 | 17 |
| **total** | | **1,496** | **70 (4.7%)** | **259** |

By county: LA 54 · Utah County 7 · Racine 5 · Monroe 4.

- Most local Meta advertising is **old** — it ran during that person's own past election. Only 18
  of 1,326 county/city/school/judicial people advertised in the last 90 days.
- Current ads are where November races are: federal and state, mostly in LA.

## Reading 15 local Pages

Public Ad Library (`facebook.com/ads/library/?view_all_page_id=…`), no login. Ad body text is in
the page and readable. Picked 15 Pages whose ads are for a **local** seat: 3 Monroe, 3 Racine,
5 Utah County, 4 LA; mixed council, mayor, county, judge, school board. Jeff Gray (Utah County
Attorney) was replaced by David Spencer because Meta had removed all of Gray's ads.

Method: scroll each Page to load ads and read the body text. For the 7 Pages with more ads than
scrolling loads (Raman ~500, Bass ~830, Wood ~69, Negrete ~39, Lockhart ~23, MacKay ~21,
Judkins ~14), also ran Meta's keyword search inside the Page for `gender`, `transgender`,
`LGBTQ`, `parents`. **Positive control:** the same search returned `encampments` 9 and `family`
3 on Bass, and `rent` 18 on Raman, so the zero results are real zeros, not a blind search.
Images and video in ads were **not** read — text bodies only.

Result:

| | Pages |
|---|---:|
| State an EGI rule (gender identity in schools, pronouns, facilities, sports, parental notification) | **0 of 15** |
| State some concrete local policy (taxes, parking, rent caps, police funding, zoning, transport) | 10 of 15 |
| No policy content (name, endorsements, qualifications, "vote on May 2") | 5 of 15 |

Closest to the topic:
- Emily Lockhart (Lehi council): "I will always advocate for students, parents, and teachers." No rule.
- Taylor Wishau's Page (Racine County Board) ran 2025 ads for two *other* people, Burlington school
  board candidates, with "keep politics out of the classroom". Coded language, no rule, and not
  Wishau's own race.
- Laurie Lieberman (school board, LA): record claims only (graduation rates, fiscal management).

Judges and school-board members in this sample advertise qualifications and endorsements, not
policy.

## Conclusion for EGI

- Paid ads are a **real own-words source for local policy in general** (10 of 15 Pages state
  something concrete) but **not for this topic**: 0 of 15 local Pages state an EGI rule, including
  the school-board Page.
- Combined with Part 2: ad text would mostly re-describe incumbents who already have an official
  record, and only 18 local people advertise now.
- **Recommendation: do not set up the Meta Ad Library API for EGI.** It would return text, at no
  money cost, but this sample predicts close to zero EGI positions from local ads. If a later topic
  is a local bread-and-butter issue (taxes, housing, policing, transport), the case is different —
  10 of 15 Pages spoke to those.
- **Ruling (Chris Andrews, 2026-10-13): agreed — the Meta Ad Library API is not set up for EGI.**
- Limit: 15 Pages is small, and image/video text was not read. A topic that is loud in a race
  (for example a school-board race fought on gender policy) could show up in that race's ads; this
  sample had only one school-board Page.

---

# Part 4 — do local ads say anything that is not available elsewhere? (2026-10-13)

Question (Chris): for topics other than EGI, are ads worth checking as a source, or is the same
information found elsewhere?

Data: `meta/ad_claims.json` (40 policy claims copied from the ads of the 10 Pages in Part 3 that
stated concrete policy), `meta/ad_claims_check_{A,B,C}.json` (cross-check).

Method: three `source-collector` agents (Sonnet), capped at 20 searches / 30 fetches each, looked
for the **same position** (not just the same topic) in: campaign site / official bio,
candidate questionnaires (BallotReady, Vote411, newspaper Q&A), local news, official record.

| Result | Claims |
|---|---:|
| Same position found elsewhere | **23 of 40 (58%)** |
| Topic found, position not | 9 |
| Not found | 8 (20%) |

Where the 23 were found: candidate questionnaires 11 (mostly **BallotReady** and the Daily Herald
Q&A), news 6, official bio 3, official record 2, campaign site 1.

What only the ads had:
- Hyper-local items: Wood's over-occupancy and UVU-stadium lines, MacKay's 311 app and Slate
  Canyon position (the Slate Canyon one is in a video, so the ad text does not state it either).
- Wishau (Racine County Board): all four claims not found or topic-only — but Racine County's site
  returned 403 to every fetch, so this is a **blocked search, not proof of absence**.
- Judkins' SB 2001 vote: the ad claims a "no" vote; the vote record was unreachable (le.utah.gov
  errors), so it is unverified either way.

Reading:
- For local candidates, ads mostly repeat what is in **questionnaires**. BallotReady matched more
  claims than any other source — a source worth checking first for local races, independent of ads.
- The ad-only content is narrow and hyper-local (a stadium, an app, towing). Few of those items map
  onto compass topics. Where ads add something, it is usually *more specific wording* of a position
  already stated elsewhere.
- **Verdict:** ads are a low-yield source for compass research. Worth a look only as a fallback for
  a candidate who has no questionnaire, no site and no record — and those candidates mostly do not
  advertise either (Part 2: 29 of 93 challengers ever, Part 3: 18 local people now).

Limits: 10 people, 40 claims, capped search budget; "not found" includes blocked sites; the
fetch tool paraphrases, so only quoted excerpts are verbatim.
