# MS — Knight slice 16 (Biloxi, Harrison County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

Lease `state:ms`, claimed 2026-09-28. Worktree `C:\ev-accounts-ms`, branch `knight/ms-slice16`.

**Mississippi is the last state in the programme owing legislative geography, and it is the only
one whose map has been redrawn, litigated, re-approved and then vacated inside one decade.**

| stage | status |
| --- | --- |
| 1 geography | ▶ **OPEN AND BLOCKED ON AN OPERATOR DECISION.** TIGER carries the 2022 plan; the sitting members of 15 districts were elected under a different one. Nothing written |
| 2 legislature | — not started. MS holds **0 of 122** House and **0 of 52** Senate |
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

🔴 **NOTHING INSIDE THE FILE DATES THE PLAN, AND HERE IT NEVER CAN.** Miss. Const. art. 13 § 254
fixes the two chambers, so 122 and 52 are constitutional constants: every plan Mississippi will
ever adopt has exactly that shape. A count check, a code-set check and an `LSY` check all pass on
every vintage. This is the Kansas, Kentucky and South Dakota finding for the fourth time, and
Mississippi is the case where it is true *by law* rather than by accident.

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

⚠ **NO ORDER ON REMAND HAS BEEN FOUND, AND THAT IS "NOT FOUND", NOT "DOES NOT EXIST."** Two
independent trackers were read: the Loyola Law School docket's latest posted filing is the
2026-08-18 reply, and the American Redistricting Project's latest dated entry is 2026-05-18.
Neither publishes an order on remand. **A tracker's silence is not a docket.** Before any load, read
PACER or the court's own docket for case 3:22-cv-00734-DPJ-HSO-LHS.

⚠ **Loyola's own reading of the vacatur is that it restores Map B**, in its words: the Supreme
Court vacated *"effectively restoring the March 2025 plan without the court's subsequent
modification"*. **That is a secondary source's inference and it is recorded here as such, not
adopted.** It is also exactly the question that decides B against C.

🟢 **AND MISSISSIPPI IS REDISTRICTING AGAIN RIGHT NOW.** MARIS publishes a *"Public Hearing Schedule
for upcoming redistricting **August 18 thru October 1, 2026**"*, and files its 2025 work under the
heading **"Court Work (2025), Pre-Callais"**. The state's own publisher treats the 2025 plans as
belonging to a superseded phase. ▶ **Whatever is loaded now has a foreseeable expiry, and it should
be diarised the way MI-1 diarised the Crane A1 reload.**

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

## ▶ RESUMING THIS SLICE — read this first

1. 🔴 **MS-1 CANNOT PROCEED UNTIL THE MAP IS CHOSEN.** A, B or C above. The House question is
   A against B/C and is not close; the Senate question is three-way and turns on what the
   2026-05-18 vacatur restored.
2. **Check the docket before anything else.** No order on remand was found on 2026-09-28, and a TRO
   motion was pending. An order may exist that no tracker has posted.
3. **If Map B or C is chosen, TIGER cannot be the source.** The geometry must be built from MARIS —
   either by reprojecting the `MS_*_CourtApproved_May72025` shapefiles out of
   `NAD_1983_HARN_Mississippi_TM` (false easting 500000, false northing 1300000, central meridian
   −89.75, scale factor 0.9998335, latitude of origin 32.5, GRS80), or by dissolving the block
   equivalency file against the TIGER 2020 block layer. ⚠ **MARIS publishes no block equivalency
   for the court-approved Senate plan** — only shapefiles — so Map C needs the reprojection route
   or a dissolve from a plan file the court accepted.
4. ⚠ **`MS_ProposedSenate_Feb25_2025` is JR 202 as the Legislature adopted it, and the court
   modified it.** The file is authoritative for Map B and stale for Map C. **A source can be
   authoritative for one field and stale for another** — the programme's rule, and the filename
   does not say which.
5. **Stage 2 owes 174 seats**, 122 House and 52 Senate, both single-member. Fix the TLS chain first.
6. **Biloxi is the last of the 26 Knight cities without officeholders.**
