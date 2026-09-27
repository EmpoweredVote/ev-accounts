# KS — slice 14 (Wichita · Sedgwick County)

Opened 2026-09-26. **Nothing has been written to production.** This file records the baseline as
measured when the slice opened, and the two mistakes that measurement corrected.

Lease: `state:ks`, claimed 2026-09-26, expires **2026-09-28 06:08Z**. Branch: `knight/ks-slice14`.

## 🔴🔴 THE FIRST MEASUREMENT OF THIS SLICE WAS WRONG, AND THE LOADER'S OWN COMMENT CAUGHT IT

A first pass counted `essentials.districts` for Kansas and concluded **"zero places"**, which would
have put a 600-row `place` load into stage 1 that Kansas does not need.

`scripts/load-state-tiger-boundaries.ts` says, in the ND block, that North Dakota

> *"owes no `place` load — one of six such states (**KS** KY MI MS ND SD)"*

▶ **That contradiction was the tell.** Re-measured against `essentials.geofence_boundaries`,
Kansas holds **114 `G4210` place rows**. The first query was counting the wrong table: places have
boundary rows and **no `districts` rows**, so a districts-only count reports zero and looks
authoritative.

🔴 **AND THE TWO TABLES KEY DIFFERENTLY.** `districts.state` holds a **USPS** code (`ks`);
`geofence_boundaries.state` holds a **2-digit FIPS** code (`20`). A query written for one and
pointed at the other returns an empty set rather than an error.
▶ **Measure geometry in `geofence_boundaries` keyed by FIPS. Measure offices and districts in
`districts` keyed by USPS.** Never infer one from the other.

⚠ **`PROGRAM.md`'s `626` column for Kansas is COUNTY SUBDIVISIONS, not places.** Reading it as a
place count is what made the first pass plausible.

## Baseline as measured when the slice opened, 2026-09-26

### Geometry — `essentials.geofence_boundaries`, `state = '20'`

| MTFCC | Kind | Rows |
| --- | --- | --- |
| `G4040` | cousub / MCD | 1,391 |
| `G6350` | (unclassified in this query) | 704 |
| `G4110` | county subdivision | 626 |
| `G4210` | **place** | **114** |
| `G4020` | county | 105 |
| `G5200` | congressional | 4 |
| **`G5210`** | **sldu (state senate)** | **0** |
| **`G5220`** | **sldl (state house)** | **0** |

🟢 **The two zeros were CONTROLLED before they were believed.** The same query shape over states
known to hold legislative geometry returns Kentucky **38/100**, Michigan **38/110**, North Dakota
**47/48**. The detector can see geometry where it exists; Kansas genuinely has none.

### Districts and offices — `essentials.districts`, `state = 'ks'`

| Kind | Rows |
| --- | --- |
| county (`G4020`) | 105 |
| congressional (`G5200`) | 4 |
| statewide, **no MTFCC** | 6 |
| **place / sldu / sldl** | **0** |

⚠ **The six MTFCC-less rows are not an anomaly** — they are the statewide entities: US Senate
(2 offices) and five state executives (Governor, Lt Governor, Attorney General, Secretary of State,
Treasurer). A statewide district legitimately carries no MTFCC and `geo_id = '20'`.

**Kansas holds ZERO state legislative offices.** `PROGRAM.md` records `0/125` House and `0/40`
Senate.

## What KS-1 owes

**`sldu` + `sldl` only** — the same shape as OH, PA, SC, MI, ND and KY. No `place` load, no
`county` load, no `cd` load; all three are already in production.

```ts
KS: new Set(['sldu', 'sldl']),
```

Expected: **40 Senate + 125 House = 165 boundaries and 165 districts.** Stage 2 then owes 165
offices.

## ✅ KS-1 step 1 — the map vintage is PROVEN, 2026-09-26

**TIGER FIPS 20 carries Substitute for Senate Bill 563 — the Senate map "Liberty 3" and the House
map "Free State 3F" — in every vintage 2022 through 2025. 40 Senate + 125 House.**
Tool: `backend/scripts/verify-ks-tiger-vintage.mjs`, which needs no database. It carries the proof
and both controls, and `--self-test` makes the proof gate fail on demand.

🟢 **THE AUTHORITY IS THE ENACTED PLAN FILE ITSELF, WHICH IS STRONGER THAN ANY EARLIER SLICE HAD.**
The Kansas Legislative Research Department — the Legislature's own agency — publishes the passed
shapefiles at `klrd.gov/wp-content/uploads/2023/11/{Liberty_3,Freestate-3F}.zip`. Those two names
are not labels this repo chose: they are the names the Kansas Supreme Court uses for the two maps
it reviewed. Kentucky had to settle for the LRC's *current-geometry* map service; Kansas publishes
the artifact that was voted on. Both answer a plain HTTPS request — no WAF, unlike Ohio.
⚠ `kslegislature.gov/li/redistricting/` is a **404**. Go to KLRD, not to the Legislature's site.

### 🔴🔴 The finding that must survive this slice: A THRESHOLD TEST PASSES KANSAS'S OLD MAP

The 2012 court-drawn plan (*Essex v. Kobach*), carried by TIGER 2020, still agrees with the 2022
enacted plan on **35 of 40 Senate (87.5%)** and **112 of 125 House (89.6%)**.

▶ **So the discriminator is NOT the agreement rate — it is that the correct plan moves EXACTLY
ZERO districts and the wrong one does not.** Anyone who relaxes `moved === 0` to "≥90% agree"
re-admits a decade-old superseded map. This reproduces ND's 92% finding *inside Kansas*, against
the real prior plan rather than a stale vintage. It is control 2 in the tool, and it is the reason
the tool asserts a count and not a percentage.

### What else the proof established

- 🔴 **Kansas gives NO structural discriminator — the Kentucky shape exactly.** TIGER 2022, 2023,
  2024 and 2025 are all 40 and 125, MTFCC `G5210`/`G5220`, codes contiguous `001..040` and
  `001..125`, zero letters, zero zeros. A count check, a code-set check and a contiguity check all
  pass every vintage. Nothing about the file dates the map; the evidence had to be geometric.
- ⚠ **`LSY` is the misleading field again**, as in KY and MI. It reads 2022 in TIGER 2022/2023 and
  2024 in TIGER 2024/2025, which reads like a new plan. It is Census bookkeeping: statewide `ALAND`
  moves 211,753,641,384 → 211,754,288,230 across all four vintages — **0.0003%** — and every
  internal point stays put.
- 🔴 **A KANSAS DISTRICT CODE IS PADDED ON ONE SIDE AND NOT THE OTHER.** The authority serves
  `DISTRICT = '39'` unpadded; TIGER serves `SLDUST/SLDLST = '039'` zero-padded to three. **A raw
  string compare agrees on nothing and looks exactly like a wrong vintage.** Both sides are checked
  numeric before normalising; a non-numeric code is refused, never cast — the family of defect that
  `04A` (ND), `08A` (MN) and `H001` (KY) are.
- 🟢 **Both chambers are single-member** (`MEMBERS = 1` on all 165 authority polygons), so polygon
  count IS seat count — unlike ND and SD.
- 🔴 **`geo_id` collides with counties, as in PA, SC, OH, ND and KY.** Measured against production:
  105 Kansas counties, `20001..20209`, all odd — **20 collide with the Senate range, 63 with the
  House range.** 🟢 **Sedgwick County escapes at `20173`**, above both ranges; Fayette County did
  not, at `21067`. That is luck of the numbering, not a property of the loader.

### Corrections this step made to the lines that used to sit here

- 🔴 **"The Senate map is SB 563 and the House map HB 2736" was WRONG.** **Both** legislative maps
  live in **one bill, Substitute for SB 563.** There is no HB 2736 House map. SB 563 was introduced
  2022-03-14 carrying maps for both chambers; the House amended it on 2022-03-21 to its own
  preferred House map — which is why the Free State 3F file carries an internal date of 2022-03-21.
- 🔴 **The congressional plan is "Ad Astra 2", not "Ardanna 2"** (KLRD publishes it as
  `M3_AdAstra_2.zip`). The bill number for it is **not** established here — do not write one down
  from memory.
- ✅ **"Whether either legislative map was challenged is not established here" — now established.**
  Kansas Constitution art. 10, § 1(b) makes Supreme Court review **AUTOMATIC AND MANDATORY**: the
  Attorney General *must* petition within 15 days of publication. **This distinguishes Kansas from
  every other slice in this programme, where review happens only if somebody sues.** AG Schmidt
  petitioned 2022-04-25; the court announced 2022-05-18 and filed its opinion 2022-06-21 (No.
  125,083), upholding Sub. SB 563 in full and **ordering no remedial map**. The one intervenor,
  Senator Thomas Holland, contested the procedure and the boundaries of Senate Districts 3 and 9,
  and lost. **One plan has governed since 2022 and governs the 2026 election.**
- ✅ **MI-1's "two chambers on different plans" risk does not apply**, and not because the terms
  were checked — because both maps are in one bill and both agree in every TIGER vintage. The
  four-year Senate term is **not** verified here and nothing now depends on it.
- ▶ **TIGER 2022 agreeing is a PASS here, not a failure** — the Kentucky direction, the opposite of
  North Dakota. The tool states that expectation in advance and asserts it, because an expectation
  formed after the measurement is not evidence.

⚠ **The 2025 congressional remap push is NOT a legislative-map event and must not be read as one.**
Kansas Republicans tried to force a November 2025 special session to redraw the four US House
districts; House leadership ended the push on **2025-11-05** without a session, so **no map of any
kind was enacted** and the congressional rows already in production are not stale from it.
Art. 10, § 1(a) puts the next legislative reapportionment in **2032**.

⚠ **The competing 2022 legislative plans are published as PDF only** — Liberty 2, Freestate 3,
Freestate 3C, Free State 1 and 5. No shapefile, so the MI-style "control against the real competing
plan" is not available here. The 2012 plan is the closest real-plan control there is, and it works.

## ✅ KS-1 step 2 — the loader knows about Kansas, 2026-09-26

`KS: new Set(['sldu', 'sldl'])` is in `STATE_LAYER_ALLOWLIST`, with the slice's findings written
into the block above it. The pre-flight gate for `fipsArg === '20'` is a sibling of Kentucky's.
**Dry-run passes 40 and 125. Nothing has been written.**

```
[sldu] KS MTFCC pre-flight assertion PASSED: 40 records (expected 40), 40 distinct OCD-ID
       suffixes, codes contiguous 001..040, 6/6 enacted-plan anchors agree (3 distinguish 2012).
[sldl] KS MTFCC pre-flight assertion PASSED: 125 records (expected 125), 125 distinct OCD-ID
       suffixes, codes contiguous 001..125, 7/7 enacted-plan anchors agree (2 distinguish 2012).
```

🟢 **The two counts are THE LAW here, not a measurement** — the only slice in this programme where
that is true. *"Kansas has 40 senatorial districts and 125 representative districts. Kan. Const.
art. 2, § 2; K.S.A. 4-101"* (No. 125,083, slip op. at 2). They were measured against TIGER as well,
and agree.

### 🔴🔴 MOST CIVIC ANCHORS IN KANSAS CANNOT DATE THE MAP — MEASURED, NOT ASSUMED

Six ordinary civic points — two in Wichita, the Capitol, the Wyandotte courthouse, Overland Park
and Garden City — resolve **identically under the 2012 and 2022 plans in 11 of their 12
chamber/point pairs.** Only the Capitol moves (Senate 18 → 19).

▶ **An anchor set chosen for being recognisable is a WEAK vintage test here.** So the last two
anchors in each chamber are chosen for the opposite reason: they sit where the plans actually
disagree (Sedgwick SD-27→26, Jefferson SD-2→18, Johnson HD-39→117, Chase HD-68→13). Their expected
values come from KLRD's enacted plan file; their counties were read from production, not inferred
from a name.

🟢 **And the gate now asserts its own discriminating power.** `KS_MIN_DISCRIMINATING = 2` fails the
load if too few anchors distinguish the two plans. That is what stops a later editor from tidying
the odd-looking last two anchors into recognisable landmarks and silently leaving Kansas with a gate
that agrees with the 2012 map.

### 🔴🔴 The gate fired for the WRONG REASON, and two fixes both looked sufficient

The `anchor` tamper perturbs **Wichita City Hall** — an anchor that does *not* distinguish the
plans. The error message diagnosed it as **"this file is the OLD MAP — check `--vintage`"**.

- Attempt 1 — *"every failure landed on its prior value"*: **vacuously true** for a
  non-discriminating anchor, whose prior *is* its expected.
- Attempt 2 — *"…and some failure has expected ≠ prior"*: the tamper sets expected to `999`, which
  satisfies exactly that. Still wrong.
- ✅ The honest test is **not about values — it is about WHICH anchors failed.** An old file makes
  *every* discriminating anchor fail, each landing on its 2012 value. A tampered expectation makes
  *one arbitrary* anchor fail while the discriminating ones still pass.

▶ **A gate that aborts for the wrong reason sends the next reader to check `--vintage` when the
fault is in the source file.** Knight has hit "a gate can abort for the wrong reason" before; this
is that rule inside the error *message* rather than the error *condition*.

### Controls — every assertion watched failing

| Control | Fires | Result |
| --- | --- | --- |
| `KS_PREFLIGHT_CONTROL=count` | MTFCC count | ✅ `expected 39, got 40`, exit 1 |
| `KS_PREFLIGHT_CONTROL=anchor` | vintage | ✅ exit 1 — **and no false "old map" claim** after the fix |
| `KS_PREFLIGHT_CONTROL=weak` | discrimination | ✅ `only 0 of 3 anchors distinguish…`, exit 1 |
| `--vintage 2020` (**no flag needed**) | vintage | ✅ both chambers, **named as the old map** |

🟢 **`--vintage 2020` IS THE CONTROL KENTUCKY COULD NOT HAVE.** Kentucky's 2022 file carries the
*same* plan, so KY-1 had to synthesise its control. Kansas has a real older map to be wrong about,
so the loader can be pointed at it and must abort. Senate failed on all three discriminating
anchors (Capitol 18≠19, Sedgwick 27≠26, Jefferson 2≠18); House on both (Johnson 39≠117, Chase
68≠13).

✅ `npx tsc --noEmit` clean · `npm run lint` 0 errors · `npm run check:ocd-loader` green.

## Expected scope for the slice

| Stage | Owed | Basis |
| --- | --- | --- |
| 1 geography | **165** — 40 sldu + 125 sldl | measured above; place/county/cd already present |
| 2 legislature | **165 offices** — 125 House + 40 Senate | Kansas holds zero today |
| 3 Wichita | unmeasured | city council, from the charter |
| 4 Sedgwick County | unmeasured | Kansas county officers, from state law |
| 5 assets | 165 + city + county portraits, plus a `wichita` banner | |

🔴 **WICHITA'S BANNER COLLIDES WITH THE KANSAS STATE BANNER** — one of four such cities in the
programme (with Miami, Detroit and Charlotte). ▶ **Read `states/KS.jpg` in the 6:1 band before
choosing anything**; Charlotte and Lexington both turned on whether the state banner actually shows
the subject its credit names.

## Next steps, in order

1. ✅ **DONE 2026-09-26 — the map vintage is proven**, against KLRD's own enacted plan files, with
   two controls that fail as required and a `--self-test` that makes the proof gate itself fail.
   Nothing has been written to production.
2. ✅ **DONE 2026-09-26 — the allowlist entry and the pre-flight block are in**, with every
   assertion watched failing first. Still nothing written to production. See below.
3. Load, measure `districts` and `geofence_boundaries` from outside against a same-session baseline
   taken **through the same connection the loader writes with**, and re-run to prove 0 inserted.
4. Probe end to end from a Wichita address, with a negative control outside Kansas.
5. Then stage 2 — **the legislature must precede the cities.**

## Debts this slice already owes

- Nothing to production. Nothing has been written.
- ⚠ **This file lived only on `knight/ks-slice14` for its first day.** A session starting in the
  `master` checkout read `MEMORY.md`, found PROGRAM.md's KS row still blank, and found no `ks.md`
  at all. The branch is pushed, so nothing was lost — but **the handoff chain only works from the
  slice's own worktree.** `C:/ev-accounts-ky` holds this branch despite the Kentucky name.
