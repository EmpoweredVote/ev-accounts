# Georgia — slice 2 notes

**Program tracker:** [`PROGRAM.md`](./PROGRAM.md) · **Spec:** [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

Jurisdictions: **Columbus** (Muscogee), **Macon** (Bibb), **Milledgeville** (Baldwin).

| Wave | Scope | Status |
| --- | --- | --- |
| GA-1 | TIGER `place` + `sldu` + `sldl`, FIPS 13 | ✅ **APPLIED 2026-08-31** |
| GA-2 | Legislature: 180 House + 56 Senate | ✅ **APPLIED 2026-09-01** (`CC_0025`, `CC_0026`) |
| GA-3 | **Milledgeville + Baldwin County** | ✅ **ALL 5 STAGES 2026-09-01** — `X0042`/`X0043`, `CC_0027`–`CC_0029`, 18 seats, 14/18 headshots, banner live |
| GA-4 | **Columbus + Muscogee County** | ⏸ **MEASURED + PLANNED 2026-09-01, NOT APPLIED** — 16 seats, R4 ruled: exclude both municipal-court offices |
| GA-5 | Macon-Bibb | — |

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

### ✅ What GA-2 needed before it wrote — all three satisfied, kept as the record

⚠ This block previously carried **three** headers, two of them empty
("What is left before GA-3", "What is left before GA-2 applies"), left behind when the GA-2 session
rewrote around them. Collapsed 2026-09-01. An empty heading reads as an unfinished section.

1. **A change-check for every seat**, against a date later than these payloads. Eleven seats turned
   over in the last year, so the base rate of change here is high.
2. Structure migration (236 offices on the districts loaded by GA-1), then occupancy migration
   (236 people, open-ended terms). Take the migration number LAST, and re-count it against
   `origin/master` rather than any file.
3. `splitName()` behaviour on `Reynaldo "Rey" Martinez`, `Williams, Jr.`, `Regina Lewis-Ward` and
   `Holly El-Mahdi` — four shapes in one roster that the FL/Nashville waves each had to widen for.

## GA-3 — Milledgeville + Baldwin County, ✅ APPLIED 2026-09-01

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

**GA-3 TASKS 1 AND 2 ARE APPLIED.** Branch `knight/ga-3-milledgeville`. Both boundary layers are in
production, loaded 2026-09-01, each idempotent (re-run inserts 0):

| Code | Rows | Loader | Source |
| --- | --- | --- | --- |
| `X0042` | **6** Milledgeville council districts | `scripts/load-milledgeville-council-boundaries.ts` | the **CITY's** own 2025 plan |
| `X0043` | **5** Baldwin commission districts | `scripts/load-baldwin-commission-boundaries.ts` | the county's `ElectionGeography` layer, single publisher |

🟢 **BOTH TIERS NOW RESOLVE THROUGH OUR OWN ROWS, AND THE NUMBERS ARE UNRELATED OVER THE SAME GROUND:**

| Address | City council | County commission |
| --- | --- | --- |
| Milledgeville City Hall, 119 E Hancock St | **D2** | **D3** |
| Baldwin County Govt Building, 1601 N Columbia St | **D5** | **D1** |

⚠ **Both buildings are inside the city limits.** Four different district numbers across two addresses
a mile apart is the confusion this wave is most exposed to, so each address is a control point in
BOTH loaders with the other tier's answer written beside it.

🔴 **A MISLABELLED CONTROL POINT IS WORSE THAN A MISSING ONE — IT READS AS COVERED.** Task 1 shipped
with a negative control labelled "Rural Baldwin County" at `(-83.12, 33.16)`. Resolved against TIGER
`G4020` while measuring Task 2, that point is in **HANCOCK County `13141`**. The gate passed, and for a
true reason — it is outside the city either way — but it was not testing its label, so the one case
that actually discriminates a city layer from a county layer, *inside Baldwin and outside
Milledgeville*, was never tested. Both loaders now carry every negative control **resolved against
TIGER and labelled with the county it is really in**.

🔴 **X0043 HAS ONE PUBLISHER, WHICH IS AN ACCEPTED LIMITATION.** The county's dedicated Commissioner
Districts app resolves to `ElectionGeography_CommissionerDistrictsView` — a VIEW over the same rows —
so Task 1's two-map comparison is impossible here. Three gated lines of evidence stand in its place:
`CreationDate` **2022-02-08** on all five (on schedule for a 2020-cycle Georgia county redistricting)
with `EditDate` **2026-04-21** (after the certified 2024 election); the five tile TIGER Baldwin to
**0.0158 of 268.2759 sq mi**, 0.006%; and all five keyed districts returned a commissioner in the
certified 2024 count. 🔴 **GATE 1 asserts freshness PER ROW, because in this very layer the city rows
are wrong on 3 of 6 seats and the President is still Joe Biden.**

⚠ **GATE 0 exists because the filter is load-bearing**: unfiltered, that layer returns **35 rows**
spanning every office in the county. A dropped `WHERE` clause would sail through every later gate that
only inspects districts keyed 1..5.

Gates after both applies: `check:child-county` **stale 0** (children 7,782 — unchanged, confirming an
`X` load needs no matview refresh); `check:reachability` **5/17/37** against baseline 5/17/38;
`check:migrations` and `check:occupancy` green; `offices_missing_terms` **unchanged at 821/166/655**.
⚠ No `districts` rows yet — GA still holds **0 `LOCAL` districts**. `CC_0027`/`CC_0029` create them.

## GA-3 Task 3 — the generator, DRY-RUN CLEAN 2026-09-01, NOT APPLIED

`scripts/gen-ga3-milledgeville-migrations.mjs` reads the committed
`data/ga3-milledgeville-roster.json` and emits three `CC_wip_*.sql`. ⚠ **The `CC_wip_*` files stay
UNTRACKED** — no `CC_wip` file has ever been committed in this repo; the convention is rename + apply
+ commit in one go, so they are regenerated at apply time.

| Half | Emits | Dry run |
| --- | --- | --- |
| city structure | 1 government, 2 chambers, **7 districts**, **7 offices** | ✅ `7 district(s) created, 1 government, 2 chambers, 7 offices` |
| city occupancy | **7 politicians, 7 terms**, all open-ended `'unknown'` | ✅ `7 politicians, 7 seated across 7 offices, 0 vacancies` |
| Baldwin (one migration) | 1 government, 2 chambers, **5 districts**, **11 offices + 11 people + 11 terms** | ✅ `5 district(s) created … 11 offices`; `11 politicians, 11 seated, 0 vacancies` |

⚠ **The city occupancy half cannot be dry-run alone** — its offices do not exist yet. Both city halves
ran as ONE transaction, audited **before sending** to hold exactly one `BEGIN`, one `ROLLBACK` and
**zero `COMMIT`**. Both rollbacks were then confirmed to have reverted: production still reads **0** GA
`LOCAL` districts, **0** `X0042`/`X0043` districts, **0** rows in `-1331018..-1331001`, **0**
governments and **0** offices.

🔴🔴 **`district_type` DIFFERS BY TIER, AND THE FIRST DRAFT GOT THE COUNTY WRONG.** City districts are
**`'LOCAL'`** (`CC_0008`); county districts are **`'COUNTY'`** (`CC_0010`). Reading the county
precedent rather than generalising the city one is what caught it.

🔴🔴 **THE WIDE DISTRICT IS CREATED FOR THE CITY AND ONLY *ASSERTED* FOR THE COUNTY.** GA-1 loaded the
place **boundary** `1351492`/`G4110` but created no place **district**, so the citywide district is
inserted here. The TIGER county load already created `13009`/`G4020` as a `COUNTY` district, so
inserting it again would put a second district row over the same ground. The county pre-flight now
fails hard if that row is missing — the six officers have nowhere to sit without it.

🟢 The generator refuses before writing a line of SQL if the roster drifts: 18 offices, 18 unique ids
matching the declared band exactly at both ends, every office naming a known chamber, no duplicate
seat key, and **no party field anywhere** — a generator is exactly where party leaks back in.

✅ **GA-3 APPLIED 2026-09-01 — `CC_0027`, `CC_0028`, `CC_0029`.** Numbers taken LAST: `CC_0026` was the
highest slot across all 81 remote refs at apply time, `check:migrations` reported **3 added**, no collisions.

| Migration | Applied |
| --- | --- |
| `CC_0027` city structure | 1 government, 2 chambers, **7 districts**, **7 offices** |
| `CC_0028` city occupancy | **7 politicians, 7 terms**, all open-ended `'unknown'` |
| `CC_0029` Baldwin County | 1 government, 2 chambers, **5 districts**, **11 offices + 11 people + 11 terms** |

### Verified in production

| Check | Result |
| --- | --- |
| Milledgeville City Council / Office of the Mayor | **6/6** and **1/1** |
| Baldwin Board of Commissioners / Elected Officials | **5/5** and **6/6** |
| `offices_missing_terms` | **unchanged at 821 / 166 / 655** |
| `check:reachability` | **5/17/37** against baseline 5/17/38 |
| GA local/county offices with no term row | **0** |
| All three migrations re-run | clean, second pass seats **0** |

🟢🟢 **ALL FOUR REQUIRED ANSWERS PASS AT MILLEDGEVILLE CITY HALL** — council D2 Arlene Simmons,
commission D3 Sammy Hall, HD-149 Floyd Griffin, SD-25 Rick Williams. The probe scored **2 of 4**
before the apply, which is why it was run first.

🟢 **A SECOND ANCHOR IS WHAT PROVES THE TIERS WERE NOT CROSSED.** The Baldwin County Government
Building is also inside the city and returns **city D5 / commission D1** — different numbers from
City Hall's D2/D3 on *both* tiers. A wave that had crossed the two tiers would still pass probe 1a.

🟢 **PER-DISTRICT POSITIVE CONTROL, BECAUSE A QUIET GATE IS NOT EVIDENCE.** `check:reachability`
takes **no per-jurisdiction probe list** — it sweeps every addressable district, so "nothing
regressed" cannot by itself distinguish *swept and clean* from *not swept*. All 11 district seats were
therefore tested individually at their own interior point: **1 holder each, 11 of 11.**
⚠ The plan said to "add a `place:milledgeville` probe to the reachability gate". That was wrong about
the mechanism, and the correction is recorded rather than quietly dropped.

⚠ **THE PROBE JOIN'S mtfcc PAIRING WAS DEMONSTRATED, NOT ASSERTED.** Run unpaired, City Hall returns
three WRONG officials: **Todd Jones** (HD-25, reached through the SD-25 polygon), **Will Wade** (HD-9)
and **Nikki Merritt** (SD-9), both reached through the **Baldwin County** polygon. Probe 2 of
`scripts/verify-milledgeville-baldwin-probes.sql` keeps that visible in the log forever.

🔴🔴 **`district_type` DIFFERS BY TIER, AND THE GENERATOR'S FIRST DRAFT GOT THE COUNTY WRONG.** City
districts are `'LOCAL'` (`CC_0008`); county districts are `'COUNTY'` (`CC_0010`). Reading the county
precedent instead of generalising the city one is what caught it.

🔴🔴 **THE WIDE DISTRICT IS CREATED FOR A CITY BUT ONLY *ASSERTED* FOR A COUNTY.** GA-1 loaded the
place **boundary** `1351492`/`G4110` and created no place **district**, so the citywide district is
inserted. The TIGER county load already made `13009`/`G4020` a `COUNTY` district, so inserting it
again would put a second district row over the same ground. `CC_0029`'s pre-flight fails hard if that
row is missing — the six officers have nowhere to sit without it.

**▶ NEXT: GA-3 stage 5 (assets)** — 18 headshots and one Milledgeville banner. Then **GA-4**:
Columbus/Muscogee and Macon-Bibb, both CONSOLIDATED.
▶ Carry forward: re-check the Milledgeville mayor's council vote and District 2's exactly-50.0% win
if a current charter ever surfaces; both are recorded as open in `ROSTERS.md`, not resolved.

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

## GA-3 stage 5 — banner: ✅ OPTION E APPLIED 2026-09-01

Proof: [Milledgeville Banner Certification](https://claude.ai/code/artifact/d1cc601b-075a-4e38-8130-a87a51783c87).
Every frame is the full 1700x540 asset in a CSS box at the production ratio with `object-fit: cover`,
so the browser performs the real crop. Composed assets are in `backend/.tmp-ga3-banner/` (untracked):
`asset-E.jpg`, `asset-F.jpg`, `asset-A.jpg`, plus `_sources.json` with URL/licence/author per source.

🔴 **THE BOX IS TWO BOXES, AND THE NUMBERS COME FROM `SectionBanner.jsx` BANNER_ASPECT** — not guessed:

| Box | Ratio | Height | Asset visible |
| --- | --- | --- | --- |
| mobile | `13 / 4` | 120px @390 | **96.9%**, rows 8-531 of 540 |
| desktop `md`+ | `6 / 1` | 216px @1296 | **52.5%**, rows **128-411** of 540 |

### Shortlist

| ID | Subject | Source | Licence |
| --- | --- | --- | --- |
| **E** | Old State Capitol / GMC, State House Square | 4080x3072 (1.33:1) | **CC0**, Clifflandis |
| **F** | Sanford & Napier Halls, Georgia College, W Greene St | 3715x1400 (**2.65:1**) | **CC BY-SA 2.0**, Ken Lund |

✅ **Cantrell chose E.** Uploaded as `cities/milledgeville.jpg` (1700x540); the live object was verified
**byte-identical** to the certified asset, not assumed. Registered in the **essentials** repo as the
program's **first `GA`-scoped `CURATED_LOCAL` key**, `match:'exact'` — PR
[essentials#112](https://github.com/EmpoweredVote/essentials/pull/112). Tests 23/23, ESLint clean.

Resolution verified in both directions, negatives included: `Milledgeville GA` resolves;
`Milledgeville IL`, `Milledgeville TN` and `Old Milledgeville GA` all resolve to **nothing**, so
state-scoping and the exact-match guard both bite. Columbus and Macon correctly resolve to nothing.

⚠ F (Georgia College, native 2.65:1) was the recommendation and remains the runner-up on record if E
is ever revisited. Overwriting a bucket object does **not** purge the CDN, so any replacement must be
**versioned**, as `states/FL-v2.jpg` was.

### 🔴🔴 THE OBVIOUS SUBJECT FAILS THIS BOX, AND AN ANCHOR SWEEP IS WHAT PROVED IT

The **Old Governor's Mansion** is Milledgeville's signature building and the natural pick. Its source
is 1.42:1, so the 3.148:1 crop already discards 55% of the rows and the desktop band keeps 52.5% of
what remains — **about a quarter of the original**. Swept at anchors 0.30 / 0.45 / 0.60 on **two**
different mansion photographs, every result is **a wall of windows**: pediment cropped off the top,
ground off the bottom. That is the FL-7 failure exactly — composed straight to 6:1, a tall building
renders as its own middle. ▶ **A frontal building portrait is not a banner subject. Prefer a
horizontally arranged subject, and prefer a source already near 3:1.** This applies to Columbus and
Macon next.

### 🔴 The best-licensed sources were unusable for a reason no licence check catches

The two widest, most permissive sources — Historic American Buildings Survey, federal work,
unambiguously public domain, **1.62:1**, which would have survived the desktop band better than
anything else found — measured **100% greyscale**. Archival black and white beside a shelf of colour
banners reads as a fault, not a choice. **Test colour, not only licence and ratio.**

### Where it ships, which is NOT this repo

⚠ `CURATED_LOCAL` lives in **`src/lib/buildingImages.js` in the `essentials` repo** (branch `main`),
so the banner is a **separate PR there** plus a `cities/milledgeville.jpg` upload to the shared bucket.
⚠ **No key is scoped `GA` yet** — Milledgeville is the first, and it must be declared
**`match:'exact'`**: FL-7 found substring matching handed one city's banner to seven others.
⚠ Attribution travels in the registry comment, as the existing entries do. Overwriting a bucket object
does **not** purge the CDN, so a replacement must be versioned.

---

## GA-4 — Columbus + Muscogee County, ⏸ MEASURED AND PLANNED 2026-09-01, NOT APPLIED

Plan: [`2026-09-01-knight-ga-wave-4-columbus-muscogee.md`](../../docs/superpowers/plans/2026-09-01-knight-ga-wave-4-columbus-muscogee.md) ·
Roster and every measurement: [`backend/data/seed-columbus-2026/ROSTERS.md`](../../backend/data/seed-columbus-2026/ROSTERS.md) ·
Brief: <https://claude.ai/code/artifact/3154e2c0-b658-4dcb-a253-3e99b432fa1d>

**16 offices, 16 people, 0 vacancies** — 11 city, 5 county. Branch `knight/ga-4-columbus-muscogee`.
Next free slots re-counted against all 82 remote refs at the start of the session: **`CC_0030`** and
**`X0044`** (`X0043` is the max in production, checked against `geofence_boundaries`, not a file).

### ✅ RULING R4 DECIDED 2026-09-01 (Cantrell): EXCLUDE BOTH MUNICIPAL-COURT OFFICES

Muscogee elects a **Municipal Court Clerk** (Reginald Thompson) and a **Municipal Court Judge**
(Steven D. Smith) countywide, both on the certified 2024 ballot. **Neither is seated.** A municipal
court is a **Ga. Const. Art. VI** court, which is the same line Baldwin drew when it excluded the Chief
Magistrate; the Clerk of Superior Court is seated only because **Art. IX** names it a *county officer*
and the Municipal Court Clerk is not in that list. **The wave is 16 offices**, sub-range
`-1331020 .. -1331035`.

⚠ The counter-argument — that these are offices Muscogee voters genuinely elect countywide — is
recorded rather than dropped. **The next consolidated city-county will raise it again**: Macon-Bibb at
GA-5, then Philadelphia and Lexington.

### 🔴🔴 THE CERTIFIED-RESULTS ROUTE RUNS OUT HERE, AND SILENTLY

GA-3's handoff said to try the SOS API first because it settled all 18 Milledgeville seats. It works
for Muscogee and it is **incomplete**: Columbus municipal contests appear **only from 2026**, absent
from 2018, 2020, 2022 and 2024, though the charter puts half the council on each of the 2022 and 2024
ballots. Every ballot item in both 2022 payloads was listed by hand to be sure. **So the portal cannot
seat the five even-numbered districts at all** — a wave inheriting Baldwin's experience would have
called them vacant. ▶ Enumerate elections from `/api/jurisdictions/muscogee-county-ga` (36 back to
2012); a **guessed slug returns HTTP 204**, indistinguishable from "no such contest".

### 🔴🔴🔴 TWO COUNCIL-DISTRICT LAYERS THAT INVERT

`[10] Council Districts` and `[3] Council/School Board Districts` both return 8 polygons and are
**different maps** — District 8 differs by 3.639 sq mi, 41% of itself. The arbiter is `[8] Elections
Combinations`, the precinct×district table the county builds ballots from: dissolved and compared, it
matches **layer 3 at 0.000 sq mi on all eight** and layer 10 on none.

But layer 3's roster names **Byron Hickey** in D1, the appointed predecessor gone since May, while
layer 10 names **Simi Barnes**, who actually holds it. **THE LAYER WITH THE FRESH ROSTER HAS THE
SUPERSEDED GEOMETRY.** GA-3 learned geometry vintage and attribute vintage are different questions
about one row; here they **invert**, so either layer taken whole gets one answer wrong. Layer 10 is
the trap — named more precisely, listed second, roster right, every boundary wrong.
⚠ Layer 3's *school-board* field is fresh (2026 winners) while its *council* field is stale. Freshness
is not a property of a layer, nor even of a row. **Read it per field.**

### 🔴 74.79 sq mi of the county is in no council district, correctly

Columbus city and Muscogee County are the same 221.011 sq mi. The 8 districts cover **146.24**. The gap
is **one contiguous piece** plus 52 slivers ≤0.002 sq mi, and layer 8 carries **5 rows reading
`Precinct N/A; … Council & School Board N/A`** totalling 74.767 sq mi — symmetric difference against
the gap **0.770 sq mi**. The county itself records that ground as belonging to no precinct and no
council district; it is Fort Benning. FL-5's Atlantic in a new dress, except the excluded ground is
**land** and the authority is **the county's own ballot record**. 🔴 **Gate the structure, not full
coverage** — a coverage gate fails on correct data.

### 🔴🔴 FOUR OF THE SIX PEOPLE COLUMBUS ELECTED IN 2026 DO NOT HOLD THE OFFICE YET

Charter Sec. 3-100(2): terms commence in **January following the election**, *except* that a councilor
filling a vacancy serves only the remainder of the unexpired term. Two seats carried **both** a regular
and a **special** contest on the same 2026 ballot, and only the special winners started early:

| | Winner | Seated |
| --- | --- | --- |
| Mayor, D3, D7 (regular) | Hugley, Aaron, Zajac | **January 2027 — not seated** |
| D1 **special** | Simi Barnes | **2026-05-26** |
| D9 **special** | Cathy Cook | **2026-07-14** |

Seating the certified winners would have installed a mayor four months early and replaced two sitting
councilors. **A certified result is a fact about an election, not about who holds the seat today.**
D9 fell vacant when Judy Thomas resigned and the Council appointed John Anker 6-3 over the Mayor's
objection; D1 when the successor-by-appointment to Jerry "Pops" Barnes, Byron Hickey, chose not to run.
Simi Barnes is Pops Barnes' daughter. **Neither current holder was appointed** — both are
`special election`.

### Charter rulings

- **R1** — 10 members: **8 district + 2 at-large** (Posts 9, 10), Sec. 3-100(3). Both GIS layers
  return 8 polygons, confirming the at-large pair has no geometry. ⚠ The city's roster page numbers all
  ten "District N" and **would have produced two districts that do not exist**.
- **R2** — the **Mayor is `non_voting` with a required note**: Sec. 4-102 gives power "to preside … and
  to have a voice in its proceedings" but "the right to vote only in the case of a tie". Quorum is 6 of
  the 10 councilors, counting the Mayor out of the body. The Nashville Vice Mayor ruling exactly.
- **R3** — **Mayor Pro Tem is a parenthetical**, elected annually by the Council from its own members
  (Sec. 3-103(1)). Lawrence County / Baldwin R2.
- **R4** — **5 county officers.** Charter Art. VIII preserves four (Sheriff, Probate Judge, Tax
  Commissioner, Coroner); the Clerk of Superior Court is not in Art. VIII **because it does not need to
  be** — Art. IX names it a county officer and attaches it to a state court. 🔴 **Muscogee elects no
  Marshal and no Surveyor**, so **Baldwin's six-officer template does NOT transfer** — which is exactly
  what "confirm from the charter, inherit nothing" was there to catch.

### 🔴 `gis.columbus.gov` is COLUMBUS, OHIO

A search for Columbus council geometry surfaces it, with a plausible name and a live Redistricting
layer. Georgia's is `ccggisprod.columbusga.org`. The FEC-homonym class in GIS clothing.

### 🟢 Zero name collisions among all 16

Near misses are all different people: `David Cook` (TX), `Gary Davis`, `Gary Garrett` (UT),
`David Smith` (FL), `Gregory Smith` (OR), `David K. Thompson` (WI), `Glenn Thompson` (PA).

---

## 🔴🔴 GA-3 CORRECTION — Baldwin's Coroner retired on 2026-05-01 and GA-3 seated him anyway

`CC_0029` seated **John Gonzalez** from the SOS certified 2024 return. That return is correct and stays
correct. **He retired mid-term on 2026-05-01**; **Steve Chapple** holds the seat. Baldwin's own staff
directory has already dropped Gonzalez.

⚠ **This is the GA-2 SD-12 failure and it reached production.** GA-3's change-check was run against the
**sources** rather than the **seats** — every source agreed, and all of them predated the retirement.
**The check must ask "has this person left?", not "do my sources agree?"**

⚠ **Found by the headshot pass, not by a gate.** The Coroner is one of the four Baldwin officials still
owed a headshot; the portrait search surfaced the retirement notice. **A body's roster is a redundancy
check on occupancy** — third time it has paid.

🟢 A full re-check of **all 18** GA-3 seats against live sources found the Coroner is **the only** stale
one.

✅ **`CC_0030_baldwin_coroner_succession.sql` APPLIED 2026-09-01.** Number taken last, re-counted
against **all 84 remote refs**. Dry-run first (zero `COMMIT` in the sent stream; rollback confirmed
reverted), then applied. Verified: Chapple `-1331019` holds the seat, Gonzalez closed 2026-05-01
`retired`. **Re-runs clean** — second pass inserts 0 and skips the succession.
`offices_missing_terms` **unchanged at 821 / 166 / 655**.
Gonzalez `term_end` **2026-05-01** at `day` (stated outright); Chapple `term_start` 2026-05-02 at
**`month`** ("Thursday morning" is not a date) and `how_started` **`unknown`** — the nearby "appointed
the new coroner" sentence is about **Gonzalez** succeeding Wayne Brooks, not Chapple, and reading it as
Chapple's would be a misattributed citation. Chapple takes `-1331019`, so **GA-4 starts at `-1331020`**.

### The four Baldwin headshots — FIVE routes tried, all dead. Leave them clean-null.

Owed: Probate Judge **Todd A. Blackwell**, Tax Commissioner **Cathy Freeman Settle**, Surveyor
**James E. Smith**, and the Coroner — **now Steve Chapple, not John Gonzalez**. All four clean nulls,
which is the correct state: **a blank beats a link.**

| Route | Result |
| --- | --- |
| Ballotpedia | pages exist for all four, **no portrait on any** |
| County staff directory, aggregate | portraits only for the 5 commissioners + 3 staff officers |
| County per-person pages `/directory-listing/<name>` | **404** — the path a search surfaces is stale |
| County party sites (`baldwincountydems.org`, `baldwincountygagop.org`) | **do not resolve** |
| The Union-Recorder, 2026-05-14 | **a real photo exists and is REFUSED** — see below |

🔴 **THE ONE PHOTOGRAPH FOUND IS A LICENCE REFUSAL, NOT A WIN.** The coroner story carries
`5-13-Chappel-sworn-in.jpg`, captioned *"Blackwell swears in Steve Chapple … "* — **two of the four
owed officials in one frame**, and the unsized original is reachable by dropping `?resize=`. It is
still refused: the photo carries **no photographer credit**, and the paper runs a **"Purchase Photos"
storefront**, so its photography is a commercial product. The standing rule is that the **credit line
is the licence test** — the absence of a permissive credit is not permission. Recorded so the next
session does not re-find it and reason differently.

🟢 The directory's opaque `documentID`s independently re-confirm GA-3's off-by-one —
**Butts 238, Davis 239**, not district order.
