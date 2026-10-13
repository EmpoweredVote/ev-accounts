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
