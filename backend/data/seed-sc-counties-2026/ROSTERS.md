# SC-4 rosters — Richland County and Horry County

Knight Foundation program, slice 7 (South Carolina), **stage 4 — county waves**.
Tracker: [`.planning/knight-foundation/sc.md`](../../../.planning/knight-foundation/sc.md).

Everything downstream is generated from this file. Nothing downstream can be more correct than it.

| | Richland | Horry |
| --- | --- | --- |
| FIPS / `geo_id` | `45079` | `45051` |
| County polygon | `G4020` — already in production | `G4020` — already in production |
| Council | **11 single-member districts, NO at-large chair** | **11 single-member districts PLUS a chairman elected at large — 12** |
| Council district layer | `X0060` (11 polygons) | `X0061` (11 polygons) |
| Separately elected officers | 6 | 6 |
| Soil and Water (elected seats) | 3 — **one VACANT** | 3 |
| **Offices** | **20** | **21** |
| **Seated** | **19** | **21** |

**41 offices · 40 seated · 1 vacant.**

---

## Who decides what is in scope

The inclusion ruling (Cantrell, 2026-09-17, NC-3): **an office is seated if the voters of that
jurisdiction elect it.** The authority for "do these voters elect it" is not a county web page — it
is the **South Carolina State Election Commission's own candidate record**,
`vrems.scvotes.sc.gov/Candidate/CandidateSearch`, queried per county for the **2020, 2022, 2024 and
2026** statewide generals. Two generals four years apart cover every four-year county office, and
the two extra cycles give the predecessor.

🔴 **The SEC candidate corpus BEGINS AT 2020.** Election `20620` is the 2018 statewide general and
it holds **zero candidate rows** — for any county, any office, any status. That was confirmed with a
positive control: the identical query returns 300+ rows for 2020, 2022, 2024 and 2026, so the empty
2018 answer is a true "no data", not a broken query. Everything below that says `unknown` says it
because the evidence stops at 2020, and a start date is never guessed.

### What is IN

| Body | Richland | Horry |
| --- | --- | --- |
| County Council | 11 districts | 11 districts + at-large Chairman |
| Auditor · Clerk of Court · Coroner · Probate Judge · Sheriff · Treasurer | 6 | 6 |
| Soil and Water Conservation District — the **elected** commissioners only | 3 | 3 |

### What is OUT, and why

- 🔴 **THE SOLICITOR IS MULTI-COUNTY AND IS NOT SEATED.** Richland's own Elected Offices page lists
  a Solicitor, and the SEC confirms `Solicitor Circuit 5` (Byron E. Gipson) and
  `Solicitor Circuit 15` (Jimmy A. Richardson II) on these counties' ballots. But the **Fifth
  Circuit is Richland + Kershaw** and the **Fifteenth is Horry + Georgetown** — neither is
  coterminous with its county. That is the Georgia ruling (Cantrell: "the Ocmulgee Circuit DA and
  its five judges as MULTI-COUNTY") and the Palm Beach precedent (the 15th Judicial Circuit State
  Attorney, **not** seated). NC-3 seated a District Attorney **because** NC Prosecutorial District
  26 is coterminous with Mecklenburg; that condition fails here in both counties. Recorded as
  program-level open work, not fixed here.
- 🔴 **HORRY'S FIVE WATERSHED CONSERVATION DISTRICTS ARE SUB-COUNTY AND ARE NOT SEATED.** Buck
  Creek, Crabtree Swamp, Gapway Swamp, Simpson Creek and Todd Swamp each elect three commissioners
  — 15 seats the SEC confirms on Horry ballots. They are **watersheds, not the county**, we hold no
  polygon for any of them, and hanging them on the county polygon would answer them for every Horry
  address. Same class as Gary's deferred district seats and Centre County's Magisterial District
  Judges: deferring is a scheduling decision, recorded, not a ruling that they do not count.
- **School boards are separate governments** and go with the school-board question North Carolina
  already owes (CMS). Richland alone has three overlapping boards — Richland One, Richland Two and
  Lexington-Richland Five, the last of which crosses a county line.
- **Register of Deeds is APPOINTED in both counties** — ⚠ and this is the office a template would
  have got wrong. Horry's own page lists a Register of Deeds (Marion Foxworth); **he was appointed**
  (WMBF, 2015: "Horry County Councilman Marion Foxworth appointed Register of Deeds"), and the SEC
  has **no Register of Deeds contest in either county in any of the four cycles**. Richland's
  Register of Deeds (John Hopkins) appears in the SC Association of Counties directory and on **no**
  ballot and **not** on Richland's own Elected Offices page. Neither is seated.
- **Master-in-Equity, Magistrate, Public Defender, Assessor, County Administrator** — appointed.

---

## The statutory term-start dates, which are NOT the same for all three groups

🔴🔴 **THREE DIFFERENT COMMENCEMENT RULES APPLY TO THESE 41 SEATS, AND A TEMPLATE THAT USED ONE
DATE WOULD BE WRONG BY UP TO SIX MONTHS.**

| Group | Commences | Authority |
| --- | --- | --- |
| County Council (both counties, chairman included) | **2 January** after the election | **S.C. Code § 4-9-90**: "commencing on the second of January next following their election" |
| Sheriff · Clerk of Court · Coroner · Probate Judge | **first Tuesday in January** after the election | **S.C. Code § 4-11-10** |
| **Auditor · Treasurer** | **1 July** after the election | **§ 4-11-10**, same sentence: "except that the terms of the county auditors and county treasurers shall commence the first day of July next following their election" (1987 Act No. 21) |
| Soil and Water commissioner | **1 February** after the election | terms expire 31 January on the SC DNR board record |

⚠ **Richland County's own council page says terms "start on January 1 after the election."** The
statute says the **second** of January. The statute governs and is what is written; the one-day
disagreement is recorded here rather than silently resolved.

First Tuesdays used: 1997-01-07 · 1999-01-05 · 2009-01-06 · 2021-01-05 · 2023-01-03.

---

# Richland County — 20 offices

Government row: `Richland County, South Carolina, US`, type `County`, `geo_id` `45079`.

## Chamber: Richland County Council — 11, `official_count` 11

Single-member districts on `X0060`. **No at-large chairman**: § 4-9-90 preserves an at-large chair
only in counties that elected one before adopting a Home Rule form, and Richland did not. The chair
and vice chair are chosen by the Council each January, so **Chair Mackey and Vice Chair Pugh hold a
district seat and nothing else** — the chairmanship is not an office here.

| District | Holder | Term start | Precision | Evidence |
| --- | --- | --- | --- | --- |
| 1 | Jason Branham | 2023-01-02 | day | SEC: won 2022. County bio places him on the Board of Zoning Appeals and then the Planning Commission "prior to being elected to Council" — no earlier council service |
| 2 | Derrek Levar Pugh | 2021-01-02 | day | County bio: "Pugh was elected to office Nov. 3, 2020." Council bulletin: "elected in 2020 and re-elected in 2024" |
| 3 | Tyra Little | 2025-01-02 | day | SEC: the 2020 District 3 winner was **Yvonne L. McBride**; Little won 2024 |
| 4 | Paul Livingston | — | **unknown** | County bio: "has represented District 4 for more than 25 years"; chaired 2000-2002 and 2009-2011. No start date is published anywhere |
| 5 | Allison Terracio | — | **unknown** | SEC has her 2022 win; District 5's previous election was 2018, outside the corpus |
| 6 | Don Weaver | — | **unknown** | as above |
| 7 | Gretchen D. Cooper | — | **unknown** | SEC: won 2020 (as Gretchen Barron) and 2024; the 2016 election is outside the corpus. ⚠ **She appears on the 2024 ballot as Gretchen D. Barron and on the county roster as Gretchen D. Cooper** — one person, a changed surname, not two people |
| 8 | Tish Dozier Alleyne | 2025-01-02 | day | SEC: the 2020 District 8 winner was **Overture Walker**, who withdrew after the 2024 primary; Alleyne won 2024 |
| 9 | Jesica Mackey | 2021-01-02 | day | Council's own bulletin: Mackey and Pugh were "elected in 2020 and re-elected in 2024" |
| 10 | Cheryl D. English | — | **unknown** | SEC: won 2020 and 2024; earlier is outside the corpus |
| 11 | Chakisse Newton | 2019-01-02 | day | Not seeking re-election "after serving two terms" (Post and Courier, 2026-03); SEC confirms the 2022 win, so the two terms are 2019-2022 and 2023-2026 |

## Chamber: Elected Officials — 6, `official_count` 6

Countywide, on the existing `G4020` county district. 🟢 **All six carry a day-precision start**,
each from the officeholder's own county page plus the statutory commencement date.

| Office | Holder | Term start | Precision | Evidence |
| --- | --- | --- | --- | --- |
| Auditor | Paul Brawley | **2007-07-01** | day | "Since his election as Richland County Auditor in November 2006" — § 4-11-10 puts an auditor's term at 1 July |
| Clerk of Court | Jeanette W. McBride | 2009-01-06 | day | "Prior to being elected Clerk of Court in 2008" |
| Coroner | Naida Rutherford | 2021-01-05 | day | "Coroner since 2020"; "The voters in Richland County … chose her as their Coroner in 2020" |
| Probate Judge | Amy McCulloch | 1999-01-05 | day | "Prior to her election as the Probate Judge for Richland County in November of 1998" |
| Sheriff | Leon Lott | 1997-01-07 | day | Sheriff's department page: "In 1996, he made a successful run for Sheriff of Richland County" |
| Treasurer | Kendra L. Dove | **2023-07-01** | day | "Kendra L. Dove was elected Richland County Treasurer in November 2022" — § 4-11-10 puts a treasurer's term at 1 July |

## Chamber: Soil and Water Conservation District — 3, `official_count` 3

A governmental subdivision of the State, not a department of county government. Its board holds
**five** commissioners; **three are elected countywide** and two are appointed by the SC Department
of Natural Resources. Only the three elected seats are carried. Source: the DNR's own board record,
`dnr.sc.gov/conservation/districtsdnr/richland.html`, which marks every seat **(E)** or **(A)**.

| Seat | Holder | Term start | Precision | Evidence |
| --- | --- | --- | --- | --- |
| 1 of 3 | Mary Burts | — | **unknown** | DNR: **(E)**, expires 01/31/29. SEC has her winning 2020 **and** 2024, so the tenure runs back past the corpus |
| 2 of 3 | Timothy McSwain | — | **unknown** | DNR: **(E)**, expires 01/31/27 |
| 3 of 3 | — | — | **VACANT** | 🔴 DNR lists the seat as **"Vacant · Commissioner · 01/31/27 (E)"**. The date it fell vacant is not published, so `offices.is_vacant` is set and **no term row is written** — CLAUDE.md forbids a vacancy span whose start is unknown |

⚠ **J. Kenneth Mullis Jr. and James W. Rhodes are on this board and are NOT seated.** Both are
marked **(A)** by DNR. Rhodes is the trap: the SEC records him winning the **elected** seat in 2022,
and he now sits in an **appointed** one. A roster built from the ballot alone would seat him in a
seat he no longer holds. **The DNR board record says who sits where now; the ballot says only how
somebody once arrived.**

---

# Horry County — 21 offices

Government row: `Horry County, South Carolina, US`, type `County`, `geo_id` `45051`.

## Chamber: Horry County Council — 12, `official_count` 12

🔴 **THE TWO COUNCILS ARE NOT THE SAME SHAPE.** Horry elects its **Chairman at large** as a separate
office — the county's own words: "The Horry County Council represents 11 different districts in the
County, and the chairman is elected at-large." § 4-9-90 permits this only where the chair was
elected at large before Home Rule, which is why Richland has no such seat. The at-large chairman
hangs on the **county** polygon; the eleven district seats hang on `X0061`.

The county publishes a term-expiry date per member, and it agrees exactly with the SEC cycle:
districts **3, 4, 6, 9, 10** expire 12/31/2028 (elected 2024) and the **Chairman and districts 1, 2,
5, 7, 8, 11** expire 12/31/2026 (elected 2022).

| Seat | Holder | Term start | Precision | Evidence |
| --- | --- | --- | --- | --- |
| Chairman (at large) | Johnny Gardner | 2019-01-02 | day | County bio: "Johnny entered electoral politics in 2018 and was re-elected in 2022; he is currently serving his eighth year as Horry County Council Chairman" |
| 1 | Jenna L. Dukes | — | **unknown** | SEC: won 2022; District 1's previous election was 2018, outside the corpus |
| 2 | Bill Howard | — | **unknown** | SEC: won 2022 |
| 3 | Dennis DiSabato | — | **unknown** | SEC: won 2020 and 2024 |
| 4 | Gary Loftus | — | **unknown** | SEC: won 2020 and 2024; the county bio gives no council start |
| 5 | Tyler Servant | — | **unknown** | SEC: won 2022 |
| 6 | Cam Crawford | — | **unknown** | SEC: won 2020 and 2024 |
| 7 | Tom Anderson | — | **unknown** | SEC: won 2022 |
| 8 | Michael "Mash" Masciarelli | — | **unknown** | SEC: won 2022 (on the ballot as "Mikey Mash Masciarelli") |
| 9 | R. Mark Causey | — | **unknown** | SEC: won 2020 and 2024 |
| 10 | Danny Hardee | — | **unknown** | SEC: won 2020 and 2024 |
| 11 | Al Allen | 2007-01-02 | day | County bio: "Al has been a County Council member since 2007" |

## Chamber: Elected Officials — 6, `official_count` 6

| Office | Holder | Term start | Precision | Evidence |
| --- | --- | --- | --- | --- |
| Auditor | Tina Hardee | **2025-07-01** | day | 🔴 SEC: the 2020 Auditor was **Beth Calhoun**; Hardee beat Calhoun in the 2024 primary and won the general. § 4-11-10 puts an auditor's term at 1 July, so Calhoun served to 2025-06-30 |
| Clerk of Court | Renee N. Elvis | — | **unknown** | SEC: won 2020 and 2024 |
| Coroner | Robert L. Edge Jr. | — | **unknown** | SEC: won 2020 and 2024 |
| Probate Judge | R. Allen Beverly Jr. | 2023-01-03 | day | County page: "In November 2022, Judge Beverly was elected Horry County Probate Judge"; he had been Chief Associate Probate Judge from 2019 — **an associate judgeship is not this office** |
| Sheriff | Phillip E. Thompson | — | **unknown** | SEC: won 2020 and 2024 |
| Treasurer | Angie Jones | — | **unknown** | SEC: won 2020 and 2024 |

## Chamber: Soil and Water Conservation District — 3, `official_count` 3

Source: `dnr.sc.gov/conservation/districtsdnr/horry.html`. Three **(E)** seats, all filled.

| Seat | Holder | Term start | Precision | Evidence |
| --- | --- | --- | --- | --- |
| 1 of 3 | Barry Shane Willoughby | — | **unknown** | DNR: **(E)**, expires 01/31/29; SEC has him winning 2020 and 2024 |
| 2 of 3 | Glenn Winburn | — | **unknown** | DNR: **(E)**, expires 01/31/27 |
| 3 of 3 | Matthew Gene Johnson | — | **unknown** | DNR: **(E)**, expires 01/31/27 |

English Warren Dixon and Benjamin Hardee are **(A)** appointed and are not seated.

---

## Change-check — has anybody LEFT?

A roster page is not a change-check. Two independent authorities name the same 23 council members
and the same 12 officers:

1. each county's own site (`richlandcountysc.gov`, `horrycountysc.gov`), and
2. the **South Carolina Association of Counties** county directory, which maintains neither site.

They agree name for name, with no expired term-expiry date anywhere on either roster — the Duluth
signal that killed Myrtle Beach's stale page at SC-3.

⚠ **One near-miss, checked rather than assumed.** Reporting on the 2026 election describes Chakisse
Newton as having "vacated the District 11 seat" with Darrell "DJ" Jackson Jr. filling it. She has
**not** resigned: she announced on 2026-03-13 that she would not seek re-election, Jackson won the
June 2026 Democratic primary, and **the general election is 2026-11-03 — it has not happened.**
Newton holds District 11 today. The same is true of Richland District 4 (Livingston, retiring) and
District 1 (Branham, not on the 2026 ballot): **a successor who has not been elected is not a
holder**, and none of them is written.

## Sources on disk

| File | What |
| --- | --- |
| `rich-council.html`, `<member>.html` ×11 | Richland council roster and per-member bios |
| `auditor.html`, `clerk-of-court.html`, `coroner.html`, `probate-judge.html`, `sheriff.html`, `treasurer.html` | Richland elected-officer pages |
| `horry-council.html`, `horry-elected-officials.html` | Horry council roster and officials list |
| `johnny-gardner.html`, `gary-loftus.html`, `al-allen.html` | the only three Horry council bios that exist |
| `scec-*.html` | SC Election Commission candidate records, 2020/2022/2024/2026, per county |
| `scac-richland-directory.html`, `scac-horry-directory.html` | SC Association of Counties — the second authority |
| `dnr-richland-swcd.html`, `dnr-horry-swcd.html` | SC DNR conservation-district boards, (E)/(A) marked |
| `sc-code-4-9.html`, `sc-code-4-11.html` | the two commencement statutes, verbatim |

🔴 **`richlandcountysc.gov` answers `node`'s `fetch` and 403s `curl` on every header set tried** —
the inverse of the usual "node fetch is blocked by TLS fingerprint, use a browser" trap. Try both
stacks before concluding a host is closed.
