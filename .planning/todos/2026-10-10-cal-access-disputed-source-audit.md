# CAL-ACCESS — the 1,336 DISPUTED sources: audit and worklist

> 🟢 **CLOSED 2026-10-11 AT BOTH ENDS.** Detachment closed with `CC_0229`; **STEP 2, the positive
> half, closed with `CC_0230`** — 9 committees re-attached to Stern, Umberg and Durazo on the
> evidence of their own CAL-ACCESS candidate pages, 3 repointed as withheld outside spending, 1
> disproved, 4 left unsettled, and the 19 placeholder rows detached.
> 🔴 **CONFIRMING THE 9 QUEUES THEM FOR INGESTION — three sitting senators gain real campaign
> finance.** "All 19 carry $0" was true of our corpus only. See the `CC_0230` section.
>
> **STATUS 2026-10-11, measured on prod.** The 1,336 in the title is where this opened.
> **365 remain.** `CC_0229` closed the last shape — the 64 surname-NOT-LEADING rows on inactive
> politicians: **63 detached, 1 kept.**
>
> 🟢 **NO DISPUTED CAL-ACCESS SOURCE OF ANY OF THE THREE SHAPES IS NOW UNREAD**, live or inactive.
> The 365 that remain are the honest residue: rows whose committee name begins with the surname
> and carries no forename, no place and no bucket to argue from. They need a CAL-ACCESS candidate
> page or a Form 460 Part 5.
>
> _Earlier:_ 1,027 after `CC_0226`; 733 after `CC_0227`; 428 after `CC_0228`. `CC_0227` (live) and `CC_0228` (inactive) cleared the whole
> *starts-with-surname* shape: **599 detached of 953, 354 kept.** 🟢 **No disputed CAL-ACCESS
> source of ANY of the three shapes is now unread.** What is left is **428** rows that carry no
> in-corpus signal at all and need a CAL-ACCESS candidate page or a Form 460 Part 5.
>
> _Earlier:_ 1,027 after `CC_0226`; 733 after `CC_0227`. `CC_0227` cleared the live *starts-with-surname* bucket (294 detached of 508;
> **214 kept**, a far higher genuine rate than `CC_0226`'s 4.7%). What is left: **445 inactive**
> starts-with-surname, plus **123 live + 41 singleton** rows that carry no in-corpus signal at all
> and need a CAL-ACCESS fetch.
>
> _Earlier, 2026-10-10:_ **1,027 remained.** `CC_0223` cleared the no-surname bucket (103) and `CC_0226` the
> surname-not-leading bucket on live rows (204, keeping 10 genuine support/oppose committees);
> `CC_0225` retyped 2 to `ie_committee`. **No live row carries an unread disputed source of
> either shape any more.** What is left is 508 live + 445 inactive that START with the surname
> (plausible, unverified, $0) and 64 inactive that do not.

Opened 2026-10-10, after `CC_0221`/`CC_0222` closed the **confirmed** population.
Brief that deprioritised this population: `2026-10-10-cal-access-published-source-audit.md` (closed).
Result of the confirmed audit: `2026-10-10-cal-access-confirmed-518-audit-log.md`.

## 🔴 THE REFRAMING — THE HANDOFF MEASURED THE WRONG AXIS

It shelved this population on **money**: only 2 of the 1,336 carry a contribution, so adjudicating
them "changes nothing a voter sees". Both halves are true and the conclusion does not follow.

▶ **827 of the 1,336 sit on LIVE politician rows.** That is the `CC_0220` hazard — a `disputed`
source on a live officeholder is a loaded gun, because the thing that created it (a name match) is
also the thing a later pass would use to confirm it. Nothing publishes today; the exposure is the
next pass, and the next merge.

| population | sources | politicians | on LIVE rows | carry money |
|---|---|---|---|---|
| mig 1792 UNVERIFIED | 1,205 | 234 | **707** | 0 |
| `CA_0192` primarily-formed | 105 | 52 | **105** | 2 |
| `confirm-cal-access.ts`, no later note | 18 | 5 | 15 | 0 |
| `CC_0216`/`CC_0217` downgrades | 5 | 1 | 0 | 0 |
| `CC_0221` support/oppose | 3 | 3 | 0 | 0 |

## 🔴🔴 THREE PREDICATES RAN BEFORE THE TRUE ONE

Each was discarded only because rows were **read**. This is the whole method; the counts are
worthless without it.

1. **Forename test** — said 705 of 707 live-row sources "do not name the politician". **False.**
   They are surname-only local committees (`MOSS FOR SCHOOL BOARD 2014`), which `CC_0221` already
   established is normal and evidence of nothing.
2. **Surname-anywhere test** — found 100 with no surname match. **Real but incomplete.**
3. 🔴 **A surname test PASSES WHEN THE POLITICIAN'S SURNAME IS SOMEBODY ELSE'S FORENAME.** Caught
   by `CC_0223`'s own pre-verify gate, which refused to run: three on Karen **Douglas** —
   `STREHL … FOR THE ELECTION OF DOUGLAS`, `PHIMISTER FOR JUDGE, CITIZENS FOR DOUGLAS C.` Same
   shape as Paulette Francis / Francis Carbajal in `CC_0221`.

▶ **The test that holds: does the committee name START with the politician's surname?** California
committees are named `SURNAME FOR OFFICE …` or `SURNAME, COMMITTEE TO ELECT FORENAME`.

## ✅ DONE — `CC_0223`: 103 foreign committees on SEVEN LIVE rows

Not one of the 103 begins with the politician's surname; all were read; none carries money.

| live politician | n | actually belongs to | in corpus? |
|---|---|---|---|
| Francis De Leon Sanchez `e086df00` | **80** | Van de Kamp · De Vore · De Maio · De Saulnier · De Young · … | mostly no |
| Gregg Hart `21940b7c` | 8 | **Henry Stern** | ✅ live incumbent |
| Dr. Corey A. Jackson `bbd7825a` | 5 | **Thomas Umberg** | ✅ live incumbent |
| Karen Douglas `5d6cae71` | 4 | Hardcastle · Douglas Strehl ×2 · Douglas Phimister | no |
| Jasmeet Kaur Bains `539874fc` | 3 | **Maria Elena Durazo** | ✅ live incumbent |
| Steve Bennett `8c61cd23` | 2 | Valladares — **three candidates, ambiguous** | ✅ but unclear which |
| Phillip Chen `ed32efa5` | 1 | **Debra Archuleta** (LA District Attorney 2024) | ✅ live |

🔴🔴 **Sanchez's 80 came from matching the particle "DE"** — a two-letter token. Larger than Dan
O'Brien's 44 in `CC_0221`, and unlike those eight rows **this one is LIVE**.

⚠ **These rows were already partly cleaned; this was the residue.** Sanchez also carries 109
`not_applicable`, Douglas 38, Chen 10, Bains 8. **A row that has been worked is not finished.**

## ✅ DONE — `CC_0230`: STEP 2, the POSITIVE half. 9 re-attached, 3 withheld, 5 held, 19 placeholders cleared

**Applied to prod 2026-10-11**, after a `ROLLBACK` dry run whose revert was confirmed and **two**
tamper controls: dropping one worklist entry failed at 16, and pointing every re-attachment at
Stern failed with *"Stern holds 9 confirmed, expected 4"* — so the per-target split gate really
does catch a mis-targeted repoint, which is the defect this migration could have introduced.

🟢 **THE DISPUTED-SOURCE PROGRAMME IS NOW CLOSED AT BOTH ENDS.** Detachment closed with `CC_0229`
(969 sources, 1,336 → 365). This is the positive half, and it is a different kind of work:
detaching needed only proof of whose a committee is *not*; **attaching is a positive claim on a
live officeholder.** Nothing below moved on a name match.

| outcome | n | what |
|---|---|---|
| re-attached, `confirmed` | **9** | Stern 4 · Umberg 4 · Durazo 1 — each listed BY FILER ID on their own CAL-ACCESS candidate page |
| re-attached, withheld | **3** | name the person, absent from their page ⇒ outside spending; typed `ie_committee`, held `not_applicable` |
| **disproved** | 1 | `1076598` is a different Stern |
| unsettled, left detached | 4 | Stern Supervisor ×2 · Durazo name-only ×2 |
| Valladares | 2 | unchanged, per the standing ruling |
| **placeholders detached** | **19** | the `CC_0220` merge hazard, closed |

### 🔴🔴 THE PREMISE "ALL 19 CARRY $0 SO NOTHING PUBLISHES" WAS INCOMPLETE

$0 was true of **our corpus**, not of what happens next. `campaignFinanceScheduler.ts` selects
`research_status = 'confirmed'` with **no `source_type` filter**, and all 448 confirmed
`cal_access` candidate committees on prod have a completed ingestion run — **none has no run at
all.** So confirming the nine QUEUES them, and CAL-ACCESS holds real money: `STERN FOR SENATE
2024` alone reports **$388,174.70** raised in 2024.

▶ **Expect Stern, Umberg and Durazo to move from no finance data, through `data_pending`, to real
dollars.** That is the correct outcome. It is recorded because it is far larger than "re-attach 19
dead rows", and the worklist said the opposite. Operator signed it off before apply.

### 🔴 THE WITHHELD THREE ARE IN A DEADLOCK, AND IT IS NAMED ON THE ROWS

`getOutsideSpendingForPolitician` has **no zero-amount filter**, so a `confirmed` IE row with no
ingested money publishes a card reading **$0 with no donors**. But the scheduler ingests
`confirmed` rows only — so holding them is itself what keeps them at $0. ▶ The exit is to confirm
them and accept one ingestion cycle. One `UPDATE`, whenever the empty window is acceptable.

- `1385335` CALIFORNIANS IN SUPPORT OF HENRY → Stern, `support`
- `1463858` SAFER LA COMMITTEE SUPPORTING JUDGE DEBRA → Archuleta, `support`
- ⚠ `1235879` UMBERG, CONSUMERS FOR TOM → Umberg, **`support_oppose` left NULL.** *FOR* is not
  approved support wording — it is the shape of a candidate's OWN committee name, the `FRIENDS OF`
  trap from `CC_0221`. ADR 0008 forbids a defaulted direction, so it is owed one.

### 🔴🔴 TWO DETECTORS THAT WOULD HAVE MISLED THIS MIGRATION

1. **A candidate page's race history covers STATE races ONLY.** Durazo is an LA County Supervisor
   candidate in 2026 — her own page carries `DURAZO FOR SUPERVISOR 2026 ATTORNEY FEES FUND`
   (1480691) — and her race list does not mention it. ▶ So Stern's race list showing only SD-27 is
   **vacuous** against `STERN FOR SUPERVISOR 2022`. A negative read off that list proves nothing
   for any county or municipal race.
2. **The filer phone groups by FILING AGENT, measured cleanly here.** **(916) 285-5733 is shared
   by ALL FIVE of Stern's committees AND FOUR of Umberg's** — two state senators, one treasurer.
   A sharper demonstration than the one `CC_0216` recorded.

### ▶ What is still open from step 2

- **The 4 unsettled.** `1442984`/`1442999` (STERN FOR SUPERVISOR 2022 + fees fund) and
  `1479450`/`1480690` (both registered literally `DURAZO, MARIA ELENA`). Absent from the candidate
  pages, **no electronic filing at all** so no Form 460 Part 5 exists to read, and no `la_socrata`
  row either. 🟢 The "no filings" reading was CONTROLLED against 1435181/1458805/1415628/1480691,
  which all return full summary data.
  ⚠ **The Durazo pair is the close call, left on the honest side.** Its case is strong — the
  registered name IS her exact full name, which no surname-matcher failure mode can produce; same
  treasurer as all five confirmed committees; 1480690 is ADJACENT to 1480691, which IS on her
  page; both ACTIVE in her cycle. The bar was the candidate page or Part 5. Neither answers.
- **`1235879` is owed a direction.**
- **The junk `politicians` rows are untouched** — 24,044 wide, and
  [`2026-07-03-cal-access-committee-rows-in-politicians`](2026-07-03-cal-access-committee-rows-in-politicians.md)
  is where they belong. Only their SOURCE rows were detached. 10 of the 12 committees carry **two**
  placeholder rows each.

### ⚠ A GATE THAT TIMED OUT, AND THE FIX IS LOAD-BEARING

The first dry run died on `canceling statement due to statement timeout` in the zero-contributions
gate. `contributions.politician_source_id` **is** indexed — but a plain `JOIN` to an un-analysed
TEMP table makes the planner sequential-scan `contributions`. ▶ `ANALYZE` the temp table and use
`= ANY(ARRAY(SELECT …))`. Both are in `CC_0230` and both are required.

## ✅ DONE — `CC_0226`: the surname-not-leading slice. 204 detached, 10 kept

**Applied to prod 2026-10-10**, after a `ROLLBACK` dry run whose revert was confirmed and a
tamper control that fired with the right number (one keep removed -> the gate reported 205).

▶ **It was 214 live, not 212.** The 212 are the mig-1792 provenance; two more on William Scott
come from `confirm-cal-access.ts`. Worked together. The disputed total also moved 1,233 -> 1,231
because `CC_0225` retyped Gipson and the Newsom recall committee — that reconciles, not drift.

🔴 **10 of 214 are genuine, which is 4.7% — NOT the "roughly one in five" estimated from a sample
of 18.** The estimate was a lead, not a measurement. **Do not size the inactive-64 slice by it.**

| kept (still `disputed`, all $0) | politician | direction |
|---|---|---|
| `1347821` OPPOSED TO NAZARIAN FOR ASSEMBLY 2012 (EdVoice IE) | Adrin Nazarian | **oppose** |
| `1322096` ...OPPOSING THE ELECTION OF MICHAEL KEEGAN ... 2009 | Michael Keegan | **oppose** |
| `1444231` PRICE FOR MAYOR 2022 AND OPPOSING REX RICHARDSON | Rex Richardson | **oppose** |
| `1472886` ...AND AGAINST BROCK FOR CITY COUNCIL 2024 | Phil Brock | **oppose** |
| `1253962` CHINESE AMERICANS FOR NEWSOM | Gavin Newsom | support |
| `1396278` LEON, BACA DEL RIO & ALTAMIRANO ... COMMERCE FORWARD | Ivan Altamirano | support |
| `1416361` D'AMICO, LINDSEY HORVATH, AND LAUREN MEISTER ... 2019 | Lindsey P. Horvath | support |
| `1423605` DEVINE, GHARPETIAN AND ASTORIAN ... GLENDALE | Vartan Gharpetian | support |
| `1451076` ENGLER, NEWMAN, AND ROHRBACH ... THOUSAND OAKS 2022 | Kyle Rohrbach | support |
| `1474164` WILKE AND CHRIS RIZZOTTI ... BURBANK 2024 | Chris Rizzotti | support |

🔴🔴 **THE TEST THAT SETTLED IT WAS JURISDICTION, NOT THE NAME.** Reading the committee name is
necessary and not sufficient. Four read as genuine and were disproved only by checking the seat:

- **Eniko Gold** is **Hidden** Hills; the committee is **Beverly** Hills (Lili Bosse's city).
- **Doug Stewart** is Mayor of **Malibu**; the committee is the **San Mateo County** DCC.
- **Linda Freedman** is Mayor of **Walnut**; `REDLANDS FOR FREEDMAN` is 60 miles away.
- **Pete Aguilar** is a **US Representative**; the committee is **Hesperia school board**.

🟢 **And the strongest instrument needed no network call: the politician's OWN committees, already
in this corpus.** `ROHRBACH FOR THOUSAND OAKS CITY COUNCIL 2022; KYLE` sits beside the disputed
`ENGLER, NEWMAN, AND ROHRBACH ... THOUSAND OAKS 2022` — same city, same year, same race. And
Penny Sylvester's `SYLVESTER FOR CVUSD SCHOOL BOARD 2024; KAREN` is **already `not_applicable`**,
so the corpus itself named the other Sylvester and settled her two CVUSD rows as foreign.

⚠ **Two findings carried forward, neither carrying money, both OUT OF SCOPE for `CC_0226`:**
- **Penny Sylvester** holds `SYLVESTER FOR DALY CITY COUNCIL 2020` / `...DC COUNCIL 2016` as
  **`confirmed`**, while she is seated as **Mayor of Agoura Hills** — 350 miles apart. One of the
  two is wrong, and a `confirmed` row is a published attribution. Belongs in the confirmed audit.
- **Phil Brock** has **no `office_current_holder` row** though he is a sitting Santa Monica council
  member — an occupancy gap, the `offices_missing_terms` class.

## ✅ DONE — `CC_0227`: the LIVE starts-with-surname bucket. 294 detached, 214 kept

**Applied to prod 2026-10-11**, after a `ROLLBACK` dry run whose revert was confirmed and a tamper
control that **removed the forename protection and fired with exactly 28** — the Hochman, Barger,
Bass, Bonta, Newsom and Park rows it exists to protect.

🔴 **THIS SLICE IS A DIFFERENT PROBLEM, AND THE WORKLIST'S COST ESTIMATE WAS WRONG.** It said
"~486 Form 460 fetches for no voter-visible change". It was not 486 fetches. Reading the name
proves nothing here — the name *starts* with the surname, so it is consistent with the attribution
either way. ⚠ **And the jurisdiction test that carried `CC_0226` does NOT reach this population:
500 of the 953 sit on politicians with no `office_current_holder` row at all.**

Three in-corpus signals did the work instead:

1. 🟢 **The forename.** `SURNAME, COMMITTEE TO ELECT <FORENAME>` is decisive both ways.
2. 🟢 **Bucket context** — `CC_0221`'s reasoning for Dan O'Brien's 44.
3. 🟢 **The politician's own committees** — the `CC_0226` instrument.

⚠ **PR #972 tried a forename test and abandoned it** ("every one of the 22 I read is a false
positive" — `FRIENDS OF TED` on Ted Lieu). Those examples are forename **agreements** its detector
called conflicts; the implementation was inverted, not the idea. ▶ **So agreement is used only to
PROTECT a row, never to detach one**, and that is the gate the control above exercises.

🔴 **PARSE ARTIFACT:** `Dr. Monica Sanchez` has `first_name = 'Dr.'`, so a naive forename
comparison misses two rows that plainly read `SUPPORT MONICA`. Strip honorifics, and require
`length(forename) >= 3` so an initial cannot match everything.

| the buckets | n | what they actually contain |
|---|---|---|
| Pat Wilson, Rolling Hills (pop ~1,900) | 33 | Lori (Suisun City), Hazel, Abram … and **four about Pete Wilson, the former Governor** |
| David L. Bradley, Rancho Palos Verdes | 9 | every one is **Tom Bradley**, Mayor of LA 1973-93 |
| Britt Huff, Rolling Hills Estates | 6 | every one is **Bob Huff**, the state senator |
| Robert Luna, LA County Sheriff | 12 | Mickie Solorio, Sylvia, David, Sammie, Ray, George |

🔴 **Two buckets are MIXED, which is why this cannot be a predicate.** **Janice Hahn**'s other
eight are her father **Kenneth P. Hahn** and her brother **James Hahn**; one names JANICE for her
exact seat. **Rob Bonta**'s fifth is `… FOR **MIA**` — Mia Bonta, who succeeded him in AD-18.

### ▶ The genuine rate is nothing like the last slice

`CC_0226` kept 10 of 214 (4.7%). **`CC_0227` keeps 214 of 508.** A committee named
`SURNAME FOR OFFICE` about the right person *is* their race, so this population is far richer in
real independent-expenditure committees — Hochman (7 of 7), Barger (7 of 7), Newsom (8 of 8),
Bass (6 of 6), Mitchell, Hutt, Caloza, Hernandez, Raman, Thurmond, Kounalakis, Richardson and ~25
more. ⚠ **Do not size the inactive-445 slice from `CC_0226`'s rate.**

⚠ Several kept rows are OPPOSE committees — `CALIFORNIANS TO RECALL GAVIN`, `VOTE SMART CALIFORNIA
OPPOSING` Ivan Altamirano, `OPPOSING PATTY` Lopez, the recall of Nancy Tragarz. Withheld until
typed and evidenced, as `CC_0226`'s ten are.

### ▶ The honest residue — 164 live rows that CANNOT be settled from this corpus

**123** in buckets of 2-4 and **41** singletons carry no forename, no place and no bucket to argue
from: `JOHNSON FOR CITY COUNCIL`, `ARELLANO FOR MAYOR`, `PARRA 2007`. They are left `disputed` and
not guessed at. Settling them needs a CAL-ACCESS candidate page or a Form 460 Part 5.
Four more are named in `CC_0227`'s `_big_keep` as explicitly **UNSETTLED** rather than evidenced:
John King's two Supervisor rows (he genuinely ran), Emmanuel Estrada's `FOR MAYOR 2020`, and Juan
Carrillo's 2022 officeholder account (Wendy Carrillo held AD-52 the same year).

## ✅ DONE — `CC_0228`: the INACTIVE starts-with-surname bucket. 305 detached, 140 kept

**Applied to prod 2026-10-11.** Companion to `CC_0227`. These sit on inactive rows, so nothing
publishes and the confirm-sweep hazard does not apply — **the exposure is the dedupe merge.**
`CC_0220` put 18 foreign committees onto two LIVE rows by merging an inactive duplicate that
carried them. Clearing these is what makes the dedupe programme safe.

⚠ **Only two of `CC_0227`'s three instruments survive here**: an inactive row has no
`office_current_holder` entry, so there is no seat to compare a jurisdiction against.

🟢 **But a third is stronger here than anywhere — the politician's ALREADY-`not_applicable` rows.**
**Diana Corona** holds **33** already-detached: Corona *city* council committees for Button,
Casillas, Connell, Husen, Kelly, Kindred, Rizvi, Speake, Tolstikov — plus other people named
Corona. "Corona" matched a CITY and a SURNAME at once, and not one of her 39 is hers.
**George Fuller** holds 25, nearly all **Jean Fuller**, the state senator.

### 🔴🔴 What the forename protection caught — the reason bucket size can be used as evidence

Two "buckets" are not buckets. They are a real person's COMPLETE committee set, misfiled:

- **Tim Nader** — all **8** read `TIM`: Assembly, Judge ×3, Southwestern College Board ×3,
  `FRIENDS OF TIM`.
- **David Patterson** — all **5** read `DAVID`.

▶ **The control proves it.** With the protection removed, the gate fired at **26 rows — of which
13 are Nader's and Patterson's complete sets.** A bucket rule alone would have erased two real
people's entire committee histories.

🔴 **A DIMINUTIVE IS AGREEMENT, NOT CONFLICT.** `ZUNIGA … EDDIE` on an Edward, `LAYNE … MIKE` on a
Michael, `HERBERS … SUE` on a Susan. A conflict test reading those as "a different forename" would
detach a person's own committees. All three are LEFT.

## ✅ DONE — `CC_0229`: the 64 not-leading rows on INACTIVE politicians. 63 detached, 1 kept

**Applied to prod 2026-10-11.** The companion to `CC_0226`, which did this shape on live rows.

⚠ **A post-`CC_0228` sweep said 74. It is 64** — the other 10 are `CC_0226`'s LIVE keeps, which
match the same pattern. 64 matches this file's long-standing figure.

**The matcher hit a PLACE, overwhelmingly:** IMPERIAL Irrigation District / County / Beach (11 of
Jay Imperial's 12), the city of CORONA (8), PASO ROBLES (3), ALUM ROCK (4), RANCHO SANTIAGO (3),
REED Union School District, the GILBERT Initiative, LOS ALTOS, ADELANTO, ALAMEDA.

🔴 **And a class worth naming: a LONGER SURNAME THAT MERELY CONTAINS THE SHORTER ONE** —
**MC SHANE** on Kristin *Shane*, **MC KAY** on Ben *Kay*, **DI DONATO** on Nathan *Donato*,
**BAUTISTA ZAVALA** on Saul *Zavala*, **BURKE MONTEZ** on Arturo *Montez*. A `LIKE '%surname%'`
predicate cannot tell these apart. Only reading the row does.

🟢 **Every ambiguous row was settled by the politician's OWN already-detached rows**, which is now
the most reliable instrument in this corpus:
Roberta Bacon's set names `BACON MAYOR OF FREMONT 2024; COMMITTEE TO ELECT **VINNIE**` ·
Tina Huber's names `HUBER FOR **OXNARD** CITY COUNCIL 2014 … **STEVE**`, same city and year ·
Saul Zavala's `BAUTISTA ZAVALA FOR YUBA CC BOARD 2028` was already `not_applicable`.

⚠ **And one was settled only by reading the UNTRUNCATED value.** `RESIDENTS FOR A BETTER IMPERIAL,
A COMMITTEE TO RECALL …` recalls **Grogan, Leimgruber, Maruca & Wyatt** — Jay Imperial is not among
them, and the names were in the part the first read cut off.

### 🔴 The one kept

`1277545  SOC - TO SUPPORT RECALL OF **JAY IMPERIAL** AND GARY TAYLOR` — it names him in full, and
sits in the same bucket as eleven rows that matched "Imperial" as a *place*. That is precisely why
a bucket may never be detached wholesale without reading it. Control: with the keep removed, the
gate fired at 64.

⚠ **1 of 64 is 1.6%** — below `CC_0226`'s 4.7% on the live half of this same shape, and far below
the 37% of the starts-with-surname shape. **The rate tracks the SHAPE, not the population.**

### ▶ (closed) WHAT WAS LEFT OF THIS SHAPE — the 64 on INACTIVE rows

⚠ **64 of this same shape sit on INACTIVE rows.** They carry the same merge hazard as `CC_0221`'s
eight duplicate rows — attribution first, merge second — but no live twin exposure, so they rank
below the live work. **Do not size them from the live slice's 4.7% genuine rate**; that rate was
measured on live officeholders, and an inactive row is likelier to be a pure name collision.

Measured on prod **after `CC_0226`** (all cal_access `disputed`, both provenances):

| | starts with surname | surname not leading | no surname |
|---|---|---|---|
| **live rows** (518) | 508 | **10** ✅ the genuine keeps, see above | 0 ✅ `CC_0223` |
| inactive rows (509) | 445 | **64** | 0 |

**Total disputed: 1,231 -> 1,027.**

✅ **The live half of this bucket has now been read in full, not sampled.** Every shape below was
confirmed, and `CC_0226` adds two the sample missed: the surname used as **another person's
forename** (Scott Peters, Anthony Phan — the `CC_0223` trap again), and a **name-parse artifact**
(`last_name` = "M.D" matching "DHAND M.D."). The matcher's reach is wider than surnames:

```
PRINCE FOR SAN GABRIEL VALLEY MUNICIPAL WATER DISTRICT  -> Jesse GABRIEL
NELSON FOR VILLA PARK CITY COUNCIL                      -> Traci PARK
RYU … GRIFFITH PARK FRIENDS SUPPORTING DAVID            -> Traci PARK
HENDRICKSON KING CITY COUNCIL 2012                      -> John KING  (King City, Monterey)
RESNICK FOR PERALTA COMMUNITY COLLEGE BOARD             -> Scarlet PERALTA
VOTE FOR PARKS  /  CALIFORNIANS FOR SAFE PARKS (Prop 12) -> Grant PARKS
CONWELL, DEVINCENZI, KERR & MAHER FOR SCHOOL BOARD      -> Megan KERR  (a slate, a different Kerr)
EDUCATION LEADERS SUPPORT ANTHONY PORTANTINO            -> Konstantine ANTHONY (his forename)
```

🔴 **But roughly one in five IS a genuine support/oppose committee naming the right person** —
`PRICE FOR MAYOR 2022 AND OPPOSING REX RICHARDSON`, `HALL, RASKIN, SNELL, ZERNITSKAYA, AND AGAINST
BROCK FOR CITY COUNCIL 2024`, `PETERS, COMMITTEE TO RECALL SCOTT`. **Those must NOT be detached.**
They are correctly withheld and blocked on the same question as `CC_0221`'s three and the Newsom
recall committee: **how outside spending renders support vs oppose.**

▶ **This bucket needs reading row by row. A predicate cannot separate "foreign" from "about them,
but against them".**

## Left alone, deliberately

- **486 live-row sources whose committee DOES start with the surname** — plausible, unverified, $0.
  Verifying them means ~486 Form 460 fetches for no voter-visible change.
- **498 mig-1792 sources on inactive rows** — same shape, lower stakes, no live twin exposure.
- **The `CA_0192` 105 primarily-formed committees.** All on live rows, but only 2 carry money and
  those two are the blocked ones. Retyping the other 103 `ie_committee` would publish nothing,
  because their money was never ingested.
- 🔴 **The two disputed sources that DO carry money, both on LIVE rows, both blocked on the
  support/oppose question:** `1448127` Gipson ($194,000) and `1418587` the Newsom recall committee
  ($33,172.80).

## The single blocker worth naming — now an ADR

**`OutsideSpendingCommittee` has no support/oppose field.** Five committees across `CC_0221`, this
audit and the closed brief are all waiting on that one schema-plus-read-path decision. Until it
exists, `disputed` is the honest state: publishing a recall committee under a heading that does not
say "opposing" is its own false statement about a real person.

▶ **Written up as [`docs/adr/0008-outside-spending-support-or-oppose.md`](../../docs/adr/0008-outside-spending-support-or-oppose.md)
(status: proposed, 2026-10-10).** It records that **all three currently-published outside-spending
committees are support by the luck of their names, not by evidence** — so the first oppose committee
anyone types publishes silently as the politician's own backing. The decision is a nullable
`support_oppose` that the read path **requires**, because there is no safe default.
