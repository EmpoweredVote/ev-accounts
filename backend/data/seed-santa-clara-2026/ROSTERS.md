# San José + Santa Clara County — CA-2 research record

**Program tracker:** [`.planning/knight-foundation/PROGRAM.md`](../../../.planning/knight-foundation/PROGRAM.md) ·
**State notes:** [`.planning/knight-foundation/ca.md`](../../../.planning/knight-foundation/ca.md)

Researched 2026-09-02. **Nothing has been written to production yet.** This file is the evidence so a
later session can finish CA-2 without repeating any of it.

Measured state, re-confirmed 2026-09-02:

| Body | Offices | Seated | Dated terms | Headshots |
| --- | --- | --- | --- | --- |
| San José city | 11 | 11 | **0 — all `undated_term`, precision `unknown`** | 11 |
| Santa Clara County officers | 3 | 3 | 3 | **0** |
| Santa Clara Board of Supervisors | **0** | — | — | — |

---

## Sources

| # | Body | Source | What it is |
| --- | --- | --- | --- |
| A | city | `sanjoseca.gov/.../mayor-and-city-council` | the city's own roster, with **term-expiry** dates |
| B | city | `webapi.legistar.com/v1/sanjose/bodies/138/officeRecords` | 🔴 **STOPS AT THE 2021 COHORT** — see defect 1 |
| C | county | `santaclaracounty.gov/government/elected-officials` | the county's own consolidated roster |
| D | county | `vote.santaclaracounty.gov/county-offices` → one page per office | **the Registrar of Voters' own officeholder record.** States the term rule, the term length, the limit and the next election per office |
| E | county | `.../Supervisorial_Districts_2021_web_app_test/FeatureServer/0` | **THE LAYER TO LOAD.** What the Board's own "Find My Supervisor" lookup serves residents |
| F | county | `.../Supervisorial_Districts_2021/FeatureServer/24` | the County Executive's **"Final Plan"** shapefile, Dec 2021 |
| G | county | `.../SCCSupervisorialDistrictsMap/FeatureServer/0` (ISD copy) | 2021 geometry, **stale roster** |
| H | county | `.../PlanningOfficeDataService2/FeatureServer/5` | 🔴 **THE TRAP** — see defect 2 |
| I | county | `.../Supervisorial_Districts_2011/FeatureServer/0` | the superseded 2011 map, used as the control |

---

## 🔴 Source defects found

### 1. 🔴🔴 San José's Legistar stops at the 2021 cohort — the CA-1 method does not carry over

Long Beach's occupancy was solved with Legistar office records at day precision. San José publishes the
**same API**, and it is **four years stale**: no record starts after 2021-01-01, and **not one current
member appears**. No Kamei, no Ortiz, no Doan, no Mahan as Mayor.

> ⚠ **A method that worked in the last jurisdiction is a hypothesis in this one.** Reusing it without
> checking currency would have produced a stale roster carrying the authority of the city's own system.

It is still useful for what it does cover, and that is real evidence: it dates **Pam Foley to
2019-01-01** and **David Cohen to 2021-01-01**, and its turnover dates (2015-01-01, 2017-01-10,
2019-01-01, 2021-01-01) establish that San José terms commence in **January**.

### 2. 🔴🔴🔴 Santa Clara has FIVE supervisor layers, and the GA-4 inversion is live — in both directions

| Layer | Last edit | Roster it carries | Geometry |
| --- | --- | --- | --- |
| **E** — Board's own lookup | 2025-08-04 | ✅ current | ✅ **operative** |
| F — CEO "Final Plan" 2021 | 2026-06-05 | none (no attributes) | ✅ operative |
| G — ISD copy | 2023-08-04 | 🔴 **Cindy Chavez, Joe Simitian** — both departed | ✅ operative (≤6.24 sq mi from F) |
| **H** — Planning layer 5 | **2026-07-22** | ✅ **current** | 🔴 **the 2011 map** |
| I — "Supervisorial_Districts_2011" | — | — | the 2011 map |

**H is the trap.** It has the most recent edit date in the county's entire GIS estate and the correct
five names — and its boundaries are **identical to the 2011 map, 0.000 sq mi on all five districts**.

> 🔴 **This nearly went wrong twice, in opposite directions.** First H looked right: freshest edit,
> correct roster. Then F and G agreed against it — but G's `POPULATION` field sums to **1,781,639**,
> the **2010** census county total, which made G look like the old map too.

**The control that settled it** was the layer explicitly named `Supervisorial_Districts_2011`:

| Layer | Symmetric difference vs the 2011 map, per district (sq mi) |
| --- | --- |
| F — "2021 Final Plan" | 244.9 · 10.1 · 145.9 · 6.4 · 119.4 |
| G — ISD copy | 251.1 · 10.1 · 147.3 · 6.4 · 120.0 |
| **H — Planning, edited 2026** | **0.000 · 0.000 · 0.000 · 0.000 · 0.000** |

**And the arbiter closed it.** The Board's own *Find My Supervisor* app
(`appid=5a47e27abd29447d8b6420fded6091af` → webmap `a51f16fac6304375bbe95813670ae6d9`, modified
2025-09-02) serves layer **E**. E is **identical to F at 0.000 on all five districts** and differs from
H by up to 244.891.

**The address probe, in a place where they disagree** — 702 Saranac Drive, Sunnyvale
(37.358594, −122.041786), reverse-geocoded from the largest populated disagreement zone:

| Layer | Says |
| --- | --- |
| **E — what the county tells residents** | **District 3** |
| G — 2021 plan | District 3 |
| H — Planning, edited 2026 | ❌ District 5 |

⚠ **Structural corroboration:** G's union closes on the TIGER county polygon to **0.0002 sq mi**;
H's spills 0.87 sq mi outside the county and leaves 3.75 sq mi uncovered. A map that does not close on
its own county is not the operative partition.

> **Freshness is a property of a FIELD, not a layer** — GA-4's rule in its sharpest form yet. H's
> roster attribute is the freshest thing in the county's GIS estate; its geometry is fifteen years old.

⚠ **UNRESOLVED, recorded rather than explained away:** G's `POPULATION` field is 2010-census data
sitting on 2021 geometry. It does not change which map is which — G differs from the 2011 layer by up
to 251 sq mi, measured — but the anomaly is real and I could not account for it.

### 3. The Registrar's own pages name TWO Board Presidents

Source D gives Otto Lee (D3) "Board President" and Susan Ellenberg (D4) "Board President", with Sylvia
Arenas (D1) "Board Vice President". One of the two is stale. **It does not matter for this wave** —
per CLAUDE.md a rotating role is a parenthetical on the seat title, never its own office, so no
President/Vice-President office is created. Recorded so nobody treats it as a finding later.

---

## Structural rulings, from the Registrar (source D)

Stated verbatim on every county office page:

- **"Term Begins: First Monday after January 1 at Noon"**
- **Supervisors:** 4-year terms, **3-term limit**
- **Assessor, Sheriff, District Attorney:** 4-year terms, **no term limits**
- Elections: Primary and General (runoff)

The rule computes exactly: Otto Lee "assumed office **January 4, 2021**", the first Monday after
1 January 2021. Betty Duong and Margaret Abe-Koga both took office **January 6, 2025**, likewise.

**San José:** terms commence **1 January** (source A gives "Term expires 12/31/YY"; source B's own
turnovers are 2019-01-01 and 2021-01-01).

---

## 🔴🔴 Change-check — nobody has left; five seats turn over in January 2027

**Santa Clara County — all 8 confirmed present on TWO independent county sources** (C, the county's
Elected Officials page, and D, the Registrar's own record):

| Office | Holder | Next election (source D) | Turns over |
| --- | --- | --- | --- |
| Supervisor D1 | Sylvia Arenas | **2026** | Jan 2027 |
| Supervisor D2 | Betty Duong | 2028 | — |
| Supervisor D3 | Otto Lee | 2028 | — |
| Supervisor D4 | Susan Ellenberg | **2026** | Jan 2027 |
| Supervisor D5 | Margaret Abe-Koga | 2028 | — |
| Assessor | Neysa Fligor | **2026** | Jan 2027 |
| Sheriff | Robert Jonsen | **2026** | Jan 2027 |
| District Attorney | Jeff Rosen | **2026** | Jan 2027 |

🟢 **THE `ca.md` FLAG ON NEYSA FLIGOR IS RESOLVED.** CA-1 flagged her `term_start 2026-01-26` as an
unverified mid-term date. Source D prints **"Neysa Fligor - Partial/Unexpired Term"**. She is filling a
vacancy, which is exactly why her start is a mid-January date and not a January commencement. The
stored date is consistent with the county's own record. ⚠ The *predecessor's* departure is still
unrecorded in our data — no `office_terms` row closes for the prior Assessor.

**San José — all 11 confirmed on source A**, matching production exactly. Districts 1, 3, 5, 7 and 9
expire 12/31/26 and are on the November ballot; winners seat **2027-01-01**. Nobody turns over now.

---

## Roster — Santa Clara County supervisors (to seat)

`term_start` is continuous occupancy. The commencement rule is source D's; the election year is from
source D's next-election cycle plus the noted corroboration.

| District | Person | term_start | prec | Basis |
| --- | --- | --- | --- | --- |
| 1 | Sylvia Arenas | 2023-01-02 | day | elected 2022 (Wasserman term-limited); rule + cycle |
| 2 | Betty Duong | **2025-01-06** | day | **directly sourced** — succeeded Chavez, who ended 2025-01-06 |
| 3 | Otto Lee | **2021-01-04** | day | **directly sourced** — "assumed office January 4, 2021" |
| 4 | Susan Ellenberg | 2019-01-07 | day | first elected 2018; rule + cycle. ⚠ **derived — the weakest of the five** |
| 5 | Margaret Abe-Koga | **2025-01-06** | day | **directly sourced** — succeeded Simitian |

⚠ Ellenberg's first-election year rests on a detector (Wikipedia) plus source D's cycle. Confirm
against the Registrar's 2018 certified results before writing, or drop her to `year` precision.

## Roster — San José (to date; all 11 already seated and correct)

| Seat | Person | term_start | Status |
| --- | --- | --- | --- |
| Mayor | Matt Mahan | ? | **OWED.** Won a 2022 special for the remainder, re-elected 2024. Mayor occupancy ≠ his D10 council record |
| D1 | Rosemary Kamei | ? | OWED — elected 2022 |
| D2 | Pamela Campos | ? | OWED — elected 2024 |
| D3 | Anthony Tordillos | ? | **OWED, and the special case.** The ROV lists a **December 30, 2025 Special Runoff Election** — almost certainly D3, after Omar Torres resigned. A special seats early; do not infer from the 12/31/26 expiry |
| D4 | David Cohen | **2021-01-01** | ✅ source B |
| D5 | Peter Ortiz | ? | OWED — elected 2022 |
| D6 | Michael Mulcahy | ? | OWED — elected 2024 |
| D7 | Bien Doan | ? | OWED — elected 2022 |
| D8 | Domingo Candelas | ? | OWED — check for an appointment before his election |
| D9 | Pam Foley | **2019-01-01** | ✅ source B |
| D10 | George Casey | ? | OWED — elected 2024 |

> ⚠ **A published term year is EXPIRY.** Source A gives expiry only. Subtracting four years is the
> error that was wrong for 5 of 17 in the NC wave, and it is wrong here for at least Tordillos.

**Where to get the missing nine:** the Registrar's certified results. The archive is at
`vote.santaclaracounty.gov/elections/past-election-information-and-results`, with a Clarity feed
(`results.enr.clarityelections.com/CA/Santa_Clara/<id>/<ver>/...`) and per-election Statement-of-Vote
XLSX/PDF on `files.santaclaracounty.gov`. The city-and-town half of the Registrar's officeholder list
is at `vote.santaclaracounty.gov/city-and-town-elected-officials-0` and is the same shape as the county
pages used above — **that is the cheapest next source, and it was not yet read.**

---

## Assets

🟢 **A headshot source for Santa Clara's stage-5 debt was found in passing.** Layer E carries a
`picture` URL for every supervisor, e.g.
`https://stgenpln.blob.core.windows.net/document/supervisor-d1-arenas-gis.jpg`, plus phone, email,
website and calendar. ⚠ **TEST them and MEASURE THE PIXELS** — GA-4's CMS upscaled on request and a
2000x2500 response had no hair strands. The three countywide officers are not covered by it.

---

## What is ready, and what is not

**Ready:** the geometry decision, fully arbitrated. Load layer **E** as **`X0047`** (verified free
2026-09-02; `X0046` is CA-1's Long Beach).

**Not done:** the loader, the offices/people migrations, nine San José term starts, Ellenberg's
confirmation, and the headshots. No production write has been made by CA-2.
