# MN-4 sources — St. Louis and Ramsey county boards

Wave: Knight slice 5, stage 4. Opened **2026-09-15**. Leases `county:27137` and `county:27123`
held by chris@empowered.vote on DESKTOP-G6KDNN2. Slice notes:
[`.planning/knight-foundation/mn.md`](../../../.planning/knight-foundation/mn.md).

**Status: ✅ APPLIED 2026-09-15.** All 19 offices created and seated — `X0054`/`X0055` boundaries
loaded, `CC_0111` and `CC_0112` applied and re-run idempotent, **52 gate verdicts with every gate
watched failing first**, probe green. See the record at the foot of this file.

---

## Baseline, measured against production 2026-09-15

| | St. Louis (`27137`) | Ramsey (`27123`) |
| --- | --- | --- |
| `districts` COUNTY row | ✅ present, `G4020` | ✅ present, `G4020` |
| County polygon | ✅ present | ✅ present |
| `governments` row | **none** | **none** |
| Offices / officials | **none** | **none** |

Every MN `COUNTY`-type office count in production is **0**. Both counties are a clean seed.

Neither is a consolidated city-county, so the program spec's §3.2 does not apply: stage 4 keeps
both the county board **and** the separately elected county officers.

---

## 🔴🔴 THE TWO COUNTIES DO NOT ELECT THE SAME OFFICES, AND THE DIFFERENCE IS STATUTORY

Minnesota's general rule, **Minn. Stat. § 382.01**, is that every county elects an **auditor,
treasurer, sheriff, recorder, attorney and coroner**. Neither of these counties matches it, and
they do not match each other. Each is governed by its own **special law**, which is what actually
decides the question — identified from Minnesota House Research, *County Offices: Combining or
Making Appointed*, and then read at the statute itself.

### Ramsey — **9 elected offices**: 7 commissioners + Sheriff + County Attorney

**Minn. Stat. § 383A.20**, subd. 2(a): *"the offices of county auditor, county treasurer, court
commissioner, and county recorder are not elective but filled by appointment by the Ramsey County
Board of Commissioners."*

Ramsey is the **only home rule charter county in Minnesota** — all 86 others are governed by
general law. Its sheriff and county attorney remain elective; so does the board.

⚠ **A SEARCH SUMMARY SAID THE AUDITOR WAS STILL ELECTED IN RAMSEY, AND IT WAS WRONG.** One
retrieval asserted "the county auditor/treasurer continues to be an elective position in Ramsey
County" in the same breath as a list of elective offices that did not include it. The statute
settles it, and a summary that contradicts itself in adjacent sentences is not a source.

### St. Louis — **10 elected offices**: 7 commissioners + Sheriff + County Attorney + Auditor

**Minn. Stat. § 383C.136**: *"the duties and functions of the county treasurer shall be transferred
to and be performed by the county auditor, and the office of county treasurer is abolished"* (1969),
and no person was to be elected after 1986 to succeed the county recorder — *"In 1991 the county
board shall appoint a county recorder to serve at its discretion."*

So St. Louis elects an **Auditor** carrying the treasurer's functions, commonly styled
**Auditor/Treasurer**, which Ramsey does **not** elect at all.

### Coroner: neither county elects one

Both use an appointed medical examiner rather than an elected coroner. Ramsey's own Medical
Examiner is **appointed by the county board** and serves Ramsey and Washington counties; St. Louis
**contracts with the Midwest Medical Examiner's Office**, so it has no county coroner post of any
kind. Minnesota counties have been consolidating into five regional offices, and § 382.01's coroner
is no longer live in either.

▶ **Nine and ten, not "the usual six".** This is the Fort Wayne rule again: read what the governing
instrument says, and do not carry one jurisdiction's answer to the next.

---

## Boundary sources

| County | Service | Layer | Features | Roster field |
| --- | --- | --- | --- | --- |
| **St. Louis** | `gis.stlouiscountymn.gov/server2/rest/services/GeneralUse/Open_Data/MapServer` | **21 — County Commissioner Districts** | 7 | `REPNAME1` ✅ populated |
| **Ramsey** | `gis.ramseycountymn.gov/server/rest/services/Boundary/BOUND_CommissionerDistrict2022_ViewOnly/FeatureServer` | **25** | 7 | `Name` ✅ populated |

🟢 **BOTH CARRY A POPULATED ROSTER FIELD**, so the vintage test used for Duluth and Saint Paul —
compare the layer's own member names against the independently verified roster — is available for
both. Fort Wayne's equivalent field was empty and the test was unavailable there.

### ⚠ Ramsey's GIS host moved, and MN-1's recorded URL is dead

MN-1 recorded Ramsey's `OpenData/OpenData` MapServer (52 layers, **layer 2 = Commissioner
Districts**) but not its host. The county has since moved from **`ramseycounty.us`** to
**`ramseycountymn.gov`**, and `gis.ramseycounty.us` no longer resolves at all.

⚠ **THE 404 THAT FOUND IT WAS ABOUT THE PATH, NOT THE HOST.** `gis.ramseycountymn.gov` answers —
it returned 404 for `/arcgis/rest/services/...` because this server publishes under
**`/server/rest/services/...`**. A negative result is only ever true of the place you looked. The
service was located instead through its ArcGIS Online item, owned by the county's own
`RamseyGIS` / `RCGISAdmin` accounts.

⚠ **THE LAYER INDEX IS 25, NOT 0.** The item URL ends `/FeatureServer/25`; a request for `/0`
returns an empty object rather than an error. Third wave running, third non-obvious layer number.

⚠ **THE COUNTY'S OWN LAYER IS HALF-MIGRATED**: its `Email` values use `ramseycountymn.gov` while
its `Web` values still point at `ramseycounty.us`. Do not take a URL out of a boundary layer.

⚠ **`BOUND_CommissionerDistrict2022` NAMES ITS VINTAGE, AND THAT IS NOT PROOF.** The name says
2022, which is the post-2020-census redistricting that also redrew Saint Paul's wards. Duluth's
superseded map carried plausible populations and a recent item date and was still the wrong map —
**the coverage measurement is the test**, and it has not been run yet for either county.

---

## Rosters as at 2026-09-15

Each county's board page and its GIS layer agree, name for name.

### St. Louis County — 7 commissioners, staggered

🟢 The county publishes a **term-expiry date per commissioner**, which MN-3 established is both a
term source and the change-check signal for a body like this.

| District | Commissioner | Term expires |
| --- | --- | --- |
| 1 | Annie Harala | 2027-01-04 |
| 2 | Patrick Boyle | 2029-01-09 |
| 3 | Ashley Grimm | 2029-01-09 |
| 4 | Paul McDonald | 2027-01-04 |
| 5 | Keith Musolf — *Vice Chair* | 2029-01-09 |
| 6 | Keith Nelson | 2027-01-04 |
| 7 | Mike Jugovich — *Chair* | 2029-01-09 |

Three expire 2027 and four expire 2029, so the board is staggered 3/4 — **not uniform**, which is
the distribution check that caught Duluth's four stale at-large pages.

Plus **Sheriff Gordon Ramsay**, **County Attorney Kimberly J. Maki**, **Auditor/Treasurer Nancy
Nilsen** — all three reported as up at the **2026-11-03** general.

### Ramsey County — 7 commissioners

| District | Commissioner |
| --- | --- |
| 1 | Tara Jebens-Singh |
| 2 | Mary Jo McGuire |
| 3 | Garrison McMurtrey |
| 4 | Rena Moran |
| 5 | Rafael E. Ortega — *Chair* |
| 6 | Mai Chong Xiong — *Vice Chair* |
| 7 | Kelly Miller |

Plus **Sheriff Bob Fletcher** and **County Attorney John Choi**.

⚠ The board page writes **"Rafael E. Ortega"** and the GIS layer writes **"Rafael Ortega"** — the
middle-initial variance MN-2 met repeatedly. Compare on a token-suffix surname test, not on the
whole string.

---

# The change-check — done 2026-09-15

All **19** officers' pages fetched and read: **19/19 HTTP 200, 19/19 naming the person the roster
says holds the seat, and ZERO stated terms already expired.** Roster:
[`backend/data/mn-counties-roster.json`](../mn-counties-roster.json).

Both signals ran over every page, because MN-2 and MN-3 each found a different one — a **word**
banner and an **expired date** — and neither alone is enough. All six controls fired.

## 🟢 The expired-date signal came up clean, and the distribution is why that is believable

St. Louis publishes a term expiry per commissioner. **Three expire 2027-01-04 and four expire
2029-01-09** — a 3/4 stagger, *not* uniform, which is exactly the check that exposed Duluth's four
identical stale at-large dates. Ramsey publishes no expiry at all.

## 🔴 THE TWO ST. LOUIS EXPIRY COHORTS FOLLOW DIFFERENT RULES, SO NEITHER GIVES A DAY

MN-3 derived Duluth's `term_start` as *expiry − 4 years* because every published expiry was a
**first Monday in January**, the boundary Duluth's charter names. That arithmetic does **not**
carry here:

| Stated expiry | Weekday | First Monday of that January |
| --- | --- | --- |
| 2027-01-04 | **Monday** ✅ | 2027-01-04 — matches |
| 2029-01-09 | **Tuesday** ❌ | 2029-01-01 — eight days earlier |

**Minn. Stat. § 375.01** is why: a commissioner serves four years *"and until their successors
qualify"*, and qualification happens at the board's organizational meeting — the first Tuesday
after the first Monday — not on a fixed calendar day. § 382.01's clean first-Monday rule governs
the **constitutional officers**, not the board.

▶ So commissioner starts are written at **`year`** precision (St. Louis) or **`month`** (Ramsey,
whose pages say "began her term in January 2025" and give no day), and only the five constitutional
officers get **`day`**. CLAUDE.md sanctions exactly this: a source that gives only a year is passed
as January 1 at `year` precision rather than guessed to a day.

⚠ **The resulting precision mix is 5 `day` · 7 `month` · 7 `year`, and its unevenness is the
point.** MN-3's 18 were all `day`; flattening these 19 to match would have been a fabrication.

### 🔴🔴 THE PROSE ABOVE AND THE ROSTER DISAGREED, AND THE PROSE WAS RIGHT (corrected 2026-09-15)

This line first read **8 `day` · 4 `month` · 7 `year`**, and the roster JSON matched it: Ramsey's
**Moran, Ortega and Xiong** each carried `2023-01-02` at **`day`**. That is § 382.01's first Monday
in January — **the date the paragraph immediately above rules out for the board.** § 375.01 gives a
commissioner four years *"and until their successors qualify"*, which is why St. Louis's own two
expiry cohorts land on a **Monday** and a **Tuesday**. None of the three pages states a day; each
was read again to confirm it, and none does.

So the three are written **`2023-01-01` at `month`** — the month is certain, the day was not — and
the mix is **5 · 7 · 7**. The five `day` rows are now **exactly the five constitutional officers**,
which is what this section's own sentence claimed all along.

▶ **A migration is where a roster's internal contradiction gets spent.** The defect was invisible
in every count the wave had taken (19 officers, 19 seated, 0 undated) and visible only in the
sentence next to it. `CC_0112`'s post-verify now asserts the mix **and** that no commissioner
carries a day, so it cannot come back.

## 🔴 Three pages state a FIRST swearing-in, and it reads exactly like a term start

| Officer | Page says | Actual current term |
| --- | --- | --- |
| **Nancy Nilsen**, St. Louis Auditor | *"sworn in on January 3, 2019"* | re-elected **2022-11-08**, 60,787–13,838 |
| **Rafael E. Ortega**, Ramsey D5 | *"elected to the Ramsey County Board in 1994"* | re-elected **2022-11-08** |
| **Mary Jo McGuire**, Ramsey D2 | *"has served … since 2012"* | re-elected **2024-11-05** |

This is MN-3's Nelsie Yang trap three more times. A biography states when someone *arrived*; the
wave seats the term they hold *now*.

## 🔴 "ELECTED IN 2023" IN A BODY THAT VOTES IN EVEN YEARS — AND IT WAS NOT A SPECIAL ELECTION

Ramsey District 6's page says Mai Chong Xiong was *"elected in 2023"*. Minnesota county
commissioners are elected in **even** years, so that reads as a special election. It is not one:
she **assumed office on 2023-01-02**, having been elected in November 2022. The page is describing
the year she took her seat.

▶ **A biography's loose phrasing is not an election record.** Chasing it to the election result is
what settled it, and the same instinct is what *correctly* found the one real special election.

## 🔴 One genuine mid-term change, in 19

**Ramsey District 3.** Trista Martinson resigned; **Garrison McMurtrey won the special election on
2025-02-11** and began his term that February — the first Black man elected to a county board in
Minnesota. A blanket "elected 2024" would have been wrong for this seat, and only the per-member
read found it. Every other one of the 19 is a regular-cycle winner.

## The five constitutional officers were all elected on the same day, and that is structural

Fletcher, Choi, Ramsay, Maki and Nilsen were **all** elected **2022-11-08**, so all five start at
**2023-01-02** — the first Monday in January, per § 382.01. A uniform answer normally needs
suspicion; here it is correct by construction, because Minnesota runs every county officer on the
gubernatorial cycle. It was still corroborated from **five separate election results**, not
inferred once and copied.

⚠ St. Louis's sheriff page says he was *"sworn in as Sheriff on January 10, 2023"*. That is the
**ceremony**; § 382.01 begins the term on 2023-01-02, and the statutory date is what is recorded.

## ⚠ All five are on the 2026-11-03 ballot

Their four-year terms end in January 2027. The standing rule applies: seat who holds the seat
today, and re-run this check if the wave slips past early November.

## ✅ ALL THREE DELIVERED — MN-4 APPLIED 2026-09-15

1. **`X0054` (St. Louis) and `X0055` (Ramsey)**, checked free in production *and* across all **154
   git refs**, the ref scan positive-controlled against `X0052`/`X0053` (12 and 14 hits) so its
   zero was a real zero. Slots **`CC_0111`** (structure) and **`CC_0112`** (occupancy), both
   reserved from the allocator and named that number straight away.
2. Both migrations dry-run as **one transaction**, and the rollback verified: 2 governments, 7
   chambers, 14 districts, 19 offices, 19 people and 19 seats inside the transaction — **every one
   of them back to 0 after the `ROLLBACK`**, with the 14 boundary rows left intact. Both then
   applied, and **both re-run to prove idempotence**: every real `INSERT` returned 0 the second time.
3. **The probe is green** — see below.

---

# ✅ Applied — what is in production

| | St. Louis (`27137`) | Ramsey (`27123`) |
| --- | --- | --- |
| Government | `St. Louis County, Minnesota, US` | `Ramsey County, Minnesota, US` |
| Chambers | **4** — Board, Sheriff, County Attorney, **Auditor** | **3** — Board, Sheriff, County Attorney |
| Commissioner districts | 7 on `X0054` | 7 on `X0055` |
| Offices / seated | **10 / 10** | **9 / 9** |

Terms: **19 dated, 0 undated, 0 with a `term_end`**, precision **5 `day` · 7 `month` · 7 `year`**.

## ✅ 52 gate verdicts, and every gate was watched failing first

**24 loader verdicts** (`scripts/load-mn-county-commissioner-boundaries.ts --control`, 12 controls
each asserting what it planted) and **28 migration gates**
(`control-mn4-migration-gates.mjs`, which splits each migration at its post-verify banner so the
gate text being judged is the real one, letter for letter).

## 🔴🔴 TWO OF MY OWN CONTROLS PLANTED THE WRONG THING, AND BOTH LOOKED LIKE PASSES

MN-3 ended on *a control that aborts for the wrong reason proves nothing*. This wave produced the
next form of it: **a control that plants a real change in the wrong place.**

- The St. Louis coverage control removed **district 1** to orphan Duluth — the county's largest
  city, and district 1 reads like the first one. **Duluth is in DISTRICT 3.** GATE 3 and GATE 3P
  both passed, because Duluth's interior point was still covered.
- The Ramsey control removed **district 4** to orphan Saint Paul. **Saint Paul is in DISTRICT 5**;
  district 4 lies wholly inside the city and holds no place interior point at all.

Both now **measure which district actually holds the place** and assert the place is in **0**
districts before any gate is allowed to judge. ▶ **Assert the consequence you planted, not the
action you took.**

## 🔴🔴 THE HOLED MAP STILL SCORED 97.682% — THE PERCENTAGE NEVER WOULD HAVE CAUGHT IT

With Duluth's district removed, St. Louis covers **97.682%** — a 0.5-point drop from 98.220%, and
*above* the 97% backstop. The clause that refused it was the decomposition: a **157.597 sq mi** gap
piece that **contains Duluth**. GATE 3P said the same thing in one line: *1 of 27 incorporated
places sits in 0 commissioner districts.*

▶ This is the measured proof of the section above. **A single percentage is not a gate**, and the
one that would have been copied from MN-3 (99.9%) and the one chosen here (97%) would *both* have
got this wrong — one by refusing a correct map, the other by accepting a broken one.

## 🔴 ST. LOUIS'S LAYER SELF-OVERLAPS, AND MN-3's GATE 4 REFUSED IT

**11 overlapping district pairs totalling 0.022856 sq mi**, the worst `D4×D6` at 0.018929 — against
MN-3's flat threshold of 0.001. Ramsey has **zero**. This is the same line-work noise as the 912
sliver gaps, on a county 40× the area with 40× the boundary to leave it on.

So GATE 4's tolerance is **per county and measured**: St. Louis 0.03 per pair / 0.05 total, Ramsey
0.001 / 0.001. Both were watched refusing a planted 8+ sq mi overlap, so the looser number is still
a gate. ⚠ And the loader now **prints the measurement beside the verdict** — it first said *"no
overlapping district pairs"* for a layer with eleven of them.

## ✅ The probe, and three waves stacking

| Anchor | Answers | From MN-4 |
| --- | --- | --- |
| **Duluth City Hall** | **13** | Commissioner D1 *Annie Harala*, Sheriff, County Attorney, **Auditor/Treasurer** |
| **Saint Paul City Hall** | **8** | Commissioner D5 *Rafael E. Ortega*, Sheriff, County Attorney |
| **Hibbing City Hall** | **7** | Commissioner D7 *Mike Jugovich*, Sheriff, County Attorney, Auditor/Treasurer |

A Duluth address now returns its councilor (MN-3), its legislators (MN-2) and its county officers
(MN-4) together. 🟢 **The probe asserts the statutory asymmetry directly**: an auditor seat must
come back for St. Louis and must **not** for Ramsey.

**Per-district control: 14 of 14**, each at its own interior point, each returning exactly one
holder and the right one, 14 distinct names.

## ⚠ MN-3's OFFSHORE CONTROL POINT DOES NOT TRANSFER, AND IT FAILED LOUDLY

MN-3 used a point 20 km out in Lake Superior (−91.85, 46.95) to prove a city-council probe returns
nothing offshore. Reused here it **returned a commissioner — correctly**: it is inside St. Louis
County, whose districts run out into the lake. ▶ **A negative control must be outside the thing
being tested, not outside the last thing that was tested.** The controls are now in Ashland County
WI, Keweenaw County MI, Hennepin County MN and Madison WI, and the probe carries a positive control
proving it is not simply blind.

## 🟢 The known lake wedge is characterised in the probe, not hidden

A point at (−91.8825, 46.8566) — inside the 120.593 sq mi wedge the loader accepted — returns the
**three countywide officers and no commissioner**. That is the exact, honest price of 98.220%, and
it is asserted so nobody rediscovers it as a bug.
