# MS — Knight slice 16 (Biloxi, Harrison County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

Lease `state:ms`, claimed 2026-09-28. Worktree `C:\ev-accounts-ms`, branch `knight/ms-slice16`.

**Mississippi is the last state in the programme owing legislative geography, and it is the only
one whose map has been redrawn, litigated, re-approved and then vacated inside one decade.**

| stage | status |
| --- | --- |
| 1 geography | ✅ **APPLIED 2026-09-28 — MISSISSIPPI HAS LEGISLATIVE GEOGRAPHY FOR THE FIRST TIME. 174 boundaries + 174 districts (52 Senate + 122 House), 0 errors.** No migration. The programme now owes legislative geography nowhere |
| 2 legislature | ✅ **APPLIED 2026-09-28 — 174 offices, 174 seated, 0 vacant** (`CC_0169`/`CC_0170`). 7 terms dated at `year`, 167 honestly `unknown` |
| 3 city waves | ✅ **APPLIED 2026-09-28 — BILOXI IS SEATED. 7 ward polygons on `X0073`, 8 offices, 8 seated, 0 vacant** (`CC_0171`/`CC_0172`). City Hall now scores 4 of 4 bar the county |
| 4 county waves | ✅ **APPLIED 2026-09-28 — HARRISON COUNTY IS SEATED. 5 supervisor-district polygons on `X0074`, 27 offices, 27 seated, 0 vacant** (`CC_0173`/`CC_0174`). **Biloxi City Hall now scores 4 of 4** |
| **5 assets** | ▶ **OPEN — the last stage of the last slice. No `biloxi` banner key; no headshots for the 35 city and county officials** |

---

## Baseline, measured 2026-09-28 against production, in the same session as this record

Nothing has been written. These are the numbers any later wave must move by an exact delta.

| scope | value |
| --- | --- |
| `politicians` | 89,485 |
| `offices` | 10,030 |
| `office_terms` | 9,966 |
| `districts` | 10,532 |
| `geofence_boundaries` | 72,712 |
| `chambers` | 1,339 |
| `governments` | 612 |
| `offices_missing_terms` | 422 total · 184 flagged `is_vacant` · **238 unflagged** |

**Mississippi holds exactly ONE government row** — `State of Mississippi` (`geo_id` 28), 5 chambers,
5 offices: Governor (Tate Reeves), Lieutenant Governor (Delbert Hosemann), Attorney General
(Lynn Fitch), Secretary of State (Michael Watson), Treasurer (David McRae). All 5 seated, all 5
terms `unknown` precision. Counting every office whose `representing_state` is `MS`, production
holds **12**: those 5, plus 4 U.S. Representatives and 2 U.S. Senators, plus one
`Candidate for U.S. Senate — Mississippi` row. ⚠ **That candidate row must never be counted as a
third senator** — the Ohio trap, live again here.

**Geofence polygons for state `28`:**

| mtfcc | layer | count |
| --- | --- | --- |
| G4020 | county | 82 |
| G4110 | place (incorporated municipalities) | 300 |
| G4210 | CDP (statistical, deliberately excluded) | 127 |
| G5200 | congressional district | 4 |
| G6350 | ZCTA | 427 |
| **G5210** | **state senate** | **0** |
| **G5220** | **state house** | **0** |

So **stage 1 owes `sldu` + `sldl` ONLY** — the OH / PA / SC / MI / ND / KY / KS / SD shape, and the
last time this programme will ever write that sentence.

**The slice's own jurisdictions already have geometry:**

- Biloxi city — `(G4110, 2806220)`, 67.7068 sq mi, `census_tiger_2024`. **No `districts` row, no
  government, no chamber, no office.**
- Harrison County — `(G4020, 28047)`, 984.6887 sq mi, `ocd-division/country:us/state:ms/county:harrison`.
  A `districts` row exists and carries **0 offices**.

⚠ Both TIGER polygons carry water. Harrison County's land area is roughly 574 sq mi against the
984.69 above, and Biloxi's polygon includes the Back Bay and part of the Mississippi Sound.
🔴 **Any closure or coverage gate written for this slice must be decomposed, not thresholded** —
the Detroit, Wayne, Grand Forks and St. Louis rule, and the coast makes it sharper here than in
any of them.

**The four-answer probe scores 0 of 4 today.** Biloxi City Hall resolves to Harrison County,
Biloxi city, Congressional District 4 and ZCTA 39530 — and **none of those four polygons carries a
single office**. The only officials any Biloxi address can return are federal and statewide.

🔴 **`geo_id` collides with counties, for the seventh state running.** Mississippi's 82 counties
run `28001`–`28163` odd; Senate districts will be `28001`–`28052` and House districts
`28001`–`28122`. **Harrison County is `28047` and Senate District 47 will also be `28047`.** Every
join must pair `geo_id` with `mtfcc`. ⚠ And Ohio's slice already recorded that `39153` returns
Summit County **and a Mississippi ZCTA** — MS holds 427 `G6350` rows, so the ZCTA layer is a third
party to every unkeyed lookup here.

---

## 🔴🔴 MS-1 IS BLOCKED, AND THE BLOCKER IS NOT A MISSING MEASUREMENT

Everything below is measured or read from a primary document. The decision at the end is the
operator's, because it is a question about which map is *operative*, not about which map is *in the
file*.

### What TIGER contains

`backend/scripts/measure-ms-tiger-legislative.mjs`, run 2026-09-28 against TIGER 2022, 2023, 2024
and 2025 for FIPS 28. A bogus-FIPS positive control fires first; every layer is counted twice, by
the `.dbf` header's own record count and by the rows the shapefile reader yields, and the two agree
in all eight files.

|  | sldl | sldu |
| --- | --- | --- |
| polygons, every vintage | **122** | **52** |
| codes | `001`–`122`, contiguous | `001`–`052`, contiguous |
| lettered codes · `ZZZ` rows | 0 · 0 | 0 · 0 |
| MTFCC | G5220 | G5210 |
| LSY | 2022 (×2), 2024 (×2) | 2022 (×2), 2024 (×2) |
| distinct file hashes | **4** | **4** |

🔴 **NOTHING INSIDE THE FILE DATES THE PLAN.** A count check, a code-set check and an `LSY` check
all pass on every vintage. This is the Kansas, Kentucky and South Dakota finding for the fourth
time.
⚠⚠ **CORRECTION, 2026-09-28, MADE BEFORE ANYTHING WAS BUILT ON IT: § 254 SETS A CEILING, NOT A FIXED SIZE, AND AN EARLIER VERSION OF THIS PAGE SAID OTHERWISE.** Read from the Secretary of State's own published constitution rather than remembered: *“The Senate shall consist of **not more than** fifty-two (52) Senators, and the House of Representatives shall consist of **not more than** one hundred twenty-two (122) Representatives, **the number of members of each house to be determined by the Legislature**.”* So 122/52 is **not** a constitutional constant, and Mississippi is **not** Pennsylvania's or South Carolina's case, where the number really is fixed. ▶ **The practical conclusion survives and the reason changes**: every apportionment since 1982 has used the maxima, so 122/52 fits the 2010 plan, the 2022 plan and the 2025 remedial plan alike, and a count still cannot date the map — by practice, not by law. ▶ **And the over-claim was hiding a consequence**: a future Mississippi plan may lawfully seat **fewer**, so the loader's equality assertion could one day fail on a perfectly valid map. That is the South Dakota shape (a range), not the Pennsylvania one. 🟢 § 254 also provides that *“Each apportionment shall be effective for the next regularly scheduled elections of members of the Legislature”*, which is the state-law half of why the map question turns on **November 2027**.


⚠ **All four hashes differ, and that is not a remap.** `backend/scripts/diff-ms-tiger-vintages.mjs`
located every one of Mississippi's 878 census tract internal points under each vintage:
**0 of 878 tracts change district, in either chamber, across every adjacent pair.** The differing
bytes are shoreline and edge re-digitisation. Controls: all 696 district internal points resolve to
their own district, and a deliberately mis-labelled map moves 878 of 878.

▶ **So TIGER 2022 through 2025 carry ONE Mississippi plan. No TIGER vintage published to date
carries the remedial plan** — the Michigan finding about Crane A1, in a state where the remedial
map has already been used in a real election.

### Which plan that is — proved against Mississippi's own definition of a plan

🟢 **A BLOCK EQUIVALENCY FILE *IS* THE PLAN.** MARIS — the Mississippi Automated Resource
Information System, the redistricting publisher of the Legislature's own PEER Committee — publishes
each plan as a census-block-to-district assignment. It carries no projection, no digitisation and
no rounding, so a re-export cannot defeat a comparison against it.

⚠ **THE GEOMETRIC COMPARISON WAS TRIED FIRST AND COULD NOT SEPARATE ANYTHING.** MARIS's House plan
as adopted by the Legislature on 2025-02-04 and as approved by the court on 2025-05-07 have `.shp`
files of **the same byte length (6,865,892) and different sha256**: the second is a re-export that
rounds every coordinate, and an `AREA` attribute goes from `464.045624` to `464.05`. A polygon
equality test called all 122 districts different, which is exactly as useless as calling them all
the same. 🔴 **A metric that does not separate is a ranking, not a gate** — SC-5a and MI-1 again, in
a new disguise. ⚠ **And two files of identical byte length are not the same file**; Sedgwick
County's soft-404 rule holds in this direction too.

`backend/scripts/verify-ms-tiger-vintage.mjs`, run 2026-09-28, compares all **112,241** Mississippi
2020 census blocks: the district MARIS's remedial block equivalency assigns, against the district
TIGER 2024 puts the block's internal point inside. Three controls, each watched failing first — all
174 district internal points resolve to themselves, a deliberately mis-labelled map disagrees on
1,158 of 1,158 probed blocks, and **0 of 112,241 blocks resolved to no district.**

| chamber | blocks agreeing | blocks disagreeing | population disagreeing |
| --- | --- | --- | --- |
| Senate | 104,432 (93.043%) | 7,809 (6.957%) | **204,910 — 6.920% of the state** |
| House | 110,980 (98.877%) | 1,261 (1.123%) | **26,099 — 0.881% of the state** |

**The districts where the disagreement exceeds 1,000 people:**

- **Senate 1, 2, 10, 11, 19** (the DeSoto County area) and **Senate 34, 41, 42, 44, 45** (the
  Hattiesburg area).
- **House 16, 22, 36, 39, 41** (northeast Mississippi).

Every other disagreement is a single block carrying **zero population** — a boundary digitisation
artefact, which is precisely the distinction the population column exists to draw.

🟢🟢 **THE COURT'S OWN OPINION NAMES THE SAME DISTRICTS, AND IT NAMES THEM FOR A DIFFERENT
PURPOSE.** The three-judge court's order of 2025-04-15 describes "Senate districts in the DeSoto
County and Hattiesburg areas and a House district in northeastern Mississippi", and says of the
benchmark map that "Four nearby Senate districts--SD 1, 2, 10, and 19--had at" issue beside SD 11,
and that "The 2022 House Plan had two opportunity districts for black voters, HD 16 … and HD 36",
with "HD 27 and HD 22" adjacent. MARIS independently publishes a Senate regional map for **DeSoto**
and one for **Hattiesburg**, and a House regional map for **Columbus**. ▶ **A block sweep run for
one purpose and a judicial opinion written for another agree district for district.** Neither was
derived from the other.

▶ **CONCLUSION, MEASURED: TIGER carries Mississippi's 2022 plan. It does not carry the 2025
remedial plan, in either chamber.**

### The three maps, and why the choice is live

- **Map A — the 2022 plan.** Adopted after the 2020 census. Every member sitting today who was
  elected at the November 2023 general election was elected under it, for a four-year term. **This
  is what TIGER contains.**
- **Map B — the 2025 legislative remedial plans.** House JR 1 (the "House Remedy Plan", MARIS file
  dated 2025-02-04) and Senate JR 202 (MARIS file dated 2025-02-25); both passed 2025-03-07. This
  is the plan the block sweep above measured against.
- **Map C — Map B as modified by the court on 2025-05-07.** The three-judge court approved the
  House plan unchanged on 2025-04-15 — *"We accept the Legislature's new map for the House
  districts"* — but rejected the Legislature's Senate District 1 and adopted the State Board of
  Election Commissioners' plan instead, which in the court's own words *"affects four districts —
  1, 2, 11, and 19"*. **This is the map the special elections were run under.** The court set the
  schedule in the same order: special primary 2025-08-05, runoff 2025-09-02, **special general
  2025-11-04.**

So for the **House**, B and C are the same map, and the only question is A against it.
For the **Senate**, all three differ, and B and C differ on exactly the four seats whose senators
were elected in November 2025. ⚠ **They do not merely move boundaries — they renumber.** The
April 15 order records that the Legislature's plan *"renames SD 11 as SD 1"*, while under the SBEC
plan the two majority-minority districts are *"SBEC SD 2 and SD 11"*. **The same voter is told a
different district number depending on which of B and C is loaded.** A wrong choice here is not a
boundary error; it sends a voter to the wrong senator by name.

### 🔴🔴 And then the judgment was vacated

Read from the primary document, not from a summary. **U.S. Supreme Court Order List, Monday,
May 18, 2026, No. 25-234, *Bd. of Election Comm'rs, et al. v. NAACP, et al.*:**

> The judgment is vacated, and the case is remanded to the United States District Court for the
> Southern District of Mississippi for further consideration in light of *Louisiana v. Callais*,
> 608 U. S. ___ (2026).

Justice Jackson dissented. The case is back before the three-judge court: briefs on next steps were
filed 2026-07-29, a motion for a temporary restraining order on 2026-08-11, oppositions 2026-08-17
and a reply 2026-08-18.

🔴🔴 **AND THEN THE DOCKET WAS READ, AND IT ANSWERED THE QUESTION THE TRACKERS COULD NOT.**

The first version of this record said no order on remand had been found on two independent
trackers, and warned that this was "not found", not "does not exist". **It did exist.** Read on
2026-09-28 from the court's own docket via CourtListener RECAP (docket id 66672561, PACER
`gov.uscourts.mssd.117094`), reached in Playwright because the page refuses a bare fetch and the
API refuses an unauthenticated docket-entries call.

⚠ **AND THE FIRST SEARCH OF THAT DOCKET RETURNED ZERO, FROM A WORKING SERVICE.** A
`docket_number=` query against the CourtListener search API answered HTTP 200 with `count: 0`
while the case was plainly there; the parameter was simply not the one that field search uses. A
second detector then reported **0 docket entries on a page carrying 44,177 characters of text**,
because the CSS class guessed at does not exist. 🔴 **TWO CLEAN ZEROES IN A ROW, BOTH FROM MY OWN
DETECTOR AND NEITHER FROM THE WORLD** — the rule that a detector reporting "nothing found" needs a
positive control, paid for twice inside one lookup. The control that broke the deadlock was a
query known to have to return rows.

**Document 318, filed 2026-09-11 — `MEMORANDUM OPINION AND ORDER DENYING PLAINTIFFS' MOTION [308]
FOR A TEMPORARY RESTRAINING ORDER`**, before Southwick, Ozerden and Jordan, per curiam. The facts
it records, and its holding, in its own words:

- **The Secretary of State has already reverted the State's own election system to the 2022 lines.**
  *"on July 24, 2026, Mississippi's Secretary of State, Michael Watson, ordered Circuit Clerks
  across Mississippi to update the Statewide Election Management System (SEMS) to revert the
  legislative district lines back to the 2022 lines in light of the Supreme Court's vacatur."*
- Plaintiffs moved to stop him and to order the 2025 lines restored. **The motion was DENIED.**
- 🔴🔴 **The 2025 plans are held not to be in force.** Both Joint Resolutions took effect only
  *"from and after its approval by the United States District Court"*, so — *"To treat our decision
  in Mississippi NAACP as though it never occurred, J.R. 1 and J.R. 202 must be treated as though
  never approved. **Thus, they are not operative.**"* And: *"no remnant of the relief we ordered in
  Mississippi NAACP carries the force of law at this juncture."*
- 🟢 **The people do not move.** Footnote 3: *"Defendants have informed the Court that the
  Legislature's current composition will remain unchanged until the 2027 election. Thus, this Order
  has no impact on those currently holding office."*
- **Nothing is imminent.** *"no regular legislative election will occur until 2027"*, and *"the 2026
  general election will not include any state legislative races in the areas changed by the 2025
  lines."*

Nothing on the docket supersedes it. The newest entries are procedural: plaintiffs' motion for a
scheduling order (Doc 319, 2026-09-18) aimed at *"a remedy in time for the state legislative
elections in November 2027"*, defendants' opposition and a motion to stay (Docs 321–324,
2026-09-25), a Republican Executive Committee joinder (Doc 325, 2026-09-25), and a text-only order
of 2026-09-21 setting a reply deadline of 2026-09-28. ⚠ **Plaintiffs' own motion argues about
"vote dilution caused by the 2022 lines"** — both sides now treat the 2022 lines as the ones in
force.

### ▶ THEREFORE MS-1 LOADS PLAIN TIGER, AND THE SLICE IS UNBLOCKED

**Mississippi's operative legislative district lines are the 2022 lines, and that is exactly what
every TIGER vintage carries.** The block sweep above is unchanged and still correct — it is the
measurement that proves TIGER is the 2022 plan, which is now the reason to *use* TIGER rather than
the reason to avoid it. Stage 1 is the ordinary `sldu` + `sldl` load, the OH/PA/SC/MI/ND/KY/KS/SD
shape.

🔴🔴 **AND THE PROGRAMME'S OWN RULE BREAKS HERE — WRITE THIS DOWN.** Michigan's rule is *the
correct map is the one the SITTING MEMBER was elected under*. In Mississippi that rule gives the
**wrong answer**: the members of about fifteen districts were elected on 2025-11-04 under lines
that a federal court has since held *"not operative"*, while the State's own address-to-district
system answers on the 2022 lines and the Legislature's composition is frozen until 2027. ▶ **A
MAP AND A MEMBER CAN COME APART. The map is a fact about the LINES and the member is a fact about
the SEAT, and a vacatur can move one without moving the other.** The right question is not "what
was the member elected under" but **"what does the State answer when it is asked which district an
address is in"** — and here that is SEMS, reverted 2026-07-24.

⚠ **STAGE 2 INHERITS A REAL ODDITY AND MUST NOT SMOOTH IT OVER.** In the DeSoto, Hattiesburg and
northeast-Mississippi areas, the person now holding district *N* may have been elected by the
voters of a differently-shaped district *N*. That is the State's position, not a defect in our
data, and it should be recorded on those rows rather than quietly normalised.

🔴 **DIARISE TWO THINGS.** The **November 2027** regular legislative elections, which every
filing on the docket is aimed at; and Mississippi's **post-Callais redistricting**, whose public
hearings MARIS schedules for **18 August – 1 October 2026** and which is likely to produce a new
plan before then. MARIS already files its 2025 work under **"Court Work (2025), Pre-Callais"**.
This is the MI-1 Crane A1 shape: a load that is correct now and has a foreseeable expiry.

⚠ **AND THE CASE IS NOT OVER.** The TRO was denied on imminence and likelihood of success, not on
a final ruling; the Section 2 merits are being re-litigated under *Callais* with a motion to stay
pending. **A later order could restore the 2025 lines or impose new ones.** Re-read the docket
before the 2027 cycle.

### 🟢 The slice's own city is not affected

`verify-ms-tiger-vintage.mjs --county 28047`, same run:

> Harrison County: 5,390 blocks, population 208,621.
> Senate — 2 blocks disagree, **disagreeing population 0**.
> House — 2 blocks disagree, **disagreeing population 0**.

**Maps A, B and C give Harrison County the same answer.** All four disagreeing blocks carry
POP20 = 0 and are boundary artefacts. Under TIGER 2024:

| probe | Senate | House |
| --- | --- | --- |
| Biloxi City Hall | **28050** (SD 50) | **28115** (HD 115) |
| Biloxi, west end | 28050 | **28117** (HD 117) |
| Gulfport City Hall | 28049 | 28120 |

▶ So the map question **does not block Biloxi or Harrison County**. It blocks the correctness of a
statewide `sldu`/`sldl` load for about **205,000 people in the Senate** and **26,000 in the House**,
none of them in this slice. ⚠ **That is a reason to decide, not a reason to proceed** — a stage-1
load writes the whole state, and knowingly writing a superseded map for 205,000 voters is a debt,
not a shortcut.

---

## ✅ MS-1 APPLIED 2026-09-28 — 174 boundaries + 174 districts, 0 errors

No migration slot: geography loads run through `scripts/load-state-tiger-boundaries.ts`, which
gained `MS: new Set(['sldu','sldl'])` and a pre-flight block. Source TIGER 2024 FIPS 28.

**Measured from outside, against a baseline taken in the same session as the write:**

| scope | before | after | expected |
| --- | --- | --- | --- |
| `districts` | 10,532 | **10,706** | +174 exact |
| `geofence_boundaries` | 72,712 | **72,886** | +174 exact |
| MS `G5210` (Senate) | 0 | **52** | 52 |
| MS `G5220` (House) | 0 | **122** | 122 |
| MS `districts` rows | 92 | **266** | +174 exact |
| MS `G4110` / `G4020` | 300 / 82 | **300 / 82** | must NOT move — unmoved |
| `offices_missing_terms` | 422 / 238 | **422 / 238** | must NOT move — unmoved |
| CONTROL: SD `G5210`/`G5220` | 35 / 37 | **35 / 37** | unmoved |

All 174 geometries valid, all SRID 4326, 52 and 122 distinct `ocd_id`s — so the MN `08A` / MD `1A`
collapse did not occur. **Both layers re-run: 0 inserted, 52 and 122 already existed.** The
child→county matview needed no work and said so (`children 13,737 · mapped 13,737 · stale 0`); a
legislative-only load writes no `G4110`, which is why.

### The gate, and what its controls cost

Four controls, **every one watched failing**, on both layers:
`count` → `[MS MTFCC assertion]`; `anchor` → `[MS vintage assertion]`; `weak` →
`[MS anchor discrimination assertion]`; `gap` → `[MS contiguity assertion]`. Clean runs pass at
52 and 122.

🔴🔴 **AND A CONTROL CAUGHT A REAL DEFECT IN MY OWN GATE — THE COUNT WAS THE TELL.** The first
anchor table was written with TIGER's zero-padded codes (`'001'`), but `ocdDistrictSuffix()` strips
the padding, so every comparison ran `'001' !== '1'`. `MS_PREFLIGHT_CONTROL=anchor` perturbs
**exactly one** anchor and reported **13 of 13 anchors disagreeing**. A clean run would have failed
too and looked like a vintage problem. ▶ **A control proves a gate CAN fire; the NUMBER it fires on
is what says whether the gate is right.** After the fix the same control reports **1 of 13** and
**1 of 8**.

⚠ **And the first attempt to run those controls printed nothing at all, four times** — the loader
was refusing on a missing `--fips` before it reached the gate, and my grep showed only silence.
**Four identical silences is a uniform answer, which is a broken detector**, including when the
detector is the control harness. Reading the raw output took one command.

### End to end on live production

| probe | county | place | Senate | House |
| --- | --- | --- | --- | --- |
| **Biloxi City Hall** | Harrison `28047` | Biloxi city `2806220` | **SD 50** | **HD 115** |
| Gulfport City Hall | Harrison `28047` | Gulfport city `2829700` | SD 49 | HD 120 |
| Jackson, Hinds Co. | Hinds `28049` | Jackson city `2836000` | SD 29 | HD 67 |
| CONTROL Mobile, Alabama | Mobile `01097` | — | **none** | **none** |
| CONTROL Aberdeen, South Dakota | Brown `46013` | Aberdeen city | SD 3 (SD's own) | HD 3 |

Every value matches the pre-flight anchors, including the two that were measured rather than
guessed. **Per-district control: 52 of 52 and 122 of 122 interior points resolve to exactly one
district of their own layer, 0 failures** — with a positive control in the same query showing that
asking across BOTH layers returns 2 everywhere, so the query can report a number other than one.

🔴 **THE `geo_id` COLLISION IS VISIBLE IN A SINGLE RESULT SET.** Jackson returns `G4020` **`28049`
= Hinds County** while Gulfport returns `G5210` **`28049` = State Senate District 49**. Same
`geo_id`, different `mtfcc`, two different places. ⚠ The South Dakota control shows the same trap
inside one state: `46003` is Senate District 3 **and** House District 3.

### Gates

`check:occupancy` green · `check:migrations` green (0 added vs `origin/master`) ·
`check:child-county` green · **`check:reachability` nothing regressed** — `BAD_GEOMETRY` 4/4,
`DEAD_GEOGRAPHY` 17/17, `UNREACHABLE` 7/7, all exactly at baseline.

⚠ **Biloxi still scores 0 of 4**, and that is correct: the polygons exist now, but Mississippi
holds no legislative office for them to carry. **Stage 2 owes 174 seats.**

---

## ✅ MS-2 APPLIED 2026-09-28 — THE MISSISSIPPI LEGISLATURE IS SEATED

`CC_0169` (structure) + `CC_0170` (occupancy): **174 offices — 52 Senate + 122 House — 174 seated,
0 vacant, 174 people created, 0 reused.** Both chambers single-member, so the polygon count is the
seat count.

| scope | before | after |
| --- | --- | --- |
| `politicians` | 89,485 | **89,659** (+174 exact) |
| `offices` | 10,030 | **10,204** (+174 exact) |
| `office_terms` | 9,966 | **10,140** (+174 exact) |
| MS chambers | 5 | **7** |
| `offices_missing_terms` | 422 / 238 | **422 / 238** — unmoved |
| CONTROL: SD legislative offices | 105 | 105 — unmoved |
| CONTROL: MS statewide execs | 5 | 5 — unmoved |

✅ **Biloxi City Hall now returns Rep. Zachary Grady (HD-115) and Sen. Scott DeLano (SD-50)**;
Gulfport returns HD-120 and SD-49; **Mobile, Alabama returns nothing**. Per-district control
**52/52 and 122/122 resolve to exactly one holder**, with a positive control in the same query
returning 2 across both chambers. **MI-2's gate 8 asserted directly**: all 174 are visible to the
reps-feed predicate, so the hidden-legislator defect does not occur here.
⚠ **Biloxi now scores 2 of 4.** The council member and the county supervisor are stages 3 and 4.

### 🔴🔴 THE TRAP: THE LIST IS STALE AND THE MEMBER PAGES ARE CURRENT

This is the **inverse** of MN-2 and MI-2, where a fresh-looking list had not noticed a departure.
Only `Last-Modified` could tell:

```
ss_membs.xml  last modified 2025-07-01
hr_membs.xml  last modified 2025-10-14
```

Both **predate the court-ordered special elections of 2025-11-04**, while member pages are current
to 2026-08-18. So the Senate list still declares "Vacancy - District 24" and "Vacancy - District
26" — both filled since — and still carries **John Polk, who retired**.
▶ **A DOCUMENT'S CONTENT CANNOT TELL YOU ITS AGE; ASK THE SERVER.** Justin Pope's page looks
exactly like a sitting member's — six committees, a capitol phone, "2026-present" — because he
**is** one. The list calling his seat vacant is fourteen months old.
⚠ **AND A PAGE EXISTING IS NOT MEMBERSHIP**: `senate/polk.xml` resolves HTTP 200 with full detail.
The site keeps former members in the same namespace as sitting ones.
⚠ **AND STALENESS IS NOT DEPARTURE**: 13 of 170 pages predate the specials and most are sitting
members in districts the remedy never touched — a page is only edited when something changes.

**A turnover therefore needs two independent halves**, both required: the page predates the
specials, **and** Open States names a different *surname* in that district and that person nowhere
in the chamber. Then the successor's own page must itself carry the expected `<DISTRICT>`.
🟢 **The correlation is the evidence** — every seat where Open States names a different surname is
also a seat whose page predates the specials, five of five. **Eight seats moved:**

| seat | list said | actually |
| --- | --- | --- |
| Senate 2 | David Parker | **Theresa Gillespie-Isom** |
| Senate 24 | *VACANT* | **Justin L. Pope** |
| Senate 26 | *VACANT* | **Kamesha B. Mumford** |
| Senate 42 | Robin Robinson | **Don Hartness** |
| Senate 44 | John A. Polk (retired) | **Chris Johnson** |
| Senate 45 | *absent from the list* | **Johnny L. DuPree** |
| House 22 | Jonathan Ray Lancaster | **Justin Crosby** |
| House 26 | Orlando Paden | **Otha Williams** |

🟢 **And the arithmetic closes without slack — 52 and 122 exactly.** That is the real control.

### ⚠ Smaller things this wave paid for

- 🔴 **A LAYOUT IS NOT A SCHEMA.** The Senate list is a **four**-column grid and the House list a
  **five**-column one, in the same document family from the same publisher on the same day. A
  hard-coded four silently dropped every M5 slot — **24 House members** — which read as "the list
  is 96 long" and produced 26 districts that looked unaccounted for. The column indices are now
  discovered from the document.
- 🔴 **THE PRESIDING OFFICERS ARE IN THE HEADER, NOT THE GRID, AND THE CHAMBERS DIFFER.** The
  House's Speaker (**Jason White**, HD-48) and Speaker Pro Tempore (**Manly Barton**, HD-109)
  appear nowhere in the member grid. The Senate's chair is the **Lieutenant Governor**, who is not
  a senator at all. Adding CHAIR+PROTEMP for both chambers would seat a 53rd senator; the
  discriminator is whether the link is a member page in this document family.
- 🔴 **A NICKNAME IS NOT A DIFFERENT PERSON, AND TWELVE OF THEM WOULD HAVE HIDDEN THE EIGHT.**
  Chuck/Charles Younger, Bubba/Joseph Tubb, Hank/Henry Zuber, Zack/Zachary Grady, Bubba/Lester
  Carpenter, Jeff/Jeffrey Guice, Greg/Gregory Holloway, Sam/Samuel Creekmore. **None is a prefix
  rule** — "Bubba" is not short for "Lester" — so only the SURNAME can carry the test. MI-2's rule:
  split the class, do not loosen the detector. A hyphen is a third class again: "Theresa
  Gillespie-Isom" has surname `gillespie-isom` and "Theresa Gillespie Isom" has surname `isom`, so
  a last-token test called the same woman two people and reported her successor NOT FOUND.
- 🔴 **A COMPOUND SURNAME IS DECIDED BY A SECOND PUBLISHER, NOT BY A LIST I WROTE.** "Angela
  Turner Ford", "Hester Jackson McCray", "Theresa Gillespie-Isom" and "Beth Luther Waldo" are
  published in one style and only three are compound — "Luther" is a middle name. Open States
  hyphenates the real ones, so the number of hyphen parts in ITS surname says how many trailing
  tokens the surname takes here. A first version hard-coded the tokens it had seen and got Waldo
  wrong.
- 🔴 **`office_terms` IS A SEAT, NOT A CAREER, AND ONE MEMBER OF THIS WAVE PROVES IT.** Member
  pages carry `<LEG_EXP><STRETCH>`. For the **seven** whose only stretch is "2026-present" that is
  the body's own statement, written at `year` precision. **Chris Johnson's reads "2020-present"
  plus "House 2016-2019"** — but he moved from SD-45 to SD-44 in 2026, so dating SD-44 from his
  career would assert he held it for six years during which **John Polk actually did**. MI-4's
  rule, where two commissioners were dated to the year they changed district number. **A gate
  asserts SD-44 is Chris Johnson with an UNDATED term**, and it was watched failing.
- 🔴 **FOUR NAMESAKE COLLISIONS, ALL DIFFERENT PEOPLE, GUARD LIFTED FOR THOSE ROWS ONLY.**
  Measured on the guard's own key with a positive control (72 active Smiths, 70 Johnsons, 45
  Williamses, so four hits is a measurement). ⚠ **The Chris Johnson case had to be checked rather
  than assumed** — the existing row has no office and `is_incumbent = false`, exactly the shape
  MI-2 reused for four sitting legislators and then found hidden. It is a **Louisiana U.S. House
  District 6 candidate**. ⚠ And "Richard Bennett" matched a row whose `full_name` reads "Rick
  Bennett": the guard keys on first/last, not on full_name — MN-2's Steve/Steven again.
- ⚠ **ONE SOURCE TYPO REPAIRED AND RECORDED**: SD-49's page reads **"Joel R.Carter, Jr."** with no
  space after the initial. Rendering "R.Carter" to a voter is the alternative, so it is repaired
  in the generator with the reason attached, not silently.
- 🔴 **I REPRODUCED ND-2'S external_id RULE AND CAUGHT IT BY READING MY OWN OUTPUT.** The band
  checked in production was `-2766400..-2766227`, but the generator **decremented**, so the ids
  actually ran to `-2766573` — a band never checked. The generator now ascends, and its printed
  range is compared against the gate's own `BETWEEN` clause. **Re-check the band you USE.**
- ⚠ **THE DRY RUN EARNED ITS KEEP.** A `-- map/member split` comment appended with a join put the
  comma **after** the comment, so the comment ate the row separator and the INSERT died at the
  second row. And three separate times the nested shell-to-Python-to-JS quoting ate backslashes in
  a regex — **MI-2's rule, met three times in one session**: do not build regexes through nested
  quoting.

### The gates, all watched failing

Seven controls, each firing on its own target: `c1` missing Senate office · `c2` a COUNTY district
receiving a legislative office (the `28047` collision) · `c3a`/`c3b` Chris Johnson dated ·
`c4a`/`c4b` a missing term · `c5` a person without `is_incumbent`.
🔴 **`c3` and `c4` each needed a second variant because an earlier gate's count fired first and
shadowed the target** — MI-3's finding, twice. ⚠ **And `c4`'s first version aborted on a SYNTAX
ERROR**, because it removed the only row without a trailing comma: **a control that aborts for the
wrong reason proves nothing**, and it looked like a pass because the run did fail.
Tooling: `scripts/ms2-migration-controls.mjs`.

Dry run was a real `BEGIN … ROLLBACK` through `psql` as `ev_api`, and **the rollback was verified
to have reverted** to 89,485 / 10,030 / 9,966 before the real apply.

`check:occupancy` · `check:migrations` · `check:reservations` green; **`check:reachability` nothing
regressed** — 4 / 17 / 7, every bucket at baseline.

### ⚠ Debts carried out of MS-2

- **167 undated arrivals.** No Mississippi member page publishes a service date, and the oath date
  must not be computed. The eight 2025-11-04 turnovers are datable from the chambers' journals by
  a later pass; seven already carry the year.
- 🔴 **THE MAP/MEMBER SPLIT IS NOW IN PRODUCTION AND MUST NOT BE "TIDIED".** In Senate 1, 2, 10,
  11, 19, 34, 41, 42, 44, 45 and House 16, 22, 36, 39, 41 the holder of district N may have been
  elected by a differently-shaped district N. Each term row carries the note.

---

---

## ▶ MS-3 MEASURED 2026-09-28 — NOTHING WRITTEN TO PRODUCTION

Biloxi. Everything below is read from a primary document or measured against a live service.

### 🟢 THE INVENTORY IS EIGHT, AND THE BALLOT IS WHAT PROVES IT

**Biloxi has no home-rule charter.** The Municode publication holds a `Code of Ordinances` and a
`Land Development Ordinance` and **no charter node** — because Mississippi's mayor-council form is
a creature of statute, adopted by ordinance, not a charter the city wrote. So the SD-3 move (read
the charter's own enumerating sentence) has no target here, and the enumeration had to come from
somewhere else.

🟢 **THE ENUMERATION IS THE 2025 BALLOT, AND IT IS EXHAUSTIVE BY CONSTRUCTION.** Every Mississippi
municipal office runs on one four-year cycle, so one general election lists every elected seat the
city has. The city's own report of 2025-06-03 (*"Four plus four equals Biloxi"*):

> *"Voters faced a Biloxi ballot with contested races for Mayor and Wards 1 and 2, while council
> member candidates in Wards 3, 4, 5, 6, and 7 were unopposed."*

**Mayor plus seven wards. Nothing else was on the ballot.** ▶ **8 elected offices.**

✅ **Two independent instruments agree.** The city's own Code of Ordinances, ch. 2 (ADMINISTRATION,
92,594 characters, Supp. 63 Update 1, codified through Ord. 2607 of 2026-07-28) contains **no
occurrence of "shall be elected" at all**. Every body it creates — human resources agency, city
development commission, neighbourhood heritage advisory board, the CAO — is *"appointed by the
mayor, subject to confirmation by the city council"*. **The municipal clerk is among them**
(§ 2-1-4(a)(2)), which closes the Fort Wayne trap: Biloxi does **not** elect a clerk. The
municipal court sits inside the legal department (§ 2-1-4(e)) and its judges are staff, so the
Grand Forks trap — an elected municipal judge named in one sentence on a staff page — does not
apply either. Ch. 2 also states the city's own ward count in passing: *"each of the seven wards of
the city"*.

⚠ **A REFUSAL THAT LOOKED LIKE A BLOCK WAS REAL, AND A CONTROL IS WHAT SAID SO.** `COOR_CH6EL`
(Chapter 6 — ELECTIONS) answers *"The requested content cannot be found or you are not authorized
to view it"* in the publisher's own app. That reads like an access problem. `COOR_CH1GEPR` on the
identical route renders in full, so **the route works and that node genuinely does not resolve** —
the refusal is about the node, not about us. The inventory does not depend on it.

⚠ **The Municode REST API 401s to `fetch` AND to an in-page `fetch`** — the app signs its own
calls. Read the rendered page instead. The TOC link `?nodeId=<NODE>` is the stable address.

### The roster, and the form

**Mayor-Council** (Miss. Code Ann. 1972, § 21-8-21 et seq., cited by the code itself at § 2-1-3).
Mayor elected citywide; **seven council members, one per ward**; four-year terms.

| seat | officeholder | in office since | precision | how |
| --- | --- | --- | --- | --- |
| Mayor | Andrew M. "FoFo" Gilich, Jr. | **2015-05-18** | day | special election |
| Ward 1 | Wayne Gray | 2025-06-30 | day | elected |
| Ward 2 | Anthony L. Marshall | 2025-06-30 | day | elected |
| Ward 3 | Robert "Mike" Nail | 2025-06-30 | day | elected |
| Ward 4 | Jamie Creel | 2025-06-30 | day | elected |
| Ward 5 | Paul A. Tisdale | **2013-07-01** | day | elected |
| Ward 6 | Kenny J. Glavan, Sr. | **2013-07-01** | day | elected |
| Ward 7 | David Shoemaker | **2024-03** | **month** | special election |

🔴🔴 **AN INAUGURATION DATE IS NOT AN OATH DATE, AND BILOXI'S OWN RECORD PROVES IT INSIDE THIS
SLICE.** Gilich's public inauguration was **Wednesday 2015-05-20**. He was not sworn in then. The
city reported on **Monday 2015-05-18**: *"His inauguration is not until Wednesday afternoon, but
Mayor-elect Andrew 'FoFo' Gilich wanted to begin the workweek early, so this morning he became
Mayor Andrew 'FoFo' Gilich"* — the oath administered *"shortly after 8"* by his 93-year-old aunt,
so that he could sign documents and sit at Tuesday's council meeting. ▶ **Taking the advertised
ceremony as the start would have been two days wrong, and nothing in the ceremony announcement
could have revealed it.** This is the programme's oath-date rule meeting its sharpest case yet: the
rule is not merely *do not compute the date from a statute*, it is **do not compute it from an
announced ceremony either**.

▶ **THAT IS WHY WARD 7 IS DATED TO A MONTH AND NOT A DAY.** Shoemaker won the special election of
2024-02-27 to fill Nathan Barrett's unexpired term (Barrett resigned on election as Harrison County
Supervisor, District 5). The city published an **invitation** to his inauguration — *"Tuesday,
March 19, 2024, 12:00 p.m., Biloxi City Hall, 2nd Floor Council Chambers"* — and then published
**nothing afterwards**: a full-text sweep of the city's posts returns nine Shoemaker hits and none
between 2024-03-15 and 2025-03-21, and the council agendas for 19 and 26 March carry no roster and
no oath item. **An invitation is a plan.** Given that this very city's own record shows a plan and
an oath coming apart by two days, the honest write is `2024-03-01` at `start_precision => 'month'`.
🔴 **DO NOT "PROMOTE" IT TO 2024-03-19 WITHOUT THE MINUTES.** The minutes live behind a Laserfiche
portal (`weblink.mccinnovations.com/weblink8/login.aspx?LogName=Biloxi`); reading them is the one
thing that would earn day precision.

🟢 **THE ARITHMETIC CLOSES, AND THAT IS THE REAL CONTROL ON THE DATES.** The mayor's inaugural
address of 2025-06-30 says *"four new council members"*. Against the 2021 inaugural list the change
is **five** seats — which would have made the mayor wrong. It is not: **Shoemaker was already a
sitting member**, seated at the 2024 special, and the 2025 result post confirms it by listing him
among *"Council members ... all unopposed"*. So four genuinely new (Gray, Marshall, Nail, Creel)
and three continuing (Tisdale, Glavan, Shoemaker). **The mayor's own count and the seat histories
agree only if Ward 7 is dated to 2024, not 2025.**

🟢 **AND THE TWO LONG-SERVING MEMBERS ARE DATED TO THE SEAT, NOT TO A CAREER** — MS-2's Chris
Johnson rule, applied in the opposite direction. Tisdale and Glavan were both sworn at the
**2013-07-01** inauguration and appear in the city's record of every ceremony since (2017-06-28,
2021-06-29, 2025-06-30). 🔴 **The 2013 ceremony report does not give wards**, so it alone cannot
date a seat — a member who changed ward would be mis-dated exactly as MS-2's SD-44 would have been.
The 2013 **result** post supplies what the ceremony post lacks: *"Ward 5, Dr. Paul Tisdale; and
Ward 6, Kenny Glavan, who defeated incumbent Edward 'Ed' Gemmill."* **Same ward, continuously.**
Dating them from 2025-06-30 would have erased twelve years of tenure.

⚠ **Names, and why the page is not the last word.** The Ward 6 portrait file is
`Ward-6-Kenny-Glavin-scaled.jpg` while the page text and the election result both read **Glavan**;
the result post gives the fuller **"Kenny J. Glavan Sr."** Ward 3's page heads *"Mike Nail"* and the
result post gives **"Robert 'Mike' Nail"**. ▶ **The filename is not evidence, and the display name
is not the full name.**

⚠ **STALE PROSE UNDER A FRESH EDIT DATE.** The mayor's page was **modified 2025-09-17** — after the
election, after the oath — and still reads *"He is now serving his second full term in office."* He
is serving his third. ▶ **An edit timestamp says the page was touched, not that the sentence was
read.** MS-2's rule was *a document's content cannot tell you its age; ask the server*. This is its
mirror: **the server's age cannot tell you the content is current.** Both halves are now paid for
in this state.
🟢 Dates came from the WordPress REST API (`/wp-json/wp/v2/pages?slug=…`), which publishes
`modified` per page; the HTML carries no `Last-Modified`, no `ETag` and no schema.org date. A bogus
slug returns an empty array, which is the control.

### 🟢 THE WARD GEOMETRY IS THE CITY'S OWN, AND TEN ANCHORS PROVE IT CURRENT

`https://services1.arcgis.com/WJhHbwy2YfOSix5p/arcgis/rest/services/Wards2022/FeatureServer/8`
— found through the AGOL item search for the org behind the city's own GIS gallery
(`experience.arcgis.com/experience/28f7d5965d164ccdb963292f0a98dfb0`, org `WJhHbwy2YfOSix5p`).
**7 polygons, SRID 4326, `lastEditDate` 2026-04-15.**

🔴🔴 **THE SERVICE IS NAMED `Wards2022` AND THE CITY'S OWN MAP SAYS `WARDS LAST REVISED: 12/12/2024`.**
A name cannot date a plan — the MS-1 finding in miniature, and the disagreement is explicit this
time. It was settled by measurement, not by reading the name:

| anchor | expected | got |
| --- | --- | --- |
| the 7 polling places named on the **2024-revised** Ward Map PDF, one per ward | 1…7 | **7 of 7 MATCH** |
| Paul A. Tisdale, 2561 Brighton Circle (Ward 5 page) | 5 | MATCH |
| Kenny Glavan, 827 Eagle Eyrie Drive (Ward 6 page) | 6 | MATCH |
| Margaret Sherry Library, Ward 4's own ward-meeting venue | 4 | MATCH |

**Ten anchors, ten matches, and not one of them derived from the layer.** Controls, both watched: a
point in Mobile, Alabama returns **no ward** (so the query can return empty), and asserting Ward 1
at the Ward 5 anchor reports **MISMATCH** (so the comparison can fail). ▶ **The layer named 2022
carries the plan revised 2024-12-12.**

🔴 **`Id` IS NOT THE WARD NUMBER. `Ward_2020` IS.** The layer carries both, and `Id` repeats —
`Id = 6` appears on Ward 4 **and** Ward 6, `Id = 1` on Ward 1 **and** Ward 3. A join on `Id` would
silently merge two wards. Reading one sample of the rows is what caught it; a count never would
have.

Ward populations, 1…7: 7,101 · 7,469 · 7,417 · 6,742 · 6,855 · 7,100 · 6,890 — **49,574 in all**.

**Biloxi City Hall, 140 Lameuse Street, is in Ward 1**, so the four-answer probe's city answer will
be Wayne Gray.

### What MS-3 still owes

- **`X0073`** for the ward boundaries — `max(mtfcc)` over both `geofence_boundaries` and
  `districts` reads **`X0072`** (Aberdeen, SD-3), measured 2026-09-28 in this session. 🔴 Re-read it
  in the session that writes.
- A `governments` row, two `chambers` (Office of the Mayor · Biloxi City Council), **8 districts**
  (1 citywide bound to `(G4110, 2806220)` + 7 wards on `X0073`), **8 offices**, 8 politicians,
  8 `office_terms`.
- Migration slots: **allocate, never count.** `CC_0169`/`CC_0170` are spent on MS-2.

### ⚠ Access facts measured this session

- 🟢 `biloxi.ms.us` answers Node directly, bare or with a Chrome UA, and **returns a real HTTP 404**
  for a bogus path (74 KB body, title "Not Found") — so the status discriminates and the
  soft-404 trap does not apply here.
- 🔴 **`harrisoncountyms.gov` AND `www.co.harrison.ms.us` ARE BEHIND A CLOUDFLARE CHALLENGE** —
  HTTP **403** with title *"Just a moment..."* to both a bare `fetch` and a Chrome UA, on the real
  path and on a bogus one alike. **MS-4 must use Playwright from the start.**
- ⚠ `biloxi.ms.us/gis` 403s; `biloxi.ms.us/gis-mapping` is the Experience Builder app.

---

## ✅ MS-3 APPLIED 2026-09-28 — BILOXI IS SEATED

`CC_0171` (structure) + `CC_0172` (occupancy), plus `scripts/load-biloxi-ward-boundaries.mjs` for
the geometry: **7 ward polygons on `X0073`, 8 offices, 8 seated, 0 vacant, 8 people created,
0 reused.** Single-member wards, so the polygon count is the seat count.

**Measured from outside, against a baseline taken in the same session as the write:**

| scope | before | after | expected |
| --- | --- | --- | --- |
| `geofence_boundaries` | 72,886 | **72,893** | +7 exact |
| `politicians` | 89,659 | **89,667** | +8 exact |
| `offices` | 10,204 | **10,212** | +8 exact |
| `office_terms` | 10,140 | **10,148** | +8 exact |
| `districts` | 10,706 | **10,714** | +8 exact |
| `chambers` | 1,341 | **1,343** | +2 |
| `governments` | 612 | **613** | +1 |
| `offices_missing_terms` | 422 / 238 | **422 / 238** | must NOT move — unmoved |
| CONTROL: MS legislative offices | 174 | 174 | unmoved |
| CONTROL: SD legislative offices | 105 | 105 | unmoved |
| CONTROL: Aberdeen offices | 9 | 9 | unmoved |
| CONTROL: `X0072` (Aberdeen wards) | 4 | 4 | unmoved |

### ✅ Biloxi City Hall now scores 4 of 4 — and the fourth is still MS-4's

| probe | Mayor | Council | Senate | House |
| --- | --- | --- | --- | --- |
| **Biloxi City Hall** | **Gilich** | **Wayne Gray (Ward 1)** | SD 50 DeLano | HD 115 Grady |
| Tisdale's own address | Gilich | **Paul A. Tisdale (Ward 5)** | SD 49 Carter | HD 117 Felsher |
| Woolmarket City Center | Gilich | **David Shoemaker (Ward 7)** | SD 50 DeLano | HD 116 Eure |
| CONTROL Gulfport City Hall | — | **none** | SD 48 | HD 119 |
| CONTROL Mobile, Alabama | — | — | — | — |

**Per-ward control: 7 of 7 ward interior points resolve to exactly one holder**, with a positive
control in the same query showing that asking across the ward layer AND the place layer returns
**2** everywhere — so the query can report a number other than one. ⚠ The county supervisor is
still missing, and that is correct: Harrison County is MS-4.

### 🔴🔴 THE HOLES ARRIVE AS PARTS, AND ONLY THE WINDING SAYS SO

The city's service returns `f=geojson` that does **not** rewind to RFC 7946. Every one of the
**162** parts across the seven wards carries **exactly one ring**, so the inner-ring channel GeoJSON
uses to express a hole is never used at all. Ward 7's two holes — the **Tchoutacabouffa River** —
arrive as two extra **counter-clockwise** parts nested inside part 0, among 160 clockwise ones.

▶ **Loaded raw, PostGIS would have read them as exteriors.** Ward 7 would overlap itself, come back
invalid, and `ST_MakeValid` would have **filled** them, handing roughly 19,000 m² of river to Ward 7
as addressable territory. 🟢 SD-3's area guard would in fact have *aborted* rather than corrupt —
that guard has now earned its keep twice — but aborting is not loading. The parts are re-assembled
instead, and a part counts as a hole only when the **nesting test and the winding test agree**;
either one alone aborts the run. In production ward 7 stores **29 parts and 31 rings**.

⚠ Census reverse geocoding puts both hole centroids **inside Biloxi city**, so this is the city
clipping its ward around water, not a gap in the city limits.

### 🔴 `Id` IS NOT THE WARD NUMBER

The layer carries `Id` and `Ward_2020`. **`Id` repeats** — `Id = 6` on Wards 4 and 6, `Id = 1` on
Wards 1 and 3, five distinct values for seven wards. A join on `Id` would have merged two pairs of
wards silently. **Reading one sample of the rows caught it; a count never would have.** A control
now asserts the collision still exists, so a future re-publish that repairs `Id` stops the loader
and makes a human re-choose the key rather than inherit a stale one.

### The gates, all watched failing

**Loader: seven controls**, each on its own target — bogus layer · ward-number set · `Id` still
unusable · population identity (49,574) · hole reassembly · the ten published anchors · the
out-of-city probes.
**Migrations: twelve controls**, via `scripts/ms3-migration-controls.mjs` — missing ward polygons ·
a foreign `X0073` row · missing place polygon · one office per ward · an office with no polygon ·
MS-2's 174 offices · seated count · the mayor's oath date · Ward 7's date · the precision split ·
`is_incumbent` · MS-2's 174 seats.

🔴 **FIVE OF THE NINETEEN WERE SHADOWED ON FIRST WRITING, AND THE HARNESS IS WHAT SAID SO.** MS-2
found this twice; it is now seven times, so it should be assumed rather than discovered:

- relabelling a ward trips the **ward-set** gate before the anchors;
- replacing a ward's geometry trips the **anchors** before the out-of-city probe;
- **adding** an eighth `X0073` row trips the **count** gate before the ownership check — renaming one does not;
- **adding** an office trips the **total-office** gate before the per-ward gate — *moving* one does not, and the per-ward gate exists precisely because the total cannot see it;
- changing Ward 7's date **and** its precision trips the **precision split** before the date assertion.

⚠ And one control reported **DID NOT FIRE** when the gate was fine: both migrations carry a line
reading `Post-verify gate`, so a tamper inserted "before the marker" landed in the **structure**
gate, which runs before the people exist. **A control that lands in the wrong place reads exactly
like a missing gate.**

⚠ **`psql` writes `RAISE NOTICE` to STDERR**, so a stdout-only capture shows a clean run with no
evidence that any gate ran at all. The harness keeps both streams.

Dry run was a real `BEGIN … ROLLBACK` through `psql` as `ev_api`, with both migrations in one
transaction, and **the rollback was verified to have reverted** — 89,659 / 10,204 / 10,140 / 10,706
and zero Biloxi rows — before the real apply.

### Gates

`check:occupancy` green · `check:migrations` green (4 added vs `origin/master`, 2,180 slots claimed
across 393 refs) · `check:reservations` green · **`check:reachability` nothing regressed** —
`BAD_GEOMETRY` 4/4, `DEAD_GEOGRAPHY` 17/17, `UNREACHABLE` 7/7, every bucket exactly at baseline.

### ⚠ Debts carried out of MS-3

- **Ward 7 is dated to a month.** Promoting it to `2024-03-19` needs the council minutes from the
  Laserfiche portal, and nothing else will do.
- **No headshots and no banner yet** — MS-5.
- 🔴 **`harrisoncountyms.gov` and `www.co.harrison.ms.us` sit behind a Cloudflare challenge**
  (HTTP 403, *"Just a moment..."*, to a bare fetch and a Chrome UA alike, on real and bogus paths).
  **MS-4 must open them in Playwright from the start.**

---

## ✅ MS-4 APPLIED 2026-09-28 — HARRISON COUNTY IS SEATED, AND BILOXI SCORES 4 OF 4

`CC_0173` (structure) + `CC_0174` (occupancy), plus
`scripts/load-harrison-supervisor-districts.mjs` for the geometry: **5 supervisor-district polygons
on `X0074`, 27 offices, 27 seated, 0 vacant, 27 people created, 0 reused.**

| scope | before | after | expected |
| --- | --- | --- | --- |
| `geofence_boundaries` | 72,893 | **72,898** | +5 exact |
| `politicians` | 89,667 | **89,694** | +27 exact |
| `offices` | 10,212 | **10,239** | +27 exact |
| `office_terms` | 10,148 | **10,175** | +27 exact |
| `districts` | 10,714 | **10,719** | +5 exact — the county row is ADOPTED, not created |
| `chambers` | 1,343 | **1,348** | +5 |
| `governments` | 613 | **614** | +1 |
| `offices_missing_terms` | 422 / 238 | **422 / 238** | must NOT move — unmoved |
| CONTROL: Biloxi offices | 8 | 8 | unmoved |
| CONTROL: MS legislative offices | 174 | 174 | unmoved |
| CONTROL: Aberdeen offices | 9 | 9 | unmoved |

### ✅✅ THE FOUR-ANSWER PROBE IS COMPLETE

**Biloxi City Hall now returns FIFTEEN officeholders**, and the four the programme set out to get:

| answer | officeholder |
| --- | --- |
| **council member** | **Wayne Gray**, Biloxi Ward 1 |
| **county supervisor** | **Dan Cuevas**, Harrison County District 1 |
| **state representative** | **Zachary Grady**, HD-115 |
| **state senator** | **Scott DeLano**, SD-50 |

plus Mayor Gilich, the seven countywide county officers, and District 1's Justice Court Judge,
Constable and Election Commissioner. **Mobile, Alabama returns nothing at all.**

**Per-district control: each of the 5 supervisor districts' interior points resolves to exactly 4
offices**, with a positive control in the same query returning **11** when the county layer is
included — so the query can report a number other than four.

🟢 **AND THE SLICE CLOSED A CIRCLE.** District 1's Justice Court Judge is **Albert J. Fountain**,
the judge who administered the oath to Biloxi's mayor in 2017; District 5's is **Nick Patano**, who
did it in 2021 and 2025. MS-3 read those names out of the city's inauguration reports without
knowing they were county officeholders. And **Nathan Barrett**, District 5 Supervisor, is the man
whose resignation created the Biloxi Ward 7 vacancy that MS-3 spent a page dating.

### 🟢 THE INVENTORY IS 27, AND THE COUNTY'S OWN SENTENCE COULD NOT SUPPLY IT

⚠ **THE COUNTY'S "Elected Officials" PAGE IS AN OPEN LIST.** It reads: *"In Harrison County, these
elected officials **include**; the Board of Supervisors, Sherriff, Circuit Clerk, Chancery Clerk,
Tax Collector, Tax Assessor, District Attorney, Coroner, Election Officials, and County
Prosecutor."* The word is *include*; it omits the **Justice Court Judges** and the **Constables**,
both of which are on the ballot. ▶ **A list that says "include" is a lead, not an enumeration.**
⚠ And the county's own site files the **Justice Court under DEPARTMENTS**, beside Mosquito Control
— the Grand Forks trap: a menu's grouping is not the elected/appointed line.

🟢 **THE ENUMERATION IS THE SECRETARY OF STATE'S CERTIFIED RECAPITULATION**, the document the
County Election Commission signed on 2023-11-17 and filed with the State. Twenty-two county
contests, and nothing else: Chancery Clerk · Circuit Clerk · Coroner · County Attorney · Sheriff ·
Tax Assessor · Tax Collector · Supervisor 1–5 · Justice Court Judge 1–5 · Constable 1–5.

⚠ **BILOXI'S ARGUMENT DOES NOT SURVIVE INTACT, AND THAT IS THE FINDING.** MS-3 could say "one
ballot enumerates everything, because every municipal office shares one cycle". **That is false for
a Mississippi county.** Only **two** Election Commissioner contests were on the 2023 ballot —
Districts 2 and 4 — while the county's own page names **five** sitting commissioners and the
recapitulation's certification page carries five signature lines. All five are seated; only the two
the certified results cover are dated.

⚠ **THE DISTRICT ATTORNEY IS DELIBERATELY NOT SEATED.** *"District Attorney 02"* (W. Crosby Parker)
is on the same ballot, but the office is elected by the **Second Circuit Court District** — Harrison,
Hancock and Stone counties together. Seating it here would hang a three-county officer on a
one-county polygon. **Recorded as a debt, not created.**

🟢 **AND THE TWO JUDICIAL DISTRICTS DO NOT DUPLICATE ANYTHING.** MS-3 flagged Harrison's First
(Gulfport) and Second (Biloxi) judicial districts as a possible duplication of county offices. They
are not: they are **courthouses**. The Board of Supervisors meets in Gulfport on the first Monday
and in Biloxi on the second, and there is one Chancery Clerk, one Circuit Clerk, one Sheriff.

### 🟢🟢 ONE GEOMETRY CARRIES TWENTY OFFICES, PROVED PRECINCT BY PRECINCT

Four office sets are elected from five districts each. **Miss. Code § 9-11-2 lets the board draw
the justice court districts**, so they need not be the beats — "obviously the same" is exactly the
assumption this programme refuses.

▶ **The certified recapitulation settles it.** The precincts that cast votes in Supervisor District
N are exactly those that cast votes in Justice Court Judge District N and Constable District N, and
Election Commissioner 2 and 4 match Supervisor 2 and 4. The totals corroborate:

| district | Supervisor | Constable | Justice Court |
| --- | --- | --- | --- |
| 1 | 4,728 | 4,754 | 4,859 |
| 2 | 7,761 | 7,842 | 7,890 |
| 3 | 9,146 | 9,159 | 9,296 |
| 4 | 5,676 | 5,745 | — |
| 5 | 7,814 | 7,792 | — |

**One electorate counted three times, not three that happen to be close.** So 20 district offices
hang on 5 district rows, four each.

⚠ **THE JUSTICE COURT JUDGES ARE JUDICIAL AND THEIR DISTRICTS ARE NOT FLAGGED `is_judicial`.** The
flag lives on the district, and these districts also carry supervisors, constables and election
commissioners. Marking it would mislabel the other fifteen.

### 🔴🔴 `DIST_ID` IS A PERMUTATION, AND IT LOOKS PERFECT

The supervisor layer carries `District` and `DIST_ID`. **`DIST_ID` is wrong for four of five:**

| District | 1 | 2 | 3 | 4 | 5 |
| --- | --- | --- | --- | --- | --- |
| DIST_ID | 1 | **5** | **4** | **3** | **2** |

A join on it would swap Districts 2↔5 and 3↔4, sending voters in four of five districts to the
wrong supervisor, judge, constable **and** election commissioner at once.
▶ **This is MS-3's Biloxi `Id` trap in the very next wave, and worse.** There the bad field
*repeated*, so it looked broken. Here it is a clean permutation of exactly the right five values
and looks perfect. **Only reading a sample row by row catches it; no count, no distinctness test
and no null check ever would.**

🟢 **The layer names its own supervisors** in `DIST_NAME`, so the Secretary of State's certified
winners could be checked straight against the geometry's attributes — five for five.

### The anchors, and a source defect they exposed

| anchor set | result |
| --- | --- |
| the **18 precincts** whose supervisor district the CERTIFIED 2023 RESULTS state | **18 of 18** |
| the county's own **49 polling places** against its own `District` field | **48 of 48 that state one** |
| `DIST_NAME` against the certified winners | 5 of 5 |

🔴 **THREE OF THE 49 POLLING PLACES CARRY LATITUDE 0, LONGITUDE 0 IN THEIR `LAT`/`LON` ATTRIBUTES**
while their **geometry is correct**. A test built on the attributes would put three anchors in the
Gulf of Guinea, match no district, and read as a broken boundary file. **The loader uses geometry
and never the attributes**, and asserts the null-island records are still there — if they are
repaired, it stops and makes a human re-decide.

🔴 **AND ONE RECORD STATES NO DISTRICT AT ALL** — `EAST ORANGE GROVE` carries `District = " "`, a
single space, *and* is one of the three at 0,0: the one record in 49 defective twice over. It is
**named and split out**, not swept up by widening the filter, and the certified results cover it
(E Orange Grove → District 2).

### 🔴🔴 THE OATH DATE MOVED BECAUSE OF A HOLIDAY, AND ONLY THE MINUTES SAY SO

Mississippi seats county officers on the **first Monday of January**. A reader who knew that would
write 2024-01-01. The Board's own organising minute says otherwise and explains itself:

> *"a regular meeting … was begun and held … on the **FIRST TUESDAY OF JANUARY 2024**, being
> January 2, 2024, **the first Monday of January 2024 being a legal holiday** … There appeared the
> following members-elect … **for the term of four years commencing on this date**: DAN CUEVAS
> District One, REBECCA POWERS District Two, MARLIN R. LADNER District Three, KENT JONES District
> Four, NATHAN BARRETT District Five — and each of them having given bond … and taken the oath
> prescribed by the Constitution of the State of Mississippi…"*

▶ **A computed date would have been a day wrong, for a reason no reading of the statute could
supply.** This is the **third** variant of the rule inside this one slice: Biloxi's mayor was sworn
**two days before** his advertised inauguration; Biloxi's Ward 7 ceremony was **announced and never
reported**; and here **the statutory day itself moved**.

⚠ **KENT JONES IS ABSENT FROM THE ROLL CALL OF THAT SAME MEETING**, and it is recorded rather than
hidden. He is dated with the other four because `office_terms` records the start of the **term**,
which the recital fixes for all five members-elect; attendance at the meeting's business is a
different fact. He is present on 2024-01-08 and no later minute records a separate oath.

**5 day-precision · 19 year · 3 honestly unknown.** The nineteen are certified winners of
2023-11-07 taking a four-year term from January 2024, written at `year` because **no document read
for this wave records the day each was sworn** — they are sworn separately from the Board. Writing
2024-01-02 for them would borrow the supervisors' minute for people it does not mention.

⚠ **THE COUNTY'S OWN OFFICER PAGES CARRY DATES AND THEY ARE NOT USED.** Each reads *"Elected: YYYY"*
and *"Current Term Ends: MM/DD/YYYY"*. The **Coroner's** says *"Elected: 2020 / Current Term Ends:
12/31/2028"* for a man the certified results show winning in **2023**, which on a four-year term
ends 12/31/2027 — the two cannot both be right. The **Circuit Clerk's** says *"Elected: 2024"* for a
man who won in November 2023. ▶ *"First elected" is not a term start and these fields mean neither
consistently.* They are excellent evidence of **current incumbency**, which is what they were used
for.

### Namesakes, and a guard lifted for one row

🟢 Two collisions on the guard's own key, both **different people**, both checked: **James Morgan**
(an inactive `indiana_discovery` stub — the shape MI-2 reused for four sitting legislators and then
found hidden) and **Jennifer Smith** (a sitting Santa Monica-Malibu Unified school board member in
California). Controls fire: 73 active Smiths, 53 Joneses, 3 existing Ladners.
🔴 **The duplicate-name guard was lifted for ONE ROW, not for the migration** — the other 26 insert
with it armed. ⚠ **James Morgan did not trip it at all**, because the existing row is *inactive* and
the guard only sees active rows; he was read anyway.
🔴 **FOUR LADNERS ARE SEATED BY THIS WAVE AND THEY ARE FOUR PEOPLE** — Marlin R. (Supervisor 3),
Paula (Tax Assessor), Brandon (Justice Court 2), Dianne (Justice Court 3) — beside three already in
production, one of whom is **Philman A. Ladner**, whom MS-2 seated in Senate District 46. A
surname-keyed merge would collapse seven people into one.

⚠ **Two names are split on a judgement and it is written down**: *Sharon Nash Barnett* is stored
with `last_name` **Barnett** and "Nash" read as a middle name, and *Toni Jo Diaz* with `first_name`
**Toni**. MS-2's rule is that a compound surname is decided by a second publisher; none was found
for either, so these are the most likely reading, not a proved one.

### The gates

**Eight loader controls and sixteen migration controls, every one watched failing on its own
target.** 🟢 **None of the sixteen was shadowed on first writing** — MS-3 had five, and its lessons
were applied in advance: *move* an office rather than add one to reach the per-district gate;
*rename* a boundary rather than add one to reach the ownership gate; hold the precision constant to
reach a date assertion; and use `beforeLast` for the second migration's gate, because both files
carry a line reading `Post-verify gate`.

Dry run was a real `BEGIN … ROLLBACK` through `psql` as `ev_api` with both migrations in one
transaction, and **the rollback was verified to have reverted** — 89,667 / 10,212 / 10,148 / 10,714
and zero Harrison County rows — before the apply.

`check:occupancy` · `check:migrations` · `check:reservations` · `check:child-county` green;
**`check:reachability` nothing regressed** — 4 / 17 / 7, every bucket exactly at baseline.

### ⚠ Debts carried out of MS-4

- **Three Election Commissioners undated** (Districts 1, 3, 5). Their arrival needs an election
  record this wave did not find. 🔴 **Do not copy 2024 onto them from their two colleagues.**
- **Nineteen officers at `year` precision.** The day each was sworn would need each officer's own
  oath record, not the Board's minute.
- **The District Attorney is not seated**, and will not be until the circuit court districts have
  geometry.
- **No headshots and no banner** — MS-5, the last stage of the last slice.

### ⚠ Access facts measured this session

- 🔴 **The Cloudflare challenge covers the county's HTML PAGES ONLY.** `harrisoncountyms.gov` answers
  a bare `fetch` with **HTTP 403 "Just a moment…"**, but its **documents redirect to
  `cms9files.revize.com`, which Node fetches normally** — the minutes, agendas and PDFs are all
  reachable without a browser. Use Playwright for the pages and plain `fetch` for the files.
- 🔴 `geo.co.harrison.ms.us` — the county's own ArcGIS Server, and the host of the *older* supervisor
  district service — is behind the same challenge and returns HTML to an API request. The county's
  **AGOL** copy is both readable and newer.
- 🟢 `sos.ms.gov` serves the certified results to a bare `fetch`, and a bogus county name returns a
  real **404**.
- ⚠ **The certified recapitulation is a 41-page SCANNED PDF.** `pdftotext` returns one line and
  `PyMuPDF` returns 46 characters across ten pages; the same extractor returns 1,783 characters from
  page 1 of a text PDF, which is the control that says the document is the problem and not the tool.
  It was read as images, block by block: contests repeat across five precinct groups, so the block
  starts are pages 2, 7, 12, 17, 22, 27, 32 and 37.

## Access facts measured this session

🔴🔴 **`legislature.ms.gov` AND `billstatus.ls.state.ms.us` SEND ONLY THEIR LEAF CERTIFICATE.** Both
fail `curl` and Node's `fetch` with `UNABLE_TO_VERIFY_LEAF_SIGNATURE`; `openssl s_client` shows a
chain of depth 0 and `Verify return code: 21 (unable to verify the first certificate)`. A browser
succeeds because it fetches the intermediate from the certificate's own AIA extension.

**This is the Michigan MI-2 defect exactly, and the fix transfers.** Both leaves name the same
issuer, and the AIA gives its location:

```
CA Issuers - URI:http://secure.globalsign.com/cacert/gsrsaovsslca2018.crt
```

▶ Add the **GlobalSign RSA OV SSL CA 2018** intermediate to `tls.rootCertificates`, exactly as MI-2
added the two DigiCert intermediates. 🔴 **Never disable verification.** Stage 2's roster sweep
cannot start until this is done, and its control must show the fix is necessary, sufficient, and
masking nothing.

🟢 `www.sos.ms.gov` (HTTP 200, 142,752 bytes) and `maris.mississippi.edu` (HTTP 200, 19,783 bytes)
are reachable from Node with no special handling.

---

## Tooling written this session (nothing writes to a database)

- `backend/scripts/measure-ms-tiger-legislative.mjs` — counts the TIGER legislative layers twice by
  independent routes, across vintages, and reports whether anything in the file can date the plan.
  Bogus-FIPS positive control.
- `backend/scripts/diff-ms-tiger-vintages.mjs` — locates every Mississippi census tract internal
  point under each vintage and reports which districts exchange tracts. Two controls, both watched
  failing.
- `backend/scripts/verify-ms-tiger-vintage.mjs` — the vintage proof. Compares MARIS's block
  equivalency files against TIGER over all 112,241 blocks, in blocks and in population, with an
  optional `--county` restriction. Three controls, all watched failing.

Inputs are downloaded by hand and passed as paths, so nothing is assumed about a working directory.
The MARIS `.xlsx` block equivalency files were converted to two-column CSV with `openpyxl`.

**Sources, all read directly rather than through a summary:**

- MARIS, 2025 legislative remedy plans (shapefiles, block equivalency, reports, regional maps):
  `maris.mississippi.edu/HTML/Redistricting/RedistrictingRedevelopment2025.html`
- MARIS, court-approved May 2025 plans:
  `maris.mississippi.edu/HTML/Redistricting/CourtApprovedHouseandSenate2025.html`
- Three-judge court, order approving the remedial plans in part, 2025-04-15 (Doc 254).
- Three-judge court, order adopting the SBEC Senate plan and setting the special-election schedule,
  2025-05-07 (Doc 262), case 3:22-cv-00734-DPJ-HSO-LHS.
- U.S. Supreme Court Order List, 2026-05-18, No. 25-234.

---

## ▶ RESUMING THIS SLICE — read this before touching anything

**State: MS-1, MS-2, MS-3 AND MS-4 ARE ALL APPLIED** and on `origin/knight/ms-slice16` (PR #839).
Nothing is uncommitted and nothing is unpushed. Geography (`X0073` Biloxi wards, `X0074` Harrison
supervisor districts) is loaded; `CC_0169`–`CC_0174` are written and applied.
✅ **Biloxi City Hall returns 15 officeholders and scores 4 of 4** — council member, county
supervisor, state representative, state senator.
▶ **MS-5 IS NEXT, AND IT IS THE LAST STAGE OF THE LAST SLICE: ASSETS.** No `biloxi` banner key
exists, and none of the 35 city and county officials has a headshot. 🔴 Read the banner rules in
memory before choosing anything — **certify in the 6:1 BAND and LOOK AT THE ASSET**, and **read
the `states/MS.jpg` banner in the band first**, because adjacency is composition.

| stage | state |
| --- | --- |
| 1 geography | ✅ applied — 174 polygons |
| 2 legislature | ✅ applied — 174 offices seated (`CC_0169`/`CC_0170`) |
| **3 Biloxi** | ✅ applied — 8 offices seated (`CC_0171`/`CC_0172`) + 7 ward polygons on `X0073` |
| **4 Harrison County** | ✅ applied — 27 offices seated (`CC_0173`/`CC_0174`) + 5 supervisor polygons on `X0074` |
| **5 assets** | ▶ **OPEN — the last stage of the last slice. No `biloxi` banner key; no headshots for the 35 city and county officials** |

### What MS-3 has to establish

🔴 **BIND ON `(mtfcc, geo_id)` = (`G4110`, `2806220`) FOR BILOXI AND (`G4020`, `28047`) FOR
HARRISON COUNTY.** Mississippi's `geo_id` collision is the worst in the programme after
Pennsylvania: STATE_UPPER runs `28001`-`28052`, STATE_LOWER `28001`-`28122` and COUNTY
`28001`-`28163`, so **Senate District 47, House District 47 and Harrison County are all `28047`**.
MS also holds **427 `G6350` ZCTA** rows. Never match on a number or a name alone.

🔴 **BILOXI HOLDS NO GOVERNMENT ROW, NO CHAMBER AND NO OFFICE.** It exists only as a TIGER place
polygon (67.7068 sq mi, water included). Harrison County is a `districts` row with 0 offices.

▶ **READ THE CITY'S OWN CHARTER FOR THE INVENTORY, the way every earlier stage 3 did** — Detroit's
came from the charter's own enumerating sentence, Aberdeen's from Home Rule Charter s 2.02(a).
⚠ **Do NOT carry a template across cities** (`feedback_describe_offices_dont_standardise`): Akron
elects no City Clerk while Fort Wayne does; Gary elects a judge and Fort Wayne does not; Grand
Forks elects a municipal judge mentioned in ONE sentence on a staff page.
⚠ Mississippi municipalities run under one of several statutory forms (mayor-council, commission,
council-manager, code charter). **Establish which form Biloxi uses before counting seats**, and
read the later, more specific instrument — SD-4's rule, where a duty statute named a structure it
did not require.

🟢 **HARRISON COUNTY HAS TWO JUDICIAL DISTRICTS (First at Gulfport, Second at Biloxi).** That is
a real Mississippi peculiarity and it may duplicate some county offices. **Check it; do not assume
it either way.** Stage 4's inventory is unread too.

### 🔴 The one thing about Mississippi that no other slice has

**THE MAP AND THE MEMBER HAVE COME APART, AND IT IS NOW WRITTEN INTO PRODUCTION.** MS-1 loaded the
**2022 lines** (the Supreme Court vacated the judgment approving the 2025 remedial plans on
2026-05-18, the Secretary of State reverted SEMS to the 2022 lines on 2026-07-24, and the
three-judge court held on 2026-09-11 that the 2025 Joint Resolutions *"are not operative"*, Doc
318). But the members seated by the **2025-11-04** specials were elected under the 2025 lines, and
the same order records that *"the Legislature's current composition will remain unchanged until
the 2027 election."*
▶ In **Senate 1, 2, 10, 11, 19, 34, 41, 42, 44, 45** and **House 16, 22, 36, 39, 41** the holder
of district N may have been elected by a differently-shaped district N. **This is the State's
position, not a defect. Do not "tidy" it.**
⚠ **RE-READ THE DOCKET BEFORE ANY RELOAD OR BEFORE THE 2027 CYCLE** — 3:22-cv-734-DPJ-HSO-LHS on
CourtListener RECAP (docket id `66672561`, PACER `gov.uscourts.mssd.117094`), **opened in
Playwright**, because the page 403s a bare fetch and the docket-entries API 401s. A motion to stay
and an expedited-schedule motion were both pending on 2026-09-28, and Mississippi was holding
post-*Callais* redistricting hearings to 2026-10-01. **The 2022 lines are operative now, not
permanently.** 🟢 Neither Loyola nor the American Redistricting Project had posted the order that
settled this — **a tracker's silence is not a docket.**

### ⚠ Working facts a fresh session will trip on

- **Worktree `C:\ev-accounts-ms`, branch `knight/ms-slice16`.** `backend/node_modules` is a real
  `npm install` (not a junction, unlike the SD worktree), and **`backend/.env` is a HARD LINK** to
  the main checkout's, because the repo `.env` is read-blocked here. Both are gitignored. Recreate
  the link with:
  `cmd //c "mklink /H C:\ev-accounts-ms\backend\.env C:\EV-Accounts\backend\.env"`
- 🔴 **The worktree's upstream was `origin/master` when created** (`git worktree add -b <branch>
  <base>` does that). It has been repointed at `origin/knight/ms-slice16`. **Check `@{u}` before
  pushing** in any new worktree made this way — OH-5's trap.
- 🔴 **MIGRATIONS ARE APPLIED WITH `psql`, NOT THE MCP**, and dry-run by concatenating the pair
  into one transaction ending in `ROLLBACK`, then **verifying the rollback reverted**:
  `cd /c/ev-accounts-ms/backend && (set -a; . ./.env; set +a; "/c/Program Files/PostgreSQL/18/bin/psql" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f <file>)`
  `scripts/ms2-migration-controls.mjs` builds the dry run and one tampered copy per gate.
- 🔴 **SLOTS USED SO FAR: `CC_0169`, `CC_0170`. ALLOCATE NEW ONES; NEVER COUNT.**
  `npm run steward --prefix backend -- slot CC --purpose "..."`. MS-1 needed no slot (geography
  loads run through the loader). ⚠ **An `X` boundary code has NO allocator** — if MS-3 loads
  council-ward polygons it needs one, read from `max(mtfcc)` in prod in the same session as the
  write (MI-3's `X0065`, SD-3's `X0072`).
- 🔴 **THE TLS CHAIN FIX IS LOAD-BEARING FOR EVERY MISSISSIPPI LEGISLATIVE FETCH** and is built
  into `scripts/build-ms-legislature-roster.mjs`: `legislature.ms.gov` and
  `billstatus.ls.state.ms.us` send only their leaf certificate, and the intermediate is
  **GlobalSign RSA OV SSL CA 2018** at `http://secure.globalsign.com/cacert/gsrsaovsslca2018.crt`.
  `--tls-control` proves it necessary, sufficient and masking nothing. **Never disable
  verification.** Biloxi's own hosts have NOT been probed — do that first, with controls.
- ⚠ **`legislature.ms.gov/legislators/` is an empty shell** (650 characters of JS navigation), not
  a second publisher. ⚠ `www.sos.ms.gov` answers **403 to a Chrome UA on a Node TLS fingerprint**
  and 200 to a bare `fetch` — the half-impersonation refusal.
- ⚠ **Regenerable working files are gitignored**: `data/seed-ms-2026/_pages` (member-page cache),
  `_ca` (the intermediate), `_dryrun` (dry run + controls). The roster JSON **is** committed,
  because the migrations were generated from it. `gen-ms-legislature-migrations.mjs` reproduces
  both migrations byte-identically — **edit the generator, never the generated SQL.**
- ⚠ **Lease `state:ms`** — extend it before a long session:
  `npm run steward --prefix backend -- extend state:ms --hours 24`
- ⚠ **Do not build regexes or SQL through nested shell→Python→JS quoting.** It ate backslashes
  three separate times in this slice alone. Write the script to a file and run it.

### Debts open across the slice

- **167 undated legislative arrivals.** No Mississippi member page publishes a service date and the
  oath date must not be computed. The eight 2025-11-04 turnovers are datable from the chambers'
  own journals by a later pass; seven already carry the year.
- **Biloxi scores 2 of 4** — state representative and state senator. The council member and the
  county supervisor are MS-3 and MS-4.
- **Biloxi is the last of the 26 Knight cities without officeholders.**
