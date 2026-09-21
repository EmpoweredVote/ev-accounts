# MN-1 sources — L2022 identity anchors

Wave: Knight slice 5, stage 1. Plan:
[`docs/superpowers/plans/2026-09-12-knight-mn-1-geography.md`](../../../docs/superpowers/plans/2026-09-12-knight-mn-1-geography.md).
Resolved **2026-09-12**. Machine-readable anchors: [`anchors-L2022.json`](./anchors-L2022.json).

## Sources

| # | Source | URL | Used for | Retrieved |
| --- | --- | --- | --- | --- |
| S1 | **Minnesota Legislative Coordinating Commission GIS** — "Who Represents Me" point service | `https://gis.lcc.mn.gov/iMaps/districts/php/getPointData.php?lat=&lng=` | all four anchors: Senate + House district at a point | 2026-09-12 |
| S2 | MN LCC GIS — L2022 plan publication | `https://gis.lcc.mn.gov/redist2020/plans.php?plname=L2022&pltype=court` | plan identity, order date, 67/134, A/B labelling | 2026-09-12 |
| S3 | US Census Bureau geocoder | `https://geocoding.geo.census.gov/geocoder/locations/onelineaddress` (benchmark `Public_AR_Current`) | address → lon/lat | 2026-09-12 |
| S4 | Duluth News Tribune; Wikipedia; Ballotpedia (McEwen, MN 8th Senate district) | see "Vintage proof" | proving S1 carries L2022 and not the 2012 plan | 2026-09-12 |
| S5 | TIGERweb Places layer 4 | `https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/Places_CouSub_ConCity_SubMCD/MapServer/4` | place GEOIDs `2717000`, `2758000` | 2026-09-12 |

### How S1 was found

It is not documented. `gis.lcc.mn.gov/iMaps/districts/` is a Mapbox GL app whose HTML contains **no**
ArcGIS or service URLs at all — a grep of the page returns nothing. The endpoint is in the app's own
`js/app.js`, in `identifyDistrict()`, which issues `$.ajax('php/getPointData.php', {lat, lng})`.

▶ This is GA-5's rule again: **when a jurisdiction publishes no documented service, ask what its own
lookup tool queries.** A negative result from the HTML is a fact about the HTML, not about the site.

## 🔴 Vintage proof — S1 carries L2022, not the 2012 plan

This is the point of the whole task. **Minnesota had 67 Senate and 134 House districts under the
2012 plan too, with the same `1A`/`1B` labelling.** The two plans are indistinguishable by count, by
shape and by label format. A loader reporting "67 and 134" has proved nothing.

The discriminator is a district that was **renumbered** between the plans:

> Duluth's Senate district was **District 7** under the 2012 plan and is **District 8** under L2022.
> Jen McEwen was elected in 2020 and served **District 7 from 2021 to 2023**; the seat was renumbered
> to **District 8** in redistricting, and she was re-elected there in November 2022. (S4)

**S1 returns Senate District `08` for Duluth City Hall.** That answer is only correct under L2022.

▶ **The same test gates the TIGER load.** After `sldu` is loaded, Duluth City Hall must resolve to
Senate District 8. **If it resolves to 7, TIGER has handed us the 2012 plan** and the load must be
rolled back, not patched.

## ⚠ Every anchor is SINGLE SOURCE

FL-1 obtained a second, government-domain confirmation for two of its three anchors and recorded
plainly that Bradenton had only one. **MN-1 is weaker than that: none of the four anchors has a
second geographic source.** Stating it rather than quietly shipping it:

| Searched | Result |
| --- | --- |
| Ramsey County `OpenData/OpenData` MapServer (52 layers) | **no legislative layer.** Has `Commissioner Districts` (layer 2) — valuable for **stage 4**, not stage 1 |
| Ramsey County `MapRamsey/MapRamseyDistrict` | one layer, `Boundaries` — not legislative |
| Ramsey County `MapRamseyOperationalLayersAll` (60 layers) | none legislative; the layer set is cadastral and survey. All 60 names were printed and read, so this is not a filter artefact |
| MN Secretary of State precinct finder | **blocked by a Radware bot manager** (302 to `validate.perfdrive.com`). Not followed. Per the repo rule, a WAF rejection can arrive as HTTP 200/202, so this needs Playwright, not `curl` |
| St. Louis County ArcGIS | two **guessed** endpoints returned empty / 404. ⚠ **Guessed endpoints prove nothing** — a negative result is only ever true of the place you looked. St. Louis County has **not** actually been searched |

▶ **Owed, and cheap:** search St. Louis County GIS properly, and retry the SOS finder in Playwright.
Either would raise Duluth to two sources. Neither blocks the load, because S1 is the enacted plan's
own publisher and its vintage is independently proved above.

## The A/B discriminator pair

The MN-1 plan asked for a third anchor in a different Saint Paul district. The obvious candidate —
the **State Capitol** — turned out to return **byte-identical** GeoJSON to Saint Paul City Hall
(sha256 `5537db17f99f`, both 56,780 bytes). It is the same district, `65`/`65B`, so it discriminates
nothing. It is recorded as rejected in `anchors-L2022.json` rather than dropped silently.

What replaced it is stronger than what was asked for:

| Anchor | Senate | House |
| --- | --- | --- |
| 235 Marshall Ave, Saint Paul | **64** | **64A** |
| 1200 Montreal Ave, Saint Paul | **64** | **64B** |

**Two points in the same Senate district and different House districts.** This is the one test that
catches Minnesota's specific failure mode: an `sldl` load that collapses each Senate district's two
halves into one, or swaps A with B. No single point can detect either. Both anchors must pass.

## ⚠ Two things this service returns that must NOT be carried

1. **Party.** Each feature carries a `party` property (`DFL`, `R`). The repo is **antipartisan by
   design**: party lives on `races.primary_party`, never on a person or an office. Do not import it.
2. **Members.** The service names the sitting legislator at each point. That is useful as a **stage 2
   cross-source**, but it is not the roster — the roster needs two independent sources diffed, per
   spec §4, and a change-check for departures the sources postdate.

## Parameter control

`getPointData.php` was confirmed to read its arguments rather than return a default: Duluth returns
355,211 bytes and a different district set from Saint Paul's 56,780. The two Saint Paul downtown
points returning identical bytes is a true same-district answer, not a cache — Duluth proves the
parameters bite.
