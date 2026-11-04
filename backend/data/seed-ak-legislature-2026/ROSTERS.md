# Alaska Legislature — verified roster, 60 elected seats

**Wave:** Alaska Legislature deep seed, 2026-10-30.
**Migrations:** `CC_0316` (structure), `CC_0317` (occupancy), `CC_0318` (portraits).
**Geography:** `scripts/load-state-tiger-boundaries.ts --state AK --fips 02 --layers sldu,sldl`
— 20 `G5210` + 40 `G5220` districts and their polygons. Production held **zero** of either
before this wave.

🔴 **EVERY SEAT IN THIS FILE IS CORRECT UNTIL 2027-01-19, AND THEN NONE OF THE HOUSE ONES ARE.**
All 40 House seats and 10 of the 20 Senate seats were on the **2026-11-03** ballot, four days
after this roster was read. Nothing goes stale on election night: **AS 24.05.080** starts the new
terms on the **third Tuesday in January** following the election. The re-seat is a
`seat_officeholder` pass against the certified results, not a re-import — see ▶ Open items.

## Sources

| # | Source | What it is | Pulled | File |
| --- | --- | --- | --- | --- |
| 1 | `akleg.gov/house.php` | The House's own 34th-Legislature member roster | 2026-10-30 | `sources/house.html` |
| 2 | `akleg.gov/senate.php` | The Senate's own 34th-Legislature member roster | 2026-10-30 | `sources/senate.html` |
| 3 | `ballotpedia.org/Alaska_House_of_Representatives` | Independent roster + date assumed office | 2026-10-30 | `sources/bp_house.html` |
| 4 | `ballotpedia.org/Alaska_State_Senate` | Independent roster + date assumed office | 2026-10-30 | `sources/bp_senate.html` |
| 5 | `ballotpedia.org/When_state_legislators_assume_office_after_a_general_election` | The term-start rule, per state | 2026-10-30 | `sources/bp_assume.html` |
| 6 | `akleg.gov/images/legislators/450x600/<CODE>.jpg` | The Legislature's own member portraits | 2026-10-30 | mirrored to storage |
| 7 | TIGER 2020/2021/2022/2023/2024 `SLDU`/`SLDL` for FIPS 02 | Geography, and dating the map | 2026-10-30 | read offline |

Parsers: `parse-roster.mjs` (1–2), `parse-ballotpedia.mjs` (3–4), `diff-sources.mjs` (1–2 vs 3–4),
`build-roster.mjs` (→ `roster-final.json`), `gen-migration-values.mjs` (→ the migrations'
VALUES blocks), `contact-sheet.mjs`, `mirror-portraits.mjs`. Raw bytes were parsed throughout.
**No name, date or count in this file came from a `WebFetch` summary or a search-result snippet.**

## Structural rulings

🔴 **THE SENATE IS LETTERED A..T AND THE HOUSE IS NUMBERED 1..40.** Alaska Const. Art. II §2 fixes
"a senate of twenty members and a house of representatives of forty members". Read from the real
TIGER `.dbf`: `SLDUST` is `'00A'..'00T'` (GEOID `0200A`..`0200T`) and `SLDLST` is `'001'..'040'`.
**Both chambers are single-member** — unlike Idaho there is no Seat A / Seat B, and the polygon
count IS the seat count in both.

🔴 **THIS IS THE INVERSE OF IDAHO AND THE TWO RULES MUST NOT BE PASTED OVER EACH OTHER.** Idaho's
pre-flight asserts lettered codes are **ABSENT**; Alaska's asserts they are **PRESENT** on `sldu`
and absent on `sldl`. Both now sit in `load-state-tiger-boundaries.ts` and each says which it is.

🔴 **`ocdDistrictSuffix('00A')` RETURNED `'0A'`, AND ALASKA IS THE FIRST STATE WHERE THAT MATTERS.**
The leading zeros in `00A` are fixed-width **padding**, not a district number, so the existing
leading-zero strip left one behind and produced `…/sldu:0A` where OCD says `…/sldu:a`. Alaska is
the first state loaded here whose district code is **purely alphabetic** — MN's `08A` and MD's
`1A` both carry a real number and never reach the new branch. ⚠ **Measured before changing it:**
zero existing `STATE_UPPER`/`STATE_LOWER` rows in production match `^0+[A-Za-z]+$`, so no existing
row moved; `ocdDistrictSuffix.test.ts` pins that as a control. Verified after the load: all 20 are
`…/sldu:A` .. `:T` and none carries a leading zero.

⚠ **`G5220` AND `G4020` SHARE A `geo_id` IN ALASKA.** House Districts 13, 16 and 20 are `02013`,
`02016`, `02020` — and so are the Aleutians East, Aleutians West and Anchorage boroughs. The key
is the pair **(mtfcc, geo_id)**, never `geo_id` alone, and `districts.state` is mixed case.

### 🔴 The Senate/House nesting, and why it is gated

Senate letter **N covers House 2N-1 and 2N**: A = 1+2, B = 3+4 … T = 39+40. Measured three
independent ways: all 40 House interior points fall inside Senate `ceil(N/2)` in the shapefile;
all 20 Senate `ALAND` values equal the sum of their two House `ALAND` values to within 0.1%; and
all 40 again with `ST_Contains` against the loaded polygons, which is the gate in `CC_0316`.

🔴 **THE PAIRINGS ARE EXACTLY WHAT ALASKA'S 2021-22 REDISTRICTING LITIGATION MOVED.** The Alaska
Supreme Court twice struck down the Board's Senate pairings around Eagle River and East Anchorage
while leaving the 40 House districts standing. So in Alaska the pairing is the part that changed,
and it is the part worth gating on. The gate confirms Eagle River (House 23, 24) pairs as Senate
**L** and East Anchorage (21, 22) as Senate **K**. A control that claimed 23 belonged to K — the
struck-down shape — failed correctly with `23->L (want K)`.

⚠ **IT IS A STRUCTURAL CHECK, NOT A VINTAGE CHECK, AND THE DIFFERENCE MATTERS.** The superseded
2013 plan nests identically, so this gate passing says **nothing** about which map was loaded.
Dating the map is the loader pre-flight's job. Keeping them apart is deliberate.

### Dating the map

🔴 **A COUNT CAN NEVER DATE ALASKA'S MAP.** 20/40 is fixed by the constitution and is byte-identical
across every TIGER vintage. Only the anchors can date it.

🟢 **ALASKA RENUMBERED END TO END IN 2021** — the old plan counted up from the Interior, the new one
from Southeast — so **21 of 28** probe points disagree between the plans. That is the opposite of
Idaho's problem, where every recognisable civic point resolved identically under both. Measured
against five vintages: **2020 and 2021 carry the superseded 2013 plan; 2022, 2023 and 2024 are
identical to one another** at all 28 points and carry the adopted plan.

The pre-flight carries **8 discriminating anchors per layer** plus 4 agreeing ones as positive
controls on the hit test. All five controls were watched failing:

| control | what fires |
| --- | --- |
| `--vintage 2021` (no flag — the real superseded plan) | vintage assertion, correctly diagnosing *"THIS FILE IS THE SUPERSEDED 2013 PLAN"* with all 8 discriminators on their 2013 values |
| `AK_PREFLIGHT_CONTROL=count` | MTFCC record-count assertion |
| `AK_PREFLIGHT_CONTROL=anchor` | vintage assertion, and correctly says this is **not** the prior plan (1 of 8 failed) |
| `AK_PREFLIGHT_CONTROL=weak` | anchor-discrimination assertion |
| `AK_PREFLIGHT_CONTROL=letters` | the Senate letter-presence assertion |

🟢 **THE ROSTER AND THE GEOGRAPHY CROSS-VALIDATE EACH OTHER.** The two were sourced independently —
one from the Legislature's member pages, one from Census shapefiles — and they agree on every
checkable seat. Ketchikan → House 1 and Senate A, and Bynum (Ketchikan) is House 1 and Stedman
(Sitka) is Senate A; Juneau → House 4 / Senate B, and Hannan and Kiehl are both Juneau; Fairbanks
→ 31 / P, Dibert and Kawasaki; North Pole → 33 / Q, Prax and Myers; Dillingham → 37, Edgmon;
Utqiagvik → 40, Frier. Neither source could have produced the other.

## 🔴 Source defects and findings

1. **The chamber pages list each member two or three times, in three different HTML shapes.** A
   leadership block uses `<li>District <span>N</span></li>`; the roster uses a `<dl>` of
   `<dt>/<dd>` pairs; a third listing carries neither. Parsing one shape returns a *complete-looking*
   roster with every district null. The parser merges all occurrences per member code and **reports
   any field that disagrees between them** — which is how the next item was found.
2. **The Senate page publishes two different "City" values per member** and they are different
   facts: the member's home city, and their district office's mailing address. Bert Stedman reads
   `Sitka` and `Ketchikan AK, 99901`; Donny Olson reads `Golovin` and `Nome AK, 99762`. The **home
   city** is kept. A parser taking the last value would have moved five members to another town.
3. 🔴 **BALLOTPEDIA PUBLISHES TWO DATES FOR EACH APPOINTEE AND ONLY ONE OF THEM IS `term_start`.**
   The infobox says Cathy Tilton was *appointed* 2025-11-26; the chamber roster says she *assumed
   office* 2025-11-29. Different events, three days apart. `term_start` is when the seat was
   **held**, so the roster date is used and the appointment date is written nowhere. Same for
   Rauscher (26th/29th Nov) and for St. Clair and Nelson (24th/30th Dec). ⚠ Same class of error as
   reading a vacancy's "date of vacancy" as the first empty day — **read what the date is a date OF.**
4. 🔴 **BALLOTPEDIA'S OWN ARTICLE II PAGE CARRIES A STALE EDITOR'S NOTE ABOUT THE TERM-START RULE,**
   describing an older split (second Monday after a presidential year, third Monday after a
   gubernatorial year). **Its own data contradicts it.** The three distinct January arrival dates in
   this roster are 2015-01-20, 2023-01-17 and 2025-01-21 — all three the **third Tuesday**, across
   both a presidential-year and a gubernatorial-year cycle. The rule is uniform, and its own
   per-state rule page says so. Corroborated a fourth way: member pages say *"current term ends on
   January 19, 2027"*, which is the third Tuesday of January 2027.
5. **Donny Olson's Ballotpedia page is at `/Donald_Olson`; `/Donny_Olson` is a real 404.** The
   alternate name is what makes him findable.
6. **Eight name disagreements between the Legislature and Ballotpedia, all formal-vs-common** —
   Chuck/Charles Kopp, Andy/Andrew Josephson, Mike/Glenn Prax, Rebecca/Becky Schwanke,
   Cathy/Catherine Giessel, Donny/Donald Olson, Robert Myers / Myers Jr., and the two members whose
   published name carries an Alaska Native middle name, **Robyn Niayuq Frier** and **Nellie Unangiq
   Jimmie**, which the aggregator drops and we keep. **None is a different person** — same district
   and same surname in every case. The Legislature's rendering is canonical; the other goes in
   `alternate_names`.
7. 🔴 **`dry-run-migration.mjs` COMMITTED TO PRODUCTION WHILE PRINTING "ROLLED BACK — prod is
   unchanged".** Fixed in this branch; the incident and the fix are described at the end of this file.

## Identity rulings

- **No seat is disputed.** Both sources return exactly 20 Senate and 40 House rows, the same person
  in every district, and no duplicate district in either.
- 🔴 **NO NAME COLLIDES, AND THAT WAS MEASURED WITH A POSITIVE CONTROL.** Zero exact `full_name`
  matches and zero exact `(first_name, last_name)` matches in production — the latter being how the
  duplicate-name guard actually keys. Both queries first returned empty, and **an empty result is a
  broken detector until a control passes**: known production rows were planted into each query and
  matched before the result was trusted. So the two-pass `allow_duplicate_name` carve-out that
  Idaho's `CC_0310` needed is **not** opened here.
- ⚠ **THE NEAR MISSES ARE REAL AND ARE ALL DIFFERENT PEOPLE.** 16 production rows share a surname and
  a first initial with an Alaska legislator: prod's **Janelle** Bynum is Oregon's congresswoman,
  **Adam** Gray is California's, **Dusty** Johnson is South Dakota's, **Richard** Myers is not
  Robert. This is the "Mike Lee failure" shape, and `CC_0317`'s pre-flight re-asserts the absence at
  run time so a row appearing later stops the migration instead of seating the wrong person.
- 🟢 **THE FOUR APPOINTMENTS FORM A CHAIN AND IT CHECKS OUT GEOGRAPHICALLY.** Tilton (House 26) and
  Rauscher (House 29) were appointed to the Senate on 2025-11-26; St. Clair and Nelson were then
  appointed to the House seats they vacated, on 2025-12-24. Ballotpedia names St. Clair's predecessor
  as Tilton and Nelson's as Rauscher — and the pairing agrees: Senate M is House 25+26 (Tilton's old
  seat), Senate O is House 29+30 (Rauscher's). Four facts that would all have to be wrong together.
- **`how_started` was read, not inferred from the date.** `appointed` (4) — each carries an explicit
  "Appointed <date>" infobox line. `unknown` (1) — **Neal Foster** arrived 2009-11-16, mid-term and
  on no election day, and his infobox carries **no** appointment line, so the mechanism is simply not
  published. Ballotpedia demonstrably records appointments, so that absence is evidence. `elected`
  (55) — everyone else. **Not guessed.**
- **Two senators have a year and no day.** Lyman Hoffman (S) assumed office "in 2003" and Donny Olson
  (T) "in 2001" — that is all either source publishes. Both are `start_precision => 'year'` at
  `YYYY-01-01`. **No date is invented.**
- **Party is not written on the person.** `politicians.party` stays NULL for all 60; party lives on
  `races.primary_party`. ⚠ Alaska makes this especially worth holding to: its general election is
  ranked-choice after an open top-four primary (Ballot Measure 2, 2020), **both chambers are run by
  bipartisan coalitions**, and the two sources disagree on the labels anyway — the Legislature prints
  "Not Affiliated" and "Independent" where Ballotpedia prints "Nonpartisan" and "Undeclared", which
  are two **distinct** registration categories in Alaska, not synonyms. Nothing here encodes a
  majority or a caucus: a coalition is re-formed each legislature and would go stale.

## Portraits

All 60 mirrored into `politician_photos/ak-legislature-2026/` as the exact bytes `akleg.gov` served
— nothing resized or re-encoded. Four were fetched back from the public CDN and were **MD5-identical
to source**. Licence `press_use`: the Legislature's own official photographs of its own members.

🔴 **ALL 60 WERE LOOKED AT**, on two contact sheets, before anything was written. Nothing in this repo
asks whether a headshot contains a **face** — a seal, a logo, a map, a banner or a blank passes every
automated check. All 60 are genuine, distinct, individual headshots, and all 60 files are distinct by
MD5. Several are candid or outdoor rather than the studio set (Carolyn Hall in a knitted hat, Ted
Eischeid in a cap, Garret Nelson outdoors, Robyn Niayuq Frier in a fur-ruffed parka) — all real
portraits of the right person.

**Measured, not eyeballed: 58 of 60 are exactly 450x600.** The two that are not:
- **George Rauscher (Senate O) — 400x600.** Narrower, full detail, nothing to do.
- 🔴 **Bryce Edgmon (House 37) — 150x200, a ninth of the area, and he is the Speaker of the House.**
  **That is all Alaska publishes for him**, and it was tested rather than assumed: the `/450x600/`
  path, the bare path and the `/rounded/` path all serve the **same 150x200 image** (the directory
  name is a label, not a transform), and the only other picture of him on the site is a 222x159
  **landscape** leadership banner, which is not a headshot shape. Mirrored at native size.
  **Not upscaled** — upscaling invents detail. **Don't re-hunt it.**

## Roster

| Chamber | District | Name | Also published as | Party (akleg) | Home city | term_start | precision | Code | Pairs with |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Senate | A | Bert Stedman |  | Republican | Sitka | 2023-01-17 | day | SMN | House 1 + 2 |
| Senate | B | Jesse Kiehl |  | Democrat | Juneau | 2023-01-17 | day | KIE | House 3 + 4 |
| Senate | C | Gary Stevens |  | Republican | Kodiak | 2023-01-17 | day | STG | House 5 + 6 |
| Senate | D | Jesse Bjorkman |  | Republican | Nikiski | 2023-01-17 | day | BJK | House 7 + 8 |
| Senate | E | Cathy Giessel | Catherine Giessel | Republican | Anchorage | 2023-01-17 | day | GIE | House 9 + 10 |
| Senate | F | James Kaufman |  | Republican | Anchorage | 2023-01-17 | day | KAU | House 11 + 12 |
| Senate | G | Elvi Gray-Jackson |  | Democrat | Anchorage | 2023-01-17 | day | GRA | House 13 + 14 |
| Senate | H | Matt Claman |  | Democrat | Anchorage | 2023-01-17 | day | CLA | House 15 + 16 |
| Senate | I | Loki Tobin |  | Democrat | Anchorage | 2023-01-17 | day | TOB | House 17 + 18 |
| Senate | J | Forrest Dunbar |  | Democrat | Anchorage | 2023-01-17 | day | DNB | House 19 + 20 |
| Senate | K | Bill Wielechowski |  | Democrat | Anchorage | 2023-01-17 | day | WIE | House 21 + 22 |
| Senate | L | Kelly Merrick |  | Republican | Eagle River | 2023-01-17 | day | MRR | House 23 + 24 |
| Senate | M | Cathy Tilton |  | Republican | Wasilla | 2025-11-29 | day | TTN | House 25 + 26 |
| Senate | N | Robert Yundt |  | Republican | Wasilla | 2025-01-21 | day | YUN | House 27 + 28 |
| Senate | O | George Rauscher |  | Republican | Sutton | 2025-11-29 | day | RAC | House 29 + 30 |
| Senate | P | Scott Kawasaki |  | Democrat | Fairbanks | 2023-01-17 | day | KAW | House 31 + 32 |
| Senate | Q | Robert Myers | Robert Myers Jr. | Republican | North Pole | 2023-01-17 | day | MYE | House 33 + 34 |
| Senate | R | Mike Cronk |  | Republican | Tok/Northway | 2025-01-21 | day | CRN | House 35 + 36 |
| Senate | S | Lyman Hoffman |  | Democrat | Bethel | 2003-01-01 | year | HOF | House 37 + 38 |
| Senate | T | Donny Olson | Donald Olson | Democrat | Golovin | 2001-01-01 | year | OLS | House 39 + 40 |
| House | 1 | Jeremy Bynum |  | Republican | Ketchikan | 2025-01-21 | day | BYN | Senate A |
| House | 2 | Rebecca Himschoot |  | Not Affiliated | Sitka | 2023-01-17 | day | HMS | Senate A |
| House | 3 | Andi Story |  | Democrat | Juneau | 2023-01-17 | day | STO | Senate B |
| House | 4 | Sara Hannan |  | Democrat | Juneau | 2023-01-17 | day | HNN | Senate B |
| House | 5 | Louise Stutes |  | Republican | Kodiak | 2023-01-17 | day | STS | Senate C |
| House | 6 | Sarah Vance |  | Republican | Homer | 2023-01-17 | day | VAN | Senate C |
| House | 7 | Justin Ruffridge |  | Republican | Soldotna | 2023-01-17 | day | RUF | Senate D |
| House | 8 | Bill Elam |  | Republican | Nikiski | 2025-01-21 | day | ELA | Senate D |
| House | 9 | Ky Holland |  | Not Affiliated | Anchorage | 2025-01-21 | day | HLA | Senate E |
| House | 10 | Chuck Kopp | Charles Kopp | Republican | Anchorage | 2025-01-21 | day | KOP | Senate E |
| House | 11 | Julie Coulombe |  | Republican | Anchorage | 2023-01-17 | day | COU | Senate F |
| House | 12 | Calvin Schrage |  | Not Affiliated | Anchorage | 2023-01-17 | day | SCG | Senate F |
| House | 13 | Andy Josephson | Andrew Josephson | Democrat | Anchorage | 2023-01-17 | day | JOS | Senate G |
| House | 14 | Alyse Galvin |  | Not Affiliated | Anchorage | 2023-01-17 | day | GAL | Senate G |
| House | 15 | Mia Costello |  | Republican | Anchorage | 2025-01-21 | day | COS | Senate H |
| House | 16 | Carolyn Hall |  | Democrat | Anchorage | 2025-01-21 | day | HLL | Senate H |
| House | 17 | Zack Fields |  | Democrat | Anchorage | 2023-01-17 | day | FIE | Senate I |
| House | 18 | David Nelson |  | Republican | Anchorage | 2025-01-21 | day | NED | Senate I |
| House | 19 | Genevieve Mina |  | Democrat | Anchorage | 2023-01-17 | day | MNA | Senate J |
| House | 20 | Andrew Gray |  | Democrat | Anchorage | 2023-01-17 | day | GRY | Senate J |
| House | 21 | Donna Mears |  | Democrat | Anchorage | 2023-01-17 | day | MEA | Senate K |
| House | 22 | Ted Eischeid |  | Democrat | Anchorage | 2025-01-21 | day | EIS | Senate K |
| House | 23 | Jamie Allard |  | Republican | Eagle River | 2023-01-17 | day | ALR | Senate L |
| House | 24 | Dan Saddler |  | Republican | Eagle River | 2023-01-17 | day | SAD | Senate L |
| House | 25 | DeLena Johnson |  | Republican | Palmer | 2023-01-17 | day | JHS | Senate M |
| House | 26 | Steve St. Clair |  | Republican | Wasilla | 2025-12-30 | day | STC | Senate M |
| House | 27 | Jubilee Underwood |  | Republican | Wasilla | 2025-01-21 | day | UND | Senate N |
| House | 28 | Elexie Moore |  | Republican | Wasilla | 2025-01-21 | day | MOO | Senate N |
| House | 29 | Garret Nelson |  | Republican | Sutton | 2025-12-30 | day | NEG | Senate O |
| House | 30 | Kevin McCabe |  | Republican | Big Lake | 2023-01-17 | day | MCA | Senate O |
| House | 31 | Maxine Dibert |  | Democrat | Fairbanks | 2023-01-17 | day | DIB | Senate P |
| House | 32 | Will Stapp |  | Republican | Fairbanks | 2023-01-17 | day | SPP | Senate P |
| House | 33 | Mike Prax | Glenn Prax | Republican | North Pole | 2023-01-17 | day | PRA | Senate Q |
| House | 34 | Frank Tomaszewski |  | Republican | Fairbanks | 2023-01-17 | day | TMZ | Senate Q |
| House | 35 | Ashley Carrick |  | Democrat | Fairbanks | 2023-01-17 | day | CAI | Senate R |
| House | 36 | Rebecca Schwanke | Becky Schwanke | Republican | Glennallen | 2025-01-21 | day | SCW | Senate R |
| House | 37 | Bryce Edgmon |  | Independent | Dillingham | 2015-01-20 | day | EDG | Senate S |
| House | 38 | Nellie Unangiq Jimmie | Nellie Jimmie | Democrat | Toksook Bay | 2025-01-21 | day | JIM | Senate S |
| House | 39 | Neal Foster |  | Democrat | Nome | 2009-11-16 | day | FON | Senate T |
| House | 40 | Robyn Niayuq Frier | Robyn Frier | Democrat | Utqiagvik | 2025-01-21 | day | FRB | Senate T |

Leadership at the time of reading — recorded here only, never in the database, because a coalition
is re-formed each legislature: Senate President **Gary Stevens** (C), Senate Majority Leader
**Cathy Giessel** (E), Senate Minority Leader **Mike Cronk** (R); Speaker **Bryce Edgmon** (37),
House Majority Leader **Chuck Kopp** (10), House Minority Leader **DeLena Johnson** (25).

## What this wave did NOT touch

- **No Alaska statewide executives.** Governor, Lieutenant Governor, the two U.S. Senators and the
  at-large U.S. Representative were already in production and are untouched.
- **No Anchorage.** `CC_0303` seeded the Municipality (1 government, 3 chambers, 7 districts, 20
  offices) and nothing here overlaps it.
- **No races, no candidates, no stances.** Stance research was explicitly deferred.
- **The occupancy baseline did not move.** Measured before and after: `293 / 55 / 238`
  (total / flagged / **unflagged**). All 60 new seats are filled, so none entered
  `essentials.offices_missing_terms`.

## ▶ Open items

🔴 **2027-01-19 — RE-SEAT AFTER THE 2026 ELECTION.** AS 24.05.080: terms begin the third Tuesday in
January. On the ballot 2026-11-03 were **all 40 House seats and 10 of the 20 Senate seats**. This is
a `seat_officeholder` pass against the certified results — **not** a re-run of these migrations,
whose pre-flights refuse a non-greenfield chamber by design.
- Read the certified results from the Alaska Division of Elections, not an aggregator, and 🔴 **a
  certified result is not a fact about who holds the seat** — seat from a source about the
  *officeholder*. Alaska is ranked-choice, so a winner is not final until the RCV tabulation is.
- ⚠ **Bryce Edgmon (House 37) is running for Senate S**, which Lyman Hoffman is not contesting. If
  he wins, House 37 and Senate S both change hands and his `office_terms` row moves chamber.
- The 10 Senate seats **not** on the ballot keep their current terms; do not close them.

▶ **Re-pull the portraits at the same time.** The 2027 member set will differ and `akleg.gov` keys
portraits on the member code, so a new member's code serves a new photograph at the same URL shape.

▶ **Nothing is owed before 2026-11-03.** This roster is correct as it stands.

---

## 🔴 Incident: `dry-run-migration.mjs` committed to production while reporting a rollback

**What happened.** `CC_0317`'s pre-flight depends on `CC_0316` having run, so the two were
concatenated into one file to rehearse them together. The run printed
`DRY RUN OK … ROLLED BACK — prod is unchanged`. **Both migrations had in fact been committed.**

**Why.** `stripOwnTransaction` removes only the **first** `BEGIN;` and the **first** `COMMIT;` —
its regexes carry no `g` flag. In a two-migration file the second `COMMIT;` survived in the middle
of the script and committed everything before it. The runner's own `ROLLBACK` then found no
transaction, and the summary line was printed unconditionally.

🔴 **THE ONLY TELL WAS TWO EASILY-MISSED NOTICES** — `there is already a transaction in progress`
and `there is no transaction in progress`. Neither is an error, and the summary said the opposite
of the truth. The module's own doc comment already promised the right behaviour: *"silently
removing one would be worse than failing loudly."* It did neither — it left the second pair in
place.

**What was committed.** Exactly the two migrations as written, with every pre-flight and post-verify
gate passing against real data. The data is correct and is what was going to be applied; it was
applied earlier and less deliberately than intended. `CC_0318` was then applied on purpose with
`apply-migration-file.mjs`.

**The fix, in this branch.** `assertSingleTransaction` in `scripts/lib/migration-file-guards.mjs`,
called by **both** `dry-run-migration.mjs` and `apply-migration-file.mjs` before the database is
touched. A file carrying more than one `BEGIN;`/`COMMIT;` is refused by name. `stripOwnTransaction`
is deliberately **left alone** — a `/g` flag would silently merge two migrations into one
transaction instead of refusing, and a test pins its current behaviour as a control.

⚠ **ONE EXISTING MIGRATION ALREADY HAS THIS SHAPE, AND THE TEST IS HOW IT WAS FOUND.**
`919_palmdale_complete.sql` opens a transaction at line 16, commits at 98, opens again at 108 and
commits at 115. It is already applied, so nothing is rewritten — but **dry-running that file would
have committed its first part for real**. It is named in the test rather than excluded, so the
number stays visible.

▶ **Rehearsing two dependent migrations together is still a reasonable thing to want.** Do it by
applying the first for real and dry-running the second, or by running them as separate files inside
a transaction you own — never by concatenating them into one file for this tool.
