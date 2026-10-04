# Minnesota scope review — Duluth and Saint Paul city offices

Season 2, 35 ladders at `local`, 18 seated people. Scope is a **per-rung** question (ruling
2026-08-28), and a scope blank is a fact about the **office**, identical for every member of the
body — so each finding below templates across all 18 rows for that topic.

Every statute below was read as **verbatim text fetched from `revisor.mn.gov` with `curl`**, not
through WebFetch, because WebFetch summarises and this programme has already paid for a fabricated
citation. The extractor was checked against four different sections before any finding was recorded:
its first pass returned the same site navigation for all four, which is the broken-detector
signature, and every finding below rests on the second pass, which returns four distinct bodies.

---

## SETTLED — 11 topics, scope blank for both cities (198 rows)

### `gun-policy` — § 471.633 FIREARMS

> The legislature preempts all authority of a home rule charter or statutory city including a city
> of the first class, county, town, municipal corporation, or other governmental subdivision, or any
> of their instrumentalities, to regulate firearms, ammunition, or their respective components to
> the complete exclusion of any order, ordinance or regulation by them except that: (a) a
> governmental subdivision may regulate the discharge of firearms; and (b) a governmental
> subdivision may adopt regulations identical to state law.

Whole field, as in NC § 14-409.40 and FL § 790.33. Neither exception reaches a rung: no rung is a
discharge rule, and adopting a regulation *identical to state law* is not a position a council
chooses. **All five rungs unavailable.**

### `campaign-finance` — § 211A.12 CONTRIBUTION LIMITS

> (c) Notwithstanding sections 211A.02, subdivision 3, and 410.21, this section supersedes any home
> rule charter.

Duluth and Saint Paul are both home rule charter cities, so the statute displaces any local limit
they might set, and the dollar figures in (a) are the legislature's. Rungs 2, 3 and 4 are all
positions on contribution limits and are therefore state levers; rungs 1 and 5 are beyond any city.
**Same conclusion as NC § 163-278.13 and FL § 106.08(11)(a), but on an explicit supersession clause.**

### `cannabis-policy` — § 342.13 LOCAL CONTROL

> (a) A local unit of government may not prohibit the possession, transportation, or use of cannabis
> flower, cannabis products… (b) Except as provided in section 342.22, a local unit of government
> may not prohibit the establishment or operation of a cannabis business… (c) A local unit of
> government may adopt reasonable restrictions on the time, place, and manner of the operation of a
> cannabis business provided that such restrictions do not prohibit the establishment or operation
> of cannabis businesses.

🔴 **This REVERSES the Florida finding and must not be copied from it.** In Florida `cannabis-policy`
stayed live because a Florida city may pass a civil-citation ordinance. In Minnesota the state both
legalised cannabis and barred local prohibition, so rungs 1, 2 and 3 are removed outright. Rung 4
*is the state's own law*, which is the FL trap in mirror image — working backwards from it would
seat all 18 at 4. Rung 5 is not a council lever either; § 342.22 registration is mandatory.
**All five rungs unavailable.**

### The eight `education-*` topics — § 123B.02 GENERAL POWERS OF INDEPENDENT SCHOOL DISTRICTS

> Subdivision 1. Board authority. The board must have the general charge of the business of the
> district, the school houses, and of the interests of the schools thereof. The board's authority to
> govern, manage, and control the district; to carry out its duties and responsibilities; and to
> conduct the business of the district includes implied powers in addition to any specific powers
> granted by the legislature.

Duluth (ISD 709) and Saint Paul (ISD 625) are independent school districts with their own elected
boards. The lever on every school question belongs to that board, not to the city council or the
mayor. This is the Charlotte-Mecklenburg Board of Education pattern, and it settles **eight topics
at once**: `education-ai`, `education-charter-authorization`, `education-curriculum`,
`education-equity-programs`, `education-gender-identity`, `education-library-books`,
`education-school-budget`, `education-school-police`.

⚠ Our database holds no school-district government for either city. That is a fact about our data,
not about the world, so the finding above rests on the statute and not on that absence.

---

## SETTLED — `rent-regulation` is LIVE, and this is why the slice was opened

### § 471.9996 RENT CONTROL PROHIBITED

> **Subdivision 1. In general.** No statutory or home rule charter city, county, or town may adopt
> or renew by ordinance or otherwise any law to control rents on private residential property
> **except as provided in subdivision 2.** This section does not impair the right of any statutory or
> home rule charter city, county, or town: (1) to manage or control property in which it has a
> financial interest through a housing authority or similar agency; (2) to contract with a property
> owner; (3) to act as required or authorized by laws or regulations of the United States government
> or this state; or (4) to mediate between property owners and tenants for the purpose of
> negotiating rents.
>
> **Subd. 2. Exception.** Subdivision 1 does not preclude a statutory or home rule charter city…
> from controlling rents on private residential property to the extent that the city… has the power
> to adopt an ordinance, charter amendment, or law to control these rents **if the ordinance,
> charter amendment, or law that controls rents is approved in a general election.**

**This is the finding the slice was chosen on, and it holds — with a condition attached.** Minnesota
is not NC or FL: rent regulation is not preempted outright. A council acting alone cannot adopt it,
but a measure approved at a general election is lawful, and four powers in subd. 1 need no vote at
all — notably (1) property the city has a financial interest in through a housing authority, which
is the same shape as the NC § 42-14.1(c) carve-out that let Charlotte's chair 4 survive, and (4)
mediation.

So the rungs are **not** categorically removed, and a member's votes and words on rent are real
positions rather than restatements of state law. Rung 3 — *maintain current tenant protections while
allowing market rents for new construction* — describes a live municipal choice precisely.

🔴 **Still to establish before any row is written:** whether Saint Paul's ordinance exists in the
form assumed, what the council has actually voted on since, and whether Duluth has any ordinance at
all. The statute proves the **lever exists**; it does not prove anyone pulled it. Do not write a row
from this section alone.

---

## NOT YET SETTLED — do not template these

| Topic | Status |
|---|---|
| `minimum-wage` | § 177.24 subd. 1 sets the state wage and carries **no** local preemption clause in the text read, but §§ 177.21–177.35 were not read end to end, and the Saint Paul ordinance was not located. **Leaning LIVE — unproven.** |
| `ranked-choice-voting` | The basis is the home rule charter, not a statute I have found. The revisor search page returned **zero** cites, and that page is JS-rendered, so the search was **blind** — it is not evidence that no statute exists. |
| `local-immigration` | No Minnesota preemption found, but not yet searched properly. If none exists, all five rungs are live — a sharp contrast with FL § 908.103 and NC § 160A-205.2, both of which removed rungs. |
| The remaining 21 | Per-rung review outstanding. Several are plainly municipal (`residential-zoning`, `city-sanitation`, `transportation-priorities`, `housing`, `growth-and-development`, `local-environment`) and several plainly are not (`abortion`, `2020-election`, `trans-athletes`, `religious-freedom`), but "plainly" is not a citation. |

## Running count

- **11 topics settled as scope blanks** → 11 × 18 = **198 rows** templated.
- **1 topic settled as live** (`rent-regulation`).
- **23 topics outstanding.**

For comparison: Charlotte ended at 216 scope blanks of 420 rows, Florida at 306 of 595.
