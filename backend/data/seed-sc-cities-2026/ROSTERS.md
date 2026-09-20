# Columbia and Myrtle Beach — SC-3 roster

Wave **SC-3** of the Knight Foundation cities programme, slice 7. The machine-readable roster is
[`data/sc-cities-roster.json`](../sc-cities-roster.json); the migrations are generated from it by
`scripts/gen-sc-cities-migrations.mjs`, and `scripts/verify-sc-cities-roster.mjs` change-checks it
against both cities' pages and a directory neither city maintains.

**14 seats — 7 Columbia + 7 Myrtle Beach. 0 vacancies.**

Slice notes: [`.planning/knight-foundation/sc.md`](../../../.planning/knight-foundation/sc.md).
Migrations: `CC_0127` (structure), `CC_0128` (occupancy) — both slots **reserved from the
allocator**, not counted.

## Sources

| | Source | What it is | Read |
| --- | --- | --- | --- |
| **A** | `citycouncil.columbiasc.gov` — council page, Districts page, six member profiles | Columbia's own council site. The Districts page assigns each of the four districts to a member by name and lists the neighbourhood associations inside it | 2026-09-20 |
| **B** | `cityofmyrtlebeach.com/government/mayor___city_council/index.php` | Myrtle Beach's council page, with a biography and a term-expiry sentence per member | 2026-09-20 |
| **C** | `masc.sc/municipality/{columbia,myrtle-beach}` | the **Municipal Association of South Carolina**'s directory — maintained by neither city. Names every official, and states the election method and the form of government in its own words | 2026-09-20 |
| **D** | `cityofmyrtlebeach.com/.../past_council_members.php` | Myrtle Beach's **"Who Served When"** history: every mayor and council member since 1940, with each span as `January YYYY-December YYYY` | 2026-09-20 |
| **E** | the cities' own swearing-in notices (`cityofmyrtlebeach.com/news_detail_T6_R2527.php`, `columbiasc.gov/city-of-columbia-swearing-in-ceremony…`) | the day each new member took office | 2026-09-20 |
| **F** | `services1.arcgis.com/Mnt8FoJcogKtoVBs/.../CouncilDistrict` | Columbia's four council-district polygons, published by ColaCityGIS | 2026-09-20 |

**A, B and C agree on all 14 names.** Every seated member is named by their own city AND by MASC;
no councillor named by either source is missing from the roster; a planted control name is reported
absent by both.

## 🔴🔴 MYRTLE BEACH PUBLISHES TWO COUNCIL PAGES AND ONLY ONE IS MAINTAINED

| URL | What it says |
| --- | --- |
| `/government/mayor___city_council/index.php` | **CURRENT** — Kruea, Chestnut, Conner, Hatley, Lowder, McClure, Render |
| `/government/mayor_and_city_concil/index.php` | **STALE** — still names Mayor **Brenda Bethune** and Councilman **Gregg Smith**, whose terms ended in January 2026 |

Both return **HTTP 200** with a complete, plausible roster, and the stale one still carries five of
the seven current members, so a name check against it passes for five people out of seven. Two
things separate them:

1. the stale page's terms read *"term expires January 2026"* — **Duluth's rule: a council's
   change-check signal is an expired date**, not a banner;
2. **MASC agrees with the other one.**

⚠ Note which is which: the **misspelled** path (`concil`) is the stale one, and it is the path the
city's own history page still lives under, so the misspelling is not itself the tell.
`verify-sc-cities-roster.mjs` asserts the stale page is **still stale**, so the day it is fixed —
or the day the current page goes stale instead — is noticed rather than assumed.

## Charter rulings, taken from each city's own words

| | Columbia | Myrtle Beach |
| --- | --- | --- |
| Form | Council-Manager (MASC) | Council-Manager (MASC) |
| Council | "the Mayor, Council District members (4), and At-Large Council members (2)" — **seven, counting the mayor** | a mayor and **six** councilmembers |
| Method | 4 single-member districts + 2 at-large | **"At large"**, non-partisan (MASC) — no districts exist |
| Elections | November of odd years | first Tuesday after the first Monday in November of odd years (MASC) |

🔴 **The two councils are not made uniform.** Columbia gets a district layer and district titles;
Myrtle Beach gets six unnumbered at-large seats on the citywide polygon and **no ward layer is
invented** — Tallahassee, State College and Boulder again.

## The district layer, and what was and was not proved

`CouncilDistrict` publishes **four polygons and one attribute, `LABEL`**. No adoption date, no plan
name, and Columbia publishes no second boundary set — so unlike Philadelphia, where a superseded
layer sits beside the current one, **there is nothing here to diff against**.

What was checked instead (`scripts/verify-sc-columbia-districts.mjs`):

- the council's **own neighbourhood lists**, which are text published by the council and not by
  GIS, geocoded through OpenStreetMap — a third party: **8 of 8 anchors fall in the district the
  page assigns them to**, two per district;
- **two points outside Columbia match nothing**, so the test is not answering yes to everything.

Measured against the city polygon: the four districts **do not overlap each other**, cover
**99.955%** of Columbia, and extend **2.500 sq mi beyond** the TIGER place boundary — annexation
lag, not an error. One polygon is **invalid as published** and is repaired with `ST_MakeValid` on
write.

⚠ **This proves agreement with the council's description TODAY. It does not date the map**, and
nothing available here can. Recorded as a limitation rather than dressed up as a vintage proof.

## Terms — eight dated, six not, and the split is not about effort

🔴🔴 **A RE-ELECTION DOES NOT RESTART AN OCCUPANCY.** Five of these fourteen were sworn in weeks
ago and none of those five dates belongs in `term_start`:

| Member | Sworn in | Written as | Why |
| --- | --- | --- | --- |
| Daniel J. Rickenmann (COL Mayor) | 2026-01-05 | `unknown` | re-elected; his occupancy began after the 2021 election and no source read here dates that day |
| Tina N. Herbert (COL D1) | 2026-01-05 | `unknown` | re-elected |
| Peter M. Brown (COL D4) | 2026-01-05 | `unknown` | re-elected in a runoff |
| C. H. "Mike" Lowder, Jr. (MB) | 2026-01-13 | **2010-01** | continuous since January 2010 |
| Jackie Hatley (MB) | 2026-01-13 | **2018-01** | continuous since January 2018 |

🔴 **And the opposite case is in the same wave.** **Philip N. Render** served January 2004 →
December 2023, was **out for the 2024-2025 term**, and returned on **2026-01-13**. "First elected"
would overstate his current occupancy by **22 years**; the gap is why his date is the swearing-in.

| Seat | Member | `term_start` | Precision | Source |
| --- | --- | --- | --- | --- |
| COL At Large | Sam P. Johnson | 2026-01-05 | day | beat the incumbent in the 2025-11-18 runoff; sworn 2026-01-05 |
| MB Mayor | Mark Kruea | 2026-01-13 | day | city's own swearing-in notice |
| MB At Large | Philip N. Render | 2026-01-13 | day | same notice — a **return**, not a first arrival |
| MB At Large | Michael "Mike" Chestnut | 2000-11 | month | history page: "November 2000-December 2003", then every span since without a gap |
| MB At Large | C. H. "Mike" Lowder, Jr. | 2010-01 | month | history page from January 2010; the council page's "elected in 2009" is the election, not the start |
| MB At Large | Jackie Hatley | 2018-01 | month | history page from January 2018 |
| MB At Large | Deborah "Debbie" K. Conner | 2024-01 | month | history page, January 2024-December 2027 |
| MB At Large | Bill McClure | 2024-01 | month | history page, January 2024-December 2027 |
| COL Mayor, D1-D4, 1 At Large | six members | — | `unknown` | Columbia publishes election YEARS on member profiles and nothing else. An election year is not a term start |

⚠ **Myrtle Beach's history page is one term behind**: its last block is January 2024-December 2027
and it does not list the members seated in January 2026. It is an excellent source for *when
somebody started* and a poor one for *who is serving now* — which is exactly the pairing the
council page and MASC supply.

## The roster

| City | Seat | Member |
| --- | --- | --- |
| Columbia | Mayor | Daniel J. Rickenmann |
| Columbia | Council Member, District 1 | Tina N. Herbert |
| Columbia | Council Member, District 2 | Edward H. McDowell, Jr. |
| Columbia | Council Member, District 3 | Will Brennan |
| Columbia | Council Member, District 4 | Peter M. Brown |
| Columbia | Council Member, At Large | Tyler D. Bailey |
| Columbia | Council Member, At Large | Sam P. Johnson |
| Myrtle Beach | Mayor | Mark Kruea |
| Myrtle Beach | Council Member, At Large | Michael "Mike" Chestnut |
| Myrtle Beach | Council Member, At Large | Deborah "Debbie" K. Conner *(Mayor Pro Tem)* |
| Myrtle Beach | Council Member, At Large | Jackie Hatley |
| Myrtle Beach | Council Member, At Large | C. H. "Mike" Lowder, Jr. |
| Myrtle Beach | Council Member, At Large | Bill McClure |
| Myrtle Beach | Council Member, At Large | Philip N. Render |

**One name collides with an existing row and it is a different person:** the `Sam Johnson` already
in production (external_id -880002) holds **Board Member, Place 2 on a Texas school board**. The
duplicate-name guard is lifted for that ONE row; the other thirteen are inserted with it armed. A
surname pass over rows with any South Carolina connection found three Johnsons and one Bailey —
all state legislators seated by SC-2, all different people.

**No party is written on any person or office.** Both councils are elected non-partisan, and party
lives on `races.primary_party` in any case.
