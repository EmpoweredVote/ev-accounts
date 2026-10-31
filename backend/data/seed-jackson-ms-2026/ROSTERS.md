# Jackson, Mississippi — deep seed

**Open this before any Jackson or Hinds County work.** Everything here is read from a primary
document or measured against a live service in the session that wrote it. Dates are absolute.

Lease `state:ms` + `place:2836000` + `county:28049`, claimed 2026-10-31.
Worktree `C:\ev-accounts-jackson`, branch `seed/ms-jackson-hinds`.

Jackson is **not** a Knight city — Biloxi was Mississippi's Knight slice (slice 16,
[`.planning/knight-foundation/ms.md`](../../../.planning/knight-foundation/ms.md)). That slice is
the reason the state already has legislative geography and a seated legislature, and its findings
are load bearing here. Read its MS-3 (Biloxi) and MS-4 (Harrison County) sections before writing
any migration: this is the same state, the same statutes and the same publishers.

| stage | status |
| --- | --- |
| 0 legislature re-verify | ✅ **DONE 2026-10-31 — zero turnovers.** See below |
| 1 ward geometry | ✅ **SETTLED 2026-10-31 — layer chosen and numbering proved.** Not yet loaded |
| 2 Jackson offices | ▶ roster read; **term starts still open** |
| 3 Hinds County | ▶ **BLOCKED ON A DEAD WEBSITE** — see below |
| 4 portraits | ▶ open — 8 city, ~25 county, 173 legislators |
| 5 banner | ▶ open — **the hardest adjacency in the programme**, see below |

---

## ✅ Stage 0 — the Mississippi Legislature re-verified, 2026-10-31

The legislature was seated on 2026-09-28 by `CC_0169`/`CC_0170` (174 offices, 174 seated). It was
rebuilt from live sources today and **nothing has moved**.

`node scripts/build-ms-legislature-roster.mjs --refresh` — both chambers reconcile exactly, 52 + 122
= 174, and `--self-test` fired all seven detectors first. Diffed against production:

| | |
| --- | --- |
| seats compared | 174 live vs 174 in production |
| exact match after normalisation | **172** |
| seats on one side only | **0** |
| real turnovers | **0** |

The two that differ are **production being more correct than the source**, not changes:

- SD-49 — the page still reads `Joel R.Carter, Jr.` with no space after the initial. `CC_0170`
  repaired it to `Joel R. Carter, Jr.` with the reason attached. Still broken at source.
- HD-28 — page `W.I. Harris`, production `W. I. Harris`.

⚠ **AND THE DIFF CALLED THE FIRST ONE A SURNAME CHANGE.** Normalising `Joel R.Carter, Jr.` gives a
last token of `rcarter`, so a last-token comparison said the surname differed and flagged a
turnover that did not happen. This is the repo's standing name-suffix defect wearing a new hat —
the missing space, not the suffix, is what did it here. **A name comparison needs the row read, not
the verdict trusted.**

🟢 **One legislator now carries a portrait and it did not come from the Legislature.** Production
had 0 of 174 on 2026-09-28; it has 1 today — **Jeffrey Hulum III (HD-119)**, whose image sits under
`politician_photos/dedupe/2026-10/`, so it arrived through a person-merge pass, not through the
blocked permission track. The other 173 are still blank. See **Portraits** below.

---

## ✅ Stage 1 — the ward geometry, settled 2026-10-31

**Jackson is mayor-council with seven single-member wards**, so the polygon count is the seat count.

### 🔴🔴 THE CITY PUBLISHES TWO WARD LAYERS AND ITS OWN ORG HOSTS BOTH

This is the Boise defect (two council maps, Hub search returns the dead one) in a new city. Both
live on the city's own ArcGIS Online org `n0wqzAPJddc1vROD`:

| | operative | superseded |
| --- | --- | --- |
| service | `Jackson_Adopted_Wards_2024/FeatureServer/0` | `Jackson_Ward_Boundary_WFL1/FeatureServer/2` |
| last edited | 2025-02-25 | 2023-06-15 |
| ward populations sum to | **153,701** | **173,514** |

🟢 **AND UNLIKE BOISE, A CHEAP CHECK SEPARATES THEM — THE POPULATION IS AN IDENTITY.**
TIGERweb's `Census2020` incorporated-places layer gives Jackson city `2836000` **POP100 = 153,701**,
with a bogus-GEOID control returning 0 features. The 2024 layer's seven wards partition that number
**exactly**. The older layer sums to 173,514, which is Jackson's 2010 count, and carries its own
`IDEAL_VALU` of 24,788 — 24,788 × 7 = 173,516, so the superseded layer corroborates its own vintage.
▶ **Where Boise had no cheap discriminator, Jackson has an arithmetic one. Use it.**

⚠ **The Census API is no longer keyless.** `api.census.gov` answers **HTTP 200 with an HTML page
titled "Missing Key"**, which `JSON.parse` turns into a thrown error rather than a clear refusal —
the "a clean 200 lies" rule, in a new place. TIGERweb needs no key and was used instead.

Three further things agree, and none derives from another:

- the city's **currently embedded** Ward Maps app (`8f89bb231b09437c84c69dc50e268eb4`, modified
  **2025-07-02**, after the June 2025 election) renders the 2024 layer;
- the city publishes its own ward maps as a ZIP of seven PDFs named **`Ward1-2024-36x48.pdf` …
  `Ward7-2024-36x48.pdf`**;
- the superseded layer's own webmap is titled **"Jackson Ward Boundary Map broken*"**.

### 🟢 THE NUMBERING IS PROVED, NOT READ OFF THE ATTRIBUTE

Mississippi has now handed this programme a bad district-number field **twice**: Biloxi's `Id`
repeated (MS-3) and Harrison County's `DIST_ID` was a clean permutation of exactly the right five
values (MS-4). Neither a count, a distinctness test nor a null check sees either.

`scripts/verify-jackson-ward-numbering.mjs` settles it. A ward redraw moves boundaries but does not
renumber wards, so new Ward N must occupy substantially the same ground as old Ward N. Measured in
PostGIS on geography, read-only:

```
new \ old      1      2      3      4      5      6      7
Ward 1     99.9    0.0    0.1    0.0    0.0    0.0    0.0
Ward 2      2.5   97.3    0.0    0.0    0.0    0.0    0.0
Ward 3      5.9    0.0   86.2    0.0    0.0    0.0    7.8
Ward 4      0.0    0.0    0.0   97.8    0.0    2.1    0.0
Ward 5      0.0    0.0   10.9    0.1   88.0    1.0    0.0
Ward 6      0.0    0.0    0.0   13.3    0.0   84.3    2.4
Ward 7      0.0    0.0    0.0    0.0    0.0    3.1   94.4
                                       diagonal strongest 7/7
```

**Controls, watched failing.** `--control=shuffle` rotates the labels — exactly the Harrison defect
— and the matrix goes red **0/7**, naming the permutation. A disc over Gulfport intersects Ward 1
at 0 m², so the comparison can report no overlap.

⚠ **A STREET-LABEL TEST WAS TRIED FIRST AND COULD NOT DISCRIMINATE. IT IS NOT IN THE REPO.**
The idea was that a street printed on Ward N's map lies in Ward N, so TIGER road midpoints should
land in the matching polygon. It returned 66% overall with wards 3, 5 and 7 apparently wrong. The
mechanism, not the data, was the problem: measured, only 198 of 1,998 TIGER names appear on exactly
one ward map and most appear on **two to four**, because each map draws its neighbours' streets for
context. **A metric that does not separate is a ranking, not a gate** — the SC-5a and MI-1 rule,
met again. 🔴 It was discarded rather than tuned, and the off-diagonal cells it produced must not
be read as evidence about wards 3, 5 and 7.

### Facts for the loader

- **7 polygons**, `esriGeometryPolygon`, stored in **Web Mercator (wkid 102100 / 3857)**.
  🔴 **Fetch with `outSR=4326` and assert the coordinate range.** This is the Holladay trap: a
  polygon can be valid, correctly shaped and in the wrong CRS, and every geometric check passes.
  Measured after reprojection: lon −90.33078 … −90.05603, lat 32.19555 … 32.41249.
- **The key is `Ward`** (integer 1–7). `District` (`WARD1`…) and `Name` (`Ward 1`…) agree with it on
  every row — read row by row, not counted. ⚠ The **superseded** layer's `FID` is *not* its ward
  number (FID 1 is Ward 2), so the trap is real in this family of files.
- Ward populations 1…7: 22,988 · 22,542 · 21,567 · 21,122 · 21,358 · 23,102 · 21,022.
- ⚠ `Voting_Precincts_2025` on the same org is a VTD layer with **no ward field** and a population
  of 162,623 — it spills outside the city limits. It cannot anchor a ward and was not used.
- **An `X` boundary code has no allocator.** `max(mtfcc)` over both `geofence_boundaries` and
  `districts` read **`X0084`** on 2026-10-31. 🔴 **Re-read it in the session that writes.**

---

## ▶ Stage 2 — the offices

### 🟢 THE INVENTORY IS EIGHT, FROM THE CITY'S OWN ENUMERATING SENTENCE

`jacksonms.gov/government/city-council/` (WordPress `modified` 2026-03-17):

> *"The City of Jackson operates under the mayor-council form of government with a full-time mayor
> elected at-large and seven part-time council members elected (one each) from seven wards."*

▶ **8 elected offices: Mayor + Wards 1–7.** Miss. Code Ann. 1972 § 21-8 (mayor-council form), the
same statute Biloxi runs under.

⚠ **STILL TO CONFIRM BEFORE WRITING: that nothing else is elected.** Biloxi's inventory was closed
by two instruments — the ballot *and* the Code of Ordinances showing the clerk is appointed. For
Jackson only the enumerating sentence has been read. The Fort Wayne trap (an elected clerk) and the
Grand Forks trap (an elected municipal judge named in one sentence on a staff page) are both
unchecked here.

### The roster — read from each member's own page, bound by ward

| seat | officeholder | page `modified` |
| --- | --- | --- |
| Mayor | John Horhn | 2026-06-05 |
| Ward 1 | Ashby M. Foote, III | 2025-12-20 |
| Ward 2 | Montyne "Tina" Clay | 2026-04-09 |
| Ward 3 | Kenneth Stokes | — |
| Ward 4 | Brian C. Grizzell | — |
| Ward 5 | Vernon Hartley | — |
| Ward 6 | Lashia Brown-Thomas | 2026-04-09 |
| Ward 7 | Kevin Parkinson | — |

⚠ **THE COUNCIL PAGE AND THE RESULTS PAGE DISAGREE ON WARD 2'S NAME.** The roster says
*Tina Clay*; the Municipal Clerk's results page says ***Montyne "Tina" Clay***. The fuller rendering
is the one to store, with "Tina" as the used name — **the display name is not the full name**, which
is MS-3's Biloxi finding (Mike / Robert Nail) in the same state.

### 🟢 THE MAYOR'S DATE IS PUBLISHED, AND IT IS A STATEMENT ABOUT THE OFFICEHOLDER

The Municipal Clerk's own results page: *"Horhn began his term on **July 1, 2025**."*
▶ That is a statement about *taking office*, not about an election and not an advertised ceremony —
which is exactly what the programme's oath-date rule asks for. **Write 2025-07-01 at day precision.**

🔴 **DO NOT COMPUTE THE COUNCIL'S DATES FROM THE MAYOR'S.** Mississippi has already produced three
variants of this failure inside one slice: Biloxi's mayor was sworn **two days before** his
advertised inauguration; Biloxi's Ward 7 ceremony was announced and never reported; and Harrison
County's statutory first-Monday **moved for a holiday**, which only the minutes recorded. Note also
that Biloxi's 2025 cohort took office on **2025-06-30** while Jackson's mayor took office on
**2025-07-01** — two cities in one state, one day apart, each from its own record.

### 🔴 TWO SEATS ALMOST CERTAINLY PRE-DATE 2025, AND ONE HAS A SPECIAL ELECTION IN BETWEEN

`office_terms` records a **seat**, not a career — MS-2's Chris Johnson rule — but the mirror of it
applies too: dating a continuously-held seat from the most recent election erases real tenure, which
is what MS-3 avoided for Biloxi's Tisdale and Glavan.

- **Ward 1, Foote.** His own page: *"In 2014, Ashby ran for and was elected as Councilman for Ward I
  in Jackson, MS, where he continues to serve."* 🔴 **"Ran for and was elected in 2014" is a FIRST
  ELECTED, not a term start.** Needs the date he took the seat, and confirmation of continuity.
- **Ward 3, Stokes.** His page says he was elected to the Jackson City Council **in 1989** — a
  career statement, and he has also served on the Hinds County Board of Supervisors in between, so
  continuity is explicitly *not* safe to assume.
- **Ward 2, Clay.** 🔴 **There was a Ward 2 SPECIAL ELECTION on 2024-10-01.** The Municipal Clerk's
  page: *"The Jackson City Council has declared the Ward 2 City Council seat vacant, thereby
  requiring a Special Election to be held October 1, 2024"* (notice dated 2024-08-19). If Clay won
  that special and was then re-elected in June 2025, her tenure dates from 2024 — the Biloxi Ward 7
  shape exactly. **Establish it; do not assume either way.**

⚠ **THE RESULTS PAGE IS AN OPEN LIST — the Harrison County "include" trap.** It names Clay (2),
Stokes (3), Hartley (5) and Parkinson (7) as *"among the candidates who prevailed"*, says the Ward 1
race was *"extremely close"*, and **names nobody for Wards 4 and 6**. It cannot enumerate anything.
The certified results are referred to as *"the City's official results archive"* and **are not
linked from it**.

### ⚠ Access facts, measured 2026-10-31

- 🟢 `jacksonms.gov` answers Node directly, bare or with a Chrome UA, and **404s honestly** on a
  bogus path (110 KB body, title "Page not found"), so the status discriminates and the soft-404
  trap does not apply.
- 🟢 It is WordPress and the **REST API works**: `/wp-json/wp/v2/pages?slug=…` publishes a `modified`
  timestamp per page, and `/wp-json/wp/v2/media?search=…` finds files the pages never link.
  A bogus slug returns `[]`, which is the control. This is how Biloxi's stale-prose finding was
  made, and it transfers.
- 🔴 **`hindscountyms.com` IS DEAD, NOT BLOCKED.** HTTP **503**, 2,702 bytes, title
  *"U.S.NEXT New Domain"*, on the real path and on a bogus one alike, to a bare fetch, to a Chrome UA
  **and to Playwright**. A browser gets the same 503, so this is not a bot challenge. Both `www.` and
  bare hosts. Search engines still index its pages.
- 🔴🔴 **`jcebmo.org` IS THE JACKSON COUNTY *MISSOURI* ELECTION BOARD.** A web search for Jackson's
  certified municipal results returned its "Official SOV" PDF as a top hit. The `mo` is the state.
  **A search result that matches the words can be the wrong place entirely** — the Mike Lee rule,
  applied to an institution rather than a person.
- 🟢 `sos.ms.gov` answers a bare fetch (HTTP 200).

---

## ▶ Stage 3 — Hinds County, and why it is blocked

The four-answer probe needs a county supervisor, so Jackson is not done without Hinds.

🔴 **THE COUNTY'S OWN WEBSITE IS DOWN** (above), which removes the source MS-4 used for Harrison's
officer pages and portraits. The inventory must therefore come from where MS-4 said it should have
come from in the first place: **the Secretary of State's certified recapitulation**, signed by the
County Election Commission. `sos.ms.gov` is reachable.

⚠ **DO NOT REUSE HARRISON COUNTY'S INVENTORY AS A TEMPLATE.** Harrison's 27 offices came from a
certified ballot, and even within one state MS-4 found that a county's own "elected officials" page
was an **open list** that omitted the Justice Court Judges and Constables. Hinds also differs
structurally: like Harrison it has **two judicial districts** (Jackson and Raymond), and MS-4's
finding that Harrison's two were merely *courthouses* was specific to Harrison and **must be
re-established here, not carried across**.

🟢 **ONE USEFUL ARTEFACT ALREADY FOUND.** The city's own ArcGIS org carries
`Export_SupervisorDist_4` (2023-09-12) — a Hinds supervisor-district export. It is one district by
its name and it is the city's copy, not the county's. Treat it as a lead.

🔴 **`geo_id` 28049 IS HINDS COUNTY *AND* SENATE DISTRICT 49 *AND* HOUSE DISTRICT 49.** Measured in
production: three `districts` rows share that `geo_id`, differing only by `mtfcc`/`district_type`.
**Every join must pair `geo_id` with `mtfcc`.** Mississippi also holds 427 ZCTA rows.

---

## ▶ Stage 4 — portraits

**Measured against production 2026-10-31**: Jackson 0 of 8, Hinds 0 of ~25, legislature **1 of 174**.

🟢 **Jackson publishes council portraits, and the WordPress media API finds them.** Seen so far:
`Ashby-M.-Foote-III-Ward-1-scaled-1.jpg`, `lashia-brown-thomas-ward-6-state-…jpg`,
`Tina-Clay-remove.bg_.png`, `Kevin-Parkinson-remove.bg_.png`, `BCG02.jpeg`.
🔴 **TWO OF THOSE FILENAMES SAY `remove.bg` — THEY ARE CUT-OUTS**, the HCSO gold-ring problem in a
different disguise. Look for the original sitting before accepting a cut-out, which is the Minnesota
House lesson MS-5 said should be tried **first**.
🔴 **Bind by seat, never by filename** — MS-5 found three different wrong labels on Biloxi's files,
including two wrong labels on one man.

### 🔴 The legislature's 173 — the permission track is CLOSED for this wave

The letter to `webmaster@ls.ms.gov` of 2026-09-28 is unanswered. **It must not be sent again and
silence is not permission**, so `billstatus.ls.state.ms.us/members/…` stays off limits.
▶ **Operator's decision, 2026-10-31: source alternatives per member instead** — free-licence and
press/official sources, licence-checked one at a time. Expect partial coverage; **a blank beats a
wrong link**, and a blank is findable by every "who still needs a headshot" query.

---

## ▶ Stage 5 — the banner, and why it is the hardest in the programme

There is **no `jackson` key** in the essentials repo (`src/lib/buildingImages.js` → generated
`public/banners.json`); confirmed 2026-10-31.

🔴🔴 **`states/MS.jpg` IS A PHOTOGRAPH OF JACKSON.** Every other city banner in the programme had to
be composed *away from* its state banner; this one shares its subject. `buildingImages.js` records
what MS-5 measured: in the 6:1 band `states/MS.jpg` is *"an ELEVATED, DISTANT inland view: the
Capitol dome and downtown towers as a thin horizontal bar in mid-distance, wide sky above, tree
canopy below"*, and its credit is accurate in the band (*MS — Jackson MS Downtown Panorama |
chmeredith | CC BY 2.0*).
▶ **So the downtown skyline and the Capitol dome are both spent.** A Jackson banner has to be a
different camera height, a different subject scale and a different thing filling the frame — the
test Biloxi passed by going water-level and near.
🔴 Read `states/MS.jpg` **in the band, computed from the file**, before choosing anything, and look
at the asset rather than only the numbers.

---

## Open questions, in the order they block work

1. **The certified 2025 municipal results.** They close the inventory, give Wards 4 and 6 their
   winners, and date the seats. The city refers to an archive it does not link and the county site
   is down.
2. **Ward 2's 2024 special election result and the date Clay took the seat.**
3. **Wards 1 and 3 — whether tenure is continuous, and from when.**
4. **Whether Jackson elects anything besides the mayor and seven council members.**
5. **Hinds County's full elected inventory**, from the certified recapitulation.
