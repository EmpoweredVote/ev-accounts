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
