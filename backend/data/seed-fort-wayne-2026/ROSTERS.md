# Fort Wayne, Indiana — IN-3 roster

Wave **IN-3** of the Knight Foundation cities programme, slice 4, stage 3.
Parent county: **Allen** (stage 4, not this wave).

**11 elected city offices. 11 people. 0 vacancies.**

Slice notes: [`.planning/knight-foundation/in.md`](../../../.planning/knight-foundation/in.md).
Boundaries: `X0048`, loaded by `scripts/load-fort-wayne-council-boundaries.ts`.
Migrations: `CC_0090` (structure), `CC_0091` (occupancy) — both slots **reserved from the
allocator**, not counted.

## Sources

| | Source | What it is | Read |
| --- | --- | --- | --- |
| **A** | [`cityoffortwayne.in.gov/185/City-Council`](https://www.cityoffortwayne.in.gov/185/City-Council) | The city's own Council page — names **and** district/at-large seats | 2026-09-10 |
| **B** | [Common Council agenda, 24 Feb 2026](https://citycouncildocuments.acfw.net/documents/download/2026-02-20/02-24-26%20Committee%20and%20Regular%20Session.pdf) | **The Council's own meeting document** — the nine members, the term span, the City Clerk and the Council President | 2026-09-10 |
| **C** | [`en.wikipedia.org/wiki/Fort_Wayne_City_Council`](https://en.wikipedia.org/wiki/Fort_Wayne_City_Council) | Third party, names + seats | 2026-09-10 |
| **D** | Ballotpedia per-member pages | Tenure start **year** only | 2026-09-10 |
| **E** | [Fort Wayne Code § 31.01](https://codelibrary.amlegal.com/codes/ftwayne/latest/ftwayne_in/0-0-0-273) | Which offices are **elected** | 2026-09-10 |
| **F** | Allen County Election Board `EBdistricts` MapServer | District geometry, and the precinct-level `City_Dist` cross-check | 2026-09-10 |

**A, B and C agree on all nine council members. Zero disagreements.**

## What § 31.01 actually says is elected

Read rather than assumed, because Indiana cities are not uniform:

- **(A) Mayor** — chief executive, four-year term, no term limit.
- **(B) Common Council** — *"six district members and three at-large members"*, four-year terms.
- **(C) City Clerk** — *"secretary and record-keeper for Common Council"*, four-year term.

The section **ends at (C)**. Fort Wayne elects **no city judge** and no other city officer, so this
wave is 1 + 9 + 1 = **11 offices**. The Council Attorney named on every agenda (Joseph G. Bonahoom)
is **appointed**, not elected, and is deliberately not modelled.

⚠ **The three at-large seats are NOT numbered.** Georgia numbers its at-large seats ("Post 9",
"Post 10") and Columbus's model reflects that; Indiana does not. All three run in one citywide
race and the top three win. So the three offices carry the **identical** title
`Council Member, At Large`, and inventing a seat number to tell them apart would be describing a
power Fort Wayne does not have.

## 🔴 Source defects found

### The boundary layer has a councilmember field and it is empty

`FW_City_Cncl_Dist_1..6` each carry an `FW_Council_Rep` attribute. Measured 2026-09-10: districts
1, 2, 4, 5 and 6 return `""` and district 3 returns `null`. **Not one is populated.**

Santa Clara's vintage test — compare the layer's roster field against the verified roster, to prove
the layer is maintained — **is therefore unavailable here**. A field that looks like a source and
holds nothing invites the sentence "the Election Board confirms the roster". It does not. The loader
asserts the field stays **empty**, so the day it is populated someone has to decide what it means.

### The Council's own agenda gives a TERM, not an occupancy

Source B prints *"Fort Wayne Common Council Members — Elected to a 4-year term: 1/1/24 – 12/31/27"*.
That is the **term**. Five of the nine were re-elected in 2023 and have served continuously since
2012, 2016 or 2020, and **re-election does not end an occupancy**. Writing `2024-01-01` for all nine
would have been wrong for five of them, from a document that is itself correct.

### 🔴 Ballotpedia gives a YEAR, and only a year

Source D's tenure field is `2012 - Present`, `2016 - Present` and so on. There is no day anywhere.
So five members are written at `start_precision = 'year'` — **not** back-filled to a January 1st
that no source states.

## Change-check — has anyone LEFT?

Two seats changed hands mid-term, and a source predating either would have seated the wrong person.

| Change | When | Detail |
| --- | --- | --- |
| **City Clerk** | **2026-01-06 → 2026-01-17** | **Lana Keesling resigned** on becoming Indiana Republican Party chair. **John McGauley** won the Allen County GOP caucus on **Saturday 17 January 2026** and was sworn in that morning. Confirmed by the Council's own 24 Feb 2026 agenda, which names McGauley as City Clerk. |
| **Council District 6** | **2024-05-21** | **Sharon Tucker** left the 6th District seat on becoming Mayor. **Rohli Booker** won the Allen County Democratic caucus on 18 May 2024 and was sworn in by Mayor Tucker on **Tuesday 21 May 2024**. |

⚠ **I got the second one wrong first, and the correction matters.** I assumed Scott Myers (D4)
replaced Tucker. He did not: **Myers won D4 at the 2023 election**, the seat having opened when
**Jason Arp** left to run for mayor. Tucker's seat was **D6**, and Booker filled it. Assigning
Myers a mid-term caucus date would have put a sourced-looking but false date on a real person.

**No other seat has changed.** All nine council members appear on the Council's own February 2026
agenda, and the Mayor and Clerk are current.

## The eleven, and where each date comes from

| Office | Holder | `term_start` | Precision | Source for the date |
| --- | --- | --- | --- | --- |
| Mayor | Sharon Tucker | 2024-04-23 | `day` | Ballotpedia, *"Assumed office: April 23, 2024"* — she succeeded Tom Henry, who died in office |
| City Clerk | John McGauley | 2026-01-17 | `day` | Sworn in the morning of the caucus, Sat 17 Jan 2026 |
| Council, District 1 | Paul Ensley | 2016-01-01 | `year` | Ballotpedia tenure `2016 - Present`; **no day is published** |
| Council, District 2 | Russ Jehl | 2012-01-01 | `year` | Ballotpedia tenure `2012 - Present` |
| Council, District 3 | Nathan Hartman | 2024-01-01 | `day` | New in 2024; the Council's own agenda states the term begins 1/1/24 |
| Council, District 4 | Scott Myers | 2024-01-01 | `day` | New in 2024, elected 7 Nov 2023; term begins 1/1/24 |
| Council, District 5 | Geoff Paddock | 2012-01-01 | `year` | Ballotpedia tenure `2012 - Present` |
| Council, District 6 | Rohli Booker | 2024-05-21 | `day` | Sworn in by Mayor Tucker, Tue 21 May 2024 |
| Council, At Large | Martin Bender | 2024-01-01 | `day` | New in 2024; term begins 1/1/24 |
| Council, At Large | Michelle Chambers | 2020-01-01 | `year` | Ballotpedia tenure `2020 - Present` |
| Council, At Large | Thomas Freistroffer | 2016-01-01 | `year` | Ballotpedia tenure `2016 - Present` |

🔴 **Three members are `day` at 2024-01-01 and five are `year`, and the difference is real.** For
Bender, Hartman and Myers the 2024 term *is* the start of continuous occupancy, and the Council's
own document states that date. For the other five the same document states the same date and it is
**not** their occupancy start, because they were already serving. Same document, opposite meaning,
decided per person.

## Boundaries — `X0048`

Six districts from the Allen County Election Board's own service, loaded 2026-09-10. All six are
`ST_MultiPolygon`, SRID 4326, valid after `ST_MakeValid`.

| District | sq mi | District | sq mi |
| --- | --- | --- | --- |
| 1 | 16.9381 | 4 | 27.5695 |
| 2 | 15.3684 | 5 | 12.2542 |
| 3 | 23.6799 | 6 | 15.1924 |

**Union 111.0025 sq mi. Zero overlap on all fifteen pairs.**

### 🔴 The six do NOT tile the TIGER place polygon, and that is correct

| Measure | sq mi |
| --- | --- |
| TIGER place `1825000` | 112.0932 |
| Union of the six districts | 111.0025 |
| Place **not** covered | **1.2524** |
| Districts **outside** the place | 0.1617 |

The uncovered ground is essentially **one piece of 1.1340 sq mi** centred at
`(-85.04700, 41.02744)`. The Election Board's **own precinct layer** reports that point as precinct
`ADAMS G` with `City_Dist = 'COUNTY'` — unincorporated Allen County, with no Fort Wayne council
representation at all.

So this is a disagreement between **TIGER's place polygon** and **the county's city limits**, not a
hole in the council map. Requiring closure would be requiring the wrong thing — the
Columbus/Fort Benning situation, not the Macon-Bibb one. The loader **bounds** the gap instead.

### 🟢 The layer was cross-checked against an independent record

The same precinct layer carries a `City_Dist` per precinct: **187 of 278** precincts are `FW 1`–`FW 6`,
64 are `COUNTY`. Every one of the six district polygons was tested at its **own interior point**
against that field:

```
D1 -> precinct 178  FW 1      D4 -> precinct 459  FW 4
D2 -> precinct 262  FW 2      D5 -> precinct 579  FW 5
D3 -> precinct 309  FW 3      D6 -> precinct 654  FW 6
```

**6 of 6 agree, and each returned a DIFFERENT value** — so the field discriminates rather than
agreeing with everything. The gap point returning `COUNTY` is a seventh distinct answer from the
same field. The loader asserts that distinctness, not just the agreement.

## Structure

One government, three chambers, seven districts, eleven offices.

| Chamber | `official_count` | Offices |
| --- | --- | --- |
| Fort Wayne Common Council | 9 | 6 district + 3 at-large |
| Office of the Mayor | 1 | Mayor |
| Office of the City Clerk | 1 | City Clerk |

Districts: six `LOCAL` rows on the `X0048` slugs, plus one `LOCAL` row on TIGER place `1825000`
labelled **Fort Wayne Citywide**, which carries the Mayor, the Clerk and the three at-large seats —
the Columbus/Bradenton convention.

⚠ **All eleven people are new to production.** None of the eleven matches any existing politician
row, including the 672-row `indiana_discovery` cohort. That was **controlled**: the same query run
against Kyle Miller, Justin Busch and Greg Taylor matched all three, so the absence is real and not
a broken join.
