# Georgia — slice 2 notes

**Program tracker:** [`PROGRAM.md`](./PROGRAM.md) · **Spec:** [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

Jurisdictions: **Columbus** (Muscogee), **Macon** (Bibb), **Milledgeville** (Baldwin).

| Wave | Scope | Status |
| --- | --- | --- |
| GA-1 | TIGER `place` + `sldu` + `sldl`, FIPS 13 | ✅ **APPLIED 2026-08-31** |
| GA-2 | Legislature: 180 House + 56 Senate | ✅ **APPLIED 2026-09-01** (`CC_0025`, `CC_0026`) |
| GA-3 | **Milledgeville + Baldwin County** | 🚧 **IN PROGRESS** — Task 1 ✅ `X0042` applied 2026-09-01 (6 council districts); Tasks 2–5 open |
| GA-4..5 | Columbus, Macon | — |

---

## Starting position, measured against production 2026-08-31

| What | Georgia holds |
| --- | --- |
| `geofence_boundaries` | `G4020` county **159**, `G5200` congressional **14**, `G6350` **751**. **No `place`, no `sldu`, no `sldl`.** |
| `districts` | COUNTY 159, NATIONAL_LOWER 14, NATIONAL_UPPER 1, STATE_EXEC 4. **Zero STATE_LOWER, STATE_UPPER, LOCAL.** |
| `offices` | 14 US House (13 seated), 4 NATIONAL_UPPER (4 seated), 4 STATE_EXEC (4 seated) |
| Target jurisdictions | Baldwin, Bibb, Muscogee counties exist as districts with `geo_id`. **All three carry ZERO offices.** |

So Georgia is greenfield below the congressional layer, exactly as the spec's §2 measurement said.

## TIGER 2024 FIPS 13, measured from the raw `.dbf` before any load

Files downloaded to `backend/data/seed-ga-2026/` (untracked) on 2026-08-31.

| Layer | Raw records | Keep | mtfcc | `LSY` | `ZZZ` pseudo-districts |
| --- | --- | --- | --- | --- | --- |
| `sldl` | 180 | 180 | `G5220` | `2024` on all 180 | 0 |
| `sldu` | 56 | 56 | `G5210` | `2024` on all 56 | 0 |
| `place` | 675 | **537** | `G4110` 537 + `G4210` 138 CDPs | — | 0 |

Georgia is **single-member in both chambers**, so polygon count equals seat count: 180 and 56.
`county` is already loaded (159) and is deliberately excluded from the layer allowlist — those rows
carry the county districts this slice will hang offices on. `cousub` is excluded: Georgia is not a
strong-MCD state, its county subdivisions are statistical militia districts. **Do not add GA to
`COUSUB_FUNCSTAT_STATES`.**

### 🔴🔴 The `geo_id` collision is THREE-WAY in Georgia, not two-way

| Layer | GEOID range |
| --- | --- |
| `sldl` | `13001` → `13180` |
| `sldu` | `13001` → `13056` |
| `county` | `13001` → `13321` (odd steps) |

All 56 `sldu` GEOIDs collide with `sldl`, **and 89 of the 159 county GEOIDs fall inside the `sldl`
range**. So `13009` is Baldwin County **and** State House District 9; `13021` is Bibb County **and**
House District 21. Florida's collision reached the county layer too, but only between two legislative
layers plus county — here three layers overlap at once.

**Every join must pair `geo_id` with `district_type` (or `mtfcc`). Never match on `label`.**

### 🔴 Two of the three target places are consolidated, and the consolidation is COMPLETE — measured

Nashville's lesson was that a consolidated city's TIGER *place* can be the **balance**, excluding
satellite municipalities whose residents still elect the consolidated council. That is **not** the
case here, and it was measured rather than assumed:

| Place | GEOID | TIGER `ALAND` + `AWATER` | Its county, measured in prod | Verdict |
| --- | --- | --- | --- | --- |
| Columbus city | `1319000` | 216.500 + 4.511 = **221.011** sq mi | Muscogee `13215` = **221.011** | identical — whole county |
| Macon-Bibb County | `1349008` | 249.383 + 5.523 = **254.906** sq mi | Bibb `13021` = **254.906** | identical — whole county |
| Milledgeville city | `1351492` | 20.259 + 0.161 sq mi | Baldwin `13009` = 268.276 | ordinary city inside a county |

Neither Payne City (Bibb) nor Bibb City (Muscogee) appears anywhere in the TIGER 2024 place file —
both dissolved into their consolidated governments. There is no satellite municipality to strand.

### 🔴 TIGER models Georgia's consolidated governments in TWO different ways, and the difference is the tell

Exactly two `G4110` places in the whole state carry `FUNCSTAT = 'F'` rather than `'A'`:

```
1304204  Augusta-Richmond County consolidated government (balance)
1303440  Athens-Clarke County unified government (balance)
```

Those are **balance** records, and they exist because Richmond County still contains Hephzibah and
Blythe, and Clarke County still contains Winterville and Bogart. **Macon-Bibb County is `FUNCSTAT =
'A'`** — a whole-county place, no balance. So in Georgia, `FUNCSTAT` on the consolidated place tells
you whether satellites exist. Neither of our two consolidated targets is a balance record.

⚠ If a later slice takes Augusta or Athens, that `'F'` is the Nashville problem waiting.

### 🔴 "Macon County" is NOT Macon's county

Production holds both `13021 Bibb County` (which contains the city of Macon) and `13193 Macon
County` — a different, rural county 60 miles away. A name-based lookup for Macon's parent county
returns the wrong row. Bibb is the parent. Same class of defect as the FEC homonyms.

### TIGER place naming trap for the city assertions gate

TIGER does not call it "Macon city". The record is **`Macon-Bibb County`**. A
`STATE_CITY_ASSERTIONS` entry of `'Macon city'` would fail on correct data, and the gate is a
substring match, so it is weak either way. The load-bearing check stays an **exact `geo_id`** query:

| Jurisdiction | Place GEOID | TIGER `NAMELSAD` | Interior point (lon, lat) |
| --- | --- | --- | --- |
| Columbus | `1319000` | Columbus city | -84.8749462, 32.5101909 |
| Macon | `1349008` | Macon-Bibb County | -83.6940595, 32.8089903 |
| Milledgeville | `1351492` | Milledgeville city | -83.2406135, 33.0879449 |

## ✅ The vintage check — CLOSED 2026-08-31. All 236 districts, not three.

Georgia's 2021 legislative maps were **struck down** on 2023-10-26. Remedial House and Senate plans
passed 2023-12-05, were signed 2023-12-08 and approved by the trial court 2023-12-28. **The operative
maps are the 2023 remedial plans.** This is a sharper vintage risk than Florida, whose legislative
maps were never litigated, so the check had to be geometric.

### The authority, and how to get it

The General Assembly's own [Find Your Legislator](https://www.legis.ga.gov/find-my-legislator) page
labels its layers **"Current Georgia House (2023)"** and **"Current Georgia Senate (2023)"** and loads
each as a GeoJSON payload from its own API:

```
/api/legislatormaps/GoogleMaps/House%20Map%202023     180 features
/api/legislatormaps/GoogleMaps/Senate%20Map%202023      56 features
```

🔴 **BOTH ENDPOINTS RETURN HTTP 401 TO curl AND TO an in-page `fetch()`.** They carry a bearer
token minted by `/api/authentication/token`. The way through is to let the page load them itself and
read the response bodies out of the browser's network log — the same shape as the WAF lesson, by a
different mechanism.

### The result

For **every** TIGER polygon, that polygon's own guaranteed-interior point (`INTPTLON`/`INTPTLAT`) was
tested against the state's map:

| Chamber | State features | TIGER polygons | Agree | Differ | Point in no state district |
| --- | --- | --- | --- | --- | --- |
| House | 180 | 180 | **180** | 0 | 0 |
| Senate | 56 | 56 | **56** | 0 | 0 |

TIGER 2024 FIPS 13 **is** the 2023 remedial plan. Load it.

🔴🔴 **TEST EVERY DISTRICT WHEN THE STATE PUBLISHES THE WHOLE MAP — THREE ANCHORS CAN PASS
ON THE WRONG MAP.** Florida used three anchor points because its plan services are queried one point
at a time. Here the entire map arrives in one payload, so the complete comparison costs the same as
three. A remap leaves many districts untouched, so three anchors that all happen to sit in unchanged
districts would agree with the superseded map too. The three anchors this file first recorded
(Columbus HD-137/SD-15, Macon-Bibb HD-145/SD-26, Milledgeville HD-149/SD-25) all matched — but they
are now a subset of a stronger result, not the result.

⚠ **DO NOT PICK A SERVICE BY ITS NAME.** A search for Georgia legislative geometry surfaces
`services2.arcgis.com/StQaZGYzUARPnrpL/.../Georgia_Senate_District`, which is a **county
government's** copy described as the **2022** adoption — the superseded map. It was not used.

## 🟢 The same payload is a GA-2 roster source, and maybe a GA-5 one

Each feature carries the sitting member, not only geometry:

```json
{"District":154,"Name":"Gerald Greene","DateVacated":null,
 "PortraitUrl":"https://www.legis.ga.gov/api/images/default-source/portraits/greene-gerald-115.jpg?size=mpSm",
 "Url":"https://www.legis.ga.gov/members/house/115"}
```

- **236 of 236 districts carry a name**, and `DateVacated` is null on every one — the General Assembly
  is claiming a full house. ⚠ That is ONE source. The wave anatomy needs **two**, and the
  "check every seat for a change since the source was last edited" rule still applies: a payload that
  reports no vacancies is exactly what a stale payload also looks like.
- `Url` yields a stable member id (`/members/house/115`) — a better external key than a name.
- `PortraitUrl` is present for all 236, but `?size=mpSm` is a **thumbnail**. Before stage 5 treats
  these as headshots, test whether dropping or raising `size` returns the original — the Ballotpedia
  `thumbs/200/300/` lesson in a different dress.

## ✅ GA-1 applied 2026-08-31

`scripts/load-state-tiger-boundaries.ts` had no `GA` entry. Adding a state is a deliberate code
change, so GA got the full FL treatment: a layer allowlist entry, a `STATE_CITY_ASSERTIONS` entry and
its own MTFCC pre-flight block, each carrying the measurement that justifies its numbers.

```
npx tsx scripts/load-state-tiger-boundaries.ts --state GA --fips 13 --layers sldu,sldl,place
```

| Layer | Boundaries | Districts | Skipped | Errors |
| --- | --- | --- | --- | --- |
| `sldu` `G5210` | 56 | 56 | 0 | 0 |
| `sldl` `G5220` | 180 | 180 | 0 | 0 |
| `place` `G4110` | 537 | 0 | **138 CDPs** | 0 |
| **total** | **773** | **236** | 138 | 0 |

Every gate passed on the dry run before any write: `GA MTFCC pre-flight` 56 / 180 / 537, and
`STATE_CITY_ASSERTIONS` for all three cities.

### Verified after the load

| Check | Result |
| --- | --- |
| Boundaries by `mtfcc` | `G4110` 537, `G5210` 56, `G5220` 180 — and `G4020` 159, `G5200` 14, `G6350` 751 untouched |
| Districts | `STATE_LOWER` **180**, `STATE_UPPER` **56**, every one with a `geo_id` |
| The three places, by **exact `geo_id`** | `1319000` Columbus 221.011 sq mi · `1349008` Macon-Bibb 254.906 · `1351492` Milledgeville 20.420 |
| Legislative `geo_id` ranges | `G5210` 13001–13056, `G5220` 13001–13180 — intact |
| `check:child-county` | children 7,782 · mapped 7,782 · **stale 0** after the CONCURRENT refresh |

The two consolidated places measure the same after loading as they did in the raw `.dbf`, and the
same as their counties: Columbus 221.011 = Muscogee, Macon-Bibb 254.906 = Bibb.

🟢 **The three-way collision does not bite, because the join is written correctly.** Resolving each
anchor through our own polygons, pairing `geo_id` with `district_type`, returns **exactly two answers
each** and they are the state's answers:

```
Columbus       -> State House District 137 · State Senate District 15
Macon-Bibb     -> State House District 145 · State Senate District 26
Milledgeville  -> State House District 149 · State Senate District 25
```

⚠ The matview refresh needs the `postgres` role — `ev_api` does not own it — so it went through the
Supabase MCP. `REFRESH … CONCURRENTLY` cannot run inside a transaction block, and the MCP wrapped it
without complaint. Per FL's correction, the refresh is required because this load wrote `place`
(`G4110`); a wave that loads only `X` codes does not need it.

## GA-2 — the roster, reconciled 2026-08-31

### Two sources, and they are genuinely different records

| # | Source | Endpoint | What it is |
| --- | --- | --- | --- |
| A | District **map** behind Find Your Legislator | `/api/legislatormaps/GoogleMaps/{House,Senate} Map 2023` | one feature per district, carrying the **sitting** member |
| B | Member **list** behind `/members/{house,senate}` | `/api/members/list/1033?chamber={1,2}` | one row per **person**, including people who have left |

Both are legis.ga.gov, but they are different endpoints over different records and they do not have
the same shape. Payloads kept in `backend/data/seed-ga-2026/` (untracked).

### The diff

| Chamber | Seats | MAP districts | LIST rows | LIST districts | Rows with `dateVacated` | Districts absent from either | **Name disagreements** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| House | 180 | 180 | **186** | 180 | 6 | none | **0** |
| Senate | 56 | 56 | **61** | 56 | 5 | none | **0** |

🟢 **The two sources agree on all 236 sitting members, name for name.** Every district has
exactly one non-vacated LIST row, and it matches the MAP feature.

🔴 **THE LIST IS OVER-LONG FOR THE SAME REASON FLORIDA'S WAS — 11 SEATS CHANGED HANDS MID-TERM**,
and the list keeps the departed member beside the sitting one. Unlike Florida, Georgia annotates it
cleanly: the departed row carries `dateVacated` and the sitting row does not. Do not de-duplicate on
name or on district alone; **filter on `dateVacated IS NULL`.**

| Chamber | District | Departed | Vacated | Sitting now |
| --- | --- | --- | --- | --- |
| House | 23 | Mandi Ballinger | 2025-10-12 | Bill Fincher |
| House | 94 | Karen Bennett | 2026-01-01 | Venola Mason |
| House | 106 | Shelly Hutchinson | 2025-09-05 | Akbar Ali |
| House | 121 | Marcus Wiedower | 2025-10-28 | Eric Gisler |
| House | 130 | Lynn Heffner | 2026-01-05 | Sheila Nelson |
| House | 177 | Dexter Sharper | 2026-03-09 | Alvin Payton |
| Senate | 7 | Nabilah Parkes | 2026-03-13 | Adrienne White Carden |
| Senate | 18 | John F. Kennedy | 2025-12-09 | Steven McNeel |
| Senate | 21 | Brandon Beach | 2025-05-05 | Jason T. Dickerson |
| Senate | 35 | Jason Esteves | 2025-09-10 | Jaha Howard |
| Senate | 53 | Colton Moore | 2026-01-13 | Lanny Thomas |

⚠ **THE MAP PAYLOAD'S "`DateVacated` NULL ON ALL 236" WAS NOT A STALENESS SIGNAL AFTER ALL.** It is
null because that payload only ever carries the sitting member; departures live in the other endpoint.
The suspicion was still right to raise — it is what made the second source non-optional — but the
resolution is that the two agree, and the LIST is the one that documents the 11 predecessors.

### 🔴 There is NO term_start to be had. Georgia publishes none.

A member page carries name, district, party, city, capitol and district addresses, staff, birthday
and spouse. It carries **no service-start of any kind** — no "elected in YYYY", no term window, no
assumed-office date. Checked on a first-term member (Bill Fincher, House 23, arrived after a
2025-10-12 vacancy): the entire About block is "Birthday / Spouse".

So GA-2 cannot do what FL-2 did, which was to lift continuous occupancy from each member's own
"Legislative Service" line. **The honest write is an open-ended term with
`start_precision => 'unknown'`** — the NC pattern — for all 236. Do not derive a date from the
2024 general election: that is the start of the current TERM, and `term_start` is the start of
continuous occupancy, which re-election does not end.

⚠ The 11 `dateVacated` values are the **predecessor's end**, not the successor's start. They are
worth recording as prose, but they do not license a `term_start` for the person who replaced them.

### 🟢 The portraits are full-resolution, and the state says so

Every member page carries a **"High Resolution Photo"** link, and it is the portrait URL with the
`?size=mpSm` query simply removed. Measured on `fincher-bill-5092.jpg`:

| URL | Dimensions | Bytes |
| --- | --- | --- |
| `...jpg?size=mpSm` | 90 x 120 | 5,401 |
| `...jpg` | **1688 x 2283** | 256,576 |

That is 19x linear and 47x the bytes — the Ballotpedia `thumbs/200/300/` lesson in a different dress,
and it was worth the two minutes to measure rather than assume. 1688x2283 is far above the 600x750
headshot target, so stage 5 needs no upscaling for the legislature. The roster payloads give a
portrait URL for all 236, so **GA's stage-5 legislative half is already sourced.**

### 🔴🔴 The change-check found a real one: SENATE DISTRICT 12 IS VACANT

Third party: `data.openstates.org/people/current/ga.csv`, diffed against the reconciled roster.

⚠ **THE FIRST RUN OF THAT DETECTOR WAS BROKEN AND SAID SO BY BEING UNIFORM.** It named the
column `current_org_classification`; the CSV calls it `current_chamber`, so every row was skipped,
the third-party side came back EMPTY, and the diff reported **all 236 of ours** as missing from
Open States. A uniform answer is a broken detector, not a finding. The script now asserts a
**positive control** — at least 150 House and 45 Senate rows parsed — and refuses to report
otherwise.

Once fixed, the diff came back at **34 cosmetic name-form differences and exactly ONE substantive
hit**:

| | House | Senate |
| --- | --- | --- |
| ours | 180 | 56 |
| Open States | 180 | **55** |
| seat mismatches | 0 | 0 |

Every other flag pairs district-for-district and is a name form: `Tyler Paul Smith` / `Tyler
Smith`, `Reynaldo "Rey" Martinez` / `Rey Martinez`, `Noel Williams, Jr.` / `Noel Williams`,
`Anissa Jones` / `Nissa Jones`, and three where our LEGAL first name differs from the published
one (`Charles`/`Chuck` Martin, `Justin`/`Jutt` Howard, `Mary`/`Mary Margaret` Oliver).

**Senate District 12 has no counterpart at all, and Open States carries no Georgian named Sims.**

> Georgia State Sen. Freddie Powell Sims announced on 2026-03-23 that she would resign, her
> husband being gravely ill. Three candidates then contested the seat.
> — WALB, Albany Herald, Early County News

**legis.ga.gov still lists her as the sitting senator, with no `dateVacated`.** The chamber's own
record is stale by five months. Seating from it would have put a departed senator in a live seat —
**the TX SD-22 Birdwell failure, exactly the thing the change-check rule exists to stop.**

⚠ `senate.ga.gov` now redirects to `legis.ga.gov/members/senate`, so there is **no separate
chamber roster to arbitrate with**. The arbiter here had to be the press plus the third party.

**Disposition: SD-12 is created as an office, flagged `is_vacant`, and seated with nobody.**
`vacant_since` is left NULL — what is documented is the ANNOUNCEMENT of a resignation, no
authoritative effective date was published, and CLAUDE.md forbids inventing one.

### 🔴 Four names already in production; only TWO are the same person

| Roster name | Existing row | Verdict |
| --- | --- | --- |
| Houston Gaines | `-131001` | **REUSE.** GA House D120, and that row is the GA-10 US House candidate whose nomination he won in May 2026. Already carries 6 compass answers. |
| Jasmine Clark | `-131301` | **REUSE.** GA House D108, and that row is the GA-13 candidate. 8 compass answers. |
| John Carson | `-810030` | **DIFFERENT PERSON — a COLORADO state senator.** New row. |
| Kim Jackson | `-364328` | **DIFFERENT PERSON — a UTAH COUNTY treasurer.** New row. |

Two of four. A name-based guard would have seated a Colorado senator and a Utah treasurer in the
Georgia General Assembly — the Robert Nash failure, caught before it happened.

### 🟢 No name parsing is needed at all

Georgia publishes structured name parts (`first` / `last` / `middle` / `suffix` / `nickname`), so
`first_name` and `last_name` come from the source rather than from splitting a display string.
`splitName()` is not involved, and the four shapes that would have broken it —
`Reynaldo "Rey" Martinez`, `Noel Williams, Jr.`, `Regina Lewis-Ward`, `Holly El-Mahdi` — never
need splitting.

### The two migrations, written and dry-run

Generated by `scripts/gen-ga-legislature-migrations.mjs` from `data/ga-legislature-roster.json`,
as `CC_wip_*.sql` — the number is taken LAST, at apply time, re-counted against `origin/master`.

| Half | Contents |
| --- | --- |
| structure | 2 chambers + **236 offices** (180 House, 56 Senate); SD-12 flagged `is_vacant`, `vacant_since` NULL |
| occupancy | **233 new politicians + 2 reused = 235 seats**, every term OPEN-ENDED at `start_precision 'unknown'` |

⚠ **THE OCCUPANCY HALF CANNOT BE DRY-RUN ALONE** — its offices do not exist yet. Both halves ran
as ONE transaction ending in ROLLBACK, with the stream asserted to hold exactly one `BEGIN`, one
`ROLLBACK` and **zero `COMMIT`** before it was sent. That is the FL-6 method.

```
BEGIN
INSERT 0 1 / INSERT 0 1          -- the two chambers
INSERT 0 236                     -- offices
UPDATE 1                         -- SD-12 flagged
NOTICE: OK: 236 Georgia legislative offices (180 House, 56 Senate); SD-12 flagged vacant
INSERT 0 233 / INSERT 0 235      -- people, then terms
NOTICE: OK: 235 Georgia legislators seated across 236 offices; SD-12 vacant
ROLLBACK
```

Rollback confirmed to have reverted: production still reads 4 Georgia chambers, **0** legislative
offices and **0** rows in the `-1330256..-1330001` band.

### ✅ GA-2 applied 2026-09-01 — `CC_0025` structure, `CC_0026` occupancy

Numbers taken LAST, re-counted against `origin/master` at apply time: `CC_0024` was the highest
claimed across all 77 remote refs, so these are `CC_0025` and `CC_0026`. `check:migrations` green,
2 added, no collisions.

| Half | Applied |
| --- | --- |
| `CC_0025` structure | 2 chambers, **236 offices** (180 House, 56 Senate), SD-12 flagged `is_vacant` |
| `CC_0026` occupancy | **233 new politicians + 2 reused**, **235 terms**, all open-ended at `'unknown'` |

### Verified in production

| Check | Result |
| --- | --- |
| Offices / seated | House **180 / 180**; Senate **56 / 55**, 1 flagged vacant |
| `offices_missing_terms` | 820 → **821** total, 165 → **166** flagged, **unflagged unchanged at 655** — the whole point of flagging SD-12 in the structure half |
| SD-12 | `is_vacant` true, `vacant_since` NULL, holder NULL |
| The two reuses | Gaines `-131001` and Clark `-131301` each hold exactly **1** seat; no duplicate row created |

🟢 **The acceptance probe returns a real person at all three Knight cities** — two of the four
answers now resolve, which is what stage 2 exists to deliver before any city wave runs:

| City | State House | State Senate |
| --- | --- | --- |
| Columbus | HD-137 Debbie Buckner | SD-15 Ed Harbison |
| Macon-Bibb | HD-145 Tangie Herring | SD-26 David Lucas |
| Milledgeville | HD-149 Floyd Griffin | SD-25 Rick Williams |

### What is left before GA-3

### What is left before GA-2 applies

### What GA-2 still needs before it writes

1. **A change-check for every seat**, against a date later than these payloads. Eleven seats turned
   over in the last year, so the base rate of change here is high.
2. Structure migration (236 offices on the districts loaded by GA-1), then occupancy migration
   (236 people, open-ended terms). Take the migration number LAST, and re-count it against
   `origin/master` rather than any file.
3. `splitName()` behaviour on `Reynaldo "Rey" Martinez`, `Williams, Jr.`, `Regina Lewis-Ward` and
   `Holly El-Mahdi` — four shapes in one roster that the FL/Nashville waves each had to widen for.

## GA-3 — Milledgeville + Baldwin County, PLANNED 2026-09-01

Plan: [`2026-09-01-knight-ga-wave-3-milledgeville-baldwin.md`](../../docs/superpowers/plans/2026-09-01-knight-ga-wave-3-milledgeville-baldwin.md) ·
Roster: [`backend/data/seed-milledgeville-2026/ROSTERS.md`](../../backend/data/seed-milledgeville-2026/ROSTERS.md)

**18 offices, 18 people, 0 vacancies** — 7 city (Mayor at-large + 6 single-member districts) and
11 county (5 single-member commission districts with **no at-large seat**, plus 6 officers).
Two boundary loads `X0042`/`X0043`, three migrations `CC_0027`–`CC_0029`. Pre-state probe at
Milledgeville City Hall scores **2 of 4** — HD-149 Floyd Griffin and SD-25 Rick Williams resolve;
Baldwin County has zero offices and Georgia has **zero `LOCAL` districts**.

🔴🔴 **THE OBVIOUS COUNCIL-DISTRICT SERVICE IS THE SUPERSEDED ONE, AND ONLY ONE DISTRICT SAYS SO.**
The city's own `City Council Districts (2025)` layer is a post-2020 plan carrying `Pop`/`DX_DEV`.
Baldwin County's `ElectionGeography` copy is 2021–2022. Tested at all six interior points, **five
agree and District 4 does not** — its point falls in the county copy's District 1 — while the
symmetric difference is non-zero on every district (D1 alone is 0.99 of ~20.4 sq mi). Three spot
checks would have passed on the wrong map. **Load the city's layer.**

🔴🔴 **A LAYER TITLED "(2025)" CAN STILL CARRY A PRE-2025 ROSTER.** That same city layer's
`CouncilMem` field reads Walden / Reynolds / Chambers — the three predecessors. Geometry vintage and
attribute vintage are different questions about the same row.

🔴 **`EditDate` IS PER ROW, AND IT IS THE TELL.** The county's layer is correct on all 5 commissioners
(edited 2026-04-21) and wrong on 3 of 6 city seats (edited 2021–2022). The same layer still names
Joe Biden as President and carries two contradictory US House rows.

🟢🟢 **THE SECRETARY OF STATE PUBLISHES CERTIFIED *MUNICIPAL* RESULTS, AND THEY SETTLED EVERY SEAT.**
`results.sos.ga.gov/results/public/api/elections/baldwin-county-ga/{electionId}/data` carries the
**November 4, 2025 Municipal General** as well as the 2024 general. ▶ **Look for this first in
Columbus and Macon** — nothing in Florida used this route. The election ids come from
`/api/jurisdictions/Georgia`; the county short name is `<county>-county-ga`; a county with no contest
in an election returns **HTTP 204**, which is itself the proof that no runoff was held.

⚠ **The Municode charter is codified through JANUARY 2014** and still says "MAYOR AND ALDERMEN" — it
describes no six-district council. Two questions stay open because of it: whether the Mayor votes on
the council, and why District 2 was seated on exactly 50.0% with no runoff (plurality is the likely
answer, unconfirmed). Municode's API 401s curl **and** an in-page `fetch()`; render the SPA and read
the DOM.

## ▶️ WHERE THIS STOPPED — read this first

Stages 1 and 2 are **applied and merged**: `CC_0025` geography loader entry (GA-1 used the loader,
not a migration), `CC_0025`/`CC_0026` the legislature. Next free slot is **`CC_0027`**, and next free
private MTFCC is **`X0042`** — ⚠ re-count both against every remote ref, this file has been wrong before.

**GA-3 Task 1 is APPLIED.** Branch `knight/ga-3-milledgeville`. `X0042` holds the **6 Milledgeville
council district boundaries**, loaded 2026-09-01 by `scripts/load-milledgeville-council-boundaries.ts`
from the CITY's own 2025 plan. All seven gates passed on the dry run before any write; the loader is
idempotent (re-run inserts 0); `check:child-county` **stale 0**; `check:reachability` at or below
baseline (5/17/37 against 5/17/38); `offices_missing_terms` **unchanged at 821/166/655**.
⚠ No `districts` rows yet — `CC_0027` creates those. GA still holds **0 `LOCAL` districts**.

**▶ NEXT: Task 2** — load `X0043`, the 5 Baldwin County commission districts, from
`ElectionGeography_dashboard_…/FeatureServer/2` filtered `electedoffice='County Commissioner'`.

What is already on disk and should NOT be re-fetched:

| Path | What |
| --- | --- |
| `backend/data/seed-ga-2026/` | the TIGER zips, both state map payloads, both member-list payloads, and the probe scripts that produced every number in this file. Untracked, on purpose. |
| `backend/data/ga-legislature-roster.json` | the reconciled 236, committed |
| `scripts/build-ga-legislature-roster.mjs` | rebuilds it, `--check-openstates` runs the change-check |
| `scripts/gen-ga-legislature-migrations.mjs` | regenerates both GA-2 migrations as `CC_wip_*` |

🔴 **The two legis.ga.gov payload endpoints 401 both curl and an in-page `fetch()`.** To refresh
them, load the page in a browser and read the response bodies out of the network log. The roster
builder deliberately does not fetch.

🔴 **Carry forward into GA-3/GA-4:** Columbus/Muscogee and Macon-Bibb are CONSOLIDATED, so stage 4
drops the county commission and keeps the separately elected county officers — confirmed from each
charter, inherited from nothing. Milledgeville is an ordinary city in Baldwin County.

🟢 **Stage 5's legislative half is already sourced**: a full-resolution portrait URL for all 236,
which is the payload URL with `?size=mpSm` removed.

⚠ **Re-check SD-12 before GA-5.** It is flagged vacant with a NULL `vacant_since`. A successor may
be seated after the November 2026 general, and the seat then needs a real `term_start`.

## The Georgia county-officer template, ruled 2026-09-01 (Cantrell)

Baldwin puts **thirteen** countywide offices on the ballot besides the commission. GA-3 seats six:

| Seated | Why |
| --- | --- |
| Sheriff, Clerk of Superior Court, Probate Judge, Tax Commissioner | named as county officers in **Ga. Const. Art. IX, Sec. I, Par. III** |
| Coroner, Surveyor | statutory county officers, and Baldwin genuinely elected both countywide in 2024 |

| Excluded | Why |
| --- | --- |
| Solicitor General | a prosecutor — the **FL-5 rule** against Palm Beach's State Attorney |
| Chief Magistrate | judicial branch, **Ga. Const. Art. VI**, as Florida excluded its county judges |
| Ocmulgee Circuit DA + 5 Superior Court judges | **MULTI-COUNTY circuit**, the FL-5 ruling exactly |
| School board, Piedmont Soil and Water supervisor | spec §11 |
| GMC Board of Trustees (6 districts, same 2025 ballot) | a **state junior college's** board, not a city office |

⚠ **Georgia's probate judge is a county officer, not a judicial-branch officer** — that is why it is
in and the magistrate is out. The line is the constitution's, not ours.

## Open questions for GA-4 / GA-5

- Which county officers are **separately elected** in Columbus-Muscogee and Macon-Bibb. Spec §3.2
  says consolidation merges the legislative body only — **confirm from each charter, inherit nothing**,
  including from the Baldwin template above.
- Council structure for both: district vs at-large split, and whether the mayor sits on the body.
- ▶ Try the SOS certified-results API first for both. It answered every Milledgeville seat.
- ⚠ Does Georgia's Reapportionment Office publish certified **local** plans in fetchable form? It
  would give a second independent map for county commission districts, which Baldwin did not have.
