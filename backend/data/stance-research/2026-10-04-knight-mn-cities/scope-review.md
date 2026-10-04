# Minnesota scope review — Duluth and Saint Paul city offices

Season 2, 35 ladders at `local`, 18 seated people, 630 rows. Scope is a **per-rung** question
(ruling 2026-08-28), and a scope blank is a fact about the **office**, identical for every member of
the body — so each finding below templates across all 18 rows for that topic.

**Result: 15 topics are scope blanks (270 rows). 20 are live (360 rows).**

That is a materially better ratio than either earlier slice — Charlotte 216 blanks of 420 (51%) and
Florida 306 of 595 (51%), against 270 of 630 (43%) here. **Four ladders that are blank or truncated
in both NC and FL are fully live in Minnesota**: `rent-regulation`, `minimum-wage`,
`local-immigration` and `ranked-choice-voting`. That is 72 rows that would have been blanks
elsewhere, and it is the reason this slice was chosen.

---

## Method, and two false answers it caught

Statutes were read as **verbatim text fetched with `curl`** from `revisor.mn.gov`, then parsed here.
WebFetch was used only to *locate* pages, never to source a section number, a date or a count.

Two detectors returned a wrong answer before they returned a right one. Both are recorded because
both would have produced a confidently wrong scope table.

1. 🔴 **The HTML extractor returned identical site navigation for all four statutes on its first
   pass.** A uniform answer is a broken detector. The second pass returns four distinct bodies, and
   every statute finding rests on that.
2. 🔴 **A Legistar search for `"ranked choice"` returned ZERO matters, and that zero was false.**
   Saint Paul's own ordinances call it **"ranked voting"**. Searching `ranked` returns nine matters
   including the ordinance that created the rules. A vocabulary mismatch produced a clean, confident,
   wrong "this city has no lever here". The same shape as the query-breadth lesson from Charlotte.
   ▶ **Search the term the body itself uses, not the term the ladder uses.**

The Legistar probe itself carried a positive control: `charlottenc` returns 200 with data, and the
clients that fail return an explicit 500 naming the missing connection string. The probe works.

---

## Access — the two cities are NOT symmetric

| | Saint Paul | Duluth |
|---|---|---|
| Legistar public Web API | 🟢 **yes — client `stpaul`, no key** | 🔴 **no** — `duluth` and `duluthmn` both 500 |
| Legislative web portal | `stpaul.legistar.com` | `duluthmn.legistar.com` responds 200 |

Saint Paul's record is queryable: matters, titles, files and per-member roll calls. Duluth has the
InSite portal but not the API, so its record needs HTML work. **Price Duluth higher than Saint Paul
per member.**

⚠ **Rent-stabilization appeals are not positions.** `stpaul` carries many `RLH RSA` matters of the
form *"Appeal of … to a Rent Stabilization Determination at 1029 Raymond Avenue"*. These are
single-property, quasi-judicial determinations. They are the Charlotte "single project approval"
trap wearing a different hat — do not read one as a chair.

---

## SCOPE BLANK — 15 topics, 270 rows

### Statute-backed, Minnesota-specific

**`gun-policy` — § 471.633 FIREARMS**

> The legislature preempts all authority of a home rule charter or statutory city … to regulate
> firearms, ammunition, or their respective components to the complete exclusion of any order,
> ordinance or regulation by them except that: (a) a governmental subdivision may regulate the
> discharge of firearms; and (b) a governmental subdivision may adopt regulations identical to state
> law.

Whole field, as in NC § 14-409.40 and FL § 790.33. Neither exception reaches a rung: no rung is a
discharge rule, and adopting a regulation *identical to state law* is not a position a council
chooses. **All five rungs unavailable.**

**`campaign-finance` — § 211A.12 CONTRIBUTION LIMITS**

> (c) Notwithstanding sections 211A.02, subdivision 3, and 410.21, this section supersedes any home
> rule charter.

Duluth and Saint Paul are both home rule charter cities, so the statute displaces any local limit,
and the dollar figures in (a) are the legislature's. Rungs 2, 3 and 4 are positions on contribution
limits and are therefore state levers; rungs 1 and 5 are beyond any city.

**`cannabis-policy` — § 342.13 LOCAL CONTROL**

> (a) A local unit of government may not prohibit the possession, transportation, or use of cannabis
> flower, cannabis products… (b) … a local unit of government may not prohibit the establishment or
> operation of a cannabis business… (c) A local unit of government may adopt reasonable restrictions
> on the time, place, and manner of the operation of a cannabis business provided that such
> restrictions do not prohibit the establishment or operation of cannabis businesses.

🔴 **This REVERSES the Florida finding and must not be copied from it.** In Florida the topic stayed
live because a Florida city may pass a civil-citation ordinance. Minnesota both legalised cannabis
and barred local prohibition, so rungs 1–3 are removed outright. Rung 4 *is the state's own law* —
the Florida trap in mirror image, where working backwards would seat all 18 at one chair. Rung 5 is
not a council lever either; § 342.22 registration is mandatory.

**The eight `education-*` topics — § 123B.02 GENERAL POWERS OF INDEPENDENT SCHOOL DISTRICTS**

> Subdivision 1. Board authority. The board must have the general charge of the business of the
> district, the school houses, and of the interests of the schools thereof.

Duluth (ISD 709) and Saint Paul (ISD 625) are independent school districts with their own elected
boards. One citation settles eight topics: `education-ai`, `education-charter-authorization`,
`education-curriculum`, `education-equity-programs`, `education-gender-identity`,
`education-library-books`, `education-school-budget`, `education-school-police`.

⚠ Our database holds no school-district government for either city. That is a fact about our data,
not the world, so this finding rests on the statute and not on that absence.

### Structural — the ladder's rungs are not municipal acts

These four follow the Charlotte precedent, which separated "the office holds no lever" from "the
lever exists but no evidence was found". Basis is the subject matter of the rungs, not a Minnesota
preemption clause.

- **`abortion`** — every rung is a question of state law on legality and timing limits. No city lever.
- **`fossil-fuels`** — every rung is about national production levels, drilling permits and public land.
- **`trans-athletes`** — eligibility is set by the state, the school board and the athletic
  associations, not by a city.
- **`jail-capacity`** — the jails serving these cities are run by the **Ramsey County** and
  **St. Louis County** sheriffs and funded by their county boards. A city member holds no vote on
  capacity, alternatives, or detention funding.

---

## LIVE — 20 topics, 360 rows

### The four that make Minnesota different, each with a cited municipal instrument

**`rent-regulation` — § 471.9996 subd. 2, and Legislative Code ch. 193A**

> **Subd. 2. Exception.** Subdivision 1 does not preclude a … city … from controlling rents on
> private residential property … **if the ordinance, charter amendment, or law that controls rents is
> approved in a general election.**

Subd. 1 also preserves four powers needing no vote, notably (1) property the city has a financial
interest in through a housing authority — the same shape as the NC § 42-14.1(c) carve-out that let
Charlotte's chair 4 survive — and (4) mediation between owners and tenants.

The lever was pulled, and the record is in `stpaul`:

| File | Date | Title |
|---|---|---|
| RES 21-968 | 2021-06-28 | Adopting the report of Ramsey County Elections finding that the petition for an initiative to adopt Chapter 193A… |
| Ord 22-16 | 2022-03-10 | Amending Chapter 193A … to define certain terms contained therein |
| Ord 22-37 | 2022-07-27 | Amending Chapter 193A … pertaining to rent stabilization |
| Ord 25-29 | 2025-03-19 | Amending Chapter 193A.08 … pertaining to rent stabilization |

Rung 3 — *maintain current tenant protections while allowing market rents for new construction* —
describes a live municipal choice precisely. **Read the text of Ord 22-37 and Ord 25-29 before
seating anyone**; the titles say the subject, not the position.

**`minimum-wage` — Legislative Code ch. 224**

| File | Date | Title |
|---|---|---|
| Ord 18-54 | 2018-10-08 | **Creating Chapter 224** of the Legislative Code to implement a City minimum wage |
| Ord 26-31 | 2026-06-15 | Amending Section 224.05(c) … to eliminate the City's provisional 90-day minimum wage rate |

§ 177.24 sets the state floor and carries no local preemption clause; the existence and continued
amendment of ch. 224 is the stronger proof that the lever exists.

🔴 **CORRECTED 2026-10-04 — Ord 26-31 is NOT usable.** This section called it the most promising
instrument in the slice. Its roll call is **7–0, adopted 2026-08-12**, and C46 refuses a unanimous
vote. See [`instruments.md`](./instruments.md). The ladder stays live; only the instrument fails.

⚠ Blank in NC (§ 95-25.1(d)) and FL (§ 218.077). Do not carry either conclusion across.

**`local-immigration` — Administrative Code ch. 44**

| File | Date | Title |
|---|---|---|
| Ord 18-21 | 2018-05-07 | Amending **Chapter 44** of the Administrative Code on Employee Authority in Immigration Matters |
| RES 25-1980 | 2025-12-10 | City Council actions in response to SPPD conduct during federal immigration enforcement |
| PH 25-10 | 2025-12-11 | Public hearing on federal immigration operations and Saint Paul Police Department conduct |

No Minnesota anti-sanctuary preemption was found, and the city has legislated in the field and acted
again ten months ago. **All five rungs appear live** — against FL § 908.103 and NC § 160A-205.2,
which each removed rungs 1 and 2.

🔴 **CORRECTED — RES 25-1980 is NOT usable**: adopted **5–0 with 2 absent**, so C46 refuses it, and
Bowie and Johnson were the absences (an absence is not a position). The ladder stays live; the
resolution seats nobody.

**`ranked-choice-voting` — Legislative Code ch. 31**

| File | Date | Title |
|---|---|---|
| Ord 10-60 | 2010-12-08 | An Ordinance creating election rules for municipal elections under **ranked voting** |
| Ord 18-12 | 2018-02-16 | Amending **Chapter 31** of the Legislative Code pertaining to ranked voting |
| CCI 25-8 | 2025-11-19 | Announcement of Charter Amendment Ballot Question Result |

Rungs 2 and 3 are reachable by a Saint Paul member; rung 5 (*ban by law*) is a state lever, and
rung 1 (proportional multi-seat) would need a charter change, which the charter-amendment route
makes possible rather than impossible. **Blank in both NC (§ 163-292) and FL (§ 101.019, banned
statewide).**

### The other sixteen — ordinary municipal subject matter

`2020-election` · `childcare` · `city-sanitation` · `civil-rights` · `climate-change` ·
`data-centers` · `economic-development` · `growth-and-development` · `homelessness` ·
`homelessness-response` · `housing` · `local-environment` · `public-safety-approach` ·
`religious-freedom` · `residential-zoning` · `transportation-priorities`

Charlotte treated `2020-election`, `childcare`, `civil-rights`, `climate-change`, `religious-freedom`
and `homelessness` as **searched** blanks rather than scope blanks — the lever exists, the evidence
did not. This slice follows that precedent.

⚠ `public-safety-approach` is the ladder Charlotte wrote up as defective for Season 3: its chairs 1
and 3 do not separate a member who funds both police and prevention, and **7 of Charlotte's 12 spoke
substantively on it and none could be seated**. Expect the same here and do not force a chair.

---

## Duluth is in scope on all 20, but with a thinner record

Both cities are home rule charter cities, so the statutory frame is identical and the **office**
holds the same levers. Duluth has no rent-stabilization ordinance, no city minimum wage and no
ranked voting, so for those three the lever exists but has not been exercised — a Duluth member's
position has to come from their words, not from an instrument. That is statement evidence, which
goes to human review, not a scope blank.

---

## Running totals

| | Topics | Rows |
|---|---|---|
| Scope blank | 15 | 270 |
| Live | 20 | 360 |
| **Total** | **35** | **630** |

The four ordinances are now read — see [`instruments.md`](./instruments.md). Next: Duluth
instruments (no API, so HTML work), then outlet profiling, then research one member per run.
