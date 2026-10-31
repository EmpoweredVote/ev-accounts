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
| 1 ward geometry | ✅ **APPLIED 2026-10-31 — 7 ward polygons on `X0085`, +7 exact** |
| 2 Jackson offices | ✅ **APPLIED 2026-10-31 — JACKSON IS SEATED. 8 offices, 8 seated, 0 vacant** (`CC_0320`/`CC_0321`) |
| 3 Hinds County | ✅ **APPLIED 2026-10-31 — HINDS IS SEATED. 28 offices, 28 seated, 0 vacant** (`CC_0322`/`CC_0323`) |
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

🔴 **BALLOTPEDIA CANNOT CLOSE IT AND SAYS SO ITSELF.** Its *City elections in Jackson, Mississippi
(2025)* page ends: *"Please note that there may have been more offices on the ballot in this capital
city than what is listed on this page."* ▶ **A publisher declaring its own list non-exhaustive is
the "include" trap stated out loud.**

### 🟢 CLOSED AT EIGHT, FROM THE CODE OF ORDINANCES

Jackson's code is on **Municode** (`library.municode.com/ms/jackson`), codified through Ordinance
No. 2026-11(3) of 2026-02-24, Supp. 56. ⚠ Municode is behind a **Cloudflare challenge** — HTTP 403
to every Node persona, real and bogus paths alike — so it must be read in **Playwright**.
⚠ **There is no CHARTER node**, same as Biloxi: Mississippi's mayor-council form is statutory.

Every other officer is appointed, and the code says so in its own words:

- **City Clerk** — *"The city clerk is to be appointed by the mayor and confirmed by the city
  council"* (§ 2-326). ▶ **The Fort Wayne trap is closed: Jackson does not elect a clerk.**
- **City Attorney** — *"appointed by the mayor, and confirmed by a majority of the city council at
  its first meeting in July"*; **Chief Administrative Officer** (§ 2-325) and **Chief Financial
  Officer** likewise.
- **Municipal judges** — Chapter 46 (17,940 characters) contains **no occurrence of "elected" or
  "elective" at all**, and its court administrator is *"appointed by the city council"*. ▶ **The
  Grand Forks trap is closed.** ⚠ That zero is trustworthy because the same query returned nine
  "judge" sentences from the same body — the extractor was live, not blind.

### 🔴🔴 "SHALL BE ELECTED" DOES NOT MEAN ELECTED BY THE VOTERS — READ WHO DOES THE ELECTING

**Biloxi's inventory test was that its Chapter 2 contained *no occurrence of "shall be elected" at
all*.** Run against Jackson, that same test returns **three results, and not one is a popular
election**:

| § | office | who elects |
| --- | --- | --- |
| 74-46 | **Chief of Police** | *"shall be elected **by the city council** at the same time as all other officers of the city"* |
| 2-167 | **five school trustees** for the separate school district | *"There shall be elected **by the city council** five trustees…"* |
| 2-37 | **Council President** | the council electing its own presiding officer |

▶ **The phrase alone would have produced three false positives here**, one of them a police chief
and one a five-member school board. The discriminating words are **"by the city council"** against
**"by the qualified electors"**. This is the Maine rotating-chair rule in a new form: *a `Mayor` can
be a rotating chair — read who ELECTS it.*

🟢 **AND THE COMPLEMENTARY ZERO IS REAL.** A code-wide search for **`"qualified electors"` returns
0 results**, and the search engine was proved working first: **`"elected by the city council"`
returns exactly 2** — §§ 74-46 and 2-167, which are precisely the two found by reading the chapters.
**The positive control passed before the zero was believed.**

▶ **INVENTORY: 8 elected offices — Mayor + Wards 1–7. Nothing else in Jackson is elected by voters.**

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

## ✅ APPLIED 2026-10-31 — JACKSON IS SEATED

`CC_0320` (structure) + `CC_0321` (occupancy), plus `scripts/load-jackson-ward-boundaries.mjs` for
the geometry: **7 ward polygons on `X0085`, 8 offices, 8 seated, 0 vacant, 8 people created,
0 reused.** Single-member wards, so the polygon count is the seat count.

| scope | before | after | expected |
| --- | --- | --- | --- |
| `geofence_boundaries` | 75,051 | **75,058** | +7 exact |
| `politicians` | 91,308 | **91,316** | +8 exact |
| `offices` | 10,911 | **10,919** | +8 exact |
| `office_terms` | 11,007 | **11,015** | +8 exact |
| `districts` | 11,232 | **11,240** | +8 exact |
| `chambers` | 1,401 | **1,403** | +2 |
| `governments` | 634 | **635** | +1 |
| `offices_missing_terms` unflagged | 238 | **238** | must NOT move — unmoved |
| CONTROL: MS legislative offices | 174 | 174 | unmoved |
| CONTROL: Biloxi offices | 8 | 8 | unmoved |

Ward areas total **113.40 sq mi**, and **sum of parts = union**, so the seven tile the city with no
overlap. The loader is idempotent: a second run inserted 0 and found 7.

### 🔴🔴 THE PROBE LOOKED BROKEN AND THE DATA WAS RIGHT — THE ADDRESSES WERE THE DEFECT

The first end-to-end probe returned **Ward 7 for four different Jackson addresses**, which reads
exactly like a collapsed or mis-joined geometry. It was none of those. City Hall, Fondren, Lakeland
Drive and Riverside Drive are all in **east Jackson**, and Jackson's Ward 7 is the large eastern
ward. ▶ **A UNIFORM ANSWER IS A BROKEN DETECTOR UNTIL YOU CHECK WHICH END IS BROKEN — and here the
sample was.** The checks that settled it, in order: the office wiring was read row by row (ward N →
"Council Member, Ward N" → the right person, 7/7); the wards were shown not to overlap; and then an
independent anchor set was built.

### 🟢🟢 THE NUMBERING IS ANCHORED OUTSIDE THE GIS, BY THE COUNCIL'S OWN MINUTES

`scripts/verify-jackson-ward-numbering.mjs` proves new Ward N occupies old Ward N's ground, 7/7.
🔴 **That rules out a permutation introduced by the 2024 redraw. It cannot rule out a labelling that
was already wrong in BOTH layers** — a count can be right and mean something else.

So a second check was built from a source outside the GIS entirely.
`scripts/verify-jackson-wards-against-minutes.mjs` harvests the sentence the City Council votes on
for every code-enforcement case —

> *"…for Case #CE-25-619 located at **1237 Grand Ave.** parcel #132-8 **in Ward 5** of the City of
> Jackson…"*

— from 34 published minutes PDFs, geocodes each address with the **Census** geocoder (not the
city's own service, so it cannot inherit the city's labelling) and asks PostGIS which ward contains
it.

**Result: 30 of 30, and every one of the seven wards is represented.** The `--control=shuffle`
rotation collapses it to **0 of 30** and names the exact permutation. 🟢 **Two independent
publishers — the GIS office and the Council clerk — agree ward for ward.**

### ✅ All seven wards answer an address

| anchor (minutes' ward) | council member | mayor | state rep | state senator |
| --- | --- | --- | --- | --- |
| 5822 Baxter Dr (1) | **Ashby M. Foote III** | Horhn | Christopher Bell | J. Walter Michel |
| 716 Kirkley Dr (2) | **Montyne Clay** | Horhn | Christopher Bell | Kamesha B. Mumford |
| 934 Carnation St (3) | **Kenneth Stokes** | Horhn | Earle S. Banks | Hillman Terome Frazier |
| 202 Lindsey Dr (4) | **Brian C. Grizzell** | Horhn | Zakiya Summers | Hillman Terome Frazier |
| 2709 Glenn St (5) | **Vernon Hartley** | Horhn | Ronnie C. Crudup | Sollie B. Norwood |
| 827 Dorgan St (6) | **Lashia Brown-Thomas** | Horhn | Grace Butler-Washington | Sollie B. Norwood |
| 1126 Crestview Ave (7) | **Kevin Parkinson** | Horhn | Earle S. Banks | David Blount |
| CONTROL Mobile, Alabama | — | — | — | — |

⚠ **Jackson scores 3 of 4 plus the mayor.** The county supervisor is stage 3 and is correct to be
missing. 🟢 A nice corroboration fell out: Ward 2's senator is **Kamesha B. Mumford**, who holds
SD-26 — the seat John Horhn vacated to become Mayor, and one of the two the stale Senate list still
called VACANT when MS-2 ran.

### The gates, all watched failing

**Loader: seven controls** — bogus layer · ward-number set · the three name fields agreeing row by
row · the population identity against a figure fetched live from TIGERweb · the coordinate range ·
the cross-plan numbering · the probes and per-ward identity.

**Migrations: nine controls**, each raising its own gate — district count · one office per ward ·
the vacancy flag · an office on a district with no polygon · Ward 2's date · the precision split ·
Ward 1/3 held at `year` · `is_incumbent` · the seated count.

🔴 **FOUR OF THE SIXTEEN WERE SHADOWED OR INERT ON FIRST WRITING, AND ALL FOUR ARE THE SAME LESSON.**

- Loader control 6 (rotate the ward labels) tripped **control 3** first, because rotating `Ward`
  alone makes it disagree with `District` and `Name`. The tamper now rotates **all three together**
  — which is also the realistic defect, since Harrison County's `DIST_ID` permutation was perfectly
  consistent within each row.
- Loader control 7 (displace the wards) tripped **control 5**'s coordinate box, because a shift big
  enough to reach Gulfport leaves Mississippi. The tamper is now a 0.05° nudge.
- 🔴🔴 **AND THE HALO PROBE THAT WAS ADDED TO CATCH IT WAS COMPUTED FROM THE WARD SET'S OWN BOUNDING
  BOX, SO IT TRANSLATED WITH THE TAMPER AND COULD NEVER FIRE.** **A CONTROL DERIVED FROM THE DATA
  UNDER TEST MOVES WITH THE DEFECT.** It is a fixed constant now.
- The Ward 1/3 precision tamper tripped the **6-day/2-year split** gate first. Ward 1 is now moved
  to `day` **and** Ward 4 to `year` in the same tamper, holding the split constant so only the
  specific assertion can fire — MS-3's rule.

⚠ **AND THE FIRST TAMPER HARNESS REPORTED SEVEN SILENT PASSES.** Its `grep` swallowed the error
lines and its `$?` captured `head`, not `node`. **Seven identical silences is a broken detector**;
reading the raw output took one command. The dry-run builder now **asserts the tamper is present in
the file before running it**, and two tampers were caught by that assertion rather than passing
vacuously.

### The dry run

🔴 **THE PAIR WAS NOT HANDED TO `dry-run-migration.mjs`.** That tool strips only the FIRST
`BEGIN`/`COMMIT`, and a concatenated pair once **committed to production while printing
"ROLLED BACK"**. The transaction was built instead, by a script that asserts on the built file:
**0 COMMITs survive, exactly 1 BEGIN, exactly 1 ROLLBACK**, and the file is over 10 KB — because an
empty migration passes every gate it does not contain.

**The rollback was verified to have reverted** — 91,308 / 10,911 / 11,007 / 11,232 / 1,401 / 634 and
zero Jackson rows — before the real apply. ⚠ The seven ward polygons correctly survived it: the
loader writes outside the migration transaction.

### Gates

`check:occupancy` green ("every politicians INSERT names is_incumbent") · `check:migrations` green
(2 added vs `origin/master`) · `check:reservations` green · **`check:reachability` nothing
regressed** — `BAD_GEOMETRY` 4/4, `DEAD_GEOGRAPHY` 17/17, `UNREACHABLE` 7/7, every bucket exactly at
baseline.

### ⚠ Debts carried out of the Jackson wave

- **Ward 1 and Ward 3 are dated to a year**, from a "first elected" statement. Promoting either
  needs an oath record. Stokes's service is explicitly not continuous.
- **The certified 2025 municipal results were never obtained.** The city refers to an archive it
  does not link, and the Hinds County archive has no 2025 entry because the city ran that election.
  It is a public-records request, not a fetch. Nothing in this wave depends on it.
- **No portraits and no banner yet.**

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

## ✅ APPLIED 2026-10-31 — HINDS COUNTY IS SEATED, AND JACKSON SCORES 4 OF 4

`CC_0322` (structure) + `CC_0323` (occupancy), plus `scripts/load-hinds-supervisor-districts.mjs`:
**5 supervisor-district polygons on `G4040`, 28 offices, 28 seated, 0 vacant, 28 people created,
0 reused.**

| scope | before | after | expected |
| --- | --- | --- | --- |
| `geofence_boundaries` | 75,058 | **75,063** | +5 exact |
| `politicians` | 91,316 | **91,344** | +28 exact |
| `offices` | 10,919 | **10,947** | +28 exact |
| `office_terms` | 11,015 | **11,043** | +28 exact |
| `districts` | 11,240 | **11,245** | +5 — the county row is ADOPTED, not created |
| `chambers` | 1,403 | **1,408** | +5 |
| `governments` | 635 | **636** | +1 |
| `offices_missing_terms` unflagged | 238 | **238** | must NOT move — unmoved |
| CONTROL: MS legislative / Harrison / Jackson | 174 / 27 / 8 | 174 / 27 / 8 | unmoved |

### 🟢🟢 NO `X` CODE: MISSISSIPPI'S SUPERVISOR DISTRICTS ARE TIGER COUNTY SUBDIVISIONS

Measured across the whole state: all 82 counties have exactly five `G4040` subdivisions named
"District 1" … "District 5". That is **Miss. Const. art. 6 § 170**, which fixes five supervisor
districts per county — so the uniform answer is the law, not a parser default, and the loader
prints the distribution rather than asserting a number.

🔴 **AND THE METHOD WAS PROVED BEFORE IT WAS USED, ON A COUNTY ANCHORED THE HARD WAY.** Harrison's
own ArcGIS layer carried a `DIST_ID` that was a clean permutation (MS-4).
`scripts/verify-ms-cousub-are-supervisor-districts.mjs` overlaps TIGER's five **Harrison**
subdivisions against the `X0074` polygons MS-4 anchored on 18 certified precincts, 49 polling
places and the certified winners: **diagonal strongest 5/5**, and **0/5** with the labels rotated.

⚠ **SO HARRISON'S X0074 IS A HAND-MADE DUPLICATE OF A LAYER THAT ALREADY EXISTED.** Two Mississippi
counties now hold the same kind of thing two different ways. Harrison's rows are correct and
anchored and were **not** touched. ▶ **This is a debt, not a defect** — consolidating it is a
separate, deliberate act.

### 🔴 A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT — AND IT CAUGHT ONE

The certified 2023 winners and the county's own phone book agree on 26 of 27 and **disagree on the
Coroner**: certified **Sharon Grisham-Stewart**, phone book **Howard**. The Board's own minutes of
**2024-12-02** settle both the fact and the spelling:

> *"Appoint **Jeremiah Howard** Interim Coroner, **Effective January 1, 2025**"*

Grisham-Stewart retired after 25 years; Howard was appointed interim from 2025-01-01 and won the
special election of 2025-12-02 for the remainder. One open term from **2025-01-01**, `how_started`
**`appointed`**. ⚠ **Three spellings circulate** — *Jeremiah* (the Board's resolution), *Jermiah*
(the county phone book), *Jeramiah* (press). The formal resolution is the authority.

### 🔴 THE DATES ARE `year`, AND HINDS IS NOT HARRISON ABOUT THIS

Hinds's Board met **Tuesday 2024-01-02** — the same holiday shift Harrison had, 2024-01-01 being
New Year's Day. But where **Harrison's** minute recites *"for the term of four years commencing on
this date"*, **Hinds's does not**. It records the Board meeting under § 19-3-13, electing Graham
president and Evers vice-president, and approving bonds *"for the four-year term … per Section
25-1-19"*. That proves they **held office** on 2024-01-02; it does not say when the term **began**.
▶ **So the day is not written.** All 24 officers elected in 2023 are `2024-01-01` at `year`
precision. Borrowing another county's recital is exactly what MS-4 refused to do for its own
undated officers.

🔴 **AND THREE ELECTION COMMISSIONERS CARRY NO DATE AT ALL.** Only Districts 2 and 4 were on the
2023 ballot. Districts 1, 3 and 5 (Kidada Brown, Jermal Clark, Felicia McClinton) are named by the
county's phone book — **evidence of incumbency, not of arrival**. They get an open term with
`start_precision => 'unknown'` and a NULL `term_start`, and a gate asserts the NULL.

### ✅ Jackson City Hall returns 17 officeholders, and all four answers

| answer | officeholder |
| --- | --- |
| **council member** | **Kevin Parkinson**, Jackson Ward 7 |
| **county supervisor** | **Bobby McGowan**, Hinds District 5 |
| **state representative** | **Zakiya Summers**, HD-67 |
| **state senator** | **David Blount**, SD-29 |

plus Mayor Horhn, the eight countywide county officers, District 5's Justice Court Judge, Constable
and Election Commissioner, and the U.S. Representative. **Raymond and Clinton** return county, state
and federal but no city offices; **Gulfport** returns Harrison's officials; **Mobile, Alabama**
returns nothing.

### The gates, all watched failing

**Loader: five controls** — the district number set · the population identity against a live
TIGERweb figure · the coordinate range · **the five tiling the county polygon** (100.00% clean,
74.79% with one withheld) · out-of-county probes.

🔴🔴 **AND ONE CONTROL FAILED A CLEAN RUN, CORRECTLY REPORTING A DEFECT THAT WAS ITS OWN.** The
per-district identity check first used the mean of the largest ring's vertices as an "interior
point". **THE CENTROID OF A RING IS NOT GUARANTEED TO BE INSIDE IT.** For Jackson's compact wards it
landed inside every time; for Hinds's large irregular District 5 it landed inside **District 4** and
reported correct data as broken. It now uses `ST_PointOnSurface`, which PostGIS guarantees is inside
the polygon — in both the pre-write control and the post-write re-check.

**Migrations: nine controls**, each raising its own gate — office count · four offices per district ·
28 distinct titles · an office on a district with no polygon · the Coroner's date and `how_started` ·
an undated commissioner given a date · `is_incumbent` · the term count · the district count.

🔴 **THREE WERE SHADOWED ON FIRST WRITING AND WERE RE-AIMED**, which is now the expected outcome
rather than a surprise: the per-district tamper tripped the **total office count**, the no-polygon
tamper tripped the **district count**, and a title tamper did not apply at all (the builder's own
"tamper must be present" assertion caught it). The working versions move one constable between
districts, retitle every district office without changing any count, and **delete a polygon inside
the transaction** so only the geometry gate can see it.

**The rollback was verified to have reverted** — 91,316 / 10,919 / 11,015 / 11,240 / 1,403 / 635 and
zero Hinds rows — before the apply.

`check:occupancy` · `check:migrations` · `check:reservations` green; **`check:reachability` nothing
regressed** — 4 / 17 / 7, every bucket at baseline.

### ⚠ Debts carried out of the Hinds wave

- **24 officers at `year` precision**, because Hinds's organising minute has no commencement recital.
- **Three Election Commissioners undated.** 🔴 **Do not copy 2024 onto them.**
- **The District Attorney (Circuit Court District 7) is not seated** — multi-county, like Harrison's.
- **The Hinds County School District board is not seated.** It is a different government with its own
  boundary, serving the county outside Jackson, and this wave did not load it.
- **Harrison's `X0074` duplicates TIGER `G4040`** — see above.
- **No portraits for any of the 28.**

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
