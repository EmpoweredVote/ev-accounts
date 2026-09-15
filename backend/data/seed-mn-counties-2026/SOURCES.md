# MN-4 sources — St. Louis and Ramsey county boards

Wave: Knight slice 5, stage 4. Opened **2026-09-15**. Leases `county:27137` and `county:27123`
held by chris@empowered.vote on DESKTOP-G6KDNN2. Slice notes:
[`.planning/knight-foundation/mn.md`](../../../.planning/knight-foundation/mn.md).

**Status: office lists settled from statute, both boundary layers found and inspected, rosters
identified. The per-member change-check, the coverage gates and the migrations are NOT done.**

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

## Rosters as at 2026-09-15 — identified, NOT yet change-checked

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

## ▶ What MN-4 still owes

1. **The per-member change-check**, all 19 of them, against each officer's own page — including
   the three St. Louis constitutional officers, whose terms are reported as expiring at the end of
   2026 and whose current holders must be confirmed rather than inferred from a candidacy story.
   🔴 MN-3's finding applies directly: for a body like this the signal is an **expired date**, not
   a banner, and a word scanner is blind to it.
2. **Term starts.** St. Louis publishes expiries per commissioner; Ramsey does not appear to.
3. **The coverage gate on both layers** — the measurement that separated Duluth's two maps. Neither
   county has been measured against its `G4020` county polygon yet.
4. **Two `X` codes** for the commissioner-district layers, checked free in production *and* across
   every git ref, and **two migration slots** from the allocator.
5. **An address probe per county.** Duluth City Hall and Saint Paul City Hall already have geocoded
   points and should now return a commissioner as well — Duluth sits in St. Louis County, Saint
   Paul in Ramsey.
