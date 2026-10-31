# Boise, Idaho — verified roster, 7 elected seats

**Wave:** Idaho deep seed, 2026-10-30. **Migration:** `CC_0312` (+ `CC_0314` portraits).
**Keys:** `geo_id 1608830`, `mtfcc G4110`. ⚠ TIGER's BASENAME is **"Boise City"**, not "Boise" —
the city's legal name is *City of Boise City*. A name search for "Boise" alone is a false-absence
trap; match the GEOID.

🟢 **BOISE IS STABLE UNTIL NOVEMBER 2027 AND IS SAFE TO SEED NOW.** Idaho municipal elections are
odd-year. Districts 2, 4 and 6 were decided 2025-11-04; districts 1, 3, 5 and the Mayor are next on
the ballot in November 2027. **Nothing here is affected by the 2026-11-03 general election.**

## Sources

| # | Source | What it is | Pulled | File |
| --- | --- | --- | --- | --- |
| 1 | `cityofboise.org/departments/city-council/` | Council landing page, all six members | 2026-10-30 | `boise_council.html` |
| 2 | `cityofboise.org/departments/city-council/council-district-N/` | One page per district, N = 1..6 | 2026-10-30 | `boise_d1..6.html` |
| 3 | `cityofboise.org/departments/mayor/` | Mayor's office | 2026-10-30 | `boise_mayor.html` |
| 4 | `ballotpedia.org/Boise,_Idaho` | Independent roster + date assumed office | 2026-10-30 | `bp_boise.html` |
| 5 | Ballotpedia person pages | Per-member assumed-office date | 2026-10-30 | `bp_<Name>.html` |
| 6 | `services1.arcgis.com/WHM6qC35aMtyAAlN/.../BoiseCityCouncilDistricts/FeatureServer/0` | **Operative** council district geometry, published by Boise_GIS | 2026-10-30 | `boise_council_districts_LIVE.geojson` |
| 7 | the same server's `Boise_City_Council_Districts_2021` | **SUPERSEDED** first districting map — kept only as the control | 2026-10-30 | `boise_council_districts.geojson` |

## 🔴 Source defects found

1. 🔴🔴 **ARCGIS HUB SEARCH RETURNS THE SUPERSEDED MAP FIRST, AND IT PASSES EVERY CHEAP CHECK.**
   Searching Hub for "Boise city council district" returns `Boise_City_Council_Districts_2021`.
   That is Boise's **first** districting plan, used only for the 2021 election; the city redrew on
   2020 census data for 2023. The two layers **cannot be told apart by count or by area** — both
   have exactly 6 districts, and their geodesic areas are 225.8 km² and 227.4 km², both matching
   Boise's ~87 sq mi. Both correctly exclude Garden City, Meridian and Eagle.
   **They disagree on where people live:** of six test points, three land in a different district —
   the North End 3→6, Bown Crossing 4→5, Collister 3→6.
   ▶ **The operative layer is `BoiseCityCouncilDistricts`**, established two ways: it is the layer
   behind the Zone Lookup app embedded on the city's own `council-districts` page (item
   `d9a911286a8641d589ab3336adff74e6` → web map `a70d7986…` → that layer), and it carries a
   `CouncilMember` attribute the city keeps current. The `_2021` layer carries no names.
   🔴 **Do not re-resolve this from a Hub search. Resolve it from the city's published app.**

2. 🔴 **TWO COUNCIL CARDS CARRY A LEGACY AT-LARGE SEAT NUMBER THAT COLLIDES WITH THE DISTRICT
   NUMBERS.** On the council landing page, Colin Nash's card is headed **"Council Seat 5"** while its
   body reads "Council District 2", and Jimmy Hallyburton's is headed **"Council Seat 3"** while its
   body reads "Council District 6". Those are the at-large seats they held before Boise districted.
   A parser keying on the card heading seats Nash in District 5 (Stead's) and Hallyburton in
   District 3 (Corless's) — **two double-seated districts and two empty ones, all plausible-looking.**
   ▶ Overruled by four independent signals: the per-district page URLs, those pages' body text,
   Ballotpedia, and the `CouncilMember` attribute on the city's own GIS layer.

3. 🔴 **"SERVING SINCE YYYY" ON THE CITY SITE MEANS THREE DIFFERENT THINGS AND MUST NOT BE USED FOR
   `term_start`.** Measured against Ballotpedia: for Willits/Corless/Morales it is the seating year;
   for Nash and Stead it is the **election** year (2023) for a seat they took in January 2024; for
   Hallyburton it is **2020**, which is his prior **at-large** service, a different office from
   District 6. Ballotpedia's per-member dates are internally consistent and are used instead.

## Charter rulings

- **Six single-member districts plus a separately elected Mayor** — seven elected offices, no
  at-large council seats. Districts since the 2021 election, under the 2020 Idaho law requiring
  cities over 100,000 to elect by district.
- **Four-year staggered terms.** All six districts were on the 2023 ballot; odd districts drew
  four-year terms and even districts two-year terms, which is what staggered them. Odd districts
  (1, 3, 5) and the Mayor run in 2027; even districts (2, 4, 6) ran in 2025 and run next in 2029.
- **Nonpartisan.** No party is written for any Boise row.

## Roster

| Office | District | Name | term_start | precision | Note |
| --- | --- | --- | --- | --- | --- |
| Mayor | citywide | Lauren McLean | 2020-01-07 | day | |
| Council Member | 1 | Luci Willits | 2022-01-11 | day | Won Nov 2021, re-elected 2023 — occupancy unbroken |
| Council Member | 2 | Colin Nash | 2024-01-09 | day | Re-elected 2025-11-04; occupancy unbroken |
| Council Member | 3 | Kathy Corless | 2024-01-09 | day | Council Pro Tem |
| Council Member | 4 | Jordan Morales | 2024-01-09 | day | |
| Council Member | 5 | Meredith Stead | 2024-01-09 | day | Council President |
| Council Member | 6 | Jimmy Hallyburton | 2024-01-09 | day | Re-elected 2025-11-04; prior at-large service is a *different* office |

## Geometry control

Run against `boise_council_districts_LIVE.geojson`, point-in-polygon:

| Point | District | Result |
| --- | --- | --- |
| Boise City Hall (43.6154, -116.2019) | 5 | exactly one ✓ |
| Boise State University | 5 | exactly one ✓ |
| Boise Airport | 4 | exactly one ✓ |
| Garden City Hall | — | correctly claimed by none ✓ |
| Meridian City Hall | — | correctly claimed by none ✓ |
| Eagle City Hall | — | correctly claimed by none ✓ |

`DistrictID` values 1..6, six distinct, no gaps.

## Counts, for the payload guard

| Measure | Value |
| --- | --- |
| Council districts (geometry) | 6 |
| Offices | 7 (1 Mayor + 6 Council) |
| Seated | 7 |
| `start_precision = day` | 7 |

## ▶ Open items

- **November 2027:** Mayor and districts 1, 3, 5. Nothing is stale before then.
- ⚠ Boise's council district geometry is **not** a TIGER layer. If it is ever reloaded, take it from
  the city's published app, not from a Hub search — see defect 1.
