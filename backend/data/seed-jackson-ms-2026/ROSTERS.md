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
| 2 Jackson offices | ▶ **roster and all 8 term starts sourced.** Inventory not yet closed |
| 3 Hinds County | ▶ **UNBLOCKED** — the county moved back to its old host. Inventory read |
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

🔴 **AND BALLOTPEDIA CANNOT CLOSE IT — IT SAYS SO ITSELF.** Its *City elections in Jackson,
Mississippi (2025)* page ends with: *"Please note that there may have been more offices on the ballot
in this capital city than what is listed on this page."* ▶ **A publisher declaring its own list
non-exhaustive is the "include" trap stated out loud.** The remaining routes are the Jackson Code of
Ordinances (its § 2-37 is cited in the council's own minutes, so the code exists and is citable) and
the Municipal Clerk's 2025 candidate qualifying list.

⚠ **The city's own ordinances page 404s** at the path its clerk sidebar links; the code has not been
located yet.

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

### 🟢 THE COUNCIL MINUTES ARE THE PRIMARY SOURCE, AND THEY BIND EVERY MEMBER TO A WARD

The city publishes its council minutes as PDFs through the WordPress media library (34 dated files,
2025-01-14 … 2025-12-30). **A bogus filename returns HTTP 404 with an HTML body**, which is the
control. Two meetings straddle the 2025 transition and each opens with a roll of members *by ward*:

| | 2025-06-17 regular (outgoing) | 2025-07-08 special (incoming) |
| --- | --- | --- |
| Mayor | Chokwe Antar Lumumba | **John A. Horhn** |
| Ward 1 | Ashby Foote | Ashby Foote |
| Ward 2 | Montyne Clay | Montyne Clay |
| Ward 3 | Kenneth Stokes | Kenneth Stokes |
| Ward 4 | Brian Grizzell | Brian Grizzell |
| Ward 5 | Vernon Hartley | Vernon Hartley |
| Ward 6 | Aaron Banks | **Lashia Brown-Thomas** |
| Ward 7 | Virgi Lindsay | **Kevin Parkinson** |

▶ **So the 2025 election changed the mayoralty and exactly two wards.** Five members continue. That
is a *structural* fact from a primary document, and it is what every date below is checked against.
The 2025-07-08 meeting is the organisational one: it elected Grizzell president and Hartley vice
president under Miss. Code § 21-8-11 and Jackson Code of Ordinances § 2-37.

⚠ **THERE IS NO MINUTED OATH.** The minutes jump from 2025-06-17 to 2025-07-08, so no meeting on or
near 1 July is recorded. The city holds **swearing-in photographs** (`MayorCouncilSwearingIN-2,3,6,7`)
but they were uploaded 2026-02, and an upload date is not an event date.

### The dates, and where each comes from

The Municipal Clerk's own results page states: *"Horhn began his term on **July 1, 2025**."* That is
a statement about *taking office* — not an election, not an advertised ceremony — which is what the
programme's oath-date rule asks for. **Ballotpedia independently gives Horhn 2025-07-01**, so two
sources agree on the one date we can check, which is what licenses using Ballotpedia for the rest.

| seat | officeholder | `term_start` | precision | basis |
| --- | --- | --- | --- | --- |
| Mayor | John Horhn | **2025-07-01** | day | city's own results page **and** Ballotpedia |
| Ward 1 | Ashby M. Foote, III | **2014-01-01** | **year** | BP "assumed office in 2014"; his page says elected 2014 |
| Ward 2 | Montyne "Tina" Clay | **2024-11-01** | day | BP; follows the 2024-10-01 special |
| Ward 3 | Kenneth Stokes | **2015-01-01** | **year** | BP "assumed office in 2015" |
| Ward 4 | Brian C. Grizzell | **2021-07-01** | day | BP |
| Ward 5 | Vernon Hartley | **2021-07-01** | day | BP |
| Ward 6 | Lashia Brown-Thomas | **2025-07-01** | day | BP |
| Ward 7 | Kevin Parkinson | **2025-07-01** | day | BP |

🟢 **EVERY DATE AGREES WITH THE MINUTES ON THE ONLY THING THE MINUTES CAN SETTLE.** The three dated
2025-07-01 are exactly the three seats the roll call shows changing hands; the five dated earlier are
exactly the five members present at *both* meetings. **A date and a roll call are different kinds of
fact, and they corroborate here.**

🔴 **BALLOTPEDIA IS AN AGGREGATOR AND WAS TREATED AS ONE.** `scratchpad/bp-verify.mjs` asserts, from
each page's own text, that it names **Jackson, Mississippi** and the **exact ward**, and reports any
page saying "was appointed" — because BP publishes *appointed* and *assumed office* and **only the
second is a `term_start`**. All eight pass; none mentions an appointment. A nonsense name 404s, which
is the control. ⚠ Ward 2 has **no page under "Tina Clay"** (404) — it is under **`Montyne_Clay`**.
**The used name is not the page name**, and a 404 nearly recorded a missing date that exists.

🔴 **FOOTE AND STOKES ARE YEAR PRECISION AND MUST STAY THAT WAY.** BP gives both a bare year, and
their own pages give *first elected* statements — Foote *"In 2014, Ashby ran for and was elected as
Councilman for Ward I"*, Stokes *"In 1989, he was elected to the Jackson [City Council]"*. **"First
elected" is not a term start**, and Stokes has served on the Hinds County Board of Supervisors in
between, so his service is explicitly not continuous from 1989. Write `YYYY-01-01` with
`start_precision => 'year'` and do not promote either without an oath record.

⚠ **BILOXI AND JACKSON TOOK OFFICE ON DIFFERENT DAYS IN THE SAME STATE.** Biloxi's 2025 cohort is
dated **2025-06-30** from its own inaugural record; Jackson's mayor **2025-07-01** from his.
**Do not reconcile them.** Each is that city's own statement, and Mississippi has already produced
three variants of the oath-date failure inside one slice — an oath two days before the advertised
ceremony (Biloxi's mayor), a ceremony announced and never reported (Biloxi Ward 7), and a statutory
day that moved for a holiday (Harrison County).

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

## ▶ Stage 3 — Hinds County

The four-answer probe needs a county supervisor, so Jackson is not done without Hinds.

### 🟢🟢 THE COUNTY IS NOT OFFLINE — IT MOVED BACK TO ITS OLD HOST, AND SAYS SO IN A COMMENT

`hindscountyms.com` is dead (HTTP 503 to Node, to a Chrome UA and to Playwright alike). The live
site is **`www.co.hinds.ms.us`**, found in the *footer of a 404 page on the city's own website* —
a link to the county's land-roll query. Its home page is five lines, and the fourth is the finding:

```html
<!--meta http-equiv="REFRESH" content="0;URL=http://www.hindscountyms.com"-->
<meta http-equiv="REFRESH" content="0;URL=https://www.co.hinds.ms.us/pgs/newindex.asp">
```

▶ **The redirect to the dead `.com` is COMMENTED OUT.** The county has already moved back. A search
engine still indexes the `.com` pages, so the search result looked current and the site looked gone.
🔴 **"THE PUBLISHER IS OFFLINE" IS A CONCLUSION, NOT AN OBSERVATION** — one hostname was down, and
the organisation was reachable the whole time at an address its own HTML names.

🔴 **`co.hinds.ms.us` SOFT-404s.** A bogus path answers **HTTP 200** with the title *"The page cannot
be found"*. Status means nothing there; read the title. This is MS-5's `harrisoncountysheriff.com`
trap in the same state, one wave later.

### 🟢 THE INVENTORY, FROM THE COUNTY'S OWN CERTIFIED RESULTS

`co.hinds.ms.us/pgs/apps/electionresults.asp` publishes certified results **by year back to 1999**,
with summary and per-precinct reports. The 2023 county cycle is the inventory.

🔴 **THE LINK LABEL AND THE FILENAME DISAGREE, AND THE DOCUMENT SETTLES IT.** The row headed
*"Tuesday, November 07, 2023 — Hinds County General Election"* links to files named `20230711 …`.
The PDF's own first page reads **"Summary Results Report Official Election Results — 2023 General
Election Hinds County — November 7, 2023"**, generated 11/17/2023. ▶ **Open the document; do not
read the filename.** The digits are transposed, nothing more.

From that certified report:

| group | n | offices |
| --- | --- | --- |
| countywide | **8** | Chancery Clerk · Circuit Clerk · Coroner · County Attorney · **County Surveyor** · Sheriff · Tax Assessor · Tax Collector |
| per district (×5) | 15 | Supervisor 1–5 · Justice Court Judge 1–5 · Constable 1–5 |
| staggered | ? | Election Commissioner — **only Districts 2 and 4** on this ballot |
| staggered | ? | **School Board** — **only "School Board 1"** on this ballot |

🔴🔴 **HINDS IS NOT HARRISON, AND THE DIFFERENCES ARE REAL OFFICES.** Harrison has **no County
Surveyor** and had **no school board contest**; Hinds elects both. Had MS-4's 27-office template
been carried across, two kinds of office would have been missed outright. **This is
`feedback_describe_offices_dont_standardise` paying for itself inside one state.**

⚠ **ONE BALLOT DOES NOT ENUMERATE A MISSISSIPPI COUNTY.** MS-4 recorded this for Harrison's Election
Commissioners and it holds again, twice over: Hinds shows **two** of five Election Commissioners and
**one** school board seat. **The full size of both bodies is still unknown and must be established
from the body's own roster, not from a ballot.**

⚠ **`District Attorney District 07` is on the ballot and must NOT be seated here.** Like Harrison's
Second Circuit DA, it is elected by a multi-county district. Record it as a debt.

**Constables, certified 2023:** 1 Jerry Moore · 2 John Brown · 3 Lawrence Funchess ·
4 Leon Seals · 5 Beverly Wade-Green.

### Still to establish for Hinds

1. The **full** Election Commission and school board, with the seats not on the 2023 ballot.
2. Supervisor-district **geometry**. 🟢 Lead: the *city's* ArcGIS org carries
   `Export_SupervisorDist_4` (2023-09-12) — one district, and the city's copy, not the county's.
3. Whether Hinds's **two judicial districts** (Jackson and Raymond) duplicate any county office.
   MS-4 established that Harrison's two were merely *courthouses*. 🔴 **That finding was about
   Harrison. Re-establish it here; do not carry it across.**
4. Term start dates, from the Board's own organising minute — the document that caught Harrison's
   statutory day moving for a holiday.

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

1. **Whether Jackson elects anything besides the mayor and seven council members.** This is the only
   thing blocking the Jackson migrations — the roster and all eight dates are sourced.
   ▶ Route: the Jackson Code of Ordinances (§ 2-37 is cited in the council's own minutes), looking
   for *"shall be elected"*, exactly as Biloxi's chapter 2 was read.
2. **Hinds's full Election Commission and school board**, neither of which a single ballot shows.
3. **Hinds supervisor-district geometry**, and a new `X` code read in the writing session.
4. **Hinds term starts**, from the Board of Supervisors' organising minute.
5. **Foote's and Stokes's oath records**, if day precision is ever wanted. Both are honestly at
   `year` now and the schema says that is correct.

⚠ **Jackson's 2025 municipal results are NOT in the county archive.** `YearId=2025` returns an empty
table: the city ran that election itself, and the Municipal Clerk's "official results archive" is
referred to on the city's site but not linked. ▶ It is a public-records request, not a fetch.
The archive **does** carry Jackson municipal races historically — a *"July 24, 2012 Special City
Council, Ward 3"* contest is listed — so it is a live route for Stokes's arrival date.
