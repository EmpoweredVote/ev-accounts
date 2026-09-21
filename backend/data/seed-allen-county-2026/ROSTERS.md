# Allen County, Indiana — IN-5 roster

Wave **IN-5** of the Knight Foundation cities programme, slice 4, **stage 4**.
City half: Fort Wayne, seated by IN-3.

**19 elected county offices. 19 people. 0 vacancies.**

Boundaries: `X0049`, loaded by `scripts/load-allen-county-council-boundaries.ts`.
Migration: `CC_0094` — **one** migration carrying offices *and* people, per spec §3.
Slice notes: [`.planning/knight-foundation/in.md`](../../../.planning/knight-foundation/in.md).

## 🔴🔴 COMMISSIONERS ARE ELECTED COUNTYWIDE, AND THE DISTRICT POLYGONS ARE A TRAP

Under Indiana law a county commissioner **must reside in a district but is elected by the entire
county**. Every registered voter in Allen County votes for **all three** commissioners.

The Allen County Election Board publishes `Comm_Dist_1/2/3` polygons — three neat, correct,
inviting layers. **Hanging the commissioner offices on them would show a voter one of the three
commissioners they actually elect.** So they are not loaded and not used: the three offices hang on
the **county polygon `18003`/`G4020`**, and the commissioner districts are recorded here as a
*candidate residency rule*, which is what they are.

⚠ **This is the inverse of the Long Beach failure.** There, nine councilmembers shared one polygon
and every address wrongly returned all nine. Here, every county address **should** return all three
commissioners — because that is who the voter elects. The same shape is right in one case and
wrong in the other, and only the statute tells you which.

The **County Council is different**, and the difference is real:

| Body | How elected | Hangs on |
| --- | --- | --- |
| Board of Commissioners (3) | **countywide**, district = residency only | county `18003` |
| County Council, Districts 1–4 | **by district** | `X0049` slugs |
| County Council, At Large (3) | **countywide** | county `18003` |
| The 8 county officers + Prosecutor | **countywide** | county `18003` |

## Ruling — Prosecutor in, judges out (Cantrell, 2026-09-10)

Allen County's own *Offices on the 2026 General Ballot* lists, under COUNTY/LOCAL, both a
**Prosecuting Attorney – 38th District** and five **Judges of Superior Court**.

The Prosecuting Attorney is modelled: an elected executive law-enforcement office on the county
ballot. The **judges are not**: they are the state trial judiciary, and they bring judicial
retention and `is_judicial` modelling this wave has not scoped. This keeps GA-4's line, which
excluded Muscogee's municipal court.

## Sources

| | Source | What it is | Read |
| --- | --- | --- | --- |
| **A** | [Offices on the 2026 General Ballot](https://www.allencounty.in.gov/DocumentCenter/View/14487/OFFICES-ON-THE-2026-GENERAL-BALLOT-PDF) | The county's own ballot document — **the authoritative enumeration of what Allen elects** | 2026-09-10 |
| **B** | [`allencounty.in.gov/m/directory`](https://www.allencounty.in.gov/m/directory) | The county's own staff directory | 2026-09-10 |
| **C** | [`allencountygop.com/electedofficials/`](https://allencountygop.com/electedofficials/) | The county party's list — partisan, and used only as a cross-check | 2026-09-10 |
| **D** | Ballotpedia per-person pages | Tenure start **year** only | 2026-09-10 |
| **E** | Allen County Election Board `EBdistricts` MapServer | Council-district geometry, and the precinct `County_Council_Dist` cross-check | 2026-09-10 |

## 🔴🔴 THE COUNTY'S OWN DIRECTORY WAS THE STALE SOURCE, AND THE PARTY PAGE WAS RIGHT

Sources B and C disagreed on **County Council District 1**: the directory said **Josh L. Hale**, the
party page said **Kyle Kerley**.

Settled from the news record: **Hale resigned effective Wednesday 2026-01-15** to focus on his job
as chief of the East Central Fire and EMS Protection Territory, and **Kyle Kerley won the GOP
caucus at noon on 2026-01-16** — he had previously served at large from 2018 to 2024.

▶ **The body's own roster is usually the check, and here it was the thing that was wrong.** A wave
that treated the official directory as authoritative would have seated a man who had resigned eight
months earlier. The change-check has to ask *has this person left?* of **every** source, including
the official one.

⚠ The same article named a **second** caucus the next morning — Fort Wayne City Clerk, Lana
Keesling to John McGauley, 2026-01-17. That is the change IN-3 already handled, and finding it here
independently confirms it.

⚠ **Name variant:** source C prints "Stacy O'Day"; the county directory and Ballotpedia both print
**Stacey O'Day**. The county's own spelling is used.

## The nineteen

| Office | Holder | `term_start` | Precision |
| --- | --- | --- | --- |
| Commissioner, District 1 | Ron Turpin | 2025-01-01 | `year` |
| Commissioner, District 2 | Therese Brown | 2011-01-01 | `year` |
| Commissioner, District 3 | Richard Beck | — | **`unknown`** |
| County Council, District 1 | Kyle Kerley | 2026-01-01 | `month` |
| County Council, District 2 | Thomas Harris | 2011-01-01 | `year` |
| County Council, District 3 | Paul Lagemann | 2023-01-01 | `year` |
| County Council, District 4 | Donald Wyss | 2023-01-01 | `year` |
| County Council, At Large | Robert Armstrong | 2008-01-01 | `year` |
| County Council, At Large | Ken Fries | 2018-01-01 | `year` |
| County Council, At Large | Lindsey Hammond | 2025-01-01 | `year` |
| Assessor | Stacey O'Day | 2014-01-01 | `year` |
| Auditor | Jacquelynn Scheuman | 2025-01-01 | `year` |
| Clerk of the Circuit Court | Christopher Nancarrow | 2019-01-01 | `year` |
| Coroner | Jon Brandenberger | 2021-01-01 | `year` |
| Recorder | Nicole Keesling | 2023-01-01 | `year` |
| Sheriff | Troy Hershberger | 2023-01-01 | `year` |
| Surveyor | Michael Fruchey | 2022-01-01 | `year` |
| Treasurer | Samantha Chenery | 2025-01-01 | `year` |
| Prosecuting Attorney | Michael McAlexander | 2023-01-01 | `year` |

**1 month + 17 year + 1 unknown.**

⚠ **Kerley is `month`, not `day`, even though the caucus date is known.** The caucus was noon on
2026-01-16; **the swearing-in day is not published**, and a caucus win and taking office are
different events. This follows the rule IN-4 set for Gary's two caucus arrivals. Contrast Fort
Wayne's John McGauley, who *is* `day`, because that source states he was sworn in that morning.

⚠ **Richard Beck has no Ballotpedia page** under any slug tried, and no other source publishes a
tenure start. `unknown` is the honest answer rather than a guess.

## Boundaries — `X0049`

Four County Council districts from the Election Board's own service, loaded 2026-09-10. All
`ST_MultiPolygon`, SRID 4326, valid.

| District | sq mi | District | sq mi |
| --- | --- | --- | --- |
| 1 | 204.2679 | 3 | 144.9529 |
| 2 | 179.1733 | 4 | 131.6293 |

**Union 660.0234 sq mi against a 659.9832 sq mi county polygon — 0.0354 uncovered, 0.0756 outside.**
Zero overlap on all six pairs.

🟢 **These four DO tile their parent, and Fort Wayne's six did not.** So this loader requires
**closure** where the city loader could only **bound** the gap. The residual is sliver noise between
two digitisations of one boundary — the tolerance rule, not `ST_Equals`.

🟢 **Cross-checked** at every district's interior point against the same service's precinct-level
`County_Council_Dist`: **4 of 4 agree, each a different value.** The commissioner-district values
returned alongside them differ from the council values, which independently confirms the two are
distinct layers.

🔴 The layer carries `County_Council_Rep` and it is **null in all four** — the same empty
roster-field trap as Fort Wayne's `FW_Council_Rep`. The loader asserts it stays null.
