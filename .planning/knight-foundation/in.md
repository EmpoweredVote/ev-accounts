# Indiana — slice 4 notes

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · Spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

Jurisdictions: **Fort Wayne** (Allen County) and **Gary** (Lake County).

Stage 1 is closed — Indiana's TIGER polygons were loaded in February 2026, before the program
existed. Stage 2 is this wave.

## 🔴🔴 INDIANA'S LEGISLATURE IS PARTIALLY SEATED, AND ITS 18 SEATS HANG ON 18 FAKE CHAMBERS

Measured against production 2026-09-10, as `ev_api`.

Every earlier slice was one of two clean shapes: a legislature at 0 (FL, GA) or a legislature at
100% (CA, CO, NC). **Indiana is neither, and the difference is not only the count.** The 18 seats
that exist are modelled wrongly, so IN-2 is a **repair and a seed in one wave** — the Long Beach
shape, one tier up.

### What exists

| Measure | House | Senate |
| --- | --- | --- |
| TIGER polygons (`G5220` / `G5210`, `census_tiger_2024`) | **100** | **50** |
| `essentials.districts` rows | **12** | **6** |
| Offices | **12** | **6** |
| Seated (`count(och.politician_id)`) | **12** | **6** |
| Districts still to create | **88** | **44** |

150 polygons, 18 districts, 132 missing. The polygon half of stage 1 is genuinely complete: every
one of the 18 district rows pairs to a polygon on `(geo_id, mtfcc)`, and the 132 orphan boundaries
are orphaned only because no `districts` row points at them yet.

### 🔴 THE DEFECT: ONE CHAMBER PER DISTRICT, `official_count = 0`

`State of Indiana` carries **46 chambers**. It carries **no `Indiana House of Representatives`
chamber and no `Indiana State Senate` chamber.** Instead there are 18 chambers named for a single
district each:

```
Indiana House of Representatives - District 45     official_count 0    1 office
Indiana State Senate - District 33                 official_count 0    1 office
...
```

`count(DISTINCT o.chamber_id)` over `STATE_LOWER` is **12 across 12 offices**, and over
`STATE_UPPER` is **6 across 6**. FL and GA are 1 and 1.

🟢 **THE DEFECT IS INDIANA-ONLY.** Swept across every state: Indiana is the *only* one where a
legislative chamber count exceeds 2. Nothing else in production has to be repaired to fix this.

🟢 **AND NOTHING DEPENDS ON THE 18.** The three tables carrying a `chambers` FK —
`meetings.meetings`, `essentials.discovered_sources`, `essentials.source_outlets` — hold **zero**
rows against any of the 18 chamber ids. The only referents are their own 18 offices.

⚠ **The same shape exists on Indiana's courts and is NOT this wave's business**: five separate
`Supreme Court` chambers of one office each, and eleven `Indiana Appeals Court Judge - District N`
chambers. Recorded here so the next reader knows it was seen and left alone, not missed.
[`project_indiana_appellate_districts`] is the related note.

### 🔴 THE 18 OCCUPANCIES ARE UNDATED VENDOR BACKFILL

All 18 politicians carry `source = 'ballotready'`; all 18 terms carry
`start_precision = 'unknown'`, a NULL `term_start` and
`source = 'backfill from essentials.off…'`. Not one is dated.

This is exactly what CA-1 found in Long Beach, where all 13 rows were undated vendor backfill and
`CC_0054` re-dated them from the city's own Legistar. The Indiana equivalent is the General
Assembly's own member pages.

⚠ **`office.title` also disagrees with the house style.** These 18 carry the district name as the
title (`Indiana House of Representatives - District 45`); FL and GA carry `Representative` and
`Senator`, with the district on the *district*.

### The 18 already seated

House: 45 Borders · 46 Heaton · 60 Mayfield · 61 Pierce · 62 Hall · 63 Lindauer · 65 May ·
96 Porter · 97 Moed · 98 Shackleford · 99 Summers · 100 Johnson.
Senate: 33 Taylor · 37 Bray · 39 Bassler · 40 Yoder · 44 Koch · 46 Hunley.

🔴 **These 18 need the same change-check as the other 132, not less of one.** They were written by
a vendor at an unknown date, so "already seated" says nothing about whether the person still holds
the seat. The Knight rule stands: the check asks *has this person left?*, and the General
Assembly's own roster is what answers it.

### ⚠ `18046` IS TWO DISTRICTS, AND IT COST ME A WRONG BASELINE FIRST TIME

A `LEFT JOIN` from `districts` to `geofence_boundaries` on `geo_id` **alone** returned 25 House and
18 Senate district rows. The true counts are **12 and 6**. Indiana's `sldl` range runs 18001–18100
and its `sldu` range 18001–18050, so every Senate geo_id collides with a House one — `18046` is
House District 46 **and** Senate District 46 — and the fan-out inflated both numbers.

The spec already says to pair `geo_id` with `district_type` in every join. This is that rule
failing loudly enough to be worth restating: **the wrong number was plausible**, off by exactly the
kind of margin a partially-seeded state would produce.

## The roster — two sources, 150 seats, zero disagreements

| Source | What it is | Rows |
| --- | --- | --- |
| **A** `iga.in.gov/api/getLegislators?session_lpid=session_2026` | The General Assembly's own list, behind its React front end | **151** |
| **B** `data.openstates.org/people/current/in.csv` | Open States, a third party | **150** |

Reconciled: **150 seats, 100 House + 50 Senate, all distinct, 0 disagreements** on the holder.

🔴 **SOURCE A IS OVER-LONG BY ONE, AND THE MARKER IS A NULL DISTRICT.** Indiana keeps the departed
member in the list and blanks the district rather than removing the row. Senator **Andy Zay** is
the 151st: `"district": null`. He resigned effective **2026-01-08** on appointment to chair the
Indiana Utility Regulatory Commission, and **Nick McKinley** took SD-17 on **2026-02-09**. The rule
is therefore `district != null`, which is Georgia's `dateVacated == null` in a different dress. Do
**not** de-duplicate on name or district.

🟢 **THAT TURNOVER ALSO DATES THE SOURCES.** Both A and B independently show McKinley in SD-17, so
both are current to at least 2026-02-09 — and Open States carries 150 rows with no Zay, agreeing
with the rule rather than merely with the list.

### 🔴 THE 0-DISAGREEMENT RESULT WAS CONTROLLED BEFORE IT WAS BELIEVED

A uniform answer is a broken detector until a positive control passes. Three defects were planted
into source B and the diff was re-run:

| Control | Planted | Reported | Verdict |
| --- | --- | --- | --- |
| 1 | nothing | 0 disagreements | baseline |
| 2 | SD-17 surname corrupted | 1 — `upper-17 IGA:McKinley vs OS:Zzzcontrol` | ✅ |
| 3 | HD-1 row deleted | 1 — `lower-1 OPENSTATES MISSING` | ✅ |
| 4 | SD-17 moved to SD-99 | 2 — `upper-17 OPENSTATES MISSING` + `upper-99 IGA MISSING` | ✅ |

Three distinct defect shapes, three correct and *distinguishable* reports. The 150/150 agreement is
real, not a detector that returns "fine" to everything.

### 🔴 THERE IS NO `term_start` TO BE HAD, AND NONE IS INVENTED

`getLegislatorDetails` — the richest per-member endpoint the site has — returns exactly this:
`lpid, honorific, firstname, lastname, statephone, district_id, party, busemail, contact_form_url,
caucus_page_url, bills[], committees[]`. **No service-start of any kind. No portrait URL either.**

So every Indiana term is written open-ended at `start_precision = 'unknown'`, which is the GA-2
pattern (all 235 of Georgia's terms are `unknown`) and is what the 18 existing Indiana rows already
carry. ⚠ **Stage 5 will need the four caucus sites for portraits** — the API has none, though the
Open States CSV carries an `image` column worth measuring first.

### ⚠ A 200 THAT CARRIES THE SPA SHELL, ON THE SAME HOST THAT SERVED JSON A MINUTE EARLIER

`getLegislators` answers curl with JSON. `getLegislatorDetails` answers curl with **HTTP 200, 691
bytes of `<!doctype html>`** — the React shell — and it does so with a browser UA, with a `Referer`,
and with `X-Requested-With`. It answers an in-page `fetch()` with 7,548 bytes of JSON. Two endpoints
on one host disagree about who may read them, and **neither returns an error code to say so**. Only
a full decode catches it; `r.ok` and the status line both say success.

## 🔴🔴 THE REAL FINDING: 671 UNREACHABLE INDIANA OFFICES, AND 92 OF THEM ARE MY ROSTER

`essentials.politicians` holds **672 rows sourced `indiana_discovery`**, of which **671 hold an
office with no `district_id`, no `chamber_id` and no government**:

| Orphan office title | Count |
| --- | --- |
| Indiana Elected Official | 305 |
| State Representative | 231 |
| State Senator | 102 |
| Governor / SoS / Lt Gov / AG / other | 33 |

These are the "stranded officeholders" of
[`project_indiana_address_reachability`], measured at full size for the first time. **No address can
ever reach them**, and nothing errors.

**92 of the 150 sitting legislators are in this cohort.** The overlap, measured:

| Group | Seats |
| --- | --- |
| Already a `ballotready` row, seated on a real office | **18** |
| Already an `indiana_discovery` row, holding an orphan office | **92** |
| No matching person row at all — genuinely new | **47** |

(The three groups overlap slightly where a seat has both kinds of row; 18 + 92 + 47 is not 150.)

🟢 **THE MATCH IS UNAMBIGUOUS.** Not one of the 150 roster names matches more than one
`indiana_discovery` row. The GA lesson — that 2 of 4 name hits were a Colorado senator and a Utah
treasurer — was tested for here and does not arise.

🟢 **AND THE 92 CARRY NOTHING.** Zero stance answers, zero photographs, between them. Reuse
preserves no data; it only avoids manufacturing duplicates.

### Ruling R2 (Cantrell, 2026-09-10): reuse the 92, leave the orphan offices

Seat the existing 92 person rows on the new district-backed offices, create 47 new people, reuse
the 18 already seated. **No duplicate person rows are created.**

Their orphan offices are **left untouched and recorded as a debt**, not cleaned here. Two reasons,
and the second is the load-bearing one:

1. My 92 are a seventh of 671. Retiring only them leaves 579 and makes the cohort harder to reason
   about, not easier.
2. **Closing a term without flagging the office vacant pushes `essentials.offices_missing_terms`
   drift up**, and that unflagged count is the number CI watches. A cleanup wave has to flag as it
   closes, deliberately, across the whole cohort — that is its own wave, not a side effect of this
   one.

⚠ **The consequence, stated so it is not discovered later:** after IN-2, each of those 92 people
holds **two** offices — the real, reachable one this wave creates, and the orphan one. That is
visible in any per-person office count, and it is expected.

### Ruling R1 (Cantrell, 2026-09-10): full repair of the 18

Create the two real chambers, repoint all 18 existing offices onto them, normalise their titles to
`Representative` / `Senator`, then delete the 18 emptied pseudo-chambers.

## 🟢 STAGE 1 RE-CHECKED: THE POLYGON VINTAGE IS CORRECT, AND THE 2026 REDISTRICTING WAS A DIFFERENT MAP

Indiana's `sldl`/`sldu` polygons are `census_tiger_2024`, loaded 2026-02-11/12 — before this
program existed, which is why stage 1 reads ✅ without a Knight wave behind it.

The 2025–26 Indiana redistricting fight was **congressional only**, and it **failed**: the House
passed a new congressional map 57–41 on 2025-12-05 and **the Senate rejected it 31–19 on
2025-12-11**, 21 Republicans joining 10 Democrats. **No state legislative map was redrawn**, so the
2021 enacted plan still governs and TIGER 2024 is the right vintage.

⚠ **This is reasoning, not the GA-1 geometric proof.** GA-1's standard was to compare the state's
own published GeoJSON against every TIGER polygon at its own interior point — 180/180 and 56/56.
Indiana has **not** had that treatment. It is a task in this wave, before 132 offices are written
onto those polygons, not an assumption to carry.

## ✅ THE VINTAGE IS PROVED, NOT ARGUED — 150 / 150 AT GA-1 GRADE

`scripts/verify-in-legislative-vintage.mjs`. The General Assembly draws its own district overlay
on Find Your Legislator from two KMZ files it publishes itself:

```
/publications/maps/senate-districts/senate_2021.kmz    50 placemarks, KML dated 2022-04-29
/publications/maps/house-districts/house_2021.kmz     100 placemarks, KML dated 2022-04-29
```

Every one of the 150 TIGER polygons was tested at its own `ST_PointOnSurface`, against those
placemarks, with holes honoured:

```
House  100 / 100 agree
Senate  50 /  50 agree
total  150 / 150 agree, 0 disagree
```

Four planted controls passed first, including the one that matters most here:

| Control | Planted | Reported |
| --- | --- | --- |
| 1 | nothing | 0 |
| 2 | HD-45 geometry removed | 1 |
| 3 | **SD-17 and SD-18 swapped** — the layer-inversion failure | 2 |
| 4 | HD-99 given HD-100's geometry as well — ambiguity, not absence | 1 |

Control 3 is the Knight rule "TWO GIS LAYERS CAN INVERT" planted deliberately, so a detector that
merely counts coverage cannot pass this suite.

### 🔴🔴 THE SAME HOST SERVES JSON TO curl AND A REACT SHELL TO curl, AND BOTH ARE HTTP 200

`getLegislators` answers curl with real JSON. `getLegislatorDetails` and **both KMZ URLs** answer
curl with **HTTP 200 and 691 bytes of `<!doctype html>`** — with a browser user agent, with a
`Referer`, and with `X-Requested-With`. The same KMZ URLs answer an in-page `fetch()` with
**1,694,603** and **2,430,264** bytes beginning `PK\x03\x04`.

A script that trusted `%{http_code}` would have written a 691-byte file called `senate_2021.kmz`
and moved on. **Only a full decode catches it** — check the magic bytes and the length, never
`r.ok`, and never the status line. This is the WAF lesson, but it is not a WAF: it is the SPA's own
catch-all route answering for a path it does not recognise.

## ✅ THE ROSTER IS LOCKED — `data/in-legislature-roster.json`

`scripts/build-in-legislature-roster.mjs --self-test`. 150 seats, 100 House + 50 Senate, every
`geo_id` of the form `18` + three digits, every one resolving to a TIGER polygon in production:

| | Count |
| --- | --- |
| Roster seats | **150** |
| With a TIGER polygon | **150** |
| With a `districts` row already | **18** |
| District rows still to create | **132** |

Party is dropped at the roster boundary — it lives on `races.primary_party`, never on a person or
an office. `openstates_image` is carried for stage 5 only, and is **unmeasured**: the IGA API
publishes no portrait at all, so that column is the wave's only lead and has to be profiled before
it is trusted.

## ✅ ROSTERS.md AND BOTH MIGRATIONS ARE WRITTEN AND DRY-RUN CLEAN — NOT APPLIED

`CC_0088_in_legislature_structure.sql` and `CC_0089_in_legislature_incumbents.sql`. **Both slots
were reserved from the allocator**, not counted. Generated by
`scripts/gen-in-legislature-migrations.mjs`; `ROSTERS.md` by `scripts/gen-in-rosters-md.mjs`, so
the 150-row table is machine-generated and carries no transcription risk.

### What the two migrations do

| | `CC_0088` structure | `CC_0089` occupancy |
| --- | --- | --- |
| Chambers | **+2** (House 100, Senate 50) | — |
| Districts | **+132** (88 House, 44 Senate) | — |
| Offices | **+132**, and **18 repointed and retitled** | — |
| Pseudo-chambers | **−18**, guarded on emptiness | — |
| People | — | **+48 created**, **84 reused** |
| Terms | — | **+132**, all open-ended at `unknown` |

### The seat resolution, and why 92 became 84

| Disposition | Seats |
| --- | --- |
| **repair** — office already exists, holder kept | **18** |
| **reuse** — seats an existing `indiana_discovery` person | **84** |
| **new** — person created in `CC_0089` | **48** |

🔴 **EIGHT PEOPLE HAVE TWO PERSON ROWS EACH, AND THAT IS THE WHOLE OF THE 92 → 84 GAP.** HD-46,
HD-63, HD-96, HD-99, HD-100, SD-37, SD-39 and SD-44 each hold **both** a `ballotready` row (which
has the office) and a duplicate `indiana_discovery` row. The `ballotready` row keeps the seat;
neither is merged. Merging is a decision about *identity*, not about seating, and is not made
inside a seeding wave.

⚠ **HD-100 is the one to read twice.** Production says **Robert B Johnson**; the General Assembly
says **Blake Johnson**. Same man — Ballotpedia files him at `Robert_Blake_Johnson`. A surname-only
match would have passed this without ever noticing the first name differed.

### 🔴 R3 — THE HOST GOVERNMENT IS CHOSEN, NOT ASSUMED

There are **22** government rows named `State of Indiana`, every one `type` STATE, `state` IN,
`geo_id` NULL — indistinguishable by attribute. **Every other state in production has exactly
one.** The 18 pseudo-chambers are spread across **18 of them**, one each.

`e00dba00-b293-499c-ad67-6f52ab8f4d7c` hosts the legislature: the only row carrying correctly
modelled statewide chambers — Comptroller, Secretary of State, Treasurer, Utility Regulatory
Commission — with real `official_count` values. The other 21 are an import artefact and are **left
alone**; after `CC_0088`, 17 of them hold no chamber at all. Consolidating them is a larger repair,
and half-doing it is worse than scheduling it — the same argument as the orphan offices.

### 🔴 R4 — THE NEW DISTRICTS MATCH THE *CURRENT* LOADER, AND THE LEGACY 18 ARE LEFT UPPERCASE

`load-state-tiger-boundaries.ts` writes `state` as a **lowercase** abbreviation (line 719,
`FIPS_TO_STATE[fips]`) and labels sldl/sldu `State House District N` / `State Senate District N`.
That is why GA, FL, CO and NC are lowercase — **1,910 legislative district rows across 15 states**,
against **319 uppercase in only CA, IN and TX**. Indiana's legacy 18 came from an older loader.

The 132 new rows match the **current** loader, so a future loader run on Indiana is a **no-op**
rather than a duplicate-maker.

⚠ **The legacy 18 are deliberately NOT normalised, and I nearly did normalise them.** Live read
paths compare `d.state = $1` **case-sensitively** against an upper-cased argument
(`essentialsBrowseService.ts:100,996` → `districtQueries.ts:218`). Those queries filter to
statewide `district_type`s and so cannot see a `STATE_LOWER` row — but proving that for *every*
caller is a bigger claim than a seeding wave needs to make. **Indiana therefore carries both cases,
and every read must keep using `lower(d.state)`.**

### ✅ Dry run — both migrations as ONE transaction, and the rollback was verified

```
INSERT 0 1 · INSERT 0 1 · INSERT 0 132 · UPDATE 18 · INSERT 0 132 · DELETE 18
NOTICE:  IN-2 structure OK: 2 chambers, 100+50 districts, 100+50 offices, 0 pseudo-chambers
INSERT 0 48 · INSERT 0 132
NOTICE:  IN-2 occupancy OK: 150 offices, 150 seated, 0 dated, 0 ended
ROLLBACK
```

**Production was re-measured afterwards and is untouched:** 12 House / 6 Senate districts, 18
offices, 18 pseudo-chambers, **0** real chambers, **0** people in the reserved band. The rollback
reverted — confirmed, not assumed.

⚠ The first dry-run attempt aborted on a mis-escaped `\echo` **before** reaching the explicit
`ROLLBACK`, and `psql` rolled back on disconnect. That is the right outcome by luck, not by design.
The run above is the one that ends in an explicit `ROLLBACK` with exit 0.

### ✅ Gates green

| Gate | Result |
| --- | --- |
| `check:migrations` | OK — 2 added vs `origin/master`, 1872 slots across 126 refs, tree scan clean |
| `check:reservations` | OK — both slots reserved by their own author |
| `check:occupancy` | OK — 6 files scanned, no writes to the dropped `offices.politician_id` |

## ✅ IN-2 APPLIED 2026-09-10 — THE INDIANA LEGISLATURE IS SEATED AND THE DEFECT IS GONE

`CC_0088` then `CC_0089`, in that order, through `psql`. Both committed, exit 0, both post-verify
gates green on the real apply.

| | Before | After |
| --- | --- | --- |
| House districts / offices / seated | 12 / 12 / 12 | **100 / 100 / 100** |
| Senate districts / offices / seated | 6 / 6 / 6 | **50 / 50 / 50** |
| Distinct chambers over IN legislative offices | **18** | **2** |
| Pseudo-chambers | **18** | **0** |
| `official_count` on the House chamber | (none existed) | **100** |
| `State of Indiana` rows holding no chamber | 0 | **17** |

🟢 **`offices_missing_terms` DID NOT MOVE: 821 total / 166 flagged / 655 unflagged, before and
after.** That is the number CI watches, and it is why the two migrations are one unit — between
them, 132 offices exist with no term, and the window is closed by applying `CC_0089` immediately.

🟢 **17 government rows are now empty**, exactly as predicted before the apply. They are the
artefact R3 declined to consolidate, and they are now visibly inert rather than merely duplicated.

## ✅ THE PROBE PASSES, AND THE CONTROL WAS WATCHED FAILING FIRST

`scripts/verify-in-legislature-probes.sql`. Read-only.

```
Fort Wayne City Hall  -> State House District 82   Kyle Miller     unknown
Fort Wayne City Hall  -> State Senate District 16  Justin Busch    unknown
Gary City Hall        -> State House District 3    Ragen Hatcher   unknown
Gary City Hall        -> State Senate District 3   Mark Spencer    unknown

IN-2 PROBE PASSED: 2 anchors validated, 2 of 2 state answers at each, city/county
asserted at 0, 150/150 districts resolve to exactly one holder, 2 chambers, 0 pseudo-chambers
```

⚠ **Indiana scores 2 of 4, deliberately, and the probe asserts that rather than hiding it.** Stages
3 and 4 have not run, so Fort Wayne and Gary have no city or county seats. Section 3 asserts those
slots at **zero** — the FL-5 pattern, where Palm Beach's city slot was asserted at zero because it
had no city half. A wave that quietly scored 2 of 4 would otherwise be indistinguishable from a
wave that broke two tiers.

### 🔴 150/150 IS A UNIFORM ANSWER, SO THE CONTROL WAS PLANTED THREE TIMES

Each plant ran inside `BEGIN … ROLLBACK` against production.

| Control | Planted | Reported |
| --- | --- | --- |
| 1 | HD-82 unseated — Fort Wayne's own district | `Fort Wayne City Hall returns 0 representative(s) and 1 senator(s)` |
| 2 | HD-50 unseated — **away from both anchors** | `1 of 150 districts … (0 return several, 1 return none)` |
| 3 | HD-50 given a **second seated office** | `1 of 150 districts … (1 return several, 0 return none)` |

Control 2 is the one that matters: it is invisible to both anchors, so **only the per-district
sweep can catch it**. Control 3 is the Long Beach fan-out in miniature — one address returning
several holders — and the message distinguishes *several* from *none*, so the two failure modes
cannot be confused.

### 🔴🔴 CONTROL 3 PASSED FOR THE WRONG REASON ON ITS FIRST RUN, AND THE TELL WAS `INSERT 0 0`

The first version seated the planted office on `external_id = -1332001`. **No such politician
exists**: that id maps to HD-1, which was a *reuse*, so only the 48 genuinely new seats carry a
band id at all. The insert silently affected **zero rows**, nothing was planted, and the probe
duly reported `IN-2 PROBE PASSED` — a green that meant nothing.

The tell was the `INSERT 0 0` line, not the probe result. ▶ **A control is not a control until you
have seen its plant take effect** — check the row count of the plant itself, not only the verdict
that follows it.

## ✅ GATES AFTER THE APPLY

| Gate | Result |
| --- | --- |
| `check:migrations` | OK — 2 added vs `origin/master`, tree scan clean |
| `check:reservations` | OK — both slots reserved by their own author |
| `check:occupancy` | OK — no writes to the dropped `offices.politician_id` |
| `check:reachability` | **OK — nothing regressed.** `BAD_GEOMETRY` 4 (baseline 5), `DEAD_GEOGRAPHY` 17 (17), `UNREACHABLE` 37 (baseline 38) |

Two buckets came in **below** baseline. No new `in|` bucket appeared, which is the thing a
newly-seated state could plausibly have caused.

# IN-3 — Fort Wayne (applied 2026-09-10)

**11 offices, 11 people, 0 vacancies.** `X0048` (6 council districts), `CC_0090` structure,
`CC_0091` occupancy. Stage 3 is now open for Indiana.
Roster: [`backend/data/seed-fort-wayne-2026/ROSTERS.md`](../../backend/data/seed-fort-wayne-2026/ROSTERS.md).

🟢 `offices_missing_terms` unmoved at **821 / 166 / 655**.

## 🔴 ELEVEN OFFICES IS WHAT THE CODE SAYS, NOT WHAT INDIANA CITIES "USUALLY" HAVE

Fort Wayne Code **§ 31.01 ELECTED OFFICIALS** reads (A) Mayor, (B) Common Council — *"six district
members and three at-large members"* — and (C) City Clerk. **The section ends at (C).** Fort Wayne
elects **no city judge**. The Council Attorney named on every agenda is **appointed** and is not
modelled. 1 + 9 + 1 = 11.

⚠ The ordinance page returns **HTTP 403 to WebFetch** and loads fine in Playwright — the documented
403-with-a-browser-UA case, hit again.

## 🔴 THE THREE AT-LARGE SEATS ARE NOT NUMBERED, AND THE MIGRATION REFUSES TO NUMBER THEM

Georgia creates numbered posts, so Columbus carries `Council Member, Post 9 (At Large)`. **Indiana
does not**: all three run in one citywide race and the top three win. So all three offices carry the
**identical** voter-facing title `Council Member, At Large`.

That left them indistinguishable for the occupancy join. The discriminator lives in
`offices.description`, spelled out as an **internal ordinal** that is *"not a ballot designation"* —
because inventing "Seat 1/2/3" would describe a power Fort Wayne does not have. The post-verify gate
asserts the three at-large seats hold **three distinct people**, which is what a loose join would break.

## 🔴 THE SAME DOCUMENT GIVES A DAY FOR THREE MEMBERS AND THE WRONG DATE FOR FIVE

The Council's own agenda prints *"Elected to a 4-year term: 1/1/24 – 12/31/27"*. That is the **term**.

- For **Bender, Hartman and Myers** — new in 2024 — the term start *is* the start of continuous
  occupancy. Written `2024-01-01` at `day`.
- For **Ensley (2016), Jehl (2012), Paddock (2012), Chambers (2020), Freistroffer (2016)** the same
  sentence is **not** their occupancy start. They were re-elected in 2023, and **re-election does
  not end an occupancy**. Ballotpedia publishes only a year, so they are written at `year`
  precision — **not** back-filled to a January 1st no source states.

**6 day + 5 year, asserted by the gate.** One document, opposite meanings, decided per person.

## 🔴 TWO SEATS CHANGED HANDS MID-TERM, AND MY FIRST READING OF ONE WAS WRONG

| Seat | Change | Date |
| --- | --- | --- |
| **City Clerk** | Lana Keesling resigned on becoming Indiana GOP chair; **John McGauley** won the caucus and was sworn in that morning | resigned **2026-01-06**, sworn **2026-01-17** |
| **District 6** | Sharon Tucker left on becoming Mayor; **Rohli Booker** won the Democratic caucus 2024-05-18 | sworn **2024-05-21** |

⚠ **I assumed Scott Myers (D4) replaced Tucker. He did not.** Myers **won D4 at the 2023 election**,
the seat having opened when **Jason Arp** left to run for mayor. Tucker's seat was **D6**. Assigning
Myers a mid-term caucus date would have put a sourced-looking but false date on a real person — the
error would have survived every count-based check, because the count was right either way.

## 🔴 THE SIX DISTRICTS DO NOT TILE THE CITY, AND THAT IS CORRECT

| Measure | sq mi |
| --- | --- |
| TIGER place `1825000` | 112.0932 |
| Union of the six districts | 111.0025 |
| Place **not** covered | **1.2524** |
| Districts outside the place | 0.1617 |

The uncovered ground is essentially **one piece of 1.1340 sq mi** at `(-85.04700, 41.02744)`. The
Election Board's **own precinct layer** reports that point as precinct `ADAMS G`,
`City_Dist = 'COUNTY'` — unincorporated Allen County with no Fort Wayne council representation.

So it is a disagreement between **TIGER's place polygon** and **the county's city limits**, not a
hole in the council map. The loader **bounds** the gap rather than requiring closure: the
Columbus/Fort Benning situation, not the Macon-Bibb one.

## 🔴 A BOUNDARY LAYER CARRIED A ROSTER FIELD AND IT WAS EMPTY

`FW_City_Cncl_Dist_1..6` each carry `FW_Council_Rep`. Districts 1, 2, 4, 5 and 6 return `""`;
district 3 returns `null`. **Not one is populated.**

Santa Clara's vintage test — compare the layer's roster field against the verified roster to prove
the layer is maintained — **is unavailable here**. A field that looks like a source and holds
nothing invites the sentence *"the Election Board confirms the roster"*. It does not. GATE 2 asserts
the field stays **empty**, so the day it is populated the loader fails and someone decides.

🟢 **A DIFFERENT INDEPENDENT RECORD DID THE JOB INSTEAD.** The same service's precinct layer carries
`City_Dist` per precinct — 187 of 278 precincts are `FW 1`–`FW 6`. Every district was tested at its
own interior point: **6 of 6 agree, each returning a DIFFERENT value**, and the gap point returns a
seventh (`COUNTY`). The loader asserts that **distinctness**, not merely the agreement — a field
returning one value everywhere would agree with anything.

## ✅ Probe and controls

Fort Wayne City Hall returns **eight** answers: District 5 Geoff Paddock, three at-large members,
Mayor Sharon Tucker, City Clerk John McGauley, HD-82 Kyle Miller and SD-16 Justin Busch.

⚠ **Fort Wayne scores 3 of 4 and the probe asserts it** — Allen County is stage 4 and has not run,
so the county slot is asserted at **zero**, the FL-5 pattern.

| Control | Planted | Reported |
| --- | --- | --- |
| 1 | District 5 unseated — City Hall's own | `City Hall returns 0 district council member(s)` |
| 2 | District 2 unseated — **away from the anchor** | `1 of 6 council districts … (0 several, 1 none)` |
| 3 | one at-large holder removed | `City Hall returns 2 at-large member(s), expected 3` |

Every plant printed `DELETE 1` before the probe ran — the IN-2 lesson applied, where a control
planted nothing and "passed".

`check:reachability`: nothing regressed, no new `in|` bucket.

# IN-4 — Gary (applied 2026-09-10)

**Gary elects TWELVE offices. This wave seated SIX.** `CC_0092` structure, `CC_0093` occupancy.
6 offices, 6 people, 0 vacancies. `offices_missing_terms` unmoved at **821 / 166 / 655**.
Roster: [`backend/data/seed-gary-2026/ROSTERS.md`](../../backend/data/seed-gary-2026/ROSTERS.md).

## 🔴🔴 GARY ELECTS A JUDGE AND FORT WAYNE DOES NOT — TWELVE OFFICES AGAINST ELEVEN

Fort Wayne Code § 31.01 ends at City Clerk. Gary additionally elects a **Judge of the City Court**:
Indiana second-class cities *may* have a city court (IC 36-4-9), and the Lake County certified 2023
results carry a `Judge of the City Court` race, won unopposed by **Deidre L Monroe**.

**Inheriting Fort Wayne's answer would have silently dropped an entire elected judgeship**, and no
count-based check would have noticed, because 11 offices is a perfectly plausible number. This is
the DESCRIBE-REAL-POWERS rule paying for itself one wave after the rule was restated.

## 🔴🔴 THE SIX DISTRICT SEATS ARE DEFERRED, AND THE REASON IS A PERFECT-LOOKING STALE MAP

Gary **missed the statutory redistricting deadline of 2022-12-31**, was sued in federal court —
total district deviation measured at about **24%** — and under a settlement the Council **adopted a
new map on 2023-02-10**, governing from the 2023 primary.

| Candidate source | Verdict |
| --- | --- |
| `github.com/cityofgary/administrative-boundaries` — the City's own repo: 6 districts, EPSG 4326 GeoJSON, correctly named, from the Gary Sanitary District GIS Department | 🔴 **REJECTED. One commit, 2014-07-21; repo unpushed since 2014-08-13** — nine years older than the settlement map, and older than the 2020 census |
| City of Gary live GIS (`GaryINsight`, 15 items, updated 2026-09) | ❌ **no council-district layer at all** |
| Lake County council-district maps, updated 2026-06-10 | ❌ **PDF and JPG only** |
| ArcGIS Online | ❌ nothing for Lake County precincts or Gary districts |

**The 2014 layer is the trap and it is a very good one** — city-published, right format, right
projection, right names, six features. Only the commit date gives it away. That is the CA-2 failure
in another dress: the most convenient, correctly-named layer is the wrong map.

### Why the six offices were not created empty

Six offices with no geometry are six offices **no address can ever reach**, and nothing errors.
That is exactly the defect this slice measured at **671** offices in `indiana_discovery`, three days
ago. The structure gate therefore **asserts the six district offices are ABSENT**, so a later wave
that obtains the map has to add them deliberately rather than finding them half-made.

▶ Lake County's GIS page offers *"Request GIS Map or Data"* — request the 2023 settlement map.
**Do not georeference the PDFs.**

## 🔴🔴 THE SAME MAN WAS ABOUT TO BE SEATED TWICE, IN TWO WAVES, THREE DAYS APART

Four of Gary's twelve seats have changed since the 2023 election:

| Seat | 2023 | Now | What happened |
| --- | --- | --- | --- |
| At Large | **Mark Spencer** | Kenneth Whisenton | Spencer won **Indiana Senate District 3**, sworn **2024-11-19** |
| At Large | Ronald G Brewer Sr | *(chain)* | left; Marian Ivey took an at-large seat |
| District 4 | Tai Adkins | Marian Ivey | Adkins became **Calumet Township trustee**; Ivey won the D4 caucus **2025-02-19** on the county chairman's tie-break |
| At Large | *(Ivey's seat)* | Myles Tolliver | caucus Friday **2025-03-21** |

🔴 **Mark Spencer is the man `CC_0089` seated in SD-3 three days ago.** A wave that read Gary's 2023
certified results as current would have put him on **two live offices at once**. The probe asserts
he holds **exactly one** Indiana `STATE_UPPER` seat and **no** Gary office — and a planted control
confirms that guard fires rather than passing vacuously.

## 🔴 BALLOTPEDIA WAS DECISIVE FOR FORT WAYNE AND IS EMPTY FOR GARY

IN-3 dated five Fort Wayne councilmembers from Ballotpedia tenure fields. For Gary, **ten of twelve
officials return HTTP 404** — Fort Wayne is a top-100 city and Gary is not. The council's own member
pages are prose biographies with no tenure data.

So three of six terms are **`unknown`**, which is the honest answer, not a gap in the work — the
GA-2 position, where all 235 Georgia legislative terms are `unknown`.

⚠ **The two `month` rows are dated from the CAUCUS, not the swearing-in**, which is a different
event days later and is not published. 1 day + 2 month + 3 unknown, asserted by the gate.

## ✅ Probe and controls

Gary City Hall returns **eight** answers: Mayor Eddie Melton, Clerk Suzette Raggs, **Judge Deidre L
Monroe**, three at-large members, HD-3 Ragen Hatcher and **SD-3 Mark Spencer**.

⚠ **Gary scores 2 of 4 and the probe asserts both absences at zero** — no district councilmember
(deferred) and no county commissioner (stage 4).

| Control | Planted | Reported |
| --- | --- | --- |
| 1 | City Judge removed | `City Hall returns 0 city judge(s) … Gary elects one and Fort Wayne does not` |
| 2 | **Mark Spencer put back on a Gary at-large seat** | `Mark Spencer holds a Gary office as well as SD-3 — the same man on two live seats` |
| 3 | a Gary District 1 office created | `1 Gary district council office(s) exist; they are deferred…` |

`check:reachability`: nothing regressed.

# IN-5 — Allen County (applied 2026-09-10)

**19 offices, 19 people, 0 vacancies.** `X0049` (4 county council districts), `CC_0094` — **one**
migration carrying offices *and* people, per spec §3. `offices_missing_terms` unmoved at
**821 / 166 / 655**.
Roster: [`backend/data/seed-allen-county-2026/ROSTERS.md`](../../backend/data/seed-allen-county-2026/ROSTERS.md).

## 🔴🔴 COMMISSIONERS ARE ELECTED COUNTYWIDE, AND THE DISTRICT POLYGONS ARE THE TRAP

Under Indiana law a county commissioner **must reside in a district but is elected by the entire
county** — every voter elects all three. The Election Board publishes `Comm_Dist_1/2/3`: three neat,
correct, inviting layers. **Hanging the offices on them would show a voter one of the three
commissioners they actually elect.** So they are not loaded, and the three offices sit on the county
polygon `18003`, with `description` recording that the district is a residency rule.

⚠ **This is the exact inverse of the Long Beach failure.** There, nine councilmembers shared one
polygon and every address wrongly returned all nine. Here every county address **should** return all
three. **The same shape is wrong in one case and right in the other, and only the statute tells you
which.** A coverage or fan-out check cannot distinguish them.

🟢 The **County Council is genuinely different**: 4 elected **by district** (`X0049`) + 3 **at large**
countywide. And unlike Fort Wayne's six city districts, these four **do tile their parent** —
660.0234 vs 659.9832 sq mi — so this loader requires **closure** where the city loader could only
**bound** the gap.

## 🔴🔴 THE COUNTY'S OWN DIRECTORY WAS THE STALE SOURCE

`allencounty.in.gov`'s directory lists **Josh L. Hale** on County Council District 1. The county
party page said **Kyle Kerley**. Settled from the news record: **Hale resigned effective
2026-01-15**; **Kerley won the GOP caucus at noon 2026-01-16**.

▶ **The body's own roster is usually the check, and here it was the thing that was wrong.** The
change-check has to ask *has this person left?* of **every** source, the official one included.

⚠ The same article named a **second** caucus the next morning — Fort Wayne City Clerk, Keesling to
McGauley. That is the IN-3 change, found again independently.

## 🟢 AN ASSERTED ABSENCE DID ITS JOB

IN-3's probe asserted **0 Allen County offices** with the comment *"so the day it lands, someone
looks"*. It **fired the moment `CC_0094` applied**, reporting 15. That is what asserting an absence
is for. The probe now asserts presence — and asserts **three** commissioners, not one.

**Fort Wayne is now 4 of 4.**

## ✅ Probe and controls

A Fort Wayne address returns **16 county answers**: 3 commissioners, 1 council district member,
3 at-large, 9 officers.

| Control | Planted | Reported |
| --- | --- | --- |
| 1 | one commissioner unseated | `returns 2 commissioner(s), expected 3 — Indiana elects all three county-wide` |
| 2 | County Council D4 unseated (the anchor's own) | `returns 0 county council DISTRICT member(s)` |
| 3 | County Council D1 unseated, **away from the anchor** | `1 of 4 … (0 several, 1 none)` |

⚠ **Control 1's plant was broader than intended** — `title = 'Commissioner, District 2'` matched
other counties too and deleted 14 rows before rolling back. The probe caught it and nothing
persisted, but the plant was sloppier than its label; **scope a planted control to the jurisdiction**.

Dates: **17 year + 1 month + 1 unknown**. Kerley is `month`, not `day`, because only the caucus date
is published — the Gary rule. Richard Beck has no Ballotpedia page under any slug tried, so
`unknown`.

# IN-6 — Lake County (applied 2026-09-10)

**Lake elects 19 offices. This wave seated 12.** `CC_0095`, one migration carrying offices *and*
people. The seven County Council district seats are **deferred**, as Gary's six were.
`offices_missing_terms` unmoved at **821 / 166 / 655**. No boundary layer was needed — everything
seated hangs on `18089`/`G4020`, already in production.
Roster: [`backend/data/seed-lake-county-2026/ROSTERS.md`](../../backend/data/seed-lake-county-2026/ROSTERS.md).

## 🔴🔴 AN AGGREGATED SEARCH GAVE ME THREE WRONG COMMISSIONERS

It returned **"Barry Shullanberger, James Williams, Mark Albertson"**, and a Clerk who was also
*"Recorder, Auditor, Public Administrator and Surveyor"* — **a combined office no Indiana county
has**. Those belong to a **Lake County in another state**. The county's own department pages give
**Kyle W. Allen Sr., Jerry Tippy, Michael C. Repay**.

▶ **For a generically named county, an aggregated source is a JURISDICTION-collision risk, not just
a staleness risk.** There are Lake Counties in at least twelve states. This is the Georgia
name-collision failure with the *jurisdiction* colliding rather than the person — and stopping the
previous session rather than seating from that source is what caught it.

## 🔴 TEN IDENTICAL ANSWERS FROM THE COUNTY'S OWN SITE, AND THEY WERE ALL THE NAV BAR

My first extraction keyed on a regex that matched a navigation item present on every page, so all
ten offices returned `"Superior Court Elected Officials — Assessor"`. **Ten identical answers is a
broken detector, not a finding.** Stripping nav/header/footer and keying on each page's "Our Team"
block returned ten distinct names — and the distinctness is the evidence the fix worked.

## 🔴 LAKE'S COUNCIL IS SEVEN SINGLE-MEMBER DISTRICTS; ALLEN'S IS FOUR PLUS THREE AT LARGE

Two Indiana counties in one slice, two different councils. All seven of Lake's are **deferred**:
Lake publishes every map as **PDF only**, and its open-data organisation (`lakecountyod`, 174
layers) is cadastral and physical with **no electoral district layer**. Offices without geometry are
unreachable, so the gate asserts their absence.

🔴 **Ronald G. Brewer Sr. — who left Gary's at-large seat in IN-4 — sits on Lake County Council
District 2**, a deferred seat. The probe asserts he holds **no** office, so a later wave cannot
double-seat him. **Two people have now moved between jurisdictions mid-term in this slice**: Mark
Spencer (Gary at-large → SD-3) and Brewer.

🔴 **All 12 terms are `unknown`.** Ballotpedia 404s for all thirteen Lake officials tried — not a
broken method: the same batch returned **14/19 for Allen** and **9/9 for Fort Wayne** minutes
earlier. It simply does not cover Lake County, as it does not cover Gary.

## ✅ Probe and controls

A Gary address returns **12 county answers**: 3 commissioners + 9 officers.
Gary's own probe was updated — its Lake assertion **fired** on apply, and **Gary now scores 3 of 4**.

| Control | Planted | Reported |
| --- | --- | --- |
| 1 | one Lake commissioner unseated (**scoped to Lake**, after the Allen over-broad plant) | `returns 2 commissioner(s), expected 3` — `DELETE 1` |
| 2 | a Lake County Council office created | `1 Lake County Council office(s) exist; all seven are deferred` |

# IN-7 — stage 5, assets (applied 2026-09-11)

**186 of 198 Indiana officials now carry a renderable portrait, from 18.** 168 imported, 18 skipped
(they already had one), 0 failed. No migration — headshots are storage objects plus
`photo_custom_url`. Legislature **150/150**, Fort Wayne **11/11**, Gary 4/6, Allen 12/19, Lake 9/12.
Both city banners are uploaded, byte-verified and **registered — [essentials#133](https://github.com/EmpoweredVote/essentials/pull/133)
merged 2026-09-11 08:22Z as `e5ab4d9f`**, and the live bundle serves both keys. **Stage 5 is CLOSED.**

⚠ **That does not complete Indiana.** Stage 3 remains WIP: Gary elects twelve offices and holds six, its six
district seats deferred until the 2023 settlement map exists. Indiana is four stages of five.

Contact sheet (198 cards, 12 of them blanks carrying their reason):
<https://claude.ai/code/artifact/b4ef0597-0eb0-4bf4-99e8-9854e877d30e>
Banner certification: <https://claude.ai/code/artifact/16f94d4f-a16c-4c84-9104-eea5733790b8>

## 🔴🔴 THE LEGISLATURE'S PORTRAITS WERE ON A HOST THE API DOES NOT ADVERTISE

IN-2 recorded that Indiana's General Assembly API publishes **no portrait**, which was true and was
read as "Indiana publishes none". Its **website** publishes one per member:

```
https://iga.in.gov/images/legislators/124/2026/{house|senate}/{iga_lpid}.jpg
```

The path is built entirely from `iga_lpid`, which the locked roster already held for all 150. It is
**600x798** where the Open States column gives 200x300, and it covers the **two** members Open
States has no image for at all. **The API's silence was not the site's.**

### 🔴🔴 PLAYWRIGHT IS NOT THE FIX ON THIS HOST — THE USER AGENT IS

Same HTTP-200 decoy shape IN-2 met on the KMZ downloads, opposite cure. Measured on one URL:

| client | result |
| --- | --- |
| `curl`, any UA | 691 B React shell, `text/html` |
| headless Chromium, Playwright's default `HeadlessChrome` UA | 691 B shell — **and the page's own `<img>` does not load either** |
| headless Chromium + a full Chrome UA | **120,801 B JPEG** |
| headed Chromium | 120,801 B JPEG |

Timing, `waitUntil` and a warm-up were each tested and changed nothing. ⚠ The tell that it is a UA
block rather than a broken fetch: the page's own `<img>` renders in one browser and not the other,
on the same DOM.

### 🔴🔴 A NEGATIVE CONTROL ALONE CERTIFIED A TOTALLY BLOCKED SWEEP

The first sweep shipped one control: *a legislator who does not exist must not return an image.* It
**passed** — while **all 150 real members returned the 691-byte shell**. The control was satisfied
precisely because nothing worked. This is IN-2's `INSERT 0 0` in another dress.

▶ **Pair every negative control with a positive one taken in the same breath**, and **run the pair
again after the sweep**, so a block that begins midway is told apart from a source that genuinely
lacks those members. An `IGA_UA=HeadlessChrome` override exists so the pair can be **watched
failing** before it is trusted.

Result, with both controls green at both ends: **150 of 150 decoded, 150 distinct sha256.**

### 🔴 THE URL, THE EXTENSION AND THE CONTENT-TYPE ALL LIE

All 150 arrive from a `.jpg` URL served as `image/jpeg`. **147 are JPEG, 2 are PNG, 1 is WEBP.**
Both PNGs carry alpha — which the renderer paints **black** and the importer flattens **white**, the
FL-7 defect. Sniff the magic number. Six files are camera originals up to 15.8 MB at 4160x6240.

## 🔴🔴 `cdn.zephyrcms.com` UPSCALES ON DEMAND, AND ITS OWN `stretch/off` IS IGNORED

Asking the Senate Republican CDN for Vaneta Becker at 2400x3600 returns a 422 KB file at exactly
that size, with `-/stretch/off/` present — the directive whose entire purpose is to forbid
enlarging. It is an enlargement: its 1200x1800 differs from **my own bicubic upscale of its own
200x300** by **RMS 4.8 of 255**, under 2%, and carries no more high-frequency detail (19.8 against
16.2 for my upscale). Her own Senate page serves the same 200x300.

**So 38 Senate Republicans are really 200x300, and no bigger file exists.** A bigger number is not a
better source.

🟢 **The opposite case, same day:** Vernon Smith's caucus page serves him from Squarespace, whose
`?format=` parameter **caps**. `1500w`, `2500w` and `original` all return the identical 273,088
bytes at **1200x1499**. That refusal to go further is what a genuine original looks like — and it
took him from IGA's 155x208 to the best portrait in the set.

⚠ **The House Republican site publishes no large portraits at all**: Clere's own member page tops
out at 308x462 for a solo image and 182x235 for the rest, its larger files being two-person event
photos. Karickhoff, Clere and Lehman stay at 255x255, at their publisher's ceiling.

## 🔴🔴 `geo_id` COLLIDES ACROSS CHAMBERS — HD-1 AND SD-1 ARE BOTH `18001`

Joining the contact sheet's candidate rows to production on `geo_id` alone paired **63
representatives with senators**: Carolyn Jackson's row took Dan Dernulc's portrait. Keyed on
**(chamber, geo_id)** it matches 150 of 150 with none unmatched, and the 16 remaining name
differences are all renderings of the same person (`Dale DeVon`/`Dale Devon`, `Bob`/`Robert`).

**A wrong-person defect produced by a join, not by a source.**

## 🔴🔴 TWO RENDERABLE FILES WERE NOT PORTRAITS, AND BOTH MATCHED ON A NAME

- **Oscar Martinez, Lake County Sheriff** — `lakecountyin.gov/images/user-icon-placeholder.png`, a
  blue silhouette, with "Oscar Martinez Sheriff" beside it.
- **Suzette Raggs, Gary City Clerk** — a 1920x600 photograph of the clerk's counter, her name on the
  office signage.

Both would have counted as coverage. **A name beside an image proves the image belongs to that
entry; it does not prove the image is a picture of the person.** ⚠ Ballotpedia's "Oscar Martinez"
page is not the Indiana one — the same collision, caught by checking the page named Indiana.

## ⚠ MY MONOCHROME DETECTOR WAS WRONG, AND ONLY CONTROLS CAUGHT IT

A channel-spread metric flagged six legislators as possible greyscale. Three **known colour**
portraits pushed through the same metric scored no better — Todd Huston at 11.19 against a flagged
9.04. Re-measured on HSV saturation the six sit at 24–49 mean, one of them above a control.
**They are muted palettes, not greyscale. No monochrome in the 150**, and the standing skip rule
dropped nobody it should not have.

Three county officers **are** genuinely black-and-white — Petalas, McAlexander, Katona — and are
blank under that rule.

## 🔴 ALLEN COUNTY PUBLISHES NO MEMBER PORTRAITS AT ALL

Verified rather than assumed: the County Council page names all five missing members and carries
**12 images, every one site chrome** — logo, search icon, five social icons, Google Translate. The
Recorder page has an office seal and a photograph of the office. Ballotpedia's pages for Lagemann
and Keesling are stubs.

The only source holding their faces is the county party site. **Ruling (Cantrell, 2026-09-11): do
not take it — leave all six blank.** A blank beats a link, as with Baldwin's four in GA-3.

## The twelve blanks

| Jurisdiction | Who | Why |
| --- | --- | --- |
| Allen | Hammond, Armstrong, Fries, Kerley, Lagemann, Keesling | no portrait published; party page refused by ruling |
| Gary | Suzette Raggs | only image is the clerk's counter |
| Gary | Deidre L Monroe | no page exists for the City Court; Ballotpedia 404s |
| Lake | Oscar Martinez | county serves a placeholder silhouette |
| Lake | Petalas, Katona | monochrome |
| Allen | McAlexander | monochrome |

## Banners — certified in the band, not the frame

| | Fort Wayne | Gary |
| --- | --- | --- |
| subject | confluence of the St Marys and St Joseph, Columbia Street Bridge | City Hall colonnade and the Lake County Superior Courthouse dome |
| credit | Momoneymoproblemz, CC BY-SA 3.0 | Nyttend, **public domain** |
| source | 4896x1992 | 2816x1584 |
| anchor_y | 0.25 | 0.35 |
| saturation | 68.6 | 63.8 |
| band luminance | 84.8 | 123.1 |
| people | none at 3x | none at 3x |

Indiana already carried two compositions to differentiate against — the **elevated** Indianapolis
state panorama and Bloomington's **street corridor** — and the comparison is camera height and
subject scale, never the subject noun.

### 🔴🔴 A CATEGORY NAME IS NOT A JURISDICTION, AND I PROVED IT ON MYSELF

Sweeping `Category:Maumee River` for Fort Wayne returned **Defiance, Ohio** — Fort Amanda, Pontiac
Park, the Auglaize confluence. The Indiana Dunes categories returned **Porter County** for Gary.
This is the IN-6 Lake County collision, reintroduced by my own choice of search root.

Fixed with a check this repo can actually make: every candidate coordinate tested against the city's
own TIGER place polygon. **21 rejected for Fort Wayne, 38 for Gary.** Gary's chosen file lands
**60 m from the City Hall point IN-4's own probe uses**. Fort Wayne's carries no coordinates and was
cleared instead by its uploader's description naming the Three Rivers Water Filtration Plant.

### 🔴🔴 GARY'S COMMONS COVERAGE IS DOMINATED BY RUIN PHOTOGRAPHY

Five of the six best candidates by size and aspect are the derelict City Methodist Church and
abandoned buildings — every one wide, sharp, in-city, daylight and correctly licensed. **Ranking on
measurements alone puts a collapsed church on the banner of a city whose mayor and council this
slice seated.** Sorting Fort Wayne the same way puts three derelict parking garages on top.
**Aspect is not merit.**

⚠ Refused and worth recording: the **Allen County Courthouse**, Fort Wayne's strongest civic
subject. Its dome sits too near the top edge to be centred in the band without discarding the
building's width — the Milledgeville frontal-building failure exactly. And
*"Marquette Park — Gates and **Chicago Skyline**"* was refused outright: another city's skyline.

## ⚠ A PATCH THAT DID NOT APPLY COST THE HARVEST TWICE

A change meant to make the portrait harvester merge rather than overwrite was written and reported
as done. **Two of its three string replaces matched nothing**, so the script kept overwriting, and a
transient timeout on three Allen pages destroyed the other seventeen pages' results — twice. A
string replace that matches nothing is a no-op that looks exactly like success.

▶ The builder and the harvester now **assert their own edits are present on disk after writing**.

# IN-8 — Gary's six district seats (applied 2026-09-11)

**Gary is complete: 12 offices, 12 people, 0 vacancies.** `CC_0096` structure, `CC_0097` occupancy,
`X0050` boundaries. **Stage 3 closes, and INDIANA IS COMPLETE ACROSS ALL FIVE STAGES** — the
program's fourth slice after FL, GA and CA. `offices_missing_terms` unmoved at **822 / 167 / 655**.

The six districts are a **dissolve** of the Lake County Surveyor's precinct layer on the leading
digit of `P26`. 47 precincts; each district dissolves to **one connected valid polygon**; **zero**
pairwise overlap; union 57.22 sq mi against Gary's 49.75 land + 7.47 water; 0.105 sq mi of the
place polygon uncovered (0.21%, six slivers and one compact 5-acre piece) against Fort Wayne's
1.2524. Six gates in the loader, and GATE 2 is the vintage assertion.

## 🟢 THE ASSERTED ABSENCE DID ITS JOB, FOR THE SECOND TIME IN THIS SLICE

`CC_0092` ended with *"the six district seats MUST NOT exist yet... this assertion is what makes
that a decision rather than an accident"*. It fired the moment `CC_0096` applied. IN-5's probe did
the same thing to IN-3's "0 Allen County offices". **Both times the absence was the thing that made
the next wave deliberate.** `CC_0092`'s gate is now updated rather than deleted, so a seventh
district office is still a defect and the file still re-runs clean.

## 🔴🔴 GA-5's "INVISIBLE BREAK" HIT THREE GATES AT ONCE, AND ONLY A RE-RUN FOUND IT

`CC_0092` and `CC_0093` counted **every Gary office** and expected 6; `CC_0093`'s precision tuple
counted every Gary term and expected 1 day / 2 month / 3 unknown. All three were correct on apply
day and **all three broke the moment IN-8 added six offices to the same government** — reading 12
offices and 1/3/8. GA-5 demonstrated this defect deliberately in three legs; here it arrived on its
own, in a slice written by the same hand a day earlier.

▶ **The fix is to SCOPE the gate to what the migration creates** — here, to the citywide district
`1827000` — never to widen the expected number. All five Indiana waves now re-run clean.

⚠ **`CC_0097`'s own pre-flight broke its second run**: it asserted the external_id band was empty,
which is false once it has applied. It now accepts 0 **or exactly our six, verified by name** —
because the reason to check a band at all is that a collision seats the wrong person silently.

## 🔴 MY CONTROL WAS BROKEN BY THE EXACT TRAP THE REPO ALREADY DOCUMENTS

Control 1 unseated District 3 and then reported the district still returning **1** councilmember, as
if the probe were blind. The plant was fine and the data was fine: **`office_current_holder` LEFT
JOINs from `offices`, so an unseated office still returns a row with a NULL `politician_id`**, and
the control used `count(*)`. `count(och.politician_id)` reads 0.

The probe itself was never wrong — it inner-joins `politicians`, which drops the NULL row. ▶ **A
control is code too, and it fails the same ways the thing it checks does.**

## 🟢 THE SCHEMA REFUSED CONTROL 3, AND THAT IS THE FINDING

Planting "Marian Ivey holds her old at-large seat as well as District 4" was **rejected by
`office_terms_no_overlap`**: an open-ended term is an infinite range, so the database already makes
**two people on one office** impossible. It cannot see **one person on two offices** — the Mark
Spencer failure — which is exactly why `CC_0097` gates that in SQL rather than trusting a
constraint. The plant had to vacate the at-large seat first.

## ✅ Probe and controls

Gary City Hall returns **7 city answers** (mayor, clerk, judge, 3 at-large, **1 district member**),
12 county, 8 state — **Gary scores 4 of 4**. All six districts resolve to exactly one councilmember
at their own interior point.

| Control | Planted | Reported |
| --- | --- | --- |
| 1 | District 3 unseated, away from the anchor | `District 3 interior point now returns 0 councilmember(s)` |
| 2 | District 6 moved onto the CITYWIDE polygon | `Gary City Hall now returns 2 district councilmember(s)` — the Long Beach defect |
| 3 | at-large seat vacated, then Ivey double-seated | `Marian Ivey now holds 2 Gary offices` |

The loader's vintage gate was also watched failing: `GARY_VINTAGE_CONTROL=1` injects `G4 22`, a
precinct that exists only in TIGER 2020's pre-settlement assignment, and GATE 2 refuses the load.

Gates after the apply: `check:occupancy` green, `check:migrations` 10 added / 1886 slots / 136 refs,
`check:reservations` green, `check:reachability` **nothing regressed**, with `BAD_GEOMETRY` 4
(baseline 5) and `UNREACHABLE` 37 (baseline 38) — both below baseline.

## ▶ WHAT REMAINS FOR INDIANA

**All five stages are closed.** What follows is debt, not scope.

▶ **The debts have their own file — [`in-debt.md`](./in-debt.md)** — with every number
re-measured 2026-09-11 and a suggested order. Three of the figures below drifted from what earlier
notes said, and the portrait debt is LARGER than it was: IN-8 seated six members with no portraits.

1. ✅ **DONE — Gary's six district council seats were seated by IN-8 on 2026-09-11.**
   Stage 3 is closed and Indiana is complete across all five stages.

   ✅ **The current map has been FOUND, and it is not loadable.** Lake County publishes
   `GARY CITY COUNCIL DISTRICTS 3X5.pdf` under `departments/voters/maps-gis/CITY-COUNCIL-DISTRICT-MAPS/`:
   six districts, **prepared by the Lake County Board of Elections & Registration**, **created in
   Esri ArcMap 10.8.1 on 2024-03-01** — thirteen months after the settlement map was adopted, and a
   decade after the 2014 GitHub layer IN-4 rejected. It is **7 raster images with ZERO vector path
   operations** and is stamped *"FOR REFERENCE ONLY"*, so there is no geometry in it to extract.

   ▶ **But its metadata names the source**: the layer exists in ArcMap at the Board of Elections.
   The request is no longer "do you have a map" but *"please export the council-district feature
   class behind GARY CITY COUNCIL DISTRICTS 3X5.pdf, created 2024-03-01"*.

### 🟢🟢 GARY IS UNBLOCKED — THE CURRENT PRECINCT LAYER IS PUBLIC, AND IT WAS TWO CLICKS AWAY

Found 2026-09-11 from the county's own GIS index page, behind the link **"Request GIS Map or Data"**:

```
https://services5.arcgis.com/8CXRnvSfSpwdf0R6/arcgis/rest/services/Selectable_Features/FeatureServer/4
   layer 4 "Election Precincts"  --  342 polygons, public, queryable, one field: P26
```

It belongs to the **Lake County Surveyor's Office GIS Hub** (`lakecountyhub-lakeingispro`), which is a
**different ArcGIS organisation** from the `lakecountyod` open-data org IN-6 swept and correctly
found to hold no electoral layer. **IN-6's finding was true of the org it looked in.**

**47 Gary precincts, six districts**, the district encoded as the leading digit of `P26`
(`G1 03` … `G6 18`), including the oddity `G5 24 NV`.

| | D1 | D2 | D3 | D4 | D5 | D6 | total |
| --- | --- | --- | --- | --- | --- | --- | --- |
| precincts | 7 | 7 | 8 | 7 | 10 | 8 | **47** |
| sq mi | 20.00 | 11.27 | 7.20 | 4.71 | 10.62 | 3.34 | **57.14** |

✅ **CLOSURE**: 57.14 sq mi against Gary's expected 49.75 land + 7.47 water = **57.22**, a 0.14%
difference. The precincts tile the city, water included.

✅ **VINTAGE PROVED ON THE THREE PRECINCTS THAT FAILED TIGER.** `G4 01`, `G5 22` and `G5 28` are all
present in this layer and all printed on the county's 2024 PDF; TIGER 2020 has none of them and puts
those precinct numbers in districts 2/5, 1/4 and 4. Rendered side by side, this layer reproduces the
PDF's colouring — including the east-centre block that TIGER paints District 4 and both the PDF and
this layer paint District 5.

⚠ **`P26` is READ AS "precincts, 2026" AND THAT IS AN INFERENCE, NOT A SOURCED FACT.** One label
differs from my reading of the 2024 PDF (the PDF appears to show `G4 14`, which this layer does not
carry), and precinct counts fall from TIGER's 52 to 47 — both consistent with precincts being
consolidated between 2020 and 2026. **This does not move a district boundary** unless a consolidation
crossed one, which the dissolve test must confirm. Confirm the field's meaning with the county before
seating.

▶ **Gary's six district seats are now a seating wave, not a data request.** What IN-8 must still do:
dissolve the 47 by leading digit, assert each district is a single connected polygon, gate that the
union equals the place polygon, load as `X00NN`, then seat the six members already identified in
IN-4 (Latham D1, Halliburton D2, Brown D3, Ivey D4, Barnes-Caldwell D5, Williams D6).

🔴 **LAKE COUNTY COUNCIL IS STILL BLOCKED.** The same org has no council-district layer, and `P26`
encodes the *city* council district, not the county one, so the seven county seats cannot be
dissolved from it. That deferral stands.

### 🔴🔴 THE PRECINCT-DISSOLVE SHORTCUT WAS TESTED AND IT FAILS — TIGER 2020 IS THE PRE-SETTLEMENT MAP

The map labels each precinct `G<district> <precinct>`, and Census publishes
`tl_2020_18_vtd20.zip` — **all 52 Gary precincts, same naming scheme, including the odd `5-24NV`**.
That looked like a way to build the six districts by dissolving precincts, with no georeferencing
and no data request. Rendering the 52 TIGER polygons coloured by the district their own name
encodes produces a map that looks **strikingly like** the county's: orange 2nd top-left, purple 1st
along the lake, mint 3rd west, pink 4th centre, blue 5th, yellow 6th south.

**It is wrong, and three named precincts prove it.** Read off the county's 2024 map at 6x zoom:

| county 2024 map prints | TIGER 2020 puts that precinct number in district |
| --- | --- |
| `G4 01` | 2 and 5 — **not 4** |
| `G5 22` | 1 and 4 — **not 5** |
| `G5 28` | 4 — **not 5** |

TIGER's district 4 is `03 05 10 14 16 22 23 25 28`; its district 5 is `01 02 03 04 06 13 14 16 19
24NV`. The 2023 settlement reassigned precincts between districts, and **the district number is
part of the precinct's name**, so there is no stable key linking a 2020 precinct to a 2024 one.
Dissolving TIGER would have produced six correctly-shaped, correctly-named, **wrong** districts.

🔴 **This is the 2014-layer trap one vintage later, and far better disguised** — a federal source,
the right city, the right precinct count, the right naming scheme, and a picture that matches at a
glance. **Only three specific labels give it away.**

⚠ **A colour-area comparison was attempted first and was a BROKEN DETECTOR** — it sampled legend
swatches at hardcoded coordinates, hit white, and reported districts 1, 2, 3 and 4 as holding
**exactly 24.2%** each. Four identical numbers is the tell. Nothing was concluded from it; the
verdict rests on the three named precincts.
2. **The two deferred geometries**, both to be **REQUESTED from the county, never georeferenced from
   a PDF**: Gary's **2023 settlement map** (6 council district seats) and **Lake County Council's
   seven districts**. Lake County GIS offers a "Request GIS Map or Data" form. Until they exist the
   13 offices stay absent, asserted so by both probes.
3. **The twelve portrait blanks** — see the table above. The six Allen officials are blank by
   ruling, not for want of looking; Gary's City Court judge has no published page at all.
4. The recorded debts: **671 unreachable offices** in `indiana_discovery` and **21 surplus
   `State of Indiana` government rows**, 17 of which now hold no chamber. Neither is drift from this
   slice; both predate it and are their own wave.
