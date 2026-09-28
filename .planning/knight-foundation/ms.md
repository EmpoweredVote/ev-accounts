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
| 3 city waves | — not started. Biloxi holds no government, no chamber, no office |
| 4 county waves | — not started. Harrison County is a `districts` row with 0 offices |
| 5 assets | — not started. No `biloxi` banner key |

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

**State: MS-1 and MS-2 are APPLIED and on `origin/knight/ms-slice16` (PR #839). Nothing is
uncommitted and nothing is unpushed. MS-3 is next: BILOXI, and its office inventory is UNREAD.**

| stage | state |
| --- | --- |
| 1 geography | ✅ applied — 174 polygons |
| 2 legislature | ✅ applied — 174 offices seated (`CC_0169`/`CC_0170`) |
| **3 Biloxi** | ▶ **OPEN, FROM ZERO. Inventory unread.** |
| 4 Harrison County | — not started |
| 5 assets | — not started. No `biloxi` banner key |

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
